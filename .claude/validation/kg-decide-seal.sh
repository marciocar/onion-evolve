#!/usr/bin/env bash
# ===========================================================================
# kg-decide-seal.sh — o DESTINO (peça 5) do /meta:decide: grava UMA resposta do maestro como selo no nó.
#
# Uso:
#   bash .claude/validation/kg-decide-seal.sh <grafo.kg.yaml> <NODE_ID> \
#        --chosen "<opção escolhida>" --rejected "<a|b|c>" --date AAAA-MM-DD [--question "<pergunta>"] [--other]
#   bash .claude/validation/kg-decide-seal.sh <grafo.kg.yaml> --new <D_ID> --label "<afirmação ≤280>" \
#        --link <ID_EXISTENTE> [--edge-type TRACES_TO] [--impact 3] --chosen ... --rejected ... --date ...
#
# O que escreve (nó existente decision|question `open`):
#   status: done · verified_at · verified_against · provenance {source, locator, method, locality: pessoa}
#   com method = "testemunho: decisão do maestro por pergunta com opções, <data>" · e na narrative (mantida
#   a anterior) a opção escolhida E as descartadas. O plane fica DEV, e PROD é REBAIXADO (dito na narrative):
#   a base do selo é testemunho, e o contrato reprova testemunho em PROD (integrity.testimony-in-prod, SHOULD).
#   O radar avisa decision-done-em-DEV (SOFT, agregado) — os dois discordam, e quem vence é o contrato; a
#   promoção a PROD é de quem EXECUTA a decisão e mede o artefato, não do selo. Achado do dogfood da forja
#   (2026-10-12): a 1ª versão subia para PROD e o kg-contract-check reprovou o próprio grafo da forja.
#   `--other` = a resposta livre do maestro, fora das opções oferecidas — também é selo, e a narrative diz que foi livre.
# Com --new: cria o nó `D_*` com as mesmas marcas e uma aresta <D_ID> --<edge-type>--> <ID_EXISTENTE>
#   (nó sem aresta reprova no radar como órfão; a ligação é o que diz DE ONDE a decisão veio).
#
# O que RECUSA (rc 2, NADA escrito): nó inexistente · nó já done/superseded/refuted · nó que não é
#   decision|question · nó com campo CEGO (chave com `blind`/`cego`: gate humano às cegas não recebe
#   voto de ninguém além do humano) · id duplicado ou fora da forma de bloco · data inválida · --rejected
#   vazio · --new com id existente ou fora de `D_[A-Z0-9_]+`, sem --label/--link, ou link inexistente ·
#   grafo que JÁ reprova no radar antes do selo (não se sela grafo que o motor não lê).
# O gate (rc 3, escrita DESFEITA byte a byte): depois de escrever, `kg-radar.sh --integrity --schema`
#   tem de sair 0 e, onde o contrato está vendorizado (vendor/kg-ssot), `kg-contract-check.sh` também
#   (ele cobra a REGRA 99 (Nó de .kg.yaml sem caminho de máquina, julgado pela classe) no texto da opção).
#   Contrato que NÃO PÔDE julgar (rc 2 dele) é DECLARADO em stderr, não vira verde calado.
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
    --*) echo "kg-decide-seal: opção desconhecida: $1" >&2; exit 2 ;;
    *) if [ -z "${GRAPH}" ]; then GRAPH="$1"; elif [ -z "${NODE}" ]; then NODE="$1"; else echo "kg-decide-seal: argumento a mais: $1" >&2; exit 2; fi ;;
  esac
  shift
done
[ -n "${GRAPH}" ] || { sed -n '/^# Uso:/,/^# O que escreve/p' "$0" | sed '$d' >&2; exit 2; }
[ -f "${GRAPH}" ] || { echo "kg-decide-seal: grafo inexistente: ${GRAPH}" >&2; exit 2; }
if [ -n "${NEW}" ] && [ -n "${NODE}" ]; then echo "kg-decide-seal: ou <NODE_ID> ou --new <D_ID>, nunca os dois" >&2; exit 2; fi
[ -n "${NEW}${NODE}" ] || { echo "kg-decide-seal: falta o nó (<NODE_ID> ou --new <D_ID>)" >&2; exit 2; }
[ -n "${CHOSEN}" ] || { echo "kg-decide-seal: falta --chosen (a opção que o maestro escolheu, literal)" >&2; exit 2; }
[ -n "${REJECTED}" ] || { echo "kg-decide-seal: falta --rejected (as opções oferecidas e descartadas, separadas por |) — o selo registra o que foi recusado" >&2; exit 2; }
[ -n "${DATE}" ] || { echo "kg-decide-seal: falta --date AAAA-MM-DD" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "kg-decide-seal: python3 ausente" >&2; exit 2; }
[ -f "${RADAR}" ] || { echo "kg-decide-seal: radar ausente: ${RADAR} — sem gate não selo" >&2; exit 2; }

