#!/usr/bin/env bash
# =============================================================================
# run-s1-s2.sh — bancada do spike F0 do configurador A2A (SAC-121): S1 (SAC-126) e S2 (SAC-127).
#
# Molde: run_a2a_verify_selftests em .claude/validation/lint-selftest.sh (sandbox mktemp -d com
# members.yaml mínimo, receptor onion-evolve, A2A_CLOCK_TRUST=attested, A2A_JWKS_DIR do sandbox).
# Diferença: a chave NÃO é efêmera da bancada — vem do a2a-keygen.sh, e o envelope vem do a2a-send.sh.
#
#   S1 (keygen conforme ao gate):
#     S1.a keygen sai 0 e imprime kid/public/fingerprint, sem "PRIVATE KEY" na saída
#     S1.b privada 0600 · pública 0644 · diretório default (~/.config/onion/a2a) 0700
#     S1.c módulo >= 3072 bits e fingerprint impresso = sha256(DER SPKI) recalculado
#     S1.d 2ª execução com o mesmo kid → rc 2 e a privada fica byte a byte igual
#     S1.e a2a-verify.sh --dry-run ACEITA o envelope do a2a-send.sh --dry-run assinado pela chave gerada
#     S1.f argv sem segredo: keygen e send REAL (contra listener em 127.0.0.1, sem rede externa) rodam em
#          background; `ps -eo args` é amostrado durante a execução; nenhuma amostra contém o token,
#          'PRIVATE KEY' ou um trecho do corpo da privada. Não-vacuidade: as amostras TÊM de ter visto o
#          openssl genpkey e o curl, e o listener TEM de ter recebido o bearer certo (por hash).
#   S2 (gate veta o errado, aceita o certo):
#     S2.0 envelope certo → verified
#     S2.1 sem body_sha256 → jws-missing-body-sha256
#     S2.2 exp vencido → expired
#     S2.3 jti repetido (mesmo envelope 2x, gate SEM --dry-run, --repo sandbox) → 1º verified, 2º replay
#     S2.4 kid não pinado (acme-2 gerado e publicado no JWKS, mas members.yaml só pina acme-1)
#          → kid-not-owned-by-from:acme-2
#
# Uso: run-s1-s2.sh [--mutant perm0644|token-argv]
#   --mutant perm0644    cópia do keygen que deixa a privada 0644 (o S1.b TEM de reprovar)
#   --mutant token-argv  cópia do send que passa o bearer em argv do curl (o S1.f TEM de reprovar —
#                        prova que o amostrador de ps não é vácuo)
# Exit: 0 = todos os casos bateram · 1 = algum caso divergiu · 2 = uso/tooling
# =============================================================================
set -uo pipefail

MUTANT=""
while [ "$#" -gt 0 ]; do case "$1" in
  --mutant) MUTANT="${2:-}"; shift 2 ;;
  *) echo "uso: run-s1-s2.sh [--mutant perm0644|token-argv]" >&2; exit 2 ;;
esac; done
case "${MUTANT}" in ''|perm0644|token-argv) ;; *) echo "mutante desconhecido: ${MUTANT}" >&2; exit 2 ;; esac

for t in openssl jq python3 curl ps; do command -v "$t" >/dev/null 2>&1 || { echo "ferramenta ausente: $t" >&2; exit 2; }; done
python3 -c 'import yaml' 2>/dev/null || { echo "python3 sem PyYAML (o gate exige)" >&2; exit 2; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "${HERE}" rev-parse --show-toplevel)"
GATE="${ROOT}/.claude/utils/federation-transport/a2a-verify.sh"
KEYGEN="${HERE}/a2a-keygen.sh"
SEND="${HERE}/a2a-send.sh"
[ -f "${GATE}" ] && [ -f "${KEYGEN}" ] && [ -f "${SEND}" ] || { echo "gate/keygen/send ausente" >&2; exit 2; }

SB="$(mktemp -d)"
SRV_PID=""
cleanup() { [ -n "${SRV_PID}" ] && kill "${SRV_PID}" 2>/dev/null; rm -rf "${SB}"; }
trap cleanup EXIT
mkdir -p "${SB}/docs/evolution/federation" "${SB}/jwks" "${SB}/home" "${SB}/ps"
cat > "${SB}/docs/evolution/federation/members.yaml" <<'YML'
members:
  - id: onion-evolve
    role: source
    kind: source
    remote: github.com/marciocar/onion-evolve
  - id: acme
    role: standalone
    remote: github.com/acme/app
    a2a: { keys: [acme-1] }
    trust: { can_receive_from: [onion-evolve] }
YML

