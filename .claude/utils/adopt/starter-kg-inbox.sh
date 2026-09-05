#!/usr/bin/env bash
# =============================================================================
# starter-kg-inbox.sh — cria a fila de PROPOSTAS ao grafo no alvo da adoção
#
# POR QUÊ : desde 2026-09-05 o /meta:kg-inbox ROTEIA por papel — num repo adotado ele sela a fila
#           LOCAL do próprio repo (a I3 é fronteira de REPO, não de papel). Sem a fila nascer na
#           adoção, o comando roteado não tem onde operar no dia 1. Sinal de campo do
#           portal-gamificacao (2026-09-04): o adotante teve de criar a fila E um comando local de
#           selagem à mão porque o core recusava rodar em `role: adopted`.
#
# COMO    : idempotente por desenho — só cria o que estiver AUSENTE; NUNCA clobba fila em uso
#           (o README do adotante pode ter sido editado, e reescrevê-lo apagaria o trabalho dele).
#
# USO     : starter-kg-inbox.sh <DEST>
# =============================================================================
set -u
DEST="${1:?uso: starter-kg-inbox.sh <DEST>}"
Q="${DEST}/docs/evolution/kg-inbox"
mkdir -p "${Q}/_sealed" "${Q}/_rejected"
[ -f "${Q}/_sealed/.gitkeep" ]   || : > "${Q}/_sealed/.gitkeep"
[ -f "${Q}/_rejected/.gitkeep" ] || : > "${Q}/_rejected/.gitkeep"
[ -f "${Q}/README.md" ] && exit 0
cat > "${Q}/README.md" <<'PTR'
# Fila de propostas ao grafo (kg-inbox)

Quem NÃO é dono do grafo **propõe** aqui (`<slug>.proposal.kg.yaml` com `meta.target` apontando o grafo
deste repo); o **dono sela** com `/meta:kg-inbox` — que roteia por papel e, num repo adotado, sela esta
fila local. Aceita vai por `append` no grafo-alvo e a proposta migra para `_sealed/`; recusada vai para
`_rejected/` com o motivo num arquivo irmão. O gate de selagem é `kg-radar` exit 0 no ALVO.

Proposta cujo `meta.target` aponta para fora deste repo não é selada aqui (um escritor por repo).
PTR
