#!/usr/bin/env bash
# =============================================================================
# currency-census.sh — o censo de ATUALIDADE: a base sobre a qual se constrói está nas versões atuais?
#
# A ORDEM QUE ELE EXECUTA (maestro, 2026-10-16, dois reforços seguidos): "temos que usar sempre as
#   versões mais atuais e não sair criando coisas em cima de base velha" e "este aviso anterior de manter
#   atualizado é eterno, não só em memoria e sessão". Doutrina: docs/knowledge-base/concepts/keep-current-doctrine.md.
#   Este script é a perna que MEDE; o hook session-currency-check.sh é a que COBRA, sozinho.
#
# DEFEITO DATADO (2026-10-16): o Agent SDK que serve o bridge estava em 0.3.301 com o npm já em 0.3.302, e
#   nenhuma superfície avisou — o /meta:cc-update compara o SDK com o CLI do HOST (não com o publicado) e só
#   roda quando o maestro o invoca. A regra "use a base atual" vivia num preâmbulo de agente no scratchpad.
#
# AS SUPERFÍCIES (superfície que não existe neste repo é OMITIDA, não "em dia"):
#   claude-cli        binário em DISCO × dist-tag do canal no npm (@anthropic-ai/claude-code). Canal: env
#                     ONION_CC_CHANNEL, senão autoUpdatesChannel de ~/.claude/settings.json (só LIDO), senão latest.
#                     Processo≠disco NÃO é daqui: é do session-version-drift.sh (não duplicar).
#   agent-sdk:<r>     o @anthropic-ai/claude-agent-sdk de quem serve por SDK × o latest do npm. Os alvos são os do
#                     censo do /meta:cc-update (mesmo arquivo, 4 colunas); só o package.json é LIDO, como a conta
#                     dona (sudo -n, ambiente limpo), e só se o caminho declarado for o REAL (sem symlink).
#   kg-ssot           vendor/kg-ssot pinado × a maior tag kg-ssot-v* do repositório público do produto.
#   python:<pkg>      PyYAML e jsonschema (as diretas do leitor do KG-SSOT) no python3 do lint × PyPI. Quando o
#                     instalado é o PINO do contrato e o PyPI andou, o estado é `pinada`: a subida é do produto.
#   base:<branch>     HEAD deste checkout × a branch de INTEGRAÇÃO do Onion no origin, pelo resolve-integration-
#                     branch.sh (C8, 2026-10-20); sem sinal de integração, a padrão do origin (ls-remote --symref). Sem fetch.
#   action:<o/r>      o pin por SHA de uma action que INSTALA um CLI (hoje: anthropics/claude-code-action, a do
#                     revisor de IA do CI) nos workflows de .github/workflows/ × a maior tag vX.Y.Z do repositório
#                     da action. Defasada, a ação traz o CLI que cada commit instala (lido de src/entrypoints/run.ts
#                     no raw do GitHub) e o comando de subida. Nasceu da rodada r13 do radar E3 (2026-10-17, SAC-169):
#                     o pin instalava o CLI 2.1.220 com o host em 2.1.302, e nenhum censo tinha linha para ele.
#
# ESTADOS: em-dia · defasada (com a AÇÃO) · pinada (atrás por pino de contrato: aviso INFORMATIVO, a subida é do
#   produto) · fora-do-pino (instalado à frente do pino que o CI instala) · nao-medida (fonte
#   INALCANÇÁVEL, perna morta ou estourada, leitura suspeita — nunca vira "em dia") · ausente (falta a
#   ferramenta que mede: PEÇA AUTORIZAÇÃO AO MAESTRO para instalar, pela fonte oficial, e instale).
#
# Uso: currency-census.sh [REPO_DIR] [--tsv|--notice|--table] [--fresh]
#      currency-census.sh --render < linhas.tsv     (o texto do aviso a partir de linhas já medidas; uso do hook)
#   --tsv     superfície · instalado · atual · estado · ação (default)
#   --notice  só o que pede atenção (tudo menos em-dia; a pinada como informativa); vazio quando tudo está em dia
#   --fresh   ignora o cache das fontes
# CACHE — só das respostas REMOTAS e da leitura do SDK (por sudo), nunca da linha pronta: o lado local (disco,
#   HEAD, carimbo, módulos) é relido a cada chamada, então a cura aparece na hora. Cada entrada é UM valor que
#   tem de casar a forma de versão/sha (texto de ação nunca sai do cache: entrada fora da forma é ignorada).
#   TTL: registros ${ONION_CURRENCY_TTL:-3600} s · origin e SDK 300 s · falha de fonte 600 s (o prompt seguinte
#   não paga o prazo de novo). Diretório: ${ONION_CURRENCY_CACHE_DIR:-$XDG_RUNTIME_DIR/onion-currency, senão
#   ~/.cache/onion-currency}; usado só se for da conta e não gravável por grupo/outros — senão, sem cache.
# PRAZO: cada perna roda sob `timeout ${ONION_CURRENCY_DEADLINE:-9}`; perna estourada ou morta vira nao-medida.
# Env de bancada (cada fonte é trocável; DEFINIDO-vazio desliga a superfície): ONION_CC_BIN · ONION_CC_CHANNEL ·
#   ONION_CURRENCY_NPM · ONION_CURRENCY_GIT · ONION_CURRENCY_PY · ONION_CURRENCY_SDK_TARGETS ·
#   ONION_CURRENCY_KG_SSOT_REMOTE · ONION_CURRENCY_ACTION_REMOTE_BASE (default https://github.com) ·
#   ONION_CURRENCY_ACTION_RAW_BASE (default https://raw.githubusercontent.com; aceita file://) · ONION_CURRENCY_CURL ·
#   ONION_CURRENCY_TIMEOUT (por fonte, s, default 4) · ONION_CURRENCY_DEADLINE
# Exit: 0 sempre que mediu (o estado está nas linhas) · 2 uso errado.
# TETO: compara com o que o REGISTRO publica, não com o que é seguro adotar. O canal do CLI vem do npm, não do
#   manifesto do instalador nativo (alinhados em 2026-10-16; se o npm publicar antes, `claude update` não sobe e
#   o aviso persiste até o nativo chegar); managed settings não são lidos. Não vê dependência fora destas
#   superfícies. Das actions, só as da lista ACTIONS e só pin por SHA (pin por tag é nao-medida); o CLI do commit
#   é lido de src/entrypoints/run.ts e some do texto (não do estado) se o arquivo mudar de lugar. A base é a do checkout passado, e a ação "rebase sobre a integração" é errada em PR empilhado; a integração é a que o resolve-integration-branch.sh dá (a mesma do /engineer:pr).
#   Exercitado por lint-selftest.sh (run_currency_census_selftests).
# =============================================================================
set -uo pipefail
export LC_ALL=C
REPO="."; FMT="tsv"; FRESH=0; LEG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --tsv) FMT=tsv ;; --notice) FMT=notice ;; --table) FMT=table ;; --render) FMT=render ;; --fresh) FRESH=1 ;;
    --leg) LEG="${2:-}"; shift ;;
    -h|--help) sed -n '2,50p' "$0"; exit 0 ;;
    --*) echo "currency-census: opção desconhecida: $1" >&2; exit 2 ;;
    *) REPO="$1" ;;
  esac
  shift
