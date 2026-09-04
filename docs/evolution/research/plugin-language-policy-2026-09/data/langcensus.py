import json, re, sys, unicodedata
from collections import Counter

STOP = {
 'en': set("the and for with your from that this you are is to of in on it as be by or an at can into when use using how what all not will".split()),
 'pt': set("de do da dos das para com uma um não e é que em os as ao aos seu sua seus suas por como mais você voce ou são sao foi ser pelo pela sobre também tambem até ate".split()),
 'es': set("de del la el los las para con una un y es que en al su sus por como más mas o son fue ser sobre también hasta usted".split()),
 'fr': set("le la les des pour avec une un et est que dans du au aux sur vos votre ou sont être pas plus".split()),
 'de': set("der die das und für mit einer ein eine ist zu von im den auf oder sind werden nicht als sie ihre".split()),
 'it': set("il lo la gli le per con una un e è che nel della delle degli dei sul sono più anche".split()),
 'id': set("dan untuk dengan yang dari ini itu adalah pada tidak ke atau anda akan bisa".split()),
 'tr': set("ve için ile bir bu olarak veya değil kullanarak".split()),
 'nl': set("de het een en voor met van is dat niet zijn op je".split()),
}
def classify(text):
    if not text: return 'EMPTY'
    if re.search(r'[぀-ヿ]', text): return 'ja'
    if re.search(r'[가-힯]', text): return 'ko'
    if re.search(r'[一-鿿]', text): return 'zh'
    if re.search(r'[Ѐ-ӿ]', text): return 'ru/cyr'
    if re.search(r'[؀-ۿ]', text): return 'ar'
    if re.search(r'[֐-׿]', text): return 'he'
    if re.search(r'[฀-๿]', text): return 'th'
    if re.search(r'[ऀ-ॿ]', text): return 'hi'
    words = re.findall(r"[a-zà-ÿ']+", text.lower())
    sc = {l: sum(1 for w in words if w in s) for l,s in STOP.items()}
    best = max(sc, key=sc.get)
    if sc[best]==0: return 'en?(no-stopwords)'
    # require non-en to beat en clearly
    if best!='en' and sc[best] <= sc['en']: return 'en'
    if best!='en' and sc[best] < 2: return 'en'
    return best

def run(path, label):
    d = json.load(open(path))
    plugins = d['plugins']
    c = Counter(); nonascii=0; rows=[]
    for p in plugins:
        desc = p.get('description') or ''
        lang = classify(desc)
        c[lang]+=1
        if re.search(r'[^\x00-\x7f]', desc): nonascii+=1
        if lang not in ('en','en?(no-stopwords)'):
            rows.append((p['name'], lang, desc[:80].replace('\n',' ')))
    print(f"== {label}: {len(plugins)} plugins; descriptions with non-ASCII chars: {nonascii}")
    for k,v in c.most_common(): print(f"  {k}: {v}")
    print("  -- non-English (heuristic) entries:")
    for r in rows: print("   ", r)
run('community-marketplace.json','community (marketplace.json descriptions)')
run('official-marketplace.json','official (marketplace.json descriptions)')
