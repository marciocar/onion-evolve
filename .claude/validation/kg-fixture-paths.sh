#!/usr/bin/env bash
# =============================================================================
# kg-fixture-paths.sh — o predicado ÚNICO de "este .kg.yaml é FIXTURE de teste?"
#
# POR QUÊ : seis consumidores repetiam `git ls-files '*.kg.yaml' | grep -v '/fixtures/'` à mão
#           (kg-radar-integrity · kg-corpus-grep · kg-trace-resolve · kg-verification-coverage ·
#           kg-backlog-project · e o escopo da REGRA 52). Seis listas, um vocabulário — e guarda de
#           lista falha pelo VOCABULÁRIO, não pela lógica.
#           ACHADO DE CAMPO (adoção greenfield, 2026-09-05): um adotante portou o radar para JS com
#           fixtures de conformidade em `packages/kg/src/__fixtures__/` — a convenção Vitest/Jest.
#           O `grep -v '/fixtures/'` NÃO casa `__fixtures__`, então os 5 grafos DELIBERADAMENTE
#           inválidos (o teste do radar!) viraram 5 violações HARD da REGRA 52 no dia 1. As saídas
#           eram apagar o teste ou desligar a guarda — o modo-de-falha que a catraca existe p/ evitar.
#
# COMO    : uma classe NOMEADA de convenções de fixture (não "qualquer coisa com fixture no nome"),
#           num único lugar. A exemplaridade é auditável: `--list-exempt` mostra o que foi isentado,
#           para que uma isenção em massa não passe calada — é isso que impede a lista de virar
#           fail-open silencioso.
#
# USO     : source kg-fixture-paths.sh && kg_graphs [ROOT]     → grafos NÃO-fixture (1/linha)
#           kg-fixture-paths.sh --is-fixture <path>            → exit 0 se é fixture
#           kg-fixture-paths.sh --list-exempt [ROOT]           → os grafos isentados (auditoria)
#           kg-fixture-paths.sh --filter                       → filtra stdin
#           kg-fixture-paths.sh --selftest
# =============================================================================
set -uo pipefail

# A classe, explícita. Cada entrada é uma CONVENÇÃO de diretório de teste, não um palpite:
#   fixtures/ fixture/   — convenção geral (a do core)
#   __fixtures__/        — convenção Vitest/Jest (o achado de campo de 2026-09-05)
#   testdata/            — convenção Go, comum em monorepo poliglota
#   __snapshots__/       — snapshots de teste (nunca conhecimento)
#   vendor do KG-SSOT    — toda pasta com o carimbo `.kg-ssot-version` rastreado (regra pública da kg-ssot 4.20.0,
#                          ADOPTING: "uma pasta com .kg-ssot-version é o vendor, onde quer que ela esteja"; o
#                          carimbo na RAIZ do que se lê não conta). Até 2026-10-23 era o caminho fixo
#                          `vendor/kg-ssot/`, nascido do incidente de 2026-10-22: o grafo de exemplo da 4.19.0
#                          (spec/vocab-examples/) virou o corpus inteiro de uma porta sem grafo próprio com trace,
#                          o kg-trace-resolve devolveu índice vazio e o materialize-door abortou. O carimbo cobre o
#                          vendor em qualquer pasta, como as ferramentas do próprio KG-SSOT.
#                          CUSTO: UMA chamada de git ao carregar este arquivo (nunca por grafo). Fora de um repo git
#                          não há carimbo rastreado, e só as convenções acima valem.
KG_FIXTURE_BASE_RE='(^|/)(__)?fixtures?(__)?/|(^|/)testdata/|(^|/)__snapshots__/'

