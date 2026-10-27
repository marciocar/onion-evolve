#!/usr/bin/env bash
# =============================================================================
# fetch-replies.selftest.sh — teste OFFLINE do caminho de volta (A6a) com as flags do degrau B (Emenda 12.14).
#
# Sem rede, sem ssh, sem a chave real do core-spike: uma chave RSA DESCARTÁVEL (openssl, em diretório
# temporário) faz as vezes da do receptor, e A2A_SPIKE_CORE_PUB aponta o fetch para a pública dela. O outbox
# é um --local-dir com um ack e uma reply sintéticos, montados como o channel monta (channel/a2a-channel.ts,
# signedEnvelope): kid onion-evolve-spike-1, aud = o `from` da ida, exp, in_reply_to = jti da ida,
# body_sha256 = sha256 do corpo. Cada caso roda numa HOME própria (o seen.txt deduplica entre rodadas).
# Cobre:
#   · ok com --me maestro-peer-test e --sent-tsv do remetente (rc 0, [ok] ack e [ok] reply);
#   · sem --me o default (maestro-notebook-test) segue valendo e o envelope sai aud-errado (rc 1);
#   · A2A_SPIKE_ME faz o mesmo que --me;
#   · sem --sent-tsv o sent.tsv da HOME (que existe, com OUTRO jti) não tem o da ida → in_reply_to-desconhecido;
#   · sent.tsv de outro usuário com `a[$(cmd)]` na coluna 1 NÃO executa nada (rc 1, sem o arquivo-prova);
#   · flag de valor sem o valor sai rc 2 (uso), não rc 1;
#   · corpo adulterado depois de assinado sai corpo-adulterado (rc 1), e o corpo não é impresso;
#   · --until-jti (perna 1 da ida e volta VPS ↔ notebook, 2026-10-27): a pergunta NOVA sem in_reply_to sai [ok]
#     e o --watch para nela (rc 0); sem a flag, a mesma pergunta sai in_reply_to-desconhecido (rc 1);
#   · MUTANTES (o --me ignorado; o --sent-tsv ignorado; a validação numérica do t_send removida): cada um
#     tem de reprovar o seu caso. Mutate-and-restore NO PRÓPRIO arquivo, conferido por sha256 no fim.
# Uso : bash notebook/fetch-replies.selftest.sh      Exit: 0 tudo passou · 1 algum caso falhou
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FETCH="${HERE}/fetch-replies.sh"
for t in openssl jq; do command -v "$t" >/dev/null 2>&1 || { echo "ERRO: ferramenta ausente: $t" >&2; exit 1; }; done
T="$(mktemp -d)"
SHA0="$(openssl dgst -sha256 < "${FETCH}" | awk '{print $NF}')"
cp "${FETCH}" "${T}/fetch.orig"
# a restauração roda em QUALQUER saída: um Ctrl-C no meio do mutante não deixa o fetch mutado no repo
restore() { [ -f "${T}/fetch.orig" ] && cp "${T}/fetch.orig" "${FETCH}"; rm -rf "${T}"; }
trap restore EXIT

KEY="${T}/recv.key.pem"; export A2A_SPIKE_CORE_PUB="${T}/recv.pub.pem"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "${KEY}" 2>/dev/null
openssl pkey -in "${KEY}" -pubout -out "${A2A_SPIKE_CORE_PUB}" 2>/dev/null
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "  ✓ $1"; }
ko() { FAIL=$((FAIL+1)); echo "  ✗ $1"; }
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

