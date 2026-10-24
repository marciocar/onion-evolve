#!/usr/bin/env bash
# kg-trace.sh — a REGRA 55 e o índice de leitura do KG, julgados pelo PARSER DO PRODUTO (kg-ssot `kg_trace.py`).
#
# ═══ POR QUE EXISTE (2026-10-24) ═══
# Até a 4.25 do kg-ssot, a casa mantinha o próprio resolvedor de `trace:` (o kg-trace-resolve.sh, ~290 linhas de
# awk, que nesta data saiu do julgamento e ficou só para o índice): ele julgava a REGRA 55 (O `trace:` de um nó APONTA para alvo que EXISTE) e emitia o
# índice de leitura. A 4.25 trouxe o `kg_trace.py` (`kg-ssot.trace/1`), que é aquela gramática promovida ao produto.
# Medido na main de 2026-10-24: 2.501 julgados nos dois, 2.501 resolvem, 0 a mais e 0 a menos.
# Este script NÃO tem parser: o julgamento é o `kg_trace.py check`. O que fica aqui é só o que o produto não faz:
# (1) o TSV que o lint consome, (2) a guarda de vacuidade da casa e (3) a porta única do índice de leitura.
# O ÍNDICE AINDA NÃO É DO PRODUTO: o `kg-ssot.trace/1` da 4.25.0 não traz os traces que resolvem, e a API interna
# do vendor (`kg_trace.classify`) não é contrato. Até a kg-ssot 4.25.1 (que traz os resolvidos no JSON), o
# `--emit-index` delega ao kg-trace-resolve.sh, restrito a esse uso — com os defeitos dele no índice: id entre
# aspas COM as aspas (5 nós), alvo da 2ª raiz sem normalizar (1), 3ª raiz não indexada. Gatilho no nó
# Q_INDICE_DE_LEITURA_PELO_KG_TRACE_4251 (sinais-de-campo-2026-09). Os consumidores já chamam este script, então a
# troca será só aqui.
#
# A raiz externa `memory/` (a memória da sessão, fora do repo) é declarada ao produto com --external-root.
#
# Uso  : bash .claude/validation/kg-trace.sh [<repo_root>] [--format tsv | --emit-index]
# Saída: humano (a saída do produto) · TSV `grafo·id·node_type·alvo·veredito` (só os que reprovam) ·
#        índice `caminho·id·grafo`, ordenado (LC_ALL=C sort -u)
# Exit : 0 = todo `trace:` julgável resolve / índice emitido · 1 = TARGET-MISSING, grafo ilegível ou VACUIDADE
#        2 = sem o produto (kg_trace.py, seus vizinhos ou python3 ausentes) ou entrada quebrada
#        3 = (--emit-index) índice VAZIO: nenhum nó com trace resolvível — legítimo no dia 1 do adotante
#        (o --emit-index devolve o rc do kg-trace-resolve.sh, que tem o mesmo contrato)
# Env  : ONION_KG_TRACE — caminho do kg_trace.py (default: <repo_root>/vendor/kg-ssot/tools/kg_trace.py; a bancada
#        aponta o do core quando roda numa caixa de areia sem vendor).
set -euo pipefail

REPO_ROOT="$(cd "${1:-$(dirname "${BASH_SOURCE[0]}")/../..}" 2>/dev/null && pwd)" || {
  printf 'kg-trace: repo_root inválido\n' >&2; exit 2; }
MODE=human
for a in "$@"; do case "$a" in tsv|--format=tsv) MODE=tsv ;; --emit-index) MODE=index ;; esac; done
if [ "${MODE}" = index ]; then
  # ATÉ A kg-ssot 4.25.1: o índice segue no resolvedor da casa, restrito a este uso (ver o cabeçalho dele). O
  # trace/1 da 4.25.0 não traz os traces que resolvem, e a API interna do vendor (classify) não é contrato.
  _R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kg-trace-resolve.sh"
  [ -f "${_R}" ] || { echo "ERRO kg-trace --emit-index: gerador do índice ausente (${_R})" >&2; exit 2; }
  exec bash "${_R}" "${REPO_ROOT}" --emit-index
