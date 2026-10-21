# 3. Referência do formato

[← Conceitos](02-conceitos.md) · [Índice](README.md) · [O contrato →](04-contrato.md)

Tirado de [`spec/kg-contract-v4.schema.json`](../../spec/kg-contract-v4.schema.json) (MUST) e
[`spec/kg-contract-v4.should.schema.json`](../../spec/kg-contract-v4.should.schema.json) (SHOULD). Se esta
página e o schema divergirem, vale o schema.

Convenções: **obr.** = obrigatório; *data* = texto `AAAA-MM-DD` que existe no calendário.

## Arquivo

- YAML, **um documento só**, com a raiz sendo um mapa.
- Booleanos do YAML 1.2: só `true` e `false` (também em `True`, `TRUE`, `False`, `FALSE`). `yes`, `no`, `on` e
  `off` são texto.
- Chaves comparadas na forma JSON: `1` e `"1"` colidem (`parse.duplicate-key`).
- `.nan` e `.inf` reprovam em qualquer posição, porque o JSON não os representa.
- Texto entre aspas em várias linhas: cada linha de continuação mais indentada que o mapa ou a lista que o contém.
- Tab só dentro de aspas (fora do espaço inicial de uma linha de continuação), de bloco literal (`|` ou `>`) e de comentário. Como espaço (depois de `:`, no fim da linha,
  entre a data e a hora) ou dentro de um texto sem aspas, reprova (`parse.yaml-error`). Use espaço.
- A tag `!` sem nome (também `!<!>`) reprova, e o `!!timestamp` explícito só aceita texto na forma de data
  (`AAAA-M-D`, com hora opcional `H:MM:SS`, fração com dígito e fuso `Z` ou `±H[:MM]`, até ±29). A forma é conferida,
  o calendário não. Sem tag, escreva a data entre aspas.
- O perfil JSON vale também no `.kg.yaml`, como aviso: inteiro fora de ±(2^53−1) (`yaml.unsafe-integer`), surrogate
  solto (`yaml.lone-surrogate`) e mais de 128 coleções aninhadas (`yaml.depth-over-128`).

### O mesmo modelo em `.kg.json`

O grafo pode vir em JSON, num arquivo `.kg.json` (a extensão é sensível a maiúsculas), com os mesmos campos e as
mesmas regras. Ele é lido por um parser JSON, no perfil JSON do contrato, e cada ponto do perfil reprova:

- sintaxe da RFC 8259: sem comentário, vírgula sobrando, aspas simples, `NaN` ou `Infinity`. O espaço em branco é só
  espaço, tab, LF e CR, e um BOM inicial é aceito e descartado;
- I-JSON (RFC 7493): sem surrogate solto, em chave ou valor, e todo número de valor inteiro dentro de ±(2^53−1),
  escrito como inteiro ou como float (`9007199254740993` e `1e20` reprovam);
- no máximo 128 coleções aninhadas, contando a raiz;
- chave única em cada objeto, comparada depois dos escapes (`"label"` e `"\u006cabel"` colidem).

A sintaxe inválida sai como `parse.yaml-error`, porque o vocabulário de códigos não tem um código próprio do JSON.
Quando a sintaxe falha, ela decide antes da chave repetida. O gate (`kg_gate.py`) e as `external_edges` seguem só
com `.kg.yaml`.

## Topo

| Chave | Tipo | Regra |
|---|---|---|
| `meta` | mapa | obr. |
| `nodes` | lista de nós | obr. Lista vazia é válida, mas alerta (`form.range.top.nodes`) |
| `edges` | lista de arestas | obr. Pode ser vazia |
| `external_edges` | lista de arestas externas | opcional (desde a 4.3) |
| `x_*` | qualquer | extensão livre |

## `meta`

| Chave | Tipo | Regra |
|---|---|---|
| `schema_version` | texto | obr. Exatamente `"1"` |
| `id` | texto | obr. Não vazio |
| `baseline` | *data* | quando o grafo foi medido pela primeira vez |
| `date` | *data* | |
| `review_after` | *data* | quando o grafo deve ser revisto |
| `layer` | `audit` · `domain` | |
| `note` · `purpose` | texto | narrativa do grafo |
| `x_*` | qualquer | |

## Nó

