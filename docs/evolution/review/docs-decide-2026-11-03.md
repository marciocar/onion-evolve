---
branch: docs/decide-2026-11-03
pr: pendente
date: 2026-11-03
reviewed_diff_sha256: 0d4576b0641e27671768466f51b21c4232a2ba2bba3b7f7473c8481ecf8bf795
reviewed_code_sha256: a8fee786c6e849101b50c15241a571ef9d3e8cc32653e5a706450b8cc106b3cf
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 5
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: "sessão do core (passada inline; selos pelo kg-decide-seal.sh)"
nota: "tokens 0 = não medido (passada inline, sem subagente)."
---

# Passada adversarial: `docs/decide-2026-11-03`

## O que muda

Seis selos do `/meta:decide` de 2026-11-03, todos pelo `kg-decide-seal.sh` (radar, contrato e nomes rc 0): as
portas (`D_ONION_CORE_PORTS_MULTI_HARNESS_2026_11`, com o complemento do maestro), o vigia de eventos
(`Q_COORD_DECIDIR_VIGIA_DE_EVENTOS`), o critério 1 e o critério 7 da ida e volta, o parque da composição e os spikes
das portas na VPS. A Emenda 3 entra no pré-registro da ida e volta, e o veredito do §10b passa a citar as duas decisões.

## Achados

1. Real, medido pelo selador: o selo do vigia foi desfeito porque a narrativa copiava o código «W3d» sem glosa.
   Curado na origem: «os casos de teste do vigia (numerados de 1 a 3d pela curadoria)».
2. Hipótese: selar o parque da composição no core, que é nó da curadoria. Não: o core grava a resposta do maestro
   num nó próprio (`D_COMPOSICAO_SEGUE_PARQUEADA_1103`), e a curadoria sela o dela citando-o.

## Mutantes

Nenhum: não há código.
