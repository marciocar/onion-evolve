<!-- translation-of: docs/manual/03-format.md sha256:d32560d49c4e0e25 -->
# 3. Referência do formato

[English](../03-format.md) | **Português (Brasil)**

<sub>Tradução do original em inglês; quando os dois divergirem, vale o inglês.</sub>

[← Conceitos](02-conceitos.md) · [Índice](README.md) · [O contrato →](04-contrato.md)

Esta página vem de [`spec/kg-contract-v4.schema.json`](../../../spec/kg-contract-v4.schema.json) (MUST) e
[`spec/kg-contract-v4.should.schema.json`](../../../spec/kg-contract-v4.should.schema.json) (SHOULD). Se esta
página e o schema divergirem, vale o schema.

Convenções: **obr.** = obrigatório; *data* = texto `AAAA-MM-DD` que existe no calendário.

## Arquivo

- YAML, **um documento só**, com a raiz sendo um mapa.
- Booleanos do YAML 1.2: só `true` e `false` (também em `True`, `TRUE`, `False`, `FALSE`). `yes`, `no`, `on` e
  `off` são texto.
- Chaves comparadas na forma JSON: `1` e `"1"` colidem (`parse.duplicate-key`).
- `.nan` e `.inf` reprovam em qualquer posição, porque o JSON não os representa.
- Texto entre aspas em várias linhas: indente cada linha de continuação mais que o mapa ou a lista que o contém.
- Tab só dentro de aspas (mas não no espaço inicial de uma linha de continuação), de bloco literal (`|` ou `>`) e de
  comentário. Tab usado como espaço (depois de `:`, no fim da linha, entre a data e a hora) ou dentro de um texto sem
  aspas reprova (`parse.yaml-error`). Use espaço.
- A tag `!` sem nome (também `!<!>`) reprova, e o `!!timestamp` explícito só aceita texto na forma de data
  (`AAAA-M-D`, com hora opcional `H:MM:SS`, fração com pelo menos um dígito e fuso `Z` ou `±H[:MM]`, até ±29). A
  forma é conferida, o calendário não. Sem tag, escreva a data entre aspas.
- O perfil JSON vale também no `.kg.yaml`, como aviso: inteiro fora de ±(2^53−1) (`yaml.unsafe-integer`), surrogate
  solto (`yaml.lone-surrogate`) e mais de 128 coleções aninhadas (`yaml.depth-over-128`).

### O mesmo modelo em `.kg.json`

O grafo pode vir também em JSON, num arquivo `.kg.json` (a extensão é sensível a maiúsculas), com os mesmos campos e
as mesmas regras. Um parser JSON o lê no perfil JSON do contrato, e cada ponto do perfil reprova:

- sintaxe da RFC 8259: sem comentário, vírgula sobrando, aspas simples, `NaN` ou `Infinity`. O espaço em branco é só
  espaço, tab, LF e CR, e um BOM inicial é aceito e descartado;
- I-JSON (RFC 7493): sem surrogate solto, em chave ou valor, e todo número de valor inteiro dentro de ±(2^53−1),
  escrito como inteiro ou como float (`9007199254740993` e `1e20` reprovam);
- no máximo 128 coleções aninhadas, contando a raiz;
- chave única em cada objeto, comparada depois dos escapes (`"label"` e `"\u006cabel"` colidem).

A sintaxe inválida sai como `parse.yaml-error`, porque o vocabulário de códigos não tem um código próprio do JSON.
Quando a sintaxe falha, ela decide antes de qualquer chave repetida. O gate (`kg_gate.py`) e as `external_edges`
funcionam só com `.kg.yaml`.

## Topo

| Chave | Tipo | Regra |
|---|---|---|
| `meta` | mapa | obr. |
| `nodes` | lista de nós | obr. Lista vazia é válida, mas alerta (`form.range.top.nodes`) |
| `edges` | lista de arestas | obr. Pode ser vazia |
| `external_edges` | lista de arestas externas | opcional (desde a 4.3) |
| `x_*` | qualquer | extensão livre |

