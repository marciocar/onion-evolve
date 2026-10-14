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
#                    é o atestado explícito do operador p/ hosts sem essas ferramentas) · exp e iat OBRIGATÓRIOS
#                    e inteiros (desde 2026-10-14) · exp<now → expired · iat>now+skew → future · exp<=iat →
#                    exp-not-after-iat · vida exp−iat > teto OU exp > now+teto → exp-beyond-ceiling
#                    (teto = A2A_EXP_MAX_TTL, default 3600 s)
#   4. ssrf        — a2a-ssrf-check.sh na URL do PushNotificationConfig (se houver)
#   5. jws         — assinatura RS256 verificada com a pubkey do kid (JWKS fixture) + claims iss==from, aud==receiver
#   5b. body       — o CORPO entra na assinatura (desde 2026-10-14): claim body_sha256 OBRIGATÓRIO e igual a
#                    sha256(bytes UTF-8 do valor decodificado de signal.body; ausente = corpo vazio) → senão
#                    body-mismatch; signal.body_path/thread, quando presentes, têm de ser claims iguais;
#                    chave JSON duplicada no envelope ou no payload → duplicate-key; id/direction/kind/
#                    classification (NÃO assinados) com forma fechada e chave desconhecida no signal → veto
#   6. never-live-pull — receptor mode:regulated → apply_mode:propose-only (aceita p/ o gate, nunca pull ao vivo)
#
# Invariantes hardcoded no veredito: gated SEMPRE true (sinal verificado ainda pende gate humano);
#   committed SEMPRE false (I3, entrega-sem-commit). O consumidor NUNCA auto-aplica.
#
# Uso : a2a-verify.sh --receiver <member-id> [--envelope <file>|-] [--repo <path>] [--dry-run]
#   envelope (stdin se '-' ou omitido). --dry-run: repassa ao trust-check (não grava trust-log).
# Envelope: { "jws":"<h.p.s>", "signal":{id,direction,from,to,kind,classification,body?,body_path?,thread?},
#             "pushNotificationConfig":{"url":"..."} }
#   claims do JWS: iss(=from)/aud(=to)/iat/exp/jti/body_sha256 (obrigatórios) + body_path/thread (se o signal os
#   tiver); header.kid. O QUE É ASSINADO: os claims e, via body_sha256, o corpo. id/direction/kind/
#   classification do signal NÃO são assinados (metadado de roteamento, declarado em a2a-live.md).
# CANONICALIZAÇÃO DO CORPO: o corpo é uma STRING JSON; o canônico são os bytes UTF-8 do valor JÁ DECODIFICADO
#   (sem aspas, sem normalização Unicode). A forma de escape no transporte (é vs é) não entra no hash —
#   o mesmo efeito que a JCS (RFC 8785) busca, e o bridge re-serializa o envelope (JSON.parse/stringify) antes
#   do gate, então hash sobre os bytes crus quebraria. Corpo não-string → body-not-string.
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
MAX_TTL="${A2A_EXP_MAX_TTL:-3600}"   # teto de vida do envelope (s); os remetentes de julho usam exp=iat+3600

# veredito de VETO (dependency-free — funciona mesmo sem jq): gated SEMPRE true, committed SEMPRE false.
veto() {  # <reason> <layer>
  printf '{"verified":false,"reason":"%s","layer_failed":"%s","gated":true,"committed":false,"apply_mode":"gated"}\n' "$1" "$2"
  exit 1
}

