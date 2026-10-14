#!/usr/bin/env bash
# =============================================================================
# run-s4-s5.sh — SPIKE F0 do configurador A2A (Linear SAC-121; S4 = SAC-129, S5 = SAC-130).
#
# Mede o protótipo do lado SERVIDOR (bridge) aplicado por bridge-invites-receivers.diff:
#   S4 — convite por membro (A2A_INVITES_FILE, relido a cada POST, amarração bearer↔from)
#   S5 — receptor múltiplo (/a2a/:receiver, role source|hub no members.yaml, aud por receptor)
#
# NADA disto é produção. Sobe o bridge LOCAL em 127.0.0.1 (porta livre), com ONION_CWD apontando
# para um SANDBOX descartável: cópias do gate do core (a2a-verify.sh, a2a-ssrf-check.sh,
# trust-topology-check.sh) desta árvore, um members.yaml de TESTE e um JWKS de chaves RSA EFÊMERAS.
# O sandbox é necessário porque o bridge chama o gate sem --dry-run: ele grava trust-log.md e o
# estado de jti no REPO alvo — apontar para o core de verdade sujaria a árvore.
#
# Segredos: os bearers de teste são aleatórios, nascem e morrem aqui, vão ao curl por ARQUIVO de
# cabeçalho 0600 (nunca argv) e o arquivo de convites guarda só o sha256 deles. Nenhum .env é lido
# (o bridge roda num cwd sem .env).
#
# CRITÉRIO (escrito ANTES da medição; cada linha da tabela é um `check` abaixo):
#   S4 passa se: convite certo → 200; convite de OUTRO membro com from≠member → 403 e o jti NÃO queima
#     (o dono reenvia o mesmo envelope e passa); vencido → 401; revogado → 401; revogar EDITANDO o
#     arquivo com o servidor no ar → a chamada seguinte já dá 401 e o pid é o mesmo; pool legado só em /a2a.
#   S5 passa se: /a2a/<role: hub> → 200; /a2a/<role: adopted> → 400 com o role no motivo; fora do
#     members.yaml → 404; aud de outro receptor → 403 claim-aud-mismatch (veto do GATE, não do bridge);
#     convite de um receptor usado na rota de outro → 403.
#   Qualquer divergência de http OU de motivo = FAIL (exit 1).
#
# Uso:  run-s4-s5.sh <dir-da-cópia-do-bridge-com-o-diff-aplicado-e-node_modules>
# Exit: 0 = todos os casos bateram o esperado · 1 = algum divergiu · 2 = uso/tooling
# =============================================================================
set -euo pipefail

BRIDGE="${1:-}"
[ -n "${BRIDGE}" ] && [ -f "${BRIDGE}/src/server.ts" ] && [ -d "${BRIDGE}/node_modules" ] \
  || { echo "uso: $0 <dir-do-bridge (com node_modules e o diff aplicado)>" >&2; exit 2; }
[ ! -e "${BRIDGE}/.env" ] || { echo "ERRO: ${BRIDGE}/.env existe — o spike não roda com .env de verdade" >&2; exit 2; }
for t in openssl jq curl node python3; do command -v "$t" >/dev/null || { echo "tooling ausente: $t" >&2; exit 2; }; done
python3 -c 'import yaml' 2>/dev/null || { echo "tooling ausente: python3-yaml" >&2; exit 2; }

CORE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)"
SB="$(mktemp -d)"; SRV_PID=""
cleanup() { [ -n "${SRV_PID}" ] && kill "${SRV_PID}" 2>/dev/null; wait 2>/dev/null || true; rm -rf "${SB}"; }
trap cleanup EXIT

# --- sandbox do core ---------------------------------------------------------
mkdir -p "${SB}/core/.claude/utils/federation-transport" "${SB}/core/.claude/validation" \
         "${SB}/core/docs/evolution/federation" "${SB}/core/docs/onion" "${SB}/jwks" "${SB}/keys"
cp "${CORE}/.claude/utils/federation-transport/a2a-verify.sh" "${CORE}/.claude/utils/federation-transport/a2a-ssrf-check.sh" \
   "${SB}/core/.claude/utils/federation-transport/"
