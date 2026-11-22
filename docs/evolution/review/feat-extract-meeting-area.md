---
branch: feat/extract-meeting-area
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: 63c3a8861acd838109cd8335efc0f05637374bbfd0e3d4800a0bdf0cf78ec666
reviewed_code_sha256: 2b40d72f3bbe26cb8364febfce3e08be468d663ad72892d539851eaa3afce28f
findings_total: 18
findings_real: 18
findings_blocking: 11
tokens: 289570
duration_min: 12
findings_fixed: 16
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "general-purpose opus, 2 passadas isoladas (refutar) + dogfood da sessão de execução"
nota: "18 = 10 da 1ª passada + 7 da 2ª + 1 do dogfood (o --backlog sobrescrevia o resumo não passado em --summary). tokens e duração somam as duas passadas, lidas no fim de cada agente. findings_fixed 16: o achado 6 da 1ª passada (grafos antigos reprovam) e o 8 em parte viram limite declarado."
---

# Passada adversarial: `feat/extract-meeting-area`

## O que muda

Cards SAC-480 e SAC-488. No gate `meeting-graph-check.sh`: o campo `x_area` (um termo de vocabulário fechado,
do repo ou o padrão de 7 áreas) em toda ação e todo risco; `--summary` reconcilia o resumo executivo com o grafo
pelo id do nó; `--backlog` grava a projeção do backlog por área, com carry-over (`--carry`) das reuniões
anteriores. O comando `/product:extract-meeting` (3.2.0) e o agente `@extract-meeting-specialist` passam a
pedir isso.

## Achados

1ª passada (10):

1. (blocking) Mutante do vocabulário do repo não mordia: o caso reprovava com e sem a cura. Curado (o caso usa o grafo com `produto/tecnico` sob o vocabulário do repo).
2. (blocking) `x_area: tecnico` com a linha seguinte `  produto` passava como `tecnico`; o YAML lê `tecnico produto`. Curado: `ESCALAR-CONTINUADO`.
3. (blocking) `--backlog` sobre o próprio grafo ou o grafo do carry destruía a fonte. Curado: rc 2 para saída que é insumo, não `.md`, ou diretório inexistente.
4. (blocking) A cópia do grafo anterior em outro caminho duplicava os itens. Curado: dedup por `meta.id`.
5. (blocking) Ação fechada sem `verified_at` sumia do backlog calada. Curado: `FECHADO-SEM-MOTIVO` e a seção dos fechados nomeados.
6. (non-blocking) Grafo anterior a este PR reprova com `AREA-AUSENTE`, inclusive no `--for-use`. Limite declarado, com a migração no comando.
7. (blocking) A reconciliação deixava passar comentário HTML, tabela sem barra inicial, seções com outro nome, `•`, recuo de 2 espaços, citação e fato fora da seção do papel. Curado.
8. (non-blocking) Falsos positivos de seção ("Timeline das decisões", "Decisões e riscos", setext, negrito). Curado em parte; ver limites.
9. (blocking) Label em bloco saía como `>-`, e marcação no label saía crua; dava para forjar `— dono:`. Curado: label em bloco reprova, campos antes do texto, texto escapado.
10. (non-blocking) Falha de escrita saía rc 1, igual a reprovado. Curado: rc 2.

Dogfood (1):

11. (blocking) Sem `--summary`, `--backlog docs/meetings/<nome>-extract.md` sobrescrevia o resumo. Curado: só sobrescreve um arquivo que já é projeção (`# Backlog por área: `).

2ª passada (7):

12. (non-blocking) `RESUMO-SECAO-ERRADA` quando o item cita outro fato como referência. Curado: o fato do item é o 1º id; o resto é referência.
13. (non-blocking) Subtítulo dentro da seção zerava a seção (falso positivo e item escondido). Curado: subtítulo sem nome de seção herda a de cima.
14. (blocking) Id repetido em dois itens, parágrafo solto e item seguido de `---` passavam. Curado.
15. (blocking) `x_due`, `x_owner` de risco e `meta.id` iam ao backlog sem validação nem escape. Curado: `CAMPO-FORA-DO-TIPO` no `x_due`, `RISCO-DONO-INEXISTENTE`, escape do id e dos caminhos.
16. (non-blocking) Temporário de nome previsível seguia link plantado. Curado: `mkstemp` no diretório da saída.
17. (non-blocking) Item quebrado em duas linhas com o id na continuação dava falso positivo. Curado.
18. (non-blocking) `ESCALAR-CONTINUADO` em `| # nota`, `|2-` e `&ancora`. Curado.

## Mutantes

Um mutante por cura no `run_meeting_graph_selftests` do `lint-selftest.sh`, cada um nomeando o caso do
`--selftest` que tem de reprovar. Rodado pelo harness da família (a função isolada): os mutantes desta branch
morderam todos; os que deixaram de se aplicar depois da reescrita da reconciliação foram reapontados, e os três
casos que a regra do parágrafo cobria por baixo foram reescritos para distinguir item de parágrafo.

## Depois da revisão

O pré-voo do `pr-finalize` acusou um sítio novo da classe pipefail/EPIPE (`head -n1 | grep -q` na guarda de
sobrescrita); trocado por here-string, sem mudar o comportamento, com o caso e o mutante reapontados.

## Limites declarados

- Grafo de reunião anterior a esta versão reprova com `AREA-AUSENTE` até alguém acrescentar `x_area`; a
  migração está no comando.
- A reconciliação vale para o nível executive; compact, complete e graph não são reconciliados.
- Título que é um item disfarçado (`#### Decisão extra sem nó` dentro de Decisões) não é cobrado como item.
- A série do carry-over é dada por quem roda (`--carry`); o gate não a infere de `docs/meetings/`.
- Item que volta numa reunião seguinte vira nó novo; a marca de novo × reforço fica aberta, com as lacunas 3 e 4
  do teste de campo (nó `Q_MB_OPEN_GAPS_1122`).
