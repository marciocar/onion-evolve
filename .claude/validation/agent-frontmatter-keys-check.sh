#!/usr/bin/env bash
# =============================================================================
# agent-frontmatter-keys-check.sh — chave de frontmatter de AGENTE fora da allowlist (REGRA 102)
#
# POR QUE EXISTE (defeito datado, SAC-106, radar E3 r9 de 2026-10-11): o Claude Code IGNORA a chave
# de frontmatter que não reconhece. Um typo como `tool: Read` no lugar de `tools: Read` não dá erro:
# a chave some e o agente herda TODAS as ferramentas da sessão. Nenhuma das cinco regras de
# frontmatter do lint (1, 3, 12, 17, 23) cobrava chave desconhecida, e o `--debug` da 2.1.296, que
# passou a nomear os campos não reconhecidos, não serve de medidor enquanto as 11 chaves da casa
# (344 ocorrências nos 51 agentes) aparecem como ruído ao lado do typo real.
#
# A SSOT da lista é agent-frontmatter-keys.tsv (oficiais da doc + as da casa, cada uma com quem a
# lê). Aqui mora só o julgamento: cada chave de TOPO do frontmatter de .claude/agents/**/*.md
# (README fora) que não está na lista é acusada, com a chave aceita mais parecida como dica.
#
# Uso : bash agent-frontmatter-keys-check.sh [<raiz>] [--tsv] [--derived]
#       bash agent-frontmatter-keys-check.sh --selftest
#       --derived: o repo é adotante/porta (o agente pode ser autoria do adotante) → SOFT, nunca HARD.
# Saída (--tsv): SEV<TAB>CLASSE<TAB>caminho-relativo<TAB>mensagem · vazio = limpo
#       classes: CHAVE-DESCONHECIDA · FECHO-AMBIGUO (`---` no meio do frontmatter: o Claude Code corta ali)
#                · MERGE-KEY (sempre SOFT)
# Leitura do frontmatter ESPELHA a do Claude Code 2.1.296 (conferida no binário pelo Elenxo da forja): BOM
#       tirado, abertura e fecho `---` com espaço/tab no fim, fecho NÃO ancorado; arquivo sem fecho não é julgado.
# Exit: 0 = limpo (ou só SOFT) · 1 = violação HARD · 2 = não pôde julgar (NAO VERIFICADO; nunca é verde)
#
# TETO (o que esta guarda NÃO vê):
#   - só a chave de TOPO; chave aninhada (dentro de hooks:, mcpServers:, experimental:) não é julgada;
#   - não julga VALOR (o valor de model: é da REGRA 3, o de tools: da REGRA 12);
#   - agente sem frontmatter na linha 1, ou sem fecho, não é julgado (é da REGRA 1);
#   - mapping de topo todo INDENTADO (`  tool: Read`) é lido pelo Claude Code e pulado aqui (falso negativo);
#   - merge key (<<) sai SOFT e as chaves mescladas não são julgadas;
#   - chave citada entre aspas ("tools":) é lida sem as aspas; YAML inválido é da REGRA 17;
#   - comandos e skills NÃO entram: os campos deles são outros e não há medição deles nesta forja;
#   - a lista oficial é a da doc no dia da leitura: chave oficial nova é acusada até entrar no .tsv.
# =============================================================================
set -uo pipefail

_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT=""; MODE="human"; DERIVED=0
ALLOWLIST="${AGENT_FM_KEYS_ALLOWLIST:-${_HERE}/agent-frontmatter-keys.tsv}"
while [ $# -gt 0 ]; do
  case "$1" in
    --tsv) MODE="tsv"; shift ;;
    --derived) DERIVED=1; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -*) echo "ERRO: flag desconhecida '$1'" >&2; exit 2 ;;
    *) [ -z "${ROOT}" ] || { echo "ERRO: raiz duplicada '$1'" >&2; exit 2; }; ROOT="$1"; shift ;;
  esac
done

