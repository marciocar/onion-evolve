<!-- translation-of: docs/manual/03-format.md sha256:875b13aa9924e6da -->
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
| `provenance` | mapa | **obr. quando `status: confirmed` ou `plane: PROD`, exceto com `status: unverifiable`**. SHOULD desde o v4.21 (proveniência sempre): no nó `evidence` em qualquer status exceto `unverifiable`, e na `decision` `done`, alerta como `form.required.node.provenance`, o mesmo código no nível SHOULD |
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
| `method` | texto | obr. Não vazio. SHOULD: `<classe>: <detalhe>`, com a classe entre `measurement`, `reading`, `judges`, `derived` e `testimony` (desde o v4.21, os apelidos em português, `medição`, `leitura`, `juízes`, `derivado`, `testemunho`, seguem passando e alertam como `form.deprecated.node.provenance.method`; saem no v5, nunca antes de 2027-03-31, e só quando a medida no primeiro adotante e no repositório de curadoria dele der zero. O valor que já falha a forma alerta só como `form.pattern.node.provenance.method`) |
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
à raiz do repositório e escrito com `/`. Cada segmento começa por letra, dígito ou `_`, ou, desde o v4.15, por um
ponto seguido de um deles (`.github/`, `.config/`). Caminho absoluto, os segmentos `.` e `..`, `\` e `:`
reprovam.

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
| `x_classification` | meta | o nível de sensibilidade do grafo inteiro, um nível do esquema próprio da organização (v4.20) |

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
| `notation` | texto | um código que identifica o termo (`GTIN`, um número de catálogo, `O1`) |
| `scheme` | slug | o vocabulário a que o termo pertence (v4.14): minúsculas, dígitos e hífen. Sem ele, o esquema é o grafo |
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

**Um código curto com nome legível (v4.14).** Um código como `O1`, `V3` ou `r16` vale desde que tenha nome. Dê a ele um
termo: o código é a `notation`, o nome é o `pref`, e o `scheme` diz a que vocabulário ele pertence, como o
`skos:notation`, o `skos:prefLabel` e o `skos:inScheme` no SKOS. O id do nó continua curto e estável. O mesmo código
pode querer dizer duas coisas em dois esquemas (a opção `O1` de uma decisão e a onda `O1` de uma recuperação): fora do
grafo dele, cite como `esquema:código`. Dentro de um esquema, um código nomeia um conceito só, então dois termos vivos
com a mesma notation no mesmo esquema alertam como `integrity.term-notation-duplicate`; o esquema do grafo tem o
nome do `meta.id`, então um esquema declarado com esse nome é o mesmo esquema. O `kg_vocab.py lint` confere os
códigos escritos nos labels e nas narrativas contra o vocabulário (capítulo 5).

```yaml
  - id: T_EAN
    node_type: entity
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    verified_at: "2026-10-22"
    verified_against: "o PDF do dicionário de dados baixado em 2026-10-22"
    provenance:
      source: "https://dados.anvisa.gov.br/dados/TA_PRECO_MEDICAMENTO%20-%20Dicionario%20de%20Dados.pdf"
      locator: "itens 9, 10 e 11"
      method: "reading: o PDF baixado, verbete a verbete"
      locality: web
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

Um termo em vigor é `confirmed`, com a `provenance` da fonte de onde foi adotado, como qualquer outro fato. Deixe-o
`open` só enquanto a definição ainda está em negociação: o `kg_vocab.py` resolve um termo aberto do mesmo jeito, mas a
fila de nós abertos (`kg_query --open`) listaria uma definição assentada como trabalho pendente.

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

### `x_classification` (v4.20)

`meta.x_classification` marca o quanto o grafo inteiro é sensível: um nível, escrito como slug (letras minúsculas,
dígitos e hífen), como `confidential`. O contrato fixa só a forma. Os níveis e a ordem deles são da organização e moram
na política do servidor que entrega o grafo, nunca no grafo: no `kg-mcp`, os `levels` da política de áreas (capítulo
5). O nível fora da forma alerta como `form.pattern.meta.x_classification`, e o valor que não é texto como
`form.type.meta.x_classification`.

```yaml
meta:
  id: folha-2026
  x_classification: confidential
```

