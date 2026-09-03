---
title: "Revisão — F3 da lente: modo decisão (Elenxo + nó D_ open) e dogfood na poda do CLAUDE.md"
date: 2026-09-03
branch: feat/research-lens-f3
reviewer: "condutor com dogfood EXECUTADO: Workflow wf_ab17f8d6-773 em mode=decision (52 agentes, 3,4M tokens, 27 min) + relançamento do write(KG) do cache (99k) após corrigir o contrato; grafo poda-instruction-bloat-2026-09 com radar exit 0 (19 nós, 12 CONSTRAINS, 1 REFUTES, D_ open); bancada run_research_workflow_selftests 7/7 isolada; lint --only rc=0 na SYNTHESIS (após citar no trace do nó Q); radar exit 0 no grafo da lente; backlog LC_ALL=C; rebase em main sem conflito"
reviewed_diff_sha256: 1ced3eb12f0bb292bd206b141fc04b851cfed7ceefd67f313c6e182062ed375c
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 3600000
duration_min: 90
---

# Resíduo — REGRA 56

## Achados

1. **O agente nunca recebeu o bloco de decisão** — meu patch mirou uma âncora inexistente na string do write(KG); a
   1ª escrita saiu com 5 nós e 0 `D_`, radar 0 (forma errada com radar verde). Cura: contrato de decisão **exigido
   pelo schema** (`decisionNodeId ^D_`, `optionNodeIds ≥ 2`, `constrainsEdges ≥ 1`) + bloco no INÍCIO do prompt +
   fail-loud em JS. Caso (g) na bancada.
2. **O Elenxo refutou a premissa da minha pergunta**: "skills sempre-carregadas" é falso (corpo entra sob demanda;
   CLAUDE.md ≈ 5 k tokens = 0,5 % de 1 M) — o alvo de poda era ~5× superestimado. É o comportamento desejado do
   modo decisão: refutar também o enunciado.
3. **12 descartes "por orçamento" reabertos** — inclusive a conclusão operacional e a correção do enquadramento do
   Radar. Lição para o orçamento default do modo decisão (`maxVerify` menor, Elenxo lê o que foi cortado).
4. **Custo 3,4 M / ~180 k por nó** — o modo decisão é caro por desenho (3 votos + refutador em opus/high); declarado na
   SYNTHESIS como lacuna.

## Não mudou

- `D_PODA_INSTRUCTION_BLOAT_CLAUDE_MD_E_SKILLS` e `D_PODA_INSTRUCTION_BLOAT_MEDIDA` seguem `open` — selo do maestro.
- F4 (revisita) segue `open`; patch pronto.
- Nada foi podado do CLAUDE.md.
