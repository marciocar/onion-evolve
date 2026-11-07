#!/usr/bin/env bash
# =============================================================================
# session-trailer.sh — a linha `Claude-Session: <URL>` dos commits que a ADOÇÃO escreve no alvo.
#
# Medido em 2026-11-07 (--update de um adotante): os commits da onion/vendor e o commit durável saíam
# só com a assinatura do `attribution.commit` do alvo; a linha da sessão, que todo commit da casa leva,
# faltava, e a sessão do adotante não tinha como saber de qual sessão aquele commit veio.
#
# A sessão NUNCA é inventada. Fontes, nesta ordem, e cada uma conferida pela forma:
#   1. ONION_CLAUDE_SESSION_URL      — quem chama passa a URL inteira (https://claude.ai/code/session_…);
#   2. CLAUDE_CODE_BRIDGE_SESSION_ID — o id que o Claude Code exporta numa sessão ligada ao claude.ai
#                                      (session_…), que vira a mesma URL.
# Nenhuma presente, ou forma inválida → saída VAZIA e rc 0: o commit sai sem a linha, e quem chama diz
# isso numa nota (`--note` imprime a nota pronta no stderr).
# O id LOCAL (CLAUDE_CODE_SESSION_ID, um UUID) NÃO serve: ele não é endereço de sessão no claude.ai, e
# montar uma URL com ele seria escrever no histórico do adotante um link que não abre.
#
# Uso:  session-trailer.sh            → imprime `Claude-Session: <URL>` ou nada
#       session-trailer.sh --note     → idem, e no stderr a nota quando não há sessão conhecida
# Exercitado por lint-selftest.sh (run_vendor_push_trailer_selftests).
# =============================================================================
set -uo pipefail

_url=""
if [ -n "${ONION_CLAUDE_SESSION_URL:-}" ]; then
  if [[ "${ONION_CLAUDE_SESSION_URL}" =~ ^https://claude\.ai/code/session_[A-Za-z0-9]+$ ]]; then
    _url="${ONION_CLAUDE_SESSION_URL}"
  fi
elif [ -n "${CLAUDE_CODE_BRIDGE_SESSION_ID:-}" ]; then
  if [[ "${CLAUDE_CODE_BRIDGE_SESSION_ID}" =~ ^session_[A-Za-z0-9]+$ ]]; then
    _url="https://claude.ai/code/${CLAUDE_CODE_BRIDGE_SESSION_ID}"
  fi
fi

if [ -n "${_url}" ]; then
  printf 'Claude-Session: %s\n' "${_url}"
elif [ "${1:-}" = "--note" ]; then
  echo "Onion: sessão do Claude Code desconhecida no ambiente (sem ONION_CLAUDE_SESSION_URL nem CLAUDE_CODE_BRIDGE_SESSION_ID válidos) — o commit sai SEM a linha Claude-Session; nada foi inventado." >&2
fi
exit 0
