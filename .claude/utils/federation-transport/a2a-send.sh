#!/usr/bin/env bash
# =============================================================================
# a2a-send.sh — o REMETENTE canônico da rede A2A do Onion.
#
# Graduado do spike F0 do configurador A2A (SAC-121, teste S2 = SAC-127), que generalizou o remetente
# conforme do spike cross-user (docs/evolution/research/a2a-cross-user-spike-2026-10/notebook/send-a2a.sh).
# Substitui o script próprio de cada remetente: monta o envelope {jws, signal} que o gate do receptor
# (a2a-verify.sh) aceita — RS256, header.kid, claims iss/aud/iat/exp/jti/body_sha256/thread, com
# body_sha256 = sha256 dos bytes UTF-8 do corpo — e o envia ao endpoint do receptor.
#
# SEGREDO NUNCA EM ARGV: o bearer do canal vai só por ARQUIVO de cabeçalho 0600 (curl -H @arquivo), e o
# corpo entra no jq por arquivo (--rawfile). Recusa token ou chave privada legível por grupo/outros (rc 2):
# segredo que outra conta da máquina lê é segredo vazado, e enviar com ele seria fingir que não.
#
# Uso: a2a-send.sh --from ID --to ID (--body "texto" | --body-file F) [opções]
#   --kid K / --key F     default <from>-1 / <cfg>/<kid>.key.pem  (o par do a2a-keygen.sh)
#   --endpoint URL        obrigatório para enviar (sem default: nada sai por acidente)
#   --token-file F        default <cfg>/bridge-token (bearer, modo 0600; NUNCA em argv)
#   --thread T            id da conversa (default: gerado) · --kind K (default question)
#   --jti J · --iat-offset S · --exp-offset S (default 300) · --no-exp · --resend F (cenários de teste)
#   --dry-run             monta e imprime o envelope, sem rede e sem gravar nada
#   --out F               salva o envelope enviado em F
#   <cfg> = ${XDG_CONFIG_HOME:-~/.config}/onion/a2a
# O bearer só viaja cifrado: --endpoint é https://, e http:// só para loopback (127.0.0.1, ::1, localhost).
# O corpo tem de ser UTF-8 válido (o jq troca byte inválido por U+FFFD e o hash deixaria de bater) e ter
# no máximo 8192 BYTES.
# Exit: 0 = HTTP 200 (ou dry-run) · 1 = HTTP != 200 · 2 = uso, segredo exposto, erro local ou ferramenta ausente
# Exercitado por lint-selftest.sh (run_federation_a2a_selftests).
# =============================================================================
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-${HOME}/.config}/onion/a2a"
ENDPOINT=""; TOKEN_FILE="${CFG}/bridge-token"; KEY=""; KID=""; FROM=""; TO=""
THREAD=""; KIND="question"; BODY=""; BODY_FILE=""; JTI=""
IAT_OFF=0; EXP_OFF=300; NO_EXP=""; RESEND=""; DRY=""; OUT=""

die() { echo "a2a-send: $*" >&2; exit 2; }
need() { [ "$#" -ge 2 ] && [ -n "$2" ] || die "$1 exige valor"; }
while [ "$#" -gt 0 ]; do case "$1" in
  --endpoint) need "$@"; ENDPOINT="$2"; shift 2 ;;
  --token-file) need "$@"; TOKEN_FILE="$2"; shift 2 ;;
  --key) need "$@"; KEY="$2"; shift 2 ;;
  --kid) need "$@"; KID="$2"; shift 2 ;;
  --from) need "$@"; FROM="$2"; shift 2 ;;
  --to) need "$@"; TO="$2"; shift 2 ;;
  --thread) need "$@"; THREAD="$2"; shift 2 ;;
  --kind) need "$@"; KIND="$2"; shift 2 ;;
  --body) need "$@"; BODY="$2"; shift 2 ;;
  --body-file) need "$@"; BODY_FILE="$2"; shift 2 ;;
  --jti) need "$@"; JTI="$2"; shift 2 ;;
  --iat-offset) need "$@"; IAT_OFF="$2"; shift 2 ;;
  --exp-offset) need "$@"; EXP_OFF="$2"; shift 2 ;;
  --no-exp) NO_EXP=1; shift ;;
  --resend) need "$@"; RESEND="$2"; shift 2 ;;
  --dry-run) DRY=1; shift ;;
  --out) need "$@"; OUT="$2"; shift 2 ;;
  -h|--help) sed -n '2,27p' "$0"; exit 0 ;;
  *) die "argumento desconhecido: $1" ;;
