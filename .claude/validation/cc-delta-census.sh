#!/usr/bin/env bash
# ===========================================================================
# cc-delta-census.sh — o MEDIDOR da peça 3 do /meta:cc-update.
#
# Responde por medição o que a sessão responderia de memória depois de atualizar o Claude Code:
#   (1) QUAIS versões entraram: a baseline do eixo E3 (`cc_version` em docs/onion/radar-baselines.yaml)
#       contra o disco (`claude --version`) e o PROCESSO (CLAUDE_CODE_EXECPATH / /proc/$CLAUDE_PID/exe);
#   (2) O QUE diz cada uma: baixa o CHANGELOG OFICIAL e separa só as seções do delta;
#   (3) O QUE no Onion pode ser tocado: inventário das superfícies (hooks do settings.json, rules
#       com `paths:`, skills `context: fork`, agentes por model, a allowlist de modelo do E6,
#       plugins, arquivos de .claude/ que citam scriptPath do Workflow).
# TETO do inventário: lê só .claude/settings.json (não settings.local.json nem hooks de plugin) e conta
# CITAÇÃO de scriptPath, não execução. A cada carga o medidor baixa o CHANGELOG (até 60 s de rede).
#   (4) Com `--write <dir>`: grava `data/<versão>.txt` e o ESQUELETO do grafo da rodada.
#
# ── O QUE ESTE SCRIPT NÃO FAZ (fronteira declarada, nasceu de defeito medido) ──────────────
# Ele NÃO decide se um item do CHANGELOG toca o Onion. Na rodada r8 (2026-10-08) três nós afirmaram
# ligação com o core que não existia (reescrita de input por PreToolUse, SessionStart async, guarda de
# modelo) e o juiz os reprovou medindo o vivo. Casar item com superfície por palavra-chave fabrica
# exatamente essa ligação. Quem liga item a superfície é a rodada, com o juiz conferindo no vivo.
# O inventário mede O QUE EXISTE; o delta diz O QUE MUDOU; o cruzamento é julgamento.
#
# ── O esqueleto não sela nada ─────────────────────────────────────────────────────────────
# Ele nasce com 2 nós (a evidência do delta, com provenance, e a pergunta aberta da rodada) e SEM a
# chave de Aufhebung: a REGRA 89 (Rodada de radar selada reconcilia o corpus que superou (Aufhebung),
# com catraca) acusa a ausência até a rodada decidir entre `external_edges` com SUPERSEDES (a
# rodada derrubou nó da anterior; contrato v4.3, 2026-10-10, SAC-98, e o gate confere que o alvo existe)
# e `meta.x_supersedes_none: <razão>` (não derrubou nada). O esqueleto traz as duas formas COMENTADAS,
# com o grafo da rodada anterior já preenchido: descomentar sem nomear o nó é alvo inventado, e o gate
# reprova (integrity.dangling-external). A chave velha `x_supersedes_external` não conta mais na REGRA 89.
#
# Uso:  bash .claude/validation/cc-delta-census.sh [<repo>] [--markdown|--tsv] [--write <dir>]
# Env (bancada e sandbox; NUNCA para fingir medição):
#   CC_DELTA_CHANGELOG=<arquivo>   usa este CHANGELOG em vez de baixar (bancada sem rede)
#   CC_DELTA_URL=<url>             fonte oficial (default: raw.githubusercontent.com/anthropics/claude-code)
#   CC_DELTA_BASELINE=<x.y.z>      sobrescreve a cc_version lida do baseline
#   CC_DELTA_DISK=<x.y.z>          sobrescreve a versão do disco
#   CC_DELTA_PROC=<x.y.z>          sobrescreve a versão do processo (vazio-definido = sem sinal)
#   CC_DELTA_TODAY=<AAAA-MM-DD>    data da rodada (default: date +%F)
#   CC_DELTA_SDK_TARGETS=<arquivo> alvos do CLI EMBUTIDO em Agent SDK (default: ops/cc-sdk-targets.tsv (core-only)
#                                  do repo, se existir; vazio-definido = nenhum alvo)
#
# ── O CLI QUE SERVE NÃO É O DO HOST (SAC-155, nasceu de defeito medido) ─────────────────────
# Na rodada r12 (2026-10-16) o censo mediu o host em 2.1.301 enquanto o bridge e o runner do /chat rodavam o
# CLI 2.1.232 embutido no Agent SDK 0.3.232: 57 versões publicadas que o delta declarava e que NÃO chegavam
# a produção, e nenhuma linha dizia isso. Quem serve por SDK carrega o próprio binário; `claude --version`
# do host não o vê. Por isso cada ALVO declarado vira uma linha da tabela de versões, e o veredito avisa
# quando o CLI do SDK está N versões publicadas atrás do host.
#   FONTE: o `--version` do BINÁRIO que o SDK traz (o que roda; comportamento), com o `claudeCodeVersion` do
#   package.json do SDK como declaração cruzada — divergência entre os dois é aviso. O package.json é lido
#   como ARQUIVO (`require` do pacote falha pelo campo `exports`). Rodado como a conta dona (`sudo -n -u`),
#   em `/`, com ambiente limpo e teto de 30 s.
#   DECLARADO POR CONFIGURAÇÃO, nunca por caminho no código: o arquivo de alvos (TAB: rótulo · conta ou `-` ·
#   package.json · binário ou `-`). Quem não serve por SDK não tem o arquivo e lê "nenhum alvo declarado".
#   Alvo inalcançável é "NÃO MEDIDO (rc, motivo)" na linha e no aviso, nunca versão vazia em silêncio; e
#   ele NÃO derruba o rc do censo: a medição do host segue válida.
# Exit: 0 = medido (delta ou "NADA A MEDIR", a linha VEREDITO diz qual) · 2 = entrada quebrada
#       (sem baseline, CHANGELOG inalcançável, versão ilegível ou fora do CHANGELOG) — nunca 0 em
#       silêncio. Determinístico, sem LLM. Exercitado por lint-selftest.sh
#       (run_cc_delta_census_selftests).
# ===========================================================================
set -uo pipefail
REPO=""; FMT="--markdown"; WRITE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --markdown|--tsv) FMT="$1" ;;
    --write) shift; WRITE="${1:?--write exige o diretório da rodada}" ;;
    --*) echo "cc-delta-census: opção desconhecida: $1" >&2; exit 2 ;;
    *) REPO="$1" ;;
  esac
  shift
