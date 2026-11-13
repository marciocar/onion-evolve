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
# ── A REGRA DO `auto` (decisão do maestro de 2026-11-13, D_REVIEW_AUTO_WITH_FALLBACK_1113) ──────────────
# Revisa SÓ o PR que toca GUARDA. A lista NÃO mora aqui: é a do ops/review/guard-paths.sh, derivada do
# ops/moat-targets.tsv mais as cercas fixas, a mesma que o ops/pr-merge-verified.sh usa para exigir o resíduo
# independente em fallback. Conta o nome antigo e o novo do rename e o arquivo removido. O teto de linhas
# (600, medido em 2026-10-13) e o `.claude/validation/*` inteiro SAÍRAM da regra com a decisão: o PR comum,
# grande ou não, fica com o gate determinístico. Helper ou diff ilegível ⇒ REVISA (na dúvida, o lado que mede).
#
# ── O FALLBACK (a mesma decisão) ─────────────────────────────────────────────────────────────────────
# Quando o revisor não pode julgar (modo off, chave ausente, ou falta de crédito na API), o veredito NÃO
# fica vermelho por isso: sai verde com a marca, dizendo "não revisado pelo CI: <motivo>", e o motivo vai
# para o sumário do check e para um comentário no PR. Quem cobre o PR de guarda nesse caso é o
# ops/pr-merge-verified.sh, que exige o resíduo da REGRA 56 com Elenxo isolado (refutador independente).
# A falta de crédito se reconhece por `--classify-credit` (o pré-voo HTTP 400 "credit balance", ou a
# evidência do run com "Credit balance is too low" / api_error_status 400 com crédito).
#
# Uso:
#   decidir : bash ops/review/review-mode-decide.sh --mode "<valor>" [--labels-json '<array JSON>'] \
#                  [--range <base>...<head>] [--repo <dir>] [--guard-helper <guard-paths.sh>] [--targets <tsv>]
#             saída (stdout, pronta para o GITHUB_OUTPUT): run=true|false · mode=on|off|auto · reason=<linha>
#                  · guard=true|false|unknown · guard_paths=<caminhos de guarda tocados, separados por espaço>
#   veredito: bash ops/review/review-mode-decide.sh --verdict-gate --mode-result <r> --run <true|false> \
#                  --mode <m> --reason <texto> --review-result <r> [--summary-file <arq>] \
#                  [--guard <true|false|unknown>] [--guard-paths <lista>] [--comment-file <arq>]
#             exit 0 = revisão DESLIGADA (o check sai verde, com a anotação-marca) · 10 = segue para o
#             veredito normal · 1 = falha NOMEADA
#   crédito : bash ops/review/review-mode-decide.sh --classify-credit [--preflight-http <c>] \
#                  [--preflight-causa <txt>] [--evidence-dir <dir>]
#             exit 0 = a falha é FALTA DE CRÉDITO (stdout: a causa numa linha) · 1 = não é
#   fallback: bash ops/review/review-mode-decide.sh --fallback --reason <motivo> [--guard ...] \
#                  [--guard-paths ...] [--summary-file <arq>] [--comment-file <arq>]
#             exit 0 sempre: a anotação-marca "não revisado pelo CI: <motivo>", o sumário e o corpo do comentário
#   marca   : bash ops/review/review-mode-decide.sh --print-marker
# Exit (decidir): 0 decidido · 2 valor fora do enum / uso inválido (falha alta e nomeada, nunca silêncio).
# =============================================================================
set -uo pipefail

FORCE_LABEL="review:ia"
# a MARCA que o ops/pr-merge-verified.sh procura na anotação do check para saber que o verde é
# DESLIGAMENTO e não aprovação. Um lugar só: o merge-verified a lê por --print-marker.
MARKER="onion-review-desligado:"
# o corpo do comentário de fallback começa por esta marca, que o post-review-comment.sh usa para EDITAR o
# mesmo comentário a cada push (sticky), em vez de empilhar um por run
COMMENT_MARK="<!-- onion-review-fallback -->"

_die2() { printf 'review-mode-decide: %s\n' "$1" >&2; exit 2; }
_one_line() { printf '%s' "$1" | tr '\n\r' '  '; }
GUARD="unknown"; GUARD_PATHS=""
_decide() { # $1=run $2=mode $3=reason
  printf 'run=%s\nmode=%s\nreason=%s\nguard=%s\nguard_paths=%s\n' "$1" "$2" "$(_one_line "$3")" "${GUARD}" "$(_one_line "${GUARD_PATHS}")"
  printf 'review-mode-decide: run=%s (modo %s) — %s\n' "$1" "$2" "$3" >&2
  exit 0
}

