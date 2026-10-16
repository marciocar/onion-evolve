#!/usr/bin/env bash
# =============================================================================
# currency-census.sh — o censo de ATUALIDADE: a base sobre a qual se constrói está nas versões atuais?
#
# A ORDEM QUE ELE EXECUTA (maestro, 2026-10-16, dois reforços seguidos): "temos que usar sempre as
#   versões mais atuais e não sair criando coisas em cima de base velha" e "este aviso anterior de manter
#   atualizado é eterno, não só em memoria e sessão". Doutrina: docs/knowledge-base/concepts/keep-current-doctrine.md.
#   Este script é a perna que MEDE; o hook session-currency-check.sh é a que COBRA, sozinho, sem ninguém
#   lembrar de rodar.
#
# DEFEITO DATADO (2026-10-16): o CLI do Agent SDK que serve o bridge estava em 0.3.301 com o npm já em
#   0.3.302, e nenhuma superfície avisou — o /meta:cc-update compara o SDK com o CLI do HOST (não com o
#   publicado) e só roda quando o maestro o invoca. A regra "use a base atual" vivia num preâmbulo de agente
#   escrito no scratchpad da sessão: evaporava com ela.
#
# AS SUPERFÍCIES (cada uma vira uma linha; superfície que não existe neste repo é OMITIDA, não "em dia"):
#   claude-cli        o binário em DISCO vs o dist-tag do canal no registro npm (@anthropic-ai/claude-code).
#                     O canal sai de autoUpdatesChannel em ~/.claude/settings.json (só LIDO), default latest.
#                     Processo≠disco NÃO é daqui: é do session-version-drift.sh (não duplicar).
#   agent-sdk:<r>     o @anthropic-ai/claude-agent-sdk de quem serve por SDK vs o latest do npm. Os alvos são
#                     os do censo do /meta:cc-update (mesmo arquivo, mesmo formato de 4 colunas); só o
#                     package.json é LIDO (como a conta dona, por sudo -n, ambiente limpo) — nenhum binário roda.
#   kg-ssot           o vendor/kg-ssot pinado vs a maior tag kg-ssot-v* do repositório público do produto.
#   python:<pkg>      PyYAML e jsonschema (as dependências DIRETAS do leitor do KG-SSOT) no python3 do lint vs
#                     o PyPI. O pino do contrato (vendor/kg-ssot/tools/requirements.txt) é citado na ação.
#   base:<branch>     o HEAD deste checkout vs a branch padrão do origin, lida por `git ls-remote` (NÃO faz
#                     fetch: medir não muda as refs de ninguém).
#
# ESTADOS: em-dia · defasada (com a AÇÃO de subida) · nao-medida (fonte INALCANÇÁVEL — nunca vira "em dia")
#   · ausente (falta a ferramenta que mede: PEÇA AUTORIZAÇÃO AO MAESTRO para instalar, pela fonte oficial,
#   e instale; nunca contorne nem declare "não medido" por falta de pacote).
#
# Uso: currency-census.sh [REPO_DIR] [--tsv|--notice|--table] [--fresh]
#   --tsv     superfície · instalado · atual · estado · ação (default)
#   --notice  o texto do hook: só o que NÃO está em dia; vazio quando tudo está em dia
#   --table   tabela markdown para humano
#   --fresh   ignora o cache
# Cache: ${ONION_CURRENCY_CACHE_DIR:-${XDG_RUNTIME_DIR:-/tmp}/onion-currency}, chave = caminho do repo, TTL
#   ${ONION_CURRENCY_TTL:-3600} s; leitura com alguma linha nao-medida vale só 600 s (rede voltou → re-mede).
# Env de bancada (cada fonte é trocável; DEFINIDO-vazio desliga a superfície):
#   ONION_CC_BIN · ONION_CC_CHANNEL · ONION_CURRENCY_NPM · ONION_CURRENCY_GIT · ONION_CURRENCY_PY
#   ONION_CURRENCY_SDK_TARGETS · ONION_CURRENCY_KG_SSOT_REMOTE · ONION_CURRENCY_TIMEOUT (s, default 5)
# Exit: 0 sempre que mediu (o estado está nas linhas) · 2 uso errado.
# TETO: compara com o que o REGISTRO publica, não com o que é seguro adotar — "latest" do npm/PyPI não é
#   juízo de estabilidade; o canal do CLI é o que o host segue. Não vê dependência fora destas superfícies
#   (pacotes do sistema, node/npm, o lock de outro repo). A base lê o origin deste checkout, não o de uma
#   worktree de agente. Exercitado por lint-selftest.sh (run_currency_census_selftests).
# =============================================================================
set -uo pipefail
export LC_ALL=C
REPO="."; FMT="tsv"; FRESH=0
for a in "$@"; do
  case "$a" in
    --tsv) FMT=tsv ;; --notice) FMT=notice ;; --table) FMT=table ;; --fresh) FRESH=1 ;;
    -h|--help) sed -n '2,46p' "$0"; exit 0 ;;
    --*) echo "currency-census: opção desconhecida: $a" >&2; exit 2 ;;
    *) REPO="$a" ;;
  esac
