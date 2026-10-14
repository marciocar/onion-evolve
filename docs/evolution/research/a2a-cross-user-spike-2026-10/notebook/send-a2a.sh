#!/usr/bin/env bash
# =============================================================================
# send-a2a.sh — REMETENTE do spike A2A cross-user. Roda NO NOTEBOOK do maestro.
#
# Monta o envelope que o `/a2a` do bridge entende ({jws, signal}), assina RS256 com a chave PRIVADA do
# membro de teste (que fica só em ~/.config/onion/a2a/, modo 0600, fora de qualquer git) e faz o POST.
# Diferença para o send-signal.sh dos handshakes de julho: o CORPO viaja (signal.body) e fica AMARRADO à
# assinatura pelo claim `body_sha256` — o gate do core hoje NÃO amarra o corpo (ver SPIKE-PROTOCOL.md §6,
# achado F1), então quem amarra é o receptor do spike (vps/accept-to-channel.sh), que confere o hash.
#
# Protocolo: docs/evolution/research/a2a-cross-user-spike-2026-10/SPIKE-PROTOCOL.md (cenários A1–A8).
# Portável: bash 3.2+ (macOS), openssl OU LibreSSL, jq, curl. Sem python obrigatório.
#
# Uso:
#   send-a2a.sh --body "texto" | --body-file F   [opções]
# Opções de identidade/destino:
#   --endpoint URL     default https://app.onionevolve.com/a2a
#   --token-file F     default ~/.config/onion/a2a/bridge-token (bearer do pool a2a; NUNCA em argv)
#   --key F            default ~/.config/onion/a2a/maestro-notebook-test-1.key.pem
#   --kid K            default maestro-notebook-test-1          (A4: passe um kid não pinado)
#   --from ID / --to ID  default maestro-notebook-test / onion-evolve
#   --thread T         id da conversa (default: gerado) · --kind K (default question)
# Opções de cenário (pré-registradas no protocolo — não invente outras sem emendar o protocolo):
#   --jti J            fixa o jti (A3: reenvie com o MESMO jti)
#   --iat-offset S     soma S segundos ao iat   (A5b: +3600 → future)
#   --exp-offset S     exp = now + S (default 300; A5a: -60 → expired)
#   --no-exp           omite exp (A5c: mede se o gate exige exp — hoje NÃO exige)
#   --resend F         reenvia BYTE A BYTE o envelope salvo em F (A3 puro: replay de verdade)
#   --dry-run          monta e imprime o envelope, sem rede
#   --out F            salva o envelope enviado em F (default: no log de estado)
# Saída: a resposta HTTP (corpo + código) e uma linha TSV em ~/.local/state/onion/a2a-spike/sent.tsv
#        (t_send_ms, jti, thread, http_code, cenário) — o relógio do NOTEBOOK mede o ciclo inteiro.
# Exit: 0 = HTTP 200 · 1 = HTTP != 200 (veto do gate é resultado ESPERADO em A3/A4/A5) · 2 = uso/tooling
# =============================================================================
set -euo pipefail

ENDPOINT="https://app.onionevolve.com/a2a"
CFG="${HOME}/.config/onion/a2a"
STATE_DIR="${HOME}/.local/state/onion/a2a-spike"
TOKEN_FILE="${CFG}/bridge-token"
KEY="${CFG}/maestro-notebook-test-1.key.pem"
KID="maestro-notebook-test-1"
FROM="maestro-notebook-test"
TO="onion-evolve"
THREAD=""; KIND="question"; BODY=""; BODY_FILE=""; JTI=""
IAT_OFF=0; EXP_OFF=300; NO_EXP=""; RESEND=""; DRY=""; OUT=""; SCENARIO="${A2A_SPIKE_SCENARIO:-adhoc}"

die() { echo "ERRO: $*" >&2; exit 2; }
while [ "$#" -gt 0 ]; do case "$1" in
  --endpoint) ENDPOINT="$2"; shift 2 ;;
  --token-file) TOKEN_FILE="$2"; shift 2 ;;
  --key) KEY="$2"; shift 2 ;;
  --kid) KID="$2"; shift 2 ;;
  --from) FROM="$2"; shift 2 ;;
  --to) TO="$2"; shift 2 ;;
  --thread) THREAD="$2"; shift 2 ;;
  --kind) KIND="$2"; shift 2 ;;
  --body) BODY="$2"; shift 2 ;;
  --body-file) BODY_FILE="$2"; shift 2 ;;
  --jti) JTI="$2"; shift 2 ;;
  --iat-offset) IAT_OFF="$2"; shift 2 ;;
  --exp-offset) EXP_OFF="$2"; shift 2 ;;
  --no-exp) NO_EXP=1; shift ;;
  --resend) RESEND="$2"; shift 2 ;;
  --dry-run) DRY=1; shift ;;
  --out) OUT="$2"; shift 2 ;;
  --scenario) SCENARIO="$2"; shift 2 ;;
  -h|--help) sed -n '2,36p' "$0"; exit 0 ;;
  *) die "argumento desconhecido: $1" ;;
