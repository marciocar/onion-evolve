---
title: 'Resíduo — a rodada parou de fabricar citação e passou a fabricar medição'
date: 2026-09-21
branch: feat/radar-e3-r5
reviewed_diff_sha256: 9707fb096dc82e2f524cdd7dda110758907a6f8da0a8271c05b5efdd57e3c5f3
tokens: 185507
duration_min: 13
findings_total: 11
findings_real: 11
findings_fixed: 11
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Refutador opus em WORKTREE ISOLADA sobre o resultado do radar E3 r5. REPROVOU com 11 achados
  reais, incluindo o nó-manchete errado em versão, magnitude e conclusão. Todos curados.
---

# O refutador reprovou a rodada inteira, e tinha razão

A rodada 5 do radar E3 rodou 47 agentes e um juiz adversarial por achado, e fechou com descarte de
2/41 — que eu li como sinal de qualidade. A passada adversarial mostrou que era o contrário: **a
rodada aprendeu a não fabricar citações e passou a fabricar medições do próprio repo**, categoria
que o juiz só pegou uma vez.

## O nó-manchete estava errado nas três dimensões

| eu afirmei | a medição |
|---|---|
| desligamento das task tools na **2.1.268** | **2.1.233**, 35 versões antes da janela |
| **551** ocorrências dependentes | **83 / 0 / 0 / 0** |
| superfície "nasce morta e em silêncio" | ferramenta some, **artefato roda** (8,9 s, medido) |
| propor religar a variável no repo | o corpus diz *"religar por reflexo pode PIORAR"* |

As contagens vieram de `grep -rl … | wc -l` — **arquivos**, publicados como "ocorrências" — somando
`.claude/worktrees/` de **outros agentes**, com `TaskList` casando dentro de `getTaskList`.

**A causa tem nome:** pulei o `kg-corpus-grep.sh` que a `research-lens` exige. O corpus já media
isto por **dogfood** desde 2026-08-16, com a conclusão oposta à minha.

**E o agravante é de desenho, não de descuido:** o juiz desta rodada **acertou** — o campo
`correcao` em `data/f1-scan-juizo.json` diz verbatim que *"o delta não é o desligamento em si (isso
o corpus já mediu em 2.1.233)"* — e eu escrevi o nó **depois** dele, descartando a correção. Juiz
cujo veredito o escritor pode ignorar não é gate; é opinião. Fica como classe a curar.

## Dois "achados" que não eram desta janela

`claude ultrareview` existe desde a **2.1.111**; `claude respawn`, desde a **2.1.251**. Eu os
apresentei como novidade do vendor. O primeiro virou "colisão de calendário"; o segundo, achado de
**uso** — a casa gastou uma decisão do maestro (quando encerrar a sessão por deriva de versão) num
problema que já tinha comando.

## Os 11, e onde cada um parou

1. versão errada no nó-manchete — **nó reescrito**
2. contagens fabricadas — **medidas de novo, com `-w` e sem worktrees**
3. contradiz o corpus sem reconciliação — **nó novo cita o dogfood de 08-16**
4. "morta e em silêncio" não sobrevive à medição — **corrigido nos dois artefatos**
5. lição de método falsificada pelos próprios dados — **reescrita: a fabricação mudou de porta**
6. painel derivado de arquivo **não-commitado de outra sessão** — **revertido**
7. `respawn` não é delta — **vira achado de uso**
8. `ultrareview` não é delta — **colisão é de calendário**
9. `gateway` na síntese sem nó — **removido**
10. 15 vs 18 hooks — **18 entradas / 15 scripts / 6 vetos, dito**
11. terceira medição fabricada aprovada pelo juiz — **entra no nó de método**

## O que sobreviveu à refutação

`E_TIMEOUT_AUSENTE_EM_7_HOOKS` — 11 de 18 entradas com `timeout`, 7 sem, dois deles os vetos `exit
2` de PreToolUse; o refutador conferiu os sete nomes. **É o melhor nó da rodada, e veio do juiz
derrubando um achado.** Também: as 88 regras de auto-mode, os achados de plugins/workflow/custo
(verbatim e na versão certa), o `claude-help` idêntico ao binário vivo, a baseline bem selada, e
`E_EXIT_2_INALTERADO_NA_JANELA` como **ausência medida** — o refutador varreu as 26 linhas com
"hook" do delta por conta própria.

## Defeitos meus de processo, nesta mesma perna

- **`git add -A` varreu o arquivo de outra sessão** (`feat-reviewer-findings-block.md`), justamente
  o que eu havia declarado que não tocaria. Tirado do stage; passei a `add` seletivo.
- **Usei `git stash` como sonda de medição com trabalho não-commitado na árvore.** O comando estourou
  600 s, foi para segundo plano, e a árvore ficou vazia até o `pop`. Nada se perdeu, mas o certo era
  medir a linha-base numa worktree destacada — que eu já sei fazer e não fiz.

## Declarado, não absorvido

A única HARD restante é **REGRA 81 (Painel de estado é GERADO dos produtores, nunca redigido)**, e
ela é artefato de concorrência: o produtor lê a árvore, e outra sessão sua tem
`feat-reviewer-findings-block.md` em edição. Provei numa worktree limpa do HEAD que o produtor
devolve os mesmos números do painel commitado (1645/1402/122003) — no CI, que faz checkout limpo,
passa. Não commito o painel: seria subir projeção cuja fonte não está no commit.
