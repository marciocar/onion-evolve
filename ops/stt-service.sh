#!/usr/bin/env bash
# stt-service.sh — o serviço de STT em LOTE do core na VPS: a unit onion-vps-stt (core-only).
#
# POR QUE EXISTE (2026-10-17, decisões do maestro D_MC_CAPTURA_WINDOWS_LOTE_VPS_1017 e
# D_MC_STT_PARAKEET_ADAPTADOR_CORE_1017, grafo docs/evolution/research/meeting-capture-2026-10/): a reunião é capturada
# no Windows e transcrita em LOTE na VPS pelo NVIDIA Parakeet TDT 0.6b v3 int8; o adaptador da curadoria foi
# reescrito no core (ops/stt/) e é operado aqui como serviço — só em 127.0.0.1, token por credencial do systemd,
# sandbox fechado, sem rede de saída, com o modelo baixado na INSTALAÇÃO (revisão fixada, sha256 conferido) e nunca
# em runtime. O TLS e o domínio são do proxy da casa, por decisão do maestro AINDA PENDENTE: este wrapper não toca o
# proxy. Molde: ops/bridge-hardening.sh e ops/chat-runner.sh (trava, recusa root, ensaio por padrão, backup, rollback
# impresso, prova depois).
#
# USO
#   ops/stt-service.sh install [--apply]   ensaio (padrão) ou instalação do onion-vps-stt
#   ops/stt-service.sh verify              prova o serviço VIVO (só leitura, sem trava)
#   ops/stt-service.sh show                imprime a unit que seria instalada (nada é medido)
#
#   install sem --apply é ENSAIO: confere as premissas da máquina (python 3.12, ensurepip, ffmpeg, systemd, disco, a
#   porta), confere os pins contra as FONTES OFICIAIS (cada hash do ops/stt/requirements.lock existe no PyPI para
#   aquela versão; cada arquivo do modelo e do VAD tem, na revisão fixada do Hugging Face, o sha256 e o tamanho
#   fixados aqui), renderiza a unit e mostra a diferença para a instalada. Se a área de instalação já estiver montada
#   (um --apply anterior), roda também a prova completa numa unit TRANSITÓRIA com o sandbox da unit renderizada. Nada
#   persistente é escrito.
#   verify é só leitura: a unit ativa e gerada por este wrapper, os limites efetivos (memória, rede, sandbox), a porta
#   escutando SÓ em loopback, o /health servindo o código do repositório e, numa unit transitória com o token por
#   LoadCredential= (o operador nunca o segura): 401 sem token, com token errado e com esquema estranho, e o fixture
#   pt-BR transcrito pelas duas rotas com palavras e tempos.
#
# O QUE O install --apply FAZ: trava → pré-voo → montagem ADITIVA e endereçada por conteúdo em /opt/onion-stt
# (models/<repo>@<rev12>, venv-<hash do lock>, code-<hash do código>; diretório que já existe com o marcador de
# completo é reusado, sem marcador é refeito) → o token em /etc/onion-stt/token se ainda não existir (gerado DENTRO do
# root, 0600, nunca impresso nem em argv) → a prova completa numa unit TRANSITÓRIA com o sandbox novo (falhou: a unit
# de produção nem foi tocada) → backup da unit anterior → instala, daemon-reload, enable, restart → /health e verify.
# Falha depois da troca imprime o rollback; nunca o executa.
#
# EXIT: 0 ok · 1 problema medido ou recusado · 2 não pude medir (trava, sudo, rede, unit) · 3 uso inválido
#
# MODO DE TESTE (bancada): ONION_STT_SERVICE_TEST=1 com ONION_STT_SERVICE_ROOT, ONION_STT_SERVICE_ETC,
#   ONION_STT_SERVICE_UNIT_DIR, ONION_STT_SERVICE_BACKUP_DIR e ONION_STT_SERVICE_LOCK. Nele nada passa por sudo:
#   systemctl, systemd-run, ss, curl e df vêm do PATH (a bancada põe falsos), e nenhum caminho pode cair em /opt,
#   /etc ou /var/backups reais. Qualquer ONION_STT_SERVICE_* sem o modo de teste é uso inválido (rc 3).
set -uo pipefail

UNIT=onion-vps-stt
PORT=8765
PROD_ROOT=/opt/onion-stt
PROD_ETC=/etc/onion-stt
PROD_UNIT_DIR=/etc/systemd/system
PROD_BACKUP_DIR=/var/backups/onion-stt
PROD_LOCK="/run/user/$(id -u)/onion-stt-service.lock"   # do operador: num /tmp comum outra conta seguraria o flock
MARKER="# onion-stt-service: v1"
COMPLETE=.onion-stt-complete
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SELF_DIR}/stt"
NAME=stt-service

