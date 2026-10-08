---
title: 'Resíduo — selo do veto do .env, vendor do contrato em 3.0.1, e o checador deixa de plantar bytecode no vendor'
date: 2026-10-08
branch: chore/seal-env-guard-decision
reviewed_diff_sha256: 5c2d68072bb94528a0d1a8c764b87f48a9c7d857c052c9de2170dc347f2f1126
reviewed_code_sha256: 559bfc7ecbb093cdf0b08fc980b3358518cf51a825c094e569108cae98c67b5d
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 5
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Selo do maestro em 2026-10-08 (resposta “se ok, sim”): D_GREP_E_HEREDOC_SEGUEM_VETADOS vira done, com
  grep no .env e heredoc que grava texto citando .env em arquivo seguindo vetados por desenho, com caminho
  sancionado (env-check.sh --lint e a ferramenta Write). Com isso Q_ENV_GUARD_SEM_FALSO_POSITIVO fecha: PR
  #975 mergeado, 5 das 7 formas medidas passam e todos os vetos verdadeiros foram preservados. Achado no
  caminho: a 1ª escrita do selo pôs aspas duplas dentro de uma string entre aspas duplas; o radar (awk) deu
  exit 0, e o kg-contract-check.sh reprovou com parse.yaml-error. É o ganho de ter dois leitores, medido
  ao vivo; corrigido com aspas tipográficas, contract rc 0 e radar exit 0. Sem Elenxo, declarado: selo do
  maestro. PR segurado até o SAC-78 (PR de execução aberto) entrar, pela regra-ponte de 2026-10-08.
  Lote segurado, solto depois do SAC-78 (#976): (2) vendor/kg-ssot atualizado para contract-v3.0.1
  (263fbd9a01c0, 182 arquivos), a pedido do adotante dedicado: mesmo contrato e mesma suíte, o
  kg_vendor.py sem a lista de nomes privados do release-check; check íntegro e gate 144 de 144 no MUST,
  base do gate inalterada. (3) Achado ao atualizar: o update recusou com VENDOR QUEBRADO porque os
  meus runs locais do gate tinham plantado tools/__pycache__/*.pyc, que o check rejeita de propósito; o
  nosso kg-contract-check.sh plantava o mesmo (importa as ferramentas do vendor sem -B). Curado com
  python3 -I -B no checador; caso (f) da família kg_contract_check (o checador não deixa bytecode no
  vendor), e o mutante que tira o -B faz o caso reprovar (medido, LC_ALL=C). O passo do CI roda check
  antes do gate, então o CI nunca sofreu. Pre-commit pulado por ordem do maestro; validação = família +
  mutante + pr-finalize + CI.
---

# Resíduo — `chore/seal-env-guard-decision`