MEMBER="maestro-peer-test"; JTI="nb-selftest0001"; THREAD="th-selftest-0001"
# envelope como o channel grava: mkenv <kind> <aud> <in_reply_to> <corpo> <jti da resposta>
mkenv() {
  local kind="$1" aud="$2" irt="$3" body="$4" rj="$5" now h p s bs
  now="$(date +%s)"; bs="$(printf '%s' "${body}" | openssl dgst -sha256 | awk '{print $NF}')"
  h="$(jq -cn '{alg:"RS256",kid:"onion-evolve-spike-1",typ:"JWT"}' | b64url)"
  p="$(jq -cn --arg aud "${aud}" --argjson iat "${now}" --argjson exp "$((now+600))" --arg jti "${rj}" --arg irt "${irt}" \
        --arg th "${THREAD}" --arg bs "${bs}" --arg kind "${kind}" \
        '{iss:"onion-evolve",aud:$aud,iat:$iat,exp:$exp,jti:$jti,in_reply_to:$irt,thread:$th,body_sha256:$bs,kind:$kind}' | b64url)"
  s="$(printf '%s' "${h}.${p}" | openssl dgst -sha256 -sign "${KEY}" | b64url)"
  jq -cn --arg jws "${h}.${p}.${s}" --arg to "${aud}" --arg kind "${kind}" --arg th "${THREAD}" --arg irt "${irt}" \
     --arg body "${body}" --arg bs "${bs}" \
     '{jws:$jws, signal:{from:"onion-evolve", to:$to, kind:$kind, thread:$th, in_reply_to:$irt, body:$body, body_sha256:$bs}}'
}
OUTBOX="${T}/outbox"; mkdir -p "${OUTBOX}"
mkenv ack   "${MEMBER}" "${JTI}" ""                    "cs-ack-0001"   > "${OUTBOX}/0001-ack.json"
mkenv reply "${MEMBER}" "${JTI}" $'são 42 grafos.\nfim' "cs-reply-0001" > "${OUTBOX}/0002-reply.json"
QBOX="${T}/outbox-question"; mkdir -p "${QBOX}"
mkenv question "${MEMBER}" "" "pergunta da perna 1" "vps-q-0001" > "${QBOX}/0003-question.json"
TAMPER="${T}/outbox-tamper"; mkdir -p "${TAMPER}"
jq -c '.signal.body = "são 43 grafos."' "${OUTBOX}/0002-reply.json" > "${TAMPER}/0002-reply.json"
# o sent.tsv do REMETENTE (o a2a-peer), fora da HOME de quem faz o fetch — formato do send-a2a.sh
SENT="${T}/a2a-peer-sent.tsv"; NOWMS="$(( $(date +%s) * 1000 ))"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$((NOWMS - 1500))" "$((NOWMS - 1400))" "${JTI}" "${THREAD}" 200 A7-C1 /dev/null > "${SENT}"

N=0; rc=0
run() {  # run <outbox> [flags do fetch]; deixa rc e a saída em ${T}/out; HOME nova a cada rodada
  local dir="$1"; shift; N=$((N+1)); mkdir -p "${T}/home${N}/.local/state/onion/a2a-spike"
  # a HOME de quem busca já tem um sent.tsv próprio, com OUTRO jti (o caso real do marciocar)
  printf '1\t2\tnb-outro-jti\tth-x\t200\tadhoc\t/dev/null\n' > "${T}/home${N}/.local/state/onion/a2a-spike/sent.tsv"
  rc=0; HOME="${T}/home${N}" bash "${FETCH}" --local-dir "${dir}" "$@" >"${T}/out" 2>&1 || rc=$?
}
expect() {  # expect <rc> <nome> <padrão>...
  local want="$1" name="$2" pat miss=""; shift 2
  for pat in "$@"; do grep -qF -- "${pat}" "${T}/out" || miss="${miss} '${pat}'"; done
  if [ "${rc}" = "${want}" ] && [ -z "${miss}" ]; then ok "${name} (rc ${rc})"
  else ko "${name}: rc ${rc} (esperado ${want})${miss:+, faltou${miss}}"; sed 's/^/      /' "${T}/out"; fi
}

