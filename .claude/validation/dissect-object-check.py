#!/usr/bin/env python3
"""dissect-object-check — o checador de forma da dissecação de QUALQUER objeto (família, Etapa 0, veredito, destino).

Cobra, por comando, os 8 itens da §6 da doutrina (.claude/commands/common/prompts/dissect-doctrine.md) sobre o grafo
de UM estudo e o git log. Determinístico, sem LLM e sem rede.

  item 1  x_dissect_tool, x_dissect_family e a aresta TRACES_TO para o registro existem e concordam
  item 2  o veredito pertence aos vereditos da família; `perseguir` declara x_dissect_pursue; o veredito e o nível
          são os que o refutador sustentou, quando quem conduz os passa (--expect-verdict, --max-level)
  item 3  x_study_destination pertence ao enum (core | panorama | projeto:<slug> | projeto-novo)
  item 4  x_who_pays e x_unverified presentes
  item 5  S_STAGE0 com x_criterion cujo sha256 bate com o plano COMMITADO, plano na pasta do estudo com os 8 elementos,
          nunca reescrito depois, e commit ancestral ESTRITO do primeiro commit que traz um nó de nível 0
  item 6  parque e rejeição com superação: nó com locality, ou x_dissect_overcoming_search com where: web
  item 7  parque com x_dissect_trigger na lista branca do kg_query, lendo o que persiste, e ainda NÃO disparado
  item 8  app com N2 sem artefato aberto nem uso observado: nível máximo 1 e veredito parquear

Modos:
  dissect-object-check.py <grafo> [--stage plan|final] [--allow-uncommitted] [--expect-verdict V] [--max-level N]
      rc 0 sem achado · 1 com achado · 3 não pôde medir
      --allow-uncommitted: quem conduz confere ANTES de commitar; só stage0-nao-commitado e n0-nao-commitado deixam
      de ser achado. O gate do comando roda sem ela.
  dissect-object-check.py --context      projeção para a sessão (peça 3): famílias e estudos

ORIGEM: protótipo de um adotante de curadoria (o checador e a bancada dele), absorvido no core por
decisão do maestro de 2026-10-24, com o registro de famílias em .claude/validation/dissect-families.kg.yaml.

TETO DECLARADO: o checador confere FORMA, PERTENÇA e ORDEM no git. Se a superação de fato entrega o valor, ou se o
gatilho mede a coisa certa, é trabalho do Elenxo. O que ele não faz é executar texto vindo de um .kg.yaml: o gatilho
só roda como argumentos de uma lista branca do kg_query, sem shell. E ele só julga quem o chama: o lint não o roda
sobre o corpus, e o passo de GATE do /meta:dissect é quem o exige.
"""
import hashlib
import json
import os
import re
import subprocess
import sys

try:
    import yaml
except ImportError:  # sem PyYAML não há medição: 3, nunca 0
    print("dissect-object-check: PyYAML ausente no python3; não meço (rc 3)", file=sys.stderr)
    sys.exit(3)

REGISTRY = ".claude/validation/dissect-families.kg.yaml"
KG_QUERY = "vendor/kg-ssot/tools/kg_query.py"
KG_CRITERION = "vendor/kg-ssot/tools/kg_criterion.py"
DEST_FIXED = {"core", "panorama", "projeto-novo"}
DEST_PROJECT = re.compile(r"^projeto:[a-z0-9][a-z0-9-]*$")
PURSUE = {"estudo", "projeto-novo"}
SEALED_BY = re.compile(r"^[A-Za-z0-9._-]+:[^\s#]+#[A-Z][A-Z0-9_]*$")
N2_EVIDENCE_OK = {"artefato-aberto", "uso-observado"}
STAGE0_HEADINGS = re.compile(r"^## ([1-8])\.", re.M)
UNCOMMITTED_CODES = {"stage0-nao-commitado", "n0-nao-commitado"}
# a lista branca do gatilho: só flags de seleção do kg_query; nada que leia estado transitório
TRIGGER_FLAGS = {"--id", "--id-prefix", "--type", "--status", "--plane", "--layer", "--file", "--text",
                 "--around", "--depth", "--edge-type", "--direction"}
TRIGGER_PERSISTENT_STATUS = {"superseded", "done"}  # medido no 1º estudo do adotante: contar estado transitório fazia o gatilho nunca valer


class NotMeasured(Exception):
    """o checador não conseguiu medir: rc 3, nunca aprovação."""


