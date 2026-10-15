#!/usr/bin/env bash
# ===========================================================================
# judge-verdict-check.sh — o JUIZ que REPROVA busca o que SUPERA, e reprova por critério CHECÁVEL.
#
# ── POR QUE EXISTE (SAC-151, maestro 2026-10-15, verbatim) ─────────────────────────────────
# "um juiz de sim ou não sem tentar superação em uma pesquisa pode restringir possibilidades de
# crescimento e inovação; é preciso ter medição e critérios claros". Medido no mesmo dia:
# `grep -c supera .claude/workflows/onion-research.js` = 0 — nenhum juiz da maquinaria pedia
# superação, e nenhum citava o comando que checa a reprovação.
#
# Os juízes que rodam DENTRO de workflow (onion-research.js, census-workflow.mjs) carregam o gate no
# próprio motor. Este script é o MESMO gate para os juízes que a SESSÃO conduz (o do /meta:cc-update,
# o juiz-fixo por eixo do /meta:radar, o veredito do /meta:dissect): a sessão grava o veredito do juiz
# num JSON e roda isto antes de aplicar qualquer reprovação.
#
# ── SSOT: o bloco `// >>> overcoming-gate` do onion-research.js, CARREGADO aqui byte a byte ────────
# Duas cópias da mesma regra divergem (a classe do vocabulário duplicado), e por isso a bancada confere
# que a cópia deste script (no fim, entre os marcadores) e a do census-workflow.mjs são IDÊNTICAS à do
# workflow. A cópia mora aqui porque este script viaja no plugin `onion` (o /meta:radar o cita) e o
# workflow não viaja: lendo o workflow, o plugin sairia rc 3 sempre (achado do refutador, 2026-10-15).
#
# ── ENTRADA ────────────────────────────────────────────────────────────────────────────────
#   { "criteria": [ {"id","when","check"} … ],      # PRÉ-REGISTRADOS antes do juiz rodar
#     "verdicts": [ {"alvo", "<campo>": "<valor>", "superacao": {classe,achada,o_que,medida},
#                    "criterio": {id, comando}} … ] }
#   NEGATIVO = o valor de `--field` (default: `veredito`, depois `verdict`) casar `--negative` (regex sem
#   caixa; o default está em NEG abaixo, e LISTA FALHA PELO VOCABULÁRIO — passe o do seu juiz), OU
#   `refuted: true` (booleano ou "true"), OU `survives: true` (objeção que fica de pé), exceto
#   `kind: discarded-by-comodismo` — que é pedido de REABRIR, não reprovação. Veredito sem campo legível
#   e lista vazia saem rc 3 (não pude medir), nunca rc 0. INCONCLUSIVO entra de propósito: o critério 1 do teste da régua do markitdown
#   deu INCONCLUSIVO porque o desenho não apontava o que superaria o teste.
#
# Uso:  bash .claude/validation/judge-verdict-check.sh <verdicts.json> [--field F] [--negative RE]
# Exit: 0 = todo negativo tem critério pré-registrado + superação · 1 = ≥1 RECUSADO (listado, contado)
#       3 = NÃO PUDE MEDIR (sem node, JSON ilegível, sem `criteria` pré-registrados, bloco ausente).
# Saída: `SUPERACAO<TAB>alvo<TAB>o_que` por superação achada (o que a sessão grava como nó
#        `C_SUPERACAO_<AAAAMMDD>_…` com aresta TRACES_TO à reprovação) e `RECUSADO<TAB>alvo<TAB>motivo`.
# TETO DECLARADO: confere FORMA e PERTENÇA (id no registro, comando não vazio); se o comando citado de
# fato reprova o objeto é de quem re-roda — o comando fica no grafo para isso.
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_research_workflow_selftests, casos og*).
# ===========================================================================
set -uo pipefail
IN="${1:-}"; shift || true
FIELD=""; NEG='^(REPROV|REFUT|REJEIT|REJECT|PARQUE|PARK|INCONCLUS|NAO|NÃO|FALH|FAIL|DRIFTED|EXAGER|UNVERIF)'
while [ "$#" -gt 0 ]; do
  case "$1" in
    --field|--negative)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { echo "judge-verdict-check: $1 exige um valor" >&2; exit 3; }
      if [ "$1" = "--field" ]; then FIELD="$2"; else NEG="$2"; fi; shift 2 ;;
    *) echo "judge-verdict-check: opção desconhecida: $1" >&2; exit 3 ;;
  esac
