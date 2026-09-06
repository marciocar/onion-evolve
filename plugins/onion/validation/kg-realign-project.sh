#!/usr/bin/env bash
# raiz do plugin resolvida PELO PRÓPRIO ARQUIVO (o ambiente do shell não traz a variável)
: "${CLAUDE_PLUGIN_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)}"
# =============================================================================
# kg-realign-project.sh — a REVISÃO EM CAMADAS da jornada do plano × o vivo.
#
# Propósito : "selar realinhado" — projetar, determinística e sem LLM, uma
#             revisão do plano-grafo em TRÊS CAMADAS (a tríade do maestro,
#             ancorada em defense-in-depth + reconcile-IaC + arXiv 2608.04066):
#               1. integridade/PASSADO (barata)  — o que foi selado ainda coere?
#               2. drift/PRESENTE (média)         — o vivo ainda bate com o plano?
#               3. north-star/FUTURO (cara)        — ainda vamos para o objetivo?
#             Classifica cada drift em (a) inócuo · (b) custoso-futuro · (c)
#             desorganiza-passado/futuro, e separa commitment-drift (objetivo
#             abandonado) de binding-drift (vínculo objetivo↔artefato quebrado).
#
# Grafo-primeiro: NÃO reparseia YAML — consome `kg-radar --triples/--freshness-tsv/
#             --open-tsv` (a atenção já vem calculada; o radar é a régua). Ontologia
#             dos KINDS de grafo: ${CLAUDE_PLUGIN_ROOT}/kb/onion-kg-ontology-hierarchy.md.
#             ⚠️ O substrato é confiável na ESCRITA (radar reprova), não na LEITURA
#             (a perna de leitura é conselho — este script revisa o que ESTÁ escrito).
#
# Uso       : bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-realign-project.sh [<grafo.kg.yaml>] [--check]
#             sem grafo → o plano de execução do core (docs/onion/graph/fios-abertos.kg.yaml)
#             --check   → só o veredito; exit 1 se houver drift tipo-(c) (DENTE, não advisory)
# =============================================================================
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
RADAR="${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh"
THRESH="${REALIGN_THRESHOLD:-15}"   # histerese: camada-3 só é recomendada acima disto (anti-thrashing)

GRAPH_DEFAULT="docs/onion/graph/fios-abertos.kg.yaml"; GRAPH="$GRAPH_DEFAULT"; MODE="project"
for a in "$@"; do
  case "$a" in
    --check) MODE="check" ;;
    *.kg.yaml) GRAPH="$a" ;;
    *) echo "arg desconhecido: $a" >&2; exit 2 ;;
  esac
done
# O DEFAULT é o plano-grafo DO CORE; num repo que só instalou o plugin ele não existe, e "grafo
# ausente" sozinho não diz o que fazer. A mensagem passa a nomear o caminho: passe o seu grafo.
[ -f "$GRAPH" ] || { echo "ERRO: grafo ausente: $GRAPH" >&2
  [ "$GRAPH" = "$GRAPH_DEFAULT" ] && echo "       (esse é só o DEFAULT — o plano-grafo do CORE, que não existe num repo que apenas instalou o plugin)" >&2
  echo "       passe o grafo deste repo: $(basename "$0") <grafo.kg.yaml> [--check]   ·   ache com: git ls-files '*.kg.yaml'" >&2
  exit 2; }

# Passo 0 — LEGIBILIDADE antes de veredito (não se realinha grafo que o motor não lê)
bash "$RADAR" "$GRAPH" --integrity --schema >/dev/null 2>&1 \
  || { echo "ERRO: $GRAPH reprova integridade/schema no radar — corrija antes de realinhar" >&2; exit 2; }

EDGES="$(mktemp)"; FRESH="$(mktemp)"; trap 'rm -f "$EDGES" "$FRESH"' EXIT
bash "$RADAR" "$GRAPH" --triples       2>/dev/null > "$EDGES"
bash "$RADAR" "$GRAPH" --freshness-tsv 2>/dev/null > "$FRESH"
# ⚠️ FEED PRÓPRIO PARA O STATUS. O `--freshness-tsv` OMITE nó de atenção zero — e todo `refuted` tem
#    atenção zero, ou seja, o superador morto é exatamente quem falta ali. Usar o feed errado fazia a
#    cura abaixo virar no-op silencioso (medido: 0 de 90 grafos mudaram, inclusive o que devia mudar).
STATUS="$(mktemp)"; trap 'rm -f "${STATUS}"' EXIT
bash "$RADAR" "$GRAPH" --status-tsv 2>/dev/null > "$STATUS"

