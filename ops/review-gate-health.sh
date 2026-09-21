#!/usr/bin/env bash
# review-gate-health.sh — o gate de achados esta MEDINDO, ou virou verde silencioso?
#
# POR QUE EXISTE (decisao do maestro, 2026-09-21). O gate do `onion-review-verdict` reprova quando
# o parecer aponta violacao, mas `achados = -1` (NAO PUDE CONTAR) nunca bloqueia — e isso e
# deliberado: transformar ignorancia em bloqueio e a classe que esta casa mais persegue. O preco
# declarado dessa escolha e um modo de morte silenciosa: se o revisor derivar de fraseado, ou se a
# fiacao do output quebrar, TODO PR cai em `-1`, o check fica VERDE com um aviso, e ninguem nota
# que o gate parou de medir. A passada adversarial de 2026-09-20 nomeou exatamente isso: "nao
# existe nenhuma catraca/telemetria que grite 'N PRs seguidos em -1'".
#
# Este script e essa catraca. Le os check-runs REAIS dos ultimos PRs e classifica cada um pelo que
# o job DECLAROU no proprio titulo/resumo — comportamento, nao suposicao.
#
# USO
#   bash ops/review-gate-health.sh [--last N=20] [--max-streak K=3]
#   bash ops/review-gate-health.sh --selftest      # so a classificacao, sem rede
#
# EXIT: 0 = saudavel · 1 = sequencia de INERTE >= K (o gate parou de medir) · 2 = erro de uso/rede
set -uo pipefail

# ── A CLASSIFICACAO E PURA (sem rede) PARA PODER TER BANCADA ─────────────────────────────────
# O YAML nao tem selftest; um script que so existisse como `gh | jq | if` teria a mesma doenca.
# ⚠️ A SAUDE SE MEDE CRUZANDO DUAS FONTES INDEPENDENTES, e a 1a versao deste script errou o campo
#    TRES vezes antes de chegar aqui — vale registrar, porque cada erro e de uma classe que esta
#    casa persegue:
#      · lia `mergeCommit` → os check-runs vivem no HEAD do PR; devolveu 0 classificacoes;
#      · lia `.output.title/summary` → o GitHub NAO popula esses campos a partir do
#        `GITHUB_STEP_SUMMARY`: sao ESTRUTURALMENTE vazios, e a telemetria nasceria inerte —
#        dentro do script feito para detectar inercia;
#      · lia `annotations` → `::notice::`/`::warning::` de step nao viram anotacao de check-run.
#    O desenho que sobrevive nao depende de nenhum campo decorativo: compara o PARECER (o que o
#    revisor DISSE, no comentario do PR) contra a CONCLUSAO do check (o que o gate FEZ).
#
# INERT = o parecer aponta violacao E o check passou. E o unico estado que significa GATE CEGO, e
# so o cruzamento o revela: olhando so o check, ele e verde; olhando so o parecer, ele acusa.
classify_pr() { # $1=achados do parecer (N|-1|vazio)  $2=conclusao do check (success|failure|…)
  local n="${1:-}" concl="${2:-}"
  [ -n "${n}" ] || { printf '%s' NO-PARECER; return 0; }
  case "${n}" in ''|*[!0-9-]*) printf '%s' UNCOUNTABLE; return 0 ;; esac
  if [ "${n}" = "-1" ]; then printf '%s' UNCOUNTABLE; return 0; fi
  if [ "${n}" -ge 1 ]; then
    [ "${concl}" = "failure" ] && printf '%s' BLOCKED || printf '%s' INERT
    return 0
  fi
  [ "${concl}" = "success" ] && printf '%s' MEASURED || printf '%s' MISMATCH
}

run_selftest() {
  local rc=0 got
  _case() { # $1=rotulo $2=achados $3=conclusao $4=esperado
    got="$(classify_pr "$2" "$3")"
    if [ "${got}" = "$4" ]; then printf '  ✓ review-gate-health: %s\n' "$1"
    else printf '  ✗ review-gate-health: %s — veio %s, esperado %s\n' "$1" "${got}" "$4"; rc=1; fi
  }
  # O ESTADO QUE O SCRIPT EXISTE PARA ACHAR: o revisor acusou e o gate deixou passar.
  _case 'INERT: parecer acusa 3 e o check PASSOU (gate cego)' 3 success INERT
  _case 'BLOCKED: parecer acusa 3 e o check reprovou (saudavel)' 3 failure BLOCKED
  _case 'MEASURED: parecer conforme e check verde' 0 success MEASURED
  _case 'MISMATCH: parecer conforme mas o check reprovou' 0 failure MISMATCH
  _case 'UNCOUNTABLE quando o parecer nao se deixa contar' -1 success UNCOUNTABLE
  _case 'UNCOUNTABLE para lixo, nunca saude' lixo success UNCOUNTABLE
  _case 'NO-PARECER quando o PR nao tem parecer nenhum' '' success NO-PARECER
  printf '\n  %s\n' "$([ "${rc}" = 0 ] && echo 'OK — classificacao integra' || echo 'FALHOU')"
  return "${rc}"
}

LAST=20; MAX_STREAK=3
while [ $# -gt 0 ]; do
  case "$1" in
    --selftest)   run_selftest; exit $? ;;
    --last)       LAST="${2:?--last exige N}"; shift 2 ;;
    --max-streak) MAX_STREAK="${2:?--max-streak exige K}"; shift 2 ;;
    *) printf 'review-gate-health: argumento desconhecido %s\n' "$1" >&2; exit 2 ;;
  esac
done

