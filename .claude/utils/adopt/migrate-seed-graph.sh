#!/usr/bin/env bash
# migrate-seed-graph.sh — leva a SEMENTE do KG de adotante antigo para o layout de documento único.
#
# ── POR QUE EXISTE (sinal de campo, 2026-10-13, um adotante com o contrato kg-ssot 4.4.0) ──────────
# Até dbcf21b1 (2026-10-06) o seed-adoption-graph.sh escrevia `docs/onion/graph/onion-adoption.kg.yaml`
# como DOIS documentos YAML: `---`, um cabeçalho (graph/title/layer/created/updated/owner/purpose/
# como_usar), `---` e o grafo. O semeador foi curado, mas a cura só vale para quem adota DEPOIS: o
# `--update` traz os scripts novos e deixa o grafo velho onde está, e o contrato o reprova com
# `parse.not-single-document`. No adotante eram 3 de 4 grafos; um era a semente, convertida à mão.
# Forma antiga MEDIDA no git log do semeador: idêntica nas 5 versões de 370b992c a dbcf21b1^.
#
# O QUE FAZ: converte SÓ a semente do Onion, reconhecida pelo marcador do semeador (o caminho fixo,
# `---` + `graph: onion-adoption` nas duas primeiras linhas, cabeçalho só com as 8 chaves do
# semeador, exatamente um separador e `meta.id: onion-adoption-*`). O cabeçalho vai para `meta`
# (graph/title/layer/created/updated/owner → x_*, purpose → purpose, como_usar → note, a mesma
# forma que o semeador atual escreve e que o adotante fez à mão de acordo com o dono do contrato); as
# datas sem aspas ganham aspas; e os nós INTACTOS do semeador ganham a provenance que o semeador
# atual declara para eles (o contrato 4.4 a exige; o 2º documento escondia esse MUST). Antes de
# gravar, prova: (1) um único documento; (2) o conteúdo parseado é o MESMO (o grafo inteiro e cada
# campo do cabeçalho, com data comparada como texto; a única adição admitida é aquela provenance);
# (3) o radar vê a mesma população de nós antes e depois, e não reprova a integridade;
# (4) o contrato não acusa nenhum MUST. Qualquer prova falhando → AVISA e não toca.
#
# O QUE NÃO FAZ: tocar grafo do adotante. Grafo com dois documentos que não é a semente é listado
# com aviso e fica intacto: só o dono sabe se o 1º documento é cabeçalho ou dado. Forma de semente
# não reconhecida → aviso, intacto. Idempotente: já convertido = no-op.
#
# Uso:  bash migrate-seed-graph.sh <DEST> [--source <SOURCE_ROOT>] [--dry-run]
#   --source: de onde vêm o radar e o vendor do contrato quando o DEST não os tem (default: o core
#             que contém este script). O vendor do DEST tem precedência: é o contrato que o julga.
# Códigos: 0 = migrado ou nada a migrar · 3 = há aviso (grafo intocado de propósito) ·
#          2 = não pôde medir (sem PyYAML, sem radar, sem vendor do contrato) — nunca passa por verde.
set -uo pipefail

DEST=""; SRC=""; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --source) SRC="${2:-}"; shift 2 || { echo "migrate-seed-graph: --source sem valor" >&2; exit 2; } ;;
    --dry-run) DRY=1; shift ;;
    -*) echo "migrate-seed-graph: opção desconhecida '$1'" >&2; exit 2 ;;
    *) [ -z "${DEST}" ] && DEST="$1" || { echo "migrate-seed-graph: alvo já informado" >&2; exit 2; }; shift ;;
  esac
done
[ -n "${DEST}" ] && [ -d "${DEST}" ] || { echo "uso: migrate-seed-graph.sh <DEST> [--source <SOURCE_ROOT>] [--dry-run]" >&2; exit 2; }
DEST="$(cd "${DEST}" && pwd)"
[ -n "${SRC}" ] || SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