# Motor de classificação — 1 awk lê arestas + frescor e emite:  camada \t tipo \t atenção \t id \t rótulo-da-ação
# ⚠️ TRÊS PASSADAS, e a 1ª existe por uma DIVERGÊNCIA DE DOUTRINA MEDIDA (2026-09-06). O radar
#    exclui da reconciliação o superador MORTO — `supersederConta` (kg-radar.sh), com o comentário
#    "os mortos (refuted/superseded), cuja própria superação é duvidosa". A camada 1 daqui contava
#    QUALQUER aresta SUPERSEDES/REFUTES, então um alvo legitimamente reaberto sob um superador que
#    CAIU virava drift tipo-(c) PERMANENTE: o radar dizia ✅ e o realign dizia REALINHAR, sobre o
#    mesmo grafo. Duas doutrinas na mesma casa é o defeito que o próprio comentário do radar nomeia.
#    Agora o status do superador é lido ANTES das arestas, e só superador VIVO cria dever de Aufhebung.
FINDINGS="$(awk -v thr="$THRESH" '
  FNR==1 { pass++ }
  # ---- passada 1: status de cada nó (para saber se o SUPERADOR está vivo) ----
  pass==1 { nodeStatus[$1]=$2; next }
  # ---- passada 2: arestas (from EDGE to) ----
  pass==2 {
    from=$1; e=$2; to=$3
    if (e=="DEPENDS_ON")      downstream[to]++            # to tem dependente a jusante (from precisa de to)
    else if (e=="SUPERSEDES" || e=="REFUTES") {
      # o mesmo critério do radar: superador `open`/`refuted`/`superseded` NÃO conta
      st = (from in nodeStatus) ? nodeStatus[from] : ""
      if (st != "open" && st != "refuted" && st != "superseded") {
        if (e=="SUPERSEDES") supTarget[to]=1; else refTarget[to]=1
      }
    }
    else if (e=="SUPPORTS")   { supports[to]++ }         # to recebe apoio (evidência)
    if (e=="TRACES_TO" || e=="SUPPORTS") binding[from]=1 # from tem vínculo declarado
    next
  }
  # ---- passada 3: frescor (id type plane status impact conf att vat vagainst trace verdict) ----
  {
    id=$1; typ=$2; st=$4; imp=$5+0; att=$7+0; trace=$10; verdict=$11
    down = (id in downstream) ? downstream[id] : 0
    hasTrace = (trace != "" && trace != "-")   # vínculo a artefato via campo trace: (não só aresta)
    unrec = ((id in supTarget) || (id in refTarget)) && (st=="confirmed" || st=="open")
    staleV = (verdict=="STALE-OLD" || verdict=="STALE-MISSING" || verdict=="UNANCHORED" || verdict=="MISPLANED" || verdict=="REFUTED" || verdict=="DRIFTED")

    if (unrec) {                                  # CAMADA 1 → tipo (c): desorganiza passado/futuro
      print "1\tc\t" att "\t" id "\treconciliar: superado/refutado mas segue " st " (Aufhebung devida)"
    } else if (staleV && down>=1) {               # CAMADA 2 → tipo (b): custoso no futuro
      print "2\tb\t" att "\t" id "\tre-medir (" verdict "): " down " dependente(s) a jusante — delegar /onion:kg-freshness"
    } else if (staleV) {                          # CAMADA 2 → tipo (a): inócuo
      print "2\ta\t" att "\t" id "\tanotar (" verdict "): sem dependentes — baixo custo"
    }
    # CAMADA 3 — north-star, a dissociação de arXiv 2608.04066: a META (question) pode ser
    # ABANDONADA (commitment); a AÇÃO (decision) pode perder o VÍNCULO ao artefato (binding).
    # Restrito a `question` de propósito: decision aberto é trabalho pendente (o backlog já cobre),
    # não objetivo abandonado — senão o sinal grita em todo nó aberto (anti-padrão cerimônia).
    if (typ=="question" && st=="open" && imp>=4 && !(id in supports)) {
      print "3\tcommit\t" att "\t" id "\tcommitment-drift: objetivo (pergunta) aberto de alto impacto sem apoio — abandonado?"
    }
    # !(id in supports): decisão que é ALVO de `evidence SUPPORTS decision` ESTÁ vinculada (apoio de
    # ENTRADA) — não é nó solto. Sem esta guarda o bind gritava em toda decisão bem-apoiada (o padrão
    # dominante em grafo audit/research). Achado do dogfood do corpus real: 3 FPs medidos num só grafo.
    if (typ=="decision" && !(id in binding) && !hasTrace && !(id in supports) && st!="superseded" && st!="refuted") {
      print "3\tbind\t" att "\t" id "\tbinding-drift: decisão sem trace:, sem TRACES_TO/SUPPORTS de saída E sem apoio de entrada — vínculo objetivo↔artefato ausente (nó solto)"
    }
  }
' "$STATUS" "$EDGES" "$FRESH")"

