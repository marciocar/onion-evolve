# Instrumentos de percepção do core — como o Onion VÊ, VERIFICA e se mantém FRESCO

## 📋 Metadados

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Criado** | 2026-07-18 |
| **Status** | `accepted` — decidido por validação multi-lente + adversário (fable, 7 furos → corrigido) |
| **Tags** | `percepção`, `instrumento`, `radar`, `farol`, `telescópio`, `canary`, `frescor`, `declarado-verificado`, `sdaal` |

> **Irmã da doutrina de breadcrumbs** ([breadcrumb-patterns.md](../agentic-patterns/ai-strategies/breadcrumb-patterns.md)):
> breadcrumbs = as **marcas deixadas** (perna `write` do ciclo); instrumentos = **como se percebem** (pernas
> `read`+`verify`). Grafo: `docs/onion/graph/perception-instruments-2026-07.kg.yaml` (radar exit 0).

## 🎯 O modelo (corrigido pelo adversário)

Um **instrumento** é um leitor **determinístico + read-only** (salvo escrita **declarada**) cuja saída é **percepção,
não mutação**. Isso é o **critério de admissão** (senão a família incha até "qualquer coisa que lê"). A **unidade** é
o **CHECK**, não o script — um script empacota vários checks (ex.: `co-evolution-inbox-check.sh` faz percepção de
inbox **e** de migalha-vencida; `kg-radar` tem 7 modos).

### Os 4 PAPÉIS (não confundir ver com decidir)
- **① SENSOR** — percebe e reporta (não muta): `kg-radar` (advisory), `federation-radar`, `session-beacon check`, `pin-integrity` (o **canary**), `inventory`, `graph`.
- **② GATE** — percebe **e decide/escreve** (veredito que barra): `a2a-verify` (7 camadas; escreve `jti`, veto anti-replay — olhar 2× muda o veredito), os checks HARD do lint.
- **③ PROJEÇÃO** — view derivada, recalcula nada: `kg-console` (embute o veredito do radar), `federation-console`.
- **④ BREADCRUMB** — *não é instrumento*: a **marca deixada** (o arquivo `.beacon` do farol, `verified_at`, o stamp) — vive na doutrina de breadcrumbs (perna `write`). *O `session-beacon.sh` `up`/`down` DEIXA a marca (Trilha); só o `check` é SENSOR.*

### Os 3 GÊNEROS de sensor (por OBJETO percebido)
| Gênero | Percebe | Sensores |
|--------|---------|----------|
| **PRESENÇA-VIVA** | sessões vivas | **farol** (`session-beacon check` — lê a marca de presença) · **telescópio** (conteúdo pleno — `doctrine-gated`, sem script ainda) |
| **ESTADO-DURÁVEL** | o SSOT | **radar** (`kg-radar`/`federation-radar` — atenção/saúde) · **grafo** (`graph.sh` — estrutura) · **inventário** (`inventory.sh` — contagem) · **canary/pin-integrity** (pin real vs forjado) · `onion-version` |
| **MENSAGEM-NA-FRONTEIRA** | o que chega | **you-have-mail** (`co-evolution-inbox-check`) · `federation-inbox-scan` |

### Os EIXOS TRANSVERSAIS (não são gêneros — modificadores que qualquer sensor carrega)
- **`veredito: advisory | gate`** — `kg-radar` REPROVA (exit 1 em integridade/schema); `federation-radar` é **advisory** (exit 0 sempre). Contratos opostos sob o mesmo nome "radar" → declarar por check.
- **VALIDADE/FRESCOR** — o **⏰**: `review_after` (RFC-0003 §2.3) + `conflict_class` (dynamic|static|conditional) + `verified_at`. O `co-evolution-inbox-check` conta migalhas vencidas e emite ⏰ no boot — **lazy-por-sessão, nunca cron** (W7 rejeitado, `work-models:26`). Comandos: `/meta:diary review`, `/meta:context-freshness`, `/meta:kb-freshness`.

### As 3 FONTES que um sensor lê (a amarra correta — não "lê breadcrumb")
Nem todo instrumento lê uma marca (o adversário refutou "instrumentos leem breadcrumbs": `inventory` lê o
filesystem; `a2a-verify` lê o relógio NTP). Todo sensor declara de qual **estrato** lê:
- **marca** (breadcrumb deixado): beacon, `verified_at`, stamp `.onion-version` → o canary/pin-integrity, o farol-check, o radar-frescor.
- **estrutura** (spec-as-code): filesystem, frontmatter, `members.yaml` → inventory, graph, federation-radar.
- **vivo** (runtime): relógio NTP, git history, a tela da sessão → a2a-verify (camada de relógio), telescópio.

## 🐤 Canary (a pergunta B) — o sensor anti-degradação que já temos
O **canary** do Onion = `pin-integrity-check.sh`: um **arquivo vendorizado que muda com frequência no core** — se
o pin declarado no stamp diverge byte-a-byte do canário, o pin é **untrusted** (drift/forjado). É um **tripwire**
de `declarado≠verificado` (não é canary-deployment). Sensor de ESTADO-DURÁVEL, fonte = **marca** (o stamp).

## 🛡️ Guardas
- **Ver ≠ decidir** — sensor reporta; gate barra. Não classificar `a2a-verify` (gate que escreve) como sensor.
- **Advisory ≠ gate** — declarar o contrato `Exit:` por check; não agrupar vereditos opostos sob um nome.
- **Frescor lazy, não cron** — ⏰ por sessão (W7 rejeitado).
- **Radar-checkável (mechanism, not advice):** modelar a doutrina como KG (`instrumentos.kg.yaml`, 1 nó por CHECK, aresta `READS`→fonte, `TRACES_TO`→`script:linha`) — o próprio `kg-radar` audita (RULE-sem-trace pega check sem script; fonte-única pega check lendo 2+ estratos).

## 🔗 Referências
- Doutrina irmã (as marcas): [breadcrumb-patterns.md](../agentic-patterns/ai-strategies/breadcrumb-patterns.md)
- Par presença-viva: [onion-adr-telescope-session-observation-2026-07.md](../../analysis/onion-adr-telescope-session-observation-2026-07.md) (telescópio `doctrine-gated`)
- Frescor/⏰: [onion-adr-work-models-session-topologies-2026-07.md](../../analysis/onion-adr-work-models-session-topologies-2026-07.md) §4 · RFC-0003 §2.3
- SSOT-as-runtime (o ciclo): [knowledge-graph-sdaal.md](./knowledge-graph-sdaal.md) §SSOT-as-runtime
