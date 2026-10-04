---
reviewed_diff_sha256: 2ee6fc0b06d9011b4f24fced54672aba370b81518bbf2f2cc6c98e733e239dd9
findings_total: 7
findings_real: 7
tokens: 121682
duration_min: 37
verdict: APROVADO
elenxo: sim
nota: >
  Elenxo opus em worktree isolada REPROVOU a 1a versão com três blockers: projeções desatualizadas
  (6 HARD, do checkpoint feito com --no-verify), a doutrina se contradizendo sobre o STATE.md, e a
  escrita do pending sem mecanismo. Os sete achados foram curados ou declarados; cinco mutantes
  novos mordem. APROVADO é o estado depois das curas.
---

# Resíduo — `fix/drive-checkpoint-in-graph`

A cura 4 da rodada do `/meta:evolve` de 2026-10-04: o checkpoint do lote do `/meta:drive` sai do
`STATE.md` gitignorado e passa a morar no grafo, onde o censo o cobra.

## O que o refutador derrubou, e o que foi feito

| # | sev | achado | desfecho |
|---|---|---|---|
| B1 | blocker | 6 HARD de projeção desatualizada (plugin, backlog, harness, painel, índice de leitura) | curado — o commit final passa pelo gate, que regenera; o checkpoint anterior tinha usado `--no-verify` |
| B2 | blocker | a doutrina se contradizia: o STATE.md virou "rascunho", mas a 4ª precondição da exceção de selo mandava nomear o flip nele | curado — a 4ª precondição virou a `drive_checkpoint_note` e foi **mecanizada** no `kg-seal-exception.sh` (casos a4/a5) |
| B3 | blocker | nada escrevia `pending`; ausência conta como selado | curado em parte — `kg-drive-project.sh --close-lot`/`--seal`; **segue social a sessão chamar o comando**, declarado na Honestidade do drive |
| R1 | rec. | o awk errava em 7 formas YAML válidas | curado — leitura e escrita por YAML, relidas antes de gravar |
| R2 | rec. | o limite "só o bloco meta" não tinha caso | curado — caso da chave citada no meta e num label |
| R3 | rec. | o nó superado tinha um 3º sítio não curado (`cycle-completion.sh`) | registrado — nó `Q_CYCLE_COMPLETION_MEDE_RECENCIA_PELO_STATE`, open, com gatilho |
| O | opp. | o flip do nó da rodada (já selado no main) passou por `supersedes_external` | **o maestro vê aqui**: o selo é o merge deste PR |

## Mutantes (5/5 mordem)

Leitura por texto (o awk de volta) · `pending` ignorado · `--close-lot` não grava · a (4) sempre OK ·
a (4) por substring.

## O que não foi verificado

Dois lotes concorrentes no mesmo grafo vindos de worktrees diferentes; o modo projeção em grafo real.
