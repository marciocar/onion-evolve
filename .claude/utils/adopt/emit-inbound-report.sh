#!/usr/bin/env bash
# =============================================================================
# emit-inbound-report.sh — GERA o relatório downstream da adoção e do `--update` no `inbound/` do alvo, MEDINDO
#
# POR QUE EXISTE (recorrência medida, 2026-11-22 e 2026-11-24): o relatório era um heredoc do adopt.md com
# placeholders `<colar …>` que a sessão-fonte preenchia à mão. Em dois `--update` seguidos de um mesmo adotante
# o relatório não foi emitido, e o adotante teve de escrevê-lo. Lembrete no texto do comando não segurou; a cura
# é mecanismo: este script roda cada medição que o procedimento manda colar e escreve o arquivo inteiro, sem
# placeholder. A sessão-fonte só chama.
#
# AS SEÇÕES E AS FONTES (as mesmas que o procedimento manda colar, nada de prosa inventada):
#   Arquivos aplicados   → applied-delta.sh <DEST> <integração> (medido NO ALVO; rc 3 = NÃO MEDIDO) e, se
#                          passada, a linha "onion/vendor remota …" do vendor-branch.sh (--vendor-line)
#   Contrato KG-SSOT     → remeasure-contract.sh <DEST> 2>&1 e plan-contract-migration.sh <DEST> 2>&1, saídas
#                          inteiras, cada uma com o rc e o significado dele
#   Gate do alvo         → a ÚLTIMA linha de prove-gate-blocks.sh <DEST> e, se passada, a linha `adopter-guard: …`
#   Configuração e HARD  → só no `--update` (é onde o procedimento manda pôr estas linhas): o diff de hooks de
#                          merge-onion-hooks.sh --diff (com --settings-before), deny-monotonic.sh, sandbox-deny-advice.sh
#                          e remeasure-hard.sh, todos medidos NO ALVO
#   Novidades            → `git log --oneline <prev>..<pin>` da FONTE, com teto de linhas declarado
#   Próximos passos      → fixos (os do procedimento)
#
# ONDE ESCREVE: <DEST>/docs/evolution/inbound/<data>-<op>-<pin>.md, depois de assert-dest.sh (DEST vazio, com
# placeholder ou que não é a raiz de um repo é recusado ANTES de qualquer mkdir). Cria `_processed/`.
# IDEMPOTENTE: se já existe relatório da mesma <op> e <pin> no inbound/, ele é REESCRITO no mesmo caminho (com a
# data do nome dele), nunca duplicado num dia novo; se ele já foi movido para `_processed/` pelo alvo, não se
# re-emite (o alvo já leu) e o script diz onde está.
#
# USO  : emit-inbound-report.sh <SOURCE_ROOT> <DEST> <adopt|update> <PIN> [--prev <pin>] [--branch <br>]
#          [--integration <branch>] [--vendor-line <linha>] [--adopter-guard-line <linha>]
#          [--settings-before <settings.json de antes do merge>]   (só no --update: o diff de hooks)
#        --integration ausente: a HEAD remota do alvo (origin/HEAD) e, sem ela, `main` — a escolha vai declarada.
# ENV  : ONION_INBOUND_LOG_MAX (teto de linhas das Novidades, default 60)
# EXIT : 0 = relatório escrito com toda medição obrigatória feita
#        2 = uso (argumento faltando ou inválido, DEST recusado pelo assert-dest) — nada escrito
#        3 = relatório ESCRITO, mas alguma medição obrigatória não rodou ou não foi informada: a lacuna vai
#            declarada no arquivo («NÃO MEDIDO» com o motivo) e listada no stderr. Nunca um número inventado no lugar.
#            Conta como lacuna: medição que saiu NÃO MEDIDO, o diff de hooks sem --settings-before (update), a linha
#            da onion/vendor ausente (update), a linha do adopter-guard ausente, o pin anterior ausente (update).
#        4 = relatório ESCRITO e há um PARE (vence o 3): o update perdeu regra de deny (deny-monotonic rc 1), o
#            checkout real do alvo mudou durante a prova do gate (prove-gate-blocks rc 4) ou o alvo mudou durante
#            o plano da migração (plan-contract-migration rc 5). Não commite nem abra PR antes de investigar.
#        1 = falha de E/S ao gravar o arquivo: NADA escrito (distinto do 3 e do 4, que sempre deixam o relatório)
# PIN: normalizado para 12 caracteres pela fonte (`rev-parse --short=12`), para 7, 12 ou 40 caracteres do mesmo
# commit darem UM arquivo só.
# LINHAS DO CHAMADOR (--vendor-line, --adopter-guard-line, --branch): placeholder `<…>` (o bloco do procedimento
# copiado sem preencher) vira lacuna declarada, nunca texto do relatório; o resto é ACHATADO numa linha só, com
# `<!--`, crases e `#` no início neutralizados, para nenhuma linha forjar seção, comentário ou cerca no relatório.
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_inbound_report_selftests).
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() { echo "uso: emit-inbound-report.sh <SOURCE_ROOT> <DEST> <adopt|update> <PIN> [--prev <pin>] [--branch <br>] [--integration <branch>] [--vendor-line <linha>] [--adopter-guard-line <linha>] [--settings-before <settings.json>]" >&2; [ -n "${1:-}" ] && echo "emit-inbound-report: $1" >&2; exit 2; }