done
[ -f "${IN}" ] || { echo "judge-verdict-check: entrada inexistente: '${IN}'" >&2; exit 3; }
command -v node >/dev/null 2>&1 || { echo "judge-verdict-check: node ausente — NÃO PUDE MEDIR (o gate é o bloco JS do motor)" >&2; exit 3; }
WF="${ONION_OVERCOMING_GATE_SRC:-${BASH_SOURCE[0]}}"
[ -f "${WF}" ] || { echo "judge-verdict-check: SSOT do gate ausente: ${WF}" >&2; exit 3; }
BLOCK="$(awk '/^\/\/ >>> overcoming-gate/{f=1} f{print} /^\/\/ <<< overcoming-gate/{f=0}' "${WF}")"
case "${BLOCK}" in *'function overcomingWhy'*'<<< overcoming-gate'*) : ;; *)
  echo "judge-verdict-check: bloco overcoming-gate ausente/incompleto em ${WF} — NÃO PUDE MEDIR" >&2; exit 3 ;;
esac
D="$(mktemp -d)"; trap 'rm -rf "${D}"' EXIT
{ printf '%s\n' "${BLOCK}"
  cat <<'JS'
const fs = require('fs')
const [inPath, field, negRe] = process.argv.slice(2)
let doc
try { doc = JSON.parse(fs.readFileSync(inPath, 'utf8')) } catch (e) { console.error('judge-verdict-check: JSON ilegível: ' + e.message); process.exit(3) }
const criteria = criteriaFrom(doc && doc.criteria, [])
if (!criteria.length) { console.error('judge-verdict-check: sem `criteria` PRÉ-REGISTRADOS ({id, when, check}) — reprovação sem critério é preferência; NÃO PUDE MEDIR'); process.exit(3) }
const verdicts = Array.isArray(doc.verdicts) ? doc.verdicts : null
if (!verdicts) { console.error('judge-verdict-check: sem lista `verdicts`'); process.exit(3) }
if (!verdicts.length) { console.error('judge-verdict-check: lista `verdicts` VAZIA — zero vereditos não é zero reprovação; NÃO PUDE MEDIR'); process.exit(3) }
let re
try { re = new RegExp(negRe, 'i') } catch (e) { console.error('judge-verdict-check: --negative inválido: ' + e.message); process.exit(3) }
const valueOf = v => String((field ? v[field] : (v.veredito !== undefined ? v.veredito : v.verdict)) ?? '').trim()
const isTrue = x => x === true || String(x).toLowerCase() === 'true'
const readable = v => v && typeof v === 'object' && (valueOf(v) !== '' || v.refuted !== undefined || v.survives !== undefined)
const unreadable = verdicts.filter(v => !readable(v))
if (unreadable.length) { console.error('judge-verdict-check: ' + unreadable.length + ' veredito(s) sem campo legível (' + (field || 'veredito/verdict') + ', refuted ou survives) — NÃO PUDE MEDIR'); process.exit(3) }
const isNeg = v => v.kind !== 'discarded-by-comodismo' && (isTrue(v.refuted) || isTrue(v.survives) || re.test(valueOf(v)))
const g = gateNegatives(verdicts, isNeg, criteria)
const alvo = v => String(v.alvo || v.target || v.node_id || v.id || '?').replace(/\s+/g, ' ').slice(0, 160)
for (const v of overcomingsFound(g.kept.filter(isNeg))) console.log('SUPERACAO\t' + alvo(v) + '\t' + String(v.superacao.o_que).replace(/\s+/g, ' ').slice(0, 280))
for (const r of g.recused) console.log('RECUSADO\t' + alvo(r.verdict) + '\t' + r.why)
const neg = verdicts.filter(v => v && isNeg(v)).length
console.log('judge-verdict-check: ' + verdicts.length + ' veredito(s) · ' + neg + ' negativo(s) · ' + overcomingsFound(g.kept.filter(isNeg)).length + ' superação(ões) achada(s) · ' + g.recused.length + ' RECUSADO(S) · critérios pré-registrados: ' + criteria.map(c => c.id).join(', '))
process.exit(g.recused.length ? 1 : 0)
JS
} > "${D}/gate.cjs"
node "${D}/gate.cjs" "${IN}" "${FIELD}" "${NEG}"
exit $?

