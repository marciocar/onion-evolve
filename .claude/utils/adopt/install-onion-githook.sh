#!/usr/bin/env bash
# =============================================================================
# install-onion-githook.sh — Provisiona o pre-commit NATIVO do Onion no adotado
#
# Propósito : Padronizar o hook de pre-commit dos adotantes no MESMO mecanismo
#             que o core Onion usa — git hook NATIVO via `core.hooksPath .githooks`,
#             dependency-free e à prova de worktree (degrada gracioso sem
#             node_modules). Substitui a necessidade de husky (que existe só para
#             REGISTRAR hooks — trabalho que o core.hooksPath faz nativo de graça)
#             e dissolve, na raiz, o atrito ENOENT da adoção legacy
#             (inbox/_processed/2026-06-27-adopt-legacy-husky-precommit-enoent.md).
#             Decisão: docs/analysis/onion-adr-native-githooks-standard-2026-06.md
#
# Mecânica  : (1) copia githook-pre-commit-onion.tpl → <DEST>/.githooks/pre-commit
#                 (NEVER-CLOBBER: se já há pre-commit próprio e DIFERENTE, grava
#                 sidecar pre-commit.onion p/ merge manual; idêntico → no-op).
#             (2) detecta husky → AVISA migração (não desinstala — é do adotante).
#             (3) core.hooksPath: seta .githooks SÓ se UNSET (never-clobber). Se já
#                 aponta p/ husky/custom, NÃO sobrescreve — avisa p/ ativar consciente.
#             IDEMPOTENTE: 2ª rodada = no-op.
#
# Uso       : install-onion-githook.sh <dest-dir>   (PATH do repo alvo)
#
# Gracioso  : dest inválido / não-repo / template ausente → exit 2 (erro de uso).
#             Falha de I/O / permissão → aviso STDERR + exit 0 (não aborta a adoção).
#             Sem `set -e` de propósito, p/ controlar o exit gracioso nos I/O.
#
# Determinístico, sem LLM. Consumido por /meta:adopt (Fase 3 + --update) e
# exercitado pelo lint-selftest.sh (run_githook_selftests).
# =============================================================================
set -uo pipefail

DEST="${1:-}"
[ -n "${DEST}" ] || { echo "uso: install-onion-githook.sh <dest-dir>" >&2; exit 2; }
[ -d "${DEST}" ] || { echo "ERRO: dest não é diretório: ${DEST}" >&2; exit 2; }
git -C "${DEST}" rev-parse --git-dir >/dev/null 2>&1 || { echo "ERRO: dest não é repo git: ${DEST}" >&2; exit 2; }

TPL="$(dirname "$0")/githook-pre-commit-onion.tpl"
[ -f "${TPL}" ] || { echo "ERRO: template não encontrado: ${TPL}" >&2; exit 2; }

HOOKDIR="${DEST}/.githooks"
HOOK="${HOOKDIR}/pre-commit"
mkdir -p "${HOOKDIR}" 2>/dev/null || { echo "AVISO: não criou ${HOOKDIR} (permissão?) — hook não provisionado." >&2; exit 0; }

# (1) Provisiona o pre-commit — NEVER-CLOBBER.
if [ -f "${HOOK}" ]; then
  if cmp -s "${TPL}" "${HOOK}" 2>/dev/null; then
    echo "Onion: .githooks/pre-commit já é o template Onion (no-op)." >&2
  else
    if cp "${TPL}" "${HOOK}.onion" 2>/dev/null && chmod +x "${HOOK}.onion" 2>/dev/null; then
      echo "Onion: .githooks/pre-commit já existe — Onion gravado como pre-commit.onion (merge manual)." >&2
    else
      echo "AVISO: falha ao gravar ${HOOK}.onion." >&2
    fi
  fi
else
  if cp "${TPL}" "${HOOK}" 2>/dev/null && chmod +x "${HOOK}" 2>/dev/null; then
    echo "Onion: .githooks/pre-commit provisionado (hook nativo)." >&2
  else
    echo "AVISO: falha ao gravar ${HOOK}." >&2; exit 0
  fi
fi

# (2) Detecta husky → recomenda migração (não desinstala — decisão do adotante).
if [ -d "${DEST}/.husky" ] || grep -q '"husky"' "${DEST}/package.json" 2>/dev/null; then
  echo "AVISO: husky detectado. O padrão Onion é hook nativo (core.hooksPath). Para migrar:" \
       "remova .husky/ + a dep husky e ative o nativo (passo abaixo). Ver ADR onion-adr-native-githooks-standard." >&2
fi

# (3) core.hooksPath — NEVER-CLOBBER: só seta se UNSET.
CURRENT="$(git -C "${DEST}" config --local --get core.hooksPath 2>/dev/null || true)"
if [ -z "${CURRENT}" ]; then
  git -C "${DEST}" config core.hooksPath .githooks 2>/dev/null \
    && echo "Onion: core.hooksPath → .githooks (hook nativo ativo)." >&2 \
    || echo "AVISO: não setou core.hooksPath (ative à mão: git -C ${DEST} config core.hooksPath .githooks)." >&2
elif [ "${CURRENT}" = ".githooks" ]; then
  echo "Onion: core.hooksPath já = .githooks (no-op)." >&2
else
  echo "AVISO: core.hooksPath já = '${CURRENT}' (husky/custom) — NÃO sobrescrito." \
       "Para ativar o hook nativo Onion: git -C ${DEST} config core.hooksPath .githooks" >&2
fi
exit 0
