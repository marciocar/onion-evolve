#!/usr/bin/env python3
# =============================================================================
# census-seal.py — aplica a tabela de selagem AUDIT do /meta:census e projeta a listagem REAL.
#
# Uso:  census-seal.py seal <consolidado.json>        # carimbos + SUPERSEDES nos grafos-fonte
#       census-seal.py list <consolidado.json> <out.md> [frescos.json]
#
# Tabela (postura AUDIT — /meta:drive): CONFIRMED+juiz-APROVADO → carimba verified_at ·
# DRIFTED → nó E_CENSO<data>_* + aresta PELA REALIDADE (SUPERSEDES se MORTO/FORA, senão CONSTRAINS) + carimbo do alvo (status INTOCADO — flip
# é do maestro) · REPROVADO/REFUTED/UNVERIFIABLE → intocado, listado.
#
# LEI DA SANITIZAÇÃO (2 disparos da guarda projeção/NOME em 2026-09-01): termos vêm de
# projection-safety.sh --emit-terms, MAS só len>=4 e SEMPRE com fronteira de palavra —
# um termo derivado de 2 letras substituído às cegas transformou "nodes:" em "no<x>s:" e
# quebrou um grafo inteiro (restaurado do git). Nunca substitua sem \b.
#
# LEI DO CARIMBO (verified_against duplicado, 2026-09-01): há nós com o par verified_* DEPOIS
# do label; inserir sempre-antes-do-label duplica. Este script procura o par no BLOCO INTEIRO
# do nó e atualiza in-place; só insere se não existir em lugar nenhum do bloco.
# =============================================================================
import json, re, sys, subprocess, datetime, os

# SCRIPTS = onde vivem radar/projection-safety/members (o core); ROOT = onde vivem os GRAFOS a selar.
# Separados para a bancada apontar ONION_CENSUS_ROOT a uma fixture (mesma costura do extrator).
SCRIPTS = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
ROOT = os.environ.get('ONION_CENSUS_ROOT', SCRIPTS)
HOJE = datetime.date.today().isoformat()

def derived_terms():
    out = subprocess.run(['bash', os.path.join(SCRIPTS, '.claude/validation/projection-safety.sh'), '--emit-terms'],
                         capture_output=True, text=True).stdout.split()
    return [t for t in out if len(t) >= 4]

def sanitize(s, terms):
    s = ' '.join(str(s).split())
    for t in terms:
        s = re.sub(r'\b' + re.escape(t) + r'\b', '<membro>', s)
    # Ids de membro vêm do members.yaml EM RUNTIME — nunca hardcoded: literal de adotante
    # neste arquivo viaja vendorizado para todo mundo (vendor-scrub pegou a 1ª versão, 2026-09-01).
    mf = os.path.join(SCRIPTS, 'docs/evolution/federation/members.yaml')
    if os.path.exists(mf):
        ids = re.findall(r'^\s*-\s*id:\s*([\w.-]+)', open(mf).read(), re.M)
        for mid in ids:
            if len(mid) >= 4 and mid not in ('onion-evolve',):
                s = re.sub(re.escape(mid), '<membro>', s, flags=re.I)
    return s.replace("'", "''")

def node_span(t, nid):
    i = t.find(f'- id: {nid}\n')
    if i < 0: return None, None
    ends = [x for x in (t.find('\n  - id: ', i+1), t.find('\nedges:', i+1)) if x > 0]
    return i, (min(ends) if ends else len(t))

def stamp(t, nid, vag):
    i, j = node_span(t, nid)
    if i is None: return t, False
    blk = t[i:j]
    if 'verified_at:' in blk:
        blk = re.sub(r'verified_at:\s*\S+', f'verified_at: {HOJE}', blk, count=1)
        blk = re.sub(r"verified_against:\s*(?:'(?:[^']|'')*'|\"[^\"]*\")", f"verified_against: '{vag}'", blk, count=1)
        # DEDUPE (lei do carimbo, 2ª mordida 2026-09-01): rodadas sucessivas deixavam pares extras
        # (o radar reprova verified_against repetido) — só o PRIMEIRO par sobrevive.
        for pat in (r"\n\s*verified_against:\s*(?:'(?:[^']|'')*'|\"[^\"]*\")", r'\n\s*verified_at:\s*\S+'):
            ms = list(re.finditer(pat, blk))
            for m in reversed(ms[1:]):
                blk = blk[:m.start()] + blk[m.end():]
        return t[:i] + blk + t[j:], True
    # Indent-agnóstico (3ª mordida, 2026-09-01): grafos antigos usam 3/5 espaços — busca fixa
    # de 4 falhava CALADA e o alvo DRIFTED ficava sem carimbo (D_pkce voltou à fila por isso).
    m = re.search(r'\n(\s+)label:', blk)
    if not m: return t, False
    ind = m.group(1)
    blk = blk[:m.start()] + f"\n{ind}verified_at: {HOJE}\n{ind}verified_against: '{vag}'" + blk[m.start():]
    return t[:i] + blk + t[j:], True

