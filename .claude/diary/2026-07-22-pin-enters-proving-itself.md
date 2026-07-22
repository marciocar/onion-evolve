---
date: 2026-07-22
instance: onion-evolve
type: innovation
classification: collective
tags: [pin, vendor, drift, validation, adopter, fixtures, dogfood, federation]
affects: [engineering, meta]
breadcrumb_for: []
share_with: []
next_recommended: "Todo valor que um script GRAVA no histórico de um adotante (pin, stamp, id de membro) deve entrar provando ser o que diz ser, antes da gravação — nunca aceitar string livre. O teste barato de suspeita: 'este campo é validado ANTES de virar registro permanente no repo de outro?'. E o alerta que este achado deu de brinde: fixtures que usam valores fictícios (v2, v3, 'pin-de-mentira') praticam exatamente o hábito que deixa o lixo real passar — quando uma validação nova quebrar fixtures antigas por serem fictícias, isso é sinal, não incômodo: as fixtures estavam ensinando o bug."
review_after: 2026-10-20
conflict_class: dynamic
significance: "O 'drift silencioso de pin' que o grafo do core registrava só em abstrato ganhou nome (vnextpin), mecanismo de entrada (o pin prova ser commit) e ferramenta de auditoria — porque a capacidade foi exercida contra adotantes reais, não desenhada."
---

## Signal
**O `vendor-branch.sh` gravava no histórico do adotante QUALQUER string como pin, sem validar** — e isso é o
mecanismo concreto do "drift silencioso de pin" que o grafo já refutava em abstrato. Medindo os 3 adotantes
locais, **2 tinham lixo carimbado**: `vnextpin` (placeholder) e `2026-07-12` (uma data no lugar do commit). O
dano é DIFERIDO: aparece semanas depois, quando o merge de 3 vias usa a base errada e lê ancestralidade como
conflito.

## Evidence
- **O caso reproduzido:** no update do gustavo-pulga, 17 arquivos em conflito — **todos byte-idênticos ao
  core**. Conflito CONTÁBIL, não de conteúdo: o `vnextpin` (nunca mergeado no `onion/adopt`) fez a base do
  3-way cair num estado anterior. Verificado blob a blob antes de resolver — senão eu teria apagado
  customização que não existia.
- **O fix (entrada):** `_update()` recusa (rc=2) pin que não seja commit da fonte, ANTES de gravar. Fecha,
  com mecanismo, a refutação que o grafo tinha em prosa (`REC_PIN_DRIFT_REAL_HEALTH_METRIC`).
- **O fix (passivo já gravado):** `pin-integrity-check.sh --audit-vendor <target> <source>` varre os pins do
  `onion/vendor` e lista os inválidos. Reproduz o achado (gustavo 1, granaai 0, metagamify 1). O passivo NÃO
  foi reescrito — a validação impede o PRÓXIMO; a cicatriz histórica é decisão do adotante.
- **O achado de brinde, que é o mais transferível:** a guarda nova quebrou **5 fixtures existentes** que
  passavam pins fictícios (`v2`, `v3`). **Os testes praticavam exatamente o hábito que deixou o lixo real
  passar.** Consertar a guarda obrigou a consertar os testes para usarem commits reais — a guarda melhorou o
  que a testava. Fixture com valor de mentira é um bug latente disfarçado de teste.

## Next crumb
Ver `next_recommended`. Regra: **valor que vira registro permanente no repo de outro entra provando-se.** E:
quando validação nova quebra fixture antiga por ela ser fictícia, a fixture era o bug. Pareia com
[[mechanism-beats-prose]] (a refutação virou mecanismo, não ficou prosa) e [[capability-never-met-reality]]
(achado só apareceu porque a federação foi EXERCIDA — 4 bugs numa tarde de uso, depois de 5 semanas de
desenho parado).
