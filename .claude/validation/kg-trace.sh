#!/usr/bin/env bash
# kg-trace.sh — a REGRA 55 e o índice de leitura do KG, julgados pelo PARSER DO PRODUTO (kg-ssot `kg_trace.py`).
#
# ═══ POR QUE EXISTE (2026-10-24) ═══
# Até a 4.25 do kg-ssot, a casa mantinha o próprio resolvedor de `trace:` (~290 linhas de
# awk, que em 2026-10-24 saiu do julgamento e, com a 4.25.1, foi removido): ele julgava a REGRA 55 (O `trace:` de um nó APONTA para alvo que EXISTE) e emitia o
# índice de leitura. A 4.25 trouxe o `kg_trace.py` (`kg-ssot.trace/1`), que é aquela gramática promovida ao produto.
# Medido na main de 2026-10-24: 2.501 julgados nos dois, 2.501 resolvem, 0 a mais e 0 a menos.
# Este script NÃO tem parser: o julgamento é o `kg_trace.py check`. O que fica aqui é só o que o produto não faz:
# (1) o TSV que o lint consome, (2) a guarda de vacuidade da casa e (3) a porta única do índice de leitura.
# O ÍNDICE TAMBÉM É DO PRODUTO desde a kg-ssot 4.25.1: o `--emit-index` lê o `resolved_targets` do JSON
# `kg-ssot.trace/1` (`{file, id, node_type, target, path, kind}`) e emite `path·id·file`. O `path` NUNCA termina
# em barra (nem diretório; `kind` file|dir é o sinal), e o hook kg-read-leg.sh tira a barra do caminho consultado
# para casar. O resolvedor antigo da casa foi removido nesta troca, e com ele os defeitos que o índice
# carregava: id entre aspas COM as aspas, alvo da 2ª raiz com `../` e 3ª raiz não indexada.
#
# A raiz externa `memory/` (a memória da sessão, fora do repo) é declarada ao produto com --external-root.
#
# Uso  : bash .claude/validation/kg-trace.sh [<repo_root>] [--format tsv | --emit-index [--out <arquivo>]]
# --out: o índice é escrito num temporário AO LADO do destino e só troca o destino (mv) com rc 0. Existe porque
#        `--emit-index > docs/onion/kg-read-index.tsv` ESVAZIA o índice antes do erro: o shell trunca o arquivo
#        antes de o script rodar, e o rc 2 (vendor anterior à 4.25.1, produto ausente) deixava o adotante sem
#        índice (medido num adotante em 2026-10-26, restaurado pelo git). Com --out: rc 2 → destino INTACTO,
#        byte a byte. rc 3 (índice vazio declarado) → destino INTACTO também: ausente segue ausente, povoado
#        segue povoado, porque o rc 3 também vem com grafo ILEGÍVEL, e quem julga a divergência é a REGRA 84 —
#        se os traces sumiram de propósito, esvazie à mão (`: > <arquivo>`). Até 2026-10-26 o rc 3 com destino
#        ausente ou vazio fazia `: > <destino>`: um caminho de erro que CRIAVA o índice vazio (e, entre o teste
#        `-s` e a escrita, truncaria o que outro processo gravasse). A revisão adversarial do adotante sge achou;
#        o dia 1 não precisa do arquivo: a REGRA 84 dá SOFT sem índice e o hook cala sem ele.
#        Sem --out, o índice vai ao stdout como sempre (compatível).
# Saída: humano (a saída do produto) · TSV `grafo·id·node_type·alvo·veredito` (só os que reprovam) ·
#        índice `caminho·id·grafo`, ordenado (LC_ALL=C sort -u)
# Exit : 0 = todo `trace:` julgável resolve / índice emitido · 1 = TARGET-MISSING, grafo ilegível ou VACUIDADE
#        2 = sem o produto (kg_trace.py, seus vizinhos ou python3 ausentes) ou entrada quebrada
#        3 = (--emit-index) índice VAZIO: nenhum nó com trace resolvível — legítimo no dia 1 do adotante
#        O rc 3 do PRODUTO (kg-ssot >= 4.27: nenhum grafo lido, D_TRACE_EMPTY_CORPUS_RC_1025) é CORPUS VAZIO, nunca
#        entrada quebrada: humano e TSV passam com aviso (a guarda de vacuidade segue julgando), --emit-index sai 3
#        (--emit-index) 2 também quando o vendor é anterior à 4.25.1 (JSON sem `resolved_targets`): NAO-GEROU,
#        nunca índice vazio
# Excl.: <repo_root>/.kg-ssot/trace-excludes.txt (do ALVO, opcional) — um glob por linha, `#` comenta; cada um vira
#        `--exclude` do kg_trace.py. Existe porque o produto julga TODO .kg.yaml/.kg.json rastreado fora das pastas de
#        fixture, e um adotante pode guardar grafos quebrados DE PROPÓSITO noutro lugar (medido em 2026-10-25: o
#        kg-ssot tem 8 casos inválidos em docs/onion/measurements/, que o CI dele exclui; o update os tornava 8 HARD
#        da REGRA 55 com ILEGIVEL). O arquivo é do adotante; o core não escreve nele.
# Env  : ONION_KG_TRACE — caminho do kg_trace.py (default: <repo_root>/vendor/kg-ssot/tools/kg_trace.py; a bancada
#        aponta o do core quando roda numa caixa de areia sem vendor).
set -euo pipefail

