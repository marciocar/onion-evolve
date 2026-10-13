#!/usr/bin/env bash
# =============================================================================
# testing-state.sh — O PAINEL (ONDA 0.7), gerado dos produtores de 0.2–0.6
#
# Uso : bash .claude/validation/testing-state.sh --markdown > docs/onion/testing-state.md   # o VERSIONADO
#       bash .claude/validation/testing-state.sh --live                                     # os números, NA HORA
#
# ─────────────────────────────────────────────────────────────────────────────
# DOIS MODOS, E POR QUE O VERSIONADO NÃO CARREGA OS CONTADORES (passo A de D_MERGE_PROCESS_ONION_2026_10,
# selado pelo maestro em 2026-10-13; grafo docs/evolution/research/merge-process-onion-2026-10/)
#   Medido em 2026-10-13 sobre as 80 últimas versões do painel em origin/main: as linhas que mudavam de
#   versão para versão eram os contadores GLOBAIS — "Vereditos no vocabulário" (65 de 79 trocas),
#   "Resíduos de revisão" (62), "Tokens por achado REAL" (57), "Achados totais/REAIS" (55),
#   "Sítios de asserção" (54), "Famílias na bancada" (36), "Pares de modo consumido" (23), "Regras do
#   lint"/"HARD" (21). Todo PR acrescenta um resíduo de revisão (REGRA 56) e muitos acrescentam
#   asserções, então o painel entrava em 59 de 60 PRs e DOIS PRs paralelos quaisquer colidiam nele —
#   nenhuma fila de merge cura isso, porque a fila ejeta o PR em conflito.
#   A cura é tirar do arquivo versionado o que todo PR muda:
#     --markdown  o painel VERSIONADO. As seções 1 e 4 (contadores das fontes que todo PR toca) imprimem
#                 a célula `↻ ao vivo` com o COMANDO ao lado; o número não mora NESTE arquivo (os da seção 1
#                 seguem versionados em testing-inventory.md, que é o passo B). O que muda raro
#                 (a série coletada, flaky, as fronteiras) continua impresso. Produtor que falha continua
#                 virando `⊘ NÃO MEDIDO` — então a catraca ainda acusa produtor quebrado.
#     --live      o MESMO painel com os números, calculados na hora por quem lê. Nunca versionado: se
#                 alguém gravar esta saída no arquivo (ou digitar um número numa célula `↻`), a catraca
#                 byte-a-byte da REGRA 81 reprova, porque o versionado é a saída de --markdown.
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
case "${MODE}" in
  --markdown) LIVE=0 ;;
  --live) LIVE=1 ;;
  *) echo "uso: testing-state.sh [--markdown|--live]" >&2; exit 2 ;;
esac
[ $# -le 1 ] || { echo "uso: testing-state.sh [--markdown|--live] (um modo só)" >&2; exit 2; }

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

# Contador de fonte que TODO PR muda (resíduos, asserções, famílias, regras): no versionado vira
# `↻ ao vivo` — o comando continua ao lado (defesa 1), o número só existe na saída de --live.
_vol() {   # $1=rótulo $2=valor $3=comando
  if [ "${LIVE}" -eq 1 ]; then _cel "$1" "$2" "$3"; else _cel "$1" "↻ ao vivo" "$3"; fi
}
_nota_viva() {   # $1 = onde MAIS o número mora no git (vazio = em lugar nenhum). Sem afirmar além do medido.
  [ "${LIVE}" -eq 1 ] && return 0
  if [ -n "${1:-}" ]; then
    printf '\n> `↻ ao vivo`: o número muda a cada PR, então **não mora neste painel** (ainda é versionado em\n'
    printf '> %s) — versioná-lo aqui punha este painel em quase todo PR e fazia dois PRs\n' "$1"
  else
    printf '\n> `↻ ao vivo`: o número muda a cada PR, então **não mora no git** — versioná-lo punha este\n'
    printf '> painel em quase todo PR e fazia dois PRs\n'
  fi
  printf '> paralelos colidirem nele (passo A de `D_MERGE_PROCESS_ONION_2026_10`). Para ler:\n'
  printf '> `bash .claude/validation/testing-state.sh --live`.\n'
}

if [ "${LIVE}" -eq 1 ]; then
  cat <<EOF
<!-- SAÍDA AO VIVO de .claude/validation/testing-state.sh --live — NÃO VERSIONE: o arquivo versionado é a saída de --markdown, e a catraca da REGRA 81 reprova esta. -->
EOF
else
  cat <<EOF
<!-- GENERATED BY .claude/validation/testing-state.sh — NÃO EDITE À MÃO. Rode \`bash .claude/validation/testing-state.sh --markdown > docs/onion/testing-state.md\` para regenerar. -->
EOF
fi
cat <<EOF
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
  _vol "Famílias na bancada"          "${HARNESS_FAMILIES}"        "bash .claude/validation/harness-inventory.sh --env"
  _vol "Sítios de asserção (estáticos)" "${HARNESS_ASSERT_SITES}"  "bash .claude/validation/harness-inventory.sh --env"
  _vol "Regras do lint"               "${HARNESS_RULES_TOTAL}"     "bash .claude/validation/rules-registry.sh --counts"
  _vol "— HARD"                       "${HARNESS_RULES_HARD}"      "bash .claude/validation/rules-registry.sh --counts"
  _vol "Pares de modo consumido"      "${HARNESS_CONSUMED_PAIRS}"  "bash .claude/validation/consumed-mode-check.sh ."
  _vol "— sem teste"                  "${HARNESS_CONSUMED_UNTESTED}" "bash .claude/validation/consumed-mode-check.sh ."
  _vol "Baselines de catraca"         "${HARNESS_BASELINES}"       "git ls-files '.claude/validation/*-baseline.txt'"
  _nota_viva '`testing-inventory.md`, a projeção do inventário — passo B'
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
  _vol "Resíduos de revisão"          "${R56_RESIDUOS}"               "bash .claude/validation/review-ledger.sh --env"
  _vol "Achados totais"               "${R56_ACHADOS}"                "bash .claude/validation/review-ledger.sh --env"
  _vol "Achados REAIS"                "${R56_ACHADOS_REAIS}"          "bash .claude/validation/review-ledger.sh --env"
  _vol "Precisão (reais/totais)"      "${R56_PRECISAO_PCT}%"          "bash .claude/validation/review-ledger.sh --env"
  _vol "Tokens por achado REAL"       "${R56_TOKENS_POR_ACHADO_REAL}" "bash .claude/validation/review-ledger.sh --env"
  _vol "Vereditos no vocabulário"     "${R56_VOCAB_OK}"               "bash .claude/validation/review-ledger.sh --env"
  _vol "— legado (texto livre)"       "${R56_VOCAB_LEGADO}"           "bash .claude/validation/review-ledger.sh --env"
  _nota_viva
  if [ "${LIVE}" -eq 1 ]; then
    printf '\nA média de tokens cobre os **%s** resíduos com custo > 0; os demais declaram `tokens: 0`\n' "${R56_COM_TOKENS}"
  else
    printf '\nA média de tokens cobre só os resíduos com custo > 0 (a contagem sai em `--live`); os demais declaram `tokens: 0`\n'
  fi
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
