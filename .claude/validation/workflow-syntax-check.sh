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
# Uso  : bash .claude/validation/workflow-syntax-check.sh <script.js|.mjs> [...]
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

# ── RELÓGIO E SORTEIO PROIBIDOS (medido 2026-11-12) ──────────────────────────
# O runtime do Workflow recusa o script com "Date.now() / new Date() are unavailable in workflow
# scripts (breaks resume)": o resume REEXECUTA o corpo e precisa que ele dê o mesmo resultado.
# O `decide-triage.js` gerava o nonce da cerca com `Date.now()` + `Math.random()`, passava neste
# check (a sintaxe é válida) e por isso o modo triagem do /meta:decide NUNCA rodou. Sintaxe válida
# que o runtime recusa é o mesmo vermelho-tardio que este arquivo existe para antecipar.
# `Math.random()` entra pela mesma razão: o replay não reproduz o sorteio.
# Varre só CÓDIGO: comentário e string são apagados antes (o `onion-research.js` cita `Date.now()`
# numa mensagem de erro e num comentário, e isso é legítimo). Regex literal é reconhecido pela
# heurística usual (barra depois de operador/abertura), para uma aspa dentro dela não dessincronizar.
_CLOCK_PY='
import io, re, sys
src = io.open(sys.argv[1], encoding="utf-8", newline="").read()
out = list(src); n = len(src); i = 0; stack = []   # stack: profundidade de chave de cada ${ aberto
def blank(a, b):
    for k in range(a, b):
        if out[k] != "\n": out[k] = " "
def prev_sig(k):
    k -= 1
    while k >= 0 and out[k] in " \t\r\n": k -= 1
    return out[k] if k >= 0 else ""
def template(k):   # k aponta logo depois da crase; devolve onde o texto do template termina
    while k < n:
        c = src[k]
        if c == "\\": k += 2; continue
        if c == "`": return k + 1, False
        if c == "$" and k + 1 < n and src[k+1] == "{": return k + 2, True
        k += 1
    return n, False
while i < n:
    c = src[i]
    if c == "/" and i + 1 < n and src[i+1] == "/":
        j = src.find("\n", i); j = n if j < 0 else j; blank(i, j); i = j; continue
    if c == "/" and i + 1 < n and src[i+1] == "*":
        j = src.find("*/", i + 2); j = n if j < 0 else j + 2; blank(i, j); i = j; continue
    if c in "\"\x27":
        j = i + 1
        while j < n and src[j] != c and src[j] != "\n":
            j += 2 if src[j] == "\\" else 1
        blank(i, min(j + 1, n)); i = j + 1; continue
    if c == "`":
        j, opened = template(i + 1); blank(i, j - (2 if opened else 0)); i = j
        if opened: stack.append(0)
        continue
    if c == "/" and (prev_sig(i) in "(,=:[!&|?{};+-*%<>~^" or re.search(r"\b(return|typeof|case)\s*$", "".join(out[max(0,i-12):i]))):
        j = i + 1; cls = False
        while j < n and src[j] != "\n":
            if src[j] == "\\": j += 2; continue
            if src[j] == "[": cls = True
            elif src[j] == "]": cls = False
            elif src[j] == "/" and not cls: break
            j += 1
        blank(i, min(j + 1, n)); i = j + 1; continue
    if stack:
        if c == "{": stack[-1] += 1
        elif c == "}":
            if stack[-1] == 0:
                stack.pop(); j, opened = template(i + 1); blank(i, j - (2 if opened else 0)); i = j
                if opened: stack.append(0)
                continue
            stack[-1] -= 1
    i += 1
code = "".join(out)
pat = re.compile(r"\bDate\s*\.\s*now\s*\(|\bnew\s+Date\b|(?<![\w$.])Date\s*\(|\bMath\s*\.\s*random\s*\(")
for m in pat.finditer(code):
    ln = code.count("\n", 0, m.start()) + 1
    print("%d: %s" % (ln, re.sub(r"\s+", "", m.group(0))))
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
    if ! clock="$(python3 -c "${_CLOCK_PY}" "${f}" 2>&1)"; then
      echo "  ⊘ ${f}: a varredura de relógio/sorteio falhou (${clock:0:100}) — NÃO PUDE JULGAR"
      rc=2; continue
    fi
    if [ -n "${clock}" ]; then
      echo "  ✗ ${f}: relógio/sorteio no código, que o runtime de workflow recusa (quebra o resume) — linha $(printf '%s' "${clock}" | sed -n '1,3p' | tr '\n' ' ')"
      rc=1; continue
    fi
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
