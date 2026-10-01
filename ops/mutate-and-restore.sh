#!/usr/bin/env bash
# ===========================================================================
# mutate-and-restore.sh — planta um MUTANTE, roda o comando, e RESTAURA sempre.
#
# ── POR QUE EXISTE (dano consumado em 2026-10-01) ──────────────────────────────────────────
# Um `exit 137` (SIGKILL do OOM killer) matou a sessão NO MEIO de um teste de mutação e deixou um
# `git add` plantado dentro do `.githooks/pre-commit` — exatamente o defeito que a guarda nova existia
# para pegar. O repo ficou PIOR que antes do teste. A restauração era um `cp` DEPOIS do laço, e `cp`
# depois do laço só roda se o processo sobreviver.
#
# ⚠️ E A CURA ÓBVIA NÃO BASTA, medido: `trap` NÃO intercepta SIGKILL. Um helper que só confia em trap
# seria cura falsa para o caso que de fato ocorreu. Por isso a defesa é em DUAS camadas:
#   1. `trap` em EXIT/INT/TERM/HUP — cobre erro, Ctrl-C e término normal (a maioria dos casos);
#   2. MARKER no mutante + guarda no lint que reprova o marcador — cobre SIGKILL, queda de energia e
#      qualquer morte que trap não vê. Mesmo que o processo evapore, o PRÓXIMO lint acusa.
#
# A camada 2 é a que importa: ela não depende de o processo sobreviver para funcionar.
#
# USO:  bash ops/mutate-and-restore.sh <arquivo> <python-expr> <comando...>
#       <python-expr> = 'ANTIGO|||NOVO' (substituição literal, 1ª ocorrência) — e o NOVO deve conter
#       o marcador ONION_MUTANTE, senão este script RECUSA (fail-closed: mutante sem marcador é o
#       mutante que some sem rastro).
# SAÍDA: o rc do COMANDO. A restauração é conferida por hash e, se falhar, o script sai 9 e GRITA.
# ===========================================================================
set -uo pipefail
MARKER='ONION_MUTANTE'
TARGET="${1:-}"; MUT_EXPR="${2:-}"; shift 2 || true
[ -f "${TARGET}" ] || { echo "mutate: alvo inexistente: '${TARGET}'" >&2; exit 2; }
[ -n "${MUT_EXPR}" ] && [ "$#" -gt 0 ] || { sed -n '/^# USO:/,/^# SAÍDA:/p' "$0" >&2; exit 2; }
case "${MUT_EXPR}" in *'|||'*) : ;; *) echo "mutate: expr precisa ser 'ANTIGO|||NOVO'" >&2; exit 2 ;; esac
case "${MUT_EXPR#*|||}" in *"${MARKER}"*) : ;; *)
  echo "mutate: RECUSADO — o lado NOVO precisa conter o marcador ${MARKER}." >&2
  echo "        Mutante sem marcador é o que desaparece sem rastro quando o processo morre." >&2
  exit 2 ;;
esac

_BACKUP="$(mktemp)"; cp -p "${TARGET}" "${_BACKUP}"
_HASH0="$(sha256sum "${TARGET}" | cut -d' ' -f1)"
_restore() {
  cp -p "${_BACKUP}" "${TARGET}" 2>/dev/null
  local _h; _h="$(sha256sum "${TARGET}" 2>/dev/null | cut -d' ' -f1)"
  if [ "${_h}" != "${_HASH0}" ]; then
    echo "❌ mutate: RESTAURAÇÃO FALHOU em ${TARGET} — o backup está em ${_BACKUP}. NÃO COMMITE." >&2
    rm -f "${_BACKUP}" 2>/dev/null; exit 9
  fi
  rm -f "${_BACKUP}" 2>/dev/null
}
trap _restore EXIT INT TERM HUP

python3 - "${TARGET}" "${MUT_EXPR}" <<'PY' || { echo "mutate: não consegui plantar o mutante" >&2; exit 3; }
import sys
p, expr = sys.argv[1], sys.argv[2]
a, b = expr.split('|||', 1)
s = open(p, encoding='utf-8').read()
if a not in s:
    sys.stderr.write(f"mutate: ancora ausente em {p}: {a[:60]!r}\n"); sys.exit(1)
open(p, 'w', encoding='utf-8').write(s.replace(a, b, 1))
PY

"$@"; _rc=$?
exit "${_rc}"
