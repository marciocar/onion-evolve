---
title: "N grafos peer, 1 visão — federação por consulta, nunca fusão (decisão para o sinal do Onion pessoal)"
date: 2026-09-04
kg: docs/evolution/research/kg-multi-graph-view-2026-09/kg-multi-graph-view-2026-09.kg.yaml
run_id: wf_bb97173d-425
tokens: 6709840
agents: 104
duration_min: 62
genre: decision
mode: decision
budget: { maxFetch: 15, maxVerify: 25 }
review_after: 2026-12-04
---

# N grafos peer, 1 visão — decisão

> **Projeção** do grafo (32 nós, radar exit 0). Nó de decisão **`D_KG_MULTI_GRAPH_VIEW_0904`** (`open`; o maestro sela). Origem: sinal upstream do Onion pessoal (2026-09-04) — 4 verticais de vida em 4 `.kg.yaml` peer, sem mecanismo para "o quadro geral".

## Custo declarado

| Item | Valor |
|---|---|
| Tokens | 6.709.840 |
| Workers do run | 104 · 15 fontes · 35 claims · 25 verificadas (10 confirmadas, 15 refutadas) |
| Parede | ~62 min |

## O que se confirmou (3-0 salvo indicado)

- Não há semântica única para agregar N grafos: fundir é escolha explícita (W3C RDF 1.1 datasets, tier 10). O mecanismo canônico de "N grafos, 1 visão" é **consulta federada por identificador, sem centralizar dados** (SPARQL 1.1 SERVICE, tier 10); o incumbente comercial faz o mesmo por camada de abstração sem duplicar dados (Neo4j Composite, tier 8).
- Arestas **não atravessam grafos**: a ligação cross-grafo é nó-espelho/ponteiro com o id de referência (Neo4j, 2-1). Referência por nome qualificado com namespace é padrão vivo em PKM multi-vault (tier 5).
- "Atenção comparável entre grafos" tem precedente formal: **normalizar pelo máximo teórico** da rede daquele tamanho (Freeman); sem denominador, a vertical com mais nós vence sempre.
- Ferramentas multi-vault reais entregam roteamento e isolamento, **não** view comparativa (2-1, tier baixo).

## O veredito do Elenxo (o que o maestro sela)

**O2 + O5 + O7; reprova O1, O4, O6, O8; console: não agora.** As razões são locais e medidas, não as fontes (a evidência tier 10 mais forte até legitimaria fundir).

1. **Radar permanece de arquivo único (O2).** `kg-radar.sh` é awk puro com zero acesso a filesystem — é isso que o faz rodar sob `env -i` (propriedade já paga; `kg-trace-resolve.sh:19-23`). Um `--corpus <glob>` obriga o motor a tocar disco para cobrir o que o laço do chamador já cobre: `kg-backlog-project.sh` já faz loop por grafo sobre `--open-tsv` (58 grafos, 122 itens). **A agregação é projeção de consumidor-irmão, nunca modo do motor.**
2. **Referência cross-arquivo = ponteiro tipado + resolver HARD (O5), nunca aresta de motor.** O `trace:` já é a referência cross-arquivo do Onion, e a casa mediu o preço de ponteiro sem verificação (13 mortos em 1.659). O `xref: <arquivo>#<id>` nasce com script-irmão no molde de `kg-trace-resolve.sh`, somente-leitura; as arestas seguem intra-arquivo e o grau não muda. **Reprova O6** (grafo de nível 0 que importa, `owl:imports`): o importador passa a ser responsável pelos nós importados — o grafo bruto de saúde/relações existiria no agregado, quebrando P3.
3. **`kg-backlog-project.sh`: parametrizar a raiz (O7).** O marcador `# kg-backlog-guard: on` já é o "FROM NAMED" do Onion e **já generaliza hoje** (o adotante marca os 4 grafos). Mas `docs/onion/graph` está hardcoded em 4 pontos (l.55, 89, 155, 160) — o adotante herda mensagens de erro sobre um caminho do core. Variável + default: ajuste pequeno, ganho direto.
4. **Console/view: não agora.** `kg-console.sh` (31 KB) tem 0 call-sites vivos hoje; somar multi-arquivo a cerimônia medida é multiplicar cerimônia. Gatilho: ≥1 consumidor vivo recorrente.