def git(*args):
    r = subprocess.run(["git", *args], capture_output=True, text=True)
    return r.returncode, r.stdout


def lf_sha(data):
    return hashlib.sha256(data.replace(b"\r\n", b"\n")).hexdigest()


def load(path):
    with open(path, encoding="utf-8") as fh:
        doc = yaml.safe_load(fh)
    if not isinstance(doc, dict):
        raise ValueError("não é um mapa YAML")
    return doc


def registry_families():
    """{pref: spec} lido do registro; o id do nó vai junto para conferir a ponta da aresta, e os labels `hidden` viram
    apelidos legados (A, B, C) lidos do PRÓPRIO registro, nunca de uma tabela paralela no código. Registro sem família
    viva não é registro: rc 3, porque com ele vazio todo estudo sairia fora do registro e o defeito seria do medidor."""
    doc = load(REGISTRY)
    out, legacy = {}, {}
    for n in doc.get("nodes") or []:
        if not isinstance(n, dict):
            continue
        term, spec = n.get("x_term"), n.get("x_dissect_family_spec")
        if isinstance(term, dict) and isinstance(spec, dict) and n.get("status") != "superseded":
            pref = str(term.get("pref"))
            out[pref] = {"id": n.get("id"), **spec}
            for lab in term.get("labels") or []:
                if isinstance(lab, dict) and lab.get("kind") == "hidden" and lab.get("literal"):
                    legacy[str(lab["literal"])] = pref
    if not out:
        raise NotMeasured("o registro %s não tem nenhuma família viva (x_term + x_dissect_family_spec)" % REGISTRY)
    return out, legacy


def nodes_of(doc):
    return [n for n in (doc.get("nodes") or []) if isinstance(n, dict)]


def level_of(n):
    """o nível do nó: inteiro 0..4; None sem a chave; 'invalido' com a chave e outro valor (string, N2, bool)."""
    if "x_dissect_level" not in n:
        return None
    v = n["x_dissect_level"]
    if isinstance(v, int) and not isinstance(v, bool) and 0 <= v <= 4:
        return v
    return "invalido"


def history(path):
    """[(commit, caminho naquele commit)] do mais antigo ao mais novo, seguindo renomes."""
    if subprocess.run(["git", "rev-parse", "--verify", "-q", "HEAD"], capture_output=True).returncode != 0:
        return []  # repo sem nenhum commit: não há história, e isso é medida (nada commitado), não falha
    # --follow não segue renome junto com --reverse (limitação do git, medida em 2026-10-23): inverte aqui
    rc, out = git("log", "--follow", "--format=%H", "--name-only", "--", path)
    if rc != 0:
        raise NotMeasured("git log --follow %s falhou" % path)
    hist, cur = [], None
    for line in out.splitlines():
        line = line.strip()
        if re.fullmatch(r"[0-9a-f]{40}", line):
            cur = line
        elif line and cur:
            hist.append((cur, line))
            cur = None
    return hist[::-1]


def first_n0_commit(path):
    """o primeiro commit em que o grafo (seguindo renomes) tem um nó de nível 0, lido pelo YAML, não por regex."""
    for commit, p in history(path):
        rc, blob = git("show", "%s:%s" % (commit, p))
        if rc != 0:
            continue
        try:
            doc = yaml.safe_load(blob)
        except yaml.YAMLError:
            continue
        if isinstance(doc, dict) and any(level_of(n) in (0, "invalido") for n in nodes_of(doc)):
            return commit
    return ""