if [ "${MUTANT}" = "perm0644" ]; then
  # o mutante deixa a privada legível por todos DEPOIS de publicada (o defeito clássico de keygen)
  sed -e 's|^ln "\${TMPD}/priv.pem" "\${PRIV}" .*$|&\nchmod 644 "${PRIV}" # MUTANTE: privada 0644|' "${KEYGEN}" > "${SB}/a2a-keygen.mut.sh"
  [ "$(grep -c '# MUTANTE' "${SB}/a2a-keygen.mut.sh")" = "1" ] || { echo "âncora do mutante não casou" >&2; exit 2; }
  KEYGEN="${SB}/a2a-keygen.mut.sh"
  echo "### MUTANTE ativo: ${MUTANT} (keygen com chmod 644 na privada)"
elif [ "${MUTANT}" = "token-argv" ]; then
  # o mutante faz o que o remetente NÃO pode: o bearer vira argumento do curl (visível em ps)
  sed -e 's|-H @"${HDRFILE}"|-H "Authorization: Bearer $(tr -d "\\r\\n" < "${TOKEN_FILE}")"|' \
      -e '1a # MUTANTE: bearer em argv' "${SEND}" > "${SB}/a2a-send.mut.sh"
  { [ "$(grep -c '# MUTANTE' "${SB}/a2a-send.mut.sh")" = "1" ] && grep -q 'Bearer \$(tr' "${SB}/a2a-send.mut.sh"; } \
    || { echo "âncora do mutante não casou" >&2; exit 2; }
  SEND="${SB}/a2a-send.mut.sh"
  echo "### MUTANTE ativo: ${MUTANT} (send com bearer em argv do curl)"
fi

ROWS=(); FAILS=0
row() {  # caso esperado obtido ok(0/1)
  local mark="OK"; [ "$4" -eq 0 ] || { mark="FALHOU"; FAILS=$((FAILS+1)); }
  ROWS+=("$(printf '%-44s | %-34s | %-40s | %s' "$1" "$2" "$3" "${mark}")")
}
reason_of() { jq -r 'if .verified then "verified" else .reason end' 2>/dev/null <<<"$1"; }
gate() {  # $1 = envelope; $2 = "dry" ou "live"  → imprime o veredito
  local extra=(); [ "$2" = "dry" ] && extra=(--dry-run)
  A2A_CLOCK_TRUST=attested A2A_JWKS_DIR="${SB}/jwks" bash "${GATE}" --receiver onion-evolve --repo "${SB}" "${extra[@]}" --envelope - <<<"$1" 2>/dev/null
}
CFG="${SB}/home/.config/onion/a2a"

# ------------------------------------------------------------------ S1 ----
# S1.f prepara: token aleatório em arquivo 0600 (nunca em argv: openssl rand escreve direto no arquivo)
mkdir -p "${SB}/secret"; chmod 700 "${SB}/secret"
( umask 077; openssl rand -hex 24 > "${SB}/secret/bridge-token" )

# amostrador de argv: grava snapshots de `ps -eo args` enquanto o PID vive
watch_ps() {  # $1 = pid; $2 = arquivo de saída
  local n=0
  while kill -0 "$1" 2>/dev/null; do ps -eo args= >> "$2" 2>/dev/null; echo "----" >> "$2"; n=$((n+1)); done
  echo "${n}" > "$2.n"
}

# keygen em background SEM --dir (exercita o default ~/.config/onion/a2a com HOME do sandbox)
HOME="${SB}/home" bash "${KEYGEN}" --member acme > "${SB}/kg.out" 2> "${SB}/kg.err" &
KG_PID=$!
watch_ps "${KG_PID}" "${SB}/ps/keygen"
wait "${KG_PID}"; KG_RC=$?

PRIV="${CFG}/acme-1.key.pem"; PUB="${CFG}/acme-1.pem"
# S1.a
if [ "${KG_RC}" -eq 0 ] && grep -qx 'kid=acme-1' "${SB}/kg.out" && grep -q '^public=' "${SB}/kg.out" \
   && grep -q '^fingerprint=sha256:[0-9a-f]\{64\}$' "${SB}/kg.out" && ! grep -q 'PRIVATE KEY' "${SB}/kg.out" "${SB}/kg.err"; then
  row "S1.a keygen imprime kid/pub/fp, sem privada" "rc0 + 3 linhas, sem PRIVATE KEY" "rc=${KG_RC} ok" 0
