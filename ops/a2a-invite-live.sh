#!/usr/bin/env bash
# a2a-invite-live.sh — o convite A2A por membro no arquivo de convites do bridge de PRODUÇÃO (core-only).
#
# POR QUE EXISTE (2026-10-15, decisão do maestro): o motor de convites (.claude/utils/federation-transport/
# a2a-invite.sh) escreve o arquivo que recebe em --file, e o arquivo vivo mora em /home/onion, um caminho
# SERVIDO (ops/moat-targets.tsv). O veto do MOAT barrou, corretamente, a primeira tentativa de preparar o
# arquivo à mão (`sudo -u onion mkdir -p /home/onion/...`). E medido na mesma rodada: o motor chamado
# DIRETO com --file apontando o arquivo servido passava o veto com rc 0, porque o juiz só via escrita no
# verbo. As duas coisas se curam juntas: o juiz passou a julgar o --file do motor como destino de escrita,
# e este wrapper é o único caminho de escrita, com trava, backup cifrado antes, check depois e rollback
# impresso. Molde: ops/update-bridge.sh e ops/bridge-backup.sh.
#
# USO
#   ops/a2a-invite-live.sh create <member> --days N --token-file <arq> --invite-out <arq> [--receiver <id>] [--apply]
#   ops/a2a-invite-live.sh revoke <member> [--receiver <id>] [--apply]
#   ops/a2a-invite-live.sh list   [--member <id>] [--receiver <id>] [--json]
#   ops/a2a-invite-live.sh check  [--json]
#
#   Sem --apply, create e revoke são ENSAIO: o motor roda com --dry-run e nada é escrito, nem o backup.
#   --token-file  arquivo do OPERADOR com o token (regular, dono = quem roda, sem bit de grupo/outros, não
#                 symlink). O wrapper o abre UMA vez e entrega o descritor aberto como entrada do motor, que
#                 roda como a conta do serviço: o token nunca passa por argv, stdout ou log, e a conta do
#                 serviço não precisa ler a home do operador. Gerar um token sem ecoar:
#                   (umask 077; set -C; python3 -c 'import secrets; print(secrets.token_hex(32))' > ~/m.token)
#   --invite-out  arquivo NOVO do operador onde o descritor SEM segredo chega (0600). O motor o escreve num
#                 diretório temporário da conta do serviço (mktemp, 0700, fora de /home/onion) e o wrapper o
#                 entrega com dono do operador; o temporário é apagado na saída.
#   Fixos, sem opção para mudar: o arquivo de convites, o motor (do clone que o bridge serve) e o registro de
#   membros (o do mesmo clone). O wrapper não aceita --file, --members nem --owner: quem quer outro arquivo
#   usa o motor direto, fora de caminho servido.
#
# O QUE ELE FAZ numa escrita (--apply): trava (a mesma do update-bridge, que reseta o clone onde o motor
# mora) → ensaio do motor → backup rotulado do estado do bridge (bridge-backup.sh, cifrado) → escrita pelo
# motor como a conta do serviço → check do arquivo → prova por contagem (create: +1 entrada, a sonda do
# bridge diz ok para o descritor, e o token do operador bate com o hash; revoke: zero ativa do membro e a
# sonda não autentica). Falha depois do backup imprime o rollback com o artefato nomeado; nunca o executa.
#
# EXIT (molde do motor): 0 ok · 1 problema medido ou escrita recusada · 2 não pude medir (trava, sudo,
#   clone sem motor, backup) · 3 uso inválido
#
# MODO DE TESTE (bancada): ONION_A2A_LIVE_TEST=1 com ONION_A2A_LIVE_FILE, ONION_A2A_LIVE_MOTOR,
#   ONION_A2A_LIVE_MEMBERS, ONION_A2A_LIVE_BACKUP (comando que imprime "ok: <artefato>") e ONION_A2A_LIVE_LOCK.
#   Nele o motor roda como QUEM RODA (sem sudo) e o arquivo não pode estar sob a home da conta do serviço.
#   Qualquer ONION_A2A_LIVE_* sem o modo de teste é uso inválido (rc 3): produção não se redireciona por env.
set -uo pipefail

SVC_USER=onion
SVC_HOME=/home/onion
PROD_FILE="${SVC_HOME}/onion-bridge/data/a2a-invites.json"
PROD_MOTOR="${SVC_HOME}/onion-evolve/.claude/utils/federation-transport/a2a-invite.sh"
PROD_LOCK=/tmp/onion-update-bridge.lock
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OP_MOTOR="${SELF_DIR}/../.claude/utils/federation-transport/a2a-invite.sh"   # lado do operador: só o inspect
NAME=a2a-invite-live