def check(path, stage, allow_uncommitted=False, expect_verdict=None, max_level=None):
    findings = []
    add = lambda item, code, detail: findings.append((item, code, detail))
    doc = load(path)
    meta = doc.get("meta") or {}
    fams, legacy = registry_families()
    nodes = nodes_of(doc)
    by_id = {n.get("id"): n for n in nodes}
    study_dir = os.path.dirname(os.path.normpath(path))

    # item 1 — família declarada, no registro, e a aresta para o mesmo termo
    tool = meta.get("x_dissect_tool")
    if not (isinstance(tool, str) and tool.strip()):
        add(1, "sem-x_dissect_tool", "meta.x_dissect_tool ausente: o censo e o --check-verdict não enxergam o estudo")
    fam = meta.get("x_dissect_family")
    fam = legacy.get(fam, fam) if isinstance(fam, str) else fam
    spec = fams.get(fam) if isinstance(fam, str) else None
    if spec is None:
        add(1, "familia-fora-do-registro", "meta.x_dissect_family=%r não é pref de família viva em %s (proposta: a família entra no registro por PR antes do N0)" % (meta.get("x_dissect_family"), REGISTRY))
    else:
        want = "%s#%s" % (REGISTRY, spec["id"])
        edges = [e for e in (doc.get("external_edges") or []) if isinstance(e, dict)]
        hit = [e for e in edges if e.get("edge_type") == "TRACES_TO" and e.get("to") == want]
        if not hit:
            other = [e.get("to") for e in edges if str(e.get("to", "")).startswith(REGISTRY + "#")]
            if other:
                add(1, "aresta-familia-discorda", "esperada external_edges TRACES_TO para %s; achadas: %s" % (want, other))
            else:
                add(1, "aresta-familia-ausente", "esperada external_edges TRACES_TO para %s; nenhuma achada" % want)

    # item 3 — destino no enum
    dest = meta.get("x_study_destination")
    if not (isinstance(dest, str) and (dest in DEST_FIXED or DEST_PROJECT.match(dest))):
        add(3, "destino-fora-do-enum", "meta.x_study_destination=%r; enum: core | panorama | projeto:<slug> | projeto-novo" % dest)

    # item 5 — nível bem formado, e a Etapa 0 pré-registrada antes do N0, pelo conteúdo commitado
    bad_levels = [n.get("id") for n in nodes if level_of(n) == "invalido"]
    if bad_levels:
        add(5, "nivel-invalido", "x_dissect_level tem de ser inteiro de 0 a 4 (sem aspas); nós: %s" % bad_levels)
    s0 = by_id.get("S_STAGE0")
    crit = s0.get("x_criterion") if isinstance(s0, dict) else None
    if not isinstance(crit, dict):
        add(5, "sem-S_STAGE0", "nó S_STAGE0 com x_criterion ausente")
    else:
        ref = os.path.normpath(str(crit.get("ref") or "")) if crit.get("ref") else ""
        want_ref = os.path.join(study_dir, "STAGE0.md")
        if ref != want_ref:
            add(5, "stage0-ref-fora-do-estudo", "x_criterion.ref=%r; exigido %s (o plano mora na pasta do estudo)" % (crit.get("ref"), want_ref))
        elif not os.path.isfile(ref):
            add(5, "stage0-ref-ausente", "%s não existe na árvore" % ref)
        else:
            plan_check(add, path, ref, crit, allow_uncommitted, stage)

    if stage == "plan":
        return findings

    # item 4 — quem paga e o que não foi verificado
    if not (isinstance(meta.get("x_who_pays"), str) and meta["x_who_pays"].strip()):
        add(4, "sem-x_who_pays", "meta.x_who_pays ausente ou vazio (quem paga e se abre via de bilhetagem)")
    if not isinstance(meta.get("x_unverified"), list):
        add(4, "sem-x_unverified", "meta.x_unverified ausente: a lista do que não foi verificado (vazia vale, ausente não)")

    # item 2 — um veredito, do vocabulário da família, e o que o Elenxo sustentou
    vnodes = [n for n in nodes if n.get("x_dissect_verdict") is not None]
    # o modo estudo do core (§1b da doutrina) para no N2 SEM veredito: a família, a Etapa 0, o destino, quem paga e o
    # não verificado seguem cobrados; veredito ali é o estudo decidindo, e o censo já o chama de INCOERENTE
    if meta.get("x_dissect_mode") == "study":
        if vnodes:
            add(2, "estudo-com-veredito", "meta.x_dissect_mode: study não emite veredito; achado em %s" % [n.get("id") for n in vnodes])
        return findings
    if len(vnodes) != 1:
        if vnodes:
            add(2, "veredito-duplicado", "%d nós com x_dissect_verdict; exigido 1" % len(vnodes))
        else:
            add(2, "veredito-ausente", "nenhum nó com x_dissect_verdict; exigido 1")
        return findings
    vn = vnodes[0]
    verdict = str(vn.get("x_dissect_verdict"))
    # o veredito mora no nó de decisão, e ele nasce open (o estudo não sela; ele registra o selo do destino)
    if vn.get("node_type") != "decision" or vn.get("id") == "S_STAGE0":
        add(2, "veredito-fora-de-decisao", "x_dissect_verdict está em %s (node_type %s); exigido o nó D_ de decisão" % (vn.get("id"), vn.get("node_type")))
    # o destino sela no repo DELE; o estudo só registra que selou: status done com x_dissect_sealed_by apontando o nó
    # do selo (<repo>:<caminho>#<ID>, ponteiro opaco: o checador não lê outro repo). Fechado sem ponteiro segue reprovado.
    sealed_by = vn.get("x_dissect_sealed_by")
    seal_ok = isinstance(sealed_by, str) and bool(SEALED_BY.match(sealed_by))
    if sealed_by is not None and not seal_ok:
        add(2, "selo-mal-formado", "x_dissect_sealed_by=%r; exigido <repo>:<caminho>#<ID_DO_NO>" % (sealed_by,))
    if vn.get("status") != "open" and not (vn.get("status") == "done" and seal_ok):
        add(2, "veredito-selado", "o nó do veredito %s está %s; ele nasce open e só fecha com x_dissect_sealed_by apontando o selo do destino" % (vn.get("id"), vn.get("status")))
    if spec is not None and verdict not in (spec.get("verdicts") or []):
        add(2, "veredito-fora-da-familia", "%s não está nos vereditos de %s: %s" % (verdict, fam, spec.get("verdicts")))
    if verdict == "perseguir" and vn.get("x_dissect_pursue") not in PURSUE:
        add(2, "perseguir-sem-saida", "x_dissect_pursue=%r; exigido estudo | projeto-novo" % vn.get("x_dissect_pursue"))
    if expect_verdict is not None and verdict != expect_verdict:
        add(2, "veredito-diverge-do-elenxo", "o grafo diz %s; o Elenxo sustentou %s (o escritor não troca o veredito)" % (verdict, expect_verdict))
    levels = [level_of(n) for n in nodes if isinstance(level_of(n), int)]
    if max_level is not None and levels and max(levels) > max_level:
        add(2, "nivel-acima-do-sustentado", "o grafo chega ao N%d; o Elenxo sustentou até o N%d" % (max(levels), max_level))

    # item 6 — negativo com superação; quando nenhuma, a busca saiu do repo
    if verdict in ("parquear", "rejeitar"):
        ov = vn.get("x_dissect_overcoming")
        if ov is None:
            add(6, "sem-x_dissect_overcoming", "veredito %s sem x_dissect_overcoming (id de nó ou nenhuma)" % verdict)
        elif ov == "nenhuma":
            search = vn.get("x_dissect_overcoming_search")
            items = [s for s in search if isinstance(s, dict)] if isinstance(search, list) else []
            bad = [s for s in items if s.get("where") not in ("corpus", "web") or not (s.get("cmd") or s.get("source"))]
            if not items or bad:
                add(6, "busca-mal-formada", "x_dissect_overcoming_search exige itens {where: corpus|web, cmd|source}")
            elif not any(s.get("where") == "web" for s in items):
                add(6, "busca-sem-web", "superação nenhuma sem busca where: web (o 1º estudo do adotante não achou a alternativa por buscar só no repo)")
        else:
            target = by_id.get(ov)
            prov = (target or {}).get("provenance") if isinstance(target, dict) else None
            loc = prov.get("locality") if isinstance(prov, dict) else None
            if target is None:
                add(6, "superacao-id-invalido", "x_dissect_overcoming=%r não é nó deste grafo" % ov)
            elif loc not in ("web", "repo"):
                add(6, "superacao-sem-locality", "o nó %s não declara provenance.locality web|repo" % ov)

    # item 7 — o parque tem gatilho que lê o que persiste, e ele ainda não disparou
    if verdict == "parquear":
        trigger_check(add, vn.get("x_dissect_trigger"), path, by_id)

    # item 8 — app sem artefato no N2 fica no nível 1 e só parqueia
    if fam == "app":
        with_art = []
        for n in nodes:
            if level_of(n) != 2 or n.get("x_dissect_n2_evidence") not in N2_EVIDENCE_OK:
                continue
            if n.get("x_dissect_n2_evidence") == "uso-observado":
                proto = os.path.normpath(str(n.get("trace") or ""))
                tracked = subprocess.run(["git", "ls-files", "--error-unmatch", proto], capture_output=True).returncode == 0
                if not (os.path.dirname(proto) == study_dir and os.path.basename(proto).startswith("PROTOCOL") and proto.endswith(".md") and tracked):
                    add(8, "uso-observado-sem-protocolo", "%s declara uso observado; o trace tem de ser um PROTOCOL*.md rastreado na pasta do estudo (achado: %r)" % (n.get("id"), n.get("trace")))
                    continue
            with_art.append(n)
        if not with_art:
            deep = sorted({lv for lv in levels if lv >= 2})
            if deep:
                add(8, "app-acima-do-nivel-1", "N2 sem artefato aberto nem uso observado; nós nos níveis %s" % deep)
            if verdict != "parquear":
                add(8, "app-sem-artefato-veredito", "N2 sem artefato limita o veredito a parquear; achado %s" % verdict)
    return findings


