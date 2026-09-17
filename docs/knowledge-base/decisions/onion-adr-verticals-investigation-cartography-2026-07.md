---
title: 'ADR — Duas verticais novas no LEGO: investigação (KG + pesquisa) e cartografia de contextos, via SDAAL'
date: 2026-07-03
type: adr
status: provisório (F0 aceito — desenho + gatilhos; construção gated)
decision-scope: meta / verticais / marketplace / sdaal
supersedes: none
extends: onion-adr-exchange-unit-2026-06.md, onion-adr-capability-contract-2026-06.md
deciders: maestro + sessão de evolução
context_freshness: 2026-07-04
related:
  - docs/knowledge-base/concepts/knowledge-graph-sdaal.md (doutrina da espinha da vertical A)
  - `onion-parecer-rhilo-lineages-2026-07` (core-only) (D3 = 1º dogfood do KG — gatilho F1 da vertical A)
  - `onion-intelligent-breadcrumbs-research-2026-07` (core-only) (lastro: estrutura de decisão ✅; armazenamento executável gated)
  - docs/knowledge-base/concepts/domain-context-lifecycle.md (ciclo que a vertical B completa com a operação NAVEGAR)
  - docs/knowledge-base/concepts/onion-relation-vocabulary.md (TBox a estender na vertical B)
  - `onion-adr-exchange-unit-2026-06` (core-only) (anatomia da vertical/plugin — o molde LEGO)
  - `onion-adr-design-peer-promotion-2026-06` (core-only) — ver docs/design-context/decisions/onion-adr-design-peer-promotion.md (critério peer NÃO se aplica aqui; verticais ≠ contextos peer)
---

# ADR — Verticais de Investigação e Cartografia de Contextos

> **Status: PROVISÓRIO (F0).** Este ADR registra o **desenho e os gatilhos** de duas verticais
> propostas pelo maestro (2026-07-03) — não autoriza construir comando, plugin ou util algum.
> Doutrina: gated-until-trigger (a lição do abandono `.onion/`/v4.0 — não construir catedral).

## Contexto

O maestro propôs duas verticais — **investigação** e **mapeamento de contextos** — perguntando se
cabem no "LEGO dos Transformers" usando SDAAL. A exploração confirmou que o encaixe é natural:

- **O LEGO existe e generaliza**: vertical = fonte em `.claude/` → manifesto
  (`.claude/utils/marketplace/verticals/*.manifest.sh`) → `assemble-plugin.sh` → plugin com
  capability contract (`provides/requires/loads` + tier bronze/silver/gold) + provenance +
  guardas de drift (lint REGRAS 19/20 + selftests). `onion-compliance` provou que o molde
  generaliza no mesmo dia que `onion-design` (ADR exchange-unit).
- **Investigação** já tem doutrina pronta (KB `knowledge-graph-sdaal`, candidata, crédito rhilo)
  e gate definido: `/meta:kg` fechado até o 1º dogfood no core.
- **Cartografia** é capacidade genuinamente nova: o `graph.sh` mapeia a **estrutura do framework**;
  o **conteúdo dos contextos de domínio** (`docs/*-context/`) é território sem mapa.

Duas decisões de escopo do maestro (2026-07-03):
1. Investigação = **KG + pesquisa externa juntas** (mais eficiente que separadas), com acoplamento fraco.
2. Mapeamento de contextos = **cartografia nova** (navegar conteúdo), não re-empacotamento do existente.

---

## Decisão A — vertical `onion-investigation`

**O que é:** a capacidade de conduzir investigações longas sem degradar para log cronológico —
achados viram **grafo tipado** (claims/evidence/decisions; arestas SUPPORTS/REFUTES/SUPERSEDES;
planes DEV↔PROD; radar de atenção), e a pesquisa multi-fonte alimenta esse grafo.

**Anatomia (espinha + alimentador, acoplamento fraco):**
- **Espinha**: Knowledge Graph SDAAL — doutrina em
  [knowledge-graph-sdaal.md](../../knowledge-base/concepts/knowledge-graph-sdaal.md) (Tijolo 1 pronto).
- **Alimentador**: `@research-agent` / deep-research — o output de pesquisa é um lote de nós
  `evidence` com confiança, prontos para o grafo.
- **Condição anti-conflito** (por que juntas não conflitam): a pesquisa continua utilizável
  **standalone** — nunca exige o grafo; o grafo a consome quando existe. Acoplamento é pelo
  **tipo de nó** (`evidence`), não por dependência de invocação.
- **SDAAL**: o eixo de provider é o **store do grafo** — `kg-yaml` (arquivo local, determinístico,
  append-mostly) | `none` (Null Object, investigação sem persistência de grafo). Futuro
  `.claude/utils/investigation/` (interface + adapters), **só quando o comando nascer**.
- **Soberania**: NÃO portar `radar.js` do rhilo — cada instância implementa seu motor
  determinístico (decisão da própria KB candidata).

**Rampa gated:**

| Fase | O quê | Gatilho | Estado (2026-07-04) |
|---|---|---|---|
| F0 | Este ADR + capability draft | decisão do maestro | ✅ feito |
| F1 | 1º dogfood do KG na federação (D3: reconciliar pesquisa-da-dose × motor via `wrr-audit.kg.yaml`) | execução na sessão rhilo + **sinal upstream com o resultado** | ✅ **concluído** (sinal `2026-07-04-kg-primeiro-dogfood-federacao` (core-only): 56 nós, 81 arestas, radar sem contradições; inclui **fluxo reverso** — o grafo refutou o framing original PROD→DEV) |
| F2 | `/meta:kg` + store `kg-yaml` no core | F1 concluído + 1ª investigação real do core modelada em `.kg.yaml` | ✅ **executado 2026-07-04** — veículo foi a rodada de `/meta:evolve`: relatório (core-only) + `onion-evolution-2026-07.kg.yaml` (core-only) (37 nós/33 arestas, integridade ✅) + motor soberano `kg-radar.sh` + comando `/meta:kg` nascido da vivência. Interface SDAAL formal (`utils/investigation/`) diferida ao 2º provider real (costura pronta) |
| F3 | manifesto `onion-investigation.manifest.sh` → plugin no marketplace | ≥2 artefatos maduros (mesmo critério que graduou design/compliance) | ⏳ gated |