cp "${CORE}/.claude/validation/trust-topology-check.sh" "${SB}/core/.claude/validation/"
cp "${CORE}/docs/onion/agent-card.json" "${SB}/core/docs/onion/"
cat > "${SB}/core/docs/evolution/federation/members.yaml" <<'YML'
members:
  - id: onion-evolve
    role: source
    kind: source
  # porta-teste imita a porta onion-core: role source, kind door
  - id: porta-teste
    role: source
    kind: door
  - id: hub-comentado          # hub com comentário NA LINHA DO id: yaml lê, o awk do trust-check não
    role: hub
    kind: adopter
  - id: hub-teste
    role: hub
    kind: adopter
  - id: adotado-teste
    role: adopted
    kind: adopter
  - id: alice
    role: consumer
    kind: adopter
    a2a: { keys: [k-alice] }
  - id: bob
    role: consumer
    kind: adopter
    a2a: { keys: [k-bob] }
YML
for m in alice bob; do
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "${SB}/keys/${m}.pem" 2>/dev/null
  openssl pkey -in "${SB}/keys/${m}.pem" -pubout -out "${SB}/jwks/k-${m}.pem" 2>/dev/null
done

# --- bearers + convites -------------------------------------------------------
( umask 077; mkdir -p "${SB}/tok" )
mk_tok() { ( umask 077; openssl rand -hex 24 > "${SB}/tok/$1" ); }
sha_tok() { tr -d '\n' < "${SB}/tok/$1" | openssl dgst -sha256 | awk '{print $NF}'; }
for t in A B C D E F G H I R P X; do mk_tok "$t"; done
FUT="$(date -u -d '+1 day' +%FT%TZ)"; PAST="$(date -u -d '-1 hour' +%FT%TZ)"
INV="${SB}/invites.json"
write_invites() {  # $1 = revoked do convite R (false|true)
  jq -n --arg a "$(sha_tok A)" --arg b "$(sha_tok B)" --arg c "$(sha_tok C)" --arg d "$(sha_tok D)" \
        --arg e "$(sha_tok E)" --arg f "$(sha_tok F)" --arg g "$(sha_tok G)" --arg h "$(sha_tok H)" --arg i "$(sha_tok I)" \
        --arg r "$(sha_tok R)" --arg fut "${FUT}" --arg past "${PAST}" --argjson rrev "$1" '[
    {token_sha256:$a, member:"alice", receiver:"onion-evolve",  expires_at:$fut,  revoked:false},
    {token_sha256:$b, member:"bob",   receiver:"onion-evolve",  expires_at:$fut,  revoked:false},
    {token_sha256:$c, member:"alice", receiver:"onion-evolve",  expires_at:$past, revoked:false},
    {token_sha256:$d, member:"alice", receiver:"onion-evolve",  expires_at:$fut,  revoked:true},
    {token_sha256:$e, member:"alice", receiver:"hub-teste",     expires_at:$fut,  revoked:false},
    {token_sha256:$f, member:"alice", receiver:"adotado-teste", expires_at:$fut,  revoked:false},
    {token_sha256:$g, member:"alice", receiver:"porta-teste",   expires_at:$fut,  revoked:false},
    {token_sha256:$h, member:"alice", receiver:"fantasma",      expires_at:$fut,  revoked:false},
    {token_sha256:$i, member:"alice", receiver:"hub-comentado", expires_at:$fut,  revoked:false},
    {token_sha256:$r, member:"alice", receiver:"onion-evolve",  expires_at:$fut,  revoked:$rrev}
  ]' > "${INV}.tmp" && mv "${INV}.tmp" "${INV}"   # troca atômica: o servidor nunca lê meio arquivo
}
write_invites false

# --- sobe o bridge local -------------------------------------------------------
PORT="$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()')"
LOG="${SB}/server.log"
( cd "${BRIDGE}" && exec env -i PATH="${PATH}" HOME="${SB}" HOST=127.0.0.1 PORT="${PORT}" \
    ONION_CWD="${SB}/core" A2A_INVITES_FILE="${INV}" A2A_JWKS_DIR="${SB}/jwks" \
    A2A_PENDING_DIR="${SB}/pending" UPLOAD_TEMP_DIR="${SB}/uploads" \
    INVITE_TOKENS_A2A="$(cat "${SB}/tok/P")" OIDC_ISSUER="http://127.0.0.1:9/oidc" \
    node_modules/.bin/tsx src/server.ts ) > "${LOG}" 2>&1 &