_pick() {   # o do DEST primeiro (é o que roda lá), depois o da fonte
  if [ -e "${DEST}/$1" ]; then printf '%s\n' "${DEST}/$1"; elif [ -e "${SRC}/$1" ]; then printf '%s\n' "${SRC}/$1"; fi
}
RADAR="$(_pick .claude/validation/kg-radar.sh)"
_KFP="$(_pick .claude/validation/kg-fixture-paths.sh)"
VENDOR="${KG_CONTRACT_VENDOR:-$(_pick vendor/kg-ssot)}"
# PRÉ-FILTRO TEXTUAL antes de exigir as dependências: sem nenhuma linha `---` nos grafos não há o que migrar,
# e cobrar PyYAML/vendor aqui faria toda ADOÇÃO nova (que passa por este passo) avisar NAO MEDIDO sobre nada.
# Só a linha `---` exata vira candidato; o veredito de "quantos documentos" é do parser, abaixo.
if git -C "${DEST}" rev-parse --git-dir >/dev/null 2>&1; then
  LIST="$(git -C "${DEST}" ls-files '*.kg.yaml' | bash "${_KFP:-/dev/null}" --filter 2>/dev/null || true)"
  _cand=""
  while IFS= read -r _g; do
    [ -n "${_g}" ] && [ -f "${DEST}/${_g}" ] && LC_ALL=C grep -qE '^---[[:space:]]*$' "${DEST}/${_g}" && { _cand=1; break; }
  done <<< "${LIST}"
  [ -n "${_KFP}" ] && [ -z "${_cand}" ] && { echo "  ⊘ migrate-seed-graph: nada a migrar (nenhum grafo com separador de documento)"; exit 0; }
fi
[ -n "${RADAR}" ] || { echo "migrate-seed-graph: kg-radar.sh ausente no alvo e na fonte — NAO MEDIDO" >&2; exit 2; }
[ -n "${_KFP}" ] || { echo "migrate-seed-graph: kg-fixture-paths.sh ausente — NAO MEDIDO" >&2; exit 2; }
[ -n "${VENDOR}" ] && [ -f "${VENDOR}/tools/kg_gate.py" ] || { echo "migrate-seed-graph: vendor do contrato ausente (vendor/kg-ssot no alvo e na fonte) — NAO MEDIDO" >&2; exit 2; }
python3 -c 'import yaml' 2>/dev/null || { echo "migrate-seed-graph: PyYAML ausente — NAO MEDIDO" >&2; exit 2; }

# A população: rastreados (ou, sem git, os de docs/), sem fixture — o predicado ÚNICO da casa.
if git -C "${DEST}" rev-parse --git-dir >/dev/null 2>&1; then
  LIST="$(git -C "${DEST}" ls-files '*.kg.yaml' | bash "${_KFP}" --filter)"
else
  LIST="$(cd "${DEST}" && find docs -name '*.kg.yaml' 2>/dev/null | bash "${_KFP}" --filter)"
fi

# A lista vai por VARIÁVEL de ambiente: o heredoc abaixo É o stdin do python (o script), e um pipe
# para ele seria silenciosamente substituído — medido na 1ª redação: "nada a migrar" sobre a semente velha.
MIGRATE_LIST="${LIST}" python3 -I -B - "${DEST}" "${RADAR}" "${VENDOR}/tools" "${DRY}" <<'PY'
import datetime, json, os, re, subprocess, sys, tempfile
import yaml

dest, radar, tools, dry = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
sys.path.insert(0, tools)
try:
    import kg_gate
except Exception as e:
    print(f"migrate-seed-graph: não consegui carregar o leitor do contrato ({e}) — NAO MEDIDO", file=sys.stderr)
    sys.exit(2)

SEED = "docs/onion/graph/onion-adoption.kg.yaml"
HEADER_KEYS = ["graph", "title", "layer", "created", "updated", "owner", "purpose", "como_usar"]
RENAME = {"graph": "x_graph", "title": "x_title", "layer": "x_layer", "created": "x_created",
          "updated": "x_updated", "owner": "x_owner", "purpose": "purpose", "como_usar": "note"}
SEP = re.compile(r"^---[ \t]*$")
DATE_LINE = re.compile(r"^(\s*(?:- )?[A-Za-z_]+:[ \t]+)(\d{4}-\d{2}-\d{2})[ \t]*$")
warns, migrated = [], []

