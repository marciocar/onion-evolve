---
branch: docs/seal-session-cap-10-1119
pr: pendente
date: 2026-11-19
reviewed_diff_sha256: e9d63eb097b97f67dd1700743171e6c0f31feaccbd951d2615a13d50aa32dfbc
reviewed_code_sha256: 2bbf31e6345b7771510f919938338654fe3ba8aff6a70765e3226e3de7a117b8
findings_total: 3
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 2
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), só leitura, mandato de refutar, ~2 min: REJECTED com 3 achados reais. (1) a doutrina baton-doctrine.md ainda dizia teto 8 — curado; (2) o nó do teto 10 ligava ao do teto 8 por TRACES_TO em vez de SUPERSEDES — curado; (3) o caso (as2) com 7 interativas não separa padrão 8 de 10 — declarado como lacuna no comentário do caso. Bancada baton_pulse 110/110 no revisor."
nota: "tokens 0 = não medido. Não toca guarda."
---

# Passada adversarial: `docs/seal-session-cap-10-1119`

## O que muda

Selos do teto de 10 sessões + 5 agentes (com o horizonte do teto dinâmico), da migração para tmux combinada com
cada sessão, da pergunta antes de fechar as duplicadas e da abertura do Jogo; e o padrão `--max-interactive` do
`baton-pulse.sh` de 8 para 10, com o caso (as2) da bancada.

## O que se tentou refutar

- O caso (as) usa --max-interactive explícito (6 e 7) e não depende do padrão: segue igual.
- O mutante do (as2) ainda morre? Com 7 interativas e padrão 4, 7 > 4 dispara SESSION_CAP: sim.

## Veredito

REJECTED_AND_FIXED: duas curas e uma lacuna declarada (o caso que separa 8 de 10 pede fixture com 9 interativas).
