# 4. O contrato

[← Referência do formato](03-formato.md) · [Índice](README.md) · [Ferramentas →](05-ferramentas.md)

## Dois níveis: MUST e SHOULD

| Nível | Arquivo | Efeito |
|---|---|---|
| **MUST** | `spec/kg-contract-v4.schema.json` | Reprova o arquivo. O leitor sai com rc 1 |
| **SHOULD** | `spec/kg-contract-v4.should.schema.json` | Só alerta. O arquivo segue válido |

Os dois são JSON Schema 2020-12 escritos à mão. Além deles, o contrato tem as regras de **perfil YAML** (um
documento só, chave duplicada, chave `on`) e as de **integridade** (ids, pontas, órfãos), que o JSON Schema não
vê. Por isso, um validador de JSON Schema sozinho não é um leitor completo: o leitor de referência aplica as três
camadas, e a suíte cobra as três de todo leitor.

O `format: date` do schema é **asserção**: a data tem de existir no calendário (`2026-02-30` reprova). Muitos
validadores tratam `format` como anotação por padrão, e por isso a suíte tem casos para isso.

## Códigos

Toda violação tem um código estável, com a forma da camada:

| Camada | Forma | Exemplos |
|---|---|---|
| parse | `parse.<motivo>` | `parse.yaml-error`, `parse.duplicate-key`, `parse.not-single-document` |
| form | `form.<tipo>.<escopo>.<campo>` | `form.required.node.label`, `form.enum.node.status`, `form.unknown-key.node.prioridade` |
| integrity | `integrity.<regra>` | `integrity.orphan-node`, `integrity.dangling-to` |
| yaml | `yaml.<regra>` | `yaml.forbidden-key-on` (MUST), `yaml.unquoted-date` (SHOULD) |

`<tipo>` é um de `required`, `enum`, `type`, `pattern`, `range`, `const` ou `unknown-key`. `<escopo>` é um de
`top`, `meta`, `node` ou `edge`. Num campo aninhado, o caminho leva ponto: `form.required.node.provenance.locator`.

A lista completa, com o que cada código pega, está em
[`spec/conformance/README.md`](../../spec/conformance/README.md#códigos).

## O que mudou do v3 para o v4

O v4 é uma versão **maior**: o que alertava passou a reprovar.

| Código | v3 | v4 |
|---|---|---|
| `form.required.node.provenance` (nó `confirmed` ou PROD sem `provenance`, fora o `unverifiable`) | SHOULD | **MUST** |
| `form.unknown-key.<escopo>.<chave>` (chave fora da gramática, sem `x_`) | SHOULD | **MUST** |
| `form.pattern.<escopo>.key` (nome de chave que não é slug, sem `x_`) | SHOULD | **MUST** |
| `form.pattern.node.provenance.source` (`source` marcador) | — | **MUST** |
| `form.pattern.node.provenance.method` (fora de `<classe>: <detalhe>`) | — | SHOULD (MUST no v5) |

As versões menores da linha 4 só acrescentaram, sem mudar veredito:

| Release | O que entrou |
|---|---|
| 4.1 | Quatro avisos SHOULD: `verified_against` ausente em claim carimbada, testemunho em PROD, verificação antes do fato, decisão sem origem |
| 4.2 | `provenance.locality`, e a dívida SHOULD do gate contada por ocorrência, como opção |
| 4.3 | `external_edges`, com a ponta externa conferida no corpus |

## Versões e tags

A release é uma tag `kg-ssot-vX.Y.Z` (até a 4.3.0, o nome era `contract-vX.Y.Z`; as tags antigas seguem
existindo). Pelo histórico das releases:

| Parte | Quando sobe |
|---|---|
| **X**, maior | Um veredito MUST muda: algo que passava reprova |
| **Y**, menor | Entra um aviso SHOULD ou um campo opcional, e nenhum veredito MUST muda |
| **Z**, patch | Correção ou melhoria do kit, do guia ou dos casos, com o mesmo contrato |

Um aviso SHOULD novo pode subir a dívida medida pelo gate. Isso é intencional: a rampa de um contrato é alertar
numa versão e reprovar na seguinte, e o adotante vê a dívida antes de ela virar erro.

A superfície que viaja em cada tag está em [`spec/release.json`](../../spec/release.json). O contrato não se
customiza no adotante: o vendor reprova edição local, e uma mudança necessária volta ao produto como pedido.

## Os contratos antigos

O repositório do produto guarda o v1, o v2 e o v3 em `spec/` como histórico; a release leva só o v4, o vigente, que
é o que o leitor usa sem `--schema`.
