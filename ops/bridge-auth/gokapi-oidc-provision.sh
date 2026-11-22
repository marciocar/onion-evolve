#!/usr/bin/env bash
# =============================================================================
# gokapi-oidc-provision.sh — provisiona o app OIDC do Gokapi no tenant `default` do Logto e grava o client id e
#                            o client secret no credstore do systemd, SEM console e SEM eco do segredo.
#
# Por quê existe (2026-11-22, spike do Gokapi, prazo 23/11): o `next` do ato gokapi-spike da vps-ops mandava o
# maestro criar o app clicando no console e COLAR o secret num `cat > /etc/credstore/…`. Clicar não é
# reproduzível, e colar segredo passa pela área de transferência e pelo terminal. A Management API resolve os
# dois, pelo mesmo caminho do ops/bridge-auth/logto-provision.sh (o molde: pré-flight do bootstrap circular,
# token M2M, idempotência, dry-run). As funções comuns vêm de logto-mapi.sh.
#
# Uso (como root, pelo maestro, com `!`; o console do Logto ligado na janela: ~/onion-vps-logto/console.sh on):
#   bash ops/bridge-auth/gokapi-oidc-provision.sh [--operator <username>]            DRY-RUN (só lê)
#   bash ops/bridge-auth/gokapi-oidc-provision.sh [--operator <username>] --apply    cria/acerta e grava
#   bash ops/bridge-auth/gokapi-oidc-provision.sh --check                            confere o credstore contra o Logto
#   bash ops/bridge-auth/gokapi-oidc-provision.sh --undo [--apply]                   apaga o app e os 2 arquivos
#
# O QUE O ATO DEIXA PRONTO:
#   - app «Traditional web» `onion-vps-gokapi` (um só: dois com o mesmo nome é recusa, nunca escolha);
#   - redirect https://transfer.onionevolve.com/oauth-callback · post sign-out https://transfer.onionevolve.com/
#     (deriva é corrigida pelo PATCH; como no Logto 1.46 ele SUBSTITUI o oidcClientMetadata inteiro, o ato manda
#     o objeto atual com só esses 2 campos trocados);
#   - SEM AUTO-CADASTRO — duas camadas, e o ato é honesto sobre qual é de quem:
#       · o auto-cadastro em si (signInMode) é do TENANT, não do app (medido no código do Logto 1.46:
#         sign-in-experience.signInMode, um por tenant). O ato LÊ e AVISA se estiver aberto; não muda o tenant,
#         porque isso afeta todos os apps (o logto-provision.sh deixa o P3.4 como ato à parte, de propósito);
#       · o que é do APP: o controle de acesso por app do Logto 1.46 (appLevelAccessControlEnabled + regras).
#         O ato põe o operador nas regras e liga o controle: mesmo com o tenant aberto, conta nova não entra no
#         Gokapi. O operador tem de existir (criar identidade humana é ato do maestro, como no molde);
#   - escopos `openid profile email`: escopo OIDC padrão não se concede por app no Logto (o cliente pede no
#     authorize). O ato confere que o issuer os anuncia em scopes_supported e declara que o Gokapi os pede;
#   - credstore: /etc/credstore/onion-vps-gokapi.oidc-client-id e .oidc-client-secret, 600 root:root, por
#     escrita atômica (mktemp no mesmo diretório + mv) e com o valor só pelo builtin printf (nunca em argv).
#     Arquivo que já bate com o Logto não é reescrito. O secret é o «Default secret» do app
#     (GET /applications/{id}/secrets; desde o 1.2x o Logto não devolve mais o secret no objeto do app).
#
# SAÍDA: só nomes, ids públicos (o client id É público) e rc. O secret nunca é impresso, nem o tamanho dele.
#
# EXIT: 0 ok · 2 uso inválido · 3 pré-requisito ausente · 4/5/6 token e pré-flight (logto-mapi.sh) ·
#       7 operador não existe · 8 estado ambíguo (2 apps com o nome, app de outro tipo, secret ambíguo) ·
#       9 a API recusou uma chamada · 10 credstore diverge do Logto (--check) · 11 --apply sem root
# =============================================================================

set -euo pipefail
set +x   # segredo nunca no xtrace

