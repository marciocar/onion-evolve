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
Nas `external_edges`, o escopo é `top` e o campo leva o nome da lista (`form.enum.top.external_edges.edge_type`). Uma
data fora do calendário (`format: date`) reprova como `form.pattern.<escopo>.<campo>`.

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

As versões menores da linha 4 acrescentaram sem mudar o veredito MUST de um grafo bem escrito, com uma exceção
registrada: a 4.11.0, a 4.12.0 e a 4.13.0 passaram a reprovar construções raras do YAML (o perfil estrito), e foram menores
porque nenhum dos grafos reais medidos em quatro repos adotantes mudou de veredito. Mesmo assim, contam como MUST novo
para o critério de estável, e cada uma zerou o relógio de 30 dias. Desde a 4.11.0, o contrato tem rótulo próprio
(v4.4 na 4.11.0, v4.5 na 4.12.0, v4.6 na 4.13.0, v4.7 na 4.14.0, v4.8 na 4.15.0), que não é o número da release.

| Release | O que entrou |
|---|---|
| 4.1 | Quatro avisos SHOULD: `verified_against` ausente em claim carimbada, testemunho em PROD, verificação antes do fato, decisão sem origem |
| 4.2 | `provenance.locality`, e a dívida SHOULD do gate contada por ocorrência, como opção |
| 4.3 | `external_edges`, com a ponta externa conferida no corpus |
| 4.4 | O exportador de proveniência para PROV-O (`kg_prov_export.py`) |
| 4.5 | O veredito estruturado `kg-ssot.verdict/1` (`kg_validate.py --format json`) |
| 4.6 | O armazém que só grava o que o contrato aprova (`kg_store.py`) |
| 4.7 | O servidor MCP de referência (`kg_mcp.py`) e o teto de aninhamento e de aliases do leitor |
| 4.8 | O `.kg.json` como formato do contrato, lido no perfil JSON; o vendor com o próprio `.gitattributes` (4.8.1) e o veredito com a linha de cada ocorrência (4.8.2) |
| 4.9 | O pacote PyPI (`kg-ssot`) e o npm; na 4.9.1, o armazém no Windows |
| 4.10 | O servidor MCP pronto para produção: perfil atrás de proxy, as duas eras do protocolo, o gate externo por comando e a imagem OCI |
| 4.11 | Contrato v4.4: o aviso `integrity.refutes-unreconciled` e o perfil YAML estrito em três construções raras (MUST novo) |
| 4.12 | Contrato v4.5: `verified_scope`, `locality: privado`, a `REFUTES` externa contando com o corpus e o tab no começo de continuação entre aspas (MUST novo) |
| 4.13 | Contrato v4.6: a continuação entre aspas mais indentada que a coleção dona (MUST novo) e o `\r` como quebra de linha no leitor JS; na 4.13.1, a identidade do contrato acusa a versão que só o leitor muda, e o migrador lê o corpus do gate |
| 4.14 | Contrato v4.7: a ponta externa pode ser um `.kg.json`; o armazém grava um conjunto de grafos de uma vez (`write_many`) |
| 4.15 | Contrato v4.8: a cadência da verificação (`reverify_every`, `reverify_on`), a retenção (`retain_for`), o `owner` como papel e o relatório de vencimento (`kg_validate.py --due`), fora do veredito |

## Versões e tags

A release é uma tag `kg-ssot-vX.Y.Z` (até a 4.3.0, o nome era `contract-vX.Y.Z`; as tags antigas seguem
existindo). Pelo histórico das releases:

| Parte | Quando sobe |
|---|---|
| **X**, maior | Um veredito MUST muda: algo que passava reprova |
| **Y**, menor | Entra um aviso SHOULD, um campo opcional ou uma ferramenta ou formato novo no kit, e nenhum veredito MUST de grafo bem escrito muda |
| **Z**, patch | Correção ou melhoria do kit, do guia ou dos casos, com o mesmo contrato |

O gate guarda o sha256 dos dois schemas como a identidade do contrato. Uma tag que muda os bytes dos schemas,
mesmo que só no texto das descrições (a 4.7.2) ou no `$id` (a 4.7.3), pede `kg_gate.py --update` no PR que traz a tag, e o gate mostra
que nenhum veredito mudou. Uma regra que só o leitor vê (o perfil YAML, a quebra de linha) também entra na descrição
do schema MUST, como "No v4.6 ...": desde a 4.13.1, a higiene da release cobra essa linha para a versão que o leitor
declara, e assim toda versão do contrato move a identidade.

Um aviso SHOULD novo pode subir a dívida medida pelo gate. Isso é intencional: a rampa de um contrato é alertar
numa versão e reprovar na seguinte, e o adotante vê a dívida antes de ela virar erro.

A superfície que viaja em cada tag está em [`spec/release.json`](../../spec/release.json). O contrato não se
customiza no adotante: o vendor reprova edição local, e uma mudança necessária volta ao produto como issue no
repositório público.

## Os contratos antigos

O repositório do produto guarda o v1, o v2 e o v3 em `spec/` como histórico; a release leva só o v4, o vigente, que
é o que o leitor usa sem `--schema`.
