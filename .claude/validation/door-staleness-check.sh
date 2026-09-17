#!/usr/bin/env bash
# =============================================================================
# door-staleness-check.sh — a PORTA ainda espelha o core, ou já mente sobre ele?
#
# ══ O CICLO ERA PROSA, E A PROSA FALHOU — com número ══════════════════════════
# O `materialize-door.sh` resolve o COMO se publica a porta. O QUANDO era uma
# frase: "toda leva mergeada em main que toque a superfície que viaja". Frase não
# dispara. Medido em 2026-09-17:
#
#     onion-standalone, pin 514dda85833a → 372 commits atrás na superfície que viaja
#
# Não é negligência de ninguém: é o modo de falha previsível de um gatilho que
# depende de alguém lembrar. E o custo é específico — uma porta defasada não fica
# "desatualizada", ela MENTE sobre o que o core é, para quem a usa como referência.
#
# ══ POR QUE CATRACA, E NÃO MURO ═══════════════════════════════════════════════
# Reprovar toda porta defasada tornaria o gate VERMELHO no primeiro run (372) e
# a guarda seria desligada na primeira sexta-feira. O passivo existente entra no
# baseline e SÓ PODE ENCOLHER; porta que ANDA PARA TRÁS (fica mais defasada que o
# tolerado) é HARD. A métrica de saúde é o número diminuindo — e porta nova nasce
# com teto BAIXO, porque não tem passivo a carregar.
#
# Uso : door-staleness-check.sh [<repo>] [--emit-baseline]
# Saída: uma linha por porta. rc=1 se alguma passou do tolerado.
# =============================================================================
set -uo pipefail
REPO="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
[ "${REPO}" = "--emit-baseline" ] && REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EMIT=0; for a in "$@"; do [ "$a" = "--emit-baseline" ] && EMIT=1; done

MEMBERS="${REPO}/docs/evolution/federation/members.yaml"
BASELINE="${REPO}/.claude/validation/door-staleness-baseline.txt"
VM="${REPO}/.claude/utils/adopt/vendor-manifest.sh"

# FALHA FECHADA: sem registro ou sem SSOT do transporte a guarda não SABE o que julgar,
# e guarda que não sabe não aprova — ela diz que não sabe.
[ -f "${MEMBERS}" ] || { echo "ERRO door-staleness: members.yaml ausente — sem registro não há porta a julgar." >&2; exit 3; }
[ -f "${VM}" ]      || { echo "ERRO door-staleness: vendor-manifest.sh ausente — sem a SSOT do transporte não se sabe QUAL superfície conta." >&2; exit 3; }
git -C "${REPO}" rev-parse HEAD >/dev/null 2>&1 || { echo "ERRO door-staleness: '${REPO}' não é repo git." >&2; exit 3; }

_roots=(); while IFS= read -r _r; do [ -n "${_r}" ] && _roots+=("${_r}"); done < <(bash "${VM}" --emit-scrub-roots 2>/dev/null)
[ "${#_roots[@]}" -gt 0 ] || { echo "ERRO door-staleness: superfície declarada VAZIA — nada a comparar." >&2; exit 3; }

# Extrai (id, kind, pin) de cada membro. Um parser só, aqui — o `members-validate.sh` já
# garantiu a forma antes de esta guarda rodar no lint.
_doors="$(python3 - "${MEMBERS}" <<'PY'
import re, sys
s = open(sys.argv[1], encoding='utf-8').read()
for blk in re.split(r'\n  - id: ', s)[1:]:
    mid = blk.split('\n', 1)[0].strip()
    kind = re.search(r'^\s+kind:\s*(\S+)', blk, re.M)
    pin  = re.search(r'^\s+onion_version:\s*(\S+)', blk, re.M)
    if kind and kind.group(1) == 'door' and pin and pin.group(1) != 'n/a':
        print(f"{mid}\t{pin.group(1)}")
PY
)"
[ -n "${_doors}" ] || { echo "door-staleness: nenhuma porta com pin no registro — nada a julgar."; exit 0; }

_out=""; _fail=0
while IFS=$'\t' read -r _id _pin; do
  [ -n "${_id}" ] || continue
  if ! git -C "${REPO}" rev-parse --verify --quiet "${_pin}^{commit}" >/dev/null; then
    _out="${_out}${_id}\tPIN-DESCONHECIDO\t${_pin}\n"; _fail=1; continue
  fi
  # `git log <pin>..HEAD -- <raízes>` conta só o que MEXEU no que viaja. Commit de biografia
  # não defasa a porta — ela não o receberia de qualquer forma, e contá-lo seria ruído.
  _n="$(git -C "${REPO}" log --oneline "${_pin}..HEAD" -- "${_roots[@]}" | grep -c . || true)"
  _lim=""
  [ -f "${BASELINE}" ] && _lim="$(awk -v id="${_id}" '$1==id {print $2; exit}' "${BASELINE}")"
  if [ "${EMIT}" -eq 1 ]; then _out="${_out}${_id} ${_n}\n"; continue; fi
  if [ -z "${_lim}" ]; then
    _out="${_out}${_id}\tSEM-BASELINE\t${_n} commit(s) atrás\n"; _fail=1
  elif [ "${_n}" -gt "${_lim}" ]; then
    _out="${_out}${_id}\tANDOU-PARA-TRAS\t${_n} > ${_lim} tolerado\n"; _fail=1
  else
    _out="${_out}${_id}\tok\t${_n}/${_lim}\n"
  fi
done <<< "${_doors}"

if [ "${EMIT}" -eq 1 ]; then printf '%b' "${_out}"; exit 0; fi
printf '%b' "${_out}"
exit "${_fail}"