APP_NAME="onion-vps-gokapi"
APP_TYPE="Traditional"
PUBLIC_URL="https://transfer.onionevolve.com"
REDIRECT_URI="${PUBLIC_URL}/oauth-callback"
POST_LOGOUT_URI="${PUBLIC_URL}/"
WANT_SCOPES="openid profile email"
SECRET_NAME="Default secret"
OPERATOR="marcio"
APPLY=0
MODE=provision
APP_SECRET=""   # nunca herdado do ambiente

usage() { sed -n '/^# Uso/,/^# O QUE/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --apply)    APPLY=1 ;;
    --operator) OPERATOR="${2:?--operator precisa do username}"; shift ;;
    --check)    MODE=check ;;
    --undo)     MODE=undo ;;
    -h|--help)  usage ;;
    *) echo "argumento desconhecido: $1" >&2; exit 2 ;;
  esac
  shift
done
[ "${MODE}" = check ] && [ "${APPLY}" = 1 ] && { echo "ERRO: --check só lê; não combina com --apply" >&2; exit 2; }

for t in curl jq docker mktemp cmp; do
  command -v "$t" >/dev/null 2>&1 || { echo "ERRO: '$t' ausente — pré-requisito." >&2; exit 3; }
done

say()  { printf '%s\n' "$*"; }
step() { printf '\n── %s\n' "$*"; }
die()  { local rc="$1"; shift; printf 'ERRO: %s\n' "$*" >&2; exit "${rc}"; }

# shellcheck source=ops/bridge-auth/logto-mapi.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logto-mapi.sh"

CRED_DIR="${LOGTO_ROOT}/etc/credstore"
CRED_ID="${CRED_DIR}/${APP_NAME}.oidc-client-id"
CRED_SECRET="${CRED_DIR}/${APP_NAME}.oidc-client-secret"

# Escrever em /etc/credstore é de root. No modo de teste a raiz é /tmp e o chown root não se aplica.
if [ "${LOGTO_TEST}" != 1 ] && [ "$(id -u)" != 0 ]; then
  [ "${APPLY}" = 1 ] && die 11 "--apply grava em /etc/credstore: rode como root (sudo bash $0 … --apply)"
  [ "${MODE}" = check ] && die 11 "--check lê o credstore: rode como root (sudo bash $0 --check)"
fi

