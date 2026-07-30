#!/usr/bin/env bash
# =============================================================================
# doctrine-freshness.sh — GATE DE FRESCOR DOUTRINÁRIO (irmão TEMPORAL da proveniência)
#
# LIMITE   : este gate NÃO pergunta "esta afirmação ainda é verdade?" — isso seria
#            um NO-OP no CI (runner sem rede) e impossível de decidir com o repo.
#            Ele verifica que toda afirmação sensível-ao-tempo carrega verified_at
#            (+ source) no frontmatter e que a data NÃO EXPIROU. Ele FORÇA a
#            re-verificação periódica; quem RE-VERIFICA de fato (contra a web) é a
#            sessão / kb-freshness, NUNCA o gate. Assim ele é CI-safe e determinístico.
#            Não leia "fresco" como "conferido" — leia como "carimbado e dentro do TTL".
#
# Propósito : Espelho TEMPORAL da REGRA 29 (kg-provenance-coverage.sh). A 29 fecha
#             conhecimento nascendo FORA do grafo (eixo ESPACIAL); esta fecha a
#             afirmação doutrinária que EXPIROU EM SILÊNCIO (eixo TEMPORAL). Ambas
#             são declarado≠verificado — uma contra o grafo, outra contra o TEMPO.
#
# Origem de campo (world-sync 2026-07-20/23): o cutoff do modelo é jan/2026; uma KB
#             dizendo "o lineup vigente é X" vira MENTIRA em julho sem uma linha do
#             repo mudar. O world-sync achou, em doutrina que "parecia fina": um tier
#             inteiro acima do Opus, tetos inferidos errados, e ASPAS FABRICADAS numa
#             KB. Nenhum mecanismo cobrava frescor. Este script é esse mecanismo.
#
# Generalização do kg-radar STALE-OLD: o radar já checa `verified_at:` vencido em NÓ
#             de grafo (régua Aristóteles — igual→transfere). Aqui a MESMA checagem
#             sobe de nó de grafo para AFIRMAÇÃO de doutrina em prosa de KB.
#
# ---------------------------------------------------------------------------
# OS PRESSUPOSTOS — cada um ENUMERADO e PROVADO pelo mesmo rigor
# ---------------------------------------------------------------------------
#   Regra de admissão da casa (inference-mitigation.md): "pressuposto não enumerado é
#   rodada adversarial futura". Este gate DEPENDE de quatro pressupostos, e cada um é
#   declarado e coberto por caso no lint-selftest.sh:
#     1. A LISTA WORLD-FACING (abaixo) — o ÚNICO eixo HARD. Enumerada, auditável.
#     2. O TTL (90 dias default) — lível por env, FIXADO pela fixture nos testes.
#     3. O RELÓGIO — "recente" só vale com relógio provado (NTP). Sem prova → degrada.
#     4. O BASELINE — passivo tolerado; SÓ ENCOLHE; ausência degrada FAIL-CLOSED.
#
# ---------------------------------------------------------------------------
# (1) LISTA WORLD-FACING — o único eixo HARD (escopo ESTREITO e ENUMERADO)
# ---------------------------------------------------------------------------
#   Começa pelas KBs que comprovadamente DRIFTAM (afirmam lineup/tetos/GA sensíveis
#   ao tempo). Cada uma comentada uma-a-uma. PARA ADICIONAR: acrescente o path
#   repo-relativo ao array DEFAULT_WORLD_FACING abaixo — nada mais (o gate passa a
#   exigir verified_at dela na próxima execução; se ainda não tiver, entra no baseline).
#
#     · concepts/agent-orchestration.md
#         — publica o LINEUP de modelos (tier Mythos-class acima de Opus, GA do
#           Fable 5/Sonnet 5) e TETOS por sessão (200 subagentes / 200 WebSearch).
#           Exatamente o que o world-sync pegou drifando. Alta densidade sensível-ao-tempo.
#     · concepts/context-window-optimization.md
#         — números de janela/caching/custo que a Anthropic muda entre releases.
#     · concepts/ai-agent-design-patterns.md
#         — substrato nativo (Workflow, nesting) datado; "padrões canônicos 2026".
#     · tools/claude-code-commands-best-practices-2026.md
#         — o próprio título carrega ano; espelha release-notes/changelog do Claude Code.
#
# ---------------------------------------------------------------------------
# (2) NÍVEL A (HARD) vs NÍVEL B (SOFT) — as duas redes
# ---------------------------------------------------------------------------
#   NÍVEL A — convenção-DURA sobre a lista world-facing:
#     · sem verified_at + FORA do baseline .......... HARD  (MISSING)
#     · sem verified_at + no baseline ............... SOFT  (PASSIVO — tolerado)
#     · verified_at malformado (não YYYY-MM-DD) ..... HARD  (MALFORMED — erro estrutural)
#     · verified_at no FUTURO (relógio confiável) ... HARD  (FUTURE — erro estrutural)
#     · verified_at mais velho que o TTL ............ SOFT  (STALE — re-verifique, como o radar)
#     · verified_at ok mas SEM source ............... SOFT  (NO-SOURCE — carimbo sem fonte é frágil)
#   NÍVEL B — rede LEXICAL, SOFT-only, honesta sobre ser frágil:
#     · doc FORA da lista, SEM verified_at, contendo TOKEN GATILHO (enumerados abaixo)
#       → SOFT (LEXICAL) "usa linguagem sensível-ao-tempo sem verified_at, é snapshot?".
#       Convenção-COM-rede: pega o que a lista dura ainda não enumerou, sem reprovar.
#
# ---------------------------------------------------------------------------
# (3) RELÓGIO (pressuposto) — REUSA a lógica de a2a-verify.sh
# ---------------------------------------------------------------------------
#   Uma idade computada sobre relógio dessincronizado mente: aceita doc vencido ou
#   acusa doc válido. Por isso, ANTES de qualquer comparação com "agora" (STALE,
#   FUTURE), checa-se relógio confiável via NTP (timedatectl|chronyc|ntpstat). Relógio
#   NÃO-confiável → a checagem que depende de "agora" degrada para SOFT com aviso
#   (não reprova por relógio; mas TAMPOUCO finge frescor). As checagens que NÃO
#   dependem de "agora" (presença, formato) seguem HARD normalmente.
#   DOCTRINE_CLOCK_TRUST=attested força confiável (operador atesta host sem NTP tooling);
#   =untrusted força o degrade (operador paranoico OU teste do caminho de degrade).
#
# ---------------------------------------------------------------------------
# (4) BASELINE + CATRACA (pressuposto) — MESMA doutrina da REGRA 29
# ---------------------------------------------------------------------------
#   passivo (world-facing hoje sem verified_at) vai ao BASELINE versionado e é SOFT;
#   doc world-facing NOVO fora do baseline e sem verified_at é HARD; o baseline SÓ
#   ENCOLHE (acrescentar path = HARD, checado contra a versão anterior no git). A
#   métrica de saúde é o baseline DIMINUINDO. Ausência do baseline degrada FAIL-CLOSED:
#   uma HARD acionável (não libera tudo, nem reprova em massa).
#
# ---------------------------------------------------------------------------
# DECIDIDO SÓ COM O REPO (não é no-op no CI) — e PROVA disso
# ---------------------------------------------------------------------------
#   Todos os insumos são internos: a lista (código), o frontmatter (arquivos do repo),
#   o TTL (env/default), o baseline (arquivo versionado + git show de um ref do repo),
#   os tokens (código). NENHUMA rede: este script não faz curl/wget/fetch — o
#   lint-selftest prova comportamentalmente (roda em sandbox sem git e sem rede) E
#   estruturalmente (grep por chamadas de rede no corpo). Um clone limpo em CI produz
#   o mesmo veredito que a máquina do maestro.
#
# Uso       : doctrine-freshness.sh [REPO_DIR] [opções]
#     --list-file <f>                lista world-facing alternativa (1 path/linha) — p/ fixture
#     --baseline <arquivo>           baseline explícito (default: ver abaixo)
#     --previous-baseline <arquivo>  versão anterior explícita (teste da catraca)
#     --base-ref <ref>               ref git de onde ler a versão anterior
#     --format text|tsv              text (default, pt-BR) | tsv (SEV\tTAG\tPATH\tMSG)
#     --emit-baseline                imprime o baseline sugerido (bootstrap manual)
#     --summary                      acrescenta a linha de contagens
#   env:
#     DOCTRINE_FRESHNESS_TTL_DAYS    TTL em dias (default 90) — a fixture fixa aqui
#     DOCTRINE_CLOCK_TRUST           attested (força confiável) | untrusted (força degrade)
#
#   Baseline default, na ordem: <repo>/.claude/validation/doctrine-freshness-baseline.txt
#                        e só então .../fixtures/doctrine-freshness-baseline.txt
#
# Exit codes: 0 = nenhuma violação HARD · 1 = ao menos uma HARD ·
#             2 = erro de uso · 0 com aviso = degrade gracioso
#
# Determinístico, sem LLM, sem rede. Consumido pela REGRA 42 do lint-artifacts.sh e
# coberto pelo lint-selftest.sh (prova dos 4 pressupostos + mutation test de severidade).
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# PRESSUPOSTO 1 — LISTA WORLD-FACING (o único eixo HARD). Ver cabeçalho, seção (1).
# ---------------------------------------------------------------------------
DEFAULT_WORLD_FACING=(
  "docs/knowledge-base/concepts/agent-orchestration.md"
  "docs/knowledge-base/concepts/context-window-optimization.md"
  "docs/knowledge-base/concepts/ai-agent-design-patterns.md"
  "docs/knowledge-base/tools/claude-code-commands-best-practices-2026.md"
  # runflow: SDK de PARCEIRO (spin-off do IFTL) que a KB documenta com nº de versão —
  # claim datável que drifta (2026-07-23: KB estava 8 meses velha). Rastreado p/ o gate
  # cobrar re-verificação periódica, não virar ruído de Nível B.
  "docs/knowledge-base/platforms/runflow.md"
)

