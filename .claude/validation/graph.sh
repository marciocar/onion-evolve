#!/usr/bin/env bash
# =============================================================================
# graph.sh — Lente sócio-técnica do Onion (grafo gerado da spec-as-code)
#
# Propósito : Compor o grafo de conhecimento do Onion (atores + artefatos + canais)
#             DIRETAMENTE da spec-as-code — nenhum store externo. É a "visão-de-fora"
#             composta da "visão-de-dentro" (como inventory.md é gerado). Serve o
#             dogfood: o Transformer lê graph.md para achar caminho/solução e
#             orquestrar; o script responde o que o LLM faz mal (impacto/órfão/caminho).
#             TBox: docs/knowledge-base/concepts/onion-relation-vocabulary.md
#
# Fontes    : docs/onion/actors.yaml (atores/canais/comunicação) + capability.json
#             dos plugins (requires/provides/loads) + frontmatter dos agentes
#             (related_agents/related_commands) + has-member (onion → artefatos).
#
# Uso       : graph.sh [--markdown|--triples|--impact <nó>|--path <de> <até>|--orphans]
#               --markdown (default) : docs/onion/graph.md (duplo público)
#               --triples            : TSV  subject<TAB>predicate<TAB>object<TAB>via
#               --impact <nó>        : quem aponta para <nó> (dependência reversa)
#               --path <de> <até>    : caminho dirigido de <de> a <até> (BFS)
#               --orphans            : artefatos que ninguém referencia
#
# Determinístico, sem LLM. Mesma spec-as-code → mesma saída. Coberto por
# lint-artifacts.sh (REGRA 21 graph-sync) e lint-selftest.sh (run_graph_selftests).
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MODE="${1:---markdown}"

have_jq() { command -v jq >/dev/null 2>&1; }

