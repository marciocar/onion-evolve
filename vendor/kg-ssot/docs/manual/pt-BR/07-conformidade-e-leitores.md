<!-- translation-of: docs/manual/07-conformance-and-readers.md sha256:6e5887ce411602a6 -->
# 7. Conformidade e leitores

[English](../07-conformance-and-readers.md) | **Português (Brasil)**

<sub>Tradução do original em inglês; quando os dois divergirem, vale o inglês.</sub>

[← Adoção e CI](06-adocao-e-ci.md) · [Índice](README.md) · [Receitas →](08-receitas.md)

O contrato vale para **todo leitor** de `.kg.yaml`: um visualizador, um extrator, um port em JavaScript, um
validador em Go. Um leitor prova que segue o contrato passando na suíte, não lendo a especificação e achando que
entendeu. A referência completa é [`spec/conformance/README.pt-BR.md`](../../../spec/conformance/README.pt-BR.md).

## Como a suíte é feita

- Cada **grupo** é uma pasta com um `manifest.json` e um `.kg.yaml` (ou `.kg.json`) real por caso. O arquivo é real
  para que qualquer CLI o leia como leria um grafo de verdade.
- Cada caso declara `valid`, os `codes` (MUST) e os `warnings` (SHOULD) esperados. `warnings` é opcional, e a lista
  ausente vale `[]`.
- **Um caso, um defeito.** O leitor passa num caso quando o **conjunto** de códigos que emite é **igual** ao
  esperado. Igualdade, não inclusão: um leitor que acusa tudo não passa. Ordem e repetição não contam.
- A suíte valida a si mesma: o `manifest.schema.json` confere todo manifesto, e `metaschema-tests/` tem manifestos
  que o schema tem de aceitar e outros que tem de recusar.

```json
{
  "description": "Os enums do nó.",
  "layer": "form",
  "pending_on": [],
  "cases": [
    {
      "file": "bad-node-type-enum.kg.yaml",
      "description": "node_type fora do enum",
      "valid": false,
      "codes": [
        "form.enum.node.node_type"
      ]
    }
  ]
}
```

| Pasta | O que vale |
|---|---|
| `fixtures/latest/` | O contrato vigente. Todo leitor **tem** de passar |
| `fixtures/optional/` | Comportamento que um leitor **pode** implementar. Reporta e não reprova |
| `fixtures/proposals/` | Casos que dependem de decisão aberta. Hoje está vazia |

## Escrever um leitor

1. **Parse.** Leia YAML com os booleanos do YAML 1.2, um documento só e um mapa na raiz. Chave duplicada reprova
   (`1` e `"1"` colidem). `.nan` e `.inf` reprovam. Um arquivo `.kg.json` passa por um parser JSON no perfil JSON do
   contrato.
2. **Forma.** Converta para o JSON canônico (datas como texto ISO, chaves como texto) e valide contra
   `kg-contract-v4.schema.json`, com `format` como **asserção**. Os avisos vêm do
   `kg-contract-v4.should.schema.json`.
3. **Integridade.** Confira ids únicos, pontas existentes (`from`, `to`, `trigger`), nenhum nó de grau 0, as pontas
   das `external_edges` e os avisos `integrity.*` que cruzam campos ou arestas.
4. **Códigos.** Mapeie cada erro para o seu código estável. A tabela de códigos e as regras de nomeação estão no
   [capítulo 4](04-contrato.md#códigos) e na referência da suíte.

O leitor de referência, [`tools/kg_validate.py`](../../../tools/kg_validate.py), é o molde. Os comentários dele
explicam cada regra, para você o ler ao lado da suíte.

### Três armadilhas que a suíte pega

- **Tamanho de texto em code points.** O limite de 280 caracteres do `label` conta code points, como o `maxLength`
  do JSON Schema. Um emoji vale 1. O `str.length` do JavaScript conta 2.
- **`format: date` como anotação.** Muitos validadores pulam a checagem de formato por padrão. Aqui a data ruim
  reprova.
- **`$` antes de quebra de linha.** Os `pattern` seguem a semântica do ECMA-262: `$` não casa antes de uma quebra
  de linha final, ao contrário do `re` do Python.

## Rodar a suíte com o seu leitor

O `kg_conformance.py` roda só o leitor de referência, e o kit não traz uma ferramenta que rode um leitor de fora
sobre a suíte. O seu leitor roda a suíte com o próprio código: itera os `manifest.json` de `fixtures/latest/`, julga cada caso (com a
raiz do repositório em `<pasta do manifesto>/<corpus>` quando o caso declara `corpus`) e compara os conjuntos de
`codes` e de `warnings` por igualdade. Um leitor que não expõe códigos compara só o veredito: `valid: true` quer
dizer aceitar, e `valid: false` quer dizer reprovar.

## O contrato de runner

Para o mantenedor medir o seu leitor ao lado do leitor de referência, caso a caso, o seu leitor expõe um
**runner**: `runner <caso>` imprime um objeto JSON na última linha do stdout e sai com rc 0.

```json
{"verdict": "accept", "codes": [], "warnings": [], "detail": ""}
```

- `verdict`: `accept`, `reject` ou `error`. É o nível 1, e todo leitor o tem.
- `codes` e `warnings`: as listas de códigos, ou `null` se o leitor não diz o porquê. É o nível 2.
- Um caso que declara `corpus` no manifesto chega como `runner <caso> --corpus <dir>`.
- Saída que não é JSON, um `verdict` desconhecido, rc diferente de 0 ou tempo estourado contam como `error`.

Um leitor que só dá o veredito já é comparável no nível 1. Expor os códigos é o nível 2, e é o que permite
diagnosticar uma divergência.