command -v gh >/dev/null 2>&1 || { printf 'review-gate-health: `gh` ausente — nao sei medir, e "nao sei" nunca vira "saudavel".\n' >&2; exit 2; }
repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)" || { printf 'review-gate-health: nao consegui resolver o repo.\n' >&2; exit 2; }

# ⚠️ O SHA E O DO **HEAD DO PR**, NAO O DO MERGE. Os check-runs sao anexados ao commit que o CI
#    exercitou — o head da branch —, e o commit de merge nao tem nenhum. A 1a versao consultava
#    `mergeCommit.oid` e devolvia ZERO classificacoes nos 12 PRs; pior, DECLARAVA SAUDE sobre isso.
# ⚠️ O SHA E O DO **HEAD DO PR**: os check-runs sao anexados ao commit que o CI exercitou, e o
#    commit de merge nao tem nenhum. A 1a versao lia `mergeCommit.oid` e devolvia zero.
prs="$(gh pr list --state merged --limit "${LAST}" --json number,headRefOid --jq '.[] | "\(.number)\t\(.headRefOid)"' 2>/dev/null)" || true
[ -n "${prs}" ] || { printf 'review-gate-health: nenhum PR mergeado lido — nada a medir.\n' >&2; exit 2; }

_VERDICT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.claude/validation/review-verdict.sh"
[ -f "${_VERDICT}" ] || { printf 'review-gate-health: review-verdict.sh AUSENTE (%s) — sem o contador nao ha o que cruzar.\n' "${_VERDICT}" >&2; exit 2; }

streak=0; worst=0; inert=0; measured=0; blocked=0; mismatch=0; uncount=0; noparecer=0; lines=""
while IFS=$'\t' read -r num sha; do
  [ -n "${sha}" ] || continue
  # (a) o PARECER — o que o revisor DISSE. Contado pelo MESMO motor do gate, entao a telemetria
  #     mede a maquina real, nao uma re-implementacao que poderia divergir dela em silencio.
  body="$(gh pr view "${num}" --json comments --jq '[.comments[] | select(.body|contains("onion-review-parecer"))] | last | .body // ""' 2>/dev/null || true)"
  ach=""
  if [ -n "${body}" ]; then
    _tmp="$(mktemp)"; printf '{"type":"result","subtype":"success","is_error":false,"num_turns":1,"total_cost_usd":0,"result":%s}\n' \
      "$(printf '%s' "${body}" | jq -Rs .)" > "${_tmp}"
    ach="$(bash "${_VERDICT}" "${_tmp}" 2>/dev/null | awk -F= '/^achados=/{print $2}')"
    rm -f "${_tmp}"
  fi
  # (b) o que o GATE FEZ.
  concl="$(gh api "repos/${repo}/commits/${sha}/check-runs?per_page=100" \
    --jq '.check_runs[] | select(.name=="onion-review-verdict") | .conclusion' 2>/dev/null | head -1 || true)"
  [ -n "${concl}" ] || continue
  k="$(classify_pr "${ach}" "${concl}")"
  case "${k}" in
    INERT)       inert=$((inert+1));       streak=$((streak+1)) ;;
    BLOCKED)     blocked=$((blocked+1));   streak=0 ;;
    MEASURED)    measured=$((measured+1)); streak=0 ;;
    MISMATCH)    mismatch=$((mismatch+1)) ;;
    UNCOUNTABLE) uncount=$((uncount+1));   streak=$((streak+1)) ;;
    *)           noparecer=$((noparecer+1)) ;;
  esac
  [ "${streak}" -gt "${worst}" ] && worst="${streak}"
  lines="${lines}  #${num}	${k}	(parecer=${ach:-—} check=${concl})
"
done <<< "${prs}"

# ⚠️ ZERO CLASSIFICADO NAO E SAUDE — e a 1a versao deste script cometeu exatamente isso: leu 12
#    PRs, classificou nenhum e imprimiu ✅. Varredura vazia que devolve aprovacao e fail-open com
#    cara de cobertura. "Nao sei" sai por exit 2, nunca por verde.
_total=$((measured+blocked+inert+mismatch+uncount+noparecer))
if [ "${_total}" -eq 0 ]; then
  printf 'review-gate-health: li %s PR(s) e nao classifiquei nenhum — sem dado nao ha veredito de saude.\n' "${LAST}" >&2
  exit 2
fi

printf '%s' "${lines}"
printf '\nmedido=%s bloqueou=%s INERTE=%s incontavel=%s divergente=%s sem-parecer=%s · pior sequencia cega=%s (teto %s)\n' \
  "${measured}" "${blocked}" "${inert}" "${uncount}" "${mismatch}" "${noparecer}" "${worst}" "${MAX_STREAK}"

if [ "${inert}" -gt 0 ]; then
  printf '\n✗ GATE CEGO EM %s PR(s): o parecer apontou violacao e o check PASSOU. Este estado NAO\n' "${inert}" >&2
  printf '  aparece em `gh pr checks` — so o cruzamento parecer x conclusao o revela.\n' >&2
  exit 1
fi
if [ "${worst}" -ge "${MAX_STREAK}" ]; then
  printf '\n✗ O GATE PAROU DE MEDIR: %s PRs seguidos sem contagem utilizavel. Verde nesse estado,\n' "${worst}" >&2
  printf '  entao invisivel no `gh pr checks`. Conferir o passo "Qual contagem de achados vale".\n' >&2
  exit 1
fi
printf '\n✅ o gate esta medindo (%s classificado(s); sequencia cega maxima %s < %s)\n' "${_total}" "${worst}" "${MAX_STREAK}"