# ── pins (conferidos em 2026-10-17 contra as fontes oficiais; o ensaio os reconfere a cada rodada) ─────────────
# Modelo: NVIDIA Parakeet TDT 0.6b v3, exportação ONNX int8 (CC-BY-4.0). Arquivo grande: sha256 do LFS; pequeno: sha1
# do blob git (o que o Hugging Face publica para arquivo fora do LFS).
MODEL_REPO=istupakov/parakeet-tdt-0.6b-v3-onnx
MODEL_REV=8f23f0c03c8761650bdb5b40aaf3e40d2c15f1ce
MODEL_FILES=(
  "encoder-model.int8.onnx sha256 6139d2fa7e1b086097b277c7149725edbab89cc7c7ae64b23c741be4055aff09 652183999"
  "decoder_joint-model.int8.onnx sha256 eea7483ee3d1a30375daedc8ed83e3960c91b098812127a0d99d1c8977667a70 18202004"
  "config.json gitsha1 02a773005666393de591dfd55230b778da1653d8 97"
  "vocab.txt gitsha1 fc43e1c723e262df60b70e1919614417162d1fe2 93939"
)
VAD_REPO=istupakov/silero-vad-onnx
VAD_REV=b3e3ee3cce4c11ceb63b1a0b229d916069c1ddf6
VAD_FILES=(
  "silero_vad.onnx sha256 1a153a22f4509e292a94e67d6f9b85e8deb25b4988682b7e174c65279d8788e3 2327524"
  "config.json gitsha1 b7ef67b9ec211c85993c5f6649bdeeac4b445d1e 30"
)
CODE_FILES=( server.py stt_core.py smoke.py fixtures/fleurs-ptbr-8821974356183732066.flac fixtures/fleurs-ptbr-8821974356183732066.json )
FIXTURE=fixtures/fleurs-ptbr-8821974356183732066.flac

# ── a configuração MEDIDA (grafo meeting-capture-2026-10, E_MC_STT_SERVICO_CORE_MEDIDO_1017) ────────────────────
INTRA_OP=4          # sonda de threads da curadoria: intra 4 / 1 worker é o mais estável nesta VM de 8 vCPU
WORKERS=1
QUEUE_MAX=2
VAD_BATCH=1         # trechos do VAD por inferência; 8 era o padrão do onnx-asr
MAX_BODY_MB=384
MAX_AUDIO_S=10800   # teto da duração DECODIFICADA por canal (3 h): 4 MB de FLAC de silêncio eram 6 h e +2,7 GB (refutador)
MEMORY_MAX=6G       # teto do cgroup; sem swap (MemorySwapMax=0): estourou, o kernel mata e o systemd reinicia
MEMORY_MAX_BYTES=6442450944
MIN_FREE_KB=$(( 3 * 1024 * 1024 ))   # disco livre exigido para montar (~0,7 GB de modelo + ~0,2 GB de venv, com folga)

say()  { printf '[%s] %s\n' "${NAME}" "$*"; }
die()  { local rc="$1"; shift; printf '[%s] ERRO: %s\n' "${NAME}" "$*" >&2; exit "${rc}"; }
usage() { sed -n '/^# USO/,/^# O QUE O install/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 3; }

case "${1:-}" in -h|--help) sed -n '/^# USO/,/^# MODO DE TESTE/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 0 ;; '') usage ;; esac