SRV_PID=$!
for _ in $(seq 1 60); do grep -q "no ar em" "${LOG}" 2>/dev/null && break; sleep 0.5; done
grep -q "no ar em" "${LOG}" || { echo "servidor não subiu:"; cat "${LOG}"; exit 2; }
echo "# bridge local em 127.0.0.1:${PORT} (pid ${SRV_PID})"

# --- remetente: envelope assinado (mesma forma do send-a2a.sh) ----------------
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
envelope() {  # <from> <to> <aud> [jti]
  local from="$1" to="$2" aud="$3" jti="${4:-j-$(openssl rand -hex 8)}" now body bs hdr pl sig th
  now="$(date +%s)"; body="spike s4/s5 ${jti}"; th="th-spike-$(openssl rand -hex 3)"
  bs="$(printf '%s' "${body}" | openssl dgst -sha256 | awk '{print $NF}')"
  hdr="$(jq -cn --arg kid "k-${from}" '{alg:"RS256",kid:$kid,typ:"JWT"}' | b64url)"
  pl="$(jq -cn --arg iss "${from}" --arg aud "${aud}" --argjson iat "${now}" --argjson exp "$((now+300))" \
        --arg jti "${jti}" --arg bs "${bs}" --arg th "${th}" '{iss:$iss,aud:$aud,iat:$iat,exp:$exp,jti:$jti,body_sha256:$bs,thread:$th}' | b64url)"
  sig="$(printf '%s' "${hdr}.${pl}" | openssl dgst -sha256 -sign "${SB}/keys/${from}.pem" | b64url)"
  jq -cn --arg jws "${hdr}.${pl}.${sig}" --arg id "sig-${jti}" --arg from "${from}" --arg to "${to}" \
     --arg body "${body}" --arg bs "${bs}" --arg th "${th}" \
     '{jws:$jws, signal:{id:$id, direction:"upstream", from:$from, to:$to, kind:"question",
       classification:"private", thread:$th, body:$body, body_sha256:$bs}}'
}
post() {  # <token-name> <path> <envelope-file> → "http reason"
  local hf="${SB}/hdr.$$"; ( umask 077; printf 'Authorization: Bearer %s\n' "$(tr -d '\n' < "${SB}/tok/$1")" > "${hf}" )
  local r; r="$(curl -sS -m 30 -o "${SB}/resp.json" -w '%{http_code}' -H @"${hf}" -H 'Content-Type: application/json' \
          --data-binary @"$3" "http://127.0.0.1:${PORT}$2" || true)"; rm -f "${hf}"
  local reason; reason="$(jq -r '.reason // .status.state // .error // "?"' "${SB}/resp.json" 2>/dev/null || echo '?')"
  printf '%s %s' "${r}" "${reason}"
}
FAILS=0
check() {  # <caso> <esperado-http> <esperado-reason|*> <obtido "http reason">
  local got_http="${4%% *}" got_reason="${4#* }" ok="PASS"
  [ "${got_http}" = "$2" ] || ok="FAIL"; [ "$3" = "*" ] || [ "${got_reason}" = "$3" ] || ok="FAIL"
  [ "${ok}" = "PASS" ] || FAILS=$((FAILS+1))
  printf '| %s | %s %s | %s %s | %s |\n' "$1" "$2" "$3" "${got_http}" "${got_reason}" "${ok}"
}
E="${SB}/env.json"

echo
echo "| caso | esperado (http motivo) | obtido (http motivo) | veredito |"
echo "|---|---|---|---|"
# ----------------------------- S4 ---------------------------------------------
envelope alice onion-evolve onion-evolve > "$E";             check "S4.1 convite certo (alice→/a2a)"            200 input_required           "$(post A /a2a "$E")"
envelope alice onion-evolve onion-evolve j-s42 > "$E"
                                                               check "S4.2 convite de OUTRO membro (bob) + from alice" 403 from-nao-e-o-membro-do-convite "$(post B /a2a "$E")"
                                                               check "S4.2b mesmo envelope, convite certo (jti não queimado)" 200 input_required "$(post A /a2a "$E")"