done
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "cc-delta-census: alvo inexistente: ${REPO}" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "cc-delta-census: python3 ausente — não meço sem ele (nunca 0 em silêncio)" >&2; exit 2; }

# Override ativo é DECLARADO antes de qualquer veredito. Achado do 1º dogfood de carga (2026-10-08): com
# CC_DELTA_URL herdado de um teste, a sessão leu "CHANGELOG oficial inalcançável" e a causa era a variável.
# O erro culpava a fonte; quem lê tem de saber que a medição não é a de produção.
OVR="$(env | LC_ALL=C grep -oE '^CC_DELTA_[A-Z_]+=.*' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"
[ -n "${OVR}" ] && echo "cc-delta-census: ⚠️ override ativo — esta NÃO é a medição de produção: ${OVR}" >&2

# ── versões ────────────────────────────────────────────────────────────────────────────────
_ver() { grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1; }
BASE="${CC_DELTA_BASELINE:-}"
if [ -z "${BASE}" ]; then
  BL="${REPO}/docs/onion/radar-baselines.yaml"
  [ -f "${BL}" ] || { echo "cc-delta-census: ${BL} ausente — sem baseline do E3 não há delta a medir" >&2; exit 2; }
  BASE="$(awk '/id: E3-claude-code-delta/{f=1;next} f&&/^  - id:/{f=0} f&&/cc_version:/{print;exit}' "${BL}" | _ver)"
  [ -n "${BASE}" ] || { echo "cc-delta-census: o eixo E3 de ${BL} não tem cc_version legível" >&2; exit 2; }
fi
DISK="${CC_DELTA_DISK-}"
if [ -z "${CC_DELTA_DISK+x}" ]; then
  DISK="$( (claude --version 2>/dev/null || true) | _ver)"
