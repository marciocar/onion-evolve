---
title: 'Síntese — matriz role→(verticais + work_tools) da família Onion (pesquisa orquestrada)'
date: 2026-07-19
type: research-synthesis
status: active
run_id: wf_ab57a814-c16
method: fan-out-and-synthesize (4 frentes sonnet + síntese opus)
related:
  - docs/analysis/onion-adr-family-repo-topology-2026-07.md
  - docs/analysis/onion-door-birth-findings-2026-07.md
  - .claude/utils/marketplace/roles.yaml
---

# Matriz role→(verticais + work_tools) — veredito da pesquisa

Nascida do nascimento da porta pública `onion-standalone`: descobriu-se que o bundling sub-selou
(tratou TODO `commands/meta/` como meta-fábrica). Pesquisa orquestrada de 4 frentes (motor vivo · KG-SSOT/
constelação · business/funil · externo-Anthropic 2026) para validar a matriz por tier + o reframe do maestro,
**antes** de codificar em `roles.yaml`.

## Veredito central

**O reframe do maestro está SUSTENTADO — convergência tripla (motor + doutrina + mercado), sem ambiguidade.**

- **Motor:** `standalone.base == hub.base` e `optional` **byte-a-byte idênticos** (`roles.yaml:20-25`). A
  ÚNICA diferença hub↔standalone é **trust/downstream** (= "com federação" vs "sem"), não capacidade —
  exatamente o reframe. Os tiers T0/T1/T2/T3 batem número-a-número com `.claude/utils/trust/types.md`.
- **Doutrina:** D4 (`roles.yaml:17`) separa meta-fábrica (`create-*/adopt/federation-*/evolve/graph/inventory`)
  de ferramentas de trabalho — ortogonal ao reframe.
- **Mercado (Anthropic-aware, jul/2026):** a Anthropic separa na MESMA junta — Agent Skills rodam plenas em
  qualquer plano pago **individual** (sem taxa por plugin), enquanto **marketplace + auto-install por grupo**
  é gated a **Team/Enterprise** (a camada de distribuição/governança = federação). Cline/Cursor/Copilot
  replicam (individual pleno via BYOK vs seat-based team). **Land-and-expand** (Datadog): o gatilho de
  expansão é a **chegada do MULTI** (2º repo/2ª pessoa), não o uso individual crescer.

## Mas: a matriz está estruturalmente incompleta + tem 1 bug vivo

- `roles.yaml` só modela bundles como listas de **verticais** (`base/optional`) — **não há eixo para os
  ~16 work_tools** de `commands/meta/`; nenhum dos 6 manifestos referencia `commands/meta` (grep vazio).
  "standalone = ferramenta completa" é verdade **doutrinária ainda não materializada** pelo motor.
- **BUG VIVO CONFIRMADO:** `engineer:work.md:24` cabeia `bash .claude/validation/kg-radar.sh` no passo-0
  KG-first, mas `onion-engineering.manifest.sh` tem `VALIDATION=()` vazio → todo standalone montado herda
  uma **referência morta** (o assembler só copia+reescreve paths listados em `VALIDATION[]`).
- **Contagem:** são **16** work-tools (não ~17). Reconciliar.

## Decisões por célula

| Célula | Decisão | Razão |
|---|---|---|
| `inventory` (comando) no standalone | **WITHHOLD** (core-only) | meta-fábrica por D4; regenera a SSOT da família, ferramenta de autoridade emissora. |
| `@onion` no standalone | **RELEASE** (escopado) | ponto de entrada/navegação; roteia só o que está no bundle. |
| `adopt`/`federation-*` no hub | **só TRUST hoje**; sub-adoção autônoma = seam gated | contradição `roles.yaml:17` (core-only) × `:19` (hub expõe sub-adotados) → hub é registro de trust; a sub-adoção é autorada pelo core até a seam org-marketplace abrir. |
| `co-deliver`/`co-announce` (downstream) no standalone | **WITHHOLD** downstream; **RELEASE** só upstream (`co-relay`+`co-evolve`) | T3 tem `exposes_downstream` sempre vazio → downstream é vestigial; upstream é o canal de refresh do adotante. |
| standalone = hub nas ferramentas de trabalho | **CONFIRMADO** (já codificado) | `roles.yaml:20-25` prova base/optional idênticos; só trust/downstream separa. |

## Recorte do funil (provar → querer → adotar)

