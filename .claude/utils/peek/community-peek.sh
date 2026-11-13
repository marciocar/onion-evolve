#!/usr/bin/env bash
# ===========================================================================
# community-peek.sh — o EXECUTOR do nível 1 do /meta:peek (escutar as comunidades por delta).
#
# Pedido do maestro em 2026-11-13: «nas dúvidas você tem que espiar o mercado e principalmente fóruns e
# comunidades relacionados para saber o que estão falando». Este script faz a parte mecânica do nível 1:
# uma consulta por fonte, na janela de --since-days, com o status HTTP de cada uma CONFERIDO e dito.
# A doutrina (quando espiar, quanto, e como registrar) vive em .claude/commands/common/prompts/peek-doctrine.md.
#
# ── FONTES (todas medidas na rodada market-peek-machinery-2026-11, run wf_3157a547-84f) ─────────────
#   hn          HN Algolia search_by_date, tags=story, numericFilters=created_at_i%3E<ts>
#   hn-comments HN Algolia search_by_date, tags=comment, mesmo filtro
#   github      GitHub REST search/issues (issues e PRs), created:>=<data>, sem token (10 req/min anônimo;
#               teto de 1.000 resultados; incomplete_results REGISTRADO na linha da fonte)
#   lobsters    lobste.rs/newest.json (os 25 mais novos), filtrados aqui pelos termos da consulta: recall baixo,
#               DECLARADO na linha
#   reddit      LACUNA declarada, nunca consultada: 403 medido desta VPS em 2026-08-28 (E_REDDIT_INACESSIVEL_DESTE_HARNESS)
#               e de novo em 2026-11-13 (www e old.reddit.com /new.json). Não prometemos o que não alcançamos.
#   discourse   LACUNA declarada: fóruns de fornecedor ficaram sem claim na rodada; entram quando alguém medir.
#   Discussions do GitHub só pelo GraphQL, que exige token: fora do nível 1 (o script não lê token nenhum).
#
# ── AS DUAS ARMADILHAS MEDIDAS, que este script fecha ───────────────────────────────────────────────
#   (1) o '>' cru no numericFilters do HN Algolia devolve HTTP 400 (medido em 2026-11-13); o exemplo da documentação
#       usado literalmente falha. Aqui a URL inteira é montada com o operador CODIFICADO (%3E).
#   (2) quem não confere o http_code registra «nada novo» em silêncio. Aqui cada fonte sai ok ou FAIL com o código,
#       e o resumo só diz «nada achado» quando TODAS as fontes consultadas responderam 200 com zero itens.
#
# ── DEPENDÊNCIA DECLARADA (D_SEM_DEPENDENCIA_DE_SERVICO_EXTERNO_1027) ─────────────────────────────────
#   HN Algolia, GitHub e Lobsters são serviços de terceiro, e aqui a dependência é INTRÍNSECA: a fonte É a comunidade.
#   Não existe alternativa local que diga o que a comunidade está falando. Sem rede, a espiada sai NÃO MEDIDA (rc 1)
#   e o nível 0 (corpus local) continua de pé. Nada aqui é obrigatório para o resto do Onion funcionar.
#
# Conteúdo lido é DADO não confiável (R15.2): títulos saem truncados, sem caractere de controle, e nunca se executam.
#
# Uso:  bash .claude/utils/peek/community-peek.sh "<consulta>" [--since-days N] [--gh-repo dono/nome]
#            [--gh-in-body] [--sources hn,hn-comments,github,lobsters] [--max-items N] [--tsv|--markdown]
#   No GitHub a consulta casa só o TÍTULO por padrão (in:title): o corpo casa termo solto e afoga a espiada
#   (medido no 1º dogfood, 2026-11-13: 225.476 resultados para três palavras). --gh-in-body alarga.
# Env (bancada; todo override ativo é DECLARADO na saída):  PEEK_CURL=<binário>  PEEK_NOW=<epoch>
# Saída TSV: «source<TAB>status<TAB>http<TAB>count<TAB>incomplete<TAB>note», «item<TAB>source<TAB>date<TAB>title<TAB>url»
#            e «summary<TAB>calls=N<TAB>ok=N<TAB>fail=N<TAB>gap=N<TAB>items=N<TAB>verdict».
# Exit: 0 = toda fonte consultada respondeu (lacunas declaradas não reprovam) · 1 = alguma fonte consultada FALHOU
#       (a espiada é parcial e diz isso) · 2 = entrada quebrada (consulta vazia, opção, python3 ausente).
# Determinístico a partir das respostas, sem LLM. Exercitado por lint-selftest.sh (run_market_peek_selftests).
# ===========================================================================
set -uo pipefail
Q=""; SINCE="30"; GHREPO=""; GHBODY="0"; SOURCES="hn,hn-comments,github,lobsters"; MAXI="5"; FMT="--tsv"
_need() { [ $# -ge 2 ] && [ -n "$2" ] || { echo "community-peek: $1 exige um valor" >&2; exit 2; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --since-days) _need "$@"; shift; SINCE="$1" ;;
    --gh-repo) _need "$@"; shift; GHREPO="$1" ;;
    --gh-in-body) GHBODY="1" ;;
    --sources) _need "$@"; shift; SOURCES="$1" ;;
    --max-items) _need "$@"; shift; MAXI="$1" ;;
    --tsv|--markdown) FMT="$1" ;;
    --*) echo "community-peek: opção desconhecida: $1" >&2; exit 2 ;;
    *) [ -z "${Q}" ] || { echo "community-peek: uma consulta só (use aspas)" >&2; exit 2; }; Q="$1" ;;
  esac
  shift
