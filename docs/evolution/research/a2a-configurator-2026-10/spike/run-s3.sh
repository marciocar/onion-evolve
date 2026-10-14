#!/usr/bin/env bash
# run-s3.sh — bancada do teste S3 (SAC-128) do spike F0 do configurador A2A (SAC-121).
#
# Monta um sandbox efêmero (mktemp -d: par RS256 novo, members.yaml mínimo, jwks pinado, convite válido,
# servidor HTTP local em 127.0.0.1) e mede o a2a-doctor.sh em estados: o saudável e os quebrados.
# Critério por estado quebrado: rc ≠ 0 (o esperado exato) E a checagem NOMEADA sai ≠ ok com causa e
# próximo passo não-vazios. Sem rede externa, sem tocar nada fora do sandbox.
#
# USO
#   bash run-s3.sh                  # mede o doctor real
#   bash run-s3.sh --mutant perm    # gera um MUTANTE (checagem de permissão sempre ok) e prova que reprova
#   DOCTOR=<arquivo> bash run-s3.sh # mede outro doctor
# EXIT: 0 só se TODOS os estados baterem · 1 algum divergiu · 2 sandbox não montou (ferramenta ausente)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCTOR="${DOCTOR:-${HERE}/a2a-doctor.sh}"
for t in openssl jq python3 curl stat; do command -v "$t" >/dev/null 2>&1 || { echo "run-s3: '$t' ausente — sandbox não monta" >&2; exit 2; }; done
python3 -c 'import yaml' 2>/dev/null || { echo "run-s3: PyYAML ausente" >&2; exit 2; }

SB="$(mktemp -d)"; SRV=""
cleanup() { [ -n "${SRV}" ] && kill "${SRV}" 2>/dev/null; rm -rf "${SB}"; }
trap cleanup EXIT

if [ "${1:-}" = "--mutant" ]; then
  [ "${2:-}" = perm ] || { echo "run-s3: mutantes conhecidos: perm" >&2; exit 2; }
  M="${SB}/a2a-doctor.mutant.sh"
  # âncora: a linha que decide a falha de permissão. Se ela não casar, o mutante não nasceu — e isso é erro,
  # não sucesso (mutante que não muda nada "passa" e prova coisa nenhuma).
  sed 's/^    if \[ -n "\${bad}" \]; then$/    if false; then/' "${DOCTOR}" > "${M}"
  cmp -s "${DOCTOR}" "${M}" && { echo "run-s3: âncora do mutante não casou — mutante idêntico ao original" >&2; exit 2; }
  echo "── MUTANTE perm: (b) permissão sempre ok ──"
  # o mutante mora no sandbox, longe do repo: sem isto ele não acharia o gate e (h) sairia nao-medido em
  # TODOS os estados — o mutante "morreria" pelo motivo errado (medido na 1ª rodada deste spike).
  ROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../../../../.." && pwd))"
  out="$(A2A_VERIFY="${ROOT}/.claude/utils/federation-transport/a2a-verify.sh" DOCTOR="${M}" bash "${BASH_SOURCE[0]}")"; r=$?
  printf '%s\n' "${out}"
  # morte LIMPA: rc 1 E o único estado divergente é o que a mutação atinge
  bad="$(printf '%s\n' "${out}" | awk '$1=="✗"{print $2}' | tr '\n' ' ')"
  if [ "${r}" -eq 1 ] && [ "${bad}" = "priv_0644 " ]; then echo "✅ mutante MORTO limpo: só priv_0644 divergiu (rc 1)"; exit 0; fi
  echo "❌ mutante SOBREVIVEU ou morreu sujo (rc ${r}; divergentes: ${bad:-nenhum})"; exit 1
fi

MEMBER=acme-test; RECV=core-test; KID=acme-test-1
free_port() { python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()'; }

# ── baseline saudável ────────────────────────────────────────────────────────────────────────
base="${SB}/base"; mkdir -p "${base}/keys" "${base}/jwks" "${SB}/www"
chmod 0700 "${base}/keys"
( umask 077; openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "${base}/keys/private.pem" 2>/dev/null )
chmod 0600 "${base}/keys/private.pem"
printf '%s\n' "${KID}" > "${base}/keys/kid"
openssl pkey -in "${base}/keys/private.pem" -pubout -out "${base}/jwks/${KID}.pem" 2>/dev/null
cat > "${base}/members.yaml" <<YML
members:
  - id: ${RECV}
    role: source
    kind: source
    remote: example.invalid/core
  - id: ${MEMBER}
    role: standalone
    remote: example.invalid/acme
    a2a:
      sends_to: ${RECV}
      keys: [${KID}]
YML
printf '{"member":"%s","expires_at":"%s","revoked":false}\n' "${MEMBER}" "$(date -u -d '+1 day' +%FT%TZ)" > "${base}/invite.json"
[ -s "${base}/keys/private.pem" ] && [ -s "${base}/jwks/${KID}.pem" ] || { echo "run-s3: par RS256 não gerou" >&2; exit 2; }

PORT="$(free_port)"; echo ok > "${SB}/www/index.html"
python3 -m http.server "${PORT}" --bind 127.0.0.1 --directory "${SB}/www" >/dev/null 2>&1 & SRV=$!
for _ in $(seq 1 50); do curl -s -o /dev/null "http://127.0.0.1:${PORT}/" && break; sleep 0.1; done
CLOSED="$(free_port)"   # porta livre e SEM ninguém escutando
curl -s -o /dev/null --max-time 2 "http://127.0.0.1:${CLOSED}/" && { echo "run-s3: porta 'fechada' ${CLOSED} respondeu" >&2; exit 2; }

# PATH SEM sinal de relógio: espelha todo o PATH em links, MENOS timedatectl/chronyc/ntpstat
nocl="${SB}/bin-noclock"; mkdir -p "${nocl}"
IFS=: read -ra _dirs <<< "${PATH}"
for d in "${_dirs[@]}"; do [ -d "$d" ] || continue
  for f in "$d"/*; do n="${f##*/}"; case "$n" in timedatectl|chronyc|ntpstat) continue ;; esac
    [ -x "$f" ] && [ ! -e "${nocl}/$n" ] && ln -s "$f" "${nocl}/$n"; done; done
