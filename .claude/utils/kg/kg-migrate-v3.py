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
  · COM --apply-judged <csv> (onda O3, 2026-10-09): aplica a planilha JULGADA (data/provenance-triage/
    o3-wave<N>-juiz.csv: id, grafo, veredito, proposta_final, source_final, locator_final, method_final). Só
    linha com veredito APROVADO ou CORRIGIDO é aplicada; REPROVADO nunca é tocado e sai no relatório.
      corrigir | testemunho → escreve (ou SUBSTITUI, no lugar) o bloco `provenance` com os valores *_final;
      rebaixar             → `status: confirmed` vira `status: unverifiable` (o v4 isenta de provenance);
      dev-óbvio            → `plane: PROD` vira `plane: DEV`; se o nó for confirmed sem provenance e a linha
                             trouxer fonte, a fonte também é escrita.
    Ondas 2 e 3 da O3 (selos do maestro, 2026-10-09) acrescentam:
      corrigir-label       → troca o `label` pelo `label_final` (≤280, senão a LINHA INTEIRA é recusada) e leva o
                             label antigo para a `narrative` como "label anterior: …" (a história não se apaga);
                             também escreve a provenance;
      refutar              → `status: confirmed` vira `refuted`, o `motivo` do juiz entra na `narrative` como
                             evidência, a provenance é escrita, e o relatório lista as arestas que tocam o nó
                             (SUPPORTS saindo, REFUTES saindo, DEPENDS_ON entrando) para a reconciliação;
      dev-dúvida           → fica em PROD: com fonte do juiz, escreve a provenance; sem fonte, intocado e listado;
      --promote-unverifiable → nó `unverifiable` com corrigir/corrigir-label/testemunho e fonte julgada volta a
                             `confirmed` (a classe "fonte contradiz o label" que a onda 1 rebaixou). Sem a flag,
                             a provenance é escrita, o status fica, e o nó sai no relatório.
    Qualquer outra proposta é decisão do maestro: intocada e reportada. Recusa (intocado e reportado, e atômica:
    nada da linha é aplicado): method fora das classes do contrato, source/locator vazios, label_final vazio ou
    acima de 280, refutar sobre status que não é confirmed, nó ausente do grafo, rebaixar sobre status que não é
    confirmed. Edição por linha; a 2ª aplicação é no-op. Datas não são citadas neste modo.
  · ONDA O4 (2026-10-09, SAC-73): a planilha com as colunas `regra` e `locality_final` (o4-juiz.csv) aceita o mesmo
    nó numa linha por regra e aplica dev-historia (PROD→DEV), manter-prod-medido (provenance medida + verified_at
    do --verified-at), reescrever-source e corrigir-method-locality (provenance com a locality do juiz; `(inalterado)`
    mantém o valor atual; caminho absoluto de arquivo na source final é recusado). Ver apply_judged_o4.
  · ONDA O5 (2026-10-09, SAC-73): o5-juiz.csv, mesmo formato da O4 com campo `*_final` VAZIO = inalterado, aplica
    reescrever-locator-method, manter-prod-binario (fica PROD), manter-dev-binario (fica DEV, plano nunca muda) e
    dev-sem-versao (PROD→DEV); caminho de máquina (absoluto ou ~/) que sobre em source, locator OU method finais
    recusa a linha inteira. Ver _o5_row.
  · COM --locality (contrato v4.2, 2026-10-09, SAC-97): só ACRESCENTA `provenance.locality` (repo|web|host|
    pessoa) às provenances em bloco que ainda não a têm, quando o `source` a determina pela regra de locality_of
    (ver o bloco "provenance.locality" abaixo); sem certeza, o nó fica sem a chave e sai na contagem. Prova, por
    grafo, que o YAML relido é o de antes mais a chave nova (senão rc 2, nada gravado). Idempotente: re-rodar
    regenera o mesmo resultado, o que resolve conflito com PR paralelo. Os modos que ESCREVEM provenance (o de
    sempre, --routing e --apply-judged) passam a escrever a locality junto, pela mesma regra.
O que ela NÃO faz (é decisão humana ou do contrato, nunca da ferramenta):
  · nó sem fonte derivável NÃO recebe provenance inventada: sai no relatório como "sem fonte recuperável"
    (a gramática diz: sem fonte verificável, o nó não é confirmed — rebaixar é decisão de quem conhece o nó);
  · label acima de 280 NÃO é cortado: separar fato e narrativa é semântico; sai no relatório.

Uso:   kg-migrate-v3.py [--check] [--routing <routing.tsv> | --apply-judged <juiz.csv> [--promote-unverifiable] [--verified-at AAAA-MM-DD] | --locality] <arquivo.kg.yaml>...
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