# --- Camada 0: parse (jq + openssl são necessários p/ TODO o gate → ausência = VETO, não skip) ---
command -v jq >/dev/null 2>&1 || veto "tooling-absent:jq" "parse"
command -v openssl >/dev/null 2>&1 || veto "tooling-absent:openssl" "parse"   # b64url decode + assinatura
if [ "${ENVFILE}" = "-" ]; then ENV="$(cat)"; else [ -f "${ENVFILE}" ] || veto "envelope-absent" "parse"; ENV="$(cat "${ENVFILE}")"; fi
# UM documento só (refutador 2026-10-14): `jq -e` sem -s aceitava `{..} {..}` e as camadas rodavam sobre envelope ambíguo
printf '%s' "${ENV}" | jq -es 'length==1 and (.[0]|type=="object")' >/dev/null 2>&1 || veto "malformed-envelope" "parse"

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
printf '%s' "${PL_JSON}" | jq -e 'type=="object"' >/dev/null 2>&1 || veto "malformed-jws-payload" "parse"
ISS="$(printf '%s' "${PL_JSON}" | jq -r '.iss // empty')"
AUD="$(printf '%s' "${PL_JSON}" | jq -r '.aud // empty')"
# iat/exp TIPADOS (2026-10-14): a leitura antiga (`.exp // empty` + `-lt ... 2>/dev/null`) deixava exp ausente
# OU não-numérico pular a janela EM SILÊNCIO — o envelope valia para sempre e só o jti o segurava. Agora:
# ausente → "", presente-mas-não-inteiro-não-negativo → "BAD"; os dois vetam na camada 3.
_int_claim() { printf '%s' "${PL_JSON}" | jq -r --arg k "$1" \
  'if has($k)|not then "" elif (.[$k]|type)=="number" and .[$k]==(.[$k]|floor) and .[$k]>=0 then (.[$k]|tostring) else "BAD" end' 2>/dev/null; }
IAT="$(_int_claim iat)"
EXP="$(_int_claim exp)"
JTI="$(printf '%s' "${PL_JSON}" | jq -r '.jti // empty')"
[ -n "${JTI}" ] || veto "jws-missing-jti" "parse"
# TIPO dos claims de identidade (2ª passada do refutador, 2026-10-14): jti objeto/array saía do `jq -r` em
# várias linhas, cada uma virava padrão no grep e ia para o jti.state antes do veto
printf '%s' "${PL_JSON}" | jq -e '(.jti|type=="string") and (.iss|type=="string") and ((has("aud")|not) or (.aud|type=="string"))' >/dev/null 2>&1 \
  || veto "jws-bad-claim-type" "parse"

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
# exp e iat OBRIGATÓRIOS (2026-10-14, achado F2 do spike a2a cross-user): sem exp o envelope não expira.
_is_small_uint() { case "$1" in ''|*[!0-9]*) return 1 ;; esac; [ "${#1}" -le 12 ]; }
_is_small_uint "${MAX_TTL}" && [ "${MAX_TTL}" -gt 0 ] || veto "bad-config:A2A_EXP_MAX_TTL" "timestamp"
_is_small_uint "${SKEW}" || veto "bad-config:A2A_CLOCK_SKEW" "timestamp"
[ -n "${EXP}" ] || veto "jws-missing-exp" "timestamp"
_is_small_uint "${EXP}" || veto "jws-bad-exp" "timestamp"
[ -n "${IAT}" ] || veto "jws-missing-iat" "timestamp"
_is_small_uint "${IAT}" || veto "jws-bad-iat" "timestamp"
[ "${EXP}" -lt "${NOW}" ] && veto "expired" "timestamp"
[ "${IAT}" -gt "$(( NOW + SKEW ))" ] && veto "future" "timestamp"
[ "${EXP}" -gt "${IAT}" ] || veto "exp-not-after-iat" "timestamp"
# TETO DE VIDA: as duas formas — vida declarada (exp−iat) e vida restante (exp−now). Só a 1ª deixaria um
# iat futuro (dentro do skew) esticar o exp; só a 2ª aceitaria um envelope de vida longa já envelhecido.
{ [ "$(( EXP - IAT ))" -le "${MAX_TTL}" ] && [ "${EXP}" -le "$(( NOW + MAX_TTL ))" ]; } || veto "exp-beyond-ceiling" "timestamp"

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

# --- Camada 5b: o CORPO entra na assinatura (2026-10-14, achado F1 do spike a2a cross-user) ---------
# Antes: a assinatura cobria só os claims; trocar signal.body depois de assinar devolvia verified:true.
# Agora o claim body_sha256 (dentro do payload ASSINADO) amarra o corpo. Remetente sem o claim é RECUSADO
# (nunca aceito em silêncio): não há modo legado.
# (i) chave duplicada: o envelope chega re-serializado pelo bridge (JSON.parse colapsa duplicatas), mas o
#     payload do JWS viaja em bytes assinados — e um `{"body_sha256":A,"body_sha256":B}` é lido como B pelo
#     jq e como A por parser first-wins. Ambiguidade de parser não se arbitra: veta.
printf '%s' "${ENV}" > "${TMP}/env.json"; printf '%s' "${PL_JSON}" > "${TMP}/pl.json"
DUP="$(python3 - "${TMP}/env.json" "${TMP}/pl.json" <<'PY'
import sys, json
class Dup(Exception): pass
def hook(pairs):
    seen = set()
    for k, _ in pairs:
        if k in seen: raise Dup(k)
        seen.add(k)
    return dict(pairs)
