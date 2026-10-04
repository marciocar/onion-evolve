#!/usr/bin/env bash
# cited-directive-check.sh — REGRA 98: diretiva de injeção escrita como CITAÇÃO não pode estar VIVA.
#
# ── O DEFEITO, MEDIDO E DATADO (cláusula 1 da guard-doctrine) ──────────────────────────────────
# 2026-10-04, rodada do /meta:evolve (nó C_CREATE_SKILL_EXECUTA_GIT_DIFF_A_CADA_INVOCACAO): o
# `/meta:create-skill` EXECUTAVA `git diff` e `git diff HEAD` a CADA invocação, porque dois exemplos
# de documentação — um em crase dupla dentro de uma pergunta, outro dentro de um bloco cercado — casam
# as regex do harness do Claude Code 2.1.289. O autor escreveu CITAÇÃO; o harness leu INVOCAÇÃO. Mais
# quatro sítios no `agent-skills-specialist`. Foi a 2ª instância no mesmo dia: o `/meta:forge-guard`
# tinha nascido MORTO NA CARGA (`cmd: command not found`) pelo mesmo mecanismo. Curados por instância
# na leva 1; esta guarda cobra a CLASSE.
#
# ── A DIVERGÊNCIA QUE ELA FECHA ─────────────────────────────────────────────────────────────────
# A REGRA 96 (Diretiva de contexto INJETADO não corta listagem em silêncio) classifica bloco cercado
# e crase dupla como CITADOS — e chamava a crase dupla de "a forma canônica de citar uma diretiva".
# O harness não pensa assim: ele NÃO pula bloco cercado, e o mascaramento dele só neutraliza code-span
# sem `!` antes, então a crase dupla sobrevive. Duas leituras do mesmo texto, e quem executa é a
# segunda. Esta guarda é o simulador da segunda leitura, cruzado com o contexto que diz "isto é
# citação": onde as duas discordam, a diretiva é viva por acidente.
#
# ── O MOTOR (cláusula 3: o motor do padrão decide a sintaxe) ────────────────────────────────────
# As funções que ACHAM as diretivas são copiadas LITERALMENTE do binário 2.1.289 e rodam em node —
# o mesmo motor de regex do harness. A 1ª versão as TRANSCREVIA para Python, e o Elenxo provou por
# fuzz diferencial (20 mil textos) 184 divergências: o lookbehind do Python reinicia a varredura uma
# posição depois e a máscara apagava as crases que o harness preserva. Transcrição é tradução, e
# tradução erra; cópia literal no motor original não tem o que errar. O que é NOSSO é só o contexto.
#   máscara (pTe) : code-span sem `!` nem crase antes perde o MIOLO, as crases ficam
#   bloco   (cDn) : sobre o texto CRU — cerca de três crases seguida de `!`
#   inline  (uDn) : sobre o texto MASCARADO — `!` + crase após início-de-linha ou espaço
#
# ── O CONTEXTO DE CITAÇÃO (o que é nosso) ───────────────────────────────────────────────────────
# Uma diretiva que o harness executa é ACUSADA se estiver em:
#   · bloco cercado — cerca de ``` ou ~~~ (3+), com qualquer recuo, fechada pelo MESMO caractere com
#     comprimento >= ao da abertura; TODA cerca alterna o estado, inclusive a da diretiva-bloco (a 1ª
#     versão deixava a cerca de fechamento de uma diretiva-bloco ABRIR um bloco, e acusava toda
#     diretiva real que viesse depois — falso positivo F1 do Elenxo);
#   · diretiva-bloco cuja cerca não começa a linha (menção em prosa) ou que está dentro de cerca maior;
#   · span de crase dupla que CONTÉM a diretiva (não basta haver crase dupla na linha — F5);
#   · linha de citação (`>`) ou comentário HTML.
# ── TETO DECLARADO (cláusula 7) ─────────────────────────────────────────────────────────────────
#  · As funções são COPIADAS do binário 2.1.289. Versão nova do Claude Code pode mudar o parser: a
#    bancada confere se o binário INSTALADO ainda contém o texto das regex (deriva vira reprovação), e
#    a REGRA 65 (Radar de mundo com baseline DATADA por eixo) acusa a versão nova.
#  · Diretiva viva numa linha de prosa comum é tratada como INTENCIONAL — é a forma das diretivas de
#    verdade, e intenção não se mede. Exemplo escrito em prosa nua, em tabela ou em lista passa.
#  · NÃO vê bloco de código por RECUO de 4 espaços (fn12 do Elenxo): distinguir dele a continuação de
#    item de lista exige um parser de markdown, e um falso positivo ali vetaria toda lista com diretiva.
#  · Universo: `.claude/commands`, `.claude/skills` e `plugins/*/{commands,skills}`. NÃO varre
#    `.claude/agents`, e isso é medido: o harness NÃO injeta em corpo de agente (as 7 chamadas do
#    executor estão no carregador de commands e skills, Elenxo da leva 1, 2026-10-04).
#  · Busca é por arquivo `.md` rastreado no git; arquivo não rastreado não é julgado.
#  · Diretiva montada por substituição de `$ARGUMENTS` só existe na invocação, não no arquivo.
#  · Arquivo não-UTF-8 é lido com substituição (como o node lê), não reprovado como ilegível.
set -euo pipefail

