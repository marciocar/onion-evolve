#!/usr/bin/env bash
# review-ledger.sh — o que as 262 rodadas de revisão adversarial CUSTARAM e DEVOLVERAM.
#
# Uso: bash .claude/validation/review-ledger.sh [--tsv|--resumo|--json] [--dir <path>]
#   0 = leu · 2 = uso inválido, diretório ausente ou ZERO resíduos (nunca "0 achados" por vacuidade)
#
# POR QUE EXISTE (medido 2026-09-08)
#   A REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial) obriga cada PR a deixar um
#   resíduo com `findings_total · findings_real · tokens · duration_min · verdict`, amarrado ao
#   diff por sha256. Conferido: 262 de 262 arquivos têm os seis campos. **E nada os lia.**
#
#   O dado do custo/retorno da IA nesta casa já existia por inteiro, espalhado em 262 arquivos, há
#   meses — faltava somar. Uma amostra: 6 achados reais por 1,9 M tokens = 317k tokens POR ACHADO.
#   Esse número nunca tinha sido calculado, e é a régua que o maestro pediu.
#
# ⚠️ O QUE ESTE LEITOR NÃO FAZ, e a fronteira é a mesma que a REGRA 56 declara de si:
#   · não julga a QUALIDADE do achado — `findings_real` é auto-declarado por quem revisou;
#   · não atribui achado a gate. Quem pegou o quê exige um campo que ainda não existe, e
#     atribuir retroativamente por grep ("o resíduo cita REGRA nn") é a heurística de nome que
#     já matou uma guarda desta casa com 8 falsos positivos. Forward-only ou nada.
#   · não dispara IA nenhuma. Uma rodada custa ~1,9 M tokens; um medidor que roda o medido é
#     mais caro que o defeito que mede.
set -uo pipefail
DIR="docs/evolution/review"; MODE="--resumo"
while [ $# -gt 0 ]; do
  case "$1" in
    --tsv|--resumo|--json) MODE="$1" ;;
    --dir) shift; DIR="${1:-}" ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "review-ledger: argumento desconhecido '$1'" >&2; exit 2 ;;
  esac
  shift
done
[ -d "${DIR}" ] || { echo "review-ledger: diretório ausente: ${DIR} — NÃO MEDIDO" >&2; exit 2; }

python3 - "${DIR}" "${MODE}" <<'PY'
import sys, os, re, json

d, mode = sys.argv[1], sys.argv[2]
arqs = sorted(f for f in os.listdir(d) if f.endswith(".md") and f != "README.md")
if not arqs:
    print(f"review-ledger: ZERO resíduos em {d} — isso é NÃO MEDIDO, não 'nenhum achado'",
          file=sys.stderr)
    sys.exit(2)

CAMPOS = ("date", "branch", "verdict", "findings_total", "findings_real",
          "findings_fixed", "tokens", "duration_min", "reviewed_diff_sha256")
linhas, incompletos = [], []
for a in arqs:
    txt = open(os.path.join(d, a), encoding="utf-8", errors="replace").read()
    m = re.match(r"^---\n(.*?)\n---", txt, re.S)
    fm = m.group(1) if m else ""
    reg = {"arquivo": a}
    for c in CAMPOS:
        mm = re.search(rf'^{c}:\s*"?([^"\n]*)"?\s*$', fm, re.M)
        reg[c] = (mm.group(1).strip() if mm else "")
    # ⚠️ campo AUSENTE é contado e NOMEADO — jamais preenchido com zero. Zero e "não declarado"
    #    são coisas diferentes, e confundi-los é o defeito que este projeto persegue.
    faltando = [c for c in ("findings_total", "findings_real", "tokens", "duration_min", "verdict")
                if not reg[c]]
    if faltando:
        incompletos.append((a, faltando))
    linhas.append(reg)

def num(v):
    try: return int(float(v))
    except Exception: return None

if mode == "--tsv":
    print("\t".join(CAMPOS))
    for r in linhas:
        print("\t".join(r[c] if r[c] else "—" for c in CAMPOS))
    sys.exit(0)

if mode == "--json":
    print(json.dumps({"residuos": linhas, "incompletos": incompletos}, ensure_ascii=False, indent=2))
    sys.exit(0)