done

render() {  # stdin: linhas TSV → o aviso (só o que pede atenção; a pinada entra como INFORMATIVA)
  local bad; bad="$(awk -F'\t' 'NF>=4 && $4!="em-dia"')"
  [ -n "${bad}" ] || return 0
  echo "⚠️ Onion — BASE ATUAL, SEMPRE (ordem eterna do maestro, 2026-10-16; doutrina: docs/knowledge-base/concepts/keep-current-doctrine.md):"
  printf '%s\n' "${bad}" | awk -F'\t' '{
    if ($4=="defasada")     printf "  • %s: %s → %s DEFASADA. Ação: %s\n", $1, $2, $3, $5;
    else if ($4=="ausente") printf "  • %s: AUSENTE a ferramenta que mede. %s\n", $1, $5;
    else if ($4=="pinada")  printf "  • %s: %s, PyPI em %s — PINADA (informativo, sem ação neste repo): %s\n", $1, $2, $3, $5;
    else if ($4=="fora-do-pino") printf "  • %s: %s FORA DO PINO %s. Ação: %s\n", $1, $2, $3, $5;
    else                    printf "  • %s: NÃO MEDIDO (não é \"em dia\"): %s\n", $1, $5 }'
  echo "  Antes de construir sobre o que está defasado: suba no mesmo fluxo, ou NOMEIE ao maestro o porquê de não subir. Faltou pacote: peça autorização ao maestro e instale pela fonte oficial — nunca contorne."
}
if [ "${FMT}" = render ]; then [ -t 0 ] && { echo "currency-census: --render lê as linhas TSV do stdin" >&2; exit 2; }; render; exit 0; fi

[ -d "${REPO}" ] || { echo "currency-census: repo inexistente: ${REPO}" >&2; exit 2; }
REPO="$(cd "${REPO}" && pwd -P)"
T="${ONION_CURRENCY_TIMEOUT:-4}"
DEADLINE="${ONION_CURRENCY_DEADLINE:-9}"
# o hook tem 15 s: prazo de perna acima de 12 s faria o Claude Code matar o hook e o aviso sumir calado; e
# fonte com teto maior que o prazo da perna faria a perna morrer antes de gravar a falha (refutador, passada 2)
if [[ "${DEADLINE}" =~ ^[0-9]+$ ]]; then
  [ "${DEADLINE}" -gt 12 ] && DEADLINE=12
  [[ "${T}" =~ ^[0-9]+$ ]] && [ "${T}" -ge "${DEADLINE}" ] && T=$(( DEADLINE > 1 ? DEADLINE - 1 : 1 ))
fi
TTL="${ONION_CURRENCY_TTL:-3600}"
NPM="${ONION_CURRENCY_NPM-npm}"
GIT="${ONION_CURRENCY_GIT-git}"
PY="${ONION_CURRENCY_PY-python3}"
CC_BIN="${ONION_CC_BIN-claude}"
KG_REMOTE="${ONION_CURRENCY_KG_SSOT_REMOTE:-https://github.com/marciocar/kg-ssot}"
ACT_REMOTE_BASE="${ONION_CURRENCY_ACTION_REMOTE_BASE:-https://github.com}"
ACT_RAW_BASE="${ONION_CURRENCY_ACTION_RAW_BASE:-https://raw.githubusercontent.com}"
CURL="${ONION_CURRENCY_CURL-curl}"
ACTIONS="anthropics/claude-code-action"   # actions que INSTALAM um CLI e que a casa pina por SHA de commit
ASK="peça autorização ao maestro para instalar"
VRE='^[0-9]+\.[0-9]+\.[0-9]+$'