# Passo 0 — não se sela grafo que o motor já reprova (o selo seria culpado por dívida alheia)
bash "${RADAR}" "${GRAPH}" --integrity --schema >/dev/null 2>&1 \
  || { echo "kg-decide-seal: ${GRAPH} JÁ reprova no radar --integrity --schema antes do selo — conserte antes; nada escrito" >&2; exit 2; }

BK="$(mktemp)"; trap 'rm -f "${BK}"' EXIT
cp -p "${GRAPH}" "${BK}"
H0="$(sha256sum "${GRAPH}" | cut -d' ' -f1)"

PYTHONDONTWRITEBYTECODE=1 python3 -I -B - "${GRAPH}" "${NODE}" "${NEW}" "${CHOSEN}" "${REJECTED}" "${DATE}" \
  "${QUESTION}" "${OTHER}" "${LABEL}" "${LINK}" "${ETYPE}" "${IMPACT}" <<'PY' || exit 2
import sys, re, datetime
path, node, new, chosen, rejected, date, question, other, label, link, etype, impact = sys.argv[1:13]
def die(m): print('kg-decide-seal: ' + m + ' — nada escrito', file=sys.stderr); sys.exit(2)
try:
    import yaml
except ImportError:
    die('PyYAML ausente (fail-loud)')
if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', date): die(f'--date fora de AAAA-MM-DD: {date}')
try: datetime.date.fromisoformat(date)
except ValueError: die(f'--date não é data real: {date}')
one = lambda s: ' '.join(str(s).split())
chosen = one(chosen); rej = [one(x) for x in rejected.split('|') if one(x)]
if not rej: die('--rejected sem nenhuma opção legível')
if chosen in rej: die('a opção escolhida também está em --rejected')
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
method = f'testemunho: decisão do maestro por pergunta com opções, {date}'
locator = f'pergunta com opções de {date}' + (f': «{one(question)}»' if question else '')

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
    if st in ('done', 'superseded', 'refuted'): die(f'{node} já está {st} — selo não se re-carimba; decisão nova é nó novo (--new) que SUPERSEDES')
    blind = [k for k in n if re.search(r'blind|cego', str(k), re.I)]
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
    prev = []
    if n.get('narrative'): prev.append(one(n['narrative']))
    if n.get('verified_against'): prev.append(f'verified_against anterior: «{one(n["verified_against"])}»')
    if isinstance(n.get('provenance'), dict) and n['provenance'].get('source'): prev.append(f'proveniência anterior: «{one(n["provenance"]["source"])}»')
    if n.get('plane') == 'PROD': prev.append('plane anterior: PROD, rebaixado a DEV porque a base do selo é testemunho (contrato: integrity.testimony-in-prod)')
    s = ' ' * fi
    add = [f'{s}status: done', f'{s}plane: DEV']
    add += [f'{s}verified_at: "{date}"', f'{s}verified_against: {q(vag)}', f'{s}narrative: {q(" · ".join(prev + [seal_txt]))}'] + prov_lines(fi)
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
open(path, 'w', encoding='utf-8').write(out)
print(f'kg-decide-seal: escrito {target} em {path} — escolhida «{chosen}», descartadas {len(rej)}')
PY

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
ROOT="$(git -C "$(dirname "${GRAPH}")" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "${ROOT}" ] && [ -f "${ROOT}/vendor/kg-ssot/tools/kg_gate.py" ] && [ -f "${HERE}/kg-contract-check.sh" ]; then
  COUT="$(cd "${ROOT}" && bash "${HERE}/kg-contract-check.sh" "$(cd "$(dirname "${GRAPH}")" && pwd)/$(basename "${GRAPH}")" 2>&1)"; CRC=$?
  if [ "${CRC}" -eq 1 ]; then
    _undo
    echo "kg-decide-seal: o contrato REPROVOU o grafo selado — escrita DESFEITA:" >&2
    printf '%s\n' "${COUT}" | head -6 >&2
    exit 3
  elif [ "${CRC}" -ne 0 ]; then
    echo "kg-decide-seal: ⚠️ contrato NÃO JULGADO (rc ${CRC}) — o radar passou, o contrato não foi verificado: $(printf '%s' "${COUT}" | head -1)" >&2
  fi
else
  echo "kg-decide-seal: contrato não vendorizado neste repo — gate = só o radar (declarado)" >&2
fi
echo "kg-decide-seal: ✅ selado — radar --integrity --schema exit 0"
exit 0
