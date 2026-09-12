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
# Descoberta dos grafos: `git ls-files '*.kg.yaml'` filtrado pelo predicado ÚNICO
# `kg-fixture-paths.sh --filter` — a forma canônica (`.claude/rules/kg-grammar.md`); o glob
# hardcoded que existia antes era 36% cego.
# FIXTURE fica FORA por desenho: lá vivem grafos propositalmente inválidos que alimentam o teste
# — gateá-los reprovaria o repo por TER testes. E a isenção deixou de ser um `grep -v '/fixtures/'`
# copiado em seis lugares: um adotante que portou o radar para JS pôs as fixtures em
# `packages/kg/src/__fixtures__/` (convenção Vitest), o grep não casou, e os 5 grafos inválidos
# viraram 5 HARD no dia 1 da adoção dele (medido 2026-09-05). O predicado cobre a CLASSE de
# convenções e é auditável por `--list-exempt` — isenção em massa não passa calada.
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

# Predicado de FIXTURE — caminho ABSOLUTO resolvido ANTES de qualquer `cd`, e ausência é FAIL-CLOSED.
# (A 1ª ligação usava `$(dirname "${BASH_SOURCE[0]}")` no ponto de uso e morria depois de um `cd`:
#  o erro era engolido por `|| true` e o script dizia "nenhum grafo" — verde por vacuidade. 2026-09-05.)
_KFP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kg-fixture-paths.sh"
[ -f "${_KFP}" ] || { echo "ERRO: predicado de fixture ausente (${_KFP}) — sem ele a varredura de grafos ficaria VAZIA e verde por vacuidade." >&2; exit 2; }

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

hard=0; total=0; proposta=0; fora=0
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
  elif grep -q 'MODO PROPOSTA' <<< "${out}"; then
    # ⚠️ RELAXAMENTO NÃO PODE DESAPARECER AQUI. Achado adversarial 2026-09-11: o `kg-radar.sh`
    #    declara no código que o MODO PROPOSTA "nunca é silencioso" — e era, exatamente neste
    #    gate, que é o único que roda por CADÊNCIA. Como o modo sai rc=0, o `out` era descartado
    #    e este laço imprimia "sem contradicao estrutural em nenhum grafo do repo" sobre um
    #    grafo com duas cobranças DESLIGADAS por auto-declaração do próprio arquivo.
    #    É o ✅ inventado que esta onda persegue, uma camada acima — e num gate de cadência ele
    #    dura até alguém desconfiar, que é a definição de invisível.
    proposta=$(( proposta + 1 ))
    # ESCOPO: dentro da fila de propostas o relaxamento É o contrato documentado, e avisar a cada
    # rodada é ruído que treina a pessoa a ignorar o aviso — o oposto do que esta cura quer. Lá o
    # grafo é CONTADO (o resumo abaixo o mostra) mas não gera linha. FORA da fila, cada um é
    # nomeado: é ali que o relaxamento não deveria estar acontecendo.
    case "${g}" in
      *docs/evolution/kg-inbox/*) continue ;;
    esac
    fora=$(( fora + 1 ))
    emit SOFT MODO-PROPOSTA "${g}" \
      "grafo passou em MODO PROPOSTA — grau 0 e referência para fora do arquivo NÃO foram cobrados aqui ($(sed -n 's/^[[:space:]]*ℹ[[:space:]]*\(relaxado pelo MODO PROPOSTA.*\)/\1/p' <<< "${out}" | head -1 || true)). Isto é legítimo num fragmento da fila de propostas e SUSPEITO em qualquer outro lugar: o gate do grafo fechado é a SELAGEM"
  fi
# ⚠️ A isenção de FIXTURE vem do predicado ÚNICO kg-fixture-paths.sh (2026-09-05): antes cada
#    consumidor repetia `grep -v '/fixtures/'` e o `__fixtures__/` do Vitest ESCAPAVA — 5 grafos
#    deliberadamente inválidos de um adotante viraram 5 HARD no dia 1 da adoção dele.
done < <(git ls-files '*.kg.yaml' | bash "${_KFP}" --filter)

if [ "${FMT}" != "tsv" ]; then
  printf '  [kg-integridade] grafos verificados: %s · reprovando: %s\n' "${total}" "${hard}"
  if [ "${proposta}" -gt 0 ]; then
    printf '  [kg-integridade] %s grafo(s) em MODO PROPOSTA (%s fora da fila kg-inbox) — cobranças de grafo FECHADO relaxadas ali.\n' "${proposta}" "${fora}"
  fi
  if [ "${hard}" -eq 0 ]; then
    if [ "${proposta}" -gt 0 ]; then
      # O resumo NAO pode dizer "nenhum" quando houve relaxamento: seria a mesma frase para dois
      # fatos diferentes, e quem le o gate por cadencia so ve a frase.
      printf '  [kg-integridade] sem contradicao estrutural nos grafos COBRADOS (ver os em MODO PROPOSTA acima).\n'
    else
      printf '  [kg-integridade] sem contradicao estrutural em nenhum grafo do repo.\n'
    fi
  fi
fi

[ "${hard}" -eq 0 ]
