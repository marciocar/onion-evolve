#!/usr/bin/env bash
# update-persona-hub.sh — o update repetível da persona do Slack (onion-slack-persona) e do worker do hub
# (onion-brain-hub), no molde do ops/update-bridge.sh: mede antes, NOOP quando está em dia, backup do que se troca,
# conferência por contagem no boot DESTA invocação e o desfazer impresso (nunca executado às cegas). Core-only.
#
# POR QUE EXISTE (SAC-447, 2026-11-21): o ops/update-bridge.sh só cobre a unit onion-vps-bridge, e a guarda manda
# atualizar serviço por wrapper. As duas units irmãs se atualizavam por script de ato único escrito na hora (o molde
# do deploy do onion-bridge #110/#111, de 20/11). E o worker do hub rodava no MESMO checkout da sessão do hub: dois
# escritores no mesmo repo (I3). Este wrapper aponta o worker para uma worktree própria e se recusa a subir sem ela.
#
# USO
#   ops/update-persona-hub.sh <persona|hub|all> [--apply | --restart]
#     sem flag é ENSAIO: mede, decide (NOOP ou update), mostra o diff da unit do hub, confere a unit gerada no
#     systemd-analyze e diz o que rodaria. Só escreve o `git fetch` no clone de código do worker (o refs/remotes dele),
#     que não muda o que roda.
#     --apply aplica; em dia, só re-verifica o vivo (NOOP).
#     --restart é o --apply que religa mesmo em dia (o vivo que não se prova por um crash antigo, NRestarts > 0, ou por
#     journal rotacionado: sem ele a única saída seria um systemctl restart à mão).
#     all = hub e depois persona; o hub falhando, a persona não é tocada.
#
# O QUE CADA ALVO FAZ
#   persona  o código é o bridge SERVIDO (/home/onion/onion-bridge, bind só leitura), cujo escritor é o
#            ops/update-bridge.sh. Este wrapper NÃO escreve nele: mede se a persona subiu antes da última mudança do
#            servido (HEAD movido pelo reflog, ou node_modules refeito) e, se sim, religa pelo `ops/slack-persona.sh start`
#            (que confere a unit efetiva e espera a conexão desta invocação); depois confere InvocationID novo e
#            NRestarts 0. Em dia, roda o `ops/slack-persona.sh verify`. A unit instalada diferente da servida é recusa:
#            trocar a unit é o `install --apply` do slack-persona.sh, com a allowlist dele.
#   hub      o código é o clone /home/marcio/onion-brain-hub-app; o ALVO é o mesmo sha que o bridge servido roda (a
#            persona e o hub falam pelo socket com o protocolo do mesmo repo). Ordem: worktree do worker conferida →
#            unit gerada da cópia do repo (BRAIN_HUB_DIR na worktree do worker, BRAIN_HUB_MAESTRO_USER_ID preservado da
#            instalada), passada por uma ALLOWLIST de diretivas e pelo systemd-analyze ANTES de parar qualquer coisa →
#            backup da unit → stop (com religamento automático, menos durante o npm ci) → fast-forward do clone → npm ci
#            só se o lock mudou → install da unit → daemon-reload → start → conferência.
#
# A WORKTREE DO WORKER (o "um escritor por repo"): BRAIN_HUB_DIR=/home/marcio/worktrees/brain-granaai/hub-worker. O
#   wrapper confere SÓ LENDO ARQUIVOS (nenhum comando git no repo da sessão do hub): o .git dela é um ARQUIVO que aponta
#   para <repo do hub>/.git/worktrees/<nome>, cujo `gitdir` aponta de volta; não é o checkout da sessão; e o que o
#   checkout da sessão tem de configuração (.mcp.json, .claude/settings.json, CLAUDE.md) existe nela (arquivo não
#   rastreado não vem no `git worktree add`). Depois, git SÓ LEITURA na própria worktree (--no-optional-locks): ela tem
#   arquivos rastreados e nenhum rastreado faltando (uma pasta só com o .git copiado não é worktree). Faltando algo,
#   recusa e imprime o ato de migração, que é do maestro.
#
# TRAVAS: a própria e a do ops/update-bridge.sh (/tmp/onion-update-bridge.lock): o update-bridge refaz o node_modules do
#   bridge servido, de onde a persona sobe e cujo HEAD é o alvo do hub.
#
# EXIT: 0 ok (ou NOOP com o vivo verificado, ou ensaio sem recusa) · 1 recusa ou falha (com o desfazer, quando algo
#       mudou) · 2 não pude medir, ou outra execução segura a trava · 3 uso inválido
#
# TETOS DECLARADOS: (1) religar o hub corta o turno em curso (um turno pode esperar o clique do admin): o wrapper não
#   sabe se há turno; (2) a worktree do worker não é sincronizada aqui com a main do hub (o worker é o escritor dela);
#   (3) os fios do Slack com sessão aberta perdem o `resume` na troca do BRAIN_HUB_DIR (a sessão mora no diretório de
#   projeto do caminho antigo); (4) a prova de vida do hub é a linha "brain hub worker listening" desta invocação e o
#   socket 0660 do grupo, não um turno de verdade; (5) o npm ci roda só se o package-lock.json mudou entre o sha de
#   antes e o alvo: um node_modules que já estava defasado antes não é refeito.
#
# MODO DE TESTE (só pela bancada ops/testing/update-persona-hub-selftest.sh): ONION_UPH_TEST=1 com ONION_UPH_ROOT em /tmp
#   (a raiz falsa onde caem /etc, /home, /run e o estado) e ONION_UPH_PERSONA_SH (o slack-persona.sh falso). Nele nada
#   passa por sudo, e systemctl, journalctl, npm e systemd-analyze vêm do PATH. ONION_UPH_* sem o modo de teste é rc 3.
set -uo pipefail

