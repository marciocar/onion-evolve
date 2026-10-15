#!/usr/bin/env bash
# =============================================================================
# run-f3-dogfood.sh — DOGFOOD da F3 do configurador A2A (SAC-124; teste S5 do plano): o hub junto com o core.
#
# Sobe o onion-bridge LOCAL (branch feat/a2a-multi-receiver) em 127.0.0.1, com ONION_CWD num SANDBOX que leva
# o gate DESTA árvore do core (a2a-verify.sh, a2a-ssrf-check.sh, trust-topology-check.sh, a2a-accept.sh) e um
# registro com DOIS receptores: o core (onion-evolve) e um hub de fixture (hub-a), mais um filho do hub
# (kid-a, parent hub-a), um standalone do core (acme), outro hub (hub-b), um standalone que não recebe
# (solo-x) e uma porta (porta-x). Os convites são POR MEMBRO e POR RECEPTOR, no formato do bridge (só o
# sha256 dos tokens). Nada toca a VPS. Depois, o aceite fecha a ponta: a fila do hub só entra pelo aceite
# do hub.
#
# Segredos: tokens aleatórios de teste, vivem só no sandbox, vão ao curl por ARQUIVO 0600; chaves RSA
# efêmeras. O bridge roda com `env -i` num cwd sem arquivo de ambiente do operador.
# CRITÉRIO (escrito antes da medição): cada linha da tabela é um `check`; qualquer divergência = FAIL.
# Uso:  run-f3-dogfood.sh <dir-do-bridge-com-node_modules>
# Exit: 0 = todos os casos bateram · 1 = algum divergiu · 2 = uso/tooling
# =============================================================================
set -euo pipefail
BRIDGE="${1:-}"
[ -n "${BRIDGE}" ] && [ -f "${BRIDGE}/src/a2a-receivers.ts" ] && [ -e "${BRIDGE}/node_modules" ] \
  || { echo "uso: $0 <dir do bridge da F3 (com node_modules)>" >&2; exit 2; }
for t in openssl jq curl node python3; do command -v "$t" >/dev/null || { echo "tooling ausente: $t" >&2; exit 2; }; done

CORE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"
SB="$(mktemp -d)"; SRV_PID=""
cleanup() { [ -n "${SRV_PID}" ] && kill "${SRV_PID}" 2>/dev/null; wait 2>/dev/null || true; rm -rf "${SB}"; }
trap cleanup EXIT
chmod 700 "${SB}"

mkdir -p "${SB}/core/.claude/utils/federation-transport" "${SB}/core/.claude/validation" \
         "${SB}/core/docs/evolution/federation" "${SB}/core/docs/onion" "${SB}/jwks" "${SB}/keys" "${SB}/data"
chmod 700 "${SB}/data"
for f in a2a-verify.sh a2a-ssrf-check.sh a2a-accept.sh; do
  cp "${CORE}/.claude/utils/federation-transport/${f}" "${SB}/core/.claude/utils/federation-transport/"
done
cp "${CORE}/.claude/validation/trust-topology-check.sh" "${SB}/core/.claude/validation/"
cp "${CORE}/docs/onion/agent-card.json" "${SB}/core/docs/onion/"
cat > "${SB}/core/docs/evolution/federation/members.yaml" <<'YML'
members:
  - id: onion-evolve
    role: source
    kind: source
  - id: hub-a
    role: hub
    kind: adopter
    parent: onion-evolve
  - id: hub-b
    role: hub
    kind: adopter
    parent: onion-evolve
  - id: porta-x
    role: source
    kind: door
    parent: onion-evolve
  - id: solo-x
    role: standalone
    kind: adopter
    parent: onion-evolve
  - id: acme
    role: standalone
    kind: adopter
    parent: onion-evolve
    a2a: { keys: [acme-1], sends_to: onion-evolve }
  - id: kid-a
    role: consumer
    kind: adopter
    parent: hub-a
    a2a: { keys: [kid-a-1], sends_to: hub-a }
YML
for m in acme kid-a; do
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "${SB}/keys/${m}.pem" 2>/dev/null
  openssl pkey -in "${SB}/keys/${m}.pem" -pubout -out "${SB}/jwks/${m}-1.pem" 2>/dev/null
done

