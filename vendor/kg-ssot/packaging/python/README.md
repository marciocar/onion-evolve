# KG-SSOT

<!-- mcp-name: io.github.marciocar/kg-ssot -->

**O grafo de conhecimento verificável: toda afirmação diz de onde veio, quando foi conferida e o que depende dela,
e o CI recusa a que não diz.**

Este pacote traz o contrato formal do KG-SSOT e as ferramentas que o aplicam:
- o **leitor de referência**, que julga um grafo `.kg.yaml` ou `.kg.json` contra o contrato, nos níveis MUST, que
  reprova, e SHOULD, que alerta;
- a **suíte de conformidade**, em dados puros, que todo leitor tem de passar;
- o **gate por grafo** para o CI, com catraca: a dívida que já existe fica nomeada e não pode piorar;
- o **armazém**, que só grava o que passa no contrato;
- o **servidor MCP de referência**, que dá o contrato e o armazém a um modelo, por stdio ou por HTTP local;
- o **exportador de proveniência** para PROV-O em JSON-LD.

O contrato, a suíte e o schema do veredito viajam dentro do pacote, e o leitor não depende de nenhum harness de
agente. Python 3.11 ou mais, com PyYAML e jsonschema.

## Instalar

```bash
pip install kg-ssot
```

Para usar os comandos sem instalar no seu ambiente, use `pipx install kg-ssot` ou `uvx --from kg-ssot kg-validate`.

## Validar um grafo

```bash
kg-validate grafo.kg.yaml outro.kg.json
```

```text
PASSA   grafo.kg.yaml
REPROVA outro.kg.json
  MUST   form.range.node.impact ×1 · integrity.orphan-node ×1
· 2 arquivos; 1 passam no MUST; 0 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

O rc é 0 quando todos passam no MUST e 1 quando algum reprova. Alguns modos úteis:
- `kg-validate --where` mostra o nó ou a aresta de cada ocorrência e, numa ocorrência MUST, a correção logo abaixo;
- `kg-validate --format json` devolve o veredito estruturado, com código, caminho, linha, mensagem e dica, no
  formato versionado `kg-ssot.verdict/1`.

## Os comandos

| Comando | O que faz |
|---|---|
| `kg-validate` | Julga grafos `.kg.yaml` e `.kg.json` contra o contrato vigente |
| `kg-conformance` | Roda a suíte de conformidade que vem no pacote contra o leitor de referência |
| `kg-gate` | Gate por grafo para o CI: grava uma linha de base (`--update`) e reprova se algo piorar |
| `kg-store` | Armazém em disco, git ou versionado, que só grava o que passa no contrato |
| `kg-mcp` (e o atalho `kg-ssot`) | Servidor MCP de referência (stdio, ou `--http` em loopback), com as ferramentas `kg_validate`, `kg_write`, `kg_get`, `kg_list`, `kg_history`, `kg_delete` e `kg_schema_help` |
| `kg-prov-export` | Exporta a proveniência de cada nó como `prov:Entity` e `prov:Derivation` em JSON-LD |

Como biblioteca, os módulos ficam em `kg_ssot`: `kg_ssot.kg_validate`, `kg_ssot.kg_store`, `kg_ssot.kg_mcp` e os
demais.

## O servidor MCP

```bash
kg-mcp --root ./grafos --init
uvx kg-ssot --root ./grafos --init   # o mesmo servidor, sem instalar: kg-ssot é um atalho para kg-mcp
```

O servidor fala MCP por stdio. Com `--http PORTA`, ele serve HTTP só em loopback, sem autenticação nem TLS: é para
uso local. Para um servidor exposto, ponha um proxy com autenticação na frente.

## Pacote ou vendor

O pacote é o caminho para usar o leitor como biblioteca, como comando ou como servidor MCP. Para o gate no CI de um
repositório, o canal recomendado continua o **vendor por tag**: o `kg_vendor.py` traz a release para dentro do seu
repositório, com o sha256 de cada arquivo conferido. Assim o contrato que julga o seu grafo fica no seu diff. O
[guia de adoção](https://github.com/marciocar/kg-ssot/blob/main/ADOPTING.md) explica os dois caminhos.

## Documentação

- [Manual](https://github.com/marciocar/kg-ssot/tree/main/docs/manual): o formato, o contrato, as ferramentas, a adoção e os problemas comuns
- [Guia de adoção](https://github.com/marciocar/kg-ssot/blob/main/ADOPTING.md)
- [Suíte de conformidade](https://github.com/marciocar/kg-ssot/blob/main/spec/conformance/README.md)
- [Para agentes de IA (llms.txt)](https://github.com/marciocar/kg-ssot/blob/main/llms.txt)

## Licença

Apache-2.0. Veja `LICENSE` e `NOTICE`.
