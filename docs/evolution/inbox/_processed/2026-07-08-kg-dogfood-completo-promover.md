---
tipo: sinal-upstream
data: 2026-07-08
origem: rhilo-metagamify (branch audit/oraculo-integration)
assunto: KG-SDAAL — dogfood completo; propor promoção ao core e des-gate do /meta:kg
relacionado:
  - docs/evolution/inbox/_processed/2026-07-02-sdaal-knowledge-graph.md
  - docs/evolution/inbox/_processed/2026-07-04-kg-primeiro-dogfood-federacao.md
  - docs/knowbase/concepts/knowledge-graph-sdaal-spec.md
---

# Sinal: o KG-SDAAL passou do proto-audit para SSOT de domínio — promover ao core

## O que aconteceu (o dogfood, agora completo)

O que nasceu como grafo de **auditoria** (WRR dose/limbo) evoluiu, neste ciclo, para um **alicerce de SSOT de
domínio**. O `/meta:kg` estava *gated* ("fechado até o core dogfoodar o método uma vez"). **Este é esse dogfood** —
e ele foi além do previsto:

1. **Camada de domínio** (`layer: domain`) coexistindo com a de auditoria no mesmo `.kg.yaml` — ontologia
   `ENTITY/STATE/EVENT/RULE|INVARIANT/POLICY` + `HAS_STATE/TRANSITIONS(on)/EMITS/CONSTRAINS/READS|WRITES/TRACES_TO`.
   Dogfooda o `ElementLink` do produto (mesmo formato/motor).
2. **4 fatias de domínio** modeladas e ancoradas no código: ciclo do SLOT, integração Urano (PULL),
   máquina de estados de SLA, e o dicionário ubíquo cross-repo.
3. **radar-de-domínio**: checagem de completude (estado-absorvente, EVENT-sem-efeito, STATE-sem-dona,
   RULE-sem-trace) — fez o **SLOT-limbo emergir do modelo** (bug estrutural, não achado de auditoria).
   Modo `--triples` para consumo por LLM.
4. **Fase-2 semântica** (`scripts/kg/reconcile.js`): embeddings MiniLM (via `libs/ml-engine`) + cosseno flagam
   redundância — detectou sozinho o cluster do limbo. A Fase-2 deixou de ser gap.
5. **Visualizador** interativo self-contained (`scripts/kg/viz.js` → HTML/Artifact).

Resultado: 111 nós / 170 arestas, radar sem contradições, 3 decisões prontas para o negócio (RHILO) vivas
no grafo (`D_ENABLE_DESAT`, `D_ABANDON_DETECTOR`, e agora `D_PROMOTE_CORE`).

## Proposta ao core

1. **Des-gate o `/meta:kg`** — o pré-requisito ("dogfoodar uma vez") está cumprido, com folga.
2. **Promover ao core o SCHEMA + o método**, não o código (soberania — decisão de federação já registrada em
   `2026-07-04-kg-primeiro-dogfood-federacao.md`): a ontologia de 2 camadas (audit + domain), os tipos de nó/aresta,
   as 5 checagens de domínio do radar, e o padrão Fase-2 (embeddings do `ml-engine`).
3. **Adotar a distinção epistêmico×domínio** como padrão do Onion: grafo de auditoria (efêmero, DEV/PROD, append-mostly)
   que **`TRACES_TO`** o grafo de domínio (durável, SSOT). Foi o que evitou o inchaço.

## Ressalva

O `.kg.yaml` desta instância mistura audit + domain no mesmo arquivo (via `layer`) por pragmatismo. Ao promover,
avaliar se o core quer **arquivos separados** (`*.domain.kg.yaml` / `*.audit.kg.yaml`) com `TRACES_TO` cross-arquivo,
ou manter o campo `layer` (reusa o parser/radar como está). Recomendo começar com `layer` (menos maquinário) e
separar só se a escala pedir.

— Rode `/meta:co-evolve` para triar este sinal.
