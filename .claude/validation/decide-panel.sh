#!/usr/bin/env bash
# ===========================================================================
# decide-panel.sh — o questionário do /meta:decide em JSON, e a volta das respostas pelo MESMO selador.
#
# Ao lado do medidor (decide-census.sh, peça 3) e do selador (kg-decide-seal.sh, peça 5). Serve o modo
# OPCIONAL `--painel` do /meta:decide: o maestro responde a rodada num painel (um Artifact com estado,
# no navegador ou no celular) em vez do AskUserQuestion do terminal. O AskUserQuestion segue o padrão.
#
# Origem do conceito (reescrita, não cópia): a UI bidirecional do MCP Apps (spec Stable 2026-01-26,
# Apache-2.0), github.com/modelcontextprotocol/ext-apps @ 82221c0c8ce7661efa6771c9d461511b1650495f,
# specification/2026-01-26/apps.mdx — a interface devolve dados ao host, e o que ela devolve é ENTRADA
# NÃO CONFIÁVEL. Nenhum código de terceiro vem junto. Decisão D_INTELLIGENT_UI_1021 (opção B, 2026-10-21),
# plano A_ABSORB_DECIDE_PAINEL_INTERATIVO, em docs/evolution/dissect/intelligent-ui-2026-10/.
#
# Uso:
#   bash .claude/validation/decide-panel.sh round [<repo>] --compose <arquivo.json> [--ask] [--from-tsv <arq>]
#                                                [--today AAAA-MM-DD] [argumentos do decide-census...]
#   bash .claude/validation/decide-panel.sh seal <round.json> <respostas> [--other <qN>]... [--only <qN>]... [--repo <raiz>]
#                                                [--dry-run]
#
#   round   roda o medidor (--tsv; ou lê --from-tsv) e monta a rodada a partir do arquivo que a sessão compôs.
#           A saída padrão é o JSON do PAINEL (schema onion.decide.panel/v1); com --ask, o payload do
#           AskUserQuestion da MESMA rodada. As duas saem do mesmo modelo, e a bancada exige a paridade.
#   seal    lê as respostas (um .json, ou o diretório que o ArtifactData grava com out_dir) e, para cada
#           uma, chama SÓ o kg-decide-seal.sh (lista de argumentos, nunca shell). Nunca abre o grafo para
#           escrever. Emite o estado por item (schema onion.decide.status/v1, cada item com o round_id), que a
#           sessão grava em status/<qN> do painel. `--only qN` (repetível) restringe a passada: a 2ª passada
#           (a do texto livre lido) vai só nele, para não re-chamar o selador sobre o que já selou.
#
# Arquivo de composição (a sessão escreve; é o julgamento do passo 2 e 3 do comando, não do medidor):
#   {"questions": [
#     {"ref": "<ID do nó, linha seal do censo>", "header": "≤12", "question": "...",
#      "options": [{"label": "...", "description": "...", "cost": "..."}, ...], "recommended": 0,
#      "destination": "mechanism", "guard": "<CARD-123|Q_ID>"},          (ou "destination": "design", sem guard)
#     {"ref": "<ref de linha de ATO do censo: PR#7, a branch, o grafo do checkpoint>", "question": "..."}
#   ]}
#   - pergunta de SELO: 2 a 4 opções compostas; `recommended` = índice (ou null: empate declarado, sem marca).
#     A recomendada vai para o 1º lugar e ganha " (Recomendado)" no rótulo.
#     `destination` é obrigatório (mechanism|design), e `guard` só com mechanism: vão ao selador como --destination e
#     --guard (ADR onion-adr-decision-destination-2026-11). A forma é conferida aqui, para a rodada não nascer com um
#     selo que o selador recusaria; o Q_ existir no grafo, o selador confere.
#   - pergunta de ATO: as opções NÃO se compõem, saem da classe medida (cláusula 8): faço-eu =
#     "Eu faço agora (Recomendado)" · "Me dê o passo a passo" · "Depois"; maestro-com-! e maestro-fora =
#     "Me dê o passo a passo (Recomendado)" · "Já fiz, confira" · "Depois". outro-dono não vira pergunta.
#   - ref que o censo não mediu é RECUSADO (não se pergunta sobre o que não foi medido). Linha do censo
#     que a composição não cita sai em `not_asked`, nomeada (o filtro não apaga em silêncio).
#   - teto do AskUserQuestion: 4 perguntas por rodada; a 5ª em diante vai para `deferred`, nomeada.
#
# Kit de revisão do hub (2026-11-26; o hub mediu 111 respostas em duas noites com decisor não técnico). Campos opcionais:
#   {"panel_only": true, ...}       rodada só-painel: pergunta de selo com 2 a 6 opções. O `--ask` dessa rodada sai
#                                   rc 2 nomeando cada pergunta com mais de 4 (o teto do AskUserQuestion não muda).
#   "cite_id": "DEMO-P01"           id citável e estável entre rodadas (PREFIXO-L00[a-z]); fora do round_id.
#   "kind": "verify"                correção para conferir, sobre linha de SELO do censo: opções fixas "Confere" (sela
#                                   pelo selador com destination design) / "Ainda não" (não sela: "não confere").
#   "resolved_by": "<regra ou nó>"  já resolvido pelas regras da pessoa: sai em `resolved` (recolhido), não é pergunta,
#                                   não conta no teto, não sela.
#   "view": {explanation, why, images: [{path|src, caption}], annotate, upload: {url, what, expires}, source_url}
#                                   APRESENTAÇÃO, fora do round_id e nunca argumento do selador. `path` é PNG/JPEG/WebP
#                                   dentro da pasta da composição, até 96 KiB, embutido; maior vai pelo asset store do
#                                   Artifact como `src` /_blob/<id>. `upload` é só um link https sem query, com prazo
#                                   (expires >= hoje), criado fora do painel: a página não recebe arquivo nem credencial.
#   Texto com "[A CONFIRMAR]" recusa a rodada. O round_id cobre o que sela ou vira ato: id, tipo, ref, pergunta, opções,
#   texto livre, selo, classe e card do ato e origem, mais data e nonce. Fora fica só a apresentação (cabeçalho,
#   cite_id, view): trocar um print não invalida a resposta, trocar uma opção ou o card invalida. O seal aceita também
#   o hash da rodada emitida antes do kit (a pergunta inteira, que cobre mais). Condição de remoção desse caminho: a
#   rodada vive horas (a sessão a refaz a cada /meta:decide), então ele sai no 1º PR que tocar o seal depois de
#   2026-12-26; a bancada (mutante sem-legado) cai junto.
#   A resposta pode levar "annotation" (estado do marker.js) e "note" (nota do Ainda não): o estado do item sai com
#   annotated/note para a sessão LER; nenhum dos dois vira argumento do selador.
#
# Resposta (o painel grava em answers/<qN>; dado NÃO CONFIÁVEL, como o structuredContent do Apps SDK):
#   {"round_id": "...", "qid": "q1", "choice": "<rótulo exato>", "other": "<texto livre>"}
#   - round_id que não é o da rodada local → recusada (rodada velha ou forjada);
#   - choice que não é EXATAMENTE um rótulo oferecido → recusada (fora das opções);
#   - other (texto livre) só sela com `--other <qN>` passado pela sessão depois de ler o texto, e só em
#     pergunta de selo; sem a flag volta como pergunta. Choice e other juntos, ou nenhum = ambígua, não sela.
#   O round.json lido é o LOCAL que este script emitiu: o do painel nunca é fonte. O round_id é o hash das
#   perguntas, da data e de um nonce da emissão: ele DETECTA a edição que não recalculou o hash, não é
#   assinatura com chave. Por isso o seal também revalida o que vira argumento (nó e grafo).
#
# Env (bancada; NUNCA em produção — o override ativo é declarado em stderr):
#   DECIDE_PANEL_SEAL=<script>   selador alternativo (a bancada injeta um gravador de argumentos)
#   DECIDE_PANEL_CENSUS=<script> medidor alternativo
#   DECIDE_PANEL_NONCE=<texto>   nonce fixo da rodada (a bancada fixa; em produção é aleatório, para que a
#                                mesma composição no mesmo dia gere OUTRO round_id e uma resposta velha não valha)
# Exit: 0 = rodada emitida / respostas processadas (o estado por item diz o que selou) ·
#       2 = entrada quebrada (composição inválida, ref não medido, round adulterado, rótulo com « » ou |).
# Determinístico, sem LLM, 0 tokens. Exercitado por lint-selftest.sh (run_decide_selftests, casos p*).
# ===========================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEAL="${DECIDE_PANEL_SEAL:-${HERE}/kg-decide-seal.sh}"
CENSUS="${DECIDE_PANEL_CENSUS:-${HERE}/decide-census.sh}"
[ -n "${DECIDE_PANEL_SEAL:-}" ] && echo "decide-panel: ⚠️ override ativo — DECIDE_PANEL_SEAL=${DECIDE_PANEL_SEAL} (não é o selador de produção)" >&2
[ -n "${DECIDE_PANEL_NONCE:-}" ] && echo "decide-panel: ⚠️ override ativo — DECIDE_PANEL_NONCE fixo (não é o nonce de produção)" >&2
[ -n "${DECIDE_PANEL_CENSUS:-}" ] && echo "decide-panel: ⚠️ override ativo — DECIDE_PANEL_CENSUS=${DECIDE_PANEL_CENSUS} (não é o medidor de produção)" >&2
command -v python3 >/dev/null 2>&1 || { echo "decide-panel: python3 ausente" >&2; exit 2; }
MODE="${1:-}"; shift || true
_need() { [ $# -ge 2 ] && [ -n "$2" ] || { echo "decide-panel: $1 exige um valor" >&2; exit 2; }; }
TMPD="$(mktemp -d)"; trap 'rm -rf "${TMPD}"' EXIT

case "${MODE}" in
  round)
    REPO=""; COMPOSE=""; ASK="0"; FROMTSV=""; TODAY="${DECIDE_TODAY:-$(date +%F)}"; CARGS=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --compose) _need "$@"; shift; COMPOSE="$1" ;;
        --ask) ASK="1" ;;
        --from-tsv) _need "$@"; shift; FROMTSV="$1" ;;
        --today) _need "$@"; shift; TODAY="$1" ;;
        --cite|--theme|--window|--foreign-repo) _need "$@"; CARGS+=("$1" "$2"); shift ;;
        --no-gh) CARGS+=("$1") ;;
        --*) echo "decide-panel: opção desconhecida: $1" >&2; exit 2 ;;
        *) [ -z "${REPO}" ] && REPO="$1" || { echo "decide-panel: argumento a mais: $1" >&2; exit 2; } ;;
      esac
      shift
    done
    [ -n "${COMPOSE}" ] && [ -r "${COMPOSE}" ] || { echo "decide-panel: round exige --compose <arquivo.json> legível (a rodada é composta pela sessão; o medidor só lista)" >&2; exit 2; }
    if [ -n "${FROMTSV}" ]; then
      [ -r "${FROMTSV}" ] || { echo "decide-panel: --from-tsv ilegível: ${FROMTSV}" >&2; exit 2; }
      cp "${FROMTSV}" "${TMPD}/census.tsv"
    else
      if ! bash "${CENSUS}" "${REPO:-.}" --tsv "${CARGS[@]}" > "${TMPD}/census.tsv" 2> "${TMPD}/census.err"; then
        echo "decide-panel: o medidor saiu com erro — sem censo não há rodada: $(head -2 "${TMPD}/census.err")" >&2; exit 2
      fi
    fi
    PYTHONDONTWRITEBYTECODE=1 python3 -I -B - round "${TMPD}/census.tsv" "${COMPOSE}" "${ASK}" "${TODAY}" "${DECIDE_PANEL_NONCE:-}" <<'PY'