REPO_ROOT="$(cd "${1:-$(dirname "${BASH_SOURCE[0]}")/../..}" 2>/dev/null && pwd)" || {
  printf 'kg-trace: repo_root inválido\n' >&2; exit 2; }
MODE=human OUT="" _prev=""
for a in "$@"; do
  [ "${_prev}" = --out ] && { OUT="${a}"; _prev=""; continue; }
  case "$a" in tsv|--format=tsv) MODE=tsv ;; --emit-index) MODE=index ;; --out) _prev=--out ;; --out=*) OUT="${a#--out=}" ;; esac
done
[ "${_prev}" != --out ] || { echo "ERRO kg-trace: --out sem arquivo" >&2; exit 2; }
if [ -n "${OUT}" ]; then
  [ "${MODE}" = index ] || { echo "ERRO kg-trace: --out só vale com --emit-index" >&2; exit 2; }
  # Escrita atômica: o script chama a si mesmo com o stdout num temporário AO LADO do destino (mesmo sistema de
  # arquivos, então o mv é rename) e só troca o destino com rc 0. Nenhum caminho de erro toca no destino.
  _odir="$(dirname -- "${OUT}")"
  # o diretório do destino nasce se faltar (o dia 1, e a worktree descartável onde docs/onion/ não é rastreado),
  # porque o temporário mora AO LADO do destino. Mas ele só FICA no sucesso: `_onew` guarda o ancestral mais alto
  # que ESTE script criou, e todo caminho de erro desfaz a cadeia (rmdir, só vazio; o que já existia nunca é tocado).
  # Revisão adversarial do adotante sge (2026-10-27): o mkdir antes do produto deixava o diretório no rc 3.
  _onew="" _op="${_odir}"
  while [ ! -e "${_op}" ] && [ ! -L "${_op}" ]; do _onew="${_op}"; _op="$(dirname -- "${_op}")"; done
  _oundo() {
    [ -n "${_onew}" ] || return 0
    local _d="${_odir}"
    while rmdir -- "${_d}" 2>/dev/null; do [ "${_d}" = "${_onew}" ] && break; _d="$(dirname -- "${_d}")"; done
  }
  mkdir -p -- "${_odir}" 2>/dev/null && [ -d "${_odir}" ] || { _oundo; echo "ERRO kg-trace --out: diretório do destino inválido (${_odir})" >&2; exit 2; }
  _otmp="$(mktemp "${_odir}/.kg-read-index.XXXXXX")" || { _oundo; echo "ERRO kg-trace --out: não consegui criar temporário em ${_odir}" >&2; exit 2; }
  trap 'rm -f "${_otmp}"; _oundo' EXIT   # interrupção no meio não deixa o temporário nem o diretório novo na árvore
  _args=() _skip=0
  for a in "$@"; do
    [ "${_skip}" -eq 1 ] && { _skip=0; continue; }
    case "$a" in --out) _skip=1 ;; --out=*) : ;; *) _args+=("$a") ;; esac
  done
  _orc=0; bash "${BASH_SOURCE[0]}" ${_args[@]+"${_args[@]}"} > "${_otmp}" || _orc=$?
  case "${_orc}" in
    0) if [ ! -s "${_otmp}" ]; then rm -f "${_otmp}"; echo "ERRO kg-trace --out: rc 0 com índice vazio — ${OUT} INTACTO" >&2; exit 2; fi
       # o modo do destino é preservado (o mktemp nasce 0600 e o mv levaria esse modo à árvore)
       if [ -e "${OUT}" ]; then chmod --reference="${OUT}" "${_otmp}" 2>/dev/null || chmod 644 "${_otmp}"; else chmod 644 "${_otmp}"; fi
       mv -f "${_otmp}" "${OUT}"; _onew=""; exit 0 ;;
    # rc 3: NENHUM caminho de erro escreve no destino — nem o vazio do dia 1 (a REGRA 84 dá SOFT sem o índice),
    # nem o diretório que o mkdir acima criou (o trap EXIT o desfaz)
    3) rm -f "${_otmp}"
       echo "AVISO kg-trace --out: o produto declarou índice VAZIO (rc 3) — ${OUT} INTACTO (ausente segue ausente; a REGRA 84 julga a divergência; se os traces sumiram de propósito, esvazie à mão)" >&2
       exit 3 ;;
    *) rm -f "${_otmp}"; echo "ERRO kg-trace --out: NAO-GEROU (rc=${_orc}) — ${OUT} INTACTO" >&2; exit "${_orc}" ;;
  esac
