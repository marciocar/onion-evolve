#!/usr/bin/env bash
# =============================================================================
# spool-import.sh — importa para o inbox/ deste repo os sinais que o carteiro deixou no SPOOL
#
# Propósito : Metade de chegada da entrega por spool do co-relay.sh. Quando o remetente roda com o
#             sandbox do Claude Code ligado, a escrita no inbox/ do destino pode dar "Read-only file
#             system" mesmo com o caminho no sandbox.filesystem.allowWrite: uma regra de permissão
#             `Edit(//<destino>/**)` no deny do remetente vira um denyWrite do sandbox, montado em
#             leitura DEPOIS da exceção do inbox, que fica por baixo (medido em 2026-11-07, Claude Code
#             2.1.319, bwrap 0.9.0; ver o SPOOL no cabeçalho do co-relay.sh). Aí o carteiro escreve num
#             diretório FORA dos repos, um por destinatário, e esta peça, rodando NA SESSÃO DO DESTINO
#             (hook SessionStart, hook UserPromptSubmit e /meta:co-evolve), traz o sinal para o inbox/ dela.
#
# Spool     : ${ONION_SPOOL_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/onion-spool}/<slug>/
#             <slug> = o caminho físico (pwd -P) da raiz do destino, com todo caractere fora de
#             [A-Za-z0-9] trocado por '-' (a mesma convenção do ~/.claude/projects). O remetente não
#             tem members.yaml; o caminho é o nome que os dois lados derivam sem combinar nada.
#
# Regras    : só *.md de 1º nível (o carteiro escreve `.<nome>.tmp.*` e renomeia: arquivo pela
#             metade nunca é lido). Para cada sinal:
#               · sem homônimo no inbox/        → move (cp + rm) para o inbox/, UNTRACKED (I3 intacto:
#                                                 ninguém commita; a triagem é da sessão do destino);
#               · homônimo byte-idêntico        → já chegou: apaga a cópia do spool;
#               · homônimo diferente, untracked → atualização ainda não triada: substitui (o mesmo que o
#                                                 carteiro faz na entrega direta);
#               · homônimo diferente, TRACKED   → o destino já commitou a versão anterior: FICA no spool
#                                                 e conta como pendente (nunca mexe na árvore commitada).
#             A guarda de destino, a de destino público, a marca reviewed_for_public e o dedup contra
#             _processed/ já rodaram no remetente, que LÊ o destino (a leitura o sandbox não barra).
#
# Saída     : stdout = uma linha "imported=<n> pending=<n>" (para o hook); avisos em stderr.
#             Sempre exit 0 quando chamado com --hook (a sessão nunca deixa de abrir por causa disto);
#             sem --hook, exit 1 se algum sinal não pôde ser importado por erro de escrita.
# Limite    : quem escreve no spool sem o carteiro (cp à mão) pula as guardas do remetente; é o mesmo
#             limite de quem copia direto no inbox/, que existe desde o 1º dia. O spool nasce 0700.
# Uso       : spool-import.sh [--repo <raiz>] [--hook] [--dry-run]
# =============================================================================
set -uo pipefail

REPO="" ; HOOK=0 ; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 || exit 2 ;;
    --hook) HOOK=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) echo "uso: spool-import.sh [--repo <raiz>] [--hook] [--dry-run]" >&2; exit 2 ;;
    *) echo "ERRO: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
REPO="$(cd "${REPO}" 2>/dev/null && pwd -P)" || { echo "imported=0 pending=0"; exit 0; }

spool_slug() { printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'; }
SPOOL_ROOT="${ONION_SPOOL_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/onion-spool}"
SPOOL="${SPOOL_ROOT}/$(spool_slug "${REPO}")"
INBOX="${REPO}/docs/evolution/inbox"

imported=0 ; pending=0 ; failed=0
if [ -d "${SPOOL}" ]; then
  for f in "${SPOOL}"/*.md; do
    [ -f "${f}" ] || continue
    base="$(basename "${f}")"
    case "${base}" in .*|[Rr][Ee][Aa][Dd][Mm][Ee].md) continue ;; esac
    dest="${INBOX}/${base}"
    if [ -e "${dest}" ]; then
      if cmp -s "${f}" "${dest}"; then
        [ "${DRY}" -eq 1 ] || rm -f "${f}"
        continue
      fi
      if git -C "${REPO}" ls-files --error-unmatch "docs/evolution/inbox/${base}" >/dev/null 2>&1; then
        echo "AVISO: ${base} chegou pelo spool com conteúdo novo, mas o inbox/ já COMMITOU a versão anterior — fica em ${SPOOL}/ (renomeie para entregar)." >&2
        pending=$((pending + 1))
        continue
      fi
    fi
    if [ "${DRY}" -eq 1 ]; then echo "importaria: ${base}" >&2; imported=$((imported + 1)); continue; fi
    mkdir -p "${INBOX}" 2>/dev/null
    if cp "${f}" "${dest}.spool-tmp.$$" 2>/dev/null && mv -f "${dest}.spool-tmp.$$" "${dest}" 2>/dev/null; then
      rm -f "${f}"
      imported=$((imported + 1))
    else
      rm -f "${dest}.spool-tmp.$$" 2>/dev/null
      echo "AVISO: não consegui escrever ${dest} — o sinal fica em ${SPOOL}/." >&2
      pending=$((pending + 1)); failed=$((failed + 1))
    fi
  done
fi
echo "imported=${imported} pending=${pending}"
[ "${HOOK}" -eq 1 ] && exit 0
[ "${failed}" -eq 0 ]
