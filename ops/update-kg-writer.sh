#!/usr/bin/env bash
# Update do onion-kg-writer (MCP de escrita de KG do chat da casa) — o ciclo repetível, no molde do
# ops/update-bridge.sh: pré-voo, NOOP, backup do estado irreversível, troca do código, reinício e
# conferência por CONTAGEM, com o rollback impresso.
#
# POR QUE EXISTE (2026-10-13): a 1ª atualização pós-GitStore foi feita por um script de scratchpad que
# fazia `sudo systemctl restart onion-vps-mcp-kg-writer` e `git -C <worktree de código> checkout --detach
# <sha>` — deploy fora de wrapper, que nada barrava. O caso virou o gatilho do veto por ALVO
# (.claude/hooks/pretooluse-moat-gate.sh), e o script graduou para cá. Com o veto armado, o deploy desta
# unidade SÓ passa por aqui (ops/moat-targets.tsv aponta este wrapper para a unidade e para a worktree).
#
# O QUE ELE FAZ (nesta ordem; falha imprime o rollback e sai — nunca executa rollback às cegas):
#   1. pré-voo: a worktree de código é worktree DO CORE (mesmo git-common-dir), está limpa, e o /health
#      responde UP — não se atualiza serviço já doente
#   2. fetch do core e SHA de origin/main; NOOP se a worktree já está nele (serviço intocado)
#   3. backup tar da raiz de dados (cada área é um repo git: o estado que não se refaz) em
#      ~/backups/onion-chat-kg/, modo 0600, com o artefato NOMEADO e o tamanho conferido
#   4. checkout --detach da worktree de código no SHA
#   5. restart da unidade — o armazém (kg_store) e o leitor do contrato são importados NO BOOT; sem
#      reiniciar, o served_commit mostraria o SHA novo julgando com o contrato velho (README do servidor)
#   6. conferência: unidade ativa, NRestarts, /health UP com o número de tools que o CÓDIGO NOVO declara
#      (contado do dict TOOLS do server.py por AST, não digitado aqui)
#
# TETO DECLARADO: /health não traz served_commit nem store_commit (só status e tools). A igualdade
# served_commit == store_commit — a prova de que o contrato julga com o código servido — se confere pelo
# probe autenticado (uma chamada a tools/call devolve os dois no envelope; com eles diferentes, vem
# `aviso_codigo`). Este script não lê o token, então não faz o probe: ele o pede, no fim.
#
# Uso: ops/update-kg-writer.sh   (chama sudo onde precisa; concorrência barrada por flock)
set -euo pipefail

CORE=/home/marcio/onion-evolve
CODE=/home/marcio/mcp-kg/core-writer
DATA=/var/lib/onion-chat-kg
UNIT=onion-vps-mcp-kg-writer
DEST="${HOME}/backups/onion-chat-kg"
HEALTH="http://172.23.0.1:3037/health"
SERVER_REL=ops/mcp-onion-kg-writer/server.py

exec 9>"/tmp/onion-update-kg-writer.lock"
flock -n 9 || { echo "[update-kg-writer] outra execução em andamento — saindo." >&2; exit 0; }

log() { printf '[update-kg-writer] %s\n' "$*"; }
OLD_SHA=""
print_rollback() {
  cat >&2 <<EOF
[update-kg-writer] ─── ROLLBACK MANUAL (capturado no pré-voo) ───
  git -C ${CODE} checkout -q --detach ${OLD_SHA:-<sha-anterior>}
  sudo systemctl restart ${UNIT}
  curl -s ${HEALTH}
  # dados: restaurável do backup nomeado acima, em ${DEST} (tar -xzf <arquivo> -C $(dirname "${DATA}"), com o serviço parado)
EOF
}
die() { printf '[update-kg-writer] ERRO: %s\n' "$*" >&2; [ -n "${OLD_SHA}" ] && print_rollback; exit 1; }

# conta as tools que o server.py declara (chaves do dict TOOLS) — a contagem esperada nasce do código
expected_tools() {
  python3 -I - "$1" <<'PY'
import ast, sys
tree = ast.parse(open(sys.argv[1], encoding="utf-8").read())
for node in tree.body:
    if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "TOOLS" for t in node.targets) \
            and isinstance(node.value, ast.Dict):
        print(len(node.value.keys)); break
else:
    sys.exit(1)
PY
}

health_tools() {  # imprime o número de tools do /health, ou nada se não estiver UP
  curl -fsS -m 5 "${HEALTH}" 2>/dev/null | python3 -I -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(1)
if d.get("status") == "UP" and isinstance(d.get("tools"), int): print(d["tools"])
else: sys.exit(1)' || true
}

