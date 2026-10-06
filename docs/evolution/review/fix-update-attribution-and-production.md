---
reviewed_diff_sha256: cee2991d4c41a6a0b8c69a3b94d4354630712d4c97c7ca80d06a59e158db7f2b
reviewed_code_sha256: 824a571a32a72de4292c2e594407765ce840db0e12cdf7313d070b087d09fa78
findings_total: 11
findings_real: 11
tokens: 229273
duration_min: 28
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Dois sinais de campo de um hub (brain-granaai, 2026-10-05): o `attribution` (assinatura de commit/PR) nunca
  viajava no --update, e o resolve-production-branch elegia `develop` num GitFlow RETOMADO. Attribution:
  never-clobber + AVISO de divergência (aprovado nas duas passadas). Produção: a 1ª passada (opus) REPROVOU a
  1ª cura ("master/main vencem o origin/HEAD" + "config = origin/HEAD é veneno") — elegia `master` parada onde a
  produção é production/trunk/release e fazia a adoção sobrescrever config setado à mão; curada com o
  discriminante único "nome com forma de integração". A 2ª passada deu CORRIGIDO: F1 falso alarme no trunk-based
  (7 adotantes) e F2 config velho (rename master→main sem prune) em silêncio, obrigatórias; F3 cláusula
  gitflow.branch.develop e F4 `HEAD` como config, recomendadas — as quatro curadas. TETO declarado (não
  regressão, igual ao antes do PR): o passo (3) do adopt sobrescreve config cujo ref ainda não foi buscado
  (clone single-branch). Bancada resolve_production 16/16 + 3 fixtures de merge; 10 mutantes mordem. Medido nos
  24 adotantes: só brain-granaai (develop→master) e rhilo-metagamify (develop→rhilo/main) mudam, ambos casando
  com o config gravado.
---

# Resíduo — `fix/update-attribution-and-production`

O `attribution` viaja no `--update` sem sobrescrever o do adotante, e a produção num GitFlow retomado é a `master`.
