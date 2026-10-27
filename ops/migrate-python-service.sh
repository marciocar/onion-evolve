#!/usr/bin/env bash
# migrate-python-service.sh — troca o intérprete dos serviços Python da VPS pelo CPython de patch FIXO em
# /opt/onion-python (core-only).
#
# POR QUE EXISTE (2026-10-27, decisões do maestro no /meta:decide, seladas no grafo
# docs/onion/graph/sinais-de-campo-2026-09.kg.yaml: D_PY315_SERVICOS_VENV_DEDICADO_1027,
# D_PY315_CHAT_RUNNER_MIGRA_1027, D_PY315_YAML_LEITOR_PURO_ATE_604_1027 e D_PY315_EXECUCAO_POR_OPS_E_OPT_1027): os dois
# MCPs de grafo rodavam no /usr/bin/python3 3.12 com os pacotes do apt (jsonschema 4.10.3, PyYAML 6.0.1), e o CI do
# core testa o 3.15 com o pino por hash (jsonschema 4.26.0, PyYAML 6.0.3). Produção validava com uma lib que o CI não
# testa. A auditoria que mediu isso (stdlib, wheels, YAML, JSON, paridade) nasceu num script de scratchpad que o veto por
# alvo barrou; graduou para cá, com bancada. Molde: ops/update-kg-writer.sh e ops/stt-service.sh (trava, recusa root,
# ensaio por padrão, backup nomeado, prova ANTES da troca, rollback impresso e conferência por contagem).
#
# USO
#   ops/migrate-python-service.sh <serviço> plan              o que seria feito (só lê; nada privilegiado)
#   ops/migrate-python-service.sh <serviço> apply --yes       faz (sem --yes: recusa, rc 1, e mostra o plan)
#   ops/migrate-python-service.sh <serviço> rollback --yes    desfaz (sem --yes: recusa, rc 1)
#   ops/migrate-python-service.sh <serviço> verify            prova o estado VIVO (só lê)
#
#   serviços:
#     runtime      o CPython 3.15.2 em /opt/onion-python/cpython-3.15.2-linux-x86_64-gnu, pelo `uv python install`
#                  com destino fixo (UV_PYTHON_INSTALL_DIR) e --no-bin, dono root, sem escrita de grupo nem de outros.
#                  O uv confere o sha256 do arquivo baixado contra o manifesto dele. rollback só tira o intérprete
#                  quando nenhuma unit o usa.
#     granaai      o MCP de leitura onion-vps-mcp-kg-granaai (porta 3033)
#     writer       o escritor de grafos onion-vps-mcp-kg-writer (porta 3037; tem estado: backup antes da troca)
#     chat-runner  só plan e verify: a troca do runner do convidado é do ops/chat-runner.sh install --apply, que
#                  confere o intérprete na allowlist de diretivas. Aqui se prova que o efetivo é o 3.15.2.
#
# O QUE O apply --yes DE granaai|writer FAZ (falha imprime o rollback e sai; nunca o executa às cegas):
#   1. trava e pré-voo: o intérprete de /opt prova ser o 3.15.2, dono root; a unit ativa, /health UP com o número de
#      tools que o CÓDIGO servido declara (por AST); o ExecStart de hoje é o /usr/bin/python3 com o server.py servido; a
#      worktree servida está limpa; o drop-in ainda não existe
#   2. venv em /opt/onion-venvs/<serviço>-py3.15.2-<sha12 do requirements.txt>: criado e populado pelo OPERADOR (o
#      sdist do PyYAML compila sem root), com o pino POR HASH da worktree servida
#      (vendor/kg-ssot/tools/requirements.txt, o mesmo que o CI testa) e PYYAML_FORCE_LIBYAML=0 (o 6.0.3 não tem wheel
#      cp315; o leitor sai puro, decisão D_PY315_YAML_LEITOR_PURO_ATE_604_1027); depois passa a root e perde a escrita.
#      Os DOIS serviços levam as libs: o PATH do venv faz o kg-radar.sh que eles chamam usar o python3 do venv
#   3. PROVA ANTES DA TROCA, no intérprete novo e com o PATH do venv: o selftest do serviço (o da worktree servida,
#      contra o server.py servido) e a PARIDADE: o kg_validate.py servido sobre as fixtures de conformidade do
#      kg-ssot e o kg-radar.sh servido sobre um grafo real, no intérprete de hoje e no novo, com a saída comparada
#      byte a byte. Reprovou: a unit nem foi tocada
#   4. (writer) backup nomeado da raiz de dados, 0600, conferido
#   5. drop-in 50-python.conf: zera o ExecStart e o refaz com o python do venv e os MESMOS argumentos de hoje, e põe o
#      bin do venv à frente do PATH (sem ele o kg-radar.sh seguiria no python3 3.12 e o serviço julgaria com dois
#      intérpretes); daemon-reload e restart
#   6. conferência: o verify inteiro
#
# O verify de granaai|writer reprova se: a unit não está ativa; /health não está UP com as tools do código; o drop-in
#   não é o renderizado; o processo vivo (/proc/<pid>/exe) não é o 3.15.2 de /opt; o PATH da unit não começa no venv;
#   o venv não é de root ou aceita escrita; as libs não são as do pino; o selftest reprova no intérprete novo; ou a
#   paridade antes × depois diverge.
#
# EXIT: 0 ok · 1 problema medido ou recusado · 2 não pude medir (trava, sudo, unit, health, fonte) · 3 uso inválido
#
# MODO DE TESTE (bancada): ONION_MIGRATE_PY_TEST=1 com ONION_MIGRATE_PY_ROOT, uma raiz de sandbox que prefixa TODO
#   caminho de produção (/opt, /etc/systemd/system, /proc, /usr/bin/python3, as worktrees servidas, a raiz de dados e
#   a pasta de backup). Nele nada passa por sudo, o dono esperado é quem roda, e systemctl, uv e curl vêm do PATH e TÊM
#   de ser falsos (fora de /usr, /bin e /sbin): um systemctl real reiniciaria a unit de produção. Qualquer
#   ONION_MIGRATE_PY_* sem o modo de teste é uso inválido (rc 3): produção não se redireciona por ambiente.
set -uo pipefail

