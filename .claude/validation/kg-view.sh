#!/usr/bin/env bash
# =============================================================================
# kg-view.sh — PROJEÇÃO legível/consumível de um .kg.yaml.
#
# O radar (kg-radar.sh) é o MOTOR: ele julga (integridade, reconciliação, frescor)
# e o veredito é dele. Este script não julga nada — só PROJETA o mesmo grafo em
# duas formas que o radar não produz:
#   --markdown  lente navegável, versionada (docs/onion/graph/<slug>-radar.md)
#   --json      dado inline para as visualizações (Artifact e página pública)
#
# Molde: docs/onion/graph.md via graph.sh — SSOT é a fonte, a lente é DERIVADA,
# sem store externo. Nunca edite a saída à mão; regenere.
#
# ---------------------------------------------------------------------------
# ⚠️ DOIS PARSERS, DUAS VERDADES — o risco desta escolha, declarado
# ---------------------------------------------------------------------------
#   Este script REIMPLEMENTA o parse do kg-radar.sh (mesmas âncoras
#   `^[[:space:]]*<campo>:`, mesma fórmula de peso). Isso é dívida deliberada:
#   o radar é awk line-based e não tem modo de exportação, e acoplar-me à sua
#   saída HUMANA seria pior (formatação muda, projeção quebra em silêncio).
#   O preço é DRIFT: o dia em que o radar mudar o parse e este script não, a
#   projeção passa a mostrar um grafo que não é o que o motor vê — mentira com
#   cara de relatório.
#   MITIGAÇÃO, e é o que torna a dívida admissível (REGRA DE ADMISSÃO):
#   `--assert-parity` compara as contagens desta projeção com as do
#   `kg-radar.sh --integrity` e REPROVA na divergência. A guarda roda no lint
#   e no selftest. Se os dois parsers discordarem, alguém fica sabendo no mesmo
#   dia — em vez de descobrir por um gráfico errado meses depois.
# ---------------------------------------------------------------------------
#
# Uso: kg-view.sh <arquivo.kg.yaml> [--markdown|--json|--assert-parity]
# Exit: 0 ok · 1 divergência de paridade · 2 erro de uso
# =============================================================================
set -uo pipefail

FILE="${1:-}"
MODE="${2:---markdown}"

