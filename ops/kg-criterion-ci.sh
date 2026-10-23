#!/usr/bin/env bash
# ops/kg-criterion-ci.sh — o critério pré-registrado (contrato v4.12, kg-ssot 4.21.0) conferido por HASH.
#
# Por que existe (2026-10-23): o leitor do contrato (kg_validate, e o gate em cima dele) acusa citação a critério
# inexistente, sha citado divergente e medição post-hoc, mas NÃO calcula hash nenhum. Um critério editado NO LUGAR
# (o texto ou o arquivo do ref mudou e o x_criterion.sha256 ficou velho) só é pego pelo
# `kg_criterion.py check`, que recalcula o sha256 de cada versão contra o text ou o arquivo. Sem esta chamada, a
# régua de um pré-registro podia ser trocada depois de ver o dado sem nenhuma guarda reprovar
# (D_CRITERIO_PRE_REGISTRADO_NO_CONTRATO_KG_SSOT_1023). O ops/kg-gate-ci.sh a chama depois do gate, então ela vale
# no CI e no pr-finalize.
#
# Decide pelo rc E pelo JSON (`--format json`), nunca pela prosa: o vendor fala inglês ou pt-BR conforme o locale.
#
# Uso : bash ops/kg-criterion-ci.sh            (da raiz do repo que se quer julgar)
#   rc 0 = nenhum achado e nada ilegível · rc 1 = critério com achado (impresso) · rc 2 = não deu para julgar
set -uo pipefail

[ -f vendor/kg-ssot/tools/kg_criterion.py ] || { echo "kg-criterion-ci: vendor/kg-ssot/tools/kg_criterion.py ausente em $(pwd) — não dá para julgar" >&2; exit 2; }

out="$(python3 -I -B vendor/kg-ssot/tools/kg_criterion.py check --root . --format json)"; rc=$?
[ "$rc" -le 1 ] || { echo "kg-criterion-ci: kg_criterion.py check saiu rc=${rc} — não julgou" >&2; exit 2; }

# fail-closed: JSON ilegível, schema inesperado ou chave ausente nunca vira verde
verdict="$(printf '%s' "$out" | python3 -I -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception as e:
    print("ERRO json ilegível: %s" % e); sys.exit(2)
if d.get("schema_version") != "kg-ssot.criterion/1" or not isinstance(d.get("findings"), list) or not isinstance(d.get("unreadable"), list):
    print("ERRO forma inesperada: schema_version=%r" % d.get("schema_version")); sys.exit(2)
for f in d["findings"]:
    print("  ✗ %s %s#%s — %s" % (f.get("code"), f.get("file"), f.get("id"), f.get("detail")))
for u in d["unreadable"]:
    print("  ✗ ilegível: %s" % (u if isinstance(u, str) else json.dumps(u, ensure_ascii=False)))
print("criterios=%s achados=%d ilegiveis=%d" % (d.get("criteria"), len(d["findings"]), len(d["unreadable"])))
sys.exit(1 if d["findings"] or d["unreadable"] else 0)
')"; vrc=$?
printf '%s\n' "$verdict"
[ "$vrc" -eq 2 ] && exit 2
# o rc do vendor e o do JSON têm de concordar; discordância é entrada quebrada, nunca verde
[ "$vrc" -eq "$rc" ] || { echo "kg-criterion-ci: rc do check (${rc}) e o JSON (${vrc}) discordam — não julgou" >&2; exit 2; }
[ "$vrc" -eq 0 ] && echo "✓ critério pré-registrado: hash de cada versão confere" || echo "✗ critério pré-registrado: há versão cujo hash não confere com o text ou o arquivo" >&2
exit "$vrc"
