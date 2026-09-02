#!/usr/bin/env bash
# kg-radar.sh — radar determinístico do Knowledge Graph SDAAL (motor soberano do core).
#
# Uso: bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo.kg.yaml> [--radar|--state|--reconcile|--integrity|--domain|--provenance|--freshness|--freshness-tsv|--open-tsv|--weights-tsv|--schema|--triples]
#      (sem flag = radar + state + reconcile + integrity + domain + provenance + freshness + schema)
#
# Doutrina: ${CLAUDE_PLUGIN_ROOT}/kb/knowledge-graph-sdaal.md
#   RADAR           = atenção — peso do nó × centralidade (grau).
#                     peso = impact(1-5) × confidence(0-1) × fator de status
#                     fator: open=1.0 · confirmed=1.0 · drifted=1.3 (SOBE — mediu e divergiu)
#                            unverifiable=1.0 · refuted=0 · superseded=0.2 · done=0.1
#   ESTADO          = a FILA DE ABERTOS — o que segue `open` neste grafo, por atenção.
#                     É o irmão do RADAR, pedido em 2026-07-16 e construído em 2026-08-06.
#                     POR QUE NÃO É REDUNDANTE COM O RADAR (medido antes de escrever): das 79
#                     `question` abertas nos grafos ativos, só 21 (26%) aparecem no top-10 do
#                     --radar; 58 (73%) são INVISÍVEIS hoje. Nos dois maiores grafos ativos,
#                     1 de 16 e 1 de 13. A fórmula de atenção favorece nó `confirmed` bem
#                     conectado, e afunda justamente o que ainda está aberto.
#                     POR QUE MODO, E NÃO SCRIPT NOVO: um `kg-state.sh` seria o TERCEIRO parser
#                     de YAML do repo, e kg-view.sh:17-31 já escreveu essa dívida em letra
#                     grande ("DOIS PARSERS, DUAS VERDADES… mentira com cara de relatório").
#                     POR QUE UM GRAFO POR VEZ: a fila cross-grafo nasce MURO — 319 dos 571
#                     nós `open` do corpus vivem num único arquivo de reconciliação, que
#                     sessão nenhuma abre. Por grafo: mediana 4, e o top-7 cobre 100% de 37
#                     dos 43 grafos com aberto (86%).
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
#                     anterior à meta.baseline) · UNANCHORED (node_type: claim com verified_at:
#                     mas SEM verified_against: — carimbo sem alvo declarado; os demais tipos
#                     ancoram por trace:/TRACES_TO e não são cobrados) · MISPLANED (plane:PROD
#                     com verified_against: branch|commit — o nó afirma sobre o VIVO e declara
#                     ter olhado a FONTE; contradição interna, vale p/ TODOS os tipos).
#                     Determinístico: compara duas datas / dois campos do arquivo, sem "agora"
#                     (ADR onion-adr-kg-freshness-gate, proposta #2 (dogfood de campo)).
#   SCHEMA          = versão de schema (✗ REPROVA na divergência — radar não sabe ler o arquivo):
#                     meta.schema_version ≠ a versão que o radar entende → recusa; ausente → ⚠
#                     retrocompat (ADR onion-adr-kg-freshness-gate, proposta #1).
#   FRESCOR-TSV     = a FILA de re-verificação, legível por máquina (irmão do FRESCOR, como
#                     TRIPLES é do grafo): 1 linha/nó vivo rastreado, ordenada por atenção.
#                     Colunas: id·node_type·plane·status·impact·confidence·atenção·verified_at·
#                     verified_against·trace·verdict. Escopo NÃO é "o flagado" — nó com verdict
#                     OK entra igual (o caso que criou o fluxo mente COM carimbo do dia).
#   FILA-ABERTA-TSV = a FILA COMPLETA de trabalho aberto, legível por máquina (irmão-máquina do
#                     ESTADO, `--open-tsv`). Existe porque o ESTADO não pode servir a este
#                     consumidor: ele EXCLUI o top-10 do radar (o que o faz complementar, e está
#                     certo lá) e TRUNCA em 7 (display humano). Medido no corpus: 584 nós de
#                     trabalho aberto em 46 grafos, e o único modo de leitura mostrava SETE.
#                     Colunas: arquivo·id·node_type·plane·status·impact·confidence·atenção·
#                     verified_at·trace·VEREDITO·label. A 1ª é o ARQUIVO porque o radar lê um grafo
#                     por vez (arestas não cruzam arquivo) e a fila do corpus é o laço de quem chama.
#                     ESCOPO por DENYLIST (`trabalhoPendente`): fora só `confirmed`/`done`/
#                     `superseded`/`refuted`. `drifted` e `unverifiable` ENTRAM — são reconciliação
#                     DEVIDA, e eram exatamente o que a allowlist do ESTADO perdia em silêncio.
#                     VEREDITO: `STATUS-DESCONHECIDO` (fora do enum) · `SEM-STATUS` · `-`. Status
#                     fora do enum recebe fator 1.3 e SOBE — clamp em 0 o mandava para o fim da
#                     fila, que é onde o `--top N` corta: promessa de fail-visible entregando
#                     fail-quiet por afundamento.
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

# SITIO UNICO do fator de status. FAIL-LOUD se faltar: fonte ausente nunca vira aprovacao.
_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/status-factor.awk"
[ -f "${_LIB}" ] || { echo "kg-radar: lib/status-factor.awk AUSENTE (${_LIB}) — o fator de status vive la, e sem ele o radar nao sabe pesar nada." >&2; exit 2; }
STATUS_FACTOR="$(cat "${_LIB}")"

