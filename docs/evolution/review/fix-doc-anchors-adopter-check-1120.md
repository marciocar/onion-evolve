---
branch: fix/doc-anchors-adopter-check-1120
pr: pendente
date: 2026-11-20
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 3
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: true
elenxo_isolado: false
reviewer: "Passada da própria sessão do core, só leitura: duas âncoras geradas por título com emoji trocadas por <a id> explícitas na linha do título, e as três citações apontadas para elas (grep confirma zero citação velha)."
nota: "tokens 0 = não medido. Não toca guarda."
---

# Passada adversarial: `fix/doc-anchors-adopter-check-1120`

## O que muda

adopt.md e task-manager/interface.md ganham âncoras explícitas; três links passam a apontar para elas.

## O que se tentou refutar

Sobrou link para a âncora velha? `grep -rn` pelas duas formas antigas no repo: zero. O título continua igual no texto
renderizado; só ganhou a âncora fixa, e o limite de linhas da REGRA 5 segue respeitado (800 e 509).