No topo, no `meta`, no nó, na aresta e na aresta externa, qualquer outra chave sem `x_` reprova
(`form.unknown-key.<escopo>.<chave>`, ou `form.pattern.<escopo>.key` quando o nome não é um slug).

## `meta`

| Chave | Tipo | Regra |
|---|---|---|
| `schema_version` | texto | obr. Exatamente `"1"` |
| `id` | texto | obr. Não vazio |
| `baseline` | *data* | quando o grafo foi medido pela primeira vez |
| `date` | *data* | |
| `review_after` | *data* | quando o grafo deve ser revisto |
| `layer` | `audit` · `domain` | |
| `note` · `purpose` | texto | a narrativa do grafo |
| `title` | texto | desde o v4.11: o título humano do grafo. Não vazio |
| `slug` | texto | desde o v4.11: o nome curto. Não vazio; SHOULD: palavras em minúsculas ligadas por hífen (`meu-grafo`) |
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
| `provenance` | mapa | **obr. quando `status: confirmed` ou `plane: PROD`, exceto com `status: unverifiable`** |
| `trace` | texto | onde a afirmação aparece (arquivo, caminho) |
| `verified_at` | *data* | SHOULD em nó PROD |
| `verified_against` | texto | SHOULD em `claim` com `verified_at` |
| `verified_scope` | enum | opcional, desde o v4.5: o alcance do `verified_at`. `fato` (o que o nó afirma foi conferido), `mecanismo` (só o mecanismo, como código ou configuração, foi conferido; o fato depende de outro ambiente) ou `nenhum` (conferido contra o repositório na data, e nada ali sustenta nem refuta o fato). Fora do enum alerta; sem `verified_at` alerta |
| `reverify_every` | duração | opcional, desde o v4.8: de quanto em quanto tempo a verificação tem de ser refeita, em duração ISO 8601 só com data (`P3M`, `P1Y`, `P2W`, `P1Y6M`). Fora dessa forma, ou zerada como `P0D`, alerta. Desde o v4.9, não alerta mais sem `verified_at`: é a regra que ainda não teve a primeira verificação, e o `--due` a lista como sem carimbo. O vencimento nunca muda o veredito: `kg_validate.py --due` o lista |
| `reverify_on` | texto | opcional, desde o v4.8: o gatilho por evento ("a cada mudança de configuração", "a cada admissão") |
| `retain_for` | duração | opcional, desde o v4.8: por quanto tempo a evidência tem de ser guardada, no mesmo formato de duração |
| `valid_from` | data parcial | `AAAA`, `AAAA-MM` ou `AAAA-MM-DD` |
| `source_tier` | inteiro | 1 a 10 |
| `source_kind` | texto | |
| `owner` | texto | o papel que responde pelo nó (`cto`, `engenharia`), e não o nome de uma pessoa: a pessoa muda, o papel fica |
| `drive_kind` · `evidence_class` | texto | |
| `sealed_by` · `sealed_at` | texto | quem selou a decisão, e quando |
| `narrative` | texto | a história por trás do `label` |
| `layer` | `audit` · `domain` | |
| `x_*` | qualquer | |

### `provenance`

| Chave | Tipo | Regra |
|---|---|---|
| `source` | texto | obr. Não vazio e não marcador (`unknown`, `n/a`, `tbd`, `?`...) |
| `locator` | texto | obr. Não vazio |
| `method` | texto | obr. Não vazio. SHOULD: `<classe>: <detalhe>`, com a classe entre `medição`, `leitura`, `juízes`, `derivado` e `testemunho` |
| `locality` | enum | opcional. `repo` `web` `host` `pessoa` `privado`; fora do enum alerta. Descreve onde está a cópia que você leu, não a classificação do documento |
| `x_*` | qualquer | outra chave alerta, não reprova |

`provenance: null` reprova. Ou o objeto vem inteiro, ou não vem.

## Aresta