# --- o juiz: allowlist + arquivos → linhas TSV (stdout); rc 2 se a SSOT não presta ----------------
# $1 = allowlist · $2 = severidade · $3 = raiz (para o caminho relativo) · demais = arquivos
_judge() {
  local allow="$1" sev="$2" root="$3"; shift 3
  [ -f "${allow}" ] || { echo "agent-frontmatter-keys: allowlist ausente (${allow}) — NAO VERIFICADO" >&2; return 2; }
  [ "$#" -gt 0 ] || return 0
  LC_ALL=C awk -v sev="${sev}" -v root="${root}/" -v allowfile="${allow}" '
    function lev(a, b,   la, lb, i, j, c, d, prev, cur, x) {
      la = length(a); lb = length(b)
      for (j = 0; j <= lb; j++) prev[j] = j
      for (i = 1; i <= la; i++) {
        cur[0] = i
        for (j = 1; j <= lb; j++) {
          c = (substr(a, i, 1) == substr(b, j, 1)) ? 0 : 1
          d = prev[j] + 1; x = cur[j-1] + 1; if (x < d) d = x
          x = prev[j-1] + c; if (x < d) d = x
          cur[j] = d
        }
        for (j = 0; j <= lb; j++) prev[j] = cur[j]
      }
      return prev[lb]
    }
    function hint(k,   best, bd, a, d, lk, la) {
      best = ""; bd = 99; lk = tolower(k); gsub(/[-_]/, "", lk)
      for (a in ok) {
        la = tolower(a); gsub(/[-_]/, "", la)
        d = (la == lk) ? 0 : lev(k, a)
        if (d < bd) { bd = d; best = a }
      }
      return (bd <= 2) ? best : ""
    }
    BEGIN {
      while ((getline line < allowfile) > 0) {
        sub(/\r$/, "", line)
        if (line ~ /^[[:space:]]*(#|$)/) continue
        n = split(line, c, "\t")
        if (n < 3 || c[1] == "" || (c[2] != "oficial" && c[2] != "runtime" && c[2] != "casa") || c[3] == "") {
          printf "agent-frontmatter-keys: linha malformada na allowlist: %s — NAO VERIFICADO\n", line > "/dev/stderr"; bad = 1; exit 2
        }
        if (c[1] in ok) { printf "agent-frontmatter-keys: chave duplicada na allowlist: %s — NAO VERIFICADO\n", c[1] > "/dev/stderr"; bad = 1; exit 2 }
        ok[c[1]] = c[2]; nok++
      }
      close(allowfile)
      if (nok == 0) { print "agent-frontmatter-keys: allowlist vazia — NAO VERIFICADO" > "/dev/stderr"; bad = 1; exit 2 }
    }
    # As acusações de um arquivo ficam PENDENTES até o fecho do frontmatter: arquivo que não fecha não tem
    # frontmatter para o Claude Code (é da REGRA 1), e julgá-lo seria somar ruído (Elenxo, achado 4).
    function flush(   i) { for (i = 1; i <= np; i++) { print pend[i]; if (pendsev[i] == "HARD") hard = 1 }; np = 0 }
    function acc(s, cls, m) { np++; pend[np] = s "\t" cls "\t" rel "\t" m; pendsev[np] = s }
    FNR == 1 { np = 0; infm = 0; done = 0; rel = FILENAME; if (index(rel, root) == 1) rel = substr(rel, length(root) + 1) }
    done { next }
    { sub(/\r$/, "") }
    # abertura e fecho como o Claude Code os lê (2.1.296: BOM tirado; `---` com espaço/tab no fim) — Elenxo 1 e FN-A
    FNR == 1 { sub(/^\357\273\277/, ""); if ($0 ~ /^---[ \t]*$/) infm = 1; else done = 1; next }
    infm && $0 ~ /^---[ \t]*$/ { done = 1; flush(); next }
    infm {
      # o fecho do Claude Code não é ancorado: um `---` em QUALQUER ponto corta o frontmatter ali, e o que
      # vem depois (tools: inclusive) some calado (Elenxo, FN-C)
      if (index($0, "---") > 0) {
        acc(sev, "FECHO-AMBIGUO", "linha do frontmatter contém \"---\" fora do fecho — o Claude Code corta o frontmatter AQUI, e as chaves seguintes (tools: inclusive) somem sem erro. Troque o \"---\" (ex.: por \"—\") ou mova o texto para o corpo")
      }
      if ($0 ~ /^[[:space:]]/ || $0 ~ /^(#|-|$)/) next
      p = index($0, ":"); if (p == 0) next
      k = substr($0, 1, p - 1); sub(/[[:space:]]+$/, "", k)
      if (k ~ /^".*"$/ || k ~ /^\047.*\047$/) k = substr(k, 2, length(k) - 2)
      if (k in ok) next
      if (k == "<<") {   # merge key é YAML válido: avisa, não barra (a guarda erra para o lado de calar)
        acc("SOFT", "MERGE-KEY", "merge key (<<) no frontmatter — as chaves mescladas NÃO são julgadas por esta guarda; prefira escrever as chaves direto")
        next
      }
      h = hint(k)
      msg = "chave de frontmatter de agente \"" k "\" fora da allowlist — o Claude Code IGNORA chave que não reconhece (um typo em tools: deixa o agente com TODAS as ferramentas)"
      if (h != "") msg = msg "; você quis dizer \"" h "\"?"; else msg = msg "."
      msg = msg " Se a chave é legítima, registre-a com origem e leitor em .claude/validation/agent-frontmatter-keys.tsv"
      acc(sev, "CHAVE-DESCONHECIDA", msg)
    }
    END { if (bad) exit 2; if (hard) exit 1 }
  ' "$@"
}

if [ "${MODE}" = "selftest" ]; then
  T="$(mktemp -d 2>/dev/null)" || { echo "agent-frontmatter-keys selftest: mktemp falhou — NAO VERIFICADO" >&2; exit 2; }
  trap 'rm -rf "${T}"' EXIT
  ok=0; bad=0
  mk() { printf '%b' "$2" > "${T}/$1.md"; }
  # $1 nome · $2 allowlist · $3 arquivo · $4 regex esperada na saída ('' = silêncio) · $5 rc esperado
  check() {
    local name="$1" al="$2" f="$3" want="$4" wrc="$5" out rc
    if out="$(_judge "${al}" HARD "${T}" "${f}" 2>&1)"; then rc=0; else rc=$?; fi
    local good=1
    [ "${rc}" = "${wrc}" ] || good=0
    if [ -n "${want}" ]; then grep -qE -- "${want}" <<< "${out}" || good=0
    elif [ "${wrc}" = 0 ]; then [ -z "${out}" ] || good=0; fi
    if [ "${good}" = 1 ]; then ok=$((ok + 1)); echo "  ✅ ${name}"
    else bad=$((bad + 1)); echo "  ✗ ${name} — rc=${rc} (esperava ${wrc}); saída: $(head -2 <<< "${out}" | tr '\n' '|')"; fi
  }
  AL="${ALLOWLIST}"
  # ── acusa (as formas da classe, verbatim do brief do SAC-106) ─────────────────────────────────────
  mk tool   '---\nname: x\ndescription: y\ntool: Read, Grep\nmodel: sonnet\ncategory: meta\n---\ncorpo\n'
  check "acusa: tool: no lugar de tools: (o agente herdaria todas as ferramentas)" "${AL}" "${T}/tool.md" 'CHAVE-DESCONHECIDA	tool.md	.*"tool".*"tools"' 1
  mk modle  '---\nname: x\ndescription: y\nmodle: sonnet\ncategory: meta\n---\n'
  check "acusa: modle: com a dica model" "${AL}" "${T}/modle.md" '"modle".*quis dizer "model"' 1
  mk dash   '---\nname: x\ndescription: y\ndisallowed-tools: Bash\ncategory: meta\n---\n'
  check "acusa: disallowed-tools (forma de skill) com a dica disallowedTools" "${AL}" "${T}/dash.md" '"disallowed-tools".*"disallowedTools"' 1
  mk caps   '---\nName: x\ndescription: y\ncategory: meta\n---\n'
  check "acusa: Name: em maiúscula não é a chave name" "${AL}" "${T}/caps.md" '"Name".*"name"' 1
  mk crlf   '---\r\nname: x\r\ndescription: y\r\ncolour: blue\r\ncategory: meta\r\n---\r\n'
  check "acusa: colour: num arquivo CRLF" "${AL}" "${T}/crlf.md" '"colour".*"color"' 1
  mk spc    '---\nname: x\ndescription: y\ntools : Read\ncategory: meta\n---\n'
  check "cala: 'tools :' com espaço antes dos dois-pontos é a chave tools" "${AL}" "${T}/spc.md" '' 0
  mk quoted '---\nname: x\n"tooles": Read\ncategory: meta\n---\n'
  check "acusa: chave entre aspas fora da lista" "${AL}" "${T}/quoted.md" '"tooles".*"tools"' 1
  mk novel  '---\nname: x\ndescription: y\nowner: alguem\ncategory: meta\n---\n'
  check "acusa: chave sem parente próximo, sem dica inventada" "${AL}" "${T}/novel.md" '"owner" fora da allowlist — [^?]*registre' 1
  # ── cala (o caso honesto: o agente real do core) ──────────────────────────────────────────────────
  mk honest '---\nname: x\ndescription: |\n  linha com dois-pontos: dentro do bloco\n  tool: isto e texto, nao chave\ntools: Read\nmodel: sonnet\ncolor: blue\ncategory: meta\nexpertise:\n  - a\nrelated_agents: []\nrelated_commands: []\npriority: alta\nversion: "1.0"\nupdated: "2026-10-11"\nrequired_env:\n  - name: X\n# comentario: com dois-pontos\n---\ntool: no corpo nao e frontmatter\n'
  check "cala: agente honesto com as chaves da casa, bloco | e comentário" "${AL}" "${T}/honest.md" '' 0
  mk official '---\nname: x\ndescription: y\ndisallowedTools: Bash\npermissionMode: plan\nmaxTurns: 5\nskills: []\nmcpServers: {}\nhooks: {}\nmemory: project\nbackground: true\nomitClaudeMd: true\neffort: high\nisolation: worktree\ninitialPrompt: oi\nexperimental:\n  cacheTtl: 1h\nautoCompactWindow: 100000\nobserver: true\nobserverMessage: x\nobserveSubagents: true\ncategory: meta\n---\n'
  check "cala: as 19 chaves oficiais e as 3 de runtime (observer*, Elenxo 2)" "${AL}" "${T}/official.md" '' 0
  # ── a leitura do frontmatter espelha a do Claude Code (Elenxo da forja, binário 2.1.296) ─────────────
  mk tabclose '---\nname: x\ndescription: y\n---\t\nNota: corpo\n\n---\n'
  check "cala: fecho '---' com tab no fim fecha o frontmatter (Elenxo 1)" "${AL}" "${T}/tabclose.md" '' 0
  mk bom '\xef\xbb\xbf---\nname: x\ntool: Read\n---\n'
  check "acusa: BOM na linha 1 não esconde o tool: (Elenxo FN-A)" "${AL}" "${T}/bom.md" '"tool".*"tools"' 1
  mk spcopen '--- \nname: x\ntool: Read\n---\n'
  check "acusa: abertura '--- ' com espaço não esconde o tool: (Elenxo FN-A)" "${AL}" "${T}/spcopen.md" '"tool".*"tools"' 1
  mk ambig '---\nname: x\ndescription: use --- para separar\ntools: Read\n---\n'
  check "acusa: '---' no meio do frontmatter corta o tools: (Elenxo FN-C)" "${AL}" "${T}/ambig.md" 'FECHO-AMBIGUO	ambig.md' 1
  mk unclosed '---\nname: x\nNota: algo\n'
  check "cala: frontmatter sem fecho não é julgado (é da REGRA 1, Elenxo 4)" "${AL}" "${T}/unclosed.md" '' 0
  mk merge '---\nname: x\n<<: {color: blue}\n---\n'
  check "avisa: merge key sai SOFT, não barra (Elenxo 3)" "${AL}" "${T}/merge.md" '^SOFT	MERGE-KEY	merge.md' 0
  mk nofm   'sem frontmatter\ntool: x\n---\n'
  check "cala: arquivo sem frontmatter na linha 1 (é da REGRA 1)" "${AL}" "${T}/nofm.md" '' 0
  mk late   '\n---\ntool: x\n---\n'
  check "cala: '---' que não está na linha 1 não abre frontmatter" "${AL}" "${T}/late.md" '' 0
  # ── fail-closed (não pude julgar ≠ verde) ─────────────────────────────────────────────────────────
  # (ausente: o `[ -f ]` do _judge e o `nok == 0` do awk cobrem o mesmo caso — defesa redundante, por isso
  #  o mutante de uma só delas não morde; o caso "só com comentários" exercita o `nok == 0` sozinho)
  check "rc 2: allowlist ausente" "${T}/nao-existe.tsv" "${T}/honest.md" 'NAO VERIFICADO' 2
  printf '# so comentario\n\n' > "${T}/vazia.tsv"
  check "rc 2: allowlist só com comentários" "${T}/vazia.tsv" "${T}/honest.md" 'vazia' 2
  printf 'name\toficial\n' > "${T}/mal.tsv"
  check "rc 2: allowlist malformada (sem a coluna de leitor)" "${T}/mal.tsv" "${T}/honest.md" 'malformada' 2
  printf 'name\toficial\tx\nname\tcasa\ty\n' > "${T}/dup.tsv"
  check "rc 2: chave duplicada na allowlist" "${T}/dup.tsv" "${T}/honest.md" 'duplicada' 2
  printf 'name\tterceiro\tx\n' > "${T}/orig.tsv"
  check "rc 2: origem fora do vocabulário" "${T}/orig.tsv" "${T}/honest.md" 'malformada' 2
  # ── severidade no derivado ────────────────────────────────────────────────────────────────────────
  if out="$(_judge "${AL}" SOFT "${T}" "${T}/tool.md" 2>&1)" && grep -q '^SOFT	CHAVE-DESCONHECIDA' <<< "${out}"; then
    ok=$((ok + 1)); echo "  ✅ derivado: a mesma acusação sai SOFT e rc 0"
  else bad=$((bad + 1)); echo "  ✗ derivado: esperava SOFT e rc 0; saída: ${out}"; fi
  echo "agent-frontmatter-keys selftest: ${ok} passaram, ${bad} falharam"
  [ "${bad}" -eq 0 ]; exit $?
fi

[ -n "${ROOT}" ] || ROOT="$(pwd)"
ROOT="$(cd "${ROOT}" 2>/dev/null && pwd)" || { echo "agent-frontmatter-keys: raiz inválida — NAO VERIFICADO" >&2; exit 2; }
AGDIR="${ROOT}/.claude/agents"
[ -d "${AGDIR}" ] || exit 0   # repo sem agentes: nada a julgar (não é defeito)
mapfile -d '' FILES < <(find "${AGDIR}" -name '*.md' ! -iname 'readme.md' -print0 2>/dev/null | sort -z)
SEV="HARD"; [ "${DERIVED}" = 1 ] && SEV="SOFT"
OUT=""; rc=0
OUT="$(_judge "${ALLOWLIST}" "${SEV}" "${ROOT}" "${FILES[@]}")" || rc=$?
[ "${rc}" -ge 2 ] && exit 2
# rc 1 sem nenhuma linha HARD é morte calada do juiz, não acusação: fail-closed
if [ "${rc}" -eq 1 ] && ! grep -q '^HARD	' <<< "${OUT}"; then
  echo "agent-frontmatter-keys: o juiz saiu 1 sem acusar — NAO VERIFICADO" >&2; exit 2
fi
if [ "${MODE}" = "tsv" ]; then
  [ -n "${OUT}" ] && printf '%s\n' "${OUT}"
else
  [ -n "${OUT}" ] && printf '%s\n' "${OUT}" | awk -F'\t' '{ printf "%s: [agent-frontmatter/%s] %s — %s\n", $1, $2, $3, $4 }'
  echo "agent-frontmatter-keys: ${#FILES[@]} agente(s), $(grep -c . <<< "${OUT}" || true) acusação(ões), severidade ${SEV}"
fi
grep -q '^HARD	' <<< "${OUT}" && exit 1
exit 0
