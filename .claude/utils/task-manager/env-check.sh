#!/usr/bin/env bash
# env-check.sh — confere e ajusta o .env do task manager SEM nunca ler, mostrar ou devolver um segredo.
#
# ── DEFEITO DATADO (2026-10-05, sinal de campo de um hub, dogfood do Zoho) ───────────────────
# O setup de integração mandava ler o .env com a ferramenta `Read` e afirmava que isso "não expõe valores".
# Expõe: `Read` devolve o arquivo inteiro ao modelo, e os segredos entram no contexto e no transcript. Este
# helper é o caminho que os comandos usam para olhar o .env, e o veto pretooluse-env-guard.sh barra os outros.
# Ele devolve NOMES de chave, o provider e — por --get — só chaves de uma lista fechada de NÃO-segredos.
#
# Uso:
#   env-check.sh [--env <arq>] --provider             → provider ativo (ambiente primeiro, depois o arquivo)
#   env-check.sh [--env <arq>] --check [<provider>]    → presença, por NOME, das chaves obrigatórias
#   env-check.sh [--env <arq>] --get <CHAVE>           → valor de uma chave NÃO-secreta (lista fechada)
#   env-check.sh [--env <arq>] --set-provider <p>      → grava SÓ TASK_MANAGER_PROVIDER (avisa se trocou)
#   env-check.sh [--env <arq>] --test [<provider>]     → teste de conexão SÓ-LEITURA (imprime o resultado)
#   env-check.sh [--env <arq>] --lint                  → defeitos de FORMA por NOME de chave (CR, espaço no
#                                                        fim, aspas desbalanceadas, chave repetida); nunca o valor
#
# --lint (SAC-68, 2026-10-08): a pergunta "a chave nova foi colada com \r no fim?" só se respondia com
# `grep -c $'\r' .env`, que o veto barra — e com razão, porque `grep` no .env é a forma mais perigosa de
# todas. O caminho sancionado responde a mesma pergunta sem tocar o valor. E o leitor daqui passou a
# tirar o \r final: uma chave colada de um editor Windows ou do celular saía com o \r e virava HTTP 401.
#
# Exit: 0 ok · 1 chave obrigatória ausente / teste reprovado · 2 uso inválido · 3 .env ausente (e nada no ambiente)
#       · 4 .env existe e está ILEGÍVEL (o valor pedido não veio do ambiente). --provider responde `ilegivel` nesse caso.
#       · 5 worktree sem .env, e o checkout principal tem um (só sem --env). --provider responde `worktree-sem-env`.
#
# ILEGÍVEL ≠ AUSENTE (2026-11-09, medido na curadoria sob sandbox): `[ -f ]` dava verdadeiro, o awk falhava em silêncio,
# e `--provider` respondia `ausente` com rc 0 com o provider declarado. O adapter ficava cego sem ninguém saber.
# WORKTREE SEM .env (2026-11-09, a curadoria corrigiu a própria medida): o `ausente` que ela viu vinha de uma worktree, onde o
# `.env` não existe e o checkout principal tem um. É a terceira resposta: inexistente, ilegível e worktree sem .env.
#
# Fronteiras (achados do Elenxo, 2026-10-06): o ambiente vence o arquivo (adotante com direnv/pass não tem
# .env); o .env é LIDO como dados, nunca executado (`. .env` rodaria código e interpretaria `$`/espaço);
# o segredo chega ao curl pela entrada padrão (`-K -`), nunca pela linha de comando (visível em /proc).
set -uo pipefail
umask 077

ENV_FILE=".env"; ENV_EXPLICIT=0; MODE=""; ARG=""
PROVIDERS=(jira clickup asana linear zoho none)
# chaves que NÃO são segredo e que comandos precisam ler (ids, hosts, escolhas de transporte)
SAFE_KEYS_RE='^(TASK_MANAGER_(PROVIDER|TRANSPORT)|FORGE_(PROVIDER|TRANSPORT)|FEDERATION_(LEDGER|MEMBER_ID)|[A-Z]+_DEFAULT_[A-Z_]*ID|[A-Z]+_WORKSPACE_ID|LINEAR_TEAM_ID|JIRA_(PROJECT_KEY|HOST|API_VERSION|AUTH_TYPE)|ZOHO_(PORTAL_ID|ACCOUNTS_HOST)|ASANA_DEFAULT_WORKSPACE)$'
die() { printf 'env-check: %s\n' "$*" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --env) shift; ENV_FILE="${1:?--env exige arquivo}"; ENV_EXPLICIT=1 ;;
    --provider|--check|--set-provider|--test|--get|--lint) MODE="${1#--}"; if [ $# -gt 1 ] && [ "${2#--}" = "$2" ]; then shift; ARG="$1"; fi ;;
    *) die "argumento desconhecido: $1" ;;
  esac
  shift
