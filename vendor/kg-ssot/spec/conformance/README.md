# Suíte de conformidade do `.kg.yaml`

> **Projeção do grafo do produto KG-SSOT, nunca fonte paralela** (os ids entre crases são nós dele). O formato
> é o de `A_CONFORMANCE_SUITE_SEED` (`EPIC_1_SUITE_FORMAT`). Os casos medem o contrato v3
> (`A_CONTRACT_V3`): `spec/kg-contract-v3.schema.json` (MUST) e `spec/kg-contract-v3.should.schema.json`
> (SHOULD), com as cinco decisões do E0 e a proveniência estruturada.

Todo leitor de `.kg.yaml` tem de passar nesta suíte: o radar e o drive do Onion, um extrator de grafos,
o port JS de um adotante e o leitor de referência `tools/kg_validate.py`. Os casos são **dados puros**,
no molde da JSON-Schema-Test-Suite (`E_JSONSCHEMA_TEST_CASE_AS_PURE_DATA`), e não dependem de Claude
Code (`D_KG_SSOT_INDEPENDENTE_DE_HARNESS`).

## Formato

Um **grupo** é uma pasta com um `manifest.json` e um `.kg.yaml` real por caso. O arquivo é real, e não
texto embutido no JSON, para que qualquer CLI receba o caminho e leia como leria um grafo de verdade.

```json
{
  "description": "enums do nó",
  "layer": "form",
  "pending_on": [],
  "cases": [
    { "file": "bad-node-type.kg.yaml",
      "description": "node_type fora do enum",
      "valid": false,
      "codes": ["form.enum.node.node_type"],
      "warnings": [] }
  ]
}
```

| Campo | Regra |
|---|---|
| `layer` | `parse`, `form`, `integrity`, `yaml` ou `semantic`: a camada que o grupo exercita. `semantic` só existe em `optional/`. |
| `pending_on` | Ids das decisões abertas de que o veredito depende. Vazio em `latest/`, não vazio em `proposals/`. |
| `valid` | `true` exige `codes: []`. `false` exige pelo menos um código. |
| `codes` | Violações de **MUST**: reprovam o arquivo. |
| `warnings` | Violações de **SHOULD**: só alertam, e o arquivo continua válido. É opcional, e ausente vale `[]`. |

O `manifest.schema.json` (JSON Schema 2020-12) valida todo manifesto. A própria suíte se valida com a
mesma tecnologia do contrato (`E_JSONSCHEMA_SUITE_SELF_METASCHEMA_CI`, no mesmo grafo de pesquisa). Em `metaschema-tests/` há os
manifestos que ele tem de aceitar (`good/`) e os que tem de recusar (`bad/`).

**Um caso, um defeito.** O leitor passa num caso quando o **conjunto** de códigos que emite é
**igual** ao esperado, tanto em `codes` quanto em `warnings`. Igualdade, não inclusão: um leitor que
acusa tudo não pode passar. Ordem e repetição não contam.

## Códigos

Cada código é um slug estável por camada, e o metaschema confere a forma.

| Camada | Forma | Exemplos |
|---|---|---|
| parse | `parse.<motivo>` | `parse.yaml-error`, `parse.duplicate-key`, `parse.empty-document`, `parse.not-single-document`, `parse.root-not-mapping` |
| form | `form.<tipo>.<escopo>.<campo>` | `form.required.node.label`, `form.enum.node.node_type`, `form.range.node.impact`, `form.pattern.edge.to`, `form.type.node.item` |
| integrity | `integrity.<regra>` | `integrity.duplicate-id`, `integrity.dangling-from`, `integrity.dangling-to`, `integrity.dangling-trigger`, `integrity.orphan-node` |
| yaml | `yaml.<regra>` | `yaml.forbidden-key-on` (MUST), `yaml.unquoted-date` (SHOULD) |
| semantic | `semantic.<regra>` | `semantic.contradiction` (MUST); `semantic.supersedes-unreconciled`, `semantic.decision-done-dev`, `semantic.stale-missing` (SHOULD) — só em `optional/` |