# ── a cópia do gate (NÃO edite à mão: copie do onion-research.js; a bancada reprova divergência) ──
: <<'OVERCOMING_GATE'
// >>> overcoming-gate — O JUIZ QUE REPROVA BUSCA O QUE SUPERA (SAC-151). SSOT: este bloco; o
// census-workflow.mjs carrega cópia BYTE A BYTE (a bancada confere) e o judge-verdict-check.sh o EXECUTA
// para os juízes conduzidos pela sessão (/meta:cc-update, /meta:radar, /meta:dissect).
// Maestro, 2026-10-15 (verbatim): "um juiz de sim ou não sem tentar superação em uma pesquisa pode restringir
// possibilidades de crescimento e inovação; é preciso ter medição e critérios claros". Duas metades:
// (a) veredito NEGATIVO carrega `superacao: {classe, achada, o_que, medida}` — a peça, variante ou caminho que
//     entregaria o valor que o objeto prometia; `achada:false` exige a razão MEDIDA (o que se procurou e onde);
// (b) o critério de reprovação é PRÉ-REGISTRADO (args ou o default do juiz) e o veredito cita o `id` e o
//     `comando` que o checa. Negativo sem as duas metades é RECUSADO aqui, no motor (fail-closed, contado):
//     não vale como reprovação NEM como aprovação — o objeto fica não-julgado, nunca liberado.
// Evidência que motivou: a dissecação do markitdown num adotante de curadoria (PR #26, merge a2f8a5aef524) fechou em
// REJEITAR COM superação medida (o tesseract local lê o PDF escaneado em que a ferramenta sai vazia), e o
// critério 1 do teste da régua deu INCONCLUSIVO porque o desenho não apontava o que superaria o teste.
// TETO DECLARADO: o motor confere FORMA e PERTENÇA (o id está no registro, o comando não é vazio); se o
// comando citado de fato reprova o objeto é trabalho de quem re-roda — o comando fica no grafo para isso.
// ── SUPERAÇÃO DE CONSOLO (SAC-151, 2ª leva, 2026-10-15) ── achado de campo de um adotante de curadoria (PR #30,
// DADO): ao pagar a dívida, a 1ª versão preencheu 4 superações que o gate aceitou e só o Elenxo dela reprovou —
// (a) carimbo ou condição FUTURA, (b) peça ainda EM CURA, (c) o STATUS QUO dado como superação, (d) costura
// CIRCULAR (a superação é parte do próprio veredito). É Goodhart: preencher o campo para passar. O que a máquina
// consegue ver aqui, ela recusa: `classe` ausente ou incoerente com `achada`; `o_que` IGUAL ao próprio objeto
// (circular); `medida` que É o comando do critério da reprovação, sem mais nada (mede a reprovação, não a
// entrega — a forma medida dos 4 consolos). Só IGUALDADE, de propósito (refutador, 2026-10-15): a variante do
// objeto ("o markitdown com OCR") e o critério aplicado à variante são as formas mais fortes de superação, e a
// inclusão as recusaria. O resto (status quo, condição futura em prosa, `o_que` que só parafraseia o objeto)
// a máquina NÃO vê sem palavra-chave frágil: vai como PERGUNTA OBRIGATÓRIA ao juiz (CONSOLO_QUESTION),
// respondida no campo `classe`. TETO: o voto do Verify não carrega alvo no schema, então lá a recusa circular
// não roda (só a da âncora e a da classe).
const CONSOLO_QUESTION = 'a superação está MEDIDA e ENTREGA o valor que o objeto prometia, ou é status quo, condição futura ou parte do próprio veredito?'
const OVERCOMING_PROPS = {
  superacao: { type: 'object', required: ['classe', 'achada', 'o_que', 'medida'], properties: {
    classe: { enum: ['entrega', 'nenhuma'] }, achada: { type: 'boolean' }, o_que: { type: 'string' }, medida: { type: 'string' } } },
  criterio: { type: 'object', required: ['id', 'comando'], properties: { id: { type: 'string' }, comando: { type: 'string' } } } }
