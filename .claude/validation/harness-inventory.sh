#!/usr/bin/env bash
# =============================================================================
# harness-inventory.sh — SSOT GERADA dos números do PRÓPRIO harness de validação
#
# Uso       : bash .claude/validation/harness-inventory.sh [--markdown|--json|--env]
#               --markdown (default) : tabela canônica para docs/onion/testing-inventory.md
#               --json               : objeto JSON (consumo por ferramenta)
#               --env                : pares KEY=VALUE (o lint sourça)
#
# POR QUE ESTE ARQUIVO EXISTE (dano medido em 2026-09-08, não incômodo estético)
#   Os números do harness viviam em COMENTÁRIO e divergiam entre si: `689 asserções` no
#   `onion-selftest.yml`, `689` de novo no `onion-validate.yml`, `~850` numa análise — e a
#   medição do dia dava 1135. Nenhum tinha gerador, nenhum tinha catraca, e todos foram
#   escritos por alguém que os mediu de verdade — na época. É a mesma classe do painel
#   inventado que esta onda apagou, um grau abaixo: não é ficção, é defasagem. As duas
#   enganam igual, e a defasagem engana por mais tempo porque um dia foi verdade.
#
# A DISTINÇÃO QUE DECIDE O DESENHO — o que EXISTE × o que RODOU
#   Este arquivo conta só o que EXISTE, estaticamente, do filesystem. Ele NÃO conta
#   asserções executadas, e a diferença não é detalhe: há 907 sítios estáticos de
#   `record_pass|record_fail|record_skip` no `lint-selftest.sh` contra 1135 asserções
#   efetivamente executadas — 228 vêm de sítios dentro de laços. Imprimir 907 como "o
#   tamanho da bancada" seria trocar uma defasagem por um erro de categoria.
#   O que RODOU é resultado de execução e vive na série histórica (`selftest-runs.jsonl`);
#   o painel (`testing-state.md`) mostra os dois LADO A LADO, cada um com seu produtor.
#
# CUSTO É DESENHO, PORQUE A CATRACA CHAMA ISTO A CADA LINT
#   Cronometrado: `rules-registry --counts` 0,05s · `consumed-mode-check --format tsv` 0,18s
#   · `git ls-files` 0,005s · `lint-selftest --list` **2,0s**. O `--list` é o modo que a
#   produção consome para enumerar famílias, e é caro demais para o gate. Então aqui as
#   famílias são contadas pelo `^_family ` estático (instantâneo) e a BANCADA prova que os
#   dois números são iguais. Sem essa prova, o barato poderia silenciosamente medir outra
#   coisa que o caro — que é como um harness deixa de espelhar o runner.
#
# FALHA ALTO, NUNCA PARCIAL. Produtor que morre derruba o gerador (exit 2) em vez de emitir
#   a linha zerada: uma SSOT que vale meio artefato é pior que nenhuma, porque a catraca
#   passaria a comparar bytes contra um estado degradado e o chamaria de verdade.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

_die() { echo "harness-inventory: $*" >&2; exit 2; }

# ---------------------------------------------------------------------------
# ENUMERAÇÃO RASTREADA — o mesmo conjunto que o CI vê. Contar por `find` incluiria arquivo
# gitignorado e o inventário local ficaria verde enquanto o CI, num checkout limpo, reprova.
# (Sinal de campo de um adotante, 2026-09-04, herdado do `inventory.sh`.)
# ---------------------------------------------------------------------------
_tracked() {   # $1 = pathspec
  if git -C "${REPO_ROOT}" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "${REPO_ROOT}" ls-files -- "$1"
  else
    _die "sem índice git — a enumeração seria de outro conjunto que o do CI. Recusa."
  fi
}
_count_tracked() { _tracked "$1" | grep -c . || true; }

