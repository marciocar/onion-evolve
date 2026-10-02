#!/usr/bin/env bash
# =============================================================================
# write-stamp.sh — escrita DETERMINÍSTICA do .claude/.onion-version (adoção E update).
#
# Origem: sinal de um adotante regulado (2026-07-10, multi-linhagem) — a regra "adopted_at NUNCA re-carimba;
# a data de update vive em updated_at" existia como PROSA no adopt.md (l.506-510) e uma sessão
# a violou no --update (re-rodou o heredoc da Fase 5 verbatim). Prosa não segura deslize de LLM;
# este helper determiniza ("conserta o propagador").
#
# Semântica:
#   - Stamp AUSENTE (adoção)  → escreve tudo dos args; adopted_at=hoje; SEM updated_at.
#   - Stamp EXISTE (update)   → PRESERVA adopted_from/mode/integration_branch/adopted_at do stamp
#     antigo (args só preenchem lacunas); atualiza source_commit/source_commit_date; updated_at=hoje.
#   - adopted_at perdido no stamp antigo (re-carimbo pré-fix) → restaura do members.yaml do core
#     (--members + --member-id); sem como restaurar → NÃO inventa (omite + warning; fail-safe).
#   - integration_branch ausente no antigo e sem arg → PRESERVA a ausência (resolução por PR).
#   - Update com pin NOVO ≠ antigo → DETECTA (não conserta) artefatos que ainda citam o pin antigo:
#     `grep -rl <8 hex do pin antigo>` no repo, EXCLUINDO história (docs/evolution/inbox|inbound,
#     .claude/diary, .git, node_modules). Medido 2026-09-02 em 10 adotantes locais (Q_PIN_GREP_WORTH_IT):
#     22 arquivos citavam pin anterior, 19 eram história legítima — sem a exclusão o aviso é ruído;
#     com ela, os 3 restantes eram SSOT viva (technical-context/index.md, project.kg.yaml) — o alvo.
#
# Uso : write-stamp.sh <target_root> --framework <n> --commit <sha> --commit-date <AAAA-MM-DD>
#         [--adopted-from <url>] [--mode <m>] [--role <adopted|hub|standalone>] [--integration-branch <b>]
#         [--members <members.yaml>] [--member-id <id>]
#   --role: papel de adoção. Default 'adopted' (consumidor). 'hub' = empresa que adota os próprios
#           projetos (Camada 2 — pode rodar /meta:adopt local; ver adopter-onboarding.md). Sem --role
#           num update, PRESERVA o role do stamp (não rebaixa hub→adopted). 'source' é o core, que
#           NÃO carrega stamp (lido ao vivo por onion-version.sh).
# Exit: 0 = escrito · 2 = uso incorreto/campo obrigatório ausente
# Exercitado por lint-selftest.sh (run_write_stamp_selftests).
# =============================================================================
set -euo pipefail

TARGET=""; FRAMEWORK=""; COMMIT=""; COMMIT_DATE=""; ADOPTED_FROM=""; MODE=""; IBRANCH=""
FRAMEWORK_SET=""; COMMIT_SET=""; COMMIT_DATE_SET=""   # flag AUSENTE herda; PRESENTE E VAZIA e erro (F2)
MEMBERS=""; MEMBER_ID=""; ROLE=""
while [ "$#" -gt 0 ]; do case "$1" in
  # ⚠️ `*_SET` existe por um FAIL-OPEN que o Elenxo mediu (F2, 2026-10-02): o fallback da 1a versao
  #    olhava so `[ -z "${COMMIT}" ]`, entao `--commit ""` — que e o que um `awk` de extracao
  #    produz quando o nome do campo muda, e esta casa JA quebrou 2x nessa vizinhanca — deixava de
  #    ser ERRO (rc=2 em origin/main) e passava a HERDAR em silencio: o stamp saia dizendo
  #    `updated_at` de HOJE com o pin VELHO. Isto e exatamente "o carimbo que MENTIRIA sobre a
  #    versao do framework", que esta leva diz curar — trocar ruido por silencio e a pior regressao.
  #    Flag AUSENTE herda; flag PRESENTE E VAZIA e erro.
  --framework)          FRAMEWORK="${2:-}"; FRAMEWORK_SET=1; shift 2 ;;
  --commit)             COMMIT="${2:-}"; COMMIT_SET=1; shift 2 ;;
  --commit-date)        COMMIT_DATE="${2:-}"; COMMIT_DATE_SET=1; shift 2 ;;
  --adopted-from)       ADOPTED_FROM="${2:-}"; shift 2 ;;
  --mode)               MODE="${2:-}"; shift 2 ;;
  --role)               ROLE="${2:-}"; shift 2 ;;
  --integration-branch) IBRANCH="${2:-}"; shift 2 ;;
  --members)            MEMBERS="${2:-}"; shift 2 ;;
  --member-id)          MEMBER_ID="${2:-}"; shift 2 ;;
  -*) echo "uso: write-stamp.sh <target_root> --framework <n> --commit <sha> --commit-date <d> [...]" >&2; exit 2 ;;
  *)  [ -z "${TARGET}" ] && TARGET="$1"; shift ;;
