#!/usr/bin/env bash
# Backup CIFRADO da raiz de dados do onion-kg-writer (MCP de escrita de KG do chat da casa), no molde do
# ops/bridge-backup.sh: tar da origem, conferência do que saiu, cifra para a chave do cofre de senhas, destino 0700
# com arquivo 0600 e retenção só dos diários.
#
# POR QUE EXISTE (2026-11-17): o único backup da raiz era o tar pré-deploy do ops/update-kg-writer.sh, que saía EM
# CLARO (`.tar.gz`) e só rodava em deploy. Cada área da raiz é um repositório git LOCAL, sem remoto: o que não está
# num backup não está em lugar nenhum. Este script é o caminho único dos dois usos: o diário (agendado pelo maestro)
# e o pré-deploy (o update-kg-writer.sh o chama com o rótulo `pre-<sha>`).
#
# O QUE ELE FAZ (nesta ordem; qualquer falha sai com rc ≠ 0 e não deixa nada com o nome final no destino):
#   1. valida o rótulo, resolve o dono da chave e lê os destinatários (antes de qualquer escrita)
#   2. tar da raiz inteira (as áreas e o .git de cada uma) para um temporário 0600 num diretório 0700
#   3. conferência do tar: lista inteira, a raiz presente e ao menos um <área>/.git/HEAD
#   4. cifra COMO o dono da chave (o chaveiro do root é vazio), para um nome provisório dentro do destino
#   5. conferência do .gpg pela SAÍDA do --list-packets (`pubkey enc packet`), nunca pelo rc: sem a chave privada
#      destravada o rc é 2, e isso é o esperado
#   6. modo 0600 conferido, e só então o arquivo ganha o nome final
#   7. retenção: só o rótulo `daily`, os ONION_KG_BACKUP_KEEP mais novos; os rotulados (pre-*) ficam todos
# O temporário em claro é triturado na saída, também quando o script falha no meio (trap de EXIT).
#
# QUEM ESCREVE ONDE (a lição do bridge-backup.sh, 2026-11-13): como root, o root só LÊ a origem. Tudo o que toca o
# destino (criar, cifrar, conferir, renomear, apagar na retenção) e a leitura do arquivo de destinatários roda como
# o dono, que só escreve no que já é dele. Root escrevendo no diretório de outro usuário é escalada por symlink.
#
# TETOS DECLARADOS:
#   · mesmo disco: não é cópia fora da máquina;
#   · roda com o serviço de pé: o tar não é instantâneo atômico (README do serviço, seção do backup);
#   · as mensagens não trazem conteúdo, destinatário nem a saída do tar e do gpg (os nomes das áreas derivam de
#     e-mail). Para diagnosticar uma falha, rode o passo à mão.
#
# Variáveis (todas opcionais; nenhuma tem padrão que aponte para uma pessoa):
#   ONION_KG_BACKUP_OWNER        dono da chave e do destino. Padrão: quem roda; como root, o SUDO_USER; sem um nem
#                                outro, erro
#   ONION_KG_BACKUP_OWNER_HOME   home do dono. Padrão: a do passwd (getent)
#   ONION_KG_BACKUP_DATA         raiz de dados. Padrão: ONION_KG_WRITER_ROOT, senão /var/lib/onion-chat-kg
#   ONION_KG_BACKUP_DEST         destino. Padrão: <home do dono>/backups/onion-chat-kg
#   ONION_KG_BACKUP_GPG_ID_FILE  arquivo com os destinatários, um por linha. Padrão: <home>/.password-store/.gpg-id
#   ONION_KG_BACKUP_KEEP         diários mantidos. Padrão: 14
#   ONION_KG_BACKUP_TAR | _GPG | _SUDO | _SHRED | _ID   os binários (a bancada os troca por dublês)
#
# Uso: ops/kg-writer-backup.sh [rótulo]   (padrão: daily; só [a-z0-9-], até 32 caracteres)
# Saída: o caminho do .gpg, sozinho, no stdout; o resto vai para o stderr.
set -Eeuo pipefail
export LC_ALL=C
umask 077

SELF=kg-writer-backup
PREFIX=onion-chat-kg
say() { printf '[%s] %s\n' "${SELF}" "$*" >&2; }
die() { printf '[%s] ERRO: %s\n' "${SELF}" "$*" >&2; exit 1; }

TAR="${ONION_KG_BACKUP_TAR:-tar}"
GPG="${ONION_KG_BACKUP_GPG:-gpg}"
SUDO="${ONION_KG_BACKUP_SUDO:-sudo}"
SHRED="${ONION_KG_BACKUP_SHRED:-shred}"
ID="${ONION_KG_BACKUP_ID:-id}"
DATA="${ONION_KG_BACKUP_DATA:-${ONION_KG_WRITER_ROOT:-/var/lib/onion-chat-kg}}"
KEEP="${ONION_KG_BACKUP_KEEP:-14}"
DAILY_RE="^${PREFIX}-daily-[0-9]{8}-[0-9]{6}\.tar\.gz\.gpg$"

WORK=""; PART=""; OWNER=""; UID_NOW=""; USER_NOW=""

