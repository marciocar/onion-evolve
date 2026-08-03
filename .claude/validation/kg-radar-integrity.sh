#!/usr/bin/env bash
# kg-radar-integrity.sh — REGRA 52: todo .kg.yaml do repo passa no radar de INTEGRIDADE.
#
# A PERGUNTA: os grafos do repo estão estruturalmente SÃOS **hoje** — todos eles, não só
# os que alguém tocou?
#
# ═══ POR QUE EXISTE (a lacuna medida em 2026-08-03) ═══
# O `kg-radar.sh` é o motor soberano dos grafos e o ÚNICO mecanismo que reprova CONTRADIÇÃO
# ESTRUTURAL (`--integrity`, exit 1): nó que recebe `REFUTES` e segue `status: confirmed`.
# E **nada o executava por cadência** — nem lint, nem CI, nem pre-commit.
#
# Ele chegava ao CI apenas de duas formas INDIRETAS e parciais:
#   · REGRA 43 (kg-born-marker) — só para os grafos que ALGUM doc cita em `kg:` no frontmatter;
#   · REGRA 31 (kg-view) — só para os grafos que têm lente gerada.
# Logo: um grafo que ninguém cita em migalha e que não tem lente NUNCA era verificado.
#
# ═══ A RULE JÁ CONVOCAVA — E POR QUE ISSO NÃO BASTA ═══
# `.claude/rules/kg-grammar.md:41` já manda `bash kg-radar.sh <arquivo> # exit 0 obrigatório`.
# Essa regra path-scoped é CERTA no propósito dela (ensinar a gramática ANTES de escrever, para
# a guarda não nascer verde-vazia), mas estruturalmente não pode dar três coisas:
#   (a) só carrega quando alguém TOCA um `.kg.yaml` — grafo não-tocado fica fora;
#   (b) depende do ator OBEDECER — o eixo que o corpus desta casa mediu falhando
#       (`posttooluse-exit-2-is-the-only-channel`, `shell-guard-paid-four-times-same-axis`);
#   (c) não pega DEGRADAÇÃO PASSIVA: um `REFUTES` que chega depois deixa o nó alvo em
#       contradição SEM QUE NINGUÉM EDITE o arquivo — nenhuma rule dispara aí.
# Este gate é a mesma convocação, promovida de cognitiva a MECÂNICA e desacoplada do ator.
#
# ═══ SEM CATRACA, E ISSO É UMA MEDIÇÃO, NÃO UM DESCUIDO ═══
# Medido em 2026-08-03: 51 grafos no escopo, **0 reprovam** `--integrity`. Não há passivo a
# tolerar, então a regra nasce LIMPA — qualquer regressão futura reprova na hora.
# A medição foi provada NÃO-VAZIA (o erro que a kg-grammar.md existe para prevenir): um grafo
# de teste com `REFUTES` sobre nó `confirmed` sai 1 com "✗ CONTRADIÇÃO"; fixture sã sai 0.
# Se um dia o passivo aparecer, o padrão da casa é baseline versionado (REGRAS 29/42/45/49).
#
# ═══ O QUE FAZ, E O QUE NÃO FAZ (limite honesto) ═══
# FAZ: reprova contradição ESTRUTURAL — a única classe que um script decide sozinho.
# NÃO FAZ: não julga se um `label` é VERDADE, nem se um `verified_at` é honesto. Isso é da
#          REGRA 49 (cadência de carimbo) e do `/meta:kg-freshness` (mede contra o vivo).
#          Mesma divisão declarada lá: o GATE cria a cadência, o WORKER testa a verdade.
#
# Descoberta dos grafos: `git ls-files '*.kg.yaml' | grep -v '/fixtures/'` — a forma canônica
# (`.claude/rules/kg-grammar.md`); o glob hardcoded que existia antes era 36% cego.
# `fixtures/` fica FORA por desenho: lá vivem grafos propositalmente inválidos que alimentam
# o lint-selftest — gateá-los reprovaria o repo por ter testes.
#
# ⚠ PONTO CEGO DECLARADO (achado na revisão de 2026-08-03): `git ls-files` só vê o RASTREADO.
# Um `.kg.yaml` recém-criado e ainda não commitado — o estado exato de uma investigação nova —
# é invisível a este gate. A irmã REGRA 29 usa `find` e por isso pega untracked (foi assim que
# ela flagrou um documento de análise minutos após ele nascer). Não trocamos aqui de propósito:
# o alvo desta regra é o ACERVO do repo, e o pre-commit roda depois do `git add`. Se o gap
# doer, a cura é `find` + filtro de `.git/`, não um segundo gate.
#
# Uso : bash .claude/validation/kg-radar-integrity.sh [<repo_root>] [--format tsv]
# TSV : sev<TAB>tag<TAB>path<TAB>msg   (mesmo contrato dos irmãos: 29, 42, 45, 49)
# Exit: 0 = sem HARD · 1 = HARD presente · 2 = erro de uso
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FMT=human
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FMT="${2:-human}"; shift ;;
    -*)       printf 'uso: %s [<repo_root>] [--format tsv]\n' "$0" >&2; exit 2 ;;
    *)        [ -d "$1" ] && REPO_ROOT="$(cd "$1" && pwd)" ;;
  esac
  shift
done

RADAR="${REPO_ROOT}/.claude/validation/kg-radar.sh"

emit() { # $1=sev $2=tag $3=path $4=msg
  if [ "${FMT}" = "tsv" ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
  elif [ "$1" = "HARD" ]; then  printf 'VIOLATION: %s: [kg-integridade/%s] %s\n' "$3" "$2" "$4"
  else                          printf 'SOFT: %s: [kg-integridade/%s] %s\n' "$3" "$2" "$4"; fi
}

cd "${REPO_ROOT}" || exit 2

# Sem o radar não há o que delegar — no-op gracioso (contrato dos irmãos: helper ausente não
# inventa veredito). Declarar que não sabe é o comportamento correto.
[ -f "${RADAR}" ] || exit 0

hard=0; total=0
while IFS= read -r g; do
  [ -n "${g}" ] || continue
  total=$(( total + 1 ))
  # A saída do radar é para o humano; aqui só o EXIT decide. Capturamos a linha da contradição
  # para a mensagem ser acionável (num grafo grande, "o arquivo tem problema" é inacionável).
  out="$(bash "${RADAR}" "${g}" --integrity 2>&1)"
  rc=$?
  if [ "${rc}" -ne 0 ]; then
    detalhe="$(printf '%s\n' "${out}" | grep -E '✗|CONTRADI' | head -2 | tr '\n' ' ' | sed 's/  */ /g')"
    emit HARD CONTRADICAO "${g}" \
      "grafo REPROVA no radar de integridade (exit ${rc}) — reconcilie antes de seguir: ${detalhe:-<sem detalhe; rode: bash .claude/validation/kg-radar.sh ${g} --integrity>}"
    hard=$(( hard + 1 ))
  fi
done < <(git ls-files '*.kg.yaml' | grep -v '/fixtures/')

if [ "${FMT}" != "tsv" ]; then
  printf '  [kg-integridade] grafos verificados: %s · reprovando: %s\n' "${total}" "${hard}"
  if [ "${hard}" -eq 0 ]; then
    printf '  [kg-integridade] sem contradicao estrutural em nenhum grafo do repo.\n'
  fi
fi

[ "${hard}" -eq 0 ]