| Chave | Tipo | Regra |
|---|---|---|
| `from` | id | obr. Tem de existir no arquivo |
| `to` | id | obr. Tem de existir no arquivo |
| `edge_type` | enum | obr. `SUPPORTS` `REFUTES` `SUPERSEDES` `CAUSES` `DEPENDS_ON` `TRACES_TO` `CONSTRAINS` `HAS_STATE` `TRANSITIONS` `EMITS` `READS` `WRITES` |
| `label` | texto | |
| `trigger` | id | o evento de uma aresta `TRANSITIONS`. Tem de existir no arquivo |
| `on` | — | **proibida** (`yaml.forbidden-key-on`): use `trigger` |
| `x_*` | qualquer | |

## Aresta externa

| Chave | Tipo | Regra |
|---|---|---|
| `from` | id ou referência | id deste arquivo, ou ausente (o grafo inteiro), ou a ponta externa |
| `to` | id ou referência | obr. Exatamente uma das duas pontas é externa |
| `edge_type` | enum | obr. `SUPERSEDES` `CONSTRAINS` `SUPPORTS` `REFUTES` `TRACES_TO` `DEPENDS_ON` |
| `label` | texto | |
| `x_*` | qualquer | |

Uma referência externa é `<caminho>.kg.yaml#<id>`, ou `<caminho>.kg.json#<id>` desde o v4.7, com o caminho relativo
à raiz do repositório e escrito com `/`. Cada segmento começa por letra, dígito ou `_`. Caminho absoluto, `..`, `\`
e `:` reprovam.

## Perfis canônicos de `x_` (v4.11 e v4.12)

A chave `x_` segue livre no MUST: nunca reprova. Algumas chaves `x_` se repetem nos adotantes com o mesmo sentido, e
desde o v4.11 o SHOULD dá uma forma a cada uma. O perfil só é julgado quando a chave está presente, e só alerta. Um
valor fora do perfil alerta com o caminho dentro dele (`form.enum.node.x_term.labels.kind`), e um item de lista dentro
do nó também leva o caminho (`form.type.node.x_term.labels.item`). Dentro do objeto de um perfil, outra chave `x_` é
livre, e qualquer outra chave alerta. Os valores de enum são códigos, em inglês, em qualquer língua da saída.

| Chave | Onde | O que é |
|---|---|---|
| `x_term` | nó | um termo de um vocabulário de domínio, com os sinônimos e a fonte de cada um |
| `x_mirror` | nó | a cópia de um registro guardado em outro sistema (um chamado, uma tarefa, um card) |
| `x_doc_cycle` | nó | o ciclo de vida de um documento externo de que o nó depende (uma norma, uma política, um contrato) |
| `x_questionnaire` | nó | o elo entre o nó e as perguntas de um questionário externo |
| `x_severity` | nó | `critical` · `high` · `medium` · `low` · `info` |
| `x_criterion` | nó | uma versão de um critério pré-registrado (v4.12) |
| `x_measured_under` | nó | as versões de critério sob as quais um resultado foi medido (v4.12) |
| `x_confidence` | aresta | a certeza da ligação, de 0 a 1 |
| `x_provisional` | aresta | `true` quando a ligação ainda espera conferência |

### `x_term`

O termo é um nó (um `entity`) com `x_term`. Os nomes seguem o SKOS: `pref` é o rótulo preferido, e cada sinônimo é
`alt` (um rótulo alternativo) ou `hidden` (uma forma que se busca mas não se mostra, como um erro de digitação ou o
nome antigo de uma coluna). O que o KG-SSOT acrescenta é a verificação por sinônimo: a fonte, a versão do documento, a
data em que foi conferido e quando conferir de novo.

| Chave | Tipo | Regra |
|---|---|---|
| `pref` | texto | obr. O termo preferido |
| `lang` | texto | uma etiqueta BCP 47 (`pt-BR`, `en`) |
| `definition` | texto | |
| `notation` | texto | um código que identifica o termo (`GTIN`, um número de catálogo) |
| `labels` | lista | os sinônimos, cada um um objeto com as chaves abaixo |

| Chave do sinônimo | Tipo | Regra |
|---|---|---|
| `literal` | texto | obr. O sinônimo como se escreve |
| `kind` | enum | obr. `alt` · `hidden` |
| `source` | texto | obr. De onde vem o sinônimo: uma URL, um documento, um caminho |
| `locator` | texto | onde, dentro da fonte |
| `version` | texto | a versão do documento (ou o hash dele, quando o documento não tem versão) |
| `verified_at` | *data* | quando o sinônimo foi conferido contra a fonte |
| `reverify_every` | duração | a cadência; pede `verified_at`, e o `--due` lista o sinônimo quando vence |
| `scope` | mapa | `level`: `domain` (vale no domínio inteiro) ou `case` (vale só num caso, nomeado em `case`); `jurisdiction`, opcional (`BR`, `BR-SP`) |
| `retired` | booleano | `true` para o nome antigo: o sinônimo aposentado ainda resolve, marcado como aposentado. O `kg_vocab.py` lê um valor que não é booleano como aposentado, e um `status` diferente de `current` também |
| `lang` | texto | quando difere da do termo |

O termo aposentado é o nó com `status: superseded` e uma aresta `SUPERSEDES` do termo que o substitui. O
`kg_vocab.py` lista os termos, resolve um texto para o termo dele e exporta para o SKOS-XL e o Apache Ossie
(capítulo 5).

```yaml
  - id: T_EAN
    node_type: entity
    plane: DEV
    status: open
    impact: 3
    confidence: 0.9
    label: "Código EAN: o código de 13 dígitos que identifica o país, o fabricante e o produto."
    x_term:
      pref: "Código EAN"
      lang: pt-BR
      labels:
        - literal: "GTIN"
          kind: alt
          source: "https://dados.anvisa.gov.br/dados/TA_PRECO_MEDICAMENTO%20-%20Dicionario%20de%20Dados.pdf"
          locator: "itens 9, 10 e 11"
          version: "sha256:44e8af589f6a0860"
          verified_at: "2026-10-22"
          reverify_every: P6M
          scope: {level: domain, jurisdiction: BR}
        - literal: "CO_EAN"
          kind: hidden
          source: "https://dados.anvisa.gov.br/dados/TA_PRECO_MEDICAMENTO%20-%20Dicionario%20de%20Dados.pdf"
          locator: "tabela De/Para: CO_EAN (anterior) para EAN 1 (atual)"
          retired: true