SELFTEST="${SCRIPT_DIR}/lint-selftest.sh"
LINT="${SCRIPT_DIR}/lint-artifacts.sh"
MANIFEST="${SCRIPT_DIR}/fixtures/manifest.tsv"
[ -f "${SELFTEST}" ] || _die "lint-selftest.sh ausente"
[ -f "${LINT}" ]     || _die "lint-artifacts.sh ausente"
[ -f "${MANIFEST}" ] || _die "fixtures/manifest.tsv ausente"

# --- bancada ---------------------------------------------------------------
# `^_family ` é a DECLARAÇÃO de família; a bancada assere que bate com `--list`.
FAMILIES="$(grep -cE '^_family ' "${SELFTEST}" || true)"
[ "${FAMILIES}" -gt 0 ] || _die "zero famílias declaradas — o grep de \`^_family \` não casou nada"

# SÍTIOS, não asserções. O nome do campo diz o que ele é para que ninguém o cite como
# "tamanho da bancada" — foi exatamente assim que `689` sobreviveu três anos em comentário.
ASSERT_SITES="$(grep -cE '^\s*(record_pass|record_fail|record_skip) ' "${SELFTEST}" || true)"
[ "${ASSERT_SITES}" -gt 0 ] || _die "zero sítios de asserção — o padrão de record_* mudou?"

# --- fixtures --------------------------------------------------------------
# DUAS populações, e elas NÃO são a mesma. O manifesto é a tabela que dirige as famílias
# table-driven; o disco tem fixture de família que a lê direto. Publicar um número só
# obrigaria o leitor a adivinhar qual — e adivinhação em SSOT é como o `689` nasce.
FIXTURE_ROWS="$(awk -F'\t' '!/^#/ && NF && $1!="kind"{n++} END{print n+0}' "${MANIFEST}")"
FIXTURE_KINDS="$(awk -F'\t' '!/^#/ && NF && $1!="kind"{k[$1]=1} END{print length(k)+0}' "${MANIFEST}")"
FIXTURE_FILES="$(_tracked '.claude/validation/fixtures/*' | grep -vc 'manifest\.tsv' || true)"
[ "${FIXTURE_ROWS}" -gt 0 ] || _die "manifesto de fixtures sem linhas de dado"

# --- regras (delegado ao ÚNICO parser; ver o docstring de --counts lá) ------
RULES_ENV="$(bash "${SCRIPT_DIR}/rules-registry.sh" --counts)" \
  || _die "rules-registry.sh --counts falhou — sem ele a contagem de regras seria um 2º parser"
eval "${RULES_ENV}"
[ "${RULES_TOTAL:-0}" -gt 0 ] || _die "rules-registry devolveu zero regras"

# --- modo consumido (REGRA 59) ---------------------------------------------
# rc=1 é veredito ("há modo sem teste"), não erro; rc>=2 é erro de execução.
CM_RC=0
CM_OUT="$(bash "${SCRIPT_DIR}/consumed-mode-check.sh" "${REPO_ROOT}" 2>&1)" || CM_RC=$?
[ "${CM_RC}" -le 1 ] || _die "consumed-mode-check.sh saiu rc=${CM_RC} (erro de execução)"
CONSUMED_PAIRS="$(sed -n 's/.*pares de produção: \([0-9]\{1,\}\).*/\1/p' <<< "${CM_OUT}" | head -1)"
CONSUMED_UNTESTED="$(sed -n 's/.*sem teste: \([0-9]\{1,\}\).*/\1/p' <<< "${CM_OUT}" | head -1)"
[ -n "${CONSUMED_PAIRS}" ] || _die "não achei 'pares de produção: N' na saída do consumed-mode-check"
[ -n "${CONSUMED_UNTESTED}" ] || _die "não achei 'sem teste: N' na saída do consumed-mode-check"

# --- superfícies do gate ---------------------------------------------------
VALIDATION_SCRIPTS="$(_count_tracked '.claude/validation/*.sh')"
HOOKS="$(_count_tracked '.claude/hooks/*.sh')"
WORKFLOWS="$(_count_tracked '.github/workflows/*.yml')"
BASELINES="$(_count_tracked '.claude/validation/*-baseline.txt')"

