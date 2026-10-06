---
reviewed_diff_sha256: f32bf8af77f8241562cf251b07dca7764c76d7244c7b7054fd43efb69d097031
reviewed_code_sha256: 6b27932111d4ea4bb78fb183c7e97b78cc075ba7c624f38e8f5d4604cdd96b1d
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
  DEPOIS DO CI (2026-10-06): a faixa 1 reprovou na catraca da classe produtor|grep -q — o caso novo do AVISO de
  attribution usava `bash helper … | grep -q`, sítio NOVO (35>34). Curado com here-string; a catraca volta a 34
  (ZERO novo); a variável do caso nasceu `_aviso` e a REGRA 60 (Identificador de código em INGLÊS) a barrou no lint do commit — virou `_warn_out`. Revisado à mão por quem escreveu, sem nova passada do Elenxo — declarado.
---

# Resíduo — `fix/update-attribution-and-production`

O `attribution` viaja no `--update` sem sobrescrever o do adotante, e a produção num GitFlow retomado é a `master`.