echo "── fetch-replies: --me e --sent-tsv (degrau B)"
run "${OUTBOX}" --me "${MEMBER}" --sent-tsv "${SENT}"
expect 0 "ok com --me ${MEMBER} e --sent-tsv do remetente" "[ok] ack ← ${JTI}" "[ok] reply ← ${JTI}" "│ são 42 grafos."
awk -F'\t' -v j="${JTI}" '$3==j && $7=="ok" && $4 ~ /^[0-9]+$/' "${T}/home${N}/.local/state/onion/a2a-spike/recv.tsv" | grep -q . \
  && ok "recv.tsv registrou rtt numérico e veredito ok" || ko "recv.tsv sem a linha ok com rtt"
run "${OUTBOX}" --sent-tsv "${SENT}"
expect 1 "sem --me: default maestro-notebook-test intacto → aud-errado" "[aud-errado] ack" "[aud-errado] reply"
A2A_SPIKE_ME="${MEMBER}" run "${OUTBOX}" --sent-tsv "${SENT}"
expect 0 "A2A_SPIKE_ME=${MEMBER} equivale a --me" "[ok] ack" "[ok] reply"
run "${OUTBOX}" --me "${MEMBER}"
expect 1 "sem --sent-tsv: o sent.tsv da HOME de quem busca tem outro jti → in_reply_to-desconhecido" \
  "[in_reply_to-desconhecido] ack" "[in_reply_to-desconhecido] reply"
run "${OUTBOX}" --me "${MEMBER}" --sent-tsv "${T}/inexistente.tsv"
expect 1 "--sent-tsv ilegível avisa e reprova (não é erro de uso)" "aviso: sent.tsv ilegível" "[in_reply_to-desconhecido] reply"
EVIL="${T}/evil-sent.tsv"; PWNED="${T}/PWNED"
# `t_recv[...]` e não `a[...]`: sob set -u um nome NÃO definido morre antes do índice; um definido executa o índice
# (medido em bash 5.2.21: o `a[$(touch)]` só deu unbound variable, o `t_recv[$(touch)]` criou o arquivo)
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "t_recv[\$(touch ${PWNED})]" 0 "${JTI}" "${THREAD}" 200 A7-C1 /dev/null > "${EVIL}"
run "${OUTBOX}" --me "${MEMBER}" --sent-tsv "${EVIL}"
if [ "${rc}" = 1 ] && [ ! -e "${PWNED}" ] && grep -qF "[in_reply_to-desconhecido] reply" "${T}/out"; then
  ok "sent.tsv com a[\$(cmd)] na coluna 1: nada executa, vira in_reply_to-desconhecido (rc 1)"
else ko "injeção pelo sent.tsv: rc ${rc}, PWNED $([ -e "${PWNED}" ] && echo CRIADO || echo ausente)"; sed 's/^/      /' "${T}/out"; fi
run "${TAMPER}" --me "${MEMBER}" --sent-tsv "${SENT}"
expect 1 "corpo adulterado depois de assinado → corpo-adulterado" "[corpo-adulterado] reply"
if grep -q "são 43" "${T}/out"; then ko "o corpo adulterado foi impresso"; else ok "o corpo adulterado não é impresso"; fi
run "${OUTBOX}" --me ""
expect 2 "--me vazio é erro de uso" "--me vazio"
run "${OUTBOX}" --sent-tsv
expect 2 "--sent-tsv sem valor é erro de uso, não unbound variable" "falta o valor de --sent-tsv"

echo "── fetch-replies: --until-jti (perna 1 da ida e volta)"
run "${QBOX}" --me "${MEMBER}" --sent-tsv "${SENT}" --watch --until-jti vps-q-0001 --timeout 5
expect 0 "--until-jti: pergunta nova sem in_reply_to sai [ok] e o --watch para nela" "[ok] question ←" "│ pergunta da perna 1"
run "${QBOX}" --me "${MEMBER}" --sent-tsv "${SENT}"
expect 1 "sem --until-jti a mesma pergunta segue in_reply_to-desconhecido" "[in_reply_to-desconhecido] question"
run "${QBOX}" --me "${MEMBER}" --until-jti 'x;y'
expect 2 "--until-jti fora da forma é erro de uso" "--until-jti fora da forma"