envelope alice onion-evolve onion-evolve > "$E";             check "S4.3 convite vencido"                        401 convite-vencido          "$(post C /a2a "$E")"
envelope alice onion-evolve onion-evolve > "$E";             check "S4.4 convite revogado"                       401 convite-revogado         "$(post D /a2a "$E")"
envelope alice onion-evolve onion-evolve > "$E";             check "S4.5a convite R válido (antes de revogar)"   200 input_required           "$(post R /a2a "$E")"
write_invites true   # revoga R EDITANDO o arquivo, servidor rodando
envelope alice onion-evolve onion-evolve > "$E";             check "S4.5b R revogado no arquivo, sem restart"    401 convite-revogado         "$(post R /a2a "$E")"
kill -0 "${SRV_PID}" 2>/dev/null && echo "| S4.5c servidor é o MESMO processo (sem restart) | pid ${SRV_PID} vivo | pid ${SRV_PID} vivo | PASS |" \
  || { echo "| S4.5c servidor é o MESMO processo | vivo | morto | FAIL |"; FAILS=$((FAILS+1)); }
envelope alice onion-evolve onion-evolve > "$E";             check "S4.6 bearer desconhecido"                    401 bearer-desconhecido      "$(post X /a2a "$E")"
envelope alice onion-evolve onion-evolve > "$E";             check "S4.7 pool legado em /a2a (compat)"           200 input_required           "$(post P /a2a "$E")"
envelope alice hub-teste hub-teste > "$E";                   check "S4.8 pool legado em /a2a/hub-teste"          403 pool-fora-do-receptor-padrao "$(post P /a2a/hub-teste "$E")"
envelope alice hub-teste hub-teste > "$E";                   check "S4.9 convite p/ onion-evolve usado em /a2a/hub-teste" 403 convite-de-outro-receptor "$(post A /a2a/hub-teste "$E")"
# ----------------------------- S5 ---------------------------------------------
envelope alice hub-teste hub-teste > "$E";                   check "S5.1 /a2a/hub-teste (role: hub)"             200 input_required           "$(post E /a2a/hub-teste "$E")"
envelope alice adotado-teste adotado-teste > "$E";           check "S5.2 /a2a/adotado-teste (role: adopted)"     400 receptor-nao-recebe:role=adopted "$(post F /a2a/adotado-teste "$E")"
envelope alice hub-teste onion-evolve > "$E";                check "S5.3 rota hub-teste, aud=onion-evolve"       403 claim-aud-mismatch       "$(post E /a2a/hub-teste "$E")"
envelope alice fantasma fantasma > "$E";                     check "S5.4 /a2a/fantasma (fora do members.yaml)"   404 receptor-desconhecido    "$(post H /a2a/fantasma "$E")"
envelope alice porta-teste porta-teste > "$E";               check "S5.5 /a2a/porta-teste (role: source, kind: door)" 403 trust-denied     "$(post G /a2a/porta-teste "$E")"
envelope alice hub-comentado hub-comentado > "$E";           check "S5.6 /a2a/hub-comentado (id com # inline)"   403 trust-denied             "$(post I /a2a/hub-comentado "$E")"

echo
echo "# fila (receptor gravado por registro):"
for f in "${SB}"/pending/*.json; do jq -r '"  \(.receiver)\tfrom=\(.from)\tauth=\(.auth.kind)\(if .auth.member then ":"+.auth.member else "" end)"' "$f"; done | sort | uniq -c
echo "# trust-log do sandbox (linhas gravadas pelo gate, inclusive de pedidos recusados):"
grep '^| 20' "${SB}/core/docs/evolution/trust-log.md" | awk -F'|' '{print "  "$3"->"$4" "$6}' | sort | uniq -c
echo "# FAILS=${FAILS}"
[ "${FAILS}" -eq 0 ]
