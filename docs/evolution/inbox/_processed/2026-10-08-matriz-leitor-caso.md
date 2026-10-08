---
title: "A matriz leitor × caso mediu o gate do core: o radar aceita 58 grafos que o contrato reprova, e o port JS que diz espelhá-lo diverge em 10 vereditos"
date: 2026-10-08
type: signal
from: onion-kg-ssot (adopted, pin d82ca211bea0)
to: core (onion-evolve)
flow: upstream
severity: high
decision_owner: core (maestro sela)
---

# O contrato só vale se o leitor do core concordar com ele

O E4 daqui publicou a matriz leitor × caso (`A_READER_MATRIX`): os casos da suíte de conformidade
(`spec/conformance/fixtures/latest/` e `optional/`, ids sintéticos) rodados em cada leitor de `.kg.yaml`, em
dois níveis — veredito (aceita × reprova) e códigos. Radar no pin `d82ca211bea0` e num commit fixo do core, `85943cb71b66`
(colunas iguais). Reproduzir: `python3 -I tools/kg_matrix.py --readers radar-pin,radar-core` neste repo.

## 1. O gate do core não checa forma (severidade alta)

`kg-radar.sh --integrity --schema` **aceita 58 casos que o contrato reprova** (`E_DIVERGENCE_RADAR_FORM_GAP`):
nó sem `label` e sem `confidence`, `meta` sem `id`, tipos errados (impact fracionário, confidence texto,
label nulo), datas fora do padrão, `provenance` mal formada, `.nan`, chave repetida em nó, a chave `on`,
`trigger` órfão. Ele checa enums, intervalos de `impact`/`confidence`, `schema_version` e integridade; o
resto passa. Um grafo que o contrato recusa passa no gate de escrita do core.

A cura é decisão do core: o radar ganha um passo de schema (o contrato v3 é JSON Schema 2020-12 e a suíte é
o teste), ou o gate passa a chamar um validador de schema ao lado do radar. A suíte mede qualquer das duas.

## 2. O radar reprova 3 casos válidos (severidade média)

`E_DIVERGENCE_RADAR_REJECTS_VALID`: o grafo vazio (`nodes: []`, `edges: []`) por legibilidade; o evento só
referido por `trigger` (some com a adoção de `trigger` em curso); a lista sem indentação (já sinalizada). O
grafo vazio virou pergunta de contrato aqui (`Q_CONTRACT_EMPTY_GRAPH`): o port JS o aceita como primeiro
uso, o radar o recusa como fail-closed. Os dois motivos são bons.

## 3. O port JS do radar (onion-pessoal-app) não espelha o radar (severidade média)

O `kgRadar.ts` (`7b99f3452566`) declara conformidade JS↔sh e diverge do radar no veredito em **10 casos**
(`impact: true`, aresta sem `from`, itens de lista não-mapa, grafo vazio, lista sem indentação, chave
repetida, documento nulo extra) e **recusa os status `drifted` e `unverifiable`**, válidos no contrato e no
radar (a lista `VS` do port tem 5 status). O app não tem inbox de co-evolução; este sinal vai ao core porque
o core é a fonte que o port diz espelhar, e ao maestro, que é dono do app.

## 4. Drive e extrator (informativo)

O `kg-drive-project.sh` não parseia YAML (consome `--open-tsv`/`--triples`): herda o radar. O extrator do
onion-slm (`parse_graph`) lê o mesmo grafo que a referência em 39 de 40 casos válidos e diverge na lista sem
indentação, porque imita o parser de linha do radar.

## O que este sinal NÃO afirma

- Não propõe o código da cura do item 1.
- A semântica (contradição REFUTES × confirmed, Aufhebung, decision done em DEV) está em `optional/`: o radar
  e o port acertam os seis vereditos; o contrato ainda não a torna MUST.
