#!/usr/bin/env bash
# ===========================================================================
# kg-decide-seal.sh — o DESTINO (peça 5) do /meta:decide: grava UMA resposta do maestro como selo no nó.
#
# Uso:
#   bash .claude/validation/kg-decide-seal.sh <grafo.kg.yaml> <NODE_ID> \
#        --chosen "<opção escolhida>" --rejected "<a|b|c>" --date AAAA-MM-DD --question "<pergunta>" [--other]
#   bash .claude/validation/kg-decide-seal.sh <grafo.kg.yaml> --new <D_ID> --label "<afirmação ≤280>" \
#        --link <ID_EXISTENTE> [--edge-type TRACES_TO] [--impact 3] --chosen ... --rejected ... --date ... --question ...
#   bash .claude/validation/kg-decide-seal.sh --batch <lote.tsv> --preview --date AAAA-MM-DD --question "<pergunta>"   (a lista VISÍVEL + o sha256)
#   bash .claude/validation/kg-decide-seal.sh --batch <lote.tsv> --approve <sha256> --date AAAA-MM-DD --question "<pergunta>"
#
# MODO LOTE (a triagem do /meta:decide, cláusula 10 da doutrina; D_FORGE_DECIDE_BATCH_TRIAGE_MODE_1111):
#   O lote é TSV, uma linha por nó: grafo · nó · destino · ref · prazo · motivo (6 colunas; `#` e vazia ignoradas;
#   o grafo como o medidor o imprime, relativo à raiz, rodando da raiz).
#     obsolete  ref = o SUCESSOR, obrigatório: ID do mesmo grafo, ou <caminho relativo à raiz>.kg.yaml#<ID> de outro ·
#               prazo `-` → status: superseded, plane DEV, verified_at, proveniência testimony da aprovação em lote,
#               motivo na narrative (a anterior verbatim) e a aresta SUPERSEDES: em `edges` (mesmo grafo) ou em
#               `external_edges` com from "<grafo>#<ID>" (contrato v4.3); a que já existe não duplica. Sem sucessor
#               não há obsoleto: o contrato reprova `integrity.superseded-without-successor` (recusa já no --preview)
#     request   ref = PAPEL em minúsculas (ceo, juridico, sessao-x; nunca `maestro`) · prazo AAAA-MM-DD → o nó
#               SEGUE open, com owner: <papel>, x_due: <prazo> e o pedido na narrative
#   A APROVAÇÃO é o sha256 do arquivo do lote + a --date + a --question, mostrado ao maestro com a lista (--preview)
#   numa pergunta só: o "sim" vira --approve. Lote, data ou pergunta que mudaram depois têm outro sha e são RECUSADOS.
#   Datas (--date e prazo) são AAAA-MM-DD estritas e reais, a régua do selo unitário.
#   RECUSA (rc 2, nada escrito): sem --approve, sha diferente, destino (a) `measure` (fecha pelo /meta:kg-freshness,
#   nunca pelo selador) e (d) `maestro` (vai à rodada normal), destino fora da lista, nó que não está open, cego,
#   repetido ou inexistente, ref de obsoleto fora do grafo, pedido sem papel ou com prazo antes da data.
#   GARANTIA: o modo externo confere o lote inteiro, guarda cópia de TODO grafo e chama este script por grafo (que
#   reconfere tudo e passa pelo MESMO gate do selo único: radar, contrato, lint de nomes). Um grafo que reprova
#   desfaz o LOTE INTEIRO byte a byte (rc 3; rc 2 se a recusa veio no passo 0 de um grafo).
#
# O que escreve (nó existente decision|question `open`):
#   status: done · verified_at · verified_against · provenance {source, locator, method, locality: pessoa}
#   com method = "testimony: decisão do maestro por pergunta com opções, <data>" (forma canônica do contrato v4.16;
#   selos antigos com o alias "testemunho:" seguem valendo) · e na narrative (mantida
#   a anterior) a opção escolhida E as descartadas. O plane fica DEV, e PROD é REBAIXADO (dito na narrative):
#   a base do selo é testemunho, e o contrato reprova testemunho em PROD (integrity.testimony-in-prod, SHOULD).
#   O radar avisa decision-done-em-DEV (SOFT, agregado) — os dois discordam, e quem vence é o contrato; a
#   promoção a PROD é de quem EXECUTA a decisão e mede o artefato, não do selo. Achado do dogfood da forja
#   (2026-10-12): a 1ª versão subia para PROD e o kg-contract-check reprovou o próprio grafo da forja.
#   `--other` = a resposta livre do maestro, fora das opções oferecidas — também é selo, e a narrative diz que foi livre.
# Com --new: cria o nó `D_*` com as mesmas marcas e uma aresta <D_ID> --<edge-type>--> <ID_EXISTENTE>
#   (nó sem aresta reprova no radar como órfão; a ligação é o que diz DE ONDE a decisão veio).
#
# O que RECUSA (rc 2, NADA escrito): nó inexistente · nó que não está `open` (lista positiva) · nó que não é
#   decision|question · nó com campo CEGO (chave com `blind`/`cego` em qualquer nível, ou valor aninhado: gate humano às cegas não recebe
#   voto de ninguém além do humano) · id duplicado ou fora da forma de bloco · data inválida · --rejected
#   vazio · --new com id existente ou fora de `D_[A-Z0-9_]+`, sem --label/--link, ou link inexistente ·
#   grafo que JÁ reprova no radar ou JÁ piora o contrato antes do selo (dívida alheia não vira culpa do selo) ·
#   --question ausente · --chosen vazio · opção com « » · escolhida também em --rejected (sem caixa) · data futura ·
#   --new num grafo no escopo da REGRA 58 (`# kg-backlog-guard: on`) cujo TETO do `meta:` o nó novo estouraria, ou
#   que não declara TETO (o mesmo kg-backlog-check.sh julga o grafo como ficaria; dano de 2026-10-13: 65º nó, teto 64).
#   A narrative anterior fica VERBATIM num bloco `|-`; a proveniência anterior vai inteira para ela.
# O gate (rc 3, escrita DESFEITA byte a byte): depois de escrever, `kg-radar.sh --integrity --schema`
#   tem de sair 0 e, onde o contrato está vendorizado (vendor/kg-ssot), `kg-contract-check.sh` também
#   (ele cobra a REGRA 99 (Nó de .kg.yaml sem caminho de máquina, julgado pela classe) no texto da opção).
#   Contrato que NÃO PÔDE julgar (rc 2 dele) é DECLARADO em stderr, não vira verde calado.
#   E o LINT DE NOMES (`kg_vocab.py lint`, o mesmo leitor que o CI do core roda sobre a prosa dos grafos), onde
#   ele está no repo (vendor/kg-ssot/tools ou tools/ do produto): o selador o roda sobre o corpus ANTES e DEPOIS
#   da escrita e reprova (rc 3, DESFEITO) o achado que o selo acrescentou ao grafo tocado — código curto sem
#   termo, ou ambíguo, num label/narrative. Dano medido (2026-10-25): o selo copia o `verified_against` e a
#   proveniência anteriores para a narrative; o `verified_against` o lint não lê, a narrative sim, e um "r18" do
#   texto antigo virou `vocab.code-unresolved` que o selador deu por ✅ e o CI reprovou depois. A comparação é
#   antes×depois (a catraca é o próprio grafo), então dívida antiga não vira culpa do selo. Lint ausente, grafo
#   não rastreado pelo git (o lint lê só os rastreados) ou lint que não julgou: DECLARADO em stderr, nunca calado.
#   As externas do repo (`.kg-ssot/vocab-externals.tsv`, esquema TAB regex), se houver, entram como --external.
# Contrato de custo (run_id · tokens · agents · duration_min): NÃO se aplica — isto não é run de workflow;
#   um selo é uma escrita determinística de 0 tokens. Declarado aqui e na doutrina, não omitido.
#
# Env (bancada; NUNCA em produção — o override ativo é declarado em stderr):
#   DECIDE_SEAL_RADAR=<script>   radar alternativo (a bancada injeta um que reprova para provar o desfazer)
# Exit: 0 selado e gate verde · 2 recusado (nada escrito) · 3 escrito, gate vermelho, DESFEITO.
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_decide_selftests).
# ===========================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RADAR="${DECIDE_SEAL_RADAR:-${HERE}/kg-radar.sh}"
[ -n "${DECIDE_SEAL_RADAR:-}" ] && echo "kg-decide-seal: ⚠️ override ativo — DECIDE_SEAL_RADAR=${DECIDE_SEAL_RADAR} (não é o gate de produção)" >&2
GRAPH=""; NODE=""; NEW=""; CHOSEN=""; REJECTED=""; DATE=""; QUESTION=""; OTHER="0"; LABEL=""; LINK=""; ETYPE="TRACES_TO"; IMPACT="3"
BATCH=""; APPROVE=""; PREVIEW="0"
_need() { [ $# -ge 2 ] && [ -n "$2" ] || { echo "kg-decide-seal: $1 exige um valor" >&2; exit 2; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --new) _need "$@"; NEW="$2"; shift ;;
    --chosen) _need "$@"; CHOSEN="$2"; shift ;;
    --rejected) _need "$@"; REJECTED="$2"; shift ;;
    --date) _need "$@"; DATE="$2"; shift ;;
    --question) _need "$@"; QUESTION="$2"; shift ;;
    --label) _need "$@"; LABEL="$2"; shift ;;
    --link) _need "$@"; LINK="$2"; shift ;;
    --edge-type) _need "$@"; ETYPE="$2"; shift ;;
    --impact) _need "$@"; IMPACT="$2"; shift ;;
    --other) OTHER="1" ;;
    --batch) _need "$@"; BATCH="$2"; shift ;;
    --approve) _need "$@"; APPROVE="$2"; shift ;;
    --preview) PREVIEW="1" ;;
    --*) echo "kg-decide-seal: opção desconhecida: $1" >&2; exit 2 ;;
    *) if [ -z "${GRAPH}" ]; then GRAPH="$1"; elif [ -z "${NODE}" ]; then NODE="$1"; else echo "kg-decide-seal: argumento a mais: $1" >&2; exit 2; fi ;;
  esac
  shift