import sys, os, json, hashlib, uuid, base64
from datetime import date
_, census, compose, ask, today, nonce = sys.argv[1:7]
def round_id(qs, today, nonce):
    # o round_id cobre o que sela ou vira ato (decisão do core, 2026-11-26): id, tipo, ref, pergunta, opções, texto
    # livre, o selo, a classe e o card do ato (o comando que a sessão roda no "executar") e a origem, mais a data e o
    # nonce. Fica FORA só a apresentação: cabeçalho, cite_id e view (imagens, explicação, link de envio): trocar um
    # print não invalida a resposta já dada.
    core = [dict({k: q.get(k) for k in ('id', 'kind', 'ref', 'question', 'allow_other', 'seal', 'actor', 'card', 'origin')},
                 options=[{k: o.get(k) for k in ('label', 'description', 'cost')} for o in (q.get('options') or [])]) for q in qs]
    canon = json.dumps({'questions': core, 'today': today, 'nonce': nonce}, ensure_ascii=False, sort_keys=True, separators=(',', ':'))
    return hashlib.sha256(canon.encode('utf-8')).hexdigest()[:16]
def round_id_legacy(qs, today, nonce):
    # hash da rodada emitida ANTES do kit (a pergunta inteira): cobre mais, então aceitá-lo é seguro; sem ele, a
    # rodada em voo no merge perderia as respostas já dadas no painel
    canon = json.dumps({'questions': qs, 'today': today, 'nonce': nonce}, ensure_ascii=False, sort_keys=True, separators=(',', ':'))
    return hashlib.sha256(canon.encode('utf-8')).hexdigest()[:16]
