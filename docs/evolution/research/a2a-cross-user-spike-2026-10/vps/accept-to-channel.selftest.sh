#!/usr/bin/env bash
# =============================================================================
# accept-to-channel.selftest.sh — teste OFFLINE da Emenda 7 (2026-10-14) no accept-to-channel.sh.
#
# Sem rede, sem bridge, sem sudo: HOME, estado, jwks e members.yaml vão para um diretório temporário, e
# o envelope sai do próprio notebook/send-a2a.sh --dry-run com uma chave descartável. Cobre:
#   · o envelope normal passa (--no-push), e a linha TRUST registra o sha do members.yaml e do .pem usados;
#   · iat no futuro além do skew, vida (exp − iat) acima do teto e exp ≤ iat são RECUSADOS;
#   · sem iat é RECUSADO; corpo adulterado continua RECUSADO (a cura de F1 do receptor não regrediu);
#   · o default da raiz de confiança é o clone SERVIDO (/home/onion/onion-evolve), não o checkout;
#   · um MUTANTE sem a checagem de vida tem de deixar passar o envelope longo (prova que o caso morde).
# Uso : bash vps/accept-to-channel.selftest.sh      Exit: 0 tudo passou · 1 algum caso falhou
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPK="$(cd "${HERE}/.." && pwd)"
ATC="${SPK}/vps/accept-to-channel.sh"; SEND="${SPK}/notebook/send-a2a.sh"
T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
export HOME="${T}/home"; mkdir -p "${HOME}"
export A2A_SPIKE_STATE="${T}/state" A2A_SPIKE_JWKS="${T}/jwks" A2A_SPIKE_MEMBERS="${T}/members.yaml"
mkdir -p "${A2A_SPIKE_JWKS}"
KEY="${T}/k.pem"; KID="selftest-1"; FROM="selftest-member"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "${KEY}" 2>/dev/null
openssl pkey -in "${KEY}" -pubout -out "${A2A_SPIKE_JWKS}/${KID}.pem" 2>/dev/null
printf 'members:\n  - id: %s\n    a2a:\n      keys: [%s]\n' "${FROM}" "${KID}" > "${A2A_SPIKE_MEMBERS}"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "  ✓ $1"; }
ko() { FAIL=$((FAIL+1)); echo "  ✗ $1"; }

mkrec() {  # mkrec <saída> [opções do send-a2a.sh]
  local out="$1"; shift
  bash "${SEND}" --dry-run --key "${KEY}" --kid "${KID}" --from "${FROM}" --body "quantos grafos?" "$@" 2>/dev/null \
    | jq --arg from "${FROM}" '{verdict:{verified:true}, from:$from, taskId:"t-1", envelope:.}' > "${out}"
}
case_rc() {  # case_rc <rc esperado> <nome> <registro> [grep da saída]
  local want="$1" name="$2" rec="$3" pat="${4:-}"
  bash "${ATC}" "${rec}" --no-push >"${T}/out" 2>&1; local rc=$?
  if [ "${rc}" = "${want}" ] && { [ -z "${pat}" ] || grep -q -- "${pat}" "${T}/out"; }; then ok "${name} (rc ${rc})"
  else ko "${name}: rc ${rc} (esperado ${want}${pat:+, saída com '${pat}'})"; sed 's/^/      /' "${T}/out"; fi
}

echo "── accept-to-channel: relógio e raiz de confiança"
mkrec "${T}/ok.json"
case_rc 0 "envelope normal (exp +300) passa" "${T}/ok.json" "aceito e entregue"
grep -q "	TRUST	${A2A_SPIKE_MEMBERS}	$(openssl dgst -sha256 < "${A2A_SPIKE_MEMBERS}" | awk '{print $NF}')	" "${A2A_SPIKE_STATE}/accept.tsv" \
  && ok "linha TRUST com o sha256 do members.yaml usado" || ko "linha TRUST ausente ou errada"
mkrec "${T}/fut.json" --iat-offset 3600 --exp-offset 3700
case_rc 1 "iat no futuro (+3600) recusado" "${T}/fut.json" "iat no futuro"
mkrec "${T}/long.json" --exp-offset 3600
case_rc 1 "vida exp − iat = 3600 s > 900 s recusada" "${T}/long.json" "vida longa demais"
mkrec "${T}/inv.json" --iat-offset 30 --exp-offset 20
case_rc 1 "exp ≤ iat recusado" "${T}/inv.json" "exp ≤ iat"
mkrec "${T}/noiat.json"
H="$(jq -r .envelope.jws "${T}/noiat.json" | cut -d. -f1)"
PL="$(jq -cn --arg iss "${FROM}" --argjson exp "$(( $(date +%s) + 300 ))" --arg bs "$(printf '%s' 'quantos grafos?' | openssl dgst -sha256 | awk '{print $NF}')" \
  --arg th "$(jq -r .envelope.signal.thread "${T}/noiat.json")" '{iss:$iss,aud:"onion-evolve",exp:$exp,jti:"nb-noiat",body_sha256:$bs,thread:$th}' \
  | openssl base64 -A | tr '+/' '-_' | tr -d '=')"