fi
PROC="${CC_DELTA_PROC-}"
if [ -z "${CC_DELTA_PROC+x}" ]; then
  ep="${CLAUDE_CODE_EXECPATH:-}"
  [ -n "${ep}" ] && PROC="$(printf '%s' "${ep##*/}" | _ver)"
  if [ -z "${PROC}" ] && [ -n "${CLAUDE_PID:-}" ] && [ -r "/proc/${CLAUDE_PID}/exe" ]; then
    PROC="$(readlink "/proc/${CLAUDE_PID}/exe" 2>/dev/null | sed 's/ (deleted)$//; s|.*/||' | _ver)"
  fi
fi
[ -n "${DISK}${PROC}" ] || { echo "cc-delta-census: nem o disco nem o processo deram versão do Claude Code — não sei o que foi instalado" >&2; exit 2; }

TMPD="$(mktemp -d)"; trap 'rm -rf "${TMPD}"' EXIT

# ── o CLI embutido no Agent SDK de quem serve (SAC-155) ─────────────────────────────────────
# Uma linha por alvo em ${TMPD}/sdk.tsv: rótulo · n · rc do package.json · rc do binário · motivo do pacote ·
# motivo do binário; as saídas brutas em sdk-<n>.pkg / sdk-<n>.bin. O Python lê e julga; aqui só se mede.
# ── FRONTEIRA DE CONFIANÇA (refutador, passadas 1 e 2, 2026-10-16) ──
# O ARQUIVO DE ALVOS (e a variável) É CÓDIGO: lê-lo é EXECUTAR o binário que ele nomeia, com o poder da conta
# declarada — e, se essa conta tem sudo sem senha, com o poder dela inteiro. Por isso:
#   · o censo rodando como ROOT recusa a perna do SDK inteira (passada 2: conta `-` sob root executava como uid 0);
#   · a conta declarada nunca é root nem uid 0;
#   · a FORMA do caminho é a do SDK (pacote em node_modules/@anthropic-ai/claude-agent-sdk/, binário `claude` num
#     irmão @anthropic-ai/claude-agent-sdk-<plataforma>/) E O LOCAL REAL também: os caminhos são resolvidos
#     (readlink -f) COMO A CONTA, o binário real tem de ficar na mesma árvore node_modules real do pacote, ser
#     DA conta declarada e não ser gravável por outros (nem o diretório dele); executa-se o caminho resolvido.
#     Passada 2: só o nome era fechado, e um `claude` em qualquer node_modules (no /tmp, no checkout) rodava.
# TETO declarado: a conta `-` é quem roda o censo — o binário tem o poder de quem o roda, como qualquer script do
# repo; entre a checagem e a execução há janela (TOCTOU) que só a conta dona ou root conseguem usar; e o grupo
# pode escrever (a instalação do bridge é 775/664 com o grupo da própria conta, medido em 2026-10-16).
SDK_CONF="${CC_DELTA_SDK_TARGETS-}"
if [ -z "${CC_DELTA_SDK_TARGETS+x}" ]; then
  SDK_CONF="${REPO}/ops/cc-sdk-targets.tsv"
  [ -f "${SDK_CONF}" ] || SDK_CONF=""
fi
: > "${TMPD}/sdk.tsv"
_as() {  # <conta|-> <cmd…>: roda como a conta dona do SDK, em /, sem pedir senha e sem herdar o stdin
  local u="$1"; shift
  if [ "${u}" = "-" ] || [ "${u}" = "$(id -un)" ]; then (cd / && "$@" < /dev/null); else (cd / && sudo -n -u "${u}" "$@" < /dev/null); fi
}
_sdk_bad() {  # <rótulo> <motivo>: alvo que não chega a ser medido (vira NÃO MEDIDO no veredito)
  printf '%s\t-\t-\t-\t%s\t\n' "$1" "$2" >> "${TMPD}/sdk.tsv"
}
_clip() { head -c 160 "$1" 2>/dev/null | tr '\t\n\r' '   '; }
# CC_DELTA_UID=0 só FORÇA a recusa (bancada que não roda como root); nunca afrouxa
_uid="$(id -u)"; [ "${CC_DELTA_UID:-}" = 0 ] && _uid=0
if [ -n "${SDK_CONF}" ] && [ "${_uid}" = 0 ]; then
  _sdk_bad "(alvos)" "o censo roda como root: recuso executar binário de SDK com uid 0 (rode como o operador)"
elif [ -n "${SDK_CONF}" ]; then
  if [ ! -f "${SDK_CONF}" ] || [ ! -r "${SDK_CONF}" ]; then
    _sdk_bad "(alvos)" "o arquivo de alvos declarado não existe ou não é legível: ${SDK_CONF}"
  else
    n=0; ln=0
    while IFS= read -r line || [ -n "${line}" ]; do
      ln=$((ln + 1)); line="${line%$'\r'}"
      t="${line#"${line%%[![:space:]]*}"}"
      case "${t}" in ''|'#'*) continue ;; esac
      n=$((n + 1))
      # split por TAB LITERAL: `IFS=$'\t' read` colapsa tabs seguidos (TAB é espaço em branco para o IFS) e
      # deslocava as colunas, lendo o binário como package.json
      f=(); rest="${line}"
      while :; do f+=("${rest%%$'\t'*}"); [[ "${rest}" == *$'\t'* ]] || break; rest="${rest#*$'\t'}"; done
      lb="(linha ${ln})"
      if [ "${#f[@]}" -ne 4 ]; then _sdk_bad "${lb}" "linha ${ln} do arquivo de alvos com ${#f[@]} coluna(s), não 4 (rótulo · conta|- · package.json · binário|-)"; continue; fi
      [[ "${f[0]}" =~ ^[A-Za-z0-9_.-]+$ ]] || { _sdk_bad "${lb}" "linha ${ln}: rótulo fora da forma [A-Za-z0-9_.-]"; continue; }
      lb="${f[0]}"; usr="${f[1]}"; pkg="${f[2]}"; bin="${f[3]}"
      if ! [[ "${usr}" =~ ^(-|[a-z_][a-z0-9_-]*)$ ]] || [ "${usr}" = root ] \
         || { [ "${usr}" != "-" ] && [ "$(id -u "${usr}" 2>/dev/null)" = 0 ]; }; then
        _sdk_bad "${lb}" "linha ${ln}: conta recusada (nunca root/uid 0; forma [a-z_][a-z0-9_-]* ou -)"; continue
      fi
      nm="${pkg%/@anthropic-ai/claude-agent-sdk/package.json}"
      if [[ "${pkg}${bin}" == *"/../"* || "${pkg}${bin}" == *"/./"* || "${pkg}${bin}" == *"//"* ]] \
         || ! [[ "${pkg}" =~ ^/([^/]+/)*node_modules/@anthropic-ai/claude-agent-sdk/package\.json$ ]]; then
        _sdk_bad "${lb}" "linha ${ln}: o package.json tem de ser <…>/node_modules/@anthropic-ai/claude-agent-sdk/package.json, absoluto e sem . ou .."; continue
      fi
      if [ "${bin}" != "-" ]; then
        mid="${bin#"${nm}/@anthropic-ai/claude-agent-sdk-"}"
        if [ "${mid}" = "${bin}" ] || ! [[ "${mid}" =~ ^[a-z0-9-]+/claude$ ]]; then
          _sdk_bad "${lb}" "linha ${ln}: o binário tem de ser o claude de @anthropic-ai/claude-agent-sdk-<plataforma> na mesma árvore node_modules do package.json, ou -"; continue
        fi
      fi
      # o LOCAL REAL, resolvido como a conta (a home dela pode ser fechada para quem roda o censo)
      own="${usr}"; [ "${own}" = "-" ] && own="$(id -un)"
      rn="$(_as "${usr}" /usr/bin/env -i PATH=/usr/bin:/bin readlink -e -- "${nm}" 2> "${TMPD}/rl.err")"; rrc=$?
      if [ "${rrc}" != 0 ] || [ -z "${rn}" ]; then
        _sdk_bad "${lb}" "linha ${ln}: inalcançável como a conta ${own}: o node_modules não resolve (readlink rc=${rrc}: $(_clip "${TMPD}/rl.err"))"; continue
      fi
      rp="$(_as "${usr}" /usr/bin/env -i PATH=/usr/bin:/bin readlink -f -- "${pkg}" 2>/dev/null)"
      if [ "${rp}" != "${rn}/@anthropic-ai/claude-agent-sdk/package.json" ]; then
        _sdk_bad "${lb}" "linha ${ln}: o package.json real (${rp:-irresolúvel}) não fica em node_modules/@anthropic-ai/claude-agent-sdk/ de ${rn:-?}"; continue
      fi
      if [ "${bin}" != "-" ]; then
        rb="$(_as "${usr}" /usr/bin/env -i PATH=/usr/bin:/bin readlink -f -- "${bin}" 2>/dev/null)"
        mid="${rb#"${rn}/@anthropic-ai/claude-agent-sdk-"}"
        if [ -z "${rb}" ] || [ "${mid}" = "${rb}" ] || ! [[ "${mid}" =~ ^[a-z0-9-]+/claude$ ]]; then
          _sdk_bad "${lb}" "linha ${ln}: o binário real (${rb:-irresolúvel}) não fica em @anthropic-ai/claude-agent-sdk-<plataforma>/ da mesma árvore node_modules real"; continue
        fi
        st="$(_as "${usr}" /usr/bin/env -i PATH=/usr/bin:/bin stat -c '%U %a' -- "${rb}" "${rb%/claude}" 2>/dev/null | tr '\n' ' ')"
        read -r o1 m1 o2 m2 _ <<< "${st}"
        if [ "${o1:-}" != "${own}" ] || [ "${o2:-}" != "${own}" ] || ! [[ "${m1:-}" =~ ^[0-7]*[0145]$ ]] || ! [[ "${m2:-}" =~ ^[0-7]*[0145]$ ]]; then
          _sdk_bad "${lb}" "linha ${ln}: o binário real e o diretório dele têm de ser da conta ${own} e não graváveis por outros (medido: ${st:-sem stat})"; continue
        fi
        bin="${rb}"
      fi
      pkg="${rp}"
      # teto de tempo e de tamanho também na leitura (um FIFO travava o censo; /dev/zero encheria o /tmp)
      _as "${usr}" /usr/bin/env -i PATH=/usr/bin:/bin timeout 30 head -c 1048576 -- "${pkg}" > "${TMPD}/sdk-${n}.pkg" 2> "${TMPD}/sdk-${n}.pkgerr"; prc=$?
      brc=-
      if [ "${bin}" != "-" ]; then
        _as "${usr}" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/nonexistent DISABLE_AUTOUPDATER=1 \
          timeout 30 "${bin}" --version > "${TMPD}/sdk-${n}.bin" 2> "${TMPD}/sdk-${n}.binerr"; brc=$?
      fi
      pwhy="$(_clip "${TMPD}/sdk-${n}.pkgerr")"; [ "${prc}" = 124 ] && pwhy="${pwhy:+${pwhy}; }teto de 30 s"
      bwhy="$(_clip "${TMPD}/sdk-${n}.binerr" 2>/dev/null)"; [ "${brc}" = 124 ] && bwhy="${bwhy:+${bwhy}; }teto de 30 s"
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${lb}" "${n}" "${prc}" "${brc}" "${pwhy}" "${bwhy}" >> "${TMPD}/sdk.tsv"
    done < "${SDK_CONF}"
    [ "${n}" -gt 0 ] || _sdk_bad "(alvos)" "o arquivo de alvos ${SDK_CONF} não declara nenhum alvo (só comentários ou vazio)"
  fi
