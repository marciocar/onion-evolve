---
branch: chore/kg-ssot-4.17.0
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: 06de2bc3d629bf75bad36c113cfc56bb4f44f219e35e961f8532a934be502487
reviewed_code_sha256: 2b24ff9e03687c526566e46bf29c53fbd2947bf36859b623257de131597e8ace
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 3
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal
nota: "tokens 0 = não medido; vendor por kg_vendor.py"
---

# Passada adversarial: `chore/kg-ssot-4.17.0`

## O que muda

O vendor vai da 4.16.1 para a 4.17.0 e o comentário do pin é alinhado. O contrato e a identidade não mudam.

## Achados

Nenhum. Pelo caminho do CI, são 183 grafos e os mesmos 16 na dívida herdada, e o gate sai rc 0 sem
`--update`. O vendor está íntegro (501 arquivos).

## Mutantes

Não se aplica.

## Limites declarados

O core ainda não consome o `kg_query.py` nem o `kg_diff.py`. Trocar o `kg-corpus-grep.sh` e os feeds TSV do
radar pela consulta do produto é trabalho seguinte, a decidir.
