---
branch: docs/aaif-projects-2026-11
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: pendente
findings_total: 15
findings_real: 15
tokens: 0
duration_min: 0
findings_fixed: 15
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "curadoria, por agente separado, só leitura na árvore do core; a cura é de outro agente, que conferiu cada achado antes de aplicar"
nota: "tokens e duração 0 = não medido: a revisão correu na sessão da curadoria. 15 achados: 1 crítico, 4 altos, 7 médios e 3 baixos. Quatro tiveram parte recusada ou corrigida, com o motivo abaixo. A cura em si ainda não foi revista."
---

# Passada adversarial: `docs/aaif-projects-2026-11`

## O que muda

Grafo e SYNTHESIS novos do estudo dos 10 projetos da AAIF (tarefa SAC-275), com a tabela projeto × peça do Onion e do kg-ssot, e `data/` com scripts e logs saneados. Nenhum código de produção. O parecer do kg-ssot entra como testemunho dele.

## Achados

Os 15 foram aplicados depois de conferidos, e nenhum foi recusado por inteiro. Parte recusada ou corrigida:

- **Achado 2:** a formulação de doutrina proposta ficou de fora; o nó segue como pergunta aberta, decidida em outra pesquisa.
- **Achado 4:** a tabela de preços confere, mas a revisão trazia só uma faixa e omitia o pré-requisito.
- **Achado 7:** recusado o cruzamento com os 91 nós de treino: «agente por reforço» dá 0 nós.
- **Achado 13:** a conta das citações é 35 + 5 + 1, não 36 + 5.

## Mutantes

Não se aplica: só grafo e texto, sem guarda nova. Achado de defeito, não curado aqui: `a2a-rt-mcp.py` ecoa em `initialize` a versão 2026-07-28, que ele não implementa (`C_DEFEITO_A2A_RT_MCP_ECOA_VERSAO`).

## Limites declarados

Nada mede adoção real, nem quem paga por projeto. OpenEnv, OpenSandbox e Agent Router nunca rodaram. As rodagens usaram chave fictícia e `-p`, a maioria com 1 corrida. A cura não teve 2ª revisão até este resíduo.
