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
  # ⚠️ ESTES DOIS ENTRARAM EM 2026-09-30 PORQUE A FALTA DELES ME CUSTOU DOIS CI SEGUIDOS.
  # A REGRA 80 (Números do harness saem de SSOT gerada, nunca de comentário) e a REGRA 81 (Painel de
  # estado é GERADO dos produtores, nunca redigido) cobram duas projeções que este script NÃO
  # regenerava — então fechá-las dependia de eu LEMBRAR de rodar os dois geradores à mão. Esqueci
  # duas vezes na mesma sessão, e o modo de falha é sutil: o painel CONTA o resíduo de revisão e os
  # achados da leva, logo gerá-lo antes de escrever o resíduo o deixa defasado POR CONSTRUÇÃO. O lint
  # local passava (rodei antes do resíduo existir) e o CI reprovava. Estando aqui, um comando fecha
  # todas as projeções, e a ordem certa — depois do resíduo — vira consequência de rodar o regen por
  # último, em vez de disciplina de lembrar.
  # E `graph.md` entrou na MESMA leva, pelo mesmo motivo, uma rodada de CI depois: `graph.sh --map`
  # já estava aqui (para o federation-map), mas a OUTRA saída do mesmo gerador — `--markdown`, que
  # produz a lente sócio-técnica cobrada pela REGRA 21 — não estava, e a bancada reprovou com
  # `graph: em-sync`. A lição é a lista, não o arquivo: um gerador com duas saídas precisa das duas
  # declaradas, senão fechar a segunda volta a depender de alguém lembrar.
  "graph.sh --markdown|docs/onion/graph.md|20|linhas"
  # E `inventory.md` fechou a PARIDADE, que é o achado de fundo desta leva: medido em 2026-09-30, o
  # `regen-ssot-projections.sh` — o que VIAJA e o adotante roda — já fechava SEIS projeções
  # (graph, inventory, testing-inventory, testing-state, lint-rules, kg-read-index) enquanto este,
  # do core, fechava QUATRO. O core estava pior servido que quem o adota, e foi por isso que eu
  # esqueci três projeções em três rodadas de CI seguidas no mesmo dia. Não é descuido: é o core
  # sem a ferramenta que ele mesmo entrega.
  "inventory.sh --markdown|docs/onion/inventory.md|20|linhas"
  "harness-inventory.sh --markdown|docs/onion/testing-inventory.md|20|linhas"
  "testing-state.sh --markdown|docs/onion/testing-state.md|20|linhas"
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