nonce = nonce or uuid.uuid4().hex
def die(m): print(f'decide-panel: {m}', file=sys.stderr); sys.exit(2)
import re
if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', today): die(f'--today inválido ({today}) — AAAA-MM-DD')
rows = []
with open(census, encoding='utf-8') as f:
    head = f.readline().rstrip('\n').split('\t')
    if head[:2] != ['kind', 'ref'] or 'actor' not in head: die('o censo não está na forma --tsv (cabeçalho kind/ref/…/actor)')
    for l in f:
        c = l.rstrip('\n').split('\t')
        r = dict(zip(head, c + [''] * (len(head) - len(c))))
        if r['kind'] != 'warn': rows.append(r)
try:
    comp = json.load(open(compose, encoding='utf-8'))
except Exception as e: die(f'composição ilegível: {e}')
qs = comp.get('questions') if isinstance(comp, dict) else None
if not isinstance(qs, list) or not qs: die('composição sem "questions" (lista não vazia)')
panel_only = comp.get('panel_only', False)
if not isinstance(panel_only, bool): die('panel_only é true ou false')
MAXOPT = 6 if panel_only else 4   # só-painel libera até 6; com paridade de terminal, o teto é o do AskUserQuestion
BAD = ('«', '»', '|')
DRAFT = re.compile(r'\[\s*a[\s_-]*confirmar\s*\]', re.I)
INVIS = dict.fromkeys(map(ord, '\u200b\u200c\u200d\u2060\ufeff\u00ad'))
def clean(s, what, n=None, bad=BAD):
    if not isinstance(s, str) or not s.strip(): die(f'{what} vazio ou não-texto')
    s = ' '.join(s.translate(INVIS).split())
    if DRAFT.search(s): die(f'{what} com marcador de rascunho [A CONFIRMAR]: rodada não sai com texto por confirmar')
    if any(b in s for b in bad): die(f'{what} com « » ou | (o selador recusaria; o | separa as descartadas): {s[:80]}')
    if n and len(s) > n: die(f'{what} passa de {n} caracteres: {s}')
    return s