# Uma chamada que muda estado: falhou, para tudo, mostrando só a mensagem do Logto (nunca o corpo inteiro).
must() { # must <descrição> <METHOD> <PATH> [json]
  local _out
  if ! _out="$(logto_api_strict "$2" "$3" "${4:-}")"; then
    die 9 "$1: a API recusou ($(printf '%s' "${_out}" | jq -r '"\(.code // "?") \(.message // "")"' 2>/dev/null | head -c 200))"
  fi
  printf '%s' "${_out}"
}

# Compara o valor (em memória) com o arquivo sem passar o valor por argv: process substitution do builtin printf.
cred_matches() { [ -f "$2" ] && cmp -s <(printf '%s' "$1") "$2"; }

# cred_put <valor> <arquivo> <rótulo> — atômico (mktemp no mesmo diretório + mv), 600, root:root.
cred_put() {
  local _val="$1" _dst="$2" _label="$3"
  if cred_matches "${_val}" "${_dst}"; then say "   ${_label}: já bate com o Logto — não reescrito"; return 0; fi
  local _was="criado"; [ -e "${_dst}" ] && _was="ATUALIZADO (divergia do Logto)"
  if [ "${APPLY}" != 1 ]; then say "   [DRY-RUN] ${_label}: seria ${_was%% *} em ${_dst}"; return 0; fi
  # GLOBAL de propósito: sob `set -e` o bash desfaz o `local` antes de rodar o trap de EXIT, e o temporário (com o
  # valor dentro) ficava no credstore quando o chmod/chown/mv falhava (refutador, reproduzido, 2026-11-22)
  _CRED_TMP="$(umask 077; mktemp "${CRED_DIR}/.${APP_NAME}.XXXXXX")"
  trap 'rm -f -- "${_CRED_TMP:-}"' EXIT
  printf '%s' "${_val}" > "${_CRED_TMP}"
  chmod 600 "${_CRED_TMP}"
  [ "${LOGTO_TEST}" = 1 ] || chown root:root "${_CRED_TMP}"
  mv -f -- "${_CRED_TMP}" "${_dst}"
  _CRED_TMP=""
  trap - EXIT
  say "   ${_label}: ${_was} em ${_dst} (600)"
}

logto_preflight
logto_token

# --- o app pelo nome (exatamente um, ou nenhum) ---------------------------------
# GET /applications sem page/page_size devolve TODOS (paginação opcional no Logto 1.46): sem o teto de 20 que
# faria um app existente "sumir" e ser duplicado.
find_app() {
  local _all
  _all="$(must "listar apps" GET "/applications")"
  APP_MATCHES="$(printf '%s' "${_all}" | jq -c --arg n "${APP_NAME}" '[.[]? | select(.name==$n) | {id, type}]')"
  APP_COUNT="$(printf '%s' "${APP_MATCHES}" | jq 'length')"
  APP_ID="$(printf '%s' "${APP_MATCHES}" | jq -r '.[0].id // empty')"
  APP_CUR_TYPE="$(printf '%s' "${APP_MATCHES}" | jq -r '.[0].type // empty')"
  if [ "${APP_COUNT}" -gt 1 ]; then
    die 8 "há ${APP_COUNT} apps chamados ${APP_NAME} (ids: $(printf '%s' "${APP_MATCHES}" | jq -r '[.[].id]|join(", ")')): o ato não escolhe; apague o excedente e rode de novo"
  fi
  if [ -n "${APP_ID}" ] && [ "${APP_CUR_TYPE}" != "${APP_TYPE}" ]; then
    die 8 "o app ${APP_NAME} (id=${APP_ID}) é do tipo ${APP_CUR_TYPE}, não ${APP_TYPE}: o ato não converte nem apaga; resolva à mão"
  fi
}

# Escolhe o secret do app sem imprimir: o «Default secret» não expirado; sem ele, o único não expirado; senão, recusa.
read_app_secret() { # read_app_secret <app-id> → APP_SECRET
  local _list _now
  _now="$(( $(date +%s) * 1000 ))"
  _list="$(must "ler os secrets do app" GET "/applications/$1/secrets")"
  APP_SECRET="$(printf '%s' "${_list}" | jq -r --arg n "${SECRET_NAME}" --argjson now "${_now}" '
    [.[]? | select(.expiresAt == null or .expiresAt > $now)] as $live
    | ([$live[] | select(.name == $n)] | if length == 1 then .[0].value else empty end)
      // (if ($live | length) == 1 then $live[0].value else empty end)
      // empty')"
  unset _list
  [ -n "${APP_SECRET}" ] || die 8 "o app $1 não tem um secret inequívoco (nenhum «${SECRET_NAME}» válido e não há um único secret válido): crie ou apague no Logto e rode de novo"
}

# =============================================================================
if [ "${MODE}" = undo ]; then
  step "desfazer: app ${APP_NAME} e os 2 arquivos do credstore"
  find_app
  if [ -z "${APP_ID}" ]; then say "   app: não existe — nada a apagar no Logto"
  elif [ "${APPLY}" = 1 ]; then must "apagar o app" DELETE "/applications/${APP_ID}" >/dev/null; say "   app apagado (id=${APP_ID})"
  else say "   [DRY-RUN] apagaria o app (id=${APP_ID})"; fi
  for f in "${CRED_ID}" "${CRED_SECRET}"; do
    if [ ! -e "${f}" ]; then say "   ${f}: não existe"
    elif [ "${APPLY}" = 1 ]; then rm -f -- "${f}"; say "   ${f}: apagado"
    else say "   [DRY-RUN] apagaria ${f}"; fi
  done
  say ""
  say "   ⚠ O config.json do Gokapi guarda a sua cópia do secret: com o app apagado, o login OIDC do Gokapi para."
  say "     Para recomeçar o spike do zero, o down --apply --purge do ato gokapi-spike da vps-ops."
  step "RESUMO"; say "   modo: $([ "${APPLY}" = 1 ] && echo APPLY || echo DRY-RUN) · undo · rc 0"
  exit 0
fi

# =============================================================================
if [ "${MODE}" = check ]; then
  step "conferir o credstore contra o Logto (sem mostrar o segredo)"
  find_app
  [ -n "${APP_ID}" ] || die 10 "o app ${APP_NAME} não existe no Logto"
  read_app_secret "${APP_ID}"
  _bad=0
  if cred_matches "${APP_ID}" "${CRED_ID}"; then say "   client id     : bate (${APP_ID})"; else say "   client id     : DIVERGE ou ausente"; _bad=1; fi
  if cred_matches "${APP_SECRET}" "${CRED_SECRET}"; then say "   client secret : bate"; else say "   client secret : DIVERGE ou ausente"; _bad=1; fi
  unset APP_SECRET
  for f in "${CRED_ID}" "${CRED_SECRET}"; do
    [ -e "${f}" ] && say "   $(stat -c '%a %U:%G' "${f}") ${f}"
  done
  [ "${_bad}" = 0 ] || die 10 "o credstore não bate com o Logto: rode com --apply para regravar"
  say "   ✓ credstore == Logto"
  exit 0
fi

# =============================================================================
step "1. tenant default: auto-cadastro (signInMode é do TENANT, não do app)"
_mode="$(must "ler a experiência de login" GET "/sign-in-exp" | jq -r '.signInMode // "?"')"
case "${_mode}" in
  SignIn) say "   signInMode=SignIn — cadastro FECHADO no tenant" ;;
  *) say "   ⚠ signInMode=${_mode} — o tenant ACEITA cadastro. O controle de acesso do app (passo 4) segura o Gokapi;"
     say "     fechar o tenant é o P3.4 do logto-provision.sh, ato à parte (afeta todos os apps)." ;;
