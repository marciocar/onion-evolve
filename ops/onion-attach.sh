#!/usr/bin/env bash
# ===========================================================================
# onion-attach.sh — ENTRA numa sessão do Claude Code pelo NOME, ache-se ela onde se achar (core-only).
#
# Pedido do maestro (2026-11-25): ele não sabe quando usar `tmux -L` (desde 2026-11-22 cada sessão aberta pelo
# ops/session-open.sh vive no PRÓPRIO servidor tmux; as antigas ficam no `default`) e, quando a sessão saiu, não sabe o
# id para o `--resume`. Em 2026-11-25 o maestro voltou o padrão ao SERVIDOR ÚNICO (a queda de 22/11 foi falta de
# memória, não isolamento do tmux); as sessões em servidor próprio migram no próximo reinício, e este atalho cobre as
# duas topologias enquanto convivem. Ele acha sozinho:
#   1. TMUX — varre os sockets de ${TMUX_TMPDIR:-/tmp}/tmux-<uid>/ (`tmux -L <servidor> has-session`). Achou num só:
#      fora do tmux, `tmux -L <servidor> attach`; dentro do MESMO servidor, `switch-client`; dentro de OUTRO servidor,
#      `detach-client -E "<attach do alvo>"`: o cliente atual vira o attach do alvo no mesmo terminal, sem tmux
#      aninhado. As duas trocas só com UM terminal anexado à sessão atual (com dois, o tmux poderia levar o outro):
#      senão, rc 3 com o caminho manual. Achou em dois servidores: ambíguo, lista e para.
#   2. FUNDO NATIVO — `claude agents --json`, `kind: background` com o nome e VIVA: `claude attach <id>` (de dentro
#      do tmux, no próprio painel: ninguém é desanexado). A regra de
#      «viva» é a do helper único .claude/utils/orchestration/session-liveness.sh quando ele existe nesta árvore (PR
#      #1761); sem ele, a MESMA regra copiada aqui (pid morto → morta; interativa → viva; pid vivo → viva; sem pid →
#      morta). Quando o #1761 entrar, o ramo local deixa de rodar sozinho: o helper é achado e vence.
#   3. FECHADA — a conversa pelo TÍTULO (`customTitle`), pelo ops/session-transcript.sh: a mais recente, com o id e a
#      pasta onde nasceu, reaberta por `ops/session-open.sh <nome> --resume <id> --dir <pasta>` (o abridor único, com as
#      recusas dele: nunca duas no checkout, id vivo noutro lugar). AMBÍGUO, lista com data e NÃO escolhe: as duas
#      conversas mais recentes mudaram com menos de ${ONION_ATTACH_AMBIG_SECS:-120} s de diferença (duas sessões vivas
#      com o mesmo nome), ou nasceram em PASTAS diferentes (o mesmo nome em dois repos). Conversas mais antigas na mesma
#      pasta são o histórico de reinícios, ditas, não ambiguidade. Para escolher outra: --resume <id>.
#
# Uso:
#   onion-attach                       lista as sessões: nome, onde está, se está viva e o comando exato para entrar
#   onion-attach <nome> [--dry-run]    entra (ou reabre) a sessão; --dry-run só diz o que faria
#   onion-attach <nome> --resume <id>  reabre aquela conversa (a escolha depois de um «ambíguo»)
#   onion-attach --install [--dry-run] cria o link ~/.local/bin/onion-attach e confere que ~/.local/bin está no PATH
#   onion-attach --install-tmux [--dry-run|--check]
#                                      liga a config da casa (ops/tmux/onion.tmux.conf) ao ~/.tmux.conf por uma linha
#                                      source-file, sem sobrescrever nada, e a recarrega em cada servidor vivo
#                                      (pelo ops/tmux/install-tmux-conf.sh; --check só mede)
#
# Saída: 0 entrou/listou/ensaiou · 2 uso · 3 não entra daqui (interativa fora do tmux, mais de um terminal na sessão
# tmux atual, link
# alheio no --install; no --install-tmux, as recusas do instalador) · 4 tmux
# ou claude ausente · 5 nada achado, ou ambíguo. Na reabertura, o rc é o do session-open.
# Para achar e entrar, só lê o estado: `tmux -L <s> ls|has-session` e `claude agents --json`. Escreve só nas instalações
# (o link em ~/.local/bin; uma linha a mais no ~/.tmux.conf e o source-file nos servidores vivos). Nunca mata nada, nunca para sessão.
# Bancada: run_onion_attach_selftests (lint-selftest.sh).
# ===========================================================================
set -uo pipefail

