# kg-ssot

**O leitor JavaScript do contrato do KG-SSOT, o grafo de conhecimento verificável: toda afirmação diz de onde veio,
quando foi conferida e o que depende dela.**

Este pacote julga um grafo `.kg.yaml` ou `.kg.json` contra o contrato vigente e devolve o veredito MUST com os
códigos estáveis da suíte de conformidade. Ele traz:
- o **núcleo do leitor**, sem `fs` e sem processo;
- o **validador do contrato pré-compilado**, que não usa `new Function` nem `eval`. Por isso roda em motores sem
  geração de código, como o Hermes do React Native e do Expo, e no Node;
- os **schemas** do contrato e do veredito.

O leitor de referência é o pacote Python [`kg-ssot`](https://pypi.org/project/kg-ssot/). Este leitor passa em todos
os casos da suíte de conformidade (`latest/`), com o veredito e os códigos esperados. O CI confere isso pelo pacote
instalado a cada mudança no leitor.

## Instalar

```bash
npm install kg-ssot
```

## No código

```js
import { verdict } from 'kg-ssot';

verdict(texto);                      // .kg.yaml (o default)
verdict(texto, { format: 'json' });  // .kg.json
// { verdict: 'accept', codes: [], warnings: null, detail: '' }
// { verdict: 'reject', codes: ['form.range.node.impact'], warnings: null, detail: '' }
```

- `verdict(texto, { format, corpus })` devolve o veredito no contrato de runner da suíte: `verdict` é `accept` ou
  `reject`, e `codes` traz os códigos MUST, ordenados e sem repetição.
- `check(texto, { format, corpus })` devolve só os códigos (vazio quando passa).
- `kg-ssot/core` é o núcleo sem o validador, para quem compila o schema por conta própria. `kg-ssot/node` traz os
  auxiliares de Node, como `corpusIndex(dir)`, que indexa os `.kg.yaml` de um diretório para conferir as
  `external_edges`. Os schemas ficam em `kg-ssot/spec/*`.

Este leitor mede só o MUST: `warnings` sai nulo. Para os avisos SHOULD, a linha de cada ocorrência e as dicas de
correção, use o leitor de referência em Python.

## TypeScript e CommonJS

O pacote traz os tipos (`index.d.mts`, `core.d.mts` e `node.d.mts`) e funciona com `moduleResolution` `bundler` ou
`nodenext`, o que cobre o template TypeScript do Expo. É um pacote ESM. Num projeto CommonJS, o `require('kg-ssot')`
funciona a partir do Node 22.12, que é o mínimo declarado em `engines`.

## Na linha de comando

```bash
npx kg-ssot-validate grafo.kg.yaml outro.kg.json
```

```text
PASSA   grafo.kg.yaml
REPROVA outro.kg.json
  MUST   form.range.node.impact · integrity.orphan-node
```

O rc é 0 quando todos passam, 1 quando algum reprova e 2 com arquivo ilegível ou opção desconhecida. Com `--json`, sai uma linha JSON por
arquivo. Com `--corpus DIR`, a ponta externa das `external_edges` é conferida contra os `.kg.yaml` sob `DIR`.

## Num app React Native ou Expo

O pacote é ESM e a entrada não importa nada do Node. Um bundler (Metro, esbuild) resolve as dependências, `yaml` e o
runtime do `ajv`. O validador já vem compilado, então nada precisa gerar código no aparelho. O comportamento foi
medido no Hermes: os mesmos vereditos do Node.

## Documentação

- [Manual](https://github.com/marciocar/kg-ssot/tree/main/docs/manual): o formato, o contrato, as ferramentas e os problemas comuns
- [Suíte de conformidade](https://github.com/marciocar/kg-ssot/blob/main/spec/conformance/README.md)
- [Guia de adoção](https://github.com/marciocar/kg-ssot/blob/main/ADOPTING.md)

## Licença

Apache-2.0. Veja `LICENSE` e `NOTICE`.
