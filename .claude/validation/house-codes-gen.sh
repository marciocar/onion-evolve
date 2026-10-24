#!/usr/bin/env bash
# house-codes-gen.sh — projeta as linhas de TERMO do glossário da glosa (house-codes.tsv) a partir do
# vocabulário dos grafos (x_term, kg-ssot 4.23.0, contrato v4.14).
#
# Por que existe (2026-10-23): o maestro decidiu que o glossário do hook vira projeção do vocabulário
# (D_NOMES_NASCEM_CERTOS_NAS_TRES_CAMADAS_1023). Antes, "r13 = rodada do radar" morava à mão no TSV, e o
# mesmo r1 que é réplica do spike A2A ganhava a glosa do radar (o caso do dia: "A réplica r1 do cenário
# A7-C1 do spike A2A rodou; a rodada seguinte..."). Agora o nome mora no grafo, uma vez, e o hook lê a
# projeção: o hook NUNCA chama o Python do vendor (a carga dele é de milissegundos), este gerador sim.
#
# O que é gerado e o que é à mão, no MESMO arquivo:
#   · à mão: as linhas static/rule/node/issue (o que não é termo) e as linhas `scheme`, que dão a cada
#     esquema projetado a opacidade, o accept e o domínio (o x_term não tem domínio de bloco);
#   · gerado: o bloco entre os marcadores, uma linha `term` por x_term vivo cujo esquema tem linha
#     `scheme` (notation → regex escapada, pref → glosa, scheme → o domínio da linha scheme). Esquema sem
#     linha `scheme` fica só no lint de nomes da kg-ssot (kg_vocab lint), fora do hook.
# Linha `scheme` sem nenhum termo é erro (esquema digitado errado não some calado).
#
# A catraca é a REGRA 62 (Projeção GERADA em sincronia com a fonte (docs/backlog.md)): o lint chama
# `--markdown` e compara byte a byte com o arquivo rastreado.
#
# Uso : bash .claude/validation/house-codes-gen.sh --markdown   o arquivo inteiro, regenerado, no stdout
#       bash .claude/validation/house-codes-gen.sh --write      regrava o house-codes.tsv
#   ONION_HOUSE_CODES_TSV troca o arquivo; ONION_VOCAB_ROOT troca a raiz do corpus (a bancada usa os dois).
#   rc 0 = gerou · rc 1 = entrada quebrada (marcadores, esquema sem termo, vendor ilegível)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${ONION_VOCAB_ROOT:-$(cd "${HERE}/../.." && pwd)}"
TSV="${ONION_HOUSE_CODES_TSV:-${HERE}/house-codes.tsv}"
mode="${1:-}"
case "${mode}" in --markdown|--write) ;; *) echo "uso: $0 --markdown | --write" >&2; exit 1 ;; esac
[ -f "${TSV}" ] || { echo "house-codes-gen: ${TSV} ausente" >&2; exit 1; }
V="${ROOT}/vendor/kg-ssot/tools/kg_vocab.py"
[ -f "${V}" ] || { echo "house-codes-gen: ${V} ausente — sem o vendor não há vocabulário" >&2; exit 1; }

# os grafos com x_term, rastreados, fora do vendor, das fixtures e do arquivo do kg-inbox (o mesmo corpus do
# lint de nomes); passar só estes é a mesma resposta do --root, sem ler os ~190 grafos (a bancada confere)
# a chave pode vir sem aspas (YAML), entre aspas (JSON e YAML citado) e o grafo pode ser .kg.json — a bancada
# compara esta lista com o --root do vendor, e foi assim que a forma citada apareceu (passada adversarial de 2026-10-23)
mapfile -t files < <(git -C "${ROOT}" grep -lE '^[[:space:]]*"?x_term"?[[:space:]]*:' -- '*.kg.yaml' '*.kg.json' 2>/dev/null |
  grep -v -e '^vendor/' -e '/fixtures/' -e '^docs/materials/' -e '^docs/evolution/kg-inbox/_rejected/' \
          -e '^docs/evolution/kg-inbox/_sealed/' | sed "s#^#${ROOT}/#")
if [ "${#files[@]}" -gt 0 ]; then
  json="$(cd "${ROOT}" && python3 -I -B "${V}" terms --format json "${files[@]}")" || { echo "house-codes-gen: kg_vocab terms falhou" >&2; exit 1; }
else
  json='{"schema_version": "kg-ssot.vocab/1", "terms": [], "unreadable": []}'
fi

tmp="$(mktemp)"; trap 'rm -f "${tmp}"' EXIT
printf '%s' "${json}" | python3 -I -B -c '
import json, re, sys
tsv = sys.argv[1]
BEGIN = "# >>> GERADO por .claude/validation/house-codes-gen.sh a partir dos x_term dos grafos: nao edite a mao (REGRA 62)"
END = "# <<< fim do bloco gerado"
d = json.load(sys.stdin)
if d.get("schema_version") != "kg-ssot.vocab/1" or not isinstance(d.get("terms"), list):
    sys.exit("house-codes-gen: JSON do kg_vocab com forma inesperada")
if d.get("unreadable"):
    sys.exit("house-codes-gen: grafo ilegivel: %r" % d["unreadable"])
lines = open(tsv, encoding="utf-8").read().split("\n")
if lines.count(BEGIN) != 1 or lines.count(END) != 1 or lines.index(BEGIN) > lines.index(END):
    sys.exit("house-codes-gen: marcadores do bloco gerado ausentes ou fora de ordem em " + tsv)
a, b = lines.index(BEGIN), lines.index(END)
schemes = {}
for ln in lines[:a] + lines[b + 1:]:
    cols = ln.split("\t")
    if cols and cols[0] == "scheme":
        if len(cols) != 6:
            sys.exit("house-codes-gen: linha scheme com %d colunas (quer 6): %r" % (len(cols), ln))
        schemes[cols[1]] = cols
rows, used = [], set()
for t in d["terms"]:
    sc, note, pref = t.get("scheme"), t.get("notation"), t.get("pref")
    if sc not in schemes or not isinstance(note, str) or not note:
        continue
    if t.get("status") in ("superseded", "refuted"):   # o termo vivo, pela regra do lint de nomes (LIVE_OUT)
        continue
    for v in (note, pref):
        if not isinstance(v, str) or "\t" in v or "\n" in v:
            sys.exit("house-codes-gen: termo %s com TAB ou quebra de linha" % t.get("id"))
    _, _, op, _, acc, dom = schemes[sc]
    rows.append((note, sc, "\t".join(("term", re.escape(note), op, pref, acc, dom, sc))))
    used.add(sc)
empty = sorted(set(schemes) - used)
if empty:
    sys.exit("house-codes-gen: linha scheme sem nenhum termo no vocabulario: " + ", ".join(empty))
rows.sort(key=lambda r: (r[1], len(r[0]), r[0]))
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(lines[:a + 1] + [r[2] for r in rows] + lines[b:]))
' "${TSV}" "${tmp}" || exit 1
# (a substituição de comando comeria a quebra final; o texto vai por arquivo)
if [ "${mode}" = "--markdown" ]; then cat "${tmp}"; else cat "${tmp}" > "${TSV}"; fi