CITE = re.compile(r'[A-Z][A-Z0-9]{1,9}-[A-Z][0-9]{2,3}[a-z]?')
cdir = os.path.dirname(os.path.realpath(compose))
IMG_MAX = 96 * 1024   # embutida no round (o documento do db tem teto de 256 KiB); maior vai pelo asset store
MAGIC = ((b'\x89PNG\r\n\x1a\n', 'image/png'), (b'\xff\xd8\xff', 'image/jpeg'))
def view_of(v, ref):
    # bloco de APRESENTAÇÃO: fica fora do round_id e nunca vira argumento do selador
    if v is None: return None
    if not isinstance(v, dict): die(f'{ref}: view não é objeto')
    extra = set(v) - {'explanation', 'why', 'images', 'annotate', 'upload', 'source_url'}
    if extra: die(f'{ref}: view com campo desconhecido: {sorted(extra)}')
    out = {}
    if 'explanation' in v: out['explanation'] = clean(v['explanation'], f'{ref}: view.explanation', 1200, ())
    if 'why' in v: out['why'] = clean(v['why'], f'{ref}: view.why', 400, ())
    if 'source_url' in v:
        u = v['source_url']
        if not (isinstance(u, str) and re.fullmatch(r'https://[^\s@/?#]+/[^\s?#]*', u)): die(f'{ref}: view.source_url só https://, sem credencial, sem query e sem fragmento')
        out['source_url'] = u
    imgs = v.get('images', [])
    if not isinstance(imgs, list) or len(imgs) > 6: die(f'{ref}: view.images é lista de até 6')
    ol = []
    for k, im in enumerate(imgs):
        if not isinstance(im, dict) or set(im) - {'path', 'src', 'caption'} or ('path' in im) == ('src' in im):
            die(f'{ref}: imagem {k + 1} leva path OU src (e caption opcional)')
        cap = clean(im['caption'], f'{ref}: legenda {k + 1}', 160, ()) if 'caption' in im else ''
        if 'src' in im:
            s = im['src']
            if not (isinstance(s, str) and re.fullmatch(r'/_blob/[A-Za-z0-9_-]+|https://[^\s@/]+/\S*', s)):
                die(f'{ref}: imagem {k + 1}: src só /_blob/<id> (asset store) ou https://')
            ol.append({'src': s, 'caption': cap}); continue
        p = os.path.realpath(os.path.join(cdir, str(im['path'])))
        if not p.startswith(cdir + os.sep) or not os.path.isfile(p): die(f'{ref}: imagem {k + 1} fora da pasta da composição ou inexistente: {im["path"]}')
        b = open(p, 'rb').read(IMG_MAX + 1)
        if len(b) > IMG_MAX: die(f'{ref}: imagem {k + 1} passa de {IMG_MAX // 1024} KiB — suba pelo asset store do Artifact e use src /_blob/<id>')
        mt = next((m for sig, m in MAGIC if b.startswith(sig)), 'image/webp' if b[:4] == b'RIFF' and b[8:12] == b'WEBP' else None)
        if not mt: die(f'{ref}: imagem {k + 1} não é PNG, JPEG nem WebP (pela assinatura do arquivo)')
        ol.append({'src': f'data:{mt};base64,' + base64.b64encode(b).decode('ascii'), 'caption': cap or os.path.basename(p)})
    if ol: out['images'] = ol
    if 'annotate' in v:
        if not isinstance(v['annotate'], bool): die(f'{ref}: view.annotate é true ou false')
        if v['annotate'] and not ol: die(f'{ref}: view.annotate sem imagem')
        if v['annotate'] and ol[0]['src'].startswith('https://'):
            die(f'{ref}: view.annotate pede a 1ª imagem embutida ou no asset store (/_blob/): imagem de outra origem contamina o canvas da marcação')
        out['annotate'] = v['annotate']
    if 'upload' in v:
        u = v['upload']
        if not isinstance(u, dict) or set(u) != {'url', 'what', 'expires'}: die(f'{ref}: view.upload leva url, what e expires (o link tem prazo)')
        if not (isinstance(u['url'], str) and re.fullmatch(r'https://[^\s@/?#]+/[^\s?#]*', u['url'])):
            die(f'{ref}: view.upload.url só https:// sem credencial, sem query e sem fragmento (nada de segredo na página)')
        try: okd = isinstance(u['expires'], str) and re.fullmatch(r'\d{4}-\d{2}-\d{2}', u['expires']) and bool(date.fromisoformat(u['expires']))
        except ValueError: okd = False
        if not okd or u['expires'] < today:
            die(f'{ref}: view.upload.expires AAAA-MM-DD, hoje ou depois (link vencido não vai para a página)')
        out['upload'] = {'url': u['url'], 'what': clean(u['what'], f'{ref}: view.upload.what', 200, ()), 'expires': u['expires']}
    return out or None
