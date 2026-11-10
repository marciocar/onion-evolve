#!/usr/bin/env bash
# maestro-ask.sh — DONO ÚNICO por pergunta ao maestro: chave, uma sessão dona, prazo e assunção do vencido.
#
# ── POR QUE EXISTE (medido em 2026-11-08) ─────────────────────────────────────────────────────────────
# Duas sessões peer perguntaram ao maestro, cada uma, o escopo da mesma integração. As respostas vieram diferentes, e o
# selo esperou uma 3ª rodada para juntar as duas (memória one-owner-session-per-maestro-question). A regra
# "combine antes quem pergunta" vivia na conversa; aqui ela é uma reserva que o censo do /meta:decide lê.
#
# ── A FORMA É A DO MERCADO (colheita de 2026-11-10, no estudo da orquestração de sessões, core-only:
#    docs/evolution/research/session-orchestration-2026-11/) ─────────────────────────────────────────────
#   · CHAVE ESCOLHIDA PELO PRODUTOR, NO MÁXIMO UMA ABERTA: o `dedup_key` do PagerDuty, o `alias` do Opsgenie, o
#     Workflow Id do Temporal. Aqui a chave é `<repo>#<ID do nó>` (o nó que a pergunta vai selar).
#   · UM ALVO POR VEZ E PRAZO DE ACK QUE ESCALA (escalation policy do PagerDuty, padrão de 30 min): aqui o alvo
#     é uma SESSÃO, o prazo default é 24 h (o maestro responde em horas, não em minutos) e o vencido NÃO troca de
#     dono sozinho — quem lê o censo assume com --takeover, dito na saída. Ack não é resolução: só o release
#     fecha, e a pergunta que volta se reserva de novo.
#
# Uso:
#   bash .claude/utils/orchestration/maestro-ask.sh claim <chave> --owner <sessão> [--ttl-hours H] [--question "texto"] [--takeover]
#       rc 0 RESERVADA (nova), RENOVADA (mesma dona) ou ASSUMIDA (vencida, com --takeover)
#       rc 3 JÁ TEM DONA (viva, ou vencida sem --takeover): a saída diz quem e desde quando — leve só o id
#   bash .claude/utils/orchestration/maestro-ask.sh release <chave> --owner <sessão> [--resolution "texto"]
#       rc 0 fechada (vai para o resolved.log) · rc 3 de outra dona · rc 4 não reservada
#   bash .claude/utils/orchestration/maestro-ask.sh list [--tsv]      as reservas abertas: chave, dona, desde, prazo, viva|vencida, pergunta
#   rc 2 = entrada quebrada (chave fora do alfabeto, dona vazia, diretório inseguro, flock ausente).
#
# Contrato:
#   · O REGISTRO é por usuário, FORA do repo, comum a toda sessão e repo desta máquina (o core e as peers
#     que vivem na mesma VPS): ${ONION_ASK_DIR:-${XDG_STATE_HOME:-~/.local/state}/onion/maestro-asks}, um
#     arquivo por chave. Sobrevive a reinício (não é /run). Escrita sob flock do diretório: duas sessões que
#     reservam a mesma chave no mesmo instante dão uma dona e uma recusa, nunca duas donas.
#   · O CENSO LÊ: `.claude/validation/decide-census.sh` imprime cada reserva como linha `ask` e marca a linha
#     `seal` cujo nó tem dona em outra sessão.
#   · Relógio trocável só para a bancada: ONION_ASK_NOW (epoch), dito na saída quando ativo.
#
# O que NÃO faz (fronteira): não pergunta ao maestro, não escolhe a dona (quem reserva primeiro é a dona; o
# combinado entre as sessões continua sendo delas) e não vê outra máquina: a reserva é desta VPS. Duas
# perguntas iguais com chaves diferentes (nós diferentes) não se juntam: a identidade é a chave.
set -uo pipefail

