#!/usr/bin/env bash
# kg-radar.sh — radar determinístico do Knowledge Graph SDAAL (motor soberano do core).
#
# Uso: bash .claude/validation/kg-radar.sh <arquivo.kg.yaml> [--radar|--reconcile|--integrity]
#      (sem flag = as três saídas)
#
# Doutrina: docs/knowledge-base/concepts/knowledge-graph-sdaal.md
#   RADAR         = atenção — peso do nó × centralidade (grau).
#                   peso = impact(1-5) × confidence(0-1) × fator de status
#                   fator: open=1.0 · confirmed=1.0 · refuted=0 · superseded=0.2 · done=0.1
#   RECONCILIAÇÃO = arestas REFUTES/SUPERSEDES (as auto-correções explícitas do grafo)
#   INTEGRIDADE   = ids duplicados · aresta para nó inexistente · nó órfão (grau 0) ·
#                   contradição (REFUTES entrando em nó que segue confirmed/open) ·
#                   enum inválido (node_type/edge_type/plane/status)
#
# Soberania: motor próprio do core (decisão D_NO_VENDOR_RADAR) — NÃO é port do radar.js do rhilo.
# Shell/awk puro por design (economia de motores: gate determinístico não aluga LLM).
# Exit: 0 = ok · 1 = INTEGRIDADE encontrou problema · 2 = erro de uso/arquivo.
set -euo pipefail

FILE="${1:-}"
MODE="${2:---all}"
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "uso: kg-radar.sh <arquivo.kg.yaml> [--radar|--reconcile|--integrity]" >&2; exit 2; }

awk -v mode="$MODE" '
function statusFactor(s) {
  if (s == "open" || s == "confirmed") return 1.0
  if (s == "refuted") return 0.0
  if (s == "superseded") return 0.2
  if (s == "done") return 0.1
  return -1  # inválido
}
function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); gsub(/^"|"$/, "", s); return s }

BEGIN { section = ""; nid = ""; ne = 0 }

# comentários e vazio fora de valores
/^[[:space:]]*#/ { next }

/^nodes:/ { section = "nodes"; next }
/^edges:/ { section = "edges"; nid = ""; next }
/^meta:/  { section = "meta"; next }

section == "nodes" && /^[[:space:]]+- id:/ {
  nid = trim($0); sub(/^- id:/, "", nid); nid = trim(nid)
  if (nid in nodeSeen) dup[nid] = 1
  nodeSeen[nid] = 1
  order[++nn] = nid
  next
}
section == "nodes" && nid != "" {
  line = $0; sub(/#.*$/, "", line)
  if (line ~ /node_type:/)  { v = line; sub(/.*node_type:/, "", v);  ntype[nid] = trim(v) }
  if (line ~ /plane:/)      { v = line; sub(/.*plane:/, "", v);      plane[nid] = trim(v) }
  if (line ~ /impact:/)     { v = line; sub(/.*impact:/, "", v);     impact[nid] = trim(v) + 0 }
  if (line ~ /confidence:/) { v = line; sub(/.*confidence:/, "", v); conf[nid] = trim(v) + 0 }
  if (line ~ /status:/)     { v = line; sub(/.*status:/, "", v);     nstatus[nid] = trim(v) }
  if ($0 ~ /label:/)        { v = $0; sub(/^[[:space:]]*label:/, "", v); label[nid] = trim(v) }
  next
}

section == "edges" && /^[[:space:]]+- from:/ {
  ne++
  v = trim($0); sub(/^- from:/, "", v); efrom[ne] = trim(v)
  next
}
section == "edges" && /to:/ && !/edge_type/ { v = $0; sub(/.*to:/, "", v); eto[ne] = trim(v); next }
section == "edges" && /edge_type:/ { v = $0; sub(/.*edge_type:/, "", v); etype[ne] = trim(v); next }

END {
  VN = "entity claim decision question evidence artifact"
  VE = "SUPPORTS REFUTES SUPERSEDES CAUSES DEPENDS_ON TRACES_TO"
  VP = "DEV PROD"
  problems = 0

  # grau (centralidade MVP) + contradições
  for (i = 1; i <= ne; i++) {
    deg[efrom[i]]++; deg[eto[i]]++
    if (etype[i] == "REFUTES") refutedBy[eto[i]]++
  }

  if (mode == "--all" || mode == "--radar") {
    print "══ RADAR — atenção (peso × centralidade) ══"
    for (i = 1; i <= nn; i++) {
      id = order[i]; sf = statusFactor(nstatus[id]); if (sf < 0) sf = 0
      att[id] = impact[id] * conf[id] * sf * (1 + deg[id])
    }
    n = asorti(att, sorted, "@val_num_desc")
    top = (n < 10) ? n : 10
    for (i = 1; i <= top; i++) {
      id = sorted[i]
      if (att[id] <= 0) break
      printf "  %5.1f  %-18s %s(%s/%s)  %s\n", att[id], id, ntype[id], plane[id], nstatus[id], label[id]
    }
    print ""
  }

  if (mode == "--all" || mode == "--reconcile") {
    print "══ RECONCILIAÇÃO — REFUTES / SUPERSEDES ══"
    found = 0
    for (i = 1; i <= ne; i++)
      if (etype[i] == "REFUTES" || etype[i] == "SUPERSEDES") {
        found++
        printf "  %-10s %s → %s\n", etype[i], efrom[i], eto[i]
        printf "             ∟ alvo: %s\n", label[eto[i]]
      }
    if (!found) print "  (nenhuma — grafo sem auto-correções registradas)"
    print ""
  }

  if (mode == "--all" || mode == "--integrity") {
    print "══ INTEGRIDADE ══"
    for (id in dup) { print "  ✗ id duplicado: " id; problems++ }
    for (i = 1; i <= ne; i++) {
      if (!(efrom[i] in nodeSeen)) { print "  ✗ aresta " i ": from aponta nó inexistente: " efrom[i]; problems++ }
      if (!(eto[i]   in nodeSeen)) { print "  ✗ aresta " i ": to aponta nó inexistente: " eto[i]; problems++ }
      if (index(VE, etype[i]) == 0 || etype[i] == "") { print "  ✗ aresta " i ": edge_type inválido: [" etype[i] "]"; problems++ }
    }
    for (i = 1; i <= nn; i++) {
      id = order[i]
      if (deg[id] == 0) { print "  ✗ nó órfão (grau 0): " id; problems++ }
      if (index(VN, ntype[id]) == 0 || ntype[id] == "") { print "  ✗ " id ": node_type inválido: [" ntype[id] "]"; problems++ }
      if (index(VP, plane[id]) == 0 || plane[id] == "") { print "  ✗ " id ": plane inválido: [" plane[id] "]"; problems++ }
      if (statusFactor(nstatus[id]) < 0) { print "  ✗ " id ": status inválido: [" nstatus[id] "]"; problems++ }
      if (impact[id] < 1 || impact[id] > 5) { print "  ✗ " id ": impact fora de 1-5: " impact[id]; problems++ }
      if (conf[id] < 0 || conf[id] > 1) { print "  ✗ " id ": confidence fora de 0-1: " conf[id]; problems++ }
      if (refutedBy[id] > 0 && (nstatus[id] == "confirmed" || nstatus[id] == "open")) {
        print "  ✗ CONTRADIÇÃO: " id " recebe REFUTES mas segue status=" nstatus[id] " (reconciliar: refuted ou superseded)"; problems++
      }
    }
    if (problems == 0) print "  ✅ sem contradições estruturais (" nn " nós, " ne " arestas)"
    print ""
  }

  exit (problems > 0 ? 1 : 0)
}
' "$FILE"