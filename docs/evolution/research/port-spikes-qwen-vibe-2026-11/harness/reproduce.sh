#!/usr/bin/env bash
# reproduce.sh — reproduz o julgamento dos spikes a partir SÓ dos arquivos de evidence-archive/.
#
# Uso: reproduce.sh [--keep]
#
# 1. confere o SHA256SUMS dos .tar.gz;
# 2. extrai os lotes (m1, m2, p5, real1, real2, fixtures) para um diretório temporário, e o
#    superseded à parte (só para conferir a integridade; o agregador ignora _superseded);
# 3. confere cada verdict.json extraído contra o sha256 do MANIFEST.tsv;
# 4. roda classify.py em cada célula (informativo: lista onde o veredito recalculado difere
#    do gravado — o gravado é o da coleta/reclassificação, ver sha256.txt de cada célula);
# 5. roda aggregate.py sobre o MESMO conjunto de células de cada agregado de referência
#    (o conjunto vem do próprio agregado). aggregate-final.json: compara o JSON inteiro, menos
#    o campo "evidence" (caminho). aggregate-m2.json: compara por inteiro cada família do lote
#    m2 (o arquivo foi gravado com RS0-qwen-c-real2 ainda rodando; a família real2 dele é um
#    retrato no meio da execução e sai como informação).
# rc 0 se os dois agregados baterem e a integridade conferir; 1 senão.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARC="$HERE/evidence-archive"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/onion-spike-reproduce.XXXXXX")"
if [ "${1:-}" = "--keep" ]; then echo "keeping $TMP"; else trap 'chmod -R u+w "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT; fi

( cd "$ARC" && sha256sum -c --quiet SHA256SUMS ) || { echo "FAIL: SHA256SUMS of the archives"; exit 1; }
echo "ok   archives match SHA256SUMS"

mkdir -p "$TMP/evidence" "$TMP/superseded"
for lot in m1 m2 p5 real1 real2 fixtures; do
  tar -xzf "$ARC/evidence-$lot.tar.gz" -C "$TMP/evidence" || { echo "FAIL: extract $lot"; exit 1; }
done
tar -xzf "$ARC/evidence-superseded.tar.gz" -C "$TMP/superseded" || { echo "FAIL: extract superseded"; exit 1; }
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
    root = tmp / ("superseded" if lot == "superseded" else "evidence")
    p = root / cell / "verdict.json"
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
for ref in ("aggregate-m2.json", "aggregate-final.json"):
    want = json.loads((here / ref).read_text())
    ids = sorted({c for f in want["families"] for c in f["attempts"] + f.get("ignored_beyond_max", [])}
                 | {c["cell_id"] for c in want.get("cells_without_meta", [])})
    out = subprocess.run([sys.executable, "-I", str(here / "aggregate.py"), str(ev), "--cells", ",".join(ids)],
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
sys.exit(rc)
PY
RC=$?
echo "reproduce rc=$RC"
exit $RC
