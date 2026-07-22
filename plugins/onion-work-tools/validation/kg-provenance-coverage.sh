#!/usr/bin/env bash
# =============================================================================
# kg-provenance-coverage.sh — GATE DE PROVENIÊNCIA INVERTIDO (com catraca)
#
# LIMITE   : cobertura é por CITAÇÃO, não por CONTEÚDO. Um nó que cite o documento sem sustentá-lo
#            satisfaz este gate — deliberado, porque cobertura precisa ser decidível por script.
#            O julgamento semântico é do kg-radar (STALE-TRACE, decisão-sem-proveniência) e da
#            verificação adversarial. Não leia "coberto" como "conferido".
#
# Propósito : Responder o ESPELHO da pergunta que o kg-radar.sh já faz.
#             O radar pergunta, de dentro do grafo para fora:
#                 "esta DECISÃO está ancorada numa origem?"  (decisão-sem-proveniência)
#             Falta a pergunta de fora do grafo para dentro:
#                 "este RELATÓRIO existe no grafo?"
#             Um documento de análise está COBERTO quando algum nó de algum
#             .kg.yaml do repo o cita em `trace:` ou `evidence:`.
#
# Origem de campo (sinal de um adotante regulado, 2026-07-20 — docs/evolution/inbox/
#             2026-07-20-gate-proveniencia-invertido.md):
#             a doutrina KG-SSOT tinha forcing function só na LEITURA (/catch-up
#             passo 0, kg-radar reprovando grafo inconsistente, STALE-TRACE).
#             Três mecanismos, todos protegendo o grafo de ESTAR ERRADO; nenhum
#             impedindo conhecimento de NASCER FORA dele. Evidência
#             auto-incriminadora: 70 agentes, 0 erros, 50 achados confirmados +
#             10 refutados em JSON — e NADA ingerido no .kg.yaml. A raiz estava
#             no PLANO, não na execução: "construir o grafo" numa fase e
#             "avaliar" na seguinte, com saída declarada em markdown. O grafo
#             virou PREDECESSOR da avaliação em vez de DESTINO dela.
#             O core já SABIA — a skill onion-orchestration (passo 7) já diz
#             "síntese que não persistiu = síntese perdida" e "advice-que-depende-
#             de-lembrar falhou empiricamente". Diagnosticou "mecanismo, não
#             conselho" e deixou como CONSELHO. Este script é o mecanismo.
#
# ---------------------------------------------------------------------------
# A CATRACA (o que torna o gate ADOTÁVEL — e não é enfeite)
# ---------------------------------------------------------------------------
#   Sem catraca o gate nasce reprovando dezenas de arquivos e é DESLIGADO no 1º
#   dia. Por isso:
#     · o passivo existente vai para um BASELINE versionado e é TOLERADO (SOFT);
#     · documento NOVO fora do baseline e sem nó é violação HARD;
#     · o baseline SÓ PODE ENCOLHER — acrescentar path a ele é REGRESSÃO e sai
#       como HARD (checado contra a versão anterior do próprio arquivo, no git).
#   A métrica de saúde é o baseline DIMINUINDO, não o gate passando. Por isso
#   entrada de baseline que já não é necessária (documento virou coberto, ou
#   sumiu) sai como SOFT "obsoleta — remova": a catraca cobra o encolhimento.
#
# ---------------------------------------------------------------------------
# ESCOPO — deliberadamente CONSERVADOR (e o PORQUÊ de cada exclusão)
# ---------------------------------------------------------------------------
#   INCLUI (onde vivem ACHADOS ESTRUTURADOS — a saída que deveria nascer no grafo):
#     · docs/analysis/*.md              (não-recursivo)
#     · docs/evolution/research/**/*.md (recursivo — SYNTHESIS + frentes)
#
#   EXCLUI, com motivo:
#     · ADRs (docs/analysis/*adr*.md, `type: adr` no frontmatter) — ADR é NORMA
#       ratificada, não achado de investigação. Sua proveniência é o próprio
#       texto + o ato de ratificação; exigir que um nó o cite inverteria a
#       direção (o grafo é que TRACES_TO o ADR, não o contrário). Além disso o
#       radar já cobre esse lado com decisão-sem-proveniência.
#     · RFCs (docs/evolution/rfc/**, `type: rfc`) — proposta normativa, mesmo
#       argumento do ADR; e não estão sob as raízes do escopo.
#     · KBs (docs/knowledge-base/**) — conhecimento DESTILADO e estável, feito
#       para ser CITADO. Forçá-las ao grafo transformaria toda KB em nó e diluiria
#       o sinal até o gate virar ruído.
#     · Diário (docs/onion/diary/**, /meta:diary) — autobiografia com forcing
#       function PRÓPRIA (o sub-comando review re-testa migalha vencida). Duas
#       catracas sobre o mesmo artefato competem.
#     · docs/onion/** — GERADO (inventory.md, graph.md, federation-map.md,
#       console). Exigir nó de artefato gerado é ruído puro: a fonte é a
#       spec-as-code, e o drift-guard dela já é outro (REGRAS 8/21/23/24).
#     · README.md / index.md / INDEX.md dentro do escopo — navegação, não achado.
#     · ${CLAUDE_PLUGIN_ROOT}/validation/fixtures/** — templates de teste, não artefatos ativos
#       (mesma isenção que as regras de varredura ampla do lint aplicam).
#
#   Distinção da REGRA 26 (check_research_kg) — NÃO é duplicata: aquela exige que
#   o DIRETÓRIO de pesquisa contenha algum .kg.yaml; esta exige que o DOCUMENTO
#   seja CITADO por algum nó. Uma pesquisa pode ter .kg.yaml e ainda assim ter um
#   relatório órfão ao lado dele — exatamente o formato do incidente de um adotante regulado.
#
# ---------------------------------------------------------------------------
# DECIDIDO SÓ COM O REPO (não é no-op no CI)
# ---------------------------------------------------------------------------
#   Todos os insumos são internos ao repositório: o escopo (find sob docs/), a
#   cobertura (todos os *.kg.yaml versionados), o baseline (arquivo versionado) e
#   a versão anterior do baseline (git show de um ref do próprio repo). NENHUM
#   caminho, serviço ou estado externo participa da decisão — um clone limpo em
#   runner de CI produz o mesmo veredito que a máquina do maestro.
#
# ---------------------------------------------------------------------------
# --scope: MEDIR fora do escopo canônico, sem instalar catraca
# ---------------------------------------------------------------------------
#   O escopo default acima é o do GATE (CI, baseline, catraca). `--scope <dir>`
#   serve a outra pergunta, EXPLORATÓRIA: "quanto deste corpus está no grafo?" —
#   é o que alimenta o modo `/meta:kg backfill`.
#
#   Por que --scope NÃO arma catraca (e isso é estrutural, não conselho):
#   um escopo alheio avaliado contra o baseline CANÔNICO faria toda entrada do
#   baseline virar ÓRFÃ (o doc não está no novo escopo) e todo documento do novo
#   escopo virar HARD-novo. Num adotante com passivo populado, o gate cuspiria
#   dezenas de violações falsas e seria desligado no mesmo dia — o modo de falha
#   que a própria catraca existe para evitar. Por isso: `--scope` sem `--baseline`
#   explícito entra em modo EXPLORATÓRIO — mede, informa, sai 0, e NÃO consulta
#   nem cobra baseline. Para armar uma catraca num escopo novo é preciso dizer
#   `--baseline <arquivo>` de propósito.
#
#   Isto NÃO contradiz as exclusões documentadas acima: elas dizem o que o GATE
#   cobra em CI. Medir uma KB com --scope é diagnóstico; pô-la sob catraca
#   permanente é que diluiria o sinal.
#
# Uso       : kg-provenance-coverage.sh [REPO_DIR] [opções]
#     --scope <dir>                  raiz alternativa, RECURSIVA, repetível
#                                    (sem --baseline ⇒ modo exploratório, sem catraca)
#     --baseline <arquivo>           baseline explícito (default: ver abaixo)
#     --previous-baseline <arquivo>  versão anterior explícita (para teste da catraca)
#     --base-ref <ref>               ref git de onde ler a versão anterior
#     --format text|tsv              text (default, pt-BR) | tsv (SEV\tTAG\tPATH\tMSG)
#     --emit-baseline                imprime no STDOUT o baseline sugerido (bootstrap)
#     --summary                      acrescenta a linha de contagens
#
#   Baseline default, na ordem: <repo>/${CLAUDE_PLUGIN_ROOT}/validation/kg-coverage-baseline.txt
#                        e só então .../fixtures/kg-coverage-baseline.txt
#   (o primeiro é o canônico — fixtures/ guarda TEMPLATES de teste, não artefato
#    ativo, por convenção documentada no cabeçalho do lint-artifacts.sh)
#
# Exit codes: 0 = nenhuma violação HARD · 1 = ao menos uma HARD ·
#             2 = erro de uso · 0 com aviso = degrade gracioso (sem git, etc.)
#
# Determinístico, sem LLM. Consumido pela REGRA 29 do lint-artifacts.sh e coberto
# pelo lint-selftest.sh (19 casos, incluindo a prova dos próprios PRESSUPOSTOS:
# severidade por delta, decisão-só-com-o-repo, catraca que só encolhe, mutation
# test). Acompanha ${CLAUDE_PLUGIN_ROOT}/validation/ nos repos adotados; num repo SEM baseline
# a primeira execução é `--emit-baseline > ${CLAUDE_PLUGIN_ROOT}/validation/kg-coverage-baseline.txt`.
# =============================================================================
set -euo pipefail

