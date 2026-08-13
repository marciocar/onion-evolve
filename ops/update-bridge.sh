#!/usr/bin/env bash
# Update do onion-bridge — o ciclo repetível, com verificação por CONTAGEM e rollback impresso.
#
# POR QUE EXISTE (Elenxo do update 2026-08-13): não havia processo — as rodadas anteriores
# (SDK 0.3.195→0.3.220 em 08-02, fix de workspace em 08-11) foram à mão via .bash_history,
# e o clone do core que o bridge SERVE chegou a 108 commits/13 dias de atraso sem ninguém
# notar. Update manual sem baseline é o padrão que já produziu "verde" sem prova nas
# outras pontas da casa (exit-code-não-é-a-verificação).
#
# v2 PÓS-7º ELENXO (19 achados; a lei da linha de novo — o script que existe para matar
# "update sem verificação" tinha a prova central satisfeita por um boot de 3 dias atrás,
# e a "higiene de rollback" destruía o não-versionado que dizia salvar). As curas moram
# nos comentários de cada fase.
#
# O QUE ELE FAZ (nesta ordem; falha imprime o rollback com os hashes do pré-voo e sai —
# nunca executa rollback às cegas):
#   1. probe /health + baseline (HEADs, invocação) — não se atualiza serviço já doente
#   1b. NOOP se os DOIS repos estão em origin/main com árvores limpas — serviço intocado
#   2. backup rotulado do estado irreversível (data/ + .env), com o artefato NOMEADO
#   3. serviço PARADO (a árvore servida não se reescreve sob leitor vivo) → resíduo do
#      clone vai para STASH (rastreado E não-rastreado — nada em claro fora do repo,
#      nada de root na home do maestro) → reset do clone
#   4. pull --ff-only do bridge → trap-de-religamento SÓ até aqui (npm ci apaga o
#      node_modules onde o ExecStart vive: religar depois = 203/EXEC em loop de 5s, o
#      modo de falha de 08-10) → npm ci + rebuild da PWA → start
#   5. verificação por CONTAGEM, no boot DESTA invocação (InvocationID — as últimas N
#      linhas do journal atravessam invocações e provariam o update com o boot antigo)
#
# O QUE ELE NÃO FAZ (one-off da rodada 2026-08-13): editar .env, mexer na unit/drop-in
# (precedente 08-10: ProtectHome derrubou o serviço), varrer .bak, trocar lockfile.
# TETO DECLARADO: /health é código HTTP + corpo com ok:true — durante queda do IdP ele
# segue 200 com todo /chat em 401 (fio Q_JWKS_REFETCH_STORM no grafo m2-bridge-logto).
#
# Uso: ops/update-bridge.sh   (chama sudo onde precisa; concorrência barrada por flock)
set -euo pipefail

BRIDGE=/home/onion/onion-bridge
CLONE=/home/onion/onion-evolve
UNIT=onion-vps-bridge
DEST=/home/marcio/backups/bridge
HEALTH_LOCAL="http://127.0.0.1:8787/health"
HEALTH_PUBLIC="https://app.onionevolve.com/health"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Duas execuções concorrentes fariam stop/start cruzados sobre o mesmo checkout.
exec 9>"/tmp/onion-update-bridge.lock"
flock -n 9 || { echo "[update-bridge] outra execução em andamento — saindo." >&2; exit 0; }

log() { printf '[update-bridge] %s\n' "$*"; }
# DEPS_TOUCHED: depois que o npm ci começa, falhar DEIXA PARADO de propósito — o
# ExecStart vive dentro de node_modules e religar sobre metade é crashloop 203/EXEC.
DEPS_TOUCHED=0
fail() {
  printf '[update-bridge] ERRO: %s\n' "$*" >&2
  [ "${DEPS_TOUCHED}" = 1 ] && \
    printf '[update-bridge] serviço DEIXADO PARADO de propósito — node_modules pode estar pela metade e o ExecStart vive lá dentro.\n' >&2
  print_rollback; exit 1
}

