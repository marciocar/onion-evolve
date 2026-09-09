#!/usr/bin/env bash
# =============================================================================
# testing-state.sh — O PAINEL (ONDA 0.7), gerado dos produtores de 0.2–0.6
#
# Uso : bash .claude/validation/testing-state.sh --markdown > docs/onion/testing-state.md
#
# ─────────────────────────────────────────────────────────────────────────────
# ESTE ARQUIVO EXISTE PORQUE O PRIMEIRO PAINEL FOI INVENTADO
#   `docs/onion/testing-validation-system.md` publicava um dashboard ASCII com
#   `Coverage: 85% · Unit Tests: 247 · Mutation: 74% · Bugs Found: 12`. Nenhum daqueles números
#   tinha produtor: eram as METAS da seção anterior redesenhadas como MEDIÇÃO, num documento
#   sobre testes. Ficou lá até 2026-09-08. O cadáver do primeiro painel é a razão de existir
#   das cinco defesas abaixo — elas não são cerimônia, são autópsia.
#
# AS CINCO DEFESAS, e o que cada uma impede
#   1. TODA célula carrega o COMANDO que a produz. Célula sem comando NÃO É IMPRESSA. É o que
#      teria impedido `Coverage: 85%` de nascer: ninguém consegue escrever o comando de um
#      número que não mediu.
#   2. CATRACA byte-a-byte (REGRA 81). Editar o .md à mão reprova HARD.
#   3. TERCEIRO DESFECHO: métrica sem produtor imprime `⊘ NÃO MEDIDO`, nunca um número — nem
#      zero. Zero é uma afirmação sobre o mundo; ausência de medição não é.
#   4. GUARDA DE VACUIDADE: se TODOS os produtores falharem, o gerador sai ≠0 em vez de emitir
#      um painel vazio. Painel vazio e catracado é pior que painel nenhum — vira verde por
#      vacuidade, que é o modo de falha que esta casa mais persegue.
#   5. O painel declara a IDADE da própria medição.
#
# ⚠️ A DEFESA 5 NÃO IMPRIME "HOJE", E ISSO É DECISÃO, NÃO ESQUECIMENTO
#   O plano pedia "data do último envelope vs. hoje". Um artefato que imprime a data de hoje
#   MUDA TODO DIA — e com catraca byte-a-byte isso significa uma violação HARD por dia, todo
#   dia, sem que nada tenha acontecido. Guarda que grita sem motivo treina o leitor a ignorá-la,
#   e aí ela não serve para o dia em que o motivo existe. Então: o painel imprime a data do
#   ÚLTIMO ENVELOPE (determinística, vem do dado) e declara a cadência esperada. O relógio fica
#   com QUEM LÊ e com o cron, nunca dentro do arquivo versionado.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LEDGER="${REPO_ROOT}/docs/onion/metrics/selftest-runs.jsonl"

MODE="${1:---markdown}"
case "${MODE}" in --markdown) : ;; *) echo "uso: testing-state.sh [--markdown]" >&2; exit 2 ;; esac

# ---------------------------------------------------------------------------
# Cada produtor é tentado; a falha de UM vira ⊘ NÃO MEDIDO naquela seção, e a de TODOS derruba
# o gerador (defesa 4). O contador `VIVOS` é o que separa uma coisa da outra.
# ---------------------------------------------------------------------------
VIVOS=0

HARNESS_OK=0
if HARNESS_ENV="$(bash "${SCRIPT_DIR}/harness-inventory.sh" --env 2>/dev/null)"; then
  eval "${HARNESS_ENV}"; HARNESS_OK=1; VIVOS=$((VIVOS+1))
fi

R56_OK=0
if R56_ENV="$(bash "${SCRIPT_DIR}/review-ledger.sh" --env 2>/dev/null)"; then
  eval "${R56_ENV}"; R56_OK=1; VIVOS=$((VIVOS+1))
fi

SERIE_OK=0
if [ -f "${LEDGER}" ] && [ -s "${LEDGER}" ]; then
  if SERIE="$(python3 - "${LEDGER}" 2>/dev/null <<'PY'
import json, sys
ls = [json.loads(l) for l in open(sys.argv[1], encoding='utf-8') if l.strip().startswith('{')]
if not ls:
    sys.exit(1)
u = ls[-1]
print(f"SERIE_N={len(ls)}")
print(f"SERIE_DIA={u['dia']}")
print(f"SERIE_PASS={u['pass']}")
print(f"SERIE_FAIL={u['fail']}")
print(f"SERIE_SKIP={u['skip']}")
print(f"SERIE_FAMILIAS={u['familias']}")
print(f"SERIE_SEG={u['segundos']}")
print(f"SERIE_SOURCE={u['source']}")
print(f"SERIE_SHA={u['sha'][:8]}")
# Uma família só é FLAKY se falhou em ALGUMA execução e passou em outra. Falhar sempre é
# defeito, e chamar defeito de flaky é como o mecanismo aprende a ignorar o vermelho.
viu, caiu = {}, {}
for e in ls:
    for f in e['familias_detalhe']:
        viu[f['familia']] = viu.get(f['familia'], 0) + 1
        if f['fail'] > 0:
            caiu[f['familia']] = caiu.get(f['familia'], 0) + 1