else row "S1.a keygen imprime kid/pub/fp, sem privada" "rc0 + 3 linhas, sem PRIVATE KEY" "rc=${KG_RC} saída fora da forma" 1; fi
# S1.b
P_PRIV="$(stat -c %a "${PRIV}" 2>/dev/null || echo ausente)"
P_PUB="$(stat -c %a "${PUB}" 2>/dev/null || echo ausente)"
P_DIR="$(stat -c %a "${CFG}" 2>/dev/null || echo ausente)"
ok=1; [ "${P_PRIV}" = "600" ] && [ "${P_PUB}" = "644" ] && [ "${P_DIR}" = "700" ] && ok=0
row "S1.b modos priv/pub/dir" "600/644/700" "${P_PRIV}/${P_PUB}/${P_DIR}" "${ok}"
# S1.c
BITS="$(openssl pkey -pubin -in "${PUB}" -noout -text 2>/dev/null | sed -n 's/.*Public-Key: (\([0-9]*\) bit).*/\1/p')"
FP_OUT="$(sed -n 's/^fingerprint=sha256://p' "${SB}/kg.out")"
FP_RE="$(openssl pkey -pubin -in "${PUB}" -outform DER 2>/dev/null | openssl dgst -sha256 | awk '{print $NF}')"
ok=1; [ "${BITS:-0}" -ge 3072 ] && [ -n "${FP_OUT}" ] && [ "${FP_OUT}" = "${FP_RE}" ] && ok=0
row "S1.c bits e fingerprint SPKI" ">=3072 e fp==sha256(DER)" "${BITS:-?} bits, fp $([ "${FP_OUT}" = "${FP_RE}" ] && echo bate || echo diverge)" "${ok}"
# S1.d
H0="$(openssl dgst -sha256 "${PRIV}" 2>/dev/null | awk '{print $NF}')"
HOME="${SB}/home" bash "${KEYGEN}" --member acme >/dev/null 2>&1; RC2=$?
H1="$(openssl dgst -sha256 "${PRIV}" 2>/dev/null | awk '{print $NF}')"
ok=1; [ "${RC2}" -eq 2 ] && [ "${H0}" = "${H1}" ] && ok=0
row "S1.d recusa sobrescrever" "rc2, privada intacta" "rc=${RC2}, $([ "${H0}" = "${H1}" ] && echo intacta || echo ALTERADA)" "${ok}"
# pina a pública no JWKS do receptor (o passo que o configurador vai automatizar)
cp "${PUB}" "${SB}/jwks/acme-1.pem"
# S1.e
ENV_OK="$(HOME="${SB}/home" bash "${SEND}" --dry-run --from acme --to onion-evolve --body $'S1: olá, "é"?\n' 2>/dev/null)"
V="$(gate "${ENV_OK}" dry)"; R="$(reason_of "${V}")"
ok=1; [ "${R}" = "verified" ] && ok=0
row "S1.e gate aceita envelope da chave gerada" "verified" "${R:-sem veredito}" "${ok}"
# S1.f — send REAL contra listener local (loopback), em background, com amostragem de argv
cat > "${SB}/listener.py" <<'PY'
import sys, time, hashlib, http.server
out = sys.argv[1]
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        self.rfile.read(int(self.headers.get("Content-Length", "0")))
        with open(out, "w") as f: f.write(hashlib.sha256(self.headers.get("Authorization", "").encode()).hexdigest())
        time.sleep(1.5)   # segura o curl vivo para o amostrador de argv vê-lo
        self.send_response(200); self.send_header("Content-Type", "application/json"); self.end_headers()
        self.wfile.write(b'{"ok":true}')
    def log_message(self, *a): pass
s = http.server.HTTPServer(("127.0.0.1", 0), H)
open(out + ".port", "w").write(str(s.server_address[1]))
s.handle_request()
PY
python3 "${SB}/listener.py" "${SB}/auth.sha" & SRV_PID=$!
for _ in $(seq 1 50); do [ -s "${SB}/auth.sha.port" ] && break; sleep 0.1; done
PORT="$(cat "${SB}/auth.sha.port" 2>/dev/null)"
HOME="${SB}/home" bash "${SEND}" --from acme --to onion-evolve --body 'S1.f: argv limpo' \
  --endpoint "http://127.0.0.1:${PORT}/a2a" --token-file "${SB}/secret/bridge-token" > "${SB}/send.out" 2> "${SB}/send.err" &
SD_PID=$!
watch_ps "${SD_PID}" "${SB}/ps/send"
wait "${SD_PID}"; SD_RC=$?
wait "${SRV_PID}" 2>/dev/null; SRV_PID=""
# pedaço do corpo da privada (2ª linha do PEM) — o vazamento de conteúdo, não só do rótulo
sed -n '2p' "${PRIV}" > "${SB}/secret/privline"
LEAK=""
for f in "${SB}/ps/keygen" "${SB}/ps/send"; do
  grep -qF -f "${SB}/secret/bridge-token" "${f}" && LEAK="${LEAK} token@$(basename "$f")"
  grep -qF 'PRIVATE KEY' "${f}" && LEAK="${LEAK} PRIVATE-KEY@$(basename "$f")"
  grep -qF -f "${SB}/secret/privline" "${f}" && LEAK="${LEAK} privbody@$(basename "$f")"