# PROVENANCE que o semeador ATUAL escreve para os MESMOS nós (seed-adoption-graph.sh). O contrato 4.4 a
# exige em todo nó confirmed ou PROD (MUST form.required.node.provenance), e a semente antiga não a tinha:
# o 2º documento escondia esse MUST atrás do parse.not-single-document (o adotante registrou a troca com
# --accept-regression). Não é invenção: é a proveniência que o próprio semeador declara para o fato que
# ele mesmo semeou, chaveada pelo id do nó E pelo verified_against que o semeador escreveu (no gate, ele diz
# qual dos três desfechos a adoção mediu). A chave é EXATA de propósito: nó que o adotante editou (a pergunta
# respondida, com outro verified_against) não é mais o fato do semeador, e carimbar nele a fonte da semente
# seria afirmar origem falsa — medido no adotante, cuja Q_WHAT_IS_THIS_REPO_DOMAIN já estava respondida. Nó fora
# da tabela sem provenance → o contrato reprova e a migração RECUSA, nomeando os nós.
PROV = {
    ("THIS_REPO", "basename-do-alvo-e-stamp-claude-onion-version"): (".claude/.onion-version deste repo", "campo role e o nome do diretório", "leitura: na adoção", "repo"),
    ("ONION_INSTALLED", "stamp-claude-onion-version-lido-na-adocao"): (".claude/.onion-version deste repo", "campos source_commit, mode, role e integration_branch", "leitura: na adoção", "repo"),
    ("DETERMINISTIC_GATE", "verify-adopter-gate-executado-na-adocao"):
        ("install-onion-githook.sh rodado na adoção (linha GATE VIVO)", "hook nativo via core.hooksPath deste repo", "medição: execução de commit-sonda", "host"),
    ("DETERMINISTIC_GATE", "nao-verificado-gate-declarado-e-nao-provado"):
        ("install-onion-githook.sh rodado na adoção (prova adiada)", "hook nativo via core.hooksPath deste repo", "derivado: instalação sem execução de prova", "host"),
    ("DETERMINISTIC_GATE", "nao-informado-ao-semeador"):
        ("semeador da adoção, sem informação do instalador do gate", "hook nativo via core.hooksPath deste repo", "derivado: nenhuma medição", "repo"),
    ("Q_WHAT_IS_THIS_REPO_DOMAIN", "semente-da-adocao-dominio-ainda-nao-mapeado"): ("semeador da adoção (seed-adoption-graph.sh)", "ausência de grafo de domínio no repo na hora da adoção", "medição: verificação de ausência por git ls-files", "repo"),
    ("D_ADOPT_ONION", "superficie-do-framework-presente-e-stamp-carimbado"): ("commit da adoção neste repo e o .claude/.onion-version", "superfície do framework presente e stamp carimbado", "leitura: na adoção", "repo"),
}

def prov_for(node):
    nid, va = node.get("id"), node.get("verified_against")
    return PROV.get((nid, va))

def ndocs(text):
    try:
        return sum(1 for _ in yaml.compose_all(text))
    except yaml.YAMLError:
        return -1

def norm(v):
    """data parseada vira texto ISO: a única diferença que a migração introduz de propósito."""
    if isinstance(v, (datetime.date, datetime.datetime)):
        return v.isoformat()
    if isinstance(v, dict):
        return {k: norm(x) for k, x in v.items()}
    if isinstance(v, list):
        return [norm(x) for x in v]
    return v

def radar_ids(path):
    r = subprocess.run(["bash", radar, path, "--status-tsv"], capture_output=True, text=True)
    if r.returncode != 0:
        return None
    return sorted(l.split("\t")[0] for l in r.stdout.splitlines() if l.strip())

def radar_integrity_ok(path):
    return subprocess.run(["bash", radar, path, "--integrity"], capture_output=True, text=True).returncode == 0

