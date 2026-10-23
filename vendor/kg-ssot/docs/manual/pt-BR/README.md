<!-- translation-of: docs/manual/README.md sha256:0871fe30587aa6f5 -->
# Manual do KG-SSOT

[English](../README.md) | **Português (Brasil)**

<sub>Tradução do original em inglês; quando os dois divergirem, vale o inglês.</sub>

O KG-SSOT é um **grafo de conhecimento verificável** num arquivo texto. Cada afirmação pode trazer a fonte dela, a data
em que foi conferida e contra o que foi conferida. Um contrato formal decide se o arquivo está bem escrito. Este manual
cobre o formato `.kg.yaml`, o contrato, as ferramentas e como adotar o KG-SSOT num repositório.

Este manual descreve a release **4.22.0** (tag `kg-ssot-v4.22.0`). O contrato vigente dessa release é o **v4**.

O manual também existe em português do Brasil, em [`docs/manual/pt-BR/`](README.md): esta tradução. Quando os
dois divergirem, vale o texto em inglês.

## Capítulos

| # | Capítulo | Para quê |
|---|---|---|
| 1 | [O que é e para quem](01-o-que-e.md) | O problema, a tese e quem ganha com isso |
| 2 | [Conceitos](02-conceitos.md) | Grafo, nó, tipos, status, planos, arestas, proveniência, carimbo de verificação |
| 3 | [Referência do formato](03-formato.md) | Todos os campos do `.kg.yaml`, tirados do schema |
| 4 | [O contrato](04-contrato.md) | MUST × SHOULD, códigos de erro, versões e tags |
| 5 | [Ferramentas](05-ferramentas.md) | `kg_validate`, `kg_conformance`, `kg_gate`, `kg_vendor`, `kg_store`, `kg_mcp`, `kg_query`, `kg_diff`, `kg_prov_export`, `kg_migrate`, com saídas reais |
| 6 | [Adoção e CI](06-adocao-e-ci.md) | O caminho curto para levar o contrato a um repositório |
| 7 | [Conformidade e leitores](07-conformidade-e-leitores.md) | A suíte de casos e como escrever um leitor próprio |
| 8 | [Receitas](08-receitas.md) | Tarefas comuns, passo a passo |
| 9 | [Solução de problemas](09-problemas.md) | O que cada erro quer dizer e como resolver |
| 10 | [Glossário](10-glossario.md) | Os termos usados neste manual |

## Leitura rápida

- **Vai escrever um grafo?** Leia os capítulos 2 e 3, e recorra ao capítulo 9 quando o leitor reprovar o arquivo.
- **Vai adotar o KG-SSOT num repositório?** Comece pelo capítulo 6 e siga para o [`ADOPTING.pt-BR.md`](../../../ADOPTING.pt-BR.md).
- **Vai escrever um leitor em outra linguagem?** Leia o capítulo 7 e o [`spec/conformance/README.pt-BR.md`](../../../spec/conformance/README.pt-BR.md).

## Fontes da verdade

Este manual é explicativo, não normativo. Quando ele divergir de um destes arquivos, valem os arquivos:

- o contrato: [`spec/kg-contract-v4.schema.json`](../../../spec/kg-contract-v4.schema.json) (MUST) e
  [`spec/kg-contract-v4.should.schema.json`](../../../spec/kg-contract-v4.should.schema.json) (SHOULD);
- a suíte: [`spec/conformance/`](../../../spec/conformance/README.pt-BR.md);
- a superfície da release: [`spec/release.json`](../../../spec/release.json).

Todas as saídas de comando deste manual foram coladas de uma execução real, em Python 3.12 com as versões fixadas em
[`tools/requirements.txt`](../../../tools/requirements.txt). As ferramentas imprimem a saída legível em inglês por
padrão, e em português do Brasil quando você define `KG_SSOT_LANG=pt-BR` ou roda num locale `pt_BR`. Os códigos de
erro, os códigos de saída e as chaves do JSON nunca mudam de língua; só o texto para pessoas muda.
