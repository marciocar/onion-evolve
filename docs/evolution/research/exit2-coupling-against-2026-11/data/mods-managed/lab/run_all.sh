#!/usr/bin/env bash
# run_all.sh: as repeticoes em rodizio, uma sessao por vez. Respeita a carga e para no gate.
set -u -o pipefail
B="$(cd "$(dirname "$0")/.."; pwd)"
LOG="$B/run_all.log"
# A espera de carga é a peça única do core (ops/load-lease.sh), com a régua da máquina (ocupado em 15,
# retoma abaixo de 12). Até 2026-11-06 este lab esperava por 16 por conta própria e, no teto de 600 s,
# seguia calado. Agora o teto estourado PARA a rodada e diz o load no log.
LEASE="$(git -C "$B" rev-parse --show-toplevel 2>/dev/null)/ops/load-lease.sh"
wait_load() {
  [ -f "$LEASE" ] || { echo "PARADO: lease de carga ausente ($LEASE)" >> "$LOG"; exit 6; }
  ONION_LOAD_LEASE_WHO=lab-run_all bash "$LEASE" wait --max 1800 2>> "$LOG" || { echo "PARADO: carga (load-lease rc=$?)" >> "$LOG"; exit 6; }
}
disk_ok() { [ "$(df --output=avail -BG "$B" | tail -1 | tr -dc 0-9)" -ge 20 ]; }
gate() { # gate <celula> <veredito esperado>: confere as 3 repeticoes
  python3 -I - "$B" "$1" "$2" <<'PY'
import json, subprocess, sys
b, c, want = sys.argv[1:4]
ok = 0
for r in (1, 2, 3):
    o = subprocess.run(["python3", "-I", b + "/lab/analyze.py", b + "/runs", f"{c}-{r}"], capture_output=True, text=True).stdout
    j = json.loads(o); ch = j["chamadas"]
    ok += all((ch.get(t) or {}).get("v") == want for t in ("Read", "Bash"))
print(ok)
sys.exit(0 if ok == 3 else 1)
PY
}
for r in 1 2 3; do
  for c in K0 K1; do wait_load; disk_ok || { echo "PARADO: disco" >> "$LOG"; exit 4; }; bash "$B/lab/run_cell.sh" "$c" "$r" >> "$LOG" 2>&1; done
done
gate K0 BARROU >> "$LOG" || { echo "PARADO: gate K0" >> "$LOG"; exit 5; }
gate K1 VENCEU >> "$LOG" || { echo "PARADO: gate K1" >> "$LOG"; exit 5; }
echo "GATE VERDE" >> "$LOG"
CELLS="$(python3 -I "$B/lab/cells.py" order | sed 's/\bK0\b//; s/\bK1\b//')"
for r in 1 2 3; do
  for c in $CELLS; do wait_load; disk_ok || { echo "PARADO: disco" >> "$LOG"; exit 4; }; bash "$B/lab/run_cell.sh" "$c" "$r" >> "$LOG" 2>&1; done
done
echo "FIM $(date -Is)" >> "$LOG"