esac; done

for t in openssl jq curl; do command -v "$t" >/dev/null 2>&1 || die "ferramenta ausente: $t"; done

now_ms() {  # milissegundos no relógio LOCAL; date +%N não existe no BSD/macOS
  if command -v python3 >/dev/null 2>&1; then python3 -c 'import time;print(int(time.time()*1000))'
  elif command -v perl >/dev/null 2>&1; then perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000'
  else echo "$(( $(date +%s) * 1000 ))"; fi
}
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
sha256_hex() { openssl dgst -sha256 | awk '{print $NF}'; }
rand_hex() { openssl rand -hex "$1"; }

mkdir -p "${STATE_DIR}"; chmod 700 "${STATE_DIR}" 2>/dev/null || true
ENVFILE="$(mktemp "${STATE_DIR}/env.XXXXXX")"; HDRFILE="$(mktemp "${STATE_DIR}/hdr.XXXXXX")"
trap 'rm -f "${HDRFILE}"' EXIT

if [ -n "${RESEND}" ]; then
  [ -f "${RESEND}" ] || die "envelope para reenviar inexistente: ${RESEND}"
  cp "${RESEND}" "${ENVFILE}"
  JTI="$(jq -r '.jws' "${ENVFILE}" | cut -d. -f2 | tr '_-' '/+' | { s="$(cat)"; case $(( ${#s} % 4 )) in 2) s="${s}==";; 3) s="${s}=";; esac; printf '%s' "$s"; } | openssl base64 -d -A | jq -r '.jti')"
  THREAD="$(jq -r '.signal.thread // ""' "${ENVFILE}")"
else
  [ -f "${KEY}" ] || die "chave privada ausente: ${KEY} (ver SPIKE-PROTOCOL.md passo P1)"
  if [ -n "${BODY_FILE}" ]; then [ -f "${BODY_FILE}" ] || die "body-file inexistente"; BODY="$(cat "${BODY_FILE}")"; fi
  [ -n "${BODY}" ] || die "corpo vazio: passe --body ou --body-file"
  [ "${#BODY}" -le 8192 ] || die "corpo > 8192 caracteres: o spike mede conversa, não transferência de arquivo"
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
  jq -n --arg jws "${HDR}.${PL}.${SIG}" --arg id "${SIGID}" --arg from "${FROM}" --arg to "${TO}" \
    --arg kind "${KIND}" --arg body "${BODY}" --arg bs "${BODY_SHA}" --arg th "${THREAD}" \
    '{jws:$jws, signal:{id:$id, direction:"upstream", from:$from, to:$to, kind:$kind,
      classification:"private", thread:$th, body:$body, body_sha256:$bs}}' > "${ENVFILE}"
fi

[ -n "${OUT}" ] && cp "${ENVFILE}" "${OUT}"
if [ -n "${DRY}" ]; then cat "${ENVFILE}"; echo "(dry-run: nada enviado; envelope em ${ENVFILE})" >&2; exit 0; fi

[ -f "${TOKEN_FILE}" ] || die "token do pool a2a ausente: ${TOKEN_FILE} (ver SPIKE-PROTOCOL.md passo P2)"
# o bearer vai num arquivo de cabeçalho 0600 — nunca em argv (ps e histórico o mostrariam)
( umask 077; printf 'Authorization: Bearer %s\n' "$(tr -d '\r\n' < "${TOKEN_FILE}")" > "${HDRFILE}" )

T0="$(now_ms)"
RESP="$(curl -sS -m 30 -o - -w '\n%{http_code}' -H @"${HDRFILE}" -H 'Content-Type: application/json' \
        --data-binary @"${ENVFILE}" "${ENDPOINT}" 2>&1)" || true
T1="$(now_ms)"
CODE="$(printf '%s' "${RESP}" | tail -n1)"; BODY_RESP="$(printf '%s' "${RESP}" | sed '$d')"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${T0}" "${T1}" "${JTI}" "${THREAD}" "${CODE}" "${SCENARIO}" "${ENVFILE}" >> "${STATE_DIR}/sent.tsv"
echo "${BODY_RESP}"
echo "http=${CODE} jti=${JTI} thread=${THREAD} ida=$(( T1 - T0 ))ms envelope=${ENVFILE}" >&2
[ "${CODE}" = "200" ]
