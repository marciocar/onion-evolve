#!/usr/bin/env bash
# =============================================================================
# accept-to-channel.sh — o ATO HUMANO do receptor no spike A2A cross-user. Roda NA VPS, pelo maestro
# (com `!` no prompt da sessão receptora, ou num terminal dele) — nunca pelo modelo por conta própria.
#
# Pega UM registro da fila gated do bridge (data/a2a-pending/, escrita pelo POST /a2a depois do
# a2a-verify do core) e:
#   1. recusa se verdict.verified != true                       (defesa em profundidade, como o a2a-accept)
#   2. RE-VERIFICA a assinatura com a pubkey pinada e AMARRA O CORPO: claim body_sha256 do JWS ==
#      sha256(signal.body) == signal.body_sha256; iss == from; aud == onion-evolve; thread do claim == signal.
#      Desde 2026-10-14 o gate do core também confere body_sha256 (F1 curado); esta camada fica como 2ª
#      verificação. Antes da cura, sem ela, o corpo que chega à sessão
#      não é o que o remetente assinou — o envelope fora do JWS é texto livre.
#   3. registra a aceitação com o a2a-accept.sh do core, num inbox DO SPIKE (não no inbox de co-evolução:
#      conversa não é sinal de triagem, e misturar sujaria a fila do /meta:co-evolve)
#   4. entrega o corpo ao channel MCP da sessão receptora (loopback, bearer de arquivo 0600), uma vez só
#      por jti (dedupe local — o jti.state do bridge veta replay NA ENTRADA; este veta reentrega NA SAÍDA)
#
# Modos de consentimento (SPIKE-PROTOCOL.md §4 — pré-registrados; C2 só com assinatura do maestro):
#   C1 (default): um registro por invocação = uma aceitação humana por mensagem.
#   C2 (--lease): o maestro aceita UMA THREAD de UM membro por TTL segundos; registros novos dessa thread
#                 entram sem nova aceitação até o TTL vencer. Exige emenda à RFC-0004 para sair do spike.
#
# Uso : accept-to-channel.sh <registro.json|-> [--no-push] [--channel-url URL]
#       accept-to-channel.sh --lease --thread T --from ID --ttl S [--pending-dir D]
# Env : A2A_SPIKE_SERVED_ROOT (default /home/onion/onion-evolve: o clone que o BRIDGE serve)
#       A2A_SPIKE_JWKS (default: jwks/ do clone servido) · A2A_SPIKE_MEMBERS (default: members.yaml do servido)
#       A2A_SPIKE_STATE (~/.local/state/onion/a2a-spike) · A2A_SPIKE_CHANNEL_TOKEN (~/.config/onion/a2a/channel-token)
#       A2A_SPIKE_MAX_SKEW (default 60 s: iat no futuro tolerado) · A2A_SPIKE_MAX_LIFE (default 900 s: exp − iat)
#       A2A_SPIKE_ACCEPT_TRUST_REPO (default: o checkout deste script — a 2ª raiz, a da reverificação do a2a-accept;
#       override só para o selftest)
# Raiz de confiança (Emenda 7, 2026-10-14): a curadoria apontou que o default era o checkout ~/onion-evolve,
#   que NÃO é o que o gate leu. O default agora é o clone SERVIDO; a leitura cai para `sudo -n cat` quando a
#   conta do maestro não lê direto, e cada aceitação grava uma linha TRUST com o sha256 do members.yaml e
#   do .pem usados (override por env continua possível e aparece na linha TRUST).
# Exit: 0 entregue (ou já entregue) · 1 recusado · 2 uso/tooling
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/../../../../.." && pwd)"
ACCEPT="${ROOT}/.claude/utils/federation-transport/a2a-accept.sh"
SERVED="${A2A_SPIKE_SERVED_ROOT:-/home/onion/onion-evolve}"
JWKS="${A2A_SPIKE_JWKS:-${SERVED}/.claude/utils/federation-transport/jwks}"
MAX_SKEW="${A2A_SPIKE_MAX_SKEW:-60}"; MAX_LIFE="${A2A_SPIKE_MAX_LIFE:-900}"
case "${MAX_SKEW}${MAX_LIFE}" in *[!0-9]*|'') echo "ERRO: A2A_SPIKE_MAX_SKEW/MAX_LIFE não numéricos" >&2; exit 2 ;; esac
STATE="${A2A_SPIKE_STATE:-${HOME}/.local/state/onion/a2a-spike}"
CHAN_TOKEN="${A2A_SPIKE_CHANNEL_TOKEN:-${HOME}/.config/onion/a2a/channel-token}"
CHAN_URL="http://127.0.0.1:8790/deliver"
RECEIVER="onion-evolve"
REC=""; NOPUSH=""; LEASE=""; L_THREAD=""; L_FROM=""; L_TTL=""; PENDING="/home/onion/onion-bridge/data/a2a-pending"
X_FROM=""; X_THREAD=""
MEMBERS="${A2A_SPIKE_MEMBERS:-${SERVED}/docs/evolution/federation/members.yaml}"