[ $# -ge 4 ] || usage "faltam argumentos posicionais"
SRC="$1"; DEST="$2"; OP="$3"; PIN="$4"; shift 4
PREV="" BR="" INT="" VENDOR_LINE="" GUARD_LINE="" SETTINGS_BEFORE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --prev|--branch|--integration|--vendor-line|--adopter-guard-line|--settings-before)
      [ $# -ge 2 ] || usage "$1 exige um valor"
      case "$1" in
        --prev) PREV="$2" ;; --branch) BR="$2" ;; --integration) INT="$2" ;;
        --vendor-line) VENDOR_LINE="$2" ;; --adopter-guard-line) GUARD_LINE="$2" ;;
        --settings-before) SETTINGS_BEFORE="$2" ;;
      esac; shift 2 ;;
    *) usage "argumento desconhecido: $1" ;;
  esac
done
case "${OP}" in adopt|update) ;; *) usage "operação '${OP}' inválida (adopt|update)" ;; esac
# O pin vira nome de arquivo: só hexadecimal, para nenhum `/` ou `..` sair do inbound/.
[[ "${PIN}" =~ ^[0-9a-f]{7,40}$ ]] || usage "PIN '${PIN}' não é um commit em hexadecimal (7 a 40)"
[ -z "${PREV}" ] || [[ "${PREV}" =~ ^[0-9a-f]{7,40}$ ]] || usage "--prev '${PREV}' não é um commit em hexadecimal (7 a 40)"
LACUNAS=() PARES=()
lacuna() { LACUNAS+=("$1"); }
pare() { PARES+=("$1"); }
# achata a linha do chamador (substituição entre aspas: no bash 5.2 o `&` cru da troca repete o casado): sem quebra, sem comentário HTML, sem crase, sem cabeçalho markdown no início
_flat() { local v="${1//$'\r'/ }" lt='&lt;!--' q="'"; v="${v//$'\n'/ }"; v="${v//<!--/"${lt}"}"; v="${v//\`/"${q}"}"
  [[ "${v}" == '#'* ]] && v="\\${v}"; printf '%s' "${v}"; }
