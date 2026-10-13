#!/usr/bin/env bash
# =============================================================================
# review-mode-decide.sh — o INTERRUPTOR do revisor de IA do CI (core-only)
#
# POR QUE EXISTE (decisão do maestro, 2026-10-13, D_REVIEW_MODE_SWITCH_PADRAO_OFF no grafo
# docs/onion/graph/review-gate-saldo-2026-09.kg.yaml): o `onion-review` rodava em TODO PR, e o
# maestro quer poder não usá-lo, "independente de crédito", porque nem todo PR tem necessidade real.
# Três modos, pela variável de repositório `ONION_REVIEW_MODE`:
#   on   → todo PR (o comportamento de antes);
#   off  → nunca (PADRÃO: variável ausente ou vazia = off);
#   auto → só quando o diff casa a regra de necessidade abaixo.
# A label `review:ia` no PR força a revisão em QUALQUER modo.
#
# A decisão vive AQUI, e não no YAML, pela lição que o próprio onion-review.yml registra: "o YAML não
# tem selftest — foi assim que a máquina quebrada sobreviveu meses parecendo sã". A bancada é a
# família `run_review_mode_selftests` de lint-selftest.sh.
#
# ── A REGRA DO `auto` (lista ÚNICA — a doc cita esta, não a copia) ───────────────────────────────
# Revisa quando o diff do PR contra a base (nomes antigos E novos: renomear um hook para docs/ não o
# tira da lista) toca algum destes caminhos:
#   .claude/hooks/*  .claude/validation/*  .github/workflows/*  .claude/settings.json
#   ops/update-*  ops/deploy-*  ops/mcp-*  ops/pr-merge-verified.sh  ops/merge-serial.sh
#   ops/apply-ruleset-main.sh  ops/review/* (este próprio juiz — quem muda o juiz é julgado)
# OU quando as linhas de CÓDIGO mudadas (adições + remoções fora de docs/ e de *.kg.yaml) passam de
# AUTO_MAX_CODE_LINES. Grafo, docs e projeções (tudo em docs/) sozinhos NÃO disparam.
# O TETO É MEDIDO, não escolhido (2026-10-13, últimos 100 PRs mergeados, arquivos por PR via
# `gh api pulls/<n>/files`): linhas de código por PR p50=198 · p70=470 · p75=579 · p90=1104. O teto é
# o p75 arredondado (600). Na mesma amostra, 78 dos 100 PRs tocaram um caminho da lista (77 deles por
# .claude/validation/), e entre os 22 que não tocaram o maior tinha 410 linhas de código — ou seja, o
# teto é a REDE para o PR grande fora da lista, e não mudou a decisão de nenhum PR medido.
#
# Uso:
#   decidir : bash ops/review/review-mode-decide.sh --mode "<valor>" [--labels-json '<array JSON>'] \
#                  [--range <base>...<head>] [--repo <dir>]
#             saída (stdout, pronta para o GITHUB_OUTPUT): run=true|false · mode=on|off|auto · reason=<linha>
#   veredito: bash ops/review/review-mode-decide.sh --verdict-gate --mode-result <r> --run <true|false> \
#                  --mode <m> --reason <texto> --review-result <r> [--summary-file <arq>]
#             exit 0 = revisão DESLIGADA (o check sai verde, com a anotação-marca) · 10 = segue para o
#             veredito normal · 1 = falha NOMEADA
#   marca   : bash ops/review/review-mode-decide.sh --print-marker
# Exit (decidir): 0 decidido · 2 valor fora do enum / uso inválido (falha alta e nomeada, nunca silêncio).
# =============================================================================
set -uo pipefail

FORCE_LABEL="review:ia"
AUTO_MAX_CODE_LINES=600
# a MARCA que o ops/pr-merge-verified.sh procura na anotação do check para saber que o verde é
# DESLIGAMENTO e não aprovação. Um lugar só: o merge-verified a lê por --print-marker.
MARKER="onion-review-desligado:"
SENSITIVE_PATHS=(
  '.claude/hooks/*'
  '.claude/validation/*'
  '.github/workflows/*'
  '.claude/settings.json'
  'ops/update-*'
  'ops/deploy-*'
  'ops/mcp-*'
  'ops/pr-merge-verified.sh'
  'ops/merge-serial.sh'
  'ops/apply-ruleset-main.sh'
  'ops/review/*'
)