# ---------------------------------------------------------------------------
# O ESTADO DA SÉRIE É MEDIDO, NÃO AFIRMADO.
# A 1ª versão desta seção tinha a frase "…`selftest-runs.jsonl`, que ainda não existe" como
# STRING ESTÁTICA no heredoc. O arquivo passou a existir no commit ANTERIOR desta mesma branch,
# e o gerador seguiu dizendo que não — para sempre, mesmo com centenas de execuções acumuladas.
# A REGRA 80 ficava VERDE porque ela compara o .md com o GERADOR, e era o gerador que mentia.
# Achado pela passada adversarial do PR, e é exatamente o painel inventado dentro do gerador que
# o substituiu: uma afirmação sobre o mundo, sem produtor, num arquivo cuja regra é não ter isso.
LEDGER_SERIE="${REPO_ROOT}/docs/onion/metrics/selftest-runs.jsonl"
if [ -s "${LEDGER_SERIE}" ]; then
  SERIE_N="$(grep -c '^{' "${LEDGER_SERIE}" || true)"
else
  SERIE_N=0
fi

emit_env() {
  cat <<EOF
HARNESS_FAMILIES=${FAMILIES}
HARNESS_ASSERT_SITES=${ASSERT_SITES}
HARNESS_FIXTURE_ROWS=${FIXTURE_ROWS}
HARNESS_FIXTURE_KINDS=${FIXTURE_KINDS}
HARNESS_FIXTURE_FILES=${FIXTURE_FILES}
HARNESS_RULES_TOTAL=${RULES_TOTAL}
HARNESS_RULES_HARD=${RULES_HARD}
HARNESS_RULES_SOFT=${RULES_SOFT}
HARNESS_RULES_BOTH=${RULES_BOTH}
HARNESS_CONSUMED_PAIRS=${CONSUMED_PAIRS}
HARNESS_CONSUMED_UNTESTED=${CONSUMED_UNTESTED}
HARNESS_VALIDATION_SCRIPTS=${VALIDATION_SCRIPTS}
HARNESS_HOOKS=${HOOKS}
HARNESS_WORKFLOWS=${WORKFLOWS}
HARNESS_BASELINES=${BASELINES}
EOF
}

emit_json() {
  cat <<EOF
{
  "families": ${FAMILIES},
  "assert_sites": ${ASSERT_SITES},
  "fixture_rows": ${FIXTURE_ROWS},
  "fixture_kinds": ${FIXTURE_KINDS},
  "fixture_files": ${FIXTURE_FILES},
  "rules_total": ${RULES_TOTAL},
  "rules_hard": ${RULES_HARD},
  "rules_soft": ${RULES_SOFT},
  "rules_both": ${RULES_BOTH},
  "consumed_pairs": ${CONSUMED_PAIRS},
  "consumed_untested": ${CONSUMED_UNTESTED},
  "validation_scripts": ${VALIDATION_SCRIPTS},
  "hooks": ${HOOKS},
  "workflows": ${WORKFLOWS},
  "baselines": ${BASELINES}
}
EOF
}