echo "── mutantes (mutate-and-restore no próprio arquivo, conferido por sha256 no fim)"
mutant() {  # mutant <nome> <expressão sed> <marca> ; deixa o fetch mutado (o próximo restore desfaz)
  cp "${T}/fetch.orig" "${FETCH}"; sed -i "$2" "${FETCH}"
  grep -q "$3" "${FETCH}" || { ko "mutante «$1» não se aplicou: a âncora mudou"; return 1; }
}
if mutant "--me ignorado" 's/^  --me) ME="\$2"; shift 2 ;;$/  --me) shift 2 ;;  # MUTANTE: --me ignorado/' 'MUTANTE: --me ignorado'; then
  run "${OUTBOX}" --me "${MEMBER}" --sent-tsv "${SENT}"
  if [ "${rc}" = 1 ] && grep -qF "[aud-errado] reply" "${T}/out"; then ok "mutante «--me ignorado» reprovou o caso ok (rc 1, aud-errado)"
  else ko "mutante «--me ignorado» passou (rc ${rc}): o caso ok não prova o --me"; fi
fi
if mutant "--sent-tsv ignorado" 's/^  --sent-tsv) SENT_TSV="\$2"; shift 2 ;;$/  --sent-tsv) shift 2 ;;  # MUTANTE: --sent-tsv ignorado/' 'MUTANTE: --sent-tsv ignorado'; then
  run "${OUTBOX}" --me "${MEMBER}" --sent-tsv "${SENT}"
  if [ "${rc}" = 1 ] && grep -qF "[in_reply_to-desconhecido] reply" "${T}/out"; then ok "mutante «--sent-tsv ignorado» reprovou o caso ok (rc 1, in_reply_to-desconhecido)"
  else ko "mutante «--sent-tsv ignorado» passou (rc ${rc}): o caso ok não prova o --sent-tsv"; fi
fi
if mutant "t_send sem validação" 's/^  case "\${t_send}" in \*\[!0-9\]\*) t_send="" ;; esac$/  : # MUTANTE: t_send cru/' 'MUTANTE: t_send cru'; then
  rm -f "${PWNED}"; run "${OUTBOX}" --me "${MEMBER}" --sent-tsv "${EVIL}"
  if [ -e "${PWNED}" ]; then ok "mutante «t_send sem validação» EXECUTOU o a[\$(cmd)]: o caso da injeção morde"
  else ko "mutante «t_send sem validação» não executou: o caso da injeção não prova nada"; fi
fi
if mutant "--until-jti não para" 's/^  \[ -n "\${UNTIL_JTI}" \] && \[ "\${rj}" = "\${UNTIL_JTI}" \] && \[ "\${verdict}" = ok \] && GOT_UNTIL=1$/  : # MUTANTE: until-jti não para/' 'MUTANTE: until-jti não para'; then
  run "${QBOX}" --me "${MEMBER}" --sent-tsv "${SENT}" --watch --until-jti vps-q-0001 --timeout 2
  if [ "${rc}" = 3 ]; then ok "mutante «--until-jti não para» saiu por timeout (rc 3): o caso da perna 1 morde"
  else ko "mutante «--until-jti não para» passou (rc ${rc})"; fi
fi
cp "${T}/fetch.orig" "${FETCH}"
SHA1="$(openssl dgst -sha256 < "${FETCH}" | awk '{print $NF}')"
if [ "${SHA0}" = "${SHA1}" ]; then ok "fetch-replies.sh restaurado (sha256 ${SHA0:0:12}… antes = depois)"
else ko "fetch-replies.sh NÃO voltou ao original (${SHA0} ≠ ${SHA1})"; fi

echo "── ${PASS} passaram, ${FAIL} falharam"
[ "${FAIL}" = 0 ]