for path, name in ((sys.argv[1], "envelope"), (sys.argv[2], "jws-payload")):
    try: json.load(open(path, encoding="utf-8"), object_pairs_hook=hook)
    except Dup: print(name); break
    except Exception: print("unparseable-" + name); break   # jq aceitou e o python não: diverge → veta
else: print("ok")
PY
)"
# fail-closed: python que morre sem imprimir NÃO é "sem duplicata" — só "ok" passa
case "${DUP}" in
  ok) ;;
  unparseable-*) veto "unparseable:${DUP#unparseable-}" "body" ;;
  *) veto "duplicate-key:${DUP:-check-failed}" "body" ;;
esac
# claims de identidade sem caractere de controle: `$(jq -r)` come o \n final, e "acme\n" passava como "acme"
# controle = C0, DEL, C1 e os separadores U+2028/U+2029 (2ª passada: só `< 32` deixava U+0085 e U+2028)
printf '%s' "${PL_JSON}" | jq -e '[.iss,.aud,.jti] | all(.[]; type!="string" or (explode|all(.[]; . >= 32 and . != 127 and (. < 128 or . > 159) and . != 8232 and . != 8233)))' >/dev/null 2>&1 \
  || veto "jws-claim-control-char" "body"
# (ii) o claim: string de 64 hex minúsculos (a saída do sha256sum/openssl dgst)
#      A forma é julgada DENTRO do jq, caractere a caractere: `$(...)` + `grep -x` aceitava "<hex>\n", e regex
#      com ^/$ no jq (Oniguruma) casa por LINHA. Por isso explode, e não test().
CL_SHA="$(printf '%s' "${PL_JSON}" | jq -r 'if (.body_sha256|type)=="string" then
    (if (.body_sha256|length)==64 and (.body_sha256|explode|all(.[]; (. >= 48 and . <= 57) or (. >= 97 and . <= 102)))
     then .body_sha256 else "BAD" end)
  elif has("body_sha256") then "BAD" else "" end')"
[ -n "${CL_SHA}" ] || veto "jws-missing-body-sha256" "body"
[ "${CL_SHA}" != "BAD" ] || veto "jws-bad-body-sha256" "body"
# (iii) o corpo: string JSON ou ausente (ausente = corpo vazio, e o remetente assina sha256 do vazio)
BTYPE="$(printf '%s' "${ENV}" | jq -r '.signal | if has("body") then (.body|type) else "absent" end' 2>/dev/null)"
case "${BTYPE}" in string|absent) ;; *) veto "body-not-string" "body" ;; esac
# canônico = bytes UTF-8 do valor decodificado; vai por pipe (jq -j) e não por $(...), que comeria o \n final
BODY_SHA="$(printf '%s' "${ENV}" | jq -j '.signal.body // ""' | openssl dgst -sha256 | awk '{print $NF}')"
[ "${BODY_SHA}" = "${CL_SHA}" ] || veto "body-mismatch" "body"
# (iv) cópia não-assinada do hash no envelope (o remetente do spike a manda): se existe, tem de bater
SIG_SHA="$(printf '%s' "${ENV}" | jq -c '.signal.body_sha256')"
[ "${SIG_SHA}" = "null" ] || [ "${SIG_SHA}" = "\"${CL_SHA}\"" ] || veto "signal-body-sha256-mismatch" "body"
# (v) o ponteiro e a conversa: body_path (o a2a-accept o materializa no inbox) e thread (o receptor do spike
#     roteia por ela) — presentes no signal OU no claim, têm de ser iguais nos dois
for f in body_path thread; do
  [ "$(printf '%s' "${ENV}" | jq -c --arg k "$f" '.signal[$k]')" = "$(printf '%s' "${PL_JSON}" | jq -c --arg k "$f" '.[$k]')" ] \
    || veto "claim-${f}-mismatch" "body"