fi

# ── CHANGELOG oficial ──────────────────────────────────────────────────────────────────────
CL="${CC_DELTA_CHANGELOG:-}"
if [ -z "${CL}" ]; then
  URL="${CC_DELTA_URL:-https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md}"
  CL="${TMPD}/CHANGELOG.md"
  if ! curl -sfL --max-time 60 "${URL}" -o "${CL}"; then
    echo "cc-delta-census: CHANGELOG oficial inalcançável (${URL}) — declaro a lacuna e paro; não invento o delta" >&2; exit 2
  fi
fi
[ -s "${CL}" ] || { echo "cc-delta-census: CHANGELOG vazio ou ausente: ${CL}" >&2; exit 2; }

TODAY="${CC_DELTA_TODAY:-$(date +%F)}"
PYTHONDONTWRITEBYTECODE=1 python3 -I -B - "${REPO}" "${CL}" "${BASE}" "${DISK}" "${PROC}" "${FMT}" "${WRITE}" "${TODAY}" "${OVR}" "${TMPD}" "${SDK_CONF}" <<'PY'
import sys, os, re, json, glob, datetime
repo, cl, base, disk, proc, fmt, write, today, ovr, tmpd, sdk_conf = sys.argv[1:12]
def vt(v): return tuple(int(x) for x in v.split('.'))
text = open(cl, encoding='utf-8').read()
parts = re.split(r'(?m)^## ', text)
sections = {}
for p in parts[1:]:
    head = p.split('\n', 1)[0].strip()
    m = re.match(r'^(\d+\.\d+\.\d+)\b', head)
    if m: sections[m.group(1)] = '## ' + p   # byte-a-byte como a r8: a seção inclui a linha em branco que a separa da próxima
