# Manual do KG-SSOT

O KG-SSOT é um **grafo de conhecimento verificável** em arquivo texto. Cada afirmação traz a fonte dela, a data
em que foi conferida e o que foi conferido, e um contrato formal decide se o arquivo está bem escrito. Este
manual cobre o formato `.kg.yaml`, o contrato, as ferramentas e a adoção num repositório.

Release descrita aqui: **4.10.0** (tag `kg-ssot-v4.10.0`). O contrato vigente dessa release é o **v4**.

## Capítulos

| # | Capítulo | Para quê |
|---|---|---|
| 1 | [O que é e para quem](01-o-que-e.md) | O problema, a tese e quem ganha com isso |
| 2 | [Conceitos](02-conceitos.md) | Grafo, nó, tipos, status, planos, arestas, proveniência, carimbo de verificação |
| 3 | [Referência do formato](03-formato.md) | Todos os campos do `.kg.yaml`, tirados do schema |
| 4 | [O contrato](04-contrato.md) | MUST × SHOULD, códigos de erro, versões e tags |
| 5 | [Ferramentas](05-ferramentas.md) | `kg_validate`, `kg_conformance`, `kg_gate`, `kg_vendor`, `kg_store`, `kg_mcp`, `kg_prov_export`, `kg_migrate`, com saídas reais |
| 6 | [Adoção e CI](06-adocao-e-ci.md) | O caminho curto para levar o contrato a um repositório |
| 7 | [Conformidade e leitores](07-conformidade-e-leitores.md) | A suíte de casos e como escrever um leitor próprio |
| 8 | [Receitas](08-receitas.md) | Tarefas comuns, passo a passo |
| 9 | [Solução de problemas](09-problemas.md) | O que cada erro quer dizer e como resolver |
| 10 | [Glossário](10-glossario.md) | Os termos do manual |

## Leitura rápida

- **Vai escrever um grafo?** Leia os capítulos 2 e 3, e use o 9 quando o leitor reprovar.
- **Vai adotar num repositório?** Comece pelo capítulo 6 e siga para o [`ADOPTING.md`](../../ADOPTING.md).
- **Vai escrever um leitor em outra linguagem?** O capítulo 7 e o [`spec/conformance/README.md`](../../spec/conformance/README.md).

## Fontes da verdade

Este manual explica, mas não manda. Quando ele e um destes arquivos divergirem, valem os arquivos:

- o contrato: [`spec/kg-contract-v4.schema.json`](../../spec/kg-contract-v4.schema.json) (MUST) e
  [`spec/kg-contract-v4.should.schema.json`](../../spec/kg-contract-v4.should.schema.json) (SHOULD);
- a suíte: [`spec/conformance/`](../../spec/conformance/README.md);
- a superfície da release: [`spec/release.json`](../../spec/release.json).

Todas as saídas de comando deste manual foram coladas de uma execução real, em Python 3.12 com as versões de
[`tools/requirements.txt`](../../tools/requirements.txt).
