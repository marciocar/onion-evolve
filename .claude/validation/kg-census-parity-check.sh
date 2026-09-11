#!/usr/bin/env bash
# kg-census-parity-check.sh — REGRA 82: os DOIS leitores do corpus concordam sobre QUEM É NÓ.
#
# IRMÃ DA REGRA 78, e a divisão entre elas é exata. A 78 fecha *"o arquivo é YAML válido"*. Esta
# fecha *"o awk e o YAML veem a MESMA população"* — e a segunda não decorre da primeira.
#
# O SINAL QUE A CRIOU (venda-direta-pdi, pin 5dcc706b2233; REPRODUZIDO no core em 30 segundos):
# um `.kg.yaml` PERFEITAMENTE VÁLIDO em que os dois leitores veem grafos DIFERENTES com todos os
# gates verdes. Um nó `B_ESCONDIDO` escrito DENTRO do bloco `label: |` de outro nó, com uma aresta
# SUPPORTS saindo dele. PyYAML vê 2 nós; o `kg-radar.sh` — QUE É QUEM EMITE O VEREDITO — anuncia
# `3 nós, 2 arestas`, e o nó forjado PESA na centralidade. A REGRA 78 sai rc=0 e está CERTA: o
# arquivo É válido.
#
# CAUSA: o matcher do radar casa `- id:` com QUALQUER indentação dentro de `nodes:`, sem rastrear
# blocos literais. É permissividade correta para um motor awk, e o preço declarado da economia de
# motores — mas o preço só é aceitável se alguém o COBRAR. Esta guarda é a cobrança.
#
# ⚠️ O REQUISITO NÃO-NEGOCIÁVEL, que o adotante descobriu na pele: a 1ª versão da guarda DELES
#    ancorava em dois espaços fixos e NÃO VIA o nó forjado a seis. Media, saía 0, e não replicava
#    nada. Por isso o `_radar_population` abaixo é transcrição LINHA A LINHA da máquina de estados
#    do `kg-radar.sh` (l.203-225), incluindo a ordem das regras — que importa, porque o salto de
#    comentário vem ANTES das trocas de seção. **Guarda que não replica o contador que DÁ O
#    VEREDITO é decoração.**
#
# CATRACA COM BASELINE VERSIONADA (padrão das REGRAS 29/42/45/49/74/78): arquivo já divergente fica
# TOLERADO e visível como SOFT; arquivo NOVO é HARD; e o baseline CRESCER vs `origin/main` é HARD.
#
# Uso : bash .claude/validation/kg-census-parity-check.sh [<raiz>] [--format tsv|--emit-baseline]
# Exit: 0 = os dois leitores concordam · 1 = divergem (fantasmas NOMEADOS) · 2 = NAO MEDIDO.
set -uo pipefail

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
[ "${SEEN_EMIT}" -eq 1 ] && [ "${SEEN_FMT}" -eq 1 ] && {
  echo "ERRO: --emit-baseline e --format são exclusivos" >&2; exit 2; }
[ -n "${ROOT}" ] || ROOT="$(pwd)"
[ -d "${ROOT}" ] || { echo "ERRO: raiz inexistente: ${ROOT}" >&2; exit 2; }

# NAO MEDIDO É DESFECHO DE PRIMEIRA CLASSE, nunca zero. Sem estas três, a guarda não sabe nada —
# e "não sei" impresso como "concordam" é o fail-open que esta casa passou a onda inteira curando.
for _dep in python3 git; do
  command -v "${_dep}" >/dev/null 2>&1 || { echo "kg-census-parity: ${_dep} ausente — NAO MEDIDO" >&2; exit 2; }
done
python3 -c 'import yaml' 2>/dev/null || { echo "kg-census-parity: PyYAML ausente — NAO MEDIDO" >&2; exit 2; }

_top="$(git -C "${ROOT}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "${_top}" ] || { echo "kg-census-parity: '${ROOT}' não é repositório git — NAO MEDIDO" >&2; exit 2; }
ROOT="${_top}"