_die2() { printf 'review-mode-decide: %s\n' "$1" >&2; exit 2; }
_one_line() { printf '%s' "$1" | tr '\n\r' '  '; }
_decide() { # $1=run $2=mode $3=reason
  printf 'run=%s\nmode=%s\nreason=%s\n' "$1" "$2" "$(_one_line "$3")"
  printf 'review-mode-decide: run=%s (modo %s) — %s\n' "$1" "$2" "$3" >&2
  exit 0
}
_is_sensitive() { local p="$1" g; for g in "${SENSITIVE_PATHS[@]}"; do
  # shellcheck disable=SC2254
  case "${p}" in ${g}) return 0 ;; esac; done; return 1; }

# ── veredito: o que o check `onion-review-verdict` faz ANTES do veredito normal ───────────────────
_verdict_gate() {
  local mres="" run="" mode="" reason="" rres="" summ=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --mode-result) mres="${2-}"; shift 2 ;;
      --run) run="${2-}"; shift 2 ;;
      --mode) mode="${2-}"; shift 2 ;;
      --reason) reason="${2-}"; shift 2 ;;
      --review-result) rres="${2-}"; shift 2 ;;
      --summary-file) summ="${2-}"; shift 2 ;;
      *) printf '::error::review-mode-decide --verdict-gate: argumento desconhecido %s\n' "$1"; return 1 ;;
    esac
  done
  _sum() { [ -n "${summ}" ] && printf '%s\n' "$@" >> "${summ}"; return 0; }
  if [ "${mres}" != "success" ]; then
    printf '::error::a decisão do modo do revisor NÃO concluiu (job onion-review-mode = %s) — valor de ONION_REVIEW_MODE fora de on|off|auto? Leia o job onion-review-mode. Sem decisão não há veredito.\n' "${mres:-vazio}"
    _sum "## ❌ Sem decisão de modo, sem veredito" "" "O job \`onion-review-mode\` saiu \`${mres:-vazio}\`. Confira \`vars.ONION_REVIEW_MODE\` (on|off|auto; vazio = off)."
    return 1
  fi
  case "${run}" in
    false)
      printf '::notice::%s revisão desligada (modo %s, motivo: %s)\n' "${MARKER}" "${mode:-?}" "$(_one_line "${reason:-?}")"
      _sum "## ⊘ Revisão de IA desligada neste PR" "" \
        "Modo \`${mode:-?}\` — ${reason:-?}." "" \
        "O check sai verde por **desligamento**, não por aprovação: a semântica NÃO foi medida." \
        "Para forçar a revisão neste PR, ponha a label \`${FORCE_LABEL}\`."
      return 0 ;;
    true)
      if [ "${rres}" = "skipped" ]; then
        printf '::error::a decisão mandou revisar (modo %s: %s) e o job onion-review foi PULADO — revisão que devia rodar e não rodou não é desligamento.\n' "${mode:-?}" "$(_one_line "${reason:-?}")"
        return 1
      fi
      return 10 ;;
    *)
      printf '::error::a decisão do modo saiu sem run=true|false (veio %s) — não invento um lado.\n' "${run:-vazio}"
      return 1 ;;
  esac
}

case "${1:-}" in
  --print-marker) printf '%s\n' "${MARKER}"; exit 0 ;;
  --verdict-gate) shift; _verdict_gate "$@"; exit $? ;;
  -h|--help) sed -n '/^# Uso:/,/^# Exit (decidir)/p' "${BASH_SOURCE[0]}"; exit 0 ;;
esac

MODE_SET=0; MODE=""; LABELS_JSON=""; RANGE=""; REPO="."
while [ $# -gt 0 ]; do
  case "$1" in
    --mode) MODE_SET=1; MODE="${2-}"; shift 2 || _die2 "--mode exige valor (vazio vale: \"\")" ;;
    --labels-json) LABELS_JSON="${2-}"; shift 2 || _die2 "--labels-json exige valor" ;;
    --range) RANGE="${2-}"; shift 2 || _die2 "--range exige <base>...<head>" ;;
    --repo) REPO="${2-}"; shift 2 || _die2 "--repo exige diretório" ;;
    *) _die2 "argumento desconhecido '$1'" ;;
  esac
