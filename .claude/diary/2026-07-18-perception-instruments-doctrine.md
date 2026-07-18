---
date: 2026-07-18
instance: onion-evolve
type: decision
classification: collective
tags: [percepcao, instrumento, radar, farol, telescopio, canary, frescor, taxonomia]
affects: [meta]
breadcrumb_for: []
share_with: [granaai, metagamify]
next_recommended: "Radar-checkavel: modelar instrumentos.kg.yaml layer:domain (1 no por CHECK, aresta READS->fonte, TRACES_TO->script:linha) pra o kg-radar auditar a doutrina. E gates faltantes p/ Absorcao/Trilha (breadcrumb doctrine)."
review_after: 2026-10-15
conflict_class: static
---

## Signal
**Os instrumentos de percepcao do core sao uma familia — irma dos breadcrumbs** (breadcrumbs = a marca deixada,
perna write; instrumentos = como se percebe, pernas read+verify). O adversario (fable) REFUTOU minha 1a taxonomia
(7 furos, 3 ALTA) e o corte certo eh: **4 PAPEIS** (sensor/gate/projecao/breadcrumb) + **3 generos de sensor por
OBJETO** (presenca-viva/estado-duravel/mensagem-na-fronteira) + **3 fontes** (marca/estrutura/vivo) + eixos
transversais (veredito advisory|gate; validade/frescor) + **unidade = CHECK, nao script**.

## Evidence
- KB `docs/knowledge-base/concepts/onion-perception-instruments.md`; grafo `docs/onion/graph/perception-instruments-2026-07.kg.yaml` (radar exit 0, SUPERSEDES das hipoteses cruas).
- **Correcoes do adversario que me pegaram:** (1) o FAROL eh breadcrumb (o .beacon eh marca DEIXADA; so o `check` eh sensor); (2) a2a-verify eh GATE-ATOR (escreve jti, olhar 2x muda o veredito), nao sensor; (3) "instrumentos leem breadcrumbs" eh falso (inventory le filesystem, a2a le relogio NTP) -> 3 fontes.
- **Canary (temos):** pin-integrity-check usa um canario (arquivo vendorizado; divergencia byte-a-byte delata pin forjado) — tripwire declarado!=verificado.
- **Prazos/frescor (temos):** review_after + conflict_class + o ⏰ lazy-por-sessao (co-evolution-inbox-check). NAO cron (W7 rejeitado).

## Next crumb
Distinguir sempre: SENSOR (ve) vs GATE (decide/escreve) vs PROJECAO (view) — ver != agir. Todo sensor declara de
qual FONTE le (marca/estrutura/vivo). "Ver o estado" != "2 metades do read(KG)": instrumentos sao read+verify;
a marca eh a perna write. Frescor eh lazy-por-sessao, nunca cron.