# ⚠️ Sob pipefail, NENHUM leitor que fecha cedo (head -1, awk …exit): o escritor toma SIGPIPE e a pipeline
# sai 141 — medido pelo refutador em 2026-10-16 (3 em 3000; foi a causa do NÃO MEDIDO intermitente do k3).
# Todo "primeira linha" aqui é awk 'NR==1', que lê a entrada inteira.
_ver() { grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | awk 'NR==1'; }
_newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]; }  # a > b
_row() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "${2:--}" "${3:--}" "$4" "$5"; }
_judge() {  # <superfície> <instalado> <atual> <ação>
  if [ "$2" = "$3" ]; then _row "$1" "$2" "$3" em-dia "-"
  elif _newer "$2" "$3"; then _row "$1" "$2" "$3" nao-medida "o instalado (${2}) está À FRENTE do publicado (${3}): leitura suspeita ou registro atrasado — confira à mão"
  else _row "$1" "$2" "$3" defasada "$4"; fi
}
_has() { [ -n "$1" ] && command -v "$1" >/dev/null 2>&1; }

# ── cache das FONTES (nunca da linha pronta) ───────────────────────────────────────────────────────────────
CDIR=""
_cache_init() {
  local base="${ONION_CURRENCY_CACHE_DIR:-}"
  if [ -z "${base}" ]; then
    if [ -n "${XDG_RUNTIME_DIR:-}" ]; then base="${XDG_RUNTIME_DIR}/onion-currency"
    elif [ -n "${HOME:-}" ]; then base="${HOME}/.cache/onion-currency"; else return 0; fi
  fi
  [ -d "${base}" ] || mkdir -p -m 700 "${base}" 2>/dev/null || return 0
  local st; st="$(stat -c '%u %a' "${base}" 2>/dev/null)" || return 0
  [ "${st%% *}" = "$(id -u)" ] || return 0                       # dono tem de ser a conta que lê
  case "${st##* }" in *[2367]?|*?[2367]) return 0 ;; esac          # grupo/outros com escrita ⇒ sem cache
  local key; key="$(printf '%s\n' "${REPO}" "${NPM}" "${GIT}" "${PY}" "${KG_REMOTE}" "${ACT_REMOTE_BASE}" "${ACT_RAW_BASE}" "${npm_config_registry-}" "${PIP_INDEX_URL-}" | cksum | awk '{print $1}')"
  CDIR="${base}/${key}"; mkdir -p -m 700 "${CDIR}" 2>/dev/null || CDIR=""
}
# _src <nome> <ttl> <regex> <função…>: o valor da fonte, do cache se fresco e na forma; senão mede e grava.
# Falha (rc≠0 ou valor fora da forma) grava "FAIL <rc>" por 600 s e devolve o rc.
_src() {
  local name="$1" ttl="$2" re="$3"; shift 3
  local f="" now mt age v rc
  if [ -n "${CDIR}" ]; then
    f="${CDIR}/${name//[^A-Za-z0-9._-]/_}"
    if [ "${FRESH}" = 0 ] && [ -f "${f}" ]; then
      now="$(date +%s)"; mt="$(stat -c %Y "${f}" 2>/dev/null || echo 0)"; age=$(( now - mt ))
      v="$(head -c 200 "${f}" 2>/dev/null | awk 'NR==1')"
      if [ "${age}" -ge 0 ] && [[ "${v}" =~ ${re} ]] && [ "${age}" -lt "${ttl}" ]; then printf '%s\n' "${v}"; return 0; fi
      if [ "${age}" -ge 0 ] && [ "${age}" -lt 600 ] && [[ "${v}" =~ ^FAIL\ ([0-9]+)$ ]]; then return "${BASH_REMATCH[1]}"; fi
    fi
    # marca de medição EM CURSO deixada por uma perna morta pelo prazo: velha o bastante para não ser de uma
    # medição viva, nova o bastante para valer como falha (600 s) ⇒ não paga o prazo de novo
    if [ "${FRESH}" = 0 ] && [ -f "${f}.inflight" ]; then
      now="$(date +%s)"; mt="$(stat -c %Y "${f}.inflight" 2>/dev/null || echo 0)"; age=$(( now - mt ))
      if [ "${age}" -gt $(( DEADLINE + 2 )) ] && [ "${age}" -lt 600 ]; then return 124; fi
    fi
    : > "${f}.inflight" 2>/dev/null
  fi
  rc=0; v="$("$@" 2>/dev/null)" || rc=$?
  v="${v%%$'\n'*}"
  if [ "${rc}" = 0 ] && [[ "${v}" =~ ${re} ]]; then
    [ -n "${f}" ] && { printf '%s\n' "${v}" > "${f}.$$" && mv -f "${f}.$$" "${f}"; rm -f "${f}.inflight"; } 2>/dev/null
    printf '%s\n' "${v}"; return 0
  fi
  [ "${rc}" = 0 ] && rc=65
  [ -n "${f}" ] && { printf 'FAIL %s\n' "${rc}" > "${f}.$$" && mv -f "${f}.$$" "${f}"; rm -f "${f}.inflight"; } 2>/dev/null
  return "${rc}"
}
_npm_tag() { timeout "${T}" "${NPM}" view "$1" "dist-tags.$2" | _ver; }
_kg_latest() {
  GIT_TERMINAL_PROMPT=0 timeout "${T}" "${GIT}" ls-remote --tags --refs "${KG_REMOTE}" 'kg-ssot-v*' \
    | sed -n 's|.*refs/tags/kg-ssot-v\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$|\1|p' | sort -V | tail -1
}
_pypi() {  # stderr à parte: aviso/retry do pip em stderr não pode virar a "primeira linha" da resposta
  local out err rc=0; err="$(mktemp)" || return 1
  out="$(PIP_DISABLE_PIP_VERSION_CHECK=1 timeout "${T}" "${PY}" -I -m pip index versions "$1" 2>"${err}")" || rc=$?
  if [ "${rc}" != 0 ]; then grep -q "No module named pip" "${err}" && rc=66; rm -f "${err}"; return "${rc}"; fi
  rm -f "${err}"
  printf '%s\n' "${out}" | awk -v p="$1" 'tolower($1)==tolower(p) && $2 ~ /^\(/ && !d {d=1; print $2}' | _ver
}
_act_tags() {  # <dono/repo> <sha do pin> → "<maior vX.Y.Z> <sha do commit dela> <maior tag do pin, ou ->"
  local out list
  out="$(GIT_TERMINAL_PROMPT=0 timeout "${T}" "${GIT}" ls-remote --tags "${ACT_REMOTE_BASE}/$1")" || return 1
  # tag anotada aparece duas vezes: o objeto da tag e o commit (^{}); vale o commit
  list="$(printf '%s\n' "${out}" | awk '{ r=$2; pe=sub(/\^\{\}$/,"",r)
      if (r !~ /^refs\/tags\/v[0-9]+\.[0-9]+\.[0-9]+$/ || $1 !~ /^[0-9a-f]{40}$/) next
      v=substr(r,12); if (pe || !(v in s)) s[v]=$1 } END { for (v in s) print v, s[v] }' | sort -V)"
  [ -n "${list}" ] || return 1
  printf '%s %s\n' "$(printf '%s\n' "${list}" | tail -1)" \
    "$(printf '%s\n' "${list}" | awk -v p="$2" '$2==p{v=$1} END{print (v==""?"-":v)}')"
}
_act_cli() {  # <dono/repo> <sha> → a versão do CLI que aquele commit da action instala
  timeout "${T}" "${CURL}" -fsS --max-time "${T}" "${ACT_RAW_BASE}/$1/$2/src/entrypoints/run.ts" \
    | sed -n 's/.*claudeCodeVersion[[:space:]]*=[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' | _ver
}
_origin() {
  local out br sha
  out="$(GIT_TERMINAL_PROMPT=0 timeout "${T}" "${GIT}" -C "${REPO}" ls-remote --symref origin HEAD)" || return 1
  br="$(printf '%s\n' "${out}" | sed -n 's|^ref: refs/heads/\([^[:space:]]*\)[[:space:]]*HEAD$|\1|p' | awk 'NR==1')"
  sha="$(printf '%s\n' "${out}" | awk '$2=="HEAD" && $1 ~ /^[0-9a-f]+$/ && length($1)==40 && !d {d=1; print $1}')"
  [ -n "${br}" ] && [ -n "${sha}" ] && printf '%s %s\n' "${br}" "${sha}"
}
_origin_branch() {  # <branch> → "branch sha" da ref no origin; nada (rc 0) quando ela não existe lá
  local out sha
  out="$(GIT_TERMINAL_PROMPT=0 timeout "${T}" "${GIT}" -C "${REPO}" ls-remote origin "refs/heads/$1")" || return 1
  sha="$(printf '%s\n' "${out}" | awk -v r="refs/heads/$1" '$2==r && $1 ~ /^[0-9a-f]+$/ && length($1)==40 {print $1; exit}')"
  [ -n "${sha}" ] && printf '%s %s\n' "$1" "${sha}"
  return 0
}
_sdk_read() {  # <conta|-> <package.json> → a versão, só se o caminho declarado for o REAL
  local acct="$1" pkg="$2" raw
  local probe='p="$(readlink -f -- "$1")" && [ "$p" = "$1" ] && head -c 1048576 -- "$1"'
  if [ "${acct}" = "-" ] || [ "${acct}" = "$(id -un)" ]; then
    raw="$(timeout "${T}" sh -c "${probe}" _ "${pkg}")" || return 1
  else
    raw="$(cd / && timeout "${T}" sudo -n -u "${acct}" /usr/bin/env -i PATH=/usr/bin:/bin sh -c "${probe}" _ "${pkg}")" || return 1
  fi
  printf '%s' "${raw}" | "${PY:-python3}" -I -c 'import json,sys
try: print(json.load(sys.stdin).get("version",""))
except Exception: pass' | _ver
}

