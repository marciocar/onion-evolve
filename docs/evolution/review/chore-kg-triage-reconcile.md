---
title: 'Resíduo — reconciliações do corpus (B2_2, arestas PR↔PR), a fila de 2026-10-06 no grafo e os sinais do onion-slm processados'
date: 2026-10-06
branch: chore/kg-triage-reconcile
reviewed_diff_sha256: 7ff7a7e6938553880cdbc3d8efb6967adca94a2468c8b9115938711b162ffc2a
reviewed_code_sha256: de63b4b058a4651aaf46c287183647fff139fe46c97d52411c6294ae4c5e7af2
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 20
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Item C da triagem do onion-slm, aprovado pelo maestro. (C2) `B2_2_claim_core_mechanic_healthy` reconciliado
  como confirmed, com verified_against no audit de origem (:18-21): as 5 arestas REFUTES que ele recebia viram
  CONSTRAINS, porque o audit as lista como ressalvas dentro do veredito "saudável"; o refuted veio do commit
  e0bf994a, posto para a catraca do radar passar. (C3) As 61 arestas PR↔PR do pr-decision-history (52
  DEPENDS_ON + 9 CAUSES, o número do sinal) ganham `provenance: llm-remap-ffecf8da`. Novo grafo
  `fila-2026-10-06` (kg-backlog-guard: on): 11 evidências medidas hoje e 11 compromissos abertos que viviam
  num arquivo temporário da sessão e quase se perderam num reinício. Os três sinais do onion-slm vão para
  inbox/_processed, com anúncio de volta na staging dele e entrada no CHANGELOG. Radar --integrity --schema
  exit 0 nos três grafos tocados. Sem Elenxo, declarado: mudança de dado, sem superfície executável.
---

# Resíduo — `chore/kg-triage-reconcile`

Teto declarado: o campo `provenance:` de aresta é novo no corpus; o radar e o parser o ignoram (medido:
radar exit 0, yaml.safe_load lê os 61). O schema formal (fila: Q_KG_SCHEMA_FORMAL) é quem vai decidir se
ele fica.
