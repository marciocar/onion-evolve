#!/usr/bin/env bash
# =============================================================================
# workflow-syntax-check.sh — checa a sintaxe de um script da ferramenta Workflow
#
# POR QUE EXISTE (medido 2026-09-22): a skill `onion-orchestration` mandava rodar
#   node --input-type=module --check < <script>
# antes de invocar o `Workflow`. Esse comando REPROVA **todo** script válido desta
# casa — 2 de 2 no corpus (`onion-research.js`, `census-workflow.mjs`) — porque o
# corpo de um script Workflow roda DENTRO de uma função async, onde `return` no
# topo é legal, e o `--check` como módulo o rejeita com `Illegal return statement`.
#
# Guarda que pune quem obedece ensina a ignorar a guarda (é a mesma doutrina já
# escrita no review-artifact-check.sh). E o custo aqui é pior que ruído: quem roda
# o check documentado vê vermelho SEMPRE, aprende que ele não vale, e o dia em que
# houver um backtick perdido no meio de um template literal — o modo-de-falha que
# a skill nomeia — o vermelho não vai dizer nada.
#
# ── COMO ESTA GUARDA ESPELHA O RUNTIME (e por que NÃO conta chaves) ───────────
# A 1ª versão separava `export const meta = {…}` do corpo CONTANDO `{`/`}`, porque
# `export` não pode viver dentro de função. A passada adversarial de 2026-09-22 a
# derrubou nas DUAS direções, e o contador ignorava strings e comentários:
#   (a) FALSO NEGATIVO, o grave — uma `{` desbalanceada dentro de uma string do
#       meta fazia a contagem nunca voltar a zero, o corpo sair VAZIO, e o arquivo
#       inteiro ser checado como módulo puro. Isto DEGRADA o wrapper de volta ao
#       `node --check` cru, que é exatamente o bug que ele existe para curar.
#   (b) FALSO POSITIVO — uma `{` ou um `export const meta` dentro de COMENTÁRIO
#       reprovava script válido com mensagem sem nexo. Não é hipotético: o
#       `onion-research.js` já carrega 12 linhas de comentário acima do meta.
# A cura REMOVE o problema em vez de refinar a heurística: tira o `export ` de UMA
# declaração só — `export const meta`, ancorada em início de linha, `count=1` — e
# envolve o ARQUIVO INTEIRO. Sem split, sem contagem.
# ⚠️ A 1ª tentativa desta cura tirava `export ` de QUALQUER declaração de topo, e
# isso abria um falso negativo novo: um `export const z = 1` perdido no corpo É
# SyntaxError no runtime, e o strip o tornava legal. Pego reproduzindo, antes do
# commit, o caso `f1` que a passada adversarial havia construído. A âncora estreita
# deixa todo outro `export` intacto — e ele continua reprovando, que é o certo.
# Comentário não é afetado: `//` e `#` não casam `^[ \t]*export`.
#
# Uso  : bash ${CLAUDE_PLUGIN_ROOT}/validation/workflow-syntax-check.sh <script.js|.mjs> [...]
# Saída: uma linha por arquivo; exit 1 se algum reprovar, 2 se faltar ferramenta.
# =============================================================================
set -uo pipefail

_lib_missing() { echo "workflow-syntax-check: $1 AUSENTE — não pude julgar (≠ passou)." >&2; exit 2; }
command -v node    >/dev/null 2>&1 || _lib_missing node
command -v python3 >/dev/null 2>&1 || _lib_missing python3

[ "$#" -gt 0 ] && [ "${1}" != "--help" ] || { echo "uso: $0 <script.js|.mjs> [...]" >&2; exit 2; }

_WRAP_PY='
import io, re, sys
src = io.open(sys.argv[1], encoding="utf-8", newline="").read()
src = re.sub(r"(?m)^([ \t]*)export[ \t]+(const[ \t]+meta\b)", r"\1\2", src, count=1)
sys.stdout.write("export default async function(){\n" + src + "\n}\n")
'

rc=0
for f in "$@"; do
  if [ ! -f "${f}" ]; then echo "  ✗ ${f}: arquivo ausente"; rc=1; continue; fi
  if ! wrapped="$(python3 -c "${_WRAP_PY}" "${f}" 2>&1)"; then
    # ferramenta/leitura falhou — NÃO é veredito sobre o SUT
    echo "  ⊘ ${f}: não consegui preparar o arquivo para o check (${wrapped:0:100}) — NÃO PUDE JULGAR"
    rc=2; continue
  fi
  # `command -v node` prova que o binario EXISTE, nao que ele RODA. Um node quebrado (exit 127,
  # 126, morto por sinal) caia no ramo de baixo e virava "✗ <arquivo>" — ferramenta quebrada
  # rotulada como defeito do SUT, a mesma classe que o cabecalho promete nao cometer. O node sai 1
  # em erro de SINTAXE; qualquer outro rc e falha de FERRAMENTA. Achado pela bancada, caso (i).
  err="$(printf '%s' "${wrapped}" | node --input-type=module --check 2>&1)"; nrc=$?
  if [ "${nrc}" -eq 0 ]; then
    echo "  ✓ ${f}"
  elif [ "${nrc}" -eq 1 ]; then
    echo "  ✗ ${f}: $(printf '%s' "${err}" | grep -m1 -E 'Error' | head -c 160)"
    rc=1
  else
    echo "  ⊘ ${f}: node saiu ${nrc} sem julgar (${err:0:80}) — NAO PUDE JULGAR (≠ passou)"
    rc=2
  fi
done
exit "${rc}"
