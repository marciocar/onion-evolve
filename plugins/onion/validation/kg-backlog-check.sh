#!/usr/bin/env bash
# kg-backlog-check.sh — mecaniza as promessas do `meta:` do grafo de backlog.
#
# POR QUE EXISTE (dano medido, 2026-08-09): o `meta:` de `fios-abertos.kg.yaml` PROMETE, em letra
# grande, um cap de 20 nós, "onda nova exige onda COLHIDA" e "QUEM NÃO CONSEGUE CARIMBAR NÃO PODE
# DECLARAR FEITO". Nenhuma das três existia como guarda. Uma passada adversarial anotou isso como
# `fix-must-become-mechanism` aplicado AO PRÓPRIO ARQUIVO QUE NOMEIA A DOUTRINA — o backlog podia
# inchar até virar cemitério, ou declarar `done` sem medição, e nada acusaria.
#
# O QUE JULGA — três checagens, todas contra o arquivo, nenhuma contra a memória de quem edita:
#   TETO         mais que o cap declarado no próprio `meta:`                        → HARD
#   DONE-NU      item `done` sem `verified_at` + `verified_against` com VALOR         → HARD
#   SEM-TETO     o `meta:` nao declara cap — nao sei o que cobrar, logo nao aprovo    → HARD
#
# ⚠️ ESTA TABELA JA MENTIU NA 1a VERSAO, no PR que criou a catraca `(w)` contra tabelas que mentem:
# ela listava `PARADO → SOFT`, que NUNCA foi emitido, e OMITIA `SEM-TETO`, que e emitido. Escrever a
# doutrina antes de escrever o codigo e o caminho normal; o que nao pode e a doutrina ficar.
#
# ⚠️ O TETO É LIDO DO ARQUIVO, não hardcoded. Um número no script e outro no `meta:` seria a mesma
# classe de `declarado != verificado` que este gate existe para fechar — e a casa já viu a tabela de
# doutrina da catraca divergir do código por um PR inteiro sem ninguém notar.
#
# ⚠️ `DONE-NU` É O CORAÇÃO. O `meta:` diz que ITEM só vira `done` em `plane: PROD` COM carimbo. Como
# o backlog nasce todo `plane: DEV`, a REGRA 49 (que só olha PROD) NÃO o alcança — de propósito, para
# não poluir o baseline. O efeito colateral é que declarar `done` ali sai de graça. Esta guarda fecha
# exatamente essa fresta, e é por isso que ela olha o backlog e não o corpus inteiro.
#
# Exit: 0 = ok · 1 = violação · 2 = erro de uso/arquivo.
# Determinístico, awk puro. Exercitado por lint-selftest.sh (run_kg_backlog_selftests).
set -uo pipefail

FILE="${1:-}"
[ -n "${FILE}" ] && [ -f "${FILE}" ] || { echo "uso: kg-backlog-check.sh <backlog.kg.yaml> [--format tsv]" >&2; exit 2; }
FMT="${2:-}"

awk -v fmt="${FMT}" -v file="${FILE}" '
  # ── cap e baseline vêm do PRÓPRIO arquivo ────────────────────────────────────────────────
  /^[[:space:]]*#.*TETO:[[:space:]]*[0-9]+[[:space:]]*N/ { if (match($0, /TETO:[[:space:]]*[0-9]+/)) { t=substr($0,RSTART,RLENGTH); gsub(/[^0-9]/,"",t); cap=t+0 } }
  /^[[:space:]]*baseline:[[:space:]]*[0-9]/ { baseline=$2 }

  # ⚠️ NORMALIZAR ANTES DE COMPARAR. A 1a versao lia `$2` cru e uma passada adversarial mediu quatro
  # fugas, todas YAML VALIDO e indistinguivel a olho: `status: "done"` (aspas) escapava do DONE-NU;
  # `verified_at: ""`, `: null` e `: TODO` passavam como carimbo, e a guarda AFIRMAVA "nenhum `done`
  # sem carimbo"; e CRLF colava `\r` no valor. Carimbo de ar e pior que carimbo ausente — ele
  # DECLARA medicao que nao houve, que e o defeito fundador da REGRA 49.
  function val(s) { sub(/^[^:]*:[[:space:]]*/, "", s); gsub(/\r/, "", s)
                    gsub(/^["'"'"']|["'"'"']$/, "", s); sub(/[[:space:]]+$/, "", s)
                    if (s == "null" || s == "~" || s == "TODO" || s == "-") return ""
                    return s }
  /^[[:space:]]*-[[:space:]]*id:/ { if (id!="") flush(); id=val($0); st=""; va=""; vg=""; ty=""; next }
  /^[[:space:]]*node_type:/  { ty=val($0) }
  /^[[:space:]]*status:/     { st=val($0) }
  /^[[:space:]]*verified_at:/{ va=val($0) }
  /^[[:space:]]*verified_against:/ { vg=val($0) }
  /^edges:/ { if (id!="") flush(); id=""; inEdges=1 }
  END { if (id!="") flush(); report() }

  function flush() {
    n++
    if (st == "done" && (va == "" || vg == "")) {
      unstamped[++un] = id "(verified_at=" (va==""?"AUSENTE":va) " verified_against=" (vg==""?"AUSENTE":vg) ")"
    }
    id=""
  }
  function report(   i) {
    if (cap == 0) {
      # fail-loud: sem o cap declarado a guarda nao sabe o que cobrar, e "nao sei" NUNCA vira "ok"
      printf "HARD\tSEM-TETO\t%s\to `meta:` nao declara TETO — a guarda nao pode afirmar conformidade sobre um limite que nao existe\n", file
      rc = 1
    } else if (n > cap) {
      printf "HARD\tTETO\t%s\t%d nos, teto declarado %d — onda nova exige onda COLHIDA (o `meta:` deste arquivo)\n", file, n, cap
      rc = 1
    }
    for (i = 1; i <= un; i++) {
      printf "HARD\tDONE-NU\t%s\titem declarado `done` SEM carimbo: %s — quem nao consegue carimbar nao pode declarar feito\n", file, unstamped[i]
      rc = 1
    }
    if (fmt != "--format" && rc != 1) printf "OK\tBACKLOG\t%s\t%d/%d nos, nenhum `done` sem carimbo\n", file, n, cap
    exit rc+0
  }
' "${FILE}"
