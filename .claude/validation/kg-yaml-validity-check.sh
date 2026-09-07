#!/usr/bin/env bash
# kg-yaml-validity-check.sh — o corpus de grafos tem de ser YAML DE VERDADE, não só texto que o awk lê.
#
# POR QUE EXISTE (medido 2026-09-06, e a prova é uma reincidência do próprio autor). O `kg-radar.sh` —
# gate de todo `.kg.yaml` pela REGRA 52 — parseia com AWK SOBRE TEXTO. Consequência: a "verdade" do
# corpus é a do awk, não a do YAML, e um arquivo passa no gate com `exit 0` sendo ilegível para
# qualquer biblioteca YAML. Cinco arquivos versionados estavam assim.
#
# ⚠️ O QUINTO FOI ESCRITO NO PR QUE DENUNCIOU A CLASSE, dentro do label que a descreve. Radar exit 0,
#    lint 0 HARD, CI verde, merge. Descrever a classe não protege contra ela; guarda protege.
#
# DANO ALÉM DA ESTÉTICA: todo consumidor não-awk (MCP, app, adotante com lib YAML) vê buracos onde o
# core vê grafos — e foi essa fresta que permitiu, na bancada do predicado de selo, forjar uma aresta
# REFUTES DENTRO de um `label: |`: para quem lê texto, a aresta existe.
#
# CATRACA COM BASELINE VERSIONADA (padrão da casa p/ passivo em massa — REGRAS 29/42/45/49/74):
# arquivo já quebrado fica TOLERADO e visível como SOFT; arquivo NOVO é HARD; e o baseline CRESCER
# vs `origin/main` é HARD (CATRACA-VIOLADA) — sem isso "só encolhe" é comentário, não mecanismo.
#
# ⚠️ CICATRIZES DA 1ª VERSÃO (todas medidas por revisor adversarial, nenhuma hipotética):
#   · heredoc de programa + here-string de dados no MESMO comando: o Python recebeu a lista de
#     arquivos como programa, deu SyntaxError e o script saiu 0 declarando corpus limpo;
#   · parser de flags POSICIONAL: `bash <emissor> --emit-baseline` (como o regen-baselines do
#     adotante invoca) devolvia exit 2, e o adotante ficava com o baseline DO CORE;
#   · `--format` como ÚLTIMO argumento fazia `shift 2` falhar e o laço girar para sempre, mudo;
#   · `split()` na lista de arquivos estilhaçava nome com espaço e recebia nome não-ASCII CITADO
#     (`core.quotePath`), produzindo HARD falso e cobertura ZERO no arquivo real;
#   · erro de I/O (arquivo apagado ainda no índice, symlink quebrado) era reportado como "não é YAML";
#   · `git` ausente ou raiz não-git virava um SOFT verde "nenhum .kg.yaml — nada a validar".
#
# Uso : bash .claude/validation/kg-yaml-validity-check.sh [<raiz>] [--format tsv|--emit-baseline]
# Exit: 0 = ok (ou só passivo) · 1 = violação · 2 = erro de uso/ambiente (NAO VERIFICADO).
set -uo pipefail

# ⚠️ PARSING EM LAÇO, COM ARIDADE VALIDADA. Ver cicatrizes 2 e 3 acima.
ROOT=""; FMT=""; SEEN_EMIT=0; SEEN_FMT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --emit-baseline|--emit) SEEN_EMIT=1; FMT="emit"; shift ;;
    --format)
      [ $# -ge 2 ] || { echo "ERRO: --format exige um valor (tsv)" >&2; exit 2; }
      case "$2" in tsv|human) : ;; *) echo "ERRO: --format desconhecido '$2' (use tsv)" >&2; exit 2 ;; esac
      SEEN_FMT=1; [ "${SEEN_EMIT}" -eq 1 ] || FMT="$2"; shift 2 ;;
    --tsv) SEEN_FMT=1; [ "${SEEN_EMIT}" -eq 1 ] || FMT="tsv"; shift ;;
    -*) echo "ERRO: flag desconhecida '$1'" >&2; exit 2 ;;
    *)  [ -z "${ROOT}" ] || { echo "ERRO: raiz duplicada '$1'" >&2; exit 2; }; ROOT="$1"; shift ;;
  esac