SELFTEST=0; FORMAT=human; ROOT=""
while [ "$#" -gt 0 ]; do case "$1" in
  --selftest) SELFTEST=1 ;;
  --tsv)      FORMAT=tsv ;;
  -h|--help)  sed -n '2,3p' "$0"; exit 0 ;;
  --*)        printf 'cited-directive-check: flag desconhecida: %s\n' "$1" >&2; exit 2 ;;
  *)          ROOT="$1" ;;
esac; shift; done
ROOT="${ROOT:-.}"
REPO="$(cd "${ROOT}" 2>/dev/null && pwd)" || { printf 'cited-directive-check: repo_root inválido: %s\n' "${ROOT}" >&2; exit 2; }
command -v node >/dev/null 2>&1 || {
  [ "${FORMAT}" = tsv ] && printf 'HARD\tSEM-MOTOR\t.claude/validation/cited-directive-check.sh\tnode ausente: a guarda NAO pode julgar (fail-loud, nunca aprovacao)\n'
  printf 'cited-directive-check: node ausente\n' >&2; exit 2; }
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# _engine <arquivo>... — imprime path<TAB>linha<TAB>contexto<TAB>comando; `#ILEGIVEL<TAB>path` se não lê
_engine() {
  node - "$@" <<'JS'
// ── verbatim de Claude Code 2.1.289 (pTe, cDn, uDn, bGn); `vi(" ",k)` do binário = " ".repeat(k) ──
function pTe(e){return e.replace(/`[^`\n]+`/g,(n,r)=>{let s=e[r-1];return s==="!"||s==="`"?n:"`"+" ".repeat(n.length-2)+"`"})}
var cDn=/```!\s*\n?([\s\S]*?)\n?```/g,uDn=/(?<=^|\s)!`([^`]+)`/gm;
function bGn(e){let n=e.matchAll(cDn),r=e.includes("!`")?pTe(e).matchAll(uDn):[],s=[];for(let g of[...n,...r]){let h=g[1]?.trim();if(h)s.push({raw:g[0],command:h,at:g.index})}return s}
// ── fim do verbatim ──
const fs = require('fs')
function fences(t) {   // [ini, fim) de cada bloco cercado, por offset
  const out = []; let open = null, off = 0
  for (const line of t.split('\n')) {
    const m = /^\s*(`{3,}|~{3,})(.*)$/.exec(line)
    if (m) {
      if (!open) open = { ch: m[1][0], len: m[1].length, at: off }
      else if (m[1][0] === open.ch && m[1].length >= open.len && !m[2].trim()) { out.push([open.at, off + line.length]); open = null }
    }
    off += line.length + 1
  }
  if (open) out.push([open.at, t.length])
  return out
}
function context(t, F, d) {
  const lineStart = t.lastIndexOf('\n', d.at - 1) + 1
  const line = t.slice(lineStart, t.indexOf('\n', d.at) < 0 ? t.length : t.indexOf('\n', d.at))
  const isBlock = d.raw.startsWith('```')
  if (isBlock) {
    if (t.slice(lineStart, d.at).trim()) return 'menção em prosa'
    // a cerca da PRÓPRIA diretiva começa nesta linha: só conta cerca aberta em linha anterior
    if (F.some(([a, b]) => a < lineStart && d.at < b)) return 'bloco cercado'
    return null
  }
  if (F.some(([a, b]) => a <= d.at && d.at < b)) return 'bloco cercado'
  for (const m of line.matchAll(/``(?!`)[\s\S]*?``/g)) {
    const a = lineStart + m.index, b = a + m[0].length
    if (a <= d.at && d.at < b) return 'crase dupla'
  }
  if (/^\s*>/.test(line)) return 'citação (>)'
  const open = t.lastIndexOf('<!--', d.at), close = t.lastIndexOf('-->', d.at)
  if (open >= 0 && open > close) return 'comentário HTML'
  return null
}
for (const p of process.argv.slice(2)) {
  let t
  try { t = fs.readFileSync(p, 'utf8') } catch (e) { console.log('#ILEGIVEL\t' + p); continue }
  const F = fences(t)
  for (const d of bGn(t)) {
    const c = context(t, F, d)
    if (c) console.log([p, t.slice(0, d.at).split('\n').length, c, d.command.replace(/\s+/g, ' ').slice(0, 80)].join('\t'))
  }
}
JS
}

if [ "${SELFTEST}" = "1" ]; then
  command -v node >/dev/null 2>&1 || { printf '  ✗ cited-directive: node ausente — selftest nao pode rodar\n'; exit 2; }
  _p=0; _f=0; d="$(mktemp -d)"; trap 'rm -rf "${d}"' EXIT
  _ok()  { _p=$((_p+1)); printf '  ✓ cited-directive: %s\n' "$1"; }
  _bad() { _f=$((_f+1)); printf '  ✗ cited-directive: %s — %s\n' "$1" "$2"; }
  B='`'; BB='``'; F='```'; FFFF='````'
  _w() { printf "$@" > "${d}/x.md"; }          # escreve o caso
  _acusa() {   # $1 nome · $2 linha esperada · $3 contexto esperado · $4 comando esperado
    local o; o="$(_engine "${d}/x.md")"
    if grep -qF "$(printf '%s\t%s\t%s' "$2" "$3" "$4")" <<< "${o}"; then _ok "$1"; else _bad "$1" "[${o}]"; fi; }
  _cala() { local o; o="$(_engine "${d}/x.md")"; if [ -z "${o}" ]; then _ok "$1"; else _bad "$1" "falso positivo: [${o}]"; fi; }

  # ── (a) ACUSA: os dois sítios do dano, VERBATIM (create-skill l.86 e l.219, 2026-10-04) ──
  _w '   - Dynamic injection (%s !%sgit diff%s %s) para dados live?\n' "${BB}" "${B}" "${B}" "${BB}"
  _acusa "(a1) crase dupla (create-skill l.86, verbatim)" 1 'crase dupla' 'git diff'
  _w '%smarkdown\n## Mudanças atuais\n\n!%sgit diff HEAD%s\n%s\n' "${F}" "${B}" "${B}" "${F}"
  _acusa "(a2) bloco cercado (create-skill l.219, verbatim)" 4 'bloco cercado' 'git diff HEAD'
  # ── (b) ACUSA: as formas que a 1a versão NÃO via (falsos negativos do Elenxo) ──
  _w '%s\n%s!\ngit status\n%s\n%s\n' "${FFFF}" "${F}" "${F}" "${FFFF}"
  _acusa "(b1) diretiva-bloco citada dentro de cerca de 4 crases (fn6)" 2 'bloco cercado' 'git status'
  _w 'A forma bloco abre com %s! e fecha com %s no fim.\n' "${F}" "${F}"
  _acusa "(b2) diretiva-bloco mencionada em prosa (fn7)" 1 'menção em prosa' 'e fecha com'
  _w '1. Exemplo:\n   %smarkdown\n   !%sgit diff%s\n   %s\n' "${F}" "${B}" "${B}" "${F}"
  _acusa "(b3) cerca recuada em item de lista (fn9)" 3 'bloco cercado' 'git diff'
  _w '~~~\n!%sgit diff%s\n~~~\n' "${B}" "${B}"
  _acusa "(b4) cerca de til (fn8)" 2 'bloco cercado' 'git diff'
  _w '> !%sgit diff%s\n' "${B}" "${B}"
  _acusa "(b5) linha de citação (fn2)" 1 'citação (>)' 'git diff'
  _w '<!--\n!%sgit diff%s\n-->\n' "${B}" "${B}"
  _acusa "(b6) comentário HTML (fn4)" 2 'comentário HTML' 'git diff'
  # ── (c) CALA no honesto (falso positivo treina a sessão a ignorar o veto) ──
  _w '**Hoje:** !%sdate +%%F%s\n' "${B}" "${B}"
  _cala "(c1) diretiva real em prosa"
  _w '%s!\ngit status\n%s\n\n**Hoje:** !%sdate +%%F%s\n' "${F}" "${F}" "${B}" "${B}"
  _cala "(c2) diretiva real DEPOIS de uma diretiva-bloco (fp1: a cerca de fechamento não abre bloco)"
  _w '**Diff:** !%sgit diff --stat%s (o par %s%sx%s%s é citação de OUTRA coisa)\n' "${B}" "${B}" "${BB}" "${B}" "${B}" "${BB}"
  _cala "(c3) crase dupla em outro trecho da linha não contamina a diretiva real (fp2)"
  _w '~~~\n%s\n~~~\n**Hoje:** !%sdate +%%F%s\n' "${F}" "${B}" "${B}"
  _cala "(c4) cerca de crase dentro de bloco de til não inverte o estado (fp5)"
  _w 'Veja %sx%s!%sgit diff%s %sy%s\n' "${B}" "${B}" "${B}" "${B}" "${BB}" "${BB}"
  _cala "(c5) o que o harness NÃO executa não é acusado (fp3 — a máscara é a do binário)"
  _w -- '- Dynamic injection (exclamação, crase, comando, crase — %s!%s FORA e antes da 1a crase)\n%sexemplo\n%s\n**Hoje:** !%sdate +%%F%s\n' "${B}" "${B}" "${F}" "${F}" "${B}" "${B}"
  _cala "(c6) a forma DESCRITA da leva 1 e diretiva real depois de bloco fechado"
  # ── (d) FAIL-LOUD ──
  _o="$(_engine "${d}/nao-existe.md")"
  if grep -q '^#ILEGIVEL' <<< "${_o}"; then _ok "(d) ilegivel vira sentinela"; else _bad "(d) ilegivel" "[${_o}]"; fi
  printf '\n  cited-directive selftest: %s passaram, %s falharam\n' "${_p}" "${_f}"
  [ "${_f}" -eq 0 ] || exit 1
  exit 0
fi

mapfile -t _FILES < <(cd "${REPO}" && git ls-files '.claude/commands/*.md' '.claude/commands/**/*.md' '.claude/skills/**/*.md' 'plugins/*/commands/*.md' 'plugins/*/commands/**/*.md' 'plugins/*/skills/**/*.md' 2>/dev/null)
if [ "${#_FILES[@]}" -eq 0 ]; then
  [ "${FORMAT}" = tsv ] && printf 'HARD\tVACUIDADE\t.claude/validation/cited-directive-check.sh\tnenhum comando/skill rastreado: o varredor esta cego, nao o repo limpo\n'
  printf '  ✗ VACUIDADE: nenhum arquivo para varrer\n' >&2; exit 1
fi
# ⚠️ motor que MORRE é HARD, nunca aprovação (F6 do Elenxo): sob `set -e` a morte saía rc=1 com
#    stdout vazio, e o dispatcher só escala rc>=2 — queda do motor passava calada.
_HITS="$(cd "${REPO}" && _engine "${_FILES[@]}")" || {
  [ "${FORMAT}" = tsv ] && printf 'HARD\tSEM-MOTOR\t.claude/validation/cited-directive-check.sh\to motor (node) morreu: a guarda NAO pode julgar (fail-loud)\n'
  printf 'cited-directive-check: motor morreu\n' >&2; exit 2; }
_ILEG="$(grep '^#ILEGIVEL' <<< "${_HITS}" | cut -f2- || true)"
if [ -n "${_ILEG}" ]; then
  while IFS= read -r _b; do [ -n "${_b}" ] || continue
    if [ "${FORMAT}" = tsv ]; then printf 'HARD\tILEGIVEL\t%s\tfonte ilegivel: a guarda NAO pode julgar este arquivo (fail-loud por stdout; nunca aprovacao por silencio)\n' "${_b}"
    else printf '  ✗ cited-directive-check: ilegível: %s\n' "${_b}" >&2; fi
  done <<< "${_ILEG}"; exit 2
fi
if [ -z "${_HITS}" ]; then
  [ "${FORMAT}" = tsv ] || printf '  ✅ REGRA 98: nenhuma diretiva citada está viva (%s arquivo(s) lidos)\n' "${#_FILES[@]}"
  exit 0
fi
while IFS=$'\t' read -r _f _n _ctx _cmd; do
  [ -n "${_f}" ] || continue
  _msg="l.${_n}: o texto está escrito como CITAÇÃO (${_ctx}) mas o harness o EXECUTA como diretiva de injeção — roda \`${_cmd}\` a cada invocação (dano medido 2026-10-04: o /meta:create-skill rodava git diff assim). O harness NÃO pula bloco cercado e NÃO mascara crase dupla. DESCREVA a forma (\"o caractere ! colado ao comando entre crases\"), nunca a escreva."
  if [ "${FORMAT}" = tsv ]; then printf 'HARD\tREGRA98\t%s\t%s\n' "${_f}" "${_msg}"
  else printf '  ✗ REGRA 98 — %s: %s\n' "${_f}" "${_msg}"; fi
done <<< "${_HITS}"
exit 1