done
SEEN_GEN=0; grep -q 'openssl genpkey' "${SB}/ps/keygen" && SEEN_GEN=1
SEEN_CURL=0; grep -q '^curl ' "${SB}/ps/send" && SEEN_CURL=1
EXP_AUTH="$(printf 'Bearer %s' "$(tr -d '\r\n' < "${SB}/secret/bridge-token")" | openssl dgst -sha256 | awk '{print $NF}')"
AUTH_OK=0; [ "$(cat "${SB}/auth.sha" 2>/dev/null)" = "${EXP_AUTH}" ] && AUTH_OK=1
NK="$(cat "${SB}/ps/keygen.n")"; NS="$(cat "${SB}/ps/send.n")"
ok=1; [ -z "${LEAK}" ] && [ "${SEEN_GEN}" = 1 ] && [ "${SEEN_CURL}" = 1 ] && [ "${AUTH_OK}" = 1 ] && [ "${SD_RC}" -eq 0 ] && ok=0
row "S1.f argv sem segredo (ps amostrado)" "0 vazamento; viu genpkey+curl; bearer ok" \
  "vaz=[${LEAK:-0}] gen=${SEEN_GEN} curl=${SEEN_CURL} auth=${AUTH_OK} amostras=${NK}+${NS}" "${ok}"

# ------------------------------------------------------------------ S2 ----
_b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
_jws_raw() {  # $1 payload JSON · $2 kid · $3 chave privada
  local h p; h="$(printf '{"alg":"RS256","kid":"%s","typ":"JWT"}' "$2" | _b64url)"; p="$(printf '%s' "$1" | _b64url)"
  printf '%s.%s.%s' "$h" "$p" "$(printf '%s' "$h.$p" | openssl dgst -sha256 -sign "$3" | _b64url)"
}
snd() { HOME="${SB}/home" bash "${SEND}" --dry-run --from acme --to onion-evolve "$@" 2>/dev/null; }
check() {  # caso esperado veredito
  local r; r="$(reason_of "$3")"; local ok=1
  case "$2" in *:*) [ "${r}" = "$2" ] && ok=0 ;; *) [ "${r}" = "$2" ] && ok=0 ;; esac
  row "$1" "$2" "${r:-sem veredito}" "${ok}"
}
# S2.0
check "S2.0 envelope certo" "verified" "$(gate "$(snd --body 'S2.0 certo')" dry)"
# S2.1 sem body_sha256: payload de julho, assinado pela chave GERADA (o defeito é só a ausência do claim)
NOW="$(date +%s)"
J="$(_jws_raw "{\"iss\":\"acme\",\"aud\":\"onion-evolve\",\"iat\":${NOW},\"exp\":$((NOW+300)),\"jti\":\"s2-nosha\"}" acme-1 "${PRIV}")"
check "S2.1 sem body_sha256" "jws-missing-body-sha256" \
  "$(gate "$(jq -cn --arg j "${J}" '{jws:$j,signal:{from:"acme",to:"onion-evolve",kind:"signal"}}')" dry)"
# S2.2 exp vencido (iat 120 s atrás, exp 60 s atrás)
check "S2.2 exp vencido" "expired" "$(gate "$(snd --body 'S2.2' --iat-offset -120 --exp-offset -60)" dry)"
# S2.3 replay: o MESMO envelope duas vezes, gate SEM --dry-run (grava trust-log e jti.state no sandbox)
ENV_R="$(snd --body 'S2.3 replay' --jti s2-replay-1)"
V1="$(gate "${ENV_R}" live)"; V2="$(gate "${ENV_R}" live)"
check "S2.3a replay — 1º envio" "verified" "${V1}"
check "S2.3b replay — 2º envio (mesmo jti)" "replay" "${V2}"
# S2.4 kid não pinado: acme-2 existe e está no JWKS, mas members.yaml[acme].a2a.keys = [acme-1]
HOME="${SB}/home" bash "${KEYGEN}" --member acme --n 2 >/dev/null 2>&1
cp "${CFG}/acme-2.pem" "${SB}/jwks/acme-2.pem" 2>/dev/null
check "S2.4 kid não pinado (acme-2)" "kid-not-owned-by-from:acme-2" \
  "$(gate "$(snd --body 'S2.4' --kid acme-2)" dry)"

# ---------------------------------------------------------------- tabela --
echo
printf '%-44s | %-34s | %-40s | %s\n' "caso" "esperado" "obtido" "resultado"
printf '%s\n' "$(printf '%.0s-' $(seq 1 135))"
printf '%s\n' "${ROWS[@]}"
echo
if [ "${FAILS}" -eq 0 ]; then echo "S1+S2: ${#ROWS[@]}/${#ROWS[@]} casos bateram"; exit 0
else echo "S1+S2: ${FAILS} de ${#ROWS[@]} casos DIVERGIRAM"; exit 1; fi