def seal(consol):
    d = json.load(open(consol))
    meds = d['medidos'] if 'medidos' in d else d
    apr, rep = set(), {}
    for v in d.get('juizo', []):
        apr.update(v['aprovados'])
        for x in v['reprovados']: rep[x['node_id']] = x['motivo']
    terms = derived_terms()
    RUN = f"/meta:census {HOJE}" + (f" ({d.get('run_id','')})" if d.get('run_id') else '')
    files, stamped, sup, skip = {}, 0, 0, []
    load = lambda p: files.setdefault(p, open(os.path.join(ROOT, p)).read())
    for m in meds:
        m['juiz'] = 'REPROVADO' if m['node_id'] in rep else ('APROVADO' if m['node_id'] in apr else 'N/A')
        if m['juiz'] == 'REPROVADO': skip.append(m['node_id']); continue
        p = m['kg_file'].lstrip('/')
        if m['verdict'] == 'CONFIRMED':
            vag = f"{RUN}: {m['claims_measured']}/{m['claims_total']} claims; juiz {m['juiz']}. {sanitize(m['method'],terms)[:80]} => {sanitize(m['observed'],terms)[:100]}…"
            t2, ok = stamp(load(p), m['node_id'], vag)
            if ok: files[p] = t2; stamped += 1
            else: skip.append(m['node_id'] + ':stamp-fail')
        elif m['verdict'] == 'DRIFTED':
            t = load(p)
            nid_new = f"E_CENSO{HOJE.replace('-','')[4:]}_{m['node_id'][:34]}"
            if nid_new in t: continue
            if '\nedges:' not in t: skip.append(m['node_id'] + ':sem-edges'); continue
            node = (f"  - id: {nid_new}\n    node_type: evidence\n    plane: PROD\n    status: confirmed\n"
                    f"    impact: 4\n    confidence: 0.9\n    verified_at: {HOJE}\n"
                    f"    verified_against: '{RUN}: DRIFTED {m['claims_measured']}/{m['claims_total']} — {sanitize(m['method'],terms)[:90]}'\n"
                    f"    label: 'MEDIDO {HOJE}, o vivo superou o no: {sanitize(m['divergence'],terms)[:300]}'\n\nedges:")
            t = t.replace('\nedges:', '\n' + node, 1)
            # TIPO DA ARESTA PELA REALIDADE (lei de 2026-09-02, regra do proprio radar): SUPERSEDES
            # diz "deixou de valer" e exige flip do alvo — mas um DRIFTED cuja realidade e GATED ou
            # REAL-ACIONAVEL ainda tem TRABALHO pendente; flipa-lo apagaria o item do backlog. Ali o
            # superseder apenas REFINA => CONSTRAINS, alvo segue open. Medido: 13 alvos de SUPERSEDES
            # ficaram open em 8 grafos apos 2 censos por esta escolha ser incondicional.
            et = 'SUPERSEDES' if m.get('realidade') in ('MORTO-CANDIDATO', 'FORA-DO-CORE') else 'CONSTRAINS'
            t = t.rstrip() + f"\n  - from: {nid_new}\n    to: {m['node_id']}\n    edge_type: {et}\n"
            nota = 'flip para superseded PROPOSTO ao maestro' if et == 'SUPERSEDES' else 'REFINA, alvo segue open'
            t, ok2 = stamp(t, m['node_id'], f"{RUN}: DRIFTED — ver {nid_new} ({et}: {nota}); label preservado como historia")
            if not ok2: skip.append(m['node_id'] + ':stamp-alvo-FALHOU')  # nunca silencioso (3ª mordida)
            files[p] = t; sup += 1
    for p, t in files.items(): open(os.path.join(ROOT, p), 'w').write(t)
    for p in files:
        rc = subprocess.run(['bash', os.path.join(SCRIPTS, '.claude/validation/kg-radar.sh'),
                             os.path.join(ROOT, p), '--integrity', '--schema'],
                            capture_output=True).returncode
        if rc != 0:
            print(f"census-seal: RADAR REPROVOU {p} — selagem ABORTADA antes de commit; corrija e re-rode.", file=sys.stderr)
            sys.exit(2)
    json.dump(d, open(consol, 'w'), ensure_ascii=False, indent=1)
    print(f"census-seal: carimbados={stamped} superseded={sup} reprovados/pulados={len(skip)} grafos={len(files)} (radar 0 em todos)")

