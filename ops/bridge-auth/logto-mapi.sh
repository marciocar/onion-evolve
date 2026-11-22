#!/usr/bin/env bash
# =============================================================================
# logto-mapi.sh — biblioteca (source, nunca executada) da Management API do tenant `default` do Logto.
#
# Por quê existe (2026-11-22): o pré-flight do bootstrap circular, o token M2M, o `api` e o `mutate` moravam
# só dentro do ops/bridge-auth/logto-provision.sh. O 2º ato que precisou deles (o app OIDC do Gokapi,
# ops/bridge-auth/gokapi-oidc-provision.sh) ia copiar ~100 linhas, e cópia de código que lida com segredo
# envelhece em duas direções. Agora os dois fazem `source` daqui; o texto das mensagens é o mesmo do molde.
#
# O que muda em relação ao molde, de propósito:
#   - o secret do `m-default` e o Bearer token deixam de ir em argv do curl (eram visíveis em /proc/<pid>/cmdline
#     durante a chamada): vão por `curl -K -`, a config do curl pelo stdin; e o corpo JSON das chamadas vai por
#     `--data-binary @<(printf …)`, porque no molde ele carrega a senha gerada do usuário e o SMTP_PASS;
#   - `logto_api_strict` falha (rc ≠ 0) em HTTP ≥ 400; o `api` do molde segue tolerante, como sempre foi;
#   - MODO DE TESTE para a bancada (ops/testing/gokapi-oidc-provision-selftest.sh): ONION_LOGTO_MAPI_TEST=1 com
#     ONION_LOGTO_MAPI_BASE=http://127.0.0.1:<porta> (o Logto simulado), ONION_LOGTO_MAPI_MDEF_SECRET (o secret de
#     mentira do m-default: no teste nunca se toca docker nem sudo) e ONION_LOGTO_MAPI_ROOT=/tmp/… (onde caem
#     os arquivos que o chamador escreveria em /etc). Qualquer ONION_LOGTO_MAPI_* SEM o modo de teste é uso
#     inválido (rc 2): produção não se redireciona por ambiente.
#
# Contrato com quem faz source: `set -euo pipefail` já ligado; APPLY definido (0/1) antes de chamar `mutate`.
# Expõe: TOKEN_ORIGIN RESOLVE API_ORIGIN MAPI_DEFAULT PG_CONTAINER LOGTO_TEST LOGTO_ROOT TOKEN
#        say step logto_preflight logto_token api logto_api_strict mutate
# RC: 2 variável de teste fora do modo de teste · 4 secret do m-default ilegível · 5 token endpoint recusou ·
#     6 pré-flight (issuer do tenant admin fora do loopback)
# =============================================================================

# Segredo nunca no xtrace: quem roda com `bash -x` não pode ver o secret passar.
set +x

declare -F say  >/dev/null 2>&1 || say()  { printf '%s\n' "$*"; }
declare -F step >/dev/null 2>&1 || step() { printf '\n── %s\n' "$*"; }

LOGTO_TEST="${ONION_LOGTO_MAPI_TEST:-0}"
if [ "${LOGTO_TEST}" != 1 ] && grep -q '^ONION_LOGTO_MAPI_' <<< "$(env)"; then
  echo "ERRO: variável ONION_LOGTO_MAPI_* sem o modo de teste: produção não se redireciona por ambiente." >&2
  exit 2
fi

# BOOTSTRAP CIRCULAR, e como se quebra (medido 2026-07-26; a história inteira está no logto-provision.sh):
# o token SAI pelo console (tenant admin, onde o `m-default` vive), alcançado por --resolve no loopback, e as
# chamadas VÃO para o endpoint do tenant default (auth.onionevolve.com).
TOKEN_ORIGIN="https://console.onionevolve.com"   # tenant admin — onde m-default existe
RESOLVE="console.onionevolve.com:443:127.0.0.1"  # loopback-only, sem exposicao publica
API_ORIGIN="https://auth.onionevolve.com"        # tenant default — onde se provisiona
MAPI_DEFAULT="https://default.logto.app/api"
PG_CONTAINER="onion-vps-logto-postgres"
LOGTO_ROOT=""