if [ -z "${FILE}" ] || [ ! -f "${FILE}" ]; then
  printf 'uso: kg-view.sh <arquivo.kg.yaml> [--markdown|--json|--assert-parity]\n' >&2
  exit 2
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# A saída precisa ser IDÊNTICA vinda de caminho relativo ou absoluto — senão a
# lente "driftaria" só por causa de quem a invocou, e o drift-guard (REGRA 31)
# reprovaria para sempre. Achado pelo próprio guard na 1ª execução.
_abs="$(cd "$(dirname "${FILE}")" && pwd)/$(basename "${FILE}")"
# GIT_DIR neutralizado: sob hook do git em worktree o GIT_DIR e ABSOLUTO, e com ele
# setado `git -C <subdir> rev-parse --show-toplevel` devolve o SUBDIR, nao a raiz —
# o script passa a procurar tudo no lugar errado e emite vazio (medido 2026-08-04).
_repo="$(env -u GIT_DIR -u GIT_WORK_TREE git -C "$(dirname "${FILE}")" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "${_repo}" ] && [ "${_abs}" != "${_abs#${_repo}/}" ]; then
  SRC_REL="${_abs#${_repo}/}"          # dentro de um repo: caminho a partir da raiz
else
  SRC_REL="$(basename "${FILE}")"      # fora de repo NÃO há raiz canônica — o
                                       # fallback anterior era `pwd`, que muda com
                                       # QUEM invoca e ressuscitava a não-determinância
                                       # (achado pela guarda V2 na fixture, que roda
                                       # em mktemp -d, fora do repo).
fi

# --- Paridade com o motor: a projeção tem de ver o MESMO tamanho de grafo ----
if [ "${MODE}" = "--assert-parity" ]; then
  # FAIL-LOUD se o motor não está lá. Sem o radar não há com o que comparar, e
  # "passou" seria uma afirmação sobre nada — o no-op silencioso de sempre.
  # Achado pela guarda V4, que roda o mutante fora de .claude/validation/ e viu
  # a paridade sair VERDE por ausência do irmão. (Mesmo pecado que o P0 da
  # REGRA 30 proíbe: fonte ausente nunca vira aprovação.)
  if [ ! -f "${HERE}/kg-radar.sh" ]; then
    printf '✗ kg-view: kg-radar.sh não encontrado em %s — paridade não pode ser afirmada.\n' "${HERE}" >&2
    exit 1
  fi
  radar_out="$(bash "${HERE}/kg-radar.sh" "${FILE}" --integrity 2>&1 || true)"
  # "✅ sem contradições estruturais (881 nós, 1086 arestas)"
  r_n="$(printf '%s' "${radar_out}" | grep -oE '\(([0-9]+) nós' | grep -oE '[0-9]+' | head -1)"
  r_e="$(printf '%s' "${radar_out}" | grep -oE '([0-9]+) arestas' | grep -oE '[0-9]+' | head -1)"
  if [ -z "${r_n}" ]; then
    # O radar só imprime as contagens quando está VERDE. Grafo com contradição
    # não é comparável — e não é papel desta guarda reprovar por isso (o radar
    # já o faz). Sai 0 dizendo que não deu para comparar, em vez de fingir.
    printf 'kg-view: paridade não verificável (radar não reportou contagens — grafo com contradição?).\n' >&2
    exit 0
  fi
  v_n="$(bash "$0" "${FILE}" --json | grep -oE '"node_count":[0-9]+' | grep -oE '[0-9]+')"
  v_e="$(bash "$0" "${FILE}" --json | grep -oE '"edge_count":[0-9]+' | grep -oE '[0-9]+')"
  if [ "${r_n}" = "${v_n}" ] && [ "${r_e}" = "${v_e}" ]; then
    printf '✅ paridade kg-view × kg-radar: %s nós, %s arestas\n' "${r_n}" "${r_e}"
    exit 0
  fi
  printf '✗ DIVERGÊNCIA de parse: radar vê %s nós/%s arestas; a projeção vê %s/%s.\n' \
         "${r_n}" "${r_e}" "${v_n}" "${v_e}" >&2
  printf '  Os dois parsers saíram de sincronia — a projeção está mentindo. Reconcilie kg-view.sh com kg-radar.sh.\n' >&2
  exit 1
fi

case "${MODE}" in --markdown|--json) ;; *) printf 'modo inválido: %s\n' "${MODE}" >&2; exit 2 ;; esac

awk -v mode="${MODE}" -v src="${SRC_REL}" '
function statusFactor(s) {
  if (s == "open" || s == "confirmed") return 1.0
  if (s == "refuted") return 0.0
  if (s == "superseded") return 0.2
  if (s == "done") return 0.1
  return -1
}
function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); gsub(/^["'\'']|["'\'']$/, "", s); return s }
# Markdown lê para humano: aspas escapadas do YAML (\") viram aspas de verdade.
# NÃO usar no JSON — lá o escape é a gramática, não sujeira.
function unesc(s) { gsub(/\\"/, "\"", s); return s }
function jesc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, " ", s); return s }

BEGIN { section = ""; nid = ""; ne = 0; nn = 0 }
/^[[:space:]]*#/ { next }
/^nodes:/ { section = "nodes"; next }
/^edges:/ { section = "edges"; nid = ""; next }
/^meta:/  { section = "meta"; next }

section == "meta" && /^[[:space:]]*id:/ { v=$0; sub(/^[[:space:]]*id:/,"",v); gid=trim(v); next }