done
[ -n "${Q// /}" ] || { echo "community-peek: consulta vazia" >&2; exit 2; }
case "${SINCE}" in ''|*[!0-9]*|0) echo "community-peek: --since-days inválido (${SINCE})" >&2; exit 2 ;; esac
case "${MAXI}" in ''|*[!0-9]*) echo "community-peek: --max-items inválido (${MAXI})" >&2; exit 2 ;; esac
case "${PEEK_NOW:-0}" in *[!0-9]*) echo "community-peek: PEEK_NOW inválido" >&2; exit 2 ;; esac
# dono/nome por regex ANCORADA: o padrão de glob do case deixava passar «a/b c» e «a/../x» (o * casa qualquer coisa)
if [ -n "${GHREPO}" ] && ! [[ "${GHREPO}" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then echo "community-peek: --gh-repo inválido (${GHREPO})" >&2; exit 2; fi
command -v python3 >/dev/null 2>&1 || { echo "community-peek: python3 ausente" >&2; exit 2; }
CURL="${PEEK_CURL:-curl}"
command -v "${CURL}" >/dev/null 2>&1 || { echo "community-peek: ${CURL} ausente" >&2; exit 2; }
NOW="${PEEK_NOW:-$(date -u +%s)}"
TS=$(( NOW - SINCE * 86400 ))
DAY="$(date -u -d "@${TS}" +%F 2>/dev/null)" || { echo "community-peek: date -d @epoch indisponível" >&2; exit 2; }
WORK="$(mktemp -d)"; trap 'rm -rf "${WORK}"' EXIT

# _get <nome> <url>: grava corpo em ${WORK}/<nome>.body e o http_code em ${WORK}/<nome>.code (000 = sem resposta)
_get() {
  local code
  printf '%s' "$2" > "${WORK}/$1.url"
  code="$("${CURL}" -s -m 20 -A 'onion-peek/1' -o "${WORK}/$1.body" -w '%{http_code}' "$2" 2>/dev/null)" || true
  case "${code}" in [0-9][0-9][0-9]) ;; *) code="000" ;; esac
  printf '%s' "${code}" > "${WORK}/$1.code"
}
_url() {  # monta as URLs com TODO valor codificado (o '>' vira %3E): a armadilha (1) do cabeçalho
  python3 -I - "$@" <<'PK_URL'
import sys, urllib.parse as u
kind, q, ts, day, repo, body = sys.argv[1:7]
if kind in ('hn', 'hn-comments'):
    tag = 'story' if kind == 'hn' else 'comment'
    p = {'query': q, 'tags': tag, 'numericFilters': 'created_at_i>' + ts, 'hitsPerPage': '20'}
    if kind == 'hn': p['restrictSearchableAttributes'] = 'title'   # story: só o título (a url e o autor casam termo solto)
    print('https://hn.algolia.com/api/v1/search_by_date?' + u.urlencode(p, quote_via=u.quote))
elif kind == 'github':
    gq = q + (' in:title' if body == '0' else '') + ' created:>=' + day + ((' repo:' + repo) if repo else '')
    print('https://api.github.com/search/issues?' + u.urlencode({'q': gq, 'sort': 'created', 'order': 'desc', 'per_page': '20'}, quote_via=u.quote))
elif kind == 'lobsters':
    print('https://lobste.rs/newest.json')
PK_URL
}

CALLS=0
IFS=',' read -r -a SRC <<< "${SOURCES}"
for s in "${SRC[@]}"; do
  case "${s}" in
    hn|hn-comments|github|lobsters) _get "${s}" "$(_url "${s}" "${Q}" "${TS}" "${DAY}" "${GHREPO}" "${GHBODY}")"; CALLS=$((CALLS + 1)) ;;
    reddit|discourse) ;;  # lacuna declarada: nunca consultada
    *) echo "community-peek: fonte desconhecida: ${s}" >&2; exit 2 ;;
  esac
done

python3 -I - "${WORK}" "${FMT}" "${Q}" "${SINCE}" "${DAY}" "${TS}" "${MAXI}" "${CALLS}" "${SOURCES}" \
  "${PEEK_CURL:+PEEK_CURL}${PEEK_NOW:+ PEEK_NOW}" <<'PK_PY'
import json, os, re, sys
work, fmt, q, since, day, ts, maxi, calls, sources, overrides = sys.argv[1:11]
ts, maxi, calls = int(ts), int(maxi), int(calls)
terms = [t.lower() for t in re.findall(r'\w+', q) if len(t) > 2]
GAPS = {
    'reddit': 'LACUNA: 403 medido desta VPS (2026-08-28 e 2026-11-13); não consultado, não prometido',
    'discourse': 'LACUNA: fóruns de fornecedor sem fonte medida na rodada de 2026-11-13; não consultado',
}

