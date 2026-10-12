#!/usr/bin/env bash
# =============================================================================
# direct-provider-api-check.sh — REGRA 105: script rastreado não chama a API do provedor de task
# manager por fora do adapter
#
# O QUE   : varre os arquivos RASTREADOS de código (.sh .bash .py .js .mjs .cjs .ts .rb .pl .php .ps1, e os
#           workflows de `.github/workflows/`, cujo step é shell) fora de `*/utils/task-manager/` e acusa a linha que monta uma URL `//<host>` de um provedor de
#           `.claude/utils/task-manager/provider-hosts.tsv`, quando o arquivo também tem um idioma de rede
#           (curl, wget, urllib, requests., fetch(, httpx, …). O adapter é o único lugar onde a chamada é
#           legítima; script que a carrega fora dele é o "cliente reescrito" que o tm.sh existe para matar.
#           Irmã da REGRA 10 (SDAAL: sem chamada direta a provider no consumidor), que procura o nome do MCP
#           (`mcp_jira_`, `mcp_ClickUp_`…) em comando/agente/workflow e não vê host HTTP nenhum.
#
# DEFEITO DATADO (SAC-75, 2026-10-12): o defeito medido mora no COMANDO da sessão (147 comandos Bash únicos
#           tocaram host de provedor entre 2026-09-23 e 2026-10-12, ~130 com cliente HTTP, e um deles DEPOIS
#           do tm.sh existir) — quem barra ali é o hook `pretooluse-direct-provider-api.sh`. Esta regra é a
#           outra metade da mesma fronteira: o script avulso que a sessão PROMOVE ao repo (`ops/`, `scripts/`)
#           escaparia do hook, porque o hook não lê arquivo de dentro do repo. Passivo medido na forja: ZERO
#           arquivo de código fora do adapter (só `adapters/linear.py` e `env-check.sh`, ambos dentro); o
#           histórico tem um caso de 2025 no `.cursor/` já removido. Nasce HARD e sem catraca, como a REGRA 102.
#
# FORA DO ESCOPO / TETO (declarado, não esquecido):
#   · MARKDOWN não é julgado — nem comando, nem agente, nem KB. Documentar ≠ chamar, e o bloco de código
#     de um .md não se distingue com certeza de um exemplo (o adapter clickup.md PRESCREVE o curl, porque
#     o ClickUp ainda não tem executável). Na dúvida a guarda cala (cláusula 4); quem barra a execução
#     de uma instrução de .md é o hook, no momento em que a sessão a roda.
#   · linha de COMENTÁRIO (`#`, `//`, `*`, `--`), docstring Python e linha de MENSAGEM (`echo`, `printf`,
#     `print`…) calam: é documentação dentro do script. O host tem de estar a até 3 linhas de um idioma de
#     rede FORA de literal de string (sem contar `import`); o idioma é por linguagem — `curl`/`wget` só em
#     shell e workflow. Endpoint numa constante a mais de 3 linhas da chamada passa (Elenxo, 2026-10-12).
#   · host montado em tempo de execução (`"api.linear" + ".app"`) passa — de propósito: é assim que a
#     própria bancada desta regra e o hook evitam carregar o host literal.
#   · arquivo não rastreado, arquivo sem extensão de código e arquivo > 1 MiB não são lidos.
#   · arma TODOS os provedores do mapa (ao contrário do hook, que arma só o que tem executável): o lugar
#     do código de provedor é o adapter, exista ou não o executável — e o passivo é zero.
#   · no derivado (adotante/porta) o dispatcher não chama esta regra: lá o PRODUTO do adotante pode
#     integrar com o provedor, e isso não é bypass do adapter do Onion.
#
# Uso    : direct-provider-api-check.sh [REPO_DIR] [--format text|tsv]
#          direct-provider-api-check.sh --selftest
# Saída  : HARD<TAB>chamada-direta<TAB><caminho>:<linha><TAB><msg> (tsv) · vazio = limpo
#          SOFT<TAB>mapa-ausente<TAB><caminho><TAB><msg> quando o mapa de hosts não existe (não medido)
# Exit   : 0 = limpo · 1 = ao menos uma HARD · 2 = uso.
# =============================================================================
set -uo pipefail

