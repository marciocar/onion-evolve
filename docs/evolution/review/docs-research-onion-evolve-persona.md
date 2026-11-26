---
branch: docs/research-onion-evolve-persona
pr: pendente
date: 2026-11-26
reviewed_diff_sha256: pendente
findings_total: 44
findings_real: 44
findings_blocking: 12
tokens: 3043145
duration_min: 25
findings_fixed: 0
verdict: APPROVED
elenxo: true
reviewer: "Elenxo e verificador separados do /onion-research (runs wf_ee5183a3-68f e wf_d4ad756c-8ae), modelo distinto do escritor"
nota: "PR só de pesquisa: as objeções do Elenxo são o conteúdo do grafo (E_OBJECAO_*), não defeitos do diff; ficam abertas por desenho e nada é selado aqui."
---

# Passada adversarial: `docs/research-onion-evolve-persona`

## O que muda

Entra o grafo `docs/evolution/research/onion-evolve-persona-2026-11/` com as duas rodadas em fontes primárias sobre a
Persona do Onion Evolve (131 nós: 125 das rodadas, 3 selos do maestro e 3 termos x_term para os códigos S4, Q2 e E3; radar exit 0, contrato rc 0) e a `SYNTHESIS.md`. A saída bruta da rodada 1 não
viaja: tinha caminhos de máquina e hashes de repo privado (REGRA 121); fica citada só pelo run_id `wf_ee5183a3-68f`.

## Achados

Elenxo das duas rodadas: 44 objeções sobreviventes viraram nós `E_OBJECAO_*`, 12 bloqueiam. Rodada 1 (5): o termo de
mercado não entregue, os 30 ciclos sem avaliador externo, o agente que edita a própria política, papel separado não é
independência, e a autodescoberta sem critério de parada. Rodada 2 (7): a contagem do termo compara 2 de 4 candidatos,
a entrada do medidor não pode ser escrita pela Persona, o "3" sem base de run length, o limiar 0% é o mais caro, a
paciência lê validação e não treino, o estado da arte não tem juiz de novidade externo, e o arXiv descartado por locator.
Nenhuma vira correção do diff: são o conteúdo da pesquisa, e a decisão é do maestro.

## Os `confirmed` de maior impacto do grafo (REGRA 87)

Os três do topo são objeções da rodada 2, e nada neste PR os contraria, porque o PR não sela proposta:

- `E_OBJECAO_R2_15_STATE_OF_ART_HAS_NO_EXTERNAL_NOVELTY_JUDGE`: o estado da arte não tem juiz de novidade externo.
  Fica aberta: `D_PERSONA_MVP_BUILD_1126` pede medidor de outro modelo, mas ele ainda não existe nem foi medido.
- `E_OBJECAO_R2_11_PATIENCE_SIGNAL_IS_VALIDATION_NOT_TRAINING`: a paciência lê validação, não treino. O selo
  `D_PERSONA_REFUTER_OTHER_MODEL_1126` cobre o refutador; o medidor de novidade só entra no MVP. Segue aberta.
- `E_OBJECAO_R2_10_DEFINITION_ONLY_THRESHOLD_MOVES_STOP`: o limiar só por definição move a parada. A superação
  `C_SUPERACAO_20261126_GUEST_6PLUS2_ACROSS_BASE_SIZES` dá a base de run length; o número final é decisão do maestro.

## Mutantes

Não se aplica: o PR não muda código nem guarda.

## Limites declarados

- 26 afirmações foram rejeitadas na ancoragem (17 + 9) e só aparecem na contabilidade `E_LACUNAS_*`.
- As medidas de 2025 (Project Vend fase 1, TheAgentCompany) não transferem a magnitude para os modelos de nov/2026.
