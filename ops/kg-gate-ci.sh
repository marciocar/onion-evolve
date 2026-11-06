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
#   KG_GATE_ALLOW_UNRELEASED=1 bash ops/kg-gate-ci.sh   (só a bancada antes da tag; ver abaixo)
#   rc 0 = vendor íntegro, nenhum grafo piorou e nenhum código novo sem nome · rc 1 = reprovou · rc 2 = entrada quebrada (nunca verde)
# Roda da raiz do repo que se quer julgar (o pr-finalize a chama dentro da worktree do HEAD).
set -uo pipefail

# a pasta das ferramentas do KG-SSOT pelo resolver único (.claude/utils/kg/kgssot-tools.sh: KG_SSOT_TOOLS →
# vendor/kg-ssot/tools → tools/ do próprio produto), a partir da raiz julgada (o cwd); nada casou, o vendor de hoje.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/utils/kg/kgssot-tools.sh" 2>/dev/null || kgssot_tools_dir() { return 1; }  # resolver único (sem ele: o caminho de hoje)
KGT="$(kgssot_tools_dir .)" || KGT=./vendor/kg-ssot/tools
KGT="${KGT#./}"
[ -f "${KGT}/kg_gate.py" ] || { echo "kg-gate-ci: ${KGT}/kg_gate.py ausente em $(pwd) (nem KG_SSOT_TOOLS, nem vendor/kg-ssot, nem tools/ do produto) — não dá para julgar" >&2; exit 2; }

# A BANCADA antes da tag (kg-ssot 4.24.0): um vendor trazido por `kg_vendor.py update --ref <commit>` tem o carimbo
# unreleased, e o check e o kg_gate.py o reprovam sem --allow-unreleased. Sem esta variável a bancada pré-tag não
# tinha como passar a flag ao check (os args extras só vão ao kg_gate.py). Ela vale SÓ quando setada a 1, e o CI e o
# pr-finalize nunca a setam: o vendor de release vem de update --tag, e um vendor de bancada nunca passa por release.
# O kg_gate.py recusa --update a partir de um vendor de bancada mesmo com a flag, então a base não se regrava daqui.
# O "nunca seta" é mecanismo, não promessa: no GitHub Actions a variável setada sai rc 2 (não julgou).
allow=()
if [ "${KG_GATE_ALLOW_UNRELEASED:-}" = 1 ]; then
  [ "${GITHUB_ACTIONS:-}" = true ] && { echo "kg-gate-ci: KG_GATE_ALLOW_UNRELEASED=1 no CI — a bancada pré-tag é só local, um vendor de bancada nunca passa por release" >&2; exit 2; }
  allow=(--allow-unreleased)
fi

# A integridade do VENDOR só existe onde há vendor: o kg_vendor.py confere o carimbo de vendor/kg-ssot contra os
# sha256 dele, e no próprio produto (tools/ na raiz) não há vendor a conferir. Por isso fica no caminho fixo.
if [ -d vendor/kg-ssot ]; then
  python3 -I vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot "${allow[@]}" || exit $?
else
  echo "kg-gate-ci: sem vendor/kg-ssot (ferramentas em ${KGT}): a integridade do vendor não se aplica" >&2
fi

# FORA DO CORPUS, explícito (política selada pelo maestro, 2026-10-08): propostas arquivadas do
# kg-inbox são história. A base tem de ser gravada com os MESMOS --exclude:
#   bash ops/kg-gate-ci.sh --update
python3 -I "${KGT}/kg_gate.py" \
  --exclude 'docs/evolution/kg-inbox/_rejected/*' \
  --exclude 'docs/evolution/kg-inbox/_sealed/*' \
  "${allow[@]}" "$@"
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
