---
branch: fix/pr-finalize-aborts-own-rebase
date: 2026-10-14
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 2
findings_fixed: 2
tokens: 125000
duration_min: 35
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: o próprio agente executor (opus), por mutação com ops/mutate-and-restore.sh, 4 mutantes contra a família pre_push; NÃO houve juiz independente nesta passada
nota: SAC-136, radar E3 r11 (Q_MERGE_SERIAL_SOBREVIVE_A_SAIDA_DA_SESSAO). O tokens é a janela consumida pelo agente (estimativa pelo contador da sessão, não um ledger)
---

# O pr-finalize aborta o rebase que ele mesmo começou

## O defeito

A 2.1.300 do Claude Code mata o comando de fundo 1,5 s depois da saída da sessão. Quem mediu foi o juiz do
radar E3 r11. O `trap _cleanup EXIT` do `ops/pr-finalize.sh` roda sob SIGTERM, mas não abortava o
`git rebase` que o `--rebase` começa. Morto nesse ponto, o motor deixava a worktree em rebase, e a rodada
seguinte morria no pré-check `git diff --cached --quiet`.

## A cura

- **Flag `_OWN_REBASE`.** Liga logo antes do `git rebase` e desliga quando o bloco termina.
- **`_abort_own_rebase`.** É o 1º passo do `_cleanup`. Só aborta com o flag ligado e com `rebase-merge`
  ou `rebase-apply` presente. O caminho sai por `--path-format=absolute`.
- **Recusa explícita do rebase alheio.** Quando já havia um rebase em curso, o motor recusa ANTES de
  instalar o trap e nomeia a causa. Antes dela também recusava, mas por "HEAD destacado", o que é
  verdadeiro e diz a coisa errada.

Lock, merge do forge e sync ficaram intocados.

## Passada adversarial (mutação, medida)

| Mutante | Caso que o pega | Resultado |
|---|---|---|
| `_cleanup` sem `_abort_own_rebase` | (k1) | **morto**: rc=143, `rebase=EM-CURSO`, `UU docs/backlog.md`; a rodada seguinte recusa |
| `_OWN_REBASE=1` virando `=0` (flag nunca liga) | (k1) | **morto**, com o mesmo desfecho |
| a recusa do rebase alheio trocada por `:` | (k2) | sobreviveu na 1ª forma do caso, que só olhava o desfecho. Curado: o caso exige a recusa nomeada, e o mutante agora **morre** |
| o abort sem checar o flag (aborta qualquer rebase) | (k2) | **sobrevive, e é equivalente por ordem**: o rebase alheio é recusado antes de o trap existir, então o abort nunca o alcança. O flag fica como 2ª camada, para um rebase alheio que comece DURANTE a rodada, e esse caso não é montável na bancada |

O mutante restaurou nas quatro vezes (`grep -c ONION_MUTANTE` deu 0).

### Achados

1. **REAL e curado: a 1ª forma do (k1) passava no vazio.** `git -C <w> rev-parse --git-path` devolve um
   caminho RELATIVO ao `-C`, e o `[ -d ]` da bancada o lia contra o cwd dela. O (k1) dava verde sem
   enxergar o rebase. Quem denunciou foi o (k2), que montou um rebase parado e mesmo assim acusou "não
   parou". A cura foi `--path-format=absolute` na bancada e no motor; no motor o cwd do trap é o ROOT, mas
   o caminho absoluto não depende disso.
2. **REAL e curado: o (k2) só olhava o desfecho.** O mutante que tira a recusa explícita sobrevivia (veja
   a tabela).
3. **Declarado, não curado:** o mutante equivalente por ordem, da última linha da tabela.

### Fora do alcance (declarado)

O SIGKILL não roda trap nenhum: um kill -9 no meio do rebase continua deixando a worktree em rebase. O
juiz mediu SIGTERM ("mata à força", 1,5 s depois), e a cura cobre o sinal medido. A recusa nomeada do
rebase alheio pelo menos faz a rodada seguinte dizer o que há.

## Os casos

- **(k1).** Num sandbox real, o PR e a main mexem em `docs/backlog.md`, que é projeção. Um `git` de
  mentira no PATH manda SIGTERM ao motor no instante do `checkout --theirs`, com o rebase PARADO no
  conflito. O caso exige: rc≠0, nenhum `rebase-merge`/`rebase-apply`, HEAD igual ao de antes, a branch
  `feat/x` e a árvore limpa. A rodada seguinte, sem limpeza à mão, tem de sair com rc 0.
- **(k2).** O rebase alheio está parado num conflito REAL em `c.txt`. O motor tem de recusar com rc 1,
  nomear "rebase em curso nesta worktree", e o rebase tem de continuar em curso, com o conflito dele.