done
[ -d "${REPO}" ] || { echo "currency-census: repo inexistente: ${REPO}" >&2; exit 2; }
REPO="$(cd "${REPO}" && pwd -P)"
T="${ONION_CURRENCY_TIMEOUT:-5}"
TTL="${ONION_CURRENCY_TTL:-3600}"
CACHE_DIR="${ONION_CURRENCY_CACHE_DIR:-${XDG_RUNTIME_DIR:-/tmp}/onion-currency}"
NPM="${ONION_CURRENCY_NPM-npm}"
GIT="${ONION_CURRENCY_GIT-git}"
PY="${ONION_CURRENCY_PY-python3}"
CC_BIN="${ONION_CC_BIN-claude}"
KG_REMOTE="${ONION_CURRENCY_KG_SSOT_REMOTE:-https://github.com/marciocar/kg-ssot}"
ASK="peça autorização ao maestro para instalar"

_ver() { grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1; }
# _newer <a> <b>: 0 se a > b (semver numérico; sort -V em locale C)
_newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]; }
_row() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "${2:--}" "${3:--}" "$4" "$5"; }
# _judge <superfície> <instalado> <atual> <ação de subida>
_judge() {
  if [ "$2" = "$3" ]; then _row "$1" "$2" "$3" em-dia "-"
  elif _newer "$2" "$3"; then _row "$1" "$2" "$3" em-dia "instalado à frente do publicado (pré-release ou registro atrasado)"
  else _row "$1" "$2" "$3" defasada "$4"; fi
}

# ── a medição (cada perna escreve o seu arquivo; rodam em paralelo, cada fonte com teto de T s) ─────────
leg_cli() {
  [ -n "${CC_BIN}" ] || return 0
  if ! command -v "${CC_BIN}" >/dev/null 2>&1; then
    _row claude-cli - - ausente "o binário ${CC_BIN} não está no PATH: ${ASK} o Claude Code pelo instalador oficial (claude.ai/install.sh)"; return 0
  fi
  local disk ch latest out rc=0
  disk="$(readlink -f "$(command -v "${CC_BIN}")" 2>/dev/null | sed 's|.*/||' | _ver)"
  [ -n "${disk}" ] || disk="$(timeout "${T}" "${CC_BIN}" --version 2>/dev/null | _ver)"
  [ -n "${disk}" ] || { _row claude-cli - - nao-medida "a versão do binário em disco não se lê (readlink e --version mudos)"; return 0; }
  ch="${ONION_CC_CHANNEL-}"
  if [ -z "${ch}" ] && [ -n "${PY}" ] && [ -r "${HOME}/.claude/settings.json" ]; then
    ch="$("${PY}" -I -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get("autoUpdatesChannel") or "")
except Exception: print("")' "${HOME}/.claude/settings.json" 2>/dev/null)"
  fi
  [[ "${ch}" =~ ^[a-z]+$ ]] || ch=latest
  if [ -z "${NPM}" ] || ! command -v "${NPM}" >/dev/null 2>&1; then
    _row "claude-cli (canal ${ch})" "${disk}" - ausente "falta o npm para ler o registro: ${ASK} o Node.js/npm pela fonte oficial (nodejs.org ou o pacote da distro)"; return 0
  fi
  out="$(timeout "${T}" "${NPM}" view @anthropic-ai/claude-code "dist-tags.${ch}" 2>/dev/null)" || rc=$?
  latest="$(printf '%s' "${out}" | _ver)"
  [ -n "${latest}" ] || { _row "claude-cli (canal ${ch})" "${disk}" - nao-medida "registro npm inalcançável ou sem o dist-tag ${ch} (rc=${rc})"; return 0; }
  _judge "claude-cli (canal ${ch})" "${disk}" "${latest}" "claude update (e reinicie a sessão: /exit → claude --continue)"
}