NAME=update-persona-hub
say()  { printf '[%s] %s\n' "${NAME}" "$*"; }
plan() { printf '[%s]   [ensaio] %s\n' "${NAME}" "$*"; }
die()  { local rc="$1"; shift; printf '[%s] ERRO: %s\n' "${NAME}" "$*" >&2; exit "${rc}"; }
usage() { sed -n '/^# USO/,/^# O QUE CADA/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 3; }

TEST="${ONION_UPH_TEST:-0}"
if [ "${TEST}" != 1 ] && grep -q '^ONION_UPH_' <<< "$(env)"; then
  die 3 "variável ONION_UPH_* sem o modo de teste: produção não se redireciona por ambiente"
fi
R=""
if [ "${TEST}" = 1 ]; then
  R="${ONION_UPH_ROOT:?modo de teste sem ONION_UPH_ROOT}"
  case "${R}" in /tmp/*|/var/tmp/*) ;; *) die 3 "a raiz de teste tem de estar em /tmp: ${R}" ;; esac
fi
[ "$(id -u)" = 0 ] && [ "${TEST}" != 1 ] && die 3 "rode como o operador (o script chama sudo onde precisa), não como root"

TARGET_ARG="${1:-}"; MODE="${2:-}"
case "${TARGET_ARG}" in persona|hub|all) ;; *) usage ;; esac
APPLY=0; FORCE=0
case "${MODE}" in "") ;; --apply) APPLY=1 ;; --restart) APPLY=1; FORCE=1 ;; *) usage ;; esac
[ $# -le 2 ] || usage

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# os caminhos de produção (o que vai dentro da unit e da linha do journal) e os do disco (com a raiz de teste na frente)
WORKER_PROD=/home/marcio/worktrees/brain-granaai/hub-worker
HUB_REPO_PROD=/home/marcio/brain-granaai
APP_PROD=/home/marcio/onion-brain-hub-app
EXEC_HUB="/usr/bin/node ${APP_PROD}/node_modules/tsx/dist/cli.mjs src/brain-hub/main.ts"
SERVED="${R}/home/onion/onion-bridge"
APP="${R}${APP_PROD}"
HUB_REPO="${R}${HUB_REPO_PROD}"
WORKER="${R}${WORKER_PROD}"
UNIT_DIR="${R}/etc/systemd/system"
STATE="${R}/home/marcio/.local/state/onion-update-persona-hub"
SOCK="${R}/run/onion-brain-hub/hub.sock"
UNIT_HUB=onion-brain-hub
UNIT_PER=onion-slack-persona
UNIT_HUB_REL=deploy/brain-hub/onion-brain-hub.service
UNIT_PER_REL=deploy/slack-persona/onion-slack-persona.service
WORKER_CONFIG=(.mcp.json .claude/settings.json CLAUDE.md)
ID_RE='^[UW][A-Z0-9]{2,20}$'
if [ "${TEST}" = 1 ]; then
  PERSONA_SH="${ONION_UPH_PERSONA_SH:?modo de teste sem ONION_UPH_PERSONA_SH}"
  SOCK_GROUP="$(id -gn)"; LOCK="${R}/tmp/onion-update-persona-hub.lock"; BRIDGE_LOCK="${R}/tmp/onion-update-bridge.lock"; mkdir -p "${R}/tmp"
else
  PERSONA_SH="${SELF_DIR}/slack-persona.sh"; SOCK_GROUP=onion-brain-hub; LOCK=/tmp/onion-update-persona-hub.lock; BRIDGE_LOCK=/tmp/onion-update-bridge.lock
fi

priv()     { if [ "${TEST}" = 1 ]; then "$@"; else sudo -n "$@"; fi; }
as_onion() { if [ "${TEST}" = 1 ]; then "$@"; else sudo -n -u onion -- "$@"; fi; }
mask() { local v="$1"; printf '%s…(%d caracteres)' "${v:0:2}" "${#v}"; }

# duas execuções concorrentes fariam stop/start cruzados no mesmo clone
exec 9>"${LOCK}" || die 2 "não abri a trava ${LOCK}"
flock -n 9 || die 2 "outra execução segura ${LOCK}: nada foi feito"
# a do update-bridge: >> não trunca e cria se faltar (a que o root cria é 0666, pelo comentário do update-bridge.sh)
exec 8>>"${BRIDGE_LOCK}" || die 2 "não abri a trava do update-bridge ${BRIDGE_LOCK}"
flock -n 8 || die 2 "o ops/update-bridge.sh (ou um install irmão) segura ${BRIDGE_LOCK}: o bridge servido está mudando, nada foi feito"
[ "${TEST}" = 1 ] || sudo -n true 2>/dev/null || die 2 "sudo sem senha indisponível (rode pelo \`!\` do maestro)"

# ── medidas comuns ───────────────────────────────────────────────────────────────────────────────────────────────
# epoch do início do processo principal da unit; vazio = não sei (conta como "desatualizado")
start_epoch() { local s; s="$(systemctl show -p ExecMainStartTimestamp --value "$1" 2>/dev/null)"
  [ -n "${s}" ] && [ "${s}" != n/a ] && date -d "${s}" +%s 2>/dev/null; }
# epoch da última mudança de um checkout: o MAIOR entre o reflog do HEAD, o mtime do HEAD, do ref da main e do ORIG_HEAD
# (o reflog pode ter expirado: sem eles, toda rodada religaria) e o node_modules refeito; vazio = não sei (religa)
moved_epoch() { # <runner: as_onion|plain> <dir>
  local run="$1" d="$2" g best=0 v
  if [ "${run}" = as_onion ]; then g="$(as_onion git -C "${d}" reflog -1 --date=unix --format=%gd HEAD 2>/dev/null)"
  else g="$(git -C "${d}" reflog -1 --date=unix --format=%gd HEAD 2>/dev/null)"; fi
  g="${g#HEAD@\{}"; g="${g%\}}"
  [[ "${g}" =~ ^[0-9]+$ ]] && best="${g}"
  for v in $(priv stat -c %Y "${d}/.git/HEAD" "${d}/.git/refs/heads/main" "${d}/.git/ORIG_HEAD" "${d}/node_modules/.package-lock.json" 2>/dev/null); do
    [[ "${v}" =~ ^[0-9]+$ ]] && [ "${v}" -gt "${best}" ] && best="${v}"
  done
  [ "${best}" -gt 0 ] && echo "${best}"
  return 0
}
inv_of() { systemctl show -p InvocationID --value "$1" 2>/dev/null; }
nrestarts_of() { systemctl show -p NRestarts --value "$1" 2>/dev/null; }
journal_of_inv() { priv journalctl -q -o cat "_SYSTEMD_INVOCATION_ID=$1" 2>/dev/null; }

served_head() {
  SERVED_HEAD="$(as_onion git -C "${SERVED}" rev-parse HEAD 2>/dev/null)" || die 2 "não li o HEAD do bridge servido (${SERVED})"
  [ -z "$(as_onion git --no-optional-locks -C "${SERVED}" status --porcelain --untracked-files=no 2>/dev/null)" ] \
    || die 1 "o bridge servido tem mudança rastreada: triagem primeiro (o escritor dele é o ops/update-bridge.sh)"
  local rm; rm="$(as_onion git -C "${SERVED}" ls-remote origin refs/heads/main 2>/dev/null | cut -f1)"
  if [ -n "${rm}" ] && [ "${rm}" != "${SERVED_HEAD}" ]; then
    say "AVISO: o bridge servido (${SERVED_HEAD:0:12}) não é a main remota (${rm:0:12}); quem o avança é o ops/update-bridge.sh. Este wrapper sobe no SERVIDO."
  fi
}

# ── persona ──────────────────────────────────────────────────────────────────────────────────────────────────────
do_persona() {
  say "── persona (${UNIT_PER})"
  priv cmp -s "${SERVED}/${UNIT_PER_REL}" "${UNIT_DIR}/${UNIT_PER}.service" \
    || die 1 "a unit instalada da persona difere da servida (ou falta): troca de unit é 'ops/slack-persona.sh install' (ensaio) e 'install --apply', com a allowlist dele"
  systemctl is-active -q "${UNIT_PER}" || die 1 "a persona não está ativa: ligar é 'ops/slack-persona.sh start', não update"
  local st mv old_inv
  st="$(start_epoch "${UNIT_PER}")"; mv="$(moved_epoch as_onion "${SERVED}")"
  if [ "${FORCE}" = 0 ] && [ -n "${st}" ] && [ -n "${mv}" ] && [ "${st}" -gt "${mv}" ]; then
    say "persona subiu depois da última mudança do servido (${SERVED_HEAD:0:12}): NOOP, re-verificando o vivo"
    [ "${APPLY}" = 1 ] || { plan "${PERSONA_SH} verify"; return 0; }
    bash "${PERSONA_SH}" verify || die 1 "NOOP e o vivo da persona NÃO está provado (slack-persona.sh verify reprovou)"
    say "persona: NOOP OK"; return 0
  fi
  [ "${FORCE}" = 1 ] && say "--restart: religando a persona mesmo em dia"
  say "persona desatualizada: início $( [ -n "${st}" ] && date -u -d "@${st}" +%FT%TZ || echo '?') · servido mudou em $( [ -n "${mv}" ] && date -u -d "@${mv}" +%FT%TZ || echo '?')"
  if [ "${APPLY}" = 0 ]; then
    plan "${PERSONA_SH} start   (confere a unit efetiva, religa e espera a conexão desta invocação)"
    plan "conferência: InvocationID novo e NRestarts 0"
    say "desfazer (para o --apply): o código é o do bridge servido; voltar é o rollback do ops/update-bridge.sh e então este wrapper de novo"
    return 0
  fi
  old_inv="$(inv_of "${UNIT_PER}")"
  bash "${PERSONA_SH}" start || die 1 "slack-persona.sh start falhou (o rollback dele está acima)"
  local inv nr; inv="$(inv_of "${UNIT_PER}")"; nr="$(nrestarts_of "${UNIT_PER}")"
  [ -n "${inv}" ] && [ "${inv}" != "${old_inv}" ] || die 1 "o start não trouxe uma invocação NOVA (${inv:0:8} = a de antes): nada prova o código novo"
  [ "${nr}" = 0 ] || die 1 "a persona reiniciou sozinha depois do start (NRestarts=${nr:-?}): veja o journal"
  say "persona: OK — invocação ${old_inv:0:8} → ${inv:0:8}, servido ${SERVED_HEAD:0:12}"
}

# ── hub ──────────────────────────────────────────────────────────────────────────────────────────────────────────
WORKER_PROBLEMS=()
worker_check() {
  WORKER_PROBLEMS=()
  if [ ! -d "${WORKER}" ]; then WORKER_PROBLEMS+=("a worktree do worker não existe: ${WORKER_PROD}"); return; fi
  if [ -L "${WORKER}" ] || [ "$(realpath -e "${WORKER}" 2>/dev/null)" = "$(realpath -e "${HUB_REPO}" 2>/dev/null)" ]; then
    WORKER_PROBLEMS+=("${WORKER_PROD} é (ou aponta para) o checkout da sessão do hub: seria o mesmo escritor"); return
  fi
  if [ ! -f "${WORKER}/.git" ] || [ -L "${WORKER}/.git" ]; then
    WORKER_PROBLEMS+=("${WORKER_PROD}/.git não é o arquivo de uma worktree (um diretório é clone separado, sem a história da sessão)"); return
  fi
  local gd name back
  gd="$(sed -n '1s/^gitdir: //p' "${WORKER}/.git")"
  name="${gd#"${HUB_REPO}/.git/worktrees/"}"
  if [ "${name}" = "${gd}" ] || ! [[ "${name}" =~ ^[A-Za-z0-9._-]+$ ]]; then
    WORKER_PROBLEMS+=("${WORKER_PROD} não é worktree do repo do hub (o .git aponta '${gd#"${R}"}', esperado ${HUB_REPO_PROD}/.git/worktrees/<nome>)"); return
  fi
  back="$(cat "${gd}/gitdir" 2>/dev/null)"
  [ "${back}" = "${WORKER}/.git" ] || WORKER_PROBLEMS+=("o registro da worktree em ${HUB_REPO_PROD}/.git/worktrees/${name}/gitdir não aponta de volta para ela ('${back#"${R}"}')")
  local f
  for f in "${WORKER_CONFIG[@]}"; do
    if [ -e "${HUB_REPO}/${f}" ] && [ ! -e "${WORKER}/${f}" ]; then
      WORKER_PROBLEMS+=("falta ${f} na worktree (o checkout da sessão tem; arquivo não rastreado não vem no worktree add)")
    fi
  done
  # git SÓ LEITURA na própria worktree (o índice dela, sem trava opcional): tem rastreados, e nenhum rastreado sumiu
  local tracked deleted
  tracked="$(git --no-optional-locks -C "${WORKER}" ls-files 2>/dev/null)"
  deleted="$(git --no-optional-locks -C "${WORKER}" ls-files --deleted 2>/dev/null)"
  if [ -z "${tracked}" ]; then WORKER_PROBLEMS+=("a worktree não tem arquivo rastreado (pasta com o .git copiado não é worktree)")
  elif [ -n "${deleted}" ]; then WORKER_PROBLEMS+=("a worktree tem arquivo rastreado faltando: $(head -3 <<< "${deleted}" | tr '\n' ' ')")
  fi
}

migration_act() {
  cat <<EOF
[${NAME}] ─── ATO DE MIGRAÇÃO (do maestro, ou da sessão do hub, que é a dona de ${HUB_REPO_PROD}) ───
  1. a worktree própria do worker (branch dela, a partir da main do hub):
       git -C ${HUB_REPO_PROD} fetch origin
       git -C ${HUB_REPO_PROD} worktree add -b hub-worker ${WORKER_PROD} origin/main
  2. o que o checkout da sessão tem fora do git e o worker precisa (o ensaio lista o que falta), por exemplo:
       [ -e ${HUB_REPO_PROD}/.mcp.json ] && cp -p ${HUB_REPO_PROD}/.mcp.json ${WORKER_PROD}/
  3. as sessões abertas dos fios do Slack (o worker retoma cada fio pelo id da sessão, que mora no diretório de projeto
     do CAMINHO; sem a cópia, a 1ª mensagem de cada fio aberto volta como erro e só a seguinte abre sessão nova):
       C=/home/marcio/.claude-granaai/projects   # o CLAUDE_CONFIG_DIR da unit
       mkdir -p \$C/-home-marcio-worktrees-brain-granaai-hub-worker && cp -p \$C/-home-marcio-brain-granaai/*.jsonl \$C/-home-marcio-worktrees-brain-granaai-hub-worker/
  4. ensaio e aplicação deste wrapper (o apply troca o BRAIN_HUB_DIR da unit e religa o worker):
       bash ops/update-persona-hub.sh hub
       ! bash ops/update-persona-hub.sh hub --apply
  A memória do projeto é a mesma (as worktrees de um repo dividem o diretório de memória). A worktree não se
  sincroniza sozinha com a main do hub: quem a mantém em dia é o próprio worker (ou a sessão do hub).
EOF
}

# a unit do repo no sha alvo, com BRAIN_HUB_DIR na worktree do worker e o id do maestro preservado da instalada.
# Recusa a unit que muda quem o processo é ou o que ele roda (o root a instala).
gen_hub_unit() { # <texto da unit do repo> <texto da instalada>; imprime a gerada; rc 1 com o motivo no stderr
  local src="$1" inst="$2" n id out
  if grep -q $'\r' <<< "${src}"; then echo "a unit do repo tem \\r" >&2; return 1; fi
  n="$(grep -c '^Environment=BRAIN_HUB_DIR=' <<< "${src}")"
  [ "${n}" = 1 ] || { echo "a unit do repo tem ${n} linha(s) Environment=BRAIN_HUB_DIR= (esperado 1; sem ela o código cai no checkout da sessão)" >&2; return 1; }
  out="$(sed -E "s|^Environment=BRAIN_HUB_DIR=.*$|Environment=BRAIN_HUB_DIR=${WORKER_PROD}|" <<< "${src}")"
  id="$(sed -n 's/^Environment=BRAIN_HUB_MAESTRO_USER_ID=//p' <<< "${inst}" | head -1)"
  if [ -n "${id}" ]; then
    [[ "${id}" =~ ${ID_RE} ]] || { echo "o BRAIN_HUB_MAESTRO_USER_ID da unit instalada está fora do formato de id do Slack" >&2; return 1; }
    n="$(grep -cE '^#?Environment=BRAIN_HUB_MAESTRO_USER_ID=' <<< "${out}")"
    [ "${n}" = 1 ] || { echo "a unit do repo tem ${n} linha(s) BRAIN_HUB_MAESTRO_USER_ID (esperado 1, comentada ou não)" >&2; return 1; }
    out="$(sed -E "s|^#?Environment=BRAIN_HUB_MAESTRO_USER_ID=.*$|Environment=BRAIN_HUB_MAESTRO_USER_ID=${id}|" <<< "${out}")"
  fi
  local why; why="$(hub_unit_allowlist <<< "${out}")" || { echo "${why}" >&2; return 1; }
  printf '%s\n' "${out}"
}

# A UNIT QUE O ROOT INSTALA vem de um clone que o operador escreve: ALLOWLIST FECHADA de diretivas (molde do
# unit_allowlist_check do ops/slack-persona.sh). Chave fora da lista recusa; as que decidem quem o processo é e o que
# ele roda têm valor FIXO; Environment= é UMA atribuição NOME=valor por linha, sem aspas, de nomes conhecidos, e
# BRAIN_HUB_DIR aparece uma vez só (no systemd a última atribuição vence). Linha com espaço na frente recusa (o
# systemd a lê; uma lista que olha só a coluna 0 não). Mudar a unit no onion-bridge numa dessas diretivas pede mudar
# esta lista no core (PR revisado): é o preço declarado.
hub_unit_allowlist() { # stdin = a unit; rc 0 = cabe; imprime o motivo da recusa
  python3 -I -c '
import re, sys
app, exe, worker = sys.argv[1], sys.argv[2], sys.argv[3]
FIX = {("Service", "Type"): {"simple"}, ("Service", "User"): {"marcio"},
  ("Service", "RuntimeDirectory"): {"onion-brain-hub"}, ("Service", "RuntimeDirectoryMode"): {"0755"},
  ("Service", "SupplementaryGroups"): {"onion-brain-hub"}, ("Service", "StateDirectory"): {"onion-brain-hub"},
  ("Service", "StateDirectoryMode"): {"0700"}, ("Service", "WorkingDirectory"): {app}, ("Service", "ExecStart"): {exe},
  ("Service", "Restart"): {"on-failure"}, ("Service", "SuccessExitStatus"): {"143"}, ("Service", "UMask"): {"0022"},
  ("Service", "NoNewPrivileges"): {"yes"}, ("Service", "PrivateTmp"): {"yes"}, ("Install", "WantedBy"): {"multi-user.target"}}
FREE = {("Unit", "Description"): r"[^\[\]\\]{1,200}", ("Unit", "After"): r"[A-Za-z0-9@._ -]+",
  ("Unit", "Wants"): r"[A-Za-z0-9@._ -]+", ("Service", "RestartSec"): r"[0-9]{1,4}"}
ENV = {"HOME": r"/home/marcio", "CLAUDE_CONFIG_DIR": r"/home/marcio/\.claude[A-Za-z0-9._-]*", "BRAIN_HUB_DIR": re.escape(worker),
  "BRAIN_HUB_SOCKET": r"/run/onion-brain-hub/hub\.sock", "BRAIN_HUB_MAESTRO_USER_ID": r"[UW][A-Z0-9]{2,20}",
  "BRAIN_HUB_MODEL": r"[A-Za-z0-9._-]{1,80}", "PATH": r"[A-Za-z0-9/._:-]+", "NODE_ENV": r"production"}
REQ = {("Service", "User"), ("Service", "ExecStart"), ("Service", "WorkingDirectory")}
txt = sys.stdin.read()
if any((ord(c) < 32 and c != "\n") or ord(c) == 127 for c in txt):
    print("caractere de controle na unit"); sys.exit(1)
sec, seen, bad, envn = None, set(), [], {}
for n, t in enumerate(txt.split("\n"), 1):
    if not t or t[0] in "#;":
        continue
    if t.endswith("\\"):
        bad.append("linha %d: continuação de linha" % n); continue
    m = re.fullmatch(r"\[(Unit|Service|Install)\]", t)
    if m:
        sec = m.group(1); continue
    m = re.fullmatch(r"([A-Za-z]+)=(.*)", t)
    if not m or sec is None:
        bad.append("linha %d: não é diretiva de seção conhecida (espaço na frente?): %s" % (n, t[:60])); continue
    k, v = (sec, m.group(1)), m.group(2)
    if v != v.strip():
        bad.append("linha %d: espaço nas pontas do valor" % n); continue
    if k[1] != "Description" and any(ord(c) > 126 for c in t):
        bad.append("linha %d: caractere fora do ASCII fora do Description" % n); continue
    if k == ("Service", "Environment"):
        e = re.fullmatch(r"([A-Z_]+)=([^\s\"\x27\\]*)", v)
        if not e or e.group(1) not in ENV or not re.fullmatch(ENV[e.group(1)], e.group(2)):
            bad.append("Environment=%s fora da allowlist" % v[:80])
        else:
            envn[e.group(1)] = envn.get(e.group(1), 0) + 1
    elif k in FIX:
        if v not in FIX[k]:
            bad.append("%s=%s fora do valor fixo" % (k[1], v[:80]))
    elif k in FREE:
        if not re.fullmatch(FREE[k], v):
            bad.append("%s=%s fora da forma" % (k[1], v[:80]))
    else:
        bad.append("diretiva fora da allowlist: [%s] %s" % k)
    seen.add(k)
for k in sorted(REQ - seen):
    bad.append("falta %s" % k[1])
for name, c in envn.items():
    if c > 1:
        bad.append("Environment %s aparece %d vezes (a última venceria)" % (name, c))
if envn.get("BRAIN_HUB_DIR", 0) != 1:
    bad.append("BRAIN_HUB_DIR ausente na unit gerada")
print("; ".join(bad[:6]))
sys.exit(1 if bad else 0)
' "${APP_PROD}" "${EXEC_HUB}" "${WORKER_PROD}"
}

hub_live_ok() { # <inv>; rc 0 = provado; imprime o que falta
  local inv="$1" j bad=""
  j="$(journal_of_inv "${inv}")"
  local l; l="$(grep -F '"msg":"brain hub worker listening"' <<< "${j}")"
  if [ -z "${l}" ]; then bad="${bad} sem a linha 'brain hub worker listening' nesta invocação;"
  else grep -qF "\"hub\":\"${WORKER_PROD}\"" <<< "${l}" || bad="${bad} o worker desta invocação não declara hub=${WORKER_PROD};"; fi
  if [ -S "${SOCK}" ]; then
    [ "$(stat -c '%a %G' "${SOCK}" 2>/dev/null)" = "660 ${SOCK_GROUP}" ] || bad="${bad} o socket não é 0660 do grupo ${SOCK_GROUP} ($(stat -c '%a %G' "${SOCK}" 2>/dev/null));"
  else bad="${bad} sem o socket ${SOCK#"${R}"};"; fi
  local nr; nr="$(nrestarts_of "${UNIT_HUB}")"
  [ "${nr}" = 0 ] || bad="${bad} NRestarts=${nr:-?} (reiniciou sozinho);"
  systemctl is-active -q "${UNIT_HUB}" || bad="${bad} a unit não está ativa;"
  [ -z "${bad}" ] || { echo "${bad# }"; return 1; }
}

UNDO=""; DEPS_TOUCHED=0; REARM=0; TMPD=""
# um EXIT só: limpa o temporário e, com REARM=1, religa o worker (o caminho de falha depois do stop)
on_exit() {
  [ -n "${TMPD}" ] && rm -rf "${TMPD}"
  if [ "${REARM}" = 1 ]; then priv systemctl start "${UNIT_HUB}" || echo "[${NAME}] ATENÇÃO: religamento automático FALHOU — worker PARADO" >&2; fi
}
trap on_exit EXIT
hub_fail() {
  printf '[%s] ERRO: %s\n' "${NAME}" "$*" >&2
  [ "${DEPS_TOUCHED}" = 1 ] && printf '[%s] worker DEIXADO PARADO de propósito: node_modules pode estar pela metade e o ExecStart vive lá dentro.\n' "${NAME}" >&2
  [ -n "${UNDO}" ] && printf '[%s] desfazer: %s\n' "${NAME}" "${UNDO}" >&2
  exit 1
}

do_hub() {
  say "── hub (${UNIT_HUB})"
  systemctl is-active -q "${UNIT_HUB}" || die 1 "o worker do hub não está ativo: triagem primeiro, update depois"
  local a0 br inst src gen why
  [ "$(git -C "${APP}" rev-parse --abbrev-ref HEAD 2>/dev/null)" = main ] || die 1 "o clone de código do worker (${APP_PROD}) não está na main"
  [ -z "$(git --no-optional-locks -C "${APP}" status --porcelain --untracked-files=no 2>/dev/null)" ] || die 1 "o clone de código do worker tem mudança rastreada: triagem primeiro"
  a0="$(git -C "${APP}" rev-parse HEAD)" || die 2 "não li o HEAD de ${APP_PROD}"
  git -C "${APP}" fetch -q origin || die 2 "git fetch no clone de código do worker falhou"
  git -C "${APP}" cat-file -e "${SERVED_HEAD}^{commit}" 2>/dev/null || die 1 "o sha servido ${SERVED_HEAD:0:12} não está na origin do clone do worker"
  git -C "${APP}" merge-base --is-ancestor "${a0}" "${SERVED_HEAD}" || die 1 "o clone do worker (${a0:0:12}) não é ancestral do servido (${SERVED_HEAD:0:12}): divergiu, resolva antes"
  worker_check
  inst="$(priv cat -- "${UNIT_DIR}/${UNIT_HUB}.service" 2>/dev/null)" || die 2 "não li a unit instalada do hub"
  src="$(git -C "${APP}" show "${SERVED_HEAD}:${UNIT_HUB_REL}" 2>/dev/null)" || die 1 "o sha ${SERVED_HEAD:0:12} não tem ${UNIT_HUB_REL}"
  if ! gen="$(gen_hub_unit "${src}" "${inst}" 2>&1)"; then die 1 "a unit do repo em ${SERVED_HEAD:0:12} recusada: ${gen}"; fi
  local id; id="$(sed -n 's/^Environment=BRAIN_HUB_MAESTRO_USER_ID=//p' <<< "${inst}" | head -1)"
  [ -n "${id}" ] || say "AVISO: a unit instalada não tem BRAIN_HUB_MAESTRO_USER_ID: a gerada fica como a do repo (comentada)"

  # NOOP: código no alvo, unit igual, processo de depois da última mudança e declarando a worktree do worker
  local st mv unit_same=0
  [ "${gen}" = "${inst}" ] && unit_same=1
  st="$(start_epoch "${UNIT_HUB}")"; mv="$(moved_epoch plain "${APP}")"
  if [ "${FORCE}" = 0 ] && [ "${a0}" = "${SERVED_HEAD}" ] && [ "${unit_same}" = 1 ] && [ -n "${st}" ] && [ -n "${mv}" ] && [ "${st}" -gt "${mv}" ] \
     && [ "${#WORKER_PROBLEMS[@]}" = 0 ]; then
    local why_live
    if why_live="$(hub_live_ok "$(inv_of "${UNIT_HUB}")")"; then say "hub: NOOP — em ${a0:0:12}, unit em dia, vivo provado"; return 0; fi
    die 1 "NOOP (nada a atualizar) e o vivo do hub NÃO está provado: ${why_live}. Religar provando: ! bash ops/update-persona-hub.sh hub --restart"
  fi
  [ "${FORCE}" = 1 ] && say "--restart: religando o worker mesmo em dia"

  say "hub: código ${a0:0:12} → ${SERVED_HEAD:0:12} · unit $( [ "${unit_same}" = 1 ] && echo igual || echo 'muda') · lock $(git -C "${APP}" diff --quiet "${a0}" "${SERVED_HEAD}" -- package-lock.json && echo igual || echo 'MUDA (npm ci)')"
  if [ "${unit_same}" = 0 ]; then
    say "diff da unit (instalada → gerada; o id do maestro mascarado):"
    diff <(printf '%s\n' "${inst}") <(printf '%s\n' "${gen}") | { if [ -n "${id}" ]; then sed "s|${id}|$(mask "${id}")|g"; else cat; fi; } | sed 's/^/      /'
  fi
  if [ "${#WORKER_PROBLEMS[@]}" -gt 0 ]; then
    local p; for p in "${WORKER_PROBLEMS[@]}"; do printf '[%s] RECUSA: %s\n' "${NAME}" "${p}" >&2; done
    migration_act >&2
    die 1 "a worktree própria do worker não está pronta: o hub não sobe no checkout da sessão"
  fi
  # a unit gerada passa no systemd-analyze ANTES de parar qualquer coisa (o tipo se lê do sufixo: o temporário é um
  # diretório, e a unit leva o nome dela); no ensaio também
  TMPD="$(mktemp -d)" || die 2 "mktemp"
  chmod 755 "${TMPD}"; ( umask 022; printf '%s\n' "${gen}" > "${TMPD}/${UNIT_HUB}.service" ) || die 2 "não escrevi a unit gerada"
  priv systemd-analyze verify "${TMPD}/${UNIT_HUB}.service" >/dev/null 2>&1 || die 1 "systemd-analyze verify reprova a unit gerada: nada foi parado nem trocado"
  say "unit gerada: allowlist e systemd-analyze verify ok"
  if [ "${APPLY}" != 1 ]; then
    plan "backup: cp -p ${UNIT_DIR#"${R}"}/${UNIT_HUB}.service ${STATE#"${R}"}/${UNIT_HUB}.service.<ts>"
    plan "sudo systemctl stop ${UNIT_HUB}   (religamento automático se falhar antes do npm ci)"
    plan "git -C ${APP_PROD} merge --ff-only ${SERVED_HEAD:0:12}; npm ci --ignore-scripts só se o lock mudou"
    plan "sudo install -m 644 <unit gerada> ${UNIT_DIR#"${R}"}/${UNIT_HUB}.service && sudo systemctl daemon-reload"
    plan "sudo systemctl start ${UNIT_HUB}; conferência: invocação nova, 'listening' com hub=${WORKER_PROD}, socket 0660 ${SOCK_GROUP}, NRestarts 0"
    say "desfazer (para o --apply): git -C ${APP_PROD} reset --hard ${a0:0:12} && (cd ${APP_PROD} && npm ci --ignore-scripts --no-audit --no-fund) && sudo install -m 644 <backup da unit> ${UNIT_DIR#"${R}"}/${UNIT_HUB}.service && sudo systemctl daemon-reload && sudo systemctl restart ${UNIT_HUB}"
    return 0
  fi

  # ── APPLY ──
  local ts bak old_inv
  ts="$(date -u +%Y%m%dT%H%M%SZ)"; mkdir -p "${STATE}" || die 2 "não criei ${STATE}"
  bak="${STATE}/${UNIT_HUB}.service.${ts}"
  printf '%s\n' "${inst}" > "${bak}" && chmod 600 "${bak}" || die 2 "backup da unit falhou"
  [ "$(cat "${bak}")" = "${inst}" ] || die 2 "o backup ${bak} não é a unit instalada"
  UNDO="git -C ${APP_PROD} reset --hard ${a0} && (cd ${APP_PROD} && npm ci --ignore-scripts --no-audit --no-fund) && sudo install -m 644 ${bak#"${R}"} ${UNIT_DIR#"${R}"}/${UNIT_HUB}.service && sudo systemctl daemon-reload && sudo systemctl restart ${UNIT_HUB}"
  say "backup da unit: ${bak#"${R}"}"
  old_inv="$(inv_of "${UNIT_HUB}")"
  priv systemctl stop "${UNIT_HUB}" || hub_fail "systemctl stop recusou"
  REARM=1
  git -C "${APP}" merge --ff-only -q "${SERVED_HEAD}" || hub_fail "fast-forward de ${APP_PROD} até ${SERVED_HEAD:0:12} recusou"
  [ "$(git -C "${APP}" rev-parse HEAD)" = "${SERVED_HEAD}" ] || hub_fail "${APP_PROD} não ficou em ${SERVED_HEAD:0:12}"
  if ! git -C "${APP}" diff --quiet "${a0}" HEAD -- package-lock.json; then
    # durante o npm ci NÃO se religa: o ExecStart vive no node_modules, e religar sobre metade é crashloop
    REARM=0; DEPS_TOUCHED=1
    (cd "${APP}" && npm ci --ignore-scripts --no-audit --no-fund) || hub_fail "npm ci em ${APP_PROD} falhou"
    DEPS_TOUCHED=0
    REARM=1  # o npm ci terminou inteiro: religar (código novo, unit antiga) volta a ser seguro
  fi
  if [ "${TEST}" = 1 ]; then install -m 644 "${TMPD}/${UNIT_HUB}.service" "${UNIT_DIR}/${UNIT_HUB}.service"
  else sudo -n install -m 644 -o root -g root "${TMPD}/${UNIT_HUB}.service" "${UNIT_DIR}/${UNIT_HUB}.service"; fi || hub_fail "install da unit falhou"
  priv systemctl daemon-reload || hub_fail "daemon-reload falhou"
  systemctl show -p Environment "${UNIT_HUB}" 2>/dev/null | grep -qF "BRAIN_HUB_DIR=${WORKER_PROD}" || hub_fail "a unit carregada não traz BRAIN_HUB_DIR=${WORKER_PROD}"
  priv systemctl reset-failed "${UNIT_HUB}" 2>/dev/null || true
  priv systemctl start "${UNIT_HUB}" || hub_fail "systemctl start recusou"
  REARM=0

  # conferência no boot DESTA invocação: espera ativa pela linha 'listening' (o socket nasce depois do import)
  local inv="" why_live="não medido" _
  for _ in $(seq 1 15); do
    inv="$(inv_of "${UNIT_HUB}")"
    if [ -n "${inv}" ] && [ "${inv}" != "${old_inv}" ] && why_live="$(hub_live_ok "${inv}")"; then break; fi
    sleep 2
  done
  [ -n "${inv}" ] && [ "${inv}" != "${old_inv}" ] || hub_fail "o start não trouxe uma invocação NOVA do worker"
  hub_live_ok "${inv}" >/dev/null || hub_fail "o worker NO AR e NÃO provado: ${why_live}"
  say "hub: OK — ${a0:0:12} → ${SERVED_HEAD:0:12}, invocação ${old_inv:0:8} → ${inv:0:8}, hub=${WORKER_PROD}, socket 0660 ${SOCK_GROUP}"
  say "desfazer: ${UNDO}"
}

echo "== $(date -u +%FT%TZ) ${NAME} ${TARGET_ARG} · modo: $([ "${APPLY}" = 1 ] && echo APPLY || echo ENSAIO)"
served_head
case "${TARGET_ARG}" in
  persona) do_persona ;;
  hub) do_hub ;;
  all) do_hub; do_persona ;;
esac
if [ "${APPLY}" = 1 ]; then say "✓ RESULTADO: ${TARGET_ARG} em dia e provado"
else
  case "${TARGET_ARG}" in persona) touched="nada mudou" ;; *) touched="nada mudou além do fetch do clone do worker" ;; esac
  say "✓ RESULTADO: ensaio sem recusa; ${touched}. Para executar: ! bash ops/update-persona-hub.sh ${TARGET_ARG} --apply"
fi
