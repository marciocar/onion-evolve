#!/usr/bin/env bash
# bridge-hardening.sh — o DEGRAU 1 do isolamento do /chat: o drop-in de INTEGRIDADE do onion-vps-bridge (core-only).
#
# POR QUE EXISTE (2026-10-16, decisão do maestro D_MAESTRO_DEGRAU1_JA_DEGRAUS_2_3_POR_SPIKE_1016, «1 já, 2 e 3 por
# spike»): o agente do /chat roda no MESMO UID da conta do serviço, e a unit dá a home dela inteira como gravável
# (20-hardening.conf: o CLI grava o .claude.json por temp+rename e o a2a-verify escreve no clone servido). Com isso
# o agente podia reescrever o código que o serviço executa (src/, scripts/, node_modules/), a raiz de confiança do
# A2A (jwks/, members.yaml, o próprio a2a-verify.sh) e os dotfiles que rodam no próximo shell — persistência que
# sobrevive ao turno e roda com todos os segredos no restart. Este drop-in fecha a ESCRITA nesses caminhos e esconde
# a chave de deploy e o PAT. NÃO guarda segredo: no mesmo UID o agente segue lendo o .env e o environ do processo
# (E_SYSTEMD_PROTECTPROC_HIDES_OTHER_USERS_ONLY); isso é o degrau 2 (UID distinto). E sem EnvironmentFile=, de
# propósito: ele levaria o segredo para o environ, que o mesmo UID lê (E_OBJECAO_01_ENVFILE_LEAKS_TO_PROCFS_ENVIRON).
# Molde: ops/update-bridge.sh e ops/a2a-invite-live.sh (trava, recusa root, ensaio por padrão, backup, rollback
# impresso, prova depois).
#
# USO
#   ops/bridge-hardening.sh install [--apply]   ensaio (padrão) ou instalação do 30-integrity.conf
#   ops/bridge-hardening.sh verify              prova, no namespace do processo VIVO, que a proteção vale
#   ops/bridge-hardening.sh show                imprime o drop-in que seria instalado (nada é medido)
#
#   install sem --apply é ENSAIO: mede a unit, renderiza o drop-in, mostra a diferença para o instalado e roda as
#   checagens numa unit TRANSITÓRIA (systemd-run --collect) com as propriedades da unit de hoje MAIS as do drop-in
#   novo, como a conta do serviço. Nada persistente é escrito.
#   verify é só leitura (sem trava): entra no namespace de montagem do MainPID como a conta do serviço e confere cada
#   caminho. Rode depois de todo ops/update-bridge.sh: um arquivo trocado por rename POR FORA da unit perde o bind
#   só-leitura dentro dela até o próximo restart (medido em 2026-10-16; diretório não perde).
#
# O QUE O install --apply FAZ: trava (a do update-bridge, que reinicia a mesma unit) → pré-voo (unit, premissas do
# 20-hardening, caminhos existem, /health ok) → ensaio na unit transitória → backup do 30-integrity.conf anterior →
# placeholders `{}` para os .claude/settings*.json ausentes (sem eles o bind não existe e o agente poderia CRIAR o
# arquivo — a classe do CVE-2026-25725) → instala o drop-in → daemon-reload → restart → /health e a linha de boot
# desta invocação → verify. Falha depois do restart imprime o rollback; nunca o executa.
#
# EXIT: 0 ok · 1 problema medido ou recusado · 2 não pude medir (trava, sudo, unit, health) · 3 uso inválido
#
# MODO DE TESTE (bancada): ONION_BRIDGE_HARDENING_TEST=1 com ONION_BRIDGE_HARDENING_SVC_HOME (a home de sandbox),
#   ONION_BRIDGE_HARDENING_STATE, ONION_BRIDGE_HARDENING_DROPIN_DIR, ONION_BRIDGE_HARDENING_BACKUP_DIR e
#   ONION_BRIDGE_HARDENING_LOCK. Nele nada passa por sudo: systemctl, systemd-run, nsenter, journalctl, findmnt e curl
#   vêm do PATH (a bancada põe falsos), e nenhum caminho pode cair sob a home real da conta do serviço.
#   Qualquer ONION_BRIDGE_HARDENING_* sem o modo de teste é uso inválido (rc 3): produção não se redireciona por env.
set -uo pipefail