# agregados
n_c=$(printf '%s\n' "$FINDINGS" | awk -F'\t' '$2=="c"' | grep -c . || true)
n_b=$(printf '%s\n' "$FINDINGS" | awk -F'\t' '$2=="b"' | grep -c . || true)
n_a=$(printf '%s\n' "$FINDINGS" | awk -F'\t' '$2=="a"' | grep -c . || true)
n_commit=$(printf '%s\n' "$FINDINGS" | awk -F'\t' '$2=="commit"' | grep -c . || true)
n_bind=$(printf '%s\n' "$FINDINGS" | awk -F'\t' '$2=="bind"' | grep -c . || true)
agg=$(printf '%s\n' "$FINDINGS" | awk -F'\t' '$2=="c"||$2=="b"{s+=$3}END{printf "%.1f", s+0}')

verdict() {
  if [ "$n_c" -gt 0 ]; then echo "REALINHAR"        # dente: tipo-c desorganiza — bloqueia
  elif awk -v a="$agg" -v t="$THRESH" 'BEGIN{exit !(a>=t)}'; then echo "ATENCAO"   # histerese cruzada
  else echo "ALINHADO"; fi
}
V="$(verdict)"

if [ "$MODE" = "check" ]; then
  printf 'realign %s — %s: (c)=%s (b)=%s (a)=%s · commit=%s bind=%s · agg=%s (limiar %s)\n' \
    "$(basename "$GRAPH" .kg.yaml)" "$V" "$n_c" "$n_b" "$n_a" "$n_commit" "$n_bind" "$agg" "$THRESH"
  [ "$n_c" -gt 0 ] && exit 1 || exit 0
fi

# projeção legível (a revisão em camadas)
grp() { printf '%s\n' "$FINDINGS" | awk -F'\t' -v c="$1" -v t="$2" '$1==c && $2==t' | sort -t$'\t' -k3,3nr; }
row() { while IFS=$'\t' read -r _cam _typ att id act; do [ -n "${id:-}" ] && printf '  - `%s` (atenção %.1f) — %s\n' "$id" "${att:-0}" "$act"; done; }

printf '# Realinhamento — %s  ·  veredito: **%s**\n\n' "$(basename "$GRAPH" .kg.yaml)" "$V"
printf '> Revisão em camadas da jornada do plano × o vivo. Gerado por `kg-realign-project.sh` (determinístico,\n'
printf '> consome o radar). O grafo é a fonte; propõe, o maestro sela (append-mostly). Drift: (a) inócuo · (b)\n'
printf '> custoso-futuro · (c) desorganiza-passado/futuro. Histerese: camada-3 só pesa acima de %s de atenção agregada.\n\n' "$THRESH"
printf '**(c)=%s · (b)=%s · (a)=%s · commitment=%s · binding=%s · atenção agregada (b+c)=%s**\n\n' "$n_c" "$n_b" "$n_a" "$n_commit" "$n_bind" "$agg"

printf '## Camada 1 — integridade/passado (tipo c: desorganiza)\n'
[ "$n_c" -gt 0 ] && grp 1 c | row || printf '  _sem drift tipo-c — o passado selado coere._\n'
printf '\n## Camada 2 — drift/presente\n'
if [ "$((n_b+n_a))" -gt 0 ]; then
  [ "$n_b" -gt 0 ] && { printf '  **(b) custoso — tem dependentes a jusante:**\n'; grp 2 b | row; }
  [ "$n_a" -gt 0 ] && { printf '  **(a) inócuo — sem dependentes:**\n'; grp 2 a | row; }
else printf '  _sem drift de frescor no vivo._\n'; fi
printf '\n## Camada 3 — north-star/futuro%s\n' "$([ "$V" = ALINHADO ] && echo ' (abaixo do limiar — informativo)' || echo '')"
if [ "$((n_commit+n_bind))" -gt 0 ]; then
  [ "$n_commit" -gt 0 ] && { printf '  **commitment-drift (objetivo abandonado):**\n'; grp 3 commit | row; }
  [ "$n_bind" -gt 0 ] && { printf '  **binding-drift (vínculo objetivo↔artefato):**\n'; grp 3 bind | row; }
else printf '  _objetivo e vínculos intactos._\n'; fi

printf '\n## Ação (dente, não advisory)\n'
case "$V" in
  REALINHAR) printf '  ⛔ há drift tipo-(c): reconcilie no grafo (novo nó + SUPERSEDES/REFUTES datado, alvo → superseded/refuted) ANTES de seguir. `--check` sai ≠0.\n' ;;
  ATENCAO)   printf '  ⚠️ drift custoso acumulado (agg=%s ≥ %s): rode `/onion:kg-freshness` nos (b) de alta atenção e reavalie a camada 3.\n' "$agg" "$THRESH" ;;
  ALINHADO)  printf '  ✅ alinhado: drift abaixo do limiar (histerese) — sem realinhamento devido. Siga.\n' ;;
esac
