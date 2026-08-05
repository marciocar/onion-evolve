#!/usr/bin/env bash
# =============================================================================
# mail-receiver.sh — "receiver que acorda": acelerador de co-evolução (pull + evento).
#
# F1.4 do roadmap de federação (RFC-0004), P0-1 parcial. O hook "you have mail"
# (co-evolution-inbox-check.sh) só dispara no INÍCIO de sessão (motd). Este receiver é o
# ACELERADOR (research S2·F6: pull + evento-acelerador, tipo Flux): rodável por cron/watcher OU chamado
# pelos carteiros (co-deliver/co-relay) após entregar — ao detectar mail NOVO nos canais, AVISA o humano
# (ntfy) p/ rodar o pull mais cedo, em vez de esperar a próxima sessão.
#
# Invariantes preservadas (RFC-0001/0004): mantém git-async como SSOT (só LÊ arquivos locais, não puxa/
# aplica nada); NÃO vira push-para-adotar (só notifica o HUMANO); NÃO quebra I3 (zero commit cross-repo).
# Dedup por assinatura do conjunto não-lido → não spama o mesmo mail.
#
# Uso : mail-receiver.sh [--repo <dir>] [--force] [--dry-run]
#   --repo   : repo alvo (default: git-root do cwd). Canais: docs/evolution/{inbox,inbound}.
#   --force  : ignora o dedup (avisa mesmo se já avisou este conjunto).
#   --dry-run: computa + imprime a mensagem, NÃO toca estado nem envia ntfy.
# Wake (PULL-first): push só se $NTFY_TOPIC E $NTFY_URL setados → POST p/ $NTFY_URL/$NTFY_TOPIC;
# senão → stdout (cron loga). SEM default público ntfy.sh (tópico adivinhável = exposição).
# Gracioso, determinístico. Exercitado por lint-selftest.sh (run_mail_receiver_selftests).
# =============================================================================
set -uo pipefail

REPO=""; FORCE=""; DRY=""
while [ "$#" -gt 0 ]; do case "$1" in
  --repo) REPO="${2:-}"; shift 2 ;;
  --force) FORCE=1; shift ;;
  --dry-run) DRY=1; shift ;;
  *) echo "uso: mail-receiver.sh [--repo <dir>] [--force] [--dry-run]" >&2; exit 2 ;;
esac; done
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -d "${REPO}" ] || { echo "ERRO: repo inexistente: ${REPO}" >&2; exit 2; }

_unread() {  # <canal> → lista de basenames não-lidos (1º nível, exclui _processed/README)
  local d="${REPO}/docs/evolution/$1"
  [ -d "${d}" ] || return 0
  find "${d}" -maxdepth 1 -type f -name '*.md' ! -iname 'readme.md' 2>/dev/null -printf '%f\n' | LC_ALL=C sort
}

SET="$( { _unread inbox; _unread inbound; } | LC_ALL=C sort )"
N="$(printf '%s' "${SET}" | grep -c . || true)"
[ "${N}" -gt 0 ] || exit 0   # sem mail → nada a acordar (silencioso)

SIG="$(printf '%s' "${SET}" | sha256sum | cut -d' ' -f1)"
STATE="${REPO}/.claude/sessions/.mail-receiver.state"

if [ -z "${FORCE}" ] && [ -z "${DRY}" ] && [ -f "${STATE}" ] && [ "$(cat "${STATE}" 2>/dev/null)" = "${SIG}" ]; then
  exit 0   # já avisado este conjunto — dedup (não spama)
fi

nb="$(_unread inbox | grep -c . || true)"; na="$(_unread inbound | grep -c . || true)"
MSG="📬 Onion co-evolução ($(basename "${REPO}")): ${N} não-lido(s)"
[ "${nb}" -gt 0 ] && MSG="${MSG} · ${nb} inbox(upstream)"
[ "${na}" -gt 0 ] && MSG="${MSG} · ${na} inbound(downstream)"
MSG="${MSG} — rode /meta:co-evolve para pull/triagem."

if [ -n "${DRY}" ]; then printf '%s\n' "${MSG}"; exit 0; fi

# WAKE (PULL-first): o canal primário é o hook SessionStart (PULL). O ntfy é um
# acelerador OPCIONAL — e exige NTFY_URL explícito: SEM default público `ntfy.sh`
# (tópico adivinhável em host público = qualquer um assina/publica). Ausente → stdout.
if [ -n "${NTFY_TOPIC:-}" ] && [ -n "${NTFY_URL:-}" ] && command -v curl >/dev/null 2>&1; then
  curl -s -H "Title: Onion co-evolução" -d "${MSG}" "${NTFY_URL}/${NTFY_TOPIC}" >/dev/null 2>&1 \
    && echo "mail-receiver: acordou via ntfy (${N} não-lido)." \
    || echo "mail-receiver: ntfy falhou — ${MSG}"
else
  printf '%s\n' "${MSG}"
fi

# persiste a assinatura (dedup) — .claude/sessions/ é gitignored (estado local)
mkdir -p "${REPO}/.claude/sessions" 2>/dev/null && printf '%s' "${SIG}" > "${STATE}" 2>/dev/null || true
exit 0
