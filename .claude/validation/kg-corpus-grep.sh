#!/usr/bin/env bash
# kg-corpus-grep.sh — "o que os grafos JÁ sabem sobre este tema" (passo 0 de toda pesquisa Onion).
#
# Uso: bash .claude/validation/kg-corpus-grep.sh <termo> [termo...] [--json] [--all-status]
#   Casa cada termo (case-insensitive) no id OU no label de todo nó de todo .kg.yaml versionado
#   (git ls-files '*.kg.yaml', fixtures excluídas — o glob hardcoded era 36% cego). Imprime, por nó:
#   grafo · id · status · verified_at · source_tier · label (recortado). Default: esconde refuted/superseded
#   (use --all-status para ver a Aufhebung). Fail-loud: nenhum grafo no corpus = exit 2, nunca "0 achados".
#
# Por que existe (medido 2026-09-02, meta-research-lens): 27 grafos de pesquisa guardados e NENHUMA
# pesquisa os lia antes de buscar fora — o único reuso era por eixo do radar. Custo: 0 tokens.
set -uo pipefail

# Predicado de FIXTURE — caminho ABSOLUTO resolvido ANTES de qualquer `cd`, e ausência é FAIL-CLOSED.
# (A 1ª ligação usava `$(dirname "${BASH_SOURCE[0]}")` no ponto de uso e morria depois de um `cd`:
#  o erro era engolido por `|| true` e o script dizia "nenhum grafo" — verde por vacuidade. 2026-09-05.)
_KFP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kg-fixture-paths.sh"
[ -f "${_KFP}" ] || { echo "ERRO: predicado de fixture ausente (${_KFP}) — sem ele a varredura de grafos ficaria VAZIA e verde por vacuidade." >&2; exit 2; }
ROOT="${ONION_KG_CORPUS_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
JSON=0; ALL=0; TERMS=()
for a in "$@"; do case "$a" in --json) JSON=1;; --all-status) ALL=1;; -h|--help) sed -n '2,10p' "$0"; exit 0;; *) TERMS+=("$a");; esac; done
[ "${#TERMS[@]}" -gt 0 ] || { echo "uso: kg-corpus-grep.sh <termo> [termo...] [--json] [--all-status]" >&2; exit 2; }
if [ -n "${ONION_KG_CORPUS_FILES:-}" ]; then files="${ONION_KG_CORPUS_FILES}"
# ⚠️ A isenção de FIXTURE vem do predicado ÚNICO kg-fixture-paths.sh (2026-09-05): antes cada
#    consumidor repetia `grep -v '/fixtures/'` e o `__fixtures__/` do Vitest ESCAPAVA — 5 grafos
#    deliberadamente inválidos de um adotante viraram 5 HARD no dia 1 da adoção dele.
else files="$(cd "${ROOT}" && git ls-files '*.kg.yaml' 2>/dev/null | bash "${_KFP}" --filter | sed "s|^|${ROOT}/|")"; fi
[ -n "${files}" ] || { echo "kg-corpus-grep: FAIL-LOUD — nenhum .kg.yaml no corpus (${ROOT}); não devolvo '0 achados' por corpus vazio" >&2; exit 2; }
LIST="$(mktemp)"; trap 'rm -f "${LIST}"' EXIT; printf '%s\n' "${files}" > "${LIST}"
# a lista vai por ARQUIVO, não por pipe: o heredoc do python abaixo É o stdin (bug medido no 1º dogfood: "0 grafos")
python3 - "${JSON}" "${ALL}" "${LIST}" "${TERMS[@]}" <<'PY'
import sys,re,json,os
json_out=sys.argv[1]=="1"; all_status=sys.argv[2]=="1"; terms=[t.lower() for t in sys.argv[4:]]
files=[l.strip() for l in open(sys.argv[3],encoding="utf-8") if l.strip()]
hits=[]; graphs=0
for f in files:
    try: txt=open(f,encoding="utf-8",errors="replace").read()
    except Exception: continue
    graphs+=1
    g=os.path.basename(f)[:-8]
    node=None
    for line in txt.split("\n"):
        m=re.match(r'^\s*-\s+id:\s*(\S+)',line)
        if m:
            if node: hits.append(node) if node.get("_hit") else None
            node={"grafo":g,"id":m.group(1),"status":"","verified_at":"","source_tier":"","label":"","_hit":False}
            if any(t in node["id"].lower() for t in terms): node["_hit"]=True
            continue
        if node is None: continue
        km=re.match(r'^\s*(status|verified_at|source_tier|label):\s*(.*)$',line)
        if km:
            k,v=km.group(1),km.group(2).strip().strip("'\"")
            node[k]=v
            if k=="label" and any(t in v.lower() for t in terms): node["_hit"]=True
    if node and node.get("_hit"): hits.append(node)
if not all_status: hits=[h for h in hits if h["status"] not in ("refuted","superseded")]
for h in hits: h.pop("_hit",None)
if json_out: print(json.dumps({"graphs":graphs,"terms":terms,"hits":hits},ensure_ascii=False,indent=1)); sys.exit(0)
print(f"# corpus: {graphs} grafos · termos: {', '.join(terms)} · {len(hits)} nó(s)")
for h in hits:
    print(f"{h['grafo']}\t{h['id']}\t{h['status'] or '-'}\t{h['verified_at'] or '-'}\ttier={h['source_tier'] or '-'}\t{h['label'][:160]}")
PY
