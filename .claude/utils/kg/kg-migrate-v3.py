#!/usr/bin/env python3
"""kg-migrate-v3.py — leva um .kg.yaml ao SHOULD do contrato v3, sem inventar nada.

Por que existe (2026-10-08, SAC-73 parte 1): o contrato v3 do .kg.yaml (vendor/kg-ssot) alerta três
dívidas no corpus do core — data sem aspas, nó confirmed/PROD sem `provenance` e label acima de 280
caracteres. Os geradores já escrevem no formato novo (SAC-71); o corpus antigo migra em ondas, e esta é a
ferramenta das ondas.

O que ela FAZ (determinístico, idempotente, edição por linha — o radar é awk e lê uma chave por linha):
  · DATAS: `baseline`, `review_after`, `verified_at`, `valid_from` sem aspas ganham aspas duplas.
  · PROVENANCE: nó confirmed ou `plane: PROD` sem `provenance` ganha o bloco SÓ quando o próprio nó já traz
    uma fonte verificável: o `trace:` do nó, ou a primeira URL / caminho de arquivo citado no
    `verified_against`. O `locator` é o `verified_against` (o registro do que foi medido), e o `method` diz,
    com todas as letras, que o bloco foi DERIVADO na migração e não reverificado.
  · COM --routing <tsv> (onda O1 do SAC-73, 2026-10-09): a ferramenta SÓ escreve provenance, e só nos nós que
    o routing da triagem (data/provenance-triage/routing-v4.tsv do grafo contrato-kg-absorcao-2026-10) manda
    para A1 ou A2 (coluna `final`). O `method` usa a classe que o routing propôs (coluna `method_class`):
    "<classe>: provenance derivada na migração …; não reverificado". Datas NÃO são citadas neste modo (a onda
    é só de provenance). Nó fora de A1/A2 (resíduo R, ou ausente do routing) fica intocado e sai no relatório;
    nó roteado com classe de method fora do contrato também, e nó cujo trace é o PRÓPRIO grafo (fonte circular).
    Fonte em caminho absoluto do host vira "testemunho: leitura do arquivo <x> no host; …" (política 4 selada).
    Sem --routing, nada muda.
  · ONDA O2 (2026-10-09, dentro do --routing): nó A1/A2 com `trace:` e SEM `verified_against` (o registro do que
    foi medido não existe, então não há locator a copiar) recebe o trace como source E como locator, com
    `method: "derivado: trace do nó, sem registro de medição"` (política selada da O2). Recusa, e deixa para a
    O3: trace circular (o próprio grafo) e trace com caminho do repo que não existe mais (resolvido a partir da
    raiz que o routing implica: o arquivo termina com o caminho do grafo no routing) e trace sem localizador
    (citação textual: memória, histórico de outro repo — sem URL nem caminho) e trace que registra um comando
    (grep/ls/find/git, run, PR #N: é medição, e a política 2 é da O3). Trace em caminho do host
    segue a política 4 (testemunho). Nó sem trace e sem fonte no verified_against segue "sem fonte recuperável".
O que ela NÃO faz (é decisão humana ou do contrato, nunca da ferramenta):
  · nó sem fonte derivável NÃO recebe provenance inventada: sai no relatório como "sem fonte recuperável"
    (a gramática diz: sem fonte verificável, o nó não é confirmed — rebaixar é decisão de quem conhece o nó);
  · label acima de 280 NÃO é cortado: separar fato e narrativa é semântico; sai no relatório.

Uso:   kg-migrate-v3.py [--check] [--routing <routing.tsv>] <arquivo.kg.yaml>...
rc:    0 = nada pendente (ou aplicado) · 1 = --check e há mudança pendente · 2 = entrada quebrada
       (arquivo ausente, routing ilegível ou sem as colunas, YAML inválido antes ou DEPOIS da edição — a edição
       nunca grava YAML inválido).
"""
import os
import re
import sys

try:
    import yaml
except ImportError:  # sem PyYAML não dá para provar que a saída continua YAML válido
    print("kg-migrate-v3: PyYAML ausente — não migro sem conferir a saída", file=sys.stderr)
    sys.exit(2)