```

O exemplo inteiro, tirado do dicionário de dados aberto da CMED/ANVISA, está em
[`spec/vocab-examples/cmed-dictionary.kg.yaml`](../../../spec/vocab-examples/cmed-dictionary.kg.yaml).

### `x_mirror`, `x_doc_cycle` e `x_questionnaire`

| Perfil | Obrigatório | Opcional |
|---|---|---|
| `x_mirror` | `system`, `ref`, `state` (o estado como foi copiado), `synced_at` (*data*) | `url`, `resync_every` (duração) |
| `x_doc_cycle` | `issuer`, `state`: `draft` `enacted` (publicado, em vigor a partir de um `effective_from` futuro) `in_force` `suspended` `revoked` `expired` `superseded` | `ref`, `version`, `effective_from`, `effective_to`, `updated_at`, `checked_at` (*datas*), `recheck_every` (duração, pede `checked_at`) |
| `x_questionnaire` | `name`, `questions` (uma lista não vazia) | `answer_draft`, `verdict`: `meets` `partial` `does_not_meet` `not_applicable` `unknown`, `answered_at` (*data*), `role`: `item` `evidence_request` `evidence_requirement` (v4.13) |

Uma cópia envelhece sem aviso: `synced_at` mais `resync_every` a põe no relatório de vencimento, e o mesmo vale para
`checked_at` mais `recheck_every` num documento.

O `x_questionnaire.role` separa o item do questionário da evidência em volta dele. `item`, o padrão, é o nó da pergunta
ou a resposta a ela; `evidence_request` é o pedido de evidência a uma pessoa, e `evidence_requirement` diz que evidência
um item exige. As `questions` dos dois são os itens a que servem. Sem o campo, só o prefixo do id os separa, e um prefixo
é convenção de um adotante, não do contrato. O pacote de auditoria (`kg_audit.py`, capítulo 5) o lê.

### `x_criterion` e `x_measured_under` (v4.12)

Um critério fixado antes do dado é um pré-registro, como no
[OSF Preregistration](https://www.cos.io/initiatives/prereg) e nas emendas versionadas de um registro de ensaio
clínico. Mudá-lo depois de ver o dado é uma emenda com data e motivo, nunca uma reescrita. Cada versão é um nó, e o
resultado cita o nó da versão sob a qual foi medido, com o `sha256` dessa versão. O resultado antigo fica preso à versão
antiga, e o veredito antigo nunca muda em silêncio.

| Perfil | Obrigatório | Opcional |
|---|---|---|
| `x_criterion` | `id` (estável entre as versões), `version` (texto ou inteiro), `registered_at` (uma data, ou uma data-hora RFC 3339 com fuso), `sha256` (64 hex minúsculos) e `ref` ou `text` | `amends` (o id do nó da versão anterior; pede `reason`), `reason`, `round` (texto: a rodada que motivou a emenda) |
| `x_measured_under` | `measured_at` (uma data ou uma data-hora), `criteria` (uma lista não vazia de `{criterion, sha256}`) | `subject` (um mapa livre: cenário, réplica, alvo), `verdict`, `round` (texto) |

O `criterion` é o id de um nó do mesmo grafo com `x_criterion`, ou `<caminho>#<id>` para um critério de outro grafo.
O `ref` é um caminho a partir da raiz do repositório, com fragmento opcional (`#/criteria/0` ou o `id` de um item de
lista); o `text` é o próprio critério. A emenda leva também uma aresta `SUPERSEDES` para a versão anterior.

