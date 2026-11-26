---
branch: docs/research-onion-evolve-persona
pr: pendente
date: 2026-11-26
reviewed_diff_sha256: db598bccd95708e5bbb389f59254d22e036714b1902ecaf773d7ae953fe5e654
reviewed_code_sha256: a51376ae93e160ef7826dd9cb06528b0651f8d35894adffea0e721eebf6ade3e
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
Persona do Onion Evolve (125 nós, radar exit 0, contrato rc 0), a `SYNTHESIS.md` e a saída bruta da rodada 1 em `data/`.

## Achados

Elenxo das duas rodadas: 44 objeções sobreviventes viraram nós `E_OBJECAO_*`, 12 bloqueiam. Rodada 1 (5): o termo de
mercado não entregue, os 30 ciclos sem avaliador externo, o agente que edita a própria política, papel separado não é
independência, e a autodescoberta sem critério de parada. Rodada 2 (7): a contagem do termo compara 2 de 4 candidatos,
a entrada do medidor não pode ser escrita pela Persona, o "3" sem base de run length, o limiar 0% é o mais caro, a
paciência lê validação e não treino, o estado da arte não tem juiz de novidade externo, e o arXiv descartado por locator.
Nenhuma vira correção do diff: são o conteúdo da pesquisa, e a decisão é do maestro.

## Mutantes

Não se aplica: o PR não muda código nem guarda.

## Limites declarados

- 26 afirmações foram rejeitadas na ancoragem (17 + 9) e só aparecem na contabilidade `E_LACUNAS_*`.
- As medidas de 2025 (Project Vend fase 1, TheAgentCompany) não transferem a magnitude para os modelos de nov/2026.