# ---------------------------------------------------------------------------
# NÍVEL B — TOKENS GATILHO (pressuposto enumerado). Linguagem sensível-ao-tempo que,
# fora da lista dura e sem verified_at, levanta um SOFT. Rede lexical, honesta.
# ---------------------------------------------------------------------------
TRIGGER_TOKENS=(
  "lineup vigente"
  "versão atual"
  "latest"
  "modelo mais recente"
  "generally available"
  "atualmente"
)

REPO_DIR=""
LIST_FILE=""
BASELINE=""
PREV_BASELINE=""
BASE_REF=""
FORMAT="text"
EMIT_BASELINE=0
SUMMARY=0
TTL_DAYS="${DOCTRINE_FRESHNESS_TTL_DAYS:-90}"

usage() {
  printf 'Uso: doctrine-freshness.sh [REPO_DIR] [--list-file <f>] [--baseline <f>]\n' >&2
  printf '                           [--previous-baseline <f>] [--base-ref <ref>]\n' >&2
  printf '                           [--format text|tsv] [--emit-baseline] [--summary]\n' >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --list-file)          [ $# -ge 2 ] || { printf '❌ --list-file exige um caminho.\n' >&2; exit 2; }; LIST_FILE="$2"; shift 2 ;;
    --list-file=*)        LIST_FILE="${1#--list-file=}"; shift ;;
    --baseline)           [ $# -ge 2 ] || { printf '❌ --baseline exige um caminho.\n' >&2; exit 2; }; BASELINE="$2"; shift 2 ;;
    --baseline=*)         BASELINE="${1#--baseline=}"; shift ;;
    --previous-baseline)  [ $# -ge 2 ] || { printf '❌ --previous-baseline exige um caminho.\n' >&2; exit 2; }; PREV_BASELINE="$2"; shift 2 ;;
    --previous-baseline=*) PREV_BASELINE="${1#--previous-baseline=}"; shift ;;
    --base-ref)           [ $# -ge 2 ] || { printf '❌ --base-ref exige um ref.\n' >&2; exit 2; }; BASE_REF="$2"; shift 2 ;;
    --base-ref=*)         BASE_REF="${1#--base-ref=}"; shift ;;
    --format)             [ $# -ge 2 ] || { printf '❌ --format exige text|tsv.\n' >&2; exit 2; }; FORMAT="$2"; shift 2 ;;
    --format=*)           FORMAT="${1#--format=}"; shift ;;
    --emit-baseline)      EMIT_BASELINE=1; shift ;;
    --summary)            SUMMARY=1; shift ;;
    -h|--help)            usage; exit 0 ;;
    *)
      if [ -z "${REPO_DIR}" ]; then REPO_DIR="$1"; else
        printf '❌ doctrine-freshness: argumento inesperado "%s".\n' "$1" >&2; exit 2
      fi
      shift ;;
  esac