done
# Emitir e formatar são modos EXCLUSIVOS: pedir os dois já gravou violação onde ia baseline.
[ "${SEEN_EMIT}" -eq 1 ] && [ "${SEEN_FMT}" -eq 1 ] && {
  echo "ERRO: --emit-baseline e --format são exclusivos (a ordem decidia o modo em silêncio)" >&2; exit 2; }
[ -n "${ROOT}" ] || ROOT="$(pwd)"
[ -d "${ROOT}" ] || { echo "ERRO: raiz inexistente: ${ROOT}" >&2; exit 2; }

# DEPENDÊNCIAS DURAS — as três, com o mesmo rigor. `git` faltava desta lista e um repo sem git virava
# "corpus vazio", que é verde.
for _dep in python3 git; do
  command -v "${_dep}" >/dev/null 2>&1 || { echo "kg-yaml-validity: ${_dep} ausente — NAO VERIFICADO" >&2; exit 2; }
done
python3 -c 'import yaml' 2>/dev/null || { echo "kg-yaml-validity: PyYAML ausente — NAO VERIFICADO" >&2; exit 2; }

# A raiz é normalizada para o TOPLEVEL: rodar de um subdiretório procurava baseline em
# <subdir>/.claude/validation e transformava o passivo inteiro em HARD.
_top="$(git -C "${ROOT}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "${_top}" ] || { echo "kg-yaml-validity: '${ROOT}' não é repositório git — NAO VERIFICADO" >&2; exit 2; }
ROOT="${_top}"

BASELINE="${ROOT}/.claude/validation/kg-yaml-validity-baseline.txt"
BASELINE_REL=".claude/validation/kg-yaml-validity-baseline.txt"
_out() {
  case "${FMT}" in
    tsv) printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" ;;
    *)   printf '%s: [kg-yaml/%s] %s — %s\n' "$1" "$2" "$3" "$4" ;;
  esac
}

# ⚠️ `-z` NÃO É ENFEITE: sem ele, nome com espaço estilhaça e nome não-ASCII chega CITADO
#    (core.quotePath default true) — HARD falso, e cobertura ZERO no arquivo que importa.
# ⚠️ E O `-z` NÃO PODE PASSAR POR VARIÁVEL: `$(...)` do bash DESCARTA bytes nulos, e a 1ª tentativa
#    colou os 121 caminhos num nome só ("File name too long"), reportando UM ILEGIVEL gigante e
#    exit 0 — o corpus inteiro deixou de ser verificado. O NUL vai direto do git para o python.
if [ -z "$(cd "${ROOT}" && git ls-files '*.kg.yaml' 2>/dev/null | head -1 || true)" ]; then
  [ "${FMT}" = "emit" ] || _out SOFT SEM-CORPUS "${BASELINE_REL}" "nenhum .kg.yaml versionado neste repo — nada a validar (git respondeu, o corpus é que está vazio)"
  exit 0
fi

# I/O e YAML são erros DIFERENTES: arquivo apagado-mas-no-índice ou symlink quebrado não é
# "YAML inválido", e reportá-lo assim manda alguém consertar sintaxe de um arquivo que não existe.
_PYCHK='
import sys, yaml
for raw in sys.stdin.buffer.read().split(b"\0"):
    if not raw:
        continue
    name = raw.decode("utf-8", "surrogateescape")
    try:
        txt = open(name, "rb").read().decode("utf-8", "replace")
    except OSError as e:
        print("%s\tIO\t%s" % (name, str(e).replace("\n", " ")[:140]))
        continue
    try:
        # ⚠️ safe_load_ALL, e a lista() é obrigatória: `safe_load` recusa STREAM MULTI-DOCUMENTO, que
        #    é YAML perfeitamente válido — e é EXATAMENTE a forma do grafo que a adoção semeia
        #    (frontmatter `---` + o grafo). Medido 2026-09-07: 3 adotantes reais tinham o PRIMEIRO
        #    grafo que o Onion lhes deu classificado como inválido por esta guarda, que nasceu ontem.
        #    A pergunta certa é "isto parseia como YAML?", não "isto é UM documento?". Sem o list()
        #    o gerador nem chega a parsear o 2º documento e o erro some.
        list(yaml.safe_load_all(txt))
    except Exception as e:
        print("%s\tYAML\t%s" % (name, str(e).replace("\n", " ")[:140]))
