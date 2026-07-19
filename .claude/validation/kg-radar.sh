#!/usr/bin/env bash
# kg-radar.sh — radar determinístico do Knowledge Graph SDAAL (motor soberano do core).
#
# Uso: bash .claude/validation/kg-radar.sh <arquivo.kg.yaml> [--radar|--reconcile|--integrity|--domain|--provenance|--freshness|--schema|--triples]
#      (sem flag = radar + reconcile + integrity + domain + provenance + freshness + schema)
#
# Doutrina: docs/knowledge-base/concepts/knowledge-graph-sdaal.md
#   RADAR           = atenção — peso do nó × centralidade (grau).
#                     peso = impact(1-5) × confidence(0-1) × fator de status
#                     fator: open=1.0 · confirmed=1.0 · refuted=0 · superseded=0.2 · done=0.1
#   RECONCILIAÇÃO   = arestas REFUTES/SUPERSEDES (as auto-correções explícitas do grafo)
#   INTEGRIDADE     = ids duplicados · aresta para nó inexistente · nó órfão (grau 0) ·
#                     contradição (REFUTES entrando em nó que segue confirmed/open) ·
#                     enum inválido (node_type/edge_type/plane/status/layer)
#   RADAR-DE-DOMÍNIO= completude da camada `layer: domain` (⚠ atenção, NÃO reprova):
#                     estado-absorvente · EVENT-sem-efeito · STATE-sem-dona ·
#                     RULE-sem-trace · fonte-única (>1 READS saindo — ADR design-extends-kg)
#   PROVENIÊNCIA    = decisão ancorada em origem (⚠ atenção, NÃO reprova — completude da camada
#                     audit): decisão VIVA sem NENHUMA proveniência (nem aresta TRACES_TO nem
#                     campo `trace:` inline `arquivo:linha`). Reconciliada (superseded/refuted)
#                     é história — não cobrada (mesmo racional do FRESCOR).
#   FRESCOR         = frescor da SSOT (⚠ atenção, NÃO reprova — nó stale mente, não corrompe):
#                     STALE-MISSING (nó plane:PROD sem verified_at:) · STALE-OLD (verified_at
#                     anterior à meta.baseline). Determinístico: compara duas datas do arquivo,
#                     sem "agora" (ADR onion-adr-kg-freshness-gate, proposta #2 (dogfood de campo)).
#   SCHEMA          = versão de schema (✗ REPROVA na divergência — radar não sabe ler o arquivo):
#                     meta.schema_version ≠ a versão que o radar entende → recusa; ausente → ⚠
#                     retrocompat (ADR onion-adr-kg-freshness-gate, proposta #1).
#   TRIPLES         = grafo como triplas `from EDGE to [on evento]` p/ consumo por LLM
#
# Camadas (campo opcional `layer`, default audit — retrocompatível):
#   audit  = grafo epistêmico da investigação (claim/evidence/decision/question)
#   domain = SSOT de domínio (entity/state/event/rule/invariant/policy), durável;
#            o audit TRACES_TO o domain (distinção epistêmico×domínio — sinal
#            2026-07-08-kg-dogfood-completo-promover, promoção schema+método).
#
# Soberania: motor próprio do core (decisão D_NO_VENDOR_RADAR) — NÃO é port do radar.js de um adotante.
# Shell/awk puro por design (economia de motores: gate determinístico não aluga LLM).
# Exit: 0 = ok · 1 = INTEGRIDADE ou SCHEMA encontrou problema · 2 = erro de uso/arquivo.
set -euo pipefail

# Versão de schema que ESTE radar entende. Bump quando a gramática do .kg.yaml mudar de forma
# incompatível — o gate de SCHEMA recusa arquivos que declaram outra versão (proposta #1).
RADAR_SCHEMA="1"

FILE="${1:-}"
MODE="${2:---all}"
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "uso: kg-radar.sh <arquivo.kg.yaml> [--radar|--reconcile|--integrity|--domain|--provenance|--freshness|--schema|--triples]" >&2; exit 2; }

awk -v mode="$MODE" -v radarSchema="$RADAR_SCHEMA" '
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