done
# ── MODO LOTE (a triagem do /meta:decide, cláusula 10 da doutrina) ──────────────────────────────────────
# O validador e o escritor do lote são UM só código Python (_lot_py), usado pelo modo externo (que confere o lote
# inteiro e chama este mesmo script uma vez por grafo) e pelo modo por grafo (que reconfere TUDO de novo: ele pode
# ser chamado direto, e a aprovação vale igual). Forma do lote, a garantia e o que ele recusa: no cabeçalho.
_lot_py() {  # $1=check|write $2=lote $3=aprovação $4=data $5=pergunta $6=grafo(realpath)|- $7=stage|- $8=preview(0|1)
  PYTHONDONTWRITEBYTECODE=1 python3 -I -B - "$@" <<'LOT'
import sys, os, re, hashlib, datetime
mode, lot, approve, date, question, graph, stage, preview = sys.argv[1:9]
def die(m): print('kg-decide-seal: lote recusado — ' + m + ' — nada escrito', file=sys.stderr); sys.exit(2)
try:
    import yaml
except ImportError:
    die('PyYAML ausente (fail-loud)')
try: raw = open(lot, 'rb').read()
except OSError as e: die(f'lote ilegível: {e}')
one = lambda s: ' '.join(str(s).split())
# DATA ESTRITA, a mesma régua do selo unitário: AAAA-MM-DD com hífens E data real. Só o fromisoformat não basta: no
# Python 3.11+ ele aceita `20261201` (achado B2 do refutador independente, 2026-11-11: o prazo virava x_due que o
# medidor não lê, e `--date 2025-13-45` saía rc 0 porque o lote só conferia o regex).
def strict_date(v):
    if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', v or ''): return False
    try: datetime.date.fromisoformat(v); return True
    except ValueError: return False
if not strict_date(date): die(f'--date fora de AAAA-MM-DD, ou data que não existe: {date!r}')
today = os.environ.get('DECIDE_SEAL_TODAY') or datetime.date.today().isoformat()
if date > today: die(f'--date no futuro ({date} > {today})')
if not one(question): die('falta --question (o texto da pergunta de aprovação do lote) — também no --preview: ela entra na aprovação')
# A APROVAÇÃO cobre o lote E a data E a pergunta (limite curado na passada independente): o mesmo lote reaprovado
# com outra pergunta ou data é outra aprovação, e o sha mostrado no --preview é o que o --approve tem de repetir
sha = hashlib.sha256(raw + b'\n\0date=' + date.encode() + b'\n\0question=' + one(question).encode('utf-8')).hexdigest()
try: text = raw.decode('utf-8')
except UnicodeDecodeError: die('lote não é UTF-8')
items = []; seen = set()
_rt = {}
def root_of(rg):  # a raiz git do grafo: é dela que sai o <grafo>#<ID> das external_edges (contrato v4.3)
    d0 = os.path.dirname(rg)
    if d0 not in _rt:
        import subprocess
        r = subprocess.run(['git', '-C', d0, 'rev-parse', '--show-toplevel'], capture_output=True, text=True)
        _rt[d0] = r.stdout.strip() if r.returncode == 0 and r.stdout.strip() else None
    return _rt[d0]
for k, l in enumerate(text.split('\n'), 1):
    if not l.strip() or l.lstrip().startswith('#'): continue
    f = l.split('\t')
    if len(f) != 6: die(f'linha {k}: esperava 6 colunas TAB (grafo, nó, destino, ref, prazo, motivo), achei {len(f)}')
    g, nid, dest, ref, due, why = [x.strip() for x in f]
    if dest in ('measure', 'medição', 'medicao', 'a', '(a)'):
        die(f'linha {k} ({nid}): destino (a) FECHA POR MEDIÇÃO e vai para o /meta:kg-freshness — nunca pelo selador, que grava testemunho do maestro')
    if dest in ('maestro', 'd', '(d)'):
        die(f'linha {k} ({nid}): destino (d) é do maestro e entra na rodada NORMAL do /meta:decide, com pergunta própria — não vai no lote')
    if dest not in ('obsolete', 'request'): die(f'linha {k}: destino fora da lista (obsolete | request): {dest!r}')
    if not one(why): die(f'linha {k} ({nid}): motivo vazio — obsoleto e pedido levam o porquê')
    if any(c in why for c in '«»'): die(f'linha {k}: motivo com « ou » (delimitadores do selo)')
    if not os.path.isfile(g): die(f'linha {k}: grafo inexistente: {g}')
    rg = os.path.realpath(g)
    if (rg, nid) in seen: die(f'linha {k}: {nid} repetido no lote')
    seen.add((rg, nid))
    if dest == 'obsolete':
        if due != '-': die(f'linha {k} ({nid}): obsoleto não leva prazo (use -)')
        # SEM SUCESSOR NÃO HÁ OBSOLETO (achado B1, bloqueava): `superseded` sem SUPERSEDES chegando reprova no contrato
        # (integrity.superseded-without-successor) e o lote inteiro voltava. Nada o supera? Então não é (c): é (a) ou (d).
        if ref == '-' or not ref:
            die(f'linha {k} ({nid}): obsoleto SEM SUCESSOR — diga quem o supera (ID do mesmo grafo, ou <grafo>#<ID> de outro, relativo à raiz); sem sucessor o contrato reprova (integrity.superseded-without-successor), e então o destino é (a) medição ou (d) maestro')
        if not re.fullmatch(r'(?:[A-Za-z0-9._/-]+\.kg\.yaml#)?[A-Za-z][A-Za-z0-9_]*', ref) or ref.startswith('/') or '..' in ref.split('#')[0].split('/'):
            die(f'linha {k} ({nid}): ref do obsoleto é ID (mesmo grafo) ou <caminho relativo à raiz>.kg.yaml#<ID>: {ref!r}')
    else:
        if not re.fullmatch(r'[a-z][a-z0-9._-]{0,47}', ref) or ref == 'maestro':
            die(f'linha {k} ({nid}): o pedido vai a um PAPEL em minúsculas (ceo, juridico, financeiro, sessao-x), nunca ao maestro nem a nome de pessoa: {ref!r}')
        if not strict_date(due): die(f'linha {k} ({nid}): prazo do pedido fora de AAAA-MM-DD, ou data que não existe: {due!r}')
        if due < date: die(f'linha {k} ({nid}): prazo {due} anterior à data do selo {date}')
    why = one(why); why = why if why[-1] in '.!?' else why + '.'
    items.append({'k': k, 'g': g, 'rg': rg, 'id': nid, 'dest': dest, 'ref': ref, 'due': due, 'why': why})
if not items: die('lote sem nenhum item')
# cada nó: existe uma vez, é decision|question, está open, sem campo cego; o ref do obsoleto existe no grafo
cache = {}
def load(rg):
    if rg not in cache:
        try: cache[rg] = open(rg, encoding='utf-8').read()
        except OSError as e: die(f'grafo ilegível: {e}')
    return cache[rg]
def blind(o, top=True):
    out = []
    if isinstance(o, dict):
        for kk, v in o.items():
            if re.search(r'blind|cego', str(kk), re.I): out.append(str(kk))
            if isinstance(v, (dict, list)): out += blind(v, False)
            elif not top and isinstance(v, str) and re.search(r'blind|cego', v, re.I): out.append(f'{kk}={v}')
    elif isinstance(o, list):
        for v in o: out += blind(v, False)
    return out
# no modo por grafo, o ESTADO dos nós só se confere nos itens deste grafo: os de grafos anteriores do mesmo lote já
# foram gravados pelo modo externo (e deixaram de estar open); a forma e o sha do lote inteiro seguem conferidos acima
for it in items:
    if mode == 'write' and it['rg'] != graph: continue
    try: d = yaml.safe_load(load(it['rg'])) or {}
    except Exception as e: die(f"{it['g']}: YAML ilegível ({one(e)[:120]})")
    ns = [n for n in (d.get('nodes') or []) if isinstance(n, dict) and str(n.get('id')) == it['id']]
    if len(ns) != 1: die(f"{it['id']}: {'inexistente' if not ns else 'duplicado'} em {it['g']}")
    n = ns[0]
    if n.get('node_type') not in ('decision', 'question'): die(f"{it['id']} é {n.get('node_type')}, não decision|question")
    if n.get('status') != 'open': die(f"{it['id']} está {n.get('status')}, não open — a triagem só toca o que está aberto")
    b = blind(n)
    if b: die(f"{it['id']} tem campo CEGO ({', '.join(b)})")
    if it['dest'] == 'obsolete':
        if '#' in it['ref']:
            # entre grafos: o sucessor vive noutro grafo RASTREADO da mesma raiz, e a superação vira external_edges
            # SUPERSEDES (from externo, to o nó) — a forma que o contrato lê como sucessor declarado
            ep, eid = it['ref'].split('#', 1)
            root = root_of(it['rg'])
            if not root: die(f"{it['id']}: o grafo não está num repo git — sem raiz, o <grafo>#<ID> do sucessor não se resolve")
            ef = os.path.join(root, ep)
            if os.path.realpath(ef) == it['rg']: die(f"{it['id']}: o sucessor está no MESMO grafo — use só o ID ({eid})")
            if not os.path.isfile(ef): die(f"{it['id']}: o grafo do sucessor não existe na raiz: {ep}")
            try: ed = yaml.safe_load(open(ef, encoding='utf-8')) or {}
            except Exception as e: die(f"{ep}: YAML ilegível ({one(e)[:120]})")
            if not any(isinstance(x, dict) and str(x.get('id')) == eid for x in (ed.get('nodes') or [])):
                die(f"{it['id']}: o sucessor {eid} não existe em {ep}")
        else:
            if it['ref'] == it['id']: die(f"{it['id']}: um nó não supera a si mesmo")
            if not any(isinstance(x, dict) and str(x.get('id')) == it['ref'] for x in (d.get('nodes') or [])):
                die(f"{it['id']}: o nó que o supera ({it['ref']}) não existe em {it['g']} — se está em outro grafo, escreva <grafo>#<ID>")
    it['node'] = n
# a aprovação se confere DEPOIS da forma das linhas e do estado dos nós: destino (a)/(d) e data torta e nó fechado recusam pelo nome, não por sha
if preview != '1':
    if not approve: die('falta --approve <sha256 da aprovação>: o lote só se aplica com a aprovação do maestro, dada sobre a lista VISÍVEL (rode --preview com a mesma --date e --question)')
    if approve.strip().lower() != sha:
        die(f'o lote, a data ou a pergunta mudaram depois da aprovação (sha256 aprovado {approve[:12]}…, atual {sha[:12]}…): item fora do lote aprovado não se grava; mostre a lista de novo e peça outra aprovação')
if mode == 'check':
    if preview == '1':
        print(f'# lote de triagem — {len(items)} item(ns) · data {date} · aprovação sha256 {sha}')
        print(f'Pergunta: «{one(question)}»')
        print('Aprovação do maestro: UMA pergunta com esta lista visível; o "sim" vira `--approve ' + sha + '`.')
        for it in items:
            if it['dest'] == 'obsolete':
                print(f"- (c) OBSOLETO `{it['id']}` — {it['g']} — {it['why']} · superado por `{it['ref']}`")
            else:
                print(f"- (b) PEDIDO a `{it['ref']}` até {it['due']}: `{it['id']}` — {it['g']} — {it['why']}")
    else:
        for rg in sorted({it['rg'] for it in items}): print(rg)
    sys.exit(0)
# ── write: só os itens deste grafo, no STAGE ──
mine = [it for it in items if it['rg'] == graph]
if not mine: die(f'nenhum item do lote é deste grafo ({graph})')
txt = load(graph); lines = txt.split('\n')
def q(s): return '"' + one(s).replace('\\', '\\\\').replace('"', '\\"') + '"'
sha12 = sha[:12]
for it in mine:
    nid = it['id']; n = it['node']
    hits = [i for i, l in enumerate(lines) if re.match(r'^(\s*)-\s+id:\s*["\']?' + re.escape(nid) + r'["\']?\s*(#.*)?$', l)]
    if len(hits) != 1: die(f'{nid}: não achei UMA linha `- id:` em forma de bloco (achei {len(hits)})')
    i = hits[0]; ind = len(lines[i]) - len(lines[i].lstrip()); fi = ind + 2
    end = len(lines)
    for j in range(i + 1, len(lines)):
        l = lines[j]
        if not l.strip(): continue
        lind = len(l) - len(l.lstrip())
        if lind < ind or (lind == ind and l.lstrip().startswith('-')) or (lind <= ind and l.lstrip().startswith('#')):
            end = j; break
    while end > i + 1 and not lines[end - 1].strip(): end -= 1
    if it['dest'] == 'obsolete':
        drop = {'status', 'verified_at', 'verified_against', 'provenance', 'narrative', 'plane'}
    else:
        drop = {'narrative', 'owner', 'x_due'}
    body = []; k = i + 1
    while k < end:
        l = lines[k]; lind = len(l) - len(l.lstrip())
        m = re.match(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:', l)
        if lind == fi and m and m.group(1) in drop:
            k += 1
            while k < end and (not lines[k].strip() or len(lines[k]) - len(lines[k].lstrip()) > fi): k += 1
            continue
        body.append(l); k += 1
    oldn = n.get('narrative')
    if isinstance(oldn, list): oldn = '\n'.join(f'- {x}' for x in oldn)
    oldn = '' if oldn is None else str(oldn).rstrip('\n')
    s = ' ' * fi
    approved = f'aprovado pelo maestro numa pergunta só, com a lista visível: «{one(question)}»'
    if it['dest'] == 'obsolete':
        prev = []
        if n.get('verified_against'): prev.append(f'verified_against anterior: «{one(n["verified_against"])}»')
        if isinstance(n.get('provenance'), dict) and n['provenance']:
            prev.append('proveniência anterior: ' + ' · '.join(f'{kk} «{one(v)}»' for kk, v in n['provenance'].items()))
        if n.get('plane') == 'PROD': prev.append('plane anterior: PROD, rebaixado a DEV porque a base do selo é testemunho')
        tail = prev + [f'Obsoleto pela triagem em lote do /meta:decide em {date} (lote {sha12}, {approved}): {it["why"]}'
                       + f' Superado por {it["ref"]}.']
        add = [f'{s}status: superseded', f'{s}plane: DEV', f'{s}verified_at: "{date}"',
               f'{s}verified_against: {q(f"triagem em lote aprovada pelo maestro em {date} (lote {sha12}): obsoleto")}']
        nb = (oldn.split('\n') + [''] if oldn else []) + tail
        add += [s + 'narrative: |-'] + [(s + '  ' + x) if x.strip() else '' for x in nb]
        add += [f'{s}provenance:', f'{s}  source: "maestro, na triagem em lote do /meta:decide"',
                f'{s}  locator: {q(f"lote {sha12} de {date}")}',
                f'{s}  method: {q(f"testimony: aprovação do maestro, em lote, da triagem do /meta:decide, {date}")}',
                f'{s}  locality: "pessoa"']
    else:
        tail = [f'Pedido a {it["ref"]} pela triagem em lote do /meta:decide em {date} (lote {sha12}, {approved}), prazo {it["due"]}: {it["why"]}']
        nb = (oldn.split('\n') + [''] if oldn else []) + tail
        add = [f'{s}owner: {it["ref"]}', f'{s}x_due: "{it["due"]}"', s + 'narrative: |-'] + [(s + '  ' + x) if x.strip() else '' for x in nb]
    lines = lines[:i + 1] + body + add + lines[end:]
# arestas SUPERSEDES dos obsoletos com ref (a que já existe não se duplica)
try: d0 = yaml.safe_load(txt) or {}
except Exception: d0 = {}
have = {(str(e.get('from')), str(e.get('to')), e.get('edge_type')) for e in (d0.get('edges') or []) if isinstance(e, dict)}
newe = [(it['ref'], it['id']) for it in mine if it['dest'] == 'obsolete' and '#' not in it['ref'] and (it['ref'], it['id'], 'SUPERSEDES') not in have]
haveX = {(str(e.get('from')), str(e.get('to')), e.get('edge_type')) for e in (d0.get('external_edges') or []) if isinstance(e, dict)}
newx = [(it['ref'], it['id']) for it in mine if it['dest'] == 'obsolete' and '#' in it['ref'] and (it['ref'], it['id'], 'SUPERSEDES') not in haveX]
if newx:
    xt = [i for i, l in enumerate(lines) if re.match(r'^external_edges\s*:', l)]
    if len(xt) > 1: die('mais de um `external_edges:` no nível 0')
    if xt and re.match(r'^external_edges\s*:\s*\[\s*\]\s*$', lines[xt[0]]): lines[xt[0]] = 'external_edges:'
    elif xt and not re.match(r'^external_edges\s*:\s*$', lines[xt[0]]): die('`external_edges:` fora da forma de bloco — escrita recusada')
    if not xt:
        while lines and not lines[-1].strip(): lines.pop()
        lines += ['external_edges:']; xt = [len(lines) - 1]
    a = xt[0]; b = len(lines)
    for j in range(a + 1, len(lines)):
        if re.match(r'^[A-Za-z_]', lines[j]): b = j; break
    while b > a + 1 and not lines[b - 1].strip(): b -= 1
    xi = next((len(l) - len(l.lstrip()) for l in lines[a + 1:b] if re.match(r'^\s*-\s+(from|to):', l)), 2)
    xs = ' ' * (xi + 2)
    add = []
    for fr, to in newx: add += [f'{" " * xi}- from: "{fr}"', f'{xs}to: {to}', f'{xs}edge_type: SUPERSEDES']
    lines = lines[:b] + add + lines[b:]
if newe:
    et = [i for i, l in enumerate(lines) if re.match(r'^edges\s*:', l)]
    if len(et) > 1: die('mais de um `edges:` no nível 0')
    if et and re.match(r'^edges\s*:\s*\[\s*\]\s*$', lines[et[0]]): lines[et[0]] = 'edges:'
    elif et and not re.match(r'^edges\s*:\s*$', lines[et[0]]): die('`edges:` fora da forma de bloco — escrita recusada')
    if not et:
        while lines and not lines[-1].strip(): lines.pop()
        lines += ['edges:']; et = [len(lines) - 1]
    a = et[0]; b = len(lines)
    for j in range(a + 1, len(lines)):
        if re.match(r'^[A-Za-z_]', lines[j]): b = j; break
    while b > a + 1 and not lines[b - 1].strip(): b -= 1
    ei = next((len(l) - len(l.lstrip()) for l in lines[a + 1:b] if re.match(r'^\s*-\s+from:', l)), 2)
    es = ' ' * (ei + 2)
    add = []
    for fr, to in newe: add += [f'{" " * ei}- from: {fr}', f'{es}to: {to}', f'{es}edge_type: SUPERSEDES']
    lines = lines[:b] + add + lines[b:]
out = '\n'.join(lines)
if not out.endswith('\n'): out += '\n'
try: d2 = yaml.safe_load(out) or {}
except Exception as e: die(f'a escrita não parseia ({one(e)[:120]})')
if len(d2.get('nodes') or []) != len(d0.get('nodes') or []): die('a escrita não releu com o mesmo número de nós')
by2 = {str(x.get('id')): x for x in (d2.get('nodes') or []) if isinstance(x, dict)}
for it in mine:
    n2 = by2.get(it['id']) or {}
    oldn = it['node'].get('narrative')
    oldn = '' if oldn is None else ('\n'.join(f'- {x}' for x in oldn) if isinstance(oldn, list) else str(oldn).rstrip('\n'))
    ok = str(n2.get('narrative', '')).startswith(oldn) and f'lote {sha12}' in str(n2.get('narrative', ''))
    if it['dest'] == 'obsolete':
        ok = ok and n2.get('status') == 'superseded' and str(n2.get('verified_at')) == date and n2.get('plane') == 'DEV'
    else:
        ok = ok and n2.get('status') == 'open' and n2.get('owner') == it['ref'] and str(n2.get('x_due')) == it['due']
    if not ok: die(f"{it['id']}: a escrita não releu como escrita")
open(stage, 'w', encoding='utf-8').write(out)
print(f"kg-decide-seal: lote {sha12} em {graph}: " + ', '.join(f"{it['id']}→{'obsoleto' if it['dest'] == 'obsolete' else 'pedido a ' + it['ref']}" for it in mine))
LOT
}
if [ -n "${BATCH}" ] && [ -z "${GRAPH}" ]; then
  [ -z "${NODE}${NEW}${CHOSEN}${REJECTED}${LABEL}${LINK}" ] && [ "${OTHER}" = "0" ] \
    || { echo "kg-decide-seal: --batch não se mistura com nó, --new, --chosen, --rejected, --label, --link nem --other" >&2; exit 2; }
  command -v python3 >/dev/null 2>&1 || { echo "kg-decide-seal: python3 ausente" >&2; exit 2; }
  if [ "${PREVIEW}" = "1" ]; then _lot_py check "${BATCH}" "" "${DATE}" "${QUESTION}" - - 1; exit $?; fi
  LOTG="$(_lot_py check "${BATCH}" "${APPROVE}" "${DATE}" "${QUESTION}" - - 0)" || exit 2
  # cópia de TODO grafo do lote antes do 1º: um grafo que reprova desfaz o lote INTEIRO, não só ele
  LOTBK="$(mktemp -d)"; trap 'rm -rf "${LOTBK}"' EXIT
  _gi=0; declare -a _LG=()
  while IFS= read -r _g; do
    [ -n "${_g}" ] || continue
    _gi=$((_gi + 1)); _LG+=("${_g}"); cp -p "${_g}" "${LOTBK}/${_gi}"; sha256sum "${_g}" | cut -d' ' -f1 > "${LOTBK}/${_gi}.sha"
  done <<< "${LOTG}"
  _lrc=0; _gi=0
  for _g in "${_LG[@]}"; do
    _gi=$((_gi + 1))
    bash "$0" "${_g}" --batch "${BATCH}" --approve "${APPROVE}" --date "${DATE}" --question "${QUESTION}" || { _lrc=$?; break; }
  done
  if [ "${_lrc}" -ne 0 ]; then
    _gi=0
    for _g in "${_LG[@]}"; do
      _gi=$((_gi + 1)); cp -p "${LOTBK}/${_gi}" "${_g}"
      [ "$(sha256sum "${_g}" | cut -d' ' -f1)" = "$(cat "${LOTBK}/${_gi}.sha")" ] \
        || { echo "❌ kg-decide-seal: o DESFAZER do lote falhou em ${_g} — restaure à mão (git checkout). NÃO COMMITE." >&2; exit 9; }
    done
    echo "kg-decide-seal: o lote NÃO foi aplicado (rc ${_lrc} num grafo) — os ${#_LG[@]} grafo(s) voltaram byte a byte" >&2
    [ "${_lrc}" -eq 2 ] && exit 2
    exit 3
  fi
  echo "kg-decide-seal: ✅ lote aplicado em ${#_LG[@]} grafo(s), cada um com o gate verde"
  exit 0
fi
if [ -n "${BATCH}" ]; then
  [ -z "${NODE}${NEW}${CHOSEN}${REJECTED}${LABEL}${LINK}" ] && [ "${OTHER}" = "0" ] && [ "${PREVIEW}" = "0" ] \
    || { echo "kg-decide-seal: --batch por grafo não se mistura com nó, --new, --chosen, --rejected, --label, --link, --other nem --preview" >&2; exit 2; }
fi
[ -n "${GRAPH}" ] || { sed -n '/^# Uso:/,/^# O que escreve/p' "$0" | sed '$d' >&2; exit 2; }
[ -f "${GRAPH}" ] || { echo "kg-decide-seal: grafo inexistente: ${GRAPH}" >&2; exit 2; }
# caminho ABSOLUTO desde já: o gate do contrato roda com `cd` na raiz, e um relativo deixava o contrato
# "não julgado" e o selo saindo 0 (achado 6 do refutador, 2026-10-12)
GRAPH="$(realpath -- "${GRAPH}")"
if [ -n "${NEW}" ] && [ -n "${NODE}" ]; then echo "kg-decide-seal: ou <NODE_ID> ou --new <D_ID>, nunca os dois" >&2; exit 2; fi
if [ -z "${BATCH}" ]; then
[ -n "${NEW}${NODE}" ] || { echo "kg-decide-seal: falta o nó (<NODE_ID> ou --new <D_ID>)" >&2; exit 2; }
[ -n "${CHOSEN}" ] || { echo "kg-decide-seal: falta --chosen (a opção que o maestro escolheu, literal)" >&2; exit 2; }
[ -n "${REJECTED}" ] || { echo "kg-decide-seal: falta --rejected (as opções oferecidas e descartadas, separadas por |) — o selo registra o que foi recusado" >&2; exit 2; }
fi
[ -n "${DATE}" ] || { echo "kg-decide-seal: falta --date AAAA-MM-DD" >&2; exit 2; }
# a PERGUNTA é obrigatória: é o único rastro, no selo, de que houve pergunta (achado 8 do refutador)
[ -n "${QUESTION}" ] || { echo "kg-decide-seal: falta --question (o texto da pergunta feita ao maestro) — selo sem pergunta registrada é testemunho sem rastro" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "kg-decide-seal: python3 ausente" >&2; exit 2; }
[ -f "${RADAR}" ] || { echo "kg-decide-seal: radar ausente: ${RADAR} — sem gate não selo" >&2; exit 2; }

# Passo 0 — não se sela grafo que o motor já reprova (o selo seria culpado por dívida alheia)
# EXCEÇÃO ÚNICA (2026-10-12, dogfood da triagem de um sinal de campo): com --new e --link, o nó de onde a decisão
# veio pode ter nascido no mesmo movimento — e então está ÓRFÃO até o selo criar a aresta que o liga. O radar
# recusava antes da aresta existir (a evidência nova e a decisão nova dependiam uma da outra). Tolera-se só
# isto: TODA linha ✗ do radar é "nó órfão" do próprio alvo do --link. Qualquer outra reprovação segue recusando,
# e o radar DEPOIS do selo (passo final) julga o grafo inteiro como sempre.
LINK_ORPHAN_TOLERATED=0
PRE_OUT="$(bash "${RADAR}" "${GRAPH}" --integrity --schema 2>&1)"; PRE_RC=$?
if [ "${PRE_RC}" -ne 0 ]; then
  _only_link_orphan=0
  if [ -n "${NEW}" ] && [ -n "${LINK}" ]; then
    _bad="$(printf '%s\n' "${PRE_OUT}" | grep '✗' | grep -v -F "nó órfão (grau 0): ${LINK}" || true)"
    _orf="$(printf '%s\n' "${PRE_OUT}" | grep -c -F "nó órfão (grau 0): ${LINK}" || true)"
    [ -z "${_bad}" ] && [ "${_orf}" -ge 1 ] && _only_link_orphan=1
  fi
  if [ "${_only_link_orphan}" -eq 1 ]; then
    LINK_ORPHAN_TOLERATED=1
    echo "kg-decide-seal: o alvo do --link (${LINK}) está órfão antes do selo — tolerado: a aresta do selo o liga (o radar e o contrato finais julgam)" >&2
  else
    echo "kg-decide-seal: ${GRAPH} JÁ reprova no radar --integrity --schema antes do selo — conserte antes; nada escrito" >&2; exit 2
  fi
fi
ROOT="$(git -C "$(dirname "${GRAPH}")" rev-parse --show-toplevel 2>/dev/null || true)"
# Leitor do contrato, por ordem: (1) o vendor do KG-SSOT (core e adotantes) pelo kg-contract-check, que mede
# a piora contra o HEAD; (2) o leitor de referência do PRÓPRIO produto (`tools/kg_validate.py`), num repo que
# é o KG-SSOT (o spec/release.json da raiz declara a tag kg-ssot-v*, pelo resolver único) e por isso não o vendoriza — julgamento absoluto do grafo (rc 0 passa, 1 reprova), e o passo 0
# já recusou o grafo que reprovava antes, então reprovar depois é culpa do selo. Sinal de campo do
# adotante KG-SSOT, 2026-10-12: lá o selador selava sem conferir o contrato. (3) nenhum: CRC=99, e a mensagem
# diz qual falta — repo git ou leitor de contrato.
CONTRACT_READER=""
# a pasta das ferramentas pelo resolver único (KG_SSOT_TOOLS → vendor/kg-ssot/tools → tools/ do produto). O kind
# decide o leitor: no PRÓPRIO produto (source) segue o leitor de referência absoluto, como antes; nos outros, o
# kg-contract-check, que resolve a mesma pasta.
. "${HERE}/../utils/kg/kgssot-tools.sh" 2>/dev/null || kgssot_tools_resolve() {  # sem o resolver: o vendor de hoje
  KGSSOT_TOOLS="$1/vendor/kg-ssot/tools"; KGSSOT_TOOLS_KIND=vendor; [ -d "${KGSSOT_TOOLS}" ] && return 0; KGSSOT_TOOLS=""; KGSSOT_TOOLS_KIND=""; return 1; }
KGSSOT_TOOLS=""; KGSSOT_TOOLS_KIND=""; [ -z "${ROOT}" ] || kgssot_tools_resolve "${ROOT}" || true
_contract() {  # COUT/CRC do contrato sobre o grafo; CRC=99 quando não há leitor de contrato
  if [ -n "${ROOT}" ] && [ "${KGSSOT_TOOLS_KIND}" != source ] && [ -n "${KGSSOT_TOOLS}" ] && [ -f "${KGSSOT_TOOLS}/kg_gate.py" ] && [ -f "${HERE}/kg-contract-check.sh" ]; then
    CONTRACT_READER="${KGSSOT_TOOLS_KIND:-vendor} kg-ssot (kg-contract-check)"
    COUT="$(cd "${ROOT}" && bash "${HERE}/kg-contract-check.sh" "${GRAPH}" 2>&1)"; CRC=$?
  elif [ -n "${ROOT}" ] && [ "${KGSSOT_TOOLS_KIND}" = source ] && [ -f "${KGSSOT_TOOLS}/kg_validate.py" ]; then
    CONTRACT_READER="tools/kg_validate.py (leitor de referência do produto)"
    COUT="$(cd "${ROOT}" && python3 -I -B "${KGSSOT_TOOLS}/kg_validate.py" "${GRAPH}" 2>&1)"; CRC=$?
  else COUT=""; CRC=99; fi
}
# e o CONTRATO também no passo 0 (achado 5 do refutador): dívida que o grafo já tinha na árvore seria
# atribuída ao selo, que sairia 3 "por culpa própria"
# a mesma exceção do passo 0: o contrato também acusa o órfão do alvo do --link (integrity.orphan-node); ali
# ele só é julgado DEPOIS do selo, quando a aresta já existe.
CRC=0; [ "${LINK_ORPHAN_TOLERATED}" -eq 1 ] || _contract
if [ "${CRC}" -eq 1 ]; then
  echo "kg-decide-seal: ${GRAPH} JÁ piora o contrato antes do selo (dívida pré-existente, não do selo) — conserte antes; nada escrito:" >&2
  printf '%s\n' "${COUT}" | head -6 >&2
  exit 2
fi

# O LINT DE NOMES, medido ANTES da escrita (o "depois" vem no gate final). VOCAB_READER vazio = não roda, com o
# porquê em VOCAB_WHY (declarado no fim, nunca calado). A comparação antes×depois é só do grafo tocado.
VOCAB_READER=""; VOCAB_WHY=""; VOCAB_REL=""; VOCAB_EXT=()
if [ -z "${ROOT}" ]; then VOCAB_WHY="fora de repo git"
elif [ -n "${KGSSOT_TOOLS}" ] && [ -f "${KGSSOT_TOOLS}/kg_vocab.py" ]; then VOCAB_READER="${KGSSOT_TOOLS}/kg_vocab.py"
else VOCAB_WHY="o repo não tem o kg_vocab.py (nem KG_SSOT_TOOLS, nem vendor/kg-ssot/tools, nem tools/ do produto)"; fi
if [ -n "${VOCAB_READER}" ]; then
  # o caminho do grafo como o lint o escreve (relativo à raiz); python e não `realpath --relative-to`, que é só GNU
  VOCAB_REL="$(python3 -I -c 'import os, sys; print(os.path.relpath(os.path.realpath(sys.argv[2]), os.path.realpath(sys.argv[1])))' "${ROOT}" "${GRAPH}")"
  if ! git -C "${ROOT}" ls-files --error-unmatch -- "${VOCAB_REL}" >/dev/null 2>&1; then
    VOCAB_WHY="o grafo não é rastreado pelo git (o lint lê só os rastreados; rode-o depois do git add)"; VOCAB_READER=""
  fi
fi
if [ -n "${VOCAB_READER}" ] && [ -f "${ROOT}/.kg-ssot/vocab-externals.tsv" ]; then
  while IFS=$'\t' read -r _vs _vr _vrest; do
    case "${_vs}" in ''|'#'*) continue ;; esac
    { [ -n "${_vr}" ] && [ -z "${_vrest:-}" ]; } || { VOCAB_WHY="linha malformada em .kg-ssot/vocab-externals.tsv (${_vs})"; VOCAB_READER=""; break; }
    VOCAB_EXT+=(--external "${_vs}=${_vr}")
  done < "${ROOT}/.kg-ssot/vocab-externals.tsv"