# ── provenance.locality (contrato v4.2, 2026-10-09, SAC-97) ───────────────────────────────────────────────
# Onde a fonte MORA: repo (versionado neste repo), web (endereço público), host (só existe numa máquina) ou
# pessoa (relato de alguém). Opcional no contrato; serve para medir o que um terceiro reverifica e para barrar
# `host` quando o grafo vai a público. A regra é DETERMINÍSTICA e erra para o lado de CALAR: sem certeza, não
# há locality (None), e o nó segue sem a chave — nunca se inventa onde a fonte mora.
#   · o source é partido em segmentos (" · ", " + ", " ; ", "; ", " e "); cada segmento é julgado pelo 1º token;
#   · web     — token http(s)://…, ou um domínio (tst.jus.br, github.com/x) que não é caminho do repo;
#   · host    — caminho absoluto (/…, ~/…) ou journal de workflow (wf_…, "run(s) wf_…": mora no host);
#   · repo    — caminho cujo 1º componente existe na raiz do repo (sem :linha/#âncora/@ref), ou sha de commit
#               que o git DESTE repo conhece (`git cat-file -e <sha>^{commit}`, também em git:<sha>, commit <sha>,
#               <sha>:<caminho>);
#   · pessoa  — segmento que abre por sessão/sessao, resposta do maestro, mensagem, relato, conversa, maestro;
#   · segmento que não cai em nenhuma classe → o source inteiro fica SEM locality;
#   · segmentos de classes diferentes → vale a MENOS reverificável (repo < web < host < pessoa): uma fonte
#     metade-host não se reverifica de fora, e é a que a porta precisa barrar.
LOCALITIES = ("repo", "web", "host", "pessoa")
_LOC_SPLIT = re.compile(r'\s+·\s+|\s+\+\s+|\s*;\s+|\s+e\s+')
_LOC_PESSOA = re.compile(r'^(sess[ãa]o|resposta d[oa]|mensage[mn]|relato|conversa|maestro)\b', re.I)
_LOC_SHA = re.compile(r'^(?:git:\s*|commit\s+)?([0-9a-f]{7,40})(?:[\^~]\d*)?(?::\S*)?(?:\s|$)')
_LOC_DOMAIN = re.compile(r'^(?:[a-z0-9-]+\.)+([a-z]{2,6})(?:/\S*)?$', re.I)
_FILE_EXT = {"md", "yaml", "yml", "sh", "py", "js", "json", "ts", "tsx", "css", "txt", "html", "astro", "toml", "csv", "tsv"}
_SHA_CACHE = {}


def _is_commit(sha, root):
    key = (root, sha)
    if key not in _SHA_CACHE:
        import subprocess
        _SHA_CACHE[key] = subprocess.run(["git", "-C", root, "cat-file", "-e", sha + "^{commit}"],
                                         capture_output=True).returncode == 0
    return _SHA_CACHE[key]


def _segment_locality(seg, root):
    seg = seg.strip().strip('"\'')
    if not seg:
        return None
    if _LOC_PESSOA.match(seg):
        return "pessoa"
    low = seg.lower()
    if re.match(r'^(?:runs?\s+)?wf_[0-9a-f]', low):
        return "host"
    tok = seg.split()[0].rstrip(",;")
    if re.match(r'^https?://', tok):
        return "web"
    if tok.startswith("/") or tok.startswith("~/"):
        return "host"
    if root:
        m = _LOC_SHA.match(seg)
        if m and _is_commit(m.group(1), root):
            return "repo"
        bare = re.split(r'[:#@]', tok)[0].rstrip("/")
        first = bare.split("/")[0]
        if first and first not in (".", "..") and os.path.exists(os.path.join(root, first)):
            return "repo"
    d = _LOC_DOMAIN.match(tok)
    if d and d.group(1).lower() not in _FILE_EXT:
        return "web"
    return None


def locality_of(src, root=None):
    """locality do source (ver o bloco acima), ou None quando não há certeza. root: a raiz do repo (sem ela,
    nada é `repo`, porque não há contra o que conferir)."""
    if not isinstance(src, str) or not src.strip():
        return None
    got = [_segment_locality(s, root) for s in _LOC_SPLIT.split(src.strip())]
    if not got or None in got:
        return None
    return max(got, key=LOCALITIES.index)


def repo_root_of(path):
    """A raiz git do arquivo (para julgar `repo`), ou None fora de um repo git."""
    import subprocess
    d = os.path.dirname(os.path.abspath(path)) or "."
    r = subprocess.run(["git", "-C", d, "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 and r.stdout.strip() else None


def _loc_line(src, root):
    loc = locality_of(src, root)
    return ["      locality: " + q(loc)] if loc else []


def add_locality(text, root):
    """Escreve `locality` nas provenances em bloco que ainda não a têm, quando o source a determina. Edição por
    linha, só ACRESCENTA uma linha ao fim do bloco provenance. Devolve (texto, {classe: [ids]}, [ids sem certeza],
    [ids em forma de fluxo])."""
    lines = text.split("\n")
    out, by, unsure, flow = [], {k: [] for k in LOCALITIES}, [], []
    in_nodes, nid, i = False, None, 0
    while i < len(lines):
        ln = lines[i]
        if re.match(r'^nodes:\s*(#.*)?$', ln):
            in_nodes = True
        elif re.match(r'^[A-Za-z_]', ln):
            in_nodes = False
        m = NODE_RE.match(ln) if in_nodes else None
        if m:
            nid = m.group(1)
        if in_nodes and nid and re.match(r'^    provenance:', ln):
            if not re.match(r'^    provenance:[ \t]*(#.*)?$', ln):
                flow.append(nid); out.append(ln); i += 1; continue
            j = i + 1
            while j < len(lines) and lines[j].startswith("      "):
                j += 1
            body = lines[i:j]
            try:
                cur = yaml.safe_load("\n".join(x[4:] for x in body))["provenance"]
            except Exception:
                cur = None
            out.extend(body)
            if isinstance(cur, dict) and "locality" not in cur:
                loc = locality_of(cur.get("source"), root)
                if loc:
                    out.append("      locality: " + q(loc)); by[loc].append(nid)
                else:
                    unsure.append(nid)
            i = j
            continue
        out.append(ln); i += 1
    return "\n".join(out), by, unsure, flow


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


def migrate(text, routes=None, graph=None, root=None, lroot=None):
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
                    ] + _loc_line(src, lroot)
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
                ] + _loc_line(src, lroot)
                rep["prov"].append(nid)
            elif routes is None and src and va:
                block = block + [
                    "    provenance:",
                    "      source: " + q(src),
                    "      locator: " + q(va),
                    "      method: " + q(f"derivado: na migração ao contrato v3 ({how}); não reverificado"),
                ] + _loc_line(src, lroot)
                rep["prov"].append(nid)
            else:
                rep["nosource"].append(nid)
        out.extend(block)
        out.extend(lines[end:j])
        i = j
    return "\n".join(out), rep


