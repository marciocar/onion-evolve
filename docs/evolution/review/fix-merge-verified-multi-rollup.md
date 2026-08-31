---
title: "Revisão — rollup duplicado em PR de stack não pode reprovar merge aprovado"
date: 2026-08-31
branch: fix/merge-verified-multi-rollup
reviewer: "defeito medido ao vivo no #735 (rollup ['SUCCESS','SUCCESS'] ≠ 'SUCCESS' → die num PR aprovado); cura agrega: ≥1 linha e TODAS SUCCESS ⇒ SUCCESS, senão devolve a primeira não-SUCCESS; provada pelo próprio merge do #735/#736 com o script curado. Registro honesto: a rota 'sem linha de veredito' segue WARN-e-segue (fail-open pré-existente, linha 82) — exercitada hoje ao mergear heads rebasados diff-idênticos sem CI novo (Actions sem minutos); classe anotada para decisão do maestro"
reviewed_diff_sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
findings_total: 2
findings_real: 2
verdict: APROVADO
tokens: 0
duration_min: 10
---

# Resíduo — REGRA 56

pr-merge-verified.sh: PR de stack retargeteado carrega o mesmo check em 2+ linhas de rollup; a
comparação com string única morria em PR aprovado. Cura por agregação. Fio aberto nomeado:
decidir se "sem linha de veredito" deve virar die (hoje é warn — fail-open deliberado do
desenho original, mas hoje ele deixou passar merges de head rebasado sem CI novo).