FILE="${1:-}"
MODE="${2:---all}"
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "uso: kg-radar.sh <arquivo.kg.yaml> [--radar|--state|--reconcile|--integrity|--domain|--provenance|--freshness|--freshness-tsv|--open-tsv|--weights-tsv|--schema|--triples]" >&2; exit 2; }

awk -v mode="$MODE" -v radarSchema="$RADAR_SCHEMA" -v arq="$FILE" "${STATUS_FACTOR}"'
# ── DENYLIST, NÃO ALLOWLIST — a lição de 2026-08-07 ─────────────────────────────────────────
# Quando `drifted`/`unverifiable` entraram (2026-08-06), os predicados escritos como ALLOWLIST
# (`== "confirmed"`, `confirmed || open`) os deixaram de fora EM SILÊNCIO, enquanto os escritos
# como DENYLIST os trataram certo POR CONSTRUÇÃO — as três denylists corretas se acham grepando
# pela string  nstatus[id] == "superseded" || nstatus[id] == "refuted"  (FRESCOR, PROVENIÊNCIA,
# FRESCOR-TSV).
# ⚠️ SEM ASPAS SIMPLES NESTE ARQUIVO: o programa awk inteiro vive dentro de aspas simples do
# shell, então uma aspa simples num COMENTÁRIO termina o programa cedo — o radar passa a imprimir
# NADA com exit 0. Aconteceu aqui, escrevendo justamente o comentário sobre fail-open, e `bash -n`
# não pega. Só a CONTAGEM de linhas de saída pega.
# Âncora de grep e não número de linha DE PROPÓSITO: a 1ª versão deste bloco citou
# "linhas 274/452/490" e elas apodreceram NA PRÓPRIA INSERÇÃO que as escreveu — o comentário é o
# artefato durável desta mudança e nasceu mentindo, num commit cuja tese é "o texto declara uma
# coisa e o artefato faz outra". Achado pelo Elenxo 2026-08-07.
#
# Um enum que CRESCE quebra allowlist e não quebra denylist — então o predicado nomeia quem NÃO
# conta, e todo status futuro entra por default.
#
# O QUE O CORPUS PROVA, E O QUE NÃO PROVA (medido 2026-08-07, e a 1ª versão exagerou):
#   · a mudança é INERTE no corpus — 0 avisos novos. Mas o corpus NÃO distingue esta fronteira
#     de quase nenhuma outra: mesmo `supersederConta(s){return 1}` dá 0 avisos, porque os 137
#     alvos de SUPERSEDES já estão todos reconciliados (113 superseded · 13 refuted · 11 done) e
#     os 116 de REFUTES também. A prova de COMPORTAMENTO é a fixture, não o corpus.
#   · a única alavanca que o corpus expõe é `done` no lado do alvo: 11 acusações — e as 11 são
#     `question`, o que virou a exclusão TIPADA abaixo.
#   · efeito interno: `supersededByLive` passa a contar 119 arestas em vez de 102 (+17, os
#     supersedes de origem `done`), todas inertes hoje porque apontam para alvos já mortos.
#   · o fail-open é LATENTE, não histórico: 0 nós `drifted` em 2.095, e 0 supersederes
#     `drifted`/`unverifiable` em 137 arestas. Ele foi demonstrado NA FIXTURE, não no campo.

# O SUPERSEDER conta? Fora: `open` (relação ainda não assentada — justificativa original de
# 2026-08-05, 1 caso medido: E_engine_measured) e os mortos (`refuted`/`superseded`), cuja
# própria superação é duvidosa. Dentro: confirmed · drifted · unverifiable · done.
# `drifted` é o caso que motivou isto: statusFactor lhe dá 1.3 dizendo "nó VIVO, mais urgente que
# confirmed", e a allowlist antiga dizia "não é confirmed, logo não conta" — duas doutrinas no
# mesmo arquivo. O efeito era fail-open: a aresta sumia e a seção imprimia ✅ sem ter avaliado.
function supersederConta(s) { return (s != "open" && s != "refuted" && s != "superseded") }

# O ALVO ainda precisa reconciliar? Fora: `superseded`/`refuted` (já reconciliados) e a
# `question` fechada como `done` — que é o remédio que ESTA MESMA seção prescreve ("pergunta
# RESPONDIDA … fechar como `done`"); cobrá-la seria o gate punindo quem obedeceu.
#
# A EXCLUSÃO É POR TIPO, NÃO POR STATUS, e a 1ª versão errou nisso (Elenxo 2026-08-07). Excluir
# `done` de todos os tipos calava um caso com a assinatura EXATA do defeito que este arquivo
# cura: uma `decision` fechada, superada por nó vivo, saía com "✅ nenhum alvo por reconciliar".
# Medido: dos 11 alvos `done` do corpus, 11 são `question` — a exclusão tipada tem churn ZERO e
# fecha o buraco. A razão antiga ("criaria 11 acusações novas") era CONVENIÊNCIA ocupando o lugar
# do critério: verdadeira no número, errada no motivo.
function pendingTarget(s, t) { return (s != "superseded" && s != "refuted" && !(s == "done" && t == "question")) }

