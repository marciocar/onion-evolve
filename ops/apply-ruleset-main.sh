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
#   · BYPASS do papel admin, `bypass_mode: pull_request` (actor RepositoryRole id 5 = admin, pela doc
#     REST de rulesets do GitHub; não medido ao vivo). Decisão do maestro em 2026-10-13
#     (D_RULESET_BYPASS_SO_EM_PR): o admin passa por cima dos checks SÓ ao mergear um PR (é o caminho
#     verificado, com a dispensa nomeada quando o revisor do CI está sem crédito), e o push direto ao
#     main fica barrado também do lado do forge, inclusive para o dono. Medido antes de trocar: nenhum
#     workflow nem script de ops/ empurra ao main (grep `git push` em .github/workflows e ops/*.sh).
#     A troca de `always` para `pull_request` soma uma 2ª camada ao hook exit 2 sem travar a emergência
#     (CI morto): o merge de PR continua passando.
#
# Também garante que existam as labels que a maquinaria LÊ: `ci:full` (o nível PR a lê para forçar a
# bancada completa) e `review:ia` (o interruptor do revisor de IA a lê para forçar a revisão em qualquer
# modo — ops/review/review-mode-decide.sh). A lista vive em _LABELS_SPEC, abaixo.
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

_LABELS_SPEC="ci:full|B60205|força a bancada COMPLETA no PR (passo D de D_MERGE_PROCESS_ONION_2026_10)
review:ia|5319E7|Força o revisor de IA do CI neste PR, em qualquer ONION_REVIEW_MODE"

# A API de labels recusa descrição com mais de 100 CARACTERES (HTTP 422, medido em 2026-10-13: a de
# `review:ia` tinha 101 — contados com python3, em LC_ALL=C — e o script morria depois de já ter aplicado o ruleset). A conta é feita aqui,
# ANTES de qualquer chamada, em caracteres (não bytes: "ç" e "—" são um caractere para a API).
# O texto de `review:ia` é o que a label já tem no repo (lido com gh label list em 2026-10-13).
_LABEL_DESC_MAX=100
_long="$(printf '%s\n' "${_LABELS_SPEC}" | python3 -I -c '
import sys
for ln in sys.stdin.read().splitlines():
    if not ln.strip(): continue
    p = ln.split("|", 2)
    d = p[2] if len(p) > 2 else ""
    if len(d) > int(sys.argv[1]): print("%s (%d caracteres)" % (p[0], len(d)))' "${_LABEL_DESC_MAX}")" \
  || { echo "apply-ruleset-main: não consegui medir as descrições das labels" >&2; exit 2; }
[ -z "${_long}" ] || { echo "apply-ruleset-main: descrição de label acima de ${_LABEL_DESC_MAX} caracteres (a API devolve 422): ${_long//$'\n'/; }" >&2; exit 2; }

if [ "${DRY}" = "1" ]; then
  echo "── dry-run: ruleset '${NAME}' em repos/${REPO}/rulesets (cria ou atualiza pelo nome) ──"
  cat "${SPEC}"
  while IFS='|' read -r _ln _lc _ld; do
    echo "── dry-run: label '${_ln}' seria criada se ausente (gh label create ${_ln} --repo ${REPO}) ──"
  done <<< "${_LABELS_SPEC}"
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
# As labels que a maquinaria LÊ. Uma linha por label: nome|cor|descrição.
#   ci:full   → o nível PR da bancada força a completa (passo D de D_MERGE_PROCESS_ONION_2026_10)
#   review:ia → o interruptor do revisor de IA força a revisão em qualquer modo (D_REVIEW_MODE_SWITCH_PADRAO_OFF)
while IFS='|' read -r _ln _lc _ld; do
  [ -n "${_ln}" ] || continue
  if grep -qxF "${_ln}" <<< "${_labels}"; then
    echo "label '${_ln}' já existe"
  else
    gh label create "${_ln}" --repo "${REPO}" --color "${_lc}" --description "${_ld}" >/dev/null \
      && echo "label '${_ln}' criada" || { echo "apply-ruleset-main: não consegui criar a label ${_ln}" >&2; exit 1; }
  fi
done <<< "${_LABELS_SPEC}"