# ── as pernas (cada uma roda num processo próprio, sob prazo) ──────────────────────────────────────────────
leg_cli() {
  [ -n "${CC_BIN}" ] || return 0
  _has "${CC_BIN}" || { _row claude-cli - - ausente "o binário ${CC_BIN} não está no PATH: ${ASK} o Claude Code pelo instalador oficial (claude.ai/install.sh)"; return 0; }
  local disk ch latest rc=0
  disk="$(readlink -f "$(command -v "${CC_BIN}")" 2>/dev/null | sed 's|.*/||' | _ver)"
  [ -n "${disk}" ] || disk="$(timeout "${T}" "${CC_BIN}" --version 2>/dev/null | _ver)"
  [ -n "${disk}" ] || { _row claude-cli - - nao-medida "a versão do binário em disco não se lê (readlink e --version mudos)"; return 0; }
  ch="${ONION_CC_CHANNEL-}"
  if [ -z "${ch}" ] && _has "${PY}" && [ -n "${HOME:-}" ] && [ -r "${HOME}/.claude/settings.json" ]; then
    ch="$("${PY}" -I -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get("autoUpdatesChannel") or "")
except Exception: print("")' "${HOME}/.claude/settings.json" 2>/dev/null)"
  fi
  [[ "${ch}" =~ ^[a-z]+$ ]] || ch=latest
  _has "${NPM}" || { _row "claude-cli (canal ${ch})" "${disk}" - ausente "falta o npm para ler o registro: ${ASK} o Node.js/npm pela fonte oficial (nodejs.org ou o pacote da distro)"; return 0; }
  latest="$(_src "npm-cc-${ch}" "${TTL}" "${VRE}" _npm_tag @anthropic-ai/claude-code "${ch}")" || rc=$?
  [ -n "${latest}" ] || { _row "claude-cli (canal ${ch})" "${disk}" - nao-medida "registro npm inalcançável ou sem o dist-tag ${ch} (rc=${rc})"; return 0; }
  _judge "claude-cli (canal ${ch})" "${disk}" "${latest}" "claude update (e reinicie a sessão: /exit → claude --continue)"
}