fi
VB="$(mktemp)"; VA="$(mktemp)"
_vocab() {  # $1=arquivo de saída: o JSON do lint sobre o corpus; rc além de 0|1 = não julgou
  (cd "${ROOT}" && python3 -I -B "${VOCAB_READER}" lint --root . --format json ${VOCAB_EXT[@]+"${VOCAB_EXT[@]}"}) > "$1" 2>/dev/null
}
if [ -n "${VOCAB_READER}" ]; then
  _vrc=0; _vocab "${VB}" || _vrc=$?
  if [ "${_vrc}" -gt 1 ]; then VOCAB_WHY="o lint saiu rc ${_vrc} antes do selo (não julgou)"; VOCAB_READER=""; fi
fi

BK="$(mktemp)"; STAGE="$(mktemp)"; trap 'rm -f "${BK}" "${STAGE}" "${VB}" "${VA}"' EXIT
cp -p "${GRAPH}" "${BK}"
H0="$(sha256sum "${GRAPH}" | cut -d' ' -f1)"

# a escrita vai PRIMEIRO para o STAGE: o teto (abaixo) julga o grafo como ficaria, e só então ele vai ao disco
if [ -n "${BATCH}" ]; then
  # modo lote por grafo: o MESMO validador do modo externo (aprovação, destino, nó open) e a escrita no STAGE
  PYOUT="$(_lot_py write "${BATCH}" "${APPROVE}" "${DATE}" "${QUESTION}" "${GRAPH}" "${STAGE}" 0)" || exit 2
