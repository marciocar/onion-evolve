---
branch: docs/capability-vs-guard-bar
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: a3e542c13c4fc9179551c16a49686268ce08c62042888a8f8330867a5de7a7ce
reviewed_code_sha256: 57e1dc815f0d8e8b3ea55ee26e856abb6cf6316d85f6c66ee35c2c2e94a130dd
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `docs/capability-vs-guard-bar`

## O que muda

- `.claude/commands/common/prompts/dissect-doctrine.md` (§2): um parágrafo separa a régua de CAPACIDADE (testa
  barato e mede, extra fora do perfil mínimo, núcleo só com prova) da de GUARDA (recorrência medida de 2 ou mais).
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: `D_REGUA_CAPACIDADE_TESTA_BARATO_GUARDA_RECORRENCIA_1025`,
  `D_EXTRA_RDF_DO_KG_SSOT_EM_SERIE_1025` e três arestas.

## Suspeitas descartadas

1. A régua nova afrouxar as guardas: descartada. O parágrafo mantém a recorrência para o que barra, e a
   capacidade só vira núcleo com prova.
2. A ordem a → c → b contrariar o «a+b+c em série» do maestro: descartada. A série é a mesma; a ordem é a do
   kg-ssot, acolhida pela delegação, e o (b) é puxado por consultas reais, o que atende a dor do ICP.