UNIT=onion-vps-bridge
SVC_USER=onion
PROD_SVC_HOME=/home/onion
PROD_STATE=/var/lib/onion-bridge
PROD_DROPIN_DIR=/etc/systemd/system/onion-vps-bridge.service.d
PROD_BACKUP_DIR=/var/backups/onion-bridge-hardening
PROD_LOCK=/tmp/onion-update-bridge.lock
HEALTH_LOCAL="http://127.0.0.1:8787/health"
DROPIN_NAME=30-integrity.conf
BASE_DROPIN=20-hardening.conf
MARKER="# onion-bridge-hardening: v1"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME=bridge-hardening

say()  { printf '[%s] %s\n' "${NAME}" "$*"; }
die()  { local rc="$1"; shift; printf '[%s] ERRO: %s\n' "${NAME}" "$*" >&2; exit "${rc}"; }
usage() { sed -n '/^# USO/,/^# O QUE O install/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 3; }

case "${1:-}" in -h|--help) sed -n '/^# USO/,/^# MODO DE TESTE/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 0 ;; '') usage ;; esac

# ── modo: produção ou teste declarado ──────────────────────────────────────────────────────────────────
TEST=0
if [ "${ONION_BRIDGE_HARDENING_TEST:-}" = 1 ]; then
  TEST=1
  SVC_HOME="${ONION_BRIDGE_HARDENING_SVC_HOME:?modo de teste exige ONION_BRIDGE_HARDENING_SVC_HOME}"
  STATE="${ONION_BRIDGE_HARDENING_STATE:?modo de teste exige ONION_BRIDGE_HARDENING_STATE}"
  DROPIN_DIR="${ONION_BRIDGE_HARDENING_DROPIN_DIR:?modo de teste exige ONION_BRIDGE_HARDENING_DROPIN_DIR}"
  BACKUP_DIR="${ONION_BRIDGE_HARDENING_BACKUP_DIR:?modo de teste exige ONION_BRIDGE_HARDENING_BACKUP_DIR}"
  LOCK="${ONION_BRIDGE_HARDENING_LOCK:?modo de teste exige ONION_BRIDGE_HARDENING_LOCK}"
  SVC_USER="$(id -un)"   # a conta do serviço não existe na bancada (CI): quem roda faz o papel dela
  for _p in "${SVC_HOME}" "${STATE}" "${DROPIN_DIR}" "${BACKUP_DIR}"; do
    _r="$(realpath -m -- "${_p}")"
    case "${_r}/" in "${PROD_SVC_HOME}/"*|"${PROD_STATE}/"*|/etc/systemd/*) die 3 "modo de teste com caminho de produção: recusado (${_r})" ;; esac
  done
else
  [ -n "${ONION_BRIDGE_HARDENING_TEST:-}" ] && die 3 "ONION_BRIDGE_HARDENING_TEST só aceita 1"
  if compgen -e | grep -E '^ONION_BRIDGE_HARDENING_' >/dev/null; then
    die 3 "variável ONION_BRIDGE_HARDENING_* sem ONION_BRIDGE_HARDENING_TEST=1: produção não se redireciona por ambiente"
  fi
  SVC_HOME="${PROD_SVC_HOME}"; STATE="${PROD_STATE}"; DROPIN_DIR="${PROD_DROPIN_DIR}"; BACKUP_DIR="${PROD_BACKUP_DIR}"; LOCK="${PROD_LOCK}"
  # o wrapper roda como root por sudo o que ele mesmo renderiza: tem de ser o RASTREADO e limpo de um checkout
  # (uma cópia mutada instalaria outro drop-in — refutador do a2a-invite-live, 2026-10-15)
  _f="${SELF_DIR}/$(basename "${BASH_SOURCE[0]}")"
  git -C "${SELF_DIR}" ls-files --error-unmatch -- "${_f}" >/dev/null 2>&1 \
    || die 3 "${_f} não é arquivo rastreado de um checkout: rode o wrapper do repositório, não uma cópia"
  git -C "${SELF_DIR}" diff --quiet HEAD -- "${_f}" 2>/dev/null \
    || die 3 "${_f} tem mudança não commitada: rode o wrapper como está no commit"
fi

[ "$(id -u)" -eq 0 ] && die 3 "rodando como root: rode como o operador (o wrapper chama sudo onde precisa)"

# priv <cmd…>: como root (produção) ou como quem roda (teste) · as_svc <cmd…>: como a conta do serviço
priv()   { if [ "${TEST}" = 1 ]; then "$@"; else sudo -n "$@"; fi; }
as_svc() { if [ "${TEST}" = 1 ]; then (cd / && "$@"); else (cd / && sudo -n -u "${SVC_USER}" "$@"); fi; }

# ── argumentos: lista FECHADA ─────────────────────────────────────────────────────────────────────────
SUB="$1"; shift
APPLY=0
case "${SUB}" in install|verify|show) : ;; *) usage ;; esac
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) [ "${SUB}" = install ] || die 3 "--apply só no install"; APPLY=1; shift ;;
    *) die 3 "opção não aceita: $1 (a unit, os caminhos e o drop-in são fixos)" ;;
  esac
done

# ── o que o drop-in protege (caminhos relativos à home da conta do serviço) ─────────────────────────────
# CRITÉRIO: código que o serviço EXECUTA ou em que CONFIA, e o que roda como a conta do serviço FORA da unit (o git e o
# npm do update-bridge, com a chave de deploy e o PAT à vista). Medido em 2026-10-16: lido o código do bridge e o do
# gate A2A; strace do SDK e do tsx numa unit transitória, 0 EROFS.
# As ÁRVORES INTEIRAS, não subdiretórios (refutador, achado 1, provado): com só `src/` só-leitura, `mv onion-bridge
# onion-bridge.old && mkdir -p onion-bridge/src` dava uma árvore nova gravável — a raiz da árvore tem de ser ponto de
# montagem, que o kernel não deixa renomear (EBUSY, medido). Isso também cobre o .git dos dois repositórios
# (core.fsmonitor e hooks rodam no git do update-bridge), o package-lock e o .npmrc de projeto (o npm ci), e os arquivos
# de confiança que o bridge lê do clone (agent-card, federation-orgs, a2a-verify, jwks, members.yaml).
RO_DIRS=( onion-bridge onion-evolve .config .local/bin )
RO_FILES=( .bashrc .profile .bash_profile .gitconfig .npmrc .claude/settings.json .claude/settings.local.json )
# o que o serviço ESCREVE dentro das árvores: exceção gravável ANINHADA (o mais específico vence, medido)
RW_NESTED=( onion-bridge/data onion-evolve/.claude/sessions onion-evolve/docs/evolution/trust-log.md )
# ausentes hoje: sem arquivo não há bind só-leitura, e o agente poderia CRIÁ-LO (a classe do CVE-2026-25725; o
# ~/.config/git/config e o ~/.npmrc seriam lidos pelo git e pelo npm do update-bridge). O --apply cria, vazios.
# ~/.local/bin entra no PATH do .profile se existir; ~/.bash_profile, se criado, vence o .profile no shell de login —
# o placeholder dele só encadeia o .profile, então o comportamento de hoje não muda (refutador, 2ª passada, achado 3)
PLACEHOLDERS=( .claude/settings.json:json .claude/settings.local.json:json .config:dir .local/bin:dir .npmrc:empty .bash_profile:chain )
INACCESSIBLE=( .ssh .git-credentials )   # o serviço não os usa (medido): o git com o PAT e a chave de deploy é do
                                         # update-bridge, que roda FORA da unit (sudo -u, não dentro dela)
# arquivos de confiança CONCRETOS, conferidos um a um no verify (a raiz só-leitura não basta: um symlink no MEIO
# de uma exceção gravável a desviava para dentro da raiz — refutador, 2ª passada, achado 1, provado)
TRUST_PROBES=( onion-bridge/src/server.ts onion-bridge/package-lock.json onion-evolve/.claude/utils/federation-transport/a2a-verify.sh
               onion-evolve/.claude/utils/federation-transport/jwks onion-evolve/.claude/validation/trust-topology-check.sh
               onion-evolve/docs/evolution/federation/members.yaml onion-evolve/.git/config )
# o que TEM de seguir gravável (o 203/EXEC de 08-10: o CLI grava na home, o bridge no estado e o gate no clone)
RW_CONTROLS=( "" .claude.json .claude .claude/projects "${RW_NESTED[@]}" )
is_placeholder() { local q; for q in "${PLACEHOLDERS[@]}"; do [ "${q%%:*}" = "$1" ] && return 0; done; return 1; }

render_dropin() {
  local p
  cat <<EOF
# ${DROPIN_DIR}/${DROPIN_NAME}
${MARKER}
# GERADO por ops/bridge-hardening.sh (core-only). Não edite à mão: rode o wrapper (install, depois verify).
# Degrau 1 do isolamento do /chat — só INTEGRIDADE: o agente roda no mesmo UID do serviço e segue LENDO o .env e o
# environ do processo; o que este arquivo fecha é a ESCRITA no código que o serviço executa, na raiz de confiança do
# A2A, nos .git e nos dotfiles, e a leitura da chave de deploy e do PAT. SEM EnvironmentFile=, de propósito (o segredo
# iria para o environ, que o mesmo UID lê). Aninhado no ReadWritePaths= do ${BASE_DROPIN}, com as exceções
# graváveis aninhadas aqui: o mais específico vence.
# O '-' em cada caminho: ausente não derruba o start (sem ele: 226/NAMESPACE, medido); a ausência aparece no verify.
# REVERSÃO: sudo rm ${DROPIN_DIR}/${DROPIN_NAME} && sudo systemctl daemon-reload && sudo systemctl restart ${UNIT}
[Service]
EOF
  for p in "${RO_DIRS[@]}" "${RO_FILES[@]}"; do printf 'ReadOnlyPaths=-%s/%s\n' "${SVC_HOME}" "${p}"; done
  for p in "${RW_NESTED[@]}"; do printf 'ReadWritePaths=-%s/%s\n' "${SVC_HOME}" "${p}"; done
  for p in "${INACCESSIBLE[@]}"; do printf 'InaccessiblePaths=-%s/%s\n' "${SVC_HOME}" "${p}"; done
}

# check_script → o sh que roda DENTRO do namespace (ensaio ou processo vivo), como a conta do serviço. Só lê e usa
# access(2): `test -w` responde EROFS de montagem só-leitura sem escrever nada. Cada linha: OK|FALHA|AUSENTE <o quê>.
check_script() {
  local mode="$1" p
  echo 'n_fail=0; ok() { echo "OK $*"; }; bad() { echo "FALHA $*"; n_fail=$((n_fail+1)); }'
  for p in "${RO_DIRS[@]}" "${RO_FILES[@]}"; do
    printf 'p=%q\n' "${SVC_HOME}/${p}"
    # placeholder ausente no ENSAIO é esperado (o --apply o cria); fora dele, ausência é proteção perdida
    if is_placeholder "${p}" && [ "${mode}" = ensaio ]; then
      echo 'if [ ! -e "$p" ]; then echo "AUSENTE só-leitura $p (o --apply cria o placeholder)"; else'
    else
      echo 'if [ ! -e "$p" ]; then bad "só-leitura AUSENTE (sem bind, sem proteção) $p"; else'
    fi
    echo '  o="$(findmnt -no OPTIONS -T "$p" 2>/dev/null | cut -d, -f1)"; m="$(findmnt -no TARGET -T "$p" 2>/dev/null)"'
    # gravável OU montagem rw → falha; e o caminho tem de SER o ponto de montagem (senão um rename do pai o tira)
    echo '  if test -w "$p" || [ "$o" != ro ]; then bad "só-leitura GRAVÁVEL (montagem: ${o:-?}) $p"'
    echo '  elif [ "$m" != "$p" ]; then bad "só-leitura sem ponto de montagem próprio (montado em ${m:-?}: um rename do pai o tira) $p"'
    echo '  else ok "só-leitura $p"; fi; fi'
  done
  for p in "${TRUST_PROBES[@]}"; do
    printf 'p=%q\n' "${SVC_HOME}/${p}"
    echo 'if [ -e "$p" ] && test -w "$p"; then bad "arquivo de confiança GRAVÁVEL $p"; elif [ -e "$p" ]; then ok "confiança só-leitura $p"; fi'
  done
  for p in "${INACCESSIBLE[@]}"; do
    printf 'p=%q\n' "${SVC_HOME}/${p}"
    echo 'if [ -e "$p" ] && test -r "$p"; then bad "inacessível LEGÍVEL $p"; else ok "inacessível $p"; fi'
  done
  for p in "${RW_CONTROLS[@]}"; do
    if [ -z "${p}" ]; then printf 'p=%q\n' "${SVC_HOME}"; else printf 'p=%q\n' "${SVC_HOME}/${p}"; fi
    echo 'if [ -e "$p" ]; then t="$p"; else t="$(dirname "$p")"; fi'
    echo 'if test -w "$t"; then ok "gravável $p"; else bad "gravável PERDIDO $p"; fi'
  done
  printf 'p=%q\n' "${STATE}"
  echo 'if test -w "$p"; then ok "gravável $p"; else bad "gravável PERDIDO $p"; fi'
  if [ "${mode}" = ensaio ]; then
    # o ExecStart vive em node_modules (só-leitura agora): tem de seguir executável E transpilar o src (o 203/EXEC de
    # 08-10). health.ts é importado de verdade (sem efeito colateral: medido), não só o --version
    printf 'p=%q; w=%q\n' "${SVC_HOME}/onion-bridge/node_modules/.bin/tsx" "${SVC_HOME}/onion-bridge"
    echo 'if (cd "$w" && "$p" --eval "import(\"$w/src/health.ts\").then(()=>process.exit(0),()=>process.exit(1))") >/dev/null 2>&1; then ok "ExecStart executa e transpila src/health.ts ($p)"; else bad "ExecStart NÃO executa ou NÃO transpila $p"; fi'
  fi
  echo 'echo "n_fail=$n_fail"; [ "$n_fail" = 0 ]'
}

# ── trava (só no install: verify e show só leem) ─────────────────────────────────────────────────────
if [ "${SUB}" = install ]; then
  exec 9>"${LOCK}" || die 2 "não abri a trava ${LOCK}"
  flock -n 9 || die 2 "outra execução (este wrapper, o update-bridge ou um wrapper A2A) segura ${LOCK}; tente de novo"
fi

TMPD="$(mktemp -d)"; trap 'rm -rf -- "${TMPD}"' EXIT
render_dropin > "${TMPD}/${DROPIN_NAME}"
if [ "${SUB}" = show ]; then cat "${TMPD}/${DROPIN_NAME}"; exit 0; fi

# ── verify: o namespace do processo VIVO ──────────────────────────────────────────────────────────────
verify_live() {
  local pid uid gid out rc dp
  pid="$(systemctl show -p MainPID --value "${UNIT}" 2>/dev/null)" || return 2
  [[ "${pid}" =~ ^[1-9][0-9]*$ ]] || { say "a unit ${UNIT} não tem processo vivo (MainPID=${pid:-?})"; return 2; }
  dp="$(systemctl show -p DropInPaths --value "${UNIT}" 2>/dev/null)" || { say "NÃO MEDI: o systemctl show de ${UNIT} falhou (DropInPaths)"; return 2; }
  case " ${dp} " in *"/${DROPIN_NAME} "*) : ;; *) say "o ${DROPIN_NAME} NÃO está carregado na unit (DropInPaths: ${dp:-vazio})"; return 1 ;; esac
  uid="$(id -u "${SVC_USER}" 2>/dev/null)"; gid="$(id -g "${SVC_USER}" 2>/dev/null)"
  [ -n "${uid}" ] && [ -n "${gid}" ] || { say "não resolvi o uid/gid de ${SVC_USER}"; return 2; }
  out="$(check_script live | priv nsenter -t "${pid}" -m -S "${uid}" -G "${gid}" --wdns=/ -- sh -s 2>&1)"; rc=$?
  printf '%s\n' "${out}"
  # NÃO MEDIU ≠ REPROVOU (2026-10-16, E_DEPLOY_DO_BRIDGE_REPROVA_O_QUE_NAO_PROVOU_1016): o sh de checagem SEMPRE imprime
  # a linha n_fail=<N> por último. Sem ela, o sh nem chegou ao fim: o sudo -n pediu senha, o nsenter não entrou no
  # namespace (MainPID que acabou de morrer, alvo ilegível) ou o sh caiu. Isso é rc 2 (não pude medir), nunca rc 1 —
  # antes saía 1, e o update-bridge o rotulava "o verify REPROVOU" sem nada ter sido medido.
  grep -qE '^n_fail=[0-9]+$' <<<"${out}" \
    || { say "NÃO MEDI: o check no namespace do MainPID ${pid} não rodou até o fim (rc ${rc}; sudo -n, nsenter ou alvo ilegível): $(tail -1 <<<"${out}" | cut -c1-200)"; return 2; }
  [ "${rc}" = 0 ] && grep -qx 'n_fail=0' <<<"${out}" || return 1
  say "verify OK — namespace do MainPID ${pid}: $(grep -c '^OK ' <<<"${out}") checagem(ns), 0 falha"
}
if [ "${SUB}" = verify ]; then verify_live; exit $?; fi

# ── install: pré-voo ─────────────────────────────────────────────────────────────────────────────────
priv test -d "${DROPIN_DIR}" || die 2 "não medi o diretório de drop-ins ${DROPIN_DIR}"
priv test -f "${DROPIN_DIR}/${BASE_DROPIN}" || die 1 "premissa mudou: ${BASE_DROPIN} não existe em ${DROPIN_DIR} (o aninhamento só-leitura pressupõe o ReadWritePaths dele)"
base="$(priv cat "${DROPIN_DIR}/${BASE_DROPIN}")" || die 2 "não li ${BASE_DROPIN}"
grep -qx 'ProtectSystem=strict' <<<"${base}" || die 1 "premissa mudou: ${BASE_DROPIN} sem ProtectSystem=strict"
grep -qx "${SVC_HOME}" <<<"$(grep -E '^ReadWritePaths=' <<<"${base}" | tr ' =' '\n\n')" \
  || die 1 "premissa mudou: ${BASE_DROPIN} não dá ${SVC_HOME} em ReadWritePaths= (o drop-in só-leitura aninha nele)"
grep -qE '^EnvironmentFile=' <<<"${base}" && die 1 "${BASE_DROPIN} tem EnvironmentFile=: o segredo no environ é o que o degrau 1 evita (E_OBJECAO_01)"
missing=(); links=()
for p in "${RO_DIRS[@]}" "${RO_FILES[@]}" "${RW_NESTED[@]}" "${INACCESSIBLE[@]}"; do
  # symlink num alvo: o systemd SEGUE o link ao montar (um settings.json → data/ deixaria o data/ só-leitura e o
  # serviço caído no restart), e um link pendente mata o placeholder (refutador, achado 6)
  # o caminho RESOLVIDO tem de ser o literal: pega o symlink na folha E em qualquer componente do meio
  [ "$(priv realpath -m -- "${SVC_HOME}/${p}")" = "${SVC_HOME}/${p}" ] || { links+=("${SVC_HOME}/${p}"); continue; }
  is_placeholder "${p}" && continue
  priv test -e "${SVC_HOME}/${p}" || missing+=("${SVC_HOME}/${p}")
done
[ "${#links[@]}" = 0 ] || die 1 "alvo(s) com SYMLINK no caminho: ${links[*]} — recusado (o bind seguiria o link); remova-o e rode de novo"
[ "${#missing[@]}" = 0 ] || die 1 "caminho(s) a proteger AUSENTE(S): ${missing[*]} — a lista é medida; mude-a no wrapper, nunca no alvo"

# ── diferença para o instalado ───────────────────────────────────────────────────────────────────────
installed=0
if priv test -e "${DROPIN_DIR}/${DROPIN_NAME}"; then
  installed=1
  priv cat "${DROPIN_DIR}/${DROPIN_NAME}" > "${TMPD}/atual.conf" || die 2 "não li o ${DROPIN_NAME} instalado"
  grep -qxF "${MARKER}" "${TMPD}/atual.conf" || say "AVISO: o ${DROPIN_NAME} instalado NÃO foi gerado por este wrapper (sem o marcador): vai para o backup antes da troca"
fi
need_ph=()
for q in "${PLACEHOLDERS[@]}"; do priv test -e "${SVC_HOME}/${q%%:*}" || need_ph+=("${q}"); done
if [ "${installed}" = 1 ] && cmp -s "${TMPD}/atual.conf" "${TMPD}/${DROPIN_NAME}" && [ "${#need_ph[@]}" = 0 ]; then
  # idêntico no disco NÃO é carregado no processo: um --apply que morreu entre o install e o restart deixaria a
  # proteção fora para sempre sob um NOOP (refutador, achado 4). O NOOP só vale com o verify do processo vivo
  if verify_live >/dev/null 2>&1; then
    say "NOOP — o ${DROPIN_NAME} instalado é idêntico ao renderizado, os placeholders existem e o verify do processo vivo passa. Serviço intocado."
    exit 0
  fi
  say "o ${DROPIN_NAME} instalado é idêntico, mas o processo vivo NÃO o prova (verify reprovou): segue para o restart"
fi
if [ "${installed}" = 1 ]; then
  say "diferença para o instalado:"; diff -u "${TMPD}/atual.conf" "${TMPD}/${DROPIN_NAME}" | sed 's/^/    /'
else
  say "drop-in NOVO (não há ${DROPIN_NAME} instalado):"; sed 's/^/    /' "${TMPD}/${DROPIN_NAME}"
fi
[ "${#need_ph[@]}" = 0 ] || say "placeholders a criar no --apply (dono ${SVC_USER}; json = \`{}\`, dir = vazio, empty = arquivo vazio): ${need_ph[*]}"

# ── ensaio: unit TRANSITÓRIA = a unit de hoje + o drop-in novo, como a conta do serviço ──────────────
props=()
while IFS='=' read -r k v; do
  case "${k}" in
    User|WorkingDirectory|ProtectSystem|ProtectHome|PrivateTmp|NoNewPrivileges|UMask) [ -n "${v}" ] && props+=(-p "${k}=${v}") ;;
    ReadWritePaths|InaccessiblePaths|ReadOnlyPaths) : ;;   # vêm do 20 (RW, abaixo) e do drop-in novo; o instalado não conta
  esac
done < <(systemctl show "${UNIT}" -p User -p WorkingDirectory -p ProtectSystem -p ProtectHome -p PrivateTmp -p NoNewPrivileges -p UMask 2>/dev/null)
rw="$(grep -E '^ReadWritePaths=' <<<"${base}" | sed 's/^ReadWritePaths=//' | paste -sd' ' -)"
ro=""; ina=""; rwn=""
while IFS= read -r l; do
  case "${l}" in ReadOnlyPaths=*) ro+="${l#ReadOnlyPaths=} " ;; InaccessiblePaths=*) ina+="${l#InaccessiblePaths=} " ;; ReadWritePaths=*) rwn+="${l#ReadWritePaths=} " ;; esac
done < "${TMPD}/${DROPIN_NAME}"
props+=(-p "ReadWritePaths=${rw} ${rwn% }" -p "ReadOnlyPaths=${ro% }" -p "InaccessiblePaths=${ina% }")
grep -q '^User=' <<<"$(printf '%s\n' "${props[@]}")" || die 2 "não medi as propriedades da unit ${UNIT} (systemctl show)"
say "ensaio numa unit transitória (systemd-run --collect, nada persistente) com $(( ${#props[@]} / 2 )) propriedade(s):"
ens="$(check_script ensaio | priv systemd-run --quiet --pipe --wait --collect "${props[@]}" /bin/sh -s 2>&1)"; erc=$?
printf '%s\n' "${ens}" | sed 's/^/    /'
if [ "${erc}" != 0 ] || ! grep -qx 'n_fail=0' <<<"${ens}"; then
  say "o ENSAIO reprovou (rc ${erc}): nada foi escrito. Leia as linhas FALHA acima."; exit 1
fi
if [ "${APPLY}" = 0 ]; then
  say "ENSAIO OK: nada foi escrito. Para instalar, repita com --apply (reinicia ${UNIT})."
  exit 0
fi

# ── --apply ──────────────────────────────────────────────────────────────────────────────────────────
grep -q '"ok":true' <<<"$(curl -fsS -m 5 "${HEALTH_LOCAL}" 2>/dev/null)" \
  || die 2 "/health já está doente ANTES da instalação — triagem primeiro (não se reinicia serviço doente)"
TS="$(date +%Y%m%d-%H%M%S)"
BK=""
if [ "${installed}" = 1 ]; then
  BK="${BACKUP_DIR}/${DROPIN_NAME}.${TS}"
  priv install -d -m 0700 "${BACKUP_DIR}" && priv install -m 0600 "${DROPIN_DIR}/${DROPIN_NAME}" "${BK}" \
    || die 2 "backup do ${DROPIN_NAME} anterior falhou: sem rede de segurança não se troca"
  say "backup do anterior: ${BK}"
fi
created=()

rollback() {
  cat >&2 <<EOF
[${NAME}] ─── ROLLBACK MANUAL (do maestro, fora da sessão: \`!\` no prompt) ───
EOF
  if [ -n "${BK}" ]; then
    echo "  sudo install -m 0644 ${BK} ${DROPIN_DIR}/${DROPIN_NAME}   # volta o anterior" >&2
  else
    echo "  sudo rm -f ${DROPIN_DIR}/${DROPIN_NAME}" >&2
  fi
  cat >&2 <<EOF
  sudo systemctl daemon-reload
  sudo systemctl reset-failed ${UNIT}   # crashloop consome StartLimitBurst
  sudo systemctl restart ${UNIT}
  curl -fsS ${HEALTH_LOCAL}
EOF
  local f
  for f in "${created[@]}"; do
    echo "  sudo -u ${SVC_USER} sh -c 'if [ -d ${f} ]; then rmdir ${f}; elif [ ! -s ${f} ] || [ \"\$(cat ${f})\" = \"{}\" ] || grep -q \"placeholder do ops/bridge-hardening.sh\" ${f}; then rm -f ${f}; fi'   # placeholder criado nesta execução" >&2
  done
}
fail_after() { printf '[%s] ERRO: %s\n' "${NAME}" "$1" >&2; rollback; exit 1; }

# placeholders: um a um, com o rollback impresso se um falhar no meio (refutador, achado 8)
for q in "${need_ph[@]}"; do
  f="${SVC_HOME}/${q%%:*}"
  case "${q##*:}" in
    json)  as_svc sh -c 'umask 022; set -C; printf "{}\n" > "$1"' _ "${f}" ;;
    empty) as_svc sh -c 'umask 022; set -C; : > "$1"' _ "${f}" ;;
    dir)   as_svc mkdir -m 0755 -- "${f}" ;;
    chain) as_svc sh -c 'umask 022; set -C; printf "%s\n" "# placeholder do ops/bridge-hardening.sh: só encadeia o .profile" "[ -f \"\$HOME/.profile\" ] && . \"\$HOME/.profile\"" > "$1"' _ "${f}" ;;
  esac || fail_after "não criei o placeholder ${f}"
  created+=("${f}")
done
[ "${#created[@]}" = 0 ] || say "placeholders criados: ${created[*]}"

own=(-o root -g root); [ "${TEST}" = 1 ] && own=()   # na bancada quem roda não é root
priv install "${own[@]}" -m 0644 "${TMPD}/${DROPIN_NAME}" "${DROPIN_DIR}/${DROPIN_NAME}" || fail_after "não instalei o ${DROPIN_NAME}"
priv systemctl daemon-reload || fail_after "daemon-reload falhou"
OLD_INV="$(systemctl show -p InvocationID --value "${UNIT}" 2>/dev/null)"
priv systemctl restart "${UNIT}" || fail_after "systemctl restart recusou (226/NAMESPACE? journalctl -u ${UNIT})"
up=0
for _ in $(seq 1 15); do
  if grep -q '"ok":true' <<<"$(curl -fsS -m 3 "${HEALTH_LOCAL}" 2>/dev/null)"; then up=1; break; fi
  sleep 2
done
[ "${up}" = 1 ] || fail_after "/health não voltou em ~30s depois do restart"
INV="$(systemctl show -p InvocationID --value "${UNIT}" 2>/dev/null)"
[ -n "${INV}" ] && [ "${INV}" != "${OLD_INV}" ] || fail_after "a invocação não mudou (${INV:-?}): o restart não aconteceu e a prova seria do boot antigo"
BOOT=""
for _ in $(seq 1 10); do
  BOOT="$(priv journalctl "_SYSTEMD_INVOCATION_ID=${INV}" --no-pager 2>/dev/null || true)"
  grep -q "auth: enforce" <<<"${BOOT}" && break
  sleep 2
done
grep -q "auth: enforce" <<<"${BOOT}" || fail_after "boot desta invocação sem 'auth: enforce'"
verify_live || fail_after "o verify no processo vivo reprovou depois do restart"
say "OK — ${DROPIN_NAME} instalado e provado no namespace vivo (invocação ${INV:0:8}); ${#created[@]} placeholder(s) criado(s)"
rollback 2>&1 | sed 's/^/  (se precisar) /'
exit 0