BASELINE="${ROOT}/.claude/validation/kg-census-parity-baseline.txt"
BASELINE_REL=".claude/validation/kg-census-parity-baseline.txt"
_out() {
  case "${FMT}" in
    tsv) printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" ;;
    *)   printf '%s: [kg-parity/%s] %s — %s\n' "$1" "$2" "$3" "$4" ;;
  esac
}

# `-z` direto do git para o python: `$(...)` do bash DESCARTA bytes nulos e colaria todos os
# caminhos num nome só (cicatriz medida na irmã 78, e ela custou a cobertura do corpus inteiro).
if [ -z "$(cd "${ROOT}" && git ls-files '*.kg.yaml' 2>/dev/null | head -1 || true)" ]; then
  [ "${FMT}" = "emit" ] || _out SOFT SEM-CORPUS "${BASELINE_REL}" "nenhum .kg.yaml versionado — nada a confrontar (git respondeu; o corpus é que está vazio)"
  exit 0
fi

_PYPARITY='
import sys, yaml

def radar_population(txt):
    """TRANSCRICAO da maquina de estados do kg-radar.sh (l.203-225). A ORDEM importa: o salto de
    comentario vem ANTES das trocas de secao, e o matcher de no aceita QUALQUER indentacao — e
    aceitar qualquer indentacao e justamente o que faz o no dentro de `label: |` virar no."""
    def trim(s):
        s = s.strip()
        if s[:1] in ("\"", "\x27"): s = s[1:]
        if s[-1:] in ("\"", "\x27"): s = s[:-1]
        return s
    section = ""; ids = []
    for line in txt.split("\n"):
        if line.lstrip(" \t").startswith("#"):        # /^[[:space:]]*#/ { next }
            continue
        if line.startswith("nodes:"): section = "nodes"; continue
        if line.startswith("edges:"): section = "edges"; continue
        if line.startswith("meta:"):  section = "meta";  continue
        if section == "nodes":
            st = line.lstrip(" \t")
            # /^[[:space:]]+- id:/ — exige >= 1 espaco a esquerda e NAO limita a profundidade
            if st.startswith("- id:") and len(line) > len(st):
                ids.append(trim(st[len("- id:"):]))
    return ids

def yaml_population(txt):
    out = []
    for doc in yaml.safe_load_all(txt):
        if isinstance(doc, dict) and isinstance(doc.get("nodes"), list):
            for n in doc["nodes"]:
                if isinstance(n, dict) and "id" in n:
                    out.append(str(n["id"]))
    return out

for raw in sys.stdin.buffer.read().split(b"\0"):
    if not raw: continue
    name = raw.decode("utf-8", "surrogateescape")
    try:
        txt = open(name, "rb").read().decode("utf-8", "replace")
    except OSError as e:
        print("%s\tIO\t%s" % (name, str(e).replace("\n", " ")[:140])); continue
    try:
        y = yaml_population(txt)
    except Exception as e:
        # YAML invalido e problema da REGRA 78, nao desta. Reportado como NAO-MEDIDO do arquivo
        # para nao virar silencio — mas nunca como paridade OK.
        print("%s\tYAMLERR\t%s" % (name, str(e).replace("\n", " ")[:100])); continue
    r = radar_population(txt)
    fantasmas = [i for i in r if i not in set(y)]
    invisiveis = [i for i in y if i not in set(r)]
    if fantasmas or invisiveis or len(r) != len(y):
        det = "radar=%d yaml=%d" % (len(r), len(y))
        if fantasmas:  det += " | FANTASMA (so o radar ve): " + ", ".join(fantasmas[:8])
        if invisiveis: det += " | INVISIVEL (so o YAML ve): " + ", ".join(invisiveis[:8])
        print("%s\tDIVERGE\t%s" % (name, det))
