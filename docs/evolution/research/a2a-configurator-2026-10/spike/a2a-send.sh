#!/usr/bin/env bash
# =============================================================================
# a2a-send.sh — REMETENTE A2A generalizado (spike F0 do configurador A2A, SAC-121 / teste S1 = SAC-126).
#
# Graduação de docs/evolution/research/a2a-cross-user-spike-2026-10/notebook/send-a2a.sh: o mesmo
# envelope ({jws, signal}) conforme ao gate do core (a2a-verify.sh) — RS256, header.kid, claims
# iss/aud/iat/exp/jti/body_sha256/thread, body_sha256 = sha256 dos bytes UTF-8 do corpo —, mas sem
# identidade de teste embutida: membro, kid, chave e destino vêm por flag.
# Diferenças declaradas contra o original:
#   - sem endpoint default: --endpoint é obrigatório fora do --dry-run (nada sai por acidente);
#   - --dry-run imprime o envelope e NÃO toca disco (o original gravava env.XXXXXX no estado);
#   - curl só é exigido quando vai enviar (o original exigia curl até no --dry-run);
#   - kid default = <from>-1 e chave default = ~/.config/onion/a2a/<kid>.key.pem (o par do a2a-keygen.sh).
# O bearer do canal vai só por ARQUIVO de cabeçalho 0600 (curl -H @arquivo) — nunca em argv.
#
# Uso: a2a-send.sh --from ID --to ID (--body "texto" | --body-file F) [opções]
#   --kid K / --key F     default <from>-1 / ~/.config/onion/a2a/<kid>.key.pem
#   --endpoint URL        obrigatório para enviar
#   --token-file F        default ~/.config/onion/a2a/bridge-token (bearer; NUNCA em argv)
#   --thread T            id da conversa (default: gerado) · --kind K (default question)
#   --jti J · --iat-offset S · --exp-offset S (default 300) · --no-exp · --resend F
#   --dry-run             monta e imprime o envelope, sem rede e sem gravar
#   --out F               salva o envelope enviado em F
# Exit: 0 = HTTP 200 (ou dry-run) · 1 = HTTP != 200 · 2 = uso/tooling
# =============================================================================
set -euo pipefail

CFG="${HOME}/.config/onion/a2a"
ENDPOINT=""; TOKEN_FILE="${CFG}/bridge-token"; KEY=""; KID=""; FROM=""; TO=""
THREAD=""; KIND="question"; BODY=""; BODY_FILE=""; JTI=""
IAT_OFF=0; EXP_OFF=300; NO_EXP=""; RESEND=""; DRY=""; OUT=""

die() { echo "ERRO: $*" >&2; exit 2; }
while [ "$#" -gt 0 ]; do case "$1" in
  --endpoint) ENDPOINT="${2:-}"; shift 2 ;;
  --token-file) TOKEN_FILE="${2:-}"; shift 2 ;;
  --key) KEY="${2:-}"; shift 2 ;;
  --kid) KID="${2:-}"; shift 2 ;;
  --from) FROM="${2:-}"; shift 2 ;;
  --to) TO="${2:-}"; shift 2 ;;
  --thread) THREAD="${2:-}"; shift 2 ;;
  --kind) KIND="${2:-}"; shift 2 ;;
  --body) BODY="${2:-}"; shift 2 ;;
  --body-file) BODY_FILE="${2:-}"; shift 2 ;;
  --jti) JTI="${2:-}"; shift 2 ;;
  --iat-offset) IAT_OFF="${2:-}"; shift 2 ;;
  --exp-offset) EXP_OFF="${2:-}"; shift 2 ;;
  --no-exp) NO_EXP=1; shift ;;
  --resend) RESEND="${2:-}"; shift 2 ;;
  --dry-run) DRY=1; shift ;;
  --out) OUT="${2:-}"; shift 2 ;;
  -h|--help) sed -n '2,27p' "$0"; exit 0 ;;
  *) die "argumento desconhecido: $1" ;;
esac; done

for t in openssl jq; do command -v "$t" >/dev/null 2>&1 || die "ferramenta ausente: $t"; done
[ -n "${DRY}" ] || command -v curl >/dev/null 2>&1 || die "ferramenta ausente: curl"
case "${IAT_OFF}" in ''|*[!0-9-]*) die "--iat-offset inteiro" ;; esac
case "${EXP_OFF}" in ''|*[!0-9-]*) die "--exp-offset inteiro" ;; esac

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
  [ -n "${KEY}" ] || KEY="${CFG}/${KID}.key.pem"
  [ -f "${KEY}" ] || die "chave privada ausente: ${KEY} (gere com a2a-keygen.sh --member ${FROM})"
  # sentinela: `$(cat F)` comeria os \n finais e o corpo assinado deixaria de ser o arquivo
  if [ -n "${BODY_FILE}" ]; then [ -f "${BODY_FILE}" ] || die "body-file inexistente"; BODY="$(cat "${BODY_FILE}"; printf x)"; BODY="${BODY%x}"; fi
  [ -n "${BODY}" ] || die "corpo vazio: passe --body ou --body-file"
  [ "${#BODY}" -le 8192 ] || die "corpo > 8192 caracteres"
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
  SIG="$(printf '%s' "${HDR}.${PL}" | openssl dgst -sha256 -sign "${KEY}" | b64url)"
  # o corpo entra no jq por ARQUIVO (--rawfile), não por --arg: corpo não é segredo, mas argv é legível
  # por qualquer usuário da máquina (ps), e uma conversa A2A não tem por que ficar exposta lá
  printf '%s' "${BODY}" > "${WORK}/body"
  jq -n --arg jws "${HDR}.${PL}.${SIG}" --arg id "${SIGID}" --arg from "${FROM}" --arg to "${TO}" \
    --arg kind "${KIND}" --rawfile body "${WORK}/body" --arg bs "${BODY_SHA}" --arg th "${THREAD}" \
    '{jws:$jws, signal:{id:$id, direction:"upstream", from:$from, to:$to, kind:$kind,
      classification:"private", thread:$th, body:$body, body_sha256:$bs}}' > "${ENVFILE}"
fi

[ -n "${OUT}" ] && cp "${ENVFILE}" "${OUT}"
if [ -n "${DRY}" ]; then cat "${ENVFILE}"; echo "(dry-run: nada enviado, nada gravado)" >&2; exit 0; fi

[ -n "${ENDPOINT}" ] || die "--endpoint obrigatório para enviar (sem default de propósito)"
[ -f "${TOKEN_FILE}" ] || die "token do canal ausente: ${TOKEN_FILE}"
# o bearer vai num arquivo de cabeçalho 0600 — nunca em argv (ps e histórico o mostrariam).
# printf é builtin: o conteúdo do token não vira argv de processo nenhum.
( umask 077; printf 'Authorization: Bearer %s\n' "$(tr -d '\r\n' < "${TOKEN_FILE}")" > "${HDRFILE}" )

RESP="$(curl -sS -m 30 -o - -w '\n%{http_code}' -H @"${HDRFILE}" -H 'Content-Type: application/json' \
        --data-binary @"${ENVFILE}" "${ENDPOINT}" 2>&1)" || true
CODE="$(printf '%s' "${RESP}" | tail -n1)"; BODY_RESP="$(printf '%s' "${RESP}" | sed '$d')"
echo "${BODY_RESP}"
echo "http=${CODE} jti=${JTI} thread=${THREAD}" >&2
[ "${CODE}" = "200" ]