SELF="$(readlink -f -- "${BASH_SOURCE[0]}")"
OPS_DIR="$(dirname "${SELF}")"
ROOT_DIR="$(dirname "${OPS_DIR}")"
TMUX_BIN="${ONION_ATTACH_TMUX:-tmux}"
CLAUDE_BIN="${ONION_ATTACH_CLAUDE:-claude}"
SOCK_DIR="${ONION_ATTACH_SOCKDIR:-${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)}"
PROJECTS_DIR="${ONION_ATTACH_PROJECTS:-${HOME}/.claude/projects}"
SESSION_OPEN="${ONION_ATTACH_SESSION_OPEN:-${OPS_DIR}/session-open.sh}"
TRANSCRIPT="${ONION_ATTACH_TRANSCRIPT:-${OPS_DIR}/session-transcript.sh}"
LIVENESS="${ONION_ATTACH_LIVENESS:-${ROOT_DIR}/.claude/utils/orchestration/session-liveness.sh}"
BIN_DIR="${ONION_ATTACH_BIN_DIR:-${HOME}/.local/bin}"
TMUX_INSTALLER="${ONION_ATTACH_TMUX_INSTALLER:-${OPS_DIR}/tmux/install-tmux-conf.sh}"
AMBIG_SECS="${ONION_ATTACH_AMBIG_SECS:-120}"

say() { printf '%s\n' "$*"; }
die() { printf 'onion-attach: %s\n' "$1" >&2; exit "${2:-2}"; }

NAME="" DRY=0 RESUME="" INSTALL=0 INSTALL_TMUX=0 CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --install) INSTALL=1 ;;
    --install-tmux) INSTALL_TMUX=1 ;;
    --check) CHECK=1 ;;
    --resume) shift; RESUME="${1:-}"; [ -n "${RESUME}" ] || die "--resume pede o id da conversa" ;;
    -h|--help) sed -n '/^# Uso:/,/^# Saída/p' "${SELF}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "opção desconhecida: $1" ;;
    *) [ -z "${NAME}" ] || die "um nome por vez (veio «${NAME}» e «$1»)"; NAME="$1" ;;
  esac
  shift
done
[ -z "${NAME}" ] || [[ "${NAME}" =~ ^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$ ]] || die "nome inválido: «${NAME}»"
[ -z "${RESUME}" ] || [[ "${RESUME}" =~ ^[A-Za-z0-9][A-Za-z0-9-]{7,63}$ ]] || die "id inválido: «${RESUME}»"
[ -z "${RESUME}" ] || [ -n "${NAME}" ] || die "--resume pede o nome da sessão junto"
[ "${INSTALL}" -eq 0 ] || [ "${INSTALL_TMUX}" -eq 0 ] || die "--install e --install-tmux se rodam um de cada vez"
[ "${CHECK}" -eq 0 ] || [ "${INSTALL_TMUX}" -eq 1 ] || die "--check só vale com --install-tmux"

