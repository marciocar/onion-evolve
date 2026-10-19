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
#   1b. NOOP se os DOIS repos estão em origin/main com árvores limpas — serviço intocado, mas as
#       checagens da fase 6 rodam sobre o boot vivo (re-rodar depois de uma cura é verificar)
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
# EXIT: 0 ok, ou NOOP com o boot vivo verificado · 1 falha (rollback impresso; na fase 6, update NO AR e não
#       provado; no NOOP, boot vivo não provado, serviço intocado) · 2 trava ocupada, nada foi feito
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
NOT_PROVEN=()

# Duas execuções concorrentes fariam stop/start cruzados sobre o mesmo checkout.
exec 9>"${LOCK}"
# rc 2, não 0: quem lê o rc concluiria que entregou (a mesma trava é a do install do bridge-hardening e do chat-runner).
flock -n 9 || { echo "[update-bridge] ERRO: outra execução (este wrapper ou um install do bridge-hardening/chat-runner) segura ${LOCK} — NADA foi atualizado." >&2; exit 2; }

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

# ── 6. (definida aqui, chamada no fim do update E no NOOP) ────────────────────────────────────────────────
# post_update_checks <update|noop>: lê BOOT, INV e NEW_CLONE_HEAD do chamador. O NOOP também a roda (as checagens
# só leem): sem isso, o "rode de novo" de uma cura cairia no NOOP e sairia rc 0 sem verificar nada (2ª passada do
# refutador, 2026-10-16).
post_update_checks() {
local mode="$1"
# NOT_PROVEN nasce vazio no topo; o NOOP pode chegar aqui com um item (o boot vivo sem 'auth: enforce').
# O JWKS É MEDIDO UMA VEZ, e isso foi medido (2026-10-16, achado irmão do #1174): o veredito sai do jwksSelfCheck do
# bridge na MESMA linha do "auth: enforce" que a fase 5 espera, então no update não há corrida entre a linha e o
# veredito, e ele tem segundos. O uso real (cada /chat) re-busca sozinho no bridge (kid desconhecido, piso de 60 s):
# re-medir daqui não provaria o uso, só repetiria o boot. Mas no NOOP o boot vivo pode ter DIAS: o "JWKS OK" é um
# instantâneo do boot, não a alcançabilidade de agora, e a linha OK do NOOP não pode dizer mais do que isso.
if grep -q "JWKS OK" <<<"${BOOT}"; then
  if [ "${mode}" = noop ]; then
    log "JWKS: OK no boot vivo, em $(grep -m1 "identidade: JWKS" <<<"${BOOT}" | cut -d' ' -f1) (instantâneo do boot; a alcançabilidade de AGORA não é re-medida aqui — teto Q_JWKS_REFETCH_STORM)"
  fi
else
  NOT_PROVEN+=("JWKS não confirmou neste boot (Logto fora?): com auth enforce, TODO /chat dá 401 até voltar")
fi
# NRestarts ABSOLUTO: o stop e o start manuais ZERAM o contador (medido pelo refutador em 2026-10-16 numa unit de usuário
# com Restart=always no systemd 255: 3 reinícios → stop → 0 → start → 0 → uma queda → 1). Qualquer valor acima de zero
# é queda desde o último start manual (no update, o DESTE boot). (A 1ª redação comparava com o valor de antes do start e
# deixava passar até N quedas novas.)
NEW_RESTARTS="$(systemctl show "${UNIT}" -p NRestarts --value 2>/dev/null || true)"
if ! [[ "${NEW_RESTARTS}" =~ ^[0-9]+$ ]]; then
  NOT_PROVEN+=("NRestarts ilegível ('${NEW_RESTARTS}'): não pude medir se o boot novo caiu")
elif [ "${NEW_RESTARTS}" -gt 0 ]; then
  NOT_PROVEN+=("o serviço reiniciou sozinho depois do start (NRestarts=${NEW_RESTARTS}): investigar o journal antes de confiar")
fi
# post_verify <rótulo> <wrapper em ${SELF_DIR}> <cura>: o rc é capturado SEM o set -e matar (o `|| rc=$?`), e as
# linhas de FALHA vão ao stderr. 0 = provado · 1 = reprovou · outro = não mediu (2 é o "não pude medir" declarado
# pelos dois wrappers — trava, sudo -n, unit, alvo ilegível —; 124 é o teto de 10 min do timeout) — os dois últimos entram em NOT_PROVEN, porque "não medi" nunca é "está bom". Cada entrada leva o
# comando que a cura para a frente.
# O JUIZ É O SERVIDO: o verify roda do checkout do operador, que pode não ser o origin/main (um worktree de feature
# julgaria o piso e as cópias com outro código). Ele só vale se for byte a byte o mesmo arquivo do clone servido,
# que acabou de ser posto em origin/main.
post_verify() {
  local label="$1" wrapper="$2" cure="$3" out rc=0 n
  local crc=0
  sudo cmp -s "${SELF_DIR}/${wrapper}" "${CLONE}/ops/${wrapper}" || crc=$?
  case "${crc}" in
    0) : ;;
    1) NOT_PROVEN+=("${label}: o ${wrapper} deste checkout (${SELF_DIR}) NÃO é o do clone servido em ${NEW_CLONE_HEAD:0:8}: o verify não foi rodado. Cura: 'bash ops/${wrapper} verify' de um checkout em origin/main")
       return 0 ;;
    *) NOT_PROVEN+=("${label}: não pude comparar o ${wrapper} deste checkout com o do clone servido (cmp rc ${crc}: o clone não tem ops/${wrapper}, ou o sudo falhou): o verify não foi rodado")
       return 0 ;;
  esac
  # -k 30: um filho que ignora o TERM leva KILL 30 s depois do teto; </dev/null: sem o terminal, o sudo -n dos
  # wrappers não para por SIGTTOU no grupo de fundo onde o timeout o põe
  out="$(timeout -k 30 600 bash "${SELF_DIR}/${wrapper}" verify </dev/null 2>&1)" || rc=$?
  case "${rc}" in
    0) log "${label}: verify OK no boot desta invocação" ;;
    1) n="$(grep -cE '^ *FALHA' <<<"${out}" || true)"
       if [ "${n}" = 0 ]; then
         NOT_PROVEN+=("${label}: o verify REPROVOU sem linha FALHA (última linha: $(tail -1 <<<"${out}")). Cura: ${cure}")
       else
         NOT_PROVEN+=("${label}: o verify REPROVOU (${n} falha(s); ${wrapper} verify). Cura: ${cure}")
       fi
       { grep -E '^ *FALHA' <<<"${out}" || true; } | head -5 | sed 's/^ */    /' >&2 ;;
    *) NOT_PROVEN+=("${label}: o verify NÃO MEDIU (rc ${rc}): $(tail -1 <<<"${out}")") ;;
  esac
}
# installed_or_unreadable <arquivo>: 0 = instalado; 1 = ausente (o diretório É legível e o arquivo não está lá);
# 2 = não pude ler o diretório (sudo falhou) — este vai a NOT_PROVEN, nunca a "não se aplica".
installed_or_unreadable() {
  sudo test -f "$1" && return 0
  sudo test -d "${UNIT_DIR}" && return 1
  return 2
}
# O drop-in de INTEGRIDADE (degrau 1 do isolamento do /chat, ops/bridge-hardening.sh) liga cada caminho no boot: um
# caminho que o update removeu ou renomeou sai da proteção em silêncio (o '-' do drop-in evita o 226/NAMESPACE). O
# verify mede no namespace DESTA invocação.
# AUSENTE segue "não se aplica" de propósito: o update não remove units, e tirar um degrau é ato do maestro.
local _st=0; installed_or_unreadable "${UNIT_DIR}/${UNIT}.service.d/30-integrity.conf" || _st=$?
case "${_st}" in
  0) post_verify "integridade (30-integrity.conf)" bridge-hardening.sh "o caminho protegido que sumiu volta ao lugar, e então 'bash ops/bridge-hardening.sh install --apply' (do maestro)" ;;
  1) log "integridade: 30-integrity.conf não instalado — verify do degrau 1 não se aplica" ;;
  *) NOT_PROVEN+=("integridade: não pude ler ${UNIT_DIR} (sudo?) para saber se o 30-integrity.conf está instalado") ;;