done

case "${FORMAT}" in text|tsv) ;; *) printf '❌ --format inválido: %s\n' "${FORMAT}" >&2; exit 2 ;; esac
case "${TTL_DAYS}" in ''|*[!0-9]*) printf '❌ TTL inválido (não-inteiro): %s\n' "${TTL_DAYS}" >&2; exit 2 ;; esac

REPO_DIR="${REPO_DIR:-.}"
if [ ! -d "${REPO_DIR}" ]; then
  printf '⚠️  doctrine-freshness: "%s" não é um diretório — nada a avaliar.\n' "${REPO_DIR}" >&2
  exit 0
fi
REPO_DIR="$(cd "${REPO_DIR}" && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

# ---------------------------------------------------------------------------
# PRESSUPOSTO 3 — RELÓGIO CONFIÁVEL (REUSA a lógica de a2a-verify.sh)
# ---------------------------------------------------------------------------
clock_trusted() {
  case "${DOCTRINE_CLOCK_TRUST:-}" in
    attested)  return 0 ;;   # atestado explícito do operador (host sem NTP tooling)
    untrusted) return 1 ;;   # força o degrade (operador paranoico OU teste do caminho)
  esac
  if command -v timedatectl >/dev/null 2>&1; then
    [ "$(timedatectl show -p NTPSynchronized --value 2>/dev/null)" = "yes" ] && return 0
  fi
  if command -v chronyc >/dev/null 2>&1; then
    chronyc tracking 2>/dev/null | grep -q '^Leap status.*Normal' && return 0
  fi
  if command -v ntpstat >/dev/null 2>&1; then
    ntpstat >/dev/null 2>&1 && return 0
  fi
  return 1
}
CLOCK_OK=1
clock_trusted || CLOCK_OK=0
NOW="$(date +%s)"