die2() { echo "maestro-ask: $*" >&2; exit 2; }
ASK_DIR="${ONION_ASK_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/onion/maestro-asks}"
NOW="${ONION_ASK_NOW:-$(date +%s)}"
case "${NOW}" in ''|*[!0-9]*) die2 "ONION_ASK_NOW inválido (${NOW})" ;; esac
[ -n "${ONION_ASK_NOW:-}" ] && echo "maestro-ask: ⚠️ relógio trocado (ONION_ASK_NOW=${NOW}): NÃO é a medição de produção" >&2
iso() { date -u -d "@$1" +%FT%TZ 2>/dev/null || echo "@$1"; }
one() { printf '%s' "$*" | tr '\t\n\r' '   '; }

_dir() {
  command -v flock >/dev/null 2>&1 || die2 "flock ausente (util-linux) — sem trava, duas donas seriam possíveis"
  if [ ! -d "${ASK_DIR}" ]; then ( umask 077; mkdir -p "${ASK_DIR}" ) 2>/dev/null || die2 "não criei ${ASK_DIR}"; chmod 700 "${ASK_DIR}" 2>/dev/null; fi
  if [ -L "${ASK_DIR}" ] || [ ! -O "${ASK_DIR}" ] || [ -n "$(find "${ASK_DIR}" -maxdepth 0 -perm /022 2>/dev/null)" ]; then
    die2 "${ASK_DIR} é link, não é meu ou aceita escrita de outros — recuso usar como registro"
  fi
}
_key() {
  printf '%s' "$1" | LC_ALL=C grep -qE '^[A-Za-z0-9][A-Za-z0-9._:#-]{0,200}$' || die2 "chave fora do alfabeto [A-Za-z0-9._:#-] (${1}); use <repo>#<ID do nó>"
}
# lê a reserva: OWNER SINCE DEADLINE QUESTION (vazios se não existe)
_read() {
  local f="${ASK_DIR}/$1.ask"; OWNER=""; SINCE=""; DEADLINE=""; QUESTION=""
  [ -f "${f}" ] || return 1
  IFS=$'\t' read -r _k OWNER SINCE DEADLINE QUESTION < "${f}" || true
  return 0
}

# grava a reserva por arquivo temporário + mv; falha de E/S é rc 2, nunca "RESERVADA" sem arquivo
_write() {  # chave dona desde prazo pergunta
  local f="${ASK_DIR}/$1.ask"
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$(one "$5")" > "${f}.tmp" 2>/dev/null && mv -f "${f}.tmp" "${f}" 2>/dev/null \
    || { rm -f "${f}.tmp" 2>/dev/null; die2 "não gravei a reserva ${f} (E/S) — nada reservado"; }
}