# ── fallback: o texto único do "não revisado pelo CI" (anotação-marca, sumário e comentário) ─────────
# $1=motivo $2=guard $3=guard_paths $4=arquivo do sumário (ou vazio) $5=arquivo do comentário (ou vazio)
_fallback_emit() {
  local why gd gp summ cfile req
  why="$(_one_line "$1")"; gd="${2:-unknown}"; gp="$(_one_line "${3:-}")"; summ="${4:-}"; cfile="${5:-}"
  printf '::notice::%s não revisado pelo CI: %s\n' "${MARKER}" "${why}"
  case "${gd}" in
    true)  req="Este PR toca GUARDA (\`${gp:-?}\`). Sem o parecer do CI, o merge pela sessão (\`ops/pr-merge-verified.sh\`) exige o resíduo da REGRA 56 (\`docs/evolution/review/<branch>.md\`) com \`elenxo: true\` e \`elenxo_isolado: true\` (refutador independente), verdict aceito e \`reviewed_diff_sha256\` carimbado; sem ele, recusa." ;;
    false) req="Este PR não toca guarda: sem exigência extra, o gate determinístico (lint e bancada) segue cobrindo." ;;
    *)     req="Não medi se este PR toca guarda; o \`ops/pr-merge-verified.sh\` mede de novo na hora do merge e exige o resíduo independente se tocar." ;;
  esac
  if [ -n "${summ}" ]; then
    printf '%s\n' "## ⊘ Não revisado pelo CI: ${why}" "" \
      "O check sai verde por **fallback**, não por aprovação: a semântica NÃO foi medida pelo revisor de IA." "" \
      "${req}" "" \
      "Para forçar a revisão neste PR, ponha a label \`${FORCE_LABEL}\` (com crédito na API)." >> "${summ}"
  fi
  if [ -n "${cfile}" ]; then
    printf '%s\n' "${COMMENT_MARK}" "⊘ **Não revisado pelo CI: ${why}**" "" "${req}" "" \
      "_Fallback do revisor de IA (D_REVIEW_AUTO_WITH_FALLBACK_1113). Ligar, desligar e pôr crédito: \`docs/onion/review-mode-card.md\`._" > "${cfile}"
  fi
  return 0
}

# ── crédito: a falha do revisor é FALTA DE SALDO? (o único modo de falha que vira fallback) ─────────
_classify_credit() {
  local http="" causa="" ev=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --preflight-http) http="${2-}"; shift 2 ;;
      --preflight-causa) causa="${2-}"; shift 2 ;;
      --evidence-dir) ev="${2-}"; shift 2 ;;
      *) printf 'review-mode-decide --classify-credit: argumento desconhecido %s\n' "$1" >&2; return 2 ;;
    esac
  done
  # (1) o pré-voo: HTTP 400 com "credit balance" no corpo da API
  if [ "${http}" = "400" ] && LC_ALL=C grep -qiF 'credit balance' <<< "${causa}"; then
    printf 'sem crédito na API (pré-voo HTTP 400: %s)\n' "$(_one_line "${causa}" | cut -c1-200)"; return 0
  fi
  # (2) a evidência do run (artefato review-evidence): a mensagem literal, ou o status 400 junto de "credit"
  if [ -n "${ev}" ] && [ -d "${ev}" ]; then
    local f
    while IFS= read -r f; do
      [ -n "${f}" ] || continue
      if LC_ALL=C grep -qiF 'credit balance is too low' "${f}" \
         || { LC_ALL=C grep -qE '"api_error_status"[[:space:]]*:[[:space:]]*"?400' "${f}" && LC_ALL=C grep -qiF 'credit' "${f}"; }; then
        printf 'sem crédito na API (evidência do run: %s)\n' "${f##*/}"; return 0
      fi
    done < <(find "${ev}" -type f 2>/dev/null)
  fi
  return 1
}