JUDGED_COLS = ("id", "grafo", "veredito", "proposta_final", "source_final", "locator_final", "method_final")
JUDGED_OK = ("APROVADO", "CORRIGIDO")
PROV_ACTIONS = ("corrigir", "testemunho")


def load_judged(path):
    """{(grafo, id): linha} da planilha julgada. Coluna ausente, arquivo ilegível ou id duplicado → BrokenInput."""
    import csv
    try:
        rows = list(csv.DictReader(open(path, encoding="utf-8", newline="")))
    except OSError as e:
        raise BrokenInput(f"planilha julgada ilegível ({path}): {e.__class__.__name__}")
    if not rows or any(c not in rows[0] for c in JUDGED_COLS):
        raise BrokenInput(f"planilha julgada sem as colunas {', '.join(JUDGED_COLS)} ({path})")
    out = {}
    by_rule = "regra" in rows[0]  # formato O4: o mesmo nó pode vir numa linha por regra
    for r in rows:
        k = (r["grafo"], r["id"])
        if by_rule:
            if any(x["regra"] == r["regra"] for x in out.get(k, [])):
                raise BrokenInput(f"planilha julgada com id duplicado na mesma regra ({path}): {k[1]} em {k[0]} (regra {r['regra']})")
            out.setdefault(k, []).append(r)
        elif k in out:
            raise BrokenInput(f"planilha julgada com id duplicado ({path}): {k[1]} em {k[0]}")
        else:
            out[k] = r
    return out


def _set_field(block, key, old, new):
    """Troca `    <key>: <old>` por `<new>` no bloco, preservando aspas e comentário. (bloco, mudou?, valor atual)."""
    for n, b in enumerate(block[1:], 1):
        fm = FIELD_RE.match(b)
        if fm and fm.group(1) == key:
            cur = scalar(fm.group(2))
            if cur != old:
                return block, False, cur
            raw = fm.group(2)
            m = re.match(r'^(["\']?)' + re.escape(old) + r'\1([ \t]*(?:#.*)?)$', raw)
            if not m:
                return block, False, cur
            block = block[:n] + [f"    {key}: {m.group(1)}{new}{m.group(1)}{m.group(2)}"] + block[n + 1:]
            return block, True, cur
    return block, False, None


def _put_provenance(block, src, loc, method, lroot=None, locality=None, derive=True):
    """Escreve o bloco provenance (ou substitui o existente, no mesmo lugar), com a locality quando o source a
    determina (contrato v4.2) ou, na O4, a que o juiz escreveu (`locality`). derive=False (O5): sem locality do juiz
    e sem locality atual, o nó continua sem a chave (campo vazio = inalterado). (bloco, mudou?)."""
    loc_val = locality or (locality_of(src, lroot) if derive else None)
    new = ["    provenance:", "      source: " + q(src), "      locator: " + q(loc), "      method: " + q(method)] \
        + (["      locality: " + q(loc_val)] if loc_val else [])
    want = {"source": src, "locator": loc, "method": method}
    if loc_val:
        want["locality"] = loc_val
    for n, b in enumerate(block[1:], 1):
        if re.match(r'^    provenance:[ \t]*(#.*)?$', b):
            e = n + 1
            while e < len(block) and (block[e].startswith("      ") or not block[e].strip()):
                e += 1
            while e > n + 1 and not block[e - 1].strip():
                e -= 1
            try:
                cur = yaml.safe_load("\n".join(x[4:] for x in block[n:e]))["provenance"]
            except Exception:
                cur = None
            if cur == want:
                return block, False
            return block[:n] + new + block[e:], True
        if re.match(r'^    provenance:', b):  # forma em fluxo ({...}): não reescrevo o que não sei editar por linha
            return block, None
    return block + new, True


def _get_scalar(block, key):
    """(índice da linha, valor) de `    <key>: <escalar>` no bloco; (None, None) se ausente; valor None se for bloco > |."""
    for n, b in enumerate(block[1:], 1):
        fm = FIELD_RE.match(b)
        if fm and fm.group(1) == key:
            return n, scalar(fm.group(2))
    return None, None


def _append_narrative(block, text):
    """Acrescenta `text` à narrative (escalar de uma linha) ou cria a chave logo após o label. (bloco, mudou?)."""
    n, cur = _get_scalar(block, "narrative")
    if n is not None and cur is None:
        return block, None  # narrative em bloco > |: não reescrevo por linha
    if n is not None:
        if text in cur:
            return block, False
        return block[:n] + ["    narrative: " + q((cur.rstrip() + " · " if cur.strip() else "") + text)] + block[n + 1:], True
    li, _ = _get_scalar(block, "label")
    at = (li + 1) if li is not None else len(block)
    return block[:at] + ["    narrative: " + q(text)] + block[at:], True


