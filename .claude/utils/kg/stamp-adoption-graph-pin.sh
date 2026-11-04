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
# campos descrevem a verificação atual. A narrative (a história) fica como o dono escreveu, salvo no molde de update.
# LABEL EDITADO PELO DONO que cita o pin ANTIGO como token exato UMA vez (o x_pin anterior, sem ser prefixo de outro
# hex; repetido, qual é o atual é leitura da frase e o motor cala): só esse token vira o pin novo, e o resto da redação fica (revisão adversarial do adotante sge, 2026-10-27: duas
# rodadas seguidas ele trocou o hash do label à mão, porque o motor gravava o x_pin e deixava o label no pin velho).
# MOLDE DE UPDATE (sinal da curadoria, 2026-11-04, 4ª recorrência): label "Framework instalado: pin `X` (update de
# AAAA-MM-DD, com o kg-ssot X.Y.Z e o contrato vN.N), modo `m`, papel `p`, integração `b`." com a narrative "Pins
# anteriores, do mais novo ao mais velho (…): `a`, `b`, …; a adoção foi `z`. …". Nesse molde o nó é REFEITO: o label
# a partir do carimbo, de hoje e do vendor/kg-ssot do alvo; a lista ganha o pin que sai (sem duplicar, sem o pin novo
# nem o da adoção); a provenance passa a citar o carimbo novo. O resto da narrative fica como o dono escreveu.
# O QUE NÃO FAZ: inventar onde está o pin. Label editado SEM o pin antigo como token ganha só o x_pin e o aviso
# (rc 3); grafo ou nó ausente = nada a carimbar (adotante sem semente), dito.
# RECUSA (rc 4, nada escrito no grafo): label que começa no molde de update e não casa com ele inteiro, narrative fora
# do molde, versão da kg-ssot ou contrato não medidos no vendor; e label editado FORA dos moldes que traz um dado do
# update que o motor não sabe refazer ("update de", "atualizado em/de/para", "kg-ssot", "contrato v"): trocar só o
# pin ali deixaria a data e a versão do update anterior. Esta lista é de vocabulário, e o que ela não nomeia segue a
# troca do token (limite declarado).
#
# Uso : stamp-adoption-graph-pin.sh <DEST> [--check]
#   --check: não escreve; rc 0 = o pin do grafo é o do carimbo (ou não há semente) · 1 = divergem
#            (imprime os dois) · 3 = não deu para ler o pin do grafo (nó sem x_pin nem pin no label).
# Saída: rc 0 escrito ou nada a fazer · 2 uso · 3 aviso (gravou só o x_pin; label sem o pin antigo como token) ·
#        4 recusado (label ou narrative que o motor não sabe refazer; nada escrito no grafo).
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