if not sections:
    print('cc-delta-census: nenhuma seção "## x.y.z" no CHANGELOG — formato desconhecido, não meço', file=sys.stderr); sys.exit(2)
if base not in sections:
    print(f'cc-delta-census: a baseline {base} não está no CHANGELOG — o delta seria chute', file=sys.stderr); sys.exit(2)
target = max([v for v in (disk, proc) if v], key=vt)
if target not in sections:
    print(f'cc-delta-census: a versão instalada {target} não está no CHANGELOG (fonte defasada?) — não meço', file=sys.stderr); sys.exit(2)
delta = sorted([v for v in sections if vt(base) < vt(v) <= vt(target)], key=vt)
items = {v: len(re.findall(r'(?m)^- ', sections[v])) for v in delta}
lines = {v: len(sections[v].splitlines()) for v in delta}
avisos = []
if ovr:
    avisos.append(f'override ativo, esta NÃO é a medição de produção: {ovr}')
if disk and proc and disk != proc:
    avisos.append(f'processo em {proc} e disco em {disk}: o que só existe na versão nova está invisível nesta sessão (reinicie antes de medir capacidade)')
if vt(target) < vt(base):
    avisos.append(f'a instalada ({target}) é ANTERIOR à baseline ({base}) — downgrade? nada a medir para frente')

# ── o CLI embutido no Agent SDK (SAC-155): a quem o delta chega em produção ─────────────────
# Cada perna que falha (pacote ou binário) gera aviso PRÓPRIO com rc e motivo: a declaração cruzada que cai
# em silêncio é fail-open (refutador, passada 1: binário rc 0 sem versão trocava "vale o binário" pelo pacote
# sem dizer nada).
def _x(path):
    try: return open(path, encoding='utf-8', errors='replace').read()
    except Exception: return ''
VRE = r'(\d+\.\d+\.\d+)(-[0-9A-Za-z.-]+)?'
sdks = []   # dicts: label, cli, sdk, fonte, falta (motivo de NÃO MEDIDO, vazio se medido)
for r in [l.split('\t', 5) for l in _x(os.path.join(tmpd, 'sdk.tsv')).splitlines() if l]:
    lb, n, prc, brc, pwhy, bwhy = (r + [''] * 6)[:6]
    d = {'label': lb, 'cli': '', 'sdk': '', 'fonte': '', 'falta': ''}
    if n == '-':
        d['falta'] = pwhy; sdks.append(d); continue
    pkg_cc, pkg_err, bin_err, sufixo = '', '', '', ''
    if prc == '0':
        try:
            pj = json.loads(_x(os.path.join(tmpd, f'sdk-{n}.pkg')))
            d['sdk'] = str(pj.get('version', '') or '')
            m = re.search(VRE, str(pj.get('claudeCodeVersion', '') or ''))
            pkg_cc = m.group(1) if m else ''
            if not pkg_cc: pkg_err = 'o package.json não declara claudeCodeVersion legível'
        except Exception as e:
            pkg_err = f'package.json ilegível ({type(e).__name__})'
    else:
        pkg_err = f'package.json rc={prc}' + (f': {pwhy.strip()}' if pwhy.strip() else '')
    bin_v = ''
    if brc == '0':
        m = re.search(VRE, _x(os.path.join(tmpd, f'sdk-{n}.bin')))
        if m: bin_v, sufixo = m.group(1), m.group(2) or ''
        else: bin_err = 'binário rc=0 SEM versão na saída'
    elif brc != '-':
        bin_err = f'binário rc={brc}' + (f': {bwhy.strip()}' if bwhy.strip() else '')
    if bin_v:
        d['cli'], d['fonte'] = bin_v, 'binário --version'
        if pkg_cc and pkg_cc != bin_v:
            avisos.append(f'SDK {lb}: o binário responde {bin_v} e o package.json declara claudeCodeVersion {pkg_cc} — vale o binário (é o que roda); o pacote está remendado ou fora do lock')
        if sufixo:
            avisos.append(f'SDK {lb}: o binário responde {bin_v}{sufixo}, um PRÉ-RELEASE — comparado como {bin_v}')
    elif pkg_cc:
        d['cli'], d['fonte'] = pkg_cc, 'package.json claudeCodeVersion' + (' (binário NÃO respondeu)' if bin_err else ' (sem binário declarado)')
    if not d['cli']:
        d['falta'] = '; '.join(x for x in (pkg_err, bin_err) if x) or 'nenhuma perna deu versão'
    else:
        if pkg_err: avisos.append(f'SDK {lb}: {pkg_err} — a versão {d["cli"]} vale só pelo binário, sem a declaração cruzada')
        if bin_err: avisos.append(f'SDK {lb}: {bin_err} — a versão {d["cli"]} é a DECLARADA pelo pacote, não a medida no que roda')
    sdks.append(d)
