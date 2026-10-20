# 2. Conceitos

[← O que é](01-o-que-e.md) · [Índice](README.md) · [Referência do formato →](03-formato.md)

## O grafo

Um grafo é **um arquivo** `.kg.yaml` com três chaves obrigatórias no topo: `meta` (identidade do grafo), `nodes`
(as afirmações) e `edges` (as relações entre elas). Uma quarta, `external_edges`, é opcional e liga um nó deste
arquivo a um nó de outro. Um repositório pode ter quantos grafos quiser.

```yaml
meta:
  schema_version: "1"
  id: exemplo
nodes:
  - id: Q_CACHE_TTL
    node_type: question
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    label: O cache de sessão precisa de TTL?
edges: []
```

Esse grafo é válido no MUST? Não. Um nó sem nenhuma aresta é **órfão** e reprova (`integrity.orphan-node`):
todo nó precisa de pelo menos uma aresta. O exemplo completo, com uma evidência ligada à pergunta, está no
[capítulo 8](08-receitas.md#escrever-o-primeiro-grafo).

## O nó

Cada nó é uma afirmação curta. Os campos obrigatórios são sete:

| Campo | O que diz |
|---|---|
| `id` | Identificador único no arquivo: começa por letra, depois letras, dígitos e `_` |
| `node_type` | Que tipo de afirmação é (tabela abaixo) |
| `plane` | `DEV` ou `PROD` |
| `status` | Em que pé a afirmação está (tabela abaixo) |
| `impact` | Inteiro de 1 a 5: quanto pesa se estiver errada |
| `confidence` | Número de 0 a 1: quanto se confia nela hoje |
| `label` | A afirmação em si, em texto curto |

### Tipos de nó (`node_type`)

O contrato fecha a lista em onze tipos, em duas famílias. Os nomes são do contrato; o uso descrito é o convencional.

| Família | Tipo | Uso |
|---|---|---|
| Investigação | `question` | Uma pergunta aberta |
| | `claim` | Uma afirmação que precisa de evidência |
| | `evidence` | Algo observado ou medido, que sustenta ou refuta outra coisa |
| | `decision` | Uma escolha, aberta ou selada |
| | `artifact` | Uma coisa que existe (um arquivo, um serviço, uma release) |
| | `entity` | Um ente do domínio que outros nós citam |
| Domínio | `state` | Um estado de uma entidade |
| | `event` | Um evento que dispara transições |
| | `rule` | Uma regra de negócio |
| | `invariant` | Algo que tem de valer sempre |
| | `policy` | Uma política que governa regras |

O campo opcional `layer` (no `meta` ou no nó) declara a camada: `audit` (investigação) ou `domain` (modelo de
domínio).

### Status

A lista é do contrato; o uso descrito é o convencional. As exigências marcadas em negrito são do contrato.

| Status | Uso |
|---|---|
| `open` | Ainda em aberto |
| `confirmed` | Conferida, com fonte. **Exige `provenance`** |
| `drifted` | Era verdade e o vivo mudou desde a conferência |
| `unverifiable` | Não há fonte recuperável. É o destino honesto de um nó sem origem, e **não exige `provenance`** |
| `refuted` | A evidência contrária venceu |
| `superseded` | Outro nó tomou o lugar deste (aresta `SUPERSEDES`) |
| `done` | Concluída (uma tarefa, um épico) |

### Planos: `DEV` e `PROD`

`PROD` marca uma afirmação sobre o que está **em produção**, ou da qual a produção depende. Pesa mais: todo nó
PROD exige `provenance` (MUST, salvo `unverifiable`), e o contrato alerta quando ele não tem `verified_at`
(SHOULD). `DEV` é todo o resto: hipótese, investigação, plano.

## As arestas

Uma aresta tem `from`, `to` e `edge_type`, e opcionalmente `label` e `trigger`. As duas pontas têm de existir no
arquivo.

| Tipo | Leitura |
|---|---|
| `SUPPORTS` | `from` sustenta `to` |
| `REFUTES` | `from` contradiz `to` |
| `SUPERSEDES` | `from` substitui `to` |
| `CAUSES` | `from` causa `to` |
| `DEPENDS_ON` | `from` depende de `to` |
| `TRACES_TO` | `from` tem origem em `to` |
| `CONSTRAINS` | `from` restringe `to` |
| `HAS_STATE` | a entidade `from` tem o estado `to` |
| `TRANSITIONS` | o estado `from` passa a `to`; o evento que dispara vai em `trigger` |
| `EMITS` | `from` emite o evento `to` |
| `READS` · `WRITES` | `from` lê ou escreve `to` |

A chave `on` numa aresta é proibida (`yaml.forbidden-key-on`): um leitor YAML 1.1 lê `on` como o booleano
`true`, e a chave some. O gatilho de uma transição vai em `trigger`.

### Arestas entre grafos (`external_edges`)

Desde a 4.3, um grafo pode apontar para um nó de outro grafo do mesmo repositório. Cada aresta externa tem
**exatamente uma** ponta externa, escrita `<caminho relativo à raiz>#<id>`. A outra ponta é um id deste arquivo;
quando a ponta externa é o `to`, o `from` pode faltar, e então vale o grafo inteiro. Só seis tipos cruzam grafos: `SUPERSEDES`, `CONSTRAINS`,
`SUPPORTS`, `REFUTES`, `TRACES_TO` e `DEPENDS_ON`.

```yaml
external_edges:
  - from: D_CACHE_TTL_15MIN
    to: docs/exemplo.kg.yaml#Q_CACHE_TTL
    edge_type: TRACES_TO
```

O leitor confere a ponta externa só quando recebe a raiz do repositório (`--corpus`). Num repo git, ele lê só os
`.kg.yaml` rastreados: um grafo alvo que ainda não teve `git add` não conta. Fora de um repo git, lê todos. Sem ela, confere a forma e a
ponta local e diz na saída que não conferiu o resto.

## Proveniência

`provenance` diz **de onde veio** a afirmação. São três campos, todos obrigatórios e não vazios quando o objeto
existe:

| Campo | O que diz | Exemplo |
|---|---|---|
| `source` | A fonte: um arquivo, um endereço, uma pessoa | `tests/payment_retry_test.py` |
| `locator` | Onde, dentro da fonte | `test_retry_is_idempotent` |
| `method` | Como a afirmação saiu da fonte, na forma `<classe>: <detalhe>` | `medição: teste de integração no CI` |

`source` não pode ser um marcador vazio: `desconhecida`, `unknown`, `n/a`, `none`, `null`, `tbd`, `sem fonte`,
hífens, travessão ou `?` reprovam (`form.pattern.node.provenance.source`). Se não há fonte, o nó é
`unverifiable`, não `confirmed`.

### As cinco classes de `method`

| Classe | Quando usar |
|---|---|
| `medição` | Você rodou algo e observou o resultado: um teste, um benchmark, uma consulta |
| `leitura` | Você leu a fonte primária e a afirmação está nela |
| `juízes` | Mais de um avaliador independente votou |
| `derivado` | A afirmação foi deduzida de outros nós, sem conferência nova |
| `testemunho` | Alguém relatou. Inclui a medição feita por terceiro que você só leu |

Fora dessa forma, o contrato v4 **alerta** (`form.pattern.node.provenance.method`). No v5 vai reprovar.

Um quarto campo, opcional, `locality`, diz se a fonte é reverificável por terceiros: `repo` (arquivo versionado
no mesmo repositório), `web` (endereço público), `host` (só existe numa máquina), `pessoa` (relato de alguém) ou, desde a
4.12.0, `privado` (fora do repo, não público e reverificável por quem tem acesso, como o Google Drive da empresa).

## O carimbo de verificação

| Campo | O que diz |
|---|---|
| `verified_at` | A data da última conferência, `AAAA-MM-DD` |
| `verified_against` | O que foi conferido: o comando, o arquivo, a versão |
| `valid_from` | Desde quando o fato vale (`AAAA`, `AAAA-MM` ou `AAAA-MM-DD`) |

Uma `claim` com `verified_at` e sem `verified_against` alerta: carimbo sem alvo não distingue o verificado do
declarado. Um `verified_at` anterior ao `valid_from` também alerta (`integrity.verified-before-fact`).

Escreva as datas **entre aspas**: `verified_at: "2026-10-12"`. Sem aspas, um leitor YAML pode transformar a data
num objeto de data, e o contrato alerta (`yaml.unquoted-date`).

## Rótulo e narrativa

`label` é o **fato**, curto. O contrato alerta acima de 280 caracteres (`form.range.node.label`). A história, o
contexto e o raciocínio vão em `narrative`, um campo livre. Essa separação deixa o rótulo comparável e a
narrativa livre.

## Extensões: o prefixo `x_`

Uma chave fora da gramática reprova (`form.unknown-key.<escopo>.<chave>`), no topo, no `meta`, no nó e na
aresta. Para guardar um dado seu, use o prefixo `x_`: `x_prioridade: alta` passa. Dentro de `provenance`, a
chave desconhecida só alerta.
