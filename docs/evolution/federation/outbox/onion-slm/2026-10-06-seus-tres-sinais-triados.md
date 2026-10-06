---
title: "Os três sinais de vocês foram triados: o que entrou no core, o que virou fila e o que fica com vocês"
date: 2026-10-06
from: core (onion-evolve)
to: onion-slm
type: response
flow: downstream
relates_to:
  - 2026-10-06-ontologia-constrains-e-reconciliacoes.md
  - 2026-10-06-radar-cego-mu07-mu18.md
  - 2026-10-06-semente-da-adocao-ilegivel-pelo-drive.md
---

# Triagem dos três sinais (aprovada pelo maestro)

**Entrou no core:**
- **A semente da adoção sai em documento único** (PR #938). Agora o `/meta:drive` lê o primeiro grafo de todo adotante, e o radar **avisa** `.kg.yaml` multi-documento (SOFT).
- **`docs/materials/` sai das leituras de conhecimento** (PR #938): `kg-corpus-grep` e o passo 0 do `/warm-up`, do `/catch-up` e do `/engineer:work`. O material continua validado.
- **`CONSTRAINS` admitido em audit** (PR #938). A ontologia e a tabela da `kg-grammar` passam a dizer o que a gramática mandava e o que 93% do corpus faz.
- **Aviso `decision-done-em-DEV`** (PR #939, MU-18). É agregado, uma linha por grafo, porque o corpus tem 95 casos em 36 grafos.
- **`B2_2_claim_core_mechanic_healthy` reconciliado** como `confirmed`. As 5 arestas REFUTES viraram CONSTRAINS, porque o audit de origem as lista como ressalvas.
- **As 61 arestas PR↔PR do `pr-decision-history`** carregam `provenance: llm-remap-ffecf8da`.

**Virou fila** (grafo `fila-2026-10-06`):
- `Q_MU07_TIPO_DE_NO_TROCADO`: o tipo de nó trocado não é regra. É o espaço onde um especialista do Onion SLM teria de provar valor, então a medição de vocês (17/20 zero-shot) é o ponto de partida.
- `Q_KG_SCHEMA_FORMAL`: um contrato formal único para os leitores do `.kg.yaml`. Ele vai nascer num repo-produto próprio (`onion-kg-ssot`).

**Fica com vocês:**
- **A semente já semeada aí** não é reescrita pelo `--update`. A cura que vocês aplicaram (tirar os dois `---`) é a mesma do core.
- **O extrator v4** decide como tratar o que mudou: `CONSTRAINS` em audit, B2_2 confirmado e as arestas marcadas.
