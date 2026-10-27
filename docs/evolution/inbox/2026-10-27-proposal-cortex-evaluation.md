---
title: "Avaliação do Cortex contra o Onion (proposta: costurar o gate de plano, a âncora única na mutação e a geração de pptx e docx; parquear a frota e o registro de uso; rejeitar quatro áreas)"
date: "2026-10-27"
from: onion-curation
merged_at: "main 699b7e7 (PR #131)"
to: onion-evolve
type: dissect-proposal
kg: docs/evolution/dissect/cortex-2026-10/cortex-2026-10.kg.yaml
piece_nodes: [D_PIECE_DISTRIBUTION, D_PIECE_FLEET, D_PIECE_PLAN_GATE, D_PIECE_SPEC_AS_CODE, D_PIECE_DOCS_PRESENTATIONS, D_PIECE_STUDIES, D_PIECE_USAGE_TELEMETRY, D_PIECE_MEMORY, D_PIECE_QUALITY]
---

# Sinal: avaliação do Cortex (família ferramenta)

> Pedido do maestro. O relatório completo está em `EVALUATION-REPORT.md`, revisto por uma revisão adversarial separada
> com 6 objeções aplicadas. A palavra final é do core, peça por peça.

## Propostas por peça

| peça | veredito | nota | resumo |
|---|---|---|---|
| gate de plano antes do código | **costurar** | 8 | exit 2 se o plano não estiver commitado no HEAD antes do 1º commit de código (`fleet-phase-gate.sh:136-156`); no core isso só existe para estudos |
| qualidade (mutação) | **costurar** | 7 | âncora única e três saídas (`mutate.py:20-30`) no `ops/mutate-and-restore.sh`, que hoje confunde "não aplicou" com "sobreviveu" (`:55-61`); a defesa contra sinal continua sendo a do core |
| documentação e apresentações | **costurar** (condicionado) | 6 | pptx e docx com print real e relatório executivo do git, como vertical opcional, depois de uma rodada de prova autorizada |
| frota | **parquear** | 5 | N issues em worktrees paralelas com aprovação humana em lote não têm par, mas nenhum adotante pede isso |
| registro de uso | **parquear** | 5 | a telemetria nativa do Claude Code em OpenTelemetry já cobre o uso, com coletor; a forma do Cortex grava dentro do git com o nome de quem rodou |
| distribuição | **rejeitar** | 4 | o merge do `onion/vendor` faz melhor (superação lida, não medida) |
| especificação como código | **rejeitar** | 3 | 104 regras de lint (`grep -oE 'REGRA [0-9]+' lint-artifacts.sh \| sort -u \| wc -l`) e o contrato do grafo, contra um prompt que não bloqueia por padrão (superação lida) |
| estudos e avaliações | **rejeitar** | 3 | `/onion-research` e `/meta:dissect` (superação lida) |
| memória e sessões | **rejeitar** | 4 | o grafo como fonte da verdade em tempo de execução, o worklog e o `/catch-up` (superação lida) |

- **Absorver no núcleo:** nenhuma peça. Nenhuma tem uso medido em dois ou mais adotantes.
- **Gatilhos dos parques:**
  - frota: `--around <grafo>#Q_FLEET_PARALLEL_DEMAND --edge-type SUPERSEDES`, com `min_count: 2`;
  - registro de uso: `--around <grafo>#E_NATIVE_OTEL_USAGE --edge-type SUPERSEDES`, com `min_count: 2`.
  Hoje os dois dão 1, e nenhum disparou.

## Confidencialidade

O Cortex mora no repositório de um cliente. Só o framework foi lido. Nenhum dado do cliente nem nome de pessoa do time
entra neste sinal ou no estudo.