def apply_judged(text, judged, promote=False, wave="", lroot=None):
    """judged={id: linha da planilha}: aplica só APROVADO/CORRIGIDO, por linha. Devolve (texto, relatório).
    promote=True é o selo do maestro que leva `unverifiable` a `confirmed` quando o juiz deu fonte (onda 3 da O3).
    A linha recusada é atômica: nada dela é aplicado (nem a provenance de um corrigir-label com label longo)."""
    lines = text.split("\n")
    rep = {"prov": [], "demote": [], "plane": [], "same": [], "rejected": [], "sealed": [], "refused": [], "missing": [],
           "relabel": [], "refute": [], "promote": [], "unpromoted": [], "doubt": []}
    seen, out, in_nodes, i = set(), [], False, 0
    tag = f"onda {wave} da O3" if wave else "O3"
    while i < len(lines):
        ln = lines[i]
        if re.match(r'^nodes:\s*(#.*)?$', ln):
            in_nodes = True
        elif re.match(r'^[A-Za-z_]', ln):
            in_nodes = False
        m = NODE_RE.match(ln) if in_nodes else None
        if not m or m.group(1) not in judged:
            out.append(ln); i += 1; continue
        nid, j = m.group(1), i + 1
        seen.add(nid)
        while j < len(lines) and (lines[j].startswith("    ") or not lines[j].strip() or lines[j].lstrip().startswith("#")) \
                and not NODE_RE.match(lines[j]):
            j += 1
        end = j
        while end > i + 1 and (not lines[end - 1].strip() or lines[end - 1].lstrip().startswith("#")):
            end -= 1
        block, r = lines[i:end], judged[nid]
        orig = list(block)
        fields = {fm.group(1): fm.group(2) for fm in (FIELD_RE.match(b) for b in block[1:]) if fm}
        status = scalar(fields.get("status", ""))
        act, verdict = r["proposta_final"].strip(), r["veredito"].strip()
        src, loc, method = r["source_final"].strip(), r["locator_final"].strip(), r["method_final"].strip()
        new_label = (r.get("label_final") or "").strip()
        has_src = bool(src and loc and method)
        good_method = bool(re.match(r'^(' + "|".join(METHOD_CLASSES) + r'): \S', method))
        refused = None
        if verdict not in JUDGED_OK:
            rep["rejected"].append(f"{nid} ({verdict})")
        elif act in PROV_ACTIONS + ("corrigir-label", "refutar", "dev-dúvida"):
            if act == "dev-dúvida" and not has_src:
                rep["sealed"].append(f"{nid} ({act})")  # sem fonte: fica em PROD, intocado
            elif not has_src:
                refused = "source/locator/method vazio"
            elif not good_method:
                refused = "method fora das classes do contrato"
            elif act == "corrigir-label" and not new_label:
                refused = "corrigir-label sem label_final"
            elif act == "corrigir-label" and len(new_label) > LABEL_MAX:
                refused = f"label_final com {len(new_label)} caracteres > {LABEL_MAX}"
            elif act == "refutar" and status not in ("confirmed", "refuted"):
                refused = f"refutar sobre status {status}"
            else:
                if act == "corrigir-label":
                    li, old_label = _get_scalar(block, "label")
                    if li is None or old_label is None:
                        refused = "label ausente ou em bloco > |"
                    elif old_label != new_label:
                        block = block[:li] + ["    label: " + q(new_label)] + block[li + 1:]
                        block, c = _append_narrative(block, "label anterior: " + old_label)
                        if c is None:
                            refused = "narrative em bloco > |"
                        else:
                            rep["relabel"].append(nid)
                if refused is None and act == "refutar" and status == "confirmed":
                    block, c, _ = _set_field(block, "status", "confirmed", "refuted")
                    if c:
                        block, c2 = _append_narrative(block, f"refutado na {tag} (2026-10-09): {r.get('motivo', '').strip()}")
                        if c2 is None:
                            refused = "narrative em bloco > |"
                        else:
                            rep["refute"].append(nid)
                if refused is None and status == "unverifiable" and act in ("corrigir", "corrigir-label", "testemunho"):
                    if promote:
                        block, c, _ = _set_field(block, "status", "unverifiable", "confirmed")
                        if c:
                            rep["promote"].append(nid)
                    else:
                        rep["unpromoted"].append(nid)
                if refused is None:
                    block, c = _put_provenance(block, src, loc, method, lroot)
                    if c is None:
                        refused = "provenance em forma de fluxo"
                    elif c:
                        rep["prov"].append(nid)
                        if act == "dev-dúvida":
                            rep["doubt"].append(nid)
        elif act == "rebaixar":
            block, changed, cur = _set_field(block, "status", "confirmed", "unverifiable")
            if changed:
                rep["demote"].append(nid)
            elif cur != "unverifiable":
                refused = f"rebaixar sobre status {cur}"
        elif act == "dev-óbvio":
            block, changed, cur = _set_field(block, "plane", "PROD", "DEV")
            if changed:
                rep["plane"].append(nid)
            elif cur != "DEV":
                refused = f"dev-óbvio sobre plane {cur}"
            if refused is None and status == "confirmed" and "provenance" not in fields and has_src and good_method:
                block, c2 = _put_provenance(block, src, loc, method, lroot)
                if c2:
                    rep["prov"].append(nid)
        else:
            rep["sealed"].append(f"{nid} ({act})")
        if refused is not None:
            block = orig  # recusa é atômica: nada da linha é aplicado
            rep["refused"].append(f"{nid} ({refused})")
        elif block == orig and verdict in JUDGED_OK and (
                act in PROV_ACTIONS + ("rebaixar", "dev-óbvio", "corrigir-label", "refutar")
                or (act == "dev-dúvida" and has_src)):
            rep["same"].append(nid)
        out.extend(block)
        out.extend(lines[end:j])
        i = j
    rep["missing"] = sorted(set(judged) - seen)
    return "\n".join(out), rep