leg_sdk() {
  local conf="${ONION_CURRENCY_SDK_TARGETS-}"
  if [ -z "${ONION_CURRENCY_SDK_TARGETS+x}" ]; then
    conf=""; [ -f "${REPO}/ops/cc-sdk-targets.tsv" ] && conf="${REPO}/ops/cc-sdk-targets.tsv"   # core-only: no adotante o arquivo não existe e a superfície some
  fi
  [ -n "${conf}" ] || return 0
  [ -r "${conf}" ] || { _row agent-sdk - - nao-medida "o arquivo de alvos declarado não é legível: ${conf}"; return 0; }
  if [ "$(id -u)" = 0 ]; then _row agent-sdk - - nao-medida "o censo roda como root: recuso ler como outra conta (rode como o operador)"; return 0; fi
  local latest="" nrc=0 lb acct pkg bin v n=0 k
  if _has "${NPM}"; then latest="$(_src npm-sdk "${TTL}" "${VRE}" _npm_tag @anthropic-ai/claude-agent-sdk latest)" || nrc=$?; fi
  while IFS=$'\t' read -r lb acct pkg bin || [ -n "${lb}" ]; do
    case "${lb}" in ''|'#'*) continue ;; esac
    n=$((n+1))
    if ! [[ "${lb}" =~ ^[A-Za-z0-9_.-]+$ ]] || [ -z "${pkg}" ]; then _row agent-sdk - - nao-medida "linha de alvo fora da forma (rótulo · conta · package.json · binário)"; continue; fi
    if [ "${acct}" != "-" ] && { ! [[ "${acct}" =~ ^[a-z_][a-z0-9_-]*$ ]] || [ "${acct}" = root ] || [ "$(id -u "${acct}" 2>/dev/null)" = 0 ]; }; then
      _row "agent-sdk:${lb}" - - nao-medida "conta recusada (nunca root/uid 0; forma [a-z_][a-z0-9_-]* ou -)"; continue
    fi
    if ! [[ "${pkg}" =~ ^/([^/]+/)*node_modules/@anthropic-ai/claude-agent-sdk/package\.json$ ]] || [[ "${pkg}" == *"/./"* || "${pkg}" == *"/../"* ]]; then
      _row "agent-sdk:${lb}" - - nao-medida "o package.json tem de ser <…>/node_modules/@anthropic-ai/claude-agent-sdk/package.json, absoluto e sem . ou .."; continue
    fi
    k="$(printf '%s\n' "${acct}" "${pkg}" | cksum | awk '{print $1}')"
    v="$(_src "sdk-${lb}-${k}" 300 "${VRE}" _sdk_read "${acct}" "${pkg}")" || v=""
    if [ -z "${v}" ]; then _row "agent-sdk:${lb}" - - nao-medida "o package.json não se lê como ${acct} pelo caminho REAL (sudo -n recusado, arquivo ausente, symlink no caminho ou JSON inválido)"; continue; fi
    _has "${NPM}" || { _row "agent-sdk:${lb}" "${v}" - ausente "falta o npm para ler o registro: ${ASK} o Node.js/npm pela fonte oficial"; continue; }
    [ -n "${latest}" ] || { _row "agent-sdk:${lb}" "${v}" - nao-medida "registro npm inalcançável (rc=${nrc})"; continue; }
    _judge "agent-sdk:${lb}" "${v}" "${latest}" "suba @anthropic-ai/claude-agent-sdk para ${latest} no repo que o serve (lock incluído) e re-implante pelo caminho de deploy declarado, nunca à mão"
  done < "${conf}"
  [ "${n}" -gt 0 ] || _row agent-sdk - - nao-medida "o arquivo de alvos ${conf} não declara nenhum alvo"
}

