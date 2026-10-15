#!/usr/bin/env bash
# =============================================================================
# a2a-accept.sh — o ATO HUMANO que fecha o gate do a2a-live: promove um sinal VERIFICADO-mas-gated
# (registro da fila `data/a2a-pending/` do bridge) para o inbox de co-evolução, onde entra na triagem normal.
#
# F2.2 (RFC-0004): o endpoint só ENFILEIRA (input_required); nada é aplicado. Este helper é a "aceitação" —
# roda na sessão do maestro (core), materializa o sinal como doc de inbox e deixa o resto ser o fluxo
# git-async de sempre (/meta:co-evolve → git mv p/ _processed). NUNCA aplica nada; só transporta fila→inbox.
#
# Fail-safe: recusa registro cujo verdict.verified != true (a fila só deveria ter verificados, mas defesa em
# profundidade — ausência/erro nunca vira aceitação). Idempotente: não sobrescreve doc de inbox existente.
#
# RECEPTOR (F3 do configurador A2A, 2026-10-15): o bridge do core serve também os hubs (/a2a/<hub>), e cada
# registro da fila diz para quem era (`receiver`, gravado pelo bridge, e `verdict.receiver`, ecoado pelo gate).
# Este aceite só materializa registro do SEU receptor: --receiver <id>, default o membro kind: source do
# registro deste repo (o core). Registro de outro receptor é RECUSADO; registro antigo, sem os dois campos,
# só é aceito no core (antes da F3 todo registro era dele). No hub não há registro do core: passe --receiver.
#
# Uso : a2a-accept.sh <pending-record.json> [--inbox <dir>] [--receiver <id>]
# Exit: 0 = aceito (ou já existia) · 1 = recusado (não-verificado/malformado) · 2 = uso incorreto
# Exercitado por lint-selftest.sh (run_a2a_accept_selftests).
# =============================================================================
set -uo pipefail

REC=""; INBOX=""; RECEIVER=""
while [ "$#" -gt 0 ]; do case "$1" in
  --inbox) INBOX="${2:-}"; shift 2 ;;
  --receiver) RECEIVER="${2:-}"; [ -n "${RECEIVER}" ] || { echo "uso: --receiver exige valor" >&2; exit 2; }; shift 2 ;;
  -*) echo "uso: a2a-accept.sh <pending-record.json> [--inbox <dir>] [--receiver <id>]" >&2; exit 2 ;;
  *) [ -z "${REC}" ] && REC="$1"; shift ;;
esac; done
[ -n "${REC}" ] || { echo "uso: a2a-accept.sh <pending-record.json> [--inbox <dir>]" >&2; exit 2; }
[ -f "${REC}" ] || { echo "ERRO: registro inexistente: ${REC}" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "ERRO: jq ausente (necessário p/ parsear o registro)." >&2; exit 1; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../../.." && pwd))"
[ -n "${INBOX}" ] || INBOX="${ROOT}/docs/evolution/inbox"

# O receptor deste aceite: --receiver, ou a fonte do registro deste repo. Sem nenhum dos dois, não sei de
# quem é a fila, e aceitar sem saber seria aceitar a fila de qualquer um.
SRC_ID=""
MEMBERS="${ROOT}/docs/evolution/federation/members.yaml"
if [ -f "${MEMBERS}" ] && command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
  SRC_ID="$(python3 -c 'import sys,yaml
try: ms=(yaml.safe_load(open(sys.argv[1])) or {}).get("members") or []
except Exception: ms=[]
print(next((m.get("id") for m in ms if isinstance(m,dict) and m.get("kind")=="source" and isinstance(m.get("id"),str)), ""))' "${MEMBERS}" 2>/dev/null)"
fi
[ -n "${RECEIVER}" ] || RECEIVER="${SRC_ID}"
[ -n "${RECEIVER}" ] || { echo "ERRO: não sei o receptor desta fila (sem --receiver e sem registro com a fonte): passe --receiver <seu id>." >&2; exit 2; }
case "${RECEIVER}" in [!A-Za-z0-9]*|*[!A-Za-z0-9._-]*) echo "ERRO: --receiver fora de [A-Za-z0-9._-] (1º caractere letra ou dígito)." >&2; exit 2 ;; esac

jq -e . "${REC}" >/dev/null 2>&1 || { echo "ERRO: registro não é JSON válido." >&2; exit 1; }
VERIFIED="$(jq -r '.verdict.verified // false' "${REC}")"
[ "${VERIFIED}" = "true" ] || { echo "RECUSADO: registro não-verificado (verdict.verified != true) — não aceito." >&2; exit 1; }

