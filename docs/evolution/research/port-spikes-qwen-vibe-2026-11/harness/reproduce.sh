#!/usr/bin/env bash
# reproduce.sh — reproduz o julgamento dos spikes a partir SÓ dos arquivos de evidence-archive/.
#
# Uso: reproduce.sh [--keep]
#
# 1. confere o SHA256SUMS dos .tar.gz;
# 2. extrai os lotes (m1, m2, p5, real1, real2, fixtures e, da rodada 2, r2 e r2cal) para um diretório
#    temporário, e o superseded e o r2-superseded à parte (só para conferir a integridade; o
#    agregador ignora _superseded);
# 3. confere cada verdict.json extraído contra o sha256 do MANIFEST.tsv;
# 4. roda classify.py em cada célula (informativo: lista onde o veredito recalculado difere
#    do gravado — o gravado é o da coleta/reclassificação, ver sha256.txt de cada célula);
# 5. roda aggregate.py sobre o MESMO conjunto de células de cada agregado de referência
#    (o conjunto vem do próprio agregado). aggregate-final.json: compara o JSON inteiro, menos
#    o campo "evidence" (caminho). aggregate-m2.json: compara por inteiro cada família do lote
#    m2 (o arquivo foi gravado com RS0-qwen-c-real2 ainda rodando; a família real2 dele é um
#    retrato no meio da execução e sai como informação).
#    aggregate-r2.json (rodada 2): roda aggregate.py --batch r2 e compara o JSON inteiro, menos
#    o campo "evidence".
# 6. roda check_parent_rule.py na célula de calibração e nas R2b-S0-V: a regra do filho do Vibe aceita o
#    que o cliente grava de fato.
# 7. roda cmp_classify.py contra harness/reference/classify_r2_lot.py (cópia do classificador de cbc067cc0): é a
#    medida de que depende a isenção da regra do medidor. As células coletadas depois dela ficam de fora.
# 8. no lote r2veto, cobra que o veredito gravado (classificador pré-dado) seja o recalculado.
# rc 0 se os três agregados baterem, a integridade conferir, a regra aceitar os registros reais e o comparador der
# 0 diferenças de veredito; 1 senão.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARC="$HERE/evidence-archive"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/onion-spike-reproduce.XXXXXX")"
if [ "${1:-}" = "--keep" ]; then echo "keeping $TMP"; else trap 'chmod -R u+w "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT; fi

( cd "$ARC" && sha256sum -c --quiet SHA256SUMS ) || { echo "FAIL: SHA256SUMS of the archives"; exit 1; }
echo "ok   archives match SHA256SUMS"

mkdir -p "$TMP/evidence" "$TMP/superseded"
for lot in m1 m2 p5 real1 real2 fixtures r2 r2cal r2veto; do
  tar -xzf "$ARC/evidence-$lot.tar.gz" -C "$TMP/evidence" || { echo "FAIL: extract $lot"; exit 1; }
done
for lot in superseded r2-superseded; do
  tar -xzf "$ARC/evidence-$lot.tar.gz" -C "$TMP/superseded" || { echo "FAIL: extract $lot"; exit 1; }
done
echo "ok   extracted to $TMP"

python3 -I - "$HERE" "$TMP" <<'PY'
import hashlib, json, subprocess, sys
from pathlib import Path
here, tmp = Path(sys.argv[1]), Path(sys.argv[2])
sys.path.insert(0, str(here))
from classify import classify

rc = 0
# 3. integridade contra o MANIFEST
lines = (here / "evidence-archive" / "MANIFEST.tsv").read_text().splitlines()[1:]
bad = []
for l in lines:
    cell, lot, verdict, basis, sha = l.split("\t")
    root = tmp / ("superseded" if lot in ("superseded", "r2-superseded") else "evidence")
    p = root / cell / "verdict.json"
    if sha == "-":
        # célula interrompida ao parar o lote (Emenda R2-9): sem veredito por desenho; confere-se só o diretório
        if not (root / cell).is_dir() or p.exists():
            bad.append(cell)
        continue
    if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest() != sha:
        bad.append(cell)
print(f"{'ok  ' if not bad else 'FAIL'} MANIFEST: {len(lines)} cells, {len(bad)} verdict.json mismatches {bad[:5]}")
rc |= 1 if bad else 0

# 4. classify em cada célula (informativo)
ev = tmp / "evidence"
diff = []
cells = sorted(d for d in ev.iterdir() if d.is_dir() and not d.name.startswith("_"))
for d in cells:
    v = classify(d)
    old = json.loads((d / "verdict.json").read_text())
    if v["verdict"] != old.get("verdict"):
        diff.append((d.name, old.get("verdict"), v["verdict"]))