tot = len(linhas)
# ⚠️ TRÊS ESTADOS, e a 1ª versão deste script tinha DOIS — o defeito que ele existe para caçar,
#    cometido por ele mesmo. Ela dizia "incompletos: 0" e usava 170 de 262: os 92 com `tokens: 0`
#    caíam num `if num(...)` falsy e sumiam SEM APARECER. Campo AUSENTE, campo ZERO e campo com
#    valor são coisas distintas: zero pode ser rodada sem custo de IA (revisão humana), e tratá-lo
#    como ausente inventa uma média sobre uma população que não é a declarada.
com = [r for r in linhas if (num(r["tokens"]) or 0) > 0 and num(r["findings_real"]) is not None]
zerados = [r for r in linhas if num(r["tokens"]) == 0]
tk = sum(num(r["tokens"]) for r in com)
mi = sum(num(r["duration_min"]) or 0 for r in com)
fr = sum(num(r["findings_real"]) for r in com)
ft = sum(num(r["findings_total"]) or 0 for r in com)
fx = sum(num(r["findings_fixed"]) or 0 for r in linhas if num(r["findings_fixed"]))
ver = {}
for r in linhas:
    ver[r["verdict"] or "(não declarado)"] = ver.get(r["verdict"] or "(não declarado)", 0) + 1

print(f"═══ LEDGER DA REVISÃO ADVERSARIAL — {tot} resíduo(s) em {d}\n")
print(f"  com tokens > 0 (entram na média)       {len(com):>7}")
print(f"  com `tokens: 0` declarado              {len(zerados):>7}   ← NÃO é ausência: é custo zero declarado")
print(f"  com campo AUSENTE                      {len(incompletos):>7}")
if len(com) + len(zerados) + len(incompletos) != tot:
    print(f"  ⚠ a partição não fecha: {len(com)}+{len(zerados)}+{len(incompletos)} ≠ {tot}")
# ⚠️ Os achados abaixo são a soma sobre os {len(com)} com tokens>0 — NÃO sobre os 262. Omitir a
#    população é o modo mais fácil de um número honesto virar afirmação falsa.
print(f"\n  ── sobre os {len(com)} resíduos com tokens > 0 (não sobre os {tot})")
print(f"  achados totais                         {ft:>7}")
print(f"  achados REAIS                          {fr:>7}"
      + (f"   ({100*fr/ft:.0f}% do total — a precisão da rodada)" if ft else ""))
print(f"  achados corrigidos (quando declarado)  {fx:>7}")
print(f"\n  tokens                            {tk:>12,}".replace(",", "."))
print(f"  minutos                           {mi:>12,}".replace(",", "."))
frz = sum(num(r["findings_real"]) or 0 for r in zerados)
print(f"\n  ── os {len(zerados)} de custo ZERO declarado renderam {frz} achado(s) real(is)")
print(f"     contados aqui para que não sumam; fora da média porque divisão por zero não é média")
if fr:
    print(f"\n  ── A RÉGUA QUE FALTAVA")
    print(f"  tokens por achado REAL            {tk//fr:>12,}".replace(",", "."))
    print(f"  minutos por achado REAL           {mi/fr:>12.1f}")
# O campo `verdict` é TEXTO LIVRE, e a dispersão é o achado: agrupar por família em vez de
# despejar 70 linhas. A dispersão em si vai declarada — é ela que impede qualquer série.
fam = {}
for k, v in ver.items():
    raiz = re.split(r"[-_ ]", k.upper(), 1)[0] or "(vazio)"
    fam[raiz] = fam.get(raiz, 0) + v
print(f"\n  veredito por família: " + " · ".join(f"{k}={v}" for k, v in sorted(fam.items(), key=lambda x: -x[1])))
print(f"  ⚠ {len(ver)} formas DISTINTAS de veredito em {tot} resíduos — o campo é texto livre e")
print(f"    não sustenta série. Padronizá-lo é decisão do maestro, não deste leitor.")
if incompletos:
    print(f"\n  ⚠ resíduos com campo ausente (não entram na conta, e por isso aparecem):")
    for a, f in incompletos[:8]:
        print(f"     {a[:52]:<52} falta: {','.join(f)}")
PY