esac; done

for t in openssl jq; do command -v "$t" >/dev/null 2>&1 || die "ferramenta ausente: $t"; done
[ -n "${DRY}" ] || command -v curl >/dev/null 2>&1 || die "ferramenta ausente: curl"
case "${IAT_OFF}" in ''|*[!0-9-]*) die "--iat-offset inteiro" ;; esac
case "${EXP_OFF}" in ''|*[!0-9-]*) die "--exp-offset inteiro" ;; esac

# modo do ALVO (segue symlink): stat GNU (-c) ou BSD (-f); sem nenhum dos dois, vazio
_mode() { stat -L -c '%a' "$1" 2>/dev/null || stat -L -f '%Lp' "$1" 2>/dev/null; }
# segredo legível por grupo/outros = vazado: recusa em vez de usar (modo ilegível também recusa)
_private_or_die() {  # $1 = arquivo · $2 = o que é
  local m; m="$(_mode "$1")"; [ -n "${m}" ] || die "não consegui ler o modo de $2 ($1)"
  [ $(( 8#${m} & 8#077 )) -eq 0 ] || die "$2 está com modo ${m} (grupo/outros leem): chmod 600 $1, e trate-o como vazado se a máquina tem outras contas"
}

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
sha256_hex() { openssl dgst -sha256 | awk '{print $NF}'; }
rand_hex() { openssl rand -hex "$1"; }

WORK="$(mktemp -d)"; trap 'rm -rf "${WORK}"' EXIT
ENVFILE="${WORK}/env.json"; HDRFILE="${WORK}/hdr"

if [ -n "${RESEND}" ]; then
  [ -f "${RESEND}" ] || die "envelope para reenviar inexistente: ${RESEND}"
  cp "${RESEND}" "${ENVFILE}"
  JTI="$(jq -r '.jws' "${ENVFILE}" | cut -d. -f2 | tr '_-' '/+' | { s="$(cat)"; case $(( ${#s} % 4 )) in 2) s="${s}==";; 3) s="${s}=";; esac; printf '%s' "$s"; } | openssl base64 -d -A | jq -r '.jti')"
  THREAD="$(jq -r '.signal.thread // ""' "${ENVFILE}")"
else
  [ -n "${FROM}" ] && [ -n "${TO}" ] || die "uso: a2a-send.sh --from ID --to ID (--body T | --body-file F) [...]"
  [ -n "${KID}" ] || KID="${FROM}-1"
  case "${KID}" in *[!A-Za-z0-9._-]*|.*) die "kid inválido: ${KID}" ;; esac
  [ -n "${KEY}" ] || KEY="${CFG}/${KID}.key.pem"
  [ -f "${KEY}" ] || die "chave privada ausente: ${KEY} (gere com a2a-keygen.sh --member ${FROM})"
  _private_or_die "${KEY}" "a chave privada"
  # sentinela: `$(cat F)` comeria os \n finais e o corpo assinado deixaria de ser o arquivo
  if [ -n "${BODY_FILE}" ]; then [ -f "${BODY_FILE}" ] || die "body-file inexistente"; BODY="$(cat "${BODY_FILE}"; printf x)"; BODY="${BODY%x}"; fi
  [ -n "${BODY}" ] || die "corpo vazio: passe --body ou --body-file"
  printf '%s' "${BODY}" > "${WORK}/body"
  [ "$(LC_ALL=C wc -c < "${WORK}/body" | tr -d ' ')" -le 8192 ] || die "corpo > 8192 bytes"
  # UTF-8 válido: o jq (--rawfile) troca byte inválido por U+FFFD, e o body_sha256 dos bytes crus deixaria
  # de bater com o corpo que viaja (o gate vetaria body-mismatch). Ida e volta pelo jq tem de ser idêntica.
  jq -Rsj . < "${WORK}/body" | cmp -s - "${WORK}/body" || die "corpo não é UTF-8 válido"
  [ -n "${JTI}" ] || JTI="nb-$(rand_hex 12)"
  [ -n "${THREAD}" ] || THREAD="th-$(date +%Y%m%d)-$(rand_hex 4)"
  NOW="$(date +%s)"; IAT=$(( NOW + IAT_OFF )); EXP=$(( NOW + EXP_OFF ))
  BODY_SHA="$(printf '%s' "${BODY}" | sha256_hex)"
  SIGID="$(date +%Y-%m-%d)-${FROM}-${THREAD}-${JTI}"
  HDR="$(jq -cn --arg kid "${KID}" '{alg:"RS256",kid:$kid,typ:"JWT"}' | b64url)"
  if [ -n "${NO_EXP}" ]; then
    PL_JSON="$(jq -cn --arg iss "${FROM}" --arg aud "${TO}" --argjson iat "${IAT}" --arg jti "${JTI}" \
      --arg bs "${BODY_SHA}" --arg th "${THREAD}" '{iss:$iss,aud:$aud,iat:$iat,jti:$jti,body_sha256:$bs,thread:$th}')"
  else
    PL_JSON="$(jq -cn --arg iss "${FROM}" --arg aud "${TO}" --argjson iat "${IAT}" --argjson exp "${EXP}" --arg jti "${JTI}" \
      --arg bs "${BODY_SHA}" --arg th "${THREAD}" '{iss:$iss,aud:$aud,iat:$iat,exp:$exp,jti:$jti,body_sha256:$bs,thread:$th}')"
  fi
  PL="$(printf '%s' "${PL_JSON}" | b64url)"
  SIG="$(printf '%s' "${HDR}.${PL}" | openssl dgst -sha256 -sign "${KEY}" 2>/dev/null | b64url)" || die "não consegui assinar com ${KEY} (chave ilegível?)"
  [ -n "${SIG}" ] || die "não consegui assinar com ${KEY} (chave ilegível?)"
  # o corpo entra no jq por ARQUIVO (--rawfile), não por --arg: argv é legível por toda conta da máquina
  jq -n --arg jws "${HDR}.${PL}.${SIG}" --arg id "${SIGID}" --arg from "${FROM}" --arg to "${TO}" \
    --arg kind "${KIND}" --rawfile body "${WORK}/body" --arg bs "${BODY_SHA}" --arg th "${THREAD}" \
    '{jws:$jws, signal:{id:$id, direction:"upstream", from:$from, to:$to, kind:$kind,
      classification:"private", thread:$th, body:$body, body_sha256:$bs}}' > "${ENVFILE}"
