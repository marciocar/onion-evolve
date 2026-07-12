---
date: 2026-07-12
instance: onion-evolve
type: learning
classification: protected
tags: [behavior-sensor, intake-execucao, consent, kg-dogfood, discussion-worktree]
affects: [engineering, compliance, product, meta]
breadcrumb_for: [meta:kg, discuss:onion-pessoal-marcio]
share_with: []
next_recommended: "docs/discussions/behavior-mapping-kg/README.md (índice da frente)"
review_after: 2026-10-10
conflict_class: static
---

## Signal
A frente isolada `discuss/behavior-mapping-kg` estabeleceu como a doutrina de autorização do Onion se
estende a um **sensor de comportamento**: mapear consentido ≠ vigiar, e a linha intake↔execução vira
**TRÊS gates** (observar / inferir / agir) — com a **inferência sendo ela mesma um gate regulado**
(SCHUFA). O padrão pesquisa-citada-antes-de-posição + um proto `kg-radar` verde por nota se sustentou
nas 5 notas. A decisão de produto (Q5) foi deixada **aberta** — não decidir pelo maestro.

## Evidence
- **5 notas (Q1–Q5) + 5 sínteses citadas (~80 fontes, verificação adversarial) + 5 protos kg-radar verdes**; índice em `docs/discussions/behavior-mapping-kg/README.md`. Tudo isolado em `discuss/*` não-pushada (nada foi ao core).
- **Q1** — mapear consentido ≠ vigilância pelos 4 eixos (finalidade/transparência/agregação/controle); dupla autorização (pessoa **E** org); a **inferência** é a lacuna que o consentimento na captura não fecha (Staab et al., ICLR 2024).
- **Q2** — a inversão+multiplicação da linha `authorization-layers`: para um sensor, **observar já é o gate** (não "guardar é livre"), e **derivar/perfilar já é ato regulado** — âncora dura: **SCHUFA (TJUE C-634/21, 2023)**, "derivar um score já É a decisão automatizada". Convergência forte: o estado-da-arte 2026 (tiered autonomy, gatear pelo side-effect, autorização determinística downstream) **reencontra** a doutrina que o Onion já tem (VETO-não-SKIP, propose-only, gate determinístico).
- **Q3/Q4** — local-first (o bruto nunca sai; "não-retenção > cifra"); passiva **E** declarada, o say-do gap vira aresta `REFUTES`; ontologia bruto→KG **object-centric** (OCEL/Event Knowledge Graph = o `entity`/`event` do KG SDAAL, sem achatar); inferência vira `claim` (audit), não `event`.
- **Q5** — recomenda **sensor-como-capability** do Onion pessoal (produto standalone conflita com a identidade canônica); proto de decisão deixa `D_SENSOR_AS_CAPABILITY` com `status: open`.
- **Lição operacional (método):** a 1ª orquestração via ferramenta Workflow com `research-agent`+schema forçado **flakou — 3 de 4 frentes devolveram stub de teste / estouraram o retry-cap**. Recuperei a frente boa do `journal.jsonl` e **re-rodei como agentes `general-purpose` diretos com WebSearch, sem schema rígido** — robusto. Para pesquisa web citada, preferir agente direto a `research-agent`+schema.

## Next crumb
Se a frente for revisitada/promovida: o desempate é a **decisão aberta da Q5** (`D_SENSOR_AS_CAPABILITY status:open`) — escolha de rumo do maestro, não de execução. O modelo **"três gates" é candidato a KB** (herdaria `authorization-layers-intake-vs-execution`) SE sair da discussão — mas **nada promove ao core sem o maestro pedir**. A lição de método (agente direto > research-agent+schema para pesquisa citada) vale para as próximas frentes.
