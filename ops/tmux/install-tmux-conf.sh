#!/usr/bin/env bash
# ===========================================================================
# install-tmux-conf.sh — instala a config do tmux da casa (ops/tmux/onion.tmux.conf) para o usuário
# (core-only; chamado por `onion-attach --install-tmux`).
#
# Pedido do maestro (2026-11-25): «toda ferramenta adotada vem com guia, grafo e configuração versionada».
# Como instala (revisão isolada de 25/11): a config é COPIADA para um caminho estável FORA do repo,
# ~/.config/onion/tmux.conf, e o ~/.tmux.conf ganha UMA linha `source-file -q ~/.config/onion/tmux.conf`.
# O tmux NUNCA lê do checkout: trocar de branch (ou um PR que mexa na config) mudaria a config viva, e config de
# tmux pode rodar comando (run-shell). Atualizar é rodar o instalador de novo, que é um ato.
#   · A cópia que já existe e difere vai para um backup datado antes de ser trocada; depois da cópia, o conteúdo é
#     conferido (cmp) contra o do repo.
#   · No ~/.tmux.conf nada é sobrescrito nem apagado: só se acrescenta a linha que falta. Rodar de novo não muda nada.
#
# Uso:
#   install-tmux-conf.sh            instala (cópia + linha) e recarrega a cópia em cada servidor tmux vivo
#   install-tmux-conf.sh --check    só mede: rc 0 a linha está lá e a cópia é igual à do repo · 1 algo falta (dito)
#   install-tmux-conf.sh --dry-run  diz o que faria
#
# Recusas (rc 3): o ~/.tmux.conf, a pasta ~/.config/onion ou a cópia é um link (escrever nele mexeria no destino, ex. um repo de dotfiles);
# backup, cópia ou conferência falhos; o source-file falhou num servidor vivo (nomeado).
# Saída: 0 ok/presente · 1 (--check) falta · 2 uso ou config ausente · 3 recusa ou falha nomeada.
# Ambiente: ONION_TMUX_CONF (a config do repo), ONION_TMUX_BIN (tmux), ONION_TMUX_SOCKDIR (sockets dos servidores).
# Bancada: run_onion_attach_selftests, casos (t1) a (t10) (lint-selftest.sh).
# ===========================================================================
set -uo pipefail

SELF_DIR="$(dirname "$(readlink -f -- "${BASH_SOURCE[0]}")")"
CONF="${ONION_TMUX_CONF:-${SELF_DIR}/onion.tmux.conf}"
TMUX_BIN="${ONION_TMUX_BIN:-tmux}"
SOCK_DIR="${ONION_TMUX_SOCKDIR:-${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)}"
DST="${HOME}/.tmux.conf"
COPY_DIR="${HOME}/.config/onion"
COPY="${COPY_DIR}/tmux.conf"
# a linha usa ~ (o tmux o expande pelo HOME de quem abre o servidor): a mesma linha vale em qualquer conta
LINE="source-file -q ~/.config/onion/tmux.conf"

say() { printf '%s\n' "$*"; }
die() { printf 'install-tmux-conf: %s\n' "$1" >&2; exit "${2:-2}"; }

MODE=install
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE=check ;;
    --dry-run) MODE=dry ;;
    -h|--help) sed -n '/^# Uso:/,/^# Saída/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "opção desconhecida: $1" ;;
  esac
  shift
done
[ -f "${CONF}" ] || die "config da casa ausente: ${CONF}" 2

# a linha já está lá? (espaços em volta não contam; a forma com o caminho absoluto também vale)
has_line() {
  [ -f "${DST}" ] || return 1
  awk -v a="${LINE}" -v b="source-file -q ${COPY}" '{ sub(/^[ \t]+/, ""); sub(/[ \t]+$/, "") } $0 == a || $0 == b { f = 1 } END { exit !f }' "${DST}"
}
copy_current() { [ -f "${COPY}" ] && [ ! -L "${COPY}" ] && cmp -s -- "${CONF}" "${COPY}"; }

