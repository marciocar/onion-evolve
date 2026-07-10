#!/usr/bin/env bash
# =============================================================================
# a2a-verify.sh — a "verificação-antes-de-agir" que o receptor A2A DEVE fazer antes de um sinal virar ação.
#
# F2.2 do roadmap de federação (RFC-0004), FUNDAÇÃO SEGURA no core. É o gate que de-risca o endpoint a2a-live
# (que vive no repo privado da VPS): dado um envelope de sinal A2A, verifica-o EM CAMADAS e emite um veredito
# tipado. Irmão conceitual de pin-integrity-check.sh (verify-before-acting p/ pins).
#
# ⚠️ FAIL-SAFE = VETO, NUNCA SKIP (divergência de idioma declarada, espelha factory.md): geradores de artefato
#    degradam gracioso (skip); um GATE DE SEGURANÇA degrada para VETO (RFC-0004 §4: "sem output válido = veto;
#    ausência nunca é aprovação"). Toda camada não-avaliável (ferramenta ausente) → VETO, não skip.
# ⚠️ OFFLINE: NÃO faz rede. O JWKS é FIXTURE LOCAL PINADA (A2A_JWKS_DIR); o fetch de JWKS-por-kid ao vivo e o
#    socket SSE/webhook são do endpoint na VPS — FORA deste helper (impede "abrir canal vivo por acidente").
#
# Camadas (fail-fast, barato→caro; toda camada não-avaliável → VETO):
#   0. parse       — jq presente + envelope JSON válido? (senão veto tooling-absent:jq / malformed-envelope)
#   1. trust       — COMPÕE trust-topology-check.sh (--from signal.from --to receiver --action relay): policy-as-data
#   2. replay      — jti já visto? (state file por-receptor) → veto replay  (jti só é GRAVADO no fim, após tudo passar)
#   3. timestamp   — RELÓGIO CONFIÁVEL primeiro (janela de tempo só vale com fonte verificada: NTP sincronizado
#                    via timedatectl|chronyc|ntpstat; sem prova → veto clock-untrusted; A2A_CLOCK_TRUST=attested
#                    é o atestado explícito do operador p/ hosts sem essas ferramentas) · exp<now → expired ·
#                    iat>now+skew → future
#   4. ssrf        — a2a-ssrf-check.sh na URL do PushNotificationConfig (se houver)
#   5. jws         — assinatura RS256 verificada com a pubkey do kid (JWKS fixture) + claims iss==from, aud==receiver
#   6. never-live-pull — receptor mode:regulated → apply_mode:propose-only (aceita p/ o gate, nunca pull ao vivo)
#
# Invariantes hardcoded no veredito: gated SEMPRE true (sinal verificado ainda pende gate humano);
#   committed SEMPRE false (I3, entrega-sem-commit). O consumidor NUNCA auto-aplica.
#
# Uso : a2a-verify.sh --receiver <member-id> [--envelope <file>|-] [--repo <path>] [--dry-run]
#   envelope (stdin se '-' ou omitido). --dry-run: repassa ao trust-check (não grava trust-log).
# Envelope: { "jws":"<h.p.s>", "signal":{id,direction,from,to,kind,classification,body_path},
#             "pushNotificationConfig":{"url":"..."} }  ·  claims do JWS: iss(=from)/aud(=to)/iat/exp/jti; header.kid
# Exit: 0 = verified · 1 = vetoed · 2 = uso incorreto
# Exercitado por lint-selftest.sh (run_a2a_verify_selftests).
# =============================================================================
set -uo pipefail

RECEIVER=""; ENVFILE="-"; REPO=""; DRY=""
while [ "$#" -gt 0 ]; do case "$1" in
  --receiver) RECEIVER="${2:-}"; shift 2 ;;
  --envelope) ENVFILE="${2:-}"; shift 2 ;;
  --repo)     REPO="${2:-}"; shift 2 ;;
  --dry-run)  DRY=1; shift ;;
  *) echo "uso: a2a-verify.sh --receiver <id> [--envelope <file>|-] [--repo <path>] [--dry-run]" >&2; exit 2 ;;