# Legibilidade da gramática (guarda anti-fail-open — sinal de campo 2026-07-17): conta as
# linhas COM conteúdo dentro de nodes:. Se a seção tem conteúdo e mesmo assim o parser não extrai
# NENHUM nó, a forma do arquivo não é a gramática deste radar. Sem `next` — só conta e segue.
section == "nodes" && NF > 0 { nodeSectionLines++ }

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
  if (line ~ /layer:/)      { v = line; sub(/.*layer:/, "", v);      layer[nid] = trim(v) }
  if (line ~ /impact:/)     { v = line; sub(/.*impact:/, "", v);     impact[nid] = trim(v) + 0 }
  if (line ~ /confidence:/) { v = line; sub(/.*confidence:/, "", v); conf[nid] = trim(v) + 0 }
  if (line ~ /status:/)     { v = line; sub(/.*status:/, "", v);     nstatus[nid] = trim(v) }
  if (line ~ /verified_against:/) { v = line; sub(/.*verified_against:/, "", v); verifiedAgainst[nid] = trim(v) }
  else if (line ~ /verified_at:/) { v = line; sub(/.*verified_at:/, "", v); verifiedAt[nid] = trim(v) }
  # Proveniência inline: a MIGALHA `arquivo:linha` (suporte de campo 2026-07-17). Âncora
  # em ^…trace: — um match solto casaria com label que cita "trace:"/"TRACES_TO" (este repo fala
  # de rastreabilidade sobre si mesmo), false-positivando a origem.
  if (line ~ /^[[:space:]]*trace:/) { v = line; sub(/^[[:space:]]*trace:/, "", v); traceInline[nid] = trim(v) }
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
section == "edges" && /on:/ { v = $0; sub(/.*on:/, "", v); eon[ne] = trim(v); next }

# meta: campos de governança de frescor/schema (proposta #1/#2 — ADR kg-freshness-gate)
section == "meta" && /schema_version:/ { v = $0; sub(/.*schema_version:/, "", v); metaSchema = trim(v); next }
section == "meta" && /baseline:/        { v = $0; sub(/.*baseline:/, "", v);        metaBaseline = trim(v); next }