_is_ph() { [[ "$1" == \<*\> ]]; }
if _is_ph "${INT}"; then INT=""; INT_PH=1; else INT_PH=0; fi
if _is_ph "${BR}"; then BR=""; fi
if _is_ph "${SETTINGS_BEFORE}"; then SETTINGS_BEFORE=""; fi
if _is_ph "${GUARD_LINE}"; then GUARD_LINE=""; lacuna "linha do adopter-guard (placeholder não preenchido)"
elif [ -z "${GUARD_LINE}" ]; then lacuna "linha do adopter-guard (não informada ao emissor)"; fi
if _is_ph "${VENDOR_LINE}"; then VENDOR_LINE=""; lacuna "linha da onion/vendor (placeholder não preenchido)"
elif [ -z "${VENDOR_LINE}" ] && [ "${OP}" = "update" ]; then lacuna "linha da onion/vendor (não informada ao emissor)"; fi
case "${SRC}" in ''|*'<'*|*'>'*) usage "SOURCE_ROOT vazio ou com placeholder: '${SRC}'" ;; esac
[ -d "${SRC}" ] || usage "SOURCE_ROOT não é diretório: ${SRC}"
bash "${HERE}/assert-dest.sh" "${DEST}" || exit 2
DEST="$(cd "${DEST}" && pwd -P)" || usage "DEST não resolvido"
VENDOR_LINE="$(_flat "${VENDOR_LINE}")"; GUARD_LINE="$(_flat "${GUARD_LINE}")"; BR="$(_flat "${BR}")"
# o pin canônico: 12 caracteres resolvidos na FONTE (7, 12 ou 40 do mesmo commit = o mesmo arquivo)
_norm() { git -C "${SRC}" rev-parse --short=12 --verify --quiet "$1^{commit}" 2>/dev/null; }
if _p="$(_norm "${PIN}")" && [ -n "${_p}" ]; then PIN="${_p}"; PIN_OK=1
else PIN="${PIN:0:12}"; PIN_OK=0; fi
if [ -n "${PREV}" ]; then
  if _p="$(_norm "${PREV}")" && [ -n "${_p}" ]; then PREV="${_p}"; PREV_OK=1; else PREV="${PREV:0:12}"; PREV_OK=0; fi
fi

INBOUND="${DEST}/docs/evolution/inbound"
mkdir -p "${INBOUND}/_processed" || usage "não criei ${INBOUND}/_processed"

# ── idempotência: mesmo <op>-<pin> já emitido? ───────────────────────────────────────────────────────
_prev_file="$(find "${INBOUND}" -maxdepth 1 -type f -name "*-${OP}-${PIN}.md" 2>/dev/null | sort | sed -n 1p)"
_done_file="$(find "${INBOUND}/_processed" -maxdepth 1 -type f -name "*-${OP}-${PIN}.md" 2>/dev/null | sort | sed -n 1p)"
if [ -z "${_prev_file}" ] && [ -n "${_done_file}" ]; then
  echo "relatório já processado pelo alvo: ${_done_file} — não re-emitido (o alvo já o leu)."
  exit 0
fi
if [ -n "${_prev_file}" ]; then REPORT="${_prev_file}"; DAY="$(basename "${REPORT}" | cut -c1-10)"
else DAY="$(date +%F)"; REPORT="${INBOUND}/${DAY}-${OP}-${PIN}.md"; fi

# ── nome do alvo: o checkout principal (o --update roda numa worktree irmã, cujo nome não é o do alvo) ──
_common="$(git -C "${DEST}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || _common=""
case "${_common}" in */.git) TO="$(basename "$(dirname "${_common}")")" ;; *) TO="$(basename "$(cd "${DEST}" && pwd -P)")" ;; esac

# ── a integração ──────────────────────────────────────────────────────────────────────────────────────
INT_NOTE="passada pelo chamador"
if [ -z "${INT}" ]; then
  INT="$(git -C "${DEST}" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)" && INT="${INT#origin/}" \
    && INT_NOTE="sem --integration: a HEAD remota do alvo (origin/HEAD)" \
    || { INT="main"; INT_NOTE="sem --integration e sem origin/HEAD no alvo: main por padrão"; }
  [ "${INT_PH}" = 1 ] && INT_NOTE="--integration veio com placeholder não preenchido; ${INT_NOTE}"
fi
# Mede pelo merge-base mais novo, que o applied-delta já procura; o fetch só traz a ref remota em dia.
if git -C "${DEST}" remote get-url origin >/dev/null 2>&1; then
  git -C "${DEST}" fetch -q origin "${INT}" >/dev/null 2>&1 || INT_NOTE="${INT_NOTE}; fetch de origin/${INT} falhou (medido pelas refs locais)"
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/inbound-report.XXXXXX")" || usage "mktemp falhou"
trap 'rm -rf "${TMP}"' EXIT

# ── Arquivos aplicados ────────────────────────────────────────────────────────────────────────────────
AD_OUT="$(bash "${HERE}/applied-delta.sh" "${DEST}" "${INT}" 2>"${TMP}/ad.err")"; AD_RC=$?
if [ "${AD_RC}" -eq 0 ]; then AD_TXT="${AD_OUT}"
else
  AD_TXT="NÃO MEDIDO (applied-delta rc ${AD_RC}): $(head -c 400 "${TMP}/ad.err" | tr '\n' ' ')"
  lacuna "arquivos aplicados (applied-delta rc ${AD_RC})"
