---
branch: docs/round-elenxo-cured
pr: 611
date: 2026-08-15
reviewed_diff_sha256: 92088f657da5ca5dbb5bff356d7215452c21e8e2d7ddcb56d800425a69e247a2
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 2
verdict: CONFORME
reviewer: carimbo docs-only (1 nó de evidência); a revisão substantiva É o próprio Elenxo que este nó registra — 16 achados, 8 refutados com medição, ALTOs curados e provados vivos no bridge
REVISOU: true
---

# Resíduo — `docs/round-elenxo-cured`

Um nó de evidência (`E_ELENXO_ROUND_CURADO`) + 1 aresta no KG do bridge. Registra o
Elenxo adversarial da rodada convite/cadastro/perfil: 16 achados, 8 refutados com
medição contra o swagger vivo do tenant, ALTO 1/2/3 + MÉDIOs + BAIXOs curados no
bridge `867f95de`. O achado que valeu a passada — o PAT do admin herdava
`bridge:admin` e rodava o chat em `bypassPermissions` sem deny — contido na raiz
(scope fora do exchange). Provas vivas 5/5. Radar exit 0 (42 nós, 48 arestas).