# ── onda O4 (2026-10-09, SAC-73): a planilha julgada traz `regra` e `locality_final` ──────────────────────
#   dev-historia             → `plane: PROD` vira `DEV` (testemunho datado sem conferência); status intocado;
#   manter-prod-medido       → fica em PROD: provenance com os *_final (method `medição: …`) e `verified_at`
#                              passa à data do --verified-at (condição do juiz: medição de hoje);
#   reescrever-source        → troca source/locator/method/locality pelos *_final; `(inalterado)` mantém o atual;
#   corrigir-method-locality → idem (a regra 3 selada: binário de versão fixa é `medição` com `host`).
#   Recusa atômica por linha: method fora das classes, locality fora de repo|web|host|pessoa, campo vazio,
#   `(inalterado)` sem provenance de onde copiar, CAMINHO ABSOLUTO DE ARQUIVO na source final, provenance em
#   fluxo, dev-historia/manter sobre plane que não é PROD, manter sem --verified-at.
O4_ACTIONS = ("dev-historia", "manter-prod-medido", "reescrever-source", "corrigir-method-locality")
O4_KEEP = re.compile(r'^\(inalterad[oa]\)$')
# ── onda O5 (2026-10-09, SAC-73): o5-juiz.csv, mesmo formato da O4, mas campo `*_final` VAZIO = inalterado ──────
#   reescrever-locator-method → troca source/locator/method/locality pelos *_final (vazio mantém o atual);
#   manter-prod-binario       → fica em PROD (plane tem de ser PROD) com a provenance dos *_final;
#   manter-dev-binario        → fica em DEV (plane tem de ser DEV, nunca muda) com a provenance dos *_final;
#   dev-sem-versao            → PROD→DEV (ou já DEV) com a provenance dos *_final.
#   Recusa atômica por linha, além das da O4: CAMINHO DE MÁQUINA (absoluto de sistema ou ~/) que sobre em source,
#   locator OU method finais (inclusive no valor mantido), e plano incompatível com a ação.
O5_ACTIONS = ("reescrever-locator-method", "manter-prod-binario", "manter-dev-binario", "dev-sem-versao")
# caminho de arquivo do host (não rota HTTP como /threads): raiz de sistema ou ~/
ABS_FS_RE = re.compile(r'(?:^|[\s"\'(=,;\[`:])(?:~/|/(?:home|etc|var|usr|tmp|opt|root|srv|boot|run|proc|sys|mnt|lib|bin|sbin|dev|snap|media)(?:/|\b))')


def _get_provenance(block):
    """O dict da provenance em bloco, None se ausente, False se em fluxo ou ilegível."""
    for n, b in enumerate(block[1:], 1):
        if re.match(r'^    provenance:[ \t]*(#.*)?$', b):
            e = n + 1
            while e < len(block) and (block[e].startswith("      ") or not block[e].strip()):
                e += 1
            try:
                cur = yaml.safe_load("\n".join(x[4:] for x in block[n:e]))["provenance"]
            except Exception:
                return False
            return cur if isinstance(cur, dict) else False
        if re.match(r'^    provenance:', b):
            return False
    return None


def _put_scalar(block, key, value):
    """`    <key>: "<value>"` no lugar (comentário preservado) ou acrescentada ao fim do bloco. (bloco, mudou?)."""
    n, cur = _get_scalar(block, key)
    if n is None:
        return block + [f"    {key}: " + q(value)], True
    if cur == value:
        return block, False
    m = re.match(r'^    [A-Za-z_][A-Za-z0-9_]*:[ \t]*(?:"[^"]*"|\'[^\']*\'|[^#]*?)([ \t]*#.*)?$', block[n])
    tail = (m.group(1) or "") if m else ""
    return block[:n] + [f"    {key}: " + q(value) + tail] + block[n + 1:], True


def _o5_row(block, r):
    """Aplica UMA linha da O5 ao bloco (campo vazio = inalterado). (bloco, chave do relatório ou None, recusa ou None)."""
    act = r["proposta_final"].strip()
    cur = _get_provenance(block)
    if cur is False:
        return block, False, "provenance em forma de fluxo"
    cur = cur or {}
    fin = {}
    for k in ("source", "locator", "method", "locality"):
        v = (r.get(k + "_final") or "").strip()
        fin[k] = v if v else cur.get(k)
    src, loc, method, locality = fin["source"], fin["locator"], fin["method"], fin["locality"]
    if not all(isinstance(x, str) and x for x in (src, loc, method)):
        return block, False, "source/locator/method vazio (nem final nem atual)"
    if not re.match(r'^(' + "|".join(METHOD_CLASSES) + r'): \S', method):
        return block, False, "method fora das classes do contrato"
    if locality is not None and locality not in LOCALITIES:
        return block, False, f"locality fora do contrato ({locality or 'vazia'})"
    for k, v in (("source", src), ("locator", loc), ("method", method)):
        if ABS_FS_RE.search(v):
            return block, False, f"caminho de máquina no {k} final"
    _, plane = _get_scalar(block, "plane")
    key = None
    if act == "manter-prod-binario" and plane != "PROD":
        return block, False, f"manter-prod-binario sobre plane {plane}"
    if act == "manter-dev-binario" and plane != "DEV":
        return block, False, f"manter-dev-binario sobre plane {plane}"
    if act == "dev-sem-versao":
        if plane == "PROD":
            block, changed, _ = _set_field(block, "plane", "PROD", "DEV")
            if not changed:
                return block, False, "dev-sem-versao: plane PROD que não sei editar por linha"
            key = "plane"
        elif plane != "DEV":
            return block, False, f"dev-sem-versao sobre plane {plane}"
    block, c = _put_provenance(block, src, loc, method, locality=locality, derive=False)
    if c is None:
        return block, False, "provenance em forma de fluxo"
    if c and key is None:
        key = "prov"
    return block, key, None