A unidade é o grafo. O nó mais sensível que o resto do grafo vai para um grafo próprio, com o nível no `meta` dele. Por
isso `x_classification` no nó não é perfil, e alerta como `form.misplaced.node.x_classification`, com qualquer valor.
Na aresta, é uma chave `x_` livre.

O rótulo é marcação que a política do servidor faz valer na leitura, não controle de acesso nó a nó: um leitor que
ignora a política vê o grafo como qualquer outro. Mover um nó para outro arquivo não o tira do histórico do git, onde a
versão antiga ainda o guarda.

Como exemplo de mapeamento, não como padrão: o TLP 2.0 da FIRST nomeia audiências (`clear`, `green`, `amber`,
`amber-strict`, `red`) para a troca entre organizações, e declara que não é um esquema formal de classificação. A
organização que o usa escreve esses nomes como os seus `levels`, nessa ordem.

## Registrar um evento externo (forma recomendada, não normativa)

Um e-mail, uma mensagem de chat, uma edição de wiki, um webhook de repositório ou um aviso de nuvem chega ao Company
Brain por um coletor. Esta é a forma que recomendamos para o nó que o registra. Ela **não** é perfil canônico: o
contrato não julga o `x_event`, e um grafo que o escreva de outro jeito mantém o veredito. A forma está aqui para que
os coletores escrevam os mesmos nomes e os leitores possam contar com eles.

**O nó é um `evidence`.** Sem tipo novo de nó: o tipo `event` quer dizer um evento de domínio, que muda um `state`,
não uma mensagem que chegou.

**O `x_event` usa os nomes dos atributos de contexto do núcleo do CloudEvents 1.0.**

| Atributo | Obrigatório | Regra (do CloudEvents) |
|---|---|---|
| `specversion` | sim | `"1.0"`, entre aspas, para o YAML o manter como texto |
| `id` | sim | texto não vazio, posto pelo produtor |
| `source` | sim | uma URI-reference não vazia: onde o evento aconteceu |
| `type` | sim | texto não vazio, com prefixo em DNS reverso (`com.example.wiki.page.updated`) |
| `subject` | não | texto não vazio: do que, dentro do `source`, o evento trata |
| `time` | não | quando o evento aconteceu, uma data-hora RFC 3339 com fuso, **entre aspas**: sem aspas, o YAML lê um timestamp, não um texto |
| `datacontenttype` | não | o tipo de mídia do corpo (`application/json`, `message/rfc822`) |
| `dataref` | não | um ponteiro para o corpo gravado, o mesmo arquivo do `provenance.source` |

**A integridade vem de fora do evento.** Nenhum atributo do CloudEvents carrega hash ou assinatura do conteúdo. O
coletor grava o corpo aceito como arquivo, e o `provenance.source` e o `provenance.sha256` apontam para ele, então o
`kg_trace.py check` (capítulo 5) reprova quando o arquivo muda depois de gravado.

**Três horas, três campos.** O `x_received_at`, no nó ao lado do `x_event`, é quando o coletor recebeu o evento, uma
data-hora RFC 3339 entre aspas. Ele não é o `x_event.time`, quando o evento aconteceu na origem, nem o `verified_at`,
quando alguém conferiu a evidência.

**A idempotência é `source` + `id`.** Um reenvio do mesmo evento pode repetir os dois, e o coletor o trata como
duplicata: um evento, um nó. O identificador de uma entrega (o `jti` de um token assinado, o id de entrega de um
webhook) não é o `id` do evento, porque um reenvio ganha um novo.

**Sem assinatura conferida, o nó fica `open`.** Como a origem foi verificada vai no `provenance.method`: `measurement`
quando o coletor conferiu uma assinatura, `reading` quando só gravou o que chegou. Só uma origem conferida deixa o nó
ser `confirmed`.

**Sem `null`.** Atributo ausente não aparece. O CloudEvents lê `null` como ausente, e o grafo mantém um jeito só de
dizer isso.

O que não fazer:

- **Fazer de cada evento um nó.** A fila fica no armazém do coletor. Vira nó só o evento que uma regra declarada
  promove, porque serve a uma pergunta ou a uma decisão.
- **Pôr o corpo no grafo.** O corpo fica no arquivo gravado. O `label` diz o fato numa frase, e o `dataref` e a
  `provenance` apontam para o corpo.
