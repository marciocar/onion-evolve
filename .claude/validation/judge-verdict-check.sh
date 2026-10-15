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
# ── SSOT: o bloco `// >>> overcoming-gate` do onion-research.js, EXECUTADO, nunca copiado ──────
# Duas cópias da mesma regra divergem (a classe do vocabulário duplicado). Aqui o bloco é extraído
# do workflow e rodado por `node`; a bancada confere que a cópia do census-workflow.mjs é idêntica.
#
# ── ENTRADA ────────────────────────────────────────────────────────────────────────────────
#   { "criteria": [ {"id","when","check"} … ],      # PRÉ-REGISTRADOS antes do juiz rodar
#     "verdicts": [ {"alvo", "<campo>": "<valor>", "superacao": {achada,o_que,medida},
#                    "criterio": {id, comando}} … ] }
#   NEGATIVO = o valor de `--field` (default: `veredito`, depois `verdict`) casar `--negative`
#   (regex, default `^(REPROV|REFUT|REJEIT|PARQUE|INCONCLUS|NAO|NÃO|FALH|DRIFTED)`, sem caixa), OU
#   `refuted: true`. INCONCLUSIVO entra de propósito: o critério 1 do teste da régua do markitdown
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
FIELD=""; NEG='^(REPROV|REFUT|REJEIT|PARQUE|INCONCLUS|NAO|NÃO|FALH|DRIFTED)'
while [ "$#" -gt 0 ]; do
  case "$1" in
    --field) FIELD="${2:-}"; shift 2 ;;
    --negative) NEG="${2:-}"; shift 2 ;;
    *) echo "judge-verdict-check: opção desconhecida: $1" >&2; exit 3 ;;
  esac
done
[ -f "${IN}" ] || { echo "judge-verdict-check: entrada inexistente: '${IN}'" >&2; exit 3; }
command -v node >/dev/null 2>&1 || { echo "judge-verdict-check: node ausente — NÃO PUDE MEDIR (o gate é o bloco JS do motor)" >&2; exit 3; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
WF="${ONION_OVERCOMING_GATE_SRC:-${ROOT}/.claude/workflows/onion-research.js}"
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
const re = new RegExp(negRe, 'i')
const valueOf = v => String((field ? v[field] : (v.veredito !== undefined ? v.veredito : v.verdict)) ?? '')
const isNeg = v => v.refuted === true || re.test(valueOf(v).trim())
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
