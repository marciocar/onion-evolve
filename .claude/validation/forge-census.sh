#!/usr/bin/env bash
# ===========================================================================
# forge-census.sh — censo das 7 PEÇAS de um comando-com-framework.
#
# É o MEDIDOR da peça 3 (contexto medido injetado) do `/meta:forge`: a saída daqui é o que a
# sessão lê ANTES de raciocinar sobre o que falta. Sem ele, a forja perguntaria ao modelo o que
# um `ls` responde — e responderia errado, como eu respondi três vezes em 2026-09-28.
#
# ── DESCOBERTA POR REFERÊNCIA, NUNCA POR NOME CONSTRUÍDO ────────────────────────────────
# Este é o ponto de desenho, e ele nasceu de defeito medido. Ao levantar este mesmo censo à
# mão, eu errei três vezes seguidas, sempre do mesmo jeito: CONSTRUÍ o caminho do artefato a
# partir do nome do candidato.
#   1. `.claude/skills/onion-${nome}/SKILL.md` com `nome=onion-research` → procurou
#      `skills/onion-onion-research/` e devolveu 1/7 para a instância de REFERÊNCIA;
#   2. `grep -iE "${nome}"` em `common/prompts/` → o arquivo é `research-doctrine.md`, o
#      candidato é `onion-research`: o RADICAL não é o nome cheio, e deu 5/7;
#   3. `grep 'kg-radar'` para achar a peça 5 no `census.md` → o doc diz "radar exit 0 em todo
#      grafo tocado", sem a palavra `kg-radar`, e a peça existente saiu como ausente.
# Os três são a mesma classe: eu inventei a relação em vez de lê-la. A cura é estrutural —
# **o artefato NOMEIA as suas próprias partes**, e o censo LÊ essa citação. Um comando-com-
# framework que não cita a doutrina que usa não tem a peça 2, e isso é verdade útil, não falso
# negativo: peça que o artefato não referencia é peça que a sessão não vai achar tampouco.
#
# ── Fronteira DECLARADA ──────────────────────────────────────────────────────────────────
# O censo mede PRESENÇA e REFERÊNCIA, não QUALIDADE. Ele não diz se a doutrina é boa, se o
# workflow funciona, nem se a bancada testa o que importa — só que existem e estão ligados.
# `bom` é julgamento; `presente e citado` é medição, e é esta que a forja precisa.
#
# Uso:  bash .claude/validation/forge-census.sh [<repo>] [--markdown|--tsv]
# Exit: 0 = censo emitido · 3 = NÃO PUDE MEDIR (declara, nunca devolve censo vazio).
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_forge_selftests).
# ===========================================================================
set -uo pipefail

REPO="${1:-}"; FMT="${2:---markdown}"
case "${REPO}" in --*) FMT="${REPO}"; REPO="" ;; esac
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "forge-census: alvo inexistente: ${REPO}" >&2; exit 3; }

# FAIL-CLOSED no índice: o censo é do conjunto RASTREADO (o que viaja e o que o CI vê).
# Sem índice, "nenhum candidato tem nada" seria falso e caríssimo — zero NÃO é resultado.
git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "forge-census: sem índice git em ${REPO} — o censo seria de outro conjunto que o do CI. Recusa." >&2; exit 3; }

_tracked() { git -C "${REPO}" ls-files -- "$1" 2>/dev/null; }

# CANDIDATOS: descobertos, não listados. Um comando-com-framework se anuncia por ter uma
# superfície invocável (skill própria ou comando em meta/) — o resto o censo mede.
mapfile -t CANDS < <( { _tracked '.claude/skills/*/SKILL.md'; _tracked '.claude/commands/meta/*.md'; } | sort -u )
[ "${#CANDS[@]}" -gt 0 ] \
  || { echo "forge-census: nenhum candidato RASTREADO em .claude/skills/ nem .claude/commands/meta/ — não emito censo vazio. Recusa." >&2; exit 3; }