leg_kg() {
  local stamp="${REPO}/vendor/kg-ssot/.kg-ssot-version" v latest rc=0
  [ -f "${stamp}" ] || return 0
  _has "${PY:-python3}" || { _row kg-ssot - - ausente "falta o python3 para ler o carimbo: ${ASK} o python3 pela distro"; return 0; }
  v="$("${PY:-python3}" -I -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get("version",""))
except Exception: pass' "${stamp}" 2>/dev/null | _ver)"
  [ -n "${v}" ] || { _row kg-ssot - - nao-medida "o carimbo do vendor kg-ssot não declara versão legível"; return 0; }
  [ -n "${GIT}" ] || return 0
  _has "${GIT}" || { _row kg-ssot "${v}" - ausente "falta o git para ler as tags do produto: ${ASK} o git pela distro"; return 0; }
  latest="$(_src kg-tags "${TTL}" "${VRE}" _kg_latest)" || rc=$?
  [ -n "${latest}" ] || { _row kg-ssot "${v}" - nao-medida "o repositório do produto (${KG_REMOTE}) inalcançável ou sem tag kg-ssot-v* (rc=${rc})"; return 0; }
  _judge kg-ssot "${v}" "${latest}" "python3 -I -B vendor/kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v${latest} --source ${KG_REMOTE} (e rode o check do contrato)"
}

leg_py_one() {  # <pkg>
  local pkg="$1" req="${REPO}/vendor/kg-ssot/tools/requirements.txt" pin="" inst latest rc=0 pypath
  pypath="$(command -v "${PY}")"
  [ -f "${req}" ] && pin="$(sed -n "s/^${pkg}==\([0-9][0-9.]*\).*/\1/p" "${req}" | awk 'NR==1')"
  inst="$("${PY}" -I -c 'import importlib.metadata as m,sys
try: print(m.version(sys.argv[1]))
except Exception: pass' "${pkg}" 2>/dev/null | _ver)"
  # Com pino, o conselho instala pelo requirements.txt INTEIRO com --require-hashes (desde a kg-ssot-v4.7.4 ele
  # traz o sha256 de cada arquivo publicado): `pip install pkg==X` avulso fura a verificação de hash.
  local hreq="${PY} -m pip install --require-hashes -r vendor/kg-ssot/tools/requirements.txt"
  if [ -z "${inst}" ]; then
    if [ -n "${pin}" ]; then _row "python:${pkg}" - "${pin}" ausente "${pkg} não está instalado no python do lint (${pypath}): ${ASK} ${pkg}==${pin} pelo PyPI (${hreq})"
    else _row "python:${pkg}" - - ausente "${pkg} não está instalado no python do lint (${pypath}): ${ASK} ${pkg} pelo PyPI (${PY} -m pip install ${pkg})"; fi
    return 0
  fi
  latest="$(_src "pypi-${pkg}" "${TTL}" "${VRE}" _pypi "${pkg}")" || rc=$?
  if [ "${rc}" = 66 ]; then _row "python:${pkg}" "${inst}" - ausente "falta o pip no python do lint (${pypath}): ${ASK} o pip (${PY} -m ensurepip ou o pacote da distro)"; return 0; fi
  [ -n "${latest}" ] || { _row "python:${pkg}" "${inst}" - nao-medida "o PyPI inalcançável pelo pip (rc=${rc})"; return 0; }
  if [ -n "${pin}" ]; then
    if [ "${inst}" != "${pin}" ] && _newer "${inst}" "${pin}"; then _row "python:${pkg}" "${inst}" "${pin}" fora-do-pino "o instalado (${inst}) está À FRENTE do pino do contrato (${pin}) e o CI instala o pino: alinhe com ${hreq}, ou suba o pino no produto kg-ssot"
    elif [ "${inst}" != "${pin}" ]; then _row "python:${pkg}" "${inst}" "${pin}" defasada "${hreq} (o pino do contrato KG-SSOT, vendor/kg-ssot/tools/requirements.txt; o PyPI está em ${latest})"
    elif [ "${pin}" = "${latest}" ]; then _row "python:${pkg}" "${inst}" "${latest}" em-dia "-"
    elif _newer "${pin}" "${latest}"; then _row "python:${pkg}" "${inst}" "${latest}" nao-medida "o pino (${pin}) está À FRENTE do PyPI (${latest}): registro atrasado ou índice trocado"
    else _row "python:${pkg}" "${inst}" "${latest}" pinada "o pino do contrato KG-SSOT é ${pin}: a subida para ${latest} é do produto kg-ssot e chega pelo re-vendor"; fi
    return 0
  fi
  _judge "python:${pkg}" "${inst}" "${latest}" "${PY} -m pip install -U ${pkg}==${latest}"
}
leg_py() {
  [ -n "${PY}" ] || return 0
  _has "${PY}" || { _row python - - ausente "falta o ${PY} que o lint usa: ${ASK} o python3 pela distro"; return 0; }
  local t; t="$(mktemp -d)" || return 1
  leg_py_one PyYAML > "${t}/a" & leg_py_one jsonschema > "${t}/b" & wait
  cat "${t}/a" "${t}/b"; rm -rf "${t}"
}