leg_sdk() {
  local conf="${ONION_CURRENCY_SDK_TARGETS-}"
  if [ -z "${ONION_CURRENCY_SDK_TARGETS+x}" ]; then
    conf=""; [ -f "${REPO}/ops/cc-sdk-targets.tsv" ] && conf="${REPO}/ops/cc-sdk-targets.tsv"   # core-only: no adotante o arquivo não existe e a superfície some
  fi
  [ -n "${conf}" ] || return 0
  [ -r "${conf}" ] || { _row "agent-sdk" - - nao-medida "o arquivo de alvos declarado não é legível: ${conf}"; return 0; }
  if [ "$(id -u)" = 0 ]; then _row "agent-sdk" - - nao-medida "o censo roda como root: recuso ler como outra conta (rode como o operador)"; return 0; fi
  local latest="" out rc=0 nrc=0 lb acct pkg bin raw v me n=0
  me="$(id -un)"
  if [ -n "${NPM}" ] && command -v "${NPM}" >/dev/null 2>&1; then
    out="$(timeout "${T}" "${NPM}" view @anthropic-ai/claude-agent-sdk dist-tags.latest 2>/dev/null)" || nrc=$?
    latest="$(printf '%s' "${out}" | _ver)"
  fi
  while IFS=$'\t' read -r lb acct pkg bin || [ -n "${lb}" ]; do
    case "${lb}" in ''|'#'*) continue ;; esac
    n=$((n+1))
    if ! [[ "${lb}" =~ ^[A-Za-z0-9_.-]+$ ]] || [ -z "${pkg}" ]; then _row "agent-sdk" - - nao-medida "linha de alvo fora da forma (rótulo · conta · package.json · binário)"; continue; fi
    if [ "${acct}" != "-" ] && { ! [[ "${acct}" =~ ^[a-z_][a-z0-9_-]*$ ]] || [ "${acct}" = root ] || [ "$(id -u "${acct}" 2>/dev/null)" = 0 ]; }; then
      _row "agent-sdk:${lb}" - - nao-medida "conta recusada (nunca root/uid 0; forma [a-z_][a-z0-9_-]* ou -)"; continue
    fi
    if ! [[ "${pkg}" =~ ^/([^/]+/)*node_modules/@anthropic-ai/claude-agent-sdk/package\.json$ ]] || [[ "${pkg}" == *"/./"* || "${pkg}" == *"/../"* ]]; then
      _row "agent-sdk:${lb}" - - nao-medida "o package.json tem de ser <…>/node_modules/@anthropic-ai/claude-agent-sdk/package.json, absoluto e sem . ou .."; continue
    fi
    rc=0
    if [ "${acct}" = "-" ] || [ "${acct}" = "${me}" ]; then
      raw="$(timeout "${T}" head -c 1048576 -- "${pkg}" 2>/dev/null)" || rc=$?
    else
      raw="$(cd / && timeout "${T}" sudo -n -u "${acct}" /usr/bin/env -i PATH=/usr/bin:/bin head -c 1048576 -- "${pkg}" 2>/dev/null)" || rc=$?
    fi
    v=""
    [ "${rc}" = 0 ] && v="$(printf '%s' "${raw}" | "${PY:-python3}" -I -c 'import json,sys