def plan_check(add, path, ref, crit, allow_uncommitted, stage):
    """item 5 pelo git: o plano commitado é o que o sha256 registra, ninguém o reescreveu, e veio antes do N0."""
    with open(ref, "rb") as fh:
        live = fh.read()
    r = subprocess.run([sys.executable, KG_CRITERION, "check", "--format", "json", path], capture_output=True, text=True)
    try:
        out = json.loads(r.stdout)
    except ValueError:
        raise NotMeasured("kg_criterion check não devolveu JSON (rc %s): %s" % (r.returncode, r.stderr.strip()[:200]))
    for f in out.get("findings") or []:
        if f.get("id") == "S_STAGE0":
            add(5, "stage0-" + str(f.get("code", "")).split(".")[-1], str(f.get("detail", ""))[:240])
    heads = set(STAGE0_HEADINGS.findall(live.decode("utf-8", "replace")))
    if len(heads) != 8:
        add(5, "stage0-sem-8-elementos", "%s tem os títulos ## 1. a ## 8. em %d de 8" % (ref, len(heads)))
    hist = history(ref)
    nodes_now = nodes_of(load(path))
    has_n0 = any(level_of(n) == 0 for n in nodes_now)
    if stage == "final" and not has_n0:
        add(5, "sem-n0", "estudo final sem nenhum nó x_dissect_level: 0: a escada não começou")
    if not hist:
        if not allow_uncommitted:
            add(5, "stage0-nao-commitado", "%s não tem commit: o plano tem de estar no git antes do N0" % ref)
        n0 = first_n0_commit(path)  # a flag perdoa o plano ainda não commitado, nunca um N0 que já entrou antes dele
        if n0:
            add(5, "stage0-depois-do-n0", "o N0 já está no commit %s e o plano ainda não tem commit" % n0[:12])
        return
    stage_commit, stage_path = hist[0]
    rc, blob = git("show", "%s:%s" % (stage_commit, stage_path))
    if lf_sha(blob.encode("utf-8")) != str(crit.get("sha256")):
        add(5, "stage0-sha-do-commit", "o sha256 registrado não é o do plano no commit %s (%s)" % (stage_commit[:12], stage_path))
    base = lf_sha(blob.encode("utf-8"))
    later = []
    for c, pth in hist[1:]:  # renome sem mudar o conteúdo não é reescrita; mudar o conteúdo é
        rc_c, b = git("show", "%s:%s" % (c, pth))
        if rc_c != 0 or lf_sha(b.encode("utf-8")) != base:
            later.append(c)
    if later:
        add(5, "stage0-reescrito", "o plano mudou em %d commit(s) depois de %s: emenda é versão nova do critério (amends), não reescrita" % (len(later), stage_commit[:12]))
    if git("status", "--porcelain", "--", ref)[1].strip():
        add(5, "stage0-editado", "%s mudou na árvore depois do commit %s" % (ref, stage_commit[:12]))
    n0 = first_n0_commit(path)
    if n0:
        if n0 == stage_commit:
            add(5, "stage0-mesmo-commit-do-n0", "o plano e o primeiro N0 entraram no mesmo commit %s: ancestral ESTRITO exigido" % n0[:12])
        elif subprocess.run(["git", "merge-base", "--is-ancestor", stage_commit, n0]).returncode != 0:
            add(5, "stage0-depois-do-n0", "o commit do plano %s não é ancestral do primeiro N0 %s" % (stage_commit[:12], n0[:12]))
    elif has_n0 and not allow_uncommitted:
        add(5, "n0-nao-commitado", "o grafo tem N0 na árvore e nenhum commit com ele: commite e rode de novo")


