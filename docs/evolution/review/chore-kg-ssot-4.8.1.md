---
title: 'Resíduo — o vendor do contrato KG-SSOT sobe para kg-ssot-v4.8.1, que fecha o defeito de EOL no produto'
date: 2026-10-17
branch: chore/kg-ssot-4.8.1
reviewed_diff_sha256: b762f56747627a72a6a9df0f2b86ab1ac8b72b9b6233de4518486bb5de243032
reviewed_code_sha256: d0e4abfc6c7a9727991c132beed5e8b43d9c2eeb96cc71893e8e53cd615f85bc
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 10
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  A 4.8.1 é a cura, no produto, do defeito que o #1186 achou aqui: fixtures com CRLF normalizadas no
  índice pelo `*.json text eol=lf` do adotante. Ela traz o `vendor/kg-ssot/.gitattributes` com
  `* -text` (gravado pelo próprio update e registrado no carimbo) e o `check --index`. O roteiro
  combinado com o kg-ssot foi seguido como especificado, com cada passo medido:
  `update --tag kg-ssot-v4.8.1` rc=0; o check em seguida deu rc=1 ("faltando .gitattributes … rode o
  update de novo"), que é o comportamento declarado de quem vem do kit da 4.8.0; o 2º update rc=0
  gravou o arquivo; `git add` e `check --dest vendor/kg-ssot --index` rc=0, com 356 arquivos íntegros
  lidos do índice. O gate sem --update saiu rc=0 (contrato, leitor e suíte iguais), e o
  requirements.txt é idêntico ao do HEAD. A regra `vendor/kg-ssot/** -text` do .gitattributes do core
  fica como segunda linha. Sem Elenxo, declarado: troca de vendor por pin, com o verificador de
  integridade do índice como prova executada.
---

# Resíduo — `chore/kg-ssot-4.8.1`

Teto: o `check --index` confere o índice no momento em que roda. Se um commit posterior mexer no
vendor à mão, é o CI que o pega (o passo "Contrato KG-SSOT" roda o check no checkout).