python3 - "${GRAPH}" "${PIN}" "${MODE}" "$(date +%F)" "${DEST}" <<'PY'
import json, os, re, sys
path, pin, mode, today, dest = sys.argv[1:6]
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
# O LABEL do SEMEADOR ("Framework instalado: pin `X`, modo …") troca o 1º "pin `X`". Label que o dono editou
# (história de pins, notas) troca SÓ o token exato do pin antigo (cur), e a redação dele fica: antes ficava
# inteiro, e o adotante sge trocou o hash à mão duas rodadas seguidas (revisão adversarial, 2026-10-27). Os
# outros hashes da cadeia dele (o pin da adoção) não são o cur e não mudam. Label que não cita o cur como token:
# grava-se só o x_pin, que é o que a REGRA 108 lê, e diz-se isso (rc 3).
SEED_LABEL = re.compile(r'^    label: "Framework instalado: pin `[0-9a-f]{7,40}`, modo `[^`]*`, papel `[^`]*`, branch de integração `[^`]*`"[ \t]*$')
# MOLDE DE UPDATE (sinal da curadoria, 2026-11-04, 4ª recorrência seguida): o label que diz a data do update, a
# versão da kg-ssot e o contrato, e a narrative que guarda a lista de pins anteriores. Trocar só o token do pin
# deixava a data, a versão, a lista (sem o pin que acabou de sair) e a provenance do update ANTERIOR, e o dono
# curava à mão a cada rodada. Neste molde o nó é REFEITO de fontes medidas: o carimbo (pin, modo, papel,
# integração), a data de hoje, o vendor/kg-ssot do alvo (versão e contrato) e a lista anterior mais o pin que sai.
UPD_PREFIX = re.compile(r'^    label: "Framework instalado: pin `[0-9a-f]{7,40}` \(update de ')
UPD_LABEL = re.compile(r'^    label: "Framework instalado: pin `[0-9a-f]{7,40}` \(update de \d{4}-\d{2}-\d{2}, com o kg-ssot [0-9]+\.[0-9]+\.[0-9]+ e o contrato v[0-9]+(?:\.[0-9]+)*\), modo `(?P<mode>[^`]*)`, papel `(?P<role>[^`]*)`, integração `(?P<ib>[^`]*)`\."[ \t]*$')
UPD_NARR = re.compile(r'^    narrative: "(?P<head>Pins anteriores, do mais novo ao mais velho(?: \([^)]*\))?: )(?P<list>`[0-9a-f]{7,40}`(?:, `[0-9a-f]{7,40}`)*); a adoção foi `(?P<adopt>[0-9a-f]{7,40})`\.(?P<rest>[^"]*)"[ \t]*$')
# Fora dos dois moldes, o label que traz um dado do update que o motor não sabe refazer (a data do update, a versão
# da kg-ssot, o contrato) fica velho com a troca só do pin: aí o motor RECUSA, em vez de reescrever às cegas.
STALE_MARK = re.compile(r"(?i)(update de|atualizad[oa] (?:em|de|para)|kg-ssot|contrato v)")
def refuse(why):
    print(f"stamp-adoption-graph-pin: RECUSADO, nada escrito no grafo — {why}. Refaça o ONION_INSTALLED à mão no molde "
          "de update (label 'Framework instalado: pin `<pin>` (update de <AAAA-MM-DD>, com o kg-ssot <X.Y.Z> e o contrato "
          "v<N.N>), modo `<m>`, papel `<p>`, integração `<b>`.' e narrative 'Pins anteriores, do mais novo ao mais velho "
          "(…): `<pin>`, …; a adoção foi `<pin>`. …') ou deixe o label sem esses dados, e rode de novo.", file=sys.stderr)
    sys.exit(4)
def same(a, b):
    k = min(len(a), len(b)); return k >= 7 and a[:k] == b[:k]
