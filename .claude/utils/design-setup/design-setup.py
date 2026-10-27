#!/usr/bin/env python3
"""design-setup.py — o motor determinístico do /design:setup (onda 1 do setup de design, 2026-10-27).

Planeja e, só com --apply, grava o design-context mínimo de um projeto a partir do brief que JÁ existe:
  · o brief (`<design>/brief.md`): MANTER se existe; stub mínimo só com --create-brief (a confirmação é do
    comando, que pergunta antes);
  · os tokens W3C DTCG (foundations, semantic, governance/contrast-pairs.json): criados só quando ausentes, a
    partir da cor da marca; presentes, são LIDOS (a marca vem do alias de color.action.primary);
  · o grafo do design-context (`<design>/design-context.kg.yaml`): criado só quando ausente, com as ligações
    por external_edges aos grafos do business-context e do technical-context quando o nó-alvo existe; sem
    alvo, um nó `question` aberto declara a falta (nunca inventa a ligação).
NUNCA sobrescreve: arquivo que existe é MANTER, e a única escrita num arquivo existente é o frontmatter do
brief, e só com --add-frontmatter e só quando o brief não tem frontmatter nenhum. Reexecutar não duplica nada.

O contraste do CTA é CALCULADO (WCAG 2.x): o texto sobre a cor de ação tem de chegar a 4,5:1 com branco ou
com quase preto; se nenhum chega, a ação usa um tom mais escuro da marca e a cor original vira acento. O gate
lint-design-tokens.sh re-mede depois de gravar e decide.

Tudo local: nenhum serviço externo, nenhuma rede.

Uso (pelo design-setup.sh): python3 -I -B design-setup.py --root R --design-dir D --business-dir B
       --technical-dir T [--brand '#RRGGBB'] [--audience TXT] [--tone TXT] [--theme-target auto|css-vars|
       tailwind|shadcn|none] [--create-brief] [--add-frontmatter] [--apply] [--today AAAA-MM-DD]
rc: 0 plano ou aplicação feita · 2 uso ou entrada quebrada · 3 precisa de confirmação ou de dado (brief
    ausente sem --create-brief; tokens ausentes sem --brand). O rc do gate é do design-setup.sh.
"""
import argparse
import datetime
import json
import os
import re
import sys

NEAR_BLACK = "#171717"
WHITE = "#FFFFFF"
MIN = 4.5
NEUTRAL = {"0": "#FFFFFF", "50": "#F7F7F7", "100": "#EDEDED", "300": "#C7C7C7",
           "500": "#8A8A8A", "700": "#4A4A4A", "900": NEAR_BLACK}
SKIP_DIRS = {".git", "node_modules", "vendor", "dist", "build", ".next", ".claude", "docs"}


