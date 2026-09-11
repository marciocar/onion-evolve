#!/usr/bin/env bash
# review-ledger.sh — o que as 262 rodadas de revisão adversarial CUSTARAM e DEVOLVERAM.
#
# Uso: bash .claude/validation/review-ledger.sh [--tsv|--resumo|--json|--env] [--dir <path>]
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
    --tsv|--resumo|--json|--env) MODE="$1" ;;
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

# `--env` reusa TODO o cálculo do modo humano e só troca a apresentação. A saída humana é uma
# sequência longa de prints; silenciá-la por REDIRECIONAMENTO é preferível a passar um flag por
# quarenta chamadas — menos sítios para uma delas escapar e vazar prosa no meio do KEY=VALUE.
_stdout_real = None
if mode == "--env":
    import io
    _stdout_real, sys.stdout = sys.stdout, io.StringIO()

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
# ── AS DUAS ERAS DO `verdict:` ────────────────────────────────────────────────────────────
# Em 2026-09-08 o maestro selou o vocabulário FECHADO, e a guarda entrou em
# `review-artifact-check.sh` julgando só o resíduo do PR corrente. Logo os 262 anteriores NÃO
# se reescrevem (histórico não se reescreve nesta casa) e a série passa a ter duas eras.
#
# ESTE LEITOR IMPRIME AS DUAS, e a de LEGADO nunca desaparece do relatório: uma métrica que
# some quando fica inconveniente é a mesma classe do painel inventado que esta onda apagou.
# O que muda com o tempo é a proporção — e é isso que se acompanha.
ENUM = ("APROVADO", "CORRIGIDO", "REPROVADO", "REPROVADO_E_CURADO", "SEM_ACHADOS")
def _canon(k):
    """Caixa e separador normalizam; a PALAVRA não. `REPROVADO-E-CURADO` e
    `REPROVADO_E_CURADO` são o mesmo veredito escrito em duas épocas — tratá-los como
    formas distintas inflaria a dispersão com um defeito que não existe. Já
    `CORRIGIDO-E-RE-REVISADO` normaliza para algo que NÃO está no enum, e continua legado."""
    return k.upper().replace("-", "_")

canon, legado = {}, {}
for k, v in ver.items():
    alvo = canon if _canon(k) in ENUM else legado
    alvo[_canon(k)] = alvo.get(_canon(k), 0) + v
n_canon, n_legado = sum(canon.values()), sum(legado.values())

print(f"\n  ── VOCABULÁRIO DO VEREDITO (fechado em 2026-09-08)")
print(f"  no vocabulário            {n_canon:>4}   " +
      (" · ".join(f"{k}={v}" for k, v in sorted(canon.items(), key=lambda x: -x[1])) or "—"))
print(f"  LEGADO (texto livre)      {n_legado:>4}   {len(legado)} formas distintas, anteriores ao selo")
if n_canon:
    print(f"  cobertura do enum         {100*n_canon//tot:>3}%   sobe sozinha: só resíduo NOVO é julgado")
else:
    print(f"  cobertura do enum        ⊘ NÃO MEDIDO — nenhum resíduo pós-selo ainda")

# A dispersão do LEGADO continua declarada: é ela que justificou o selo, e apagá-la seria
# apagar a evidência da própria decisão.
fam = {}
for k, v in legado.items():
    raiz = re.split(r"[-_ ]", k.upper(), 1)[0] or "(vazio)"
    fam[raiz] = fam.get(raiz, 0) + v
if fam:
    print(f"\n  legado por família: " + " · ".join(f"{k}={v}" for k, v in sorted(fam.items(), key=lambda x: -x[1])))
    print(f"  ⚠ {len(legado)} formas DISTINTAS no legado — a evidência que motivou fechar o vocabulário.")
    print(f"    Não se reescreve: a série começa no 1º resíduo pós-selo.")
if incompletos:
    print(f"\n  ⚠ resíduos com campo ausente (não entram na conta, e por isso aparecem):")
    for a, f in incompletos[:8]:
        print(f"     {a[:52]:<52} falta: {','.join(f)}")

if mode == "--env":
    # KEY=VALUE para o PAINEL. Existe pelo mesmo motivo do `rules-registry --counts`: a
    # alternativa era o painel reparsear a saída HUMANA deste script — texto alinhado, com
    # acento e ⊘. Segundo parser sobre a mesma população é a divergência que esta onda cura.
    #
    # ⚠️ `PRECISAO_PCT` usa `{100*fr/ft:.0f}` — a MESMA expressão da linha humana, de propósito.
    # A 1ª versão usava `//` (piso) e imprimia 82 enquanto o modo humano imprimia 83, sobre os
    # mesmos 1099/1331. Dois números para o mesmo fato, no mesmo arquivo, separados por uma
    # barra: é a classe inteira desta onda, cometida em dez linhas de código.
    sys.stdout = _stdout_real
    print(f"R56_RESIDUOS={tot}")
    # ⚠️ CONTA A POPULAÇÃO QUE O NOME DIZ. A 1ª versão era `len(linhas) - len(zerados)` — total
    # menos os de custo zero —, e nessa conta um resíduo com o campo AUSENTE entraria como "com
    # tokens". Hoje os ausentes são 0 e os dois números coincidem, mas o campo prometia o que a
    # conta não garantia: bastaria um resíduo sem o campo para o painel dizer que a média cobre
    # um resíduo que ela não cobre. [[duas-grandezas-contadas-como-uma]]
    print(f"R56_COM_TOKENS={sum(1 for r in linhas if (num(r['tokens']) or 0) > 0)}")
    print(f"R56_ACHADOS={ft}")
    print(f"R56_ACHADOS_REAIS={fr}")
    print(f"R56_PRECISAO_PCT={format(100*fr/ft, '.0f') if ft else 0}")
    print(f"R56_TOKENS={tk}")
    print(f"R56_MINUTOS={mi}")
    print(f"R56_TOKENS_POR_ACHADO_REAL={(tk//fr) if fr else 0}")
    print(f"R56_VOCAB_OK={n_canon}")
    print(f"R56_VOCAB_LEGADO={n_legado}")
    sys.exit(0)
PY