( umask 077; mkdir -p "${SB}/tok" )
mk_tok() { ( umask 077; openssl rand -hex 32 > "${SB}/tok/$1" ); }
sha_tok() { tr -d '\n' < "${SB}/tok/$1" | openssl dgst -sha256 | awk '{print $NF}'; }
for t in ACME KIDHUB KIDCORE KIDHUBB SOLO DOOR GHOST POOL; do mk_tok "$t"; done
FUT="$(date -u -d '+1 day' +%FT%TZ)"
INV="${SB}/data/a2a-invites.json"
jq -n --arg a "$(sha_tok ACME)" --arg kh "$(sha_tok KIDHUB)" --arg kc "$(sha_tok KIDCORE)" --arg kb "$(sha_tok KIDHUBB)" \
      --arg s "$(sha_tok SOLO)" --arg d "$(sha_tok DOOR)" --arg g "$(sha_tok GHOST)" --arg fut "${FUT}" '{version:1, invites:[
  {token_sha256:$a,  member:"acme",  receiver:"onion-evolve", expires_at:$fut, revoked:false},
  {token_sha256:$kh, member:"kid-a", receiver:"hub-a",        expires_at:$fut, revoked:false},
  {token_sha256:$kc, member:"kid-a", receiver:"onion-evolve", expires_at:$fut, revoked:false},
  {token_sha256:$kb, member:"kid-a", receiver:"hub-b",        expires_at:$fut, revoked:false},
  {token_sha256:$s,  member:"kid-a", receiver:"solo-x",       expires_at:$fut, revoked:false},
  {token_sha256:$d,  member:"kid-a", receiver:"porta-x",      expires_at:$fut, revoked:false},
  {token_sha256:$g,  member:"kid-a", receiver:"fantasma",     expires_at:$fut, revoked:false}
]}' > "${INV}.tmp"
chmod 600 "${INV}.tmp"; mv "${INV}.tmp" "${INV}"

PORT="$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()')"
LOG="${SB}/server.log"
( cd "${BRIDGE}" && exec env -i PATH="${PATH}" HOME="${SB}" HOST=127.0.0.1 PORT="${PORT}" \
    ONION_CWD="${SB}/core" A2A_INVITES_FILE="${INV}" A2A_JWKS_DIR="${SB}/jwks" METER_DIR="${SB}/data" \
    A2A_PENDING_DIR="${SB}/pending" UPLOAD_TEMP_DIR="${SB}/uploads" \
    INVITE_TOKENS_A2A="$(cat "${SB}/tok/POOL")" OIDC_ISSUER="http://127.0.0.1:9/oidc" \
    node_modules/.bin/tsx src/server.ts ) > "${LOG}" 2>&1 &
SRV_PID=$!
for _ in $(seq 1 120); do grep -q "no ar em" "${LOG}" 2>/dev/null && break; sleep 0.5; done
grep -q "no ar em" "${LOG}" || { echo "servidor não subiu:"; cat "${LOG}"; exit 2; }
echo "# bridge local da F3 em 127.0.0.1:${PORT} (pid ${SRV_PID}); bridge $(git -C "${BRIDGE}" rev-parse --short HEAD) + árvore; gate do core $(git -C "${CORE}" rev-parse --short HEAD) + árvore"

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
envelope() {  # <from> <to> <aud|-> [jti]   (aud "-" = sem o claim)
  local from="$1" to="$2" aud="$3" jti="${4:-j-$(openssl rand -hex 8)}" now body bs hdr pl sig th
  now="$(date +%s)"; body="dogfood f3 ${jti}"; th="th-f3-$(openssl rand -hex 3)"
  bs="$(printf '%s' "${body}" | openssl dgst -sha256 | awk '{print $NF}')"
  hdr="$(jq -cn --arg kid "${from}-1" '{alg:"RS256",kid:$kid,typ:"JWT"}' | b64url)"
  pl="$(jq -cn --arg iss "${from}" --arg aud "${aud}" --argjson iat "${now}" --argjson exp "$((now+300))" \
        --arg jti "${jti}" --arg bs "${bs}" --arg th "${th}" \
        '{iss:$iss,aud:$aud,iat:$iat,exp:$exp,jti:$jti,body_sha256:$bs,thread:$th} | if $aud=="-" then del(.aud) else . end' | b64url)"
  sig="$(printf '%s' "${hdr}.${pl}" | openssl dgst -sha256 -sign "${SB}/keys/${from}.pem" | b64url)"
  jq -cn --arg jws "${hdr}.${pl}.${sig}" --arg id "sig-${jti}" --arg from "${from}" --arg to "${to}" \
     --arg body "${body}" --arg th "${th}" \
     '{jws:$jws, signal:{id:$id, direction:"upstream", from:$from, to:$to, kind:"question",
       classification:"private", thread:$th, body:$body}}'
}
post() {  # <token-name|-> <path> <envelope-file> → "http reason"
  local hf="${SB}/hdr.$$" r reason
  if [ "$1" = "-" ]; then : > "${hf}"; else ( umask 077; printf 'Authorization: Bearer %s\n' "$(tr -d '\n' < "${SB}/tok/$1")" > "${hf}" ); fi
  r="$(curl -sS -m 30 -o "${SB}/resp.json" -w '%{http_code}' -H @"${hf}" -H 'Content-Type: application/json' \
        --data-binary @"$3" "http://127.0.0.1:${PORT}$2" || true)"; rm -f "${hf}"
  reason="$(jq -r '.reason // .status.state // .error // "?"' "${SB}/resp.json" 2>/dev/null || echo '?')"
  printf '%s %s' "${r}" "${reason}"
}
FAILS=0
check() {
  local got_http="${4%% *}" got_reason="${4#* }" ok="PASS"
  [ "${got_http}" = "$2" ] || ok="FAIL"; [ "$3" = "*" ] || [ "${got_reason}" = "$3" ] || ok="FAIL"
  [ "${ok}" = "PASS" ] || FAILS=$((FAILS+1))
  printf '| %s | %s %s | %s %s | %s |\n' "$1" "$2" "$3" "${got_http}" "${got_reason}" "${ok}"
}
yes_no() {  # <caso> <condição-em-bash>
  if eval "$2"; then printf '| %s | sim | sim | PASS |\n' "$1"; else printf '| %s | sim | não | FAIL |\n' "$1"; FAILS=$((FAILS+1)); fi
}
E="${SB}/env.json"; E2="${SB}/env2.json"