# ── Os predicados ────────────────────────────────────────────────────────────────────────
# Cada um faz DUAS perguntas, e a segunda foi acrescentada em 2026-09-29 depois que a passada
# adversarial provou o furo: um `.md` que só CITAVA caminhos inexistentes pontuava 7/7. O
# docstring prometia medir "PRESENÇA e REFERÊNCIA" e o código media só referência.
#   (1) o artefato CITA a peça? (a cláusula 1 da doutrina — o artefato nomeia as suas partes)
#   (2) o caminho citado EXISTE no índice? (senão a citação é promessa, não peça)
# Peça citada que não existe conta como AUSENTE, igual a peça que existe e não é citada. As duas
# falham pelo mesmo motivo prático: a sessão não chega nela.
_cited_paths() {  # $1=arquivo  $2=regex do caminho → imprime os caminhos citados, um por linha
  grep -oE "$2" "$1" 2>/dev/null | sort -u
}
# ⚠️ SEM FECHADOR-PRECOCE: a 1a versão dava `break` no 1o casamento, e sob `set -o pipefail` (l.33) o
#    escritor a montante leva EPIPE — o pipeline devolve 141 e a peça EXISTENTE conta como ausente.
#    É a classe pipefail-epipe-early-closer, que eu curei hoje em OUTRO script e reintroduzi aqui;
#    latente só porque o candidato mais citador do repo tem 2 caminhos. O laço DRENA a entrada.
_any_tracked() {  # stdin = caminhos → 0 se ALGUM está no índice
  local pth found=1
  while IFS= read -r pth; do
    [ -n "${pth}" ] || continue
    git -C "${REPO}" ls-files --error-unmatch -- "${pth}" >/dev/null 2>&1 && found=0
  done
  return "${found}"
}

# ⚠️ DOUTRINA: exige fragmento `*-doctrine.md`, não qualquer coisa em `common/prompts/`. Medido:
#    o predicado largo dava 14 positivos e 12 eram falsos (86%) — dez citavam fragmento genérico
#    (`inventory-sync-after-create`, `untrusted-content-provenance`…). Citar a doutrina de OUTRO
#    comando continua contando, e é desenho: a peça 2 é "doutrina REUTILIZÁVEL", logo reuso é a
#    peça funcionando, não falso positivo.
# ⚠️ ACEITA A FORMA RELATIVA, e não por generosidade: a convenção de link deste repo entre comando e
#    fragmento é relativa (`../common/prompts/x-doctrine.md`), e o predicado absoluto dava 75% de
#    falso-negativo — inclusive no `/meta:forge`, que NÃO detectava a doutrina escrita para ele. O
#    caminho relativo é normalizado para o absoluto antes de conferir o índice.
_cites_doctrine() {
  _cited_paths "$1" '((\.\./)*|[.]claude/commands/)common/prompts/[a-z0-9-]+-doctrine[.]md' \
    | sed -E 's|^(\.\./)*common/prompts/|.claude/commands/common/prompts/|' | _any_tracked
}
_cites_workflow() { _cited_paths "$1" '[.]claude/(workflows|utils/[a-z0-9-]+)/[a-z0-9.-]+[.](js|mjs)' | _any_tracked; }
_cites_lens()     { _cited_paths "$1" '[.]claude/rules/[a-z0-9-]+[.]md' | _any_tracked; }

# ⚠️ BANCADA: o nome da família tem de EXISTIR no runner. O predicado largo casava a palavra
#    `lint-selftest` em prosa — cinco positivos sem família nenhuma.
_cites_bench() {
  local fam
  while IFS= read -r fam; do
    [ -n "${fam}" ] || continue
    grep -q "${fam}() {" "${REPO}/.claude/validation/lint-selftest.sh" 2>/dev/null && return 0
  done < <(grep -oE 'run_[a-z0-9_]+_selftests' "$1" 2>/dev/null | sort -u)
  return 1
}

# ⚠️ DESTINO é COMPORTAMENTO, não arquivo — não há caminho para conferir no índice, e isso fica
#    DECLARADO: esta peça é medida por citação apenas. É o teto honesto do censo.
# ⚠️ A ÂNCORA `.kg.yaml` SOLTA CAIU: ela contava ponteiro de backlog (`fios-abertos.kg.yaml` citado
#    como fio) e prosa didática ("os .kg.yaml") como se fossem DESTINO. Inflava o número em ~26%.
#    Sobram as âncoras que denotam ESCRITA: write(KG), o radar como gate, ou o par kg-radar.
_cites_destination() { grep -qiE 'write\(KG\)|kg-radar|radar exit 0' "$1"; }

