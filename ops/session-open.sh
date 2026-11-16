#!/usr/bin/env bash
# ===========================================================================
# session-open.sh — o ABRIDOR ÚNICO das sessões longas do Claude Code nesta máquina (core-only).
#
# Uso:
#   bash ops/session-open.sh <nome> [--dry-run] [--no-attach] [--resume <id>] [--mode <permission-mode>]
#   bash ops/session-open.sh --all  [--dry-run]      reabre, sem anexar, toda sessão com batuta-de-projeto (grants.tsv)
#   bash ops/session-open.sh --list                  o que existe: sessão tmux, processo claude e pasta de cada nome
#
# O padrão (D_SESSION_CAP_8_AND_TMUX_MIGRATION_1116; espiada E_PEEK_SESSION_OPENER_TMUX_1116):
#   · UMA sessão tmux por repo, com o NOME DO REPO: o mesmo nome no tmux, no `claude --name` e no grants.tsv.
#   · `tmux new-session -A`: se a sessão existe, ANEXA; se não, CRIA. Rodar duas vezes nunca abre duas.
#   · Quem tem a janela migra: este script NUNCA mata processo. Se já há um `claude` vivo naquela pasta FORA do tmux
#     pedido, ele RECUSA (rc 3) e diz o que fazer (`/exit` lá, depois rodar de novo). Duas cópias da mesma sessão
#     escrevem no mesmo histórico (incidente de 2026-11-16).
#   · O tmux NÃO sobrevive a reboot: depois de um, `--all` reabre as sessões da lista.
#
# Saída: 0 abriu/anexou/ensaiou · 2 uso ou pasta inválida · 3 recusa (processo vivo fora do tmux) · 4 tmux ou claude ausente.
# Este script só abre terminal: não lê .env, não toca serviço, não decide permissão (o modo vem de --mode, senão do
# que o Claude Code já tem configurado).
# ===========================================================================
set -uo pipefail

HOME_DIR="${SESSION_OPEN_HOME:-${HOME}}"
STATE_DIR="${BATON_STATE_DIR:-${HOME_DIR}/.local/state/onion/baton}"
PROC_DIR="${SESSION_OPEN_PROC:-/proc}"
TMUX_BIN="${SESSION_OPEN_TMUX:-tmux}"
CLAUDE_BIN="${SESSION_OPEN_CLAUDE:-claude}"

say() { printf '%s\n' "$*"; }
die() { printf 'session-open: %s\n' "$1" >&2; exit "${2:-2}"; }

NAME="" DRY=0 ATTACH=1 RESUME="" MODE="" ALL=0 LIST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --no-attach) ATTACH=0 ;;
    --all) ALL=1 ;;
    --list) LIST=1 ;;
    --resume) shift; RESUME="${1:-}"; [ -n "${RESUME}" ] || die "--resume pede o id da sessão" ;;
    --mode) shift; MODE="${1:-}"; [ -n "${MODE}" ] || die "--mode pede o modo de permissão" ;;
    -*) die "opção desconhecida: $1" ;;
    *) [ -z "${NAME}" ] || die "um nome por vez (veio «${NAME}» e «$1»)"; NAME="$1" ;;
  esac
  shift
done

# nome → pasta. O nome É o do repo; «core» é o apelido do checkout da fonte.
dir_of() {
  local n="$1"
  [ "${n}" = "core" ] && n="onion-evolve"
  printf '%s/%s' "${HOME_DIR}" "${n}"
}
valid_name() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]]; }

# pids de `claude` cujo cwd é a pasta. $2 = "out" (fora de tmux) | "any". Erro de leitura NÃO vira «nenhum»: rc 2.
claude_pids() {
  local dir="$1" want="$2" p comm cwd env out=""
  [ -d "${PROC_DIR}" ] || return 2
  for p in "${PROC_DIR}"/[0-9]*; do
    [ -r "${p}/comm" ] || continue
    comm="$(cat "${p}/comm" 2>/dev/null)" || continue
    [ "${comm}" = "claude" ] || continue
    cwd="$(readlink "${p}/cwd" 2>/dev/null)" || return 2
    [ "${cwd}" = "${dir}" ] || continue
    if [ "${want}" = "out" ]; then
      env="$(tr '\0' '\n' < "${p}/environ" 2>/dev/null)" || return 2
      grep -q '^TMUX=' <<< "${env}" && continue
    fi
    out="${out}${p##*/} "
  done
  printf '%s' "${out% }"
}

has_tmux_session() { "${TMUX_BIN}" has-session -t "=$1" 2>/dev/null; }