say()  { printf '[%s] %s\n' "${NAME}" "$*"; }
die()  { local rc="$1"; shift; printf '[%s] ERRO: %s\n' "${NAME}" "$*" >&2; exit "${rc}"; }
usage() { sed -n '/^# USO/,/^# O QUE ELE FAZ/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 3; }

case "${1:-}" in -h|--help) sed -n '/^# USO/,/^# EXIT/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 0 ;; '') usage ;; esac

# ── modo: produção ou teste declarado ──────────────────────────────────────────────────────────────────
TEST=0
if [ "${ONION_A2A_LIVE_TEST:-}" = 1 ]; then
  TEST=1
  FILE="${ONION_A2A_LIVE_FILE:?modo de teste exige ONION_A2A_LIVE_FILE}"
  MOTOR="${ONION_A2A_LIVE_MOTOR:?modo de teste exige ONION_A2A_LIVE_MOTOR}"
  MEMBERS="${ONION_A2A_LIVE_MEMBERS:?modo de teste exige ONION_A2A_LIVE_MEMBERS}"
  BACKUP="${ONION_A2A_LIVE_BACKUP:?modo de teste exige ONION_A2A_LIVE_BACKUP}"
  LOCK="${ONION_A2A_LIVE_LOCK:?modo de teste exige ONION_A2A_LIVE_LOCK}"
  OP_MOTOR="${MOTOR}"
  # o teste nunca toca a home da conta do serviço, nem por symlink
  for _p in "${FILE}" "$(dirname "${FILE}")"; do
    _r="$(realpath -m -- "${_p}")"
    case "${_r}/" in "${SVC_HOME}/"*) die 3 "modo de teste com caminho sob ${SVC_HOME}: recusado (${_r})" ;; esac
  done
else
  [ -n "${ONION_A2A_LIVE_TEST:-}" ] && die 3 "ONION_A2A_LIVE_TEST só aceita 1"
  if env | grep -q '^ONION_A2A_LIVE_'; then
    die 3 "variável ONION_A2A_LIVE_* sem ONION_A2A_LIVE_TEST=1: produção não se redireciona por ambiente"
  fi
  FILE="${PROD_FILE}"; MOTOR="${PROD_MOTOR}"; MEMBERS=""; BACKUP=""; LOCK="${PROD_LOCK}"
  # o wrapper e o backup que ele chama por sudo (como root) têm de ser os RASTREADOS e limpos de um checkout:
  # uma cópia em /tmp chamaria `sudo <diretório dela>/bridge-backup.sh`, que outra conta pode plantar, e uma
  # cópia mutada perderia o backup e o check (refutador, 2026-10-15)
  for _f in "${SELF_DIR}/$(basename "${BASH_SOURCE[0]}")" "${SELF_DIR}/bridge-backup.sh"; do
    git -C "${SELF_DIR}" ls-files --error-unmatch -- "${_f}" >/dev/null 2>&1 \
      || die 3 "${_f} não é arquivo rastreado de um checkout: rode o wrapper do repositório, não uma cópia"
    git -C "${SELF_DIR}" diff --quiet HEAD -- "${_f}" 2>/dev/null \
      || die 3 "${_f} tem mudança não commitada: rode o wrapper como está no commit"
  done
fi

[ "$(id -u)" -eq 0 ] && die 3 "rodando como root: rode como o operador (o wrapper chama sudo -u ${SVC_USER} onde precisa; o descritor nasceria de root)"

# as_svc <args…>: roda como a conta do serviço (produção) ou como quem roda (teste), sempre a partir de /
# (o cwd do operador pode ser ilegível para a conta do serviço). O fd 3 (o token aberto) NÃO desce: só a
# entrada do create o carrega, redirecionada como fd 0 antes da chamada
as_svc() {
  if [ "${TEST}" = 1 ]; then (cd / && "$@") 3<&-
  else (cd / && sudo -n -u "${SVC_USER}" "$@") 3<&-; fi
}
motor() { as_svc bash "${MOTOR}" "$@"; }

# ── argumentos: lista FECHADA (o wrapper não vira escritor genérico como a conta do serviço) ─────────────
SUB="$1"; shift
MEMBER=""; DAYS=""; TOKEN_FILE=""; INVITE_OUT=""; RECEIVER=""; APPLY=0; JSON=0; LMEMBER=""
ID_RE='^[A-Za-z0-9_-][A-Za-z0-9._-]*$'
case "${SUB}" in
  create|revoke)
    [ $# -ge 1 ] || usage
    MEMBER="$1"; shift ;;
  list|check) : ;;
  *) usage ;;