def _o4_row(block, r, verified_at):
    """Aplica UMA linha da O4 ao bloco. (bloco, chave do relatório ou None, motivo da recusa ou None)."""
    act = r["proposta_final"].strip()
    if act in O5_ACTIONS:
        return _o5_row(block, r)
    if act == "dev-historia":
        block, changed, cur = _set_field(block, "plane", "PROD", "DEV")
        if changed:
            return block, "plane", None
        return block, (None if cur == "DEV" else False), (None if cur == "DEV" else f"dev-historia sobre plane {cur}")
    src, loc, method = r["source_final"].strip(), r["locator_final"].strip(), r["method_final"].strip()
    locality = (r.get("locality_final") or "").strip()
    cur = _get_provenance(block)
    if cur is False:
        return block, False, "provenance em forma de fluxo"
    if O4_KEEP.match(src) or O4_KEEP.match(loc) or O4_KEEP.match(method):
        if not cur:
            return block, False, "(inalterado) sem provenance de onde copiar"
        src = cur.get("source", "") if O4_KEEP.match(src) else src
        loc = cur.get("locator", "") if O4_KEEP.match(loc) else loc
        method = cur.get("method", "") if O4_KEEP.match(method) else method
    if not (isinstance(src, str) and src and isinstance(loc, str) and loc and isinstance(method, str) and method):
        return block, False, "source/locator/method vazio"
    if not re.match(r'^(' + "|".join(METHOD_CLASSES) + r'): \S', method):
        return block, False, "method fora das classes do contrato"
    if locality not in LOCALITIES:
        return block, False, f"locality fora do contrato ({locality or 'vazia'})"
    if ABS_FS_RE.search(src):
        return block, False, "caminho absoluto na source final"
    if act == "manter-prod-medido":
        _, plane = _get_scalar(block, "plane")
        if plane != "PROD":
            return block, False, f"manter-prod-medido sobre plane {plane}"
        if not method.startswith("medição: "):
            return block, False, "manter-prod-medido sem method medição"
        if not verified_at:
            return block, False, "manter-prod-medido sem --verified-at"
    block, c = _put_provenance(block, src, loc, method, locality=locality)
    if c is None:
        return block, False, "provenance em forma de fluxo"
    key = "prov" if c else None
    if act == "manter-prod-medido":
        block, c2 = _put_scalar(block, "verified_at", verified_at)
        if c2:
            key = key or "verified"
    return block, key, None


def apply_judged_o4(text, judged, verified_at=None):
    """judged={id: [linhas, uma por regra]}: aplica só APROVADO/CORRIGIDO das ações O4, linha a linha (recusa atômica
    por linha: o que a linha mudou volta). Devolve (texto, relatório)."""
    lines = text.split("\n")
    rep = {"plane": [], "prov": [], "verified": [], "same": [], "rejected": [], "sealed": [], "refused": [], "missing": []}
    seen, out, in_nodes, i = set(), [], False, 0
    while i < len(lines):
        ln = lines[i]
        if re.match(r'^nodes:\s*(#.*)?$', ln):
            in_nodes = True
        elif re.match(r'^[A-Za-z_]', ln):
            in_nodes = False
        m = NODE_RE.match(ln) if in_nodes else None
        if not m or m.group(1) not in judged:
            out.append(ln); i += 1; continue
        nid, j = m.group(1), i + 1
        seen.add(nid)
        while j < len(lines) and (lines[j].startswith("    ") or not lines[j].strip() or lines[j].lstrip().startswith("#")) \
                and not NODE_RE.match(lines[j]):
            j += 1
        end = j
        while end > i + 1 and (not lines[end - 1].strip() or lines[end - 1].lstrip().startswith("#")):
            end -= 1
        block = lines[i:end]
        for r in sorted(judged[nid], key=lambda x: x["regra"]):
            act, verdict = r["proposta_final"].strip(), r["veredito"].strip()
            tag = f"{nid} [regra {r['regra']}]"
            if verdict not in JUDGED_OK:
                rep["rejected"].append(f"{tag} ({verdict})"); continue
            if act not in O4_ACTIONS + O5_ACTIONS:
                rep["sealed"].append(f"{tag} ({act})"); continue
            before = list(block)
            block, key, refused = _o4_row(block, r, verified_at)
            if refused is not None:
                block = before  # recusa atômica: nada da linha é aplicado
                rep["refused"].append(f"{tag} ({refused})")
            elif key:
                rep[key].append(tag)
            else:
                rep["same"].append(tag)
        out.extend(block)
        out.extend(lines[end:j])
        i = j
    rep["missing"] = sorted(set(judged) - seen)
    return "\n".join(out), rep