def trigger_check(add, trig, path, by_id):
    args = trig.get("kg_query") if isinstance(trig, dict) else None
    mc = trig.get("min_count") if isinstance(trig, dict) else None
    if not (isinstance(args, list) and args and all(isinstance(a, str) for a in args)
            and isinstance(mc, int) and not isinstance(mc, bool) and mc >= 1):
        add(7, "gatilho-mal-formado", "x_dissect_trigger exige {kg_query: [flags…], min_count: inteiro ≥ 1}")
        return
    why = trigger_whitelist(args)
    if why:
        add(7, "gatilho-fora-da-lista-branca", why)
        return
    # a âncora do --around é um nó DESTE grafo, que existe; noutro grafo, o parque reabriria
    # por superação alheia, e um nó inexistente fazia o kg_query sair rc 2 (o checador lia "não mediu")
    if "--around" in args[0::2]:
        anchor = args[args[0::2].index("--around") * 2 + 1]
        apath, _, aid = anchor.rpartition("#")
        if (apath and os.path.normpath(apath) != os.path.normpath(path)) or aid not in by_id:
            add(7, "gatilho-ancora-fora-do-estudo", "--around %s: a âncora tem de ser um nó existente deste grafo (%s#<id>)" % (anchor, path))
            return
    # a seleção, sem o filtro de status, tem de casar ao menos um nó; senão o gatilho nunca dispararia
    sel = []
    for i in range(0, len(args), 2):
        if args[i] != "--status":
            sel += args[i:i + 2]
    if sel and not query_total(sel, allow_broken=True):
        add(7, "gatilho-selecao-vazia", "a seleção %s não casa nenhum nó do corpus: o gatilho nunca dispararia" % sel)
        return
    total = query_total(args)
    if total >= mc:
        add(7, "gatilho-ja-disparou", "kg_query deu %d ≥ min_count %d: o parque não se sustenta ao selar" % (total, mc))