esac
while [ $# -gt 0 ]; do
  case "$1" in
    --days)        [ "${SUB}" = create ] || die 3 "--days só no create"; DAYS="${2:-}"; shift 2 || usage ;;
    --token-file)  [ "${SUB}" = create ] || die 3 "--token-file só no create"; TOKEN_FILE="${2:-}"; shift 2 || usage ;;
    --invite-out)  [ "${SUB}" = create ] || die 3 "--invite-out só no create"; INVITE_OUT="${2:-}"; shift 2 || usage ;;
    --receiver)    [ "${SUB}" = check ] && die 3 "--receiver não se aplica ao check"; RECEIVER="${2:-}"; shift 2 || usage ;;
    --member)      [ "${SUB}" = list ] || die 3 "--member só no list"; LMEMBER="${2:-}"; shift 2 || usage ;;
    --apply)       case "${SUB}" in create|revoke) APPLY=1 ;; *) die 3 "--apply só em create/revoke" ;; esac; shift ;;
    --json)        case "${SUB}" in list|check) JSON=1 ;; *) die 3 "--json só em list/check" ;; esac; shift ;;
    *) die 3 "opção não aceita: $1 (o arquivo, o motor e o registro são fixos)" ;;
  esac
done
for _id in "${MEMBER}" "${RECEIVER}" "${LMEMBER}"; do
  [ -z "${_id}" ] || [[ "${_id}" =~ ${ID_RE} ]] || die 3 "id inválido: ${_id}"
done
if [ "${SUB}" = create ]; then
  [[ "${DAYS}" =~ ^[1-9][0-9]{0,2}$ ]] && [ "${DAYS}" -le 365 ] || die 3 "--days precisa ser inteiro de 1 a 365"
  [ -n "${TOKEN_FILE}" ] || die 3 "create exige --token-file <arq> (o token não vai por argv)"
  [ -n "${INVITE_OUT}" ] || die 3 "create exige --invite-out <arq novo> (o descritor sem segredo que viaja com o token)"
fi

# ── trava: a MESMA do update-bridge (ele reseta o clone onde o motor mora) ──────────────────────────────
exec 9>"${LOCK}" || die 2 "não abri a trava ${LOCK}"
flock -n 9 || die 2 "outra execução (este wrapper ou o update-bridge) segura ${LOCK}; tente de novo"

# ── o motor existe para a conta do serviço? ────────────────────────────────────────────────────────────
as_svc test -f "${MOTOR}" || die 2 "o motor não está em ${MOTOR} (para a conta ${SVC_USER}); atualize o clone servido pelo ops/update-bridge.sh"

common=(--file "${FILE}")
[ -n "${MEMBERS}" ] && common+=(--members "${MEMBERS}")
rcv=(); [ -n "${RECEIVER}" ] && rcv=(--receiver "${RECEIVER}")

# ── leitura: list e check passam direto (o motor só lê) ────────────────────────────────────────────────
if [ "${SUB}" = list ] || [ "${SUB}" = check ]; then
  args=("${SUB}" --file "${FILE}")
  [ -n "${LMEMBER}" ] && args+=(--member "${LMEMBER}")
  args+=("${rcv[@]}")
  [ "${JSON}" = 1 ] && args+=(--json)
  motor "${args[@]}"; exit $?
fi

