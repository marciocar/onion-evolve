---
title: Onde mora o estado da evidência de auditoria contínua — a varredura de fornecedores
date: 2026-10-21
kg: docs/evolution/research/audit-evidence-storage-2026-10/audit-evidence-storage-2026-10.kg.yaml
run_id: wf_1b66acda-ac8
tokens: 7031427
agents: 106
duration_min: 39
review_after: 2026-11-20
type: research
mode: decision
---

> **Projeção do grafo, nunca fonte.** A decisão `D_AUDIT_STORAGE_SEAL_AFTER_VENDOR_SWEEP_1021` está
> **`open`** e reabre a pergunta de `D_AUDIT_GRAPH_IS_STORAGE_OSCAL_IS_EDGE_1021`, que o maestro selou
> como «pesquisar mais fornecedores». Esta sessão não sela.

## O que a varredura sustenta

- **OSCAL é borda em quase todo lugar onde a primária é legível.** O Gemara (OpenSSF) converte para
  OSCAL e SARIF por pacote dedicado. Attestful e claude-grc-engineering só exportam ou geram. A Vanta
  exporta OSCAL desde 04/05/2026 com o estado dentro do produto. O C2P produz Assessment Results a partir
  do motor de política.
- **Há uma quarta via que a pergunta omitiu: OSCAL como arquivo versionado em git** (trestle, IBM 2021),
  revisado por PR. Só que o git do trestle guarda **autoria** (catálogo, perfil, SSP), não o resultado
  medido (`E_OBJECAO_01`, `E_OBJECAO_02`).
- **O capital vai para o estado dentro do produto.** Vanta com cerca de US$ 300M de ARR e Série D a
  US$ 4,15B (Sacra, tier 5, com inconsistência interna). Comp AI com Série A de US$ 34M (tier 4).
  Nenhuma fonte confirmada mostra capital em estado git-nativo.

## O que NÃO sustenta — "o git guarda TODO o estado"

1. **O git não é WORM, e quem configura o host é o auditado.** A proteção de branch não dá independência
   ao auditor, e o core não tem âncora externa de imutabilidade (`E_OBJECAO_11`, `E_OBJECAO_12`, a mais
   forte do run).
2. **A população vem da produção.** O git só vê o que passou por ele, e a evidência precisa reconciliar
   com os deploys (`E_OBJECAO_09`).
3. **Resultado em volume é analítico.** O kyverno reports-server levou os relatórios do etcd para
   Postgres, e o complyctl grava em diretório de trabalho (`E_OBJECAO_14`, `E_OBJECAO_29`).
4. **O trestle assina só JSON**, e o grafo é YAML (`E_OBJECAO_13`).

## As opções (nó `D_AUDIT_STORAGE_SEAL_AFTER_VENDOR_SWEEP_1021`)

| Opção | Em uma linha |
|---|---|
| **B (recomendação do Elenxo)** | o grafo guarda o estado **declarativo e de julgamento** (controles, mapeamentos, achados, carimbos de frescor, decisões, ponteiros com digest); a evidência bruta e os resultados em volume ficam fora, append-only, referenciados por hash; OSCAL, OCSF 2003 e o EvaluationLog do Gemara são bordas |
| A | selar como está: todo o estado no git |
| C | mais uma passada focada (RegScale, Paramify, Hyperproof, Drata, InSpec, o whitepaper do Gemara, o consumo pelo auditor) |
| D | OSCAL como arquivo nativo em git (modelo do trestle) |
| E | banco relacional próprio |

⚠️ **O texto do Elenxo chegou TRUNCADO ao escritor** (600 caracteres, por defeito do motor:
`webText()` com `slice` aplicado à recomendação). A íntegra foi restaurada no nó a partir do journal do
run, sem completar de memória. A cura do motor vai em PR próprio. Nas palavras dele: *"Quando escolher C
em vez de B: se o maestro exigir que a metade 'git como trilha' seja selada já, a resposta honesta é C:
falta exatamente a evidência de imutabilidade e de consumo pelo auditor."* D é descartada porque o Lula
saiu dela, e E porque conflita com o KG-SSOT sem ganho: o volume se resolve com a divisão de B.

## NÃO-VERIFICADOS

- **Refutadas: 5.** A ARR da Drata (US$ 98M) caiu.
- **Fora do orçamento: 34 não verificadas e 36 descartadas.** Muitas objeções do Elenxo
  (`E_OBJECAO_15` a `E_OBJECAO_38`) apontam claims cortadas sem votos.
- **Sem classificação (~6 dos 14 pedidos):** Hyperproof, Secureframe, Thoropass, Anecdotes, Paramify e
  Chef InSpec.
- **Eixos vazios:** o consumo pelo auditor (zero claims ancoradas), as aquisições do setor e os
  analistas sobre o futuro do OSCAL.
- **RegScale "OSCAL-native":** o armazenamento não foi medido, e ela é o contraexemplo mais forte à tese
  da borda (`E_OBJECAO_07`).
- **Não verificado:** o relato de que os participantes do piloto FedRAMP 20x não usaram OSCAL
  (`E_OBJECAO_35`).

## valeu-a-pena

7.031.427 tokens ÷ 78 nós ≈ **90k por nó**, com 106 agentes em 39 min. Fica entre o modo primárias
(≈30–42k por nó) e a varredura de referência (≈291k por nó). Rendeu a quarta opção e a objeção do WORM,
que mudam a forma do selo, de "git guarda tudo" para um escopo dividido. Deixou cerca de 70 claims sem
verificar por orçamento: se o maestro escolher C, a passada deve ser em **modo primárias**, sobre as
fontes que as objeções já nomeiam.

Retorno integral: `data/run-wf_1b66acda-ac8.json`.