die() { echo "ERRO: $*" >&2; exit 2; }
refuse() { echo "RECUSADO: $*" >&2; exit 1; }
while [ "$#" -gt 0 ]; do case "$1" in
  --no-push) NOPUSH=1; shift ;;
  --channel-url) CHAN_URL="$2"; shift 2 ;;
  --lease) LEASE=1; shift ;;
  --thread) L_THREAD="$2"; shift 2 ;;
  --from) L_FROM="$2"; shift 2 ;;
  --ttl) L_TTL="$2"; shift 2 ;;
  --pending-dir) PENDING="$2"; shift 2 ;;
  --expect-from) X_FROM="$2"; shift 2 ;;
  --expect-thread) X_THREAD="$2"; shift 2 ;;
  -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
  -) REC="-"; shift ;;
  -*) die "argumento desconhecido: $1" ;;
  *) REC="$1"; shift ;;
esac; done
for t in jq openssl curl; do command -v "$t" >/dev/null 2>&1 || die "ferramenta ausente: $t"; done
mkdir -p "${STATE}/inbox" "${STATE}/records"; chmod 700 "${STATE}" 2>/dev/null || true

now_ms() { python3 -c 'import time;print(int(time.time()*1000))' 2>/dev/null || echo "$(( $(date +%s) * 1000 ))"; }
b64url_decode() { local d="$1"; d="${d//-/+}"; d="${d//_//}"; case $(( ${#d} % 4 )) in 2) d="${d}==";; 3) d="${d}=";; esac; printf '%s' "${d}" | openssl base64 -d -A; }

# ── C2: lease por thread ─────────────────────────────────────────────────────────────────────────────
if [ -n "${LEASE}" ]; then
  [ -n "${L_THREAD}" ] && [ -n "${L_FROM}" ] && [ -n "${L_TTL}" ] || die "--lease exige --thread, --from e --ttl"
  [ "${L_TTL}" -le 1800 ] 2>/dev/null || die "TTL acima de 1800 s não está no protocolo"
  END=$(( $(date +%s) + L_TTL ))
  printf '%s\tLEASE-START\t%s\t%s\t%s\n' "$(now_ms)" "${L_FROM}" "${L_THREAD}" "${L_TTL}" >> "${STATE}/accept.tsv"
  echo "lease aberto: from=${L_FROM} thread=${L_THREAD} até $(date -d "@${END}" +%T 2>/dev/null || echo "${END}")" >&2
  PROBE="$(mktemp "${STATE}/records/probe.XXXXXX")"
  while [ "$(date +%s)" -lt "${END}" ]; do
    sudo -n ls "${PENDING}" 2>/dev/null | grep -E '^[A-Za-z0-9._-]+\.json$' | while IFS= read -r f; do
      sudo -n cat "${PENDING}/${f}" > "${PROBE}" 2>/dev/null || continue
      # o filtro é só pré-seleção (barato); a decisão é da invocação C1 abaixo, que confere
      # --expect-from/--expect-thread contra os CLAIMS ASSINADOS, nunca contra o envelope solto
      th="$(jq -r '.envelope.signal.thread // ""' "${PROBE}")"; fr="$(jq -r '.envelope.signal.from // ""' "${PROBE}")"
      [ "${th}" = "${L_THREAD}" ] && [ "${fr}" = "${L_FROM}" ] || continue
      bash "$0" "${PROBE}" --channel-url "${CHAN_URL}" --expect-from "${L_FROM}" --expect-thread "${L_THREAD}" 2>&1 \
        | grep -v '^já entregue' >&2 || true
    done || true   # fila vazia: o grep sai 1 e, sob pipefail+errexit, mataria o lease
    sleep 1
  done
  rm -f "${PROBE}"
  printf '%s\tLEASE-END\t%s\t%s\n' "$(now_ms)" "${L_FROM}" "${L_THREAD}" >> "${STATE}/accept.tsv"
  echo "lease vencido — de volta ao C1 (uma aceitação por mensagem)" >&2; exit 0
fi

# ── C1: um registro ─────────────────────────────────────────────────────────────────────────────────
[ -n "${REC}" ] || die "uso: accept-to-channel.sh <registro.json|-> [--no-push]"
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 || die "python3+yaml ausente (kid-binding)"
T_ACC="$(now_ms)"
# arquivos POR INVOCAÇÃO (refutador 2026-10-14: com caminho fixo, um lease e um C1 simultâneos podiam
# entregar o corpo de B com o meta de A) + lock em volta do dedupe/entrega
LOCAL="$(mktemp "${STATE}/records/rec.XXXXXX")"; BODYF="$(mktemp "${STATE}/records/body.XXXXXX")"
TMPS="$(mktemp)"; TRUSTD="$(mktemp -d)"; trap 'rm -f "${TMPS}" "${BODYF}"; rm -rf "${TRUSTD}"' EXIT
# lê um arquivo da raiz de confiança (o clone servido é da conta onion): direto, ou por sudo -n cat
trust_read() { if [ -r "$1" ]; then cat "$1" > "$2"; else sudo -n cat "$1" > "$2" 2>/dev/null; fi; [ -s "$2" ]; }
if [ "${REC}" = "-" ]; then cat > "${LOCAL}"
elif [ -r "${REC}" ]; then cp "${REC}" "${LOCAL}"
else sudo -n cat "${REC}" > "${LOCAL}" 2>/dev/null || die "registro ilegível (fila do bridge é da conta onion): ${REC}"; fi
jq -e . "${LOCAL}" >/dev/null 2>&1 || refuse "registro não é JSON"
[ "$(jq -r '.verdict.verified // false' "${LOCAL}")" = "true" ] || refuse "verdict.verified != true"

JWS="$(jq -r '.envelope.jws // empty' "${LOCAL}")"; [ -n "${JWS}" ] || refuse "registro sem envelope.jws (auditoria perdida)"
H="${JWS%%.*}"; R="${JWS#*.}"; P="${R%%.*}"; SIGB="${R#*.}"
HDR="$(b64url_decode "${H}")"; PL="$(b64url_decode "${P}")"
KID="$(printf '%s' "${HDR}" | jq -r '.kid // empty')"; ALG="$(printf '%s' "${HDR}" | jq -r '.alg // empty')"
[ "${ALG}" = "RS256" ] || refuse "alg ${ALG}"
case "${KID}" in ""|*/*|..*|.) refuse "kid inválido" ;; esac
PEM="${TRUSTD}/kid.pem"; MEMF="${TRUSTD}/members.yaml"
trust_read "${JWKS}/${KID}.pem" "${PEM}" || refuse "kid ${KID} não pinado em ${JWKS} (ou ilegível mesmo por sudo -n)"
trust_read "${MEMBERS}" "${MEMF}" || refuse "members.yaml da raiz de confiança ilegível: ${MEMBERS}"
printf '%s\tTRUST\t%s\t%s\t%s\t%s\n' "$(now_ms)" "${MEMBERS}" "$(openssl dgst -sha256 < "${MEMF}" | awk '{print $NF}')" \
  "${JWKS}/${KID}.pem" "$(openssl dgst -sha256 < "${PEM}" | awk '{print $NF}')" >> "${STATE}/accept.tsv"
b64url_decode "${SIGB}" > "${TMPS}"
printf '%s' "${H}.${P}" | openssl dgst -sha256 -verify "${PEM}" -signature "${TMPS}" >/dev/null 2>&1 || refuse "assinatura não confere"

FROM="$(jq -r '.envelope.signal.from // empty' "${LOCAL}")"
# kid-binding (o mesmo do a2a-verify): a chave pinada tem de ser DO from. Sem isto a re-verificação só
# provaria "alguma chave pinada assinou" — e um registro montado à mão passaria com a chave de outro dono.
python3 - "${MEMF}" "${FROM}" "${KID}" <<'PY' || refuse "kid ${KID} não pertence a keys[${FROM}] no members.yaml"
import sys, yaml
ms = (yaml.safe_load(open(sys.argv[1])) or {}).get('members') or []
keys = next(((m.get('a2a') or {}).get('keys') or [] for m in ms if m.get('id') == sys.argv[2]), [])
sys.exit(0 if sys.argv[3] in keys else 1)
PY
EXP="$(printf '%s' "${PL}" | jq -r '.exp // empty')"
case "${EXP}" in ''|*[!0-9]*) refuse "JWS sem exp numérico (achado F2, curado no gate do core em 2026-10-14)" ;; esac
NOW_S="$(date +%s)"
[ "${EXP}" -ge "${NOW_S}" ] || refuse "expirado (exp ${EXP})"
# Emenda 7 (2026-10-14): a curadoria apontou que só o exp era conferido. iat no futuro e vida longa demais
# passavam: um envelope com exp em 10 anos valia 10 anos.
IAT="$(printf '%s' "${PL}" | jq -r '.iat // empty')"
case "${IAT}" in ''|*[!0-9]*) refuse "JWS sem iat numérico" ;; esac
# TIPO, não só dígitos (passada adversarial 2026-10-14): `"exp":"013000000000"` (string com zero à esquerda)
# passava no filtro de dígitos, o `[ -gt ]` lia em decimal (ano 2381) e o `$(( ))` lia em OCTAL (vida negativa
# ≤ teto). exp e iat têm de ser NÚMEROS JSON inteiros, e a aritmética força base 10.
printf '%s' "${PL}" | jq -e '(.exp|type=="number" and . == floor) and (.iat|type=="number" and . == floor)' >/dev/null 2>&1 \
  || refuse "exp/iat não são inteiros JSON (string numérica recusada)"
EXP=$(( 10#${EXP} )); IAT=$(( 10#${IAT} ))
[ "${IAT}" -le $(( NOW_S + MAX_SKEW )) ] || refuse "iat no futuro (iat ${IAT} > agora + ${MAX_SKEW} s)"
[ "${EXP}" -gt "${IAT}" ] || refuse "exp ≤ iat (exp ${EXP}, iat ${IAT})"
[ $(( EXP - IAT )) -le "${MAX_LIFE}" ] || refuse "vida longa demais: exp − iat = $(( EXP - IAT )) s > ${MAX_LIFE} s"
[ "$(jq -r '.from // empty' "${LOCAL}")" = "${FROM}" ] || refuse "from do registro ≠ from do envelope"
[ "$(printf '%s' "${PL}" | jq -r '.iss // empty')" = "${FROM}" ] || refuse "iss ≠ from"
[ "$(printf '%s' "${PL}" | jq -r '.aud // empty')" = "${RECEIVER}" ] || refuse "aud ≠ ${RECEIVER}"
JTI="$(printf '%s' "${PL}" | jq -r '.jti // empty')"; [ -n "${JTI}" ] || refuse "sem jti"
CL_SHA="$(printf '%s' "${PL}" | jq -r '.body_sha256 // empty')"
[ -n "${CL_SHA}" ] || refuse "JWS sem claim body_sha256 — corpo não amarrado à assinatura (envelope de sinal antigo?)"
# o corpo vai a um arquivo e o hash sai do arquivo: `$(...)` comeria o \n final e mudaria o hash
jq -j '.envelope.signal.body // ""' "${LOCAL}" > "${BODYF}"
BODY_SHA="$(openssl dgst -sha256 < "${BODYF}" | awk '{print $NF}')"
[ "${BODY_SHA}" = "${CL_SHA}" ] || refuse "corpo adulterado: sha256(body)=${BODY_SHA} ≠ claim ${CL_SHA}"
[ "$(jq -r '.envelope.signal.body_sha256 // empty' "${LOCAL}")" = "${CL_SHA}" ] || refuse "signal.body_sha256 ≠ claim"
THREAD="$(printf '%s' "${PL}" | jq -r '.thread // empty')"
[ "$(jq -r '.envelope.signal.thread // empty' "${LOCAL}")" = "${THREAD}" ] || refuse "thread do envelope ≠ claim"
[ -z "${X_FROM}" ] || [ "${X_FROM}" = "${FROM}" ] || refuse "lease é de ${X_FROM}; o claim assinado diz ${FROM}"
[ -z "${X_THREAD}" ] || [ "${X_THREAD}" = "${THREAD}" ] || refuse "lease é da thread ${X_THREAD}; o claim assinado diz ${THREAD}"

exec 8>"${STATE}/.deliver.lock"
command -v flock >/dev/null 2>&1 && flock 8
if grep -qxF "${JTI}" "${STATE}/delivered.jti" 2>/dev/null; then echo "já entregue (jti ${JTI}) — nada a fazer" >&2; exit 0; fi

# registro humano da aceitação (o a2a-accept do core, idempotente, num inbox do spike)
# DUAS RAÍZES, NÃO UMA (2026-10-22): desde a SAC-150 N1 o a2a-accept REVERIFICA o envelope contra o --trust-repo,
# cujo default é o CHECKOUT onde este script mora (conta do maestro). É de propósito que ela NÃO é a raiz servida
# lida acima: o clone servido é da conta onion, o mesmo UID que escreve a fila, e um UID do bridge comprometido
# que plantasse chave no servido e forjasse o registro passaria se as duas camadas lessem os mesmos bytes
# (refutador desta cura). Aceitar exige que as duas raízes concordem. A2A_SPIKE_ACCEPT_TRUST_REPO só existe para
# o selftest (sandbox) e, quando usado, avisa. O razão de aceites vai para o estado do spike, ao lado do inbox que
# ele deduplica: no checkout, um jti do spike suprimiria o aceite real do mesmo jti no inbox do core.
ACC_TRUST="${A2A_SPIKE_ACCEPT_TRUST_REPO:-${ROOT}}"
if [ "${ACC_TRUST}" != "${ROOT}" ]; then   # override deixa rastro DURÁVEL, não só o stderr (2ª passada do refutador)
  echo "AVISO: a reverificação do a2a-accept usa A2A_SPIKE_ACCEPT_TRUST_REPO=${ACC_TRUST}, não o checkout" >&2
  printf '%s\tACC-TRUST-OVERRIDE\t%s\t%s\n' "$(now_ms)" "${ACC_TRUST}" "${JTI}" >> "${STATE}/accept.tsv"
fi
bash "${ACCEPT}" "${LOCAL}" --inbox "${STATE}/inbox" --receiver "${RECEIVER}" --trust-repo "${ACC_TRUST}" \
  --ledger "${STATE}/accept.ledger" >/dev/null || refuse "a2a-accept recusou (a reverificação lê a 2ª raiz: ${ACC_TRUST})"

TASK="$(jq -r '.taskId // ""' "${LOCAL}")"
if [ -z "${NOPUSH}" ]; then
  [ -f "${CHAN_TOKEN}" ] || die "token do channel ausente: ${CHAN_TOKEN}"
  HF="$(mktemp)"; ( umask 077; printf 'Authorization: Bearer %s\n' "$(tr -d '\r\n' < "${CHAN_TOKEN}")" > "${HF}" )
  PAYLOAD="$(jq -n --rawfile body "${BODYF}" --arg from "${FROM}" --arg kid "${KID}" --arg jti "${JTI}" \
    --arg thread "${THREAD}" --arg task "${TASK}" --arg sha "${CL_SHA}" \
    '{body:$body, meta:{from:$from, kid:$kid, jti:$jti, thread:$thread, task_id:$task, body_sha256:$sha}}')"
  T_PUSH="$(now_ms)"
  RESPF="$(mktemp)"
  CODE="$(printf '%s' "${PAYLOAD}" | curl -sS -m 10 -o "${RESPF}" -w '%{http_code}' -H @"${HF}" \
          -H 'Content-Type: application/json' --data-binary @- "${CHAN_URL}" || true)"
  RESP="$(head -c 200 "${RESPF}" 2>/dev/null)"; rm -f "${HF}" "${RESPF}"
  [ "${CODE}" = "200" ] || refuse "channel não aceitou (http ${CODE}) — a sessão receptora está aberta com a flag de dev?"
  # o channel diz "já entregue" de um jti que ESTE accept nunca registrou (o delivered.jti acima não o tinha):
  # não é entrega, é suspeita — uma entrega anterior pode ter falhado depois de o channel marcá-la. Não vira
  # ACCEPT 200 (passada adversarial 2026-10-14: assim uma perda contaria como entregue).
  if [ "${RESP}" = "já entregue" ]; then
    printf '%s\tSUSPECT-ALREADY-DELIVERED\t%s\t%s\t%s\n' "$(now_ms)" "${FROM}" "${THREAD}" "${JTI}" >> "${STATE}/accept.tsv"
    refuse "o channel já tinha o jti ${JTI} sem ACCEPT deste lado: registrado como SUSPECT, confira o receipts.jsonl"
  fi
else
  T_PUSH="$(now_ms)"; CODE="no-push"
fi
printf '%s\n' "${JTI}" >> "${STATE}/delivered.jti"
printf '%s\tACCEPT\t%s\t%s\t%s\t%s\t%s\t%s\n' "${T_ACC}" "${T_PUSH}" "${FROM}" "${THREAD}" "${JTI}" "${TASK}" "${CODE}" >> "${STATE}/accept.tsv"
echo "aceito e entregue ao channel: from=${FROM} thread=${THREAD} jti=${JTI} (push http ${CODE})" >&2