DATE_KEYS = ("baseline", "review_after", "verified_at", "valid_from")
# data (ano, ano-mês ou ano-mês-dia) SEM aspas, com comentário opcional ao fim
DATE_RE = re.compile(r'^(\s*(?:' + "|".join(DATE_KEYS) + r'):[ \t]+)(\d{4}(?:-\d{2}(?:-\d{2})?)?)([ \t]*(?:#.*)?)$')
NODE_RE = re.compile(r'^  - id:[ \t]*(\S+)')
FIELD_RE = re.compile(r'^    ([A-Za-z_][A-Za-z0-9_]*):[ \t]*(.*)$')
URL_RE = re.compile(r'https?://[^\s"\'<>),;]+')
PATH_RE = re.compile(r'(?<![\w./-])((?:\.claude|docs|ops|vendor|plugins|\.github)/[\w./+-]*[\w+-])')
# trace que REGISTRA um comando (grep/ls/find/git, run do Actions, PR #N) é registro de medição, e o method
# "sem registro de medição" seria falso: vai para a O3, onde a política 2 decide ("medição: <comando>").
# Passada adversarial da O2 (2026-10-09): 8 nós escritos assim; o `→` solto ficou de fora (casava descrição de cadeia).
CMD_TRACE_RE = re.compile(r'\b(grep|ls|find)\s|\bgit\s+(show|log|ls-files|ls-tree|merge-base|diff)\b|\bruns?\s+\d{6,}|\bPR\s*#\d+')
LABEL_MAX = 280
# as classes de method do contrato v4 (SHOULD: ^(medição|leitura|juízes|derivado|testemunho): \S)
METHOD_CLASSES = ("medição", "leitura", "juízes", "derivado", "testemunho")
ROUTED = ("A1", "A2")
ROUTING_COLS = ("graph", "id", "final", "method_class")


class BrokenInput(Exception):
    """Entrada quebrada: rc 2."""


def load_routing(path):
    """{(grafo, id): (final, method_class)} do TSV da triagem. Coluna ausente ou arquivo ilegível → BrokenInput."""
    try:
        rows = [ln.rstrip("\n").split("\t") for ln in open(path, encoding="utf-8") if ln.strip()]
    except OSError as e:
        raise BrokenInput(f"routing ilegível ({path}): {e.__class__.__name__}")
    if not rows or any(c not in rows[0] for c in ROUTING_COLS):
        raise BrokenInput(f"routing sem as colunas {', '.join(ROUTING_COLS)} no cabeçalho ({path})")
    ix = {c: rows[0].index(c) for c in ROUTING_COLS}
    out = {}
    for r in rows[1:]:
        if len(r) <= max(ix.values()):
            raise BrokenInput(f"routing com linha curta ({path}): {r[:2]}")
        out[(r[ix["graph"]], r[ix["id"]])] = (r[ix["final"]], r[ix["method_class"]])
    return out


def routes_for(routing, f):
    """(caminho do grafo no routing, {id: rota}): casa o caminho do routing (relativo à raiz) com o fim do dado."""
    norm = f.replace("\\", "/")
    while norm.startswith("./"):
        norm = norm[2:]
    graphs = {g for g, _ in routing if norm == g or norm.endswith("/" + g)}
    if not graphs:
        return None, {}
    g = max(graphs, key=len)
    return g, {i: v for (gg, i), v in routing.items() if gg == g}


def scalar(raw):
    """Valor YAML de uma linha (aspas tiradas por YAML, não por regex). Bloco > | não é tratado aqui."""
    raw = raw.strip()
    if not raw or raw[0] in ">|":
        return None
    try:
        v = yaml.safe_load("k: " + raw)["k"]
    except Exception:
        return None
    return v if isinstance(v, str) else (str(v) if v is not None else None)