fi

# ── Contrato KG-SSOT ──────────────────────────────────────────────────────────────────────────────────
RC_OUT="$(bash "${HERE}/remeasure-contract.sh" "${DEST}" 2>&1)"; RC_RC=$?
case "${RC_RC}" in
  0) RC_MEAN="todo grafo passa no MUST" ;;
  1) RC_MEAN="há dívida MUST (o número e o caminho estão acima; o update segue)" ;;
  4) RC_MEAN="não se aplica (alvo sem o contrato ou sem grafo)" ;;
  *) RC_MEAN="NÃO MEDIDO"; lacuna "contrato KG-SSOT (remeasure-contract rc ${RC_RC})" ;;
esac
PL_OUT="$(bash "${HERE}/plan-contract-migration.sh" "${DEST}" 2>&1)"; PL_RC=$?
case "${PL_RC}" in
  0) PL_MEAN="plano gerado: o resumo e a planilha estão acima; aplicar é do dono do corpus" ;;
  2) PL_MEAN="há dívida MUST e falta o perfil: a orientação está acima" ;;
  4) PL_MEAN="não roda (o corpus passa no MUST ou o contrato não se aplica)" ;;
  5) PL_MEAN="o alvo MUDOU durante o plan: PARE e investigue"; pare "migração planejada: o alvo mudou durante o plan (plan-contract-migration rc 5)" ;;
  *) PL_MEAN="NÃO MEDIDO"; lacuna "migração planejada (plan-contract-migration rc ${PL_RC})" ;;
esac

# ── Gate do alvo ──────────────────────────────────────────────────────────────────────────────────────
PG_OUT="$(bash "${HERE}/prove-gate-blocks.sh" "${DEST}" 2>&1)"; PG_RC=$?
PG_LAST="$(printf '%s\n' "${PG_OUT}" | sed '/^[[:space:]]*$/d' | tail -n 1)"
[ -n "${PG_LAST}" ] || PG_LAST="bloqueio NÃO PROVADO: prove-gate-blocks não imprimiu veredito (rc ${PG_RC})"
case "${PG_RC}" in
  0|1) ;;   # 0 PROVADO · 1 NÃO PROVADO por defeito do gate: as duas são medição (o defeito é o achado)
  4) pare "gate do alvo: o checkout real mudou durante a prova (prove-gate-blocks rc 4)" ;;
  *) lacuna "gate do alvo (prove-gate-blocks rc ${PG_RC})" ;;
esac

# ── Configuração e HARD (só no --update) ──────────────────────────────────────────────────────────────
CFG=""
if [ "${OP}" = "update" ]; then
  if [ -z "${SETTINGS_BEFORE}" ]; then CFG="- hooks: NÃO MEDIDO (o settings.json de antes do merge não foi passado ao emissor; --settings-before)"
    lacuna "diff de hooks (sem --settings-before)"
  else
    _o="$(bash "${HERE}/merge-onion-hooks.sh" --diff "${SETTINGS_BEFORE}" "${DEST}/.claude/settings.json" 2>&1)"; _r=$?
    if [ "${_r}" -eq 0 ]; then CFG="- hooks:"$'\n''```'$'\n'"${_o}"$'\n''```'
    else CFG="- hooks: NÃO MEDIDO (merge-onion-hooks --diff rc ${_r}): $(tr '\n' ' ' <<< "${_o:0:300}")"; lacuna "diff de hooks (rc ${_r})"; fi
  fi
  _o="$(bash "${HERE}/deny-monotonic.sh" "${DEST}" "${INT}" 2>&1)"; _r=$?
  case "${_r}" in
    0) CFG="${CFG}"$'\n'"- ${_o//$'\n'/$'\n'  }" ;;
    1) CFG="${CFG}"$'\n'"- ⚠️ PARE — o update PERDEU regra de deny (deny-monotonic rc 1):"$'\n''```'$'\n'"${_o}"$'\n''```'
       pare "deny: o update PERDEU regra de deny (deny-monotonic rc 1)" ;;
    *) CFG="${CFG}"$'\n'"- deny: NÃO MEDIDO (deny-monotonic rc ${_r}): $(tr '\n' ' ' <<< "${_o:0:300}")"; lacuna "deny (deny-monotonic rc ${_r})" ;;
  esac
  _o="$(bash "${HERE}/sandbox-deny-advice.sh" "${DEST}" 2>&1)"; _r=$?
  if [ "${_r}" -eq 0 ]; then CFG="${CFG}"$'\n'"- ${_o//$'\n'/$'\n'  }"
  else CFG="${CFG}"$'\n'"- sandbox: NÃO MEDIDO (sandbox-deny-advice rc ${_r}): $(tr '\n' ' ' <<< "${_o:0:300}")"; lacuna "sandbox (sandbox-deny-advice rc ${_r})"; fi
  _o="$(bash "${HERE}/remeasure-hard.sh" "${DEST}" 2>&1)"; _r=$?
  case "${_r}" in
    0|1) CFG="${CFG}"$'\n'$'\n''```'$'\n'"${_o}"$'\n''```' ;;
    *) CFG="${CFG}"$'\n'$'\n'"HARD: NÃO MEDIDO (remeasure-hard rc ${_r}): $(tr '\n' ' ' <<< "${_o:0:300}")"; lacuna "HARD (remeasure-hard rc ${_r})" ;;
  esac
