# 1. O que é e para quem

[← Índice](README.md) · [Conceitos →](02-conceitos.md)

## O problema

Uma equipe, humana ou de agentes, acumula conclusões: "o retry é idempotente", "o cache precisa de TTL",
"decidimos três tentativas". Elas costumam morar em atas, em tickets e em memórias de conversa. Três coisas se
perdem nesse caminho:

1. **De onde veio.** A conclusão perde a fonte e vira opinião repetida.
2. **Quando foi conferida.** Um fato verdadeiro em março pode ser falso em outubro, e nada avisa.
3. **O que depende do quê.** Quando uma evidência cai, ninguém sabe quais decisões caem junto.

Uma ferramenta que escreve conhecimento, seja pessoa ou modelo, consegue produzir texto convincente sem nenhuma
das três. O KG-SSOT trata isso como um problema de **formato verificável**, não de boa vontade.

## A tese

Conhecimento operacional cabe num **grafo em arquivo texto**, versionado junto do código, em que:

- cada nó é uma afirmação curta e tipada (pergunta, evidência, decisão, artefato...);
- todo nó `confirmed` ou de produção diz **de onde veio** (`provenance`), e o carimbo de verificação diz
  **quando** e **contra o quê** (`verified_at`, `verified_against`);
- as arestas dizem **o que sustenta, refuta, substitui ou depende** de quê;
- um **contrato formal** (JSON Schema 2020-12 mais regras de integridade) decide o que reprova e o que só alerta,
  e qualquer leitor, em qualquer linguagem, prova que segue o contrato passando numa **suíte de conformidade**.

O resultado é um arquivo que uma máquina consegue julgar no CI, como julga código.

## O que vem no produto

| Peça | O que é |
|---|---|
| O contrato | Dois JSON Schemas, MUST (reprova) e SHOULD (alerta), mais as regras de integridade que o schema não alcança |
| A suíte de conformidade | 225 casos em `latest/`, em dados puros, com o veredito e os códigos esperados de cada um |
| O leitor de referência | `kg_validate.py`, em Python 3.11 ou mais com PyYAML e jsonschema, sem outra dependência |
| O kit de adoção | `kg_vendor.py`, que traz uma release por tag, e `kg_gate.py`, a catraca por grafo no CI |
| O armazém com gate | `kg_store.py`, que grava grafos em disco, num repo git ou num armazém versionado, só depois do PASS do contrato |
| O servidor MCP de referência | `kg_mcp.py`, que dá a um modelo o contrato e o armazém por MCP, por stdio ou HTTP local |
| O exportador PROV-O | `kg_prov_export.py`, que leva a proveniência de cada nó para o ecossistema W3C PROV, em JSON-LD |

## Para quem

- **Equipes de engenharia** que registram decisões e evidências e querem que o CI recuse uma afirmação sem fonte.
- **Quem constrói agentes** e precisa de uma memória que o agente lê primeiro e que não aceita escrita sem origem.
- **Quem escreve ferramentas de grafo** (visualizadores, extratores, ports em outra linguagem) e quer provar
  compatibilidade com uma suíte, não com um "funciona na minha máquina".

## O que o KG-SSOT não é

- **Não é um banco de grafos.** Não há servidor, consulta nem índice. É um formato de arquivo com um contrato.
- **Não é um padrão da web semântica.** Não é RDF nem OWL. O formato é YAML com um vocabulário fechado e pequeno.
- **Não decide se a afirmação é verdadeira.** O contrato confere que a afirmação **diz** de onde veio e quando foi
  conferida. Conferir a fonte de novo é trabalho de quem revisa.
- **Não depende de um editor, de um assistente ou de uma plataforma.** O contrato e o leitor de referência rodam
  com Python e nada mais.