NAME=migrate-python
PY_VERSION=3.15.2
PY_MINOR=3.15
PY_KEY="cpython-${PY_VERSION}-linux-x86_64-gnu"
MARKER="# onion-migrate-python: v1"
COMPLETE=.onion-venv-complete
DROPIN_NAME=50-python.conf
SYS_PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# o intérprete do runner do convidado: o MESMO literal do ops/chat-runner.sh (RUNNER_PY) e do template do bridge
# (deploy/chat-runner/onion-chat@.service.in). A bancada confere que os dois scripts dizem o mesmo.
RUNNER_PY=/opt/onion-python/cpython-3.15.2-linux-x86_64-gnu/bin/python3.15
# o grafo real da paridade do radar (existe em toda worktree servida desde 2026-07)
RADAR_GRAPH=docs/onion/graph/onion-identity-2026-07.kg.yaml
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

take_lock() { { exec 9>"${LOCK}"; } 2>/dev/null || die 2 "não abri a trava ${LOCK}"; flock -n 9 || die 2 "outra execução segura ${LOCK}"; }
say() { printf '[%s] %s\n' "${NAME}" "$*"; }
die() { local rc="$1"; shift; printf '[%s] ERRO: %s\n' "${NAME}" "$*" >&2; exit "${rc}"; }
usage() { sed -n '/^# USO/,/^# O QUE O apply/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 3; }

case "${1:-}" in -h|--help) sed -n '/^# USO/,/^# MODO DE TESTE/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 0 ;; '') usage ;; esac

