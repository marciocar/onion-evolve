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
#   6. verificações pós-update FAIL-CLOSED (JWKS, reinícios, verify do degrau 1 e do runner):
#      qualquer uma que reprove ou não meça sai rc 1 nomeando-as, com o serviço deixado
#      RODANDO e o rollback impresso — nunca rollback automático (ver a fase 6).
#
# EXIT: 0 ok, NOOP ou trava ocupada · 1 falha (rollback impresso; na fase 6, update NO AR e não provado)
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
UNIT_DIR=/etc/systemd/system
LOCK=/tmp/onion-update-bridge.lock
HEALTH_LOCAL="http://127.0.0.1:8787/health"
HEALTH_PUBLIC="https://app.onionevolve.com/health"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Duas execuções concorrentes fariam stop/start cruzados sobre o mesmo checkout.
exec 9>"${LOCK}"
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
# O teste TAMBÉM passa por sudo (a MESMA lição escrita no bridge-backup.sh): [ -d ]
# como marcio não atravessa /home/onion (750) e o guard mentia DIR-AUSENTE com o
# node_modules SÃO — matou o deploy do G0 (diagnóstico errado: "npm transiente") e o
# da F2 até a classe ser reconhecida. 14º achado da linha: guard-sem-sudo mente.
NM_ROOT="$( sudo test -d "${BRIDGE}/node_modules" && sudo find "${BRIDGE}/node_modules" -user root -print -quit || echo "DIR-AUSENTE" )"
[ -z "${NM_ROOT}" ] || fail "node_modules contaminado/ausente (${NM_ROOT}) — dono errado quebra o próximo npm como onion"
if sudo test -f "${BRIDGE}/web/package.json"; then
  sudo -u onion -H npm --prefix "${BRIDGE}/web" ci --no-audit --no-fund || fail "npm ci da PWA falhou"
  sudo -u onion -H npm --prefix "${BRIDGE}/web" run build || fail "build da PWA falhou"
fi
# Reinícios automáticos ANTES do start: a fase 6 compara o delta, não o absoluto (a semântica de zerar o
# contador no start manual não foi medida nesta máquina, e o delta não depende dela).
PRE_RESTARTS="$(systemctl show "${UNIT}" -p NRestarts --value 2>/dev/null || true)"
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
# A linha de identidade sai DEPOIS do /health: o self-check do JWKS é assíncrono (medido em 2026-10-15:
# "no ar" 16:35:08.65, "auth: enforce" 16:35:09.29). Uma leitura só, logo após o health, reprovava um
# boot são. Espera ativa pela linha, com teto, como o /health acima.
BOOT=""
for _ in $(seq 1 10); do
  BOOT="$(sudo journalctl "_SYSTEMD_INVOCATION_ID=${INV}" --no-pager 2>/dev/null || true)"
  grep -q "auth: enforce" <<<"${BOOT}" && break
  sleep 2
done
grep -q "auth: enforce" <<<"${BOOT}" || fail "boot DESTA invocação sem 'auth: enforce' — a superfície de auth mudou sem intenção"
# ── 6. verificações pós-update: FAIL-CLOSED, serviço deixado RODANDO ─────────────────────────────────────
# ANTES (achado do refutador no #1172, medido em 2026-10-16): as quatro checagens abaixo só AVISAVAM, e as duas
# de verify nem isso — `VOUT="$(… verify)"; VRC=$?` sob `set -e` matava o script NA ATRIBUIÇÃO, com o rc do
# verify e SEM UMA LINHA de saída (o trap de religamento já tinha saído), e o `case` do AVISO era código morto.
# Um downgrade do SDK abaixo do piso, ou uma unit quebrada, ficava no ar com rc≠0 mudo (sem a linha OK, sem nomear
# o defeito, sem o rollback); e JWKS ausente ou boot que caiu e voltou saíam rc 0 com AVISO.
# A POLÍTICA: o que não se provou neste boot é DEFEITO NOMEADO, nunca aviso. Reprovar ou NÃO MEDIR sai rc 1,
# com cada falha nomeada e o rollback impresso.
# POR QUE NÃO ROLLBACK AUTOMÁTICO (decidido medindo, 2026-10-16), apesar de o script ter os dois HEADs e o
# backup: (1) o rollback refaz o npm ci, que depende de rede — se ele falhar, o serviço fica PARADO, pior que
# o estado em que a fase 6 o encontra (no ar, /health 200, auth enforce); (2) os verifies rodam do checkout do
# OPERADOR (${SELF_DIR}), não do clone servido: o piso do SDK e as cópias do runner são julgados pela versão
# NOVA do core, e o bridge antigo pode reprovar o mesmo verify; (3) a cura de "cópias do runner defasadas" é
# o install do runner, não desfazer o bridge; (4) o rollback não pode ser provado sem o serviço real, e
# deploy é do maestro. Então: para, nomeia, imprime o rollback, e o maestro decide.
NOT_PROVEN=()
grep -q "JWKS OK" <<<"${BOOT}" \
  || NOT_PROVEN+=("JWKS não confirmou neste boot (Logto fora?): com auth enforce, TODO /chat dá 401 até voltar")