# ── modo: produção ou teste declarado ──────────────────────────────────────────────────────────────────
TEST=0
if [ "${ONION_STT_SERVICE_TEST:-}" = 1 ]; then
  TEST=1
  ROOT="${ONION_STT_SERVICE_ROOT:?modo de teste exige ONION_STT_SERVICE_ROOT}"
  ETC="${ONION_STT_SERVICE_ETC:?modo de teste exige ONION_STT_SERVICE_ETC}"
  UNIT_DIR="${ONION_STT_SERVICE_UNIT_DIR:?modo de teste exige ONION_STT_SERVICE_UNIT_DIR}"
  BACKUP_DIR="${ONION_STT_SERVICE_BACKUP_DIR:?modo de teste exige ONION_STT_SERVICE_BACKUP_DIR}"
  LOCK="${ONION_STT_SERVICE_LOCK:?modo de teste exige ONION_STT_SERVICE_LOCK}"
  for _p in "${ROOT}" "${ETC}" "${UNIT_DIR}" "${BACKUP_DIR}"; do
    _r="$(realpath -m -- "${_p}")"
    case "${_r}/" in "${PROD_ROOT}/"*|"${PROD_ETC}/"*|/etc/systemd/*|/var/backups/*) die 3 "modo de teste com caminho de produção: recusado (${_r})" ;; esac
  done
else
  [ -n "${ONION_STT_SERVICE_TEST:-}" ] && die 3 "ONION_STT_SERVICE_TEST só aceita 1"
  if compgen -e | grep -E '^ONION_STT_SERVICE_' >/dev/null; then
    die 3 "variável ONION_STT_SERVICE_* sem ONION_STT_SERVICE_TEST=1: produção não se redireciona por ambiente"
  fi
  ROOT="${PROD_ROOT}"; ETC="${PROD_ETC}"; UNIT_DIR="${PROD_UNIT_DIR}"; BACKUP_DIR="${PROD_BACKUP_DIR}"; LOCK="${PROD_LOCK}"
  # o wrapper instala como root o que ele mesmo renderiza e copia: tem de ser o RASTREADO e limpo de um checkout
  for _f in "${SELF_DIR}/$(basename "${BASH_SOURCE[0]}")" "${SRC}/requirements.lock" "${SRC}/pip.lock" "${CODE_FILES[@]/#/${SRC}/}"; do
    git -C "${SELF_DIR}" ls-files --error-unmatch -- "${_f}" >/dev/null 2>&1 \
      || die 3 "${_f} não é arquivo rastreado de um checkout: rode o wrapper do repositório, não uma cópia"
    git -C "${SELF_DIR}" diff --quiet HEAD -- "${_f}" 2>/dev/null \
      || die 3 "${_f} tem mudança não commitada: rode o wrapper como está no commit"
  done
fi

[ "$(id -u)" -eq 0 ] && die 3 "rodando como root: rode como o operador (o wrapper chama sudo onde precisa)"

priv() { if [ "${TEST}" = 1 ]; then "$@"; else sudo -n "$@"; fi; }

# ── argumentos: lista FECHADA ─────────────────────────────────────────────────────────────────────────
SUB="$1"; shift
APPLY=0
case "${SUB}" in install|verify|show) : ;; *) usage ;; esac
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) [ "${SUB}" = install ] || die 3 "--apply só no install"; APPLY=1; shift ;;
    *) die 3 "opção não aceita: $1 (a porta, os pins, os caminhos e os limites são fixos)" ;;
  esac
done

for _f in requirements.lock pip.lock "${CODE_FILES[@]}"; do
  [ -f "${SRC}/${_f}" ] || die 2 "fonte ausente: ${SRC}/${_f}"
done

# ── endereços derivados do conteúdo ─────────────────────────────────────────────────────────────────
h12() { sha256sum | cut -c1-12; }
CODE_ID="$(for f in "${CODE_FILES[@]}"; do printf '%s %s\n' "${f}" "$(sha256sum < "${SRC}/${f}" | cut -d' ' -f1)"; done | h12)"
LOCK_ID="$( { cat "${SRC}/pip.lock" "${SRC}/requirements.lock"; python3 -c 'import sys; print(sys.version.split()[0])'; } | h12)"
MODEL_DIR="${ROOT}/models/parakeet-tdt-0.6b-v3-int8@${MODEL_REV:0:12}"
VAD_DIR="${ROOT}/models/silero-vad@${VAD_REV:0:12}"
VENV_DIR="${ROOT}/venv-${LOCK_ID}"
CODE_DIR="${ROOT}/code-${CODE_ID}"
TOKEN_FILE="${ETC}/token"
UNIT_FILE="${UNIT_DIR}/${UNIT}.service"
SERVER_SHA="$(sha256sum < "${SRC}/server.py" | cut -d' ' -f1)"
CORE_SHA="$(sha256sum < "${SRC}/stt_core.py" | cut -d' ' -f1)"
SERVER_ARGS=( --host 127.0.0.1 --model-dir "${MODEL_DIR}" --vad-dir "${VAD_DIR}" --intra-op "${INTRA_OP}" --workers "${WORKERS}"
              --queue-max "${QUEUE_MAX}" --vad-batch "${VAD_BATCH}" --max-body-mb "${MAX_BODY_MB}" --max-audio-s "${MAX_AUDIO_S}" )

# as propriedades do sandbox: a MESMA lista vai para a unit e para a transitória do ensaio (o que se prova é o que roda)
SANDBOX=(
  "DynamicUser=yes" "LoadCredential=token:${TOKEN_FILE}" "WorkingDirectory=/"
  "Environment=HF_HUB_OFFLINE=1 OMP_NUM_THREADS=${INTRA_OP} PYTHONDONTWRITEBYTECODE=1"
  "MemoryMax=${MEMORY_MAX}" "MemorySwapMax=0" "TasksMax=64" "LimitNOFILE=1024" "UMask=0077"
  "NoNewPrivileges=yes" "ProtectSystem=strict" "ProtectHome=yes" "PrivateTmp=yes" "PrivateDevices=yes"
  "ProtectKernelTunables=yes" "ProtectKernelModules=yes" "ProtectKernelLogs=yes" "ProtectControlGroups=yes"
  "ProtectClock=yes" "ProtectHostname=yes" "ProtectProc=invisible" "RestrictNamespaces=yes" "RestrictRealtime=yes"
  "RestrictSUIDSGID=yes" "LockPersonality=yes" "SystemCallArchitectures=native" "SystemCallFilter=@system-service"
  "SystemCallErrorNumber=EPERM" "CapabilityBoundingSet=" "AmbientCapabilities="
  "RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX" "IPAddressDeny=any" "IPAddressAllow=localhost"
)

render_unit() {
  local p
  cat <<EOF
# ${UNIT_FILE}
${MARKER}
# GERADO por ops/stt-service.sh (core-only). Não edite à mão: rode o wrapper (install, depois verify).
# STT em LOTE do core (Parakeet TDT 0.6b v3 int8 pelo onnx-asr): só 127.0.0.1:${PORT}, token por LoadCredential=,
# sem rede de saída, modelo local (revisão ${MODEL_REV:0:12}), código ${CODE_ID}, ambiente ${LOCK_ID}.
# REVERSÃO: sudo systemctl disable --now ${UNIT} && sudo rm ${UNIT_FILE} && sudo systemctl daemon-reload
[Unit]
Description=onion-vps-stt — STT em lote (Parakeet TDT 0.6b v3 int8), só em 127.0.0.1:${PORT}
After=network.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=exec
ExecStart=${VENV_DIR}/bin/python -I -B ${CODE_DIR}/server.py ${SERVER_ARGS[*]} --port ${PORT}
Restart=on-failure
RestartSec=10
TimeoutStartSec=120
EOF
  for p in "${SANDBOX[@]}"; do printf '%s\n' "${p}"; done
  printf '\n[Install]\nWantedBy=multi-user.target\n'
}

# ── trava (só no install: verify e show só leem) ─────────────────────────────────────────────────────
if [ "${SUB}" = install ]; then
  exec 9>"${LOCK}" || die 2 "não abri a trava ${LOCK}"
  flock -n 9 || die 2 "outra execução deste wrapper segura ${LOCK}; tente de novo"
fi

TMPD="$(mktemp -d)"; trap 'rm -rf -- "${TMPD}"' EXIT
render_unit > "${TMPD}/${UNIT}.service"
if [ "${SUB}" = show ]; then cat "${TMPD}/${UNIT}.service"; exit 0; fi

# ── a prova numa unit TRANSITÓRIA (o ensaio e o --apply) ──────────────────────────────────────────────
# transient_smoke <rótulo> <args do smoke.py…>: roda o smoke.py dentro de uma unit transitória com o SANDBOX da unit
# renderizada; devolve 0 (n_fail=0), 1 (FALHA medida) ou 2 (não rodou até o fim: sem a linha n_fail=).
transient_smoke() {
  local label="$1"; shift
  local props=() p out rc
  for p in "${SANDBOX[@]}"; do props+=(-p "${p}"); done
  out="$(priv systemd-run --quiet --pipe --wait --collect "${props[@]}" "${VENV_DIR}/bin/python" -I -B "${CODE_DIR}/smoke.py" \
         --fixture "${CODE_DIR}/${FIXTURE}" "$@" 2>&1)"; rc=$?
  printf '%s\n' "${out}" | sed 's/^/    /'
  if ! grep -qE '^n_fail=[0-9]+$' <<<"${out}"; then
    grep -q '^FALHA ' <<<"${out}" && { say "${label}: a prova morreu antes do fim (rc ${rc}), mas já tinha medido FALHA"; return 1; }
    say "${label}: NÃO MEDI — a prova não rodou até o fim (rc ${rc}; sudo, systemd-run ou o python da área)"; return 2
  fi
  [ "${rc}" = 0 ] && grep -qx 'n_fail=0' <<<"${out}" && return 0
  return 1
}

# ── verify: o serviço VIVO ───────────────────────────────────────────────────────────────────────────
verify_live() {
  local show st pid frag mem cur ipd ipa dpi ldr addrs a h hsha vrc nok
  show="$(systemctl show "${UNIT}" -p ActiveState -p MainPID -p FragmentPath -p DropInPaths -p MemoryMax -p MemorySwapMax \
          -p MemoryCurrent -p IPAddressDeny -p IPAddressAllow -p DynamicUser -p ProtectHome -p NRestarts -p NeedDaemonReload 2>/dev/null)" \
    || { say "NÃO MEDI: systemctl show ${UNIT} falhou"; return 2; }
  st="$(sed -n 's/^ActiveState=//p' <<<"${show}")"; pid="$(sed -n 's/^MainPID=//p' <<<"${show}")"
  frag="$(sed -n 's/^FragmentPath=//p' <<<"${show}")"; mem="$(sed -n 's/^MemoryMax=//p' <<<"${show}")"
  cur="$(sed -n 's/^MemoryCurrent=//p' <<<"${show}")"; ipd="$(sed -n 's/^IPAddressDeny=//p' <<<"${show}")"
  [ "${st}" = active ] && [[ "${pid}" =~ ^[1-9][0-9]*$ ]] || { say "a unit ${UNIT} não está ativa (ActiveState=${st:-?}, MainPID=${pid:-?})"; return 1; }
  [ "${frag}" = "${UNIT_FILE}" ] || { say "a unit carregada vem de ${frag:-?}, não de ${UNIT_FILE}"; return 1; }
  # o arquivo pode ser o renderizado e a config VIVA outra (editaram, recarregaram, devolveram sem reload)
  [ "$(sed -n 's/^NeedDaemonReload=//p' <<<"${show}")" = no ] || { say "a unit em disco difere da carregada (NeedDaemonReload≠no): rode install"; return 1; }
  # um drop-in (onion-vps-stt.service.d/*.conf) mudaria a unit sem passar pela comparação abaixo (IPAddressAllow=any
  # abriria a saída e o cmp do FragmentPath seguiria igual): a unit deste serviço não tem drop-in, nenhum
  dpi="$(sed -n 's/^DropInPaths=//p' <<<"${show}")"
  [ -z "${dpi}" ] || { say "a unit tem drop-in(s) que este wrapper não gera: ${dpi}"; return 1; }
  priv grep -qxF "${MARKER}" "${UNIT_FILE}" 2>/dev/null || { say "${UNIT_FILE} não foi gerada por este wrapper (sem o marcador)"; return 1; }
  if priv cmp -s "${UNIT_FILE}" "${TMPD}/${UNIT}.service"; then say "OK a unit instalada é a renderizada deste commit"
  else say "a unit instalada DIFERE da renderizada deste commit (rode install para ver a diferença)"; return 1; fi
  [ "${mem}" = "${MEMORY_MAX_BYTES}" ] || { say "MemoryMax efetivo ${mem:-?} != ${MEMORY_MAX_BYTES}"; return 1; }
  [ "$(sed -n 's/^MemorySwapMax=//p' <<<"${show}")" = 0 ] || { say "MemorySwapMax efetivo diferente de 0"; return 1; }
  say "OK MemoryMax=${mem} (em uso agora: ${cur:-?} B)"
  # `any` é mostrado como as DUAS faixas: só uma delas deixaria a outra família aberta (refutador, passada 2)
  { grep -qE '(^| )any( |$)' <<<"${ipd}" || { grep -qE '(^| )0\.0\.0\.0/0( |$)' <<<"${ipd}" && grep -qE '(^| )::/0( |$)' <<<"${ipd}"; }; } \
    || { say "IPAddressDeny efetivo não nega tudo (${ipd:-vazio})"; return 1; }
  # o allow vence o deny: só o loopback pode estar nele (127.0.0.0/8 e ::1/128 é como o systemd mostra `localhost`)
  ipa="$(sed -n 's/^IPAddressAllow=//p' <<<"${show}")"
  for a in ${ipa}; do case "${a}" in 127.0.0.0/8|::1/128|127.0.0.1/32|localhost) : ;; *) say "IPAddressAllow efetivo fora do loopback: ${a}"; return 1 ;; esac; done
  grep -qx 'DynamicUser=yes' <<<"${show}" && grep -qx 'ProtectHome=yes' <<<"${show}" || { say "DynamicUser/ProtectHome efetivos diferentes de yes"; return 1; }
  say "OK sandbox efetivo: DynamicUser, ProtectHome, IPAddressDeny=${ipd}"
  ldr="$(ss -ltnH "sport = :${PORT}" 2>/dev/null)" || { say "NÃO MEDI: ss falhou"; return 2; }
  addrs="$(awk '{print $4}' <<<"${ldr}")"
  [ -n "${addrs}" ] || { say "ninguém escuta na porta ${PORT}"; return 1; }
  while IFS= read -r a; do
    case "${a}" in "127.0.0.1:${PORT}"|"[::1]:${PORT}") : ;; *) say "a porta ${PORT} escuta FORA do loopback: ${a}"; return 1 ;; esac
  done <<<"${addrs}"
  say "OK a porta ${PORT} escuta só em loopback ($(tr '\n' ' ' <<<"${addrs}"))"
  h="$(curl -fsS -m 10 "http://127.0.0.1:${PORT}/health" 2>/dev/null)" || { say "/health não respondeu"; return 1; }
  hsha="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("server_sha256",""))' <<<"${h}" 2>/dev/null)"
  [ "${hsha}" = "${SERVER_SHA}" ] || { say "o processo serve outro código (server_sha256 ${hsha:0:12} != ${SERVER_SHA:0:12} do repositório)"; return 1; }
  say "OK /health pronto, servindo o server.py deste commit (${SERVER_SHA:0:12})"
  say "prova pelo cliente numa unit transitória (token por LoadCredential=, mesmo sandbox):"
  transient_smoke "verify" --url "http://127.0.0.1:${PORT}" --expect-sha "${SERVER_SHA}" --expect-core-sha "${CORE_SHA}"; vrc=$?
  [ "${vrc}" = 0 ] || return "${vrc}"
  nok="$(grep -c '' <<<"${show}")"
  say "verify OK — ${UNIT} vivo (MainPID ${pid}), loopback, token exigido, fixture transcrito, MemoryMax ${MEMORY_MAX} (${nok} propriedades lidas)"
}
if [ "${SUB}" = verify ]; then verify_live; exit $?; fi

# ── install: pré-voo da máquina ──────────────────────────────────────────────────────────────────────
python3 -c 'import sys; sys.exit(0 if sys.version_info[:2] == (3, 12) else 1)' \
  || die 1 "python3 não é 3.12: o requirements.lock fixa rodas cp312 (refaça o lock para a versão nova)"
python3 -c 'import ensurepip' 2>/dev/null || die 1 "python3 sem ensurepip (pacote python3-venv): o venv não nasce"
command -v ffmpeg >/dev/null || die 1 "ffmpeg ausente: o servidor decodifica por ele o que o libsndfile não lê"
command -v systemd-run >/dev/null || die 2 "systemd-run ausente"
sdv="$(systemctl --version 2>/dev/null | awk 'NR==1{print $2}')"
[[ "${sdv}" =~ ^[0-9]+$ ]] && [ "${sdv}" -ge 247 ] || die 1 "systemd ${sdv:-?} < 247 (LoadCredential= e IPAddressDeny= exigem)"
say "OK máquina: python $(python3 -c 'import sys; print(sys.version.split()[0])'), $(ffmpeg -version 2>/dev/null | awk 'NR==1{print $1, $3}'), systemd ${sdv}"
occ="$(ss -ltnpH "sport = :${PORT}" 2>/dev/null)" || die 2 "não medi a porta ${PORT} (ss)"
if [ -n "${occ}" ]; then
  mpid="$(systemctl show -p MainPID --value "${UNIT}" 2>/dev/null)"
  [[ "${mpid}" =~ ^[1-9][0-9]*$ ]] && grep -q "pid=${mpid}," <<<"$(priv ss -ltnpH "sport = :${PORT}" 2>/dev/null)" \
    || die 1 "a porta ${PORT} está ocupada por outro processo: ${occ}"
  say "OK a porta ${PORT} é do próprio ${UNIT} (MainPID ${mpid})"
else
  say "OK a porta ${PORT} está livre"
fi

staged() { priv test -f "$1/${COMPLETE}"; }
need_stage=0
for d in "${MODEL_DIR}" "${VAD_DIR}" "${VENV_DIR}" "${CODE_DIR}"; do staged "${d}" || need_stage=1; done
if [ "${need_stage}" = 1 ]; then
  pd="${ROOT}"; while [ ! -d "${pd}" ]; do pd="$(dirname "${pd}")"; done
  free_kb="$(df -Pk "${pd}" 2>/dev/null | awk 'NR==2{print $4}')"
  [[ "${free_kb}" =~ ^[0-9]+$ ]] || die 2 "não medi o disco livre em ${pd}"
  [ "${free_kb}" -ge "${MIN_FREE_KB}" ] || die 1 "disco livre em ${pd}: ${free_kb} KB < ${MIN_FREE_KB} KB"
  say "OK disco livre em ${pd}: $(( free_kb / 1024 )) MB"
fi

# ── pins contra as fontes oficiais ─────────────────────────────────────────────────────────────────────
check_hf() {  # <repo> <rev> <arquivos…>: a revisão fixada publica cada arquivo com o hash e o tamanho fixados
  local repo="$1" rev="$2"; shift 2
  local api
  api="$(curl -fsS -m 30 --proto '=https' "https://huggingface.co/api/models/${repo}/revision/${rev}?blobs=true" 2>/dev/null)" \
    || { say "NÃO MEDI: a API do Hugging Face não respondeu para ${repo}@${rev:0:12}"; return 2; }
  printf '%s\n' "$@" | python3 -c '
import json, sys
api = json.loads(sys.argv[1]); rev = sys.argv[2]
got_rev = api.get("sha")
if got_rev != rev:
    print(f"FALHA a revisão respondida ({got_rev}) não é a fixada"); sys.exit(1)
sib = {s["rfilename"]: s for s in api.get("siblings", [])}
bad = 0
for line in sys.stdin:
    name, kind, digest, size = line.split()
    s = sib.get(name)
    got = None if s is None else ((s.get("lfs") or {}).get("sha256") if kind == "sha256" else s.get("blobId"))
    if s is None or got != digest or int(s.get("size") or -1) != int(size):
        pub_size = None if s is None else s.get("size")
        print(f"FALHA {name}: publicado {got} ({pub_size} B) != fixado {digest[:12]} ({size} B)"); bad += 1
    else:
        print(f"OK {name} {digest[:12]} ({size} B)")
sys.exit(1 if bad else 0)' "${api}" "${rev}" | sed 's/^/    /'
  return "${PIPESTATUS[1]}"
}
check_pypi() {  # cada linha do lock: o hash existe no PyPI para aquela versão
  local f="$1" line name ver hash js bad=0
  while IFS= read -r line; do
    case "${line}" in ''|'#'*) continue ;; esac
    name="${line%%==*}"; ver="${line#*==}"; ver="${ver%% *}"; hash="${line##*sha256:}"
    js="$(curl -fsS -m 30 --proto '=https' "https://pypi.org/pypi/${name}/${ver}/json" 2>/dev/null)" \
      || { say "NÃO MEDI: o PyPI não respondeu para ${name} ${ver}"; return 2; }
    if python3 -c 'import json,sys; d=json.loads(sys.argv[1]); sys.exit(0 if any(u.get("digests",{}).get("sha256")==sys.argv[2] for u in d.get("urls",[])) else 1)' "${js}" "${hash}"; then
      printf '    OK %s %s %s\n' "${name}" "${ver}" "${hash:0:12}"
    else
      printf '    FALHA %s %s: o hash %s não está entre os arquivos publicados\n' "${name}" "${ver}" "${hash:0:12}"; bad=1
    fi
  done < "${f}"
  return "${bad}"
}
say "pins do modelo (${MODEL_REPO}@${MODEL_REV:0:12}) e do VAD (${VAD_REPO}@${VAD_REV:0:12}) contra o Hugging Face:"
check_hf "${MODEL_REPO}" "${MODEL_REV}" "${MODEL_FILES[@]}"; r=$?; [ "${r}" = 0 ] || die "${r}" "pin do modelo não confere com a fonte oficial"
check_hf "${VAD_REPO}" "${VAD_REV}" "${VAD_FILES[@]}"; r=$?; [ "${r}" = 0 ] || die "${r}" "pin do VAD não confere com a fonte oficial"
say "lock do ambiente contra o PyPI (pip.lock + requirements.lock):"
check_pypi "${SRC}/pip.lock"; r=$?; [ "${r}" = 0 ] || die "${r}" "pip.lock não confere com o PyPI"
check_pypi "${SRC}/requirements.lock"; r=$?; [ "${r}" = 0 ] || die "${r}" "requirements.lock não confere com o PyPI"

# ── a unit: diferença para a instalada ─────────────────────────────────────────────────────────────────
installed=0
if priv test -e "${UNIT_FILE}"; then
  installed=1
  priv cat "${UNIT_FILE}" > "${TMPD}/atual.service" || die 2 "não li ${UNIT_FILE}"
  grep -qxF "${MARKER}" "${TMPD}/atual.service" || say "AVISO: ${UNIT_FILE} NÃO foi gerada por este wrapper: vai para o backup antes da troca"
fi
if [ "${installed}" = 1 ] && cmp -s "${TMPD}/atual.service" "${TMPD}/${UNIT}.service" && [ "${need_stage}" = 0 ] && priv test -s "${TOKEN_FILE}"; then
  vrc=0; verify_live >/dev/null 2>&1 || vrc=$?
  [ "${vrc}" = 2 ] && die 2 "NÃO MEDI o serviço vivo: nada foi tocado"
  if [ "${vrc}" = 0 ]; then say "NOOP — unit idêntica, área montada, token presente e o verify do serviço vivo passa. Nada tocado."; exit 0; fi
  say "a unit instalada é idêntica, mas o serviço vivo NÃO a prova (verify reprovou): segue para a troca"
fi
if [ "${installed}" = 1 ]; then say "diferença para a instalada:"; diff -u "${TMPD}/atual.service" "${TMPD}/${UNIT}.service" | sed 's/^/    /'
else say "unit NOVA (não há ${UNIT_FILE}):"; sed 's/^/    /' "${TMPD}/${UNIT}.service"; fi

if [ "${APPLY}" = 0 ]; then
  if [ "${need_stage}" = 0 ] && priv test -s "${TOKEN_FILE}"; then
    say "a área já está montada: prova completa numa unit TRANSITÓRIA com o sandbox renderizado (o servidor sobe nela):"
    transient_smoke "ensaio" --serve "${VENV_DIR}/bin/python" -I -B "${CODE_DIR}/server.py" "${SERVER_ARGS[@]}"; r=$?
    [ "${r}" = 0 ] || die "${r}" "o ENSAIO na unit transitória reprovou: nada foi escrito"
  else
    say "a área ainda não está montada (modelo, venv ou código): a prova na unit transitória roda no --apply, ANTES de trocar a unit"
  fi
  say "ENSAIO OK: nada foi escrito. Para instalar, repita com --apply (monta ${ROOT}, cria o token se faltar, instala e reinicia ${UNIT})."
  exit 0
fi

# ── --apply: montagem aditiva ─────────────────────────────────────────────────────────────────────────
digest_ok() {  # <arquivo> <sha256|gitsha1> <hex>
  priv python3 -I -c '
import hashlib, sys
p, kind, want = sys.argv[1:4]
data = open(p, "rb").read()
got = hashlib.sha256(data).hexdigest() if kind == "sha256" else hashlib.sha1(b"blob %d\0" % len(data) + data).hexdigest()
sys.exit(0 if got == want else 1)' "$1" "$2" "$3"
}
fresh_dir() {  # diretório sem o marcador de completo é refeito do zero (montagem que morreu no meio)
  if priv test -e "$1"; then priv rm -rf --one-file-system -- "$1" || return 1; fi
  priv install -d -m 0755 "$1"
}
stage_hf() {  # <dir> <repo> <rev> <arquivos…>
  local dir="$1" repo="$2" rev="$3"; shift 3
  local line name kind digest size
  staged "${dir}" && { say "reusa ${dir}"; return 0; }
  fresh_dir "${dir}" || return 1
  for line in "$@"; do
    read -r name kind digest size <<<"${line}"
    priv curl -fsSL --proto '=https' --retry 3 -o "${dir}/${name}" "https://huggingface.co/${repo}/resolve/${rev}/${name}" \
      || { say "download falhou: ${repo}/${name}"; return 1; }
    digest_ok "${dir}/${name}" "${kind}" "${digest}" || { say "hash NÃO confere: ${dir}/${name}"; return 1; }
    priv chmod 0644 "${dir}/${name}"
  done
  printf '%s@%s\n' "${repo}" "${rev}" | priv tee "${dir}/${COMPLETE}" >/dev/null
  say "montado ${dir} ($# arquivo(s), hashes conferidos)"
}
stage_venv() {
  staged "${VENV_DIR}" && { say "reusa ${VENV_DIR}"; return 0; }
  fresh_dir "${VENV_DIR}" || return 1
  priv python3 -m venv "${VENV_DIR}" || return 1
  local pipargs=(-I -m pip install --quiet --disable-pip-version-check --no-cache-dir --require-hashes --only-binary :all: --no-deps)
  priv "${VENV_DIR}/bin/python" "${pipargs[@]}" -r "${SRC}/pip.lock" || return 1
  priv "${VENV_DIR}/bin/python" "${pipargs[@]}" -r "${SRC}/requirements.lock" || return 1
  priv "${VENV_DIR}/bin/python" -I -m pip check >/dev/null || return 1
  priv "${VENV_DIR}/bin/python" -I -c 'import onnx_asr, onnxruntime, numpy, soundfile, starlette, uvicorn, multipart' || return 1
  priv chmod -R go-w "${VENV_DIR}"
  printf '%s\n' "${LOCK_ID}" | priv tee "${VENV_DIR}/${COMPLETE}" >/dev/null
  say "montado ${VENV_DIR} (lock por hash, pip check limpo)"
}
stage_code() {
  local f
  if staged "${CODE_DIR}"; then
    # o nome é o hash do conteúdo, mas quem o confere é o disco: arquivo trocado depois do marcador refaz o diretório
    for f in "${CODE_FILES[@]}"; do priv cmp -s "${SRC}/${f}" "${CODE_DIR}/${f}" || break; done
    if priv cmp -s "${SRC}/${f}" "${CODE_DIR}/${f}"; then say "reusa ${CODE_DIR} (conteúdo conferido)"; return 0; fi
    say "${CODE_DIR} difere da fonte (${f}): refaço"
  fi
  fresh_dir "${CODE_DIR}" || return 1
  priv install -d -m 0755 "${CODE_DIR}/fixtures" || return 1
  for f in "${CODE_FILES[@]}"; do priv install -m 0644 "${SRC}/${f}" "${CODE_DIR}/${f}" || return 1; done
  printf '%s\n' "${CODE_ID}" | priv tee "${CODE_DIR}/${COMPLETE}" >/dev/null
  say "montado ${CODE_DIR}"
}
priv install -d -m 0755 "${ROOT}" "${ROOT}/models" || die 2 "não criei ${ROOT}"
stage_hf "${MODEL_DIR}" "${MODEL_REPO}" "${MODEL_REV}" "${MODEL_FILES[@]}" || die 1 "montagem do modelo falhou (a unit de produção não foi tocada)"
stage_hf "${VAD_DIR}" "${VAD_REPO}" "${VAD_REV}" "${VAD_FILES[@]}" || die 1 "montagem do VAD falhou (a unit de produção não foi tocada)"
stage_venv || die 1 "montagem do venv falhou (a unit de produção não foi tocada)"
stage_code || die 1 "montagem do código falhou (a unit de produção não foi tocada)"

# o token: gerado DENTRO do root (nunca em argv, nunca impresso), 0600; existente é mantido
if ! priv test -s "${TOKEN_FILE}"; then
  priv install -d -m 0700 "${ETC}" || die 2 "não criei ${ETC}"
  priv sh -c 'umask 077; set -C; python3 -I -c "import secrets; print(secrets.token_urlsafe(48))" > "$1"' _ "${TOKEN_FILE}" \
    || die 1 "não gerei o token em ${TOKEN_FILE}"
  say "token novo em ${TOKEN_FILE} (0600, root; o cliente o recebe do maestro por: sudo cat ${TOKEN_FILE})"
else
  priv sh -c 'test "$(stat -c %a "$1")" = 600' _ "${TOKEN_FILE}" || die 1 "${TOKEN_FILE} existe com modo diferente de 0600: corrija antes"
  say "token existente mantido (${TOKEN_FILE}, 0600)"
fi

say "prova completa numa unit TRANSITÓRIA com o sandbox novo, ANTES de trocar a unit de produção:"
transient_smoke "pré-troca" --serve "${VENV_DIR}/bin/python" -I -B "${CODE_DIR}/server.py" "${SERVER_ARGS[@]}"; r=$?
[ "${r}" = 0 ] || die "${r}" "a prova pré-troca reprovou: a unit de produção NÃO foi tocada (a área montada fica, aditiva)"

TS="$(date +%Y%m%d-%H%M%S)"
BK=""
if [ "${installed}" = 1 ]; then
  BK="${BACKUP_DIR}/${UNIT}.service.${TS}"
  priv install -d -m 0700 "${BACKUP_DIR}" && priv install -m 0600 "${UNIT_FILE}" "${BK}" \
    || die 2 "backup da unit anterior falhou: sem rede de segurança não se troca"
  say "backup da anterior: ${BK}"
fi
rollback() {
  cat >&2 <<EOF
[${NAME}] ─── ROLLBACK MANUAL (do maestro, fora da sessão: \`!\` no prompt) ───
EOF
  if [ -n "${BK}" ]; then
    echo "  sudo install -m 0644 ${BK} ${UNIT_FILE}   # volta a anterior (a área antiga em ${ROOT} segue lá: a montagem é aditiva)" >&2
  else
    echo "  sudo systemctl disable --now ${UNIT}; sudo rm -f ${UNIT_FILE}" >&2
  fi
  cat >&2 <<EOF
  sudo systemctl daemon-reload
  sudo systemctl reset-failed ${UNIT}
  sudo systemctl restart ${UNIT}   # só se voltou uma unit anterior
  curl -fsS http://127.0.0.1:${PORT}/health
EOF
}
fail_after() { printf '[%s] ERRO: %s\n' "${NAME}" "$1" >&2; rollback; exit 1; }

own=(-o root -g root); [ "${TEST}" = 1 ] && own=()
priv install "${own[@]}" -m 0644 "${TMPD}/${UNIT}.service" "${UNIT_FILE}" || fail_after "não instalei ${UNIT_FILE}"
priv systemctl daemon-reload || fail_after "daemon-reload falhou"
priv systemctl enable "${UNIT}" >/dev/null 2>&1 || fail_after "systemctl enable falhou"
OLD_INV="$(systemctl show -p InvocationID --value "${UNIT}" 2>/dev/null)"
priv systemctl restart "${UNIT}" || fail_after "systemctl restart recusou (journalctl -u ${UNIT})"
up=0
for _ in $(seq 1 60); do
  if curl -fsS -m 3 "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then up=1; break; fi
  sleep 2
done
[ "${up}" = 1 ] || fail_after "/health não respondeu em ~120 s depois do restart"
INV="$(systemctl show -p InvocationID --value "${UNIT}" 2>/dev/null)"
[ -n "${INV}" ] && [ "${INV}" != "${OLD_INV}" ] || fail_after "a invocação não mudou (${INV:-?}): o restart não aconteceu"
_vrc=0; verify_live || _vrc=$?
[ "${_vrc}" = 0 ] || fail_after "o verify do serviço vivo $([ "${_vrc}" = 2 ] && echo 'NÃO MEDIU (rc 2)' || echo reprovou) depois do restart"
say "OK — ${UNIT} instalado e provado (invocação ${INV:0:8}); código ${CODE_ID}, ambiente ${LOCK_ID}, modelo ${MODEL_REV:0:12}"
rollback 2>&1 | sed 's/^/  (se precisar) /'
exit 0
