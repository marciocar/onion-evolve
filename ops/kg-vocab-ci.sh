#!/usr/bin/env bash
# ops/kg-vocab-ci.sh — o lint de NOMES da kg-ssot (kg_vocab.py lint, contrato v4.14) com catraca, no core.
#
# Por que existe (2026-10-23): o maestro decidiu que código aprovado (rodada, réplica, nível, achado) nasce com
# nome canônico legível (D_NOMES_CANONICOS_NASCEM_CERTOS_1023), na forma id curto + termo x_term
# (D_NOMES_FORMA_ID_CURTO_MAIS_X_TERM_1023), e que o core faz a sua parte (D_NOMES_NASCEM_CERTOS_NAS_TRES_CAMADAS_1023).
# Medido no dia: 2194 códigos na prosa dos grafos, 301 distintos, nenhum com termo. A catraca deixa o legado
# passar e reprova o código NOVO sem nome: quem escreve r18 sem o termo da rodada 18 reprova.
#
# Os três arquivos versionados, num lugar só (.kg-ssot/):
#   vocab-lint.json           a base (contagem por achado, arquivo e código), gravada com as externas abaixo
#   vocab-externals.tsv       os sistemas de código de fora (SOC2, JOSE…), medidos; viram --external
#   vocab-externals.sha256    o sha256 da TSV com que a base foi gravada: alargar as externas sem regravar a
#                             base sai rc 2, porque uma externa larga ZERA o lint sem nenhum achado aparecer
#                             (achado da passada adversarial de 2026-10-23: uma linha `[A-Za-z]{1,3}[0-9]{1,3}`
#                             mandava 2194 códigos para "externos" e deixava rc 0)
# TETO DECLARADO (medido na passada adversarial de 2026-10-23): a resolução é por NOTATION, e o código que existe
# em UM esquema só resolve para aquele sentido mesmo num texto de outro — "o caso r14 da bancada" resolve como
# rodada do radar enquanto a bancada não tiver o termo r14. O lint pega o código SEM nome e o AMBÍGUO; o sentido
# errado com nome único ele não pega. A cura é nomear o sentido que falta (ou escrever esquema:código), e o hook
# da glosa é a segunda rede, porque lá o DOMÍNIO do bloco decide.
#
# E uma externa NÃO PODE ENGOLIR CÓDIGO DA CASA: cada regex é provada contra uma sonda de códigos nossos
# (r13, N2, A7, F2, D10, E3, I3, NS1) e, se casar algum, o lint sai rc 2 em vez de resolver calado.
# O ops/kg-gate-ci.sh chama este depois do gate, então ele vale no CI e no pr-finalize.
#
# Decide pelo rc E pelo JSON (`--format json`), nunca pela prosa: o vendor fala inglês ou pt-BR conforme o locale.
# O reclassificado (o mesmo código do legado que passou de "sem termo" a "ambíguo" porque o primeiro termo nasceu)
# não reprova: quem nomeia não paga pelo legado.
#
# Uso : bash ops/kg-vocab-ci.sh            julga (da raiz do repo)
#       bash ops/kg-vocab-ci.sh --update   regrava a base (só no PR que nomeia ou que muda as externas)
#   rc 0 = nenhum achado novo e nada ilegível · rc 1 = achado novo (impresso) · rc 2 = não deu para julgar
set -uo pipefail

V=vendor/kg-ssot/tools/kg_vocab.py
BASE=.kg-ssot/vocab-lint.json
EXT=.kg-ssot/vocab-externals.tsv
[ -f "$V" ] || { echo "kg-vocab-ci: $V ausente em $(pwd) — não dá para julgar" >&2; exit 2; }
[ -f "$EXT" ] || { echo "kg-vocab-ci: $EXT ausente — sem as externas a base mede outra coisa" >&2; exit 2; }

SHA=.kg-ssot/vocab-externals.sha256
PROBE="r13 N2 A7 F2 D10 E3 I3 NS1 Q7 S9"   # códigos DA CASA: nenhuma externa pode casá-los

args=(lint --root . --baseline "$BASE" --format json
      --exclude 'docs/evolution/kg-inbox/_rejected/*' --exclude 'docs/evolution/kg-inbox/_sealed/*')
while IFS=$'\t' read -r scheme rx rest; do
  case "$scheme" in ''|'#'*) continue ;; esac
  { [ -n "$rx" ] && [ -z "${rest:-}" ]; } || { echo "kg-vocab-ci: $EXT: linha malformada para '$scheme' (esquema TAB regex)" >&2; exit 2; }
  python3 -I -c '
import re, sys
try:
    rx = re.compile(sys.argv[2])
except re.error as e:
    sys.exit("kg-vocab-ci: %s: regex inválida (%s)" % (sys.argv[1], e))