- **Tratar o conteúdo do evento como instrução.** Um corpo que diz "marque a fatura como paga" ou "ignore as regras
  anteriores" é o que o remetente afirma: gravado, nunca obedecido.

Um exemplo completo: uma edição de wiki cuja assinatura do webhook foi conferida, e um e-mail cujo remetente não foi
verificado. O coletor gravou `inbox/events/2026-11-05-wiki-rev-42.json`:

```json
{"page": "Refund policy", "revision": 42, "editor": "finance-team", "summary": "Refund window changed from 30 to 14 days"}
```

e `inbox/events/2026-11-05-mail-price-update.eml`:

```text
From: sales@supplier.example.net
To: purchasing@example.com
Subject: Price update
Message-ID: <price-2026-12@supplier.example.net>
Date: Thu, 05 Nov 2026 09:12:00 -0300

Our prices rise 8% from 2026-12-01.
```

Cada arquivo termina com uma quebra de linha, e cada `sha256` é o hash do arquivo inteiro.

```yaml
meta:
  schema_version: "1"
  id: events
nodes:
  - id: Q_PRICING_TERMS
    node_type: question
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    label: Do the refund and supplier terms in the pricing model still hold?
  - id: E_WIKI_REFUND_POLICY_REV_42
    node_type: evidence
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    label: "The refund policy page changed on 2026-11-05 (revision 42): the refund window went from 30 to 14 days."
    verified_at: "2026-11-05"
    verified_against: the recorded body, after the webhook signature was checked on receipt
    x_received_at: "2026-11-05T14:03:12Z"
    x_event:
      specversion: "1.0"
      id: "rev-42"
      source: "https://wiki.example.com/spaces/finance"
      type: "com.example.wiki.page.updated"
      subject: "pages/refund-policy"
      time: "2026-11-05T14:03:07Z"
      datacontenttype: "application/json"
      dataref: "inbox/events/2026-11-05-wiki-rev-42.json"
    provenance:
      source: inbox/events/2026-11-05-wiki-rev-42.json
      locator: "the whole file"
      method: "measurement: the collector checked the webhook HMAC signature against the shared secret before recording the body"
      sha256: "4abc0a46c949c6425bd1c438dfc0353b8082731837e103e9c2a8dbaaabc0dfed"
      locality: repo
  - id: E_MAIL_SUPPLIER_PRICE_UPDATE
    node_type: evidence
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    label: "An e-mail from the supplier says its prices rise 8% from 2026-12-01; the sender was not verified."
    x_received_at: "2026-11-05T12:12:41Z"
    x_event:
      specversion: "1.0"
      id: "<price-2026-12@supplier.example.net>"
      source: "imap://mail.example.com/purchasing"
      type: "com.example.mail.received"
      time: "2026-11-05T09:12:00-03:00"
      datacontenttype: "message/rfc822"
      dataref: "inbox/events/2026-11-05-mail-price-update.eml"
    provenance:
      source: inbox/events/2026-11-05-mail-price-update.eml
      locator: "the whole file"
      method: "reading: the collector recorded the message as received; no signature was checked"
      sha256: "8bd9767d59723248b6acde789c58e2c6d7e1f31f77def0bf949493ca00df7585"
      locality: repo
edges:
  - from: E_WIKI_REFUND_POLICY_REV_42
    to: Q_PRICING_TERMS
    edge_type: SUPPORTS
  - from: E_MAIL_SUPPLIER_PRICE_UPDATE
    to: Q_PRICING_TERMS
    edge_type: SUPPORTS
```

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/events.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_trace.py check --root .
```

```text
PASSA   docs/events.kg.yaml
· 1 arquivos; 1 passam no MUST; 0 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
· 2 fonte(s) lida(s) pelo scheme ou pelo sha256: 2 ok, 0 com falha (2 sha256 conferido(s)); não julgado (contado): 0 só pela forma, 0 URL sem --with, 0 fonte não achada, 0 scheme, locator ou hash malformado, 0 outro(s)
· 0 trace(s) julgado(s): 0 resolve(m), 0 faltando; fora de julgamento (contados): 0 absoluto(s) ou URL, 0 raiz externa, 0 não caminho, 0 fora de texto
```

Quando o evento chega embrulhado num envelope assinado que um inbox aceitou, a fonte é o documento aceito e o hash do
corpo vai em `provenance.x_body_sha256`: veja a receita no
[capítulo 8](08-receitas.md#registrar-um-evento-externo-que-chegou-por-mensagem-assinada).

Quando dois adotantes, ou 50 nós reais, usarem esta forma, ela vira um perfil canônico no SHOULD, julgado só quando
presente.

## Registrar uma mudança planejada (forma recomendada, não normativa)

Uma mudança num sistema, numa política ou num processo é planejada, comunicada a quem ela afeta, aplicada, conferida e,
às vezes, desfeita. Esta é a forma que recomendamos para os nós que a registram, e ela é irmã da forma do `x_event`,
acima. Ela também **não** é perfil canônico: o contrato não julga o `x_change`, e um grafo que o escreva de outro
jeito mantém o veredito.

**A mudança é uma `decision`, e cada transição é uma `evidence`.** A `decision` é a escolha de mudar, e o
`x_change.state` dela diz onde a mudança está, então o `kg_query` lista as mudanças por estado. Cada transição depois
de `planned` é um nó `evidence` com `x_change_transition` e uma aresta `SUPPORTS` para a decisão: a evidência é a
prova, e o estado é só o que a prova permite. A história de uma mudança são os nós de evidência dela na ordem do `at`,
não uma lista dentro da decisão, e os valores anteriores do `state` ficam no histórico do git.

**Cinco estados.** Nenhum padrão dá nome a eles. A habilitação de mudança (*change enablement*) do ITIL 4 avalia o
risco, autoriza a mudança e mantém o calendário de mudanças, e a ISO/IEC 20000-1 pede também que o remédio de uma
mudança malsucedida seja planejado; nenhuma das duas dá nome aos estados do registro. As convenções semânticas do
OpenTelemetry têm o `vcs.change.state` (`open`, `wip`, `closed`, `merged`), que trata de uma mudança de código em
revisão, e o `deployment.status` (`succeeded`, `failed`), que é o resultado de uma implantação; nenhum dos dois cobre
a mudança de uma política ou de um processo. Então os nomes são nossos:

| Estado | O que quer dizer | O que o grafo tem |
|---|---|---|
| `planned` | registrada, com o alvo, a janela e o plano de reversão | a decisão com `x_change` |
| `communicated` | quem ela afeta foi avisado | uma `evidence` com o `x_event` do aviso, e o `communicated_by` apontando para ela |
| `applied` | foi feita no alvo | uma `evidence` da aplicação (um registro de implantação, uma linha de log), e a aprovação no `sealed_by` |
| `verified` | uma conferência mediu que ela pegou | uma `evidence` cujo `provenance.method` é `measurement`, com `status: confirmed` |
| `reverted` | foi desfeita | uma `evidence` da reversão, com uma aresta `SUPERSEDES` para a evidência da aplicação que ela desfaz, que passa a `status: superseded` |

O estado anda nessa ordem. O `communicated` pode ser pulado quando ninguém precisa ser avisado, como numa mudança
padrão, e o `reverted` vem depois de `applied` ou de `verified`. Uma mudança abandonada antes de aplicada não é nenhum
dos cinco: a decisão fecha com `status: done`, o estado fica onde parou, e a `narrative` diz por quê.

**O `x_change`, na decisão:**

| Chave | Obrigatória | Regra |
|---|---|---|
| `state` | sim | um dos cinco. É `state`, não `status`: alguns leitores leem um `status` aninhado como o status do nó |
| `target` | sim | o que muda: uma URI-reference não vazia, ou o id do nó deste grafo que o representa (uma `policy`, um `artifact`) |
| `window` | sim | `start` e `end`, datas-horas RFC 3339 com fuso, **entre aspas**, com o `end` depois do `start`: quando a mudança pode ser aplicada. Mudança sem janela ainda não está planejada |
| `rollback_plan` | sim | um ponteiro para o plano (um caminho no repositório, ou uma URL), não o próprio plano |
| `kind` | não | `standard` (risco baixo, autorizada de antemão), `normal` ou `emergency`: os tipos de mudança do ITIL 4 |
| `ref` | não | o id da mudança na ferramenta que a registra (`CHG-0142`) |
| `communicated_by` | a partir de `communicated` | o id, neste grafo, do nó `evidence` com o `x_event` do aviso |

**O `x_change_transition`, em cada evidência:** o `to` (obrigatório) é `communicated`, `applied`, `verified` ou
`reverted`, e o `at` (obrigatório) é quando a transição aconteceu, uma data-hora RFC 3339 entre aspas. No nó com
`x_event`, o `at` é o `x_event.time`.

**Quem aprovou vai no `sealed_by`, por referência.** O contrato já tem `sealed_by` e `sealed_at` numa decisão: aqui
eles são a autoridade de mudança e a data da autorização. Escreva um papel (`role:change-advisory-board`) ou uma
referência que uma tabela fora do git resolve para uma pessoa (`person:p-0042`), nunca um nome: o grafo e o histórico
do git são um registro que não esquece, e um nome escrito ali fica em toda cópia. Uma mudança padrão é autorizada uma
vez, pelo modelo dela, e o `sealed_by` e o `sealed_at` dela são os do modelo. Nenhuma mudança fica `applied` sem
`sealed_by`: uma mudança emergencial é autorizada mais depressa, não pulada.

**Três horas, três campos.** O `x_change.window` é quando a mudança pode acontecer, o `x_change_transition.at` é
quando uma transição aconteceu, e o `verified_at` é quando alguém conferiu a evidência.

**Uma mudança, um nó.** A ferramenta que escreve o grafo acha a decisão de novo pelo `ref` e atualiza o `state` dela.
Ela não escreve uma decisão nova para cada estado.

**O `verified` pede uma medição.** Uma pessoa que diz que funciona é um `testimony`, e a linha de log em que a
ferramenta aplicou a mudança é uma `reading` que sustenta o `applied`. Só uma evidência cujo `provenance.method` é
`measurement`, com `status: confirmed`, deixa o estado ser `verified`. A decisão fica `open` enquanto a mudança está
`planned`, `communicated` ou `applied`, `confirmed` quando está `verified`, e `done` quando está `reverted`: o status
diz se o registro fechou, e o estado diz como. Quando a medição mostra que a mudança não pegou, o estado fica
`applied`, a evidência `REFUTES` a decisão, e o `kg_validate` avisa `integrity.refutes-unreconciled` enquanto a
decisão está viva. O grafo se reconcilia quando a mudança é revertida e a decisão passa a `refuted`, ou quando uma
decisão nova, aplicada e conferida, faz `SUPERSEDES` nela.

O que não fazer:

- **Fazer de cada passo de implantação um nó.** O pipeline guarda os passos dele. Uma transição vira nó só quando muda
  o estado: uma aplicação, uma conferência, uma reversão.
- **Pôr segredo ou dado pessoal no nó.** O plano de reversão, o log e a saída da conferência são arquivos para os
  quais o nó aponta, e nenhum deles carrega credencial, token ou string de conexão. As pessoas envolvidas entram por
  referência, como no `sealed_by`.
- **Tratar o estado como verdade sem a evidência.** O `state` é o que a evidência permite. Um estado sem evidência por
  trás é uma afirmação, e um leitor que conta as mudanças por estado confere a evidência de cada uma
  (`kg_query.py --around <id> --direction in --edge-type SUPPORTS`).

Um exemplo completo: duas mudanças num app financeiro. A primeira pede um segundo fator no login: foi comunicada à
equipe, aplicada e medida. A segunda encurta o tempo de sessão, uma mudança padrão que foi aplicada e revertida. O
coletor gravou o aviso em `inbox/events/2026-10-27-mail-chg-0142-notice.eml`:

```text
From: it-changes@example.com
To: finance-staff@example.com
Subject: CHG-0142: the finance app will ask for a second factor
Message-ID: <chg-0142-notice@example.com>
Date: Tue, 27 Oct 2026 10:00:00 +0000