def listing(consol, out, frescos_path):
    d = json.load(open(consol)); meds = d['medidos']
    frescos = json.load(open(frescos_path))['frescos'] if frescos_path else []
    terms = derived_terms()
    S = lambda s: sanitize(s, terms).replace("''", "'")
    reais = [m for m in meds if m['realidade']=='REAL-ACIONAVEL' and m.get('juiz')!='REPROVADO']
    disp = [m for m in meds if m['realidade']=='GATED' and m['gatilho_disparou']=='SIM']
    gated = [m for m in meds if m['realidade']=='GATED' and m['gatilho_disparou']!='SIM' and m.get('juiz')!='REPROVADO']
    mortos = [m for m in meds if m['realidade']=='MORTO-CANDIDATO']
    fora = [m for m in meds if m['realidade']=='FORA-DO-CORE']
    reprov = [m for m in meds if m.get('juiz')=='REPROVADO']
    L = [f"# Backlog REAL — /meta:census {HOJE}\n",
         f"> Projeção do censo (SSOT = grafos-fonte). Teto: {d.get('parametros',{})}. "
         f"Não-medidos-por-teto: {len(d.get('nao_medidos_por_teto',[]))} (nomeados abaixo).\n",
         f"**{len(reais)} reais · {len(disp)} gatilho-disparado · {len(gated)} gated · {len(mortos)} selos propostos · {len(reprov)} re-medir · {len(fora)} fora · {len(frescos)} frescos**\n"]
    def sec(titulo, items, fmt):
        L.append(f"\n## {titulo}\n")
        for m in items: L.append(fmt(m))
    sec("1 · REAIS + gatilhos DISPARADOS", disp+reais, lambda m: f"- `{m['node_id']}` ({m['kg_file'].split('/')[-1][:-8]}) — {S(m['proximo_passo'])[:160]}")
    sec("2 · GATED (gatilho medido, não-disparado)", gated, lambda m: f"- `{m['node_id']}` — gatilho: {S(m['gatilho'])[:150]}")
    sec("3 · PROPOSTAS DE SELO (flip é do maestro)", mortos, lambda m: f"- `{m['node_id']}` — {S(m.get('divergence') or m['observed'])[:150]}")
    sec("4 · RE-MEDIR (juiz reprovou)", reprov, lambda m: f"- `{m['node_id']}` — {S(m.get('juiz_motivo',''))[:150]}" if m.get('juiz_motivo') else f"- `{m['node_id']}`")
    sec("5 · FORA-DO-CORE", fora, lambda m: f"- `{m['node_id']}` — {S(m['proximo_passo'])[:120]}")
    sec("6 · FRESCOS (citados pelo carimbo)", frescos, lambda r: f"- `{r['id']}` ({r['grafo']}) — verified_at {r['verified_at']}")
    if d.get('nao_medidos_por_teto'):
        sec("7 · NÃO-MEDIDOS-POR-TETO (próxima rodada)", d['nao_medidos_por_teto'], lambda n: f"- `{n}`")
    open(out, 'w').write('\n'.join(L) + '\n')
    print(f"census-seal: listagem em {out}")

if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'seal': seal(sys.argv[2])
    elif cmd == 'list': listing(sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None)
    else: print("uso: census-seal.py seal <json> | list <json> <out.md> [extract.json]", file=sys.stderr); sys.exit(2)