done
# (vi) forma fechada dos rótulos (refutador 2026-10-14): id/direction/kind/classification NÃO entram no JWS,
#      e o a2a-accept os escreve no frontmatter e no título do doc de inbox. Sem isto, quem não tem a chave
#      injetava linhas de YAML e prosa num sinal verificado. from/to/thread (comparados com claims, mas por
#      `$()`, que come o \n final) e body_path (assinado, mas interpolado no inbox) entram na mesma régua (2ª
#      passada). Chave desconhecida no signal veta (campo novo entra por aqui, de propósito). Rótulos: 1–128 de
#      [A-Za-z0-9._:-]; body_path: 1–256 de [A-Za-z0-9._/-] sem "..". Checados por explode (regex com ^/$ no
#      jq casaria só uma linha).
SIGF="$(printf '%s' "${ENV}" | jq -r '.signal
  | (keys - ["id","direction","from","to","kind","classification","body","body_path","body_sha256","thread"]) as $x
  | if ($x|length) > 0 then "signal-unknown-key:" + ($x[0] | explode | map(select((. >= 48 and . <= 57) or (. >= 65 and . <= 90) or (. >= 97 and . <= 122) or . == 95 or . == 45)) | implode | .[0:40])
    else ([ ("id","direction","kind","classification","from","to","thread") as $k | select(has($k))
            | select( (.[$k]|type) != "string" or (.[$k]|length) < 1 or (.[$k]|length) > 128
                      or ((.[$k]|explode|all(.[]; (. >= 48 and . <= 57) or (. >= 65 and . <= 90) or (. >= 97 and . <= 122)
                                                  or . == 46 or . == 95 or . == 58 or . == 45)) | not) )
            | $k ]
          + [ select(has("body_path")) | select( (.body_path|type) != "string" or (.body_path|length) < 1
                or (.body_path|length) > 256 or (.body_path|contains(".."))
                or ((.body_path|explode|all(.[]; (. >= 48 and . <= 57) or (. >= 65 and . <= 90) or (. >= 97 and . <= 122)
                                            or . == 46 or . == 95 or . == 45 or . == 47)) | not) ) | "body_path" ]
          | if length > 0 then "signal-field-unsafe:" + .[0] else "ok" end)
    end' 2>/dev/null)"
[ "${SIGF}" = "ok" ] || veto "${SIGF:-signal-shape-unreadable}" "body"

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
# FAIL-CLOSED (2026-10-14, achado da sessão principal no preparo do spike a2a cross-user): a linha antiga
# terminava em `|| true` — estado não-gravável fazia o anti-replay sumir EM SILÊNCIO e o veredito saía
# `verified:true` mesmo assim, então o mesmo envelope passaria de novo. Se o jti não fica GRAVADO e
# RELIDO, o sinal não é verificado: gravar é parte da verificação, não efeito colateral dela.
if ! { mkdir -p "$(dirname "${STATE}")" 2>/dev/null \
       && printf '%s\n' "${JTI}" >> "${STATE}" 2>/dev/null \
       && grep -qxF "${JTI}" "${STATE}" 2>/dev/null; }; then
  veto "replay-state-unwritable" "replay"
fi
# CORRIDA (pré-existente, apontada pelo refutador do spike em 2026-10-14): o CHECK da camada 2 e esta
# GRAVAÇÃO são separados por python/openssl/trust-check, então dois POST simultâneos com o mesmo jti
# passavam ambos pelo check. Append pequeno é atômico: depois de gravar, o jti tem de aparecer UMA vez.
# Duas linhas = outro processo gravou o mesmo jti → replay. (Na corrida exata os dois podem ver 2 e
# vetar: fail-closed, o remetente reenvia com jti novo.)
[ "$(grep -cxF "${JTI}" "${STATE}" 2>/dev/null)" = "1" ] || veto "replay" "replay"
printf '{"verified":true,"reason":"ok","layer_failed":null,"gated":true,"committed":false,"regulated":%s,"apply_mode":"%s"}\n' "${REG}" "${APPLY}"
exit 0