echo
echo "| caso | esperado (http motivo) | obtido (http motivo) | veredito |"
echo "|---|---|---|---|"
envelope kid-a hub-a hub-a > "$E";               check "D1 filho do hub → /a2a/hub-a (convite e aud do hub)"         200 input_required "$(post KIDHUB /a2a/hub-a "$E")"
yes_no "D1b registro na fila do HUB (pending/hub-a/), receiver hub-a no registro e no eco do gate" \
  '[ "$(ls "${SB}/pending/hub-a/"*.json 2>/dev/null | wc -l)" = 1 ] && [ "$(jq -r ".receiver+\"/\"+.verdict.receiver" "${SB}/pending/hub-a/"*.json)" = "hub-a/hub-a" ]'
envelope acme onion-evolve onion-evolve > "$E2"; check "D2 standalone do core → /a2a (sem sufixo = o core)"           200 input_required "$(post ACME /a2a "$E2")"
yes_no "D2b registro na fila do CORE (raiz de pending/), receiver onion-evolve" \
  '[ "$(find "${SB}/pending" -maxdepth 1 -name "*.json" | wc -l)" = 1 ] && [ "$(jq -r .receiver "$(find "${SB}/pending" -maxdepth 1 -name "*.json")")" = onion-evolve ]'
envelope kid-a hub-a onion-evolve > "$E";        check "D3 rota do hub, aud de OUTRO receptor (o core)"              403 claim-aud-mismatch "$(post KIDHUB /a2a/hub-a "$E")"
envelope kid-a hub-a - > "$E";                   check "D4 rota do hub, JWS SEM aud"                                 403 jws-missing-aud "$(post KIDHUB /a2a/hub-a "$E")"
envelope kid-a hub-a hub-a > "$E";               check "D5 convite do filho para o CORE usado em /a2a/hub-a"         401 convite-de-outro-receptor "$(post KIDCORE /a2a/hub-a "$E")"
envelope kid-a onion-evolve onion-evolve > "$E"; check "D6 convite do filho para o HUB usado em /a2a (o core)"       401 convite-de-outro-receptor "$(post KIDHUB /a2a "$E")"
envelope kid-a onion-evolve onion-evolve > "$E"; check "D7 filho do hub → o core, com convite do core (permitido)"   200 input_required "$(post KIDCORE /a2a "$E")"
envelope kid-a hub-b hub-b > "$E";               check "D8 filho do hub-a → /a2a/hub-b (não é o pai dele)"           403 trust-denied "$(post KIDHUBB /a2a/hub-b "$E")"
envelope kid-a solo-x solo-x > "$E";             check "D9 /a2a/solo-x (role standalone)"                            400 "receptor-nao-recebe:role=standalone" "$(post SOLO /a2a/solo-x "$E")"
envelope kid-a porta-x porta-x > "$E";           check "D10 /a2a/porta-x (role source, kind door)"                   400 "receptor-nao-recebe:kind=door" "$(post DOOR /a2a/porta-x "$E")"
envelope kid-a fantasma fantasma > "$E";         check "D11 /a2a/fantasma (fora do registro)"                        404 receptor-desconhecido "$(post GHOST /a2a/fantasma "$E")"
envelope kid-a hub-a hub-a > "$E";               check "D12 /a2a/-repo (injeção de opção no gate)"                   400 receptor-malformado "$(post KIDHUB /a2a/-repo "$E")"
envelope kid-a hub-a hub-a > "$E";               check "D13 /a2a/hub-a sem bearer"                                   401 credencial-ausente "$(post - /a2a/hub-a "$E")"
envelope kid-a hub-a hub-a > "$E";               check "D14 pool legado em /a2a/hub-a"                               401 pool-fora-do-receptor-padrao "$(post POOL /a2a/hub-a "$E")"
check "D15 o envelope aceito no core (D2) reapresentado em /a2a/hub-a com o convite do core" 401 convite-de-outro-receptor "$(post ACME /a2a/hub-a "$E2")"
envelope kid-a onion-evolve onion-evolve > "$E"
check "D16a envelope do filho para o core, aceito no core"                                       200 input_required "$(post KIDCORE /a2a "$E")"
jq -c '.signal.to="hub-a"' "$E" > "${E2}"
check "D16b o MESMO envelope (jti e aud do core, signal.to reescrito) em /a2a/hub-a com o convite do hub" 403 claim-aud-mismatch "$(post KIDHUB /a2a/hub-a "${E2}")"
if kill -0 "${SRV_PID}" 2>/dev/null; then echo "| D17 o servidor segue de pé (mesmo pid, sem restart) | sim | sim | PASS |"
else echo "| D17 servidor de pé | sim | não | FAIL |"; FAILS=$((FAILS+1)); fi

