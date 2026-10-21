#!/usr/bin/env bash
# =============================================================================
# remeasure-contract.sh — o CONTRATO KG-SSOT medido no corpus do ALVO, dentro do `--update`, antes do relatório
#
# POR QUE EXISTE (sinal de campo de um hub, 2026-10-19, pin 59ebe7fe1288): o `vendor/kg-ssot` v4.9.1 chegou ao hub
# pela primeira vez e 1.024 dos 1.268 nós dos grafos dele reprovavam no MUST `form.required.node.provenance`. NADA
# avisou: o lint do alvo deu 0 HARD (o gate do corpus é o `ops/kg-gate-ci.sh` (core-only), que não viaja), o
# relatório do `--update` não mediu o contrato e o `offer-onion-ci.sh` disse "lint VERDE". É a classe do
# `remeasure-hard.sh` um andar ao lado: o merge da vendor muda o CONTRATO que julga os grafos do alvo, e o número
# do relatório tem de ser medido, nunca suposto. Decisão do maestro de 2026-10-20 (D_U1_CAMADA_SDAAL_NO_UPDATE,
# fase 1): o `--update` mede o contrato no alvo e relata; a migração conduzida é a fase seguinte.
#
# MEDIR NÃO É GATE: este script nunca bloqueia o update. Ele diz o número; quem lê decide.
#
# O QUE MEDE: o contrato que VIAJOU para o alvo (o `vendor/kg-ssot/tools/kg_gate.py` DO ALVO, nunca o da fonte),
# sobre os .kg.yaml rastreados pelo git, fora os excluídos padrão do kit (`*/fixtures/*`, `docs/materials/*`) e as
# propostas arquivadas do kg-inbox (`_rejected/`, `_sealed/`). Esta última é a POLÍTICA DE CORPUS DO CORE (história,
# não grafo vivo), não necessariamente a do gate do alvo: um `kg_gate.py` rodado no alvo sem `--exclude` veria também
# os arquivados. A saída imprime os excluídos, para quem compara saber com o quê. A medição é ABSOLUTA: a linha de
# base do alvo (`.kg-ssot/gate.json`), se existir, só é lida para dizer quanto dela é dívida travada — dívida travada
# continua sendo dívida.
#
# USO  : remeasure-contract.sh <TARGET> [--exclude GLOB]...   (cole stdout E stderr: `2>&1`)
#        ONION_CONTRACT_NODES_OUT=<arquivo> grava ali os nós da dívida MUST (JSON lines {file, id, place}), para a fase 2 conferir
#        o plano da migração por identidade (fora do alvo: quem chama escolhe o caminho)
# SAÍDA: `CONTRATO medido: …` + uma linha por regra MUST e SHOULD (ocorrências, grafos) e, com dívida MUST, a
#        frase do caminho (migração). Sem vendor ou sem grafo: `CONTRATO não se aplica: …`.
# EXIT : 0 = todo grafo passa no MUST (dívida SHOULD, se houver, vai listada)
#        1 = há dívida MUST (escreva o número e o caminho no relatório; o update SEGUE)
#        3 = NÃO MEDIDO (vendor quebrado ou anterior, dependência ausente, alvo fora do git, QUALQUER exceção
#            imprevista) — escreva NÃO MEDIDO, nunca 0. O rc 1 só sai do ramo que contou a dívida: um traceback
#            nunca se passa por dívida (passada adversarial de 2026-10-20).
#        4 = não se aplica (alvo sem vendor/kg-ssot, ou sem nenhum .kg.yaml no corpus) — declare, não omita
# =============================================================================
set -uo pipefail
T="${1:?uso: remeasure-contract.sh <TARGET> [--exclude GLOB]...}"; shift
EXTRA=()
while [ $# -gt 0 ]; do
  case "$1" in
    --exclude) [ $# -ge 2 ] || { echo "CONTRATO NÃO MEDIDO: --exclude exige um glob" >&2; exit 3; }; EXTRA+=("$2"); shift 2 ;;
    *) echo "CONTRATO NÃO MEDIDO: argumento desconhecido: $1" >&2; exit 3 ;;
  esac
done
[ -d "${T}" ] || { echo "CONTRATO NÃO MEDIDO: ${T} não é diretório." >&2; exit 3; }
TOOLS="${T}/vendor/kg-ssot/tools"
if [ ! -f "${TOOLS}/kg_gate.py" ]; then
  echo "CONTRATO não se aplica: ${T} não tem o contrato vendorizado (vendor/kg-ssot/tools/kg_gate.py) — nada a medir."
  exit 4