const _ogFilled = (s, min) => typeof s === 'string' && s.trim().length >= min
// critérios do chamador (args) substituem o default SÓ quando bem formados: {id, when, check}
function criteriaFrom(override, defaults) {
  const list = Array.isArray(override) ? override.filter(c => c && _ogFilled(String(c.id || ''), 1) && _ogFilled(String(c.check || ''), 3))
    .map(c => ({ id: String(c.id).trim(), when: String(c.when || '').trim(), check: String(c.check).trim() })) : []
  return list.length ? list : defaults
}
const criteriaBlock = (criteria) => '\n\n## Critérios de reprovação PRÉ-REGISTRADOS (reprovar fora deles é preferência, não medida)\n' +
  criteria.map(c => '- `' + c.id + '` — ' + c.when + ' · checa: `' + c.check + '`').join('\n') +
  '\n\n## Todo veredito NEGATIVO leva as duas metades (o motor RECUSA e conta o que vier sem elas)\n' +
  '- `criterio: {id, comando}` — o `id` de UM critério acima e o comando concreto (com os argumentos deste caso) que qualquer um re-roda para ver a reprovação.\n' +
  '- `superacao: {classe, achada, o_que, medida}` — antes de reprovar, PROCURE o que supera: a peça, variante, fonte ou caminho que entregaria o valor que o objeto prometia. `achada:true` → `o_que` nomeia e `medida` diz como se mediu; `achada:false` → `medida` diz o que se procurou e onde (comando ou fonte), nunca "não encontrei" seco.\n' +
  '- PERGUNTA OBRIGATÓRIA antes de preencher `classe`: ' + CONSOLO_QUESTION + ' Só `classe: "entrega"` (com `achada:true`) quando a superação JÁ foi medida entregando aquele valor; status quo, carimbo ou condição futura, peça ainda em cura e costura que é parte do próprio veredito são CONSOLO e vão como `classe: "nenhuma"` (com `achada:false`) e a razão medida. `nenhuma` honesta é veredito válido; consolo preenchido para passar é o que o Elenxo reprova.'
const _ogNorm = (x) => String(x == null ? '' : x).toLowerCase().replace(/[`'"]/g, '').replace(/\s+/g, ' ').trim()
const _ogSquash = (x) => _ogNorm(x).replace(/\s+/g, '')
function overcomingWhy(v, criteria) {
  const s = v && v.superacao
  if (!s || typeof s !== 'object' || typeof s.achada !== 'boolean') return 'veredito negativo sem superacao {classe, achada, o_que, medida}'
  if (s.classe !== 'entrega' && s.classe !== 'nenhuma') return 'superacao sem classe (entrega|nenhuma): responda a pergunta do consolo'
  if ((s.classe === 'entrega') !== s.achada) return 'superacao com classe ' + s.classe + ' contradiz achada:' + s.achada
  if (s.achada && !_ogFilled(s.o_que, 8)) return 'superacao achada sem o_que (a peca, variante ou caminho que supera)'
  if (!_ogFilled(s.medida, 8)) return s.achada ? 'superacao achada sem a medida que a sustenta' : 'superacao nao achada sem a razao MEDIDA (achada:false exige medida)'
  const c = v.criterio
  if (!c || typeof c !== 'object' || !_ogFilled(c.id, 1)) return 'veredito negativo sem criterio pre-registrado citado'
  if (!criteria.some(k => k.id === String(c.id).trim())) return 'criterio ' + JSON.stringify(String(c.id)) + ' NAO esta pre-registrado (' + criteria.map(k => k.id).join(', ') + ')'
  if (!_ogFilled(c.comando, 3)) return 'criterio citado sem o comando que o checa'
  if (s.classe === 'entrega') {
    const objTarget = _ogNorm(v.alvo || v.target || v.node_id || v.id || v.claim)
    if (objTarget && _ogNorm(s.o_que) === objTarget) return 'superacao CIRCULAR: o_que e o proprio objeto julgado (consolo)'
    const cmd = _ogSquash(c.comando)
    if (cmd.length >= 8 && _ogSquash(s.medida) === cmd) return 'superacao ancorada no criterio da reprovacao: a medida e o comando que reprova, nao o que entrega (consolo)'
  }
  return ''
}
// separa o que VALE do que o motor recusa: { kept, recused: [{ verdict, why }] }
function gateNegatives(list, isNegative, criteria) {
  const kept = [], recused = []
  for (const v of (list || [])) { if (!v) continue; const why = isNegative(v) ? overcomingWhy(v, criteria) : ''; if (why) recused.push({ verdict: v, why }); else kept.push(v) }
  return { kept, recused }
}
const overcomingsFound = (list) => (list || []).filter(v => v && v.superacao && v.superacao.achada === true && v.superacao.classe === 'entrega')
// <<< overcoming-gate
OVERCOMING_GATE