fi

# o envelope leva o corpo (classification private): sai 0600, não com a umask do ambiente
if [ -n "${OUT}" ]; then ( umask 077; cp "${ENVFILE}" "${OUT}" ) || die "não consegui gravar ${OUT}"; fi
if [ -n "${DRY}" ]; then cat "${ENVFILE}"; echo "(dry-run: nada enviado, nada gravado)" >&2; exit 0; fi

[ -n "${ENDPOINT}" ] || die "--endpoint obrigatório para enviar (sem default de propósito)"
# o bearer só viaja cifrado; http:// só para loopback (teste local)
case "${ENDPOINT}" in
  https://*) ;;
  http://127.0.0.1[:/]*|http://127.0.0.1|http://localhost[:/]*|http://localhost|http://\[::1\][:/]*|http://\[::1\]) ;;
  http://*) die "--endpoint em http:// só para loopback; o bearer viajaria em claro: use https://" ;;
  *) die "--endpoint precisa ser https://" ;;
esac
case "${ENDPOINT}" in *://*@*) die "a URL do endpoint carrega credencial embutida; o bearer vai só pelo --token-file" ;; esac
[ -f "${TOKEN_FILE}" ] || die "token do canal ausente: ${TOKEN_FILE} (o receptor o entrega fora de banda)"
_private_or_die "${TOKEN_FILE}" "o token do canal"
# o bearer vai num arquivo de cabeçalho 0600, nunca em argv (ps e histórico o mostrariam).
# printf é builtin: o conteúdo do token não vira argv de processo nenhum.
( umask 077; printf 'Authorization: Bearer %s\n' "$(tr -d '\r\n' < "${TOKEN_FILE}")" > "${HDRFILE}" )

RESP="$(curl -sS -m 30 -o - -w '\n%{http_code}' -H @"${HDRFILE}" -H 'Content-Type: application/json' \
        --data-binary @"${ENVFILE}" "${ENDPOINT}" 2>&1)" || true
CODE="$(printf '%s' "${RESP}" | tail -n1)"; BODY_RESP="$(printf '%s' "${RESP}" | sed '$d')"
echo "${BODY_RESP}"
echo "http=${CODE} jti=${JTI} thread=${THREAD}" >&2
[ "${CODE}" = "200" ]
