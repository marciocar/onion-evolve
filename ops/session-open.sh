#!/usr/bin/env bash
# ===========================================================================
# session-open.sh — o ABRIDOR ÚNICO das sessões longas do Claude Code nesta máquina (core-only).
#
# Uso:
#   bash ops/session-open.sh <nome> [--dry-run] [--no-attach] [--resume <id> | --new] [--mode <permission-mode>]
#   bash ops/session-open.sh --all  [--dry-run]   reabre, sem anexar, toda sessão dona do registro de posse
#   bash ops/session-open.sh --list               o que existe: sessão tmux, processo claude e pasta de cada sessão dona
#
# O padrão (D_SESSION_ACCESS_TMUX_MOSH_RESUME_BY_ID_1120 e D_SESSION_ONE_OWNERSHIP_REGISTRY_BY_NAME_1120, 2026-11-20,
# sobre D_SESSION_CAP_8_AND_TMUX_MIGRATION_1116):
#   · UMA sessão tmux por repo, com o NOME da sessão dona (o do registro de posse, que é o nome do repo): o mesmo nome
#     no tmux e no Claude Code. O acesso de fora é tmux + mosh.
#   · QUEM é dono e QUAL é o nome vêm do leitor único, .claude/utils/orchestration/ownership.sh (members.yaml de
#     origin/main + a lista privada de sessões donas). Nome fora do registro abre em ~/<nome>, e o preflight diz não.
#   · A RETOMADA É SEMPRE POR ID EXATO, nunca `--continue` (que pega «a última conversa da pasta», qualquer que seja).
#     Sem --resume, o id se resolve pelo NOME no estado do harness: (1) `claude agents --json`; (2) o transcript mais
#     recente da pasta cujo título é o nome. O escolhido é DITO. Dois candidatos = ambíguo: RECUSA (rc 5). Nenhum: só
#     abre sessão NOVA com --new, dito na linha (abrir nova sem querer perde o histórico da antiga).
#     A retomada leva só `--resume <id>` (mais o canal da campainha, onde o repo a declara, e o --mode se pedido): o
#     teste nativo de 2026-11-20 mediu que flag a mais na retomada de sessão de fundo abre uma CÓPIA com outro id e nome.
#     A campainha EXIGE a flag do canal (sem ela a sessão volta muda). Medido em 2026-11-20 (Claude Code 2.1.329, sessão
#     descartável num repo de brinquedo): `claude --bg --resume <sid> --dangerously-load-development-channels
#     server:doorbell` abriu CÓPIA (note: «the flags you passed started a copy as …»); `claude --resume <sid>` com a
#     mesma flag, INTERATIVO num tmux (o que este abridor faz), retomou o MESMO id e o mesmo nome, com o histórico.
#     Custo medido: o interativo para no aviso «Loading development channels» até alguém dar Enter no painel; depois
#     do --all, entre em cada sessão de campainha e confirme. Por isso este abridor nunca usa --bg.
#   · NUNCA DUAS SESSÕES NO MESMO CHECKOUT: `tmux new-session -A` só anexa; e, para criar, RECUSA (rc 3) se já há um
#     `claude` vivo com o cwd naquela pasta (fora do tmux ou noutra sessão tmux), ou se o id resolvido já está vivo
#     noutro lugar (a cópia escreveria no mesmo histórico: incidente de 2026-11-16). Nunca mata processo.
#   · PREFLIGHT na abertura: «este repo merja sozinho? sim|não, e por quê», pela parte estática da catraca do
#     ops/pr-merge-verified.sh, lida pelo ownership.sh (sem reimplementar aqui).
#   · O tmux NÃO sobrevive a reboot: depois de um, `--all` reabre as sessões donas do registro, cada uma pelo seu id.
#     O core (kind: source, sem owner_session) fica FORA do --all por desenho deste passo: ele é quem roda o abridor;
#     abre-se à mão (`session-open.sh core`). Entrar no --all é decisão do maestro (2º passo da migração).
#   · A lista de peers do harness é obrigatória para CRIAR: a sessão de fundo não aparece no /proc como `claude`, e só a
#     lista diz que ela está viva neste checkout ou que o id já roda noutro lugar. Sem a lista, recusa (rc 3).
#
# Saída: 0 abriu/anexou/ensaiou · 2 uso ou pasta inválida · 3 recusa (sessão viva: duplicaria) · 4 tmux ou claude
# ausente · 5 id não resolvido (ambíguo, ou nenhum sem --new).
# Este script só abre terminal: não lê .env, não toca serviço, não decide permissão (o modo vem de --mode, senão do
# que o Claude Code já tem configurado). Do transcript lê só a linha do título (customTitle), nunca a conversa.
# ===========================================================================
set -uo pipefail