**Capability draft** (rascunho — vira `capability.json` só na F3):

```json
{
  "provides": ["knowledge-graph-investigation", "evidence-research-multi-source"],
  "requires": ["agent:research-agent", "command:kg", "kb:knowledge-graph-sdaal"],
  "loads": ["when:investigation -> kb:knowledge-graph-sdaal"],
  "conformance": "bronze-alvo-inicial"
}
```

---

## Decisão B — vertical `onion-cartography`

**O que é:** NAVEGAR o conteúdo dos contextos de domínio — impacto/caminho/órfão sobre entidades
de negócio/técnica/compliance ("que features dependem deste cliente?", "que decisão técnica órfã
não rastreia a requisito?"). É a **3ª operação** do ciclo de contexto, complementar às duas que
existem: GERAR (`/docs:build-*-docs`) e VALIDAR (`/meta:context-freshness`). Não duplica nenhuma.

**Mecânica:** a mesma tese do `graph.sh` — grafo **derivado** da spec-as-code, sem store externo
— apontada para `docs/*-context/`. TBox = extensão do
[onion-relation-vocabulary](../../knowledge-base/concepts/onion-relation-vocabulary.md) com
predicados de domínio. Liga com a visão breadcrumbs (estrutura de decisão navegável — a aposta
com lastro da pesquisa 2026-07).

**Relação com a Decisão A (e por que NÃO unificar agora):** cartografia = grafo do **estável**
(contexto consolidado, SSOT viva); investigação = grafo do **disputado** (claims em disputa,
REFUTES/radar). A ponte natural é a aresta `TRACES_TO` e o vocabulário compartilhado — mas a
convergência de store é decisão **pós-dogfood dos dois**, não agora (unificação prematura =
catedral).

**Gate honesto:** no core os contextos são templates vazios (1 README cada) — **não há o que
cartografar aqui**. Sem conteúdo, qualquer comando nasceria não-dogfoodável.

**Rampa gated:**

| Fase | O quê | Gatilho | Estado (2026-07-03) |
|---|---|---|---|
| F0 | Este ADR + capability draft | decisão do maestro | ✅ feito |
| F1 | 1º dogfood da cartografia | adotante com contextos populados (candidato natural: **um adotante** — 3 contextos ativos, 5+ meses de sessões) OU core popular contexto próprio | ⏳ gated |
| F2 | comando de cartografia (nome a decidir no dogfood) sobre o motor `graph.sh` estendido | F1 revelar as consultas que importam | ⏳ gated |
| F3 | manifesto → plugin | ≥2 artefatos maduros | ⏳ gated |

**Capability draft:**

```json
{
  "provides": ["domain-context-cartography"],
  "requires": ["validation:graph.sh", "kb:onion-relation-vocabulary", "kb:domain-context-lifecycle"],
  "loads": ["when:context-mapping -> kb:domain-context-lifecycle"],
  "conformance": "bronze-alvo-inicial"
}
```

---

## O que NÃO fazemos agora

- **Nenhum comando** (`/meta:kg`, cartografia) — F2 de cada rampa.
- **Nenhum util** (`.claude/utils/investigation/`) — junto com o comando.
- **Nenhum manifesto/plugin** — F3, atrás de maturidade real.
- **Nenhuma promoção a peer** — verticais ≠ contextos peer (o critério dono×ritmo×decisão do
  `architecture.md §8` não está em jogo aqui; investigação e cartografia são **capacidades**,
  não dimensões).

A identidade manda (onion-review-2026-05.md (core-only)): construir à frente do
gatilho foi o erro do plano v4.0. Este ADR é o anti-v4.0 — desenho registrado, construção gated.

## Consequências

- O D3 do rhilo deixa de ser só "reconciliação de linhagens" — é o **F1 da vertical A**. Quando o
  sinal upstream chegar (📬), a triagem via `/meta:co-evolve` deve reconhecê-lo como disparo de gate.
- A cartografia ganha um destino nomeado para a visão breadcrumbs/LLM-as-VM sem virar projeto
  especulativo: o gatilho é conteúdo real, não beleza arquitetural.
- Quando qualquer rampa atingir F3, o marketplace ganha a 3ª/4ª peça — e o padrão exchange-unit
  é re-validado com verticais de natureza diferente (conhecimento, não domínio de engenharia).

## Histórico

| Data | Mudança |
|---|---|
| 2026-07-03 | F0: desenho aceito pelo maestro; F1 da vertical A em execução (sessão rhilo) |
| 2026-07-04 | F1 da vertical A ✅ (sinal upstream do rhilo, triado e confirmado); F2 🔓 aberto aguardando veículo. Decisão de triagem: NÃO vendorizar `scripts/kg/` do rhilo (soberania mantida) |
| 2026-07-04 | **F2 ✅ executado** — veículo: rodada `/meta:evolve` (16 achados, 7 refutações modeladas como REFUTES). Nasceram `/meta:kg` + `kg-radar.sh`. Dogfood do motor pegou 7 órfãos na 1ª modelagem (lição incorporada ao comando). Falta na vertical A: só F3 (plugin, gated ≥2 artefatos maduros — agora há 2: comando+radar; o gate pede MADUROS, i.e. uso repetido) |
