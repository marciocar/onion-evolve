#!/usr/bin/env bash
# =============================================================================
# kg-seal-check.sh — o VEREDITO foi SELADO no grafo? (REGRA 57)
#
# Um run de /meta:kg-freshness produz vereditos (CONFIRMED/DRIFTED/REFUTED/UNVERIFIABLE) e o
# maestro SELA o resultado no .kg.yaml. Esta guarda compara as duas pontas: o LEDGER do run
# (docs/evolution/research/<run>/ledger-por-item.tsv, apontado pelo frontmatter `ledger:` da
# SYNTHESIS) contra o GRAFO que ele julgou (frontmatter `source:`).
#
# POR QUE EXISTE — gatilho MEDIDO, não vontade (o falsificador do nó C_ANCORA_SOLTA_79PCT exigia
# medição, e ela veio ao contrário do que eu supunha): o selo do M8 foi aplicado À MÃO DUAS VEZES
# e ficou defeituoso NAS DUAS. Em 2026-08-06 (#552) escreveu-se `verified_at` sem status — a SSOT
# seguiu afirmando `whatsapp-sender VIVO` por 12h depois de a medição não achar o serviço. Em
# 2026-08-07 (#555) corrigiu-se o status e ficaram 2 dos 4 DRIFTED sem a reconciliação que a
# tabela do Passo 4 manda. O radar saiu exit 0 nas três vezes: ele valida o grafo contra si mesmo,
# nunca contra o veredito que o run produziu.
#
# O PREDICADO (reescrito pelo Elenxo 2026-08-07, que achou 3 falsos-positivos HARD — todos
# disparando para quem OBEDECE a doutrina):
#   CONFIRMED    → verified_at >= data do run.  `>=` e nao `==`: o Passo 4 manda `verified_at:
#                  <hoje>`, e "hoje" e o dia em que o maestro SELA, nao o dia do run. Com
#                  igualdade a regra bloquearia os PROPRIOS commits que a embarcaram (8b005f6 e
#                  1681c7c sao de 2026-08-07 escrevendo verified_at 2026-08-06).
#   DRIFTED      → status `drifted` (mediu, ainda nao reconciliou)  OU  aresta SUPERSEDES em
#                  QUALQUER das duas direcoes com a outra ponta `superseded` E com a data do run
#                  em alguma das pontas. As duas direcoes porque a FORMA DO CONTRATO (Passo 4:
#                  "Novo no + SUPERSEDES -> antigo; antigo vira superseded") poe o no julgado como
#                  ALVO — a 1a versao so aceitava a inversa e teria acusado 11 arestas do
#                  m2-bridge-logto, o grafo que o proprio contrato cita como o dogfood CERTO.
#                  A amarra de data existe porque uma aresta de JULHO estava selando veredito de
#                  AGOSTO: bastava flipar uma linha do ledger, sem escrever nada, e a guarda passava.
#   REFUTED      → SOFT. Cobre 2 das 6 clausulas do Passo 4 (falta o no `evidence` com PROD,
#                  verified_at, verified_against e trace), tem ZERO linhas no ledger real e nunca
#                  foi exercitado pelo teste de aceite. HARD aqui seria poder emprestado da
#                  evidencia dos outros ramos — o vexame do kg-trace-resolve.sh:50-56 em especie.
#   UNVERIFIABLE → verified_at != data do run  E  (confidence < 1.0 OU question+DEPENDS_ON)
#
#   PRECEDENCIA: se o no tem verified_at MAIS NOVO que o run, pula. Sem isso a regra vira CATRACA
#   CONTRA RE-VERIFICAR — com dois runs sobre o mesmo grafo nenhum estado satisfaz os dois ledgers
#   (verified_at guarda UMA data), o que e incompativel com a razao de existir do comando.
#
#   VOCABULARIO FECHADO: veredito fora de {CONFIRMED,DRIFTED,REFUTED,UNVERIFIABLE} e HARD nomeado.
#   Um ledger em minusculas (a MESMA caixa que `status:` usa) atravessava os quatro ramos sem casar
#   nenhum e a guarda saia VERDE sobre grafo defeituoso. E a contagem de vacuidade e de julgamentos
#   APLICADOS, nao de linhas LIDAS — contar leitura nao prova julgamento.
#
# NAO cobra `status: drifted` para veredito DRIFTED. A doutrina (kg-freshness.md, bloco de
# 2026-08-07) diz que um DRIFTED JA RECONCILIADO deixa o no `confirmed` — "a memoria do veredito
# vive na ARESTA, nao no status".
#
# SILENCIO POR ESCOPO, NUNCA POR SORTE: repo sem nenhuma SYNTHESIS declarando `ledger:` no
# FRONTMATTER (entre as duas primeiras linhas ---, nao no corpo: um bloco ```yaml de DOCUMENTACAO
# disparava a regra) emite ISENCAO CONTADA. E o caminho do adotante que nunca rodou
# /meta:kg-freshness — e o precedente esta escrito em kg-trace-resolve.sh: "shipei como HARD sem
# baseline tendo verificado so que o CORE tinha zero; no primeiro adotante acusou 11 ponteiros,
# TODOS falsos. O CORE E O PIOR ORACULO DO QUE VIAJA". Aqui a superficie e fechada, por isso HARD
# nos tres ramos que o aceite EXERCITOU (CONFIRMED, DRIFTED, UNVERIFIABLE) e SOFT no que nao.
#
# Uso: kg-seal-check.sh [REPO_ROOT] [--format=tsv]
# TSV: sev \t tag \t path \t msg      (contrato de review-artifact-check.sh)
# Exit: 0 = tudo selado (ou fora de escopo) · 1 = selo faltando/errado · 2 = erro de uso
#
# Determinístico, sem jq, sem LLM. Exercitado por lint-selftest.sh (run_kg_seal_check_selftests).
# =============================================================================
set -uo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${ROOT}" ] || { echo "uso: kg-seal-check.sh [REPO_ROOT] [--format=tsv]" >&2; exit 2; }
shift 2>/dev/null || true