emit_markdown() {
  cat <<EOF
<!-- GENERATED BY .claude/validation/harness-inventory.sh — NÃO EDITE À MÃO. Rode \`bash .claude/validation/harness-inventory.sh --markdown > docs/onion/testing-inventory.md\` para regenerar. -->
# 🧪 Inventário do Harness de Validação

> **SSOT gerada do filesystem** — nenhum número aqui foi digitado. Qualquer contagem sobre o
> harness em comentário de workflow, doc ou análise **deriva deste arquivo**.
>
> **A regra desta página, e ela não tem exceção:** nenhuma célula é impressa sem o comando que
> a produz ao lado. Métrica sem produtor imprime \`⊘ NÃO MEDIDO\` — nunca um número.

## O que EXISTE (contado estaticamente)

| Dimensão | Nº | Produtor |
|----------|---:|----------|
| Famílias na bancada | **${FAMILIES}** | \`grep -cE '^_family ' .claude/validation/lint-selftest.sh\` |
| Sítios de asserção (**não** asserções executadas) | **${ASSERT_SITES}** | \`grep -cE '^\s*(record_pass\|record_fail\|record_skip) ' .claude/validation/lint-selftest.sh\` |
| Linhas do manifesto de fixtures | **${FIXTURE_ROWS}** | \`awk -F'\t' '!/^#/ && NF && \$1!="kind"' .claude/validation/fixtures/manifest.tsv\` |
| Kinds no manifesto | **${FIXTURE_KINDS}** | idem, \`length(k)\` da coluna 1 |
| Arquivos de fixture rastreados | **${FIXTURE_FILES}** | \`git ls-files '.claude/validation/fixtures/*'\` menos o manifesto |
| Regras do lint | **${RULES_TOTAL}** | \`bash .claude/validation/rules-registry.sh --counts\` |
| — das quais HARD | **${RULES_HARD}** | idem |
| — das quais SOFT | **${RULES_SOFT}** | idem |
| — HARD **e** SOFT (contadas nas duas) | **${RULES_BOTH}** | idem |
| Pares de modo consumido (REGRA 59) | **${CONSUMED_PAIRS}** | \`bash .claude/validation/consumed-mode-check.sh .\` |
| — sem teste | **${CONSUMED_UNTESTED}** | idem |
| Scripts de validação | **${VALIDATION_SCRIPTS}** | \`git ls-files '.claude/validation/*.sh'\` |
| Hooks | **${HOOKS}** | \`git ls-files '.claude/hooks/*.sh'\` |
| Workflows de CI | **${WORKFLOWS}** | \`git ls-files '.github/workflows/*.yml'\` |
| Baselines de catraca | **${BASELINES}** | \`git ls-files '.claude/validation/*-baseline.txt'\` |

## O que RODOU

Este arquivo conta o que **existe**. Quantas asserções de fato **passaram** é resultado de
execução, vive em \`docs/onion/metrics/selftest-runs.jsonl\` (**${SERIE_N}** envelope(s)
coletado(s)) e é projetado em [\`testing-state.md\`](testing-state.md).

A distinção não é formalismo. Há **${ASSERT_SITES}** sítios estáticos de asserção e a última
execução completa contou **mais** que isso, porque sítio dentro de laço dispara N vezes.
Publicar o número estático como "tamanho da bancada" trocaria uma defasagem por um erro de
categoria — e foi por confundir os dois que \`689 asserções\` sobreviveu em três comentários
de CI depois de ter deixado de ser verdade.

Para medir agora, sem esperar a série:

\`\`\`bash
ONION_SELFTEST_STRICT=1 bash .claude/validation/lint-selftest.sh --jobs auto --report /tmp/r.tsv
grep -P '^TOTAL\t' /tmp/r.tsv
\`\`\`

## Fronteiras declaradas

- **Estático só.** Nada aqui executa a bancada — a catraca da REGRA 62 (Projeção GERADA em
  sincronia com a fonte) chama este gerador a cada lint, e uma rodada de 10 minutos por lint
  não é gate, é bloqueio.
- **Famílias contadas pelo \`^_family \`, não pelo \`--list\`.** O modo que a produção consome
  custa ~2s; o grep é instantâneo. A **bancada** prova que os dois dão o mesmo número — sem
  essa prova, o barato poderia medir outra coisa que o caro.
- **Duas populações de fixture, de propósito.** Manifesto (tabela que dirige famílias
  table-driven) e disco (inclui fixture de família que a lê direto) não são a mesma coisa.
- **Falha alto.** Produtor que morre derruba o gerador; nenhuma linha é emitida zerada.
EOF
}

case "${1:---markdown}" in
  --env)      emit_env ;;
  --json)     emit_json ;;
  --markdown) emit_markdown ;;
  *) echo "uso: harness-inventory.sh [--markdown|--json|--env]" >&2; exit 2 ;;
esac
