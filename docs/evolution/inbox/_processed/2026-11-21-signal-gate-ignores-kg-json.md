---
title: "Sinal: o kg_gate.py da 4.56 não mede grafos .kg.json"
date: 2026-11-21
type: signal
from: brain-granaai (hub)
to: kg-ssot (dono do vendor), via onion-evolve
flow: upstream
severity: medium
status: open
reviewed_for_public: true  # relido pelo core em 2026-11-22 como se publicado: só ferramentas e formatos públicos do kg-ssot, sem pessoa, cliente, segredo ou detalhe operacional
processed: 2026-11-22  # item 3 (o kg-radar.sh lê .kg.json) curado no core: nós E_SINAL_RADAR_ABORTA_KG_JSON_1122 e D_RADAR_LE_KG_JSON_PELO_MESMO_AWK_1122 em docs/onion/graph/sinais-de-campo-2026-09.kg.yaml; itens 1 e 2 são do kg-ssot, já em consulta Delphi repassada ao hub
---

# O gate não enxerga o grafo em JSON

## Medido

No hub, com o kg-ssot 4.56.0 vendorizado, criamos um grafo novo em `.kg.json` (formato que o `kg_migrate format --to json`
já produz). O `kg_validate.py` mede o grafo e passa no MUST com 0 SHOULD. Já o `kg_gate.py --baseline` e o
`--touched` dão rc 0 **sem medir o grafo**: a base não pede registro dele, e a saída não o lista. Também não dá para
usar `external_edges` no JSON, e o `kg-radar.sh` do Onion aborta em JSON.

## Por que importa

Um grafo novo pode entrar sem nenhum gate ver. O ratchet por grafo some justamente no formato que a 4.56 incentiva para
volumes grandes.

## Pedido

1. Que o `kg_gate.py` descubra e meça os `.kg.json` rastreados, como faz com os `.kg.yaml`.
2. Que `external_edges` funcione no perfil JSON, ou que a documentação diga a alternativa.
3. (Onion) Que o `kg-radar.sh` leia `.kg.json`.
