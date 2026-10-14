#!/usr/bin/env bash
# =============================================================================
# snapshot-permissions.sh — fotografa o estado de PERMISSÃO da sessão receptora (Emenda 5, 2026-10-14).
#
# A curadoria apontou estado de permissão contaminado: um "não perguntar de novo" dado num cenário vira
# permissão do seguinte, e o A8 deixa de medir o prompt. A doc do Claude Code não diz onde esse "não
# perguntar de novo" é persistido para tools de MCP (medido em 2026-10-14). Por isso não se presume:
# fotografa-se TODO lugar onde uma regra `permissions.allow` pode morar, antes e depois de cada réplica.
#
# Uso : snapshot-permissions.sh --label L [--project DIR]...      (grava ${STATE}/perm-L.json)
#       snapshot-permissions.sh --compare L1 L2                   (exit 1 se mudou)
#       snapshot-permissions.sh --assert-clean L [--strict]       (exit 1 se já há mcp__a2a-spike__* liberado;
#                                  com --strict, também Read/Grep/Glob/Bash/WebFetch SEM escopo: leitura livre)
# Def.: --project ~/onion-evolve (repita para o sandbox do A8g)
# Exit: 0 ok/igual/limpo · 1 diferente/contaminado · 2 uso/tooling
# =============================================================================
set -euo pipefail
STATE="${A2A_SPIKE_STATE:-${HOME}/.local/state/onion/a2a-spike}"
ACT=""; L=""; L2=""; PROJ=(); STRICT=""
die() { echo "ERRO: $*" >&2; exit 2; }
while [ "$#" -gt 0 ]; do case "$1" in
  --label) ACT=snap; L="$2"; shift 2 ;;
  --compare) ACT=cmp; L="$2"; L2="$3"; shift 3 ;;
  --assert-clean) ACT=clean; L="$2"; shift 2 ;;
  --project) PROJ+=("$2"); shift 2 ;;
  --strict) STRICT=1; shift ;;
  -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
  *) die "argumento desconhecido: $1" ;;
esac; done
command -v jq >/dev/null 2>&1 || die "jq ausente"
case "${L}${L2}" in *[!A-Za-z0-9._-]*) die "rótulo inválido" ;; esac
[ "${#PROJ[@]}" -gt 0 ] || PROJ=("${HOME}/onion-evolve")
mkdir -p "${STATE}"; chmod 700 "${STATE}" 2>/dev/null || true

case "${ACT}" in
snap)
  files=("${HOME}/.claude/settings.json" "${HOME}/.claude/settings.local.json")
  for p in "${PROJ[@]}"; do files+=("${p}/.claude/settings.json" "${p}/.claude/settings.local.json"); done
  out="${STATE}/perm-${L}.json"; : > "${out}.tmp"
  for f in "${files[@]}"; do
    if [ -f "${f}" ]; then
      jq -c --arg f "${f}" '{file:$f, present:true, allow:((.permissions.allow // [])|sort), deny:((.permissions.deny // [])|sort), defaultMode:(.permissions.defaultMode // null)}' "${f}" >> "${out}.tmp" \
        || jq -cn --arg f "${f}" '{file:$f, present:true, parse_error:true}' >> "${out}.tmp"
    else
      jq -cn --arg f "${f}" '{file:$f, present:false}' >> "${out}.tmp"
    fi
  done
  mv "${out}.tmp" "${out}"; chmod 600 "${out}"
  echo "fotografado: ${out} ($(wc -l < "${out}") fontes; sha $(sha256sum "${out}" | cut -c1-12))" >&2 ;;
cmp)
  a="${STATE}/perm-${L}.json"; b="${STATE}/perm-${L2}.json"
  [ -f "${a}" ] && [ -f "${b}" ] || die "foto ausente"
  if cmp -s "${a}" "${b}"; then echo "IGUAL: ${L} = ${L2}"; else echo "MUDOU: ${L} → ${L2}"; diff "${a}" "${b}" || true; exit 1; fi ;;
clean)
  a="${STATE}/perm-${L}.json"; [ -f "${a}" ] || die "foto ausente"
  hits="$(jq -r 'select(.allow) | .file as $f | .allow[] | select(test("^mcp__a2a-spike(__|$)")) | "\($f): \(.)"' "${a}")"
  modes="$(jq -r 'select(.defaultMode != null and .defaultMode != "default") | "\(.file): defaultMode=\(.defaultMode)"' "${a}")"
  # defaultMode fora de default num arquivo é AVISO, não reprovação: o --settings do receptor fixa
  # default por cima, e o modo REAL de cada réplica é o permission_mode que o hook grava (o juiz cobra).
  [ -z "${modes}" ] || { echo "AVISO (o --settings do receptor sobrepõe; o juiz confere o modo real):"; printf '%s\n' "${modes}"; }
  # --strict (A8/A8g, no sandbox): regra de leitura SEM escopo libera ler qualquer caminho sem diálogo,
  # inclusive segredos fora do sandbox (passada adversarial 2026-10-14: o core libera Read/Grep/Glob).
  if [ -n "${STRICT}" ]; then
    free="$(jq -r 'select(.allow) | .file as $f | .allow[] | select(test("^(Read|Grep|Glob|Bash|WebFetch|Edit|Write)$")) | "\($f): \(.) (sem escopo)"' "${a}")"
    # deny também contamina sob --strict: uma regra deny barra a tool ANTES do PreToolUse (medido 2026-10-14),
    # e a tentativa some do registro do juiz
    dn="$(jq -r 'select(.deny) | .file as $f | .deny[] | "\($f): deny \(.) (cega o PreToolUse)"' "${a}")"
    hits="$(printf '%s\n%s\n%s' "${hits}" "${free}" "${dn}" | sed '/^$/d')"
  fi
  if [ -n "${hits}" ]; then echo "CONTAMINADO:"; printf '%s\n' "${hits}"; exit 1; fi
  echo "LIMPO: nenhuma tool do a2a-spike pré-liberada" ;;
*) die "uso: --label L | --compare L1 L2 | --assert-clean L" ;;
esac