# --- helpers ----------------------------------------------------------------
# Lê UM campo do frontmatter YAML (entre as cercas --- iniciais). Vazio se ausente.
read_fm_field() {  # <arquivo-abs> <campo>
  awk -v field="$2" '
    NR==1 && $0=="---" { infm=1; next }
    NR==1 { exit }                       # sem frontmatter
    infm && $0=="---" { exit }
    infm && index($0, field ":")==1 {
      v=$0; sub("^" field ":[[:space:]]*", "", v)
      gsub(/^["'\'']|["'\'']$/, "", v); sub(/[[:space:]]+$/, "", v)
      print v; exit
    }
  ' "$1" 2>/dev/null || true
}

is_ymd() { printf '%s' "$1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; }

# ---------------------------------------------------------------------------
# LISTA WORLD-FACING efetiva (default no código, ou --list-file p/ a fixture)
# ---------------------------------------------------------------------------
: > "${TMP}/list"
if [ -n "${LIST_FILE}" ]; then
  case "${LIST_FILE}" in /*) ;; *) LIST_FILE="${REPO_DIR}/${LIST_FILE}" ;; esac
  if [ ! -f "${LIST_FILE}" ]; then
    printf '⚠️  --list-file: "%s" inexistente — nada a avaliar no Nível A.\n' "${LIST_FILE}" >&2
  else
    grep -vE '^[[:space:]]*(#|$)' "${LIST_FILE}" 2>/dev/null | sed 's/[[:space:]]*$//' | sort -u > "${TMP}/list" || true
  fi
else
  printf '%s\n' "${DEFAULT_WORLD_FACING[@]}" | sort -u > "${TMP}/list"
fi

# ---------------------------------------------------------------------------
# NÍVEL A — avalia cada doc world-facing. Preenche:
#   uncovered  (sem verified_at)   → entra na lógica de baseline/catraca
#   structural (HARD imediato: malformed/future) e stale/no-source (SOFT) saem JÁ
# ---------------------------------------------------------------------------
HARD=0
SOFT=0
: > "${TMP}/out"
: > "${TMP}/uncovered"

# say SEV TAG PATH MSG — TAG deixa o lint AGREGAR classes volumosas (PASSIVO, LEXICAL).
say() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "${TMP}/out"
  if [ "$1" = "HARD" ]; then HARD=$((HARD + 1)); else SOFT=$((SOFT + 1)); fi
}

# A avaliação temporal (stale/future/no-source) é adiada até depois do modo
# --emit-baseline (que só precisa da lista de uncovered). Guardamos os veredictos.
: > "${TMP}/levelA"
while IFS= read -r rel; do
  [ -n "${rel}" ] || continue
  abs="${REPO_DIR}/${rel}"
  if [ ! -f "${abs}" ]; then
    printf 'SOFT\tLIST-ORFA\t%s\tdoc world-facing na lista não existe no repo — corrija a lista em doctrine-freshness.sh (ou --list-file)\n' "${rel}" >> "${TMP}/levelA"
    continue
  fi
  va="$(read_fm_field "${abs}" verified_at)"
  src="$(read_fm_field "${abs}" source)"
  if [ -z "${va}" ]; then
    printf '%s\n' "${rel}" >> "${TMP}/uncovered"   # sem carimbo → baseline decide (HARD/PASSIVO)
    continue
  fi
  # tem verified_at: valida FORMATO (independe do relógio) → HARD estrutural
  if ! is_ymd "${va}"; then
    printf 'HARD\tMALFORMED\t%s\tverified_at "%s" malformado — use YYYY-MM-DD (erro estrutural, não frescor)\n' "${rel}" "${va}" >> "${TMP}/levelA"
    continue
  fi
  epoch="$(date -d "${va}" +%s 2>/dev/null || true)"
  if [ -z "${epoch}" ]; then
    printf 'HARD\tMALFORMED\t%s\tverified_at "%s" não é data de calendário válida (erro estrutural)\n' "${rel}" "${va}" >> "${TMP}/levelA"
    continue
  fi
  # comparações com "agora" (FUTURE / STALE) — só valem com relógio provado
  if [ "${CLOCK_OK}" -eq 0 ]; then
    printf 'SOFT\tSTALE-CLOCK-UNTRUSTED\t%s\tverified_at "%s" presente, mas o relógio não é confiável (NTP não provado) — frescor NÃO verificável; sincronize o relógio ou ateste com DOCTRINE_CLOCK_TRUST=attested\n' "${rel}" "${va}" >> "${TMP}/levelA"
  elif [ "${epoch}" -gt "${NOW}" ]; then
    printf 'HARD\tFUTURE\t%s\tverified_at "%s" está no FUTURO — erro estrutural (data impossível ou digitada errada)\n' "${rel}" "${va}" >> "${TMP}/levelA"
  else
    age_days=$(( (NOW - epoch) / 86400 ))
    if [ "${age_days}" -gt "${TTL_DAYS}" ]; then
      printf 'SOFT\tSTALE\t%s\tverified_at "%s" tem %s dias (> TTL %s) — RE-VERIFIQUE contra o vivo e re-carimbe (o gate não confere a web; você/kb-freshness confere)\n' "${rel}" "${va}" "${age_days}" "${TTL_DAYS}" >> "${TMP}/levelA"
    fi
    # source é o par do carimbo: carimbo sem fonte é frágil (não reprova; avisa)
    if [ -z "${src}" ]; then
      printf 'SOFT\tNO-SOURCE\t%s\tverified_at presente mas SEM source — um carimbo sem fonte não é re-verificável; adicione source: <url primária que a KB já cita>\n' "${rel}" >> "${TMP}/levelA"
    fi
  fi
done < "${TMP}/list"
sort -u "${TMP}/uncovered" -o "${TMP}/uncovered"

# ---------------------------------------------------------------------------
# --emit-baseline: bootstrap manual (o maestro redireciona). Não há modo que ESCREVA
# o baseline — escrita automática desarmaria a catraca.
# ---------------------------------------------------------------------------
if [ "${EMIT_BASELINE}" -eq 1 ]; then
  printf '# Baseline de frescor doutrinário — PASSIVO TOLERADO (world-facing hoje sem verified_at).\n'
  printf '# Gerado por: bash .claude/validation/doctrine-freshness.sh --emit-baseline\n'
  printf '# Esta lista SÓ PODE ENCOLHER. Acrescentar path aqui é regressão (HARD).\n'
  cat "${TMP}/uncovered"
  exit 0
fi

# ---------------------------------------------------------------------------
# PRESSUPOSTO 4 — BASELINE + CATRACA
# ---------------------------------------------------------------------------
BASELINE_REL=""
if [ -n "${BASELINE}" ]; then
  case "${BASELINE}" in /*) ;; *) BASELINE="${REPO_DIR}/${BASELINE}" ;; esac
  BASELINE_REL="${BASELINE#${REPO_DIR}/}"
else
  for _cand in ".claude/validation/doctrine-freshness-baseline.txt" \
               ".claude/validation/fixtures/doctrine-freshness-baseline.txt"; do
    if [ -f "${REPO_DIR}/${_cand}" ]; then BASELINE="${REPO_DIR}/${_cand}"; BASELINE_REL="${_cand}"; break; fi
  done
  if [ -z "${BASELINE}" ]; then
    BASELINE="${REPO_DIR}/.claude/validation/doctrine-freshness-baseline.txt"
    BASELINE_REL=".claude/validation/doctrine-freshness-baseline.txt"
  fi
fi

# `|| true` ESSENCIAL: baseline vazio (só cabeçalho) faz o grep sair 1 e, sob
# `set -euo pipefail`, abortaria o script inteiro em silêncio — o gate morreria
# justo no repo mais são (o de baseline zerado).
read_baseline() {
  grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null | sed 's/[[:space:]]*$//' | sort -u || true
}

BASELINE_PRESENT=0
: > "${TMP}/baseline"
if [ -f "${BASELINE}" ]; then
  BASELINE_PRESENT=1
  read_baseline "${BASELINE}" > "${TMP}/baseline"
fi

if [ "${BASELINE_PRESENT}" -eq 0 ]; then
  # DEGRADE FAIL-CLOSED que NÃO libera tudo: a ausência do baseline é ela própria a
  # violação HARD (uma só, acionável); o passivo sai SOFT informativo. Silenciar
  # transformaria "apagar o baseline" em bypass do gate.
  say "HARD" "NO-BASELINE" "${BASELINE_REL}" "baseline de frescor AUSENTE — a catraca está desarmada e nenhum doc novo pode ser distinguido do passivo. Gere: bash .claude/validation/doctrine-freshness.sh --emit-baseline > ${BASELINE_REL}"
  while IFS= read -r p; do
    [ -n "${p}" ] || continue
    say "SOFT" "NO-BASELINE-UNCOVERED" "${p}" "world-facing sem verified_at (severidade rebaixada: sem baseline não há como saber se é passivo ou novo)"
  done < "${TMP}/uncovered"
else
  # (a) world-facing sem carimbo e FORA do baseline => HARD. O coração do Nível A.
  comm -23 "${TMP}/uncovered" "${TMP}/baseline" > "${TMP}/novos"
  while IFS= read -r p; do
    [ -n "${p}" ] || continue
    say "HARD" "MISSING" "${p}" "doc world-facing SEM verified_at no frontmatter — afirmação sensível-ao-tempo sem carimbo de frescor. Verifique contra o vivo e adicione verified_at: <YYYY-MM-DD> + source: <url> (ou, se é passivo, some ao baseline — que só encolhe)"
  done < "${TMP}/novos"

  # (b) passivo tolerado => SOFT. É o que torna o gate adotável no 1º dia.
  comm -12 "${TMP}/uncovered" "${TMP}/baseline" > "${TMP}/passivo"
  while IFS= read -r p; do
    [ -n "${p}" ] || continue
    say "SOFT" "PASSIVO" "${p}" "passivo tolerado pelo baseline — carimbe verified_at+source e remova do baseline (a métrica de saúde é o baseline diminuindo)"
  done < "${TMP}/passivo"

  # (c) entrada de baseline que já não é necessária => SOFT (cobra o encolhimento).
  while IFS= read -r p; do
    [ -n "${p}" ] || continue
    if grep -qxF "${p}" "${TMP}/uncovered"; then continue; fi
    if grep -qxF "${p}" "${TMP}/list"; then
      say "SOFT" "BASELINE-OBSOLETA" "${BASELINE_REL}" "entrada OBSOLETA: '${p}' já carrega verified_at — remova do baseline (a catraca só encolhe)"
    else
      say "SOFT" "BASELINE-ORFA" "${BASELINE_REL}" "entrada ÓRFÃ: '${p}' não está mais na lista world-facing — remova do baseline"
    fi
  done < "${TMP}/baseline"

  # (d) CATRACA — o baseline SÓ PODE ENCOLHER. Versão anterior: --previous-baseline
  #     (teste) > --base-ref > branch de integração > HEAD. Tudo interno ao repo.
  : > "${TMP}/prev"
  PREV_SOURCE=""
  if [ -n "${PREV_BASELINE}" ]; then
    if [ -f "${PREV_BASELINE}" ]; then
      read_baseline "${PREV_BASELINE}" > "${TMP}/prev"; PREV_SOURCE="arquivo ${PREV_BASELINE}"
    else
      say "SOFT" "CATRACA-INDISPONIVEL" "${BASELINE_REL}" "catraca não verificável — --previous-baseline aponta para arquivo inexistente (${PREV_BASELINE})"
    fi
  elif git -C "${REPO_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
    refs=""
    if [ -n "${BASE_REF}" ]; then
      refs="${BASE_REF}"
    else
      integ=""
      _sib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/resolve-integration-branch.sh"
      [ -x "${_sib}" ] && integ="$("${_sib}" "${REPO_DIR}" 2>/dev/null || true)"
      [ -n "${integ}" ] && refs="origin/${integ} ${integ}"
      refs="${refs} HEAD"
    fi
    for r in ${refs}; do
      if git -C "${REPO_DIR}" show "${r}:${BASELINE_REL}" >"${TMP}/prev.raw" 2>/dev/null; then
        read_baseline "${TMP}/prev.raw" > "${TMP}/prev"; PREV_SOURCE="git ${r}"
        # CATRACA FRACA: HEAD/branch local já contêm o commit local — comparar contra
        # eles é comparar a mudança consigo mesma (o no-op silencioso). Só
        # origin/<integração> (ou --base-ref) é referência FORTE. Degrada com AVISO.
        case "${r}" in
          origin/*) : ;;
          *) [ -n "${BASE_REF}" ] || say "SOFT" "CATRACA-FRACA" "${BASELINE_REL}" \
               "catraca comparando contra '${r}' (ref LOCAL): crescimento já commitado aqui NÃO é detectado — só 'origin/<integração>' ou --base-ref é referência forte" ;;
        esac
        break
      fi
    done
    if [ -z "${PREV_SOURCE}" ]; then
      say "SOFT" "CATRACA-INDISPONIVEL" "${BASELINE_REL}" "catraca não verificável — o baseline ainda não está versionado em nenhum ref (${refs// /, }); comite-o para armar a catraca"
    fi
  else
    say "SOFT" "CATRACA-INDISPONIVEL" "${BASELINE_REL}" "catraca não verificável — '${REPO_DIR}' não é repositório git (degrade gracioso: o gate segue valendo, só a checagem de crescimento fica suspensa)"
  fi

  if [ -n "${PREV_SOURCE}" ]; then
    comm -13 "${TMP}/prev" "${TMP}/baseline" > "${TMP}/added"
    while IFS= read -r p; do
      [ -n "${p}" ] || continue
      say "HARD" "CATRACA" "${BASELINE_REL}" "CATRACA VIOLADA: '${p}' foi ACRESCENTADO ao baseline (vs ${PREV_SOURCE}) — o baseline só pode ENCOLHER. Passivo se carimba, não se amplia a lista de tolerância"
    done < "${TMP}/added"
  fi
fi

# Despeja os veredictos do Nível A (structural/stale/no-source/list-orfa) já apurados.
while IFS=$'\t' read -r sev tag path msg; do
  [ -n "${sev}" ] || continue
  say "${sev}" "${tag}" "${path}" "${msg}"
done < "${TMP}/levelA"

# ---------------------------------------------------------------------------
# NÍVEL B — rede LEXICAL (SOFT-only): docs FORA da lista, sem verified_at, com token gatilho.
# Escopo: docs/knowledge-base/**/*.md (a doutrina em prosa). Bounded e CI-safe.
# ---------------------------------------------------------------------------
KB_ROOT="${REPO_DIR}/docs/knowledge-base"
if [ -d "${KB_ROOT}" ]; then
  # regex ERE case-insensitive com os tokens enumerados (escapa nada especial aqui).
  _re="$(printf '%s|' "${TRIGGER_TOKENS[@]}")"; _re="${_re%|}"
  while IFS= read -r abs; do
    [ -n "${abs}" ] || continue
    rel="${abs#${REPO_DIR}/}"
    case "${rel}" in
      */index.md|*/README.md) continue ;;
      # A KB que DEFINE os tokens-gatilho (esta doutrina) casaria a si mesma — é a fonte
      # dos tokens, não uma afirmação sensível-ao-tempo. Auto-referência, não frescor.
      docs/knowledge-base/concepts/onion-guardrails.md) continue ;;
    esac
    grep -qxF "${rel}" "${TMP}/list" && continue          # da lista dura → Nível A já cuida
    [ -n "$(read_fm_field "${abs}" verified_at)" ] && continue   # já carimbado → honesto
    # PULA BLOCOS DE CÓDIGO: `latest` numa tag Docker (`image:latest`), num nome de método
    # (`getLatestRuns`) ou num env-example é CÓDIGO, não afirmação doutrinária em prosa — não
    # é o que esta rede pega. Varrer código gerava uma classe inteira de falso-positivo (docker,
    # exemplos). O awk alterna dentro/fora da cerca ``` e só entrega a PROSA ao grep.
    hits="$(awk '/^[[:space:]]*```/{c=!c; next} !c' "${abs}" 2>/dev/null \
             | grep -ioE "${_re}" 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//' || true)"
    [ -n "${hits}" ] || continue
    say "SOFT" "LEXICAL" "${rel}" "usa linguagem sensível-ao-tempo (${hits}) sem verified_at — é snapshot? Se afirma lineup/versão/GA, carimbe verified_at+source (ou promova à lista world-facing); se é atemporal, ignore (rede frágil, SOFT-only)"
  done < <(find "${KB_ROOT}" -type f -name '*.md' 2>/dev/null | sort)
