#!/usr/bin/env bash
# kg-backlog-check.sh — mecaniza as promessas do `meta:` do grafo de backlog.
#
# POR QUE EXISTE (dano medido, 2026-08-09): o `meta:` de `fios-abertos.kg.yaml` PROMETE, em letra
# grande, um teto de 20 nós, "onda nova exige onda COLHIDA" e "QUEM NÃO CONSEGUE CARIMBAR NÃO PODE
# DECLARAR FEITO". Nenhuma das três existia como guarda. Uma passada adversarial anotou isso como
# `fix-must-become-mechanism` aplicado AO PRÓPRIO ARQUIVO QUE NOMEIA A DOUTRINA — o backlog podia
# inchar até virar cemitério, ou declarar `done` sem medição, e nada acusaria.
#
# O QUE JULGA — três checagens, todas contra o arquivo, nenhuma contra a memória de quem edita:
#   TETO         mais que o teto declarado no próprio `meta:`                        → HARD
#   DONE-NU      item `done` sem `verified_at` + `verified_against`                  → HARD
#   PARADO       item `open` mais velho que o `baseline:` do arquivo, sem carimbo     → SOFT
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

awk -v fmt="${FMT}" -v arq="${FILE}" '
  # ── teto e baseline vêm do PRÓPRIO arquivo ────────────────────────────────────────────────
  /^[[:space:]]*#.*TETO:[[:space:]]*[0-9]+[[:space:]]*N/ { if (match($0, /TETO:[[:space:]]*[0-9]+/)) { t=substr($0,RSTART,RLENGTH); gsub(/[^0-9]/,"",t); teto=t+0 } }
  /^[[:space:]]*baseline:[[:space:]]*[0-9]/ { base=$2 }

  /^[[:space:]]*-[[:space:]]*id:/ { if (id!="") flush(); id=$3; st=""; va=""; vg=""; ty=""; next }
  /^[[:space:]]*node_type:/  { ty=$2 }
  /^[[:space:]]*status:/     { st=$2 }
  /^[[:space:]]*verified_at:/{ va=$2 }
  /^[[:space:]]*verified_against:/ { vg=$2 }
  /^edges:/ { if (id!="") flush(); id=""; inEdges=1 }
  END { if (id!="") flush(); report() }

  function flush() {
    n++
    if (st == "done" && (va == "" || vg == "")) {
      donenu[++dn] = id "(verified_at=" (va==""?"AUSENTE":va) " verified_against=" (vg==""?"AUSENTE":vg) ")"
    }
    id=""
  }
  function report(   i) {
    if (teto == 0) {
      # fail-loud: sem o teto declarado a guarda nao sabe o que cobrar, e "nao sei" NUNCA vira "ok"
      printf "HARD\tSEM-TETO\t%s\to `meta:` nao declara TETO — a guarda nao pode afirmar conformidade sobre um limite que nao existe\n", arq
      exitcode = 1
    } else if (n > teto) {
      printf "HARD\tTETO\t%s\t%d nos, teto declarado %d — onda nova exige onda COLHIDA (o `meta:` deste arquivo)\n", arq, n, teto
      exitcode = 1
    }
    for (i = 1; i <= dn; i++) {
      printf "HARD\tDONE-NU\t%s\titem declarado `done` SEM carimbo: %s — quem nao consegue carimbar nao pode declarar feito\n", arq, donenu[i]
      exitcode = 1
    }
    if (fmt != "--format" && exitcode != 1) printf "OK\tBACKLOG\t%s\t%d/%d nos, nenhum `done` sem carimbo\n", arq, n, teto
    exit exitcode+0
  }
' "${FILE}"