print(f"info classify: {len(cells)} cells re-classified; {len(diff)} with a different verdict than the stored one {diff[:5]}")

# 5. agregados de referência
for ref in ("aggregate-m2.json", "aggregate-final.json", "aggregate-r2.json"):
    want = json.loads((here / ref).read_text())
    ids = sorted({c for f in want["families"] for c in f["attempts"] + f.get("ignored_beyond_max", [])}
                 | {c["cell_id"] for c in want.get("cells_without_meta", [])})
    # o r2 é agregado por lote (--batch r2), como foi gravado; os da rodada 1, pelo conjunto de células
    sel = ["--batch", "r2"] if ref == "aggregate-r2.json" else ["--cells", ",".join(ids)]
    out = subprocess.run([sys.executable, "-I", str(here / "aggregate.py"), str(ev), *sel],
                         capture_output=True, text=True)
    if out.returncode != 0:
        print(f"FAIL {ref}: aggregate.py rc={out.returncode} {out.stderr[-300:]}")
        rc |= 1
        continue
    got = json.loads(out.stdout)
    got.pop("evidence", None); want.pop("evidence", None)
    if ref == "aggregate-m2.json":
        # O aggregate-m2.json foi gravado com a célula RS0-qwen-c-real2 AINDA RODANDO (lá ela é
        # INCONCLUSIVO/PENDENTE; com a evidência completa é FURA). O critério desse arquivo é o
        # lote m2: compara-se, por inteiro, cada família do lote m2; o resto é informativo.
        key = lambda f: json.dumps(f["family"], sort_keys=True)
        W = {key(f): f for f in want["families"] if f["family"]["batch"] == "m2"}
        G = {key(f): f for f in got["families"] if f["family"]["batch"] == "m2"}
        same = W == G
        print(f"{'ok  ' if same else 'FAIL'} {ref}: lot m2, {len(W)} families compared in full, match={same}")
        other = [json.loads(k) for k in {key(f) for f in want["families"]} | {key(f) for f in got["families"]}
                 if k not in W and next((f for f in want["families"] if key(f) == k), None)
                 != next((f for f in got["families"] if key(f) == k), None)]
        for fam in other:
            print(f"info {ref}: non-m2 family differs (snapshot taken mid-run): {fam}")
    else:
        same = got == want
        print(f"{'ok  ' if same else 'FAIL'} {ref}: {len(ids)} cells, {len(want['families'])} families, match={same}")
        if not same:
            for k in want:
                if got.get(k) != want.get(k):
                    print(f"     differs in '{k}'")
    rc |= 0 if same else 1

# 6. a lista positiva do pai aceita o que o Vibe grava (Emenda R2-10 parte D)
real = sorted(str(d) for d in ev.iterdir() if d.name == "CAL-sub-vibe-r1"
              or d.name.startswith(("R2b-S0-V-r", "R2b-S1-V-r", "R2b-M-V-r")))
out = subprocess.run([sys.executable, "-I", str(here / "check_parent_rule.py"), "--classify-dir", str(here), *real],
                     capture_output=True, text=True)
print(out.stdout.rstrip() or out.stderr[-300:])
print(f"{'ok  ' if out.returncode == 0 and len(real) == 11 else 'FAIL'} parent rule on the real records: {len(real)} cells")
rc |= 0 if out.returncode == 0 and len(real) == 11 else 1

# 7. a isenção da regra do medidor: nenhuma célula muda de veredito contra o classificador que produziu o lote r2
out = subprocess.run([sys.executable, "-I", str(here / "cmp_classify.py"), str(here / "reference" / "classify_r2_lot.py"),
                      str(here / "classify.py"), str(ev), "--manifest", str(here / "evidence-archive" / "MANIFEST.tsv"),
                      "--skip-lots", "r2veto"], capture_output=True, text=True)
print(out.stdout.rstrip() or out.stderr[-300:])
rc |= 1 if out.returncode else 0

# 8. o lote r2veto foi julgado pelo classificador pré-dado: o gravado tem de bater com o recalculado
veto = [l.split("\t") for l in lines if l.split("\t")[1] == "r2veto"]
moved = [c[0] for c in veto if (classify(ev / c[0])["verdict"], classify(ev / c[0])["basis"])
         != (json.loads((ev / c[0] / "verdict.json").read_text())["verdict"], json.loads((ev / c[0] / "verdict.json").read_text())["basis"])]
print(f"{'ok  ' if not moved and len(veto) == 7 else 'FAIL'} lot r2veto: {len(veto)} cells, stored = recalculated, moved {moved}")
rc |= 1 if moved or len(veto) != 7 else 0
sys.exit(rc)
PY
RC=$?
echo "reproduce rc=$RC"
exit $RC