OLD_CLONE_HEAD=""; OLD_BRIDGE_HEAD=""
print_rollback() {
  cat >&2 <<EOF
[update-bridge] ─── ROLLBACK MANUAL (hashes capturados no pré-voo) ───
  sudo systemctl stop ${UNIT}
  sudo -u onion git -C ${CLONE} reset --hard ${OLD_CLONE_HEAD:-<clone-head>}
  sudo -u onion git -C ${BRIDGE} reset --hard ${OLD_BRIDGE_HEAD:-<bridge-head>}
  sudo -u onion -H npm --prefix ${BRIDGE} ci --no-audit --no-fund
  sudo -u onion -H npm --prefix ${BRIDGE}/web ci --no-audit --no-fund && \\
    sudo -u onion -H npm --prefix ${BRIDGE}/web run build
  sudo systemctl reset-failed ${UNIT}   # crashloop consome StartLimitBurst; sem isto o start pode ser recusado
  sudo systemctl start ${UNIT}
  curl -fsS ${HEALTH_LOCAL}
  # estado (data/ + .env): restaurável do backup rotulado em ${DEST}
  # resíduo do clone (se houve): sudo -u onion git -C ${CLONE} stash list
EOF
}

# ── 1. pré-voo ────────────────────────────────────────────────────────────────────────────
curl -fsS -m 5 "${HEALTH_LOCAL}" | grep -q '"ok":true' \
  || { echo "[update-bridge] ERRO: /health já está doente ANTES do update — triagem primeiro, update depois." >&2; exit 1; }
OLD_CLONE_HEAD="$(sudo -u onion git -C "${CLONE}" rev-parse HEAD)"   || fail "rev-parse do clone falhou"
OLD_BRIDGE_HEAD="$(sudo -u onion git -C "${BRIDGE}" rev-parse HEAD)" || fail "rev-parse do bridge falhou"
log "pré-voo ok — clone ${OLD_CLONE_HEAD:0:8} · bridge ${OLD_BRIDGE_HEAD:0:8}"

# ── 1b. NOOP — os DOIS repos em dia e limpos? Então NÃO se toca no serviço ────────────────
sudo -u onion git -C "${CLONE}" fetch --quiet origin  || fail "fetch do clone falhou"
sudo -u onion git -C "${BRIDGE}" fetch --quiet origin || fail "fetch do bridge falhou"
CLONE_REMOTE="$(sudo -u onion git -C "${CLONE}" rev-parse origin/main)"
BRIDGE_REMOTE="$(sudo -u onion git -C "${BRIDGE}" rev-parse origin/main)"
if [ "${OLD_CLONE_HEAD}" = "${CLONE_REMOTE}" ] && [ "${OLD_BRIDGE_HEAD}" = "${BRIDGE_REMOTE}" ] \
   && [ -z "$(sudo -u onion git -C "${CLONE}" status --porcelain)" ] \
   && [ -z "$(sudo -u onion git -C "${BRIDGE}" status --porcelain)" ]; then
  log "NOOP — clone e bridge já em origin/main (${OLD_CLONE_HEAD:0:8} / ${OLD_BRIDGE_HEAD:0:8}), árvores limpas. Serviço intocado."
  exit 0
fi

# ── 2. backup rotulado (estado irreversível), artefato NOMEADO ────────────────────────────
BK_OUT="$(sudo "${SELF_DIR}/bridge-backup.sh" "pre-update")" || fail "backup falhou — sem rede de segurança não se atualiza"
log "backup: $(tail -1 <<<"${BK_OUT}")"

# ── 3. STOP antes de tocar a árvore SERVIDA (workspaces symlinkam .claude/ e docs/ do
#       clone; o /a2a spawna o gate do core — reescrever sob leitor vivo é corrida) ───────
sudo systemctl stop "${UNIT}"
trap 'sudo systemctl start '"${UNIT}"' || echo "[update-bridge] ATENÇÃO: religamento automático FALHOU — serviço PARADO" >&2' EXIT
if [ -n "$(sudo -u onion git -C "${CLONE}" status --porcelain)" ]; then
  # STASH, não diff-para-arquivo: git diff não carrega o CONTEÚDO de untracked (só o nome),
  # e o clean -fd apagaria o resto; e arquivo em claro em ${DEST} é BACKUP-EM-CLARO (HARD
  # no vps-exposure-check) nascendo root na home do maestro. O stash guarda rastreado E
  # não-rastreado, dentro do repo, como onion.
  sudo -u onion git -C "${CLONE}" stash push --include-untracked -q -m "pre-update-$(date +%F-%H%M%S)" \
    || fail "stash do resíduo falhou"
  log "resíduo do clone (rastreado E não-rastreado) guardado no stash — 'git stash list' no clone recupera"