# de quem é o registro: o campo do bridge e o eco do gate, quando existem, têm de ser este receptor
REC_RCV="$(jq -r 'if (.receiver|type)=="string" then .receiver elif has("receiver") then "<inválido>" else "" end' "${REC}")"
VER_RCV="$(jq -r 'if (.verdict.receiver|type)=="string" then .verdict.receiver elif (.verdict|type)=="object" and (.verdict|has("receiver")) then "<inválido>" else "" end' "${REC}")"
for got in "${REC_RCV}" "${VER_RCV}"; do
  if [ -n "${got}" ] && [ "${got}" != "${RECEIVER}" ]; then
    echo "RECUSADO: o registro é do receptor '${got}', e este aceite é de '${RECEIVER}' — não aceito a fila de outro receptor." >&2; exit 1
  fi
done
if [ -z "${REC_RCV}" ] && [ -z "${VER_RCV}" ] && [ "${RECEIVER}" != "${SRC_ID}" ]; then
  echo "RECUSADO: registro sem receptor (anterior à F3, quando toda a fila era do core) num aceite de '${RECEIVER}', que não é a fonte deste registro." >&2; exit 1
fi

FROM="$(jq -r '.from // .signal.from // "desconhecido"' "${REC}")"
SIGID="$(jq -r '.signal.id // .taskId // "sinal"' "${REC}")"
KIND="$(jq -r '.signal.kind // "signal"' "${REC}")"
BODY="$(jq -r '.signal.body_path // ""' "${REC}")"
TASKID="$(jq -r '.taskId // ""' "${REC}")"
RECVAT="$(jq -r '.receivedAt // ""' "${REC}")"
REGULATED="$(jq -r '.verdict.regulated // false' "${REC}")"
APPLY="$(jq -r '.verdict.apply_mode // "gated"' "${REC}")"
DATE="${RECVAT:0:10}"; [ -n "${DATE}" ] || DATE="$(date +%F)"

# nome de arquivo seguro (o signal.id costuma já vir datado)
SAFE="$(printf '%s' "${SIGID}" | tr -c 'A-Za-z0-9._-' '_' | sed 's/^_*//;s/_*$//')"
case "${SAFE}" in *[0-9][0-9][0-9][0-9]-[0-9][0-9]-*) OUT="${INBOX}/${SAFE}.md" ;; *) OUT="${INBOX}/${DATE}-a2a-${SAFE}.md" ;; esac

if [ -f "${OUT}" ]; then echo "já aceito (não sobrescreve): ${OUT}" >&2; exit 0; fi
mkdir -p "${INBOX}"

if [ -n "${BODY}" ]; then
  BODY_LINE="**Conteúdo referenciado:** \`${BODY}\` — ler/relayar no repo do remetente (o a2a-live transporta o SINAL, não o corpo)."
else
  BODY_LINE="**Sem corpo** (handshake/ping) — nada a acionar além do registro de que o canal vivo funcionou."
fi

cat > "${OUT}" <<EOF
---
tipo: sinal-upstream
data: ${DATE}
origem: ${FROM} (via a2a-live)
assunto: sinal ${KIND} via a2a-live — ${SIGID}
transporte: a2a-live (verificado — trust + jti + timestamp + JWS + kid-binding)
verificacao:
  verified: true
  regulated: ${REGULATED}
  apply_mode: ${APPLY}
  taskId: ${TASKID}
  recebido_em: ${RECVAT}
para: ${RECEIVER} — triagem normal (/meta:co-evolve)
---

# Sinal a2a-live de ${FROM} — ${SIGID}

Recebido pelo endpoint **a2a-live** (F2.2), verificado pelo \`a2a-verify\` (assinatura RS256 + kid∈keys[from]
+ anti-replay + janela + anti-SSRF) e **aceito pelo maestro** (fila gated \`data/a2a-pending\` → inbox). Nada
foi auto-aplicado — segue o fluxo git-async normal de triagem.

${BODY_LINE}

> Envelope JWS preservado no registro da fila do bridge (auditoria): taskId \`${TASKID}\`.
EOF

echo "aceito → ${OUT}"
echo "  (próximo: /meta:co-evolve p/ triar; e limpar o registro da fila do bridge — ato humano via '!')" >&2
