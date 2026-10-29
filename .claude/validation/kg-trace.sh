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
# Outras raízes externas vêm do ALVO (ver «Ext.» abaixo): o material que mora numa pasta ignorada pelo git.
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
#        índice `caminho·id·grafo`, ordenado (LC_ALL=C sort -u). No TSV, desde a kg-ssot 4.37.0, a falha do
#        provenance.scheme/sha256 sai `SCHEME-FALHA:<código>` e o unpinned/malformed do skipped numa linha
#        `SCHEME-AVISO` (que não conta para o rc); desde a 4.38.0, o provenance.node_sha256 que não confere sai
#        `SCHEME-FALHA:integrity.trace-node-sha256-mismatch` e o not_canonical entra no aviso
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
# Ext. : <repo_root>/.kg-ssot/trace-external-roots.txt (do ALVO, opcional) — um prefixo relativo por linha, `#`
#        comenta, o mesmo parser do trace-excludes.txt; cada um vira mais um `--external-root`, somado ao `memory/`
#        fixo. Existe porque o material de cliente mora numa pasta ignorada pelo git (doutrina client-material), e o
#        `/product:extract-meeting` grava `trace: <pasta-ignorada>/transcricao.md#Lx`: sem a declaração, cada nó do
#        grafo de reunião vira `integrity.trace-target-missing` (20 HARD da REGRA 55 medidos num adotante em
#        2026-10-29, pela REGRA 55 (O `trace:` de um nó APONTA para alvo que EXISTE)). O prefixo declarado sai do julgamento como external_root (contado no skipped, não resolvido).
#        O prefixo é casado LITERALMENTE com o texto do `trace:` (startswith do produto, antes de tirar `./`): escreva-o
#        com barra final (`_material/`, ao contrário da regra do .gitignore), senão `_material` isenta `_material2/…`, e
#        `./_material/x` não casa. A isenção vale também onde o material existe (o checkout principal): lá quem
#        julga o trace é o meeting-graph-check.sh. Arquivo ausente = só `memory/`. Prefixo absoluto é recusado pelo produto (entrada quebrada, rc 2).
#        O arquivo é do adotante; o core não escreve nele.
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
  # o caminho é normalizado ANTES de medir a cadeia (passada adversarial: com `novo/../velho/x` o rmdir subia por
  # `novo/..` e apagava `velho/`, vazio e pré-existente). Teto declarado: um diretório que OUTRO processo crie
  # entre a medida e o mkdir pode sair no desfazer, se ainda estiver vazio (o rmdir nunca apaga conteúdo).
  _odir="$(realpath -m -- "${_odir}" 2>/dev/null)" || { echo "ERRO kg-trace --out: não consegui normalizar ${OUT}" >&2; exit 2; }
  OUT="${_odir}/${OUT##*/}"   # o destino segue o caminho normalizado: `novo/` do `novo/../` não é criado, e o mv não pode depender dele
  # o destino é o ARQUIVO do índice, nunca um diretório (3ª passada adversarial do adotante sge, 2026-10-27): com
  # `--out dir/` o nome vazio fazia o mv mirar o próprio temporário (rc 1, mensagem crua do mv), e com `--out <dir
  # existente>` o mv punha o índice DENTRO dele e saía rc 0, largando um `.kg-read-index.XXXXXX` oculto. Recusa aqui,
  # antes do mkdir e do mktemp: nada é criado.
  case "${OUT}" in */) echo "ERRO kg-trace --out: o destino termina em barra — --out recebe o caminho do ARQUIVO do índice (ex.: docs/onion/kg-read-index.tsv), não um diretório" >&2; exit 2 ;; esac
  [ ! -d "${OUT}" ] || { echo "ERRO kg-trace --out: o destino é um diretório existente (${OUT}) — --out recebe o caminho do ARQUIVO do índice (ex.: docs/onion/kg-read-index.tsv)" >&2; exit 2; }
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
# as raízes externas: o `memory/` fixo e, opcional, as do alvo (mesmo parser do trace-excludes.txt)
_KT_EXT=(--external-root memory/)
if [ -f "${REPO_ROOT}/.kg-ssot/trace-external-roots.txt" ]; then
  while IFS= read -r _g || [ -n "${_g}" ]; do
    _g="${_g%%#*}"; _g="${_g#"${_g%%[![:space:]]*}"}"; _g="${_g%"${_g##*[![:space:]]}"}"
    [ -n "${_g}" ] && _KT_EXT+=(--external-root "${_g}")
  done < "${REPO_ROOT}/.kg-ssot/trace-external-roots.txt"
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
  _krc=0; python3 -I -B "${KT}" check --root "${REPO_ROOT}" "${_KT_EXT[@]}" ${_KT_EXCL[@]+"${_KT_EXCL[@]}"} --format json >"${_kj}" 2>/dev/null || _krc=$?
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
  _hrc=0; python3 -I -B "${KT}" check --root "${REPO_ROOT}" "${_KT_EXT[@]}" ${_KT_EXCL[@]+"${_KT_EXCL[@]}"} || _hrc=$?
  [ "${_hrc}" -ne 3 ] || { echo "AVISO kg-trace: corpus vazio (o kg_trace.py não leu nenhum grafo, rc 3)" >&2; exit 0; }
  exit "${_hrc}"
fi

# ── TSV para o lint ──────────────────────────────────────────────────────────────────────────────────────────
# O rc do produto é lido, nunca a prosa: 0 resolve · 1 missing/ilegível · outro = entrada quebrada (a regra vira
# HARD de ambiente no lint, nunca verde).
_kj="$(mktemp)"; trap 'rm -f "${_kj}"' EXIT
_krc=0; python3 -I -B "${KT}" check --root "${REPO_ROOT}" "${_KT_EXT[@]}" ${_KT_EXCL[@]+"${_KT_EXCL[@]}"} --format json >"${_kj}" 2>/dev/null || _krc=$?
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
# LOCATOR (kg-ssot >= 4.35.0, `locators`, aditivo): o provenance.locator em JSON Pointer (#/a/b) seguido dentro do
# .json que a fonte do nó nomeia. É a parte GENÉRICA que a REGRA 111 fazia por conta própria (o token que some de
# dentro do JSON com o arquivo presente) e passou ao produto; o design-context-check.py ficou só com o que é de
# design (o destino ser token DTCG, com $value, e a regra do brief). O alvo sai como `<arquivo><ponteiro>`.
loc = d.get("locators") or {}
for m in loc.get("missing", []):
    print(f"{m['file']}\t{m['id']}\t-\t{m['target']}{m['locator']}\tLOCATOR-MISSING")
for u in loc.get("unreadable", []):
    print(f"{u['file']}\t{u['id']}\t-\t{u['target']}{u['locator']}\tLOCATOR-ILEGIVEL")
# SCHEMES (kg-ssot >= 4.37.0, contrato v4.17, `schemes`, aditivo): a fonte lida pelo provenance.scheme e conferida pelo
# provenance.sha256. Cada falha sai com o nó e o código do produto (integrity.trace-sha256-mismatch,
# -locator-out-of-range, -quote-missing), nunca como ENTRADA-QUEBRADA. O skipped que é DEFEITO de quem declara sai
# numa linha de aviso: malformed (scheme, locator ou hash fora da forma), missing_source (a fonte que o nó nomeia não
# está no repo) e unpinned (o ref da URL anda). O resto (form_only, absolute, not_json...) é o não-julgado por desenho.
# TETO DECLARADO (passada adversarial da adoção da 4.37.0): este TSV não passa --with ao produto, então a fonte por URL
# de outro repo cai em `absolute` e NÃO é julgada aqui; o unpinned só nasce com --with. O sha256 ou o node_sha256 de um nó que cita outro
# repo se confere por `kg_trace.py check --with <prefixo>=<clone>` (o 1º do core: Q_MA_FREE_ORG_READ_ENFORCED).
# NODE_SHA256 (kg-ssot >= 4.38.0, contrato v4.18): o provenance.node_sha256 é o SHA-256 do JCS (RFC 8785) do nó citado,
# com scheme kg-node, e só a mudança DESSE nó o derruba (o vizinho no mesmo arquivo, não). A falha chega pelo mesmo
# `schemes.failures`, com o código integrity.trace-node-sha256-mismatch, e sai nomeando o nó como as outras. O skipped
# ganha o not_canonical (o nó citado se repete ou não tem forma JCS, como um inteiro fora de ±(2^53−1)): sem hash a
# conferir, o produto conta o nó como ok pelo locator e sai 0, e calar seria declarar a ponte conferida. Sai no aviso.
# O not_found e o no_with da 4.38.0 são motivos do `kg_query --revisit`, não do `kg_trace check`: não chegam a este JSON
# (medido na adoção: as chaves do schemes.skipped da 4.38.0 são as da 4.37.0 mais not_canonical).
def _cell(s):
    return " ".join(str(s or "").split())
sch = d.get("schemes") or {}
for m in sch.get("failures", []):  # a tradução das falhas de esquema (o mutante (s-MUT) a esvazia)
    print(f"{m['file']}\t{m['id']}\t-\t{_cell(m.get('target'))} [{_cell(m.get('scheme')) or 'sha256'}] "
          f"{_cell(m.get('locator'))}".rstrip() + f"\tSCHEME-FALHA:{m['code']}")
ss = sch.get("skipped") or {}
warn = [f"{ss[k]} {k}" for k in ("malformed", "missing_source", "unpinned", "not_canonical") if ss.get(k)]  # o aviso do skipped
if warn:
    print(f"-\tSCHEMES\t-\t({', '.join(warn)})\tSCHEME-AVISO")
PY
)" || { printf '%s\t%s\t%s\t%s\t%s\n' '-' 'PRODUTO' '-' '(JSON do kg_trace.py ilegível)' 'ENTRADA-QUEBRADA'; exit 1; }
# rc 1 do produto SEM nenhuma linha traduzida: o rc e o JSON discordam (um código novo do produto que esta tradução
# não conhece). Com a 4.35.0 e antes desta tradução, o locator que não resolvia dava rc 1 com TSV vazio, e o lint
# calava (medido na adoção, 2026-10-27): nunca verde calado.
# A linha SCHEME-AVISO não é achado (o produto sai 0 com ela): não conta para o rc, nem para esta guarda.
_findings="$(grep -v $'\tSCHEME-AVISO$' <<< "${_tsv}" || true)"
if [ -z "${_findings}" ] && [ "${_krc}" -eq 1 ]; then
  [ -z "${_tsv}" ] || printf '%s\n' "${_tsv}"
  printf '%s\t%s\t%s\t%s\t%s\n' '-' 'PRODUTO' '-' '(kg_trace.py rc=1 sem achado que esta tradução conheça)' 'ENTRADA-QUEBRADA'; exit 1
fi
[ -n "${_tsv}" ] || exit "${_krc}"
printf '%s\n' "${_tsv}"
[ -z "${_findings}" ] || exit 1
exit "${_krc}"