def query_total(args, allow_broken=False):
    """o total da consulta. O kg_query lê os grafos RASTREADOS (git ls-files): o estudo tem de estar ao menos no índice
    (git add) para o gatilho ancorado nele casar; a doutrina manda commitar o grafo junto com o plano.
    Com allow_broken, entrada que o kg_query recusa (rc 2, BROKEN INPUT) conta como seleção vazia, não como 'não mediu'."""
    r = subprocess.run([sys.executable, KG_QUERY, "--root", ".", *args, "--format", "json"], capture_output=True, text=True)
    try:
        return int(json.loads(r.stdout).get("total"))
    except (ValueError, TypeError, AttributeError):
        if allow_broken and r.returncode == 2:
            return 0
        raise NotMeasured("kg_query rc %s sem total legível: %s" % (r.returncode, r.stderr.strip()[:200]))


def trigger_whitelist(args):
    if len(args) % 2:
        return "flags e valores em pares; achados %d itens" % len(args)
    persistent = False
    flags = args[0::2]
    for i in range(0, len(args), 2):
        flag, val = args[i], args[i + 1]
        if flag not in TRIGGER_FLAGS:
            return "flag %r fora da lista branca %s" % (flag, sorted(TRIGGER_FLAGS))
        if val.startswith("-"):
            return "valor %r de %s parece flag" % (val, flag)
        if flag == "--status":
            if val not in TRIGGER_PERSISTENT_STATUS:
                return "--status %s lê estado transitório; o gatilho lê o que persiste (%s)" % (val, ", ".join(sorted(TRIGGER_PERSISTENT_STATUS)))
            persistent = True
        if flag == "--edge-type" and val == "SUPERSEDES" and "--around" in flags:
            persistent = True  # sem --around o kg_query ignora --edge-type (medido: o total não muda)
        # com --around, o total só cresce pela superação se a vizinhança alcança quem supera
        # (profundidade ≥ 1, direção in ou both) e se nenhuma outra aresta conta (CONSTRAINS é a do refutador)
        if flag == "--edge-type" and "--around" in flags and val != "SUPERSEDES":
            return "--edge-type %s junto do --around conta o que não persiste; com --around, só SUPERSEDES" % val
        if flag == "--depth" and not (val.isdigit() and int(val) >= 1):
            return "--depth %s congela o total (a vizinhança não alcança quem supera); exigido inteiro ≥ 1" % val
        if flag == "--direction" and val not in ("in", "both"):
            return "--direction %s não vê quem supera a âncora (a aresta SUPERSEDES chega nela); exigido in ou both" % val
    if not persistent:
        return "o gatilho não lê o que persiste: exija --status superseded|done ou --around <id> --edge-type SUPERSEDES"
    return ""