esac; done
[ -n "${TARGET}" ] && [ -d "${TARGET}" ] || { echo "ERRO: target_root inválido: '${TARGET}'" >&2; exit 2; }

STAMP="${TARGET}/.claude/.onion-version"
# ⚠️ NORMALIZA comentario inline e espaco final (F9 do Elenxo): o fallback abaixo e o 1o consumidor
# que ESCREVE DE VOLTA o que `field()` le, e carimbo no mundo real tem `source_commit: abc # pin da
# adocao`. Sem isto o pin voltava ao stamp COM o comentario dentro e o `pin-integrity-check` recusava.
# Precedente da casa: `door-role-parity-check.sh` tem `_norm_role` existindo pela MESMA razao.
field() { grep -m1 "^$1:" "${STAMP}" 2>/dev/null | sed "s/^$1:[[:space:]]*//; s/[[:space:]]*#.*\$//; s/[[:space:]]*\$//" || true; }

# ⚠️ FALLBACK DE PIN, E ELE PRECISA RODAR **ANTES** DA COBRANÇA — sinal de campo de um adotante hub
#    em 2026-10-02, e a 1ª tentativa de cura falhou por ORDEM: eu pus o fallback dentro do bloco do
#    stamp, que roda DEPOIS desta validação, então `--role hub` sem `--commit` continuava saindo
#    `rc=2` sem escrever nada. Medido: `rc=2` antes e depois, stamp intacto — o dogfood pegou.
#    O DEFEITO DE ORIGEM: o snippet do `--promote-hub` em `adopt.md` carimbava
#    `--commit "$(git -C "$REPO" rev-parse --short=12 HEAD)"`, isto é, o HEAD DO PRÓPRIO ADOTANTE,
#    que NÃO EXISTE na história do core. O `pin-integrity-check` do `--update` seguinte acusaria pin
#    inválido (delta e early-exit desligados) e o carimbo MENTIRIA sobre a versão do framework.
#    POR QUE A CURA MORA AQUI e não no chamador: promover papel NÃO é mudar de versão. Quando não vem
#    `--commit` e já existe stamp, o pin VIGENTE é a resposta certa para QUALQUER chamador — curar só
#    o snippet deixaria a próxima chamada livre para repetir o erro.
#    `--framework` entra no mesmo fallback QUANDO A FLAG E OMITIDA — e a 1a redacao desta nota
#    afirmava que ele "entra no mesmo fallback" sem essa condicao, o que era FALSO: o snippet do
#    `--promote-hub` passava `--framework` derivado do remote do PROPRIO ADOTANTE, o arg vencia o
#    fallback, e o stamp virava `framework: <nome-do-repo-do-alvo>`. Medido por Elenxo (F1).
# FLAG PRESENTE E VAZIA = ERRO, antes de qualquer heranca (F2). Um `awk` que falhou na extracao
# produz string vazia, e herdar dali e carimbar "atualizado hoje" com o pin velho.
for _pair in "FRAMEWORK_SET:FRAMEWORK:--framework" "COMMIT_SET:COMMIT:--commit" "COMMIT_DATE_SET:COMMIT_DATE:--commit-date"; do
  _setv="${_pair%%:*}"; _rest="${_pair#*:}"; _valv="${_rest%%:*}"; _flag="${_rest##*:}"
  if [ -n "${!_setv}" ] && [ -z "${!_valv}" ]; then
    echo "ERRO: ${_flag} veio PRESENTE e VAZIO — extração falhou a montante. Omita a flag para herdar do stamp, ou passe o valor." >&2
    exit 2
  fi
done
if [ -f "${STAMP}" ]; then
  [ -z "${FRAMEWORK_SET}" ]   && FRAMEWORK="$(field framework)"
  [ -z "${COMMIT_SET}" ]      && COMMIT="$(field source_commit)"
  [ -z "${COMMIT_DATE_SET}" ] && COMMIT_DATE="$(field source_commit_date)"
fi
# F8: a mensagem nomeia as DUAS causas. A 1a redacao dizia so "sem stamp existente para herdar", e
# mandava o operador procurar um stamp que ESTAVA la (campo vazio ou campo ausente no stamp).
[ -n "${FRAMEWORK}" ] && [ -n "${COMMIT}" ] && [ -n "${COMMIT_DATE}" ] \
  || { echo "ERRO: framework/source_commit/source_commit_date indefinidos — stamp AUSENTE, ou PRESENTE sem o(s) campo(s). Passe --framework/--commit/--commit-date." >&2; exit 2; }