# O nó ainda é TRABALHO por fazer? Pergunta DIFERENTE das duas acima (que são sobre reconciliação),
# por isso predicado próprio — o pecado é a MESMA pergunta respondida em dois lugares, não perguntas
# distintas com nomes distintos.
#
# ⚠️ DENYLIST, e a forma importa mais que a lista. O `--state` nasceu com ALLOWLIST
# (`nstatus[id] != "open"`), e em 2026-08-06 o enum cresceu POR BAIXO dela: `drifted` e
# `unverifiable` são a saída do `/meta:kg-freshness` e significam **reconciliação DEVIDA** — o
# trabalho mais urgente que existe. A allowlist os descartava em silêncio, e a fila de abertos ficava
# cega justamente para o que acabou de provar que o mundo andou. Era o 4º sítio da mesma classe
# (C_ALLOWLIST_QUEBRA_COM_ENUM_QUE_CRESCE, elenxos-2026-08-07); os outros três já foram curados.
# Com denylist, um status NOVO entra na fila por default: fail-visible em vez de fail-open.
function trabalhoPendente(s) { return (s != "confirmed" && s != "done" && s != "superseded" && s != "refuted") }

function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); gsub(/^["'\'']|["'\'']$/, "", s); return s }

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
  # ── CAMPO SÓ EM POSIÇÃO DE CAMPO (âncora ^[[:space:]]*<campo>:) ──────────────────────────────
  # O parser é line-based: um match SOLTO (`line ~ /layer:/` + `sub(/.*layer:/…)`) lê CONTEÚDO como
  # CONFIGURAÇÃO — basta um label citar o token. Real, não hipotético:
  #     label: "66 nos, TODOS layer:audit, ZERO domain"
  # virava `✗ layer inválido: [audit, ZERO domain]` e REPROVAVA um grafo correto. A defesa já
  # existia — mas só para `trace:` (comentário abaixo) — e ficou fechada em 1 de 7 campos. Agora
  # a ancoragem cobre a classe inteira EM TODAS AS SEÇÕES: `nodes` (node_type/plane/layer/impact/
  # confidence/status/verified_*/label), `edges` (to/edge_type/on) e `meta` (schema_version/baseline).
  # Crédito: sinal de campo da estrela onion-pessoal-app (2026-07-19), que pushou um grafo quebrado
  # exatamente por isto — um repo que FALA de layers/status escreve esses tokens em prosa o tempo todo.
  # Âncora também no `sub`: casar ancorado e extrair solto (`.*campo:`) recortaria pela ÚLTIMA
  # ocorrência da linha, devolvendo o rabo do label quando o valor cita o próprio token.
  if (line ~ /^[[:space:]]*node_type:/)  { v = line; sub(/^[[:space:]]*node_type:/, "", v);  ntype[nid] = trim(v) }
  if (line ~ /^[[:space:]]*plane:/)      { v = line; sub(/^[[:space:]]*plane:/, "", v);      plane[nid] = trim(v) }
  if (line ~ /^[[:space:]]*layer:/)      { v = line; sub(/^[[:space:]]*layer:/, "", v);      layer[nid] = trim(v) }
  if (line ~ /^[[:space:]]*impact:/)     { v = line; sub(/^[[:space:]]*impact:/, "", v);     impact[nid] = trim(v) + 0 }
  if (line ~ /^[[:space:]]*confidence:/) { v = line; sub(/^[[:space:]]*confidence:/, "", v); conf[nid] = trim(v) + 0 }
  if (line ~ /^[[:space:]]*status:/)     { v = line; sub(/^[[:space:]]*status:/, "", v);     nstatus[nid] = trim(v) }
  # evidence_class (opt-in, 2026-09-02, Q_TESTEMUNHO_NAO_MEDIVEL_0804): `testimony` marca o nó cuja
  # fonte é RELATO (intenção, fato de campo fora do repo) — a única checagem disponível é o texto
  # que codificou o relato, circular por construção. Sem o marcador, esses nós passavam nos três
  # vereditos com carimbo fresco, indistinguíveis de um nó medido. Default (ausente) = measured.
  if (line ~ /^[[:space:]]*evidence_class:/) { v = line; sub(/^[[:space:]]*evidence_class:/, "", v); eclass[nid] = trim(v) }
  if (line ~ /^[[:space:]]*verified_against:/) {
    v = line; sub(/^[[:space:]]*verified_against:/, "", v)
    if (nid in verifiedAgainst && verifiedAgainst[nid] != trim(v)) dupKey[nid "|verified_against"] = verifiedAgainst[nid] " -> " trim(v)
    verifiedAgainst[nid] = trim(v)
  }
  else if (line ~ /^[[:space:]]*verified_at:/) {
    v = line; sub(/^[[:space:]]*verified_at:/, "", v)
    # CHAVE REPETIDA: atribuição simples faz a ÚLTIMA vencer, em SILÊNCIO. Medido em 2026-08-12:
    # cinco nós deste repo carregavam DUAS linhas `verified_at:` (08-10 e 08-11) porque um carimbo
    # aplicado à mão INSERIU em vez de SUBSTITUIR. O comportamento estava correto POR ACIDENTE — o
    # arquivo afirmava duas verdades e nenhuma guarda olhava para isso (nem --integrity, nem
    # --schema, nem o lint). Registrar em vez de sobrescrever calado: o próximo carimbo ingênuo
    # criaria uma TERCEIRA linha e o grafo continuaria "verde".
    if (nid in verifiedAt && verifiedAt[nid] != trim(v)) dupKey[nid "|verified_at"] = verifiedAt[nid] " -> " trim(v)
    verifiedAt[nid] = trim(v)
  }
  # Proveniência inline: a MIGALHA `arquivo:linha` (suporte de campo 2026-07-17). Âncora
  # em ^…trace: — um match solto casaria com label que cita "trace:"/"TRACES_TO" (este repo fala
  # de rastreabilidade sobre si mesmo), false-positivando a origem. Foi o PROTÓTIPO da defesa acima.
  if (line ~ /^[[:space:]]*trace:/) { v = line; sub(/^[[:space:]]*trace:/, "", v); traceInline[nid] = trim(v) }
  # label: lê de $0 (não de `line`) de propósito — o texto do label pode conter `#` legítimo, e a
  # poda de comentário o truncaria. Match agora ancorado como os demais (antes casava solto e só o
  # sub era ancorado: numa linha de OUTRO campo que citasse "label:", o valor virava a linha inteira).
  if ($0 ~ /^[[:space:]]*label:/) { v = $0; sub(/^[[:space:]]*label:/, "", v); label[nid] = trim(v) }
  next
}

