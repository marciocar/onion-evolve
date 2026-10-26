---
title: "Dissecação da frente de IA na curadoria (proposta: perseguir como estudo em ondas, piloto 3 a decidir; ao core: o rótulo do nó de modelos pequenos e a lacuna do radar)"
date: "2026-10-26"
from: onion-curation
merged_at: "main e605e6f (PR #117 e #118)"
to: onion-evolve
destination: projeto:onion-curation (o veredito da frente é da curadoria; ao core vão o rótulo do nó e a lacuna do radar)
type: dissect-proposal
kg: docs/evolution/dissect/ai-front-2026-10/ai-front-2026-10.kg.yaml
decision_node: D_AI_FRONT_VERDICT
---

# Sinal: a frente de IA (família ideia)

## Veredito proposto

**Perseguir a frente de IA como estudo em ondas, ainda sem frente fixa.** Pela régua da Etapa 0, a nota de 4 a 6
parquearia. O maestro selou "não parquear" (`D_AI_FRONT_PILOT2_NOW_1026`), e a direção dele é que piloto
inconclusivo pede piloto melhor.

| piloto | perguntas | aceitos pelo juiz | de pé depois da revisão adversarial |
|---|---|---|---|
| 1 | as 3 de IA mais estudadas pelo core | 1 de 8 | 0: o achado já estava no nível 0 deste estudo (análogos e identidade) |
| 2 | 3 de IA sem estudo próprio | 2 de 6 | 1: o PoETa v2, que mede modelo pequeno em português do Brasil |

O critério era 2 ou mais. Os dois pilotos são inconclusivos.

**Próxima onda, só proposta (`C_PILOT3_PROPOSAL`), para o maestro decidir:**
- 6 perguntas;
- um juiz separado filtra já na escolha;
- a condição (iii) exige caso de uso real ou um nó de impacto 4 ou mais para mudar;
- a fonte tem de medir a mesma coisa que a pergunta pede;
- a contagem é por fato, não por fonte.

O que mais derrubou achados no piloto 2 foi a fonte que mede outra coisa: mock de HTTP no lugar do modelo real,
fronteira simulada, tradução no lugar de compreensão, benchmark no lugar de caso real.

## Ao core

**(a) Correção de rótulo, com fonte primária.** O nó `Q_ONION_SLM_PRIMARIES_2026_10`
(`docs/evolution/research/onion-slm-2026-10/onion-slm-2026-10.kg.yaml`, linha 49) afirma que "NENHUMA primaria mede SLM
em pt-BR nem em extracao de KG".
- A metade "pt-BR" caiu. Hochgraf, Assis, Paes e Cozman (USP e UFF), "Beyond Aggregate Scores: A Diagnostic Analysis
  of Portuguese LLM Evaluation Suites", STIL 2026 (https://aclanthology.org/2026.stil-1.18.pdf), medem três variantes
  do Qwen3 1.7B adaptadas ao português no PoETa v2, com corpus do Brasil (Carolina, ENEM 2022) e bootstrap de 10 mil
  réplicas. Elas empatam no total (menos de 1 ponto percentual) e divergem muito por tarefa.
- A metade "extração de grafo" continua de pé.
- Sugestão fraca ao eval de domínio: reportar por tarefa e por origem (nativa ou traduzida), não só o total.
- O nó é do core, e a correção é dele.

**(b) A lacuna do radar, como antes.**
- O eixo de fronteira de modelos cobre só o modelo da sessão do Claude Code, com 0 menções a treino, ajuste fino,
  LoRA, destilação, quantização ou inferência.
- O fim do ajuste fino self-serve da OpenAI vale desde 2026-05-07 e não aparece no radar.
- Proposta: alargar o eixo, ou abrir um eixo novo, para a trajetória do mercado de modelos: treino e ajuste; APIs que
  abrem e fecham; plataformas de treino de pesos abertos; modelos pequenos.

**(c) Só informação: o ToolOrchestra.**
- Um orquestrador de 8B treinado por reforço relata 37,1% no Humanity's Last Exam, contra 35,1% do GPT-5, a custo
  menor (https://arxiv.org/abs/2511.21689).
- Não muda a pergunta do gatilho de federação, que pede caso de uso real.
- O roteamento entre vários modelos já tem rejeição de identidade no core: "Model-routing multi-LLM fere a identidade
  plataforma única" (`onion-engine-economy.md`, linha 97).
- O número é autorrelatado e sem réplica.

## Enquanto isso

Quando o maestro pedir um estudo de IA, a lista de fontes da frente entra no estudo por demanda: artigos, laboratórios,
comunidades, empresas e dinheiro.

## Elenxo (revisão adversarial por agente separado)

- No estudo, derrubou a justificativa "superação" e limitou a nota, a escolha, o gatilho e o custo.
- No piloto 2, derrubou o ToolOrchestra pela condição (iii), estreitou o PoETa v2 e registrou que duas fontes do mesmo
  fato contam uma vez.
- Tudo está no grafo, em `pilot/judge.md` e em `pilot2/judge-and-review.md`.
