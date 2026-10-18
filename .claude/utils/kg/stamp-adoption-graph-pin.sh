#!/usr/bin/env bash
# =============================================================================
# stamp-adoption-graph-pin.sh — o pin do grafo de adoção tem UM escritor: quem escreve o carimbo.
#
# POR QUE EXISTE (SAC-149, 2026-10-15; 2ª ocorrência medida, a 1ª no update #20 do mesmo adotante): o nó
# ONION_INSTALLED da semente do KG (docs/onion/graph/onion-adoption.kg.yaml) diz "Framework instalado: pin X".
# O --update re-carimba o .claude/.onion-version e deixava o grafo dizendo o pin ANTIGO; carimbá-lo era passo
# à mão, fora do procedimento, e o grafo — que o warm-up manda ler PRIMEIRO — mentia sobre a versão instalada.
# Agora o write-stamp.sh chama este helper ao fim de todo carimbo de adoção: o escritor do pin é o mesmo do
# carimbo, e a REGRA 108 (Pin do grafo de adoção concorda com o carimbo) cobra a paridade no lint.
#
# O QUE FAZ: no bloco do nó ONION_INSTALLED, grava `x_pin: "<source_commit>"` (o campo de máquina que a
# REGRA 108 lê), troca o 1º "pin `<hex>`" do label pelo pin novo e re-carimba verified_at/verified_against
# como leitura do carimbo. Não toca outro nó nem outro campo. Idempotente.
# Também troca, em verified_against e provenance (source/locator), as citações do pin ANTIGO pelo novo: esses
# campos descrevem a verificação atual. Label e narrative (a história) ficam como o dono escreveu.
# O QUE NÃO FAZ: inventar onde está o pin. Nó sem x_pin e com label sem "pin `<hex>`" (editado pelo dono)
# ganha só o x_pin e o aviso; grafo ou nó ausente = nada a carimbar (adotante sem semente), dito.
#
# Uso : stamp-adoption-graph-pin.sh <DEST> [--check]
#   --check: não escreve; rc 0 = o pin do grafo é o do carimbo (ou não há semente) · 1 = divergem
#            (imprime os dois) · 3 = não deu para ler o pin do grafo (nó sem x_pin nem pin no label).
# Saída: rc 0 escrito ou nada a fazer · 2 uso · 3 aviso (gravou só o x_pin; label não reconhecido).
# =============================================================================
set -uo pipefail
DEST="${1:-}"; MODE="write"
[ "${2:-}" = "--check" ] && MODE="check"
[ -n "${DEST}" ] && [ -d "${DEST}" ] || { echo "uso: stamp-adoption-graph-pin.sh <DEST> [--check]" >&2; exit 2; }
STAMP="${DEST}/.claude/.onion-version"
GRAPH="${DEST}/docs/onion/graph/onion-adoption.kg.yaml"
[ -f "${STAMP}" ] || { echo "stamp-adoption-graph-pin: sem carimbo em ${DEST} — nada a carimbar"; exit 0; }
PIN="$(awk '/^source_commit:/{print $2; exit}' "${STAMP}")"
[ -n "${PIN}" ] || { echo "stamp-adoption-graph-pin: carimbo sem source_commit — nada a carimbar"; exit 0; }
[ -f "${GRAPH}" ] || { echo "stamp-adoption-graph-pin: sem a semente do KG (docs/onion/graph/onion-adoption.kg.yaml) — nada a carimbar"; exit 0; }

python3 - "${GRAPH}" "${PIN}" "${MODE}" "$(date +%F)" <<'PY'
import re, sys
path, pin, mode, today = sys.argv[1:5]
lines = open(path, encoding="utf-8").read().split("\n")
start = next((i for i, l in enumerate(lines) if re.match(r"""^  - id:[ \t]*["']?ONION_INSTALLED["']?[ \t]*$""", l)), None)
if start is None:
    print("stamp-adoption-graph-pin: a semente não tem o nó ONION_INSTALLED — nada a carimbar"); sys.exit(0)
end = start + 1
while end < len(lines) and not re.match(r"^  - id:", lines[end]) and not (lines[end] and not lines[end].startswith((" ", "#"))):
    end += 1
blk = lines[start:end]
def field(name):
    return next((i for i, l in enumerate(blk) if l.startswith(f"    {name}:")), None)
LABEL_PIN = re.compile(r"pin `([0-9a-f]{7,40})`")
xi, li = field("x_pin"), field("label")
cur = None
if xi is not None:
    cur = blk[xi].split(":", 1)[1].strip().strip('"\'')
elif li is not None and LABEL_PIN.search(blk[li]):
    cur = LABEL_PIN.search(blk[li]).group(1)