'
_scan="$(cd "${ROOT}" && git ls-files -z '*.kg.yaml' | python3 -c "${_PYPARITY}" 2>/dev/null)" || {
  echo "kg-census-parity: a varredura FALHOU ao rodar — NAO MEDIDO (nunca leia isto como verde)" >&2; exit 2; }

_div="$(printf '%s\n' "${_scan}" | awk -F'\t' '$2=="DIVERGE"{print $1"\t"$3}')"
_io="$(printf  '%s\n' "${_scan}" | awk -F'\t' '$2=="IO"{print $1"\t"$3}')"
_yerr="$(printf '%s\n' "${_scan}" | awk -F'\t' '$2=="YAMLERR"{print $1"\t"$3}')"

if [ "${FMT}" = "emit" ]; then
  printf '# kg-census-parity-baseline — .kg.yaml em que radar e PyYAML DIVERGEM sobre quem é nó, TOLERADOS.\n'
  printf '# Gerado por: bash .claude/validation/kg-census-parity-check.sh --emit-baseline\n'
  printf '# A métrica de saúde é esta lista ENCOLHENDO — e é MECANISMO: crescer vs origin/main é HARD.\n'
  printf '%s\n' "${_div}" | awk -F'\t' 'NF{print $1}' | LC_ALL=C sort
  exit 0
fi

_tol=""
[ -f "${BASELINE}" ] && _tol="$(grep -vE '^[[:space:]]*(#|$)' "${BASELINE}" || true)"
rc=0

# CATRACA-VIOLADA — o passivo SÓ ENCOLHE, e quem prova é a comparação com origin/main. Sem isto,
# afrouxar a catraca custa uma linha apendada num .txt.
if [ -f "${BASELINE}" ] && git -C "${ROOT}" rev-parse --verify --quiet origin/main >/dev/null 2>&1; then
  _prev="$(git -C "${ROOT}" show "origin/main:${BASELINE_REL}" 2>/dev/null | grep -vcE '^[[:space:]]*(#|$)' || true)"
  _cur="$(printf '%s\n' "${_tol}" | grep -c . || true)"
  if [ -n "${_prev}" ] && [ "${_prev}" -gt 0 ] 2>/dev/null && [ "${_cur}" -gt "${_prev}" ] 2>/dev/null; then
    rc=1
    _out HARD CATRACA-VIOLADA "${BASELINE_REL}" "baseline CRESCEU: ${_prev} → ${_cur} entrada(s) vs origin/main — o passivo só encolhe"
  fi
fi

if [ ! -f "${BASELINE}" ] && [ -n "${_div}" ]; then
  _out SOFT NO-BASELINE "${BASELINE_REL}" "há grafo divergente e NÃO existe baseline — a catraca não está armada (emita com --emit-baseline)"
fi

passivo=0
while IFS=$'\t' read -r f det; do
  [ -n "${f}" ] || continue
  if grep -qxF "${f}" <<< "${_tol}"; then
    passivo=$((passivo+1))
  else
    rc=1
    _out HARD DIVERGE "${f}" "os dois leitores discordam sobre QUEM É NÓ (${det}) — o radar emite o veredito sobre uma população que o YAML não tem; nó dentro de bloco literal é o caso conhecido"
  fi
done <<< "${_div}"

while IFS=$'\t' read -r f det; do
  [ -n "${f}" ] || continue
  _out SOFT NAO-MEDIDO "${f}" "paridade NÃO MEDIDA: o PyYAML não parseou (${det}) — isto é a REGRA 78, não esta; não leia como paridade OK"
done <<< "${_yerr}"

while IFS=$'\t' read -r f det; do
  [ -n "${f}" ] || continue
  _out SOFT ILEGIVEL "${f}" "versionado mas não deu para LER (${det}) — apagado sem git rm? symlink quebrado?"
done <<< "${_io}"

[ "${passivo}" -eq 0 ] || _out SOFT PASSIVO "${BASELINE_REL}" "${passivo} grafo(s) divergente(s) tolerado(s) pelo baseline — a métrica de saúde é este número DIMINUINDO"
exit "${rc}"