fi
git -C "${T}" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "CONTRATO NÃO MEDIDO: ${T} não é repositório git (o corpus do gate é o que o git rastreia)." >&2; exit 3; }
command -v python3 >/dev/null 2>&1 || { echo "CONTRATO NÃO MEDIDO: python3 ausente (o leitor do contrato é Python)." >&2; exit 3; }

# -I: sem o diretório do script nem o cwd no sys.path. -B: sem bytecode — o vendor do alvo é carimbado por sha256,
# e um tools/__pycache__ plantado aqui faria o `kg_vendor.py check` dele reprovar (medido em 2026-10-08 no core).
# O alvo é só LIDO: git ls-files e a leitura dos .kg.yaml; nenhum arquivo dele é escrito.
# `${EXTRA[@]+…}`: array vazio sob `set -u` derruba o bash 3.2 (o do macOS).
python3 -I -B - "${TOOLS}" "${T}" ${EXTRA[@]+"${EXTRA[@]}"} <<'PY'
import collections, json, os, pathlib, sys
tools, repo, extra = sys.argv[1], sys.argv[2], tuple(sys.argv[3:])
sys.path.insert(0, tools)
ARCHIVE = ("docs/evolution/kg-inbox/_rejected/*", "docs/evolution/kg-inbox/_sealed/*")


def no(msg):
    print(f"CONTRATO NÃO MEDIDO: {msg}", file=sys.stderr)
    sys.exit(3)