HOME_DIR="${SESSION_OPEN_HOME:-${HOME}}"
PROC_DIR="${SESSION_OPEN_PROC:-/proc}"
TMUX_BIN="${SESSION_OPEN_TMUX:-tmux}"
CLAUDE_BIN="${SESSION_OPEN_CLAUDE:-claude}"
PROJECTS_DIR="${SESSION_OPEN_PROJECTS:-${HOME_DIR}/.claude/projects}"
OWNERSHIP="${SESSION_OPEN_OWNERSHIP:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.claude/utils/orchestration/ownership.sh}"
OWN_ARGS=()
[ -n "${SESSION_OPEN_MEMBERS:-}" ] && OWN_ARGS+=(--members "${SESSION_OPEN_MEMBERS}")   # bancada: registro de fixture
OWN_ARGS+=(--home "${HOME_DIR}")
# «meu uid» para comparar o DONO de /proc/<pid>: um claude de OUTRA conta (cwd/environ ilegível por permissão) não pode
# ser a sessão desta conta naquela pasta, então é ignorado — sem isto o abridor travava (rc 3) por causa do processo
# alheio. SESSION_OPEN_UID é o substituto de teste (o /proc falso da bancada é todo do usuário do teste).
MY_UID="${SESSION_OPEN_UID:-$(id -u)}"
# janela, em segundos, em que dois transcripts com o mesmo nome contam como simultâneos (ambíguo)
AMBIG_SECS="${SESSION_OPEN_AMBIG_SECS:-120}"

say() { printf '%s\n' "$*"; }
die() { printf 'session-open: %s\n' "$1" >&2; exit "${2:-2}"; }

NAME="" DRY=0 ATTACH=1 RESUME="" MODE="" ALL=0 LIST=0 NEW=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --no-attach) ATTACH=0 ;;
    --all) ALL=1 ;;
    --list) LIST=1 ;;
    --new) NEW=1 ;;
    --resume) shift; RESUME="${1:-}"; [ -n "${RESUME}" ] || die "--resume pede o id da sessão" ;;
    --mode) shift; MODE="${1:-}"; [ -n "${MODE}" ] || die "--mode pede o modo de permissão" ;;
    --continue|-c) die "--continue não existe aqui: a retomada é sempre por id exato (D_SESSION_ACCESS_TMUX_MOSH_RESUME_BY_ID_1120). Sem --resume, o id se resolve pelo nome." ;;
    -*) die "opção desconhecida: $1" ;;
    *) [ -z "${NAME}" ] || die "um nome por vez (veio «${NAME}» e «$1»)"; NAME="$1" ;;
  esac
  shift
done
[ -z "${RESUME}" ] || [ "${NEW}" -eq 0 ] || die "--resume e --new se excluem"
ID_RE='^[A-Za-z0-9][A-Za-z0-9-]{7,63}$'
[ -z "${RESUME}" ] || [[ "${RESUME}" =~ ${ID_RE} ]] || die "id de sessão inválido: «${RESUME}»"
case "${MODE}" in ''|default|acceptEdits|plan|auto|dontAsk|bypassPermissions) ;; *) die "--mode fora da lista (default, acceptEdits, plan, auto, dontAsk, bypassPermissions): «${MODE}»" ;; esac

valid_name() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]]; }

