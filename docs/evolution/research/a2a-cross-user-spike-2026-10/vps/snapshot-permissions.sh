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
#       snapshot-permissions.sh --assert-clean L [--strict] [--server S]... [--mcp-config F]...
#                                  (exit 1 se já há tool de um SERVIDOR DO TESTE liberada; com --strict, também
#                                  Read/Grep/Glob/Bash/WebFetch SEM escopo: leitura livre)
#   Servidores do teste: a2a-spike e a2a-rt sempre, mais cada --server e cada chave de .mcpServers de cada
#   --mcp-config (o mcp.json que a sessão carrega). Achado a, ida e volta de 2026-10-28: o casamento fixo em
#   ^mcp__a2a-spike deixou passar um "mcp__a2a-rt__read_inbox" lembrado e deu LIMPO. Guarda por lista falha pelo
#   VOCABULÁRIO: a lista agora nasce do teste, e um mcp.json ilegível ou nome fora da forma é erro (rc 2).
# Def.: --project ~/onion-evolve (repita para o sandbox do A8g)
# Exit: 0 ok/igual/limpo · 1 diferente/contaminado · 2 uso/tooling
# =============================================================================
set -euo pipefail
STATE="${A2A_SPIKE_STATE:-${HOME}/.local/state/onion/a2a-spike}"
ACT=""; L=""; L2=""; PROJ=(); STRICT=""; SERVERS=(a2a-spike a2a-rt); MCPC=()
die() { echo "ERRO: $*" >&2; exit 2; }
while [ "$#" -gt 0 ]; do case "$1" in
  --label) ACT=snap; L="$2"; shift 2 ;;
  --compare) ACT=cmp; L="$2"; L2="$3"; shift 3 ;;
  --assert-clean) ACT=clean; L="$2"; shift 2 ;;
  --project) PROJ+=("$2"); shift 2 ;;
  --strict) STRICT=1; shift ;;
  --server) [ "$#" -ge 2 ] || die "--server exige valor"; SERVERS+=("$2"); shift 2 ;;
  --mcp-config) [ "$#" -ge 2 ] || die "--mcp-config exige valor"; MCPC+=("$2"); shift 2 ;;
  -h|--help) sed -n '2,21p' "$0"; exit 0 ;;
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
  for c in "${MCPC[@]}"; do
    [ -f "${c}" ] || die "--mcp-config ausente: ${c}"
    names="$(jq -r '.mcpServers | keys[]' "${c}")" || die "--mcp-config ilegível (sem .mcpServers): ${c}"
    while IFS= read -r n; do [ -z "${n}" ] || SERVERS+=("${n}"); done <<< "${names}"
  done
  for n in "${SERVERS[@]}"; do case "${n}" in ''|*[!A-Za-z0-9_-]*) die "nome de servidor fora da forma: ${n}" ;; esac; done
  SJ="$(printf '%s\n' "${SERVERS[@]}" | jq -R . | jq -sc 'unique')"
  # por PREFIXO literal (startswith), não por regex montada do nome: o nome não vira metacaractere. Curinga mais
  # largo (mcp__*, mcp__a2a-*) que cobre um servidor do teste também conta (passada adversarial de 2026-10-28)
  hits="$(jq -r --argjson s "${SJ}" 'select(.allow) | .file as $f | .allow[] | . as $r
    | select([$s[] as $n | ($r == "mcp__" + $n) or ($r | startswith("mcp__" + $n + "__"))
      or (($r | startswith("mcp__")) and ($r | contains("*")) and (("mcp__" + $n + "__") | startswith($r | split("*")[0])))] | any) | "\($f): \(.)"' "${a}")"
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
  echo "LIMPO: nenhuma tool dos servidores do teste pré-liberada ($(jq -r 'join(", ")' <<< "${SJ}"))" ;;
*) die "uso: --label L | --compare L1 L2 | --assert-clean L" ;;
esac