done
[ -n "${MODE}" ] || die "diga o que fazer: --provider | --check | --get <CHAVE> | --set-provider <p> | --test | --lint"

valid_provider() { local p; for p in "${PROVIDERS[@]}"; do [ "$1" = "$p" ] && return 0; done; return 1; }
required() {
  case "$1" in
    jira) echo "JIRA_HOST JIRA_EMAIL JIRA_API_TOKEN" ;; clickup) echo "CLICKUP_API_TOKEN" ;;
    asana) echo "ASANA_ACCESS_TOKEN" ;; linear) echo "LINEAR_API_KEY" ;;
    zoho) echo "ZOHO_CLIENT_ID ZOHO_CLIENT_SECRET ZOHO_PORTAL_ID" ;; none) echo "" ;; *) return 1 ;;
  esac
}
# abertura de verdade: sob sandbox `[ -r ]` responde legível para arquivo que o processo não consegue abrir (medido com bwrap)
# só arquivo regular: abrir um FIFO sem escritor penduraria o script, e o hook morreria no timeout sem aviso
env_opens() { [ -f "${ENV_FILE}" ] && { : < "${ENV_FILE}"; } 2>/dev/null; }
# valor de uma chave lido do arquivo COMO DADO: última ocorrência, `export ` opcional, aspas e comentário fora.
# Uso interno; só sai do script por --provider (validado) e --get (lista fechada).
file_value() {
  env_opens || return 0
  awk -v k="$1" '
    { line=$0; sub(/\r$/, "", line); sub(/^[ \t]*export[ \t]+/, "", line) }
    line ~ "^[ \t]*" k "[ \t]*=" {
      v=line; sub("^[ \t]*" k "[ \t]*=[ \t]*", "", v)
      if (v ~ /^"/) { sub(/^"/, "", v); sub(/".*$/, "", v) }
      else if (v ~ /^'"'"'/) { sub(/^'"'"'/, "", v); sub(/'"'"'.*$/, "", v) }
      else { sub(/[ \t]+#.*$/, "", v); sub(/[ \t]+$/, "", v) }
      last=v; found=1
    }
    END { if (found) printf "%s", last }' "${ENV_FILE}"
}
# ambiente primeiro (direnv/pass/source), depois o arquivo
value_of() { local v="${!1:-}"; [ -n "$v" ] && { printf '%s' "$v"; return; }; file_value "$1"; }
has_key() { [ -n "$(value_of "$1")" ]; }
# existe e não dá para ler (sandbox, permissão): é outra resposta que "ausente"
env_unreadable() { [ -e "${ENV_FILE}" ] && ! env_opens; }
# os avisos de rc 4 e 5 vão ao stderr: quem captura `--get` numa variável não pode guardar o aviso como valor
die_unreadable() { echo "⚠️  ${ENV_FILE} existe mas está ilegível (sandbox ou permissão): não dá para saber o que ele declara" >&2; exit 4; }
# worktree ligada, sem .env aqui, com um no checkout principal (só `test -e` nele; o conteúdo não é lido)
main_checkout_env() {
  local gd cd
  gd="$(git rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  cd="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  [ "${gd}" != "${cd}" ] && [ -e "$(dirname "${cd}")/.env" ] && printf '%s' "$(dirname "${cd}")/.env"
}
# em subpasta, conta o .env da RAIZ da worktree: subpasta de worktree com .env na raiz não é "worktree sem .env"
worktree_without_env() {
  local top
  [ "${ENV_EXPLICIT}" = 0 ] && [ ! -e "${ENV_FILE}" ] || return 1
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  [ ! -e "${top}/.env" ] && main_checkout_env >/dev/null
}
die_worktree() { echo "⚠️  esta worktree não tem ${ENV_FILE}, e o checkout principal tem: rode com --env <checkout-principal>/.env" >&2; exit 5; }

case "${MODE}" in
  set-provider)
    env_unreadable && die_unreadable
    p="${ARG:-}"; [ -n "${p}" ] || die "--set-provider exige o provider"
    valid_provider "${p}" || die "provider desconhecido: '${p}' (válidos: ${PROVIDERS[*]})"
    [ -f "${ENV_FILE}" ] || : > "${ENV_FILE}"
    old="$(file_value TASK_MANAGER_PROVIDER)"
    if grep -Eq '^[[:space:]]*(export[[:space:]]+)?TASK_MANAGER_PROVIDER[[:space:]]*=' "${ENV_FILE}"; then
      tmp="$(mktemp)"
      sed -E "s/^[[:space:]]*(export[[:space:]]+)?TASK_MANAGER_PROVIDER[[:space:]]*=.*/TASK_MANAGER_PROVIDER=${p}/" "${ENV_FILE}" > "${tmp}" && cat "${tmp}" > "${ENV_FILE}"
      rm -f "${tmp}"
    else
      printf 'TASK_MANAGER_PROVIDER=%s\n' "${p}" >> "${ENV_FILE}"
    fi
    if [ -n "${old}" ] && [ "${old}" != "${p}" ]; then
      valid_provider "${old}" && echo "⚠️  TASK_MANAGER_PROVIDER trocado: ${old} → ${p}" || echo "⚠️  TASK_MANAGER_PROVIDER trocado: (valor inválido) → ${p}"
    else echo "✅ TASK_MANAGER_PROVIDER=${p}"; fi
    echo "   Carregue na sessão: set -a; source ${ENV_FILE}; set +a"
    exit 0 ;;
  lint)
    env_unreadable && die_unreadable
    worktree_without_env && die_worktree
    [ -f "${ENV_FILE}" ] || { echo "⚠️  ${ENV_FILE} não encontrado"; exit 3; }
    # só NOMES e o tipo do defeito saem daqui; o valor nunca é impresso
    awk '
      { raw=$0; cr=sub(/\r$/, "", raw) }
      raw ~ /^[ \t]*(#|$)/ { next }
      { line=raw; sub(/^[ \t]*export[ \t]+/, "", line)
        if (line !~ /^[A-Za-z_][A-Za-z0-9_]*[ \t]*=/) { printf "  ❌ linha %d: não é CHAVE=valor\n", NR; bad=1; next }
        k=line; sub(/[ \t]*=.*$/, "", k); v=line; sub(/^[^=]*=[ \t]*/, "", v)
        if (cr) { printf "  ❌ %s: termina em \\r (fim de linha Windows) — o valor sai com o \\r grudado\n", k; bad=1 }
        if (v ~ /^"/ && v !~ /^"[^"]*"/) { printf "  ❌ %s: aspas duplas sem fechar\n", k; bad=1 }
        if (v ~ /^'"'"'/ && v !~ /^'"'"'[^'"'"']*'"'"'/) { printf "  ❌ %s: aspas simples sem fechar\n", k; bad=1 }
        if (v !~ /^["'"'"']/ && v ~ /[ \t]+$/) { printf "  ⚠️  %s: espaço no fim do valor (o leitor o tira; outros leitores não)\n", k }
        if (seen[k]++) { printf "  ⚠️  %s: chave repetida — vale a última\n", k }
      }
      END { if (!bad) print "✅ forma do arquivo sem defeito"; exit bad }' "${ENV_FILE}"
    exit $? ;;
  get)
    k="${ARG:-}"; [ -n "${k}" ] || die "--get exige a chave"
    [[ "${k}" =~ ${SAFE_KEYS_RE} ]] || die "'${k}' não está na lista de chaves NÃO-secretas — segredo não sai por aqui"
    [ -z "${!k:-}" ] && env_unreadable && die_unreadable
    [ -z "${!k:-}" ] && worktree_without_env && die_worktree
    # chave da lista pode carregar credencial embutida em URL (`https://user:token@host`): sai mascarada
    value_of "${k}" | sed -E 's#(://)[^/@]*@#\1***@#'; echo; exit 0 ;;
esac

P="${ARG:-$(value_of TASK_MANAGER_PROVIDER)}"
if [ -z "${P}" ] && env_unreadable; then [ "${MODE}" = provider ] && { echo "ilegivel"; echo "env-check: ${ENV_FILE} existe mas está ilegível" >&2; exit 4; }; die_unreadable; fi
if [ -z "${P}" ] && worktree_without_env; then [ "${MODE}" = provider ] && { echo "worktree-sem-env"; echo "env-check: worktree sem ${ENV_FILE}; o checkout principal tem um. Use --env" >&2; exit 5; }; die_worktree; fi
# --provider responde "ausente" (é resposta, não erro: a skill o injeta no contexto); --check/--test declaram rc=3
if [ "${MODE}" != provider ] && [ ! -f "${ENV_FILE}" ] && [ -z "${P}" ]; then echo "⚠️  ${ENV_FILE} não encontrado e TASK_MANAGER_PROVIDER ausente do ambiente"; exit 3; fi

case "${MODE}" in
  provider)
    if [ -z "${P}" ]; then echo "ausente"; elif valid_provider "${P}"; then echo "${P}"; else echo "invalido"; fi
    exit 0 ;;
  check)
    [ -n "${P}" ] || { echo "❌ TASK_MANAGER_PROVIDER ausente"; exit 1; }
    valid_provider "${P}" || { echo "❌ TASK_MANAGER_PROVIDER inválido (fora de: ${PROVIDERS[*]})"; exit 1; }
    keys="$(required "${P}")"
    echo "provider: ${P}"
    miss=0
    for k in ${keys}; do if has_key "$k"; then echo "  ✅ $k"; else echo "  ❌ $k"; miss=1; fi; done
    [ -z "${keys}" ] && echo "  (none: modo offline, nenhuma chave exigida)"
    [ "${miss}" -ne 0 ] && env_unreadable && die_unreadable
    exit "${miss}" ;;
  test)
    valid_provider "${P}" || die "provider desconhecido ou ausente"
    [ "${P}" = none ] && { echo "none: nada a testar (modo offline)"; exit 0; }
    # sem ler o .env o token sairia vazio e a resposta seria um 401 enganoso: pare antes da rede
    for k in $(required "${P}"); do
      has_key "$k" && continue
      env_unreadable && die_unreadable
      worktree_without_env && die_worktree
    done
    command -v curl >/dev/null || die "curl ausente — teste de conexão impossível"
    v() { value_of "$1"; }
    # cfg vai ao curl pela entrada padrão (-K -): o segredo nunca aparece na linha de comando
    req() { curl -s -o /dev/null -w '%{http_code}' -K - "$@"; }
    case "${P}" in
      clickup) code="$(printf 'header = "Authorization: %s"\n' "$(v CLICKUP_API_TOKEN)" | req https://api.clickup.com/api/v2/user)" ;;
      linear)  code="$(printf 'header = "Authorization: %s"\nheader = "Content-Type: application/json"\ndata = "{\\"query\\":\\"{ viewer { id } }\\"}"\n' "$(v LINEAR_API_KEY)" | req https://api.linear.app/graphql)" ;;
      asana)   code="$(printf 'header = "Authorization: Bearer %s"\n' "$(v ASANA_ACCESS_TOKEN)" | req https://app.asana.com/api/1.0/users/me)" ;;
      jira)    host="$(v JIRA_HOST)"; host="${host#https://}"; host="${host%/}"
               if [ "$(v JIRA_AUTH_TYPE)" = bearer ]; then cfg="$(printf 'header = "Authorization: Bearer %s"\n' "$(v JIRA_API_TOKEN)")"
               else cfg="$(printf 'user = "%s:%s"\n' "$(v JIRA_EMAIL)" "$(v JIRA_API_TOKEN)")"; fi
               code="$(printf '%s\n' "${cfg}" | req "https://${host}/rest/api/$(v JIRA_API_VERSION | grep . || echo 3)/myself")" ;;
      zoho)    ahost="$(v ZOHO_ACCOUNTS_HOST)"; ahost="${ahost:-https://accounts.zoho.com}"
               tld="${ahost##*accounts.zoho.}"; tld="${tld%%/*}"
               # o token vem do helper com cache por escopo (2026-10-07: emitir por chamada bloqueou o client
               # de um adotante por ~5 min). As credenciais vão pelo ambiente do filho, nunca pela linha de comando.
               tok="$(ZOHO_CLIENT_ID="$(v ZOHO_CLIENT_ID)" ZOHO_CLIENT_SECRET="$(v ZOHO_CLIENT_SECRET)" ZOHO_ACCOUNTS_HOST="${ahost}" \
                      bash "$(dirname "${BASH_SOURCE[0]}")/zoho-token.sh" --scope ZohoProjects.portals.READ)"
               if [ -z "${tok}" ]; then code="token-negado"
               else
                 body="$(printf 'header = "Authorization: Zoho-oauthtoken %s"\n' "${tok}" | curl -s -K - "https://projects.zoho.${tld}/api/v3/portals")"
                 pid="$(v ZOHO_PORTAL_ID)"
                 printf '%s' "${body}" | grep -Eq "\"id\":\"?${pid:-x}\"?[,}]" && code=200 || code="portal-fora"
               fi ;;
    esac
    case "${code}" in
      200) echo "✅ ${P}: conexão OK (só-leitura)"; exit 0 ;;
      token-negado) echo "❌ ${P}: o datacenter recusou a credencial (confira ZOHO_ACCOUNTS_HOST e o client)"; exit 1 ;;
      portal-fora) echo "❌ ${P}: a credencial vale, mas ZOHO_PORTAL_ID não está entre os portais que ela enxerga"; exit 1 ;;
      *) echo "❌ ${P}: conexão reprovada (HTTP ${code:-sem-resposta})"; exit 1 ;;
    esac ;;
esac