fi
KT="${ONION_KG_TRACE:-${REPO_ROOT}/vendor/kg-ssot/tools/kg_trace.py}"
# o próprio produto KG-SSOT (tools/ na raiz, sem vendor de si mesmo) se julga pelo kg_trace.py dele
[ -n "${ONION_KG_TRACE:-}" ] || [ -f "${KT}" ] || [ ! -f "${REPO_ROOT}/tools/kg_trace.py" ] || KT="${REPO_ROOT}/tools/kg_trace.py"
command -v python3 >/dev/null 2>&1 || { echo "ERRO kg-trace: python3 ausente" >&2; exit 2; }
# O perfil `gate` do release.json do kg-ssot não leva kg_trace.py nem kg_query.py (que ele importa): o adotante com
# esse perfil, ou com vendor próprio anterior à 4.25, cai aqui, e o lint diz que NÃO julgou (nunca verde, nunca HARD).
_KTD="$(dirname "${KT}")"
{ [ -f "${KT}" ] && [ -f "${_KTD}/kg_query.py" ] && [ -f "${_KTD}/kg_validate.py" ]; } || {
  echo "ERRO kg-trace: kg_trace.py ausente ou incompleto (${KT}, com kg_query.py e kg_validate.py ao lado) — o vendor kg-ssot >= 4.25, perfil completo, é quem julga o trace" >&2; exit 2; }


if [ "${MODE}" = human ]; then
  python3 -I -B "${KT}" check --root "${REPO_ROOT}" --external-root memory/
  exit $?
fi

# ── TSV para o lint ──────────────────────────────────────────────────────────────────────────────────────────
# O rc do produto é lido, nunca a prosa: 0 resolve · 1 missing/ilegível · outro = entrada quebrada (a regra vira
# HARD de ambiente no lint, nunca verde).
_kj="$(mktemp)"; trap 'rm -f "${_kj}"' EXIT
_krc=0; python3 -I -B "${KT}" check --root "${REPO_ROOT}" --external-root memory/ --format json >"${_kj}" 2>/dev/null || _krc=$?
case "${_krc}" in 0|1) : ;; *) printf '%s\t%s\t%s\t%s\t%s\n' '-' 'PRODUTO' '-' "(kg_trace.py rc=${_krc})" 'ENTRADA-QUEBRADA'; exit 1 ;; esac

# GUARDA DE VACUIDADE (herdada do resolvedor da casa, e a razão de ela seguir aqui): um leitor que não lê nada e
# diz OK é pior que guarda nenhuma. O produto conta julgados E excluídos; só há vacuidade quando NADA foi lido
# (nem julgável, nem excluído) e o corpus TEM `trace:` — tudo não-julgável por desenho não é parser morto.
_tsv="$(python3 -I -B - "${_kj}" "${REPO_ROOT}" <<'PY'
import json, pathlib, re, subprocess, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
root = pathlib.Path(sys.argv[2])
read = d.get("judged", 0) + sum(d.get("skipped", {}).values())
if read == 0:
    out = subprocess.run(["git", "-C", str(root), "ls-files", "-z", "--", "*.kg.yaml", "*.kg.json"], capture_output=True)
    names = [n for n in out.stdout.decode("utf-8", "surrogateescape").split("\0") if n]
    pat = re.compile(r"^\s+(-\s+)?trace:|\"trace\"\s*:", re.M)
    def has_trace(n):
        try:
            return bool(pat.search((root / n).read_text(encoding="utf-8")))
        except (OSError, UnicodeDecodeError):
            return False
    if any(has_trace(n) for n in names if "fixture" not in n and "testdata/" not in n and "__snapshots__/" not in n
           and not n.startswith("vendor/") and "/vendor/" not in n and not n.startswith("docs/materials/")):
        print("-\tPARSER\t-\t(nenhum nó lido)\tVACUIDADE")
for m in d.get("missing", []):
    print(f"{m['file']}\t{m['id']}\t{m.get('node_type') or '-'}\t{m['target']}\tTARGET-MISSING")
for u in d.get("unreadable", []):
    print(f"{u['file']}\t-\t-\t({u['code']})\tILEGIVEL")
PY
)" || { printf '%s\t%s\t%s\t%s\t%s\n' '-' 'PRODUTO' '-' '(JSON do kg_trace.py ilegível)' 'ENTRADA-QUEBRADA'; exit 1; }
[ -n "${_tsv}" ] || exit "${_krc}"
printf '%s\n' "${_tsv}"
exit 1