# roda o comando, ou só o diz no ensaio. exec: o terminal passa a ser o da sessão
run() { if [ "${DRY}" -eq 1 ]; then say "ensaio: $*"; exit 0; fi; exec "$@"; }
# citação para o shell que o tmux usa no detach-client -E (POSIX: aspas simples, a aspa interna fechada e escapada);
# o nome do servidor vem do diretório de sockets e o id vem do harness: dado, nunca código
sq() { local v="$1"; printf "'%s'" "${v//\'/\'\\\'\'}"; }
# switch-client e detach-client sem -t/-c agem no cliente «mais ativo» da sessão, não necessariamente em quem chamou
# (medido pela revisão isolada de 25/11 com dois clientes reais: PC e celular). Só se troca com UM terminal anexado à
# sessão atual; com mais de um, ou sem conseguir contar, recusa (rc 3) e diz o caminho manual.
one_client_or_refuse() {  # $1 = socket do servidor atual
  local cs n
  cs="$("${TMUX_BIN}" -S "$1" display-message -p -t "${TMUX_PANE:-}" '#{session_name}' 2>/dev/null)" && [ -n "${cs}" ] \
    || die "não li a sessão tmux atual: não troco às cegas. Saia com Ctrl-b d e rode: onion-attach ${NAME}" 3
  n="$("${TMUX_BIN}" -S "$1" list-clients -t "=${cs}" 2>/dev/null | grep -c .)" \
    || die "não li os terminais anexados à sessão «${cs}»: não troco às cegas. Saia com Ctrl-b d e rode: onion-attach ${NAME}" 3
  [ "${n}" -le 1 ] || die "há ${n} terminais nesta sessão («${cs}»); a troca poderia levar o outro terminal, não este. Saia com Ctrl-b d e rode: onion-attach ${NAME}" 3
}
fmt_date() { date -u -d "@$1" +%Y-%m-%dT%H:%MZ 2>/dev/null || printf '%s' "$1"; }

# ── instalação ────────────────────────────────────────────────────────────────────────────────────
if [ "${INSTALL}" -eq 1 ]; then
  [ -z "${NAME}" ] || die "--install não leva nome"
  link="${BIN_DIR}/onion-attach"
  if [ -L "${link}" ] && [ "$(readlink -f -- "${link}")" = "${SELF}" ]; then say "onion-attach: o link já existe: ${link} → ${SELF}"
  elif [ -e "${link}" ] || [ -L "${link}" ]; then
    die "${link} já existe e não aponta para ${SELF}: não sobrescrevo; confira o que é e remova à mão se for velho" 3
  elif [ "${DRY}" -eq 1 ]; then say "ensaio: mkdir -p ${BIN_DIR} && ln -s ${SELF} ${link}"
  else
    mkdir -p -- "${BIN_DIR}" || die "não criei ${BIN_DIR}" 3
    ln -s -- "${SELF}" "${link}" || die "não criei o link ${link}" 3
    say "onion-attach: link criado: ${link} → ${SELF}"
  fi
  case ":${PATH}:" in
    *":${BIN_DIR}:"*) say "onion-attach: ${BIN_DIR} está no PATH; já dá para rodar: onion-attach <nome>" ;;
    *) say "onion-attach: ⚠️ ${BIN_DIR} NÃO está no PATH. Acrescente ao ~/.bashrc (ou ~/.profile) e abra outro terminal:"
       say "  export PATH=\"${BIN_DIR}:\$PATH\"" ;;
  esac
  exit 0
fi

command -v "${TMUX_BIN}" >/dev/null 2>&1 || die "tmux ausente (${TMUX_BIN})" 4

# servidores tmux: um socket por servidor em SOCK_DIR. Socket sem servidor (o tmux saiu e deixou o arquivo) some no ls.
tmux_servers() { local s; for s in "${SOCK_DIR}"/*; do [ -S "${s}" ] && printf '%s\n' "${s##*/}"; done; }

# ── instalação da config do tmux da casa: o instalador próprio (acrescenta UMA linha source-file, nunca sobrescreve) ─
if [ "${INSTALL_TMUX}" -eq 1 ]; then
  [ -z "${NAME}" ] || die "--install-tmux não leva nome"
  [ -f "${TMUX_INSTALLER}" ] || die "instalador ausente: ${TMUX_INSTALLER}" 2
  a=(); [ "${DRY}" -eq 1 ] && a+=(--dry-run); [ "${CHECK}" -eq 1 ] && a=(--check)
  ONION_TMUX_BIN="${TMUX_BIN}" ONION_TMUX_SOCKDIR="${SOCK_DIR}" exec bash "${TMUX_INSTALLER}" "${a[@]}"
fi

# ── leitura do estado ─────────────────────────────────────────────────────────────────────────────