section == "edges" && /^[[:space:]]+- from:/ {
  ne++
  v = trim($0); sub(/^- from:/, "", v); efrom[ne] = trim(v)
  next
}
# ARESTAS/META — mesma ancoragem dos nós (2ª metade do fix; a 1ª cobriu só a seção `nodes`).
# Dois vetores reais que o match solto abria aqui:
#   (a) `to: D_migrate_to:v2` — `sub(/.*to:/)` recorta na ÚLTIMA ocorrência e devolve "v2":
#       nó inexistente → falso "aresta para nó inexistente" reprovando um grafo correto;
#   (b) `/on:/` casava QUALQUER linha contendo "on:" como substring — inclusive `reason:`
#       (reas·on:), que é campo válido da migalha TRACES_TO. Bastava uma aresta com `reason:`
#       para o atributo `on:` (evento gatilho de TRANSITIONS) ser lido do campo errado.
# Ancorar em posição de campo mata os dois. (O antigo `!/edge_type/` virou redundante: uma linha
# `edge_type:` não casa `^[[:space:]]*to:`.)
section == "edges" && /^[[:space:]]*to:/ { v = $0; sub(/^[[:space:]]*to:/, "", v); eto[ne] = trim(v); next }
section == "edges" && /^[[:space:]]*edge_type:/ { v = $0; sub(/^[[:space:]]*edge_type:/, "", v); etype[ne] = trim(v); next }
section == "edges" && /^[[:space:]]*on:/ { v = $0; sub(/^[[:space:]]*on:/, "", v); eon[ne] = trim(v); next }

