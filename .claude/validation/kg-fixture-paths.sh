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
KG_FIXTURE_RE='(^|/)(__)?fixtures?(__)?/|(^|/)testdata/|(^|/)__snapshots__/'

kg_is_fixture() { printf '%s\n' "$1" | grep -qE "${KG_FIXTURE_RE}"; }

kg_graphs() {   # $1=ROOT (default: repo atual)
  local root="${1:-.}"
  (cd "${root}" && git ls-files '*.kg.yaml' 2>/dev/null | grep -vE "${KG_FIXTURE_RE}") || true
}

kg_fixture_graphs() {   # os ISENTADOS — a contrapartida auditável de kg_graphs
  local root="${1:-.}"
  (cd "${root}" && git ls-files '*.kg.yaml' 2>/dev/null | grep -E "${KG_FIXTURE_RE}") || true
}

case "${1:-}" in
  --is-fixture)  kg_is_fixture "${2:?uso: --is-fixture <path>}"; exit $? ;;
  --list-exempt) kg_fixture_graphs "${2:-.}"; exit 0 ;;
  --graphs)      kg_graphs "${2:-.}"; exit 0 ;;
  --filter)      grep -vE "${KG_FIXTURE_RE}" || true; exit 0 ;;
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
    [ "${fails}" -eq 0 ] && { echo "kg-fixture-paths selftest: OK"; exit 0; }
    echo "kg-fixture-paths selftest: ${fails} falha(s)"; exit 1 ;;
esac