try: print(json.load(sys.stdin).get("version",""))
except Exception: print("")' 2>/dev/null | _ver)"
    if [ -z "${v}" ]; then _row "agent-sdk:${lb}" - - nao-medida "o package.json não se lê como ${acct} (rc=${rc}: sudo -n recusado, arquivo ausente ou JSON inválido)"; continue; fi
    if [ -z "${NPM}" ] || ! command -v "${NPM}" >/dev/null 2>&1; then _row "agent-sdk:${lb}" "${v}" - ausente "falta o npm para ler o registro: ${ASK} o Node.js/npm pela fonte oficial"; continue; fi
    if [ -z "${latest}" ]; then _row "agent-sdk:${lb}" "${v}" - nao-medida "registro npm inalcançável (rc=${nrc})"; continue; fi
    _judge "agent-sdk:${lb}" "${v}" "${latest}" "suba @anthropic-ai/claude-agent-sdk para ${latest} no repo que o serve (lock incluído) e re-implante pelo caminho de deploy declarado, nunca à mão"
  done < "${conf}"
  [ "${n}" -gt 0 ] || _row "agent-sdk" - - nao-medida "o arquivo de alvos ${conf} não declara nenhum alvo"
}

leg_kg() {
  local stamp="${REPO}/vendor/kg-ssot/.kg-ssot-version" v out rc=0 latest
  [ -f "${stamp}" ] || return 0
  v="$("${PY:-python3}" -I -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get("version",""))
except Exception: print("")' "${stamp}" 2>/dev/null | _ver)"
  [ -n "${v}" ] || { _row kg-ssot - - nao-medida "o carimbo ${stamp#"${REPO}/"} não declara versão legível"; return 0; }
  if [ -z "${GIT}" ] || ! command -v "${GIT}" >/dev/null 2>&1; then _row kg-ssot "${v}" - ausente "falta o git para ler as tags do produto: ${ASK} o git pela distro"; return 0; fi
  out="$(GIT_TERMINAL_PROMPT=0 timeout "${T}" "${GIT}" ls-remote --tags --refs "${KG_REMOTE}" 'kg-ssot-v*' 2>/dev/null)" || rc=$?
  latest="$(printf '%s\n' "${out}" | sed -n 's|.*refs/tags/kg-ssot-v\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$|\1|p' | sort -V | tail -1)"
  [ -n "${latest}" ] || { _row kg-ssot "${v}" - nao-medida "o repositório do produto (${KG_REMOTE}) inalcançável ou sem tag kg-ssot-v* (rc=${rc})"; return 0; }
  _judge kg-ssot "${v}" "${latest}" "python3 -I -B vendor/kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v${latest} --source ${KG_REMOTE} (e rode o check do contrato)"
}