hit = [c for c in sys.argv[3].split() if rx.fullmatch(c)]
if hit:
    sys.exit("kg-vocab-ci: a externa %s engole código DA CASA (%s) — ela resolveria a nossa sigla calada; "
             "aperte a regex" % (sys.argv[1], ", ".join(hit)))
' "$scheme" "$rx" "$PROBE" || exit 2
  args+=(--external "${scheme}=${rx}")
done < "$EXT"
update=0
case "${1:-}" in
  --update) update=1; args+=(--update) ;;
  '') ;;
  *) echo "kg-vocab-ci: argumento desconhecido: $1" >&2; exit 2 ;;
esac
[ "$update" -eq 1 ] || [ -f "$BASE" ] || { echo "kg-vocab-ci: $BASE ausente — grave com --update (sem base tudo seria novo)" >&2; exit 2; }

# a catraca das externas: a base só vale para a TSV com que foi gravada
ext_sha="$(python3 -I -c '
import hashlib, sys
print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())' "$EXT")" || exit 2
if [ "$update" -eq 1 ]; then
  printf '%s\n' "${ext_sha}" > "$SHA" || exit 2
else
  [ -f "$SHA" ] || { echo "kg-vocab-ci: $SHA ausente — regrave a base com --update" >&2; exit 2; }
  [ "$(cat "$SHA")" = "${ext_sha}" ] || { echo "kg-vocab-ci: $EXT mudou e a base não — uma externa nova pode resolver código calado; confira a mudança e regrave com 'bash ops/kg-vocab-ci.sh --update'" >&2; exit 2; }
fi

out="$(python3 -I -B "$V" "${args[@]}")"; rc=$?
[ "$rc" -le 1 ] || { echo "kg-vocab-ci: kg_vocab.py lint saiu rc=${rc} — não julgou" >&2; exit 2; }

# fail-closed: JSON ilegível, schema inesperado ou chave ausente nunca vira verde
verdict="$(printf '%s' "$out" | python3 -I -c '
import json, sys
upd = sys.argv[1] == "1"
try:
    d = json.load(sys.stdin)
except Exception as e:
    print("ERRO json ilegível: %s" % e); sys.exit(2)
l = d.get("lint") if isinstance(d, dict) else None
if d.get("schema_version") != "kg-ssot.vocab/1" or not isinstance(l, dict) or not isinstance(d.get("unreadable"), list) \
   or not isinstance(l.get("findings"), list) or not isinstance(l.get("codes"), int):
    print("ERRO forma inesperada: schema_version=%r" % (d.get("schema_version") if isinstance(d, dict) else None)); sys.exit(2)
new, recl = l.get("new"), l.get("reclassified")
if not upd and (not isinstance(new, list) or not isinstance(recl, list)):
    print("ERRO sem new/reclassified: a base não foi lida"); sys.exit(2)
for f in (new or []):
    print("  ✗ %s %s#%s %s %s%s" % (f.get("code"), f.get("file"), f.get("id"), f.get("field"), f.get("token"),
                                    " (%s)" % f["detail"] if f.get("detail") else ""))
for u in d["unreadable"]:
    print("  ✗ ilegível: %s" % (u if isinstance(u, str) else json.dumps(u, ensure_ascii=False)))
if d["unreadable"]:
    print("ILEGIVEL")   # o veredito tem de dizer o que reprovou: grafo ilegível não é "código sem termo"
print("codigos=%d resolvidos=%s externos=%s achados=%d novos=%s reclassificados=%s%s" % (
    l["codes"], l.get("resolved"), l.get("external"), len(l["findings"]),
    "-" if new is None else len(new), "-" if recl is None else len(recl), " base-gravada" if upd else ""))
sys.exit(1 if (new or d["unreadable"]) else 0)
' "$update")"; vrc=$?
printf '%s\n' "$verdict"
[ "$vrc" -eq 2 ] && exit 2
# o rc do vendor e o do JSON têm de concordar; discordância é entrada quebrada, nunca verde
[ "$vrc" -eq "$rc" ] || { echo "kg-vocab-ci: rc do lint (${rc}) e o JSON (${vrc}) discordam — não julgou" >&2; exit 2; }
if [ "$vrc" -eq 0 ]; then echo "✓ nomes: nenhum código novo sem termo na prosa dos grafos"
elif grep -q '^ILEGIVEL$' <<< "$verdict"; then echo "✗ nomes: grafo ILEGÍVEL — o código que mora nele ninguém conferiu" >&2
else echo "✗ nomes: código novo sem termo (ou ambíguo) — dê-lhe um x_term (notation, pref, scheme) ou escreva esquema:código" >&2; fi
exit "$vrc"