section == "nodes" && /^[[:space:]]+- id:/ {
  nid = trim($0); sub(/^- id:/, "", nid); nid = trim(nid)
  order[++nn] = nid; next
}
section == "nodes" && nid != "" {
  line = $0; sub(/#.*$/, "", line)
  if (line ~ /^[[:space:]]*node_type:/)  { v=line; sub(/^[[:space:]]*node_type:/,"",v);  ntype[nid]=trim(v) }
  if (line ~ /^[[:space:]]*plane:/)      { v=line; sub(/^[[:space:]]*plane:/,"",v);      plane[nid]=trim(v) }
  if (line ~ /^[[:space:]]*layer:/)      { v=line; sub(/^[[:space:]]*layer:/,"",v);      layer[nid]=trim(v) }
  if (line ~ /^[[:space:]]*impact:/)     { v=line; sub(/^[[:space:]]*impact:/,"",v);     impact[nid]=trim(v)+0 }
  if (line ~ /^[[:space:]]*confidence:/) { v=line; sub(/^[[:space:]]*confidence:/,"",v); conf[nid]=trim(v)+0 }
  if (line ~ /^[[:space:]]*status:/)     { v=line; sub(/^[[:space:]]*status:/,"",v);     nstatus[nid]=trim(v) }
  if (line ~ /^[[:space:]]*verified_at:/)      { v=line; sub(/^[[:space:]]*verified_at:/,"",v);      vat[nid]=trim(v) }
  if (line ~ /^[[:space:]]*verified_against:/) { v=line; sub(/^[[:space:]]*verified_against:/,"",v); vag[nid]=trim(v) }
  if (line ~ /^[[:space:]]*trace:/)      { v=line; sub(/^[[:space:]]*trace:/,"",v);      tr[nid]=trim(v) }
  if ($0  ~ /^[[:space:]]*label:/)       { v=$0;   sub(/^[[:space:]]*label:/,"",v);      label[nid]=trim(v) }
  next
}
section == "edges" && /^[[:space:]]*- from:/ {
  v=$0; sub(/^[[:space:]]*- from:/,"",v); ne++; efrom[ne]=trim(v); next
}
section == "edges" && /^[[:space:]]*to:/       { v=$0; sub(/^[[:space:]]*to:/,"",v);        eto[ne]=trim(v); next }
section == "edges" && /^[[:space:]]*edge_type:/{ v=$0; sub(/^[[:space:]]*edge_type:/,"",v); etype[ne]=trim(v); next }
section == "edges" && /^[[:space:]]*on:/       { v=$0; sub(/^[[:space:]]*on:/,"",v);        eon[ne]=trim(v); next }

END {
  for (i = 1; i <= ne; i++) { deg[efrom[i]]++; deg[eto[i]]++ }
  for (i = 1; i <= nn; i++) {
    id = order[i]; sf = statusFactor(nstatus[id]); if (sf < 0) sf = 0
    att[id] = impact[id] * conf[id] * sf * (1 + deg[id])
    byType[ntype[id]]++; byStatus[nstatus[id]]++; byPlane[plane[id]]++
    if (deg[id] == 0) orphans++
  }
  n = asorti(att, sorted, "@val_num_desc")

  if (mode == "--json") {
    printf "{\"graph\":\"%s\",\"node_count\":%d,\"edge_count\":%d,\"orphans\":%d,\n", jesc(gid), nn, ne, orphans+0
    printf "\"by_type\":{"; sep=""
    for (k in byType) { printf "%s\"%s\":%d", sep, jesc(k), byType[k]; sep="," }
    printf "},\n\"by_status\":{"; sep=""
    for (k in byStatus) { printf "%s\"%s\":%d", sep, jesc(k), byStatus[k]; sep="," }
    printf "},\n\"by_plane\":{"; sep=""
    for (k in byPlane) { printf "%s\"%s\":%d", sep, jesc(k), byPlane[k]; sep="," }
    printf "},\n\"nodes\":[\n"; sep=""
    for (i = 1; i <= nn; i++) {
      id = sorted[i]
      ly = (layer[id] == "") ? "audit" : layer[id]
      printf "%s{\"id\":\"%s\",\"t\":\"%s\",\"p\":\"%s\",\"s\":\"%s\",\"w\":%.2f,\"d\":%d,\"i\":%d,\"c\":%.2f,\"ly\":\"%s\",\"va\":\"%s\",\"vg\":\"%s\",\"l\":\"%s\",\"tr\":\"%s\"}",
             sep, jesc(id), jesc(ntype[id]), jesc(plane[id]), jesc(nstatus[id]), att[id], deg[id]+0, impact[id]+0, conf[id]+0, jesc(ly), jesc(vat[id]), jesc(vag[id]), jesc(label[id]), jesc(tr[id])
      sep=",\n"
    }
    printf "\n],\n\"edges\":[\n"; sep=""
    for (i = 1; i <= ne; i++) {
      printf "%s{\"f\":\"%s\",\"t\":\"%s\",\"k\":\"%s\",\"on\":\"%s\"}", sep, jesc(efrom[i]), jesc(eto[i]), jesc(etype[i]), jesc(eon[i])
      sep=",\n"
    }
    printf "\n]}\n"
    exit 0
  }

  # ── markdown ──────────────────────────────────────────────────────────────
  printf "<!-- GERADO por .claude/validation/kg-view.sh — NÃO EDITE À MÃO. -->\n"
  printf "<!-- Fonte: %s · regenere: bash .claude/validation/kg-view.sh %s --markdown -->\n\n", src, src
  printf "# Lente do grafo — `%s`\n\n", gid
  printf "**%d nós · %d arestas · %d órfãos**\n\n", nn, ne, orphans+0
  printf "> Projeção DERIVADA. O veredito (integridade, reconciliação, frescor) é do\n"
  printf "> `kg-radar.sh` — esta lente não julga, só mostra.\n\n"

  printf "## Composição\n\n| Tipo | n |\n|---|---|\n"
  m = asorti(byType, st, "@val_num_desc")
  for (i = 1; i <= m; i++) printf "| %s | %d |\n", st[i], byType[st[i]]
  printf "\n| Status | n |\n|---|---|\n"
  m = asorti(byStatus, ss, "@val_num_desc")
  for (i = 1; i <= m; i++) printf "| %s | %d |\n", ss[i], byStatus[ss[i]]
  printf "\n| Plano | n |\n|---|---|\n"
  m = asorti(byPlane, sp, "@val_num_desc")
  for (i = 1; i <= m; i++) printf "| %s | %d |\n", sp[i], byPlane[sp[i]]

  printf "\n## Radar — 25 focos de atenção (peso × centralidade)\n\n"
  printf "| # | atenção | nó | tipo | plano/status | grau |\n|---|---|---|---|---|---|\n"
  top = (n < 25) ? n : 25
  for (i = 1; i <= top; i++) {
    id = sorted[i]; if (att[id] <= 0) break
    printf "| %d | %.1f | `%s` | %s | %s/%s | %d |\n", i, att[id], id, ntype[id], plane[id], nstatus[id], deg[id]+0
  }

  printf "\n### O que esses focos dizem\n\n"
  for (i = 1; i <= ((n < 10) ? n : 10); i++) {
    id = sorted[i]; if (att[id] <= 0) break
    printf "- **`%s`** *(%s, %s)* — %s\n", id, ntype[id], nstatus[id], unesc(label[id])
  }

  printf "\n## Perguntas em aberto (o que ainda cobra resposta)\n\n"
  cnt = 0
  for (i = 1; i <= n; i++) {
    id = sorted[i]
    if (ntype[id] == "question" && nstatus[id] == "open" && att[id] > 0) {
      cnt++; if (cnt > 20) break
      printf "%d. **`%s`** (atenção %.1f) — %s\n", cnt, id, att[id], unesc(label[id])
    }
  }
  if (cnt == 0) printf "_Nenhuma pergunta aberta com peso._\n"
  printf "\n"
}
' "${FILE}"