fi
sudo -u onion git -C "${CLONE}" reset --hard --quiet origin/main
sudo -u onion git -C "${CLONE}" clean -fdq   # SEM -x, jamais: -x arrastaria ignorados
NEW_CLONE_HEAD="$(sudo -u onion git -C "${CLONE}" rev-parse HEAD)" || fail "rev-parse pós-reset falhou"
[ -z "$(sudo -u onion git -C "${CLONE}" status --porcelain)" ] || fail "clone não ficou limpo após reset"
log "clone do core: ${OLD_CLONE_HEAD:0:8} → ${NEW_CLONE_HEAD:0:8}"

# ── 4. bridge: pull → (trap sai ANTES do npm ci) → deps → PWA → start ─────────────────────
sudo -u onion git -C "${BRIDGE}" pull --ff-only --quiet origin main \
  || fail "pull --ff-only recusou (histórico divergiu?) — resolva no repo, não aqui"
NEW_BRIDGE_HEAD="$(sudo -u onion git -C "${BRIDGE}" rev-parse HEAD)" || fail "rev-parse do bridge falhou"
# Daqui em diante o trap NÃO religa: npm ci apaga o node_modules onde o ExecStart mora.
trap - EXIT; DEPS_TOUCHED=1
# --no-audit --no-fund, NUNCA --silent: medido, --silent engole o erro INTEIRO (0 chars);
# e a linha "added N packages" é contagem que o método deste script exige.
sudo -u onion -H npm --prefix "${BRIDGE}" ci --no-audit --no-fund || fail "npm ci do backend falhou"
# (-H é seguro barato; nesta máquina o sudoers já reseta HOME — medido idêntico sem ele)
NM_ROOT="$( [ -d "${BRIDGE}/node_modules" ] && sudo find "${BRIDGE}/node_modules" -user root -print -quit || echo "DIR-AUSENTE" )"
[ -z "${NM_ROOT}" ] || fail "node_modules contaminado/ausente (${NM_ROOT}) — dono errado quebra o próximo npm como onion"
if [ -f "${BRIDGE}/web/package.json" ]; then
  sudo -u onion -H npm --prefix "${BRIDGE}/web" ci --no-audit --no-fund || fail "npm ci da PWA falhou"
  sudo -u onion -H npm --prefix "${BRIDGE}/web" run build || fail "build da PWA falhou"
fi
sudo systemctl start "${UNIT}" || fail "systemctl start recusou"
DEPS_TOUCHED=0

# ── 5. verificação por contagem, NO BOOT DESTA INVOCAÇÃO ──────────────────────────────────
# Espera ativa (não sleep fixo): o boot já mediu 1s e 3s em invocações reais — margem zero.
up=0
for _ in $(seq 1 15); do
  if curl -fsS -m 3 "${HEALTH_LOCAL}" 2>/dev/null | grep -q '"ok":true'; then up=1; break; fi
  sleep 2
done
[ "${up}" = 1 ] || fail "/health local não voltou em ~30s"
curl -fsS -m 10 "${HEALTH_PUBLIC}" | grep -q '"ok":true' || fail "/health via Caddy não voltou"
[ "${NEW_BRIDGE_HEAD}" = "${BRIDGE_REMOTE}" ] || fail "bridge não ficou em origin/main"
[ "${NEW_CLONE_HEAD}"  = "${CLONE_REMOTE}"  ] || fail "clone não ficou em origin/main"
INV="$(systemctl show "${UNIT}" -p InvocationID --value)"
BOOT="$(sudo journalctl "_SYSTEMD_INVOCATION_ID=${INV}" --no-pager 2>/dev/null || true)"
grep -q "auth: enforce" <<<"${BOOT}" || fail "boot DESTA invocação sem 'auth: enforce' — a superfície de auth mudou sem intenção"
grep -q "JWKS OK"       <<<"${BOOT}" || log "AVISO: JWKS não confirmou neste boot (Logto fora?) — TUDO dará 401 até voltar"
NEW_RESTARTS="$(systemctl show "${UNIT}" -p NRestarts --value)"
[ "${NEW_RESTARTS}" = "0" ] || log "AVISO: NRestarts=${NEW_RESTARTS} — investigar journal antes de confiar"
log "OK — clone ${NEW_CLONE_HEAD:0:8} · bridge ${NEW_BRIDGE_HEAD:0:8} · health 200+ok:true local+público · auth enforce (invocação ${INV:0:8})"
log "prova independente: compare um artefato novo do core no clone (ex.: ls ${CLONE}/.claude/rules/)"
