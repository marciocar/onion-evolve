import json, re, subprocess, base64, sys, unicodedata
from concurrent.futures import ThreadPoolExecutor
from collections import Counter

STOP = {
 'en': set("the and for with your from that this you are is to of in on it as be by or an at can into when use using how what all not will".split()),
 'pt': set("de do da dos das para com uma um não e é que em os as ao aos seu sua seus suas por como mais você voce ou são sao foi ser pelo pela sobre também tambem até ate".split()),
 'es': set("de del la el los las para con una un y es que en al su sus por como más mas o son fue ser sobre también hasta usted".split()),
 'fr': set("le la les des pour avec une un et est que dans du au aux sur vos votre ou sont être pas plus".split()),
 'de': set("der die das und für mit einer ein eine ist zu von im den auf oder sind werden nicht als sie ihre".split()),
 'it': set("il lo la gli le per con una un e è che nel della delle degli dei sul sono più anche".split()),
 'id': set("dan untuk dengan yang dari ini itu adalah pada tidak ke atau anda akan bisa".split()),
 'vi': set("là và cho của các với một trong được này không có để bạn".split()),
 'tr': set("ve için ile bir bu olarak veya değil kullanarak".split()),
 'nl': set("de het een en voor met van is dat niet zijn op je".split()),
}
SCRIPTS = [('ja', r'[぀-ヿ]'), ('ko', r'[가-힯]'), ('zh', r'[一-鿿]'), ('ru/cyr', r'[Ѐ-ӿ]'), ('ar', r'[؀-ۿ]'), ('he', r'[֐-׿]'), ('th', r'[฀-๿]'), ('hi', r'[ऀ-ॿ]')]

def classify(text):
    if not text or not text.strip(): return 'EMPTY'
    latin = sum(1 for ch in text if ch.isalpha() and ord(ch) < 0x250)
    nonlatin = sum(1 for ch in text if ch.isalpha() and ord(ch) >= 0x250)
    if nonlatin > latin:
        for lang, rx in SCRIPTS:
            if re.search(rx, text): return lang
        return 'non-latin'
    words = re.findall(r"[a-zà-ÿ']+", text.lower())
    sc = {l: sum(1 for w in words if w in s) for l,s in STOP.items()}
    best = max(sc, key=sc.get)
    if sc[best]==0: return 'en?(no-stopwords)'
    if best!='en' and (sc[best] <= sc['en'] or sc[best] < 2): return 'en'
    if best=='en' and nonlatin>0: return 'en(+non-latin chars)'
    return best

def gh(path):
    r = subprocess.run(['gh','api',path], capture_output=True, text=True)
    if r.returncode != 0:
        return None, (r.stderr.strip() or r.stdout.strip())[:120]
    try: return json.loads(r.stdout), None
    except Exception as e: return None, str(e)

def resolve(entry, local_repo):
    s = entry['source']
    if isinstance(s, str):
        return local_repo, s.lstrip('./'), 'main', 'local'
    url = s.get('url','')
    m = re.match(r'^(?:https?://github\.com/)?([^/]+)/([^/]+?)(?:\.git)?/?$', url)
    if not m: return None, None, None, f'unsupported-url:{url}'
    repo = f"{m.group(1)}/{m.group(2)}"
    path = (s.get('path') or '').strip('/')
    ref = s.get('sha') or s.get('ref') or 'HEAD'
    return repo, path, ref, s.get('source')

def probe(entry, local_repo):
    out = {'name': entry['name'], 'mkt_desc_lang': classify(entry.get('description','')), 'mkt_desc': (entry.get('description') or '')[:80].replace('\n',' ')}
    repo, path, ref, kind = resolve(entry, local_repo)
    out['repo']=repo; out['path']=path; out['kind']=kind
    if not repo:
        out['error']=kind; return out
    base = f"repos/{repo}/contents/{path}" if path else f"repos/{repo}/contents"
    listing, err = gh(f"{base}?ref={ref}")
    if err or not isinstance(listing, list):
        out['error']=f"root-listing:{err}"; return out
    names = [x['name'] for x in listing]
    out['readmes'] = sorted([n for n in names if re.match(r'(?i)^readme', n)])
    out['has_mcp_json'] = '.mcp.json' in names
    out['has_hooks_dir'] = 'hooks' in names
    out['has_manifest_dir'] = '.claude-plugin' in names
    out['has_settings_json'] = 'settings.json' in names
    # plugin.json
    if out['has_manifest_dir']:
        pj, err = gh(f"{base.rstrip('/')}/.claude-plugin/plugin.json?ref={ref}")
        if pj and pj.get('content'):
            try:
                doc = json.loads(base64.b64decode(pj['content']).decode('utf-8','replace'))
                out['pj_desc'] = (doc.get('description') or '')[:80].replace('\n',' ')
                out['pj_desc_lang'] = classify(doc.get('description') or '')
                out['pj_mcpServers'] = bool(doc.get('mcpServers'))
                out['pj_hooks'] = bool(doc.get('hooks'))
                out['pj_keys'] = sorted(doc.keys())
            except Exception as e:
                out['pj_error']=str(e)[:80]
        else:
            out['pj_error']=err or 'no-content'
    # hooks.json
    if out['has_hooks_dir']:
        hl, err = gh(f"{base.rstrip('/')}/hooks?ref={ref}")
        out['has_hooks_json'] = bool(hl) and isinstance(hl, list) and any(x['name']=='hooks.json' for x in hl)
    else:
        out['has_hooks_json'] = False
    # README.md language
    if 'README.md' in names:
        rd, err = gh(f"{base.rstrip('/')}/README.md?ref={ref}")
        if rd and rd.get('content'):
            txt = base64.b64decode(rd['content']).decode('utf-8','replace')[:3000]
            out['readme_lang'] = classify(txt)
        else:
            out['readme_lang'] = f'NÃO MEDIDO ({err})'
    return out

def main(mkt, local_repo, cap, outfile):
    d = json.load(open(mkt))
    plugins = d['plugins'][:cap] if cap else d['plugins']
    with ThreadPoolExecutor(max_workers=8) as ex:
        results = list(ex.map(lambda e: probe(e, local_repo), plugins))
    json.dump(results, open(outfile,'w'), indent=1, ensure_ascii=False)
    print(f"wrote {outfile}: {len(results)} entries; errors={sum(1 for r in results if r.get('error'))}")

if __name__=='__main__':
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4])
