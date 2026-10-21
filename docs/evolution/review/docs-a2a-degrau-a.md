---
branch: docs/a2a-degrau-a
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: 1404f945205721686f2e683d883982ac130305ec279e2b69d43c02d367ddf474
reviewed_code_sha256: 77942b1bea44c53bfd4faa773b0f19772463fc76a578cc1b5baec55c275af9a8
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal
nota: "tokens 0 = não medido; evidências PROD do teste rodado pelo maestro"
---

# Passada adversarial: `docs/a2a-degrau-a`

## O que muda

Duas evidências PROD no grafo do spike (A1 ida e P5b) e o doc aceito do sinal de teste em `inbox/_processed/`.

## Achados

1. O roteiro do negativo "expired" estava errado: `--iat-offset -400 --exp-offset 300` gera `exp` no
   futuro, porque o `a2a-send.sh` calcula `exp = agora + exp-offset`, e o gate o aceitou com razão.
   Curado com `--exp-offset -60`, que deu 403 `expired`. O nó registra o erro do roteiro, e esse envio
   válido ficou na fila como teste, a arquivar sem aceite.

## Mutantes

Não se aplica: o diff tem evidência de teste vivo e nenhuma guarda.

## Limites declarados

- O A2 (a volta) não rodou, por decisão (A0 + A1).
- O degrau B, a conversa entre duas máquinas, ficou parcial: este A1 já veio do notebook, mas sem volta.
- O convite e o membro de teste seguem ativos até a limpeza.
