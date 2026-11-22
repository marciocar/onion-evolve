#!/usr/bin/env bash
# =============================================================================
# agent-color-check.sh — cor de AGENTE presente, na paleta e igual à da categoria (REGRA 122)
#
# POR QUE EXISTE (defeito datado, SAC-409, proposta da curadoria de 2026-11-21, reconferido em 2026-11-22):
# o Claude Code aceita só as 8 cores da paleta no campo color: e IGNORA em silêncio qualquer outro valor
# (o agente fica sem cor, sem erro). Medido nesta guarda contra a main de 2026-11-22: 38 dos 51 agentes não
# batiam a categoria — 7 fora da paleta (teal, black, indigo), 1 sem a chave e 30 com uma cor da paleta trocada —,
# e o molde do @agent-creator-specialist vazava o placeholder "[cor da categoria]". A REGRA 102 (Chave de frontmatter de agente pertence à allowlist
# (oficiais + as da casa)) confere a CHAVE, não o VALOR: o desvio passava calado.
#
# A SSOT é agent-colors.tsv (a paleta, com a fonte, e a cor de cada categoria). Aqui mora só o julgamento:
# cada .claude/agents/<categoria>/**/*.md (README fora) com frontmatter fechado tem de ter color: com o valor
# EXATO da categoria do diretório.
#
# Uso : bash agent-color-check.sh [<raiz>] [--tsv] [--derived]
#       bash agent-color-check.sh --selftest
#       --derived: o repo é adotante/porta (o agente e a categoria podem ser autoria do adotante) → SOFT.
# Saída (--tsv): SEV<TAB>CLASSE<TAB>caminho-relativo<TAB>mensagem · vazio = limpo
#       classes: COR-AUSENTE · COR-PLACEHOLDER · COR-FORA-DA-PALETA · COR-DIVERGE-DA-CATEGORIA
#                · CATEGORIA-SEM-COR (o diretório do agente não tem linha no .tsv)
# Leitura do frontmatter ESPELHA a da REGRA 102 (BOM tirado, abertura e fecho `---` com espaço/tab no fim);
# a comparação do valor ESPELHA o Claude Code 2.1.330 (`includes` exato: "Blue" não pinta).
# Exit: 0 = limpo (ou só SOFT) · 1 = violação HARD · 2 = não pôde julgar (NAO VERIFICADO; nunca é verde)
#
# TETO (o que esta guarda NÃO vê):
#   - só color: de TOPO, sem indentação; color: repetido vale o ÚLTIMO, como no YAML do Claude Code (nenhuma regra
#     acusa chave duplicada);
#   - FALSO POSITIVO raro, declarado (Elenxo da forja, medido contra o leitor do Claude Code em bun): valor em bloco
#     (`color: >-`), em várias linhas, alias de âncora (`*a`), tag (`!!str purple`), escape (`"pur\x70le"`) e
#     frontmatter todo indentado são cor válida para o Claude Code e acusados aqui; nenhum agente real os usa;
#   - `---` no meio do frontmatter corta a cor no Claude Code e passa aqui: é da REGRA 102 (Chave de frontmatter de
#     agente pertence à allowlist (oficiais + as da casa)), classe FECHO-AMBIGUO;
#   - agente sem frontmatter na linha 1, sem fecho ou sem name: não é julgado: o Claude Code o descarta (é da
#     REGRA 1 (Frontmatter de agente: name:, description:, tools: obrigatórios));
#   - a categoria vem do DIRETÓRIO, não do campo category: (a coerência dos dois é da REGRA 23 (Frontmatter:
#     category: em agentes (a metade 'model: em comandos' foi REVOGADA pela REGRA 71)));
#   - no lint com --only num agente, a guarda julga a árvore inteira (como a REGRA 102): pode repetir acusações;
#   - o --agents JSON e os agentes de plugin/usuário (~/.claude/agents) não entram;
#   - a paleta é a da doc e do binário no dia da leitura: cor nova do Claude Code é acusada até entrar no .tsv.
# =============================================================================
set -uo pipefail

_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT=""; MODE="human"; DERIVED=0
MAPFILE_TSV="${AGENT_COLORS_TSV:-${_HERE}/agent-colors.tsv}"
while [ $# -gt 0 ]; do
  case "$1" in
    --tsv) MODE="tsv"; shift ;;
    --derived) DERIVED=1; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -*) echo "ERRO: flag desconhecida '$1'" >&2; exit 2 ;;
    *) [ -z "${ROOT}" ] || { echo "ERRO: raiz duplicada '$1'" >&2; exit 2; }; ROOT="$1"; shift ;;
  esac