ACT_OPTS = {
  'faço-eu': [('Eu faço agora (Recomendado)', 'a sessão roda o comando abaixo agora e reporta o rc'), ('Me dê o passo a passo', 'você recebe o card e faz à mão'), ('Depois', 'fica em voo, nomeado no relatório')],
  'maestro-com-!': [('Me dê o passo a passo (Recomendado)', 'o veto barra a sessão: o card traz os comandos com o prefixo de bang'), ('Já fiz, confira', 'a sessão roda a conferência do card e reporta'), ('Depois', 'fica em voo, nomeado no relatório')],
  'maestro-fora': [('Me dê o passo a passo (Recomendado)', 'falta à sessão o que o ato pede: o card diz onde rodar'), ('Já fiz, confira', 'a sessão roda a conferência do card e reporta'), ('Depois', 'fica em voo, nomeado no relatório')],
}
# CONFERIR uma correção: opções fixas, como as do ATO (não se compõem); sem recomendada, quem confere é a pessoa
VERIFY_OPTS = [('Confere', 'a correção está certa: sela o nó como conferido por você'), ('Ainda não', 'volta para a sessão corrigir; não sela')]
byref = {}
for r in rows: byref.setdefault(r['ref'], r)
out, used, cites, resolved = [], set(), set(), []
for i, q in enumerate(qs):
    if not isinstance(q, dict): die(f'pergunta {i + 1} não é objeto')
    ref = q.get('ref')
    if not isinstance(ref, str) or ref not in byref: die(f'pergunta {i + 1}: ref {ref!r} não está no censo desta rodada — não se pergunta sobre o que não foi medido')
    if ref in used: die(f'ref repetido na composição: {ref}')
    used.add(ref); r = byref[ref]
    cite = q.get('cite_id')
    if cite is not None:
        if not (isinstance(cite, str) and CITE.fullmatch(cite)): die(f'{ref}: cite_id fora da forma PREFIXO-L00 (ex.: DEMO-P01, DEMO-P01b)')
        if cite in cites: die(f'cite_id repetido na composição: {cite}')
        cites.add(cite)
    question = clean(q.get('question'), f'pergunta {i + 1}: question')
    if q.get('resolved_by') is not None:   # já resolvido por regra: recolhido, NÃO é pergunta, não conta, não sela
        extra = set(q) - {'ref', 'cite_id', 'question', 'resolved_by', 'header'}
        if extra: die(f'{ref}: item resolvido por regra não é pergunta e não leva {sorted(extra)}')
        resolved.append({'ref': ref, 'cite_id': cite, 'question': question,   # só texto: a página não mostra view aqui
                         'resolved_by': clean(q['resolved_by'], f'{ref}: resolved_by', 400, ())})
        continue
    view = view_of(q.get('view'), ref)
    kind = q.get('kind')
    if kind not in (None, 'verify'): die(f'{ref}: kind só "verify" (selo e ato saem da linha do censo)')
    if kind == 'verify':
        if r['kind'] != 'seal': die(f'{ref}: verify só sobre linha de selo do censo (o nó da correção)')
        if 'options' in q or 'recommended' in q: die(f'{ref}: as opções de verify são fixas (Confere / Ainda não), não se compõem')
        if q.get('destination', 'design') != 'design' or 'guard' in q: die(f'{ref}: verify sela com destination design, sem guard (é conferência da pessoa)')
        ol = [{'label': l, 'description': d, 'cost': '', 'recommended': False} for l, d in VERIFY_OPTS]
        item = {'kind': 'verify', 'ref': ref, 'header': clean(q.get('header') or 'Correção', f'{ref}: header', 12), 'question': question,
                'options': ol, 'allow_other': False, 'actor': 'faço-eu',
                'seal': {'graph': r['origin'].rsplit(':', 1)[0], 'node': ref, 'destination': 'design'}, 'origin': r['origin'], 'card': ''}
    elif r['kind'] == 'seal':
        opts = q.get('options')
        if not isinstance(opts, list) or not 2 <= len(opts) <= MAXOPT:
            die(f'{ref}: 2 a {MAXOPT} opções' + (' (só-painel)' if panel_only else ' (teto do AskUserQuestion; só-painel libera até 6 com "panel_only": true)'))
        ol = []
        for j, o in enumerate(opts):
            if not isinstance(o, dict): die(f'{ref}: opção {j + 1} não é objeto')
            lab = clean(o.get('label'), f'{ref}: rótulo {j + 1}')
            if lab.endswith('(Recomendado)'): die(f'{ref}: a marca (Recomendado) é posta por este script a partir de "recommended", nunca escrita à mão')
            ol.append({'label': lab, 'description': clean(o.get('description'), f'{ref}: descrição {j + 1}'),
                       'cost': clean(str(o['cost']), f'{ref}: custo {j + 1}', 120, ()) if o.get('cost') not in (None, '') else ''})
        rec = q.get('recommended')
        if rec is not None:
            if not isinstance(rec, int) or isinstance(rec, bool) or not 0 <= rec < len(ol): die(f'{ref}: recommended fora do intervalo')
            ol.insert(0, ol.pop(rec)); ol[0]['label'] += ' (Recomendado)'   # a sugestão do agente é a 1ª opção, sempre
        for o in ol: o['recommended'] = o['label'].endswith(' (Recomendado)')
        if len({o['label'].casefold() for o in ol}) != len(ol): die(f'{ref}: rótulos repetidos')
        g = r['origin'].rsplit(':', 1)[0]
        header = clean(q.get('header'), f'{ref}: header', 12)
        dest, guard = q.get('destination'), q.get('guard')
        if dest not in ('mechanism', 'design'): die(f'{ref}: destination obrigatório, mechanism ou design (todo selo novo declara o destino)')
        if dest == 'mechanism' and not (isinstance(guard, str) and re.fullmatch(r'[A-Z][A-Z0-9]*-[0-9]+|Q_[A-Z0-9_]+', guard)):
            die(f'{ref}: destination mechanism exige guard na forma de card (LETRAS-N) ou nó Q_*')
        if dest == 'design' and guard is not None: die(f'{ref}: destination design não leva guard')
        item = {'kind': 'seal', 'ref': ref, 'header': header, 'question': question, 'options': ol, 'allow_other': True,
                'actor': 'faço-eu', 'seal': {'graph': g, 'node': ref, 'destination': dest, **({'guard': guard} if dest == 'mechanism' else {})}, 'origin': r['origin'],
                'card': (r.get('hint') or '')}
    else:
        actor = r.get('actor', '')
        if actor not in ACT_OPTS: die(f'{ref}: ato de classe {actor!r} não vira pergunta (outro-dono vai para o que o filtro tirou)')
        if 'options' in q: die(f'{ref}: as opções de ATO saem da classe medida (cláusula 8), não se compõem')
        header = clean(q.get('header') or {'merge': 'Merge', 'checkpoint': 'Checkpoint', 'thread': 'Worktree', 'triage': 'Triagem', 'access': 'Acesso'}.get(r['kind'], 'Ato'), f'{ref}: header', 12)
        ol = [{'label': l, 'description': d, 'cost': '', 'recommended': l.endswith(' (Recomendado)')} for l, d in ACT_OPTS[actor]]
        item = {'kind': 'act', 'ref': ref, 'header': header, 'question': question, 'options': ol, 'allow_other': False,
                'actor': actor, 'seal': None, 'origin': r['origin'], 'card': r.get('action') or ''}
    item['cite_id'] = cite
    item['view'] = view
    out.append(item)