OLD_EXISTS=""
if [ -f "${STAMP}" ]; then
  OLD_EXISTS=1
  # PRESERVE: o stamp antigo vence os args nestes campos (semântica única do audit 2026-07-01 #5)
  old_from="$(field adopted_from)";        [ -n "${old_from}" ]  && ADOPTED_FROM="${old_from}"
  old_mode="$(field mode)";                [ -n "${old_mode}" ]  && MODE="${old_mode}"
  old_ib="$(field integration_branch)";    [ -n "${old_ib}" ]    && IBRANCH="${old_ib}"
  # ROLE: --role explícito VENCE (é como um --update vira hub, ou um --promote-hub); sem arg,
  # PRESERVA o role do stamp antigo (um update não rebaixa um hub p/ adopted).
  old_role="$(field role)";  [ -z "${ROLE}" ] && [ -n "${old_role}" ] && ROLE="${old_role}"
  ADOPTED_AT="$(field adopted_at)"
  OLD_COMMIT="$(field source_commit)"
else
  ADOPTED_AT="$(date +%F)"
fi
# Default + validação do papel de ADOÇÃO (source não carrega stamp — é lido ao vivo por onion-version.sh).
[ -n "${ROLE}" ] || ROLE="adopted"
# ⚠️ `standalone` entrou em 2026-09-15, e a ausência dele era um MECANISMO SEM PORTA DE ENTRADA: o
# transporte aprendeu a cortar por papel, o `--update` aprendeu a LER o papel do stamp — e o stamp
# recusava justamente o papel que corta. Medido pela passada adversarial: o único standalone do mundo
# (o repo PÚBLICO onion-standalone) carrega `role: adopted`, então um `--update` nele republicaria a
# meta-fábrica exatamente como antes. Corte que não pode ser carimbado é corte que não acontece.
case "${ROLE}" in adopted|hub|standalone) : ;; *) echo "ERRO: --role deve ser 'adopted', 'hub' ou 'standalone' (veio '${ROLE}')" >&2; exit 2 ;; esac

# restauração do adopted_at perdido (re-carimbo pré-fix) — do members.yaml do core, nunca inventado
if [ -n "${OLD_EXISTS}" ] && [ -z "${ADOPTED_AT}" ] && [ -n "${MEMBERS}" ] && [ -n "${MEMBER_ID}" ] \
   && command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
  ADOPTED_AT="$(python3 - "${MEMBERS}" "${MEMBER_ID}" <<'PY'
import sys, yaml
try: ms=(yaml.safe_load(open(sys.argv[1])) or {}).get('members') or []
except Exception: sys.exit(0)
for m in ms:
    if m.get('id')==sys.argv[2] and m.get('adopted_at'): print(m['adopted_at']); break
PY
)"
fi
[ -n "${OLD_EXISTS}" ] && [ -z "${ADOPTED_AT}" ] \
  && echo "AVISO: adopted_at irrecuperável (stamp antigo sem o campo; members.yaml não resolveu) — omitido, NÃO inventado." >&2

mkdir -p "${TARGET}/.claude"
{
  printf 'framework: %s\n'          "${FRAMEWORK}"
  printf 'source_commit: %s\n'      "${COMMIT}"
  printf 'source_commit_date: %s\n' "${COMMIT_DATE}"
  printf 'role: %s\n'               "${ROLE}"
  [ -n "${ADOPTED_FROM}" ] && printf 'adopted_from: %s\n' "${ADOPTED_FROM}"
  [ -n "${ADOPTED_AT}" ]   && printf 'adopted_at: %s\n'   "${ADOPTED_AT}"
  [ -n "${OLD_EXISTS}" ]   && printf 'updated_at: %s\n'   "$(date +%F)"
  [ -n "${MODE}" ]         && printf 'mode: %s\n'         "${MODE}"
  [ -n "${IBRANCH}" ]      && printf 'integration_branch: %s\n' "${IBRANCH}"
} > "${STAMP}"
# D_GREP_OLD_PIN — detecta, não conserta: corrigir cada artefato exige a semântica de cada um.
OLD_COMMIT="${OLD_COMMIT:-}"
if [ -n "${OLD_EXISTS}" ] && [ -n "${OLD_COMMIT}" ] && [ "${OLD_COMMIT:0:8}" != "${COMMIT:0:8}" ]; then
  stale="$(grep -rl --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=inbox --exclude-dir=inbound \
    --exclude-dir=diary --exclude=.onion-version -- "${OLD_COMMIT:0:8}" "${TARGET}" 2>/dev/null || true)"
  if [ -n "${stale}" ]; then
    n="$(printf '%s\n' "${stale}" | grep -c .)"
    echo "AVISO: ${n} referência(s) ao pin anterior (${OLD_COMMIT:0:8}) neste repo, fora da história — revise:" >&2
    printf '%s\n' "${stale}" | sed "s#^${TARGET}/##; s#^#  · #" >&2
  fi
fi
echo "stamp escrito: ${STAMP} ($([ -n "${OLD_EXISTS}" ] && echo "update — adopted_at preservado: ${ADOPTED_AT:-<ausente>}" || echo "adoção — adopted_at: ${ADOPTED_AT}"))"