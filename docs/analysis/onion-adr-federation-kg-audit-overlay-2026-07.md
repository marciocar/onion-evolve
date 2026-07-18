---
title: 'ADR — A foto da federação como KG: overlay AUDIT de saúde-de-verificação + radar de federação (não domain-layer forçado)'
date: 2026-07-18
type: adr
status: accepted (finding do dogfood) — o radar de federação é slice de follow-on (design-target)
decision-scope: federation / observability (a "foto da federação" que o maestro pediu — "core não surpreendido")
supersedes: none
extends:
  - knowledge-graph-sdaal.md (as duas camadas audit/domain; planes; radar)
  - rfc/rfc-0003-federated-identity-collective-intelligence.md (members.yaml, trust)
origin-signal: pergunta do maestro 2026-07-18 ("a foto da federação deveria ser um KG?") + Fase 3 do plano de sync de doutrina
deciders: maestro
related:
  - docs/onion/graph/federation-health-2026-07.kg.yaml (o dogfood: 9 nós, radar exit 0)
  - .claude/validation/graph.sh (a estrutura já é grafo — triplas)
  - .claude/utils/co-evolution/reconcile-inputs.sh (o extrator do estado de anúncio)
---

# ADR — A foto da federação como KG

## Contexto (a pergunta do maestro)

*"A foto da federação deveria ser um KG?"* — motivada por "o core não pode ser surpreendido" (granaai e
onion-pessoal evoluindo doutrina em campo; o core precisa da posição da malha antes de agir). Fase 3
dogfood-first: modelar a 1ª `federation.kg.yaml` real e **deixar o radar revelar a ontologia**, sem inventar
tipo antes da prova (doutrina do `/meta:kg`).

## O que o dogfood revelou (`federation-health-2026-07.kg.yaml`, radar exit 0)

A federação tem **dois eixos**, e só um pede um KG novo:

1. **Estrutura** (quem adota quem, tier, trust, pin, linhagem) — **JÁ é grafo**: `graph.sh --triples`
   emite do `members.yaml` (`adopts`/`tier`/`trust-corrects`/`pin`/`lineage`). Não re-modelar.
2. **Estado de verificação** (pin verificado vs declarado, anúncio transportado vs em staging, personalidade
   emergida vs seed manual) — é **`declarado≠verificado` puro**, o wheelhouse da **camada audit**. É AQUI
   que mora o valor "não-surpreendido".

Rodado o overlay audit de saúde, o **ranking de ATENÇÃO do radar surfou exatamente o que o core deve olhar**:
`C_GRANAAI_PIN_UNTRUSTED` (15.0, pin declarado≠verificado), `C_ANNOUNCE_BACKLOG` (12.0, anúncios em staging
não-transportados), metagamify-uncommitted, linhagens indeterminadas, personality-seeds. O radar É o
instrumento de não-surpresa — sem código novo, só modelando o estado como claims.

## Decisão

**Sim, a foto da federação é um KG — mas como overlay AUDIT de saúde-de-verificação, NÃO um domain-layer.**

1. **A federação-KG é camada `audit`** (claims sobre o estado de verificação da malha, eixo `declarado≠verificado`),
   sobreposta à **estrutura que já é triplas** (`graph.sh`). O radar de atenção = "o que o core não pode ser
   surpreendido".
2. **NÃO forçar a camada `domain`.** As relações sociais da federação (`adopts`, `trust-corrects`, `lineage`)
   **não cabem** nos 6 edge-types domain (`HAS_STATE/TRANSITIONS/EMITS/CONSTRAINS/READS/WRITES`) — o dogfood
   **provou a falta** sem inventar tipo. A estrutura fica nas triplas; o KG adiciona o eixo de verificação.
3. **Falta um radar de federação** (`C_FED_RADAR_ABSENT`, o nó de maior atenção, 25.2): os checks de saúde
   — pin declarado≠verificado · anúncio staging-não-transportado · hub sem sub-adotado · linhagem sem pin
   verificado — hoje vivem espalhados (`pin-integrity-check.sh`, `reconcile-inputs.sh`, `/meta:federation-*`),
   **fora do motor KG**. Consolidá-los num radar de federação (que reusa as triplas do `graph.sh` + o
   `reconcile-inputs.sh`) é o **slice de follow-on**.

## Próximos passos (slice de follow-on — design-target)
1. `federation-radar.sh` (ou modo do `kg-radar`): computa os 4+ checks de saúde do `members.yaml` + estado
   de anúncio (extrator = `reconcile-inputs.sh`) → veredito de atenção. Determinístico.
2. Regenerar a `federation-health.kg.yaml` do estado vivo (o overlay audit) — candidato a passo do
   `federation-status` / `co-evolve` do core.
3. `declarado≠verificado`: cada claim de saúde só fecha (`confirmed`) com re-verificação (pin-integrity, transporte confirmado).

## Invariantes
- **Estrutura nas triplas, verificação no audit** — não duplicar a topologia no `.kg.yaml`.
- **Não inventar edge-type de federação** até um dogfood provar que os checks precisam (hoje não precisam — são atenção, não arestas novas).
- **O radar é o instrumento de não-surpresa** — atenção alta = re-verificar, não ignorar.