leg_base() {
  [ -n "${GIT}" ] || return 0
  [ -e "${REPO}/.git" ] || return 0
  _has "${GIT}" || { _row base - - ausente "falta o git para medir a base: ${ASK} o git pela distro"; return 0; }
  "${GIT}" -C "${REPO}" remote get-url origin >/dev/null 2>&1 || return 0
  local v rc=0 br sha cur n ib="" ibe="" res ok key
  # C8 (2026-10-20, sinal de campo de um hub adotante): a base se compara com a branch de INTEGRAÇÃO do Onion,
  # pelo MESMO resolvedor do /engineer:pr (stamp → gitflow.branch.develop → develop → principal). Num hub cuja
  # integração é onion/develop, comparar com a padrão do origin (a develop de produto) mandou rebasear sobre a
  # branch errada. Só o PALPITE CEGO do resolvedor (sem sinal nenhum; ele avisa no stderr) cai no symref do
  # origin, que é resposta melhor que "main". Integração que não está no origin: não medida, nunca a padrão.
  res="${ONION_CURRENCY_RESOLVER:-$(dirname "${BASH_SOURCE[0]}")/resolve-integration-branch.sh}"
  if [ -f "${res}" ]; then
    ibe="$(bash "${res}" "${REPO}" 2>&1 >/dev/null)"; ib="$(bash "${res}" "${REPO}" 2>/dev/null)"
    # passada adversarial: `integration_branch: "onion/develop"` (com aspas, editado à mão) volta COM as aspas;
    # recusar e cair no symref seria o mesmo falso positivo que esta cura fecha, agora calado. Não medida, nomeada.
    if [ -n "${ib}" ] && [ -z "${ibe}" ] && ! [[ "${ib}" =~ ^[A-Za-z0-9._/-]+$ ]]; then
      _row base - - nao-medida "a branch de integração que o resolve-integration-branch.sh devolveu não é um nome de branch ($(printf '%q' "${ib}" | cut -c1-60)): corrija integration_branch no .claude/.onion-version (sem aspas)"
      return 0
    fi
  fi
  ok='^[A-Za-z0-9._/-]+ [0-9a-f]{40}$'
  key="$("${GIT}" -C "${REPO}" remote get-url origin 2>/dev/null | cksum | awk '{print $1}')"
  if [ -n "${ib}" ] && [ -z "${ibe}" ]; then
    v="$(_src "origin-int-${key}-$(printf '%s' "${ib}" | cksum | awk '{print $1}')" 300 "${ok}" _origin_branch "${ib}")" || rc=$?
    if [ -z "${v}" ]; then
      if [ "${rc}" = 65 ]; then _row "base:${ib}" - - nao-medida "a branch de integração ${ib} (resolve-integration-branch.sh) não está no origin: publique-a ou grave integration_branch no .claude/.onion-version"
      else _row base - - nao-medida "o origin inalcançável por git ls-remote (rc=${rc})"; fi
      return 0
    fi
  else
    v="$(_src "origin-head-${key}" 300 "${ok}" _origin)" || rc=$?
    [ -n "${v}" ] || { _row base - - nao-medida "o origin inalcançável por git ls-remote --symref (rc=${rc})"; return 0; }
  fi
  br="${v%% *}"; sha="${v##* }"
  cur="$("${GIT}" -C "${REPO}" rev-parse --short HEAD 2>/dev/null)"
  if "${GIT}" -C "${REPO}" merge-base --is-ancestor "${sha}" HEAD 2>/dev/null; then _row "base:${br}" "${cur}" "${sha:0:8}" em-dia "-"; return 0; fi
  if "${GIT}" -C "${REPO}" cat-file -e "${sha}^{commit}" 2>/dev/null; then
    n="$("${GIT}" -C "${REPO}" rev-list --count "HEAD..${sha}" 2>/dev/null)"
    _row "base:${br}" "${cur}" "${sha:0:8}" defasada "o HEAD está ${n} commit(s) atrás de origin/${br}: git fetch origin e rebase sobre origin/${br} (na ${br}: git pull --ff-only) antes de construir"
  else
    _row "base:${br}" "${cur}" "${sha:0:8}" defasada "origin/${br} andou para ${sha:0:8}, que este checkout ainda não buscou: git fetch origin e rebase sobre origin/${br} antes de construir"
  fi
}