def refuted_dependents(text, ids):
    """Para cada nó refutado agora: quem ainda se apoia nele (SUPPORTS saindo dele, DEPENDS_ON entrando nele) e
    quem ele REFUTA. É o relatório da reconciliação: a gramática cobra o status do alvo de REFUTES
    (.claude/rules/kg-grammar.md), e o radar reprova a contradição; o resto é decisão de quem conhece o grafo."""
    if not ids:
        return []
    g = yaml.safe_load(text) or {}
    st = {n.get("id"): n.get("status") for n in g.get("nodes") or [] if isinstance(n, dict)}
    out = []
    for e in g.get("edges") or []:
        if not isinstance(e, dict):
            continue
        f, t, k = e.get("from"), e.get("to"), e.get("edge_type")
        if f in ids and k == "SUPPORTS":
            out.append(f"{f} SUPPORTS {t} ({st.get(t)})" + (" ← CONFIRMED APOIADO EM REFUTADO" if st.get(t) == "confirmed" else ""))
        elif f in ids and k == "REFUTES":
            out.append(f"{f} REFUTES {t} ({st.get(t)})")
        elif t in ids and k == "DEPENDS_ON":
            out.append(f"{f} ({st.get(f)}) DEPENDS_ON {t}")
    return out


def main_locality(files, check):
    """O laço do --locality: acrescenta `locality` (contrato v4.2) onde o source a determina. Prova, por grafo,
    que o YAML lido depois é IGUAL ao de antes com a chave acrescentada — e nada mais (senão rc 2, nada gravado)."""
    if not files:
        print(__doc__.strip().split("\n\n")[-1], file=sys.stderr); return 2
    pending, tot, unsure_tot = False, {k: 0 for k in LOCALITIES}, 0
    for f in files:
        try:
            text = open(f, encoding="utf-8").read()
            before = yaml.safe_load(text)
        except FileNotFoundError:
            print(f"kg-migrate-v3: {f} não existe", file=sys.stderr); return 2
        except yaml.YAMLError as e:
            print(f"kg-migrate-v3: {f} não é YAML válido ({e.__class__.__name__}) — não toco", file=sys.stderr); return 2
        new, by, unsure, flow = add_locality(text, repo_root_of(f))
        try:
            after = yaml.safe_load(new)
        except yaml.YAMLError as e:
            print(f"kg-migrate-v3: a locality em {f} daria YAML inválido ({e.__class__.__name__}) — nada gravado", file=sys.stderr); return 2
        written = {i for v in by.values() for i in v}
        for n in (after or {}).get("nodes") or []:
            if isinstance(n, dict) and n.get("id") in written and isinstance(n.get("provenance"), dict):
                n["provenance"].pop("locality", None)
        if after != before:
            print(f"kg-migrate-v3: a locality em {f} mudaria mais que a chave nova — nada gravado", file=sys.stderr); return 2
        changed = new != text
        for k in LOCALITIES:
            tot[k] += len(by[k])
        unsure_tot += len(unsure)
        verb = ("PENDENTE" if check else "aplicado") if changed else "nada a escrever"
        print(f"{f}: {verb} · " + " · ".join(f"{k} {len(by[k])}" for k in LOCALITIES)
              + f" · sem certeza (intocado) {len(unsure)}" + (f" · forma de fluxo (intocado) {len(flow)}" if flow else ""))
        if changed:
            pending = True
            if not check:
                open(f, "w", encoding="utf-8").write(new)
    print("TOTAL · " + " · ".join(f"{k} {tot[k]}" for k in LOCALITIES) + f" · sem certeza {unsure_tot}")
    return 1 if (check and pending) else 0


def main(argv):
    check = "--check" in argv
    argv = [a for a in argv if a != "--check"]
    if "--locality" in argv:
        return main_locality([a for a in argv if a != "--locality"], check)
    routing = judged = None
    if "--apply-judged" in argv:
        k = argv.index("--apply-judged")
        if k + 1 >= len(argv):
            print("kg-migrate-v3: --apply-judged pede o caminho da planilha julgada", file=sys.stderr); return 2
        if "--routing" in argv:
            print("kg-migrate-v3: --apply-judged e --routing são ondas diferentes; use um só", file=sys.stderr); return 2
        try:
            judged = load_judged(argv[k + 1])
        except BrokenInput as e:
            print(f"kg-migrate-v3: {e}", file=sys.stderr); return 2
        m = re.search(r'wave(\d+)', os.path.basename(argv[k + 1]))
        wave = m.group(1) if m else ""
        argv = argv[:k] + argv[k + 2:]
        promote = "--promote-unverifiable" in argv
        argv = [a for a in argv if a != "--promote-unverifiable"]
        vat = None
        if "--verified-at" in argv:
            k = argv.index("--verified-at")
            if k + 1 >= len(argv) or not re.match(r'^\d{4}-\d{2}-\d{2}$', argv[k + 1]):
                print("kg-migrate-v3: --verified-at pede uma data AAAA-MM-DD", file=sys.stderr); return 2
            vat = argv[k + 1]
            argv = argv[:k] + argv[k + 2:]
        if judged and isinstance(next(iter(judged.values())), list):
            return main_judged_o4(argv, judged, check, vat)
        return main_judged(argv, judged, check, promote, wave)
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
        new, rep = migrate(text, routes, gpath, root, repo_root_of(f))
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