_kg_vendor_re() {   # imprime "(^|/)(d1|d2)/" com as pastas carimbadas, relativas à raiz do repo; nada se não houver
  local top f d alts=""
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || return 0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    d="${f%/*}"
    [ "$d" = "$f" ] && continue                                   # carimbo na raiz do que se lê não conta
    d="$(printf '%s' "$d" | sed 's/[][\.*^$+?(){}|]/\\&/g')"
    alts="${alts:+${alts}|}${d}"
  done < <(git -C "$top" ls-files -- '*.kg-ssot-version' 2>/dev/null)
  [ -n "$alts" ] && printf '(^|/)(%s)/' "$alts"
  return 0
}
KG_VENDOR_RE="$(_kg_vendor_re)"
KG_FIXTURE_RE="${KG_FIXTURE_BASE_RE}${KG_VENDOR_RE:+|${KG_VENDOR_RE}}"

kg_is_fixture() { grep -qE "${KG_FIXTURE_RE}" <<< "$1"; }

# MATERIAL DIDÁTICO (2026-10-06, sinal de campo de um adotante): `docs/materials/` guarda grafos de EXEMPLO,
# com dados fictícios (o example-domain: churn de 8% contra 3%), para ensinar adotante frio. Não é
# fixture — o radar e as catracas SEGUEM validando —, mas também não é CONHECIMENTO: uma leitura de
# corpus (kg-corpus-grep, o passo 0 do /warm-up) que o devolve como fato mente. Daí uma 2ª classe,
# usada só pelas LEITURAS de conhecimento.
KG_DIDACTIC_RE='(^|/)docs/materials/'

kg_graphs() {   # $1=ROOT (default: repo atual)
  local root="${1:-.}"
  (cd "${root}" && git ls-files '*.kg.yaml' 2>/dev/null | grep -vE "${KG_FIXTURE_RE}") || true
}

kg_fixture_graphs() {   # os ISENTADOS — a contrapartida auditável de kg_graphs
  local root="${1:-.}"
  (cd "${root}" && git ls-files '*.kg.yaml' 2>/dev/null | grep -E "${KG_FIXTURE_RE}") || true
}

# Sourcing vs execução: as funções acima são a API de biblioteca (`source … && kg_graphs`, uso
# documentado no cabeçalho). O dispatcher abaixo — e os `exit` dele, inclusive o fail-closed da
# MUDEZ — valem SÓ em execução direta; sem esta guarda, um `source` sem argumentos cairia no branch
# `""` e mataria o shell chamador com rc=2 (medido em 2026-09-05, ao aplicar a cura da mudez).
[ "${BASH_SOURCE[0]}" = "${0}" ] || return 0 2>/dev/null || true

