#!/usr/bin/env bash
# =============================================================================
# workflow-syntax-check.sh — checa a sintaxe de um script da ferramenta Workflow
#
# POR QUE EXISTE (medido 2026-09-22): a skill `onion-orchestration` manda rodar
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
# A CURA: espelhar o runtime. `export const meta = {…}` fica no topo (é módulo), e
# TODO o resto vai para dentro de `export default async function(){ … }`, que é a
# forma que o runtime de fato executa. Aí `return` no topo é válido e um erro de
# sintaxe real aparece.
#
# Uso  : bash .claude/validation/workflow-syntax-check.sh <script.js|.mjs> [...]
# Saída: uma linha por arquivo; exit 1 se algum reprovar, 2 se faltar ferramenta.
# =============================================================================
set -uo pipefail

command -v node >/dev/null 2>&1 || {
  echo "workflow-syntax-check: node AUSENTE — não pude julgar (≠ passou)." >&2; exit 2; }

[ "$#" -gt 0 ] || { echo "uso: $0 <script.js|.mjs> [...]" >&2; exit 2; }

rc=0
for f in "$@"; do
  if [ ! -f "${f}" ]; then echo "  ✗ ${f}: arquivo ausente"; rc=1; continue; fi
  # separa `export const meta = {…}` do corpo contando chaves (o meta é literal puro
  # por contrato da ferramenta, então a contagem é segura)
  wrapped="$(python3 - "${f}" <<'PY'
import io, sys
src = io.open(sys.argv[1], encoding='utf-8').read()
i = src.find('export const meta')
if i < 0:
    # sem meta: o arquivo inteiro é corpo
    print("export default async function(){\n" + src + "\n}")
    raise SystemExit(0)
k = src.index('{', i); d = 0
while k < len(src):
    if src[k] == '{': d += 1
    elif src[k] == '}':
        d -= 1
        if d == 0: break
    k += 1
print(src[:k+1] + "\nexport default async function(){\n" + src[k+1:] + "\n}")
PY
)" || { echo "  ✗ ${f}: não consegui separar o bloco meta"; rc=1; continue; }
  if err="$(printf '%s' "${wrapped}" | node --input-type=module --check 2>&1)"; then
    echo "  ✓ ${f}"
  else
    echo "  ✗ ${f}: $(printf '%s' "${err}" | grep -m1 -E 'Error|error' | head -c 160)"
    rc=1
  fi
done
exit "${rc}"