else
PYOUT="$(PYTHONDONTWRITEBYTECODE=1 python3 -I -B - "${GRAPH}" "${NODE}" "${NEW}" "${CHOSEN}" "${REJECTED}" "${DATE}" \
  "${QUESTION}" "${OTHER}" "${LABEL}" "${LINK}" "${ETYPE}" "${IMPACT}" "${STAGE}" <<'PY'
import sys, re, datetime
path, node, new, chosen, rejected, date, question, other, label, link, etype, impact, stage = sys.argv[1:14]
def die(m): print('kg-decide-seal: ' + m + ' — nada escrito', file=sys.stderr); sys.exit(2)
try:
    import yaml
except ImportError:
    die('PyYAML ausente (fail-loud)')
if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', date): die(f'--date fora de AAAA-MM-DD: {date}')
try: datetime.date.fromisoformat(date)
except ValueError: die(f'--date não é data real: {date}')
import os
today = os.environ.get('DECIDE_SEAL_TODAY') or datetime.date.today().isoformat()
if date > today: die(f'--date no futuro ({date} > {today}): o selo registra uma resposta que já foi dada')
one = lambda s: ' '.join(str(s).split())
chosen = one(chosen); rej = [one(x) for x in rejected.split('|') if one(x)]
if not chosen: die('--chosen vazio depois de normalizar espaços: resposta ambígua não sela')
if not rej: die('--rejected sem nenhuma opção legível')
if any(c in x for x in [chosen] + rej for c in '«»'): die('opção com « ou »: são o delimitador do selo na narrative — reescreva sem eles')
if chosen.casefold() in {r.casefold() for r in rej}: die('a opção escolhida também está em --rejected (comparado sem caixa)')
txt = open(path, encoding='utf-8').read()
try: d = yaml.safe_load(txt) or {}
except Exception as e: die(f'YAML ilegível: {one(e)[:160]}')
nodes = d.get('nodes') or []
byid = {}
for n in nodes:
    if isinstance(n, dict) and 'id' in n: byid.setdefault(str(n['id']), []).append(n)