'
_scan="$(cd "${ROOT}" && git ls-files -z '*.kg.yaml' | python3 -c "${_PYCHK}" 2>/dev/null)" || {
  echo "kg-yaml-validity: a varredura FALHOU ao rodar — NAO VERIFICADO (nunca leia isto como verde)" >&2; exit 2; }

_bad="$(printf '%s\n' "${_scan}" | awk -F'\t' '$2=="YAML"{print $1"\t"$3}')"
_io="$(printf '%s\n' "${_scan}"  | awk -F'\t' '$2=="IO"{print $1"\t"$3}')"

if [ "${FMT}" = "emit" ]; then
  printf '# kg-yaml-validity-baseline — arquivos .kg.yaml que o PyYAML rejeita e que estão TOLERADOS.\n'
  printf '# Gerado por: bash .claude/validation/kg-yaml-validity-check.sh --emit-baseline\n'
  printf '# A métrica de saúde é esta lista ENCOLHENDO — e isso é MECANISMO: crescer vs origin/main é HARD.\n'
  printf '%s\n' "${_bad}" | awk -F'\t' 'NF{print $1}' | LC_ALL=C sort
  exit 0
fi

_tol=""
[ -f "${BASELINE}" ] && _tol="$(grep -vE '^[[:space:]]*(#|$)' "${BASELINE}" || true)"
rc=0

# CATRACA-VIOLADA — o passivo SÓ ENCOLHE, e quem prova isso é a comparação com origin/main, não o
# comentário no topo do arquivo. Sem esta guarda, afrouxar a catraca custa uma linha apendada num .txt.
if [ -f "${BASELINE}" ] && git -C "${ROOT}" rev-parse --verify --quiet origin/main >/dev/null 2>&1; then
  _prev="$(git -C "${ROOT}" show "origin/main:${BASELINE_REL}" 2>/dev/null | grep -vcE '^[[:space:]]*(#|$)' || true)"
  _cur="$(printf '%s\n' "${_tol}" | grep -c . || true)"
  if [ -n "${_prev}" ] && [ "${_prev}" -gt 0 ] 2>/dev/null && [ "${_cur}" -gt "${_prev}" ] 2>/dev/null; then
    rc=1
    _out HARD CATRACA-VIOLADA "${BASELINE_REL}" "baseline CRESCEU: ${_prev} → ${_cur} entrada(s) vs origin/main — o passivo só encolhe"
  fi
fi

if [ ! -f "${BASELINE}" ] && [ -n "${_bad}" ]; then
  _out SOFT NO-BASELINE "${BASELINE_REL}" "há arquivo inválido e NÃO existe baseline — a catraca não está armada (emita com --emit-baseline)"
fi

passivo=0
while IFS=$'\t' read -r f err; do
  [ -n "${f}" ] || continue
  if grep -qxF "${f}" <<< "${_tol}"; then
    passivo=$((passivo+1))
  else
    rc=1
    _out HARD INVALIDO "${f}" "não é YAML válido (${err}) — o kg-radar parseia TEXTO e aceita; qualquer consumidor com lib YAML não"
  fi
done <<< "${_bad}"

while IFS=$'\t' read -r f err; do
  [ -n "${f}" ] || continue
  _out SOFT ILEGIVEL "${f}" "versionado mas não deu para LER (${err}) — apagado sem git rm? symlink quebrado? isto não é erro de YAML"
done <<< "${_io}"

[ "${passivo}" -eq 0 ] || _out SOFT PASSIVO "${BASELINE_REL}" "${passivo} grafo(s) inválido(s) tolerado(s) pelo baseline — a métrica de saúde é este número DIMINUINDO"
exit "${rc}"