# pids de `claude` cujo cwd é a pasta. $2 = "out" (fora de tmux) | "any". Erro de leitura NÃO vira «nenhum»: rc 2 —
# MAS só quando o processo é do MESMO dono (falha fechada real). Se o cwd/environ não se lê e o processo é de OUTRA
# conta (uid de /proc/<pid> ≠ MY_UID), ele é IGNORADO: não pode ser a sessão desta conta naquela pasta, e não deve
# travar o abridor. Dono indeterminado (stat falhou) também é falha fechada (rc 2).
claude_pids() {
  local dir="$1" want="$2" p comm cwd env puid out=""
  [ -d "${PROC_DIR}" ] || return 2
  for p in "${PROC_DIR}"/[0-9]*; do
    [ -r "${p}/comm" ] || continue
    comm="$(cat "${p}/comm" 2>/dev/null)" || continue
    [ "${comm}" = "claude" ] || continue
    puid="$(stat -c '%u' "${p}" 2>/dev/null)" || puid=""
    if ! cwd="$(readlink "${p}/cwd" 2>/dev/null)"; then
      [ -n "${puid}" ] && [ "${puid}" != "${MY_UID}" ] && continue  # cwd ilegível de OUTRO dono → ignora
      return 2  # cwd ilegível do mesmo dono (ou dono indeterminado) → não mede às cegas
    fi
    [ "${cwd}" = "${dir}" ] || continue
    if [ "${want}" = "out" ]; then
      if ! env="$(tr '\0' '\n' < "${p}/environ" 2>/dev/null)"; then
        [ -n "${puid}" ] && [ "${puid}" != "${MY_UID}" ] && continue  # environ ilegível de OUTRO dono → ignora
        return 2  # environ ilegível do mesmo dono → não mede às cegas
      fi
      grep -q '^TMUX=' <<< "${env}" && continue
    fi
    out="${out}${p##*/} "
  done
  printf '%s' "${out% }"
}

has_tmux_session() { "${TMUX_BIN}" has-session -t "=$1" 2>/dev/null; }

# a lista de peers do harness, como TSV: sessionId kind state pid name cwd. rc 1 = não medida (dito por quem chama).
peers_tsv() {
  local j
  j="$(timeout 20 "${CLAUDE_BIN}" agents --json 2>/dev/null)" || return 1
  python3 -I -c '
import json, sys
d = json.loads(sys.stdin.read() or "null")
if not isinstance(d, list): sys.exit(1)
for x in d:
    if not isinstance(x, dict): continue
    sid = str(x.get("sessionId") or x.get("id") or "")
    if not sid: continue
    # campo vazio vira «-»: o read com IFS de TAB funde tabs seguidos, e o campo seguinte escorregaria
    f = [str(x.get(k)) if x.get(k) not in (None, "") else "-" for k in ("kind", "state", "pid", "name", "cwd")]
    print("\t".join(v.replace("\t", " ").replace("\n", " ") for v in [sid] + f))
' <<< "${j}" 2>/dev/null
}
# viva = interativa listada (o harness só lista interativa que roda) ou de fundo num estado de processo de pé
peer_live() { case "$1:$2" in interactive:*) return 0 ;; *:working|*:blocked|*:done|*:idle|*:running) return 0 ;; esac; return 1; }

# o último título (customTitle) de um transcript: só a linha do título, nunca a conversa
title_of() { grep -oE '"customTitle":"[^"]*"' "$1" 2>/dev/null | tail -1 | sed -E 's/^"customTitle":"//; s/"$//'; }