```yaml
  - id: C_A7_V2
    node_type: claim
    plane: DEV
    status: open
    impact: 3
    confidence: 0.8
    label: "Criterion A7, version 2: passes with 8 of 10 replicas."
    x_criterion:
      id: A7
      version: 2
      registered_at: "2026-10-22T10:00:00-03:00"
      sha256: "7fb806ea1c06b6816ad43681d179143472b3c2a48b69f422c05b08339b48305a"
      text: "Passes with 8 of 10 replicas."
      amends: C_A7_V1
      reason: "Replica 3 showed that the limit was wrong."
      round: r3
  - id: E_A7_R4
    node_type: evidence
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.8
    label: "Round r4 passes criterion A7 with 9 of 10 replicas."
    x_measured_under:
      measured_at: "2026-10-23T09:00:00Z"
      round: r4
      criteria:
        - criterion: C_A7_V2
          sha256: "7fb806ea1c06b6816ad43681d179143472b3c2a48b69f422c05b08339b48305a"
      verdict: passes
```

O leitor compara datas e rodadas sem calcular hash. As duas com hora comparam o instante em UTC; as duas só data
comparam o dia escrito, o que supõe as duas escritas no mesmo fuso, e o mesmo dia não diz a ordem; com uma só data, cujo fuso é desconhecido, a outra vale pelo
dia em UTC, e a distância de até um dia também não diz a ordem. Só o mesmo `round` decide (a rodada que motivou a
emenda): rodadas são rótulos, não uma ordem. A data num dia que não existe (30 de fevereiro) não é comparada. O `sha256` contra o texto ou o arquivo, e a citação de outro
grafo, são conferidos pelo `kg_criterion.py` (capítulo 5).

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
| critério citado, ou `amends`, que não é um nó deste grafo com `x_criterion` | SHOULD | `integrity.criterion-unknown` |
| emenda que aponta a versão de outro critério (outro `x_criterion.id`), ou cuja cadeia de `amends` volta a ela mesma | SHOULD | `integrity.criterion-amends-mismatch` |
| `sha256` citado que não é o da versão citada | SHOULD | `integrity.criterion-sha-mismatch` |
| medido no mesmo `round` da versão citada, ou antes do registro dela (veja abaixo) | SHOULD | `integrity.measured-post-hoc` |
| as datas não dizem se o resultado veio antes ou depois da versão citada | SHOULD | `integrity.measured-order-unknown` |

Uma aresta externa conta como ligação: o nó ligado só por ela não é órfão.