FORMAT=human
for a in "$@"; do case "$a" in tsv|--format=tsv) FORMAT=tsv ;; --format) : ;; esac; done

PROBLEMS=0
SKIPS=""
JUDGED=0

_out() {  # sev tag path msg
  PROBLEMS=$((PROBLEMS + 1))
  if [ "${FORMAT}" = tsv ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
  else printf '  x %s: %s\n' "$2" "$4"; fi
}

_skip() { SKIPS="${SKIPS}${SKIPS:+, }$1"; }

# ── descoberta: SYNTHESIS que DECLARA ledger ────────────────────────────────────────────────
SYNS="$(cd "${ROOT}" && git ls-files 'docs/evolution/research/*/SYNTHESIS.md' 2>/dev/null || true)"

[ "${FORMAT}" = tsv ] || printf '== KG-SEAL-CHECK -- o veredito do run foi selado no grafo? ==\n'

for syn in ${SYNS}; do
  f="${ROOT}/${syn}"
  [ -f "${f}" ] || continue
  # SO o frontmatter (entre as DUAS primeiras linhas ---). Varrer o arquivo inteiro fazia uma
  # SYNTHESIS que apenas DOCUMENTA o formato num bloco ```yaml disparar a regra. Elenxo 2026-08-07.
  ledger="$(awk '/^---$/{ n++; if (n==2) exit; next } n==1 && /^ledger:[[:space:]]/ { sub(/^ledger:[[:space:]]*/, ""); print; exit }' "${f}")"
  [ -n "${ledger}" ] || continue
  src="$(awk '/^---$/{ n++; if (n==2) exit; next } n==1 && /^source:[[:space:]]/ { sub(/^source:[[:space:]]*/, ""); print; exit }' "${f}")"
  runday="$(awk '/^---$/{ n++; if (n==2) exit; next } n==1 && /^verified_at:[[:space:]]/ { sub(/^verified_at:[[:space:]]*/, ""); print; exit }' "${f}")"

  # `source:` carrega path + " @ commit" + prosa, tudo numa string com aspas. Limpa.
  graph="$(printf '%s' "${src}" | sed -e 's/^"//' -e 's/"$//' -e 's/[[:space:]]*@.*$//' -e 's/[[:space:]]*$//')"

  if [ -z "${graph}" ] || [ ! -f "${ROOT}/${graph}" ]; then
    _out SOFT FONTE-ILEGIVEL "${syn}" "declara ledger mas o campo source: nao resolve para um .kg.yaml existente (lido: ${graph:-vazio}) — sem o grafo julgado o selo nao e verificavel"
    continue
  fi
  [ -f "${ROOT}/${ledger}" ] || {
    _out HARD LEDGER-AUSENTE "${syn}" "frontmatter declara ledger: ${ledger} e o arquivo nao existe — o custo por item nao e auditavel e o selo nao e verificavel"
    continue
  }
  [ -n "${runday}" ] || {
    _out HARD RUN-SEM-DATA "${syn}" "declara ledger mas nao tem verified_at: no frontmatter — sem a data do run nao da para julgar se o carimbo e daquele run"
    continue
  }

  # ── julgamento: um awk lê grafo + ledger e emite as violações ──────────────────────────────
  out="$(awk -v runday="${runday}" -v lf="${ROOT}/${ledger}" '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); gsub(/^["]|["]$/, "", s); return s }
    BEGIN { sec = ""; nid = "" }
    /^[[:space:]]*#/ { next }
    /^nodes:/ { sec = "nodes"; next }
    /^edges:/ { sec = "edges"; nid = ""; ef = ""; et = ""; next }
    /^meta:/  { sec = "meta";  next }
    sec == "nodes" && /^[[:space:]]+- id:/ { v = $0; sub(/^[[:space:]]*- id:/, "", v); nid = trim(v); seen[nid] = 1; next }
    sec == "nodes" && nid != "" {
      if ($0 ~ /^[[:space:]]*status:/)           { v = $0; sub(/^[[:space:]]*status:/, "", v); st[nid] = trim(v) }
      else if ($0 ~ /^[[:space:]]*node_type:/)   { v = $0; sub(/^[[:space:]]*node_type:/, "", v); ty[nid] = trim(v) }
      else if ($0 ~ /^[[:space:]]*confidence:/)  { v = $0; sub(/^[[:space:]]*confidence:/, "", v); cf[nid] = trim(v) + 0 }
      else if ($0 ~ /^[[:space:]]*verified_against:/) { }
      else if ($0 ~ /^[[:space:]]*verified_at:/) { v = $0; sub(/^[[:space:]]*verified_at:/, "", v); va[nid] = trim(v) }
      next
    }
    sec == "edges" && /^[[:space:]]+- from:/ { v = $0; sub(/^[[:space:]]*- from:/, "", v); ef = trim(v); next }
    sec == "edges" && /^[[:space:]]*to:/     { v = $0; sub(/^[[:space:]]*to:/, "", v);     et = trim(v); next }
    sec == "edges" && /^[[:space:]]*edge_type:/ {
      v = $0; sub(/^[[:space:]]*edge_type:/, "", v); e = trim(v)
      if (e == "SUPERSEDES") { supOut[ef] = supOut[ef] " " et; supIn[et] = supIn[et] " " ef }
      if (e == "REFUTES")    { refIn[et]  = refIn[et]  " " ef }
      if (e == "DEPENDS_ON") { depIn[et]  = depIn[et]  " " ef }
      next
    }
    END {
      # LEGIBILIDADE — se o grafo tem nodes: e saiu ZERO nó, o parser morreu. Nao opinar.
      n = 0; for (k in seen) n++
      if (n == 0) { print "VACUO\t\t\t"; exit }

      while ((getline line < lf) > 0) {
        if (line ~ /^[[:space:]]*#/) continue
        if (line ~ /^[[:space:]]*$/) continue
        split(line, c, "\t")
        id = trim(c[1]); vd = trim(c[2])
        if (id == "" || vd == "") continue
        if (!(id in seen)) { print "SOFT\tAUSENTE\t" id "\to id do ledger nao existe no grafo julgado — no renomeado ou removido depois do run? SOFT porque nao e o defeito medido que originou a regra, e um HARD aqui vira lapide permanente"; applied++; continue }

        # PRECEDENCIA — um run POSTERIOR ja re-verificou este no. Cobrar o ledger antigo tornaria
        # a regra uma CATRACA CONTRA RE-VERIFICAR: com dois runs sobre o mesmo grafo, nenhum estado
        # satisfaz os dois ledgers (verified_at guarda UMA data). Seria incompatível com a razao de
        # existir do /meta:kg-freshness. Medido no Elenxo 2026-08-07 (fixture de dois runs).
        if (va[id] != "" && va[id] > runday) { applied++; continue }

        if (vd == "CONFIRMED") {
          # `<` e nao `!=`: o selo pode ser do DIA SEGUINTE. O Passo 4 manda `verified_at: <hoje>`,
          # e "hoje" e o dia em que o maestro SELA, nao o dia do run. Com igualdade, a regra
          # bloquearia quem segue o contrato ao pe da letra — e bloquearia os proprios commits que
          # a embarcaram (8b005f6 e 1681c7c sao de 2026-08-07 escrevendo verified_at 2026-08-06).
          if (va[id] == "" || va[id] < runday)
            print "HARD\tSELO-FALTANDO\t" id "\tveredito CONFIRMED e verified_at=" (va[id] == "" ? "ausente" : va[id]) " e anterior ao run (" runday ") — o no foi medido e o carimbo nao registra"
          applied++
        } else if (vd == "DRIFTED") {
          ok = 0
          # (i) estado intermediario legitimo: mediu, ainda nao escreveu a reconciliacao
          if (st[id] == "drifted") ok = 1
          # (ii) A FORMA DO CONTRATO (Passo 4, linha 139): "Novo no com a verdade atual +
          #      SUPERSEDES -> antigo; antigo vira status: superseded". O no do LEDGER e o ANTIGO:
          #      ele RECEBE a aresta e fica superseded. A 1a versao desta guarda so aceitava a
          #      direcao INVERSA e teria acusado 11 arestas do m2-bridge-logto — o grafo que o
          #      PROPRIO contrato cita como o dogfood CERTO. Elenxo 2026-08-07.
          if (!ok && st[id] == "superseded" && supIn[id] != "") {
            m = split(supIn[id], ss, " "); for (i = 1; i <= m; i++) if (ss[i] != "" && (va[id] >= runday || va[ss[i]] >= runday)) ok = 1
          }
          # (iii) a forma praticada no vps-shared-tools: o no julgado segue vivo e SUPERSEDE um no
          #       novo que carrega a posicao superada.
          # A RECONCILIACAO TEM DE SER DESTE RUN. Sem esta amarra, uma aresta ANTIGA sela um
          # veredito NOVO: medido no Elenxo 2026-08-07 — bastou flipar uma linha do ledger para
          # DRIFTED, sem escrever NADA no grafo, e a guarda passou verde porque a aresta ja existia
          # desde julho. Era o modo de falha original entrando pela porta da frente.
          if (!ok) { m = split(supOut[id], tt, " "); for (i = 1; i <= m; i++) if (tt[i] != "" && st[tt[i]] == "superseded" && (va[id] >= runday || va[tt[i]] >= runday)) ok = 1 }
          if (!ok)
            print "HARD\tDRIFT-NAO-RECONCILIADO\t" id "\tveredito DRIFTED e o grafo nao registra a reconciliacao: nem SUPERSEDES (em nenhuma das duas direcoes do contrato) com a outra ponta superseded, nem status drifted (esta em " (st[id] == "" ? "sem status" : st[id]) ")"
          applied++
        } else if (vd == "REFUTED") {
          # SOFT, e a razao e honesta: esta guarda cobra 2 das 6 clausulas que o Passo 4 exige para
          # REFUTED (falta o no `evidence` com plane PROD, verified_at, verified_against e trace).
          # O ledger real tem ZERO linhas REFUTED e o teste de aceite nunca exercitou este ramo —
          # subir HARD aqui seria poder emprestado da evidencia dos outros. E o vexame do
          # kg-trace-resolve.sh:50-56 em especie. Sobe a HARD quando cobrir o contrato e tiver caso.
          if (st[id] != "refuted" || refIn[id] == "")
            print "SOFT\tREFUTACAO-NAO-SELADA\t" id "\tveredito REFUTED exige aresta REFUTES entrando E status refuted (tem status " (st[id] == "" ? "vazio" : st[id]) ", REFUTES entrando: " (refIn[id] == "" ? "nao" : "sim") ") — SOFT: cobre 2 das 6 clausulas do Passo 4 e nunca foi exercitado por ledger real"
          applied++
        } else if (vd == "UNVERIFIABLE") {
          if (va[id] == runday)
            print "HARD\tUNVER-CARIMBADO\t" id "\tveredito UNVERIFIABLE mas verified_at e a data do run — o contrato proibe: nao se mediu, nao se carimba"
          else {
            ok = 0
            if (cf[id] < 1.0) ok = 1
            m = split(depIn[id], dd, " "); for (i = 1; i <= m; i++) if (dd[i] != "" && ty[dd[i]] == "question") ok = 1
            if (!ok)
              print "HARD\tUNVER-INERTE\t" id "\tveredito UNVERIFIABLE sem efeito no grafo: confidence segue 1.0 e nenhuma question DEPENDS_ON o no — o selo nao muda nada (statusFactor de unverifiable == confirmed)"
          }
          applied++
        } else {
          # VOCABULARIO FECHADO. Sem isto, um ledger escrito em minusculas (a MESMA caixa que o
          # campo `status:` usa) atravessava os quatro ramos sem casar nenhum e a guarda saia
          # VERDE sobre um grafo comprovadamente defeituoso. Fail-open dentro da cura do fail-open.
          print "HARD\tVOCABULARIO-DESCONHECIDO\t" id "\tveredito \"" vd "\" fora do vocabulario fechado (CONFIRMED|DRIFTED|REFUTED|UNVERIFIABLE) — caixa errada no ledger faz a guarda passar em silencio"
          applied++
        }
      }
      close(lf)
      if (applied == 0) print "VACUO\t\t\t"
    }
  ' "${ROOT}/${graph}")"

  if printf '%s' "${out}" | grep -q '^VACUO'; then
    _out HARD VACUIDADE "${ledger}" "o par ledger/grafo foi lido e ZERO itens foram julgados — parser morto ou ledger sem linhas de dado. Guarda que nao le nada nao pode dizer que esta tudo certo"
    continue
  fi

  while IFS=$'\t' read -r sev tag nid msg; do
    [ -n "${tag}" ] || continue
    JUDGED=$((JUDGED + 1))
    _out "${sev}" "${tag}" "${graph}" "${nid}: ${msg} (run: ${syn})"
  done <<< "${out}"

  # conta os julgados mesmo quando nada saiu (senao JUDGED so cresce com defeito)
  JUDGED=$((JUDGED + 1))
done

# ── VACUIDADE DE ESCOPO — antes da bifurcacao de formato, senao o modo consumido cala ────────
if [ "${JUDGED}" -eq 0 ] && [ "${PROBLEMS}" -eq 0 ]; then
  _skip "sem-run-declarando-ledger"
  if [ "${FORMAT}" = tsv ]; then
    printf 'SOFT\tISENCAO\t.claude/validation/kg-seal-check.sh\tREGRA 57 nao julgou nada: nenhuma SYNTHESIS declara ledger: neste repo (adotante que nunca rodou /meta:kg-freshness). A guarda declara que NAO SABE, em vez de passar em silencio\n'
  else
    printf '  o fora de escopo: %s\n' "${SKIPS}"
  fi
  exit 0
fi

if [ "${PROBLEMS}" -eq 0 ]; then
  [ "${FORMAT}" = tsv ] || printf '  ok todo veredito do ledger esta selado no grafo\n'
  exit 0
fi
exit 1
