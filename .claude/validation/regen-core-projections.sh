#!/usr/bin/env bash
# =============================================================================
# regen-core-projections.sh — regenera as projeções CORE-ONLY, as que o
# `regen-ssot-projections.sh` legitimamente NÃO cobre.
#
# ══ POR QUE ESTE SCRIPT EXISTE, e por que ele NÃO é o irmão gêmeo do outro ═══
# O `regen-ssot-projections.sh` regenera o que um ADOTANTE precisa — e ele está
# certo em NÃO tocar nas projeções da federação: elas derivam do `members.yaml`,
# que é superfície core-only. Sem registro não há mapa, console nem agent-card
# a gerar. A isenção é de desenho.
#
# O que faltava era o outro lado: no CORE essas quatro projeções TÊM catraca no
# lint (REGRAS 24, 38, 39 e a do agent-card) e ninguém as regenerava em bloco.
# Medido em 2026-09-17: QUATRO vezes no mesmo dia eu descobri, uma a uma e pelo
# gate vermelho, qual projeção tinha envelhecido depois de tocar o `members.yaml`
# ou o registro de regras. Descobrir por gate vermelho é caro e é tarde.
#
# ⚠️ A LIÇÃO NÃO É "faltava um script". É que a COBERTURA estava partida em duas
# e só uma metade tinha dono. O `regen_completude` da bancada isenta estes
# geradores com razão escrita — e a razão vale para o ALVO. No core, a mesma
# isenção virava buraco. Cobertura que depende de quem lembra não é cobertura.
#
# ══ O CONTRATO DE ESCRITA, e ele não é zelo ══════════════════════════════════
# Nenhuma projeção é sobrescrita sem que o GERADOR tenha saído 0 E produzido
# tamanho plausível. A classe é conhecida nesta casa (REGRA 62): gerador que
# falha e escreve vazio DESTRÓI a projeção boa, e o `[ -s ]` sozinho não basta
# porque um byte já passa. Em 2026-09-17 eu trunquei o `kg-read-index.tsv` para
# ZERO linhas exatamente assim — com um gerador que saiu rc=2 e um redirect
# direto. Aqui o gerador escreve num temporário e só é promovido se convencer.
#
# Uso : bash .claude/validation/regen-core-projections.sh [<repo>]
# Saída: uma linha por projeção. rc=1 se alguma NÃO pôde ser regenerada.
# =============================================================================
set -uo pipefail
REPO="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "${REPO}" || { echo "ERRO: '${REPO}' inacessível." >&2; exit 2; }

# gerador · destino · piso plausível · unidade
# O piso NÃO é arbitrário: é a ordem de grandeza medida da projeção viva, escolhida
# baixa o bastante para não reprovar encolhimento legítimo e alta o bastante para
# barrar o vazio-que-parece-conteúdo (um cabeçalho solto, um erro em JSON).
_PROJ=(
  "graph.sh --map|docs/onion/federation-map.md|10|linhas"
  "federation-console.sh|docs/onion/federation-console.html|500|bytes"
  "rules-registry.sh|.claude/validation/lint-rules.md|50|linhas"
  "a2a-agent-card.sh|docs/onion/agent-card.json|100|bytes"
)

_fail=0 _n=0
for _p in "${_PROJ[@]}"; do
  IFS='|' read -r _gen _out _piso _un <<< "${_p}"
  _bin="${_gen%% *}"; _arg="${_gen#"${_bin}"}"
  if [ ! -f ".claude/validation/${_bin}" ]; then
    printf '  ⊘ %-38s gerador ausente (%s) — NÃO julgado\n' "${_out}" "${_bin}"; continue
  fi
  _tmp="$(mktemp)"
  # shellcheck disable=SC2086
  bash ".claude/validation/${_bin}" ${_arg} > "${_tmp}" 2>/dev/null
  _rc=$?
  if [ "${_un}" = linhas ]; then _got="$(grep -c . "${_tmp}" || true)"; else _got="$(wc -c < "${_tmp}")"; fi
  if [ "${_rc}" -ne 0 ] || [ "${_got}" -lt "${_piso}" ]; then
    printf '  ✗ %-38s gerador rc=%s, %s %s (piso %s) — NÃO sobrescrevi\n' "${_out}" "${_rc}" "${_got}" "${_un}" "${_piso}"
    _fail=1; rm -f "${_tmp}"; continue
  fi
  if cmp -s "${_tmp}" "${_out}"; then printf '  = %-38s já em dia\n' "${_out}"
  else cp "${_tmp}" "${_out}"; printf '  ✓ %-38s regenerada (%s %s)\n' "${_out}" "${_got}" "${_un}"; _n=$((_n+1)); fi
  rm -f "${_tmp}"
done

printf '  → %d projeção(ões) core-only regenerada(s)\n' "${_n}"
exit "${_fail}"