# PATH com relógio que DIZ "não sincronizado" (stub de timedatectl)
nosync="${SB}/bin-nosync"; mkdir -p "${nosync}"
printf '#!/bin/sh\necho no\n' > "${nosync}/timedatectl"; chmod +x "${nosync}/timedatectl"

# ── estados ──────────────────────────────────────────────────────────────────────────────────
# nome | rc esperado | checagem que tem de nomear o defeito | preparo (função) | modo de relógio
mk() { local s="${SB}/st-$1"; rm -rf "${s}"; cp -a "${base}" "${s}"; printf '%s' "${s}"; }
prep_saudavel()      { :; }
prep_sem_chave()     { rm -f "$1/keys/private.pem"; }
prep_priv_0644()     { chmod 0644 "$1/keys/private.pem"; }
prep_kid_fora()      { sed -i "s/keys: \[${KID}\]/keys: [outro-kid-1]/" "$1/members.yaml"; }
prep_convite_vencido() { printf '{"member":"%s","expires_at":"%s","revoked":false}\n' "${MEMBER}" "$(date -u -d '-1 hour' +%FT%TZ)" > "$1/invite.json"; }
prep_relogio()       { :; }
prep_relogio_nosync(){ :; }
prep_endpoint_fora() { :; }

STATES=(
  "saudavel|0|-|attested|live"
  "sem_chave|1|a|attested|live"
  "priv_0644|1|b|attested|live"
  "kid_fora|1|d|attested|live"
  "convite_vencido|1|e|attested|live"
  "relogio|2|f|noclock|live"
  "endpoint_fora|1|g|attested|closed"
  "relogio_nosync|1|f|nosync|live"
)
fail=0; rows=""
for spec in "${STATES[@]}"; do
  IFS='|' read -r name exp chk clock ep <<< "${spec}"
  s="$(mk "${name}")"; "prep_${name}" "${s}"
  url="http://127.0.0.1:${PORT}/"; [ "${ep}" = closed ] && url="http://127.0.0.1:${CLOSED}/"
  args=(--member "${MEMBER}" --dir "${s}/keys" --members "${s}/members.yaml" --jwks "${s}/jwks" --invite "${s}/invite.json" --endpoint "${url}" --json)
  case "${clock}" in
    attested) out="$(A2A_CLOCK_TRUST=attested bash "${DOCTOR}" "${args[@]}" 2>/dev/null)"; got=$? ;;
    noclock)  out="$(env -u A2A_CLOCK_TRUST PATH="${nocl}" bash "${DOCTOR}" "${args[@]}" 2>/dev/null)"; got=$? ;;
    nosync)   out="$(env -u A2A_CLOCK_TRUST PATH="${nosync}:${PATH}" bash "${DOCTOR}" "${args[@]}" 2>/dev/null)"; got=$? ;;
  esac
  ok=1
  [ "${got}" = "${exp}" ] || ok=0
  if [ "${chk}" = "-" ]; then
    diag="$(printf '%s' "${out}" | jq -r '[.checks[] | select(.status!="ok") | "\(.id)=\(.status)"] | if length==0 then "todas ok" else join(" ") end' 2>/dev/null)"
    [ "$(printf '%s' "${out}" | jq '[.checks[] | select(.status!="ok")] | length' 2>/dev/null)" = 0 ] || ok=0
  else
    line="$(printf '%s' "${out}" | jq -r --arg c "${chk}" '.checks[] | select(.id==$c) | "\(.status)\t\(.cause)\t\(.next)"' 2>/dev/null)"
    IFS=$'\t' read -r cs cc cn <<< "${line}"
    { [ -n "${cs}" ] && [ "${cs}" != ok ] && [ -n "${cc}" ] && [ -n "${cn}" ] && [ "${cn}" != "—" ]; } || ok=0
    others="$(printf '%s' "${out}" | jq -r --arg c "${chk}" '[.checks[] | select(.id!=$c and .status!="ok") | .id] | join(",")' 2>/dev/null)"
    diag="(${chk}) ${cs:-?}: ${cc:0:90}$([ ${#cc} -gt 90 ] && printf '…') → ${cn:0:60}$([ ${#cn} -gt 60 ] && printf '…')${others:+ [também ≠ok: ${others}]}"
  fi
  [ "${ok}" = 1 ] && mark="✓" || { mark="✗"; fail=1; }
  rows="${rows}${mark}|${name}|${exp}|${got}|${diag}
"
done

printf '%-2s %-16s %-4s %-4s %s\n' "" "estado" "esp" "obt" "diagnóstico"
while IFS='|' read -r m n e g d; do [ -n "${n}" ] && printf '%-2s %-16s %-4s %-4s %s\n' "${m}" "${n}" "${e}" "${g}" "${d}"; done <<< "${rows}"
echo
if [ "${fail}" = 0 ]; then echo "✅ S3: todos os estados bateram"; exit 0; fi
echo "❌ S3: algum estado divergiu"; exit 1
