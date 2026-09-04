---
title: "Revisão — hook Stop rule-title-in-prose: 'REGRA N' na prosa do assistente vem com o título (exit 2 senão)"
date: 2026-09-04
branch: feat/hook-rule-title-in-prose
reviewer: "condutor com dogfood EXECUTADO: --selftest 3/3; simulação com transcript de mentira → exit 2 e a forma correta 'REGRA 74 (Caminho .claude/ NU …)'; anti-loop (stop_hook_active) → exit 0; lint 0 HARD"
reviewed_diff_sha256: 42fade3445e5cdb9d82f7cd7af9a823129210d6afee3d795a94bf516d48fd0c9
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 30000
duration_min: 15
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados

1. **`python3 - <<'PY'` engole o stdin** — o texto entubado à função se perdia e o selftest passava vazio nos casos (a)/(b) (falhou por isso na 1ª rodada). Cura: texto por arquivo temporário. Classe medida 3× hoje (helper 74, helper Stop, o `<<<` do baseline).
2. **Títulos são derivados do SSOT** (`lint-artifacts.sh`), nunca de lista no hook — regra nova ganha título de graça; regra sem título no lint devolve "título não encontrado" em vez de inventar.
3. **Teto declarado:** o hook vê o texto do assistente, não arquivos escritos por subagentes; hooks novos exigem sessão nova para valer — o 1º veto ao vivo é gatilho da migalha.

## Fora de escopo
- Core-only: o plugin `onion` não embarca `lint-artifacts.sh`, logo não embarca este hook (títulos não resolveriam).