NEW_RESTARTS="$(systemctl show "${UNIT}" -p NRestarts --value 2>/dev/null || true)"
if ! [[ "${NEW_RESTARTS}" =~ ^[0-9]+$ && "${PRE_RESTARTS}" =~ ^[0-9]+$ ]]; then
  NOT_PROVEN+=("NRestarts ilegível (antes '${PRE_RESTARTS}', depois '${NEW_RESTARTS}'): não pude medir se o boot novo caiu")
elif [ "${NEW_RESTARTS}" -gt "${PRE_RESTARTS}" ]; then
  NOT_PROVEN+=("o serviço reiniciou sozinho depois do start (NRestarts ${PRE_RESTARTS} → ${NEW_RESTARTS}): investigar o journal antes de confiar")
fi
# post_verify <rótulo> <wrapper em ${SELF_DIR}>: o rc é capturado SEM o set -e matar (o `|| rc=$?`), e as linhas
# de FALHA vão ao stderr. 0 = provado · 1 = reprovou · outro = não mediu (trava, sudo, unit) — os dois últimos
# entram em NOT_PROVEN, porque "não medi" nunca é "está bom".
post_verify() {
  local label="$1" wrapper="$2" out rc=0 n
  out="$(bash "${SELF_DIR}/${wrapper}" verify 2>&1)" || rc=$?
  case "${rc}" in
    0) log "${label}: verify OK no boot desta invocação" ;;
    1) n="$(grep -cE '^ *FALHA' <<<"${out}" || true)"
       NOT_PROVEN+=("${label}: o verify REPROVOU (${n} falha(s); ${wrapper} verify)")
       { grep -E '^ *FALHA' <<<"${out}" || true; } | head -5 | sed 's/^ */    /' >&2 ;;
    *) NOT_PROVEN+=("${label}: o verify NÃO MEDIU (rc ${rc}): $(tail -1 <<<"${out}")") ;;
  esac
}
# O drop-in de INTEGRIDADE (degrau 1 do isolamento do /chat, ops/bridge-hardening.sh) liga cada caminho no boot: um
# caminho que o update removeu ou renomeou sai da proteção em silêncio (o '-' do drop-in evita o 226/NAMESPACE). O
# verify mede no namespace DESTA invocação.
if sudo test -f "${UNIT_DIR}/${UNIT}.service.d/30-integrity.conf"; then
  post_verify "integridade (30-integrity.conf)" bridge-hardening.sh
else
  log "integridade: 30-integrity.conf não instalado — verify do degrau 1 não se aplica"
fi
# O RUNNER do convidado (degrau 2, ops/chat-runner.sh) é instalado A PARTIR do bridge servido: o lançador e as units
# instaladas são cópias de root, e um update que muda deploy/chat-runner/ as deixa defasadas (o verify acusa "DIFERE");
# o verify também prova o contrato do SDK servido contra o lançador instalado (o piso). Reinstalar é
# `! bash ops/chat-runner.sh install --apply`, do maestro.
if sudo test -f "${UNIT_DIR}/onion-chat.socket"; then
  post_verify "runner do convidado (onion-chat.socket)" chat-runner.sh
else
  log "runner: onion-chat.socket não instalado — verify do degrau 2 não se aplica"
fi
if [ "${#NOT_PROVEN[@]}" -gt 0 ]; then
  printf '[update-bridge] ERRO: update NO AR e NÃO PROVADO — %s checagem(ns) pós-update falharam:\n' "${#NOT_PROVEN[@]}" >&2
  for _m in "${NOT_PROVEN[@]}"; do printf '  - %s\n' "${_m}" >&2; done
  printf '[update-bridge] serviço deixado RODANDO de propósito (/health 200 e auth enforce neste boot): parar seria pior. Corrija para a frente ou rode o rollback abaixo.\n' >&2
  print_rollback; exit 1
fi
log "OK — clone ${NEW_CLONE_HEAD:0:8} · bridge ${NEW_BRIDGE_HEAD:0:8} · health 200+ok:true local+público · auth enforce (invocação ${INV:0:8})"
log "prova independente: compare um artefato novo do core no clone (ex.: ls ${CLONE}/.claude/rules/)"