# a ordem é a do CENSO (bloqueio → atenção, cláusula 4), nunca a da composição
pos = {}
for k, r in enumerate(rows): pos.setdefault(r['ref'], k)
out.sort(key=lambda it: pos[it['ref']])
resolved.sort(key=lambda it: pos[it['ref']])
rnd, deferred = out[:4], out[4:]
for k, it in enumerate(rnd): it['id'] = f'q{k + 1}'
rid = round_id(rnd, today, nonce)   # só o que sela entra no hash; cite_id, view e cabeçalho ficam fora
def ask_desc(o): return o['description'] + (f' · custo: {o["cost"]}' if o['cost'] else '')
if ask == '1':
    if not rnd: die('--ask: a rodada não tem pergunta (só itens resolvidos ou adiados): nada a perguntar no terminal')
    wide = [f"{it['ref']} ({len(it['options'])})" for it in rnd if len(it['options']) > 4]
    if wide: die('--ask: o AskUserQuestion aceita até 4 opções; esta rodada só-painel tem mais em: ' + ', '.join(wide) + ' — responda no painel ou recomponha com até 4')
    print(json.dumps({'questions': [{'question': it['question'], 'header': it['header'], 'multiSelect': False,
                                     'options': [{'label': o['label'], 'description': ask_desc(o)} for o in it['options']]} for it in rnd]},
                     ensure_ascii=False, indent=2))
    sys.exit(0)
panel = {'schema': 'onion.decide.panel/v1', 'round_id': rid, 'today': today, 'nonce': nonce, 'panel_only': panel_only, 'questions': rnd,
         'resolved': resolved,
         'deferred': [f"{it['kind']}:{it['ref']}" + (f" [{it['cite_id']}]" if it['cite_id'] else '') for it in deferred],
         'not_asked': [f"{r['kind']}:{r['ref']} ({r.get('actor', '')})" for r in rows if r['ref'] not in used]}
