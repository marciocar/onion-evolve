#!/usr/bin/env bash
# ===========================================================================
# voice-conduct-check.sh — confere o arquivo de VOZ E CONDUTA da persona contra o esquema da vertical
# company-brain-context.
#
# POR QUE EXISTE (selo D_PERSONA_VOICE_CONDUCT_PIECE_1111, 2026-11-11, card SAC-417): o primeiro cliente
# regulou uma v1 local das regras da persona de serviço (documento em prosa, com dono e histórico) e pediu
# ao core a peça como contrato: arquivo por adotante, versionado e aprovado, carregado a cada resposta, com
# gate medido. Prosa com dono é DECLARAÇÃO; este validador é a verificação: esquema, histórico que contém a
# versão atual, aprovador que é o dono, revisão periódica não vencida, e pedir separado de aprovar.
#
# A PRÓXIMA PEÇA (não construída nesta onda): o gate pré-envio, que mede a MENSAGEM (tamanho, marcações,
# assinatura, link testado) contra o bloco `send_gate` deste arquivo. Aqui só se confere que o bloco tem forma.
#
# Onde mora o arquivo: <pasta do contexto company-brain>/voice-conduct.yaml, com a pasta resolvida por
#   .claude/utils/scope/resolve-context-dir.sh company-brain (declaração explícita vence; default
#   docs/company-brain-context). --file <caminho> sobrepõe.
#
# Uso:  bash .claude/validation/voice-conduct-check.sh [<raiz>] [--file <arquivo>] [--today AAAA-MM-DD]
#                                                      [--format tsv|human] [--require]
#   --require : arquivo ausente vira achado (VC-FILE-ABSENT, rc 1). É o modo do warm-up da persona: sem
#               regra aprovada a persona não fala. Sem a flag, arquivo ausente sai 0 com aviso no stderr
#               (o core e o adotante que ainda não tem persona não têm o que julgar).
# Exit: 0 vale (ou nada a julgar sem --require) · 1 algum achado · 2 NÃO PUDE JULGAR (python3/PyYAML
#       ausente, esquema ausente, YAML ilegível, declaração de contexto inválida). rc 2 nunca é verde.
# Exercitado por lint-selftest.sh (run_voice_conduct_selftests).
# ===========================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT=""; FILE=""; REQUIRE=0; PASS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --file)   [ "$#" -ge 2 ] || { echo "voice-conduct-check: --file pede um arquivo" >&2; exit 2; }; FILE="$2"; shift 2 ;;
    --today)  [ "$#" -ge 2 ] || { echo "voice-conduct-check: --today pede AAAA-MM-DD" >&2; exit 2; }; PASS+=(--today "$2"); shift 2 ;;
    --format) [ "$#" -ge 2 ] || { echo "voice-conduct-check: --format pede tsv|human" >&2; exit 2; }; PASS+=(--format "$2"); shift 2 ;;
    --require) REQUIRE=1; shift ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "voice-conduct-check: opção desconhecida: $1" >&2; exit 2 ;;
    *) [ -z "${ROOT}" ] && ROOT="$1" || { echo "voice-conduct-check: raiz repetida: $1" >&2; exit 2; }; shift ;;
  esac
done
[ -n "${ROOT}" ] || ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -d "${ROOT}" ] || { echo "voice-conduct-check: raiz inexistente: ${ROOT} — não pude julgar" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "voice-conduct-check: python3 ausente — não pude julgar" >&2; exit 2; }
python3 -c 'import yaml' 2>/dev/null || { echo "voice-conduct-check: PyYAML ausente — não pude julgar" >&2; exit 2; }

SCHEMA="${HERE}/../utils/company-brain/voice-conduct.schema.yaml"
[ -f "${SCHEMA}" ] || { echo "voice-conduct-check: esquema ausente: ${SCHEMA} — não pude julgar" >&2; exit 2; }

if [ -z "${FILE}" ]; then
  RESOLVER="${HERE}/../utils/scope/resolve-context-dir.sh"
  dir="docs/company-brain-context"
  if [ -f "${RESOLVER}" ]; then
    dir="$(bash "${RESOLVER}" company-brain --repo "${ROOT}" 2>/dev/null)"; rc=$?
    [ "${rc}" -eq 0 ] || { echo "voice-conduct-check: o resolver de contexto recusou 'company-brain' (rc=${rc}) — não pude julgar" >&2; exit 2; }
  fi
  FILE="${ROOT}/${dir}/voice-conduct.yaml"
else
  case "${FILE}" in /*) : ;; *) FILE="${ROOT}/${FILE}" ;; esac
fi

if [ ! -f "${FILE}" ]; then
  if [ "${REQUIRE}" -eq 1 ]; then
    printf 'VC-FILE-ABSENT\t%s\tsem arquivo de voz e conduta aprovado: a persona não fala\n' "${FILE#"${ROOT}"/}"
    exit 1
  fi
  echo "voice-conduct-check: sem ${FILE#"${ROOT}"/} — nada a julgar (use --require no warm-up da persona)" >&2
  exit 0
fi

python3 -I -B "${HERE}/voice-conduct-check.py" --file "${FILE}" --schema "${SCHEMA}" "${PASS[@]}"