FORMAT="text"; SELFTEST=0; REPO_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --selftest) SELFTEST=1; shift ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    -*) echo "uso: $0 [REPO_DIR] [--format text|tsv] | --selftest" >&2; exit 2 ;;
    *) REPO_DIR="$1"; shift ;;
  esac
done

check_repo() {  # $1=repo → tsv em stdout; rc 1 se houve HARD
  local repo="$1" map="$1/.claude/utils/task-manager/provider-hosts.tsv"
  if [ ! -f "${map}" ]; then
    printf 'SOFT\tmapa-ausente\t.claude/utils/task-manager/provider-hosts.tsv\tsem o mapa de hosts a REGRA 105 não mediu nada — não é aprovação\n'
    return 0
  fi
  command -v python3 >/dev/null 2>&1 || {
    printf 'SOFT\tpython-ausente\t.claude/validation/direct-provider-api-check.sh\tsem python3 a REGRA 105 não mediu nada — não é aprovação\n'; return 0; }
  git -C "${repo}" ls-files -z 2>/dev/null | ONION_REPO="${repo}" ONION_MAP="${map}" python3 -I -B /dev/fd/4 4<<'ONION_DPA_LINT_PY'
import os, re, sys

repo, mp = os.environ["ONION_REPO"], os.environ["ONION_MAP"]
pats = []
for line in open(mp, encoding="utf-8"):
    line = line.rstrip("\r\n")
    if not line.strip() or line.lstrip().startswith("#"):
        continue
    parts = line.split("\t")
    if len(parts) >= 2 and parts[0].strip() and parts[1].strip():
        pats.append((parts[0].strip(), re.compile(r"//(?:" + parts[1].strip() + r")")))
# idioma de rede por LINGUAGEM: em shell/workflow é o comando (curl, wget); em código é a biblioteca — `"curl" in c`
# num script Python de medição é palavra, não chamada (Elenxo, achado 5)
NET_LIB = r"urllib|urlopen|\brequests\.|http\.client|httpx|aiohttp|\bfetch\s*\(|axios|XMLHttpRequest|" \
          r"Net::HTTP|LWP::|HTTP::Tiny|Invoke-(?:WebRequest|RestMethod)|undici"
NET_CODE = re.compile(NET_LIB)
NET_SHELL = re.compile(NET_LIB + r"|\bcurl\b|\bwget\b")
STRLIT = re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|`(?:\\.|[^`\\])*`')
IMPORT = re.compile(r"^\s*(?:import\s|from\s+\S+\s+import\s|(?:const|let|var)\s+\w+\s*=\s*require\(|use\s)[^;]*;?\s*$")  # import não é chamada
MSG = re.compile(r"^\s*(?:echo|printf|print|die|warn|log|say)\b")
WINDOW = 3    # host e idioma de rede na mesma instrução, aproximada por janela de linhas
EXT = (".sh", ".bash", ".py", ".js", ".mjs", ".cjs", ".ts", ".rb", ".pl", ".php", ".ps1")
COMMENT = re.compile(r"^\s*(?:#|//|/\*|\*|--)")
found = 0
for rel in sys.stdin.read().split("\0"):
    wf = rel.startswith(".github/workflows/") and rel.endswith((".yml", ".yaml"))   # step de Actions é shell
    if not rel or not (rel.endswith(EXT) or wf) or "utils/task-manager/" in "/" + rel:
        continue
    path = os.path.join(repo, rel)
    try:
        if not os.path.isfile(path) or os.path.getsize(path) > 1048576:
            continue
        text = open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        continue
    shellish = rel.endswith((".sh", ".bash", ".yml", ".yaml", ".ps1"))
    net_rx = NET_SHELL if shellish else NET_CODE
    if not net_rx.search(text):
        continue
    lines, in_doc = [], None
    for ln in text.split("\n"):                     # comentário, docstring e linha de mensagem não são chamada
        if in_doc:
            lines.append("")
            if in_doc in ln: in_doc = None
            continue
        m = re.match(r'^\s*[rRbBuU]?("""|\'\'\')', ln) if rel.endswith(".py") else None
        if m:
            lines.append("")
            if ln.count(m.group(1)) < 2: in_doc = m.group(1)
            continue
        lines.append("" if COMMENT.match(ln) or MSG.match(ln) else ln)
    net = [k for k, ln in enumerate(lines) if not IMPORT.match(ln) and net_rx.search(STRLIT.sub('""', ln))]
    for n, ln in enumerate(lines, 1):
        hit = next((p for p, rx in pats if rx.search(ln)), None)
        if hit and any(abs(n - 1 - j) <= WINDOW for j in net):
            found = 1
            print("HARD\tchamada-direta\t%s:%d\tchama a API do %s direto, fora do adapter — o lugar do código de provedor é "
                  ".claude/utils/task-manager/adapters/%s.py (rode pelo tm.sh)" % (rel, n, hit, hit))
            break
sys.exit(1 if found else 0)
ONION_DPA_LINT_PY
}

_emit_all() {  # tsv → formato pedido
  local out="$1" sev code path msg
  [ -n "${out}" ] || return 0
  if [ "${FORMAT}" = "tsv" ]; then printf '%s\n' "${out}"; return 0; fi
  while IFS=$'\t' read -r sev code path msg; do
    [ -n "${sev}" ] && printf '%s [%s] %s: %s\n' "${sev}" "${code}" "${path}" "${msg}"
  done <<< "${out}"
}

run_selftest() {
  local self d ok=0 tot=0 H out
  self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  d="$(TMPDIR=/tmp mktemp -d)"
  H="api.linear"; H="${H}.app"     # o host nasce em tempo de execução: este arquivo não o carrega literal
  _mk() {  # repo novo com o mapa real
    rm -rf "${d}/r"; mkdir -p "${d}/r/.claude/utils/task-manager/adapters" "${d}/r/ops" "${d}/r/docs"
    cp "$(dirname "${self}")/../utils/task-manager/provider-hosts.tsv" "${d}/r/.claude/utils/task-manager/"
    git -C "${d}/r" init -q 2>/dev/null
  }
  _run() { git -C "${d}/r" add -A >/dev/null 2>&1; out="$(check_repo "${d}/r")"; }
  _c() {  # <nome> <condição avaliada: 0=passou>
    tot=$((tot + 1)); if [ "$2" = 0 ]; then ok=$((ok + 1)); echo "✓ $1"; else echo "✗ $1 [${out:0:160}]"; fi
  }
  # ── ACUSA ──
  _mk; printf 'import json,os,urllib.request\nr=urllib.request.Request("https://%s/graphql",data=b"{}")\n' "${H}" > "${d}/r/ops/linear-move.py"; _run
  grep -qP '^HARD\tchamada-direta\tops/linear-move\.py:2\t.*linear' <<< "${out}"; _c "(i) o script avulso promovido a ops/ acusa, na linha da URL" $?
  _mk; printf '#!/usr/bin/env bash\nB=https://%s/graphql\ncurl -s "$B" -d @q.json\n' "${H}" > "${d}/r/ops/move.sh"; _run
  grep -qP '^HARD\tchamada-direta\tops/move\.sh:2\t' <<< "${out}"; _c "(ii) shell com curl e a URL numa variável acusa" $?
  local J="atlassian"; J="${J}.net/rest"
  _mk; printf 'const r = await fetch(`https://${site}.%s/api/3/issue`)\n' "${J}" > "${d}/r/ops/j.mjs"; _run
  grep -qP '^HARD\tchamada-direta\tops/j\.mjs:1\t.*jira' <<< "${out}"; _c "(iii) provedor SEM executável (jira) também acusa no arquivo rastreado" $?
  local Z="projectsapi.zoho"; Z="${Z}.com"     # zoho: o 5º provider (paridade da REGRA dos 5 — o tipo já ficou sem ele uma vez)
  _mk; printf 'import urllib.request\nurllib.request.urlopen("https://%s/restapi/portals/")\n' "${Z}" > "${d}/r/ops/z.py"; _run
  grep -qP '^HARD\tchamada-direta\tops/z\.py:2\t.*zoho' <<< "${out}"; _c "(iii-z) provedor SEM executável (zoho) também acusa no arquivo rastreado" $?
  # ── CALA ──
  _mk; printf 'import urllib.request\nENDPOINT = "https://%s/graphql"\nurllib.request.urlopen(ENDPOINT)\n' "${H}" > "${d}/r/.claude/utils/task-manager/adapters/linear.py"; _run
  [ -z "${out}" ]; _c "(iv) o adapter executável cala" $?
  _mk; printf '# exemplo: curl https://%s/graphql\n' "${H}" > "${d}/r/docs/linear.md"
  printf '## Linear\n```python\nurllib.request.urlopen("https://%s/graphql")\n```\n' "${H}" > "${d}/r/docs/kb.md"; _run
  [ -z "${out}" ]; _c "(v) markdown com bloco de código cala (documentar ≠ chamar)" $?
  _mk; printf '#!/usr/bin/env bash\n# o adapter chama https://%s/graphql — aqui só se conta\ncurl -s https://example.com\n' "${H}" > "${d}/r/ops/c.sh"; _run
  [ -z "${out}" ]; _c "(vi) linha de comentário cala" $?
  _mk; printf 'import re\nHOST = re.compile(r"https://%s")\nprint(HOST.pattern)\n' "${H}" > "${d}/r/ops/conta.py"; _run
  [ -z "${out}" ]; _c "(vii) arquivo sem idioma de rede (só cita o host) cala" $?
  _mk; printf 'import urllib.request\n"""Antes: urllib contra https://%s; agora o tm.sh."""\ndef f(c):\n    return "curl" in c and "//%s" in c\n' "${H}" "${H}" > "${d}/r/ops/medir.py"
  printf '#!/usr/bin/env bash\necho "nao chame https://%s direto; use tm.sh" >&2\ncurl -s https://api.github.com/zen\n' "${H}" > "${d}/r/ops/aviso.sh"; _run
  [ -z "${out}" ]; _c "(xi) docstring, mensagem e script de medição que só citam calam (Elenxo)" $?
  _mk; printf 'import urllib.request\nurllib.request.urlopen("https://%s/graphql")\n' "${H}" > "${d}/r/ops/nao-rastreado.py"
  out="$(check_repo "${d}/r")"
  [ -z "${out}" ]; _c "(viii) arquivo NÃO rastreado não é lido" $?
  _mk; mkdir -p "${d}/r/.github/workflows"
  printf 'jobs:\n  s:\n    steps:\n      - run: curl -s https://%s/graphql -d @q.json\n' "${H}" > "${d}/r/.github/workflows/sync.yml"; _run
  grep -qP '^HARD\tchamada-direta\t\.github/workflows/sync\.yml:4\t' <<< "${out}"; _c "(x) step de workflow com curl acusa (o step é shell)" $?
  _mk; rm -f "${d}/r/.claude/utils/task-manager/provider-hosts.tsv"; _run
  grep -qP '^SOFT\tmapa-ausente\t' <<< "${out}"; _c "(ix) sem o mapa: SOFT 'não medido', nunca silêncio" $?
  rm -rf "${d}"
  echo "selftest: ${ok}/${tot} verdes"
  [ "${ok}" -eq "${tot}" ]
}

if [ "${SELFTEST}" = 1 ]; then run_selftest; exit $?; fi
[ -n "${REPO_DIR}" ] || REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
out="$(check_repo "${REPO_DIR}")"; rc=$?
_emit_all "${out}"
[ "${rc}" -eq 1 ] && exit 1
exit 0
