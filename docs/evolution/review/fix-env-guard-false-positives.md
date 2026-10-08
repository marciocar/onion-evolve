---
title: 'Resíduo — o veto do .env julga glob pelo bash e pelo disco, e a pergunta do \r ganha caminho sancionado'
date: 2026-10-08
branch: fix/env-guard-false-positives
reviewed_diff_sha256: 3ddad8ca641b933e937a55c19db7f2595a26475a22bb59b56890d32a98bcbe97
reviewed_code_sha256: 95edd4e6f68cc4ab842fad7a6206c403e2f229c163aa92f0831175bf971c6d73
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 70
verdict: CORRIGIDO
elenxo: nao
nota: >-
  SAC-68, conduzido pelo /meta:drive com a forja de guarda (/meta:forge-guard invocado de verdade). Defeito
  datado em E_ENV_GUARD_VETOU_COMANDO_SEM_ENV: 7 vetos numa leva em comando que não lia .env. As 7 formas
  foram reproduzidas contra o hook com o JSON do PreToolUse; 6 vetavam. Causa comum de 5 delas: o glob era
  testado contra .env com fnmatch, que casa `*` com nome oculto, e o bash (dotglob desligado) não casa.
  Cura em pretooluse-env-guard.sh: glob terminado em / é diretório e nunca é .env; glob com ponto fecha como
  antes; glob sem ponto é conferido no disco, na pasta do cwd do JSON seguindo cd literal; fecha como antes
  com cd por variável, subshell com cd, pushd, .env citado na linha, glob que nomeia env, e variável ou
  crase no caminho. Passam agora: o laço de espera do CI, o grep em ops/testing/*, o laço for d in */ com o
  env-check, o for sobre /home/marcio/*/ e o corpo de heredoc com **. Seguem vetados por desenho, com
  caminho sancionado: o grep no .env (env-check.sh ganhou --lint, que acusa \r, aspas sem fechar e chave
  repetida por NOME, sem valor; e o leitor dele passou a tirar o \r final, que virava HTTP 401) e o heredoc
  que grava em arquivo texto citando .env (a ferramenta Write). Passada adversarial própria, com mandato de
  achar ESCAPE; achados reais, todos curados no mesmo PR: (1) grep -r --include=*.env . passava, porque o
  disco só era conferido no topo — pego pelo caso h2 da bancada; (2) cat $X/* e (3) cat ~/* passavam,
  porque o glob conferido no disco não expande variável nem ~; (4) a regra do glob de diretório era
  redundante nos casos (o mutante M1 não mordeu), então ganhou o caso que a exige (.env citado na linha
  com for d in */). Bancada env_exposure 14 de 14, casos novos l (21 formas com pastas reais) e m; famílias
  afetadas capability, shell_pipefail_robustness, zoho_token, plugin_hooks_json e plugin_runtime verdes; 7
  mutantes (M1 a M7), todos reprovando o caso deles, com LC_ALL=C. Grafo: E_GLOB_JULGADO_PELO_DISCO,
  D_GREP_E_HEREDOC_SEGUEM_VETADOS (proposta) e dois tetos; Q_ENV_GUARD_SEM_FALSO_POSITIVO segue open,
  porque 2 das 7 formas seguem vetadas por desenho e quem fecha é o selo do maestro. Radar --integrity
  --schema exit 0 e kg-contract-check.sh rc 0. REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed
  dele) — confirmed vistos: E_ENV_GUARD_VETOU_COMANDO_SEM_ENV, E_GLOB_JULGADO_PELO_DISCO. Tetos: grep -r
  sobre pasta (anterior à cura) e o disco visto no instante do veto. Sem Elenxo separado, declarado: a
  passada adversarial foi do próprio fork. Pre-commit pulado por ordem do maestro; validação = famílias +
  mutantes + pr-finalize + CI.
---

# Resíduo — `fix/env-guard-false-positives`