if [ "${LOGTO_TEST}" = 1 ]; then
  _lm_base="${ONION_LOGTO_MAPI_BASE:?modo de teste sem ONION_LOGTO_MAPI_BASE}"
  # Só o loopback por HTTP: o modo de teste não pode virar um jeito de mandar o token a outro host.
  [[ "${_lm_base}" =~ ^http://127\.0\.0\.1:[0-9]+$ ]] || { echo "ERRO: ONION_LOGTO_MAPI_BASE tem de ser http://127.0.0.1:<porta>" >&2; exit 2; }
  LOGTO_ROOT="${ONION_LOGTO_MAPI_ROOT:?modo de teste sem ONION_LOGTO_MAPI_ROOT}"
  # `..` escaparia de /tmp (refutador: /tmp/.. virava o /etc/credstore real): resolve antes de conferir
  LOGTO_ROOT="$(realpath -m -- "${LOGTO_ROOT}")"
  case "${LOGTO_ROOT}" in /tmp/?*|/var/tmp/?*) ;; *) echo "ERRO: a raiz de teste tem de estar em /tmp: ${LOGTO_ROOT}" >&2; exit 2 ;; esac
  TOKEN_ORIGIN="${_lm_base}"; API_ORIGIN="${_lm_base}"; RESOLVE=""
fi

# curl para o issuer do tenant admin (o --resolve só em produção; o -k porque o vhost loopback é tls internal)
_lm_curl_admin() {
  if [ -n "${RESOLVE}" ]; then curl -sS -k --resolve "${RESOLVE}" "$@"; else curl -sS "$@"; fi
}

# Escapa um valor para string entre aspas da config do curl (`\` e `"`).
_lm_cfg_quote() { local v="${1//\\/\\\\}"; printf '%s' "${v//\"/\\\"}"; }

