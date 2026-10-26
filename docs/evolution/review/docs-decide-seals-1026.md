---
branch: docs/decide-seals-1026
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: f156fa75dcb1e7fda7001fcdaff7fbe45ac6539d35da8ef08f8d4498cd1f305b
reviewed_code_sha256: 84df3e19cd23c2366b45ea64256dc2086876fb78b56ee61136eee519db5f2635
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (onion-evolve-d4), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `docs/decide-seals-1026`

## O que muda

Sete selos do maestro pelo `/meta:decide` de 2026-10-26, escritos pelo `kg-decide-seal.sh`:

- `Q_INTELLIGENT_UI_GPT6_NOT_VERIFIED_1021`: verificado por secundária. A primária da OpenAI existe e devolveu 403 à
  leitura; duas secundárias confirmam o conteúdo.
- `Q_MCP_APPS_PILOT_PROPOSAL_1021`: o piloto está servido no bridge (PRs #83 e #86, main servida 5819d8e, sandbox
  respondendo 200). A flag no .env servido e o selftest do piloto ficam declarados como não medidos.
- Cinco perguntas cumpridas ou superadas: as subidas do SDK do bridge para 2.1.309 e 2.1.310, as provas do
  revisor nos pins 1.0.257 e 1.0.258, e o idioma depois da compactação.

## Achados

1. REAL, corrigido: o selador do #1364 recusou três selos (rc 3, escrita desfeita) por «r16» e «r18» copiados do
   `verified_against` antigo para a narrativa. O código foi glosado na origem («rodada N do radar do Claude Code»), e
   os selos passaram. É o primeiro uso real da guarda nova, e ela pegou o defeito de 2026-10-25.