END {
  VN = "entity claim decision question evidence artifact state event rule invariant policy"
  VE = "SUPPORTS REFUTES SUPERSEDES CAUSES DEPENDS_ON TRACES_TO HAS_STATE TRANSITIONS EMITS CONSTRAINS READS WRITES"
  VP = "DEV PROD"
  VL = "audit domain"
  problems = 0

  # ── GUARDA DE LEGIBILIDADE (o radar tem que saber que NÃO SABE) ────────────────────────────
  # Zero nós extraídos = o radar não leu o arquivo. Sem esta guarda, todo veredito abaixo é
  # VACUOSAMENTE verdadeiro ("não há contradição em conjunto vazio") e o gate fica verde guardando
  # NADA — o falso-verde que o sinal de campo (2026-07-17) pegou num CI regulado, onde
  # "o gate de rastreabilidade estava verde" é frase que aparece em auditoria. Nenhum KG legítimo
  # tem zero nós. Mesma classe do bug do jq (2026-07-01): guarda que falha na direção do silêncio —
  # lá fail-closed (barulhento, pego no mesmo dia), aqui fail-open (silencioso, durou commits).
  # Reprova ANTES de opinar: o selo (meta.schema_version) atesta a intenção do gerador, não a forma
  # do artefato, por isso ele não salva — a forma só se verifica parseando.
  if (nn == 0) {
    print "══ LEGIBILIDADE — o radar conseguiu ler o arquivo? (✗ reprova) ══"
    if (nodeSectionLines > 0) {
      print "  ✗ gramática não reconhecida: a seção nodes: tem " nodeSectionLines " linha(s) de conteúdo,"
      print "    mas o radar extraiu 0 nós. Este radar entende nós como LISTA indentada:"
      print "        nodes:"
      print "          - id: <ID>"
      print "            node_type: <tipo>          # (não `type:`)"
      print "    e arestas como \"- from:\" INDENTADO + \"edge_type:\". Regenere na gramática canônica"
      print "    (ver /meta:kg) ou corrija o gerador."
    } else {
      print "  ✗ nenhum nó encontrado: seção nodes: ausente ou vazia — isto não é um .kg.yaml legível."
    }
    if (metaSchema != "") {
      print "  NOTA: o arquivo declara schema_version \"" metaSchema "\", mas o SELO atesta a INTENÇÃO do"
      print "        gerador, não a FORMA do artefato — por isso ele não pegou isto."
    }
    print "  Abortando sem opinar: um veredito de integridade aqui seria vacuoso (falso-verde)."
    print ""
    exit 1
  }

  # layer default (retrocompat: grafo sem layer = 100% audit)
  for (i = 1; i <= nn; i++) {
    id = order[i]
    if (layer[id] == "") layer[id] = "audit"
    if (layer[id] == "domain") hasDomain = 1
  }

  # grau (centralidade MVP) + contradições + agregados de domínio
  for (i = 1; i <= ne; i++) {
    deg[efrom[i]]++; deg[eto[i]]++
    if (etype[i] == "REFUTES")     refutedBy[eto[i]]++
    if (etype[i] == "TRANSITIONS") { transOut[efrom[i]]++; transIn[eto[i]]++ }
    if (etype[i] == "HAS_STATE")   ownedState[eto[i]]++
    if (etype[i] == "TRACES_TO")   traceOut[efrom[i]]++
    if (etype[i] == "READS")       readsOut[efrom[i]]++
    if (eon[i] != "")              { onUsed[eon[i]] = 1; deg[eon[i]]++ }  # on: conecta o evento (não é órfão)
    outDeg[efrom[i]]++
  }

  if (mode == "--triples") {
    for (i = 1; i <= ne; i++) {
      t = efrom[i] " " etype[i] " " eto[i]
      if (eon[i] != "") t = t " on " eon[i]
      print t
    }
    exit 0
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

  if (mode == "--all" || mode == "--domain") {
    print "══ RADAR-DE-DOMÍNIO — completude da camada domain (⚠ atenção, não reprova) ══"
    if (!hasDomain) {
      print "  (camada domain ausente — grafo puramente epistêmico/audit)"
      print ""
    } else {
      warns = 0
      for (i = 1; i <= nn; i++) {
        id = order[i]
        if (layer[id] != "domain") continue
        # 1. estado-absorvente: recebe TRANSITIONS mas nenhuma sai (limbo? terminal legítimo? decidir)
        if (ntype[id] == "state" && transIn[id] > 0 && transOut[id] == 0) {
          print "  ⚠ estado-absorvente: " id " (recebe TRANSITIONS, nenhuma sai — limbo ou terminal legítimo?)"; warns++
        }
        # 2. EVENT-sem-efeito: evento que não dispara nada (sem aresta de saída e sem uso em on:)
        if (ntype[id] == "event" && outDeg[id] == 0 && !(id in onUsed)) {
          print "  ⚠ EVENT-sem-efeito: " id " (não origina aresta nem dispara TRANSITIONS via on:)"; warns++
        }
        # 3. STATE-sem-dona: estado que nenhuma entity possui via HAS_STATE
        if (ntype[id] == "state" && ownedState[id] == 0) {
          print "  ⚠ STATE-sem-dona: " id " (nenhuma entity o possui via HAS_STATE)"; warns++
        }
        # 4. RULE-sem-trace: regra/invariante/política não ancorada no código
        if ((ntype[id] == "rule" || ntype[id] == "invariant" || ntype[id] == "policy") && traceOut[id] == 0) {
          print "  ⚠ RULE-sem-trace: " id " (sem TRACES_TO — regra não ancorada em artefato)"; warns++
        }
        # 5. fonte-única: nó de domínio lendo de 2+ fontes (ADR design-extends-kg — atom-map)
        if (readsOut[id] > 1) {
          print "  ⚠ fonte-única violada: " id " (" readsOut[id] " arestas READS saindo — 1 átomo = 1 fonte)"; warns++
        }
      }
      if (warns == 0) print "  ✅ camada domain completa (sem lacunas nas 5 checagens)"
      print ""
    }
  }

  if (mode == "--all" || mode == "--provenance") {
    print "══ PROVENIÊNCIA — decisão ancorada em origem (⚠ atenção, não reprova) ══"
    # Completude da camada AUDIT: uma decisão deveria apontar PARA a sua origem — a aresta
    # TRACES_TO (ADR/artefato) ou a migalha `trace: arquivo:linha` inline. Sem NENHUMA das
    # duas, a decisão é uma afirmação sem chão: quem lê não consegue voltar ao "porquê". É
    # AVISO (não toca `problems`, não muda o exit) — o oposto do falso-verde: barulho honesto
    # sobre uma lacuna, não uma reprovação.
    pwarns = 0; ndec = 0
    for (i = 1; i <= nn; i++) {
      id = order[i]
      if (ntype[id] != "decision") continue
      # Decisão reconciliada (superseded/refuted) é HISTÓRIA, não SSOT viva — cobrar a origem
      # dela é ruído que treina o leitor a ignorar o aviso (mesmo racional do FRESCOR, dogfood
      # 2026-07-17). A guarda mira a decisão VIVA sem chão.
      if (nstatus[id] == "superseded" || nstatus[id] == "refuted") continue
      ndec++
      if (traceOut[id] == 0 && traceInline[id] == "") {
        print "  ⚠ decisão-sem-proveniência: " id " (sem aresta TRACES_TO nem campo trace: inline — origem não ancorada)"; pwarns++
      }
    }
    if (ndec == 0) print "  (nenhuma decisão viva no grafo — nada a verificar)"
    else if (pwarns == 0) print "  ✅ " ndec " decisão(ões) viva(s) com proveniência ancorada"
    print ""
  }

  if (mode == "--all" || mode == "--schema") {
    print "══ SCHEMA — versão da gramática do .kg.yaml (✗ reprova na divergência) ══"
    if (metaSchema == "") {
      print "  ⚠ schema_version ausente no meta: — declare schema_version: \"" radarSchema "\" (retrocompat: aceito por ora)"
    } else if (metaSchema != radarSchema) {
      print "  ✗ schema_version divergente: arquivo declara [" metaSchema "], radar entende [" radarSchema "] — rode kg migrate ou atualize o radar"
      problems++
    } else {
      print "  ✅ schema_version " metaSchema " (bate com o radar)"
    }
    print ""
  }

  if (mode == "--all" || mode == "--freshness") {
    print "══ FRESCOR — SSOT re-verificada contra o vivo (⚠ atenção, não reprova) ══"
    # Rastreado por frescor = plane:PROD (alvo implícito: o artefato vivo) OU qualquer nó que
    # declare verified_against: (opt-in — nomeia o artefato MÓVEL que rastreia: branch/commit/
    # deploy/config). Um nó DEV que aponta p/ branch/commit também apodrece (sinal de campo
    # ssot-como-runtime, §2: C_CONSOLIDATION_MAP stale). Não inunda claims epistêmicos comuns.
    fwarns = 0; ntracked = 0
    for (i = 1; i <= nn; i++) {
      id = order[i]
      if (plane[id] != "PROD" && verifiedAgainst[id] == "") continue
      # Nó já reconciliado (superseded/refuted) é HISTÓRIA, não SSOT viva: append-mostly o mantém
      # para auditoria, mas ninguém raciocina a partir dele — cobrar re-verificação é ruído que
      # treina o leitor a ignorar o aviso. Achado de dogfood (2026-07-17, re-verificação dos 24
      # nós de identidade): 4 nós recém-supersededos seguiam sendo cobrados.
      if (nstatus[id] == "superseded" || nstatus[id] == "refuted") continue
      ntracked++
      if (verifiedAt[id] == "") {
        print "  ⚠ STALE-MISSING: " id " (frescor rastreado — plane:PROD ou verified_against: — sem verified_at:; re-verifique contra o vivo)"; fwarns++
      } else if (metaBaseline != "" && verifiedAt[id] "" < metaBaseline "") {
        print "  ⚠ STALE-OLD: " id " (verified_at " verifiedAt[id] " anterior à baseline " metaBaseline " — a verdade pode ter envelhecido)"; fwarns++
      }
    }
    if (ntracked == 0) print "  (nenhum nó com frescor rastreado — nada a verificar)"
    else if (fwarns == 0) print "  ✅ " ntracked " nó(s) com frescor declarado" (metaBaseline != "" ? " (baseline " metaBaseline ")" : "")
    print ""
  }

  if (mode == "--all" || mode == "--integrity") {
    print "══ INTEGRIDADE ══"
    for (id in dup) { print "  ✗ id duplicado: " id; problems++ }
    for (i = 1; i <= ne; i++) {
      if (!(efrom[i] in nodeSeen)) { print "  ✗ aresta " i ": from aponta nó inexistente: " efrom[i]; problems++ }
      if (!(eto[i]   in nodeSeen)) { print "  ✗ aresta " i ": to aponta nó inexistente: " eto[i]; problems++ }
      if (index(VE, etype[i]) == 0 || etype[i] == "") { print "  ✗ aresta " i ": edge_type inválido: [" etype[i] "]"; problems++ }
      if (eon[i] != "" && !(eon[i] in nodeSeen)) { print "  ✗ aresta " i ": on aponta evento inexistente: " eon[i]; problems++ }
    }
    for (i = 1; i <= nn; i++) {
      id = order[i]
      if (deg[id] == 0) { print "  ✗ nó órfão (grau 0): " id; problems++ }
      if (index(VN, ntype[id]) == 0 || ntype[id] == "") { print "  ✗ " id ": node_type inválido: [" ntype[id] "]"; problems++ }
      if (index(VP, plane[id]) == 0 || plane[id] == "") { print "  ✗ " id ": plane inválido: [" plane[id] "]"; problems++ }
      if (index(VL, layer[id]) == 0) { print "  ✗ " id ": layer inválido: [" layer[id] "]"; problems++ }
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