fi

# ---------------------------------------------------------------------------
# SAÍDA
# ---------------------------------------------------------------------------
if [ "${FORMAT}" = "tsv" ]; then
  cat "${TMP}/out"
else
  n_list=$(wc -l < "${TMP}/list" | tr -d ' ')
  n_unc=$(wc -l < "${TMP}/uncovered" | tr -d ' ')
  printf '=== Frescor doutrinário (Nível A: lista world-facing · Nível B: rede lexical em docs/knowledge-base) ===\n'
  printf '  Docs world-facing    : %s\n' "${n_list}"
  printf '  Sem verified_at      : %s\n' "${n_unc}"
  printf '  TTL                  : %s dias%s\n' "${TTL_DAYS}" "$([ -n "${DOCTRINE_FRESHNESS_TTL_DAYS:-}" ] && printf ' (env)' || printf ' (default)')"
  printf '  Relógio              : %s\n' "$([ "${CLOCK_OK}" -eq 1 ] && printf 'confiável' || printf 'NÃO confiável — checagem de idade degradada a SOFT')"
  printf '  Baseline             : %s\n' \
    "$([ "${BASELINE_PRESENT}" -eq 1 ] && printf '%s (%s entrada(s))' "${BASELINE_REL}" "$(wc -l < "${TMP}/baseline" | tr -d ' ')" || printf 'AUSENTE')"
  printf '\n'
  while IFS=$'\t' read -r sev tag path msg; do
    [ -n "${sev}" ] || continue
    printf '%s [%s] %s: %s\n' "$([ "${sev}" = "HARD" ] && printf '❌ HARD' || printf '⚠️  SOFT')" "${tag}" "${path}" "${msg}"
  done < "${TMP}/out"
fi

if [ "${SUMMARY}" -eq 1 ]; then
  printf 'SUMMARY\tHARD=%s\tSOFT=%s\n' "${HARD}" "${SOFT}"
fi

[ "${HARD}" -eq 0 ] || exit 1
exit 0