REPO_DIR=""
BASELINE=""
PREV_BASELINE=""
BASE_REF=""
FORMAT="text"
EMIT_BASELINE=0
SUMMARY=0
SCOPE_ROOTS=()
EXPLORATORY=0

usage() {
  printf 'Uso: kg-provenance-coverage.sh [REPO_DIR] [--scope <dir>] [--baseline <f>] [--previous-baseline <f>]\n' >&2
  printf '                               [--base-ref <ref>] [--format text|tsv] [--emit-baseline] [--summary]\n' >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --scope)              [ $# -ge 2 ] || { printf '❌ --scope exige um diretório.\n' >&2; exit 2; }; SCOPE_ROOTS+=("$2"); shift 2 ;;
    --scope=*)            SCOPE_ROOTS+=("${1#--scope=}"); shift ;;
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
        printf '❌ kg-provenance-coverage: argumento inesperado "%s".\n' "$1" >&2; exit 2
      fi
      shift ;;
  esac
done

case "${FORMAT}" in text|tsv) ;; *) printf '❌ --format inválido: %s\n' "${FORMAT}" >&2; exit 2 ;; esac

REPO_DIR="${REPO_DIR:-.}"
if [ ! -d "${REPO_DIR}" ]; then
  printf '⚠️  kg-provenance-coverage: "%s" não é um diretório — nada a avaliar.\n' "${REPO_DIR}" >&2
  exit 0