def q(s): return '"' + one(s).replace('\\', '\\\\').replace('"', '\\"') + '"'
lines = txt.split('\n')
seal_txt = (f'Selado por /meta:decide em {date}: escolhida «{chosen}»'
            + (' (resposta livre do maestro, fora das opções oferecidas)' if other == '1' else '')
            + '; descartadas: ' + ' · '.join(f'«{r}»' for r in rej) + '.')
vag = f'decisão do maestro em {date}, por pergunta com opções (/meta:decide): escolhida «{chosen}»'
method = f'testimony: decisão do maestro por pergunta com opções, {date}'
locator = f'pergunta com opções de {date}' + (f': «{one(question)}»' if question else '')

def narr_block(fi, old, tail):
    s = ' ' * (fi + 2)
    body = (old.split('\n') + [''] if old else []) + tail
    return [' ' * fi + 'narrative: |-'] + [(s + l) if l.strip() else '' for l in body]

def prov_lines(fi):
    s = ' ' * fi
    return [f'{s}provenance:', f'{s}  source: "maestro, na sessão do /meta:decide"', f'{s}  locator: {q(locator)}',
            f'{s}  method: {q(method)}', f'{s}  locality: "pessoa"']

if not new:
    if node not in byid: die(f'nó inexistente em {path}: {node}')
    if len(byid[node]) > 1: die(f'id duplicado em {path}: {node}')
    n = byid[node][0]
    if n.get('node_type') not in ('decision', 'question'): die(f'{node} é {n.get("node_type")}, não decision|question — não se "decide" um nó desse tipo')
    st = n.get('status')
    # lista POSITIVA (achado 1 do refutador): a negativa deixava re-carimbar `confirmed` em PROD com proveniência
    # medida — 195 decisões do corpus expostas. Só `open` está em aberto para o maestro.
    if st != 'open': die(f'{node} está {st}, não open — selo não se re-carimba; decisão nova é nó novo (--new) que SUPERSEDES')
    def _blind(o, top=True):   # chave cega em qualquer nível; VALOR cego só abaixo do 1º nível (prosa fica fora)
        out = []
        if isinstance(o, dict):
            for k, v in o.items():
                if re.search(r'blind|cego', str(k), re.I): out.append(str(k))
                if isinstance(v, (dict, list)): out += _blind(v, False)
                elif not top and isinstance(v, str) and re.search(r'blind|cego', v, re.I): out.append(f'{k}={v}')
        elif isinstance(o, list):
            for v in o: out += _blind(v, False)
        return out
    blind = _blind(n)
    if blind: die(f'{node} tem campo CEGO ({", ".join(blind)}): gate humano às cegas não recebe selo de sessão')
    hits = [i for i, l in enumerate(lines) if re.match(r'^(\s*)-\s+id:\s*["\']?' + re.escape(node) + r'["\']?\s*(#.*)?$', l)]
    if len(hits) != 1: die(f'{node}: não achei UMA linha `- id:` em forma de bloco (achei {len(hits)})')
    i = hits[0]; ind = len(lines[i]) - len(lines[i].lstrip()); fi = ind + 2
    end = len(lines)
    for j in range(i + 1, len(lines)):
        l = lines[j]
        if not l.strip(): continue
        lind = len(l) - len(l.lstrip())
        if lind < ind or (lind == ind and l.lstrip().startswith('-')) or (lind <= ind and l.lstrip().startswith('#')):
            end = j; break
    while end > i + 1 and not lines[end - 1].strip(): end -= 1
    drop = {'status', 'verified_at', 'verified_against', 'provenance', 'narrative', 'plane'}
    body = []; k = i + 1
    while k < end:
        l = lines[k]; lind = len(l) - len(l.lstrip())
        m = re.match(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:', l)
        if lind == fi and m and m.group(1) in drop:
            k += 1
            while k < end and (not lines[k].strip() or len(lines[k]) - len(lines[k].lstrip()) > fi): k += 1
            continue
        body.append(l); k += 1
    # a narrative anterior é PRESERVADA verbatim num bloco `|-` (achado 3: o achatamento mutilava listas e
    # parágrafos); a proveniência anterior vai INTEIRA (achado 2: só o source sobrevivia)
    oldn = n.get('narrative')
    if isinstance(oldn, list): oldn = '\n'.join(f'- {x}' for x in oldn)
    oldn = '' if oldn is None else str(oldn).rstrip('\n')
    prev = []
    if n.get('verified_against'): prev.append(f'verified_against anterior: «{one(n["verified_against"])}»')
    if isinstance(n.get('provenance'), dict) and n['provenance']:
        prev.append('proveniência anterior: ' + ' · '.join(f'{k} «{one(v)}»' for k, v in n['provenance'].items()))
    if n.get('plane') == 'PROD': prev.append('plane anterior: PROD, rebaixado a DEV porque a base do selo é testemunho (contrato: integrity.testimony-in-prod)')
    s = ' ' * fi
    add = [f'{s}status: done', f'{s}plane: DEV']
    add += [f'{s}verified_at: "{date}"', f'{s}verified_against: {q(vag)}', ] + narr_block(fi, oldn, prev + [seal_txt]) + prov_lines(fi)
    out = '\n'.join(lines[:i + 1] + body + add + lines[end:])
    target = node
else:
    if not re.fullmatch(r'D_[A-Z0-9_]+', new): die(f'--new exige id D_[A-Z0-9_]+ (achei {new})')
    if new in byid: die(f'{new} já existe em {path} — decisão existente se sela pelo id, não por --new')
    if not label: die('--new exige --label (a afirmação curta da decisão)')
    if len(label) > 280: die(f'--label com {len(label)} caracteres (teto 280; o porquê vai na narrative)')
    if not link: die('--new exige --link <ID> (nó sem aresta é órfão no radar; a ligação diz de onde a decisão veio)')
    if link not in byid: die(f'--link aponta nó inexistente em {path}: {link}')
    if etype not in ('SUPPORTS', 'REFUTES', 'SUPERSEDES', 'CAUSES', 'DEPENDS_ON', 'TRACES_TO', 'CONSTRAINS'): die(f'--edge-type fora da gramática audit: {etype}')
    if not re.fullmatch(r'[1-5]', impact): die(f'--impact fora de 1–5: {impact}')
    top = [i for i, l in enumerate(lines) if re.match(r'^nodes\s*:\s*$', l)]
    if len(top) != 1: die('não achei UM `nodes:` de bloco no nível 0')
    a = top[0]; b = len(lines)
    for j in range(a + 1, len(lines)):
        if re.match(r'^[A-Za-z_]', lines[j]): b = j; break
    while b > a + 1 and not lines[b - 1].strip(): b -= 1
    ii = next((len(l) - len(l.lstrip()) for l in lines[a + 1:b] if re.match(r'^\s*-\s+id:', l)), 2)
    s = ' ' * (ii + 2)
    nl = [f'{" " * ii}- id: {new}', f'{s}node_type: decision', f'{s}layer: audit', f'{s}plane: DEV', f'{s}status: done',
          f'{s}impact: {impact}', f'{s}confidence: 0.9', f'{s}verified_at: "{date}"', f'{s}verified_against: {q(vag)}',
          f'{s}label: {q(label)}', f'{s}narrative: {q(seal_txt)}'] + prov_lines(ii + 2)
    lines = lines[:b] + nl + lines[b:]
    et = [i for i, l in enumerate(lines) if re.match(r'^edges\s*:', l)]
    if len(et) > 1: die('mais de um `edges:` no nível 0')
    if et and re.match(r'^edges\s*:\s*\[\s*\]\s*$', lines[et[0]]): lines[et[0]] = 'edges:'
    elif et and not re.match(r'^edges\s*:\s*$', lines[et[0]]): die('`edges:` fora da forma de bloco — escrita recusada')
    if not et:
        while lines and not lines[-1].strip(): lines.pop()
        lines += ['edges:']; et = [len(lines) - 1]
    a = et[0]; b = len(lines)
    for j in range(a + 1, len(lines)):
        if re.match(r'^[A-Za-z_]', lines[j]): b = j; break
    while b > a + 1 and not lines[b - 1].strip(): b -= 1
    ei = next((len(l) - len(l.lstrip()) for l in lines[a + 1:b] if re.match(r'^\s*-\s+from:', l)), 2)
    es = ' ' * (ei + 2)
    lines = lines[:b] + [f'{" " * ei}- from: {new}', f'{es}to: {link}', f'{es}edge_type: {etype}'] + lines[b:]
    out = '\n'.join(lines)
    if not out.endswith('\n'): out += '\n'
    target = new
# releitura: a escrita tem de reler como escrita, senão nada vai ao disco
try: d2 = yaml.safe_load(out) or {}
except Exception as e: die(f'a escrita não parseia ({one(e)[:120]})')
m2 = [n for n in (d2.get('nodes') or []) if isinstance(n, dict) and str(n.get('id')) == target]
want_n = len(nodes) + (1 if new else 0)
if len(m2) != 1 or len(d2.get('nodes') or []) != want_n: die('a escrita não releu com o mesmo número de nós')
n2 = m2[0]
if (n2.get('status') != 'done' or n2.get('plane') != 'DEV' or str(n2.get('verified_at')) != date or (n2.get('provenance') or {}).get('method') != method
        or f'«{chosen}»' not in str(n2.get('narrative')) or any(f'«{r}»' not in str(n2.get('narrative')) for r in rej)):
    die('a escrita não releu como escrita (status/verified_at/method/narrative)')
if not new and oldn and not str(n2.get('narrative')).startswith(oldn):
    die('a narrative anterior não sobreviveu verbatim à escrita')
open(stage, 'w', encoding='utf-8').write(out)
print(f'kg-decide-seal: escrito {target} em {path} — escolhida «{chosen}», descartadas {len(rej)}')
PY
)" || exit 2
fi