# ── modo: produção ou teste declarado ──────────────────────────────────────────────────────────────────
TEST=0; R=""
if [ "${ONION_MIGRATE_PY_TEST:-}" = 1 ]; then
  TEST=1
  R="${ONION_MIGRATE_PY_ROOT:?modo de teste exige ONION_MIGRATE_PY_ROOT}"
  R="$(realpath -m -- "${R}")"
  # a raiz `/` (o realpath tira a barra final: `//` não casava com `/`, achado 4 da passada adversarial) daria os
  # caminhos de produção com o prefixo vazio
  case "${R}" in /|/opt|/opt/*|/etc|/etc/*|/usr|/usr/*|/var|/var/*|/proc|/proc/*|/home/marcio/mcp-kg*) die 3 "modo de teste com raiz de produção: recusado (${R})" ;; esac
  # os falsos moram AO LADO da raiz de sandbox, pelo DESTINO (achado 5: o nome não basta; o uv real mora fora de /usr,
  # em ~/.local/bin, e um symlink para o /usr/bin/systemctl passaria por nome)
  for _b in systemctl uv curl; do
    _w="$(command -v "${_b}" 2>/dev/null || true)"; _w="${_w:+$(readlink -f -- "${_w}")}"
    case "${_w}" in "$(dirname -- "${R}")"/*) : ;; *) die 3 "modo de teste exige ${_b} FALSO no PATH, ao lado da raiz de sandbox (achado: ${_w:-nenhum}): um real mexeria na produção" ;; esac
  done
  OWNER="$(id -un)"; UV="$(command -v uv)"
else
  [ -n "${ONION_MIGRATE_PY_TEST:-}" ] && die 3 "ONION_MIGRATE_PY_TEST só aceita 1"
  if compgen -e | grep -E '^ONION_MIGRATE_PY_' >/dev/null; then
    die 3 "variável ONION_MIGRATE_PY_* sem ONION_MIGRATE_PY_TEST=1: produção não se redireciona por ambiente"
  fi
  OWNER=root; UV="${HOME}/.local/bin/uv"
  # o wrapper roda como root, por sudo, o que ele mesmo renderiza: tem de ser o RASTREADO e limpo de um checkout
  _f="${SELF_DIR}/$(basename "${BASH_SOURCE[0]}")"
  git -C "${SELF_DIR}" ls-files --error-unmatch -- "${_f}" >/dev/null 2>&1 \
    || die 3 "${_f} não é arquivo rastreado de um checkout: rode o wrapper do repositório, não uma cópia"
  git -C "${SELF_DIR}" diff --quiet HEAD -- "${_f}" 2>/dev/null \
    || die 3 "${_f} tem mudança não commitada: rode o wrapper como está no commit"
fi
[ "$(id -u)" -eq 0 ] && die 3 "rodando como root: rode como o operador (o wrapper chama sudo onde precisa)"

priv() { if [ "${TEST}" = 1 ]; then "$@"; else sudo -n "$@"; fi; }

# ── argumentos: lista FECHADA ─────────────────────────────────────────────────────────────────────────
SVC="$1"; MODE="${2:-}"; YES=0
[ $# -ge 2 ] || usage
shift 2
while [ $# -gt 0 ]; do
  case "$1" in
    --yes) case "${MODE}" in apply|rollback) YES=1 ;; *) die 3 "--yes só no apply e no rollback" ;; esac ;;
    *) die 3 "opção não aceita: $1 (a versão, os caminhos e as units são fixos)" ;;
  esac
  shift
done
case "${MODE}" in plan|apply|rollback|verify) : ;; *) usage ;; esac

# ── os caminhos (todo absoluto de produção ganha o prefixo da sandbox no modo de teste) ──────────────
PYROOT="${R}/opt/onion-python"
PYDIR="${PYROOT}/${PY_KEY}"
PYBASE="${PYDIR}/bin/python${PY_MINOR}"
VENVROOT="${R}/opt/onion-venvs"
UNIT_DIR="${R}/etc/systemd/system"
PROC="${R}/proc"
OLD_PY="${R}/usr/bin/python3"
OLD_BIN="${R}/usr/bin"
HTRIES=15; HSLEEP=2   # /health volta em até ~30 s; na bancada, duas tentativas sem espera
if [ "${TEST}" = 1 ]; then HTRIES=2; HSLEEP=0; LOCK="${R}/lock"; BK_DIR="${R}/backups/onion-chat-kg"; RUN_TAIL="${PATH}"
else LOCK="/run/user/$(id -u)/onion-migrate-python.lock"; BK_DIR="${HOME}/backups/onion-chat-kg"; RUN_TAIL="${SYS_PATH}"; fi

case "${SVC}" in
  runtime|chat-runner) : ;;
  granaai) UNIT=onion-vps-mcp-kg-granaai; CODE="${R}/home/marcio/mcp-kg/core-served"; REL=ops/mcp-onion-kg
           HEALTH=http://172.23.0.1:3033/health; DATA="" ;;
  writer)  UNIT=onion-vps-mcp-kg-writer; CODE="${R}/home/marcio/mcp-kg/core-writer"; REL=ops/mcp-onion-kg-writer
           HEALTH=http://172.23.0.1:3037/health; DATA="${R}/var/lib/onion-chat-kg" ;;
  *) die 3 "serviço desconhecido: ${SVC} (runtime | granaai | writer | chat-runner)" ;;
esac

# ── o intérprete de /opt ─────────────────────────────────────────────────────────────────────────────
py_version() { "$1" -I -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])' 2>/dev/null; }
# runtime_state → imprime um problema por linha (vazio = o intérprete vale); rc 0 sempre
runtime_state() {
  [ -x "${PYBASE}" ] || { echo "AUSENTE ${PYBASE}"; return 0; }
  local v; v="$(py_version "${PYBASE}")"
  [ "${v}" = "${PY_VERSION}" ] || echo "${PYBASE} responde '${v:-nada}', não ${PY_VERSION}"
  [ "$(realpath -m -- "${PYBASE}")" = "$(realpath -m -- "${PYDIR}")/bin/python${PY_MINOR}" ] || echo "${PYBASE} aponta para fora de ${PYDIR}"
  # o symlink tem modo 0777 por natureza (o do python3 → python3.15 inclusive): só o que não é link é julgado
  local bad; bad="$( { find "${PYROOT}" -maxdepth 0 \( ! -user "${OWNER}" -o -perm /022 \) -print
                       find "${PYDIR}" ! -type l \( ! -user "${OWNER}" -o -perm /022 \) -print; } 2>/dev/null | head -3)"
  [ -z "${bad}" ] || echo "em ${PYDIR}, dono ≠ ${OWNER} ou escrita de grupo/outros: $(tr '\n' ' ' <<<"${bad}")"
  return 0
}
need_runtime() {
  local p; p="$(runtime_state)"
  [ -z "${p}" ] && return 0
  case "${p}" in AUSENTE*) die 1 "o intérprete não está instalado (${PYBASE}): rode antes ops/migrate-python-service.sh runtime apply --yes" ;; esac
  die 1 "o intérprete de /opt não vale: ${p}"
}

# ── a unit ───────────────────────────────────────────────────────────────────────────────────────────
DROPDIR=""; DROPIN=""
[ -n "${UNIT:-}" ] && { DROPDIR="${UNIT_DIR}/${UNIT}.service.d"; DROPIN="${DROPDIR}/${DROPIN_NAME}"; }
REQ_REL=vendor/kg-ssot/tools/requirements.txt

health_tools() {  # o número de tools do /health, ou nada se não estiver UP
  curl -fsS -m 5 "${HEALTH}" 2>/dev/null | python3 -I -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(1)
if d.get("status") == "UP" and isinstance(d.get("tools"), int): print(d["tools"])
else: sys.exit(1)' 2>/dev/null || true
}
expected_tools() {  # as chaves do dict TOOLS do server.py servido, por AST (nunca digitado)
  python3 -I - "$1" <<'PY' 2>/dev/null
import ast, sys
t = ast.parse(open(sys.argv[1], encoding="utf-8").read())
for n in t.body:
    if isinstance(n, ast.Assign) and isinstance(n.value, ast.Dict) and any(isinstance(x, ast.Name) and x.id == "TOOLS" for x in n.targets):
        print(len(n.value.keys)); break
else:
    sys.exit(1)
PY
}
proc_exe() {  # o binário que o processo vivo da unit roda de fato
  local pid; pid="$(systemctl show "${UNIT}" -p MainPID --value 2>/dev/null)"
  [ -n "${pid}" ] && [ "${pid}" != 0 ] || { echo "?"; return 0; }
  readlink -f -- "${PROC}/${pid}/exe" 2>/dev/null || echo "?"
}
# o argv do ExecStart CARREGADO (o fragmento + drop-ins), sem o intérprete: os argumentos que o drop-in mantém
exec_argv() { systemctl show "${UNIT}" -p ExecStart --value 2>/dev/null | sed -n 's/.*argv\[\]=\([^;]*\) ;.*/\1/p' | head -1 | sed 's/ *$//'; }
# o PATH que o processo vivo TEM (passada adversarial, achado 3): um PATH= no EnvironmentFile= da unit vence o
# Environment= do drop-in, e o systemctl show mostraria só o do drop-in. O serviço roda na conta do operador, então o
# environ é legível sem sudo; daqui sai SÓ a linha PATH= (o resto do environ, onde mora o token, nunca é impresso)
proc_path() {
  local pid; pid="$(systemctl show "${UNIT}" -p MainPID --value 2>/dev/null)"
  [ -n "${pid}" ] && [ "${pid}" != 0 ] || return 0
  tr '\0' '\n' < "${PROC}/${pid}/environ" 2>/dev/null | sed -n 's/^PATH=//p' | tail -1
}