as_root() { if [ "${UID_NOW}" -eq 0 ]; then "$@"; else "${SUDO}" -- "$@"; fi; }
as_owner() { if [ "${USER_NOW}" = "${OWNER}" ]; then "$@"; else "${SUDO}" -n -u "${OWNER}" -H -- "$@"; fi; }

# tritura um arquivo; se o shred falhar, ao menos o nome some (e o aviso fica)
wipe() {  # wipe <como: self|owner> <arquivo>
  local how="$1" f="$2"
  if [ "${how}" = owner ]; then
    as_owner test -e "${f}" 2>/dev/null || return 0
    as_owner "${SHRED}" -u -- "${f}" 2>/dev/null || { as_owner rm -f -- "${f}" 2>/dev/null || true; say "AVISO: o shred falhou; arquivo removido sem trituração"; }
  else
    [ -e "${f}" ] || return 0
    "${SHRED}" -u -- "${f}" 2>/dev/null || { rm -f -- "${f}" 2>/dev/null || true; say "AVISO: o shred falhou; temporário removido sem trituração"; }
  fi
}

cleanup() {
  local rc=$? f
  trap - EXIT
  set +e
  if [ -n "${PART}" ]; then wipe owner "${PART}"; fi
  if [ -n "${WORK}" ] && [ -d "${WORK}" ]; then
    while IFS= read -r -d '' f; do wipe self "${f}"; done < <(find "${WORK}" -type f -print0 2>/dev/null)
    rmdir -- "${WORK}" 2>/dev/null || say "AVISO: o diretório temporário não ficou vazio"
  fi
  exit "${rc}"
}

# ── 1. rótulo, dono, destinatários: tudo antes de qualquer escrita ────────────────────────────
[ "$#" -le 1 ] || die "uso: ${SELF}.sh [rótulo]"
LABEL="${1-daily}"
case "${LABEL}" in
  ''|-*|*-|*[!a-z0-9-]*) die "rótulo inválido: só [a-z0-9-], sem hífen na ponta, até 32 caracteres" ;;
esac
[ "${#LABEL}" -le 32 ] || die "rótulo inválido: só [a-z0-9-], sem hífen na ponta, até 32 caracteres"
case "${KEEP}" in ''|*[!0-9]*|0*) die "ONION_KG_BACKUP_KEEP tem de ser um inteiro ≥ 1" ;; esac

UID_NOW="$("${ID}" -u)" || die "não consegui ler o uid de quem roda"
USER_NOW="$("${ID}" -un)" || die "não consegui ler o nome de quem roda"
case "${UID_NOW}" in ''|*[!0-9]*) die "uid de quem roda fora da forma" ;; esac

OWNER="${ONION_KG_BACKUP_OWNER:-}"
if [ -z "${OWNER}" ]; then
  if [ "${UID_NOW}" -ne 0 ]; then OWNER="${USER_NOW}"
  elif [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != root ]; then OWNER="${SUDO_USER}"
  else die "sem dono da chave: como root e sem SUDO_USER, defina ONION_KG_BACKUP_OWNER"; fi
fi
case "${OWNER}" in ''|-*|*[!A-Za-z0-9_.-]*) die "dono da chave fora da forma de nome de usuário" ;; esac