rc, label_ok = 0, li is not None and SEED_LABEL.match(blk[li])
label_swapped = 0
rebuilt = False
if li is not None and UPD_PREFIX.match(blk[li]):
    m = UPD_LABEL.match(blk[li])
    if not m:
        refuse("o label começa no molde de update mas não casa com ele inteiro (token fora do molde)")
    ni = field("narrative")
    nm = UPD_NARR.match(blk[ni]) if ni is not None else None
    if not nm:
        refuse("o label está no molde de update, mas a narrative não traz a lista de pins anteriores no molde")
    try:
        kv = json.load(open(os.path.join(dest, "vendor/kg-ssot/.kg-ssot-version"), encoding="utf-8"))["version"]
        assert re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", str(kv))
    except Exception:
        refuse("a versão da kg-ssot não foi medida em vendor/kg-ssot/.kg-ssot-version")
    try:
        cv = re.search(r'^CONTRACT_VERSION\s*=\s*["\']([0-9]+(?:\.[0-9]+)*)["\']', open(os.path.join(dest, "vendor/kg-ssot/tools/kg_validate.py"), encoding="utf-8").read(), re.M).group(1)
    except Exception:
        refuse("o contrato não foi medido (CONTRACT_VERSION em vendor/kg-ssot/tools/kg_validate.py)")
    def sfield(name):
        for l in open(os.path.join(dest, ".claude/.onion-version"), encoding="utf-8"):
            if l.startswith(name + ":"):
                return re.sub(r"\s*#.*$", "", l.split(":", 1)[1]).strip()
        return ""
    smode = sfield("mode") or m.group("mode")
    srole = sfield("role") or m.group("role")
    sib = sfield("integration_branch") or m.group("ib")
    blk[li] = (f'    label: "Framework instalado: pin `{pin}` (update de {today}, com o kg-ssot {kv} e o contrato v{cv}), '
               f'modo `{smode}`, papel `{srole}`, integração `{sib}`."')
    adopt = nm.group("adopt")
    hist = [h for h in re.findall(r"`([0-9a-f]{7,40})`", nm.group("list")) if not same(h, pin)]
    if cur and not same(cur, pin) and not same(cur, adopt) and not any(same(cur, h) for h in hist):
        hist.insert(0, cur)
    blk[ni] = (f'    narrative: "{nm.group("head")}' + ", ".join(f"`{h}`" for h in hist)
               + f'; a adoção foi `{adopt}`.{nm.group("rest")}"')
    # a provenance passa a dizer o carimbo NOVO; sem @<commit> do adotante, que ainda não existe quando o motor roda
    prov = {"source": '".claude/.onion-version"',
            "locator": f'"campos source_commit, role, mode e integration_branch; a versão da kg-ssot em vendor/kg-ssot/.kg-ssot-version e o CONTRACT_VERSION em vendor/kg-ssot/tools/kg_validate.py, lidos no update de {today} para o pin {pin}"',
            "method": '"reading: carimbo e vendor/kg-ssot lidos pelo escritor do carimbo no update"'}
    pi = field("provenance")
    if pi is None:
        blk.append("    provenance:"); pi = len(blk) - 1
    k = pi + 1
    while k < len(blk) and blk[k].startswith("      "):
        key = blk[k].strip().split(":", 1)[0]
        if key in prov:
            blk[k] = f"      {key}: {prov.pop(key)}"
        k += 1
    for key in ("source", "locator", "method"):
        if key in prov:
            blk.insert(k, f"      {key}: {prov.pop(key)}"); k += 1
    rebuilt = True
elif li is not None and not label_ok and STALE_MARK.search(blk[li]):
    refuse(f"o label editado traz '{STALE_MARK.search(blk[li]).group(0)}', um dado do update que o motor não sabe refazer fora do molde")
if rebuilt:
    pass  # o molde de update já foi refeito inteiro acima
elif label_ok:
    blk[li] = LABEL_PIN.sub(f"pin `{pin}`", blk[li], count=1)
elif li is not None and cur and len(cur) >= 7:
    # o pin antigo como TOKEN exato (nem prefixo nem pedaço de outro hex): só ele muda, a frase do dono fica
    # e só quando ele aparece UMA vez: citado duas ou mais (histórico "X -> Y, agora X"), qual é o atual é
    # leitura da frase do dono, não do motor; aí cala como antes (rc 3, passada adversarial de 2026-10-27)
    _tok = re.compile(r"(?<![0-9A-Za-z])" + re.escape(cur) + r"(?![0-9A-Za-z])")
    if len(_tok.findall(blk[li])) == 1:
        blk[li], label_swapped = _tok.subn(pin, blk[li])
    if not label_swapped:
        rc = 3
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
# verificou mais. Esses dois campos descrevem a verificação ATUAL, então o pin antigo vira o novo neles; a
# narrative guarda a HISTÓRIA e fica como o dono escreveu (o label troca só o token do pin, acima). Só troca o pin que ESTAVA no nó (cur):
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
      + (" (molde de update: label, lista de pins anteriores e provenance refeitos do carimbo e do vendor/kg-ssot)" if rebuilt
         else "" if label_ok else f" (label editado pelo dono: {label_swapped} citação(ões) do pin antigo {cur} trocada(s) pelo novo, o resto intacto)" if label_swapped
         else " (só o x_pin: o label foi editado pelo dono, não cita o pin antigo como token único, e ficou intacto — confira-o)")
      + (f"; {swapped} citação(ões) do pin antigo em verified_against/provenance trocada(s) pelo novo" if swapped else ""))
sys.exit(rc)
PY