From 2026-10-29 22:00 UTC, signing in to the finance app requires a second factor.
```

a ferramenta de implantação escreveu `changes/CHG-0142.log`:

```text
2026-10-29T22:14:03Z apply CHG-0142 policy=finance-sign-in second_factor=required result=ok
```

e `changes/CHG-0143.log`:

```text
2026-10-29T22:20:41Z apply CHG-0143 setting=finance-session-timeout from=8h to=1h result=ok
2026-10-30T09:05:12Z revert CHG-0143 setting=finance-session-timeout from=1h to=8h result=ok
```

e a conferência escreveu `changes/CHG-0142-check.json`:

```json
{"change": "CHG-0142", "measured_at": "2026-10-30T08:00:00Z", "check": "sign-in policy export of the finance app", "accounts": 42, "second_factor_required": 42}
```

Cada arquivo termina com uma quebra de linha, e cada `sha256` é o hash do arquivo inteiro. Os registros das mudanças
ficam na ferramenta de mudanças, fora do repositório (`locality: privado`).

```yaml
meta:
  schema_version: "1"
  id: changes
nodes:
  - id: D_CHG_0142_FINANCE_SECOND_FACTOR
    node_type: decision
    plane: PROD
    status: confirmed
    impact: 4
    confidence: 0.9
    label: "Signing in to the finance app requires a second factor (change CHG-0142)."
    verified_at: "2026-10-30"
    sealed_by: "person:p-0042"
    sealed_at: "2026-10-26"
    x_change:
      state: verified
      target: "https://finance.example.com/settings/sign-in"
      kind: normal
      ref: "CHG-0142"
      window:
        start: "2026-10-29T22:00:00Z"
        end: "2026-10-29T23:00:00Z"
      rollback_plan: "https://changes.example.com/CHG-0142#rollback"
      communicated_by: E_CHG_0142_NOTICE
    provenance:
      source: "https://changes.example.com/CHG-0142"
      locator: "the change record, with its approval"
      method: "reading: the change record in the change tool"
      locality: privado
  - id: E_CHG_0142_NOTICE
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 3
    confidence: 0.9
    label: "The finance staff were told on 2026-10-27 that the finance app would ask for a second factor from 2026-10-29 22:00 UTC."
    verified_at: "2026-10-27"
    x_received_at: "2026-10-27T10:00:04Z"
    x_event:
      specversion: "1.0"
      id: "<chg-0142-notice@example.com>"
      source: "imap://mail.example.com/it-changes"
      type: "com.example.mail.sent"
      time: "2026-10-27T10:00:00Z"
      datacontenttype: "message/rfc822"
      dataref: "inbox/events/2026-10-27-mail-chg-0142-notice.eml"
    x_change_transition:
      to: communicated
      at: "2026-10-27T10:00:00Z"
    provenance:
      source: inbox/events/2026-10-27-mail-chg-0142-notice.eml
      locator: "the whole file"
      method: "measurement: the collector checked the DKIM signature of example.com before recording the message"
      sha256: "f6adb2d2565f84f4d8d09a0eefb3530389d2dd6f7bcdb8a529b8becc15d6e8ad"
      locality: repo
  - id: E_CHG_0142_APPLIED
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 3
    confidence: 0.8
    label: "The deployment log says the second-factor sign-in policy of the finance app was applied at 2026-10-29 22:14 UTC."
    verified_at: "2026-10-29"
    x_change_transition:
      to: applied
      at: "2026-10-29T22:14:03Z"
    provenance:
      source: changes/CHG-0142.log
      locator: "line=0"
      scheme: text
      method: "reading: the line the deployment tool wrote when it applied the change"
      sha256: "07888a04da6abf1b52170fe640782f9ed6739d86218d6d4284d7c73a7ecdc755"
      locality: repo
  - id: E_CHG_0142_VERIFIED
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 4
    confidence: 0.95
    label: "On 2026-10-30, the sign-in policy export of the finance app requires a second factor on all 42 accounts."
    verified_at: "2026-10-30"
    x_change_transition:
      to: verified
      at: "2026-10-30T08:00:00Z"
    provenance:
      source: changes/CHG-0142-check.json
      locator: "the whole file"
      method: "measurement: the check exported the sign-in policy and counted the accounts that require a second factor"
      sha256: "73df0837c693dd0a24c04b2b9fd5f6de2407bd94f3284eceb9a475225b179e35"
      locality: repo
  - id: D_CHG_0143_FINANCE_SESSION_TIMEOUT
    node_type: decision
    plane: PROD
    status: done
    impact: 3
    confidence: 0.9
    label: "The finance app session timeout went from 8 hours to 1 hour (change CHG-0143), and the change was reverted."
    narrative: "The overnight reconciliation job keeps one session open for more than an hour, and it stopped on 2026-10-30. The timeout went back to 8 hours."
    verified_at: "2026-10-30"
    sealed_by: "role:change-advisory-board"
    sealed_at: "2026-09-14"
    x_change:
      state: reverted
      target: "https://finance.example.com/settings/session"
      kind: standard
      ref: "CHG-0143"
      window:
        start: "2026-10-29T22:00:00Z"
        end: "2026-10-29T23:00:00Z"
      rollback_plan: "https://changes.example.com/standard/session-timeout#rollback"
    provenance:
      source: "https://changes.example.com/CHG-0143"
      locator: "the change record, under the standard change model it follows"
      method: "reading: the change record in the change tool"
      locality: privado
  - id: E_CHG_0143_APPLIED
    node_type: evidence
    plane: PROD
    status: superseded
    impact: 3
    confidence: 0.8
    label: "The deployment log says the finance app session timeout was set to 1 hour at 2026-10-29 22:20 UTC."
    verified_at: "2026-10-29"
    x_change_transition:
      to: applied
      at: "2026-10-29T22:20:41Z"
    provenance:
      source: changes/CHG-0143.log
      locator: "line=0"
      scheme: text
      method: "reading: the line the deployment tool wrote when it applied the change"
      sha256: "6e732995a0bc52533899832bde3258ff205c497d2d958128cb9002edd2f592a4"
      locality: repo
  - id: E_CHG_0143_REVERTED
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 3
    confidence: 0.8
    label: "The deployment log says the finance app session timeout went back to 8 hours at 2026-10-30 09:05 UTC."
    verified_at: "2026-10-30"
    x_change_transition:
      to: reverted
      at: "2026-10-30T09:05:12Z"
    provenance:
      source: changes/CHG-0143.log
      locator: "line=1"
      scheme: text
      method: "reading: the line the deployment tool wrote when it ran the rollback plan"
      sha256: "6e732995a0bc52533899832bde3258ff205c497d2d958128cb9002edd2f592a4"
      locality: repo