if [ -z "${ONION_KG_BACKUP_DEST:-}" ] || [ -z "${ONION_KG_BACKUP_GPG_ID_FILE:-}" ]; then
  OWNER_HOME="${ONION_KG_BACKUP_OWNER_HOME:-}"
  if [ -z "${OWNER_HOME}" ]; then
    OWNER_HOME="$(getent passwd "${OWNER}" 2>/dev/null | cut -d: -f6)" || OWNER_HOME=""
  fi
  case "${OWNER_HOME}" in /*) ;; *) die "não achei a home do dono: defina ONION_KG_BACKUP_OWNER_HOME, ou o destino e o arquivo de destinatários" ;; esac
fi
DEST="${ONION_KG_BACKUP_DEST:-${OWNER_HOME:-}/backups/${PREFIX}}"
GPG_ID_FILE="${ONION_KG_BACKUP_GPG_ID_FILE:-${OWNER_HOME:-}/.password-store/.gpg-id}"
case "${DEST}" in /*) ;; *) die "o destino tem de ser caminho absoluto" ;; esac
case "${DATA}" in /*) ;; *) die "a raiz de dados tem de ser caminho absoluto" ;; esac

[ ! -L "${DATA}" ] || die "a raiz de dados é link simbólico: recuso"
[ -d "${DATA}" ] || die "não achei a raiz de dados"
DATA_BASE="$(basename "${DATA}")"; DATA_PARENT="$(dirname "${DATA}")"

RCPT=()
ids="$(as_owner cat -- "${GPG_ID_FILE}" 2>/dev/null)" || die "não consegui ler o arquivo de destinatários como o dono da chave"
while IFS= read -r line; do
  [ -n "${line}" ] || continue
  case "${line}" in -*|*[[:cntrl:]]*) die "destinatário fora da forma no arquivo de destinatários" ;; esac
  RCPT+=(-r "${line}")
done <<< "${ids}"
[ "${#RCPT[@]}" -gt 0 ] || die "o arquivo de destinatários veio vazio: sem chave não gravo nada"

# ── a partir daqui há escrita: o trap tritura o claro em qualquer saída ───────────────────────
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if as_owner test -L "${DEST}"; then die "o destino é link simbólico: recuso"; fi
as_owner install -d -m 700 -- "${DEST}" || die "não consegui criar o destino como o dono"
as_owner test -d "${DEST}" || die "o destino não é diretório"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/onion-kg-backup.XXXXXX")" || die "mktemp falhou"
CLEAR="${WORK}/${PREFIX}.tar.gz"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${DEST}/${PREFIX}-${LABEL}-${STAMP}.tar.gz.gpg"

# ── 2. o tar da raiz inteira; o stderr do tar não é repassado (traz nome de área) ─────────────
make_clear() {
  local rc=0
  as_root "${TAR}" -C "${DATA_PARENT}" -czf - "${DATA_BASE}" > "${CLEAR}" 2>/dev/null || rc=$?
  [ "${rc}" -eq 0 ] || die "o tar falhou (rc ${rc}; rc 1 costuma ser arquivo que mudou durante a leitura, ou sudo recusado)"
  [ -s "${CLEAR}" ] || die "o tar saiu vazio"
}

# ── 3. o tar se lista inteiro, tem a raiz e ao menos uma área com .git ────────────────────────
#    (here-string, não pipe: sob pipefail o `grep -q` que sai cedo mata o emissor por SIGPIPE e o rc mente)
verify_clear() {
  local list
  list="$("${TAR}" -tzf "${CLEAR}" 2>/dev/null)" || die "o tar não se lista (ilegível)"
  grep -qxF -- "${DATA_BASE}/" <<< "${list}" || die "o tar não tem a raiz de dados"
  grep -qE '^[^/]+/[^/]+/\.git/HEAD$' <<< "${list}" || die "o tar não tem nenhuma área com .git/HEAD: recuso cifrar"
}

# ── 4. cifra como o dono; o claro entra pelo stdin (o dono não precisa ler o temporário) ──────
encrypt() {
  local rc=0
  PART="${DEST}/.${PREFIX}-${LABEL}-${STAMP}.$$.partial"
  as_owner "${GPG}" --batch --yes --trust-model always "${RCPT[@]}" -o "${PART}" -e < "${CLEAR}" 2>/dev/null || rc=$?
  [ "${rc}" -eq 0 ] || die "a cifra falhou (rc ${rc})"
  as_owner test -s "${PART}" || die "o .gpg saiu vazio"
}

# ── 5. o .gpg é OpenPGP endereçado a chave pública: pela SAÍDA, não pelo rc ───────────────────
verify_cipher() {
  local pkts
  pkts="$(as_owner "${GPG}" --batch --list-packets "${PART}" 2>/dev/null || true)"
  case "${pkts}" in
    *"pubkey enc packet"*) return 0 ;;
  esac
  die "o .gpg não é OpenPGP endereçado a chave pública: apagado"
}

# ── 6. modo conferido, e só então o nome final ────────────────────────────────────────────────
publish() {
  local meta
  as_owner chmod 600 -- "${PART}" || die "chmod 600 falhou"
  meta="$(as_owner stat -c '%a %s' -- "${PART}")" || die "não consegui conferir o .gpg"
  [ "${meta%% *}" = 600 ] || die "o .gpg não ficou em modo 600"
  [ "${meta##* }" -gt 0 ] || die "o .gpg saiu vazio"
  if as_owner test -e "${OUT}"; then die "já existe um backup com este rótulo neste segundo: recuso sobrescrever"; fi
  as_owner mv -n -- "${PART}" "${OUT}" || die "não consegui dar o nome final ao .gpg"
  as_owner test -f "${OUT}" || die "o .gpg não chegou ao nome final"
  PART=""
  say "backup pronto: ${meta##* } bytes, modo 600"
  printf '%s\n' "${OUT}"
}

# ── 7. retenção: só arquivo regular, só dentro do destino, só o nome exato do diário ──────────
rotate() {
  local names="${WORK}/names" n i drop daily=()
  as_owner find "${DEST}" -maxdepth 1 -type f -printf '%f\0' > "${names}" 2>/dev/null || die "backup pronto, mas a listagem da retenção falhou"
  while IFS= read -r -d '' n; do
    if [[ "${n}" =~ ${DAILY_RE} ]]; then daily+=("${n}"); fi
  done < <(sort -z -- "${names}")
  drop=$(( ${#daily[@]} - KEEP ))
  for (( i = 0; i < drop; i++ )); do
    as_owner rm -f -- "${DEST}/${daily[i]}" || die "backup pronto, mas a retenção não conseguiu apagar um diário antigo"
  done
  if [ "${drop}" -gt 0 ]; then say "retenção: ${drop} diário(s) antigo(s) apagado(s), ${KEEP} mantido(s)"; fi
}

make_clear
verify_clear
encrypt
verify_cipher
publish
if [ "${LABEL}" = daily ]; then rotate; fi
