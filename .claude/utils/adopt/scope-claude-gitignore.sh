#!/usr/bin/env bash
# =============================================================================
# scope-claude-gitignore.sh — Escopa um ignore CEGO de .claude/ no repo adotado
#
# Propósito : Um adotante pode ignorar `.claude/` INTEIRO no seu .gitignore (comum
#             quando o projeto já usava Cursor/Claude e ignorou config local). Nesse
#             caso a adoção Onion QUEBRA silenciosamente: o durable-commit faz
#             `git add .claude` → respeita o gitignore → ZERO arquivos da superfície
#             do framework (agents/commands/skills/utils/validation/hooks) E do stamp
#             `.claude/.onion-version` entram no commit. Um clone perde o marcador e
#             TODOS os guards de adotante desligam (o modo-de-falha que a REGRA 40
#             existe para evitar). Sinal de campo REAL: um adotante legacy (2026-07-24) ignorava
#             `.claude/` em DUAS linhas → 0 arquivos .claude/ commitados. [[fix-must-become-mechanism]]
#
# Mecânica  : Detecta linhas de ignore CEGO de .claude (`.claude`, `.claude/`,
#             `/.claude`, `/.claude/`, com `**/` opcional) — NÃO toca em ignores já
#             ESCOPADOS (`.claude/sessions/`, `.claude/settings.local.json`, …) nem
#             em negações (`!.claude/...`). Substitui a 1ª linha cega pelo bloco
#             escopado Onion (só efêmeros ignorados: sessions/ + settings.local.json)
#             e REMOVE as duplicatas cegas seguintes. Preserva todo o resto verbatim.
#             IDEMPOTENTE: 2ª execução = no-op (o bloco escopado já não casa "cego").
#
# Uso       : scope-claude-gitignore.sh <dest-dir>   (PATH do repo alvo)
#             Escreve in-place em <dest-dir>/.gitignore. Sem .gitignore, ou sem
#             ignore cego → no-op (a superfície .claude/ já rastreia naturalmente).
#
# Gracioso  : <dest> inválido → exit 2 (erro de uso). Falha de I/O → aviso STDERR +
#             exit 0 (não aborta a adoção). Determinístico, sem LLM, sem jq.
#
# Consumido por /meta:adopt (Fase 3 + --update) e exercitado pelo lint-selftest.sh
# (run_scope_gitignore_selftests).
# =============================================================================
set -uo pipefail

DEST="${1:-}"
[ -n "${DEST}" ] || { echo "uso: scope-claude-gitignore.sh <dest-dir>" >&2; exit 2; }
[ -d "${DEST}" ] || { echo "ERRO: dest não é diretório: ${DEST}" >&2; exit 2; }

GI="${DEST}/.gitignore"
# Sem .gitignore → a superfície .claude/ rastreia naturalmente; nada a fazer.
[ -f "${GI}" ] || exit 0

# Bloco escopado Onion (substitui o ignore cego). Só efêmeros/locais ficam ignorados.
SCOPED_MARKER='.claude/ — superfície do framework Onion é TRACKEADA'

# Já escopado (marcador presente) E sem nenhuma linha cega restante → no-op idempotente.
is_blind() {
  # $1 = linha JÁ trimada (sem espaços nas pontas). Retorna 0 se for ignore CEGO de .claude.
  case "$1" in
    '.claude'|'.claude/'|'/.claude'|'/.claude/'|'**/.claude'|'**/.claude/') return 0 ;;
    *) return 1 ;;
  esac
}

# Varre: existe alguma linha cega?
found_blind=""
while IFS= read -r raw || [ -n "${raw}" ]; do
  trimmed="${raw#"${raw%%[![:space:]]*}"}"; trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
  if is_blind "${trimmed}"; then found_blind=1; break; fi
done < "${GI}"

[ -n "${found_blind}" ] || exit 0   # nenhum ignore cego → nada a escopar (idempotente)

TMP="$(mktemp 2>/dev/null)" || { echo "AVISO: mktemp falhou — .gitignore NÃO escopado em ${DEST}." >&2; exit 0; }
emitted_scope=""
while IFS= read -r raw || [ -n "${raw}" ]; do
  trimmed="${raw#"${raw%%[![:space:]]*}"}"; trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
  if is_blind "${trimmed}"; then
    if [ -z "${emitted_scope}" ]; then
      # 1ª linha cega → substitui pelo bloco escopado.
      {
        printf '# %s (adoção); só efêmeros/locais ficam ignorados\n' "${SCOPED_MARKER}"
        printf '.claude/sessions/\n'
        printf '.claude/settings.local.json\n'
      } >> "${TMP}"
      emitted_scope=1
    fi
    # duplicatas cegas seguintes → descartadas.
    continue
  fi
  printf '%s\n' "${raw}" >> "${TMP}"
done < "${GI}"

if cat "${TMP}" > "${GI}" 2>/dev/null; then
  rm -f "${TMP}"
  # A estaca do aviso vem de campo (V1, adoção legacy 2026-07): um ignore cego de .claude/ NÃO custa só
  # o stamp Onion — custa o TRABALHO do próprio adotante. Este repo já perdera 242 arquivos (71 skills, 39
  # comandos) por ignorar .claude/ INTEIRO; some de todo clone em SILÊNCIO e só aparece meses depois como
  # referências mortas num doc que parece aspiracional. O aviso carrega essa dimensão — não é cosmético.
  echo "Onion: .gitignore escopado em ${DEST}." >&2
  echo "  .claude/ estava ignorado POR INTEIRO — isso impediria commitar a superfície do framework E o stamp" >&2
  echo "  (.onion-version); pior, QUALQUER coisa sua sob .claude/ (skills/comandos locais) sumiria de todo" >&2
  echo "  clone em SILÊNCIO, só notada meses depois por referências mortas. Agora .claude/ é TRACKEÁVEL" >&2
  echo "  (só .claude/sessions/ + .claude/settings.local.json seguem ignorados). Revise o diff do .gitignore." >&2
else
  rm -f "${TMP}"
  echo "AVISO: não foi possível escrever ${GI} (permissão?) — .claude/ pode seguir ignorado; a superfície do framework não será commitada." >&2
fi
exit 0