case "${1:-}" in
  --is-fixture)  kg_is_fixture "${2:?uso: --is-fixture <path>}"; exit $? ;;
  --list-exempt) kg_fixture_graphs "${2:-.}"; exit 0 ;;
  --graphs)      kg_graphs "${2:-.}"; exit 0 ;;
  --filter)      grep -vE "${KG_FIXTURE_RE}" || true; exit 0 ;;
  # leitura de CONHECIMENTO: fora fixture E material didático (este segue validado pelo --filter)
  --filter-knowledge) grep -vE "${KG_FIXTURE_RE}" | grep -vE "${KG_DIDACTIC_RE}" || true; exit 0 ;;
  # espelho do --filter: os ISENTOS de stdin. Existe para o consumidor calcular a partição em UMA
  # passada em vez de um fork por arquivo (perf medida: 121 forks = +2,2 s no lint).
  --list-exempt-stdin) grep -E "${KG_FIXTURE_RE}" || true; exit 0 ;;
  --selftest)
    fails=0
    for p in \
      'packages/kg/src/__fixtures__/orphan.kg.yaml' \
      '.claude/validation/fixtures/bad.kg.yaml' \
      'a/fixture/x.kg.yaml' \
      'pkg/testdata/y.kg.yaml' \
      'ui/__snapshots__/z.kg.yaml'
    do
      if kg_is_fixture "$p"; then echo "  ✅ isenta: $p"; else echo "  ✗ NÃO isentou: $p"; fails=$((fails+1)); fi
    done
    # e o que NÃO pode ser isentado — senão a isenção vira fail-open
    for p in \
      'docs/onion/graph/fios-abertos.kg.yaml' \
      'docs/evolution/research/x-2026-09/x.kg.yaml' \
      'docs/onion/graph/fixtures-do-produto.kg.yaml' \
      'docs/mixtures/y.kg.yaml'
    do
      if kg_is_fixture "$p"; then echo "  ✗ isentou o que NÃO é fixture: $p"; fails=$((fails+1)); else echo "  ✅ NÃO isenta: $p"; fi
    done
    # material DIDÁTICO: fora da leitura de conhecimento, DENTRO da validação
    _k="$(printf '%s\n' docs/materials/cold-adopter-2026-07/example-domain.kg.yaml docs/onion/graph/fios-abertos.kg.yaml | "${BASH_SOURCE[0]}" --filter-knowledge)"
    _v="$(printf '%s\n' docs/materials/cold-adopter-2026-07/example-domain.kg.yaml | "${BASH_SOURCE[0]}" --filter)"
    if [ "${_k}" = "docs/onion/graph/fios-abertos.kg.yaml" ] && [ -n "${_v}" ]; then
      echo "  ✅ material didático: fora do --filter-knowledge, dentro do --filter (segue validado)"
    else echo "  ✗ material didático mal classificado (knowledge='${_k}' validação='${_v}')"; fails=$((fails+1)); fi
    # O CARIMBO do vendor (regra pública da kg-ssot 4.20.0): num repo de mentira, o vendor fora de vendor/ é isento,
    # a pasta sem carimbo não é, e o carimbo na raiz do repo não isenta o repo inteiro.
    _self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    _sb="$(mktemp -d)"
    (
      cd "${_sb}" && git init -q . && mkdir -p lib/terceiros/kgs/spec docs/kg docs/vendor-kg-ssot-notes \
        && : > lib/terceiros/kgs/.kg-ssot-version && : > .kg-ssot-version \
        && for f in lib/terceiros/kgs/spec/ex.kg.yaml docs/kg/real.kg.yaml docs/vendor-kg-ssot-notes/z.kg.yaml; do echo 'meta: {}' > "$f"; done \
        && git add -A >/dev/null 2>&1
    )
    _out="$(cd "${_sb}" && git ls-files '*.kg.yaml' | bash "${_self}" --filter | tr '\n' ' ')"
    _want='docs/kg/real.kg.yaml docs/vendor-kg-ssot-notes/z.kg.yaml '
    if [ "${_out}" = "${_want}" ]; then
      echo "  ✅ carimbo: vendor fora de vendor/ isento; pasta sem carimbo e carimbo na raiz não isentam"
    else echo "  ✗ carimbo mal aplicado (saiu '${_out}', esperado '${_want}')"; fails=$((fails+1)); fi
    rm -rf "${_sb}"
    [ "${fails}" -eq 0 ] && { echo "kg-fixture-paths selftest: OK"; exit 0; }
    echo "kg-fixture-paths selftest: ${fails} falha(s)"; exit 1 ;;
  "")
    echo "uso: kg-fixture-paths.sh --graphs|--list-exempt|--filter|--is-fixture <path>|--selftest" >&2; exit 2 ;;
  *)
    # MUDEZ é irmã da AUSÊNCIA — e o fail-closed só cobria uma. Sem este branch, um typo na flag
    # (`--filtre`) caía fora do `case`, o script saía 0 com STDOUT VAZIO, e o consumidor que canaliza
    # por aqui via ZERO grafos: verde por vacuidade, o defeito que este arquivo veio fechar.
    # Medido em 2026-09-05: um caractere bastava.
    echo "ERRO: flag desconhecida '$1' — recusando em vez de sair 0 com saída vazia (seria varredura VAZIA e verde por vacuidade). Use: --graphs|--list-exempt|--filter|--is-fixture <path>|--selftest" >&2
    exit 2 ;;
esac