esac
# O RUNNER do convidado (degrau 2, ops/chat-runner.sh) é instalado A PARTIR do bridge servido: o lançador e as units
# instaladas são cópias de root, e um update que muda deploy/chat-runner/ as deixa defasadas (o verify acusa "DIFERE");
# o verify também prova o contrato do SDK servido contra o lançador instalado (o piso). Reinstalar é
# `! bash ops/chat-runner.sh install --apply`, do maestro.
_st=0; installed_or_unreadable "${UNIT_DIR}/onion-chat.socket" || _st=$?
case "${_st}" in
  0) post_verify "runner do convidado (onion-chat.socket)" chat-runner.sh "'! bash ops/chat-runner.sh install --apply' (do maestro) reinstala as cópias do bridge servido; SDK abaixo do piso se cura no bridge, não aqui" ;;
  1) log "runner: onion-chat.socket não instalado — verify do degrau 2 não se aplica" ;;
  *) NOT_PROVEN+=("runner: não pude ler ${UNIT_DIR} (sudo?) para saber se o onion-chat.socket está instalado") ;;
esac
if [ "${#NOT_PROVEN[@]}" -gt 0 ]; then
  if [ "${mode}" = noop ]; then
    printf '[update-bridge] ERRO: NOOP (nada foi atualizado) e o boot VIVO NÃO está provado — %s checagem(ns) falharam:\n' "${#NOT_PROVEN[@]}" >&2
  else
    printf '[update-bridge] ERRO: update NO AR e NÃO PROVADO — %s checagem(ns) pós-update falharam:\n' "${#NOT_PROVEN[@]}" >&2
  fi
  local _m
  for _m in "${NOT_PROVEN[@]}"; do printf '  - %s\n' "${_m}" >&2; done
  if [ "${mode}" = noop ]; then
    printf '[update-bridge] serviço intocado. Cure pela cura de cada item e rode de novo: o NOOP re-verifica o boot vivo.\n' >&2
    exit 1
  fi
  printf '[update-bridge] serviço deixado RODANDO de propósito (/health 200 e auth enforce no momento da medida, não prova de estabilidade): parar seria pior. Corrija para a frente pela cura de cada item (rodar o update-bridge de novo, já em dia, cai no NOOP e re-verifica), ou rode o rollback abaixo.\n' >&2
  print_rollback; exit 1