esac

step "2. escopos ${WANT_SCOPES} anunciados pelo issuer do tenant default"
_sup="$(curl -sS --max-time 5 "${API_ORIGIN}/oidc/.well-known/openid-configuration" 2>/dev/null | jq -c '.scopes_supported // []' 2>/dev/null || echo '[]')"
_missing=""
for s in ${WANT_SCOPES}; do printf '%s' "${_sup}" | jq -e --arg s "$s" 'index($s)' >/dev/null || _missing="${_missing} ${s}"; done
if [ -z "${_missing}" ]; then say "   anunciados (o Gokapi os pede no authorize; escopo OIDC padrão não se concede por app)"
else say "   ⚠ o issuer não anuncia:${_missing} — o login do Gokapi pode falhar"; fi

step "3. operador '${OPERATOR}' (tem de existir; criar identidade humana é ato do maestro)"
_uid="$(must "buscar o operador" GET "/users?search=$(jq -rn --arg u "${OPERATOR}" '$u|@uri')" \
  | jq -r --arg u "${OPERATOR}" '[.[]? | select(.username==$u)] | if length==1 then .[0].id else empty end')"
[ -n "${_uid}" ] || die 7 "o usuário '${OPERATOR}' não existe (ou não é único) no tenant default; use --operator <username>"
say "   existe (id=${_uid})"

step "4. app ${APP_TYPE} '${APP_NAME}'"
find_app
_meta="$(jq -nc --arg r "${REDIRECT_URI}" --arg p "${POST_LOGOUT_URI}" '{redirectUris:[$r], postLogoutRedirectUris:[$p]}')"
_created=0
if [ -z "${APP_ID}" ]; then
  if [ "${APPLY}" = 1 ]; then
    APP_ID="$(must "criar o app" POST "/applications" "$(jq -nc --arg n "${APP_NAME}" --arg t "${APP_TYPE}" --argjson m "${_meta}" \
      '{name:$n, type:$t, description:"Gokapi (transfer.onionevolve.com): login do operador por OIDC", oidcClientMetadata:$m}')" | jq -r '.id // empty')"
    [ -n "${APP_ID}" ] || die 9 "o Logto criou o app sem devolver o id"
    _created=1
    say "   criado (client id=${APP_ID})"
  else
    say "   [DRY-RUN] criaria o app ${APP_TYPE} ${APP_NAME} com redirect ${REDIRECT_URI}"
  fi
else
  say "   já existe (client id=${APP_ID})"
  # Todo estado ambíguo recusa ANTES de qualquer mutação: o secret se resolve aqui, não no passo 6 (o refutador
  # mediu PATCH e PUT feitos e só depois a recusa rc 8)
  read_app_secret "${APP_ID}"
  _full="$(must "ler o app" GET "/applications/${APP_ID}" | jq -c '.oidcClientMetadata // {}')"
  _cur="$(printf '%s' "${_full}" | jq -c '{redirectUris:(.redirectUris // []), postLogoutRedirectUris:(.postLogoutRedirectUris // [])}')"
  if [ "$(printf '%s' "${_cur}" | jq -S -c .)" = "$(printf '%s' "${_meta}" | jq -S -c .)" ]; then
    say "   redirect e post sign-out: já no estado desejado"
  elif [ "${APPLY}" = 1 ]; then
    # o PATCH do Logto 1.46 SUBSTITUI o oidcClientMetadata inteiro: manda o atual com os 2 campos trocados, para não
    # apagar o que o maestro configurou à mão (logo, back-channel…)
    must "acertar os redirects" PATCH "/applications/${APP_ID}" "$(jq -nc --argjson f "${_full}" --argjson m "${_meta}" '{oidcClientMetadata:($f + $m)}')" >/dev/null
    say "   redirect e post sign-out: ACERTADOS (estavam ${_cur})"
  else
    say "   [DRY-RUN] acertaria redirect e post sign-out (estão ${_cur})"
  fi