flaky = [k for k, v in caiu.items() if v < viu[k]]
print(f"SERIE_FLAKY={len(flaky)}")
print(f"SERIE_SEMPRE_VERMELHA={len([k for k, v in caiu.items() if v >= viu[k]])}")
PY
  )"; then
    eval "${SERIE}"; SERIE_OK=1; VIVOS=$((VIVOS+1))
  fi
fi

# DEFESA 4 — vacuidade. Nenhum produtor vivo ⇒ recusa, em vez de painel vazio catracado.
if [ "${VIVOS}" -eq 0 ]; then
  echo "testing-state: NENHUM produtor respondeu (harness-inventory, review-ledger, série)." >&2
  echo "  Emitir um painel vazio aqui o tornaria VERDE POR VACUIDADE — e a catraca passaria a" >&2
  echo "  comparar bytes contra o nada, chamando isso de estado. Recusa alto." >&2
  exit 2
fi

_cel() {   # $1=rótulo $2=valor $3=comando — DEFESA 1: sem comando, a linha não sai
  [ -n "${3:-}" ] || return 0
  printf '| %s | **%s** | `%s` |\n' "$1" "$2" "$3"
}

cat <<EOF
<!-- GENERATED BY .claude/validation/testing-state.sh — NÃO EDITE À MÃO. Rode \`bash .claude/validation/testing-state.sh --markdown > docs/onion/testing-state.md\` para regenerar. -->
# 🧪 Estado dos Testes do Onion

> **Nenhum número desta página foi digitado.** Cada célula carrega o comando que a produz, ao
> lado. Métrica sem produtor imprime \`⊘ NÃO MEDIDO\` — nunca um número, nem zero.
>
> Este painel existe porque o anterior era **inventado**: até 2026-09-08 o repo publicava
> \`Coverage: 85% · Unit Tests: 247 · Mutation: 74%\` sem nenhum produtor — eram metas
> redesenhadas como medição, num documento sobre testes. As defesas aqui são autópsia daquilo.

## 1. O que EXISTE (contagem estática)

EOF

if [ "${HARNESS_OK}" -eq 1 ]; then
  printf '| Dimensão | Nº | Produtor |\n|---|---:|---|\n'
  _cel "Famílias na bancada"          "${HARNESS_FAMILIES}"        "bash .claude/validation/harness-inventory.sh --env"
  _cel "Sítios de asserção (estáticos)" "${HARNESS_ASSERT_SITES}"  "bash .claude/validation/harness-inventory.sh --env"
  _cel "Regras do lint"               "${HARNESS_RULES_TOTAL}"     "bash .claude/validation/rules-registry.sh --counts"
  _cel "— HARD"                       "${HARNESS_RULES_HARD}"      "bash .claude/validation/rules-registry.sh --counts"
  _cel "Pares de modo consumido"      "${HARNESS_CONSUMED_PAIRS}"  "bash .claude/validation/consumed-mode-check.sh ."
  _cel "— sem teste"                  "${HARNESS_CONSUMED_UNTESTED}" "bash .claude/validation/consumed-mode-check.sh ."
  _cel "Baselines de catraca"         "${HARNESS_BASELINES}"       "git ls-files '.claude/validation/*-baseline.txt'"
  printf '\nDetalhe completo: [`testing-inventory.md`](testing-inventory.md) (SSOT gerada, catracada).\n'
else
  printf '⊘ **NÃO MEDIDO** — `harness-inventory.sh --env` não respondeu.\n'
fi

cat <<EOF

## 2. O que RODOU (última execução da bancada)

EOF

if [ "${SERIE_OK}" -eq 1 ]; then
  printf '| Medida | Valor | Produtor |\n|---|---:|---|\n'
  _cel "Asserções que passaram" "${SERIE_PASS}"     "bash ops/testing/collect-selftest.sh --resumo"
  _cel "Falharam"               "${SERIE_FAIL}"     "bash ops/testing/collect-selftest.sh --resumo"
  _cel "Pularam (⊘)"            "${SERIE_SKIP}"     "bash ops/testing/collect-selftest.sh --resumo"
  _cel "Famílias distintas"     "${SERIE_FAMILIAS}" "bash ops/testing/collect-selftest.sh --resumo"
  _cel "Duração (s)"            "${SERIE_SEG}"      "bash ops/testing/collect-selftest.sh --resumo"
  printf '\n'
  printf -- '- **última medição: %s** · origem `%s` · árvore `%s`\n' "${SERIE_DIA}" "${SERIE_SOURCE}" "${SERIE_SHA}"
  printf -- '- execuções na série: **%s**\n' "${SERIE_N}"
  printf -- '- cadência esperada: a bancada roda **todo dia** na main (`onion-selftest.yml`, `schedule: 17 4 * * *`)\n'
  printf -- '  e em cada pre-commit. Um envelope muito mais velho que isso significa que a COLETA parou —\n'
  printf -- '  não que a bancada parou.\n\n'
  printf '> Esta página **não imprime a data de hoje**, de propósito: um artefato catracado que\n'
  printf '> carrega "hoje" muda todo dia e produz uma violação HARD diária sem que nada tenha\n'
  printf '> acontecido. Guarda que grita sem motivo ensina a ignorá-la. O relógio fica com quem lê.\n'
else
  printf '⊘ **NÃO MEDIDO** — não há série coletada.\n\n'
  printf 'Isto **não é** "zero falhas": é ausência de medição. Para medir:\n\n'
  printf '```bash\nONION_SELFTEST_STRICT=1 bash .claude/validation/lint-selftest.sh --jobs auto --report /tmp/r.tsv\nbash ops/testing/collect-selftest.sh --report /tmp/r.tsv --source local\n```\n'
fi

cat <<EOF

## 3. Flaky

EOF

if [ "${SERIE_OK}" -eq 1 ]; then
  if [ "${SERIE_N}" -lt 10 ]; then
    printf '⊘ **NÃO MEDIDO** — %s execução(ões) na série.\n\n' "${SERIE_N}"
    printf 'Flaky é uma propriedade da REPETIÇÃO: mede-se em dezenas de execuções, não em unidades.\n'
    printf 'Com esta amostra, "nenhuma falha" seria **ausência de observação** apresentada como saúde —\n'
    printf 'exatamente o que o painel anterior fazia. Produtor: `bash ops/testing/collect-selftest.sh --flaky`.\n'
  else
    printf '| Classe | Nº | Produtor |\n|---|---:|---|\n'
    _cel "Famílias FLAKY (falharam em algumas)"   "${SERIE_FLAKY}"           "bash ops/testing/collect-selftest.sh --flaky"
    _cel "SEMPRE vermelhas (defeito, não flaky)"  "${SERIE_SEMPRE_VERMELHA}" "bash ops/testing/collect-selftest.sh --flaky"
    printf '\nFalhar em ALGUMAS execuções é flaky; falhar em TODAS é defeito. Chamar defeito de flaky é\n'
    printf 'como o mecanismo aprende a ignorar o vermelho.\n'
  fi
else
  printf '⊘ **NÃO MEDIDO** — sem série não há detector.\n'
fi

cat <<EOF

## 4. Custo e retorno da revisão de IA (REGRA 56)

EOF

if [ "${R56_OK}" -eq 1 ]; then
  printf '| Medida | Valor | Produtor |\n|---|---:|---|\n'
  _cel "Resíduos de revisão"          "${R56_RESIDUOS}"               "bash .claude/validation/review-ledger.sh --env"
  _cel "Achados totais"               "${R56_ACHADOS}"                "bash .claude/validation/review-ledger.sh --env"
  _cel "Achados REAIS"                "${R56_ACHADOS_REAIS}"          "bash .claude/validation/review-ledger.sh --env"
  _cel "Precisão (reais/totais)"      "${R56_PRECISAO_PCT}%"          "bash .claude/validation/review-ledger.sh --env"
  _cel "Tokens por achado REAL"       "${R56_TOKENS_POR_ACHADO_REAL}" "bash .claude/validation/review-ledger.sh --env"
  _cel "Vereditos no vocabulário"     "${R56_VOCAB_OK}"               "bash .claude/validation/review-ledger.sh --env"
  _cel "— legado (texto livre)"       "${R56_VOCAB_LEGADO}"           "bash .claude/validation/review-ledger.sh --env"
  printf '\nA média de tokens cobre os **%s** resíduos com custo > 0; os demais declaram `tokens: 0`\n' "${R56_COM_TOKENS}"
  printf '(custo zero DECLARADO, que não é ausência) e ficam fora da média porque divisão por zero\n'
  printf 'não é média — mas seus achados continuam contados no total.\n'
else
  printf '⊘ **NÃO MEDIDO** — `review-ledger.sh --env` não respondeu.\n'
fi

cat <<EOF

## 5. O que este painel NÃO mede

Declarado para que a ausência não seja lida como zero:

- **Cobertura de código** — não existe suíte de teste de código neste repo (sem pytest, jest,
  playwright ou bats). O que existe é bancada de GUARDAS. \`⊘ NÃO MEDIDO\`, e é honesto.
- **Mutação** — há provas de mutação pontuais dentro de famílias, não uma taxa agregada.
- **E2E de superfície web** (site, LibreChat, bridge) — nenhum. É o escopo da pesquisa R1.
- **Concordância IA × gate determinístico** — os dados existem nos resíduos, o comparador não.
- **Acessibilidade** — o WCAG é calculado só sobre pares declarados em \`contrast-pairs.json\`;
  fora dessa lista, \`⊘ NÃO MEDIDO\`.

<sub>Painel gerado por \`.claude/validation/testing-state.sh\` a partir de
\`harness-inventory.sh\`, \`review-ledger.sh\` e \`docs/onion/metrics/selftest-runs.jsonl\`.
Produtores vivos nesta geração: ${VIVOS}/3.</sub>
EOF