done

# --- o juiz: mapa + arquivos → linhas TSV (stdout); rc 2 se a SSOT não presta --------------------------
# $1 = mapa · $2 = severidade · $3 = raiz (caminho relativo e categoria) · demais = arquivos
_judge() {
  local map="$1" sev="$2" root="$3"; shift 3
  [ -f "${map}" ] || { echo "agent-color: mapa ausente (${map}) — NAO VERIFICADO" >&2; return 2; }
  [ "$#" -gt 0 ] || return 0
  LC_ALL=C awk -v sev="${sev}" -v root="${root}/" -v mapfile="${map}" '
    BEGIN {
      while ((getline line < mapfile) > 0) {
        sub(/\r$/, "", line)
        if (line ~ /^[[:space:]]*(#|$)/) continue
        n = split(line, c, "\t")
        if (c[1] == "palette" && n >= 3 && c[2] != "" && c[3] != "") {
          if (c[2] in pal) { printf "agent-color: cor duplicada na paleta: %s — NAO VERIFICADO\n", c[2] > "/dev/stderr"; bad = 1; exit 2 }
          pal[c[2]] = 1; npal++; plist = plist (plist == "" ? "" : " ") c[2]; continue
        }
        if (c[1] == "category" && n >= 4 && c[2] != "" && c[3] != "" && c[4] != "") {
          if (c[2] in cat) { printf "agent-color: categoria duplicada no mapa: %s — NAO VERIFICADO\n", c[2] > "/dev/stderr"; bad = 1; exit 2 }
          cat[c[2]] = c[3]; ncat++; continue
        }
        printf "agent-color: linha malformada no mapa: %s — NAO VERIFICADO\n", line > "/dev/stderr"; bad = 1; exit 2
      }
      close(mapfile)
      if (npal == 0 || ncat == 0) { print "agent-color: mapa sem paleta ou sem categoria — NAO VERIFICADO" > "/dev/stderr"; bad = 1; exit 2 }
      for (k in cat) if (!(cat[k] in pal)) {
        printf "agent-color: a categoria %s aponta a cor %s, fora da paleta do próprio mapa — NAO VERIFICADO\n", k, cat[k] > "/dev/stderr"; bad = 1; exit 2
      }
    }
    function emit(cls, m) { print sev "\t" cls "\t" rel "\t" m; if (sev == "HARD") hard = 1 }
    # julga no FECHO: arquivo que não fecha não tem frontmatter para o Claude Code (é da REGRA 1)
    function verdict(   want) {
      if (!named) return   # o Claude Code descarta agente sem name: (o loader devolve null): nada a pintar
      if (!(category in cat)) {
        emit("CATEGORIA-SEM-COR", "o agente está em \"" category "\", categoria sem cor em .claude/validation/agent-colors.tsv — acrescente a linha category da categoria (a cor sai da paleta: " plist ")")
        return
      }
      want = cat[category]
      if (!seen) { emit("COR-AUSENTE", "agente sem color: no frontmatter — a categoria " category " pede \"color: " want "\" (agent-colors.tsv)"); return }
      if (val ~ /[][{}<>]/ || val == "") {
        emit("COR-PLACEHOLDER", "color: \"" val "\" é placeholder ou vazio, não cor — o Claude Code o ignora e o agente fica sem cor; a categoria " category " pede \"color: " want "\"")
        return
      }
      if (!(val in pal)) {
        emit("COR-FORA-DA-PALETA", "color: \"" val "\" fora da paleta do Claude Code (" plist ") — ele IGNORA o valor em silêncio e o agente fica sem cor; a categoria " category " pede \"color: " want "\"")
        return
      }
      if (val != want) emit("COR-DIVERGE-DA-CATEGORIA", "color: \"" val "\" diverge da cor da categoria " category " — use \"color: " want "\" (agent-colors.tsv: a cor sai da categoria, não do agente)")
    }
    FNR == 1 {
      infm = 0; done = 0; seen = 0; val = ""; named = 0
      rel = FILENAME; if (index(rel, root) == 1) rel = substr(rel, length(root) + 1)
      category = rel; sub(/^\.claude\/agents\//, "", category)
      if (index(category, "/") > 0) category = substr(category, 1, index(category, "/") - 1); else category = ""
    }
    done { next }
    { sub(/\r$/, "") }
    FNR == 1 { sub(/^\357\273\277/, ""); if ($0 ~ /^---[ \t]*$/) infm = 1; else done = 1; next }
    infm && $0 ~ /^---[ \t]*$/ { done = 1; verdict(); next }
    infm && /^("name"|\047name\047|name)[ \t]*:[ \t]*[^ \t]/ { named = 1 }
    infm && /^("color"|\047color\047|color)[ \t]*:/ {
      seen = 1; v = $0; sub(/^[^:]*:[ \t]*/, "", v)
      if (v ~ /^"/) { v = substr(v, 2); p = index(v, "\""); if (p > 0) v = substr(v, 1, p - 1) }
      else if (v ~ /^\047/) { v = substr(v, 2); p = index(v, "\047"); if (p > 0) v = substr(v, 1, p - 1) }
      else { sub(/[ \t]+#.*$/, "", v); sub(/[ \t]+$/, "", v) }
      val = v
    }
    END { if (bad) exit 2; if (hard) exit 1 }
  ' "$@"
}

if [ "${MODE}" = "selftest" ]; then
  T="$(mktemp -d 2>/dev/null)" || { echo "agent-color selftest: mktemp falhou — NAO VERIFICADO" >&2; exit 2; }
  trap 'rm -rf "${T}"' EXIT
  ok=0; bad=0
  mkdir -p "${T}/.claude/agents/meta" "${T}/.claude/agents/development" "${T}/.claude/agents/novacat"
  mk() { printf '%b' "$2" > "${T}/.claude/agents/$1.md"; }
  # $1 nome · $2 mapa · $3 arquivo · $4 regex esperada ('' = silêncio) · $5 rc esperado
  check() {
    local name="$1" mp="$2" f="$3" want="$4" wrc="$5" out rc
    if out="$(_judge "${mp}" HARD "${T}" "${f}" 2>&1)"; then rc=0; else rc=$?; fi
    local good=1
    [ "${rc}" = "${wrc}" ] || good=0
    if [ -n "${want}" ]; then grep -qE -- "${want}" <<< "${out}" || good=0
    elif [ "${wrc}" = 0 ]; then [ -z "${out}" ] || good=0; fi
    if [ "${good}" = 1 ]; then ok=$((ok + 1)); echo "  ✅ ${name}"
    else bad=$((bad + 1)); echo "  ✗ ${name} — rc=${rc} (esperava ${wrc}); saída: $(head -2 <<< "${out}" | tr '\n' '|')"; fi
  }
  M="${MAPFILE_TSV}"; A="${T}/.claude/agents"
  # ── acusa (as formas do defeito, verbatim de como apareceram nos 51 agentes e no molde) ────────────
  mk meta/noc     '---\nname: x\ndescription: y\nmodel: sonnet\ncategory: meta\n---\ncorpo\n'
  check "acusa: agente sem color: (o caso do runflow-specialist)" "${M}" "${A}/meta/noc.md" 'COR-AUSENTE	\.claude/agents/meta/noc\.md	.*"color: purple"' 1
  mk meta/ph      '---\nname: x\ndescription: y\ncolor: [cor da categoria]\ncategory: meta\n---\n'
  check "acusa: o placeholder [cor da categoria] do molde" "${M}" "${A}/meta/ph.md" 'COR-PLACEHOLDER	.*"\[cor da categoria\]"' 1
  mk meta/ph2     '---\nname: x\ndescription: y\ncolor: {{color}}\ncategory: meta\n---\n'
  check "acusa: placeholder de template {{color}}" "${M}" "${A}/meta/ph2.md" 'COR-PLACEHOLDER' 1
  mk meta/empty   '---\nname: x\ndescription: y\ncolor:\ncategory: meta\n---\n'
  check "acusa: color: vazio" "${M}" "${A}/meta/empty.md" 'COR-PLACEHOLDER	.*"" é placeholder ou vazio' 1
  mk meta/black   '---\nname: x\ndescription: y\ncolor: black\ncategory: meta\n---\n'
  check "acusa: black, fora da paleta (o caso do @onion)" "${M}" "${A}/meta/black.md" 'COR-FORA-DA-PALETA	.*"black"' 1
  mk development/teal '---\nname: x\ndescription: y\ncolor: teal   # cor antiga\n---\n'
  check "acusa: teal com comentário no fim, fora da paleta" "${M}" "${A}/development/teal.md" 'COR-FORA-DA-PALETA	.*"teal"' 1
  mk meta/caps    '---\nname: x\ndescription: y\ncolor: Purple\n---\n'
  check "acusa: Purple em maiúscula (o Claude Code compara exato)" "${M}" "${A}/meta/caps.md" 'COR-FORA-DA-PALETA	.*"Purple"' 1
  mk meta/div     '---\nname: x\ndescription: y\ncolor: cyan\ncategory: meta\n---\n'
  check "acusa: cor da paleta trocada com a da categoria (cyan em meta)" "${M}" "${A}/meta/div.md" 'COR-DIVERGE-DA-CATEGORIA	.*categoria meta.*"color: purple"' 1
  mk meta/last    '---\nname: x\ndescription: y\ncolor: purple\ncolor: red\n---\n'
  check "acusa: color: repetido vale o último" "${M}" "${A}/meta/last.md" 'COR-DIVERGE-DA-CATEGORIA	.*"red"' 1
  mk novacat/a    '---\nname: x\ndescription: y\ncolor: blue\n---\n'
  check "acusa: categoria sem linha no mapa" "${M}" "${A}/novacat/a.md" 'CATEGORIA-SEM-COR	.*"novacat"' 1
  mk rootagent    '---\nname: x\ndescription: y\ncolor: blue\n---\n'
  check "acusa: agente na raiz de agents/, sem categoria" "${M}" "${A}/rootagent.md" 'CATEGORIA-SEM-COR	.*em ""' 1
  mk meta/crlf    '---\r\nname: x\r\ndescription: y\r\ncolor: teal\r\n---\r\n'
  check "acusa: teal num arquivo CRLF" "${M}" "${A}/meta/crlf.md" 'COR-FORA-DA-PALETA	.*"teal"' 1
  mk meta/bom     '\xef\xbb\xbf---\nname: x\ncolor: teal\n---\n'
  check "acusa: BOM na linha 1 não esconde o color:" "${M}" "${A}/meta/bom.md" 'COR-FORA-DA-PALETA' 1
  # ── cala (o caso honesto) ─────────────────────────────────────────────────────────────────────────
  mk meta/honest  '---\nname: x\ndescription: |\n  color: red dentro do bloco não é chave\ntools: Read\nmodel: sonnet\ncolor: purple                    # cor da categoria\ncategory: meta\n---\ncolor: red no corpo não é frontmatter\n'
  check "cala: agente honesto (cor da categoria, comentário, color: no bloco | e no corpo)" "${M}" "${A}/meta/honest.md" '' 0
  mk development/dq '---\nname: x\ndescription: y\ncolor: "blue"\n---\n'
  check "cala: valor entre aspas duplas" "${M}" "${A}/development/dq.md" '' 0
  mk development/sq "---\nname: x\ndescription: y\ncolor: 'blue'\n---\n"
  check "cala: valor entre aspas simples" "${M}" "${A}/development/sq.md" '' 0
  mk meta/qkey    '---\nname: x\n"color": purple\n---\n'
  check "cala: chave color entre aspas é a chave color" "${M}" "${A}/meta/qkey.md" '' 0
  mk meta/tabclose '---\nname: x\ncolor: purple\n---\t\ncolor: teal no corpo\n\n---\n'
  check "cala: fecho '---' com tab no fim fecha o frontmatter" "${M}" "${A}/meta/tabclose.md" '' 0
  mk meta/unclosed '---\nname: x\ncolor: teal\n'
  check "cala: frontmatter sem fecho não é julgado (é da REGRA 1)" "${M}" "${A}/meta/unclosed.md" '' 0
  mk meta/nofm    'sem frontmatter\nname: x\ncolor: teal\n---\n'
  check "cala: arquivo sem frontmatter na linha 1 (é da REGRA 1)" "${M}" "${A}/meta/nofm.md" '' 0
  mk meta/noname  '---\ndescription: fragmento, não agente\ncolor: teal\n---\n'
  check "cala: frontmatter sem name: (o Claude Code descarta o arquivo)" "${M}" "${A}/meta/noname.md" '' 0
  mk meta/emptyname '---\nname:\ncolor: teal\n---\n'
  check "cala: name: vazio também é descartado" "${M}" "${A}/meta/emptyname.md" '' 0
  # ── fail-closed (não pude julgar ≠ verde) ─────────────────────────────────────────────────────────
  check "rc 2: mapa ausente" "${T}/nao-existe.tsv" "${A}/meta/honest.md" 'NAO VERIFICADO' 2
  printf '# so comentario\n\n' > "${T}/vazio.tsv"
  check "rc 2: mapa só com comentários" "${T}/vazio.tsv" "${A}/meta/honest.md" 'sem paleta ou sem categoria' 2
  printf 'palette\tpurple\tdoc\n' > "${T}/semcat.tsv"
  check "rc 2: mapa com paleta e sem categoria" "${T}/semcat.tsv" "${A}/meta/honest.md" 'sem paleta ou sem categoria' 2
  printf 'palette\tpurple\tdoc\ncategory\tmeta\tpurple\n' > "${T}/mal.tsv"
  check "rc 2: linha de categoria sem a razão é malformada" "${T}/mal.tsv" "${A}/meta/honest.md" 'malformada' 2
  printf 'palette\tpurple\tdoc\ncategory\tmeta\tpurple\tr\ncategory\tmeta\tred\tr\n' > "${T}/dup.tsv"
  check "rc 2: categoria duplicada no mapa" "${T}/dup.tsv" "${A}/meta/honest.md" 'duplicada' 2
  printf 'palette\tpurple\tdoc\npalette\tpurple\tdoc\ncategory\tmeta\tpurple\tr\n' > "${T}/duppal.tsv"
  check "rc 2: cor duplicada na paleta" "${T}/duppal.tsv" "${A}/meta/honest.md" 'cor duplicada' 2
  printf 'palette\tpurple\tdoc\ncategory\tmeta\tteal\tr\n' > "${T}/foracat.tsv"
  check "rc 2: categoria aponta cor fora da paleta do mapa" "${T}/foracat.tsv" "${A}/meta/honest.md" 'fora da paleta do próprio mapa' 2
  printf 'paleta\tpurple\tdoc\ncategory\tmeta\tpurple\tr\n' > "${T}/tipo.tsv"
  check "rc 2: tipo de linha fora do vocabulário" "${T}/tipo.tsv" "${A}/meta/honest.md" 'malformada' 2
  # ── severidade no derivado ────────────────────────────────────────────────────────────────────────
  if out="$(_judge "${M}" SOFT "${T}" "${A}/meta/black.md" 2>&1)" && grep -q '^SOFT	COR-FORA-DA-PALETA' <<< "${out}"; then
    ok=$((ok + 1)); echo "  ✅ derivado: a mesma acusação sai SOFT e rc 0"
  else bad=$((bad + 1)); echo "  ✗ derivado: esperava SOFT e rc 0; saída: ${out}"; fi
  echo "agent-color selftest: ${ok} passaram, ${bad} falharam"
  [ "${bad}" -eq 0 ]; exit $?
fi

[ -n "${ROOT}" ] || ROOT="$(pwd)"
ROOT="$(cd "${ROOT}" 2>/dev/null && pwd)" || { echo "agent-color: raiz inválida — NAO VERIFICADO" >&2; exit 2; }
AGDIR="${ROOT}/.claude/agents"
[ -d "${AGDIR}" ] || exit 0   # repo sem agentes: nada a julgar (não é defeito)
# diretório ilegível no meio da árvore: o find avisa e segue, e "0 agentes" sairia verde (Elenxo, achado 3)
find "${AGDIR}" -name '*.md' -print > /dev/null 2>&1 || { echo "agent-color: não consegui ler toda a árvore de ${AGDIR} — NAO VERIFICADO" >&2; exit 2; }
mapfile -d '' FILES < <(find "${AGDIR}" -name '*.md' ! -iname 'readme.md' -print0 2>/dev/null | sort -z)
SEV="HARD"; [ "${DERIVED}" = 1 ] && SEV="SOFT"
OUT=""; rc=0
OUT="$(_judge "${MAPFILE_TSV}" "${SEV}" "${ROOT}" "${FILES[@]}")" || rc=$?
[ "${rc}" -ge 2 ] && exit 2
# rc 1 sem nenhuma linha HARD é morte calada do juiz, não acusação: fail-closed
if [ "${rc}" -eq 1 ] && ! grep -q '^HARD	' <<< "${OUT}"; then
  echo "agent-color: o juiz saiu 1 sem acusar — NAO VERIFICADO" >&2; exit 2
fi
if [ "${MODE}" = "tsv" ]; then
  [ -n "${OUT}" ] && printf '%s\n' "${OUT}"
else
  [ -n "${OUT}" ] && printf '%s\n' "${OUT}" | awk -F'\t' '{ printf "%s: [agent-color/%s] %s — %s\n", $1, $2, $3, $4 }'
  echo "agent-color: ${#FILES[@]} agente(s), $(grep -c . <<< "${OUT}" || true) acusação(ões), severidade ${SEV}"
fi
grep -q '^HARD	' <<< "${OUT}" && exit 1
exit 0