fi
KT="${ONION_KG_TRACE:-${REPO_ROOT}/vendor/kg-ssot/tools/kg_trace.py}"
_KT_EXCL=()
if [ -f "${REPO_ROOT}/.kg-ssot/trace-excludes.txt" ]; then
  while IFS= read -r _g || [ -n "${_g}" ]; do
    _g="${_g%%#*}"; _g="${_g#"${_g%%[![:space:]]*}"}"; _g="${_g%"${_g##*[![:space:]]}"}"
    [ -n "${_g}" ] && _KT_EXCL+=(--exclude "${_g}")
  done < "${REPO_ROOT}/.kg-ssot/trace-excludes.txt"
fi
# o próprio produto KG-SSOT (tools/ na raiz, sem vendor de si mesmo) se julga pelo kg_trace.py dele
[ -n "${ONION_KG_TRACE:-}" ] || [ -f "${KT}" ] || [ ! -f "${REPO_ROOT}/tools/kg_trace.py" ] || KT="${REPO_ROOT}/tools/kg_trace.py"
command -v python3 >/dev/null 2>&1 || { echo "ERRO kg-trace: python3 ausente" >&2; exit 2; }
# O perfil `gate` do release.json do kg-ssot não leva kg_trace.py nem kg_query.py (que ele importa): o adotante com
# esse perfil, ou com vendor próprio anterior à 4.25, cai aqui, e o lint diz que NÃO julgou (nunca verde, nunca HARD).
_KTD="$(dirname "${KT}")"
{ [ -f "${KT}" ] && [ -f "${_KTD}/kg_query.py" ] && [ -f "${_KTD}/kg_validate.py" ]; } || {
  echo "ERRO kg-trace: kg_trace.py ausente ou incompleto (${KT}, com kg_query.py e kg_validate.py ao lado) — o vendor kg-ssot >= 4.25, perfil completo, é quem julga o trace" >&2; exit 2; }


if [ "${MODE}" = index ]; then
  # O rc do produto é lido, nunca a prosa: 0|1 trazem o JSON (1 = há missing ou grafo ilegível, que a REGRA 55
  # acusa; o índice segue com o que resolve). Outro rc, JSON ilegível ou sem `resolved_targets` = NAO-GEROU, rc 2.
  _kj="$(mktemp)"; trap 'rm -f "${_kj}"' EXIT
  _krc=0; python3 -I -B "${KT}" check --root "${REPO_ROOT}" --external-root memory/ ${_KT_EXCL[@]+"${_KT_EXCL[@]}"} --format json >"${_kj}" 2>/dev/null || _krc=$?
  case "${_krc}" in
    0|1) : ;;
    3) echo "ERRO kg-trace --emit-index: índice VAZIO (o produto não leu nenhum grafo; 0 nós com trace resolvível)" >&2; exit 3 ;;
    *) echo "ERRO kg-trace --emit-index NAO-GEROU: kg_trace.py rc=${_krc}" >&2; exit 2 ;;
  esac
  _irc=0
  python3 -I -B - "${_kj}" <<'PY' || _irc=$?
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except (OSError, ValueError):
    print("ERRO kg-trace --emit-index NAO-GEROU: JSON do kg_trace.py ilegível", file=sys.stderr); sys.exit(2)
