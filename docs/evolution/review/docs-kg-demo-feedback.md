---
branch: docs/kg-demo-feedback
pr: TBD
date: 2026-08-14
reviewed_diff_sha256: fbd5152eb9c345607d463da13acc846f6c33e5674e4622fada071baa1b8c1fa0
findings_total: 9
findings_real: 9
findings_fixed: 9
tokens: 30000
duration_min: 10
verdict: CORRIGIDO
reviewer: verificação claim→medição (a substância — PR-25 do bridge — foi revisada pela bancada 16/16+38 e pelas curas medidas na demo)
---

# Passada adversarial — `docs/kg-demo-feedback`

Carimbo de 2 nós no KG do programa. A substância é o PR-25 do bridge (`29b946d`, deployado):
8 achados da demo real do maestro + 1 da bancada (cache mtime same-ms), todos com cura
verificada (bench verde: share-selftest 16/16, vitest 38, gzip 259 KiB — folga de 4 bytes,
teto anotado como fio). Conferência claim→medição deste diff:

- Cada achado do label existe em screenshot da demo e tem cura commitada no PR-25 ✓
- "preset claude_code só entrava com append" — lido no código (chat.ts, options.systemPrompt condicional) ✓
- Q novo declara as 3 decisões GATED sem pré-cozinhar (gated-work-derives-fresh) ✓
- Arestas: evidence SUPPORTS o gate do dogfood; question CONSTRAINS a fase (dissent que limita, não derruba) ✓
- Radar exit 0 (28 nós, 32 arestas) ✓