fi

# ── Novidades: o log da FONTE, não prosa ──────────────────────────────────────────────────────────────
LOG_MAX="${ONION_INBOUND_LOG_MAX:-60}"; [[ "${LOG_MAX}" =~ ^[0-9]+$ ]] && [ "${LOG_MAX}" -gt 0 ] || LOG_MAX=60
if [ -z "${PREV}" ] && [ "${OP}" = "adopt" ]; then
  NEWS="Sem pin anterior (1ª adoção): o histórico da fonte não é listado."
elif [ -z "${PREV}" ]; then
  NEWS="NÃO MEDIDO: pin anterior não informado ao emissor (--prev); o histórico da fonte não é listado."
  lacuna "novidades (pin anterior não informado)"
elif [ "${PIN_OK}" != 1 ] || [ "${PREV_OK}" != 1 ]; then
  NEWS="NÃO MEDIDO: ${PREV} ou ${PIN} não existe na fonte (${SRC})."
  lacuna "novidades (pin ausente na fonte)"
elif ! git -C "${SRC}" log --oneline --no-decorate "${PREV}..${PIN}" > "${TMP}/log" 2>"${TMP}/log.err"; then
  NEWS="NÃO MEDIDO: git log ${PREV}..${PIN} falhou na fonte: $(head -c 300 "${TMP}/log.err" | tr '\n' ' ')"
  lacuna "novidades (git log falhou)"
else
  _n="$(wc -l < "${TMP}/log" | tr -d ' ')"
  if [ "${_n}" -eq 0 ]; then NEWS="Nenhum commit na fonte entre ${PREV} e ${PIN}."
  else
    NEWS="\`git log --oneline ${PREV}..${PIN}\` da fonte: ${_n} commit(s)"
    [ "${_n}" -gt "${LOG_MAX}" ] && NEWS="${NEWS}; mostrando os ${LOG_MAX} mais novos (teto ONION_INBOUND_LOG_MAX)"
    NEWS="${NEWS}."$'\n\n''```'$'\n'"$(head -n "${LOG_MAX}" "${TMP}/log")"$'\n''```'
  fi
fi