req_file() { echo "${CODE}/${REQ_REL}"; }
# dono e modo do venv E da pasta-mãe (achado 6: com a mãe do operador, ele trocaria o diretório conferido inteiro);
# o symlink tem modo 0777 por natureza e fica de fora. Vazio = vale.
venv_owner_problems() {
  find "${VENVROOT}" -maxdepth 0 \( ! -user "${OWNER}" -o -perm /022 \) -print 2>/dev/null
  find "$1" ! -type l \( ! -user "${OWNER}" -o -perm /022 \) -print 2>/dev/null | head -3
}
venv_dir() { local h; h="$(sha256sum < "$(req_file)" | cut -c1-12)"; echo "${VENVROOT}/${SVC}-py${PY_VERSION}-${h}"; }
# os pinos (nome==versão) do requirements.txt, normalizados, para conferir o que o venv tem
# Só o que o instalador instala NESTE python (passada adversarial, achado 1: o `typing-extensions … ; python_version <
# "3.13"` não entra no 3.15, e exigi-lo travava o apply e o verify). O marcador é avaliado contra o PY_VERSION; um
# marcador fora da forma `python_version <op> "X.Y"` sai como pino ilegível, e o chamador recusa (fail-closed).
req_pins() {
  python3 -I - "$(req_file)" "${PY_VERSION}" <<'PY' | sort
import operator, re, sys
path, ver = sys.argv[1], tuple(int(x) for x in sys.argv[2].split(".")[:2])
ops = {"<": operator.lt, "<=": operator.le, ">": operator.gt, ">=": operator.ge, "==": operator.eq, "!=": operator.ne}
for line in open(path, encoding="utf-8"):
    m = re.match(r"^([A-Za-z0-9_.-]+)==([^ ;\\]+)\s*(?:;\s*([^\\]*?))?\s*\\?\s*$", line)
    if not m:
        continue
    name, v, marker = m.group(1).lower().replace("_", "-"), m.group(2), (m.group(3) or "").strip()
    if marker:
        mm = re.fullmatch(r'python_version\s*(<=|>=|==|!=|<|>)\s*"(\d+)\.(\d+)"', marker)
        if not mm:
            print("MARCADOR-ILEGIVEL==%s" % name); continue
        if not ops[mm.group(1)](ver, (int(mm.group(2)), int(mm.group(3)))):
            continue
    print("%s==%s" % (name, v))
PY
}
venv_pins() {
  "$1/bin/python" -I - <<'PY' 2>/dev/null | sort
import importlib.metadata as m
for d in m.distributions():
    print("%s==%s" % (d.metadata["Name"].lower().replace("_", "-"), d.version))
PY
}

render_dropin() {  # render_dropin <venv> <argumentos do ExecStart de hoje, sem o intérprete>
  cat <<EOF
${MARKER}
# ${DROPIN} — o intérprete do serviço é o CPython ${PY_VERSION} de /opt, num venv dedicado com o pino por hash.
# Gerado por ops/migrate-python-service.sh ${SVC} apply. Remover este arquivo (e daemon-reload, restart) = voltar ao
# /usr/bin/python3 do sistema. O PATH põe o venv na frente: o kg-radar.sh que o serviço chama usa o mesmo python3.
[Service]
ExecStart=
ExecStart=$1/bin/python $2
Environment=PATH=$1/bin:${SYS_PATH}
EOF
}