SIG="$(printf '%s' "${H}.${PL}" | openssl dgst -sha256 -sign "${KEY}" | openssl base64 -A | tr '+/' '-_' | tr -d '=')"
jq --arg jws "${H}.${PL}.${SIG}" '.envelope.jws = $jws' "${T}/noiat.json" > "${T}/noiat2.json"
case_rc 1 "JWS sem iat recusado" "${T}/noiat2.json" "sem iat"
# octal (passada adversarial 2026-10-14): exp como STRING com zero à esquerda — decimal no [ ], octal no $(( ))
PLO="$(jq -cn --arg iss "${FROM}" --argjson iat "$(date +%s)" --arg bs "$(printf '%s' 'quantos grafos?' | openssl dgst -sha256 | awk '{print $NF}')" \
  --arg th "$(jq -r .envelope.signal.thread "${T}/noiat.json")" '{iss:$iss,aud:"onion-evolve",iat:$iat,exp:"013000000000",jti:"nb-octal",body_sha256:$bs,thread:$th}' \
  | openssl base64 -A | tr '+/' '-_' | tr -d '=')"
SIGO="$(printf '%s' "${H}.${PLO}" | openssl dgst -sha256 -sign "${KEY}" | openssl base64 -A | tr '+/' '-_' | tr -d '=')"
jq --arg jws "${H}.${PLO}.${SIGO}" '.envelope.jws = $jws' "${T}/noiat.json" > "${T}/octal.json"
case_rc 1 "exp string \"013000000000\" (octal no \$(( ))) recusado" "${T}/octal.json" "não são inteiros JSON"
mkrec "${T}/tamper.json"; jq '.envelope.signal.body = "outro corpo"' "${T}/tamper.json" > "${T}/tamper2.json"
case_rc 1 "corpo adulterado segue recusado (F1 no receptor)" "${T}/tamper2.json" "corpo adulterado"
A2A_SPIKE_MAX_LIFE=4000 bash "${ATC}" "${T}/long.json" --no-push >/dev/null 2>&1 \
  && ok "o teto de vida é o do env (A2A_SPIKE_MAX_LIFE=4000 aceita os 3600 s)" || ko "A2A_SPIKE_MAX_LIFE não respeitado"

echo "── default da raiz de confiança"
( unset A2A_SPIKE_JWKS A2A_SPIKE_MEMBERS; A2A_SPIKE_SERVED_ROOT="${T}/served-inexistente" bash "${ATC}" "${T}/ok.json" --no-push ) >"${T}/out" 2>&1
grep -q "${T}/served-inexistente/.claude/utils/federation-transport/jwks" "${T}/out" \
  && ok "sem override, a confiança vem de A2A_SPIKE_SERVED_ROOT (e recusa se ilegível)" || { ko "default da raiz não é o clone servido"; cat "${T}/out"; }
grep -q 'SERVED="${A2A_SPIKE_SERVED_ROOT:-/home/onion/onion-evolve}"' "${ATC}" \
  && ok "o default literal é o clone servido pelo bridge" || ko "default literal mudou"

echo "── mutante (sem a checagem de vida): tem de deixar passar o envelope longo"
MUT="${T}/atc-mutant.sh"; sed '/vida longa demais/d' "${ATC}" > "${MUT}"
cp "${MUT}" "${SPK}/vps/.atc-mutant.$$.sh"   # o ROOT do ATC é relativo ao arquivo: o mutante roda ao lado
mkrec "${T}/long2.json" --exp-offset 3600
bash "${SPK}/vps/.atc-mutant.$$.sh" "${T}/long2.json" --no-push >/dev/null 2>&1; rc=$?
rm -f "${SPK}/vps/.atc-mutant.$$.sh"
[ "${rc}" = 0 ] && ok "mutante deixou passar: o caso de vida longa morde a checagem real" || ko "mutante não passou (rc ${rc}): o caso não prova nada"

echo "── ${PASS} passaram, ${FAIL} falharam"
[ "${FAIL}" = 0 ]
