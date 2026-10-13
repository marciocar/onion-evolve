#!/usr/bin/env bash
# =============================================================================
# apply-ruleset-main.sh — aplica (cria ou atualiza pelo NOME) o ruleset do main (core-only)
#
# POR QUE EXISTE: D_REQUIRED_CHECKS_RULESET_MAIN (selo do maestro, 2026-10-13: «Sim, sem histórico
# linear»). O ruleset é uma SEGUNDA camada, do lado do forge, sobre o veto exit 2 do hook de merge e o
# caminho verificado (ops/pr-merge-verified.sh). O que ele exige são os checks ESTÁVEIS da bancada em
# dois níveis (passo D de D_MERGE_PROCESS_ONION_2026_10):
#   · selftest-gate         — o job agregado de onion-selftest.yml (as faixas da matriz têm nome móvel);
#   · lint-onion-artifacts  — o job do lint de onion-validate.yml (sem filtro de path desde o passo D).
# A fonte é ops/github-ruleset-main.json; este script NÃO inventa regra, só a entrega.
#
# O QUE O RULESET NÃO TEM, DE PROPÓSITO (declarado):
#   · `required_linear_history` — barraria o --merge-commit do SAC-80 (ops/pr-merge-verified.sh);
#   · review obrigatório — o core é uma pessoa; review obrigatório travaria todo merge;
#   · strict (`strict_required_status_checks_policy: false`) — o modo LOOSE é o eixo da decisão
#     (E_OBJECAO_STRICT_VS_LOOSE_IS_THE_AXIS): strict faria cada auto-rebase pagar o CI de novo, e o
#     verificado já rebaseia e espera o CI do head novo.
#   · BYPASS do papel admin, `bypass_mode: always` (actor RepositoryRole id 5 = admin, pela doc REST de
#     rulesets do GitHub; não medido ao vivo). ⚠️ Num repo de dono User o dono É o admin: o ruleset NÃO
#     prende o dono, que é quem mergeia. Para ele a camada que prende segue sendo o hook exit 2 + o
#     caminho verificado; o ruleset prende colaborador e App. É o preço de não travar o caminho
#     verificado numa emergência (CI morto), e é declarado em vez de escondido.
#
# Também garante que a label `ci:full` exista (o nível PR a lê para forçar a bancada completa).
#
# Uso  : bash ops/apply-ruleset-main.sh [--dry-run] [--repo dono/nome]
#        --dry-run imprime o JSON e o que FARIA, sem chamar a API de escrita.
# Exit : 0 aplicado (ou dry-run) · 1 a API recusou · 2 uso/entrada inválida.
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC="${ONION_RULESET_SPEC:-${ROOT}/ops/github-ruleset-main.json}"
REPO="marciocar/onion-evolve"; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --repo) shift; REPO="${1:-}" ;;
    -h|--help) sed -n '/^# Uso  :/,/^# Exit :/p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "apply-ruleset-main: argumento desconhecido '$1'" >&2; exit 2 ;;
  esac
  shift
done
[ -n "${REPO}" ] || { echo "apply-ruleset-main: --repo vazio" >&2; exit 2; }
[ -f "${SPEC}" ] || { echo "apply-ruleset-main: spec ausente: ${SPEC}" >&2; exit 2; }

# A spec é validada ANTES de qualquer chamada: nome, alvo, checks e as três ausências declaradas.
NAME="$(SPEC="${SPEC}" python3 -I -c '
import json, os, sys
d = json.load(open(os.environ["SPEC"], encoding="utf-8"))
rules = {r["type"]: r for r in d.get("rules", [])}
ctx = [c["context"] for c in rules.get("required_status_checks", {}).get("parameters", {}).get("required_status_checks", [])]
err = []
if not d.get("name"): err.append("sem name")
if d.get("conditions", {}).get("ref_name", {}).get("include") != ["~DEFAULT_BRANCH"]: err.append("alvo != ~DEFAULT_BRANCH")
if sorted(ctx) != ["lint-onion-artifacts", "selftest-gate"]: err.append("checks != selftest-gate + lint-onion-artifacts: %s" % ctx)
if "required_linear_history" in rules: err.append("required_linear_history presente (barra o --merge-commit do SAC-80)")
if "pull_request" in rules: err.append("regra pull_request presente (review obrigatório não foi decidido)")
if err: sys.stderr.write("spec inválida: " + "; ".join(err) + "\n"); sys.exit(2)
print(d["name"])
')" || exit 2

if [ "${DRY}" = "1" ]; then
  echo "── dry-run: ruleset '${NAME}' em repos/${REPO}/rulesets (cria ou atualiza pelo nome) ──"
  cat "${SPEC}"
  echo "── dry-run: label 'ci:full' seria criada se ausente (gh label create ci:full --repo ${REPO}) ──"
  exit 0
fi

command -v gh >/dev/null 2>&1 || { echo "apply-ruleset-main: gh ausente" >&2; exit 2; }
_list="$(gh api "repos/${REPO}/rulesets" --paginate 2>&1)" || { echo "apply-ruleset-main: não consegui listar os rulesets: ${_list}" >&2; exit 1; }
_id="$(printf '%s' "${_list}" | NAME="${NAME}" python3 -I -c '
import json, os, sys
raw = sys.stdin.read().replace("][", ",")
for r in json.loads(raw or "[]"):
    if r.get("name") == os.environ["NAME"]:
        print(r["id"]); break
')"
if [ -n "${_id}" ]; then
  gh api -X PUT "repos/${REPO}/rulesets/${_id}" --input "${SPEC}" >/dev/null \
    || { echo "apply-ruleset-main: a API recusou a ATUALIZAÇÃO do ruleset ${_id}" >&2; exit 1; }
  echo "ruleset '${NAME}' ATUALIZADO (id ${_id})"
else
  gh api -X POST "repos/${REPO}/rulesets" --input "${SPEC}" >/dev/null \
    || { echo "apply-ruleset-main: a API recusou a CRIAÇÃO do ruleset" >&2; exit 1; }
  echo "ruleset '${NAME}' CRIADO"
fi
_labels="$(gh label list --repo "${REPO}" --limit 200 --json name --jq '.[].name' 2>/dev/null || true)"
if grep -qxF 'ci:full' <<< "${_labels}"; then
  echo "label 'ci:full' já existe"
else
  gh label create 'ci:full' --repo "${REPO}" --color B60205 \
    --description "força a bancada COMPLETA no PR (passo D de D_MERGE_PROCESS_ONION_2026_10)" >/dev/null \
    && echo "label 'ci:full' criada" || { echo "apply-ruleset-main: não consegui criar a label ci:full" >&2; exit 1; }
fi