# --- pré-flight do nó circular -------------------------------------------------
# Sem isto, a ausência do vhost loopback aparece lá embaixo como `invalid_client` — erro que não diz NADA
# sobre a causa e custou uma sessão inteira para diagnosticar. [[fix-must-become-mechanism]]
logto_preflight() {
  step "pré-flight: o issuer do tenant admin está alcançável?"
  if ! grep -q "console.onionevolve.com/oidc" <<< "$(_lm_curl_admin --max-time 5 \
       "${TOKEN_ORIGIN}/oidc/.well-known/openid-configuration" 2>/dev/null)"; then
    cat >&2 <<'HELP'
ERRO: o issuer do tenant `admin` não responde no loopback.

  POR QUÊ: o app M2M `m-default` (o único que concede a Management API do tenant
  `default`) vive no tenant `admin`, e o Logto só RESOLVE esse tenant quando a
  requisição chega com origem exatamente igual ao ADMIN_ENDPOINT
  (https://console.onionevolve.com). Sem o vhost, tudo cai no OIDC do tenant
  `default` e o token endpoint responde `invalid_client` — sem dizer o motivo.

  CONSERTO — USE O MECANISMO QUE JA EXISTE, nao erga um vhost paralelo:

    bash ~/onion-vps-logto/console.sh on      # liga o vhost do console (publico, cert real)
    bash ~/onion-vps-logto/console.sh status  # confere
    bash ~/onion-vps-logto/console.sh off     # DESLIGUE ao terminar

  O maestro construiu esse liga/desliga de proposito: o console fica FORA do ar por
  padrao e so sobe na janela de configuracao. Ate 2026-07-28 este bloco mandava
  escrever um vhost loopback proprio — o autor ergueu e derrubou SEIS vezes num dia
  sem procurar o mecanismo que ja existia. Conselho nao se repete sozinho; ponteiro sim.

  ANTES DE DEIXAR LIGADO ALEM DA JANELA: o tenant `admin` esta com registro ABERTO
  (sign_up identifiers ["username"], password). Fechar antes de publicar de vez.

  NOTA: mexer no Caddy de produção é mudança que o maestro precisa AUTORIZAR NOMEANDO
  — não é inferível de um "pode seguir" genérico.
HELP
    exit 6
  fi
  say "   issuer do tenant admin OK (loopback)"
}

# --- token M2M (client_credentials) ---------------------------------------------
# O app `m-default` vive no tenant `admin` e carrega o papel machine:mapi:default, que concede a Management API
# do tenant `default`. O secret é lido do banco para a memória e NUNCA impresso nem posto em argv.
logto_token() {
  step "0. token M2M para a Management API do tenant default"
  # `|| true` NÃO é desleixo: sem ele, sob `set -euo pipefail`, a falha do docker mata o script NA ATRIBUIÇÃO —
  # e a checagem abaixo, que existe e dá a mensagem certa, NUNCA RODA (medido 2026-08-02).
  # E o docker exige sudo para usuário fora do grupo `docker`: tenta direto e cai para `sudo -n`.
  # No modo de teste NUNCA toca docker nem sudo: o secret de mentira vem de ONION_LOGTO_MAPI_MDEF_SECRET. Medido na
  # 1ª rodada da bancada (2026-11-22): o docker falso que falhava fazia o `sudo -n docker` REAL ler o secret do
  # Logto de verdade e mandá-lo, em HTTP aberto, ao Logto simulado; e o refutador apontou que, mesmo sem o sudo, um
  # teste sem o docker falso no PATH alcançaria o docker real (o operador está no grupo docker).
  local _secret _tok_resp
  if [ "${LOGTO_TEST}" = 1 ]; then
    _secret="${ONION_LOGTO_MAPI_MDEF_SECRET:-}"
  else
    _dk() { docker "$@" 2>/dev/null || sudo -n docker "$@" 2>/dev/null; }
    _secret="$(_dk exec "${PG_CONTAINER}" psql -U logto -d logto -tAc \
      "select secret from applications where id='m-default';" | tr -d ' \r\n' || true)"
  fi
  [ -n "${_secret}" ] || {
    cat >&2 <<'HELPSEC'
ERRO: não consegui ler o secret do app M2M `m-default` no banco do Logto.

  CAUSAS POSSÍVEIS, em ordem de probabilidade:
   1. docker exige sudo para este usuário e o `sudo -n` (sem senha) falhou;
   2. o container do Postgres não está de pé  → sudo docker ps | grep logto-postgres
   3. o app `m-default` não existe no tenant admin → rode o logto-provision.sh SEM --smtp para provisioná-lo.

  DIAGNÓSTICO EM UM COMANDO:
    sudo docker exec onion-vps-logto-postgres psql -U logto -d logto -tAc \
      "select id from applications where id='m-default';"
HELPSEC
    exit 4
  }
  # A credencial vai pela config do curl no stdin (`-K -`), nunca em argv.
  _tok_resp="$(printf 'user = "m-default:%s"\n' "$(_lm_cfg_quote "${_secret}")" \
    | _lm_curl_admin -K - -X POST "${TOKEN_ORIGIN}/oidc/token" \
        --data-urlencode grant_type=client_credentials \
        --data-urlencode "resource=${MAPI_DEFAULT}" \
        --data-urlencode scope=all || true)"
  unset _secret
  TOKEN="$(printf '%s' "${_tok_resp}" | jq -r '.access_token // empty' 2>/dev/null || true)"
  [ -n "${TOKEN}" ] || {
    echo "ERRO no token endpoint. Corpo (sem segredo):" >&2
    printf '%s\n' "${_tok_resp}" | jq -c 'del(.access_token)' >&2 2>/dev/null || echo "   (corpo não é JSON; omitido)" >&2
    exit 5
  }
  unset _tok_resp
  say "   token obtido (len=${#TOKEN})"
}

# --- chamadas à Management API ----------------------------------------------------
# O Bearer vai pela config do curl no stdin, nunca em argv.
_lm_auth_cfg() { printf 'header = "Authorization: Bearer %s"\n' "$(_lm_cfg_quote "${TOKEN}")"; }

api() { # api <METHOD> <PATH> [json-body] — tolerante (o comportamento do molde): devolve o corpo, rc do curl
  local m="$1" p="$2" b="${3:-}"
  if [ -n "$b" ]; then
    _lm_auth_cfg | curl -sS -K - -X "$m" "${API_ORIGIN}/api${p}" -H "Content-Type: application/json" --data-binary @<(printf '%s' "$b")
  else
    _lm_auth_cfg | curl -sS -K - -X "$m" "${API_ORIGIN}/api${p}"
  fi
}

logto_api_strict() { # logto_api_strict <METHOD> <PATH> [json-body] — rc ≠ 0 em HTTP ≥ 400 (corpo segue no stdout)
  local m="$1" p="$2" b="${3:-}"
  if [ -n "$b" ]; then
    _lm_auth_cfg | curl -sS --fail-with-body -K - -X "$m" "${API_ORIGIN}/api${p}" -H "Content-Type: application/json" --data-binary @<(printf '%s' "$b")
  else
    _lm_auth_cfg | curl -sS --fail-with-body -K - -X "$m" "${API_ORIGIN}/api${p}"
  fi
}

mutate() { # mutate <descrição> <METHOD> <PATH> <json>
  # A mensagem humana vai para STDERR de propósito: o STDOUT desta função é DADO (JSON que o chamador parseia
  # com jq). Misturar os dois faz o dry-run quebrar com "Invalid numeric literal".
  if [ "${APPLY}" = "1" ]; then api "$2" "$3" "$4"
  else printf '   [DRY-RUN] %s\n' "$1" >&2; printf '%s' '{}'; fi
}
