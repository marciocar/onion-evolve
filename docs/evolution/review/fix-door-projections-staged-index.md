---
title: 'A porta regenerava antes de saber o que tinha, e a minha cura piorou o silêncio'
date: 2026-09-28
branch: fix/door-projections-staged-index
reviewed_diff_sha256: 5ac2eb83aaf3c7ab9a5ea0c7c17112a8962aa893b0956e71cb4a1ac6982e67ac
elenxo: sim
findings_total: 11
findings_real: 11
verdict: REPROVADO_E_CURADO
tokens: 160367
duration_min: 27
agents: 1
nota: 'Refutador opus em worktree ISOLADA (fronteira, não instrução em prosa), mandato REFUTAR, default REPROVADO. Veredito: REPROVADO — 3 bloqueantes, 3 a corrigir, 1 informativo, 6 ângulos refutados por medição. As 3 bloqueantes estão curadas e re-medidas; a mais grave é uma REGRESSÃO que eu introduzi (de 2 projeções faltando para 5, em silêncio). Somam-se 4 erros MEUS de medição, todos do mesmo formato — medir num caminho e concluir sobre outro. O revisor semântico do CI segue fora por saldo da conta de API; o Elenxo aqui foi subagente local, não o gate do forge.'
---

# Resíduo — a porta regenerava antes de saber o que tinha

## O defeito, e como ele estava publicado

`ops/materialize-door.sh` roda `regen-ssot-projections.sh` contra o destino no passo (6). Duas das
cinco projeções — `testing-inventory.md` (via `harness-inventory.sh`) e `testing-state.md`, que
depende dele — enumeram o conjunto **RASTREADO** (`git ls-files`), não o disco. Isso é deliberado e é
cura de um defeito anterior: contar o disco enumeraria um conjunto diferente do que o CI vê.

O corolário nunca foi cumprido: elas precisam de um índice que já contenha o que acabou de ser
materializado, e o único `git add -A` do script era uma **instrução impressa ao humano**, executada
depois. Medido em 2026-09-28:

| onde | `testing-inventory.md` / `testing-state.md` |
|---|---|
| `onion-core` (porta) | presentes |
| **`onion-standalone` (porta pública)** | **AUSENTES** |
| `origin/main`, materializando fresco | **AUSENTES** (2 de 5) |

Ou seja: defeito **em produção**, reproduzível em `main`, com o materializador saindo `rc=0` e
dizendo "✅ Porta materializada". Pré-existente ao PR que o expôs — e o core cura em vez de devolver.

## O que o expôs, e por que só agora

O caso de bancada `door: (f)` ficou vermelho porque a cura do `_die`-em-subshell (PR anterior, mesma
sessão) trocou um fail-open por recusa de verdade no `harness-inventory.sh`. Antes, o gerador
fail-openava e emitia um inventário zerado — arquivo **não-vazio**, logo a bancada passava. A guarda
nova está certa; o **harness e o materializador** estavam incompletos. Classe já nomeada nesta casa:
trocar dependência para fail-closed quebra todo harness que copiava o motor sem ela.

## A regressão que EU introduzi, e que o refutador derrubou

Minha 1ª cura stajava o destino antes de regenerar. Mas o passo (0) apaga `docs/onion/` (que não
viaja no manifesto) **imediatamente antes**, então aquele `add -A` stajava a **REMOÇÃO** das 5
projeções; os geradores as reescreviam depois, como untracked. Quem publica com `git add -A; git
commit` (o caminho impresso pelo script) não sente. Quem usa `git commit -am` — plausível em 18
re-materializações — publicaria a porta com **ZERO** projeções.

Verificado por mim, de forma independente, antes de aceitar o achado:

```
1ª materialização → commit v1 → projeções no commit: 5
2ª materialização → status: D docs/onion/{graph,inventory,kg-read-index,testing-inventory,testing-state}
                  → git commit -am → projeções no commit v2: 0   (esperado 5)
```

De "2 faltando" para "5 faltando", **e mudo**, porque os arquivos ficam no disco: inspeção visual da
árvore não mostra nada. Estritamente pior que o defeito curado.

## Os 11 achados