fi
}

# ── 1. pré-voo ────────────────────────────────────────────────────────────────────────────
grep -q '"ok":true' <<< "$(curl -fsS -m 5 "${HEALTH_LOCAL}")" \
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
  log "NOOP — clone e bridge já em origin/main (${OLD_CLONE_HEAD:0:8} / ${OLD_BRIDGE_HEAD:0:8}), árvores limpas. Serviço intocado; re-verificando o boot vivo."
  NEW_CLONE_HEAD="${OLD_CLONE_HEAD}"
  INV="$(systemctl show "${UNIT}" -p InvocationID --value)"
  # -o short-iso: cada linha nasce com a sua data, e a do JWKS vai nomeada na linha do NOOP (o boot vivo pode ter dias)
  BOOT="$(sudo journalctl "_SYSTEMD_INVOCATION_ID=${INV}" --no-pager -o short-iso 2>/dev/null || true)"
  grep -q "auth: enforce" <<<"${BOOT}" || NOT_PROVEN+=("o boot vivo (invocação ${INV:0:8}) não tem 'auth: enforce' no journal")
  post_update_checks noop
  log "NOOP OK — boot vivo (invocação ${INV:0:8}) verificado, nada a atualizar."
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
sudo systemctl start "${UNIT}" || fail "systemctl start recusou"
DEPS_TOUCHED=0

# ── 5. verificação por contagem, NO BOOT DESTA INVOCAÇÃO ──────────────────────────────────
# Espera ativa (não sleep fixo): o boot já mediu 1s e 3s em invocações reais — margem zero.
up=0
for _ in $(seq 1 15); do
  if grep -q '"ok":true' <<< "$(curl -fsS -m 3 "${HEALTH_LOCAL}" 2>/dev/null)"; then up=1; break; fi
  sleep 2
done
[ "${up}" = 1 ] || fail "/health local não voltou em ~30s"
grep -q '"ok":true' <<< "$(curl -fsS -m 10 "${HEALTH_PUBLIC}")" || fail "/health via Caddy não voltou"
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
# o estado em que a fase 6 o encontra (no ar, /health 200, auth enforce); (2) o verify é o do core NOVO (o
# post_verify exige que o do checkout do operador seja byte a byte o do clone servido): o piso do SDK e as cópias
# do runner são julgados pela versão nova, e o bridge antigo pode reprovar o mesmo verify; (3) a cura de "cópias do runner defasadas" é
# o install do runner, não desfazer o bridge; (4) o rollback não pode ser provado sem o serviço real, e
# deploy é do maestro. Então: para, nomeia, imprime o rollback, e o maestro decide.
post_update_checks update
log "OK — clone ${NEW_CLONE_HEAD:0:8} · bridge ${NEW_BRIDGE_HEAD:0:8} · health 200+ok:true local+público · auth enforce (invocação ${INV:0:8})"
log "prova independente: compare um artefato novo do core no clone (ex.: ls ${CLONE}/.claude/rules/)"