if [ "${MODE}" = check ]; then
  miss=""
  copy_current || miss="${miss} a cópia ${COPY} não existe ou difere da do repo;"
  has_line || miss="${miss} o ${DST} não tem a linha «${LINE}»;"
  if [ -z "${miss}" ]; then say "install-tmux-conf: presente — ${DST} lê ${COPY}, igual à config do repo."; exit 0; fi
  say "install-tmux-conf: FALTA —${miss% ;} Rode: onion-attach --install-tmux"; exit 1
fi

for f in "${DST}" "${COPY_DIR}" "${COPY}"; do
  [ ! -L "${f}" ] || die "${f} é um link (→ $(readlink -- "${f}")): não escrevo através dele. Resolva o link à mão e rode de novo." 3
done

# 1. a cópia estável, fora do repo
if copy_current; then
  say "install-tmux-conf: ${COPY} já é igual à config do repo."
elif [ "${MODE}" = dry ]; then
  [ ! -e "${COPY}" ] || say "ensaio: backup de ${COPY} em ${COPY}.bak-<data>"
  say "ensaio: copiar ${CONF} para ${COPY}"
else
  mkdir -p -- "${COPY_DIR}" || die "não criei ${COPY_DIR}" 3
  if [ -e "${COPY}" ]; then
    bak="${COPY}.bak-$(date -u +%Y%m%dT%H%M%SZ)"
    [ ! -e "${bak}" ] || die "o backup ${bak} já existe: não sobrescrevo; rode de novo daqui a um segundo" 3
    cp -p -- "${COPY}" "${bak}" || die "não fiz o backup ${bak}: nada foi trocado" 3
    say "install-tmux-conf: backup da cópia anterior: ${bak}"
  fi
  cp -- "${CONF}" "${COPY}" || die "não copiei a config para ${COPY}" 3
  cmp -s -- "${CONF}" "${COPY}" || die "a cópia ${COPY} não confere com ${CONF}" 3
  say "install-tmux-conf: config copiada e conferida: ${COPY}"
fi

# 2. a linha no ~/.tmux.conf: só se acrescenta, o resto fica como estava
if has_line; then
  say "install-tmux-conf: ${DST} já lê ${COPY}; nada a acrescentar."
elif [ "${MODE}" = dry ]; then
  say "ensaio: acrescentar a ${DST}: ${LINE}"
else
  if [ -s "${DST}" ] && [ "$(tail -c1 -- "${DST}" | od -An -c | tr -d ' ')" != '\n' ]; then printf '\n' >> "${DST}" || die "não escrevi em ${DST}" 3; fi
  printf '\n# Onion: a config do tmux da casa, copiada do repo (onion-attach --install-tmux)\n%s\n' "${LINE}" >> "${DST}" \
    || die "não escrevi em ${DST}" 3
  say "install-tmux-conf: acrescentada a ${DST}: ${LINE}"
fi

# 3. recarrega a cópia em cada servidor vivo; o que falha é DITO e muda o rc, nunca some
bad=0 n=0
for s in "${SOCK_DIR}"/*; do
  [ -S "${s}" ] || continue
  srv="${s##*/}"
  "${TMUX_BIN}" -L "${srv}" ls >/dev/null 2>&1 || { say "install-tmux-conf: servidor «${srv}»: sem tmux vivo no socket, pulado."; continue; }
  n=$((n + 1))
  if [ "${MODE}" = dry ]; then say "ensaio: ${TMUX_BIN} -L ${srv} source-file ${COPY}"; continue; fi
  if "${TMUX_BIN}" -L "${srv}" source-file "${COPY}" 2>/dev/null; then
    say "install-tmux-conf: servidor «${srv}»: config recarregada (rolagem e tipo de terminal valem nos painéis novos)."
  else say "install-tmux-conf: ⚠️ servidor «${srv}»: o source-file falhou; a config vale nas sessões novas desse servidor." >&2; bad=1; fi
done
[ "${n}" -gt 0 ] || say "install-tmux-conf: nenhum servidor tmux vivo: a config vale no próximo que abrir."
exit "$([ "${bad}" -eq 0 ] && echo 0 || echo 3)"