done
[ "${MODE_SET}" -eq 1 ] || _die2 "--mode é obrigatório (passe \"\" para o padrão off)"

# (1) o MODO. Vazio = off (o padrão selado). Fora do enum = falha NOMEADA — e o enum é EXATO: " on",
#     "ON" e "Off " são recusados, não normalizados. Normalizar seria adivinhar o que o maestro quis.
case "${MODE}" in
  "") MODE=off; _mode_src="variável ausente ou vazia ⇒ padrão off" ;;
  on|off|auto) _mode_src="vars.ONION_REVIEW_MODE=${MODE}" ;;
  *) _die2 "ONION_REVIEW_MODE='${MODE}' fora do enum on|off|auto (exato, minúsculo, sem espaço; vazio = off). Corrija a variável do repositório — o revisor não decide sobre valor que não entende." ;;
esac

# (2) a LABEL força em qualquer modo. Pertinência EXATA no array JSON (nome de label é texto livre
#     de quem tem permissão de triagem; nunca interpolado, nunca casado por substring).
if [ -n "${LABELS_JSON}" ]; then
  command -v jq >/dev/null 2>&1 || _die2 "jq ausente — não consigo ler as labels, e 'não li' não vira 'sem label'"
  _has="$(printf '%s' "${LABELS_JSON}" | jq -r --arg l "${FORCE_LABEL}" 'if type=="array" then (map(select(.==$l))|length>0) else "invalido" end' 2>/dev/null)" \
    || _die2 "--labels-json ilegível: $(printf '%s' "${LABELS_JSON}" | head -c 80)"
  [ "${_has}" = "invalido" ] && _die2 "--labels-json não é um array JSON"
  [ "${_has}" = "true" ] && _decide true "${MODE}" "label ${FORCE_LABEL} no PR força a revisão (${_mode_src})"
fi

case "${MODE}" in
  on)  _decide true on "modo on: todo PR é revisado" ;;
  off) _decide false off "${_mode_src}; sem a label ${FORCE_LABEL}" ;;
esac

# (3) modo auto: a regra de necessidade. Diff ilegível ⇒ REVISA (na dúvida, o lado que mede).
[ -n "${RANGE}" ] || _die2 "modo auto exige --range <base>...<head>"
if ! _names="$(git -C "${REPO}" -c core.quotepath=off diff --name-status --no-renames "${RANGE}" -- 2>&1)"; then
  _decide true auto "o diff ${RANGE} não pôde ser lido ($(printf '%s' "${_names}" | head -c 100)) — na dúvida, revisa"
fi
while IFS=$'\t' read -r _st _p; do
  [ -n "${_p:-}" ] || continue
  _is_sensitive "${_p}" && _decide true auto "o diff toca ${_p} (caminho sensível da lista do auto)"
done <<< "${_names}"
if ! _num="$(git -C "${REPO}" -c core.quotepath=off diff --numstat --no-renames "${RANGE}" -- 2>&1)"; then
  _decide true auto "o numstat de ${RANGE} não pôde ser lido — na dúvida, revisa"
fi
_lines="$(printf '%s\n' "${_num}" | awk -F'\t' 'NF>=3 && $3 !~ /^docs\// && $3 !~ /\.kg\.yaml$/ {a=($1=="-")?0:$1; d=($2=="-")?0:$2; s+=a+d} END{print s+0}')"
if [ "${_lines}" -gt "${AUTO_MAX_CODE_LINES}" ]; then
  _decide true auto "${_lines} linhas de código mudadas (fora de docs/ e *.kg.yaml) passam do teto ${AUTO_MAX_CODE_LINES}"
fi
_decide false auto "nenhum caminho sensível e ${_lines} linhas de código (teto ${AUTO_MAX_CODE_LINES}) — grafo/docs/projeções sozinhos não disparam"