| # | achado | severidade | estado |
|---|---|---|---|
| 1 | `door: (h)` reprovaria em clone fresco: `.claude/worktrees/` não é rastreado nem existe no CI, então a pré-condição do pai dispara primeiro com OUTRA mensagem | BLOQUEIA | curado — destino na raiz do repo; mutante reprova, real passa |
| 2 | `git add -A` e `git init` sem checar rc = fail-open no ponto exato que a cura resolve (`set -e` não está ligado) | BLOQUEIA | curado fail-closed; `index.lock` plantado → rc=3 |
| 3 | o `add -A` stajava a deleção de `docs/onion/`; `git commit -am` publicaria 0 projeções | BLOQUEIA | curado: 2º `add -A` + verificação por CONTAGEM; medido 5/5 no commit |
| 4 | a 2ª metade do `(h)` era vácua no ambiente onde roda (`.git/info/exclude`, arquivo não versionado) | corrigir | mesma linha do 1 |
| 5 | o `add -A` apaga do índice o WIP stajado-não-commitado do dono do destino (o índice era a última rede; o passo (0) já apagava do disco) | corrigir | aviso explícito quando o índice do destino já divergia do HEAD |
| 6 | `git init` criava `master`; o remoto da porta é `main` — e morde só o caminho greenfield, que é o que o `init` existe para cobrir | informativo | `init -q -b main`; medido `branch=main` |
| 7 | **afirmação minha FALSA**: "o `\|\| true` do `_regen` engole a recusa". Não engole — o regenerador sai 0 com 3 de 5 e **imprime** "saída VAZIA". O defeito foi aviso IGNORADO | informativo | comentário corrigido |
| 8–11 | quatro erros MEUS de medição (abaixo) | — | três viraram comentário no código, um virou o caso (h) |

## Os quatro erros meus de medição, todos do mesmo formato

Medir num caminho e concluir sobre outro:

1. Chamei de "66 casos, 0 falhas" o resultado de `--affected-staged`, que mede só as famílias tocadas
   pelo diff. A bancada inteira tem 1502 casos, e um deles estava vermelho.
2. Rodei o mutante **do hospedeiro**, onde o script aborta antes do passo medido → "não contaminou".
3. Pus o mutante no scratchpad; o script resolve `REPO_ROOT` pela **própria localização** e abortou em
   `vendor-manifest.sh ausente` → nunca chegou ao passo medido.
4. O predicado de aninhamento comparava o toplevel do **pai** com o próprio pai — iguais SEMPRE.
   A guarda nunca disparava no caso mais comum (destino novo dentro de um repo), e só o mutante, com
   630 arquivos stajados no hospedeiro, mostrou isso.

## O custo que eu paguei em mim

Rodar o mutante contra a árvore viva stajou **630+ caminhos da porta no índice do core** — exatamente
o dano que a guarda existe para impedir. Limpei (`git reset` dos caminhos de sonda; status conferido).
Mutante que exercita um efeito destrutivo pede destino descartável, não a árvore de trabalho.

## Fronteira deliberada (o que NÃO mudei, e por quê)

O `regen-ssot-projections.sh` continua degradando gracioso — o `|| true` fica, e a decisão está
escrita no próprio script: gerador que falha por ambiente do ALVO não deve derrubar uma adoção, e o
lint de lá cobra depois. Quem passa a **verificar o efeito** é o materializador, no caminho da porta,
onde publicar vermelho é o dano real. Tornar o regenerador fail-closed contrariaria uma decisão
datada sem medir o custo no adotante.

## NÃO-VERIFICADO (declarado, não resolvido)

- **Disputa de observável compartilhado no caso (h).** Ele lê `git status --porcelain` do
  `${REPO_ROOT}` inteiro, sob `--jobs auto` em faixas paralelas. O refutador **não reproduziu** o
  falso-✗ (a recusa aborta em ~0,15s), mas o risco é estrutural e a cura do achado 1 não o remove.
  O repo já pagou essa lição uma vez (um caso foi movido para `mktemp` por disputa com `--jobs`).
  Gatilho: se o `(h)` piscar vermelho sem mudança no artefato, o destino vira `mktemp` com hospedeiro
  próprio.
- **Submódulo como destino**: não montado. Pelo desenho o `--show-toplevel` de um submódulo devolve
  ele mesmo, então passaria — e passar é correto, o índice é próprio. Não medido.
- **CI do repositório**: `startup_failure` em rajada desde 2026-09-26, inclusive em `main`. Este PR
  não teve check nenhum; a cobertura é o gate determinístico local, exercido pelo escape nomeado.