fi

step "5. controle de acesso do app: só o operador entra (sem auto-cadastro no Gokapi)"
if [ -n "${APP_ID}" ]; then
  _acl="$(must "ler o controle de acesso" GET "/applications/${APP_ID}/access-control")"
  if printf '%s' "${_acl}" | jq -e --arg u "${_uid}" '(.userIds // []) | index($u)' >/dev/null; then
    say "   operador já nas regras"
  elif [ "${APPLY}" = 1 ]; then
    # acrescenta, nunca substitui: quem o maestro pôs à mão continua
    must "pôr o operador nas regras" PUT "/applications/${APP_ID}/access-control" \
      "$(printf '%s' "${_acl}" | jq -c --arg u "${_uid}" '{userIds:((.userIds // []) + [$u] | unique), userRoleIds:(.userRoleIds // []), organizationIds:(.organizationIds // []), organizationRoleRules:(.organizationRoleRules // [])}')" >/dev/null
    say "   operador posto nas regras"
  else
    say "   [DRY-RUN] poria o operador (id=${_uid}) nas regras do app"
  fi
  _enabled="$(must "ler o app" GET "/applications/${APP_ID}" | jq -r '.appLevelAccessControlEnabled == true')"
  if [ "${_enabled}" = true ]; then
    say "   controle de acesso do app: já LIGADO"
  elif [ "${APPLY}" = 1 ]; then
    must "ligar o controle de acesso" PATCH "/applications/${APP_ID}" '{"appLevelAccessControlEnabled":true}' >/dev/null
    say "   controle de acesso do app: LIGADO"
  else
    say "   [DRY-RUN] ligaria o controle de acesso do app"
  fi
else
  say "   [DRY-RUN] poria o operador (id=${_uid}) nas regras e ligaria o controle de acesso do app novo"
fi

step "6. credstore ${CRED_DIR} (600 root, escrita atômica, sem eco)"
if [ "${LOGTO_TEST}" != 1 ] && [ "$(id -u)" != 0 ]; then
  say "   (sem root: o credstore não é legível daqui; o ensaio abaixo supõe os arquivos ausentes)"
fi
if [ -n "${APP_ID}" ]; then
  if [ ! -d "${CRED_DIR}" ]; then
    if [ "${APPLY}" = 1 ]; then install -d -m 700 "${CRED_DIR}"; say "   ${CRED_DIR}: criado (700)"
    else say "   [DRY-RUN] criaria ${CRED_DIR} (700)"; fi
  fi
  [ -n "${APP_SECRET:-}" ] || read_app_secret "${APP_ID}"   # app recém-criado: o secret ainda não foi lido
  cred_put "${APP_ID}" "${CRED_ID}" "client id"
  cred_put "${APP_SECRET}" "${CRED_SECRET}" "client secret"
  unset APP_SECRET
else
  say "   [DRY-RUN] gravaria ${CRED_ID} e ${CRED_SECRET} com o client id e o «${SECRET_NAME}» do app novo"
fi

step "RESUMO"
say "   modo          : $([ "${APPLY}" = 1 ] && echo APPLY || echo DRY-RUN)"
say "   app           : ${APP_NAME} (${APP_TYPE}) ${APP_ID:+client id=${APP_ID}}$([ "${_created}" = 1 ] && echo ' — criado agora')"
say "   redirect      : ${REDIRECT_URI}"
say "   post sign-out : ${POST_LOGOUT_URI}"
say "   operador      : ${OPERATOR} (id=${_uid})"
say "   credstore     : ${CRED_ID} · ${CRED_SECRET}"
say "   o secret não é impresso; confira com --check"