# ── veredito: o que o check `onion-review-verdict` faz ANTES do veredito normal ───────────────────
_verdict_gate() {
  local mres="" run="" mode="" reason="" rres="" summ="" gd="unknown" gp="" cfile=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --guard) gd="${2-}"; shift 2 ;;
      --guard-paths) gp="${2-}"; shift 2 ;;
      --comment-file) cfile="${2-}"; shift 2 ;;
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
      # modo off é FALLBACK (o maestro desligou): sumário + comentário no PR. modo auto sem guarda é a regra
      # de necessidade dizendo "não precisa": sumário, sem comentário (não há o que pedir a ninguém).
      if [ "${mode}" = "auto" ]; then
        _fallback_emit "revisão desligada (modo auto, motivo: ${reason:-?})" "${gd}" "${gp}" "${summ}" ""
      else
        _fallback_emit "revisão desligada (modo ${mode:-?}, motivo: ${reason:-?})" "${gd}" "${gp}" "${summ}" "${cfile}"
      fi
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

_fallback_cli() {
  local why="" gd="unknown" gp="" summ="" cfile=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --reason) why="${2-}"; shift 2 ;;
      --guard) gd="${2-}"; shift 2 ;;
      --guard-paths) gp="${2-}"; shift 2 ;;
      --summary-file) summ="${2-}"; shift 2 ;;
      --comment-file) cfile="${2-}"; shift 2 ;;
      *) printf '::error::review-mode-decide --fallback: argumento desconhecido %s\n' "$1"; return 1 ;;
    esac
  done
  [ -n "${why}" ] || { printf '::error::review-mode-decide --fallback exige --reason (fallback sem motivo é verde mudo)\n'; return 1; }
  _fallback_emit "${why}" "${gd}" "${gp}" "${summ}" "${cfile}"
}

case "${1:-}" in
  --print-marker) printf '%s\n' "${MARKER}"; exit 0 ;;
  --classify-credit) shift; _classify_credit "$@"; exit $? ;;
  --fallback) shift; _fallback_cli "$@"; exit $? ;;
  --verdict-gate) shift; _verdict_gate "$@"; exit $? ;;
  -h|--help) sed -n '/^# Uso:/,/^# Exit (decidir)/p' "${BASH_SOURCE[0]}"; exit 0 ;;
esac

MODE_SET=0; MODE=""; LABELS_JSON=""; RANGE=""; REPO="."
GUARD_HELPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/guard-paths.sh"; TARGETS_ARG=()
while [ $# -gt 0 ]; do
  case "$1" in
    --mode) MODE_SET=1; MODE="${2-}"; shift 2 || _die2 "--mode exige valor (vazio vale: \"\")" ;;
    --labels-json) LABELS_JSON="${2-}"; shift 2 || _die2 "--labels-json exige valor" ;;
    --range) RANGE="${2-}"; shift 2 || _die2 "--range exige <base>...<head>" ;;
    --repo) REPO="${2-}"; shift 2 || _die2 "--repo exige diretório" ;;
    --guard-helper) GUARD_HELPER="${2-}"; shift 2 || _die2 "--guard-helper exige caminho" ;;
    --targets) TARGETS_ARG=(--targets "${2-}"); shift 2 || _die2 "--targets exige caminho" ;;
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

# (1b) a GUARDA, medida em todo modo quando há diff: o fallback diz ao PR se ele cai na exigência do resíduo.
#      A pergunta é do helper (a lista única); rc 2 dele (tsv ou diff ilegível) fica `unknown`, nunca `false`.
_guard_err=""
if [ -n "${RANGE}" ]; then
  _grc=0; _gout="$(bash "${GUARD_HELPER}" --range "${RANGE}" --git-dir "${REPO}" "${TARGETS_ARG[@]}" 2>&1)" || _grc=$?
  case "${_grc}" in
    0) GUARD=true; GUARD_PATHS="$(printf '%s\n' "${_gout}" | head -5 | paste -sd' ' -)" ;;
    1) GUARD=false ;;
    *) GUARD=unknown; _guard_err="$(printf '%s' "${_gout}" | head -c 160)" ;;
  esac
fi

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

# (3) modo auto: a regra de necessidade é a lista de guardas. Sem medida ⇒ REVISA (na dúvida, o lado que mede).
[ -n "${RANGE}" ] || _die2 "modo auto exige --range <base>...<head>"
case "${GUARD}" in
  true)  _decide true auto "o diff toca guarda: ${GUARD_PATHS} (lista do ops/review/guard-paths.sh)" ;;
  false) _decide false auto "o diff não toca nenhuma guarda (lista do ops/review/guard-paths.sh): o PR comum fica com o gate determinístico" ;;
  *)     _decide true auto "não medi se o diff ${RANGE} toca guarda (${_guard_err:-sem saída}) — na dúvida, revisa" ;;
esac