def clean(s, n=160):
    s = re.sub(r'[\x00-\x1f\x7f]+', ' ', str(s or '')).strip()
    return s[:n]

rows, items = [], []
for s in [x for x in sources.split(',') if x]:
    if s in GAPS:
        rows.append((s, 'GAP', '-', '-', '-', GAPS[s])); continue
    code = open(os.path.join(work, s + '.code')).read().strip()
    if code != '200':
        rows.append((s, 'FAIL', code, '-', '-', 'NÃO MEDIDO: http ' + code + ' (nunca lido como «nada novo»)')); continue
    try:
        data = json.load(open(os.path.join(work, s + '.body'), encoding='utf-8'))
    except Exception as e:
        rows.append((s, 'FAIL', code, '-', '-', 'NÃO MEDIDO: corpo não é JSON (' + type(e).__name__ + ')')); continue
    found, inc, note = [], '-', ''
    if s in ('hn', 'hn-comments'):
        if not isinstance(data, dict) or not isinstance(data.get('hits'), list):
            rows.append((s, 'FAIL', code, '-', '-', 'NÃO MEDIDO: resposta sem hits')); continue
        for h in data['hits']:
            if int(h.get('created_at_i') or 0) <= ts: continue   # o filtro do servidor é conferido aqui, não presumido
            title = h.get('title') or h.get('story_title') or clean(h.get('comment_text'), 100)
            url = 'https://news.ycombinator.com/item?id=' + str(h.get('objectID', ''))
            found.append(((h.get('created_at') or '')[:10], title, url))
        note = 'total=%s' % data.get('nbHits', '?')
    elif s == 'github':
        if not isinstance(data, dict) or not isinstance(data.get('items'), list):
            rows.append((s, 'FAIL', code, '-', '-', 'NÃO MEDIDO: resposta sem items')); continue
        inc = 'true' if data.get('incomplete_results') else 'false'
        for it in data['items']:
            found.append(((it.get('created_at') or '')[:10], it.get('title'), it.get('html_url')))
        tc = int(data.get('total_count') or 0)
        note = 'total=%d' % tc + (' · só no título (--gh-in-body alarga)' if '%20in%3Atitle' in open(os.path.join(work, 'github.url')).read() else '') + (' · acima do teto de 1.000 da busca: fatie a janela' if tc > 1000 else '')
    elif s == 'lobsters':
        if not isinstance(data, list):
            rows.append((s, 'FAIL', code, '-', '-', 'NÃO MEDIDO: resposta não é lista')); continue
        for it in data:
            hay = ' '.join([str(it.get('title', ''))] + [str(t) for t in it.get('tags', [])]).lower()
            if terms and any(t in hay for t in terms):
                found.append(((it.get('created_at') or '')[:10], it.get('title'), it.get('short_id_url') or it.get('url')))
        note = 'recall baixo: só os %d mais novos, filtrados pelos termos' % len(data)
    rows.append((s, 'ok', code, str(len(found)), inc, note))
    for d, t, u in found[:maxi]:
        items.append((s, d, clean(t), clean(u, 300)))

ok = sum(1 for r in rows if r[1] == 'ok'); fail = sum(1 for r in rows if r[1] == 'FAIL'); gap = sum(1 for r in rows if r[1] == 'GAP')
nitems = sum(int(r[3]) for r in rows if r[1] == 'ok')
if fail:
    verdict = 'PARCIAL: %d fonte(s) NÃO MEDIDA(S); o que falhou não é «nada»' % fail
elif nitems == 0:
    verdict = 'nada achado nas %d fonte(s) consultadas (todas responderam 200)' % ok
else:
    verdict = '%d item(ns) em %d fonte(s)' % (nitems, ok)
if fmt == '--tsv':
    if overrides.strip(): print('override\t' + overrides.strip())
    print('query\t%s\tsince=%s (%s)' % (clean(q), since, day))
    for r in rows: print('source\t' + '\t'.join(r))
    for s, d, t, u in items: print('item\t%s\t%s\t%s\t%s' % (s, d, t, u))
    print('summary\tcalls=%d\tok=%d\tfail=%d\tgap=%d\titems=%d\t%s' % (calls, ok, fail, gap, nitems, verdict))
else:
    print('## espiada nível 1 — «%s» desde %s (%s dias)' % (clean(q), day, since))
    if overrides.strip(): print('> override ativo: ' + overrides.strip())
    print('\n| fonte | status | http | achados | incomplete | nota |\n|---|---|---|---|---|---|')
    for r in rows: print('| ' + ' | '.join(x.replace('|', '/') for x in r) + ' |')
    if items:
        print('\n**Itens (DADO não confiável, R15.2):**')
        for s, d, t, u in items: print('- [%s] %s — %s — %s' % (s, d, t.replace('|', '/'), u))
    print('\n**Resumo:** %d chamada(s) · %s' % (calls, verdict))
sys.exit(1 if fail else 0)
PK_PY