def q(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def source_of(fields):
    trace = scalar(fields.get("trace", ""))
    if trace:
        return trace, "trace do nó"
    va = scalar(fields.get("verified_against", "")) or ""
    m = URL_RE.search(va)
    if m:
        return m.group(0), "URL citada no verified_against"
    m = PATH_RE.search(va)
    if m:
        return m.group(1), "caminho citado no verified_against"
    return None, None


def trace_locator(src, root):
    """(caminhos sumidos, tem localizador) do trace na onda O2. Localizador = URL http(s), caminho do repo que
    existe (com o prefixo de PATH_RE, ou o 1º token, sem :linha/#âncora, existindo a partir da raiz). Citação
    textual (comando, memória, "síntese desta leva", histórico de outro repo) NÃO é localizador: sem o registro
    da medição, nada ali se resolve — fica para a O3 (passada adversarial da O2, 2026-10-09: 15 nós assim)."""
    paths = [m.group(1) for m in PATH_RE.finditer(src)]
    gone = [p for p in paths if not os.path.exists(os.path.join(root, p))]
    first = re.sub(r"[:#].*$", "", re.split(r"[\s;,·]", src)[0])
    loose = bool(first) and "/" not in first[:1] and os.path.isfile(os.path.join(root, first))
    return gone, bool(URL_RE.search(src) or paths or loose)


def migrate(text, routes=None, graph=None, root=None):
    """routes=None: o modo de sempre. routes={id: (final, method_class)}: só provenance, só nos ids A1/A2.
    graph: o caminho do próprio grafo (modo routing), para recusar a fonte circular."""
    lines = text.split("\n")
    out, rep = [], {"dates": 0, "prov": [], "nosource": [], "longlabel": [], "unrouted": [], "badclass": [],
                    "circular": [], "gone": [], "nolocator": [], "cmdtrace": []}
    # 1) datas (fora do modo routing: a onda O1 é só de provenance)
    for ln in lines:
        m = DATE_RE.match(ln) if routes is None else None
        if m:
            ln = m.group(1) + '"' + m.group(2) + '"' + m.group(3)
            rep["dates"] += 1
        out.append(ln)
    lines, out = out, []
    # 2) nós: provenance e label
    in_nodes, i = False, 0
    while i < len(lines):
        ln = lines[i]
        if re.match(r'^nodes:\s*(#.*)?$', ln):
            in_nodes = True
        elif re.match(r'^[A-Za-z_]', ln):
            in_nodes = False
        m = NODE_RE.match(ln) if in_nodes else None
        if not m:
            out.append(ln); i += 1; continue
        nid, j = m.group(1), i + 1
        # o bloco do nó: linhas com indentação >= 4, comentários e brancos internos
        while j < len(lines) and (lines[j].startswith("    ") or not lines[j].strip() or lines[j].lstrip().startswith("#")) \
                and not NODE_RE.match(lines[j]):
            j += 1
        # brancos/comentários do fim pertencem ao que vem depois
        end = j
        while end > i + 1 and (not lines[end - 1].strip() or lines[end - 1].lstrip().startswith("#")):
            end -= 1
        block = lines[i:end]
        fields = {}
        for b in block[1:]:
            fm = FIELD_RE.match(b)
            if fm:
                fields[fm.group(1)] = fm.group(2)
        status, plane = scalar(fields.get("status", "")), scalar(fields.get("plane", ""))
        label = scalar(fields.get("label", "")) or ""
        if len(label) > LABEL_MAX:
            rep["longlabel"].append(f"{nid} ({len(label)})")
        # no modo routing vale o universo do contrato v4: unverifiable é isento de provenance, mesmo em PROD
        exempt = routes is not None and status == "unverifiable"
        if (status == "confirmed" or plane == "PROD") and "provenance" not in fields and not exempt:
            src, how = source_of(fields)
            va = scalar(fields.get("verified_against", ""))
            route = None if routes is None else routes.get(nid)
            if routes is not None and (route is None or route[0] not in ROUTED):
                # fora de A1/A2 (resíduo, ou ausente do routing): intocado — é da onda O2/O3, não desta
                rep["unrouted"].append(f"{nid} ({route[0] if route else 'sem rota'})")
            elif routes is not None and route[1] not in METHOD_CLASSES:
                rep["badclass"].append(f"{nid} ({route[1]})")
            elif routes is not None and graph and how == "trace do nó" and re.split(r"[\s#:@]", src.strip())[0] == graph:
                # o trace aponta o PRÓPRIO grafo: a fonte seria circular (o que foi lido está noutro lugar).
                # Medido na passada adversarial da O1 (2026-10-09): 6 nós assim, todos com a fonte real fora do grafo.
                rep["circular"].append(nid)
            elif routes is not None and src and not va and how == "trace do nó":
                # onda O2: sem o registro da medição, o trace é o único locator honesto — e o method diz que é só isso
                s = src.strip()
                host = s.startswith("/")
                gone, located = (([], True) if host else ([], False) if root is None else trace_locator(s, root))
                if gone:
                    rep["gone"].append(f"{nid} ({gone[0]})")
                elif CMD_TRACE_RE.search(s):
                    rep["cmdtrace"].append(nid)
                elif not located:
                    rep["nolocator"].append(nid)
                else:
                    method = (f"testemunho: leitura do arquivo {s.split()[0]} no host; trace do nó, sem registro de medição"
                              if host else "derivado: trace do nó, sem registro de medição")
                    block = block + [
                        "    provenance:",
                        "      source: " + q(src),
                        "      locator: " + q(src),
                        "      method: " + q(method),
                    ]
                    rep["prov"].append(nid)
            elif routes is not None and src and va:
                # política 4 selada (D_POLITICAS_DA_MIGRACAO_DE_PROVENANCE): fonte em caminho do host, fora do repo,
                # é testemunho da leitura no host — a CI não alcança o arquivo; a classe do routing não vale aqui
                host = src.strip().startswith("/")
                cls = "testemunho" if host else route[1]
                detail = (f"leitura do arquivo {src.strip().split()[0]} no host; " if host else "") + \
                    f"provenance derivada na migração ao contrato v4 ({how}; rota {route[0]} da triagem); não reverificado"
                block = block + [
                    "    provenance:",
                    "      source: " + q(src),
                    "      locator: " + q(va),
                    "      method: " + q(f"{cls}: {detail}"),
                ]
                rep["prov"].append(nid)
            elif routes is None and src and va:
                block = block + [
                    "    provenance:",
                    "      source: " + q(src),
                    "      locator: " + q(va),
                    "      method: " + q(f"derivado: na migração ao contrato v3 ({how}); não reverificado"),
                ]
                rep["prov"].append(nid)
            else:
                rep["nosource"].append(nid)
        out.extend(block)
        out.extend(lines[end:j])
        i = j
    return "\n".join(out), rep


def main(argv):
    check = "--check" in argv
    argv = [a for a in argv if a != "--check"]
    routing = None
    if "--routing" in argv:
        k = argv.index("--routing")
        if k + 1 >= len(argv):
            print("kg-migrate-v3: --routing pede o caminho do TSV", file=sys.stderr); return 2
        try:
            routing = load_routing(argv[k + 1])
        except BrokenInput as e:
            print(f"kg-migrate-v3: {e}", file=sys.stderr); return 2
        argv = argv[:k] + argv[k + 2:]
    files = argv
    if not files:
        print(__doc__.strip().split("\n\n")[-1], file=sys.stderr); return 2
    pending = False
    for f in files:
        try:
            text = open(f, encoding="utf-8").read()
            yaml.safe_load(text)
        except FileNotFoundError:
            print(f"kg-migrate-v3: {f} não existe", file=sys.stderr); return 2
        except yaml.YAMLError as e:
            print(f"kg-migrate-v3: {f} não é YAML válido antes da migração ({e.__class__.__name__}) — não toco", file=sys.stderr); return 2
        gpath, routes = (None, None) if routing is None else routes_for(routing, f)
        root = None
        if gpath is not None:
            norm = os.path.abspath(f).replace("\\", "/")
            root = norm[:-len(gpath)] or "/"
        new, rep = migrate(text, routes, gpath, root)
        try:
            yaml.safe_load(new)
        except yaml.YAMLError as e:
            print(f"kg-migrate-v3: a migração de {f} daria YAML inválido ({e.__class__.__name__}) — nada gravado", file=sys.stderr); return 2
        changed = new != text
        verb = ("PENDENTE" if check else "aplicado") if changed else "nada a migrar"
        extra = "" if routing is None else (f" · fora da rota A1/A2 (intocado) {len(rep['unrouted'])}"
                                             f" · classe de method fora do contrato {len(rep['badclass'])}"
                                             f" · fonte circular (trace = o próprio grafo) {len(rep['circular'])}"
                                             f" · trace sumido {len(rep['gone'])}"
                                             f" · trace sem localizador {len(rep['nolocator'])}"
                                             f" · trace é registro de comando {len(rep['cmdtrace'])}")
        print(f"{f}: {verb} · datas citadas {rep['dates']} · provenance derivada {len(rep['prov'])}"
              f" · sem fonte recuperável {len(rep['nosource'])} · label > {LABEL_MAX}: {len(rep['longlabel'])}{extra}")
        for k, title in (("prov", "provenance derivada"), ("nosource", "SEM FONTE RECUPERÁVEL (decisão humana: fonte ou rebaixar)"),
                         ("unrouted", "FORA DA ROTA A1/A2 (intocado: onda O2/O3)"),
                         ("badclass", "CLASSE DE METHOD FORA DO CONTRATO (intocado)"),
                         ("circular", "FONTE CIRCULAR: o trace é o próprio grafo (intocado: onda O3)"),
                         ("gone", "TRACE SUMIDO: o caminho citado não existe mais (intocado: onda O3)"),
                         ("nolocator", "TRACE SEM LOCALIZADOR: citação textual sem verified_against (intocado: onda O3)"),
                         ("cmdtrace", "TRACE É REGISTRO DE COMANDO: medição, política 2 (intocado: onda O3)"),
                         ("longlabel", "label longo (decisão humana: label curto + narrative)")):
            if rep[k]:
                print(f"  {title}: " + ", ".join(rep[k]))
        if changed:
            pending = True
            if not check:
                open(f, "w", encoding="utf-8").write(new)
    return 1 if (check and pending) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