`<tipo>` ∈ `required enum type pattern range const unknown-key`. `<escopo>` ∈ `top meta node edge`.
Num objeto aninhado, `<campo>` é o caminho com ponto: `form.required.node.provenance.locator`.
`range` cobre também o tamanho de texto: `label: ""` (MUST) e `label` acima de 280 caracteres
(SHOULD, a narrativa vai para `narrative`). O tamanho conta code points, como o `maxLength` do JSON
Schema: um emoji vale 1, não 2 unidades UTF-16 (`str.length` de JS erraria), e não há normalização.
Data completa tem de existir no calendário, e o código é `form.pattern`: o `format: date` do schema é
**asserção**, e todo leitor tem de checá-lo. `.nan` e `.inf` reprovam como `form.type` em qualquer
posição, também em chave `x_` e dentro de lista, porque o JSON não os representa. Um item de lista que não é mapa usa o
campo `item` (`form.type.node.item`). Nome de chave que não é slug (`<<`, `1.0`) alerta como
`form.pattern.<escopo>.key`. As chaves são comparadas na forma JSON: `1` e `"1"` colidem
(`parse.duplicate-key`), `true` vira `true`, não `True`. Uma aresta com `on` reprova por
`yaml.forbidden-key-on`; se o alvo de `on` não existir, sai também `integrity.dangling-on`. `unknown-key` é SHOULD no v1 (chave fora da gramática e
sem o prefixo `x_`) e vira MUST na próxima versão. Os `pattern` têm a semântica do ECMA-262, a do JSON
Schema: `$` não casa antes de uma quebra de linha final.
O mesmo código pode aparecer como MUST num caso e como SHOULD em outro, porque a severidade é do
caso, não do código.

## Pastas

Os casos moram em `fixtures/`, a convenção de diretório de teste que validadores de repositório
costumam isentar. Sem isso, os grafos quebrados de propósito reprovariam o próprio repo. A exceção
é `latest/parse/document/bad-yaml-syntax.yaml`: há validador que varre todo `.kg.yaml` rastreado sem
respeitar a convenção, e o único caso não parseável usa a extensão `.yaml` (o metaschema aceita as
duas). Dentro de cada pasta, o grupo é livre; por convenção, `latest/<camada>/<grupo>/`.

| Pasta | O que vale |
|---|---|
| `fixtures/latest/` | O contrato vigente. O leitor **tem** de passar em todos os casos. |
| `fixtures/optional/` | Comportamento que um leitor **pode** implementar; hoje, `semantic/`, a camada do radar. Roda e reporta, mas não reprova, e entra na matriz leitor × caso. |
| `fixtures/proposals/` | O veredito depende de decisão aberta (`pending_on`). Roda e reporta, mas não reprova. |

**Regra de promoção.** Um grupo sai de `proposals/` para `latest/` só quando **todas** as decisões em
`pending_on` estiverem seladas, isto é, mergeadas no grafo do produto, **e** o schema de `spec/` já
aceitar o que o grupo exige (ex.: `trigger` em `integrity-trigger`). O PR da promoção esvazia
`pending_on` e cita o nó selado. Nada antecipa decisão aberta.

**O placar de hoje.** O leitor de referência passa em 100% de `latest/`, e `proposals/` está vazia:
toda decisão de contrato está aplicada. Ela volta a ter casos quando abrir uma pergunta nova, como
`Q_CONTRACT_STRUCTURED_PROVENANCE`.

## Rodar

```bash
pip install -r tools/requirements.txt          # PyYAML e jsonschema, versões exatas
python3 -I tools/kg_conformance.py             # --suite DIR, --schema F, --should-schema F, --json OUT
```

rc `0` se `latest/` passa inteiro, `1` se algum caso de `latest/` falha e `2` se a própria suíte está
quebrada: metaschema ou manifesto ilegível ou inválido, `pending_on` fora da regra, pasta
desconhecida, arquivo ausente, repetido ou fora de todo manifesto, ou `latest/` vazia. Um leitor que
cai num caso conta como falha daquele caso. `optional/` (hoje só a camada `semantic`, que o leitor de referência
não implementa) e `proposals/` reportam
e nunca mudam o rc.

## O contrato de runner

Para ser medido caso a caso (a matriz leitor × caso do produto), um leitor implementa o **contrato de
runner**: `runner <caso>` imprime, na última linha do stdout, UM objeto JSON, e sai com rc 0:

```json
{"verdict": "accept" | "reject" | "error", "codes": [...] | null, "warnings": [...] | null, "detail": "..."}
```

- `verdict` é o nível 1, e todo leitor o tem: o arquivo é aceito ou reprovado? Um caso com `codes` MUST
  espera `reject`; um caso válido, mesmo com `warnings`, espera `accept`.
- `codes` é o nível 2, só para quem expõe motivo, comparado por conjunto nas camadas que o registro declara
  em `layers`. `null` quer dizer que o leitor não diz o porquê.
- `error` quer dizer que o leitor caiu. Saída que não é JSON, `verdict` desconhecido, rc diferente de 0 ou
  tempo estourado também viram `error`. É divergência e nunca some da matriz.

## Higiene

Os casos são escritos aqui, sem copiar as fixtures do core, e usam ids sintéticos (`Q_A`, `EV_A`...),
sem caminho de máquina e sem id de nó privado (`EPIC_7_PUBLICATION_HYGIENE`). Este arquivo viaja na release
(`spec/release.json`): o que é operação do repo do produto (a matriz, a catraca, a paridade) não mora aqui, e o
a conferência de higiene do mantenedor reprova referência privada em `spec/` e nos arquivos da release.
