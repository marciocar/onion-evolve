---
title: "Revisão — correção do carimbo: o veto ao vivo veio APÓS /exit + --resume (hooks exigem reiniciar)"
date: 2026-09-02
branch: fix/kg-premodelswitch-restart-correction
reviewer: "condutor corrigido pelo maestro (\"eu saí com /exit e depois entrei com claude --resume\"); evidência: id de sessão nos paths de tarefa mudou a331b306 → d7888077; radar --integrity --schema exit 0 (34/34)"
reviewed_diff_sha256: aae8473b5f126d4aa86f001c6b0b449c3f7b478e112bbf9c0e23206bcd028427
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 8000
duration_min: 4
---

# Resíduo — REGRA 56

## Achados

1. **Inferência vendida como medição**: escrevi "sem reiniciar — settings.json recarregado na sessão" no
   `verified_against` do nó e no resíduo do #771, sem checar o id de sessão/PID. O maestro reiniciou
   (`/exit` + `--resume`). Corrigido no carimbo do nó (texto do `verified_against`; status `done`
   permanece — o veto foi observado de fato) e anexada nota de correção ao resíduo do #771 (histórico
   preservado). Lição gravada na memória: id de sessão/PID é a medição de "mesma sessão".

## Não mudou

- Status/plane/impact do nó; grafo no teto (34/34), sem nó novo.