| Degrau | Libera | Retém | Régua |
|---|---|---|---|
| **mini** (teaser) | a **demo instrumentada** no repo do prospect (3 contextos + efeito medido 40%↓erro/55%↑veloc) | o framework completo, o código, a rede | o "não-dá-pra-desver" é a **prova ao vivo**, não o download (`journey.md:19`) |
| **standalone** (solo, GRÁTIS) | o framework **completo** source-available: 6 verticais + todos os work-tools + motor de KG + `@onion` + refresh upstream (`co-relay`+`co-evolve`) | **federação** (downstream/rede), meta-fábrica, sub-adotados, templates curados fechados | dá-se de graça o "texto" (replicável); vende-se a **rede** (`strategy.md:58`). **É MOAT/advocacy, não funil de receita** (D5: solo não sustenta volume) |
| **hub** (empresa, UPSELL) | federação como **camada de time** (sync multi-repo, bundles role-scoped por squad, members.yaml/console, autoridade de sub-adoção) + templates fechados + **serviço** (treino/consultoria/certificação) | — (topo pago) | federação é o **moat inimitável** (`competitive-landscape.md:55-61`). Gatilho de promoção = **sinal social** (2º repo/2ª pessoa), não uso crescer |

## Caminhos de evolução

- **std→hub** = expansão de trust, **MESMO bundle** (não reinstala nada — base idêntica): muda o **stamp**
  (T3→T1), o **trust** (`exposes_downstream` deixa de ser vazio), e a meta-fábrica só entra **quando** a
  seam org-marketplace abrir. Gatilho: chegada do multi. **Lastro externo forte** (Anthropic/Datadog).
- **std→consumer** = re-parent upstream (source→hub) + **narrowing** (bundle encolhe: `consumer.base` =
  eng+docs, product/testing viram optional). **Extrapolação do maestro sem análogo de mercado** — o modelo
  de papéis suporta, mas fica como **hipótese** (não corroborada externamente).

## Onde codificar (3 ondas — separar não-gated do gated)

1. **AGORA, não-gated:** adicionar `.claude/validation/kg-radar.sh` ao `VALIDATION[]` de
   `onion-engineering.manifest.sh` — fecha o dead-ref de `work.md:24` **e** entrega o motor de KG soberano
   (doutrina: viaja o **script**, nunca o **dado** `.kg.yaml` do core — `public-door-vs-private-core.md:91-92`).
   One-liner de manifesto.
2. **DESIGN gated:** eixo **`work_tools:`** cross-cutting em `roles.yaml` (ortogonal a base/optional; NÃO
   forçar 7ª pseudo-vertical nem enfiar em onion-engineering). Popular hub == standalone com os work-tools
   (kg/diary/orchestrate/graph→só leitura?/@onion/context-freshness/kb-freshness/recover/
   analyze-complex-problem + upstream co-relay/co-evolve). Drift-guards no lint (eixo work_tools +
   "dependência-de-comando-bundlado": todo script citado em allowed-tools de comando empacotado deve estar no bundle).
3. **NEGÓCIO/DOC:** propagar "standalone" como degrau nomeado no `business-context` (journey/personas/
   sales-process ainda roteiam P5 pelo "mini"); resolver **D2** (moeda-dado, garantia local-first+destilado)
   antes de vender federação como upsell limpo; acionar **D3** (brand voice — o tom atual é "do core").

## Costuras / contradições registradas

- `hub sub-adota` (`roles.yaml:19`) × `adopt = core-only` (`:17`) → doc precisa cravar "hub downstream =
  trust-registro, não install-autônomo" até a seam abrir.
- `kg.md:60-61` ("nunca o código do radar viaja") é escopado à **Federação** (orgs distintas) — não
  transfere ao door-mesma-família (teste Aristóteles: diferente nesse eixo). O veto é só sobre o **dado**.
- **Seam org-marketplace/managed-settings** (hub autônomo): a própria Anthropic tem gap CLI declarado≠
  verificado (issue #45323) — testar o real antes de prometer auto-install.

## Referências externas (Frente D)

- Anthropic — Manage plugins for org (marketplace = Team/Enterprise): support.claude.com/en/articles/13837433
- Agent Skills free em plano pago individual; land-and-expand (Datadog); benchmarks free→paid 7%+ (saasmag/saasgrowthpros 2026)
- Pricing AI dev tools 2026 (Cline/Cursor/Copilot — individual-BYOK vs seat-based team): nxcode.io/checkthat.ai