edges:
  - from: E_CHG_0142_NOTICE
    to: D_CHG_0142_FINANCE_SECOND_FACTOR
    edge_type: SUPPORTS
  - from: E_CHG_0142_APPLIED
    to: D_CHG_0142_FINANCE_SECOND_FACTOR
    edge_type: SUPPORTS
  - from: E_CHG_0142_VERIFIED
    to: D_CHG_0142_FINANCE_SECOND_FACTOR
    edge_type: SUPPORTS
  - from: E_CHG_0143_APPLIED
    to: D_CHG_0143_FINANCE_SESSION_TIMEOUT
    edge_type: SUPPORTS
  - from: E_CHG_0143_REVERTED
    to: D_CHG_0143_FINANCE_SESSION_TIMEOUT
    edge_type: SUPPORTS
  - from: E_CHG_0143_REVERTED
    to: E_CHG_0143_APPLIED
    edge_type: SUPERSEDES
```

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/changes.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_trace.py check --root .
python3 -I -B vendor/kg-ssot/tools/kg_query.py --root . --type decision --has x_change --group-by x_change.state
```

```text
PASSA   docs/changes.kg.yaml
· 1 arquivos; 1 passam no MUST; 0 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
· 5 fonte(s) lida(s) pelo scheme ou pelo sha256: 5 ok, 0 com falha (5 sha256 conferido(s)); não julgado (contado): 0 só pela forma, 0 URL sem --with, 0 fonte não achada, 0 scheme, locator ou hash malformado, 0 outro(s)
· 0 trace(s) julgado(s): 0 resolve(m), 0 faltando; fora de julgamento (contados): 0 absoluto(s) ou URL, 0 raiz externa, 0 não caminho, 0 fora de texto
     1  x_change.state=reverted
     1  x_change.state=verified
· só os nós que têm x_change
· 2 nó(s) em 1 grafo(s), em 2 grupo(s) por x_change.state
```

O `--where x_change.state=applied` lista as mudanças aplicadas e ainda não conferidas, e o
`--where x_change.kind=emergency` lista as emergenciais.

Quando dois adotantes, ou 50 nós reais, usarem esta forma, ela vira um perfil canônico no SHOULD, julgado só quando
presente.

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
