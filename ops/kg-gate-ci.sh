#!/usr/bin/env bash
# ops/kg-gate-ci.sh — o gate do contrato KG-SSOT, UMA invocação para o CI e para o pr-finalize.
#
# Por que existe (2026-10-14): o PR #1106 passou no pr-finalize (0 HARD no lint) e reprovou no CI,
# porque um label de 538 caracteres subiu a dívida SHOULD de um grafo, e a catraca da dívida é do
# kg_gate.py, que só o passo "Contrato KG-SSOT" do onion-validate.yml rodava. O pr-finalize julgava o
# commit com o lint e não com o contrato. Copiar a linha do CI para o pr-finalize duplicaria os
# --exclude, e eles têm de casar com os da base (.kg-ssot/gate/, uma pasta com um registro por grafo desde a kg-ssot 4.16.0); por isso os dois chamam este.
#
# Uso: bash ops/kg-gate-ci.sh [args extras do kg_gate.py, como --update]
#   rc 0 = vendor íntegro, nenhum grafo piorou e nenhum código novo sem nome · rc 1 = reprovou · rc 2 = entrada quebrada (nunca verde)
# Roda da raiz do repo que se quer julgar (o pr-finalize a chama dentro da worktree do HEAD).
#
# BANCADA PRÉ-TAG (kg-ssot 4.24.0): um vendor trazido por `kg_vendor.py update --ref <commit>` tem o carimbo
# `unreleased`, e o check do vendor e o kg_gate.py o reprovam sem --allow-unreleased. Para medir esse vendor:
#   KG_ALLOW_UNRELEASED=1 bash ops/kg-gate-ci.sh
# A variável passa --allow-unreleased aos DOIS (check e gate). O CI NUNCA a define: com CI no ambiente ela sai
# rc 2, para um vendor de bancada nunca passar por release. Sem ela, o vendor de bancada reprova (rc 1).
set -uo pipefail

[ -f vendor/kg-ssot/tools/kg_gate.py ] || { echo "kg-gate-ci: vendor/kg-ssot ausente em $(pwd) — não dá para julgar" >&2; exit 2; }

if [ -n "${KG_ALLOW_UNRELEASED:-}" ] && [ -n "${CI:-}" ]; then
  echo "kg-gate-ci: KG_ALLOW_UNRELEASED é só da bancada local; no CI (CI=${CI}) um vendor de bancada nunca passa" >&2; exit 2
fi
python3 -I vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot ${KG_ALLOW_UNRELEASED:+--allow-unreleased} || exit $?

# FORA DO CORPUS, explícito (política selada pelo maestro, 2026-10-08): propostas arquivadas do
# kg-inbox são história. A base tem de ser gravada com os MESMOS --exclude:
#   bash ops/kg-gate-ci.sh --update
python3 -I vendor/kg-ssot/tools/kg_gate.py \
  --exclude 'docs/evolution/kg-inbox/_rejected/*' \
  --exclude 'docs/evolution/kg-inbox/_sealed/*' \
  ${KG_ALLOW_UNRELEASED:+--allow-unreleased} \
  "$@"
gate_rc=$?

# O critério pré-registrado por HASH (kg-ssot 4.21.0): o leitor não calcula hash, então a régua editada no lugar
# só é pega aqui. Roda sempre (inclusive com --update), e o rc final é o pior dos dois; 2 (não julgou) vence.
bash "$(dirname "${BASH_SOURCE[0]}")/kg-criterion-ci.sh"; crit_rc=$?

# O lint de NOMES (kg-ssot 4.23.0, contrato v4.14): código novo na prosa sem x_term reprova; o legado está na
# base .kg-ssot/vocab-lint.json, com as externas de .kg-ssot/vocab-externals.tsv. Roda sempre e SEM --update
# (a base dele se regrava só por `bash ops/kg-vocab-ci.sh --update`, no PR que nomeia).
bash "$(dirname "${BASH_SOURCE[0]}")/kg-vocab-ci.sh"; vocab_rc=$?
[ "$gate_rc" -eq 2 ] || [ "$crit_rc" -eq 2 ] || [ "$vocab_rc" -eq 2 ] && exit 2
[ "$gate_rc" -ne 0 ] && exit "$gate_rc"
[ "$crit_rc" -ne 0 ] && exit "$crit_rc"
exit "$vocab_rc"