leg_py() {
  [ -n "${PY}" ] || return 0
  local req="${REPO}/vendor/kg-ssot/tools/requirements.txt" pkg pin inst out rc latest act pypath
  if ! command -v "${PY}" >/dev/null 2>&1; then _row "python" - - ausente "falta o ${PY} que o lint usa: ${ASK} o python3 pela distro"; return 0; fi
  pypath="$(command -v "${PY}")"
  for pkg in PyYAML jsonschema; do
    pin=""; [ -f "${req}" ] && pin="$(sed -n "s/^${pkg}==\([0-9][0-9.]*\).*/\1/p" "${req}" | head -1)"
    inst="$("${PY}" -I -c 'import importlib.metadata as m,sys
try: print(m.version(sys.argv[1]))
except Exception: print("")' "${pkg}" 2>/dev/null | _ver)"
    if [ -z "${inst}" ]; then
      _row "python:${pkg}" - "${pin:--}" ausente "${pkg} não está instalado no python do lint (${pypath}): ${ASK} ${pkg}${pin:+==${pin}} pelo PyPI (${PY} -m pip install ${pkg}${pin:+==${pin}})"; continue
    fi
    rc=0; out="$(PIP_DISABLE_PIP_VERSION_CHECK=1 timeout "${T}" "${PY}" -I -m pip index versions "${pkg}" 2>&1)" || rc=$?
    if [ "${rc}" != 0 ] && printf '%s' "${out}" | grep -q "No module named pip"; then
      _row "python:${pkg}" "${inst}" - ausente "falta o pip no python do lint (${pypath}): ${ASK} o pip (${PY} -m ensurepip ou o pacote da distro)"; continue
    fi
    latest="$(printf '%s\n' "${out}" | head -1 | grep -oiE "^${pkg} \([0-9][0-9.]*\)" | _ver)"
    [ -n "${latest}" ] || { _row "python:${pkg}" "${inst}" - nao-medida "o PyPI inalcançável pelo pip (rc=${rc})"; continue; }
    if [ -n "${pin}" ] && [ "${pin}" != "${latest}" ]; then
      act="o pino do contrato KG-SSOT é ${pin} (vendor/kg-ssot/tools/requirements.txt): a subida para ${latest} é do produto kg-ssot e chega pelo re-vendor; subir só aqui desalinha do CI"
      [ "${inst}" != "${pin}" ] && act="${PY} -m pip install ${pkg}==${pin} (o pino do contrato); ${act}"
    else
      act="${PY} -m pip install -U ${pkg}==${latest}"
    fi
    _judge "python:${pkg}" "${inst}" "${latest}" "${act}"
  done
}

leg_base() {
  [ -n "${GIT}" ] || return 0
  command -v "${GIT}" >/dev/null 2>&1 || return 0
  "${GIT}" -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 || return 0
  "${GIT}" -C "${REPO}" remote get-url origin >/dev/null 2>&1 || return 0
  local br out rc=0 sha cur n
  br="$("${GIT}" -C "${REPO}" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"; br="${br#origin/}"
  [ -n "${br}" ] || br=main
  out="$(GIT_TERMINAL_PROMPT=0 timeout "${T}" "${GIT}" -C "${REPO}" ls-remote origin "refs/heads/${br}" 2>/dev/null)" || rc=$?
  sha="$(printf '%s' "${out}" | awk 'NR==1{print $1}')"
  [[ "${sha}" =~ ^[0-9a-f]{40}$ ]] || { _row "base:${br}" - - nao-medida "o origin inalcançável por git ls-remote (rc=${rc})"; return 0; }
  cur="$("${GIT}" -C "${REPO}" rev-parse --short HEAD 2>/dev/null)"
  if "${GIT}" -C "${REPO}" merge-base --is-ancestor "${sha}" HEAD 2>/dev/null; then _row "base:${br}" "${cur}" "${sha:0:8}" em-dia "-"; return 0; fi
  if "${GIT}" -C "${REPO}" cat-file -e "${sha}^{commit}" 2>/dev/null; then
    n="$("${GIT}" -C "${REPO}" rev-list --count "HEAD..${sha}" 2>/dev/null)"
    _row "base:${br}" "${cur}" "${sha:0:8}" defasada "o HEAD está ${n} commit(s) atrás de origin/${br}: git fetch origin e rebase sobre origin/${br} (na ${br}: git pull --ff-only) antes de construir"
  else
    _row "base:${br}" "${cur}" "${sha:0:8}" defasada "origin/${br} andou para ${sha:0:8}, que este checkout ainda não buscou: git fetch origin e rebase sobre origin/${br} antes de construir"
  fi
}

measure() {
  local tmp; tmp="$(mktemp -d)" || return 1
  leg_cli  > "${tmp}/1" 2>/dev/null & leg_sdk > "${tmp}/2" 2>/dev/null &
  leg_kg   > "${tmp}/3" 2>/dev/null & leg_py  > "${tmp}/4" 2>/dev/null &
  leg_base > "${tmp}/5" 2>/dev/null &
  wait
  cat "${tmp}/1" "${tmp}/2" "${tmp}/3" "${tmp}/4" "${tmp}/5"
  rm -rf "${tmp}"
}