esac; done
[ -n "${RECEIVER}" ] || { echo "uso: a2a-verify.sh --receiver <id> [--envelope <file>|-]" >&2; exit 2; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_ROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../../.." && pwd))"
# REPO = repo ALVO (members.yaml/trust-log a checar); default = a própria instalação. Sandbox-ável p/ teste.
[ -n "${REPO}" ] || REPO="${REAL_ROOT}"
MEMBERS="${REPO}/docs/evolution/federation/members.yaml"
# helpers vêm da INSTALAÇÃO real (HERE/REAL_ROOT), nunca do --repo alvo (que pode ser um sandbox sem eles):
TRUST_CHECK="${REAL_ROOT}/.claude/validation/trust-topology-check.sh"
SSRF_CHECK="${HERE}/a2a-ssrf-check.sh"
JWKS_DIR="${A2A_JWKS_DIR:-${HERE}/jwks}"
SKEW="${A2A_CLOCK_SKEW:-300}"   # tolerância p/ iat futuro (s)

# veredito de VETO (dependency-free — funciona mesmo sem jq): gated SEMPRE true, committed SEMPRE false.
veto() {  # <reason> <layer>
  printf '{"verified":false,"reason":"%s","layer_failed":"%s","gated":true,"committed":false,"apply_mode":"gated"}\n' "$1" "$2"
  exit 1
}

# --- Camada 0: parse (jq + openssl são necessários p/ TODO o gate → ausência = VETO, não skip) ---
command -v jq >/dev/null 2>&1 || veto "tooling-absent:jq" "parse"
command -v openssl >/dev/null 2>&1 || veto "tooling-absent:openssl" "parse"   # b64url decode + assinatura
if [ "${ENVFILE}" = "-" ]; then ENV="$(cat)"; else [ -f "${ENVFILE}" ] || veto "envelope-absent" "parse"; ENV="$(cat "${ENVFILE}")"; fi
printf '%s' "${ENV}" | jq -e . >/dev/null 2>&1 || veto "malformed-envelope" "parse"

FROM="$(printf '%s' "${ENV}" | jq -r '.signal.from // empty')"
TO="$(printf '%s' "${ENV}" | jq -r '.signal.to // empty')"
JWS="$(printf '%s' "${ENV}" | jq -r '.jws // empty')"
HOOK="$(printf '%s' "${ENV}" | jq -r '.pushNotificationConfig.url // empty')"
[ -n "${FROM}" ] && [ -n "${JWS}" ] || veto "envelope-missing-fields" "parse"

# decode base64url (pad + tradução) — usado p/ ler claims e verificar assinatura
b64url_decode() {  # <b64url> → bytes em stdout
  local d="$1"; d="${d//-/+}"; d="${d//_//}"
  case $(( ${#d} % 4 )) in 2) d="${d}==";; 3) d="${d}=";; esac
  printf '%s' "${d}" | openssl base64 -d -A 2>/dev/null
}

HDR_B64="${JWS%%.*}"; REST="${JWS#*.}"; PL_B64="${REST%%.*}"; SIG_B64="${REST#*.}"
[ -n "${HDR_B64}" ] && [ -n "${PL_B64}" ] && [ -n "${SIG_B64}" ] && [ "${SIG_B64}" != "${JWS}" ] \
  || veto "malformed-jws" "parse"

# --- Camada 1: trust policy (compõe trust-topology-check.sh) ------------------
[ -f "${TRUST_CHECK}" ] || veto "trust-check-absent" "trust"
tc_args=(--from "${FROM}" --to "${RECEIVER}" --action relay --repo "${REPO}")
[ -n "${DRY}" ] && tc_args+=(--dry-run)
bash "${TRUST_CHECK}" "${tc_args[@]}" >/dev/null 2>&1 || veto "trust-denied" "trust"

# --- ler claims do JWS (precisa jq; já garantido) ----------------------------
PL_JSON="$(b64url_decode "${PL_B64}")"
printf '%s' "${PL_JSON}" | jq -e . >/dev/null 2>&1 || veto "malformed-jws-payload" "parse"
ISS="$(printf '%s' "${PL_JSON}" | jq -r '.iss // empty')"
AUD="$(printf '%s' "${PL_JSON}" | jq -r '.aud // empty')"
IAT="$(printf '%s' "${PL_JSON}" | jq -r '.iat // empty')"
EXP="$(printf '%s' "${PL_JSON}" | jq -r '.exp // empty')"
JTI="$(printf '%s' "${PL_JSON}" | jq -r '.jti // empty')"
[ -n "${JTI}" ] || veto "jws-missing-jti" "parse"

# --- Camada 2: anti-replay jti (CHECK agora; grava só no fim, após tudo passar) ---
STATE="${REPO}/.claude/sessions/.a2a-verify.${RECEIVER}.jti.state"
if [ -f "${STATE}" ] && grep -qxF "${JTI}" "${STATE}" 2>/dev/null; then veto "replay" "replay"; fi

# --- Camada 3: janela de timestamp -------------------------------------------
# Pré-condição: o relógio local é confiável? Uma janela de tempo computada sobre relógio dessincronizado
# aceita sinal expirado ou veta sinal válido — o carimbo só vale com fonte verificada (NTP). Fail-safe: VETO.
clock_trusted() {
  [ "${A2A_CLOCK_TRUST:-}" = "attested" ] && return 0   # atestado explícito do operador (host sem tooling NTP)
  if command -v timedatectl >/dev/null 2>&1; then
    [ "$(timedatectl show -p NTPSynchronized --value 2>/dev/null)" = "yes" ] && return 0
  fi
  if command -v chronyc >/dev/null 2>&1; then
    chronyc tracking 2>/dev/null | grep -q '^Leap status.*Normal' && return 0
  fi
  if command -v ntpstat >/dev/null 2>&1; then
    ntpstat >/dev/null 2>&1 && return 0
  fi
  return 1
}
clock_trusted || veto "clock-untrusted" "timestamp"
NOW="$(date +%s)"
[ -n "${EXP}" ] && [ "${EXP}" -lt "${NOW}" ] 2>/dev/null && veto "expired" "timestamp"
[ -n "${IAT}" ] && [ "${IAT}" -gt "$(( NOW + SKEW ))" ] 2>/dev/null && veto "future" "timestamp"

# --- Camada 4: anti-SSRF (só se há webhook) ----------------------------------
if [ -n "${HOOK}" ]; then
  [ -f "${SSRF_CHECK}" ] || veto "ssrf-check-absent" "ssrf"
  A2A_MEMBERS_FILE="${MEMBERS}" bash "${SSRF_CHECK}" "${HOOK}" >/dev/null 2>&1 || veto "ssrf" "ssrf"
fi

# --- Camada 5: assinatura JWS (RS256, pubkey do kid no JWKS fixture) ----------
HDR_JSON="$(b64url_decode "${HDR_B64}")"
ALG="$(printf '%s' "${HDR_JSON}" | jq -r '.alg // empty' 2>/dev/null)"
KID="$(printf '%s' "${HDR_JSON}" | jq -r '.kid // empty' 2>/dev/null)"
[ "${ALG}" = "RS256" ] || veto "unsupported-alg:${ALG:-none}" "jws"    # fundação = RS256; ES256 é evolução
[ -n "${KID}" ] || veto "jws-missing-kid" "jws"
case "${KID}" in */*|..*|.) veto "bad-kid" "jws" ;; esac                # kid vira nome de arquivo → sanitiza
PUB="${JWKS_DIR}/${KID}.pem"
[ -f "${PUB}" ] || veto "unknown-kid:${KID}" "jws"
# kid DEVE pertencer ao `from` (members.yaml a2a.keys) — fecha impersonação: sem isso, o dono de QUALQUER
# kid pinado poderia assinar reivindicando from=outro. (Só assinatura+iss==from não basta com 2+ chaves.)
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 || veto "tooling-absent:python-yaml" "jws"
OWNED="$(python3 - "${MEMBERS}" "${FROM}" <<'PY'
import sys, yaml
try: ms=(yaml.safe_load(open(sys.argv[1])) or {}).get('members') or []
except Exception: sys.exit(0)
for m in ms:
    if m.get('id')==sys.argv[2]:
        for k in ((m.get('a2a') or {}).get('keys') or []): print(k)
        break
PY
)"
printf '%s\n' "${OWNED}" | grep -qxF "${KID}" || veto "kid-not-owned-by-from:${KID}" "jws"

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
b64url_decode "${SIG_B64}" > "${TMP}/sig.bin"
if ! printf '%s' "${HDR_B64}.${PL_B64}" | openssl dgst -sha256 -verify "${PUB}" -signature "${TMP}/sig.bin" >/dev/null 2>&1; then
  veto "bad-signature" "jws"
fi
# claims coerentes com o envelope (defesa contra confusão): iss==from, aud==receiver
[ "${ISS}" = "${FROM}" ] || veto "claim-iss-mismatch" "jws"
[ -z "${AUD}" ] || [ "${AUD}" = "${RECEIVER}" ] || veto "claim-aud-mismatch" "jws"
[ -z "${TO}" ] || [ "${TO}" = "${RECEIVER}" ] || veto "signal-to-mismatch" "jws"

# --- Camada 6: never-live-pull (receptor regulado) ---------------------------
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 || veto "tooling-absent:python-yaml" "never-live-pull"
MODE="$(python3 - "${MEMBERS}" "${RECEIVER}" <<'PY'
import sys, yaml
try: ms=(yaml.safe_load(open(sys.argv[1])) or {}).get('members') or []
except Exception: sys.exit(0)
for m in ms:
    if m.get('id')==sys.argv[2]: print(m.get('mode','') or ''); break
PY
)"
if [ "${MODE}" = "regulated" ]; then REG="true"; APPLY="propose-only"; else REG="false"; APPLY="gated"; fi

# --- Sucesso: grava o jti (single-use) e emite o veredito --------------------
mkdir -p "$(dirname "${STATE}")" 2>/dev/null && printf '%s\n' "${JTI}" >> "${STATE}" 2>/dev/null || true
printf '{"verified":true,"reason":"ok","layer_failed":null,"gated":true,"committed":false,"regulated":%s,"apply_mode":"%s"}\n' "${REG}" "${APPLY}"
exit 0