if mode == "check":
    if cur is None:
        print("stamp-adoption-graph-pin: ONION_INSTALLED sem x_pin e sem 'pin `<sha>`' no label — pin do grafo NÃO MEDIDO"); sys.exit(3)
    _n = min(len(cur), len(pin))          # pin de 7 hex no label casa com o de 12 do carimbo (passada adversarial)
    if _n < 7 or cur[:_n] != pin[:_n]:
        print(f"stamp-adoption-graph-pin: o grafo diz pin {cur}, o carimbo diz {pin}"); sys.exit(1)
    sys.exit(0)
# IDEMPOTENTE DE VERDADE (passada adversarial, 2026-10-15): o x_pin já é o do carimbo → nada muda, nem o
# verified_at. Re-carimbar o MESMO pin (o --promote-hub) deixava o grafo sujo e fora do commit dele.
if xi is not None and cur and cur[:min(len(cur), len(pin))] == pin[:min(len(cur), len(pin))] and len(cur) >= len(pin):
    print(f"stamp-adoption-graph-pin: ONION_INSTALLED já diz o pin {pin} — nada a carimbar"); sys.exit(0)
# O LABEL só é reescrito quando ainda é o do SEMEADOR ("Framework instalado: pin `X`, modo …"). Label que o dono
# editou (história de pins, notas) fica INTACTO: trocar só o hash deixava o resto da frase desatualizado e
# cortava a cadeia que ele escreveu. Aí grava-se só o x_pin, que é o que a REGRA 108 lê, e diz-se isso.
SEED_LABEL = re.compile(r'^    label: "Framework instalado: pin `[0-9a-f]{7,40}`, modo `[^`]*`, papel `[^`]*`, branch de integração `[^`]*`"[ \t]*$')
rc, label_ok = 0, li is not None and SEED_LABEL.match(blk[li])
if label_ok:
    blk[li] = LABEL_PIN.sub(f"pin `{pin}`", blk[li], count=1)
else:
    rc = 3
newpin = f'    x_pin: "{pin}"'
if xi is not None:
    blk[xi] = newpin
else:
    k = (field("verified_against") if field("verified_against") is not None else (li if li is not None else 0)) + 1
    blk.insert(k, newpin)
vi, gi = field("verified_at"), field("verified_against")
if vi is not None:
    blk[vi] = f'    verified_at: "{today}"'
SEED_VA = ("stamp-claude-onion-version-lido-na-adocao", "stamp-claude-onion-version-lido-pelo-escritor-do-carimbo")
if gi is not None and blk[gi].split(":", 1)[1].strip().strip('"\'') in SEED_VA:   # o do dono fica
    blk[gi] = "    verified_against: stamp-claude-onion-version-lido-pelo-escritor-do-carimbo"
# A FONTE DA VERIFICAÇÃO acompanha o pin (2026-10-18, sinal de um adotante): o motor trocava o verified_at e o
# x_pin e deixava verified_against e provenance citando o pin ANTIGO, e o nó declarava verificado o que não
# verificou mais. Esses dois campos descrevem a verificação ATUAL, então o pin antigo vira o novo neles; o
# label e a narrative guardam a HISTÓRIA e ficam como o dono escreveu. Só troca o pin que ESTAVA no nó (cur):
# um outro hash citado ali é referência do dono, não o pin desta adoção.
swapped = 0
if cur:
    HEX = re.compile(r"\b[0-9a-f]{7,40}\b")
    def _swap(m):
        global swapped
        h = m.group(0); k = min(len(h), len(cur))
        if k >= 7 and h[:k] == cur[:k] and h[:min(len(h), len(pin))] != pin[:min(len(h), len(pin))]:
            swapped += 1; return pin
        return h
    in_prov = False
    for n, l in enumerate(blk):
        if l.startswith("    provenance:"):
            in_prov = True; continue
        if in_prov and not l.startswith("      "):
            in_prov = False
        if l.startswith("    verified_against:") or (in_prov and re.match(r"^      (source|locator):", l)):
            blk[n] = HEX.sub(_swap, l)
new = lines[:start] + blk + lines[end:]
if new != lines:
    open(path + ".pin-tmp", "w", encoding="utf-8").write("\n".join(new))
    import os; os.replace(path + ".pin-tmp", path)
print(f"stamp-adoption-graph-pin: ONION_INSTALLED carimbado com o pin {pin}"
      + ("" if label_ok else " (só o x_pin: o label foi editado pelo dono e ficou intacto — confira-o)")
      + (f"; {swapped} citação(ões) do pin antigo em verified_against/provenance trocada(s) pelo novo" if swapped else ""))
sys.exit(rc)
PY
