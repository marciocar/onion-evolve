#!/usr/bin/env bash
# Oferece (não impõe) o gate de CI ao adotante — com forge detectado e lint VERDE antes.
#
# ── POR QUE OFERTA, E NÃO EMBARQUE ──────────────────────────────────────────────────────
# Medição de 2026-08-16 nos adotantes: CI rodando a maquinaria em 1 de 7, e o githook local
# — que é o que o adopt instala — é PULÁVEL com `git commit --no-verify` (o autor deste
# script o pulou três vezes no mesmo dia). Logo o CI é o gate que fecha o buraco.
# Mas embarcar calado erraria três vezes:
#   · FORGE — 1 dos 7 adotantes medidos não está no GitHub; cravar `.github/workflows`
#     assume plataforma, e o Onion tem adapter de forge exatamente para não assumir.
#   · CONTA ALHEIA — minutos de CI são dinheiro do adotante; ligar sem perguntar é gastar
#     por ele.
#   · DIA 1 VERMELHO — repo recém-adotado quase sempre tem violação (baseline, contagens).
#     CI vermelho na primeira hora é o que faz alguém APAGAR o arquivo: perde-se o gate e a
#     confiança. Por isso o lint tem de estar VERDE antes de o CI existir.
#
# Sem `--apply` este script apenas RELATA o que faria (propor→confirmar). Com `--apply`,
# escreve o workflow — e nunca sobrescreve um existente.
#
# Uso: offer-onion-ci.sh <dest-dir> [--apply]
set -uo pipefail

DEST="${1:-}"
[ -n "${DEST}" ] || { echo "uso: offer-onion-ci.sh <dest-dir> [--apply]" >&2; exit 2; }
[ -d "${DEST}/.git" ] || { echo "✗ '${DEST}' não é repositório git" >&2; exit 2; }
APPLY=0
[ "${2:-}" = "--apply" ] && APPLY=1

TPL="$(dirname "${BASH_SOURCE[0]}")/ci-workflow-onion.tpl"
[ -f "${TPL}" ] || { echo "✗ template ausente: ${TPL}" >&2; exit 2; }
TARGET="${DEST}/.github/workflows/onion-validate.yml"

# ── 1. FORGE — só oferece onde o artefato serve ─────────────────────────────────────────
REMOTE="$(git -C "${DEST}" remote get-url origin 2>/dev/null || true)"
case "${REMOTE}" in
  *github.com*|*github*) : ;;
  "") echo "⊘ sem remote 'origin' — CI não se aplica (nada a disparar). Nenhuma mudança." >&2; exit 0 ;;
  *) echo "⊘ o remote não é GitHub (${REMOTE%%:*}…) — este template é do GitHub Actions." >&2
     echo "  O lint roda em QUALQUER CI: o comando é 'bash .claude/validation/lint-artifacts.sh'." >&2
     echo "  Nenhuma mudança feita." >&2; exit 0 ;;
esac

# ── 2. NEVER-CLOBBER ────────────────────────────────────────────────────────────────────
if [ -f "${TARGET}" ]; then
  echo "⊘ '${TARGET#${DEST}/}' já existe — não sobrescrevo. Nenhuma mudança." >&2
  exit 0
fi

# ── 3. LINT VERDE ANTES (a trava que protege o dia 1) ───────────────────────────────────
LINT="${DEST}/.claude/validation/lint-artifacts.sh"
if [ ! -f "${LINT}" ]; then
  echo "⊘ alvo sem .claude/validation/lint-artifacts.sh — não há gate a rodar ainda." >&2
  exit 0
fi
if ! ( cd "${DEST}" && bash "${LINT}" >/dev/null 2>&1 ); then
  echo "✗ o lint do alvo REPROVA agora — CI não deve nascer vermelho." >&2
  echo "  Conserte primeiro:  cd ${DEST} && bash .claude/validation/lint-artifacts.sh" >&2
  echo "  Depois rode esta oferta de novo. (CI vermelho no dia 1 é o que faz apagarem o arquivo.)" >&2
  exit 1
fi

# ── 4. CONSENTIMENTO ────────────────────────────────────────────────────────────────────
if [ "${APPLY}" -eq 0 ]; then
  echo "✓ APLICÁVEL: forge=GitHub · lint do alvo VERDE · sem workflow prévio." >&2
  echo "  O que faria: criar '${TARGET#${DEST}/}' rodando o lint determinístico em cada PR." >&2
  echo "  Custo: minutos de CI da conta do adotante. Ganho: o gate deixa de ser pulável com --no-verify." >&2
  echo "  PERGUNTE ao dono do repositório e, se ele aceitar, rode com --apply." >&2
  exit 0
fi

mkdir -p "${DEST}/.github/workflows"
cp "${TPL}" "${TARGET}"
echo "✓ CI instalado em '${TARGET#${DEST}/}' — o gate agora roda no PR, onde --no-verify não alcança." >&2
exit 0