def run():
    try:
        import kg_gate
        kg_validate = kg_gate.kg_validate
    except ModuleNotFoundError as e:  # PyYAML/jsonschema ausentes
        no(f"falta a dependência '{e.name}' do leitor do contrato — instale {tools}/requirements.txt")
    except Exception as e:  # vendor quebrado
        no(f"o leitor do contrato do alvo não carrega ({e.__class__.__name__}: {str(e)[:200]})")
    # a API que esta medição usa; vendor anterior (4.0.x não tem where/external_info) é NÃO MEDIDO, dito pelo nome
    need = [("kg_gate", kg_gate, n) for n in ("DEFAULT_EXCLUDE", "DEFAULT_BASELINE", "corpus", "tracked_graphs",
                                              "measure_texts", "validators")]
    need += [("kg_validate", kg_validate, n) for n in ("external_info", "corpus_index", "where")]
    missing = [f"{m}.{n}" for m, mod, n in need if not hasattr(mod, n)]
    if missing:
        no(f"o vendor do alvo é anterior ou incompatível (falta {', '.join(missing)}) — o --update traz o atual")

    exclude = tuple(kg_gate.DEFAULT_EXCLUDE) + ARCHIVE + extra
    items = kg_gate.corpus(repo, exclude)
    if not items:
        print(f"CONTRATO não se aplica: nenhum .kg.yaml rastreado no corpus de {repo} (excluídos: {', '.join(exclude)}).")
        sys.exit(4)
    # o índice das external_edges, exatamente como o main() do gate o monta: só os grafos que alguma referência cita
    info = [kg_validate.external_info(t) for _, t in items]
    wanted = set().union(*(targets for _, targets in info)) if info else set()
    index = (kg_validate.corpus_index(repo, [n for n in kg_gate.tracked_graphs(repo) if n in wanted])
             if any(uses for uses, _ in info) else None)
    measured = kg_gate.measure_texts(items, index)  # a MESMA medição do gate: os códigos que ele julga
    must_v, should_v = kg_gate.validators()
    # as ocorrências com o lugar (where): é o que separa "nós" de "arestas/arquivo" no número do relatório
    places = {name: kg_validate.where(text, must_v, should_v, index) for name, text in items}

    version = "?"
    try:
        version = json.loads((pathlib.Path(tools).parent / ".kg-ssot-version").read_text(encoding="utf-8")).get("version", "?")
    except Exception:
        pass

    failing = sorted(n for n, r in measured.items() if r["must"])
    must_occ, must_graphs, must_nodes = collections.Counter(), collections.defaultdict(set), set()
    should_occ, should_graphs = collections.Counter(), collections.defaultdict(set)
    off_node = 0  # ocorrências MUST cujo lugar NÃO é um nó (aresta, meta, arquivo): contadas à parte, nunca por subtração
    for name in sorted(measured):
        seen = set()
        for level, code, place in places[name]:
            if level == "MUST":
                seen.add(code)
                must_occ[code] += 1; must_graphs[code].add(name)
                if isinstance(place, str) and place.startswith("nó "):
                    must_nodes.add((name, place))
                else:
                    off_node += 1
            else:
                should_occ[code] += 1; should_graphs[code].add(name)
        # where() e o gate têm de concordar nos CÓDIGOS MUST; divergir é medição que não se sustenta
        if seen != set(measured[name]["must"]):
            no(f"em {name} o gate vê {sorted(measured[name]['must'])} e as ocorrências veem {sorted(seen)} — "
               "as duas leituras do vendor discordam")

    g = len(measured)
    out = [f"CONTRATO medido: kg-ssot {version} (o vendor do alvo) · {g} grafo(s) · {g - len(failing)} passam no MUST · "
           f"{len(failing)} reprovam",
           f"  corpus os .kg.yaml rastreados, excluídos: {', '.join(exclude)}"]
    out += [f"  MUST   {c}: {must_occ[c]} ocorrência(s) em {len(must_graphs[c])} grafo(s)" for c in sorted(must_occ)]
    out += [f"  SHOULD {c}: {should_occ[c]} ocorrência(s) em {len(should_graphs[c])} grafo(s)" for c in sorted(should_occ)]
    base = pathlib.Path(repo) / kg_gate.DEFAULT_BASELINE
    if base.is_file():
        try:
            locked = len(json.loads(base.read_text(encoding="utf-8")).get("failing") or {})
            out.append(f"  base   {kg_gate.DEFAULT_BASELINE}: {locked} grafo(s) na dívida MUST travada (travada continua sendo dívida)")
        except Exception:
            out.append(f"  base   {kg_gate.DEFAULT_BASELINE}: ilegível (o kg_gate.py do alvo sairia rc 2)")
    else:
        out.append(f"  base   {kg_gate.DEFAULT_BASELINE}: ausente (o alvo ainda não trava a dívida; o kg_gate.py dele sairia rc 2)")
    if failing:
        out.append(f"⚠️ seu corpus reprova no contrato vendorizado: {len(must_nodes)} nó(s) em {len(failing)} grafo(s)"
                   + (f" (e {off_node} ocorrência(s) MUST fora de nó: aresta, meta ou arquivo)" if off_node else "")
                   + "; caminho: migração do corpus ao contrato (a fase seguinte do --update planeja com o kg_migrate.py"
                   " do vendor e o perfil do alvo: plan-contract-migration.sh). Medir não é gate: o update segue.")
        out += [f"    · {name}: {' · '.join(measured[name]['must'])}" for name in failing]
    nodes_out = os.environ.get("ONION_CONTRACT_NODES_OUT")
    if nodes_out:  # a fase 2 confere o plano por IDENTIDADE, não só pelo número: os nós da dívida MUST, um por linha
        # JSON lines {file, id}: o arquivo pelo caminho REAL relativo ao alvo (o migrador resolve symlink) e o id
        # pelo place do where() ('nó X', 'nó X (#2)' na repetição, 'nó #5' sem id): uma linha por OCORRÊNCIA
        import re
        place_rx, real_repo = re.compile(r"^nó (?:#(\d+)|(.+?))(?: \(#(\d+)\))?$"), os.path.realpath(repo)
        lines = []
        for n, p in sorted(must_nodes):
            m = place_rx.match(p)
            lines.append(json.dumps({"file": os.path.relpath(os.path.realpath(os.path.join(repo, n)), real_repo),
                                     "id": (m.group(2) if m and m.group(2) is not None else None),
                                     "place": p}, ensure_ascii=False))
        pathlib.Path(nodes_out).write_text("".join(x + "\n" for x in lines), encoding="utf-8")
    print("\n".join(out))  # tudo de uma vez: uma exceção no meio não deixa meio relatório no stdout
    return 1 if failing else 0


try:
    rc = run()
except SystemExit:
    raise
except BaseException as e:  # Broken (fora do git), YAML ilegível, API diferente: NUNCA o rc 1 da dívida
    no(f"a medição quebrou ({e.__class__.__name__}: {str(e)[:200]})")
sys.exit(rc)
PY