# meta: campos de governança de frescor/schema (proposta #1/#2 — ADR kg-freshness-gate)
section == "meta" && /^[[:space:]]*schema_version:/ { v = $0; sub(/^[[:space:]]*schema_version:/, "", v); metaSchema = trim(v); next }
section == "meta" && /^[[:space:]]*baseline:/       { v = $0; sub(/^[[:space:]]*baseline:/, "", v);       metaBaseline = trim(v); next }

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
    # SUPERSEDES só ACUSA se o superseder está VIVO — ver supersederConta(). Superseder `open`
    # significa relação ainda não assentada, e o alvo legitimamente segue confirmado até que ela
    # assente (medido 2026-08-05: dos 15 alvos não-reconciliados do corpus, 1 — E_engine_measured —
    # tinha superseder `open`; acusá-lo seria cobrar reconciliação de superação que ninguém fechou).
    # Era ALLOWLIST de um valor até 2026-08-07, e por isso engolia superseder `drifted` — defeito
    # LATENTE (0 ocorrências no corpus), demonstrado na fixture supersedes-mixed, não em campo.
    if (etype[i] == "SUPERSEDES" && supersederConta(nstatus[efrom[i]])) supersededByLive[eto[i]]++
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

  # Irmão-MÁQUINA do --freshness (como --triples é do grafo): a fila de re-verificação, em TSV.
  # Existe porque a saída humana do --freshness é prosa pt-BR com emoji — parseá-la para
  # alimentar um fluxo seria frágil por construção. Uma linha por nó frescor-rastreado e VIVO.
  #
  # ORDEM: atenção desc — MESMA fórmula do --radar (impact × confidence × statusFactor × (1+grau)).
  # A decisão que carrega peso aqui: o escopo NÃO é "o que o radar flagou". O caso que motivou o
  # fluxo (C_ancestor_cap_zeroes_floors do grafo do M2) tem verdict OK — carimbo do dia, alvo
  # declarado, os três vereditos passam — e MENTE assim mesmo. Filtrar por flagado nasceria cego
  # ao caso fundador. O carimbo diz se a SSOT está bem-formada; a atenção diz o que custa caro
  # estar errado. Re-verifica-se pelo CUSTO DO ERRO, não pela ausência do carimbo.
  if (mode == "--freshness-tsv") {
    # PRIMEIRA PASSADA — calcula atenção e ELEGE quem entra. A segunda passada emite ORDENADO.
    # POR QUE EXISTE (achado de revisão adversarial, 2026-08-06): o cabeçalho deste bloco DECLARA
    # "ORDEM: atenção desc — MESMA fórmula do --radar" desde que nasceu, e a implementação iterava
    # `order[i]` — ORDEM DE ARQUIVO. O `asorti()` só existia no --radar. Ou seja: o instrumento que
    # esta casa usa para medir declarado-vs-verificado tinha, ele mesmo, uma declaração não
    # verificada. Medido no grafo da VPS: ENT_logto (14.25) saía ANTES de ENT_whatsapp (14.40).
    # O dano não é cosmético: quem consome a fila corta em --top N, e um corte sobre ordem errada
    # descarta o nó de MAIOR atenção. E numa corrida serial a ordem decide qual worker aprende
    # primeiro — foi essa ambiguidade que quase inverteu a conclusão do M8.
    for (i = 1; i <= nn; i++) {
      id = order[i]
      if (plane[id] != "PROD" && verifiedAgainst[id] == "") continue
      if (nstatus[id] == "superseded" || nstatus[id] == "refuted") continue   # história, não SSOT viva
      sf = statusFactor(nstatus[id]); if (sf < 0) sf = 0
      att[id] = impact[id] * conf[id] * sf * (1 + deg[id])
      elegivel[id] = 1
    }
    fn = asorti(att, fsorted, "@val_num_desc")
    for (i = 1; i <= fn; i++) {
      id = fsorted[i]
      if (!(id in elegivel)) continue
      if (verifiedAt[id] == "") verdict = "STALE-MISSING"
      else if (eclass[id] == "testimony") verdict = "TESTIMONY"   # não re-verificável por máquina — consumidor NÃO enfileira
      else if (verifiedAgainst[id] == "" && ntype[id] == "claim") verdict = "UNANCHORED"
      else if (metaBaseline != "" && verifiedAt[id] "" < metaBaseline "") verdict = "STALE-OLD"
      else verdict = "OK"
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%.2f\t%s\t%s\t%s\t%s\n",
        id, ntype[id], plane[id], nstatus[id], impact[id], conf[id], att[id],
        (verifiedAt[id] == "" ? "-" : verifiedAt[id]),
        (verifiedAgainst[id] == "" ? "-" : verifiedAgainst[id]),
        (traceInline[id] == "" ? "-" : traceInline[id]),
        verdict
    }
    exit 0
  }

  # ══ A FILA COMPLETA DE TRABALHO ABERTO, LEGÍVEL POR MÁQUINA ═══════════════════════════════════
  # Irmão-MÁQUINA do `--state`, como o `--freshness-tsv` é do `--freshness`. E existe porque o
  # `--state` NÃO PODE servir a este consumidor, por duas decisões que estão CERTAS lá e são
  # venenosas aqui:
  #   · ele EXCLUI o top-10 do radar por construção (é o que o faz complementar, e está escrito no
  #     bloco dele que sem isso 51% da saída — e 100% num grafo — repetia o radar);
  #   · ele TRUNCA em 7 linhas, porque é display humano.
  # Medido no corpus: 584 nós de trabalho aberto em 46 grafos, e o único modo de leitura mostra 7.
  # Navegar o próprio backlog era impossível, e toda priorização feita assim era opinião.
  #
  # ORDEM: atenção desc — MESMA fórmula do `--radar`, e pelo mesmo motivo do `--freshness-tsv`:
  # quem consome uma fila corta em `--top N`, e corte sobre ordem errada descarta o de maior peso.
  #
  # ESCOPO POR ARQUIVO, de propósito: o radar lê um grafo por vez (arestas não cruzam arquivo). A
  # fila do corpus é o laço de quem chama — por isso a 1ª coluna é o ARQUIVO, sem a qual o id
  # sozinho não localiza nada num corpus de 57 grafos.
  if (mode == "--open-tsv") {
    for (i = 1; i <= nn; i++) {
      id = order[i]
      if (!trabalhoPendente(nstatus[id])) continue
      # ⚠️ STATUS DESCONHECIDO SOBE, NAO AFUNDA — e a diferenca entre fail-visible e fail-quiet.
      # O comentario do `trabalhoPendente` promete que "um status NOVO entra na fila por default".
      # Ele entrava — e o clamp em 0 o mandava para o FIM da fila ordenada por atencao, que e
      # exatamente onde o `--top N` corta. Medido: no com `status: blocked` e impact 5 saia em 16o de
      # 17, abaixo de nos de impact 1. Promessa de visibilidade entregando invisibilidade por
      # afundamento — o mesmo modo de falha que o comentario do `refuted` neste arquivo ja nomeia
      # ("apaga o sinal em vez de perde-lo"). 1.3 e a MESMA escolha ja tomada para `drifted`, e pelo
      # mesmo motivo: status fora do enum e pergunta aberta sobre o proprio enum.
      # Escopo LOCAL ao --open-tsv de proposito: mexer no clamp do --radar/--state mudaria a janela
      # de top-10 e quebraria a complementaridade que funda o --state.
      sf3 = statusFactor(nstatus[id]); if (sf3 < 0) sf3 = 1.3
      oatt[id] = impact[id] * conf[id] * sf3 * (1 + deg[id])
      oelegivel[id] = 1
    }
    on = asorti(oatt, osorted, "@val_num_desc")
    for (i = 1; i <= on; i++) {
      id = osorted[i]
      if (!(id in oelegivel)) continue
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%.2f\t%s\t%s\t%s\t%s\n",
        arq, id, ntype[id], (plane[id]=="" ? "-" : plane[id]), (nstatus[id]=="" ? "-" : nstatus[id]), impact[id], conf[id], oatt[id],
        (verifiedAt[id] == "" ? "-" : verifiedAt[id]),
        (traceInline[id] == "" ? "-" : traceInline[id]),
        (nstatus[id] == "" ? "SEM-STATUS" : (statusFactor(nstatus[id]) < 0 ? "STATUS-DESCONHECIDO" : "-")),
        label[id]
    }
    exit 0
  }

  # ══ O VETOR DE PESOS — TODOS os nós, para comparação entre motores ═══════════════════════════
  # Nasceu de uma passada adversarial que derrubou a versão anterior da paridade do `kg-view`, e o
  # que ela derrubou vale escrito porque é uma armadilha geral, não um bug local: comparar duas
  # implementações por um ESCALAR AGREGADO (a soma dos pesos) não prova que elas concordam.
  #   · o cancelamento é EXPLORÁVEL, e foi medido: uma lente que troca os pesos de dois nós inverte
  #     a ORDEM DE URGÊNCIA e a soma continua idêntica — 10.40+8.00 == 8.00+10.40, guarda VERDE;
  #   · e a soma só cobria os nós EM ABERTO: 4 dos 7 valores do enum (`confirmed`/`done`/
  #     `superseded`/`refuted`) ficavam fora, então divergir neles saía verde por construção.
  # Por isso aqui é VETOR, e é o corpo INTEIRO: quem compara faz `diff` das duas listas e qualquer
  # divergência aparece com o id ao lado. De quebra some a razão de o consumidor replicar a denylist
  # de escopo — cópia de regra que existia só para poder somar.
  #
  # ORDEM POR ID (não por atenção): o consumidor é `diff`, que precisa de ordem ESTÁVEL. Ordenar por
  # peso faria uma divergência de peso deslocar todas as linhas seguintes e o diff apontaria o
  # arquivo inteiro em vez do nó culpado.
  # CLAMP EM 0, como o `--radar` e como a lente — NÃO o 1.3 do `--open-tsv`. O 1.3 é declaradamente
  # LOCAL à fila (fazer status desconhecido SUBIR em vez de afundar onde o `--top N` corta); aqui o
  # consumidor é a paridade, que compara a lente contra o PAINEL. Usar 1.3 faria toda divergência de
  # status-fora-do-enum acusar peso, sem que nenhuma das duas implementações estivesse errada.
  if (mode == "--weights-tsv") {
    for (i = 1; i <= nn; i++) {
      id = order[i]; sfw = statusFactor(nstatus[id]); if (sfw < 0) sfw = 0
      watt[id] = impact[id] * conf[id] * sfw * (1 + deg[id])
    }
    wn = asorti(watt, wsorted, "@ind_str_asc")
    for (i = 1; i <= wn; i++) printf "%s\t%.2f\n", wsorted[i], watt[wsorted[i]]
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

  # ESTADO — a fila de abertos. Irmão do RADAR: mesma fórmula de atenção, escopo invertido.
  # O RADAR responde "o que pesa"; o ESTADO responde "o que falta". Um nó `confirmed` de impacto 5
  # domina o primeiro e não tem nada a fazer no segundo.
  #
  # APOSTA DECLARADA (2026-08-06) — este modo não nasce de pull medido, e sim da convicção de que
  # a sessão que abre um grafo quer ver o que segue aberto nele. O que o mataria está escrito:
  # 5 aberturas de sessão com o --state na saída e ZERO id citado seguido de ação. Nesse caso o
  # modo sai do caminho padrão (do --all) e o aprendizado e que `status: open` e RESIDUO, nao
  # estado de trabalho — o que mataria a classe inteira "projetar estado a partir de status".
  # A EXCLUSÃO DO TOP-10 NÃO É DETALHE — É O QUE FAZ O MODO EXISTIR. Medido na 1ª versão, que
  # ordenava todos os `open` por atenção: 51% do que ela exibia JÁ estava no --radar, e num grafo
  # (m3-federation-admin) a sobreposição era de 100%. Ordenar por atenção traz de volta os mesmos
  # nós pesados que o radar mostra — o modo virava vista filtrada do que já se via. Excluindo o
  # top-10 por construção, o ESTADO passa a ser 100% complementar: só o que o radar AFUNDA.
  if (mode == "--all" || mode == "--state") {
    print "══ ESTADO — a fila de abertos (o que o RADAR afunda) ══"
    for (i = 1; i <= nn; i++) {                       # atenção de TODOS (o --radar pode não ter rodado)
      id = order[i]; sf2 = statusFactor(nstatus[id]); if (sf2 < 0) sf2 = 0
      ratt[id] = impact[id] * conf[id] * sf2 * (1 + deg[id])
    }
    rn = asorti(ratt, rord, "@val_num_desc")
    rtop = (rn < 10) ? rn : 10
    for (i = 1; i <= rtop; i++) if (ratt[rord[i]] > 0) noRadar[rord[i]] = 1
    nopen = 0
    for (i = 1; i <= nn; i++) {
      id = order[i]
      if (!trabalhoPendente(nstatus[id])) continue    # DENYLIST: `drifted`/`unverifiable` SAO trabalho
      nopen++
      if (id in noRadar) continue                    # já visível no RADAR — não repetir
      satt[id] = ratt[id]
    }
    sn = asorti(satt, sord, "@val_num_desc")
    if (nopen == 0)      print "  ✅ nada em aberto neste grafo"
    else if (sn == 0)    printf "  ✅ os %d aberto(s) deste grafo já aparecem no RADAR acima\n", nopen
    else {
      stop = (sn < 7) ? sn : 7
      for (i = 1; i <= stop; i++) {
        id = sord[i]
        printf "  %5.1f  %-24s %s  %s\n", satt[id], id, ntype[id], label[id]
      }
      if (sn > stop) printf "  … e mais %d fora do radar — %d aberto(s) no total\n", sn - stop, nopen
    }
    print ""
    delete satt; delete sord; delete ratt; delete rord; delete noRadar
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

    # ⚠ ALVO NÃO-RECONCILIADO — o buraco que a INTEGRIDADE não cobre.
    #
    # POR QUE EXISTE (medido 2026-08-05): a linha 438 cobra contradição SÓ para REFUTES. SUPERSEDES
    # passa em silêncio — e de 137 arestas SUPERSEDES no corpus, 15 apontam para um alvo que segue
    # `confirmed` ou `open`. Duas decisões de impacto 5 vivem hoje superadas e confirmadas ao mesmo
    # tempo, sem um único aviso.
    #
    # POR QUE ⚠ E NÃO ✗ (a refutação que forjou esta forma): o remédio óbvio — virar o status —
    # PRODUZ DADO ERRADO em boa parte dos casos. `statusFactor(superseded)` = 0.2 corta 80% da
    # atenção e a linha 226 tira o nó do frescor; 6 dos 15 alvos estão no top-10 do próprio grafo e
    # sairiam. Há casos em que o superseder apenas REFINA (o alvo segue vigente — é `CONSTRAINS`,
    # já no enum da linha 148 e idioma dominante no grafo do M2: 43 CONSTRAINS contra 14 SUPERSEDES)
    # e casos em que o alvo era PERGUNTA respondida (fecha como `done`, não como história superada).
    # Um gate HARD que compra verde CORROMPENDO o grafo é o verde falso invertido. Por isso: nomeia,
    # não reprova. `problems` fica intocado.
    #
    # PROMOÇÃO A ✗ HARD: gated. Gatilho escrito — um 16º caso aparecer DEPOIS da triagem dos 15.
    swarn = 0
    for (i = 1; i <= nn; i++) {
      id = order[i]
      if (supersededByLive[id] > 0 && pendingTarget(nstatus[id], ntype[id])) {
        if (ntype[id] == "question")
          printf "  ⚠ %s: pergunta RESPONDIDA segue status=%s — fechar como `done` (respondida ≠ superada)\n", id, nstatus[id]
        else
          printf "  ⚠ %s: recebe SUPERSEDES e segue status=%s — reconciliar: `superseded` se deixou de valer · `CONSTRAINS` se o superseder apenas REFINA · ou justificar por escrito\n", id, nstatus[id]
        swarn++
      }
    }
    if (found && swarn == 0) print "  ✅ nenhum alvo de SUPERSEDES ficou por reconciliar"
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
    fwarns = 0; ntracked = 0; fsuppressed = 0; ftestimony = 0
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
      } else {
        # UNANCHORED — o carimbo existe mas NÃO diz contra O QUÊ. "Verificado" sem alvo
        # declarado é declaração, não verificação: o radar não consegue julgar a semântica,
        # mas pode EXIGIR que o alvo seja escrito — e é escrevendo-o que o desalinhamento
        # fica legível a quem lê. Sinal de campo 2026-07-25 (adotante): nós com plane:PROD e
        # verified_at "porque um curl respondera" — mas o curl mediu o CORE e a claim era
        # sobre o ADOTANTE. O carimbo estava no artefato errado, e nada no arquivo denunciava.
        # UNANCHORED cobra quem AFIRMA — não quem ANCORA, nem quem PERGUNTA. Whitelist por
        # `node_type: claim`, mesmo idioma do bloco PROVENIÊNCIA (que filtra por `decision`).
        # MEDIDO nos 22 grafos do core (2026-07-26): sem o filtro são 275 avisos, 170 deles em
        # tipos que JÁ carregam a âncora por outro campo — 114 `evidence` (a evidência É a
        # âncora; 101 delas já trazem `trace:`), 17 `decision` (a proveniência já é cobrada no
        # bloco acima: dois nomes para a mesma obrigação), 21 `entity` (domínio ancora por
        # `trace:` + READS/WRITES, o contrato do modo `map`), 15 `artifact` (o nó NOMEIA o
        # alvo — alvo do alvo é tautologia) e 3 `question` (pergunta não afirma).
        # 275 avisos treinam o leitor a ignorar: é o mesmo racional que já pula superseded/refuted.
        # A guarda vive AQUI, no ramo, e NÃO como `continue` no laço: STALE-MISSING e STALE-OLD
        # continuam valendo para TODOS os tipos. (Um `continue` quebraria os casos (b)/(c)/(f)
        # do selftest, cujos sujeitos são `state` e `decision` — a suíte é a guarda desta guarda.)
        # Whitelist, não blacklist: ntype vazio/inválido já REPROVA na INTEGRIDADE (VN, exit 1).
        if (verifiedAgainst[id] == "" && ntype[id] == "claim") {
          print "  ⚠ UNANCHORED: " id " (verified_at " verifiedAt[id] " SEM verified_against:; declare o ALVO da claim — carimbo sem alvo não distingue verificado de declarado)"; fwarns++
        } else if (verifiedAgainst[id] == "") {
          fsuppressed++   # supressão CONTADA, nunca silenciosa — ver linha-resumo abaixo
        }
        if (eclass[id] == "testimony") {
          # TESTEMUNHO: re-carimbar seria circular (a fonte é o relato). Não cobra STALE-OLD; CONTA
          # em linha própria para o leitor saber que o carimbo fresco NÃO é medição.
          ftestimony++
        } else if (metaBaseline != "" && verifiedAt[id] "" < metaBaseline "") {
          print "  ⚠ STALE-OLD: " id " (verified_at " verifiedAt[id] " anterior à baseline " metaBaseline " — a verdade pode ter envelhecido)"; fwarns++
        }
      }
      # TESTIMONY-UNMARKED — o alvo declarado É um relato (`relato-*`) mas o nó não se classifica:
      # continua a passar por medido. Determinístico: só o vocabulário já usado por esta casa.
      # Só o PRIMEIRO token do alvo, e só quando ele COMEÇA por `relato` — um carimbo de censo que
      # CITA "relato-do-maestro-*" no texto não é relato (guarda-por-lista falha pelo vocabulário:
      # no 1º dogfood o próprio nó da pergunta foi acusado por citar o padrão), e um alvo MISTO
      # cuja fonte primária é medida (`gh-api-...-e-relato-...`) segue medido: o relato ali apoia.
      va1 = verifiedAgainst[id]; sub(/[[:space:](].*$/, "", va1)
      if (eclass[id] != "testimony" && va1 ~ /^relato(-|_|$)/) {
        print "  ⚠ TESTIMONY-UNMARKED: " id " (verified_against: " verifiedAgainst[id] " é RELATO sem evidence_class: testimony — o carimbo passa por medição; classifique)"; fwarns++
      }
      # TESTEMUNHO + plane:PROD é a MESMA contradição do MISPLANED: PROD afirma "cruzei com o
      # artefato vivo"; relato não cruza com artefato nenhum.
      if (eclass[id] == "testimony" && plane[id] == "PROD") {
        print "  ⚠ MISPLANED: " id " (plane:PROD mas evidence_class: testimony — relato não é artefato vivo; reclassifique para plane:DEV)"; fwarns++
      }
      # MISPLANED — CONTRADIÇÃO INTERNA ao próprio nó, e vale para TODOS os tipos.
      # `plane: PROD` afirma "cruzei com o ARTEFATO VIVO"; `verified_against: branch|commit`
      # declara "olhei a FONTE". Os dois campos falam da mesma coisa (a natureza da evidência)
      # e até aqui o radar nunca os confrontava.
      # Crédito: sinal de campo de um adotante (2026-07-27), que MEDIU no próprio repo
      # 21 nós afirmando sobre produção com evidência de leitura de código — com o radar VERDE
      # o tempo todo. E o motivo de escapar era o filtro que eu mesmo shipei horas antes: o
      # UNANCHORED isenta os tipos não-claim ("ancoram por trace:/TRACES_TO"), e quase todos os
      # 21 eram `evidence`. Reduzir ruído cegou o gate para uma classe que ele nunca vira.
      # Por isso esta checagem NÃO se restringe a claim: a contradição não depende do tipo.
      # Determinística: dois campos do mesmo nó, sem rede, sem heurística, sem campo novo.
      # TETO DECLARADO (pelo próprio autor do sinal): audita a procedência DECLARADA, não se a
      # declaração é verdadeira — um nó que escreve `deploy` medindo bench local passa. Isso é
      # limite honesto, não defeito: fecha a contradição legível, não a mentira deliberada.
      # `pin` NÃO é cobrado de propósito: é ambíguo (ler o stamp do checkout vivo é PROD legítimo).
      if (plane[id] == "PROD" && verifiedAgainst[id] ~ /(^|[^a-zA-Z])(branch|commit)([^a-zA-Z]|$)/) {
        print "  ⚠ MISPLANED: " id " (plane:PROD mas verified_against: " verifiedAgainst[id] " — o nó afirma sobre o VIVO e declara ter olhado a FONTE; reclassifique para plane:DEV ou re-verifique contra o artefato vivo)"; fwarns++
      }
    }
    if (ntracked == 0) print "  (nenhum nó com frescor rastreado — nada a verificar)"
    else if (fwarns == 0) print "  ✅ " ntracked " nó(s) com frescor declarado" (metaBaseline != "" ? " (baseline " metaBaseline ")" : "")
    # `if` próprio, FORA da cadeia else-if: a supressão tem de aparecer mesmo quando fwarns==0.
    # Uma linha no lugar de N, e o filtro fica auditável em vez de mágico.
    if (fsuppressed > 0) print "  ℹ " fsuppressed " nó(s) não-claim com carimbo sem verified_against: — não cobrados (evidência/decisão/domínio/artefato ancoram por trace:/TRACES_TO; pergunta não afirma)"
    if (ftestimony > 0) print "  ℹ " ftestimony " nó(s) TESTEMUNHO (evidence_class: testimony) — carimbo é RELATO, não medição; não re-verificáveis por máquina, não enfileirados (atenção continua contando)"
    print ""
  }

  if (mode == "--all" || mode == "--integrity") {
    print "══ INTEGRIDADE ══"
    for (id in dup) { print "  ✗ id duplicado: " id; problems++ }
    # Chave repetida DENTRO de um nó: o parser sobrescreve calado e o arquivo passa a afirmar
    # duas verdades. Reprova — quem carimba tem de SUBSTITUIR, não INSERIR (medido 2026-08-12).
    for (k in dupKey) {
      split(k, _p, "|")
      print "  ✗ " _p[2] " repetido em " _p[1] ": " dupKey[k] " — a última venceu em silêncio; remova a linha antiga (carimbo SUBSTITUI, não insere)"
      problems++
    }
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
      if (refutedBy[id] > 0 && pendingTarget(nstatus[id], ntype[id])) {
        print "  ✗ CONTRADIÇÃO: " id " recebe REFUTES mas segue status=" nstatus[id] " (reconciliar: refuted ou superseded)"; problems++
      }
    }
    if (problems == 0) print "  ✅ sem contradições estruturais (" nn " nós, " ne " arestas)"
    print ""
  }

  exit (problems > 0 ? 1 : 0)
}
' "$FILE"