def convert(text):
    """devolve (novo_texto, motivo_da_recusa). Recusa = forma que o semeador antigo não escrevia."""
    lines = text.split("\n")
    seps = [i for i, l in enumerate(lines) if SEP.match(l)]
    if len(lines) < 3 or seps[:1] != [0] or lines[1] != "graph: onion-adoption":
        return None, "não começa com `---` + `graph: onion-adoption` (marcador do semeador antigo)"
    if len(seps) != 2:
        return None, f"{len(seps)} separadores `---` (o semeador antigo escrevia exatamente 2)"
    k = seps[1]
    header, body = lines[1:k], lines[k + 1:]
    # o cabeçalho: só chaves de topo do semeador, cada uma com as suas linhas de continuação
    blocks, cur = {}, None
    for l in header:
        m = re.match(r"^([a-z_]+):(.*)$", l)
        if m:
            if m.group(1) not in HEADER_KEYS or m.group(1) in blocks:
                return None, f"chave de cabeçalho fora do semeador ou repetida: `{m.group(1)}`"
            cur = m.group(1); blocks[cur] = [m.group(2)]
        elif l.startswith("  ") or not l.strip():
            if cur is None:
                return None, "continuação antes da 1ª chave do cabeçalho"
            blocks[cur].append(l)
        else:
            return None, f"linha de cabeçalho não reconhecida: {l[:60]!r}"
    try:
        meta_i = body.index("meta:")
    except ValueError:
        return None, "sem `meta:` no grafo"
    if not any(re.match(r"^  id:[ \t]+onion-adoption-", l) for l in body[meta_i + 1:]):
        return None, "meta.id não é `onion-adoption-*` (marcador do semeador)"
    meta_keys = set()
    for l in body[meta_i + 1:]:
        if l and not l.startswith(" "):
            break
        m = re.match(r"^  ([A-Za-z_]+):", l)
        if m:
            meta_keys.add(m.group(1))
    clash = sorted(meta_keys & {RENAME[h] for h in blocks})
    if clash:
        return None, f"meta já tem {clash} — mover o cabeçalho sobrescreveria"
    moved = []
    for h in HEADER_KEYS:
        if h not in blocks:
            continue
        first, rest = blocks[h][0], blocks[h][1:]
        first = re.sub(r"^[ \t]+(\d{4}-\d{2}-\d{2})[ \t]*$", r' "\1"', first)
        moved.append(f"  {RENAME[h]}:{first}")
        moved.extend(("  " + l) if l.strip() else l for l in rest)
    while moved and not moved[-1].strip():
        moved.pop()
    new_body = []
    for i, l in enumerate(body):
        new_body.append(DATE_LINE.sub(r'\1"\2"', l))
        if i == meta_i:
            new_body.extend(moved)
    new_body = add_provenance(new_body)
    out = ["# Adoção do Onion neste repositório — a semente do KG, migrada para DOCUMENTO ÚNICO pelo",
           "# /meta:adopt --update (migrate-seed-graph.sh): o cabeçalho do layout antigo de dois documentos",
           "# foi para meta (graph/title/layer/created/updated/owner → x_*, como_usar → note), as datas ganharam",
           "# aspas e os nós do semeador ganharam a provenance que o semeador atual declara; nenhum dado existente mudou."]
    return "\n".join(out + new_body), None

def add_provenance(body):
    """insere, no fim de cada bloco de nó da tabela PROV que não a tem, a provenance do semeador atual."""
    out, i, in_nodes = [], 0, False
    while i < len(body):
        l = body[i]
        if re.match(r"^nodes:[ \t]*$", l):
            in_nodes = True; out.append(l); i += 1; continue
        if in_nodes and l and not l.startswith((" ", "#")):
            in_nodes = False
        m = re.match(r"^  - id:[ \t]*(\S+)[ \t]*$", l) if in_nodes else None
        if not m:
            out.append(l); i += 1; continue
        j = i + 1
        while j < len(body) and not re.match(r"^  - id:", body[j]) and not (body[j] and not body[j].startswith((" ", "#"))):
            j += 1
        block = body[i:j]
        k = len(block)
        while k > 1 and not block[k - 1].strip():
            k -= 1
        va = next((re.sub(r"^    verified_against:[ \t]*", "", b).strip().strip('"') for b in block if b.startswith("    verified_against:")), None)
        pv = prov_for({"id": m.group(1), "verified_against": va})
        if pv and not any(b.startswith("    provenance:") for b in block):
            q = lambda v: json.dumps(v, ensure_ascii=False)
            block = block[:k] + ["    provenance:", f"      source: {q(pv[0])}", f"      locator: {q(pv[1])}",
                                 f"      method: {q(pv[2])}", f"      locality: {q(pv[3])}"] + block[k:]
        out.extend(block); i = j
    return out