# ── contraste WCAG ────────────────────────────────────────────────────────────────────────────────────
def _rgb(h):
    h = h.lstrip("#")
    if not re.fullmatch(r"[0-9A-Fa-f]{6}", h):
        raise ValueError(h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def _lum(h):
    def ch(c):
        c = c / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (ch(c) for c in _rgb(h))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(a, b):
    la, lb = sorted((_lum(a), _lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def darker(h, step):
    return "#" + "".join(f"{max(0, round(c * (1 - step))):02X}" for c in _rgb(h))


def cta_choice(brand, near_black):
    """(cor de ação, cor do texto, razão, escureceu?) — texto branco ou quase preto, o que der mais."""
    rw, rb = ratio(brand, WHITE), ratio(brand, near_black)
    if max(rw, rb) >= MIN:
        return (brand, WHITE, rw, False) if rw >= rb else (brand, near_black, rb, False)
    for i in range(1, 101):
        cand = darker(brand, i / 100)
        if ratio(cand, WHITE) >= MIN:
            return cand, WHITE, ratio(cand, WHITE), True
    return "#000000", WHITE, ratio("#000000", WHITE), True


# ── leitura de tokens existentes ──────────────────────────────────────────────────────────────────────
def load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def get_path(doc, dotted):
    cur = doc
    for k in dotted.split("."):
        if not isinstance(cur, dict) or k not in cur:
            return None
        cur = cur[k]
    return cur


def resolve_value(docs, dotted, depth=0):
    if depth > 10:
        return None
    for d in docs:
        tok = get_path(d, dotted)
        if isinstance(tok, dict) and "$value" in tok:
            v = tok["$value"]
            m = re.fullmatch(r"\{([^}]+)\}", v) if isinstance(v, str) else None
            return resolve_value(docs, m.group(1), depth + 1) if m else v
    return None


def alias_of(doc, dotted):
    tok = get_path(doc, dotted)
    if isinstance(tok, dict) and isinstance(tok.get("$value"), str):
        m = re.fullmatch(r"\{([^}]+)\}", tok["$value"])
        return m.group(1) if m else None
    return None


def pointer(dotted):
    return "#/" + "/".join(k.replace("~", "~0").replace("/", "~1") for k in dotted.split("."))


# ── detecção do alvo de tema ──────────────────────────────────────────────────────────────────────────
def detect_theme(root):
    if os.path.isfile(os.path.join(root, "components.json")):
        return "shadcn", "components.json"
    for name in sorted(os.listdir(root)):
        if name.startswith("tailwind.config."):
            return "tailwind", name
    css, pkg = None, os.path.isfile(os.path.join(root, "package.json"))
    for dirpath, dirnames, files in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS and not d.startswith("."))
        files = sorted(files)
        if dirpath.count(os.sep) - root.count(os.sep) > 4:
            dirnames[:] = []
        for f in files:
            if f.endswith(".css"):
                rel = os.path.relpath(os.path.join(dirpath, f), root)
                try:
                    with open(os.path.join(dirpath, f), encoding="utf-8", errors="replace") as fh:
                        if "@theme" in fh.read(200000):
                            return "tailwind", rel
                except OSError:
                    pass
                css = css or rel
    if css:
        return "css-vars", css
    if pkg:
        return "css-vars", "package.json"
    return "none", ""


# ── grafos vizinhos ───────────────────────────────────────────────────────────────────────────────────
def find_node(root, ctx_dir, node_id):
    """O 1º .kg.yaml da pasta do contexto que tem o nó `node_id` → caminho relativo, ou None."""
    base = os.path.join(root, ctx_dir)
    if not os.path.isdir(base):
        return None
    pat = re.compile(r"^\s*-\s*id:\s*[\"']?" + re.escape(node_id) + r"[\"']?\s*$", re.M)
    for name in sorted(os.listdir(base)):
        if name.endswith(".kg.yaml"):
            try:
                with open(os.path.join(base, name), encoding="utf-8") as fh:
                    if pat.search(fh.read()):
                        return f"{ctx_dir}/{name}"
            except OSError:
                pass
    return None


# ── emissão ───────────────────────────────────────────────────────────────────────────────────────────
def q(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


def node_yaml(n):
    out = [f"  - id: {n['id']}"]
    for k in ("node_type", "layer", "plane", "status", "impact", "confidence"):
        out.append(f"    {k}: {n[k]}")
    for k in ("label", "narrative", "trace", "verified_at", "verified_against", "x_missing_context"):
        if n.get(k):
            out.append(f"    {k}: {q(n[k])}")
    if n.get("provenance"):
        out.append("    provenance:")
        for k in ("source", "locator", "method", "locality"):
            if n["provenance"].get(k):
                out.append(f"      {k}: {q(n['provenance'][k])}")
    return "\n".join(out)


def build_graph(a, t):
    D, today = a.design_dir, a.today
    found = f"{D}/foundations/color.tokens.json"
    sem = f"{D}/semantic/color.tokens.json"
    pairs = f"{D}/governance/contrast-pairs.json"
    brief = f"{D}/brief.md"
    read = lambda src, loc, what: {"source": src, "locator": loc, "method": f"reading: {what}", "locality": "repo"}
    cta_ok = t["cta_ratio"] >= MIN
    nodes = [
        dict(id="C_BRIEF", node_type="claim", layer="audit", plane="DEV", status="confirmed", impact=4,
             confidence=0.7, label="O brief do design: a intenção da marca, o público e o tom, de onde os tokens derivam.",
             trace=brief, verified_at=today, verified_against=brief,
             provenance=read(brief, "o arquivo inteiro", "o brief escrito à mão")),
        dict(id="E_BRAND", node_type="entity", layer="domain", plane="DEV", status="confirmed", impact=4,
             confidence=0.8, label=f"A marca do projeto: a cor primária {t['brand']} nos tokens W3C DTCG.",
             trace=t["brand_file"], verified_at=today, verified_against=t["brand_file"],
             provenance=read(t["brand_file"], pointer(t["brand_token"]), "os tokens W3C DTCG")),
        dict(id="E_TOKEN_ACTION_PRIMARY", node_type="entity", layer="domain", plane="DEV", status="confirmed",
             impact=4, confidence=0.8, label=f"O token da ação primária (CTA): {t['action']}.",
             trace=sem, verified_at=today, verified_against=sem,
             provenance=read(sem, pointer("color.action.primary"), "os tokens W3C DTCG")),
        dict(id="E_TOKEN_ON_PRIMARY", node_type="entity", layer="domain", plane="DEV", status="confirmed",
             impact=4, confidence=0.8, label=f"O token do texto sobre a ação primária: {t['on']}.",
             trace=sem, verified_at=today, verified_against=sem,
             provenance=read(sem, pointer("color.action.on-primary"), "os tokens W3C DTCG")),
        dict(id="A_TOKENS_FOUNDATIONS", node_type="artifact", layer="audit", plane="DEV", status="open", impact=3,
             confidence=0.8, label="O arquivo dos primitivos de cor (foundations), valores crus em W3C DTCG.", trace=found),
        dict(id="A_TOKENS_SEMANTIC", node_type="artifact", layer="audit", plane="DEV", status="open", impact=3,
             confidence=0.8, label="O arquivo dos papéis de cor (semantic), que referenciam as foundations por alias.", trace=sem),
        dict(id="I_CONTRAST_CTA", node_type="invariant", layer="domain", plane="DEV",
             status="confirmed" if cta_ok else "open", impact=5, confidence=0.9 if cta_ok else 0.4,
             label=f"O texto do CTA tem contraste de pelo menos 4,5:1 sobre a cor de ação (medido: {t['cta_ratio']:.2f}:1).",
             trace=pairs, verified_at=today if cta_ok else "", verified_against=pairs if cta_ok else "",
             provenance={"source": pairs, "locator": "o par color.action.on-primary sobre color.action.primary",
                         "method": "measurement: razão WCAG 2.x calculada pelo design-setup; o lint-design-tokens.sh re-mede",
                         "locality": "repo"} if cta_ok else None),
        dict(id="ST_THEME", node_type="state", layer="domain", plane="DEV", status="open", impact=3, confidence=0.6,
             label=f"O tema do projeto no modo claro, com alvo de materialização {t['target']}"
                   + (f" (detectado por {t['target_src']})." if t["target_src"] else " (nenhum alvo detectado)."),
             trace=t["target_src"] if t["target_src"] and t["target_src"] != "package.json" else ""),
        dict(id="P_BRAND_USE", node_type="policy", layer="domain", plane="DEV", status="open", impact=3, confidence=0.6,
             label="Uso da marca: só a cor de ação marca o CTA; o acento nunca concorre com ela"
                   + ("; a cor original da marca fica como acento, porque a ação usa um tom mais escuro." if t["darkened"] else ".")),
        dict(id="D_PALETTE", node_type="decision", layer="audit", plane="DEV", status="open", impact=4, confidence=0.5,
             label="A escolha da paleta da marca, que espera o selo do maestro."),
    ]
    edges = [("E_BRAND", "C_BRIEF", "TRACES_TO"), ("D_PALETTE", "E_BRAND", "TRACES_TO"),
             ("E_TOKEN_ACTION_PRIMARY", "E_BRAND", "DEPENDS_ON"), ("A_TOKENS_FOUNDATIONS", "E_BRAND", "TRACES_TO"),
             ("A_TOKENS_SEMANTIC", "E_TOKEN_ACTION_PRIMARY", "TRACES_TO"), ("A_TOKENS_SEMANTIC", "E_TOKEN_ON_PRIMARY", "TRACES_TO"),
             ("I_CONTRAST_CTA", "E_TOKEN_ACTION_PRIMARY", "CONSTRAINS"), ("I_CONTRAST_CTA", "E_TOKEN_ON_PRIMARY", "CONSTRAINS"),
             ("E_BRAND", "ST_THEME", "HAS_STATE"), ("ST_THEME", "D_PALETTE", "TRACES_TO"),
             ("P_BRAND_USE", "E_BRAND", "CONSTRAINS"), ("P_BRAND_USE", "C_BRIEF", "TRACES_TO")]
    ext = []
    if t["biz_pos"]:
        ext.append(("C_BRIEF", f"{t['biz_pos']}#E_POSITIONING", "TRACES_TO"))
        if t["biz_aud"]:
            ext.append(("C_BRIEF", f"{t['biz_aud']}#E_AUDIENCE", "TRACES_TO"))
    else:
        nodes.append(dict(id="Q_MISSING_POSITIONING", node_type="question", layer="audit", plane="DEV", status="open",
                          impact=3, confidence=0.5, x_missing_context="business-context",
                          label="Falta o posicionamento: o brief foi escrito sem um grafo do business-context com E_POSITIONING."))
        edges.append(("Q_MISSING_POSITIONING", "C_BRIEF", "CONSTRAINS"))
    if t["tech_theme"]:
        ext.append(("I_CONTRAST_CTA", f"{t['tech_theme']}#ST_THEME_APPLIED", "CONSTRAINS"))
    else:
        nodes.append(dict(id="Q_MISSING_THEME_APPLIED", node_type="question", layer="audit", plane="DEV", status="open",
                          impact=2, confidence=0.5, x_missing_context="technical-context",
                          label="Falta o tema aplicado: nenhum grafo do technical-context tem ST_THEME_APPLIED para o contraste restringir."))
        edges.append(("Q_MISSING_THEME_APPLIED", "I_CONTRAST_CTA", "CONSTRAINS"))
    head = ("# Grafo do design-context, gerado pelo /design:setup (design-setup.py). O brief.md segue escrito à mão,\n"
            "# com projection_of apontando este arquivo. Editar à mão é permitido; o setup nunca o sobrescreve.\n")
    meta = (f"meta:\n  id: design-context\n  schema_version: \"1\"\n  baseline: {q(today)}\n"
            f"  review_after: {q(t['review_after'])}\n")
    body = "nodes:\n" + "\n".join(node_yaml(n) for n in nodes) + "\nedges:\n"
    body += "\n".join(f"  - from: {f}\n    to: {to}\n    edge_type: {e}" for f, to, e in edges) + "\n"
    if ext:
        body += "external_edges:\n" + "\n".join(f"  - from: {f}\n    to: {q(to)}\n    edge_type: {e}" for f, to, e in ext) + "\n"
    return head + meta + body


def brief_stub(a, t):
    return (f"---\nprojection_of: {a.design_dir}/design-context.kg.yaml\nreview_after: \"{t['review_after']}\"\n"
            f"date: {a.today}\n---\n\n# Brief de Identidade Visual — {t['project']}\n\n"
            "> Intenção declarada que ancora os tokens. O nó `C_BRIEF` do grafo o representa.\n\n"
            "## Personalidade da marca\n\n<a preencher: três a quatro adjetivos>\n\n"
            f"## Público\n\n{a.audience or '<a preencher: lido do business-context, ou perguntado>'}\n\n"
            f"## Tom e restrições\n\n- **Tom:** {a.tone or '<a preencher>'}\n"
            "- **Acessibilidade:** WCAG AA, 4,5:1 em todo par texto/fundo declarado (gate `lint-design-tokens.sh`)\n\n"
            f"## Cor de marca\n\n| Papel | Cor |\n|---|---|\n| Primária (ação) | `{t['action']}` |\n"
            + (f"| Acento (cor original da marca) | `{t['brand']}` |\n" if t["darkened"] else "")
            + f"| Texto sobre a ação | `{t['on']}` ({t['cta_ratio']:.2f}:1) |\n")


def new_tokens(t):
    brand = {"primary": {"$value": t["brand"], "$description": "Cor primária da marca."}}
    if t["darkened"]:
        brand["primary-strong"] = {"$value": t["action"],
                                   "$description": "Tom mais escuro da marca, para o CTA chegar a 4,5:1 com texto branco."}
    found = {"$schema": "https://design-tokens.github.io/community-group/format/",
             "$description": "Foundations: primitivos de cor, valores crus (gerado pelo /design:setup). W3C DTCG.",
             "color": {"$type": "color", "brand": brand,
                       "neutral": {k: {"$value": v} for k, v in NEUTRAL.items()}}}
    on = "{color.neutral.0}" if t["on"].upper() == WHITE else "{color.neutral.900}"
    action = {"primary": {"$value": "{color.brand.primary-strong}" if t["darkened"] else "{color.brand.primary}"},
              "on-primary": {"$value": on}}
    if t["darkened"]:
        action["accent"] = {"$value": "{color.brand.primary}", "$description": "A cor original da marca, como acento."}
    sem = {"$schema": "https://design-tokens.github.io/community-group/format/",
           "$description": "Semantic: papéis de cor que referenciam as foundations por alias (gerado pelo /design:setup). W3C DTCG.",
           "color": {"$type": "color",
                     "surface": {"base": {"$value": "{color.neutral.0}"}, "subtle": {"$value": "{color.neutral.50}"}},
                     "on-surface": {"strong": {"$value": "{color.neutral.900}"}, "muted": {"$value": "{color.neutral.700}"}},
                     "border": {"default": {"$value": "{color.neutral.300}"}},
                     "action": action}}
    pairs = {"$description": "Pares de contraste WCAG que o lint-design-tokens.sh consome (gerado pelo /design:setup).",
             "pairs": [{"fg": "color.on-surface.strong", "bg": "color.surface.base", "min": 4.5, "note": "texto principal"},
                       {"fg": "color.on-surface.muted", "bg": "color.surface.base", "min": 4.5, "note": "texto secundário"},
                       {"fg": "color.action.on-primary", "bg": "color.action.primary", "min": 4.5, "note": "texto no CTA"}]}
    dump = lambda d: json.dumps(d, indent=2, ensure_ascii=False) + "\n"
    return dump(found), dump(sem), dump(pairs)


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    for k in ("design", "business", "technical"):
        ap.add_argument(f"--{k}-dir", required=True)
    ap.add_argument("--brand", default="")
    ap.add_argument("--audience", default="")
    ap.add_argument("--tone", default="")
    ap.add_argument("--theme-target", default="auto", choices=("auto", "css-vars", "tailwind", "shadcn", "none"))
    ap.add_argument("--create-brief", action="store_true")
    ap.add_argument("--add-frontmatter", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--today", default=datetime.date.today().isoformat())
    try:
        a = ap.parse_args(argv)
    except SystemExit:
        return 2
    root = os.path.realpath(a.root)
    if not os.path.isdir(root):
        print(f"ERRO: raiz inexistente: {a.root}", file=sys.stderr)
        return 2
    try:
        today = datetime.date.fromisoformat(a.today)
    except ValueError:
        print(f"ERRO: --today inválido: {a.today}", file=sys.stderr)
        return 2
    D = a.design_dir.strip("/")
    a.design_dir = D
    P = lambda rel: os.path.join(root, rel)
    paths = {"brief": f"{D}/brief.md", "found": f"{D}/foundations/color.tokens.json",
             "sem": f"{D}/semantic/color.tokens.json", "pairs": f"{D}/governance/contrast-pairs.json",
             "graph": f"{D}/design-context.kg.yaml"}
    t = {"project": os.path.basename(root), "review_after": (today + datetime.timedelta(days=92)).isoformat()}
    plan, need = [], []

    # 1. a marca e o contraste do CTA
    have_tokens = os.path.isfile(P(paths["found"])) and os.path.isfile(P(paths["sem"]))
    if have_tokens:
        try:
            fdoc, sdoc = load_json(P(paths["found"])), load_json(P(paths["sem"]))
        except (OSError, ValueError) as exc:
            print(f"ERRO: tokens existentes não abrem como JSON ({exc}) — rode o lint-design-tokens.sh", file=sys.stderr)
            return 2
        brand_tok = alias_of(sdoc, "color.action.primary") or ""
        # a ação pode apontar o tom escurecido que o próprio setup cria (`*-strong`); aí a MARCA é a cor
        # original, que ficou como acento (achado 7 da passada adversarial)
        accent_tok = alias_of(sdoc, "color.action.accent") or ""
        if brand_tok.endswith("-strong") and accent_tok:
            brand_tok = accent_tok
        t["brand_token"] = brand_tok
        t["brand_file"] = paths["found"] if get_path(fdoc, brand_tok) is not None else paths["sem"]
        t["action"] = resolve_value([sdoc, fdoc], "color.action.primary")
        t["on"] = resolve_value([sdoc, fdoc], "color.action.on-primary")
        t["brand"] = resolve_value([fdoc, sdoc], brand_tok) or t["action"]
        if not (brand_tok and isinstance(t["action"], str) and isinstance(t["on"], str)):
            print("ERRO: os tokens existentes não têm color.action.primary (por alias) e color.action.on-primary"
                  " resolvíveis — o setup não adivinha a marca; acerte os tokens ou declare --brand num projeto sem tokens",
                  file=sys.stderr)
            return 2
        if a.brand and "#" + a.brand.lstrip("#").upper() != str(t["brand"]).upper():
            plan.append(("AVISO", "-", f"--brand {a.brand} ignorado: os tokens existentes dizem {t['brand']} (nunca sobrescrevo)"))
        t["darkened"] = str(t["brand"]).upper() != str(t["action"]).upper()
        t["cta_ratio"] = ratio(t["action"], t["on"])
        for k in ("found", "sem", "pairs"):
            plan.append(("MANTER", paths[k], "existe — nunca sobrescrevo") if os.path.isfile(P(paths[k]))
                        else ("FALTA", paths[k], "os tokens existem sem este arquivo; o setup não o inventa"))
    elif any(os.path.exists(P(paths[k])) for k in ("found", "sem")):
        # TOKENS PARCIAIS (achado 3): um dos dois arquivos existe. Criar o outro com aliases do esquema do setup
        # gravava 4 arquivos incoerentes com o que ficou (11 alias órfãos no gate). O setup não completa à mão.
        for k in ("found", "sem"):
            plan.append(("MANTER", paths[k], "existe — nunca sobrescrevo") if os.path.exists(P(paths[k]))
                        else ("FALTA", paths[k], "tokens parciais: o setup não cria a outra metade"))
        need.append("tokens parciais: complete foundations e semantic à mão (ou pelo /design:identity) e rode de novo")
    else:
        if not a.brand:
            need.append("--brand '#RRGGBB' (a cor ou marca principal: os tokens não existem)")
        else:
            try:
                _rgb(a.brand)
            except ValueError:
                print(f"ERRO: --brand não é #RRGGBB: {a.brand}", file=sys.stderr)
                return 2
            b = "#" + a.brand.lstrip("#").upper()
            act, on, r, dk = cta_choice(b, NEAR_BLACK)
            t.update(brand=b, action=act, on=on, cta_ratio=r, darkened=dk,
                     brand_token="color.brand.primary", brand_file=paths["found"])
            rw, rb = ratio(b, WHITE), ratio(b, NEAR_BLACK)
            plan.append(("CONTRASTE", "-", f"{b}: branco {rw:.2f}:1 · quase preto {rb:.2f}:1 → "
                         + (f"nenhum chega a 4,5:1; a ação usa o tom mais escuro {act} com texto branco ({r:.2f}:1), e {b} fica como acento"
                            if dk else f"texto {on} ({r:.2f}:1)")))
            for k in ("found", "sem", "pairs"):
                plan.append(("CRIAR", paths[k], "tokens W3C DTCG mínimos") if not os.path.exists(P(paths[k]))
                            else ("MANTER", paths[k], "existe — nunca sobrescrevo"))

    # 2. o brief
    if os.path.isfile(P(paths["brief"])):
        with open(P(paths["brief"]), encoding="utf-8-sig") as fh:  # -sig: um BOM não esconde o frontmatter
            has_fm = fh.read(4).startswith("---")
        plan.append(("MANTER", paths["brief"], "a entrada do setup — a prosa não é tocada"))
        if not has_fm:
            plan.append(("FRONTMATTER" if a.add_frontmatter else "SUGERIR", paths["brief"],
                         "acrescentar projection_of e review_after no topo"
                         + ("" if a.add_frontmatter else " (rode com --add-frontmatter, depois de confirmar)")))
    elif a.create_brief:
        plan.append(("CRIAR", paths["brief"], "stub mínimo do brief (confirmado)"))
    else:
        need.append("--create-brief (não há brief: o stub só nasce com confirmação)")

    # 3. o alvo de tema e os grafos vizinhos
    if a.theme_target == "auto":
        t["target"], t["target_src"] = detect_theme(root)
    else:
        t["target"], t["target_src"] = a.theme_target, ""
    plan.append(("TEMA", "-", f"alvo {t['target']}" + (f" (detectado por {t['target_src']})" if t["target_src"] else "")))
    t["biz_pos"] = find_node(root, a.business_dir.strip("/"), "E_POSITIONING")
    t["biz_aud"] = find_node(root, a.business_dir.strip("/"), "E_AUDIENCE")
    t["tech_theme"] = find_node(root, a.technical_dir.strip("/"), "ST_THEME_APPLIED")
    plan.append(("LIGACAO", "-", (f"brief TRACES_TO {t['biz_pos']}#E_POSITIONING" if t["biz_pos"]
                                  else "sem grafo do business-context com E_POSITIONING: question aberta declara a falta")))
    plan.append(("LIGACAO", "-", (f"contraste CONSTRAINS {t['tech_theme']}#ST_THEME_APPLIED" if t["tech_theme"]
                                  else "sem grafo do technical-context com ST_THEME_APPLIED: question aberta declara a falta")))
    if os.path.exists(P(paths["graph"])):
        plan.append(("MANTER", paths["graph"], "existe — nunca sobrescrevo"))
    elif not need:
        plan.append(("CRIAR", paths["graph"], "o grafo do design-context"))

    for act, path, why in plan:
        print(f"{act}\t{path}\t{why}")
    if need:
        for n in need:
            print(f"PRECISA\t-\t{n}")
        return 3
    if not a.apply:
        print("DRY-RUN\t-\tnada gravado; rode com --apply depois de confirmar o plano")
        return 0

    writes = {}
    if not have_tokens:
        fj, sj, pj = new_tokens(t)
        for k, body in (("found", fj), ("sem", sj), ("pairs", pj)):
            if not os.path.exists(P(paths[k])):
                writes[paths[k]] = body
    if not os.path.exists(P(paths["brief"])) and a.create_brief:
        writes[paths["brief"]] = brief_stub(a, t)
    if not os.path.exists(P(paths["graph"])):
        writes[paths["graph"]] = build_graph(a, t)
    for rel, body in writes.items():
        os.makedirs(os.path.dirname(P(rel)), exist_ok=True)
        try:
            with open(P(rel), "x", encoding="utf-8") as fh:  # "x": falha se alguém criou no meio — nunca sobrescreve
                fh.write(body)
        except FileExistsError:
            print(f"ERRO: {rel} apareceu durante o setup — não sobrescrevo; o que já foi gravado fica, rode de novo", file=sys.stderr)
            return 2
        print(f"GRAVADO\t{rel}\t-")
    if a.add_frontmatter and os.path.isfile(P(paths["brief"])):
        with open(P(paths["brief"]), encoding="utf-8-sig") as fh:
            text = fh.read()
        if not text.startswith("---"):
            with open(P(paths["brief"]), "w", encoding="utf-8") as fh:
                fh.write(f"---\nprojection_of: {D}/design-context.kg.yaml\nreview_after: \"{t['review_after']}\"\n"
                         f"date: {a.today}\n---\n\n" + text)
            print(f"GRAVADO\t{paths['brief']}\tfrontmatter (a prosa ficou intacta)")
    if not writes:
        print("NADA\t-\ttudo já existia: reexecutar não duplica")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
