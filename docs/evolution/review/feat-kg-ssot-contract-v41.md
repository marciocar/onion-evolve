---
title: 'Resíduo — adoção do contrato KG-SSOT v4.1 (SAC-73)'
date: 2026-10-09
branch: feat/kg-ssot-contract-v41
reviewed_diff_sha256: 8eedcb76645ba1a4f9b3d7e12ec0712684814b90506019b406db7109375ceac7
reviewed_code_sha256: d67e3731bb0ed302a4e5832f1126f4e717ed06fb687e902b16ac52f7b135ac85
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 50
verdict: CORRIGIDO
elenxo: nao
nota: >-
  A passada é do autor. O contrato é vendorizado por pin, e o juízo dele é do onion-kg-ssot, que publicou
  a tag. Aqui se prova a integração: vendor íntegro, gate rc 0 com a base nova, as 9 famílias de bancada
  dos geradores verdes com LC_ALL=C, um mutante para cada caso novo e a bancada completa do CI.
---

# O que o v4.1 mudou e o que precisou mudar aqui

A tag `contract-v4.1.0` (commit 7543bdf0fdd8) não muda nenhum veredito MUST. Ela acrescenta quatro avisos
SHOULD. Medidos no corpus do gate (138 grafos, com os `--exclude` do CI), em número de grafos:

| Código | Antes | Depois |
|---|---:|---:|
| `form.pattern.node.provenance.method` | 6 | 6 |
| `form.range.node.label` | 112 | 112 |
| `form.required.node.verified_at` | 7 | 7 |
| `yaml.unquoted-date` | 129 | 129 |
| `form.required.node.verified_against` (novo) | — | 16 |
| `integrity.testimony-in-prod` (novo) | — | 34 |
| `integrity.untraced-decision` (novo) | — | 19 |
| `integrity.verified-before-fact` (novo) | — | 0 |

A soma vai de 254 para 323 incidências. Os grafos na dívida MUST seguem 91. A base `.kg-ssot/gate.json`
foi regravada com `--accept-regression`, e o motivo ficou nela.

O onion-kg-ssot mediu, no pin dele, 16, 1 e 22 para `verified_against`, `verified-before-fact` e
`untraced-decision`. A diferença vem do corpus, que a onda 1 da O3 mudou depois.

## Insumo das ondas 2 e 3

São 125 nós PROD, em 34 grafos, que se apoiam em testemunho. Todos são pegos pelo `method` da classe
`testemunho`, e nenhum por `evidence_class`. Estão em
`docs/evolution/research/contrato-kg-absorcao-2026-10/data/provenance-triage/v41-testimony-in-prod.tsv`.

## Geradores

Nenhuma das 9 famílias reprovou com o v4.1 (`seed_adoption_graph`, `census_seal`, `drive`, `research_lens`,
`dissect`, `research_workflow`, `kg_contract_check`, `kg_migrate_v3`, `cc_delta_census`; 95 casos). Lendo
os geradores, um ponto ficou exposto. O modo decisão do `onion-research.js`, que o `/meta:dissect`
reusa, manda escrever um `D_` open e não exige `trace`. Uma decisão sem trace, sem provenance e sem
`TRACES_TO` acusa `integrity.untraced-decision`, e o `kg-contract-check` cobra SHOULD vazio em grafo novo.

Curas:
- **Prompt:** o bloco do contrato no `write(KG)` ensina os quatro avisos.
- **Bancada:** caso `research-workflow (q)`. O mutante tira a linha e o caso reprova.
- **Checador:** o `kg-contract-check` ganha a dica de cura de cada código novo. Caso `kg-contract-check (g)`:
  uma decisão nova sem origem dá rc 1, com o código e a dica. O mutante tira a dica e o caso reprova.

# Achados (reais, curados)

1. **O caso (q) abortava a bancada inteira sob o mutante.** `_v41="$(grep … | head -1)"` sob
   `set -euo pipefail` sai 1 quando a linha falta, e o `set -e` matava a suíte antes da soma. Com a cura no
   lugar, isso não aparecia. Foi pego ao rodar o mutante: a bancada imprimiu "ABORTOU ANTES DA SOMA" em vez
   do ✗. Cura: `|| true` no pipeline. Com isso, o mutante reprova (q) como ✗ nomeado.
2. **A fixture do caso (g) apagava o próprio nó sob teste.** O nó `D_A` era impresso depois de `edges:`, e o
   `sed '/^edges:/,$d'` o removia. O grafo saía conforme, e o caso reprovava pela razão errada. Pego na
   1ª execução (rc 0 e "conforme"), contra o leitor do vendor, que acusava o código no mesmo grafo escrito à
   mão. Cura: o nó entra antes das arestas e ganha uma aresta própria, para não cair em `orphan-node`.
3. **O caso (q) abria três sítios novos da classe EPIPE.** Ele usava `printf '%s' "$v" | grep -qF` como veredito,
   e a catraca `shell-pipefail` reprovou no CI (shard 3, 37 > 34 sítios). A família não estava entre as 9 que rodei
   localmente, porque ela não pertence a gerador: guarda a própria bancada. Cura: here-string
   (`grep -qF PAD <<< "$v"`) e `grep -m1` no lugar de `grep | head -1`. Com a cura, `shell_pipefail_robustness` e
   `research_workflow` passam verdes, e o mutante de (q) segue reprovando.

# Divergências do radar contra o contrato (apontadas pelo onion-kg-ssot, medidas aqui, não curadas neste PR)

- **Testemunho em PROD.** O `MISPLANED` do `kg-radar.sh` lê só `evidence_class: testimony`. Por isso não vê
  nenhum dos 125 nós, que são testemunho pelo `method`.
- **Decisão sem origem.** A `decisão-sem-proveniência` do radar aceita só `trace` ou `TRACES_TO`, e o contrato
  aceita também `provenance`. São 9 decisões vivas, em 4 grafos, que o radar cobra e o contrato aceita.
  Os dois cobram outras 53, em 19 grafos.

Ficam registradas no nó `E_CONTRATO_V41_ADOTADO`. A cura é do radar e vira lote próprio.

# Fora deste PR (pré-existente)

- O lint local acusa a REGRA 16 (Contagem de inventário-TOTAL divergente da SSOT) em
  `docs/technical-context/02-ai-context/codebase-guide.md`: a tabela fala em 113 comandos, e a SSOT tem 114.
  A tabela por categoria inteira está defasada (meta 35, contra 46 da SSOT). No ambiente do CI ela não é HARD: o
  `pr-finalize` deu 0 HARD e o linter do CI passou. Fica para quem tocar o guia.

# Tetos

- A dívida SHOULD subiu por desenho: o v4.1 nomeia o que o corpus já tinha. Quem a queima são as ondas 2 e 3,
  não este PR.
- A lista de testemunho em PROD é uma fotografia de 2026-10-09. A onda que a consumir deve re-medi-la contra
  o vivo.