fi
REPO_DIR="$(cd "${REPO_DIR}" && pwd)"

# --- Modo EXPLORATÓRIO: escopo alheio sem baseline explícito -----------------
# Ver o bloco "--scope" no cabeçalho: avaliar escopo alheio contra o baseline
# canônico produziria órfãs em massa + HARDs falsos. Impedido por construção.
if [ ${#SCOPE_ROOTS[@]} -gt 0 ] && [ -z "${BASELINE}" ]; then
  EXPLORATORY=1
fi

# --- Baseline: resolução (canônico primeiro, fixtures como compat) -----------
BASELINE_REL=""
if [ -n "${BASELINE}" ]; then
  case "${BASELINE}" in /*) ;; *) BASELINE="${REPO_DIR}/${BASELINE}" ;; esac
  BASELINE_REL="${BASELINE#${REPO_DIR}/}"
else
  for _cand in "${CLAUDE_PLUGIN_ROOT}/validation/kg-coverage-baseline.txt" \
               "${CLAUDE_PLUGIN_ROOT}/validation/fixtures/kg-coverage-baseline.txt"; do
    if [ -f "${REPO_DIR}/${_cand}" ]; then BASELINE="${REPO_DIR}/${_cand}"; BASELINE_REL="${_cand}"; break; fi
  done
  if [ -z "${BASELINE}" ]; then
    BASELINE="${REPO_DIR}/${CLAUDE_PLUGIN_ROOT}/validation/kg-coverage-baseline.txt"
    BASELINE_REL="${CLAUDE_PLUGIN_ROOT}/validation/kg-coverage-baseline.txt"
  fi
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

# ---------------------------------------------------------------------------
# (1) ESCOPO — documentos de análise sob as raízes declaradas
# ---------------------------------------------------------------------------
scope_excluded() {
  local rel="$1"
  case "${rel}" in
    */README.md|README.md|*/index.md|index.md|*/INDEX.md|INDEX.md) return 0 ;;
    *adr-*|*-adr.md|*/adr/*)                                        return 0 ;;
    *rfc-*|*-rfc.md|*/rfc/*)                                        return 0 ;;
    */validation/fixtures/*)                                        return 0 ;;
  esac
  # Frontmatter é a segunda rede: ADR/RFC que não siga a convenção de nome.
  # Sem pipe: `head | grep -q` sob `set -o pipefail` retorna != 0 quando o grep
  # ACHA (fecha o pipe, head morre de SIGPIPE) — o falso-negativo silencioso que
  # deixaria todo ADR-sem-prefixo entrar no escopo.
  local fm; fm="$(head -n 20 "${REPO_DIR}/${rel}" 2>/dev/null || true)"
  if printf '%s\n' "${fm}" | grep -qiE '^type:[[:space:]]*"?(adr|rfc)"?[[:space:]]*$'; then
    return 0
  fi
  return 1
}

: > "${TMP}/scope"
if [ ${#SCOPE_ROOTS[@]} -gt 0 ]; then
  # Escopo explícito: RECURSIVO sob cada raiz. As exclusões de scope_excluded
  # (README/index, ADR, RFC, fixtures) continuam valendo — são sobre a NATUREZA
  # do documento, não sobre onde ele mora.
  for _root in "${SCOPE_ROOTS[@]}"; do
    case "${_root}" in /*) _abs="${_root}" ;; *) _abs="${REPO_DIR}/${_root}" ;; esac
    if [ ! -d "${_abs}" ]; then
      printf '⚠️  --scope: "%s" não é um diretório — ignorado.\n' "${_root}" >&2
      continue
    fi
    find "${_abs}" -type f -name '*.md' 2>/dev/null | sort >> "${TMP}/raw"
  done
else
  if [ -d "${REPO_DIR}/docs/analysis" ]; then
    find "${REPO_DIR}/docs/analysis" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort >> "${TMP}/raw"
  fi
  if [ -d "${REPO_DIR}/docs/evolution/research" ]; then
    find "${REPO_DIR}/docs/evolution/research" -type f -name '*.md' 2>/dev/null | sort >> "${TMP}/raw"
  fi
fi
touch "${TMP}/raw"
while IFS= read -r abs; do
  [ -n "${abs}" ] || continue
  rel="${abs#${REPO_DIR}/}"
  scope_excluded "${rel}" && continue
  printf '%s\n' "${rel}"
done < "${TMP}/raw" | sort -u > "${TMP}/scope"

# ---------------------------------------------------------------------------
# (2) COBERTURA — paths citados em trace:/evidence: por QUALQUER .kg.yaml do repo
#     `trace:` é migalha inline (arquivo[:linha]); `evidence:` aceita escalar e
#     lista de itens. Normalização: aspas fora, `:NNN` final fora, `./` fora.
# ---------------------------------------------------------------------------
: > "${TMP}/kgfiles"
find "${REPO_DIR}" \
     -path '*/.git' -prune -o \
     -path '*/node_modules' -prune -o \
     -path '*/.claude/worktrees' -prune -o \
     -type f -name '*.kg.yaml' -print 2>/dev/null | sort > "${TMP}/kgfiles"

: > "${TMP}/covered"
if [ -s "${TMP}/kgfiles" ]; then
  # shellcheck disable=SC2046
  awk '
    function emit(v,   s, tok) {
      # ROBUSTEZ: não "limpa e parte" — EXTRAI tokens que parecem path .md.
      # Por que: o repo cita de formas legítimas que quebravam a limpeza —
      #   trace: "PR #394; docs/analysis/foo.md"   (o `;` não era separador, e o
      #   strip de `#comentário` comia o "#394" E o path depois dele);
      #   evidence: - docs/x.md — anotação livre;  listas com `, `; sufixo :NNN.
      # Extrair token é indiferente a separador e a anotação: o que não é path, ignora.
      s = v
      while (match(s, /[A-Za-z0-9_.@][A-Za-z0-9_.@\/-]*\.md(:[0-9][0-9.]*)?/)) {
        tok = substr(s, RSTART, RLENGTH)
        s   = substr(s, RSTART + RLENGTH)
        sub(/:[0-9][0-9.]*$/, "", tok)   # migalha arquivo:linha (e :2.1)
        sub(/^\.\//, "", tok)
        if (tok != "") print tok
      }
    }
    FNR == 1 { inEv = 0 }
    /^[[:space:]]*trace:/      { v = $0; sub(/^[[:space:]]*trace:/, "", v); emit(v); inEv = 0; next }
    /^[[:space:]]*evidence:[[:space:]]*$/ { inEv = 1; next }
    /^[[:space:]]*evidence:/   { v = $0; sub(/^[[:space:]]*evidence:/, "", v); emit(v); inEv = 0; next }
    {
      if (inEv && $0 ~ /^[[:space:]]*-[[:space:]]*/) { v = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", v); emit(v); next }
      if ($0 ~ /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*:/) inEv = 0
    }
  ' $(cat "${TMP}/kgfiles") 2>/dev/null | sort -u > "${TMP}/covered" || true
fi

comm -23 "${TMP}/scope" "${TMP}/covered" > "${TMP}/uncovered"
comm -12 "${TMP}/scope" "${TMP}/covered" > "${TMP}/covered_in_scope"

# --emit-baseline: bootstrap operado À MÃO pelo maestro (redireciona ele mesmo).
# Não existe modo que ESCREVA o baseline: escrita automática desarmaria a catraca.
if [ "${EMIT_BASELINE}" -eq 1 ]; then
  printf '# Baseline de cobertura de proveniência invertida — PASSIVO TOLERADO.\n'
  printf '# Gerado por: bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-provenance-coverage.sh --emit-baseline\n'
  printf '# Esta lista SÓ PODE ENCOLHER. Acrescentar path aqui é regressão (HARD).\n'
  cat "${TMP}/uncovered"
  exit 0
fi

# --- Modo EXPLORATÓRIO (--scope sem --baseline): MEDE, não cobra --------------
# Sai SEMPRE 0: é diagnóstico, não gate. Quem consome isto é o /meta:kg backfill,
# que usa a lista de descobertos como pauta de trabalho.
if [ "${EXPLORATORY}" -eq 1 ]; then
  n_scope=$(wc -l < "${TMP}/scope" | tr -d ' ')
  n_cov=$(wc -l < "${TMP}/covered_in_scope" | tr -d ' ')
  n_unc=$(wc -l < "${TMP}/uncovered" | tr -d ' ')
  if [ "${FORMAT}" = "tsv" ]; then
    while IFS= read -r p; do
      [ -n "${p}" ] || continue
      printf 'SOFT\tEXPLORATORIO\t%s\tsem nó no grafo (medição exploratória — nenhuma catraca armada neste escopo)\n' "${p}"
    done < "${TMP}/uncovered"
    exit 0
  fi
  printf '=== Cobertura de proveniência invertida — MEDIÇÃO EXPLORATÓRIA ===\n'
  printf '  Escopo               : %s\n' "$(printf '%s ' "${SCOPE_ROOTS[@]}")"
  printf '  Documentos no escopo : %s\n' "${n_scope}"
  printf '  Cobertos pelo grafo  : %s\n' "${n_cov}"
  printf '  Descobertos          : %s\n' "${n_unc}"
  printf '  Catraca              : NÃO armada (modo exploratório — use --baseline para armar)\n'
  if [ "${n_unc}" -gt 0 ]; then
    printf '\n  Pauta para /meta:kg backfill:\n'
    while IFS= read -r p; do [ -n "${p}" ] && printf '    · %s\n' "${p}"; done < "${TMP}/uncovered"
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# (3) BASELINE + CATRACA
# ---------------------------------------------------------------------------
# Lê o baseline ignorando comentários/linhas vazias. O `|| true` é ESSENCIAL:
# baseline vazio (ou só com cabeçalho) faz o grep sair 1 e, sob `set -euo pipefail`,
# abortaria o script INTEIRO em silêncio — o gate morreria justo no repo mais são.
read_baseline() {
  grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null | sed 's/[[:space:]]*$//' | sort -u || true
}

HARD=0
SOFT=0
: > "${TMP}/out"

# say SEV TAG PATH MSG — a TAG existe para o consumidor (lint) poder AGREGAR a
# classe volumosa (PASSIVO) numa linha só, sem perder as classes acionáveis.
say() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "${TMP}/out"
  if [ "$1" = "HARD" ]; then HARD=$((HARD + 1)); else SOFT=$((SOFT + 1)); fi
}

BASELINE_PRESENT=0
: > "${TMP}/baseline"
if [ -f "${BASELINE}" ]; then
  BASELINE_PRESENT=1
  read_baseline "${BASELINE}" > "${TMP}/baseline"
fi

if [ "${BASELINE_PRESENT}" -eq 0 ]; then
  # DEGRADE GRACIOSO que NÃO libera tudo: a ausência do baseline é ela própria a
  # violação HARD (uma só, acionável), e o passivo sai como SOFT informativo.
  # O oposto — tratar tudo como novo — reprovaria o repo inteiro e mataria o gate;
  # e silenciar tudo transformaria "apagar o baseline" em bypass do gate.
  say "HARD" "NO-BASELINE" "${BASELINE_REL}" "baseline de cobertura AUSENTE — a catraca está desarmada e nenhum documento novo pode ser distinguido do passivo. Gere: bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-provenance-coverage.sh --emit-baseline > ${BASELINE_REL}"
  while IFS= read -r p; do
    [ -n "${p}" ] || continue
    say "SOFT" "NO-BASELINE-UNCOVERED" "${p}" "sem nó no grafo (severidade rebaixada: sem baseline não há como saber se é passivo ou novo)"
  done < "${TMP}/uncovered"
else
  # (3a) Documento fora do baseline e sem nó => HARD. O coração da regra.
  comm -23 "${TMP}/uncovered" "${TMP}/baseline" > "${TMP}/novos"
  while IFS= read -r p; do
    [ -n "${p}" ] || continue
    say "HARD" "NEW" "${p}" "documento de análise NOVO sem nó no grafo — nenhum .kg.yaml o cita em trace:/evidence:. Achado estruturado nasce no grafo; o markdown é vista. Modele com /meta:kg e valide: bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <grafo>.kg.yaml"
  done < "${TMP}/novos"

  # (3b) Passivo tolerado => SOFT. É o que torna o gate adotável no 1º dia.
  comm -12 "${TMP}/uncovered" "${TMP}/baseline" > "${TMP}/passivo"
  while IFS= read -r p; do
    [ -n "${p}" ] || continue
    say "SOFT" "PASSIVO" "${p}" "passivo tolerado pelo baseline — modele no .kg.yaml e remova do baseline (a métrica de saúde é o baseline diminuindo)"
  done < "${TMP}/passivo"

  # (3c) Entrada de baseline que já não é necessária => SOFT. A catraca cobra
  #      o encolhimento: sem isto o baseline vira lixo permanente.
  while IFS= read -r p; do
    [ -n "${p}" ] || continue
    if grep -qxF "${p}" "${TMP}/uncovered"; then continue; fi
    if grep -qxF "${p}" "${TMP}/covered_in_scope"; then
      say "SOFT" "BASELINE-OBSOLETA" "${BASELINE_REL}" "entrada OBSOLETA: '${p}' já está coberta pelo grafo — remova do baseline (a catraca só encolhe)"
    else
      say "SOFT" "BASELINE-ORFA" "${BASELINE_REL}" "entrada ÓRFÃ: '${p}' não existe mais no escopo — remova do baseline"
    fi
  done < "${TMP}/baseline"

  # (3d) CATRACA — o baseline SÓ PODE ENCOLHER.
  #      Versão anterior: --previous-baseline (teste) > --base-ref > branch de
  #      integração > HEAD. Tudo interno ao repo.
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
        # CATRACA FRACA: `HEAD` (e a branch de integração LOCAL) já contêm o commit local — comparar
        # contra eles é comparar a mudança consigo mesma, e um baseline que CRESCEU e já foi commitado
        # passa despercebido. Só `origin/<integração>` (ou um --base-ref explícito) é referência forte.
        # Degrada com AVISO em vez de sair verde em silêncio (o no-op silencioso é o modo de falha que
        # esta casa mais paga: o gate parece saudável e não está trabalhando).
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
      say "HARD" "CATRACA" "${BASELINE_REL}" "CATRACA VIOLADA: '${p}' foi ACRESCENTADO ao baseline (vs ${PREV_SOURCE}) — o baseline só pode ENCOLHER. Passivo se modela no grafo, não se amplia a lista de tolerância"
    done < "${TMP}/added"
  fi
fi

# ---------------------------------------------------------------------------
# (4) SAÍDA
# ---------------------------------------------------------------------------
if [ "${FORMAT}" = "tsv" ]; then
  cat "${TMP}/out"
else
  n_scope=$(wc -l < "${TMP}/scope" | tr -d ' ')
  n_cov=$(wc -l < "${TMP}/covered_in_scope" | tr -d ' ')
  printf '=== Cobertura de proveniência invertida (escopo: docs/analysis + docs/evolution/research) ===\n'
  printf '  Documentos no escopo : %s\n' "${n_scope}"
  printf '  Cobertos pelo grafo  : %s\n' "${n_cov}"
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