leg_act() {
  [ -n "${GIT}" ] || return 0
  local wf="${REPO}/.github/workflows"; [ -d "${wf}" ] || return 0
  local a p pins files v rc lv lsha pv cn cp
  for a in ${ACTIONS}; do
    # linha comentada fica fora; aspas e subcaminho (…/base-action, que também instala o CLI) entram; o pin só
    # sai com caracteres de ref (sem glob nem espaço — refutador, 2026-10-17)
    pins="$(cat "${wf}"/*.yml "${wf}"/*.yaml 2>/dev/null | grep -vE '^[[:space:]]*#' \
      | grep -oE "uses:[[:space:]]*[\"']?${a}(/[A-Za-z0-9._-]+)*@[A-Za-z0-9._/-]+" | sed 's/.*@//' | sort -u)"
    [ -n "${pins}" ] || continue
    _has "${GIT}" || { _row "action:${a}" - - ausente "falta o git para ler as tags da action: ${ASK} o git pela distro"; continue; }
    while IFS= read -r p; do
      [ -n "${p}" ] || continue
      files="$(grep -lE "${a}(/[A-Za-z0-9._-]+)*@${p}([^A-Za-z0-9._/-]|\$)" "${wf}"/*.yml "${wf}"/*.yaml 2>/dev/null | sed "s|^${REPO}/||" | tr '\n' ' ')"; files="${files% }"
      if ! [[ "${p}" =~ ^[0-9a-f]{40}$ ]]; then
        _row "action:${a}" "${p}" - nao-medida "o pin não é SHA de commit (@${p}, em ${files}): a casa pina por SHA, e o censo só julga pin por SHA"; continue
      fi
      rc=0; v="$(_src "act-tags-${a}-${p:0:12}" "${TTL}" '^[0-9]+\.[0-9]+\.[0-9]+ [0-9a-f]{40} ([0-9]+\.[0-9]+\.[0-9]+|-)$' _act_tags "${a}" "${p}")" || rc=$?
      [ -n "${v}" ] || { _row "action:${a}" "${p:0:8}" - nao-medida "as tags de ${ACT_REMOTE_BASE}/${a} inalcançáveis por git ls-remote ou sem tag vX.Y.Z (rc=${rc})"; continue; }
      lv="${v%% *}"; v="${v#* }"; lsha="${v%% *}"; pv="${v##* }"
      if [ "${p}" = "${lsha}" ]; then _row "action:${a}" "${lv}" "${lv}" em-dia "-"; continue; fi
      if [ "${pv}" = "-" ]; then
        _row "action:${a}" "${p:0:8}" "${lv}" nao-medida "o pin ${p:0:8} (em ${files}) não é commit de nenhuma tag de release: pode estar à frente ou atrás da v${lv}; confira à mão"; continue
      fi
      if _newer "${pv}" "${lv}"; then _row "action:${a}" "${pv}" "${lv}" nao-medida "a tag do pin (v${pv}) está À FRENTE da maior tag lida (v${lv}): leitura suspeita"; continue; fi
      cp="CLI não lido"; cn="CLI não lido"
      if _has "${CURL}"; then  # as duas leituras em PARALELO: em série, ls-remote + 2 curl passariam do prazo da perna
        local tc; tc="$(mktemp -d)" || tc=""
        if [ -n "${tc}" ]; then
          _src "act-cli-${a}-${p:0:12}" "${TTL}" "${VRE}" _act_cli "${a}" "${p}" > "${tc}/p" &
          _src "act-cli-${a}-${lsha:0:12}" "${TTL}" "${VRE}" _act_cli "${a}" "${lsha}" > "${tc}/n" &
          wait
          [ -s "${tc}/p" ] && cp="CLI $(awk 'NR==1' "${tc}/p")"
          [ -s "${tc}/n" ] && cn="CLI $(awk 'NR==1' "${tc}/n")"
          rm -rf "${tc}"
        fi
      fi
      _row "action:${a}" "${pv}" "${lv}" defasada "o pin ${p:0:8} (v${pv}) instala o ${cp}; a v${lv} instala o ${cn}. Suba: sed -i 's/${p}/${lsha}/g' ${files} — leia as notas das releases entre as duas contra os inputs usados, e prove no PR SEGUINTE (o PR que edita o workflow pode fazer a action se auto-pular)"
    done <<< "${pins}"
  done
}

if [ -n "${LEG}" ]; then
  _cache_init
  case "${LEG}" in cli) leg_cli ;; sdk) leg_sdk ;; kg) leg_kg ;; py) leg_py ;; base) leg_base ;; act) leg_act ;; *) exit 2 ;; esac
  exit 0
fi

# ── pré-voo: as ferramentas de que a MEDIÇÃO depende (faltando, é ausente — nunca "inalcançável") ────────────
pre=""
for tool in timeout stat cksum sort sed awk head tail readlink mktemp grep cat rm date id; do _has "${tool}" || pre="${pre:+${pre}, }${tool}"; done
if [ -z "${pre}" ] && [ "$(printf '1.10.0\n1.9.0\n' | sort -V 2>/dev/null | tail -1)" != "1.10.0" ]; then pre="sort -V (GNU coreutils)"; fi
if [ -n "${pre}" ]; then
  rows="$(_row ferramentas - - ausente "falta ${pre}, de que o censo depende: ${ASK} o GNU coreutils pela distro")"
else
  tmp="$(mktemp -d)"
  fl=""; [ "${FRESH}" = 1 ] && fl="--fresh"
  for l in cli sdk kg py base act; do
    ( timeout -k 1 "${DEADLINE}" bash "$0" "${REPO}" --leg "${l}" ${fl} < /dev/null > "${tmp}/${l}" 2>/dev/null; echo $? > "${tmp}/${l}.rc" ) &
  done
  wait
  rows=""
  for l in cli sdk kg py base act; do
    r="$(cat "${tmp}/${l}" 2>/dev/null)"; rc="$(cat "${tmp}/${l}.rc" 2>/dev/null || echo 99)"
    [ -n "${r}" ] && rows="${rows}${r}"$'\n'
    case "${rc}" in
      0) ;;
      124|137) rows="${rows}$(_row "perna:${l}" - - nao-medida "a perna ${l} estourou o prazo de ${DEADLINE} s (fonte lenta ou travada; a falha fica em cache por 10 min)")"$'\n' ;;
      *) rows="${rows}$(_row "perna:${l}" - - nao-medida "a perna ${l} morreu (rc=${rc}) — medição incompleta, não confie no silêncio dela")"$'\n' ;;
    esac
  done
  rm -rf "${tmp}"
fi
rows="$(printf '%s\n' "${rows}" | sed '/^$/d')"

case "${FMT}" in
  tsv) [ -n "${rows}" ] && printf '%s\n' "${rows}"; exit 0 ;;
  table)
    echo "| superfície | instalado | atual | estado | ação |"; echo "|---|---|---|---|---|"
    if [ -n "${rows}" ]; then printf '%s\n' "${rows}" | awk -F'\t' '{printf "| %s | %s | %s | %s | %s |\n",$1,$2,$3,$4,$5}'
    else echo "| (nenhuma superfície medível neste repo) | | | | |"; fi
    exit 0 ;;
  notice) printf '%s\n' "${rows}" | render; exit 0 ;;
esac