# O TETO do `meta:` (dano medido, 2026-10-13): o --new criou o 65º nó num grafo que declara TETO de 64 e saiu
# rc 0; só a REGRA 58 (O backlog cumpre as promessas do próprio `meta:`) acusou, no pr-finalize. O selador cobra o
# MESMO teto, pela MESMA convenção e pelo MESMO leitor da REGRA 58: no escopo dela (o marcador
# `# kg-backlog-guard: on`), o kg-backlog-check.sh julga o grafo como ficaria, e o veredito é a TAG (TETO,
# SEM-TETO), nunca o texto da mensagem. Teto estourado ou não declarado = rc 2, nada escrito. Fora do escopo da
# REGRA 58 o selador não inventa teto (a guarda erra para o lado de calar). Só o --new muda a contagem.
if [ -n "${NEW}" ] && grep -qE '^[[:space:]]*#[[:space:]]*kg-backlog-guard:[[:space:]]*on\b' "${GRAPH}"; then
  BACKLOG="${HERE}/kg-backlog-check.sh"
  [ -f "${BACKLOG}" ] || { echo "kg-decide-seal: ${GRAPH} declara kg-backlog-guard e o leitor do teto (kg-backlog-check.sh) não está ao lado — sem ler o teto não crio nó; nada escrito" >&2; exit 2; }
  BRC=0; BOUT="$(bash "${BACKLOG}" "${STAGE}" --format tsv 2>&1)" || BRC=$?
  if [ "${BRC}" -ge 2 ]; then
    echo "kg-decide-seal: o leitor do teto saiu rc ${BRC} (erro de execução, não veredito) — nada escrito: $(printf '%s' "${BOUT}" | head -1)" >&2; exit 2
  fi
  BTETO="$(printf '%s\n' "${BOUT}" | awk -F'\t' '$1 == "HARD" && ($2 == "TETO" || $2 == "SEM-TETO") { print $2 "\t" $4; exit }')"
  if [ -n "${BTETO}" ]; then
    echo "kg-decide-seal: --new ${NEW} não cabe no TETO do meta: de ${GRAPH} [${BTETO%%$'\t'*}] — ${BTETO#*$'\t'}. Nada escrito. Suba o TETO no meta: com o motivo (+1 justificado, como as linhas dele), ou reconcilie antes (colha ou funda um nó), e sele de novo." >&2
    exit 2
  fi
