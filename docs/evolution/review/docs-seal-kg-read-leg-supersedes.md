---
branch: docs/seal-kg-read-leg-supersedes
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: 8c49ee59b83a83ae716c7e46c815039a54371b8b0bce435b5cf126c5e51faa44
reviewed_code_sha256: 400a0ecf7144e30973a254bff6f326fb667bb454a8132ebe34de8b51ade495ef
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 6
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, com o radar do grafo; sem subagentes
nota: ""
---

# Passada adversarial: `docs/seal-kg-read-leg-supersedes`

## O que muda

O selo `D_KG_READ_LEG_HOOK_SUPERA_NENHUMA_DAS_TRES` entra pelo selador com aresta SUPERSEDES para
`D_build_none_of_three`, que passa de `confirmed` a `superseded`.

## Achados

1. **REAL, curado:** depois do selo, o radar avisou que `D_build_none_of_three` recebia SUPERSEDES e continuava
   `confirmed`. A resposta do maestro foi «Supera», então o status certo é `superseded`. Editei só essa linha do
   nó, e a reconciliação ficou limpa (radar `--integrity --schema` exit 0).

## Mutantes

Nenhum: não há código.

## Limites declarados

O selo é testemunho do maestro sobre IDENTIDADE de objeto. O A/B não foi refeito com o hook ligado: essa opção,
«Pesquisar antes», foi descartada por ele.