rollback_text() {
  cat >&2 <<EOF
[${NAME}] ─── ROLLBACK (do maestro, fora da sessão: \`!\` no prompt) ───
  bash ops/migrate-python-service.sh ${SVC} rollback --yes
  # à mão, se o wrapper não puder: sudo rm -f ${DROPIN} && sudo rmdir --ignore-fail-on-non-empty ${DROPDIR}
  #                                sudo systemctl daemon-reload && sudo systemctl restart ${UNIT} && curl -fsS ${HEALTH}
  # o venv fica: sem o drop-in, nada o usa
EOF
}

# ── a prova: selftest e paridade, num intérprete ─────────────────────────────────────────────────────
run_selftest() {  # run_selftest <venv> → imprime a última linha; rc do selftest
  local st="${CODE}/${REL}/selftest.py" args out rc
  [ -f "${st}" ] || { echo "sem ${st}"; return 2; }
  if [ "${SVC}" = writer ]; then args=(--server "${CODE}/${REL}/server.py" --code-root "${CODE}"); else args=(--server "${CODE}/${REL}/server.py"); fi
  out="$(cd "${CODE}" && env PATH="$1/bin:${RUN_TAIL}" "$1/bin/python" -I -B "${st}" "${args[@]}" 2>&1)"; rc=$?
  printf '%s\n' "${out}" | grep -E '^(FAIL|TOTAL)' | tail -4 | tr '\n' ' '; echo
  return "${rc}"
}
# parity_leg <bin do python3> → imprime o sha da saída (rc e stdout) do kg_validate nas fixtures e do radar no grafo
parity_leg() {
  local bin="$1" val="${CODE}/vendor/kg-ssot/tools/kg_validate.py" fx="${CODE}/vendor/kg-ssot/spec/conformance/fixtures/latest"
  local radar="${CODE}/.claude/validation/kg-radar.sh" g="${CODE}/${RADAR_GRAPH}" files rc1 rc2 o1 o2
  [ -f "${val}" ] && [ -d "${fx}" ] && [ -f "${radar}" ] && [ -f "${g}" ] || return 2
  # a perna sem o python3 dela cairia no python3 do sistema e daria "igual" sem medir nada (dogfood de 2026-10-27)
  [ -x "${bin}/python3" ] || return 2
  # todo .yaml das fixtures, os 36 do perfil estrito inclusive (achado 8). O .kg.json fica de fora, MEDIDO: o json da
  # stdlib do 3.13+ aponta outra LINHA no erro de sintaxe (2 das fixtures: veredito e código iguais, só o `line` muda), e
  # os serviços só gravam e julgam .kg.yaml; com ele, a paridade reprovaria sempre por um locator
  mapfile -t files < <(find "${fx}" -type f -name '*.yaml' | LC_ALL=C sort)
  [ "${#files[@]}" -gt 0 ] || return 2
  o1="$(cd "${CODE}" && env PATH="${bin}:${RUN_TAIL}" LC_ALL=C.UTF-8 python3 -I -B "${val}" --format json -- "${files[@]}" 2>&1)"; rc1=$?
  # rc 0 ou 1 é veredito; outro (2 = uso, o vendor antigo sem --format) é "não julgou", nunca igualdade
  case "${rc1}" in 0|1) : ;; *) return 2 ;; esac
  # rc 1 também é o de um traceback (achado 9): só conta como veredito a saída na forma do relatório do contrato
  grep -qE '"schema_version": *"kg-ssot\.verdict/1"' <<<"${o1}" || return 2
  o2="$(cd "${CODE}" && env PATH="${bin}:${RUN_TAIL}" LC_ALL=C.UTF-8 bash "${radar}" "${g}" --integrity --schema 2>&1)"; rc2=$?
  printf '%s fixtures · kg_validate rc %s sha %s · radar rc %s sha %s\n' "${#files[@]}" "${rc1}" "$(printf '%s' "${o1}" | sha256sum | cut -c1-16)" \
    "${rc2}" "$(printf '%s' "${o2}" | sha256sum | cut -c1-16)"
}
parity() {  # parity <venv> → rc 0 igual · 1 diverge · 2 não medi; imprime as duas pernas
  local a b
  a="$(parity_leg "${OLD_BIN}")" || { echo "não medi a perna de hoje (${OLD_PY}): falta o kg_validate, as fixtures, o radar ou o grafo na worktree servida, ou o kg_validate não julgou (o vendor antigo não tem --format: suba a worktree servida para a origin/main)"; return 2; }
  b="$(parity_leg "$1/bin")" || { echo "não medi a perna nova (${1}/bin/python3 ausente, ou o kg_validate não julgou)"; return 2; }
  echo "hoje (${OLD_PY}): ${a}"; echo "novo (${PY_VERSION}): ${b}"
  [ "${a}" = "${b}" ]
}

# ── verify de serviço: um problema por linha em VFAIL ────────────────────────────────────────────────
VFAIL=0
vok()  { say "  OK ${*}"; }
vbad() { say "  FALHA ${*}"; VFAIL=$((VFAIL+1)); }
verify_service() {
  local venv exp got exe v pe argv want
  VFAIL=0
  venv="$(venv_dir)"
  say "verify ${UNIT} (venv esperado ${venv})"
  if systemctl is-active --quiet "${UNIT}"; then vok "a unit está ativa"; else vbad "a unit não está ativa"; fi
  exp="$(expected_tools "${CODE}/${REL}/server.py")"; got="$(health_tools)"
  if [ -n "${exp}" ] && [ "${got}" = "${exp}" ]; then vok "/health UP com ${got} tools (o código declara ${exp})"
  else vbad "/health com '${got:-fora do ar}' tools; o código declara '${exp:-?}'"; fi
  local nr; nr="$(systemctl show "${UNIT}" -p NRestarts --value 2>/dev/null)"
  [ "${nr}" = 0 ] && vok "NRestarts=0" || say "  AVISO NRestarts=${nr:-?}: ler o journal"
  if [ ! -f "${DROPIN}" ]; then vbad "sem o drop-in ${DROPIN}: o serviço segue no intérprete do sistema"
  else
    argv="$(exec_argv)"; want="$(render_dropin "${venv}" "${argv#* }")"
    if [ "$(cat "${DROPIN}")" = "${want}" ]; then vok "o drop-in é o renderizado"; else vbad "o drop-in DIFERE do renderizado"; fi
  fi
  exe="$(proc_exe)"
  case "${exe}" in
    "$(realpath -m -- "${PYDIR}")/"*) v="$(py_version "${exe}")"
       if [ "${v}" = "${PY_VERSION}" ]; then vok "o processo vivo roda ${exe} (${v})"; else vbad "o processo vivo roda ${exe}, que responde '${v:-nada}', não ${PY_VERSION}"; fi ;;
    *) vbad "o processo vivo roda ${exe}, não o ${PY_VERSION} de ${PYDIR}" ;;
  esac
  pe="$(proc_path)"
  case "${pe}" in "${venv}/bin:"*) vok "o PATH da unit começa no venv" ;; *) vbad "o PATH da unit não começa em ${venv}/bin (${pe:-sem PATH}): o radar julgaria em outro python3" ;; esac
  if [ -f "${venv}/${COMPLETE}" ] && [ -d "${venv}" ] && [ -z "$(venv_owner_problems "${venv}")" ]; then
    vok "o venv é de ${OWNER} e não aceita escrita de grupo/outros"
  else vbad "o venv ${venv} está incompleto, não é de ${OWNER} ou aceita escrita"; fi
  local miss; miss="$(comm -23 <(req_pins) <(venv_pins "${venv}"))"
  if [ -z "${miss}" ] && [ -n "$(req_pins)" ]; then vok "as libs do venv são as do pino ($(req_pins | tr '\n' ' '))"; else vbad "o venv não tem os pinos: $(tr '\n' ' ' <<<"${miss:-requirements sem pino}")"; fi
  local so; so="$(run_selftest "${venv}")" && vok "selftest no ${PY_VERSION}: ${so}" || vbad "selftest reprova no ${PY_VERSION}: ${so}"
  local po prc=0; po="$(parity "${venv}")" || prc=$?
  case "${prc}" in 0) vok "paridade antes × depois igual: ${po##*novo (${PY_VERSION}): }" ;;
    1) vbad "paridade DIVERGE: $(tr '\n' '|' <<<"${po}")" ;; *) vbad "paridade não medida: ${po}" ;; esac
  [ "${VFAIL}" = 0 ]
}

# ═════════════════════════════════════════════════════════════════════════════════════════════════════
# runtime
# ═════════════════════════════════════════════════════════════════════════════════════════════════════
runtime_users() {  # quem usa o intérprete: o drop-in de um dos dois serviços (o venv dele é desta versão) e o runner
  grep -lsF -- "-py${PY_VERSION}-" "${UNIT_DIR}"/onion-vps-mcp-kg-*.service.d/"${DROPIN_NAME}" 2>/dev/null
  grep -lsF -- "/${PY_KEY}/bin/python${PY_MINOR}" "${UNIT_DIR}/onion-chat@.service" 2>/dev/null
  # e o processo VIVO (achado 13): um rollback de serviço que morreu depois do rm do drop-in deixa o processo no /opt
  local u pid exe
  for u in onion-vps-mcp-kg-writer onion-vps-mcp-kg-granaai; do
    pid="$(systemctl show "${u}" -p MainPID --value 2>/dev/null)"; [ -n "${pid}" ] && [ "${pid}" != 0 ] || continue
    exe="$(readlink -f -- "${PROC}/${pid}/exe" 2>/dev/null)"
    case "${exe}" in "$(realpath -m -- "${PYDIR}")/"*) echo "${u} (processo vivo ${pid} em ${exe})" ;; esac
  done
}
if [ "${SVC}" = runtime ]; then
  # o root NÃO executa o uv da home do operador, que o operador pode reescrever (achado 6): roda uma CÓPIA de dono
  # root, feita no apply e apagada no fim
  ROOT_UV="${PYROOT}/.uv-install/uv"
  INSTALL_CMD=(env "UV_PYTHON_INSTALL_DIR=${PYROOT}" UV_CACHE_DIR=/root/.cache/uv UV_NO_CONFIG=1 "${ROOT_UV}" python install --no-bin "${PY_KEY}")
  case "${MODE}" in
    plan|verify)
      st="$(runtime_state)"
      if [ "${MODE}" = verify ]; then
        if [ -z "${st}" ]; then say "verify OK: ${PYBASE} é ${PY_VERSION}, dono ${OWNER}, sem escrita de grupo/outros (sha256 do binário $(sha256sum < "${PYBASE}" | cut -c1-16))"; exit 0; fi
        say "verify FALHA: ${st}"; exit 1
      fi
      say "runtime ${PY_VERSION}: $([ -z "${st}" ] && echo "já instalado e válido em ${PYBASE}" || echo "${st}")"
      say "o apply --yes faria (como root, por sudo):"
      say "  install -d -m 0755 -o root -g root ${PYROOT}"
      say "  ${INSTALL_CMD[*]}"
      say "  chown -R -h root:root ${PYDIR}; chmod -R go-w ${PYDIR}; setfacl -R -b ${PYDIR}"
      say "  e prova: ${PYBASE} -I responde ${PY_VERSION}. Custo declarado: este Python não recebe o unattended-upgrades;"
      say "  patch novo = PR que muda PY_VERSION aqui e no ops/chat-runner.sh + apply de cada serviço."
      exit 0 ;;
    apply)
      [ "${YES}" = 1 ] || { say "RECUSADO: apply sem --yes. Nada foi feito."; "$0" runtime plan; exit 1; }
      take_lock
      if [ -z "$(runtime_state)" ]; then say "NOOP: ${PYBASE} já é ${PY_VERSION} e de ${OWNER}"; exit 0; fi
      priv install -d -m 0755 -o "${OWNER}" -g "$(id -gn "${OWNER}")" "${PYROOT}" || die 2 "não criei ${PYROOT} (sudo?)"
      [ -x "${UV}" ] || die 2 "uv ausente em ${UV}"
      priv install -D -m 0755 -o "${OWNER}" -g "$(id -gn "${OWNER}")" "${UV}" "${ROOT_UV}" || die 2 "não copiei o uv para ${ROOT_UV}"
      priv "${INSTALL_CMD[@]}"; irc=$?
      priv rm -rf -- "${ROOT_UV%/*}"
      [ "${irc}" = 0 ] || die 1 "o uv python install ${PY_KEY} falhou"
      [ -x "${PYBASE}" ] || die 1 "${PYBASE} não apareceu depois do install"
      priv chown -R -h "${OWNER}:$(id -gn "${OWNER}")" "${PYDIR}" && priv chmod -R go-w "${PYDIR}" || die 1 "não fechei dono e modo de ${PYDIR}"
      if command -v setfacl >/dev/null 2>&1; then priv setfacl -R -b "${PYDIR}" || die 1 "não tirei as ACLs de ${PYDIR}"; fi
      st="$(runtime_state)"; [ -z "${st}" ] || die 1 "o intérprete instalado não vale: ${st}"
      say "OK: ${PYBASE} (${PY_VERSION}), dono ${OWNER}. Rollback: ops/migrate-python-service.sh runtime rollback --yes"
      exit 0 ;;
    rollback)
      [ "${YES}" = 1 ] || { say "RECUSADO: rollback sem --yes. Nada foi feito."; exit 1; }
      take_lock
      [ -e "${PYDIR}" ] || { say "NOOP: ${PYDIR} não existe"; exit 0; }
      users="$(runtime_users | sort -u)"
      [ -z "${users}" ] || die 1 "o intérprete está em uso, desfaça antes os serviços: $(tr '\n' ' ' <<<"${users}")"
      priv rm -rf -- "${PYDIR}" || die 1 "não removi ${PYDIR}"
      if [ -L "${PYROOT}/cpython-${PY_MINOR}-linux-x86_64-gnu" ] && [ ! -e "${PYROOT}/cpython-${PY_MINOR}-linux-x86_64-gnu" ]; then
        priv rm -f -- "${PYROOT}/cpython-${PY_MINOR}-linux-x86_64-gnu"; fi
      say "rollback OK: ${PYDIR} removido (nenhuma unit o usava)"; exit 0 ;;
  esac
fi

# ═════════════════════════════════════════════════════════════════════════════════════════════════════
# chat-runner (só plan e verify)
# ═════════════════════════════════════════════════════════════════════════════════════════════════════
if [ "${SVC}" = chat-runner ]; then
  case "${MODE}" in apply|rollback) die 3 "a troca do runner é do ops/chat-runner.sh install --apply (e o rollback, pelo backup dele em /var/backups/onion-chat-runner): veja ops/migrate-python-service.sh chat-runner plan" ;; esac
  RPY="${R}${RUNNER_PY}"
  eff="$(systemctl show onion-chat@verify.service -p ExecStart --value 2>/dev/null)"
  inst="$(grep -s '^ExecStart=' "${UNIT_DIR}/onion-chat@.service" | head -1)"
  if [ "${MODE}" = plan ]; then
    say "runner do convidado: o intérprete alvo é ${RUNNER_PY} ($([ -x "${RPY}" ] && echo presente || echo 'AUSENTE: runtime apply --yes antes'))"
    say "  instalado hoje: ${inst:-sem template instalado}"
    say "  o caminho é CONTRATO em três lugares, que mudam juntos: o template do bridge (deploy/chat-runner/onion-chat@.service.in),"
    say "  a allowlist de diretivas do ops/chat-runner.sh (RUNNER_PY) e a verificação do efetivo dele. Passos, depois do merge dos dois PRs:"
    say "    bash ops/update-bridge.sh                  # o bridge servido no SHA novo (o template novo)"
    say "    bash ops/chat-runner.sh install            # ensaio: diff das units e a unit transitória com o sandbox"
    say "    bash ops/chat-runner.sh install --apply    # troca (backup das units em /var/backups/onion-chat-runner)"
    say "    bash ops/migrate-python-service.sh chat-runner verify && bash ops/chat-runner.sh verify"
    exit 0
  fi
  VFAIL=0
  case "${eff}" in *"argv[]=${RUNNER_PY} -I /run/onion-chat-bin/launcher.py ;"*) vok "o ExecStart efetivo do runner é ${RUNNER_PY}" ;;
    *) vbad "o ExecStart efetivo do runner não é ${RUNNER_PY}: $(sed -n 's/.*argv\[\]=\([^;]*\);.*/\1/p' <<<"${eff}" | head -1)" ;; esac
  v="$(py_version "${RPY}")"
  if [ "${v}" = "${PY_VERSION}" ]; then vok "${RPY} responde ${v}"; else vbad "${RPY} responde '${v:-nada}', não ${PY_VERSION}"; fi
  st="$(runtime_state)"; if [ -z "${st}" ]; then vok "o intérprete de /opt é de ${OWNER} e não aceita escrita"; else vbad "${st}"; fi
  [ "${VFAIL}" = 0 ] && { say "verify OK (a prova inteira do runner é o ops/chat-runner.sh verify)"; exit 0; }
  say "verify FALHA: ${VFAIL} problema(s)"; exit 1
fi

# ═════════════════════════════════════════════════════════════════════════════════════════════════════
# granaai | writer
# ═════════════════════════════════════════════════════════════════════════════════════════════════════
[ -f "$(req_file)" ] || die 2 "sem $(req_file) na worktree servida: não há pino por hash para o venv"
VENV="$(venv_dir)"
SERVER="${CODE}/${REL}/server.py"
[ -f "${SERVER}" ] || die 2 "sem ${SERVER}"

case "${MODE}" in
  plan)
    say "${UNIT}: $(systemctl is-active "${UNIT}" 2>/dev/null || true) · processo $(proc_exe) · /health tools=$(health_tools) (o código declara $(expected_tools "${SERVER}"))"
    say "  ExecStart carregado: $(exec_argv)"
    [ -f "${DROPIN}" ] && say "  drop-in PRESENTE (${DROPIN}): já migrado? rode verify" || say "  drop-in: ausente"
    st="$(runtime_state)"; say "  intérprete: $([ -z "${st}" ] && echo "${PYBASE} (${PY_VERSION}) válido" || echo "${st}")"
    say "  venv alvo: ${VENV} $([ -f "${VENV}/${COMPLETE}" ] && echo '(já montado: será reusado)' || echo '(a montar, pelo operador, com o pino por hash e PYYAML_FORCE_LIBYAML=0)')"
    say "  pinos: $(req_pins | tr '\n' ' ')"
    [ -n "${DATA}" ] && say "  backup antes da troca: ${DATA} → ${BK_DIR}/onion-chat-kg-<data>-pre-py${PY_VERSION}.tar.gz"
    say "  drop-in que seria gravado:"
    a="$(exec_argv)"; render_dropin "${VENV}" "${a#* }" | sed 's/^/      /'
    say "  o apply --yes prova ANTES da troca: selftest e paridade (kg_validate nas fixtures de conformidade + radar em ${RADAR_GRAPH}) no intérprete de hoje e no novo"
    exit 0 ;;
  verify)
    if verify_service; then say "verify OK"; exit 0; fi
    say "verify FALHA: ${VFAIL} problema(s)"; exit 1 ;;
  rollback)
    [ "${YES}" = 1 ] || { say "RECUSADO: rollback sem --yes. Nada foi feito."; exit 1; }
    take_lock
    [ -f "${DROPIN}" ] || { say "NOOP: sem ${DROPIN}, nada a desfazer"; exit 0; }
    grep -qxF "${MARKER}" "${DROPIN}" || die 1 "${DROPIN} não foi gerado por este wrapper (sem o marcador): desfaça à mão"
    priv rm -f -- "${DROPIN}" || die 2 "não removi ${DROPIN} (sudo?)"
    priv rmdir --ignore-fail-on-non-empty -- "${DROPDIR}" 2>/dev/null || true
    priv systemctl daemon-reload && priv systemctl restart "${UNIT}" || die 1 "daemon-reload/restart recusou: confira à mão"
    got=""; for _ in $(seq 1 "${HTRIES}"); do got="$(health_tools)"; [ -n "${got}" ] && break; sleep "${HSLEEP}"; done
    [ -n "${got}" ] || die 1 "/health não voltou depois do rollback"
    exe="$(proc_exe)"
    case "${exe}" in "$(realpath -m -- "${PYROOT}")/"*|'?') die 1 "o processo ainda roda ${exe} depois do rollback" ;; esac
    say "rollback OK: ${UNIT} em ${exe}, /health UP com ${got} tools (o venv ${VENV} fica, sem uso)"; exit 0 ;;
esac

# ── apply ────────────────────────────────────────────────────────────────────────────────────────────
[ "${YES}" = 1 ] || { say "RECUSADO: apply sem --yes. Nada foi feito; o que ele faria:"; "$0" "${SVC}" plan; exit 1; }
take_lock

# 1. pré-voo
need_runtime
systemctl is-active --quiet "${UNIT}" || die 2 "${UNIT} não está ativa: não se migra serviço doente"
EXPECTED="$(expected_tools "${SERVER}")" || die 2 "não contei as tools de ${SERVER}"
[ -n "$(health_tools)" ] || die 2 "/health de ${UNIT} não está UP antes da troca"
[ -f "${DROPIN}" ] && die 1 "já existe ${DROPIN}: rode verify (ou rollback --yes) antes"
ARGV="$(exec_argv)"
[ "${ARGV}" = "/usr/bin/python3 ${CODE#"${R}"}/${REL}/server.py" ] \
  || die 1 "o ExecStart carregado mudou (${ARGV:-vazio}); esperado /usr/bin/python3 ${CODE#"${R}"}/${REL}/server.py: confira a unit antes"
[ -z "$(git -C "${CODE}" status --porcelain 2>/dev/null)" ] || die 1 "a worktree servida ${CODE} está SUJA: o servido não é versionado"
SHA="$(git -C "${CODE}" rev-parse HEAD 2>/dev/null)" || die 2 "rev-parse da worktree servida falhou"
say "pré-voo OK: código ${SHA:0:12}, ${EXPECTED} tools, processo $(proc_exe)"

# 2. o venv (montado pelo operador; root só no fim)
if [ -f "${VENV}/${COMPLETE}" ]; then
  # reusar exige o venv já entregue (achado 2: o marcador sem o dono certo faria a unit rodar num venv do operador)
  [ -z "$(venv_owner_problems "${VENV}")" ] || die 1 "${VENV} tem o marcador mas não é de ${OWNER} ou aceita escrita: $(venv_owner_problems "${VENV}")"
  say "venv ${VENV} já montado e de ${OWNER}: reusado"
else
  [ -e "${VENV}" ] && die 1 "${VENV} existe sem o marcador de completo (montagem interrompida): remova-o (sudo rm -rf ${VENV}) e rode de novo"
  priv install -d -m 0755 -o "${OWNER}" -g "$(id -gn "${OWNER}")" "${VENVROOT}" || die 2 "não criei ${VENVROOT} (sudo?)"
  priv install -d -m 0755 -o "$(id -un)" -g "$(id -gn)" "${VENV}" || die 2 "não criei ${VENV}"
  "${UV}" venv --allow-existing --python "${PYBASE}" "${VENV}" >/dev/null || die 1 "uv venv falhou"
  PYYAML_FORCE_LIBYAML=0 "${UV}" pip install --python "${VENV}/bin/python" --require-hashes -r "$(req_file)" \
    || die 1 "uv pip install com --require-hashes falhou (nada foi trocado na unit; o venv parcial fica em ${VENV} sem o marcador)"
  "${VENV}/bin/python" -I -c 'import yaml, jsonschema, sys; from importlib.metadata import version as v; print("deps:", sys.version.split()[0], "pyyaml", yaml.__version__, "libyaml", yaml.__with_libyaml__, "jsonschema", v("jsonschema"))' \
    || die 1 "o venv não importa yaml e jsonschema"
  priv chown -R -h "${OWNER}:$(id -gn "${OWNER}")" "${VENV}" && priv chmod -R go-w "${VENV}" || die 1 "não passei ${VENV} a ${OWNER} (o venv fica sem o marcador)"
  # o marcador nasce DEPOIS da entrega e pelas mãos do dono (achado 2): marcador presente = venv de root
  priv install -m 0644 -o "${OWNER}" -g "$(id -gn "${OWNER}")" /dev/null "${VENV}/${COMPLETE}" || die 1 "não gravei o marcador de completo"
  [ -z "$(venv_owner_problems "${VENV}")" ] || die 1 "${VENV} não ficou de ${OWNER}: $(venv_owner_problems "${VENV}")"
  say "venv montado e entregue a ${OWNER}: ${VENV}"
fi
miss="$(comm -23 <(req_pins) <(venv_pins "${VENV}"))"
[ -z "${miss}" ] || die 1 "o venv não tem os pinos do requirements.txt: $(tr '\n' ' ' <<<"${miss}")"

# 3. a prova ANTES da troca
say "selftest no intérprete novo (o escritor leva ~40 s)…"
so="$(run_selftest "${VENV}")" || die 1 "selftest reprovou no ${PY_VERSION} (${so}): nada foi trocado na unit"
say "selftest: ${so}"
po="$(parity "${VENV}")"; prc=$?
printf '%s\n' "${po}" | sed "s/^/[${NAME}]   /"
[ "${prc}" = 0 ] || { [ "${prc}" = 1 ] && die 1 "a paridade antes × depois DIVERGE: nada foi trocado na unit"; die 2 "não medi a paridade: nada foi trocado na unit"; }

# 4. backup (só o escritor tem estado)
if [ -n "${DATA}" ]; then
  install -d -m 0700 "${BK_DIR}" || die 2 "não criei ${BK_DIR}"
  BK="${BK_DIR}/onion-chat-kg-$(date +%Y%m%d-%H%M%S)-pre-py${PY_VERSION}.tar.gz"
  ( umask 077; priv tar -C "$(dirname "${DATA}")" -czf "${BK}" "$(basename "${DATA}")" ) || die 1 "backup falhou: sem rede de segurança não se troca"
  priv chown "$(id -un):$(id -gn)" "${BK}"; chmod 600 "${BK}"
  [ "$(stat -c %s "${BK}")" -gt 0 ] && priv tar -tzf "${BK}" >/dev/null || die 1 "backup vazio ou ilegível (${BK})"
  say "backup: ${BK} ($(stat -c %s "${BK}") bytes, 0600)"
fi

# 5. o drop-in e a troca
priv install -d -m 0755 "${DROPDIR}" || die 2 "não criei ${DROPDIR}"
render_dropin "${VENV}" "${ARGV#* }" | priv tee "${DROPIN}" >/dev/null && priv chmod 0644 "${DROPIN}" || { rollback_text; die 1 "não gravei ${DROPIN}"; }
priv systemctl daemon-reload || { rollback_text; die 1 "daemon-reload recusou"; }
priv systemctl restart "${UNIT}" || { rollback_text; die 1 "restart recusou"; }
got=""; for _ in $(seq 1 "${HTRIES}"); do got="$(health_tools)"; [ -n "${got}" ] && break; sleep "${HSLEEP}"; done
[ -n "${got}" ] || { rollback_text; die 1 "/health não voltou em ~30 s"; }

# 6. a conferência: o verify inteiro
if ! verify_service; then rollback_text; die 1 "o verify reprovou depois da troca (${VFAIL} problema(s))"; fi
say "OK: ${UNIT} no ${PY_VERSION} de /opt, venv ${VENV}, código ${SHA:0:12} intocado"
say "FALTA (exige o token, de propósito fora daqui): o probe autenticado de uma chamada real pelo MCP."
rollback_text
exit 0