for d in sdks:
    if d['falta']:
        avisos.append(f'SDK {d["label"]}: NÃO MEDIDO ({d["falta"]}) — a quem o delta chega em produção ficou sem medida')
        continue
    c = d['cli']
    if vt(c) < vt(target):
        atras = sum(1 for v in sections if vt(c) < vt(v) <= vt(target))
        avisos.append(f'o CLI do SDK {d["label"]} ({c}{", SDK " + d["sdk"] if d["sdk"] else ""}) está {atras} versão(ões) publicada(s) atrás do host ({target}): o que entrou depois de {c} NÃO chega a quem serve por ele — suba o SDK antes de dar o delta por recebido em produção')
    elif vt(c) > vt(target):
        avisos.append(f'o CLI do SDK {d["label"]} ({c}) está À FRENTE do host ({target}): o delta medido aqui não cobre o que produção já roda')

# ── inventário das superfícies do Onion (o que EXISTE; não o que é tocado) ─────────────────
def fm(path):
    try: s = open(path, encoding='utf-8').read()
    except Exception: return ''
    if not s.startswith('---'): return ''
    end = s.find('\n---', 3)
    return s[3:end] if end > 0 else ''
inv = {}
hooks = []
sj = os.path.join(repo, '.claude/settings.json')
if os.path.isfile(sj):
    try:
        conf = json.load(open(sj, encoding='utf-8'))
    except Exception as e:
        print(f'cc-delta-census: .claude/settings.json ilegível ({e}) — inventário de hooks impossível', file=sys.stderr); sys.exit(2)
    for ev, arr in (conf.get('hooks') or {}).items():
        for m in arr or []:
            for h in m.get('hooks', []) or []:
                cmd = h.get('command') or h.get('url') or h.get('prompt') or ''
                nm = re.search(r'([A-Za-z0-9_.-]+\.(?:sh|py|js|mjs))', cmd)
                hooks.append({'evento': ev, 'tipo': h.get('type', '?'), 'alvo': nm.group(1) if nm else cmd[:40],
                              'onFailure': h.get('onFailure', '—'), 'async': h.get('async', False), 'timeout': h.get('timeout', '—')})
inv['hooks'] = hooks
inv['rules_paths'] = sorted(os.path.relpath(f, repo) for f in glob.glob(os.path.join(repo, '.claude/rules/*.md')) if re.search(r'(?m)^paths:', fm(f)))
inv['skills_fork'] = sorted(os.path.relpath(f, repo) for f in glob.glob(os.path.join(repo, '.claude/skills/*/SKILL.md')) if re.search(r'(?m)^context:\s*fork', fm(f)))
models = {}
for f in glob.glob(os.path.join(repo, '.claude/agents/**/*.md'), recursive=True):
    m = re.search(r'(?m)^model:\s*(.+)$', fm(f))
    k = m.group(1).strip() if m else '(sem model)'
    models[k] = models.get(k, 0) + 1
inv['agentes_por_model'] = dict(sorted(models.items()))
sm = []
bl = os.path.join(repo, 'docs/onion/radar-baselines.yaml')
if os.path.isfile(bl):
    s = open(bl, encoding='utf-8').read()
    m = re.search(r'session_models:\s*\n((?:\s+- .+\n)+)', s)
    if m: sm = [re.sub(r'\s*#.*$', '', x).strip('- "\'\t ') for x in m.group(1).splitlines()]
inv['session_models'] = [x for x in sm if x]
# a rodada anterior e o diretório da próxima saem da baseline, não da memória de quem conduz
prev_kg, next_dir = '', ''
if os.path.isfile(bl):
    m = re.search(r'id: E3-claude-code-delta\n((?:    .*\n|\s*#.*\n)+)', open(bl, encoding='utf-8').read())
    k = re.search(r'(?m)^    kg:\s*(\S+)', m.group(1)) if m else None
    if k:
        prev_kg = k.group(1)
        r = re.search(r'-r(\d+)/', prev_kg)
        if r: next_dir = f'docs/evolution/research/radar-E3-{today}-r{int(r.group(1)) + 1}/'