def prove(old, new, path_rel):
    """as quatro provas; devolve (ok, motivo, should_codes)."""
    if ndocs(new) != 1:
        return False, "o resultado não é um documento único", []
    d1, d2 = [norm(d) for d in yaml.safe_load_all(old)]
    n = norm(yaml.safe_load(new))
    expect_meta = dict(d2.get("meta") or {})
    for h in HEADER_KEYS:
        if h in d1:
            expect_meta[RENAME[h]] = d1[h]
    if n.get("meta") != expect_meta:
        return False, "o meta convertido não é o meta antigo + o cabeçalho", []
    expect = {k: v for k, v in d2.items() if k != "meta"}
    for node in expect.get("nodes") or []:        # a única adição de conteúdo: a provenance da tabela
        pv = prov_for(node) if isinstance(node, dict) else None
        if pv and "provenance" not in node:
            node["provenance"] = dict(zip(("source", "locator", "method", "locality"), pv))
    if {k: v for k, v in n.items() if k != "meta"} != expect:
        return False, "nodes/edges mudaram na conversão além da provenance do semeador", []
    with tempfile.TemporaryDirectory() as td:
        po, pn = os.path.join(td, "old", os.path.basename(path_rel)), os.path.join(td, "new", os.path.basename(path_rel))
        for p, t in ((po, old), (pn, new)):
            os.makedirs(os.path.dirname(p)); open(p, "w", encoding="utf-8").write(t)
        ro, rn = radar_ids(po), radar_ids(pn)
        if ro is None or rn is None:
            return False, "o radar não respondeu (rc≠0) — população NAO MEDIDA", []
        if ro != rn:
            return False, f"o radar vê populações diferentes (antes {len(ro)}, depois {len(rn)})", []
        if not radar_integrity_ok(pn):
            return False, "o radar reprova a integridade do convertido", []
    m = kg_gate.measure_texts([(path_rel, new)])[path_rel]
    if m["must"]:
        sem = [x.get("id") for x in n.get("nodes") or [] if isinstance(x, dict) and "provenance" not in x
               and (x.get("status") == "confirmed" or x.get("plane") == "PROD")]
        extra = f" — nós do ADOTANTE sem provenance: {', '.join(map(str, sem))}" if sem else ""
        return False, f"o contrato acusa MUST: {', '.join(m['must'])}{extra}", []
    return True, "", m["should"]

for rel in (l.strip() for l in os.environ.get("MIGRATE_LIST", "").splitlines()):
    if not rel:
        continue
    p = os.path.join(dest, rel)
    if not os.path.isfile(p):
        continue
    text = open(p, encoding="utf-8").read()
    nd = ndocs(text)
    if nd <= 1:
        continue                     # documento único (ou YAML quebrado: é da REGRA 78, não daqui)
    if rel != SEED:
        warns.append(f"{rel}: {nd} documentos YAML, mas NÃO é a semente do Onion — intocado (o dono decide; o contrato o reprova com parse.not-single-document)")
        continue
    new, why = convert(text)
    if new is None:
        warns.append(f"{rel}: dois documentos, mas a forma não é a do semeador antigo ({why}) — intocado; converta à mão")
        continue
    ok, why, should = prove(text, new, rel)
    if not ok:
        warns.append(f"{rel}: conversão RECUSADA ({why}) — intocado")
        continue
    if not dry:
        tmp = p + ".migrating"
        open(tmp, "w", encoding="utf-8").write(new)
        os.replace(tmp, p)
    migrated.append(rel)
    print(f"  ✓ {'(dry-run) ' if dry else ''}migrado para documento único: {rel}"
          + (f" — dívida que o 2º documento escondia (SHOULD, não MUST): {', '.join(should)}" if should else ""))

for w in warns:
    print(f"  ⚠ migrate-seed-graph: {w}")
if not migrated and not warns:
    print("  ⊘ migrate-seed-graph: nada a migrar (nenhum grafo em dois documentos)")
sys.exit(3 if warns else 0)
PY
