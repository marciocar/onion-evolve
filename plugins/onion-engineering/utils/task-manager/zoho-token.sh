#!/usr/bin/env bash
# zoho-token.sh — devolve um access_token do Zoho REUSANDO o que ainda vale, em vez de emitir um por chamada.
#
# ── DEFEITO DATADO (2026-10-07, sinal de campo de um adotante) ───────────────────────────────
# O `client_credentials` devolve um token de 3600 s. Um cliente que pedia token novo a CADA chamada recebeu,
# depois de umas 30 emissões em poucos minutos, `{"error":"Access Denied","error_description":"You have made
# too many requests continuously…"}` e ficou ~5 minutos sem operar. Uma fase do /onion-engineering:work que atualiza
# várias tasks reproduz isso. O adapter só dizia que o token "se pede de novo" — conselho, não mecanismo.
#
# Uso (as credenciais vêm do AMBIENTE; carregue o .env DENTRO do mesmo comando, nunca para o contexto):
#   set -a; source .env; set +a; TOKEN="$(bash ${CLAUDE_PLUGIN_ROOT}/utils/task-manager/zoho-token.sh [--scope <escopos>])"
#   zoho-token.sh --invalidate [--scope <escopos>]     → apaga o cache (use depois de um 401)
#
# Variáveis: ZOHO_CLIENT_ID, ZOHO_CLIENT_SECRET (obrigatórias), ZOHO_ACCOUNTS_HOST (default .com),
#            ONION_ZOHO_TOKEN_CACHE_DIR (default ${XDG_CACHE_HOME:-$HOME/.cache}/onion).
# Exit: 0 token no stdout · 1 emissão recusada (o motivo vai ao stderr, SEM valores) · 2 uso inválido.
#
# Fronteiras:
# - O cache é POR ESCOPO E POR CLIENT: a chave é um hash de host|client_id|escopo, então um token de leitura
#   nunca serve a uma escrita, e dois clients na mesma máquina não se misturam.
# - Arquivo 600 em diretório 700, fora do git. O token é segredo de curta duração; o arquivo some ao expirar
#   da utilidade, mas não é apagado sozinho.
# - Margem de 300 s: um token a 5 minutos de expirar é renovado, para não morrer no meio de uma fase.
# - O segredo chega ao curl pela entrada padrão (`-K -`), nunca pela linha de comando (visível em /proc).
# - TETO: o limite de emissão (~30 em poucos minutos) é estimativa do adotante pela contagem de chamadas,
#   não um número documentado pela Zoho.
set -uo pipefail
umask 077

SCOPE="ZohoProjects.portals.READ,ZohoProjects.projects.ALL,ZohoProjects.tasks.ALL,ZohoProjects.tasklists.ALL,ZohoProjects.milestones.ALL"
MODE="get"; MARGIN=300
die() { printf 'zoho-token: %s\n' "$*" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --scope) shift; SCOPE="${1:?--scope exige a lista de escopos}" ;;
    --invalidate) MODE="invalidate" ;;
    *) die "argumento desconhecido: $1" ;;
  esac
  shift
done
[ -n "${ZOHO_CLIENT_ID:-}" ] && [ -n "${ZOHO_CLIENT_SECRET:-}" ] \
  || die "ZOHO_CLIENT_ID/ZOHO_CLIENT_SECRET ausentes do ambiente (carregue o .env no mesmo comando; ou rode /onion:setup-integration)"
AHOST="${ZOHO_ACCOUNTS_HOST:-https://accounts.zoho.com}"; AHOST="${AHOST%/}"

DIR="${ONION_ZOHO_TOKEN_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/onion}"
mkdir -p "${DIR}" && chmod 700 "${DIR}" || die "não consegui preparar o diretório do cache"
KEY="$(printf '%s|%s|%s' "${AHOST}" "${ZOHO_CLIENT_ID}" "${SCOPE}" | { sha256sum 2>/dev/null || shasum -a 256; } | cut -c1-16)"
FILE="${DIR}/zoho-token-${KEY}"

if [ "${MODE}" = invalidate ]; then rm -f "${FILE}"; exit 0; fi

# Uma emissão por vez: duas fases em paralelo esperam a mesma renovação em vez de emitirem duas.
if command -v flock >/dev/null; then exec 9>"${FILE}.lock"; flock -w 30 9 || true; fi

now="$(date +%s)"
if [ -f "${FILE}" ]; then
  read -r exp tok < "${FILE}" || true
  if [ -n "${tok:-}" ] && [ "${exp:-0}" -gt $((now + MARGIN)) ] 2>/dev/null; then  # CACHE-HIT
    printf '%s\n' "${tok}"; exit 0
  fi
fi

command -v curl >/dev/null || { printf 'zoho-token: curl ausente\n' >&2; exit 1; }
body="$(printf 'data = "grant_type=client_credentials"\ndata = "client_id=%s"\ndata = "client_secret=%s"\ndata = "scope=%s"\n' \
          "${ZOHO_CLIENT_ID}" "${ZOHO_CLIENT_SECRET}" "${SCOPE}" \
        | curl -s -K - -X POST "${AHOST}/oauth/v2/token")"
tok="$(printf '%s' "${body}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')"
ttl="$(printf '%s' "${body}" | sed -n 's/.*"expires_in":\([0-9][0-9]*\).*/\1/p')"
if [ -z "${tok}" ]; then
  # o campo `error` do Zoho é texto de diagnóstico ("Access Denied", "invalid_client"), não segredo
  err="$(printf '%s' "${body}" | sed -n 's/.*"error":"\([^"]*\)".*/\1/p')"
  printf 'zoho-token: emissão recusada (%s) — nada foi gravado no cache\n' "${err:-sem resposta legível}" >&2
  exit 1
fi
tmp="$(mktemp "${DIR}/.zoho-token.XXXXXX")"
printf '%s %s\n' "$(( now + ${ttl:-3600} ))" "${tok}" > "${tmp}" && chmod 600 "${tmp}" && mv -f "${tmp}" "${FILE}"
printf '%s\n' "${tok}"