# ── 1. pré-voo ────────────────────────────────────────────────────────────────────────────────
[ -d "${CODE}" ] || die "worktree de código ausente: ${CODE}"
cd_core="$(git -C "${CORE}" rev-parse --path-format=absolute --git-common-dir)" || die "rev-parse do core falhou"
cd_code="$(git -C "${CODE}" rev-parse --path-format=absolute --git-common-dir)" || die "rev-parse da worktree falhou"
[ "$(realpath "${cd_core}")" = "$(realpath "${cd_code}")" ] \
  || die "${CODE} não é worktree do core (${cd_code} ≠ ${cd_core}) — o SHA do core não existiria lá"
[ -z "$(git -C "${CODE}" status --porcelain)" ] || die "worktree de código SUJA — o servido não é versionado; triagem primeiro"
OLD_SHA="$(git -C "${CODE}" rev-parse HEAD)" || die "rev-parse HEAD da worktree falhou"
OLD_TOOLS="$(health_tools)"
[ -n "${OLD_TOOLS}" ] || { echo "[update-kg-writer] ERRO: /health não está UP ANTES do update — triagem primeiro, update depois." >&2; exit 1; }
log "pré-voo ok — código ${OLD_SHA:0:12} · /health UP com ${OLD_TOOLS} tools"

# ── 2. alvo + NOOP ────────────────────────────────────────────────────────────────────────────
git -C "${CORE}" fetch -q origin || die "fetch do core falhou"
SHA="$(git -C "${CORE}" rev-parse origin/main)" || die "rev-parse origin/main falhou"
if [ "${OLD_SHA}" = "${SHA}" ]; then
  log "NOOP — a worktree já está em origin/main (${SHA:0:12}). Serviço intocado."
  exit 0
fi
EXPECTED="$(git -C "${CORE}" show "${SHA}:${SERVER_REL}" > "/tmp/onion-kgw-server-$$.py" && expected_tools "/tmp/onion-kgw-server-$$.py")" \
  || { rm -f "/tmp/onion-kgw-server-$$.py"; die "não consegui contar as tools do server.py em ${SHA:0:12}"; }
rm -f "/tmp/onion-kgw-server-$$.py"
log "alvo ${SHA:0:12} — o código novo declara ${EXPECTED} tools"

# ── 3. backup da raiz de dados (estado irreversível), artefato NOMEADO ────────────────────────
install -d -m 0700 "${DEST}"
BK="${DEST}/onion-chat-kg-$(date +%Y%m%d-%H%M%S)-pre-${SHA:0:12}.tar.gz"
( umask 077; sudo tar -C "$(dirname "${DATA}")" -czf "${BK}" "$(basename "${DATA}")" ) || die "backup falhou — sem rede de segurança não se atualiza"
sudo chown "$(id -un):$(id -gn)" "${BK}"; chmod 600 "${BK}"
BK_BYTES="$(stat -c %s "${BK}")"
[ "${BK_BYTES}" -gt 0 ] || die "backup VAZIO (${BK})"
sudo tar -tzf "${BK}" >/dev/null || die "backup ilegível (${BK})"
log "backup: ${BK} (${BK_BYTES} bytes, 0600)"

# ── 4. troca do código ────────────────────────────────────────────────────────────────────────
git -C "${CODE}" checkout -q --detach "${SHA}" || die "checkout --detach ${SHA:0:12} falhou"
[ "$(git -C "${CODE}" rev-parse HEAD)" = "${SHA}" ] || die "a worktree não ficou em ${SHA:0:12}"
log "código: ${OLD_SHA:0:12} → ${SHA:0:12}"

# ── 5. restart (o armazém e o leitor do contrato carregam no boot) ────────────────────────────
sudo systemctl restart "${UNIT}" || die "systemctl restart recusou"

# ── 6. conferência por contagem ────────────────────────────────────────────────────────────────
got=""
for _ in $(seq 1 15); do
  got="$(health_tools)"; [ -n "${got}" ] && break
  sleep 2
done
[ -n "${got}" ] || die "/health não voltou em ~30s"
systemctl is-active --quiet "${UNIT}" || die "unidade ${UNIT} não está ativa"
[ "${got}" = "${EXPECTED}" ] || die "/health com ${got} tools; o código ${SHA:0:12} declara ${EXPECTED}"
NR="$(systemctl show "${UNIT}" -p NRestarts --value)"
[ "${NR}" = "0" ] || log "AVISO: NRestarts=${NR} — investigar o journal antes de confiar"
log "OK — código ${SHA:0:12} · /health UP com ${got} tools (esperado ${EXPECTED}) · backup ${BK##*/}"
log "FALTA (não feito aqui, de propósito — exige o token): o probe autenticado, que confere served_commit == store_commit == ${SHA:0:12}; com eles diferentes, o envelope traz aviso_codigo e o serviço precisa de outro restart."