| Chave | Tipo | Regra |
|---|---|---|
| `id` | texto | obr. `^[A-Za-z][A-Za-z0-9_]*$`, único no arquivo |
| `node_type` | enum | obr. `entity` `claim` `decision` `question` `evidence` `artifact` `state` `event` `rule` `invariant` `policy` |
| `plane` | enum | obr. `DEV` · `PROD` |
| `status` | enum | obr. `open` `confirmed` `drifted` `unverifiable` `refuted` `superseded` `done` |
| `impact` | inteiro | obr. 1 a 5 |
| `confidence` | número | obr. 0 a 1 |
| `label` | texto | obr. Não vazio. SHOULD: até 280 caracteres |
| `provenance` | mapa | **obr. quando `status: confirmed` ou `plane: PROD`, exceto `status: unverifiable`** |
| `trace` | texto | onde a afirmação aparece (arquivo, caminho) |
| `verified_at` | *data* | SHOULD em nó PROD |
| `verified_against` | texto | SHOULD em `claim` com `verified_at` |
| `verified_scope` | enum | opcional, desde o v4.5: o alcance do `verified_at`. `fato` (o que o nó afirma foi conferido), `mecanismo` (só o mecanismo, como código ou configuração; o fato depende de outro ambiente) ou `nenhum` (conferido contra o repo na data, e nada ali sustenta nem refuta o fato). Fora do enum alerta; sem `verified_at` alerta |
| `reverify_every` | duração | opcional, desde o v4.8: de quanto em quanto tempo a verificação tem de ser refeita, em duração ISO 8601 só com data (`P3M`, `P1Y`, `P2W`, `P1Y6M`). Fora da forma alerta; sem `verified_at` alerta, porque a cadência conta do carimbo. O vencimento nunca muda o veredito: `kg_validate.py --due` o lista |
| `reverify_on` | texto | opcional, desde o v4.8: o gatilho por evento ("a cada mudança de configuração", "por admissão") |
| `retain_for` | duração | opcional, desde o v4.8: por quanto tempo a evidência tem de ser guardada, na mesma duração |
| `valid_from` | data parcial | `AAAA`, `AAAA-MM` ou `AAAA-MM-DD` |
| `source_tier` | inteiro | 1 a 10 |
| `source_kind` | texto | |
| `owner` | texto | o papel que responde pelo nó (`cto`, `engenharia`), e não o nome de uma pessoa: a pessoa muda, o papel fica |
| `drive_kind` · `evidence_class` | texto | |
| `sealed_by` · `sealed_at` | texto | quem selou a decisão e quando |
| `narrative` | texto | a história por trás do `label` |
| `layer` | `audit` · `domain` | |
| `x_*` | qualquer | |

### `provenance`

| Chave | Tipo | Regra |
|---|---|---|
| `source` | texto | obr. Não vazio e não marcador (`unknown`, `n/a`, `tbd`, `?`...) |
| `locator` | texto | obr. Não vazio |
| `method` | texto | obr. Não vazio. SHOULD: `<classe>: <detalhe>`, classe em `medição` `leitura` `juízes` `derivado` `testemunho` |
| `locality` | enum | opcional. `repo` `web` `host` `pessoa` `privado` (fora do enum alerta). Vale onde está a cópia lida, não a classificação do documento |
| `x_*` | qualquer | outra chave alerta, não reprova |

`provenance: null` reprova. Ou o objeto vem inteiro, ou não vem.

## Aresta

| Chave | Tipo | Regra |
|---|---|---|
| `from` | id | obr. Tem de existir no arquivo |
| `to` | id | obr. Tem de existir no arquivo |
| `edge_type` | enum | obr. `SUPPORTS` `REFUTES` `SUPERSEDES` `CAUSES` `DEPENDS_ON` `TRACES_TO` `CONSTRAINS` `HAS_STATE` `TRANSITIONS` `EMITS` `READS` `WRITES` |
| `label` | texto | |
| `trigger` | id | o evento de uma `TRANSITIONS`. Tem de existir no arquivo |
| `on` | — | **proibida**: use `trigger` |
| `x_*` | qualquer | |

## Aresta externa

| Chave | Tipo | Regra |
|---|---|---|
| `from` | id ou referência | id deste arquivo, ou ausente (o grafo inteiro), ou a ponta externa |
| `to` | id ou referência | obr. Exatamente uma das duas pontas é externa |
| `edge_type` | enum | obr. `SUPERSEDES` `CONSTRAINS` `SUPPORTS` `REFUTES` `TRACES_TO` `DEPENDS_ON` |
| `label` | texto | |
| `x_*` | qualquer | |

Uma referência externa é `<caminho>.kg.yaml#<id>`, ou `<caminho>.kg.json#<id>` desde o v4.7, com o caminho relativo à raiz do repositório e escrito com
`/`. Cada segmento começa por letra, dígito ou `_`. Caminho absoluto, `..`, `\` e `:` reprovam.

## Integridade (fora do schema)

O schema não alcança estas regras, e todo leitor tem de aplicá-las:

| Regra | Nível | Código |
|---|---|---|
| ids únicos no arquivo | MUST | `integrity.duplicate-id` |
| `from`, `to` e `trigger` apontam para nó existente | MUST | `integrity.dangling-from` · `-to` · `-trigger` |
| nenhum nó sem aresta (grau 0) | MUST | `integrity.orphan-node` |
| a ponta local de uma aresta externa existe | MUST | `integrity.dangling-external-local` |
| a ponta externa existe (só com o corpus) | MUST | `integrity.dangling-external` |
| nó PROD sustentado só por testemunho | SHOULD | `integrity.testimony-in-prod` |
| `verified_at` anterior a `valid_from` | SHOULD | `integrity.verified-before-fact` |
| `decision` viva sem `trace`, sem `provenance` e sem `TRACES_TO` saindo dela | SHOULD | `integrity.untraced-decision` |
| nó que recebe `REFUTES` e segue vivo (nem `superseded` nem `refuted`; a `question` `done` já está respondida) | SHOULD (MUST depois) | `integrity.refutes-unreconciled` |

Uma aresta externa conta como ligação: o nó ligado só por ela não é órfão.
