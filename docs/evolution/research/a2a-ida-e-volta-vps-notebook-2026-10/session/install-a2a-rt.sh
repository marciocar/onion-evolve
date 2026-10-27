#!/usr/bin/env bash
# =============================================================================
# install-a2a-rt.sh — monta a sessão de TESTE da ida e volta VPS ↔ notebook (PRE-REGISTRO.md §4 e §5, item 9).
#
# Copia a peça de rascunho (a2a-rt-mcp.py), a moldura R15.2 e o gravador de tentativas para FORA da árvore de
# trabalho (~/.local/share/onion/a2a-rt/) e gera os dois arquivos que a linha de comando da sessão de teste usa:
#   ~/.local/share/onion/a2a-rt/mcp.json       a config do MCP a2a-rt (o único servidor da sessão)
#   ~/.local/share/onion/a2a-rt/settings.json  o gravador de tentativas em todo evento de ferramenta
# Nenhum segredo é lido, copiado ou gerado aqui: a peça não abre chave nem token.
#
# Uso: bash install-a2a-rt.sh --side notebook|vps [--core DIR]
#   notebook  A2A_RT_ME=maestro-peer-test; caixa = ~/.local/state/onion/a2a-rt/inbox (os envelopes [ok] da
#             retirada, copiados pelo marciocar com sudo install); verifica com a pública pinada do core
#   vps       A2A_RT_ME=onion-evolve; caixa = <core>/docs/evolution/inbox (só os docs do a2a-accept.sh)
#   --core    o checkout do core de onde se copia (default: a raiz deste repositório)
# Depois: claude --tools "" --strict-mcp-config --mcp-config ~/.local/share/onion/a2a-rt/mcp.json \
#                --settings ~/.local/share/onion/a2a-rt/settings.json --permission-mode default
# Exit: 0 montado · 2 uso ou arquivo ausente
# =============================================================================
set -euo pipefail
SIDE=""; CORE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
die() { echo "install-a2a-rt: $*" >&2; exit 2; }
while [ "$#" -gt 0 ]; do case "$1" in
  --side) [ "$#" -ge 2 ] || die "--side exige valor"; SIDE="$2"; shift 2 ;;
  --core) [ "$#" -ge 2 ] || die "--core exige valor"; CORE="$2"; shift 2 ;;
  -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
  *) die "argumento desconhecido: $1" ;;
esac; done
case "${SIDE}" in notebook|vps) ;; *) die "--side notebook|vps obrigatório" ;; esac
command -v jq >/dev/null 2>&1 || die "jq ausente"
MCP="${CORE}/.claude/utils/federation-transport/a2a-rt-mcp.py"
WRAP="${CORE}/.claude/utils/guardrails/onion-untrusted-wrap.sh"
REC="${CORE}/docs/evolution/research/a2a-cross-user-spike-2026-10/hooks/record-tool-attempts.sh"
PUB="${CORE}/docs/evolution/research/a2a-cross-user-spike-2026-10/keys/onion-evolve-spike-1.pub.pem"
for f in "${MCP}" "${WRAP}" "${REC}" "${PUB}"; do [ -f "${f}" ] || die "ausente: ${f}"; done

D="${HOME}/.local/share/onion/a2a-rt"; S="${HOME}/.local/state/onion/a2a-rt"
install -d -m 700 "${D}" "${S}" "${S}/inbox"
install -m 600 "${MCP}" "${D}/a2a-rt-mcp.py"
install -m 600 "${WRAP}" "${D}/onion-untrusted-wrap.sh"
install -m 700 "${REC}" "${D}/record-tool-attempts.sh"
install -m 644 "${PUB}" "${D}/onion-evolve-spike-1.pub.pem"

if [ "${SIDE}" = notebook ]; then
  ENVJ="$(jq -n --arg s "${S}" --arg in "${S}/inbox" --arg pub "${D}/onion-evolve-spike-1.pub.pem" \
    '{A2A_RT_ME:"maestro-peer-test", A2A_RT_STATE:$s, A2A_RT_INBOX_MODE:"envelope", A2A_RT_INBOX:$in,
      A2A_RT_PEER_PUB:$pub, A2A_RT_PEER_KID:"onion-evolve-spike-1"}')"
else
  [ -d "${CORE}/docs/evolution/inbox" ] || die "inbox do core ausente: ${CORE}/docs/evolution/inbox"
  ENVJ="$(jq -n --arg s "${S}" --arg in "${CORE}/docs/evolution/inbox" \
    '{A2A_RT_ME:"onion-evolve", A2A_RT_STATE:$s, A2A_RT_INBOX_MODE:"inbox-doc", A2A_RT_INBOX:$in}')"
fi
( umask 077
  jq -n --arg py "${D}/a2a-rt-mcp.py" --argjson env "${ENVJ}" \
    '{mcpServers:{"a2a-rt":{type:"stdio", command:"python3", args:["-I",$py], env:$env}}}' > "${D}/mcp.json"
  H="bash \"${D}/record-tool-attempts.sh\""
  jq -n --arg h "${H}" '
    def hk: [{hooks:[{type:"command", command:$h}]}];
    def hm: [{matcher:"*", hooks:[{type:"command", command:$h}]}];
    {permissions:{defaultMode:"default"},
     hooks:{SessionStart:hk, PreToolUse:hm, PermissionRequest:hm, PostToolUse:hm, PostToolUseFailure:hm}}' > "${D}/settings.json" )
echo "montado (${SIDE}) em ${D}:"
echo "  mcp.json      → servidor a2a-rt, A2A_RT_ME=$(jq -r '.mcpServers["a2a-rt"].env.A2A_RT_ME' "${D}/mcp.json"), caixa $(jq -r '.mcpServers["a2a-rt"].env.A2A_RT_INBOX' "${D}/mcp.json")"
echo "  settings.json → gravador de tentativas em ${A2A_SPIKE_STATE:-${HOME}/.local/state/onion/a2a-spike}/tool-attempts.jsonl"
echo "sessão de teste:"
echo "  claude --tools \"\" --strict-mcp-config --mcp-config ${D}/mcp.json --settings ${D}/settings.json --permission-mode default"