# ── create: o arquivo do token, aberto UMA vez e conferido NO DESCRITOR ────────────────────────────────
if [ "${SUB}" = create ]; then
  [ -L "${TOKEN_FILE}" ] && die 1 "--token-file é symlink: recusado"
  exec 3<"${TOKEN_FILE}" || die 1 "não abri o --token-file"
  read -r t_lino t_uid t_mode t_type < <(stat -L -c '%d:%i %u %a %F' /proc/self/fd/3) || die 2 "não medi o --token-file"
  p_lino="$(stat -c '%d:%i' -- "${TOKEN_FILE}" 2>/dev/null)" || die 2 "não medi o --token-file"
  [ "${t_lino}" = "${p_lino}" ] || die 1 "o --token-file mudou entre a abertura e a conferência (ou é symlink): recusado"
  [ "${t_type}" = "regular file" ] || die 1 "o --token-file não é arquivo regular (${t_type})"
  [ "${t_uid}" = "$(id -u)" ] || die 1 "o --token-file não é seu (uid ${t_uid}): o token é do operador"
  [ $(( 8#${t_mode} & 8#077 )) -eq 0 ] || die 1 "o --token-file tem modo ${t_mode}: precisa ser 0600 ou 0400 (chmod 600)"
  # o descritor: arquivo NOVO do operador, num diretório que existe, fora de árvore git versionável
  [ -e "${INVITE_OUT}" ] || [ -L "${INVITE_OUT}" ] && die 1 "${INVITE_OUT} já existe: recuso sobrescrever"
  out_dir="$(dirname -- "${INVITE_OUT}")"
  [ -d "${out_dir}" ] || die 1 "o diretório de --invite-out não existe: ${out_dir}"
  if git -C "${out_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
     && ! git -C "${out_dir}" check-ignore -q -- "$(realpath -m -- "${INVITE_OUT}")" 2>/dev/null; then
    die 1 "${INVITE_OUT} cairia numa árvore git sem estar no .gitignore: gere fora do repo"
  fi
fi

# ── ensaio do motor (sempre; sem --apply é só isto) ────────────────────────────────────────────────────
dry=("${SUB}" "${MEMBER}" "${common[@]}" "${rcv[@]}" --dry-run)
[ "${SUB}" = create ] && dry+=(--days "${DAYS}" --token-stdin)
if [ "${SUB}" = create ]; then motor "${dry[@]}" 0<&3; else motor "${dry[@]}" </dev/null; fi
rc=$?
[ "${rc}" -eq 0 ] || { say "o ensaio do motor saiu ${rc}: nada foi escrito"; exit "${rc}"; }
if [ "${APPLY}" = 0 ]; then
  say "ENSAIO: nada foi escrito. Para escrever, repita com --apply."
  exit 0
fi

# ── contagem ANTES (a prova é por contagem, não pelo rc da escrita) ────────────────────────────────────
count() {  # count all|active → número; active = do membro, ativas, e do --receiver quando ele foi passado
  motor list --file "${FILE}" --json </dev/null 2>/dev/null \
    | python3 -I -c 'import json,sys
d=json.load(sys.stdin); m=sys.argv[1]; k=sys.argv[2]; r=sys.argv[3]
es=d.get("entries") or []
if d.get("state") == "absent": print(0); raise SystemExit
if d.get("state") != "ok": print("x"); raise SystemExit
print(sum(1 for e in es if (k == "all") or (e.get("member") == m and e.get("state") == "ativo" and (not r or e.get("receiver") == r))))' "${MEMBER}" "$1" "${RECEIVER}"
}
before_all="$(count all)"; before_act="$(count active)"
[[ "${before_all}" =~ ^[0-9]+$ ]] || die 2 "não medi o arquivo antes da escrita (estado não-ok); rode: ops/a2a-invite-live.sh check"
existed=1; [ "$(motor list --file "${FILE}" --json </dev/null 2>/dev/null | python3 -I -c 'import json,sys; print(json.load(sys.stdin).get("state"))')" = absent ] && existed=0

# ── backup rotulado do estado do bridge (cifrado), artefato NOMEADO ────────────────────────────────────
label="pre-invite-${SUB}-${MEMBER}"
if [ "${TEST}" = 1 ]; then BK_OUT="$("${BACKUP}" "${label}" 3<&-)"; else BK_OUT="$(sudo -n "${SELF_DIR}/bridge-backup.sh" "${label}" 3<&-)"; fi
[ $? -eq 0 ] || die 2 "backup falhou: sem rede de segurança não se escreve"
BK="$(printf '%s\n' "${BK_OUT}" | sed -n 's/^ok: \([^ ]*\).*/\1/p' | tail -1)"
[ -n "${BK}" ] || die 2 "o backup não nomeou o artefato: ${BK_OUT}"
say "backup: ${BK}"

rollback() {
  local rel="${FILE#"$(dirname "$(dirname "${FILE}")")"/}"
  cat >&2 <<EOF
[${NAME}] ─── ROLLBACK MANUAL (do maestro, fora da sessão: \`!\` no prompt) ───
EOF
  if [ "${existed}" = 0 ]; then
    cat >&2 <<EOF
  # o arquivo NÃO existia antes desta escrita:
  sudo -u ${SVC_USER} rm -f -- ${FILE}
EOF
  else
    cat >&2 <<EOF
  # restaura o arquivo do backup rotulado (o .gpg pede a chave do pass):
  gpg -d ${BK} | tar -xzO ${rel} \\
    | sudo -u ${SVC_USER} sh -c 'umask 077; cat > ${FILE}.restore && [ -s ${FILE}.restore ] \
        && python3 -c "import json,sys; json.load(open(sys.argv[1]))" ${FILE}.restore && mv -f ${FILE}.restore ${FILE}'
  # (o [ -s ] e o json.load seguram o mv: sem pipefail, um tar que falha trocaria o arquivo por um vazio)
EOF
  fi
  cat >&2 <<EOF
  ops/a2a-invite-live.sh check     # tem de sair 0
EOF
  [ "${SUB}" = create ] && echo "  # alternativa sem restaurar: ops/a2a-invite-live.sh revoke ${MEMBER} --apply (revoga TODOS os convites do membro)" >&2
}
fail_after_write() { printf '[%s] ERRO: %s\n' "${NAME}" "$1" >&2; rollback; exit 1; }

# ── escrita ────────────────────────────────────────────────────────────────────────────────────────────
if [ "${SUB}" = create ]; then
  tmpd="$(as_svc mktemp -d /tmp/onion-a2a-invite.XXXXXXXX)" || die 2 "não criei o temporário da conta do serviço"
  trap 'as_svc rm -rf -- "${tmpd}" 2>/dev/null' EXIT
  # o ensaio leu até o fim: reabre o MESMO arquivo pelo descritor (não pelo caminho, que podia ter sido trocado)
  exec 3<"/proc/self/fd/3" || die 2 "não reabri o --token-file"
  motor create "${MEMBER}" "${common[@]}" "${rcv[@]}" --days "${DAYS}" --token-stdin --invite-out "${tmpd}/invite.json" 0<&3
  rc=$?
  exec 3<&-
  if [ "${rc}" -ne 0 ]; then
    # o motor só escreve no rename final: rc != 0 é nada escrito, salvo o rename ter ido e o fsync não
    [ "$(count all)" = "${before_all}" ] || fail_after_write "o motor saiu ${rc} e a contagem mudou"
    say "o motor saiu ${rc}: nada foi escrito (contagem ${before_all} intacta)"; exit "${rc}"
  fi
  # entrega do descritor com dono do operador (0600, arquivo novo)
  ( umask 077; set -C; as_svc cat -- "${tmpd}/invite.json" > "${INVITE_OUT}" ) \
    || fail_after_write "não entreguei o descritor em ${INVITE_OUT} (o convite FOI escrito)"
  motor check --file "${FILE}" </dev/null || fail_after_write "check depois da escrita reprovou"
  after_all="$(count all)"
  [ "${after_all}" = "$(( before_all + 1 ))" ] || fail_after_write "contagem: esperava $(( before_all + 1 )) entrada(s), há ${after_all}"
  motor list --file "${FILE}" --invite "${tmpd}/invite.json" </dev/null >/dev/null \
    || fail_after_write "a sonda do bridge não diz ok para o descritor recém-criado"
  bash "${OP_MOTOR}" inspect --invite "${INVITE_OUT}" --member "${MEMBER}" "${rcv[@]}" --token-file "${TOKEN_FILE}" >/dev/null \
    || fail_after_write "o token do operador não bate com o descritor entregue"
  say "OK — convite de '${MEMBER}' criado: ${before_all} → ${after_all} entrada(s); check 0; sonda ok; token↔descritor conferidos"
  say "entregue ao membro, fora de banda: o token (${TOKEN_FILE}) e o descritor (${INVITE_OUT})"
else
  motor revoke "${MEMBER}" "${common[@]}" "${rcv[@]}" </dev/null
  rc=$?
  [ "${rc}" -eq 0 ] || { [ "$(count active)" = "${before_act}" ] || fail_after_write "o motor saiu ${rc} e a contagem mudou"; say "o motor saiu ${rc}: nada foi escrito"; exit "${rc}"; }
  motor check --file "${FILE}" </dev/null || fail_after_write "check depois da escrita reprovou"
  after_act="$(count active)"
  [ "${after_act}" = 0 ] || fail_after_write "contagem: ainda há ${after_act} convite(s) ativo(s) de '${MEMBER}'"
  rcp=0; motor list --file "${FILE}" --member "${MEMBER}" "${rcv[@]}" </dev/null >/dev/null || rcp=$?
  [ "${rcp}" = 1 ] || fail_after_write "a sonda do bridge não confirmou a revogação (rc ${rcp}, esperava 1: nenhum bearer do membro autentica)"
  say "OK — '${MEMBER}': ${before_act} → 0 convite(s) ativo(s); check 0; a sonda do bridge recusa (vale no próximo POST /a2a, sem restart)"
fi
exit 0