# Os plugins que o core PUBLICA saem dos MANIFESTOS (F4 das portas, 2026-10-10): o `plugins/` montado não é
# mais versionado aqui. O nome do arquivo é o PLUGIN_NAME por convenção (verticals/<nome>.manifest.sh).
inv['plugins'] = sorted(os.path.basename(m)[:-len('.manifest.sh')] for m in glob.glob(os.path.join(repo, '.claude/utils/marketplace/verticals/*.manifest.sh')) if not os.path.basename(m).startswith('__'))
inv['marketplace'] = os.path.isfile(os.path.join(repo, '.claude-plugin/marketplace.json'))
wf = []
for pat in ('.claude/**/*.md', '.claude/**/*.js', '.claude/**/*.mjs'):
    for f in glob.glob(os.path.join(repo, pat), recursive=True):
        if '/worktrees/' in f: continue
        try:
            if 'scriptPath' in open(f, encoding='utf-8').read(): wf.append(os.path.relpath(f, repo))
        except Exception: pass
inv['workflow_scriptpath'] = sorted(set(wf))
# guardas de DERIVA DE BINÁRIO: famílias da bancada que leem o Claude Code INSTALADO (`command -v claude`).
# No CI não há binário e elas só medem a cópia; a deriva do motor só aparece onde ele existe — então a
# rodada as roda aqui. Nasceu do SAC-84 (2026-10-09): a 2.1.295 renomeou as locais do parser de diretivas
# e o (f) do cited_directive reprovou a main LOCAL, invisível ao CI.
bin_guards, fam = [], None
st = os.path.join(repo, '.claude/validation/lint-selftest.sh')
if os.path.isfile(st):
    for ln in open(st, encoding='utf-8', errors='replace'):
        m = re.match(r'^(run_[A-Za-z0-9_]+)_selftests\(\)\s*\{', ln)
        if m: fam = m.group(1)[4:]
        elif fam and re.search(r'command -v claude\b', ln) and fam not in bin_guards: bin_guards.append(fam)
inv['guardas_binario'] = bin_guards
# sinal factual, não ligação: id de modelo citado no delta que não está na allowlist do E6
novos = sorted({m for v in delta for m in re.findall(r'claude-[a-z]+-\d+(?:-\d+)?', sections[v])} - set(inv['session_models']))

veredito = 'NADA A MEDIR' if not delta else f'DELTA {len(delta)} versão(ões): {delta[0]} a {delta[-1]}'
sem_onfail = [h for h in hooks if h['onFailure'] == '—']

if write:
    os.makedirs(os.path.join(write, 'data'), exist_ok=True)
    for v in delta:
        open(os.path.join(write, 'data', f'{v}.txt'), 'w', encoding='utf-8').write(sections[v])
    if delta:
        rid = os.path.basename(os.path.normpath(write))
        review = (datetime.date.fromisoformat(today) + datetime.timedelta(days=30)).isoformat()
        conta = ', '.join(f'{v} ({lines[v]} linhas, {items[v]} itens)' for v in delta)
        rel = os.path.relpath(os.path.join(write, 'data'), repo) if os.path.isabs(write) else os.path.join(write, 'data')
        sdk_va = ''.join(f', SDK {d["label"]} ' + (d['cli'] if not d['falta'] else 'NÃO MEDIDO') for d in sdks)
        kg = f'''# kg-backlog-guard: on
# Radar E3 (ecossistema Claude Code): o delta de {delta[0]} a {delta[-1]} contra a baseline {base}.
# ESQUELETO gerado por .claude/validation/cc-delta-census.sh — a rodada liga item a superfície (com medição
# no vivo), o juiz refuta, e a rodada decide a Aufhebung: external_edges SUPERSEDES ou x_supersedes_none.
meta:
  id: {rid}
  schema_version: "1"
  baseline: "{today}"
  review_after: "{review}"   # 30d: cadência de ferramenta
  # ═══ TETO: 25 NÓS ═══
  #   2 no esqueleto ({today}).
# ═══ AUFHEBUNG: a rodada decide UMA forma antes de selar (a REGRA 89 acusa até lá) ═══
#   (a) derrubou nó da rodada anterior → descomente e NOMEIE o nó (contrato v4.3; o gate confere o alvo):
# external_edges:
#   - to: "{prev_kg or '<grafo da rodada anterior>'}#<NO_DERRUBADO>"
#     edge_type: SUPERSEDES
#   (b) não derrubou nada → no meta: x_supersedes_none: "<a razão medida>"
nodes:
  - id: E_DELTA_DA_RODADA
    node_type: evidence
    layer: audit
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    verified_at: "{today}"
    verified_against: "CHANGELOG oficial: seções {conta}; baseline {base}, disco {disk or '—'}, processo {proc or '—'}{sdk_va}"
    label: "o delta desde a baseline {base} são {len(delta)} versão(ões), de {delta[0]} a {delta[-1]}, extraídas do CHANGELOG oficial"
    provenance:
      source: "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"
      locator: "seções ## {delta[0]} a ## {delta[-1]} (cópias em {rel}/)"
      method: "medição: extração determinística pelo cc-delta-census.sh"
      locality: "web"
  - id: Q_O_QUE_O_DELTA_TOCA_NO_ONION
    node_type: question
    layer: audit
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    verified_at: "{today}"
    verified_against: "aberta pelo esqueleto em {today}; fecha quando a rodada ligar cada item a superfície medida no vivo e o juiz refutar"
    label: "quais itens de {delta[0]} a {delta[-1]} tocam o Onion de verdade, medidos no vivo e julgados pelo juiz"
edges:
  - from: E_DELTA_DA_RODADA
    to: Q_O_QUE_O_DELTA_TOCA_NO_ONION
    edge_type: SUPPORTS
'''
        open(os.path.join(write, f'{rid}.kg.yaml'), 'w', encoding='utf-8').write(kg)