# ⚠️ CONTEXTO INJETADO é a DIRETIVA DE INJEÇÃO, não a saída dela — e descobrir isso custou QUATRO
#    versões erradas deste predicado, todas do mesmo formato: eu procurava o BLOCO MEDIDO no arquivo.
#    Ele nunca está lá. A superfície carrega `!`comando`` e o HARNESS executa na carga, injetando o
#    resultado no contexto. O bloco de corpus que eu "via" era o RENDERIZADO na minha janela, não o
#    conteúdo do `.md` — confundir a projeção com a fonte é exatamente o que este censo existe para
#    não fazer. As quatro tentativas anteriores: (1) o TÍTULO da seção; (2) `bash <script>` em
#    qualquer lugar, que é passo de procedimento; (3) `**Hoje:` sozinho, uma linha digitável, e a 2a
#    passada adversarial provou o fantasma forjando-a; (4) data + versão juntas, que reprovou a
#    própria instância de referência.
#    O marcador honesto é a diretiva com comando de MEDIÇÃO: ela não se digita, ela roda.
_has_context() { grep -qE '!`[^`]*(date|bash |claude |git )' "$1"; }

_label_of() {  # o nome do candidato SAI do caminho, nunca de uma lista paralela que drifta
  case "$1" in
    .claude/skills/*/SKILL.md) printf '%s' "$(basename "$(dirname "$1")")" ;;
    *)                         printf '%s' "$(basename "$1" .md)" ;;
  esac
}

rows=""; ref_count=0
for rel in "${CANDS[@]}"; do
  f="${REPO}/${rel}"
  [ -f "${f}" ] || continue
  p2=0; p3=0; p4=0; p5=0; p6=0; p7=0
  _cites_doctrine "${f}" && p2=1
  _has_context  "${f}" && p3=1
  _cites_workflow "${f}" && p4=1
  _cites_destination  "${f}" && p5=1
  _cites_lens    "${f}" && p6=1
  _cites_bench  "${f}" && p7=1
  tot=$((1 + p2 + p3 + p4 + p5 + p6 + p7))   # a peça 1 é a própria superfície: existe por construção
  [ "${tot}" -ge 6 ] && ref_count=$((ref_count + 1))
  rows="${rows}${tot}	$(_label_of "${rel}")	${p2}	${p3}	${p4}	${p5}	${p6}	${p7}	${rel}
"
done

sorted_rows="$(printf '%s' "${rows}" | sort -t'	' -k1,1nr -k2,2)"

if [ "${FMT}" = "--tsv" ]; then
  printf 'pecas\tcandidato\tdoutrina\tcontexto\tworkflow\tdestino\tlente\tbancada\tcaminho\n'
  printf '%s\n' "${sorted_rows}"
  exit 0
fi

# ── Markdown: a projeção que entra na SKILL como contexto injetado ────────────────────────
total="${#CANDS[@]}"
printf '# censo das 7 peças · %s candidato(s) rastreado(s) · %s com 6+ peças\n' "${total}" "${ref_count}"
printf 'peças | candidato | 2 doutrina | 3 contexto | 4 workflow | 5 destino | 6 lente | 7 bancada\n'
printf '%s\n' "${sorted_rows}" | awk -F'\t' 'NF>=8 && $2!=""{
  printf "%s/7 | %s | %s | %s | %s | %s | %s | %s\n", $1, $2, ($3?"sim":"—"), ($4?"sim":"—"),
         ($5?"sim":"—"), ($6?"sim":"—"), ($7?"sim":"—"), ($8?"sim":"—") }' | head -12
printf '\n(peça 1 = a própria superfície, existe por construção; o censo mede PRESENÇA e REFERÊNCIA,\n'
printf 'nunca qualidade. Fonte: forge-census.sh, descoberta por citação — o artefato nomeia as\n'
printf 'suas partes e o censo lê. Construir o nome da peça a partir do nome do candidato errou\n'
printf '3 vezes em 2026-09-28 e é o defeito que este desenho existe para não repetir.)\n'