s = json.dumps(panel, ensure_ascii=False, indent=2)
if len(s.encode('utf-8')) > 240 * 1024: die(f'round com {len(s.encode("utf-8")) // 1024} KiB passa do teto do documento do db (256 KiB): suba as imagens pelo asset store (src /_blob/<id>)')
print(s)
PY
    ;;
  seal)
    ROUND="${1:-}"; ANS="${2:-}"; shift 2 2>/dev/null || { echo "decide-panel: seal exige <round.json> <respostas>" >&2; exit 2; }
    OTHERS=""; ONLY=""; DRY="0"; SREPO="$(pwd)"
    while [ $# -gt 0 ]; do
      case "$1" in
        --other) _need "$@"; shift; OTHERS="${OTHERS} $1" ;;
        --only) _need "$@"; shift; ONLY="${ONLY} $1" ;;
        --repo) _need "$@"; shift; SREPO="$1" ;;
        --dry-run) DRY="1" ;;
        *) echo "decide-panel: opção desconhecida: $1" >&2; exit 2 ;;
      esac
      shift
    done
    [ -r "${ROUND}" ] || { echo "decide-panel: round ilegível: ${ROUND}" >&2; exit 2; }
    [ -e "${ANS}" ] || { echo "decide-panel: respostas inexistentes: ${ANS}" >&2; exit 2; }
    [ -f "${SEAL}" ] || { echo "decide-panel: selador ausente: ${SEAL} — sem selador não selo" >&2; exit 2; }
    PYTHONDONTWRITEBYTECODE=1 python3 -I -B - seal "${ROUND}" "${ANS}" "${SEAL}" "${OTHERS}" "${DRY}" "${SREPO}" "${ONLY}" <<'PY'
import sys, os, json, hashlib, subprocess, glob
_, roundp, ansp, seal, others, dry, srepo, only = sys.argv[1:9]
def round_id(qs, today, nonce):
    # o round_id cobre o que sela ou vira ato (decisão do core, 2026-11-26): id, tipo, ref, pergunta, opções, texto
    # livre, o selo, a classe e o card do ato (o comando que a sessão roda no "executar") e a origem, mais a data e o
    # nonce. Fica FORA só a apresentação: cabeçalho, cite_id e view (imagens, explicação, link de envio): trocar um
    # print não invalida a resposta já dada.
    core = [dict({k: q.get(k) for k in ('id', 'kind', 'ref', 'question', 'allow_other', 'seal', 'actor', 'card', 'origin')},
                 options=[{k: o.get(k) for k in ('label', 'description', 'cost')} for o in (q.get('options') or [])]) for q in qs]
    canon = json.dumps({'questions': core, 'today': today, 'nonce': nonce}, ensure_ascii=False, sort_keys=True, separators=(',', ':'))
    return hashlib.sha256(canon.encode('utf-8')).hexdigest()[:16]
def round_id_legacy(qs, today, nonce):
    # hash da rodada emitida ANTES do kit (a pergunta inteira): cobre mais, então aceitá-lo é seguro; sem ele, a
    # rodada em voo no merge perderia as respostas já dadas no painel
    canon = json.dumps({'questions': qs, 'today': today, 'nonce': nonce}, ensure_ascii=False, sort_keys=True, separators=(',', ':'))
    return hashlib.sha256(canon.encode('utf-8')).hexdigest()[:16]
srepo = os.path.realpath(srepo)
def die(m): print(f'decide-panel: {m}', file=sys.stderr); sys.exit(2)
try: rd = json.load(open(roundp, encoding='utf-8'))
except Exception as e: die(f'round ilegível: {e}')
if not isinstance(rd, dict) or rd.get('schema') != 'onion.decide.panel/v1': die('round não é onion.decide.panel/v1')
qs = rd.get('questions') or []
if rd.get('round_id') not in (round_id(qs, rd.get('today'), rd.get('nonce')), round_id_legacy(qs, rd.get('today'), rd.get('nonce'))): die('round adulterado: o round_id não é o hash das perguntas — recuso selar a partir dele')
byq = {q['id']: q for q in qs}
import re
if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', str(rd.get('today'))): die('round sem data AAAA-MM-DD')
for q in qs:   # defesa em profundidade: o nó é um id (nunca uma flag), e o grafo é relativo, dentro da raiz, e existe
    if q.get('kind') not in ('seal', 'verify'): continue   # verify também sela: o nó dele passa pela mesma checagem
    if not re.fullmatch(r'[A-Z][A-Z0-9_]*', str((q.get('seal') or {}).get('node'))): die(f"{q.get('id')}: nó do selo fora de [A-Z][A-Z0-9_]* — recuso (viraria flag do selador)")
    g = (q.get('seal') or {}).get('graph') or ''
    gp = os.path.realpath(os.path.join(srepo, g))
    if os.path.isabs(g) or not g.endswith('.kg.yaml') or not gp.startswith(srepo + os.sep) or not os.path.isfile(gp):
        die(f"{q.get('id')}: grafo do selo fora da raiz ou inexistente ({g!r} em {srepo}) — passe --repo <raiz do repo medido>")
allow_other = set(others.split())
only = set(only.split())
for o in allow_other | only:
    if o not in byq: die(f'--other/--only {o}: pergunta inexistente nesta rodada')
if only and not allow_other <= only: die('--other fora do --only: a flag vale só para pergunta desta passada')
# respostas: um arquivo (objeto, lista, ou {"answers": [...]}) ou o diretório que o ArtifactData grava com out_dir
raw = []
files = sorted(glob.glob(os.path.join(ansp, '**', '*.json'), recursive=True)) if os.path.isdir(ansp) else [ansp]
for fp in files:
    try: d = json.load(open(fp, encoding='utf-8'))
    except Exception as e: die(f'resposta ilegível {fp}: {e}')
    if isinstance(d, dict) and isinstance(d.get('answers'), list): raw += d['answers']
    elif isinstance(d, list): raw += d
    else: raw.append(d)