# --- extrator de lista YAML (inline [a,b] OU bloco "- a") do frontmatter ---
yaml_list() { # $1=file $2=key
  awk -v key="$2" '
    $0 ~ "^"key":" {
      l=$0; sub("^"key":[[:space:]]*","",l)
      if (l ~ /^\[/) { gsub(/[]["]/,"",l); n=split(l,a,","); for(i=1;i<=n;i++){gsub(/^[[:space:]]+|[[:space:]]+$/,"",a[i]); if(a[i]!="")print a[i]} ; next }
      b=1; next
    }
    b && /^[[:space:]]+-[[:space:]]/ { it=$0; sub(/^[[:space:]]+-[[:space:]]*/,"",it); gsub(/"/,"",it); gsub(/^[[:space:]]+|[[:space:]]+$/,"",it); if(it!="")print it; next }
    b && /^[^[:space:]]/ { b=0 }
  ' "$1" 2>/dev/null
}

# --- emite todas as triplas: subject<TAB>predicate<TAB>object<TAB>via ---
emit_triples() {
  # (1) actor seed (atores/canais/comunicação)
  local f="${REPO_ROOT}/docs/onion/actors.yaml"
  if [ -f "${f}" ]; then
    grep -E '^[[:space:]]*-[[:space:]]*\{[[:space:]]*s:' "${f}" 2>/dev/null | while IFS= read -r line; do
      s="$(printf '%s' "${line}" | sed -E 's/.*\bs:[[:space:]]*([A-Za-z0-9_./-]+).*/\1/')"
      p="$(printf '%s' "${line}" | sed -E 's/.*\bp:[[:space:]]*([A-Za-z0-9_./-]+).*/\1/')"
      o="$(printf '%s' "${line}" | sed -E 's/.*\bo:[[:space:]]*([A-Za-z0-9_./-]+).*/\1/')"
      via="$(printf '%s' "${line}" | grep -oE 'via:[[:space:]]*[A-Za-z0-9_./-]+' | sed -E 's/via:[[:space:]]*//')"
      printf '%s\t%s\t%s\t%s\n' "${s}" "${p}" "${o}" "${via}"
    done
  fi

  # (2) capability contracts dos plugins (requires/provides/loads)
  if have_jq; then
    for cap in "${REPO_ROOT}"/plugins/*/.claude-plugin/capability.json; do
      [ -f "${cap}" ] || continue
      local nm; nm="$(jq -r '.name' "${cap}" 2>/dev/null)"
      [ -n "${nm}" ] || continue
      jq -r '.requires[]?' "${cap}" 2>/dev/null | while IFS= read -r r; do printf '%s\trequires\t%s\t\n' "${nm}" "${r}"; done
      jq -r '.provides[]?' "${cap}" 2>/dev/null | while IFS= read -r r; do printf '%s\tprovides\t%s\t\n' "${nm}" "${r}"; done
      jq -r '.loads[]?'    "${cap}" 2>/dev/null | while IFS= read -r r; do printf '%s\tloads\t%s\t\n' "${nm}" "${r}"; done
    done
  fi

  # (3) frontmatter dos agentes (related_agents / related_commands) — atores especialistas
  while IFS= read -r ag; do
    local an; an="$(basename "${ag}" .md)"
    yaml_list "${ag}" "related_agents"   | while IFS= read -r x; do [ -n "${x}" ] && printf '%s\trelated\t%s\t\n' "${an}" "${x}"; done
    yaml_list "${ag}" "related_commands" | while IFS= read -r x; do [ -n "${x}" ] && printf '%s\trelated\t%s\t\n' "${an}" "${x}"; done
  done < <(find "${REPO_ROOT}/.claude/agents" -name "*.md" ! -iname "readme.md" 2>/dev/null | sort)

  # (4) has-member: onion → agentes/skills (artefatos)
  while IFS= read -r ag; do printf 'onion\thas-member\t%s\t\n' "$(basename "${ag}" .md)"; done \
    < <(find "${REPO_ROOT}/.claude/agents" -name "*.md" ! -iname "readme.md" 2>/dev/null | sort)
  for sk in "${REPO_ROOT}"/.claude/skills/*/; do [ -d "${sk}" ] && printf 'onion\thas-member\t%s\t\n' "$(basename "${sk}")"; done
}

# Computa as triplas UMA vez por execução (cache) — evita re-emitir em cada seção do --markdown.
_TRIPLES_CACHE="$(emit_triples | LC_ALL=C sort -u)"
triples_sorted() { printf '%s\n' "${_TRIPLES_CACHE}"; }

case "${MODE}" in
  --triples)
    triples_sorted
    ;;

  --impact)
    node="${2:-}"; [ -n "${node}" ] || { echo "uso: graph.sh --impact <nó>" >&2; exit 2; }
    echo "# Impacto reverso de '${node}' — quem aponta para ele:"
    triples_sorted | awk -F'\t' -v n="${node}" '$3 ~ n {printf "  %s --%s--> %s\n",$1,$2,$3}'
    ;;

  --orphans)
    echo "# Órfãos — artefatos que o Onion tem mas ninguém referencia (related/requires):"
    refs="$(triples_sorted | awk -F'\t' '$2=="related"||$2=="requires"{print $3}' | sort -u)"
    triples_sorted | awk -F'\t' '$2=="has-member"{print $3}' | sort -u | while IFS= read -r m; do
      printf '%s\n' "${refs}" | grep -qiF "${m}" || echo "  ${m}"
    done
    ;;

  --path)
    from="${2:-}"; to="${3:-}"; [ -n "${from}" ] && [ -n "${to}" ] || { echo "uso: graph.sh --path <de> <até>" >&2; exit 2; }
    # BFS dirigido (s -> o) sobre as triplas
    edges="$(triples_sorted | awk -F'\t' '{print $1"\t"$3}')"
    echo "# Caminho de '${from}' até '${to}':"
    printf '%s\n' "${edges}" | awk -F'\t' -v start="${from}" -v goal="${to}" '
      { adj[$1]=adj[$1]" "$2 }
      END{
        split(start,q," "); head=1; tail=1; queue[tail++]=start; seen[start]=1; prev[start]=""
        found=0
        while(head<tail){ cur=queue[head++]; if(cur==goal){found=1;break}
          n=split(adj[cur],nb," "); for(i=1;i<=n;i++){ if(nb[i]!="" && !(nb[i] in seen)){seen[nb[i]]=1; prev[nb[i]]=cur; queue[tail++]=nb[i]} } }
        if(!found){print "  (sem caminho dirigido)"; exit}
        path=goal; node=goal; while(prev[node]!=""){node=prev[node]; path=node" -> "path}
        print "  "path
      }'
    ;;

  --markdown|*)
    {
      echo "# Grafo do Onion — lente sócio-técnica (GERADO; não editar à mão)"
      echo ""
      echo "> Gerado por \`.claude/validation/graph.sh\` da spec-as-code (actors.yaml + capability contracts +"
      echo "> frontmatter + inventário). SSOT = spec-as-code; este arquivo é **derivado**. Sem store externo."
      echo "> TBox: \`docs/knowledge-base/concepts/onion-relation-vocabulary.md\`. Duplo público: o Transformer"
      echo "> navega para achar caminho/solução/orquestração; o script responde impacto/órfão/caminho."
      echo ""
      echo "## Atores e canais (o sistema sócio-técnico)"
      echo ""
      triples_sorted | awk -F'\t' '
        $1=="maestro"||$1=="assistant"||$1=="onion"||$1=="core"||$1=="adopter" {
          line=sprintf("- **%s** --%s--> %s",$1,$2,$3); if($4!="")line=line" _(via "$4")_"; print line }'
      echo ""
      echo "## Capacidades por vertical (requires / provides / loads)"
      echo ""
      triples_sorted | awk -F'\t' '$2=="requires"||$2=="provides"||$2=="loads"{printf "- %s **%s** %s\n",$1,$2,$3}'
      echo ""
      echo "## Triplas (cruas — para consumo determinístico)"
      echo ""
      echo '```tsv'
      echo "# subject	predicate	object	via"
      triples_sorted
      echo '```'
    }
    ;;
esac