fi
cat "${STAGE}" > "${GRAPH}"
printf '%s\n' "${PYOUT}"

_undo() {
  cp -p "${BK}" "${GRAPH}"
  [ "$(sha256sum "${GRAPH}" | cut -d' ' -f1)" = "${H0}" ] \
    || { echo "❌ kg-decide-seal: o DESFAZER falhou em ${GRAPH} — restaure à mão (git checkout). NÃO COMMITE." >&2; exit 9; }
}
if ! ROUT="$(bash "${RADAR}" "${GRAPH}" --integrity --schema 2>&1)"; then
  _undo
  echo "kg-decide-seal: o radar REPROVOU o grafo selado — escrita DESFEITA (byte a byte):" >&2
  printf '%s\n' "${ROUT}" | grep -m5 '✗' >&2 || printf '%s\n' "${ROUT}" | tail -5 >&2
  exit 3
fi
_contract
if [ "${CRC}" -ne 99 ]; then
  if [ "${CRC}" -eq 1 ]; then
    _undo
    echo "kg-decide-seal: o contrato REPROVOU o grafo selado — escrita DESFEITA:" >&2
    printf '%s\n' "${COUT}" | head -6 >&2
    exit 3
  elif [ "${CRC}" -ne 0 ]; then
    echo "kg-decide-seal: ⚠️ contrato NÃO JULGADO (rc ${CRC}) — o radar passou, o contrato não foi verificado: $(printf '%s' "${COUT}" | head -1)" >&2
  fi