cmd="${1:-}"; shift || true
case "${cmd}" in
  claim|release)
    key="${1:-}"; shift || true; [ -n "${key}" ] || die2 "${cmd} sem chave"; _key "${key}"
    owner=""; ttl=24; question=""; resolution=""; takeover=0
    while [ $# -gt 0 ]; do
      case "$1" in
        --owner) owner="${2:-}"; shift ;;
        --ttl-hours) ttl="${2:-}"; shift ;;
        --question) question="${2:-}"; shift ;;
        --resolution) resolution="${2:-}"; shift ;;
        --takeover) takeover=1 ;;
        *) die2 "opção desconhecida: $1" ;;
      esac
      shift
    done
    [ -n "${owner}" ] || die2 "${cmd} exige --owner <sessão>"
    owner="$(one "${owner}")"
    case "${ttl}" in ''|*[!0-9]*|0) die2 "--ttl-hours inválido (${ttl}) — inteiro ≥ 1" ;; esac
    _dir
    exec 9>>"${ASK_DIR}/.lock" || die2 "não abri ${ASK_DIR}/.lock"
    flock -w 10 9 || die2 "o registro está travado há 10 s por outra sessão — tente de novo"
    f="${ASK_DIR}/${key}.ask"
    if [ "${cmd}" = claim ]; then
      dl=$(( NOW + ttl * 3600 ))
      if _read "${key}"; then
        if [ "${OWNER}" = "${owner}" ]; then
          _write "${key}" "${owner}" "${SINCE}" "${dl}" "${question:-${QUESTION}}"
          echo "maestro-ask: RENOVADA — ${key} segue com ${owner}, prazo $(iso "${dl}")"; exit 0
        fi
        if [ "${DEADLINE:-0}" -gt "${NOW}" ] 2>/dev/null; then
          echo "maestro-ask: JÁ TEM DONA — ${key} é de ${OWNER} desde $(iso "${SINCE}"), prazo $(iso "${DEADLINE}"). Não pergunte: leve só o id a ela." >&2; exit 3
        fi
        if [ "${takeover}" != 1 ]; then
          echo "maestro-ask: VENCIDA — ${key} é de ${OWNER} desde $(iso "${SINCE}") e o prazo passou em $(iso "${DEADLINE}"). Confira com a dona; para assumir: --takeover" >&2; exit 3
        fi
        printf '%s\tescalada\t%s\t%s\t%s\tassumida por %s\n' "$(iso "${NOW}")" "${key}" "${OWNER}" "$(one "${QUESTION}")" "${owner}" >> "${ASK_DIR}/resolved.log"
        _write "${key}" "${owner}" "${NOW}" "${dl}" "${question:-${QUESTION}}"
        echo "maestro-ask: ASSUMIDA — ${key} era de ${OWNER} (vencida em $(iso "${DEADLINE}")); agora ${owner}, prazo $(iso "${dl}")"; exit 0
      fi
      _write "${key}" "${owner}" "${NOW}" "${dl}" "${question}"
      echo "maestro-ask: RESERVADA — ${key} é de ${owner}, prazo $(iso "${dl}")"; exit 0
    fi
    # release
    if ! _read "${key}"; then echo "maestro-ask: ${key} não está reservada — nada a fechar" >&2; exit 4; fi
    if [ "${OWNER}" != "${owner}" ]; then echo "maestro-ask: ${key} é de ${OWNER}, não de ${owner} — só a dona fecha" >&2; exit 3; fi
    printf '%s\tfechada\t%s\t%s\t%s\t%s\n' "$(iso "${NOW}")" "${key}" "${OWNER}" "$(one "${QUESTION}")" "$(one "${resolution}")" >> "${ASK_DIR}/resolved.log"
    rm -f -- "${f}"
    echo "maestro-ask: FECHADA — ${key} (${OWNER})"; exit 0 ;;
  list)
    tsv=0; [ "${1:-}" = "--tsv" ] && tsv=1
    [ -d "${ASK_DIR}" ] || { [ "${tsv}" = 1 ] && printf 'key\towner\tsince\tdeadline\tstate\tquestion\n'; echo "maestro-ask: registro vazio (${ASK_DIR} não existe)" >&2; exit 0; }
    _dir
    [ "${tsv}" = 1 ] && printf 'key\towner\tsince\tdeadline\tstate\tquestion\n'
    n=0
    for f in "${ASK_DIR}"/*.ask; do
      [ -f "${f}" ] || continue
      k="$(basename "${f}" .ask)"; _read "${k}" || continue
      st=viva; [ "${DEADLINE:-0}" -gt "${NOW}" ] 2>/dev/null || st=vencida
      n=$((n + 1))
      if [ "${tsv}" = 1 ]; then printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${k}" "${OWNER}" "$(iso "${SINCE}")" "$(iso "${DEADLINE}")" "${st}" "${QUESTION}"
      else echo "- ${k} — ${OWNER} desde $(iso "${SINCE}") · prazo $(iso "${DEADLINE}") · ${st}${QUESTION:+ · ${QUESTION}}"; fi
    done
    [ "${tsv}" = 1 ] || echo "maestro-ask: ${n} reserva(s) aberta(s) em ${ASK_DIR}"
    exit 0 ;;
  *) sed -n '18,25p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;;
esac