rt = d.get("resolved_targets")
if not isinstance(rt, list):
    print("ERRO kg-trace --emit-index NAO-GEROU: o JSON não traz resolved_targets — o vendor kg-ssot é anterior à "
          "4.25.1 (suba o vendor)", file=sys.stderr); sys.exit(2)
if d.get("unreadable"):
    # Não esconde: o grafo ilegível fica fora do índice, e a REGRA 55 o acusa como ILEGIVEL.
    print(f"AVISO kg-trace --emit-index: {len(d['unreadable'])} grafo(s) ilegível(is) fora do índice", file=sys.stderr)
rows = sorted({f"{r['path']}\t{r['id']}\t{r['file']}" for r in rt}, key=lambda x: x.encode("utf-8"))
if not rows:
    print("ERRO kg-trace --emit-index: índice VAZIO (o produto leu 0 nós com trace resolvível)", file=sys.stderr)
    sys.exit(3)
sys.stdout.write("\n".join(rows) + "\n")
PY
  exit "${_irc}"
fi

if [ "${MODE}" = human ]; then
  _hrc=0; python3 -I -B "${KT}" check --root "${REPO_ROOT}" --external-root memory/ ${_KT_EXCL[@]+"${_KT_EXCL[@]}"} || _hrc=$?
  [ "${_hrc}" -ne 3 ] || { echo "AVISO kg-trace: corpus vazio (o kg_trace.py não leu nenhum grafo, rc 3)" >&2; exit 0; }
  exit "${_hrc}"
fi

# ── TSV para o lint ──────────────────────────────────────────────────────────────────────────────────────────
# O rc do produto é lido, nunca a prosa: 0 resolve · 1 missing/ilegível · outro = entrada quebrada (a regra vira
# HARD de ambiente no lint, nunca verde).
_kj="$(mktemp)"; trap 'rm -f "${_kj}"' EXIT
_krc=0; python3 -I -B "${KT}" check --root "${REPO_ROOT}" --external-root memory/ ${_KT_EXCL[@]+"${_KT_EXCL[@]}"} --format json >"${_kj}" 2>/dev/null || _krc=$?
# rc 3 = corpus vazio (kg-ssot >= 4.27): o JSON pode nem vir, e a guarda de vacuidade abaixo julga do mesmo jeito
# (corpus com `trace:` e nada lido segue VACUIDADE). Sem achado, sai 0.
case "${_krc}" in
  0|1) : ;;
  3) python3 -I -B -c 'import json,sys; json.load(open(sys.argv[1]))' "${_kj}" 2>/dev/null \
       || printf '{"judged": 0, "skipped": {}}\n' >"${_kj}"
     _krc=0 ;;
  *) printf '%s\t%s\t%s\t%s\t%s\n' '-' 'PRODUTO' '-' "(kg_trace.py rc=${_krc})" 'ENTRADA-QUEBRADA'; exit 1 ;;
esac

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