def context():
    fams, legacy = registry_families()
    print("# famílias da dissecação (registro %s) · %d viva(s)" % (REGISTRY, len(fams)))
    print("família | vereditos | destino padrão | N2 prova")
    for pref, s in sorted(fams.items()):
        print("%s | %s | %s | %s" % (pref, " · ".join(s.get("verdicts") or []), s.get("default_destination") or "(Etapa 0)",
                                       str((s.get("levels") or {}).get("N2", ""))[:90]))
    rc, files = git("ls-files", "*.kg.yaml")
    rows = []
    for f in files.splitlines():
        if "/fixtures/" in f or f.startswith("vendor/") or f == REGISTRY:
            continue
        try:
            doc = load(f)
        except Exception:
            continue
        meta = doc.get("meta") or {}
        if not meta.get("x_dissect_tool"):
            continue
        verdict = next((str(n.get("x_dissect_verdict")) for n in nodes_of(doc) if n.get("x_dissect_verdict") is not None), "—")
        fam = meta.get("x_dissect_family")
        k3 = "anterior"
        if meta.get("x_study_destination") is not None:  # o marcador de estudo v4; família legada sem ele fica fora
            try:
                n = len(check(f, "final"))
                k3 = "ok" if n == 0 else "%d achado(s)" % n
            except Exception as exc:  # um grafo que o checador não lê não derruba a projeção inteira
                k3 = "não medido (%s)" % str(exc)[:60]
        rows.append((f, meta.get("x_dissect_tool"), (legacy.get(fam, fam) if isinstance(fam, str) else fam) or "(sem família)", meta.get("x_study_destination") or "—", verdict, k3))
    print("\n# estudos de dissecação no corpus · %d" % len(rows))
    print("objeto | família | destino | veredito | forma | grafo")
    for f, tool, fam, dest, verdict, k3 in rows:
        print("%s | %s | %s | %s | %s | %s" % (tool, fam, dest, verdict, k3, f))
    print("\n(o checador só julga estudo por família, o que declara x_study_destination: o anterior a 2026-10-24 fica fora por desenho, e o checador direto")
    print(" sobre ele lista o que falta para migrar. Presença, pertença e ordem no git, não qualidade.)")
    return 0


def main(argv):
    if not os.path.isfile(REGISTRY):
        print("dissect-object-check: registro %s ausente; rode na raiz do repo (rc 3)" % REGISTRY, file=sys.stderr)
        return 3
    if argv[:1] == ["--context"]:
        try:
            return context()
        except (NotMeasured, OSError, ValueError, yaml.YAMLError) as exc:
            print("dissect-object-check: não medi o contexto: %s (rc 3)" % exc, file=sys.stderr)
            return 3
    opts = {"stage": "final", "allow": False, "verdict": None, "level": None}
    rest = []
    i = 0
    try:
        while i < len(argv):
            a = argv[i]
            if a == "--stage":
                opts["stage"] = argv[i + 1]; i += 2
            elif a == "--allow-uncommitted":
                opts["allow"] = True; i += 1
            elif a == "--expect-verdict":
                opts["verdict"] = argv[i + 1]; i += 2
            elif a == "--max-level":
                opts["level"] = int(argv[i + 1]); i += 2
            else:
                rest.append(a); i += 1
    except (IndexError, ValueError):
        rest = []
    if opts["stage"] not in ("plan", "final") or len(rest) != 1:
        print("uso: dissect-object-check.py <grafo> [--stage plan|final] [--allow-uncommitted] [--expect-verdict V] [--max-level N] | --context", file=sys.stderr)
        return 3
    path = os.path.relpath(os.path.abspath(rest[0]))
    try:
        findings = check(path, opts["stage"], opts["allow"], opts["verdict"], opts["level"])
    except NotMeasured as exc:
        print("dissect-object-check: não medi: %s (rc 3)" % exc, file=sys.stderr)
        return 3
    except Exception as exc:  # grafo ilegível não é aprovação
        print("dissect-object-check: %s ilegível: %s (rc 3)" % (rest[0], exc), file=sys.stderr)
        return 3
    for item, code, detail in findings:
        print("item %d %s: %s" % (item, code, detail))
    print("dissect-object-check: %s · stage %s · %d achado(s)" % (path, opts["stage"], len(findings)))
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