# «viva?» — a regra única do helper do #1761 quando ele existe; senão, a mesma regra aqui
is_live() {  # kind state pid → rc 0 viva · 1 morta
  if [ -f "${LIVENESS}" ]; then bash "${LIVENESS}" live "$1" "$2" "$3" >/dev/null 2>&1; return $?; fi
  local k="$1" p="$3"
  if [ -n "${p}" ] && [ "${p}" != "-" ]; then
    [[ "${p}" =~ ^[1-9][0-9]*$ ]] || { [ "${k}" = interactive ]; return $?; }   # pid 0 ou torto: só a interativa conta
    kill -0 "${p}" 2>/dev/null || [ -d "/proc/${p}" ] || return 1   # EPERM: o processo existe, é de outro dono
    return 0
  fi
  [ "${k}" = interactive ]
}

# lista de peers do harness, TSV: sessionId short kind state pid name cwd. rc 1 = não lida.
PEERS="" PEERS_OK=0
read_peers() {
  local j
  j="$(timeout 20 "${CLAUDE_BIN}" agents --json 2>/dev/null)" || return 1
  PEERS="$(python3 -I -c '
import json, sys
d = json.loads(sys.stdin.read() or "null")
if not isinstance(d, list): sys.exit(1)
for x in d:
    if not isinstance(x, dict): continue
    sid = str(x.get("sessionId") or x.get("id") or "")
    if not sid: continue
    short = str(x.get("id") or sid[:8])
    f = [str(x.get(k)) if x.get(k) not in (None, "") else "-" for k in ("kind", "state", "pid", "name", "cwd")]
    if f[1] == "-" and x.get("status"): f[1] = str(x.get("status"))
    print("\t".join(v.replace("\t", " ").replace("\n", " ") for v in [sid, short] + f))
' <<< "${j}" 2>/dev/null)" || return 1
  PEERS_OK=1
}
if command -v "${CLAUDE_BIN}" >/dev/null 2>&1; then read_peers || true; fi
peers_note() { [ "${PEERS_OK}" -eq 1 ] || say "onion-attach: ⚠️ não li a lista do harness (${CLAUDE_BIN} agents --json): sessões de fundo nativas ficam de fora."; }

# ── sem argumento: a lista ────────────────────────────────────────────────────────────────────────
if [ -z "${NAME}" ]; then
  printf '%-22s %-30s %-8s %s\n' "nome" "onde" "estado" "para entrar"
  declare -A IN_TMUX=()
  dead=""
  while IFS= read -r srv; do
    [ -n "${srv}" ] || continue
    if ! sess="$("${TMUX_BIN}" -L "${srv}" ls -F '#{session_name}' 2>/dev/null)"; then dead="${dead} ${srv}"; continue; fi
    while IFS= read -r s; do
      [ -n "${s}" ] || continue
      IN_TMUX["${s}"]=1
      printf '%-22s %-30s %-8s %s\n' "${s}" "tmux (servidor ${srv})" "viva" "${TMUX_BIN} -L ${srv} attach -t ${s}"
    done <<< "${sess}"
  done < <(tmux_servers)
  while IFS=$'\t' read -r sid short k st p nm cw; do
    [ -n "${sid}" ] || continue
    if [ "${k}" = background ]; then
      if is_live "${k}" "${st}" "${p}"; then printf '%-22s %-30s %-8s %s\n' "${nm}" "fundo nativo (id ${short})" "viva" "${CLAUDE_BIN} attach ${short}"
      else printf '%-22s %-30s %-8s %s\n' "${nm}" "fundo nativo (id ${short})" "parada" "onion-attach ${nm}  (reabre pela conversa)"; fi
    elif [ "${k}" = interactive ] && [ -z "${IN_TMUX[${nm}]:-}" ]; then
      printf '%-22s %-30s %-8s %s\n' "${nm}" "interativa fora do tmux (pid ${p})" "viva" "— entre pelo terminal onde ela roda (cwd ${cw})"
    fi
  done <<< "${PEERS}"
  [ -z "${dead}" ] || say "(sockets sem servidor tmux vivo:${dead})"
  peers_note
  say "(sessão fechada não aparece aqui: onion-attach <nome> acha a conversa pelo título e a reabre)"
  exit 0