def main_judged(files, judged, check, promote=False, wave=""):
    """O laço do --apply-judged: um grafo por vez, YAML conferido antes e depois, nada gravado em --check."""
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
        _, rows = routes_for(judged, f)
        new, rep = apply_judged(text, rows, promote, wave, repo_root_of(f))
        deps = refuted_dependents(new, set(rep["refute"]))
        try:
            yaml.safe_load(new)
        except yaml.YAMLError as e:
            print(f"kg-migrate-v3: a aplicação em {f} daria YAML inválido ({e.__class__.__name__}) — nada gravado", file=sys.stderr); return 2
        changed = new != text
        verb = ("PENDENTE" if check else "aplicado") if changed else "nada a aplicar"
        print(f"{f}: {verb} · linhas julgadas {len(rows)} · provenance escrita {len(rep['prov'])}"
              f" · label corrigido {len(rep['relabel'])} · confirmed→refuted {len(rep['refute'])}"
              f" · unverifiable→confirmed {len(rep['promote'])}"
              f" · confirmed→unverifiable {len(rep['demote'])} · PROD→DEV {len(rep['plane'])}"
              f" · já aplicado {len(rep['same'])} · REPROVADO (intocado) {len(rep['rejected'])}"
              f" · selo do maestro (intocado) {len(rep['sealed'])} · recusado {len(rep['refused'])}"
              f" · ausente do grafo {len(rep['missing'])}")
        for k, title in (("prov", "provenance escrita"), ("relabel", "label corrigido (o anterior foi para a narrative)"),
                         ("refute", "confirmed→refuted (evidência na narrative)"),
                         ("promote", "unverifiable→confirmed (selo do maestro)"),
                         ("unpromoted", "UNVERIFIABLE COM FONTE JULGADA (fica unverifiable sem --promote-unverifiable)"),
                         ("doubt", "dev-dúvida: fica em PROD com a fonte do juiz"),
                         ("demote", "confirmed→unverifiable"), ("plane", "PROD→DEV"),
                         ("rejected", "REPROVADO pelo juiz (intocado: onda de revisão)"),
                         ("sealed", "PROPOSTA QUE É SELO DO MAESTRO (intocado)"),
                         ("refused", "RECUSADO (intocado)"), ("missing", "AUSENTE DO GRAFO")):
            if rep[k]:
                print(f"  {title}: " + ", ".join(rep[k]))
        if deps:
            print("  RECONCILIAÇÃO DO REFUTADO (arestas que tocam o nó refutado): " + " · ".join(deps))
        if changed:
            pending = True
            if not check:
                open(f, "w", encoding="utf-8").write(new)
    return 1 if (check and pending) else 0


def main_judged_o4(files, judged, check, verified_at=None):
    """O laço do --apply-judged no formato O4: um grafo por vez, YAML conferido antes e depois, e a prova de que
    só os nós da planilha mudaram (senão rc 2, nada gravado)."""
    if not files:
        print(__doc__.strip().split("\n\n")[-1], file=sys.stderr); return 2
    pending, tot = False, {k: 0 for k in ("plane", "prov", "verified", "same", "rejected", "sealed", "refused", "missing")}
    for f in files:
        try:
            text = open(f, encoding="utf-8").read()
            before = yaml.safe_load(text)
        except FileNotFoundError:
            print(f"kg-migrate-v3: {f} não existe", file=sys.stderr); return 2
        except yaml.YAMLError as e:
            print(f"kg-migrate-v3: {f} não é YAML válido antes da migração ({e.__class__.__name__}) — não toco", file=sys.stderr); return 2
        _, rows = routes_for(judged, f)
        new, rep = apply_judged_o4(text, rows, verified_at)
        try:
            after = yaml.safe_load(new)
        except yaml.YAMLError as e:
            print(f"kg-migrate-v3: a aplicação em {f} daria YAML inválido ({e.__class__.__name__}) — nada gravado", file=sys.stderr); return 2
        strip = lambda g: {k: v for k, v in (g or {}).items() if k != "nodes"}
        others = lambda g: [n for n in (g or {}).get("nodes") or [] if not (isinstance(n, dict) and n.get("id") in rows)]
        if strip(after) != strip(before) or others(after) != others(before):
            print(f"kg-migrate-v3: a aplicação em {f} mudaria nó fora da planilha — nada gravado", file=sys.stderr); return 2
        changed = new != text
        verb = ("PENDENTE" if check else "aplicado") if changed else "nada a aplicar"
        print(f"{f}: {verb} · nós julgados {len(rows)} · PROD→DEV {len(rep['plane'])} · provenance escrita {len(rep['prov'])}"
              f" · só verified_at {len(rep['verified'])} · já aplicado {len(rep['same'])} · REPROVADO (intocado) {len(rep['rejected'])}"
              f" · fora das ações O4/O5 (intocado) {len(rep['sealed'])} · recusado {len(rep['refused'])} · ausente do grafo {len(rep['missing'])}")
        for k, title in (("plane", "PROD→DEV"), ("prov", "provenance escrita"), ("verified", "verified_at atualizado"),
                         ("rejected", "REPROVADO pelo juiz (intocado)"), ("sealed", "FORA DAS AÇÕES O4/O5 (intocado)"),
                         ("refused", "RECUSADO (intocado)"), ("missing", "AUSENTE DO GRAFO")):
            if rep[k]:
                print(f"  {title}: " + ", ".join(rep[k]))
        for k in tot:
            tot[k] += len(rep[k])
        if changed:
            pending = True
            if not check:
                open(f, "w", encoding="utf-8").write(new)
    print("TOTAL · " + " · ".join(f"{k} {v}" for k, v in tot.items()))
    return 1 if (check and pending) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