else
  if [ -z "${ROOT}" ]; then
    echo "kg-decide-seal: fora de repo git — sem leitor de contrato; gate = só o radar (declarado)" >&2
  else
    echo "kg-decide-seal: repo git sem leitor de contrato (nem KG_SSOT_TOOLS, nem vendor/kg-ssot, nem tools/kg_validate.py com spec/release.json do kg-ssot) — gate = só o radar (declarado)" >&2
  fi
fi
# O LINT DE NOMES, depois: o achado que o grafo tocado NÃO tinha antes é do selo → desfaz, rc 3, nomeando
# código, campo e nó. Decide pelo rc e pelo JSON do lint, nunca pela prosa dele (o vendor fala conforme o locale).
_vsuf=""
if [ -n "${VOCAB_READER}" ]; then
  _vrc=0; _vocab "${VA}" || _vrc=$?
  if [ "${_vrc}" -gt 1 ]; then
    VOCAB_WHY="o lint saiu rc ${_vrc} depois do selo (não julgou)"
  else
    _drc=0
    VDELTA="$(python3 -I -B - "${VB}" "${VA}" "${VOCAB_REL}" <<'VPY'
import json, sys
def rows(p):
    d = json.load(open(p, encoding='utf-8'))
    l = d.get('lint') if isinstance(d, dict) else None
    if d.get('schema_version') != 'kg-ssot.vocab/1' or not isinstance(l, dict) or not isinstance(l.get('findings'), list):
        sys.exit(2)
    out = {}
    for f in l['findings']:
        if isinstance(f, dict) and f.get('file') == sys.argv[3]:
            k = (str(f.get('id')), str(f.get('field')), str(f.get('code')), str(f.get('token')))
            out[k] = out.get(k, 0) + 1
    return out
try:
    b, a = rows(sys.argv[1]), rows(sys.argv[2])
except (OSError, ValueError, AttributeError):
    sys.exit(2)
new = [k for k, n in sorted(a.items()) if n > b.get(k, 0)]
for nid, field, code, token in new:
    print(f'«{token}» no campo {field} do nó {nid} ({code})')
sys.exit(1 if new else 0)
VPY
)" || _drc=$?
    if [ "${_drc}" -eq 1 ]; then
      _undo
      echo "kg-decide-seal: o lint de nomes REPROVOU o que o selo escreveu — escrita DESFEITA:" >&2
      printf '%s\n' "${VDELTA}" | head -6 | sed 's/^/  ✗ /' >&2
      echo "  O selo copia o texto anterior (verified_against, proveniência) e as opções para a narrative, que o lint lê. Glose o código na origem (esquema:código, ou um x_term com a notation) e sele de novo." >&2
      exit 3
    elif [ "${_drc}" -ne 0 ]; then VOCAB_WHY="o JSON do lint veio com forma inesperada (não julgou)"
    else _vsuf=" · nomes sem achado novo por $(basename "${VOCAB_READER}")"; fi
  fi
fi
if [ -z "${_vsuf}" ]; then
  echo "kg-decide-seal: ⚠️ lint de nomes não rodou — ${VOCAB_WHY}" >&2
  _vsuf=" · nomes NÃO julgados"
fi
# "contrato rc 0" só quando o contrato JULGOU e passou (passada adversarial de 2026-10-15): com o vendor agora
# viajando, um adotante sem PyYAML/jsonschema tem leitor e CRC=2 — o sufixo afirmava rc 0 logo depois do aviso
# "contrato NÃO JULGADO".
_csuf=""; [ -n "${CONTRACT_READER}" ] && [ "${CRC}" -eq 0 ] && _csuf=" · contrato rc 0 por ${CONTRACT_READER}"
[ -n "${CONTRACT_READER}" ] && [ "${CRC}" -ne 0 ] && [ "${CRC}" -ne 99 ] && _csuf=" · contrato NÃO julgado (rc ${CRC})"
echo "kg-decide-seal: ✅ selado — radar --integrity --schema exit 0${_csuf}${_vsuf}"
exit 0