## CONSTRAINS (nenhuma é opcional)

- **C1 — normalização antes de qualquer ordem cross-grafo (bloqueante; o defeito já está vivo no core).** Atenção = `impact × confidence × statusFactor × (1 + grau)` com grau BRUTO; `docs/backlog.md` já ordena 36 grupos por atenção crua entre grafos de densidades diferentes. Antes de agregar 4 verticais: medir no corpus se a ordem cross-grafo muda sob normalização do termo de grau, e (a) agregar sempre **agrupado por grafo**, sem rank global interleaved, ou (b) introduzir a variante normalizada com comparabilidade **provada**.
- **C2 — xref só entra com o resolver.** Sintaxe sem garantia reproduz a classe dos 13 ponteiros mortos. Somente-leitura.
- **C3 — identidade vs. ponteiro segue em aberto.** `P_LEISURE` em saúde e em trabalho pode ser a MESMA entidade, não um ponteiro; a régua análoga já existe no Onion pessoal (`RU_PEER_TEST`, r>0.7 "funde ou mantém"). Decidir isso antes da direção do xref.
- **C4 — a visão agregada não pode ter estado próprio.** Projeção derivada, arquivo gerado, item fecha no grafo e some sozinho (catraca da REGRA 62, Projeção GERADA em sincronia com a fonte).
- **C5 — lacunas antes de selar:** Datalog modular (0 fontes lidas), doc atual de composite databases (achado 2-1 veio da página legada), normalização estatística (só Wikipedia tier 6).

## Mercado (eixo invariante)

Sem sinal de capital. O único sinal comercial é de fornecedor: o incumbente monetiza a **camada de consulta federada**, não o painel agregado — a favor de `D_anti_catalogo`. PKM multi-vault: plugins de indivíduos, sem produto, sem incumbente.

## NÃO-VERIFICADOS (declarado)

Refutados 15; fora do orçamento 10 claims e 21 fontes (entre elas Datalog/Soufflé, arXiv de normalização, doc atual do Neo4j). Caveat do run: nada na evidência trata de grafos de VIDA peer com atenção comparável — Freeman corrige tamanho, não maturidade (12 nós/3 semanas vs 300 nós/8 meses). A comparabilidade entre "trabalho" e "saúde" é **desenho original do Onion**, a fechar por dogfood.

## valeu-a-pena

6,71M tokens ÷ 32 nós ≈ **210k/nó**. O que se comprou: o Elenxo derrubou a resposta "óbvia" (`--corpus` no radar) por uma propriedade load-bearing que eu não tinha na mão (awk sem filesystem, `env -i`), e nomeou o defeito vivo no core (ranking cross-grafo por atenção bruta) que o próprio backlog exibe hoje.

## O que responde ao sinal do Onion pessoal

| Pergunta do sinal | Resposta |
|---|---|
| (1) radar `--corpus`? | **Não.** Radar fica de um arquivo; o agregado é consumidor-irmão que faz o laço (padrão do backlog). |
| (2) `_XV` vira aresta? | **Vira ponteiro tipado** `xref: <arquivo>#<id>` com resolver HARD; nunca aresta, nunca grafo importador. Antes: decidir se `P_LEISURE` é identidade ou ponteiro. |
| (3) backlog generaliza? | **Já, hoje:** marque os 4 grafos com `# kg-backlog-guard: on`. O core parametriza a raiz hardcoded (fio aberto). |
| (4) console multi-grafo? | **Não agora** (0 call-sites). Comparativo sai em texto/TSV do radar, **agrupado por grafo** enquanto a normalização (C1) não for provada. |