# --- o doctor do filho contra o bridge de verdade: a rota do hub responde 401 (existe), a errada não -----
DOC="${CORE}/.claude/utils/federation-transport/a2a-doctor.sh"
doc_g() {  # <url> → "status|causa" da checagem (g); o doctor sai rc != 0 (falta chave etc.): lê-se o JSON
  local j; j="$(A2A_CLOCK_TRUST=attested HOME="${SB}" XDG_CONFIG_HOME= bash "${DOC}" --member kid-a --receiver hub-a \
    --members "${SB}/core/docs/evolution/federation/members.yaml" --jwks "${SB}/jwks" --endpoint "$1" --json 2>/dev/null || true)"
  jq -r '.checks[] | select(.id=="g") | "\(.status)|\(.cause)"' <<< "${j}" 2>/dev/null || true
}
G="$(doc_g "http://127.0.0.1:${PORT}/a2a/hub-a")"
yes_no "G1 doctor com a rota do hub → (g) ok, HTTP 401 (o guard responde: a rota existe)" '[ "${G%%|*}" = ok ] && [[ "${G}" == *"HTTP 401"* ]]'
G="$(doc_g "http://127.0.0.1:${PORT}/a2a/hub-a/")"
yes_no "G2 doctor com barra final → (g) falha rota malformada (o bridge responde 404)" '[ "${G%%|*}" = falha ] && [[ "${G}" == *"rota malformada"* ]]'
G="$(doc_g "http://127.0.0.1:${PORT}/a2a")"
yes_no "G3 doctor do filho do hub apontando /a2a (o core) → (g) falha" '[ "${G%%|*}" = falha ] && [[ "${G}" == *"receptor padrão"* ]]'
code="$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' --data '{}' "http://127.0.0.1:${PORT}/a2a/hub-a/")"
yes_no "G4 o bridge responde 404 a /a2a/hub-a/ (o que o doctor previu)" '[ "${code}" = 404 ]'

# --- o aceite: a fila do hub só entra pelo aceite DO HUB -------------------------------------
ACC="${SB}/core/.claude/utils/federation-transport/a2a-accept.sh"
HUBREC="$(ls "${SB}/pending/hub-a/"*.json | head -1)"
mkdir -p "${SB}/hub-inbox" "${SB}/core-inbox"
rc=0; bash "${ACC}" "${HUBREC}" --inbox "${SB}/core-inbox" >/dev/null 2>&1 || rc=$?
yes_no "A1 aceite do CORE recusa o registro do hub (rc 1, nada no inbox do core)" "[ ${rc} -eq 1 ] && [ -z \"\$(ls \"${SB}/core-inbox\")\" ]"
rc=0; bash "${ACC}" "${HUBREC}" --inbox "${SB}/hub-inbox" --receiver hub-a >/dev/null 2>&1 || rc=$?
yes_no "A2 aceite do HUB (--receiver hub-a) materializa o sinal no inbox do hub, endereçado a ele" "[ ${rc} -eq 0 ] && grep -q '^para: hub-a ' \"${SB}\"/hub-inbox/*.md"

echo
echo "# linhas de recusa (401/400) no log do bridge: $(grep -c 'a2a 401\|a2a 400' "${LOG}" || true)"
if grep -qF "$(cat "${SB}/tok/KIDHUB")" "${LOG}"; then echo "| L1 o log NÃO carrega token | sim | NÃO | FAIL |"; FAILS=$((FAILS+1))
else echo "| L1 o log não carrega token | sim | sim | PASS |"; fi
echo
if [ "${FAILS}" -eq 0 ]; then echo "✓ dogfood F3: todos os casos bateram"; exit 0; fi
echo "✗ dogfood F3: ${FAILS} caso(s) divergiram"; exit 1
