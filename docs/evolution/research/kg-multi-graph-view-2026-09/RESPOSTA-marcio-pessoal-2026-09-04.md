---
title: "Resposta ao sinal 'N grafos peer, 1 visão' — federação por consulta, nunca fusão"
date: 2026-09-04
from: onion-evolve (core / sala de design)
to: marcio-pessoal (Onion pessoal — method-adopter, trust soberano)
re: docs/evolution/inbox/2026-09-04-consolidacao-cross-vertical-kg.md (sinal upstream) → pesquisa profunda wf_bb97173d-425
type: downstream-announce
classe: RESPOSTA-A-SINAL (decisão proposta; o maestro sela)
status: a transportar (rascunho na staging do core)
---

# 📣 Resposta do core — "o quadro geral" com N grafos peer

> Push core→adotante (doc-bridge). O core não roda nada no seu repo (I3); este arquivo chega como untracked no seu `inbound/` e o commit é da sua sessão. Seu dado bruto não saiu de lá e não foi lido: a pesquisa foi sobre o MECANISMO, com o sinal como única entrada.

## O que foi feito com o sinal

Pesquisa profunda em modo decisão (`/onion-research`, 104 workers, 15 fontes, 25 claims verificadas, 15 refutadas, Elenxo com 29 objeções sobreviventes), corpus primeiro, mercado invariante. Grafo: `docs/evolution/research/kg-multi-graph-view-2026-09/` no core; nó de decisão `D_KG_MULTI_GRAPH_VIEW_0904` aguarda selo. Custo declarado: 6,7M tokens.

## Resposta às 4 perguntas

**1. Radar multi-arquivo (`--corpus <glob>`)? Não — e a razão é medida, não doutrina.** O `kg-radar.sh` é awk puro com zero acesso a filesystem; é isso que o faz rodar sob `env -i` (propriedade já paga por refutação anterior). Um modo multi-arquivo obriga o motor a tocar disco para cobrir o que o **laço do chamador** já cobre: o `kg-backlog-project.sh` é exatamente esse padrão (loop por grafo sobre `--open-tsv`, rc lido). O agregado é projeção de consumidor-irmão, nunca modo do motor. As fontes primárias (W3C RDF datasets, SPARQL federado, Neo4j Composite) convergem: consulta federada por identificador, sem centralizar dados.

**2. `_XV` vira aresta de verdade? Vira PONTEIRO tipado, nunca aresta nem grafo importador.** Desenho aceito: campo `xref: <arquivo>#<id>` (o `trace:` já é a referência cross-arquivo do Onion), resolvido por um script-irmão HARD no molde do `kg-trace-resolve.sh` — a casa já mediu o preço de ponteiro sem verificação: 13 mortos em 1.659. O motor de atenção nunca atravessa arquivo; o grau não muda. O "grafo de nível 0 que importa" foi reprovado: quem importa passa a ser responsável pelos nós importados, e o seu grafo bruto de saúde/relações existiria no agregado — quebra P3. **Antes do xref, uma pergunta é sua:** `P_LEISURE` em saúde e em trabalho é a MESMA entidade ou um ponteiro? A sua régua `RU_PEER_TEST` (r>0.7 → funde ou mantém) decide isso, e a direção do xref depende da resposta.

**3. `kg-backlog-project.sh` generaliza? Já, hoje.** O marcador `# kg-backlog-guard: on` no cabeçalho de cada `.kg.yaml` é o "FROM NAMED" do Onion — marque os 4 verticais e a projeção agregada dos abertos sai sem tocar em código. O que falta é do core: a raiz canônica `docs/onion/graph` está hardcoded em 4 pontos e você herdaria mensagens de erro sobre um caminho que não tem. Fio aberto no core (variável + default).

**4. Console/view multi-grafo? Não agora.** O `kg-console.sh` tem 0 call-sites vivos hoje; somar multi-arquivo a cerimônia medida é multiplicar cerimônia. O comparativo sai em texto/TSV do radar, **agrupado por grafo**.

## A ressalva que muda como você usa o agregado (C1 — bloqueante)

A atenção do radar usa o **grau bruto** (`impact × confidence × statusFactor × (1 + grau)`). Grafos de tamanhos diferentes não são comparáveis por essa régua — a vertical com mais nós vence sempre (Freeman/closeness normalizam pelo máximo teórico; e mesmo isso corrige tamanho, não maturidade: 12 nós em 3 semanas vs 300 em 8 meses). O próprio backlog do core hoje ordena 36 grupos por atenção crua — defeito vivo, nomeado pela pesquisa. **Até a normalização ser provada, leia o agregado agrupado por vertical, nunca como ranking global entre verticais.**

## O que você pode fazer agora (sem esperar o core)

1. `# kg-backlog-guard: on` nos 4 grafos → `bash .claude/validation/kg-backlog-project.sh --write` (ignore, por ora, o aviso sobre `docs/onion/graph`).
2. Responder a pergunta identidade-vs-ponteiro para os `_XV` com a `RU_PEER_TEST`.
3. Não criar arquivo agregado com nós próprios: vira fonte paralela e reprova por KG-SSOT-first (a projeção some sozinha quando o item fecha no grafo).

## O que o core vai fazer (fios nomeados, no grafo)

Raiz do backlog parametrizada · `xref:` + resolver HARD · medição da normalização no corpus (a ordem cross-grafo muda?) · console multi-grafo gated (≥1 consumidor vivo). Nada disso antes do selo do maestro no nó de decisão.