fi

# ── com nome: tmux, depois fundo nativo, depois a conversa fechada ───────────────────────────────
hits=()
while IFS= read -r srv; do
  [ -n "${srv}" ] || continue
  "${TMUX_BIN}" -L "${srv}" has-session -t "=${NAME}" 2>/dev/null && hits+=("${srv}")
done < <(tmux_servers)
# --resume <id> com a sessão VIVA no tmux: o abridor anexaria à conversa que já roda lá, não à pedida
if [ -n "${RESUME}" ] && [ "${#hits[@]}" -gt 0 ]; then
  die "«${NAME}» está viva no servidor tmux «${hits[0]}», com a conversa que já roda lá: --resume ${RESUME} não troca a conversa de uma sessão viva. Entre nela (onion-attach ${NAME}) e dê /exit antes, ou abra a outra conversa com outro nome." 3
fi
if [ -z "${RESUME}" ]; then
  if [ "${#hits[@]}" -gt 1 ]; then
    say "onion-attach: a sessão «${NAME}» existe em ${#hits[@]} servidores tmux: ambíguo, não escolho. Entre na certa:" >&2
    for srv in "${hits[@]}"; do say "  ${TMUX_BIN} -L ${srv} attach -t ${NAME}" >&2; done
    exit 5
  fi
  if [ "${#hits[@]}" -eq 1 ]; then
    srv="${hits[0]}"
    say "onion-attach: «${NAME}» está no servidor tmux «${srv}»."
    if [ -n "${TMUX:-}" ]; then
      cur="${TMUX%%,*}"
      one_client_or_refuse "${cur}"
      if [ "$(readlink -f -- "${cur}" 2>/dev/null || printf '%s' "${cur}")" = "$(readlink -f -- "${SOCK_DIR}/${srv}" 2>/dev/null || printf '%s' "${SOCK_DIR}/${srv}")" ]; then
        run "${TMUX_BIN}" -L "${srv}" switch-client -t "=${NAME}"
      fi
      # outro servidor: nada de tmux aninhado. O cliente atual se desliga e, no MESMO terminal, vira o attach do alvo
      # (detach-client -E, tmux 3.4: «run shell-command to replace the client»; medido em 25/11 num servidor descartável)
      say "onion-attach: você está no servidor tmux «${cur##*/}»; «${NAME}» está no «${srv}»: troco o cliente, sem aninhar."
      run "${TMUX_BIN}" -S "${cur}" detach-client -E "$(sq "${TMUX_BIN}") -L $(sq "${srv}") attach -t $(sq "=${NAME}")"
    fi
    run "${TMUX_BIN}" -L "${srv}" attach -t "=${NAME}"
  fi
  # fundo nativo, ou interativa fora do tmux
  bg=() inter=""
  while IFS=$'\t' read -r sid short k st p nm cw; do
    [ -n "${sid}" ] && [ "${nm}" = "${NAME}" ] || continue
    is_live "${k}" "${st}" "${p}" || continue
    if [ "${k}" = background ]; then bg+=("${short}"); else inter="${inter}pid ${p} em ${cw}; "; fi
  done <<< "${PEERS}"
  if [ "${#bg[@]}" -gt 1 ]; then
    say "onion-attach: há ${#bg[@]} sessões de fundo vivas com o nome «${NAME}»: ambíguo, não escolho. Entre na certa:" >&2
    for s in "${bg[@]}"; do say "  ${CLAUDE_BIN} attach ${s}" >&2; done
    exit 5
  fi
  if [ "${#bg[@]}" -eq 1 ]; then
    say "onion-attach: «${NAME}» é uma sessão de fundo nativa (id ${bg[0]})."
    # dentro de um tmux, o `claude attach` roda no PRÓPRIO painel: ninguém é desanexado do tmux (revisão isolada 25/11)
    run "${CLAUDE_BIN}" attach "${bg[0]}"
  fi
  if [ -n "${inter}" ]; then
    die "«${NAME}» está viva como sessão interativa fora de um tmux que eu ache (${inter%; }): não dá para anexar daqui. Entre pelo terminal onde ela roda." 3
  fi
  peers_note