# nome + pasta → RID e RID_SRC. rc 0 achou · 1 nenhum · 3 já vivo · 5 ambíguo. PEERS_NOTE diz se o harness não foi medido.
RID="" RID_SRC="" PEERS_NOTE="" PEERS=""
resolve_id() {
  local n="$1" dir="$2" hits ids cnt enc f t m best="" bestm=0 second=0 nhit=0
  RID="" RID_SRC=""
  if PEERS="$(peers_tsv)"; then PEERS_NOTE=""
  else
    # sem a lista não se vê sessão de fundo (o processo dela não se chama claude no /proc) nem id vivo noutro lugar
    say "session-open: não li a lista de peers do harness (${CLAUDE_BIN} agents --json): sem ela não sei se há sessão de fundo neste checkout ou se o id já está vivo noutro lugar. Não abro às cegas." >&2; return 3
  fi
  # nunca duas sessões no mesmo checkout: peer VIVO (qualquer nome) com o cwd nesta pasta. A sessão de fundo não aparece
  # no /proc como `claude` (o processo leva o nome da versão), então o /proc sozinho não a vê.
  local s k st p nm cw
  while IFS=$'\t' read -r s k st p nm cw; do
    [ -n "${s}" ] && [ "${cw}" != "-" ] || continue
    [ "$(realpath -m -- "${cw}")" = "${dir}" ] || continue
    peer_live "${k}" "${st}" && { say "session-open: a sessão «${nm}» (id ${s}, ${k}/${st}) já está viva neste checkout (${dir}): nunca duas sessões no mesmo checkout. Entre nela, ou abra a 2ª numa worktree (claude --worktree)." >&2; return 3; }
  done <<< "${PEERS}"
  if [ -n "${RESUME}" ]; then RID="${RESUME}"; RID_SRC="--resume"
  else
    hits="$(awk -F'\t' -v n="${n}" '$5 == n' <<< "${PEERS}")"
    if [ -n "${hits}" ]; then
      while IFS=$'\t' read -r s k st p nm cw; do
        peer_live "${k}" "${st}" && { say "session-open: a sessão «${n}» já está viva (id ${s}, ${k}${st:+/${st}}, cwd ${cw}): não abro outra cópia. Entre nela: ${TMUX_BIN} attach -t ${n}, ou claude attach ${s}." >&2; return 3; }
      done <<< "${hits}"
      ids="$(cut -f1 <<< "${hits}" | sort -u)"; cnt="$(wc -l <<< "${ids}")"
      if [ "${cnt}" -gt 1 ]; then say "session-open: o harness lista ${cnt} sessões paradas com o nome «${n}» ($(tr '\n' ' ' <<< "${ids}")): ambíguo, não escolho. Diga o id com --resume." >&2; return 5; fi
      RID="${ids}"; RID_SRC="claude agents --json"
    else
      enc="$(sed 's#[^A-Za-z0-9-]#-#g' <<< "${dir}")"
      if [ -d "${PROJECTS_DIR}/${enc}" ]; then
        while IFS= read -r f; do
          [ -n "${f}" ] || continue
          t="$(title_of "${f}")"; [ "${t}" = "${n}" ] || continue
          m="$(stat -c '%Y' "${f}" 2>/dev/null)" || continue
          nhit=$((nhit + 1))
          if [ -z "${best}" ]; then best="${f}"; bestm="${m}"; else second="${m}"; break; fi
        done < <(ls -1t "${PROJECTS_DIR}/${enc}"/*.jsonl 2>/dev/null | head -200)
      fi
      [ -n "${best}" ] || return 1
      if [ "${nhit}" -gt 1 ] && [ $(( bestm - second )) -le "${AMBIG_SECS}" ]; then
        say "session-open: dois transcripts de ${dir} com o título «${n}» mudaram com menos de ${AMBIG_SECS} s de diferença: ambíguo (duas sessões com o mesmo nome?), não escolho. Diga o id com --resume." >&2; return 5
      fi
      RID="$(basename "${best}" .jsonl)"; RID_SRC="transcript mais recente com o título «${n}» ($(date -u -d "@${bestm}" +%Y-%m-%dT%H:%MZ 2>/dev/null || echo "${bestm}"))"
    fi
  fi
  # o id resolvido vem de fora (harness, nome de arquivo): só entra no comando se tiver a forma de id
  [[ "${RID}" =~ ${ID_RE} ]] || { say "session-open: o id resolvido para «${n}» não tem a forma de id de sessão («${RID}»): não o ponho no comando." >&2; return 5; }
  # o id escolhido não pode estar vivo noutro lugar (outro nome, outra pasta): a cópia escreveria no mesmo histórico
  hits="$(awk -F'\t' -v s="${RID}" '$1 == s' <<< "${PEERS}")"
  if [ -n "${hits}" ]; then
    while IFS=$'\t' read -r s k st p nm cw; do
      peer_live "${k}" "${st}" && { say "session-open: o id ${RID} já está vivo (nome «${nm}», ${k}${st:+/${st}}, cwd ${cw}): não abro outra cópia do mesmo histórico." >&2; return 3; }
    done <<< "${hits}"
  fi
  return 0
}

# o preflight: a resposta do leitor único, numa linha
preflight() {  # $1 = nome ou pasta no registro
  local o rc
  if [ ! -f "${OWNERSHIP}" ]; then say "session-open: preflight — este repo merja sozinho? NÃO MEDIDO: leitor de posse ausente (${OWNERSHIP})"; return 0; fi
  o="$(bash "${OWNERSHIP}" merge-alone "$1" "${OWN_ARGS[@]}" 2>/dev/null)"; rc=$?
  case "${rc}" in
    0|1) say "session-open: preflight — este repo merja sozinho? ${o%%$'\t'*}: ${o#*$'\t'}" ;;
    *) say "session-open: preflight — este repo merja sozinho? NÃO MEDIDO: o leitor de posse falhou (rc ${rc}); trate como não" ;;
  esac
}

# nome → «nome-da-sessão<TAB>pasta<TAB>chave-do-registro», pelo leitor único; fora do registro, ~/<nome>
locate() {
  local n="$1" row rc
  if [ -f "${OWNERSHIP}" ]; then
    row="$(bash "${OWNERSHIP}" who "${n}" "${OWN_ARGS[@]}" 2>/dev/null)"; rc=$?
    [ "${rc}" -eq 2 ] && die "o registro de posse não respondeu por «${n}» (ilegível ou ambíguo): rode bash ${OWNERSHIP} who ${n}"
    if [ "${rc}" -eq 0 ]; then
      IFS=$'\t' read -r _id _k _o sn lp _v _r <<< "${row}"
      [ "${lp}" != "-" ] || die "«${n}» está no registro de posse, mas sem pasta conhecida (local_path ausente, ou a 4ª coluna da lista privada vazia): não adivinho"
      printf '%s\t%s\t%s\n' "${sn}" "${lp}" "${n}"; return 0
    fi
  fi
  [ "${n}" = core ] && n="onion-evolve"
  printf '%s\t%s\t%s\n' "${n}" "${HOME_DIR}/${n}" "${n}"
}

open_one() {  # $1 = nome, $2 = anexar (1|0), $3 = pasta (opcional: --all já a sabe)
  local n="$1" attach="$2" dir="${3:-}" key cmd out rc loc
  valid_name "${n}" || die "nome inválido: «${n}» (letras, dígitos, ponto, hífen e sublinhado)"
  if [ -z "${dir}" ]; then loc="$(locate "${n}")" || exit $?; IFS=$'\t' read -r n dir key <<< "${loc}"
  else key="${n}"; fi
  valid_name "${n}" || die "nome de sessão inválido no registro: «${n}»"
  dir="$(realpath -m -- "${dir}")"   # o /proc dá o cwd canônico: barra final ou `..` no registro furariam a comparação
  [ -d "${dir}/.git" ] || [ -f "${dir}/.git" ] || die "«${dir}» não é um repositório git: o nome da sessão é o nome do repo"

  preflight "${key}"
  if has_tmux_session "${n}"; then
    say "session-open: a sessão tmux «${n}» já existe — anexo, não crio outra."
    # a sessão tmux existe, mas pode haver OUTRA cópia fora dela (aberta à mão num terminal): avisa, não mata. Lacuna
    # NOMEADA se não deu para medir um processo do MESMO dono (rc 2), em vez de engolir o erro em silêncio.
    out="$(claude_pids "${dir}" out)"; rc=$?
    if [ "${rc}" -ne 0 ]; then
      say "session-open: ⚠️ não deu para medir se há um claude do mesmo dono em ${dir} fora do tmux (${PROC_DIR} ilegível) — confira à mão."
    elif [ -n "${out}" ]; then
      say "session-open: ⚠️ há também um claude em ${dir} FORA do tmux (pid ${out}): se for a mesma sessão, dê /exit lá e fique só com a do tmux."
    fi
    # e a sessão de FUNDO viva no checkout, que o /proc não vê como claude: aviso (anexar não abre uma 2ª)
    local pl; pl="$(peers_tsv)" || say "session-open: ⚠️ não li a lista de peers do harness: não sei se há sessão de fundo viva em ${dir}."
    while IFS=$'\t' read -r _s _k _st _p _nm _cw; do
      [ -n "${_s}" ] && [ "${_k}" = background ] && [ "${_cw}" != "-" ] && [ "$(realpath -m -- "${_cw}")" = "${dir}" ] || continue
      peer_live "${_k}" "${_st}" && say "session-open: ⚠️ há também a sessão de fundo «${_nm}» (id ${_s}) viva em ${dir}: duas no mesmo checkout; pare uma (claude stop ${_s}) ou leve-a para uma worktree."
    done <<< "${pl}"
  else
    # nunca duas sessões no mesmo checkout: QUALQUER claude vivo com o cwd na pasta (fora do tmux ou noutra sessão tmux)
    out="$(claude_pids "${dir}" any)"; rc=$?
    [ "${rc}" -eq 0 ] || die "não li ${PROC_DIR} para saber se já há um claude em ${dir}: não abro às cegas" 3
    if [ -n "${out}" ]; then
      local o2; o2="$(claude_pids "${dir}" out)"
      [ $? -eq 0 ] || die "já há um claude vivo em ${dir} (pid ${out}) e não li se ele está num tmux (${PROC_DIR} ilegível): não abro às cegas" 3
      if [ -n "${o2}" ]; then
        die "já há um claude vivo em ${dir} FORA do tmux (pid ${o2}). Abrir outro duplica a sessão no checkout. Vá à janela dele, dê /exit, e rode este comando de novo." 3
      fi
      die "já há um claude vivo em ${dir} (pid ${out}), noutra sessão tmux ou de outra conta, não na «${n}»: nunca duas sessões no mesmo checkout. Entre nela (${TMUX_BIN} ls) ou dê /exit lá; a 2ª sessão de trabalho vai para uma worktree (claude --worktree)." 3
    fi
    resolve_id "${n}" "${dir}"; rc=$?
    [ -z "${PEERS_NOTE}" ] || say "session-open: ℹ️  ${PEERS_NOTE}"
    case "${rc}" in
      0) say "session-open: retomo «${n}» pelo id exato ${RID} (fonte: ${RID_SRC})."
         cmd="$(printf '%q --resume %q' "${CLAUDE_BIN}" "${RID}")" ;;
      1) [ "${NEW}" -eq 1 ] || die "não achei sessão com o nome «${n}» (harness e transcripts de ${dir}): para abrir uma NOVA, rode de novo com --new; para retomar outra, --resume <id>. Nunca --continue." 5
         say "session-open: nenhuma sessão «${n}» achada; abro NOVA (--new)."
         cmd="$(printf '%q --name %q' "${CLAUDE_BIN}" "${n}")" ;;
      *) exit "${rc}" ;;
    esac
    [ -n "${MODE}" ] && cmd="${cmd} --permission-mode $(printf '%q' "${MODE}")"
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

# toda sessão dona do registro de posse (members.yaml + lista privada) → «nome<TAB>pasta», só as que TÊM pasta git;
# a que não tem é DITA no stderr, nunca some em silêncio
roster() {
  local rows id sn lp via
  [ -f "${OWNERSHIP}" ] || die "leitor de posse ausente (${OWNERSHIP}): sem o registro não sei o que reabrir" 2
  rows="$(bash "${OWNERSHIP}" list "${OWN_ARGS[@]}")" || die "o leitor de posse falhou: sem o registro não sei o que reabrir" 2
  while IFS=$'\t' read -r id sn lp via; do
    [ -n "${id}" ] || continue
    valid_name "${sn}" || { printf 'session-open: pulo %s: nome de sessão inválido («%s»)\n' "${id}" "${sn}" >&2; continue; }
    if [ "${lp}" = "-" ]; then printf 'session-open: pulo «%s» (%s): pasta desconhecida no registro\n' "${sn}" "${via}" >&2; continue; fi
    [ -d "${lp}/.git" ] || [ -f "${lp}/.git" ] || { printf 'session-open: pulo «%s»: %s não é repo git nesta máquina\n' "${sn}" "${lp}" >&2; continue; }
    printf '%s\t%s\n' "${sn}" "${lp}"
  done <<< "${rows}" | sort -u
}

command -v "${TMUX_BIN}" >/dev/null 2>&1 || die "tmux ausente (${TMUX_BIN})" 4
[ "${DRY}" -eq 1 ] || command -v "${CLAUDE_BIN}" >/dev/null 2>&1 || die "claude ausente (${CLAUDE_BIN})" 4

if [ "${LIST}" -eq 1 ]; then
  names="$(roster)" || exit $?
  printf '%-22s %-8s %-18s %s\n' "nome" "tmux" "claude (pid)" "pasta"
  while IFS=$'\t' read -r n d; do
    [ -n "${n}" ] || continue
    if has_tmux_session "${n}"; then t="sim"; else t="não"; fi
    p="$(claude_pids "${d}" any)" || p="NÃO MEDIDO"
    printf '%-22s %-8s %-18s %s\n' "${n}" "${t}" "${p:--}" "${d}"
  done <<< "${names}"
  exit 0
fi

if [ "${ALL}" -eq 1 ]; then
  [ -z "${NAME}" ] || die "--all não leva nome"
  [ -z "${RESUME}" ] || die "--all não leva --resume: cada sessão se resolve pelo próprio nome"
  names="$(roster)" || exit $?
  [ -n "${names}" ] || die "nenhuma sessão dona com pasta no registro de posse" 2
  worst=0
  while IFS=$'\t' read -r n d; do
    [ -n "${n}" ] || continue
    ( open_one "${n}" 0 "${d}" ); r=$?
    [ "${r}" -gt "${worst}" ] && worst="${r}"
  done <<< "${names}"
  exit "${worst}"
fi

[ -n "${NAME}" ] || die "uso: session-open.sh <nome> [--dry-run] [--no-attach] [--resume <id> | --new] [--mode <modo>] | --all | --list"
open_one "${NAME}" "${ATTACH}"
