# kg-ssot

**O leitor JavaScript do contrato do KG-SSOT, o grafo de conhecimento verificável: toda afirmação diz de onde veio,
quando foi conferida e o que depende dela.**

Este pacote julga um grafo `.kg.yaml` ou `.kg.json` contra o contrato vigente e devolve o veredito MUST e os avisos
SHOULD, com os códigos estáveis da suíte de conformidade. Ele traz:
- o **núcleo do leitor**, sem `fs` e sem processo;
- os **validadores do contrato pré-compilados**, MUST e SHOULD, que não usam `new Function` nem `eval`. Por isso rodam
  em motores sem geração de código, como o Hermes do React Native e do Expo, e no Node;
- os **schemas** do contrato e do veredito.

O leitor de referência é o pacote Python [`kg-ssot`](https://pypi.org/project/kg-ssot/). Este leitor passa em todos
os casos da suíte de conformidade (`latest/`), com o veredito, os códigos e os avisos esperados. O CI confere isso
pelo pacote instalado a cada mudança no leitor.

## Instalar

```bash
npm install kg-ssot
```

## No código

```js
import { verdict } from 'kg-ssot';

verdict(texto);                      // .kg.yaml (o default)
verdict(texto, { format: 'json' });  // .kg.json
// { verdict: 'accept', codes: [], warnings: [], detail: '' }
// { verdict: 'accept', codes: [], warnings: ['yaml.unquoted-date'], detail: '' }
// { verdict: 'reject', codes: ['form.range.node.impact'], warnings: [], detail: '' }
```

- `verdict(texto, { format, corpus })` devolve o veredito no contrato de runner da suíte: `verdict` é `accept` ou
  `reject`, `codes` traz os códigos MUST e `warnings` os avisos SHOULD, os dois ordenados e sem repetição. Um aviso
  não reprova: o grafo com aviso continua `accept`.
- `check(texto, { format, corpus })` devolve só os códigos MUST (vazio quando passa), e `checkWarnings(texto,
  { format })` só os avisos.
- `kg-ssot/core` é o núcleo sem o validador, para quem compila o schema por conta própria. `kg-ssot/node` traz os
  auxiliares de Node, como `corpusIndex(dir)`, que indexa os `.kg.yaml` de um diretório para conferir as
  `external_edges`. Os schemas ficam em `kg-ssot/spec/*`.

Desde a 4.10.0, este leitor também mede os avisos SHOULD, com os mesmos códigos do leitor de referência em todos os
casos da suíte, e desde a 4.13.0 trata o `\r` como quebra de linha, como a referência. Desde a 4.11.0, as três construções raras do YAML em que ele divergia da referência (a tag `!` sem
nome, o `!!timestamp` com texto que não é data e o tab fora de aspas) reprovam nos dois, com casos na suíte. A linha de cada ocorrência e as dicas de correção continuam só no leitor de referência em Python.

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
  AVISO  yaml.unquoted-date
REPROVA outro.kg.json
  MUST   form.range.node.impact · integrity.orphan-node
```

O rc é 0 quando todos passam, 1 quando algum reprova e 2 com arquivo ilegível ou opção desconhecida. Os avisos não
mudam o rc. Com `--json`, sai uma linha JSON por
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
