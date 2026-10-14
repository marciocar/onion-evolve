---
branch: chore/registry-pins-2026-10-14
date: 2026-10-14
reviewed_diff_sha256: 60645b0d81378d61d2728324952185da2e8265a441315afede90d4b8df27fff8
reviewed_code_sha256: 7b48d0e3c8225dce4db0876e16d8248a88d7be9c86cae9fec9185cddc0fa97f9
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 5
verdict: APROVADO
reviewer: passada adversarial própria; cada pin lido do REMOTO pelos carimbadores (door-seal-pin.sh e registry-pins.sh --seal), nunca digitado
---

# Pins do registro: as 4 portas na onion-v1.2.0 e o brain-granaai no update de hoje

- onion-core, onion-standalone, onion-plugins e onion-mini → 6e6deab1c443 (release onion-v1.2.0, publicada e conferida no remoto).
- brain-granaai → 0d0636f4ca74 (o update mergeado no #1578 de lá, lido da onion/develop remota).

Nenhum valor foi escrito à mão: os dois carimbadores leem o carimbo publicado e só gravam o que leram.