open_one() {  # $1 = nome, $2 = anexar (1|0)
  local n="$1" attach="$2" dir cmd out rc
  valid_name "${n}" || die "nome inválido: «${n}» (letras, dígitos, ponto, hífen e sublinhado)"
  dir="$(dir_of "${n}")"
  [ -d "${dir}/.git" ] || [ -f "${dir}/.git" ] || die "«${dir}» não é um repositório git: o nome da sessão é o nome do repo em ${HOME_DIR}"
  [ "${n}" = "core" ] && n="onion-evolve"

  if has_tmux_session "${n}"; then
    say "session-open: a sessão tmux «${n}» já existe — anexo, não crio outra."
    # a sessão tmux existe, mas pode haver OUTRA cópia fora dela (aberta à mão num terminal): avisa, não mata
    out="$(claude_pids "${dir}" out)" || out=""
    [ -z "${out}" ] || say "session-open: ⚠️ há também um claude em ${dir} FORA do tmux (pid ${out}): se for a mesma sessão, dê /exit lá e fique só com a do tmux."
  else
    out="$(claude_pids "${dir}" out)"; rc=$?
    [ "${rc}" -eq 0 ] || die "não li ${PROC_DIR} para saber se já há um claude em ${dir}: não abro às cegas" 3
    if [ -n "${out}" ]; then
      die "já há um claude vivo em ${dir} FORA do tmux (pid ${out}). Abrir outro duplica a sessão no mesmo histórico. Vá à janela dele, dê /exit, e rode este comando de novo." 3
    fi
    cmd="${CLAUDE_BIN} --name ${n}"
    if [ -n "${RESUME}" ]; then cmd="${cmd} --resume ${RESUME}"; else cmd="${cmd} --continue"; fi
    [ -n "${MODE}" ] && cmd="${cmd} --permission-mode ${MODE}"
    # o canal da campainha só entra onde o repo a declara
    if [ -f "${dir}/.mcp.json" ] && grep -q '"doorbell"' "${dir}/.mcp.json"; then
      cmd="${cmd} --dangerously-load-development-channels server:doorbell"
    fi
    if [ "${DRY}" -eq 1 ]; then
      say "ensaio: ${TMUX_BIN} new-session -d -s ${n} -c ${dir} '${cmd}'"
    else
      "${TMUX_BIN}" new-session -d -s "${n}" -c "${dir}" "${cmd}" || die "o tmux não criou a sessão «${n}»" 4
      say "session-open: criada a sessão tmux «${n}» em ${dir}."
    fi
  fi

  [ "${attach}" -eq 1 ] || { say "session-open: para entrar: ${TMUX_BIN} attach -t ${n}"; return 0; }
  if [ "${DRY}" -eq 1 ]; then say "ensaio: ${TMUX_BIN} attach -t ${n}"; return 0; fi
  if [ -n "${TMUX:-}" ]; then "${TMUX_BIN}" switch-client -t "=${n}"; else "${TMUX_BIN}" attach -t "=${n}"; fi
}

roster() {  # nomes com batuta-de-projeto = sim, que TÊM pasta (uma linha por repo)
  local f="${STATE_DIR}/grants.tsv" k c g _
  [ -r "${f}" ] || die "não li ${f}: sem a lista de concessões não sei o que reabrir" 2
  while IFS=$'\t' read -r k c g _; do
    case "${k}" in ''|'#'*) continue ;; esac
    case "$(tr '[:upper:]' '[:lower:]' <<< "${g:-}")" in sim|yes|true|1) ;; *) continue ;; esac
    valid_name "${k}" || continue
    [ -d "$(dir_of "${k}")/.git" ] || [ -f "$(dir_of "${k}")/.git" ] || continue
    printf '%s\n' "${k}"
  done < "${f}" | sort -u
}

command -v "${TMUX_BIN}" >/dev/null 2>&1 || die "tmux ausente (${TMUX_BIN})" 4
[ "${DRY}" -eq 1 ] || command -v "${CLAUDE_BIN}" >/dev/null 2>&1 || die "claude ausente (${CLAUDE_BIN})" 4

if [ "${LIST}" -eq 1 ]; then
  names="$(roster)" || exit $?
  printf '%-22s %-8s %-18s %s\n' "nome" "tmux" "claude (pid)" "pasta"
  while IFS= read -r n; do
    [ -n "${n}" ] || continue
    d="$(dir_of "${n}")"
    if has_tmux_session "${n}"; then t="sim"; else t="não"; fi
    p="$(claude_pids "${d}" any)" || p="NÃO MEDIDO"
    printf '%-22s %-8s %-18s %s\n' "${n}" "${t}" "${p:--}" "${d}"
  done <<< "${names}"
  exit 0
fi

if [ "${ALL}" -eq 1 ]; then
  [ -z "${NAME}" ] || die "--all não leva nome"
  names="$(roster)" || exit $?
  [ -n "${names}" ] || die "nenhuma sessão com batuta-de-projeto e pasta em ${STATE_DIR}/grants.tsv" 2
  worst=0
  while IFS= read -r n; do
    [ -n "${n}" ] || continue
    ( open_one "${n}" 0 ); r=$?
    [ "${r}" -gt "${worst}" ] && worst="${r}"
  done <<< "${names}"
  exit "${worst}"
fi

[ -n "${NAME}" ] || die "uso: session-open.sh <nome> [--dry-run] [--no-attach] [--resume <id>] [--mode <modo>] | --all | --list"
open_one "${NAME}" "${ATTACH}"