fi

# fechada: a conversa pelo título (ou a escolhida por --resume), reaberta pelo abridor único
[ -f "${TRANSCRIPT}" ] || die "leitor de transcript ausente (${TRANSCRIPT})" 2
if [ -n "${RESUME}" ]; then
  row="$(bash "${TRANSCRIPT}" by-id "${RESUME}" --projects "${PROJECTS_DIR}")"; rc=$?
  [ "${rc}" -eq 0 ] || die "não achei uma conversa só com o id ${RESUME} (rc ${rc})" 5
  # o título da conversa escolhida não é o nome pedido: avisa (não recusa; a sessão reabre com o nome pedido)
  IFS=$'\t' read -r _m _i _d _p _l rt <<< "${row}"
  [ "${rt}" = "${NAME}" ] || say "onion-attach: ⚠️ a conversa ${RESUME} tem o título «${rt}», não «${NAME}»: confira o id; ela reabre com o nome «${NAME}»." >&2
else
  rows="$(bash "${TRANSCRIPT}" by-title "${NAME}" --projects "${PROJECTS_DIR}")"; rc=$?
  [ "${rc}" -ne 1 ] || die "«${NAME}» não está viva (tmux nem fundo nativo) e não achei conversa com esse título em ${PROJECTS_DIR}. Para abrir uma NOVA: bash ${SESSION_OPEN} ${NAME} --new" 5
  [ "${rc}" -eq 0 ] || die "o leitor de transcript falhou (rc ${rc})" 2
  row="$(head -1 <<< "${rows}")"
  n="$(wc -l <<< "${rows}")"
  if [ "${n}" -gt 1 ]; then
    IFS=$'\t' read -r m1 _ d1 _ <<< "${row}"
    IFS=$'\t' read -r m2 _ _ _ <<< "$(sed -n 2p <<< "${rows}")"
    other_dir="$(awk -F'\t' -v d="${d1}" 'NR > 1 && $3 != d && $3 != "-" { print $3; exit }' <<< "${rows}")"
    if [ $(( m1 - m2 )) -le "${AMBIG_SECS}" ] || [ -n "${other_dir}" ]; then
      if [ -n "${other_dir}" ]; then why="há conversas com esse título em pastas diferentes"; else why="as duas mais recentes mudaram com menos de ${AMBIG_SECS} s de diferença"; fi
      say "onion-attach: «${NAME}» tem ${n} conversas com esse título e ${why}: ambíguo, não escolho. Opções:" >&2
      while IFS=$'\t' read -r m id d _p last _t; do
        say "  $(fmt_date "${m}")  id ${id}  pasta ${d}  → onion-attach ${NAME} --resume ${id}" >&2
      done <<< "${rows}"
      exit 5
    fi
  fi
fi
IFS=$'\t' read -r m id d _p last _t <<< "${row}"
[ "${d}" != "-" ] || die "a conversa ${id} não grava a pasta onde nasceu: reabra à mão com bash ${SESSION_OPEN} ${NAME} --resume ${id} --dir <pasta>" 5
say "onion-attach: «${NAME}» está fechada; a conversa é a ${id} ($(fmt_date "${m}")), nascida em ${d}."
if [ -z "${RESUME}" ] && [ "$(wc -l <<< "${rows}")" -gt 1 ]; then
  say "onion-attach: conversas mais antigas com o mesmo título, na mesma pasta (o histórico de reinícios; para uma delas, --resume <id>):"
  sed -n '2,6p' <<< "${rows}" | while IFS=$'\t' read -r om oid _r; do say "  $(fmt_date "${om}")  id ${oid}"; done
fi
args=("${NAME}" --resume "${id}" --dir "${d}")
[ "${DRY}" -eq 1 ] && args+=(--dry-run)
say "onion-attach: reabro pelo abridor único: bash ${SESSION_OPEN} ${args[*]}"
exec bash "${SESSION_OPEN}" "${args[@]}"