# ── escrita (arquivo temporário no próprio inbound/ e mv: nunca um relatório pela metade) ─────────────
[ -n "${BR}" ] || BR="(branch não informada ao emissor)"
OUT="$(mktemp "${INBOUND}/.inbound-report.XXXXXX")" || usage "não criei arquivo temporário em ${INBOUND}"
{
  printf -- "---\n"
  printf "title: 'Relatório de %s Onion — pin %s'\n" "${OP}" "${PIN}"
  printf "date: %s\n" "${DAY}"
  printf "from: core (sessão-fonte, source-driven)\n"
  printf "to: %s (consumidor)\n" "${TO}"
  printf "type: flow-a-report\n"
  printf "source_commit: %s\n" "${PIN}"
  printf "previous_commit: %s\n" "${PREV:-—}"
  printf "flow: downstream (core→consumidor / distribuição)\n"
  printf "emitted_by: emit-inbound-report.sh\n"
  printf -- "---\n\n"
  printf "# Relatório de %s — pin %s\n\n" "${OP}" "${PIN}"
  printf "Gerado pelo emissor do /meta:adopt: cada seção é a saída de uma medição, nenhuma é preenchida à mão.\n\n"
  if [ "${#PARES[@]}" -gt 0 ]; then
    printf "> ⛔ **PARE** — não commite nem abra PR antes de investigar:\n"
    for l in "${PARES[@]}"; do printf ">  - %s\n" "${l}"; done
    printf "\n"
  fi
  if [ "${#LACUNAS[@]}" -gt 0 ]; then
    printf "> ⚠️ **Medição que não rodou** (vai como NÃO MEDIDO na seção, nunca como número):\n"
    for l in "${LACUNAS[@]}"; do printf ">  - %s\n" "${l}"; done
    printf "\n"
  fi
  printf "## Arquivos aplicados\n\n"
  printf "Integração: \`%s\` (%s).\n\n" "${INT}" "${INT_NOTE}"
  printf '```\n%s\n```\n' "${AD_TXT}"
  if [ -n "${VENDOR_LINE}" ]; then printf "\n%s\n" "${VENDOR_LINE}"
  elif [ "${OP}" = "update" ]; then printf "\nLinha da onion/vendor remota: NÃO MEDIDO (não informada ao emissor).\n"; fi
  printf "\n## Contrato KG-SSOT do corpus\n\n"
  printf "remeasure-contract rc %s: %s.\n\n" "${RC_RC}" "${RC_MEAN}"
  printf '```\n%s\n```\n\n' "${RC_OUT}"
  printf "plan-contract-migration rc %s: %s.\n\n" "${PL_RC}" "${PL_MEAN}"
  printf '```\n%s\n```\n' "${PL_OUT}"
  printf "\n## Gate do alvo\n\n"
  printf "%s\n" "${PG_LAST}"
  if [ -n "${GUARD_LINE}" ]; then printf "\n%s\n" "${GUARD_LINE}"
  else printf "\nadopter-guard: NÃO MEDIDO (linha não informada ao emissor).\n"; fi
  if [ "${OP}" = "update" ]; then printf "\n## Configuração e HARD\n\n%s\n" "${CFG}"; fi
  printf "\n## Novidades / capacidades novas\n\n%s\n" "${NEWS}"
  printf "\n## Próximos passos (NO ALVO)\n\n"
  printf "1. Revisar o commit da instalação (já feito automaticamente na branch \`%s\` pelo 🔒 Procedimento de\n" "${BR}"
  printf "   Commit Durável — a instalação já é objeto git, não se perde num descarte de working-tree).\n"
  printf "2. Push / abrir PR dessa branch para a integração e mergear com **merge commit** (\`pr-merge-verified.sh --merge-commit --assert-ancestor onion/vendor\` onde houver, senão \"Create a merge commit\" no forge; nunca rebase/squash): linearizar tira a \`onion/vendor\` da ancestralidade e o próximo update conflita em falso.\n"
  printf "3. (Opcional) Devolver sinal de campo ao core via inbox/ (upstream).\n"
} > "${OUT}" || { rm -f "${OUT}"; echo "emit-inbound-report: falha ao escrever o relatório (nada escrito)" >&2; exit 1; }
chmod 0644 "${OUT}" 2>/dev/null || true
mv -f "${OUT}" "${REPORT}" || { rm -f "${OUT}"; echo "emit-inbound-report: falha ao mover para ${REPORT} (nada escrito)" >&2; exit 1; }

echo "relatório escrito: ${REPORT}"
for l in "${PARES[@]+"${PARES[@]}"}"; do echo "PARE: ${l}" >&2; done
for l in "${LACUNAS[@]+"${LACUNAS[@]}"}"; do echo "NÃO MEDIDO: ${l}" >&2; done
[ "${#PARES[@]}" -gt 0 ] && exit 4
[ "${#LACUNAS[@]}" -gt 0 ] && exit 3
exit 0
