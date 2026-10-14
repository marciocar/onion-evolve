---
date: 2026-07-02
instance: onion-evolve
type: learning
classification: public
tags: [breadcrumbs, sdaal, llm-as-vm, memory-staleness, argumentation, deep-research]
affects: [meta, diary, knowledge-graph-sdaal, federation]
breadcrumb_for: [meta:diary, meta:co-evolve, meta:evolve]
share_with: [collective]
next_recommended: "2026-07-02-sovereign-lazy-triggers-research"
review_after: 2027-01-12
conflict_class: static
valid_when: "os benchmarks STALE/MemConflict seguem sendo o estado da arte publicado (campo move em meses)"
---

## Signal
A visão "breadcrumbs inteligentes" (LLM-as-VM, md-as-bytecode) tem lastro: pesquisa verificada
adversarialmente (run `wf_b1cf8d42-e18`, 19/25 claims confirmados, 6 refutados) mostra que
**estrutura de decisão + validade temporal é a aposta com evidência mais forte**, e que o pilar
"armazenamento executável" ficou **sem prova quantitativa sobrevivente** — todos os claims de
vantagem (Voyager 15,3×, MemStrata) caíram 0-3 na verificação.

## Evidence
- STALE (arXiv 2605.06527): melhor modelo de fronteira = 55,2% em detectar memória vencida;
  MemConflict (2605.20926): melhor sistema = 0,2501 em reconhecer contradição — a doutrina
  "re-testar, nunca re-carimbar" ataca uma lacuna real do campo, não hype.
- Herdado nomeado com fonte: AIF/AIFdb (2006), ASPIC+ (rebut/undercut/undermine — nosso
  SUPPORTS/REFUTES é mais grosseiro), divisiveness 2017, CoRE 2024 (LLM-as-interpreter),
  progressive disclosure (Skills). Combinação completa (grafo+re-teste+plane+replay+federação
  git-nativa) NÃO encontrada publicada; markdown-as-memory está fora do survey mais recente.
- Relatório citado completo: docs/analysis/onion-intelligent-breadcrumbs-research-2026-07.md.
- **Estado em 2026-10-14 (re-teste):** (a) o menor enabler do Next crumb FOI ENTREGUE: `conflict_class` e
  `valid_when` no frontmatter, re-teste POR CLASSE no `/meta:diary review`, guarda no selftest (família
  `diary_crumbs` 8/8). A passada de 2026-10-14 sobre 29 migalhas vencidas é o 1º ciclo real que o
  Next crumb pedia antes do ADR. (b) A tese LLM-como-VM / md-como-bytecode foi SUPERADA (Aufhebung) em
  2026-10-05 por diretriz do maestro, sem ser apagada: nó `D_PROMPTS_COMO_BYTECODE_LLM_COMO_VM_SUPERADA` em
  `docs/onion/graph/onion-doctrine-elenxo-bulbo-2026-07.kg.yaml`. A resposta parcial ao "cadê os testes?" é
  a maquinaria determinística que verifica parte do bytecode (lint, selftest). (c) Busca externa de 10-14:
  o STALE (arXiv 2605.06527, 55,2% no melhor modelo) segue sendo a referência publicada que apareceu, e
  nenhum benchmark posterior o supera. O MemConflict NÃO apareceu nessa busca, então o número 0,2501 fica
  como registro datado do relatório e não foi re-medido.

## Next crumb
O enabler (`conflict_class`/`valid_when` + re-teste por classe) está ENTREGUE, e o 1º ciclo real rodou em
2026-10-14. Próximo: decidir se esse ciclo basta para o ADR, e medir a re-absorção com e sem estrutura (Q2). Re-selar esta pesquisa em ~1 trimestre
(benchmarks têm semanas de idade). Não investir em migalha executável sem medir re-absorção no
próprio fluxo primeiro.

## Re-testada em 2026-10-14 — PARCIAL: (static, contra a melhor fonte atual + busca externa) o Signal vale. O Evidence registra o enabler entregue, a superação da tese LLM-como-VM em 10-05 e o STALE ainda como referência. O MemConflict não foi re-confirmado externamente.
