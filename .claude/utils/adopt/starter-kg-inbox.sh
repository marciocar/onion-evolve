#!/usr/bin/env bash
# =============================================================================
# starter-kg-inbox.sh — cria a fila de PROPOSTAS ao grafo no alvo da adoção
#
# POR QUÊ : desde 2026-09-05 o /meta:kg-inbox ROTEIA por papel — num repo adotado ele sela a fila
#           LOCAL do próprio repo (a I3 é fronteira de REPO, não de papel). Sem a fila nascer na
#           adoção, o comando roteado não tem onde operar no dia 1. Sinal de campo do
#           um adotante (2026-09-04): o adotante teve de criar a fila E um comando local de
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
_verifica() {   # o script CONFERE o que produziu; `exit 0` seria só declaração sobre si mesmo
  [ -f "${Q}/README.md" ] && [ -d "${Q}/_sealed" ] && [ -d "${Q}/_rejected" ] && exit 0
  echo "starter-kg-inbox: a fila não ficou completa em ${Q} (README/_sealed/_rejected)" >&2; exit 1
}
[ -f "${Q}/README.md" ] && _verifica
cat > "${Q}/README.md" <<'PTR'
# Fila de propostas ao grafo (kg-inbox)

Quem NÃO é dono do grafo **propõe** aqui (`<slug>.proposal.kg.yaml`; se souber o grafo de destino,
declare-o em `meta.target`); o **dono sela** com `/meta:kg-inbox` — que roteia por papel e, num repo
adotado, sela esta fila local. Aceita vai por `append` no grafo-alvo e a proposta migra para `_sealed/`;
recusada vai para `_rejected/` com o motivo num arquivo irmão. O gate de selagem é `kg-radar` exit 0 no
ALVO.

**O grafo-alvo tem de ser um grafo DESTE repo** (`git ls-files '*.kg.yaml'`) — um escritor por repo.
Conhecimento que mora noutro repo não se sela aqui: é rejeitado com o motivo, e o gap vira nó `open`.

**Uma proposta é FRAGMENTO, não grafo fechado.** Por isso o radar entra em MODO PROPOSTA quando o
arquivo declara `meta.target` ou termina em `.proposal.kg.yaml`: ele deixa de exigir grau ≥ 1 e de
resolver aresta para fora do arquivo — e **conta** o que relaxou. Todo o resto (id duplicado,
`node_type`, `plane`, `status`, `impact`, `confidence`, `edge_type`) continua reprovando. Sem isso a
proposta de UM nó que este README manda escrever nunca passaria: reprovava com `nó órfão (grau 0)`.
O relaxamento acaba na SELAGEM, onde o grafo volta a ser fechado.

```yaml
meta:
  schema_version: "1"
  target: docs/onion/graph/<o-grafo-vivo>.kg.yaml
nodes:
  - id: P_O_QUE_EU_PROPONHO
    node_type: claim
    plane: DEV
    status: open
    impact: 3
    confidence: 0.8
    label: "A afirmação proposta, em uma frase que se possa refutar."
edges: []
```
PTR
_verifica
