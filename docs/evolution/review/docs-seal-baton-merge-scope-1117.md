---
branch: docs/seal-baton-merge-scope-1117
pr: pendente
date: 2026-11-18
reviewed_diff_sha256: ddfc55706cdf19fe4b57dbec09581eb373cb4edc7d260b18d510c64518457f08
reviewed_code_sha256: 45ddd14e277bf3a0b661a95df542296c185500ec82422d711c02c9332bcf93a3
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: APPROVED
elenxo: false
reviewer: "sessão do core, releitura do diff contra as respostas literais do maestro nos formulários de 17 e 18/11"
nota: "tokens 0 = não medido: a passada foi a releitura do diff pela própria sessão que selou, sem agente separado. PR só de grafo (um arquivo .kg.yaml), sem código nem guarda; cada selo passou pelo kg-decide-seal.sh, que só grava com o radar --integrity --schema exit 0."
---

# Passada adversarial: `docs/seal-baton-merge-scope-1117`

## O que muda

Catorze decisões do maestro, de 17 e 18/11, gravadas como nós novos no arquivo de selos de coordenação
(`docs/onion/graph/coordenacao-selos-arquivo-2026-11.kg.yaml`), todas pelo selador: o escopo da batuta para merge de
PR que não toca guarda; a janela da mensagem direta da ponte; o padrão de atendimento; a extensão da condição como
guia; o portão por identidade da ponte só com a cura da rotina; a abertura do Jogo do Company Brain pelos princípios;
a opção B do perfil de ritual; a gramática (o descartado como nó e o modo de fechamento) como guia; o repo e a sessão
do Jogo; as três grandezas; a tese com sombra; o estado da sessão só do agente; e a régua do movimento.

## A passada

Cada `verified_against` e cada `narrative` foi lido contra a resposta literal do formulário. Doze batem palavra por
palavra (sem o sufixo «(Recomendado)», que o selador tira). As respostas livres do maestro foram gravadas com
`--other`.

## Achado

- **(baixo, declarado)** O selo `D_COMPANY_BRAIN_GAME_MEASURES_APPROVED_1118` grava o início literal da resposta
  («Opção 1, Aprovo os três + Ter em mente que não é um jogo completo») e RESUME o resto (os links das referências e o
  pedido de dissecação conjunta) em vez de copiá-lo. O texto literal completo está no brief comum entregue às sessões
  (`/run/user/1000/onion-jogo-referencias-1118.txt`, fora do repo). Não reescrevo o selo: o selador não edita nó já
  `done`; fica declarado aqui.