ans = {}
status = {}
for a in raw:
    if isinstance(a, dict) and isinstance(a.get('data'), dict): a = a['data']   # envelope do documento lido
    if not isinstance(a, dict) or not isinstance(a.get('qid'), str):
        continue
    qid = a['qid']
    if qid not in byq: status[f'?{qid[:20]}'] = {'state': 'recusada', 'detail': 'qid que não existe nesta rodada'}; continue
    if a.get('round_id') != rd['round_id']:
        status[qid] = {'state': 'recusada', 'detail': 'round_id de outra rodada (velha ou forjada): volta como pergunta'}; continue
    if qid in ans: status[qid] = {'state': 'ambígua', 'detail': 'duas respostas para a mesma pergunta: volta como pergunta'}; ans[qid] = None; continue
    ans[qid] = a
date = rd.get('today') or ''
for q in qs:
    qid = q['id']
    if only and qid not in only: status.pop(qid, None); continue
    if qid in status: continue
    a = ans.get(qid)
    if a is None: status[qid] = {'state': 'sem resposta', 'detail': 'pergunta pulada não sela'}; continue
    ch = a.get('choice') if isinstance(a.get('choice'), str) else ''
    ot = a.get('other') if isinstance(a.get('other'), str) else ''
    ch, ot = ch.strip(), ' '.join(ot.split())
    labels = [o['label'] for o in q['options']]
    if bool(ch) == bool(ot):
        status[qid] = {'state': 'ambígua', 'detail': 'escolha e texto livre juntos, ou nenhum: volta como pergunta'}; continue
    if ch and ch not in labels:
        status[qid] = {'state': 'recusada', 'detail': 'escolha fora das opções oferecidas: volta como pergunta'}; continue
    if ot:
        if not q.get('allow_other'):
            status[qid] = {'state': 'ambígua', 'detail': 'texto livre num ATO: a sessão lê e pergunta de novo'}; continue
        if qid not in allow_other:
            status[qid] = {'state': 'aguarda leitura', 'detail': f'resposta livre: a sessão lê o texto e só sela com --other {qid}', 'other': ot[:500]}; continue
    if q['kind'] == 'verify' and ch == 'Ainda não':
        status[qid] = {'state': 'não confere', 'detail': 'a pessoa não deu a correção por certa: volta para a sessão corrigir'}; continue
    if q['kind'] == 'act':
        st = {'Eu faço agora (Recomendado)': 'executar', 'Me dê o passo a passo': 'card pendente',
              'Me dê o passo a passo (Recomendado)': 'card pendente', 'Já fiz, confira': 'conferir', 'Depois': 'depois'}.get(ch, 'ambígua')
        status[qid] = {'state': st, 'detail': q.get('card') or ''}; continue
    if q['seal'].get('destination') not in ('mechanism', 'design'):   # rodada emitida antes do destino declarado
        status[qid] = {'state': 'recusada', 'detail': 'rodada sem destino declarado (mechanism|design): recomponha a rodada'}; continue
    strip = lambda s: s[:-len(' (Recomendado)')] if s.endswith(' (Recomendado)') else s
    chosen = ot or strip(ch)
    rejected = [strip(l) for l in labels if l != ch]
    argv = ['bash', seal, q['seal']['graph'], q['seal']['node'], '--chosen', chosen, '--rejected', '|'.join(rejected),
            '--date', date, '--question', q['question']] + (['--other'] if ot else []) \
           + ['--destination', q['seal']['destination']] + (['--guard', q['seal']['guard']] if q['seal'].get('guard') else [])
    if dry == '1':
        status[qid] = {'state': 'ensaio', 'detail': 'não chamado (--dry-run)', 'argv': argv[1:]}; continue
    # lista de argumentos, NUNCA shell: o texto do painel é dado, não comando
    r = subprocess.run(argv, capture_output=True, text=True, cwd=srepo)
    tail = ' '.join((r.stderr or r.stdout).split())[-300:]
    status[qid] = ({'state': 'selado', 'detail': f"{q['seal']['node']} em {q['seal']['graph']}"} if r.returncode == 0
                   else {'state': 'recusada pelo selador', 'detail': f'rc {r.returncode}: {tail}'})
for qid, a in ans.items():   # anotação no print e nota livre: DADO para a sessão ler, nunca argumento do selador
    if not a or qid not in status: continue
    if isinstance(a.get('annotation'), str) and a['annotation'].strip(): status[qid]['annotated'] = True
    if isinstance(a.get('note'), str) and a['note'].strip(): status[qid]['note'] = ' '.join(a['note'].split())[:500]
for v in status.values(): v['round_id'] = rd['round_id']   # o painel só mostra o estado da rodada dele
print(json.dumps({'schema': 'onion.decide.status/v1', 'round_id': rd['round_id'], 'items': status}, ensure_ascii=False, indent=2))
PY
    ;;
  *) sed -n '/^# Uso:/,/^# Arquivo de composição/p' "$0" | sed '$d' >&2; exit 2 ;;
esac