# ── cache (o hook roda por prompt; a rede, no máximo uma vez por TTL) ─────────────────────────────────────
# a chave cobre o repo E toda fonte trocável: uma leitura com override (bancada, perfilagem) nunca
# envenena o cache de quem roda com as fontes de produção (medido: um perfil com ONION_CURRENCY_GIT vazio
# fez o hook seguinte declarar o git AUSENTE, 2026-10-16)
key="$(printf '%s\n' "${REPO}" "${NPM}" "${GIT}" "${PY}" "${CC_BIN}" "${ONION_CC_CHANNEL-}" "${KG_REMOTE}" \
  "${ONION_CURRENCY_SDK_TARGETS-<default>}" "${ONION_CURRENCY_SDK_TARGETS+set}" "$(id -u)" "${npm_config_registry-}" "${PIP_INDEX_URL-}" | cksum | awk '{print $1}')"
cache="${CACHE_DIR}/${key}.tsv"
rows=""; age=""; hit=0
if [ "${FRESH}" = 0 ] && [ -f "${cache}" ]; then
  now="$(date +%s)"; mt="$(stat -c %Y "${cache}" 2>/dev/null || echo 0)"; age=$(( now - mt ))
  ttl="${TTL}"; grep -q $'\tnao-medida\t' "${cache}" && [ "${ttl}" -gt 600 ] && ttl=600
  if [ "${age}" -ge 0 ] && [ "${age}" -lt "${ttl}" ]; then rows="$(cat "${cache}")"; hit=1; fi
fi
if [ "${hit}" = 0 ]; then
  rows="$(measure)"; age=0
  if mkdir -p "${CACHE_DIR}" 2>/dev/null; then
    t="$(mktemp "${CACHE_DIR}/.w.XXXXXX" 2>/dev/null)" && { printf '%s\n' "${rows}" | sed '/^$/d' > "${t}"; mv -f "${t}" "${cache}"; }
  fi
fi
rows="$(printf '%s\n' "${rows}" | sed '/^$/d')"

case "${FMT}" in
  tsv) [ -n "${rows}" ] && printf '%s\n' "${rows}"; exit 0 ;;
  table)
    echo "| superfície | instalado | atual | estado | ação |"; echo "|---|---|---|---|---|"
    [ -n "${rows}" ] && printf '%s\n' "${rows}" | awk -F'\t' '{printf "| %s | %s | %s | %s | %s |\n",$1,$2,$3,$4,$5}'
    [ -n "${rows}" ] || echo "| (nenhuma superfície medível neste repo) | | | | |"
    exit 0 ;;
  notice)
    bad="$(printf '%s\n' "${rows}" | awk -F'\t' '$4!="em-dia" && NF>=4')"
    [ -n "${bad}" ] || exit 0
    m=$(( ${age:-0} / 60 ))
    echo "⚠️ Onion — BASE ATUAL, SEMPRE (ordem eterna do maestro, 2026-10-16; doutrina: docs/knowledge-base/concepts/keep-current-doctrine.md). Medido há ${m} min:"
    printf '%s\n' "${bad}" | awk -F'\t' '{
      if ($4=="defasada")   printf "  • %s: %s → %s DEFASADA. Ação: %s\n", $1, $2, $3, $5;
      else if ($4=="ausente") printf "  • %s: AUSENTE a ferramenta que mede. %s\n", $1, $5;
      else                    printf "  • %s: NÃO MEDIDO (não é \"em dia\"): %s\n", $1, $5 }'
    echo "  Antes de construir sobre o que está defasado: suba no mesmo fluxo, ou NOMEIE ao maestro o porquê de não subir. Faltou pacote: peça autorização ao maestro e instale pela fonte oficial — nunca contorne."
    exit 0 ;;
esac