if fmt == '--tsv':
    print(f'veredito\t{veredito}'); print(f'baseline\t{base}'); print(f'disco\t{disk}'); print(f'processo\t{proc}')
    print(f'rodada_anterior\t{prev_kg}'); print(f'proxima_rodada\t{next_dir}')
    if not sdks: print('sdk\t-\tsem_alvo')
    for d in sdks:
        print(f'sdk\t{d["label"]}\tnao_medido\t{d["falta"]}' if d['falta'] else f'sdk\t{d["label"]}\t{d["cli"]}\t{d["sdk"] or "-"}\t{d["fonte"]}')
    for v in delta: print(f'versao\t{v}\t{lines[v]}\t{items[v]}')
    print(f'hooks\t{len(hooks)}\tsem_onFailure\t{len(sem_onfail)}')
    for f in inv['guardas_binario']: print(f'guarda_binario\t{f}')
    for a in avisos: print(f'aviso\t{a}')
    sys.exit(0)

print(f'# delta do Claude Code · {today}\n')
print(f'**VEREDITO: {veredito}**\n')
print('| fonte | versão |\n|---|---|')
print(f'| baseline E3 (`cc_version`) | {base} |\n| disco (`claude --version`) | {disk or "— (sem sinal)"} |\n| processo | {proc or "— (sem sinal)"} |')
if not sdks:
    print('| CLI embutido em Agent SDK | — (nenhum alvo declarado' + (f': {sdk_conf} vazio' if sdk_conf else '') + ') |')
for d in sdks:
    if d['falta']: print(f'| SDK `{d["label"]}` (CLI embutido) | — NÃO MEDIDO ({d["falta"]}) |')
    else: print(f'| SDK `{d["label"]}` (CLI embutido, {d["fonte"]}) | {d["cli"]}' + (f' (SDK {d["sdk"]})' if d['sdk'] else '') + ' |')
print()
for a in avisos: print(f'⚠️ {a}\n')
if not delta:
    print('Nada a medir: a instalada não passa da baseline. Não há rodada a escrever.')
    sys.exit(0)
print(f'- rodada anterior (baseline E3 `kg`): `{prev_kg or "— (não lida)"}`')
print(f'- diretório da próxima rodada: `{next_dir or "— (sem -rN na rodada anterior: nomeie à mão)"}`\n')
print('## seções do delta (texto integral em `data/<versão>.txt` com `--write`)\n')
print('| versão | linhas | itens |\n|---|---|---|')
for v in delta: print(f'| {v} | {lines[v]} | {items[v]} |')
print('\n## superfícies do Onion (inventário; a LIGAÇÃO item↔superfície é da rodada e do juiz)\n')
print(f'- hooks: **{len(hooks)}**, sem `onFailure`: **{len(sem_onfail)}**, async: {sum(1 for h in hooks if h["async"])}')
for h in hooks: print(f'  - {h["evento"]} · {h["tipo"]} · {h["alvo"]} · onFailure={h["onFailure"]} · timeout={h["timeout"]}')
print(f'- rules com `paths:` ({len(inv["rules_paths"])}): ' + ', '.join(inv['rules_paths']))
print(f'- skills `context: fork`: {len(inv["skills_fork"])}' + (': ' + ', '.join(inv['skills_fork']) if inv['skills_fork'] else ''))
print('- agentes por model: ' + ', '.join(f'{k}={v}' for k, v in inv['agentes_por_model'].items()))
print('- allowlist de modelo (E6 `session_models`): ' + (', '.join(inv['session_models']) or '— (não lida)'))
print(f'- plugins ({len(inv["plugins"])}): ' + ', '.join(inv['plugins']) + f' · marketplace.json: {"sim" if inv["marketplace"] else "não"}')
print(f'- arquivos de `.claude/` que citam `scriptPath` (citação, não execução): {len(inv["workflow_scriptpath"])}')
gb = inv['guardas_binario']
print(f'- guardas de deriva de binário ({len(gb)}; só medem onde o Claude Code está instalado, o CI não as vê — RODE-AS nesta rodada): '
      + (', '.join(f'`LC_ALL=C bash .claude/validation/lint-selftest.sh --families {f}`' for f in gb) or '—'))
if novos: print(f'\n- sinal: ids de modelo citados no delta e fora da allowlist do E6: ' + ', '.join(novos))
print('\n(TETO: este censo mede versões, delta e superfícies. Ele NÃO diz que um item toca o Onion —'
      ' na r8 três ligações assim foram reprovadas pelo juiz medindo o vivo.)')
PY
