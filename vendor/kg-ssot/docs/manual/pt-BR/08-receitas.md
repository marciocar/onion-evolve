<!-- translation-of: docs/manual/08-recipes.md sha256:0fbea3c4f2b33552 -->
# 8. Receitas

[English](../08-recipes.md) | **Português (Brasil)**

<sub>Tradução do original em inglês; quando os dois divergirem, vale o inglês.</sub>

[← Conformidade e leitores](07-conformidade-e-leitores.md) · [Índice](README.md) · [Solução de problemas →](09-problemas.md)

## Escrever o primeiro grafo

Uma pergunta e a evidência que a sustenta. A evidência é `confirmed`, então leva `provenance`.

```yaml
meta:
  schema_version: "1"
  id: example
  baseline: "2026-10-12"
  review_after: "2027-01-12"
nodes:
  - id: Q_CACHE_TTL
    node_type: question
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    label: Does the session cache need a TTL?
  - id: E_CACHE_GROWTH
    node_type: evidence
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    label: Without a TTL, cache memory grows 40 MB per hour in the load test.
    trace: bench/cache-load.md
    verified_at: "2026-10-12"
    provenance:
      source: bench/cache-load.md
      locator: table 2
      method: "medição: 4-hour load test"
edges:
  - from: E_CACHE_GROWTH
    to: Q_CACHE_TTL
    edge_type: SUPPORTS
```

O `method` começa pela classe, `medição`, seguida do detalhe.

Todo nó precisa de pelo menos uma aresta: um nó solto reprova como `integrity.orphan-node`. Por isso um grafo de
um nó só não passa, e o seu primeiro grafo já nasce com uma pergunta e o que a sustenta.

Com o venv da [adoção](06-adocao-e-ci.md) ativo (`. .venv/bin/activate`), ou com `.venv/bin/python3` no lugar de
`python3`:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/example.kg.yaml
```

```text
PASSA   docs/example.kg.yaml
· 1 arquivos; 1 passam no MUST; 0 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

## Consertar um nó que reprova

Este nó de produção reprovou com `form.required.node.provenance` e `form.unknown-key.node.priority`, e alertou
com `form.required.node.verified_against`:

```yaml
  - id: C_RETRY_SAFE
    node_type: claim
    plane: PROD
    status: confirmed
    impact: 4
    confidence: 0.8
    label: The payment retry is idempotent.
    verified_at: "2026-10-01"
    owner: payments-team
    priority: high
```

O conserto: a sua chave própria ganha o prefixo `x_`, o carimbo ganha alvo, e a proveniência diz de onde veio a
afirmação.

```yaml
    verified_at: "2026-10-01"
    owner: payments-team
    x_priority: high
    verified_against: tests/payment_retry_test.py
    provenance:
      source: tests/payment_retry_test.py
      locator: test_retry_is_idempotent
      method: "medição: integration test in CI"
```

## Registrar um relato sem inventar medição

Alguém do time disse que o retry é idempotente, e ninguém rodou nada. A classe é `testemunho`:

```yaml
    provenance:
      source: payments team
      locator: conversation on 2026-10-01
      method: "testemunho: report from the payments team"
```

Num nó PROD, o contrato alerta (`integrity.testimony-in-prod`): produção apoiada só em relato é um risco que o
grafo deve mostrar, não esconder.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where testimony.kg.yaml
```

```text
PASSA   testimony.kg.yaml
  SHOULD integrity.testimony-in-prod ×1
    SHOULD integrity.testimony-in-prod  nó C_RETRY_SAFE
· 1 arquivos; 1 passam no MUST; 1 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

## Um nó sem fonte nenhuma

Não escreva `source: unknown`: isso reprova. Em vez disso, mude o `status` do nó para `unverifiable`. Ele fica
válido sem `provenance`, mesmo em PROD, e o grafo diz a verdade: aquela afirmação não tem origem recuperável.

## Entregar um nó a um agente sem perder o status

O label de um nó é uma afirmação, e o `status` diz em que pé ela está. Um label como `The supplier does not meet
item 4.2` num nó `open` é uma afirmação em julgamento. Se a ferramenta que serve o grafo a um agente entrega só o
label, o agente lê aquilo como fato. Um adotante achou esse defeito no teste de um chat: a leitura do grafo mandava o
label de uma `claim` `open`, e o modelo respondeu que o fornecedor não atendia o item.

**A afirmação nunca viaja sem o status dela.** Quando você resume um nó para outra ferramenta (uma tool de MCP, um
prompt, um relatório), leve junto ao menos o `status`. Quando a resposta depende da força da evidência, leve também a
classe do `method`. E diga nas instruções do agente o que cada status quer dizer:

```text
C_ITEM_42 [claim · open] The supplier does not meet item 4.2.
  → under review: do not assert it; say it is being analyzed.
C_ITEM_17 [claim · confirmed · leitura] The supplier meets item 1.7.
  → confirmed by reading the document.
```

A ferramenta `kg_get` do `kg_mcp.py` devolve o grafo inteiro, com o `status` de cada nó. O risco está na camada que
você escreve em cima dele, quando resume.

## Ligar uma decisão a uma pergunta de outro grafo

```yaml
meta:
  schema_version: "1"
  id: decision
nodes:
  - id: D_CACHE_TTL_15MIN
    node_type: decision
    plane: DEV
    status: open
    impact: 3
    confidence: 0.7
    label: A 15-minute TTL on the session cache.
    trace: docs/adr/0009-cache-ttl.md
edges: []
external_edges:
  - from: D_CACHE_TTL_15MIN
    to: docs/example.kg.yaml#Q_CACHE_TTL
    edge_type: TRACES_TO
```

Confira com o corpus, para o leitor checar a ponta externa. Num repositório git, o corpus são os grafos rastreados,
então o grafo alvo precisa estar no git:

```bash
git add docs/example.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --corpus . docs/decision.kg.yaml
```

Com um id que não existe no outro grafo, o leitor reprova o arquivo:

```text
REPROVA docs/wrong.kg.yaml
  MUST   integrity.dangling-external ×1
· 1 arquivos; 0 passam no MUST; 0 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

## Travar o ganho depois de pagar dívida

Consertou um grafo herdado? O gate passa e pede `--update`. Rode no mesmo PR:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update
```

Sem isso, um PR futuro pode voltar a quebrar aquele grafo sem que o gate perceba, porque o grafo continuaria na
dívida herdada.

## Achar todos os nós com um código

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where docs/*.kg.yaml
```

Cada linha indentada traz o código e o nó, e dá para filtrar com `grep`.

## Uma regra de negócio ligada ao código

Num app, a regra fica no grafo, junto com a decisão de onde veio e o código que a implementa. Aqui, a regra da
sequência de um app de hábitos: a decisão de produto, a regra de domínio com o teste que a mede, e o arquivo do
código.

```yaml
meta:
  schema_version: "1"
  id: streak
  baseline: "2026-10-13"
  review_after: "2027-01-13"
nodes:
  - id: D_STREAK_RESET
    node_type: decision
    plane: PROD
    status: done
    impact: 4
    confidence: 0.9
    label: The streak resets after one full day with no entry, in the user's time zone.
    trace: docs/decisions/2026-10-streak.md
    verified_at: "2026-10-13"
    provenance:
      source: docs/decisions/2026-10-streak.md
      locator: Decision section
      method: "leitura: product decision record"
  - id: R_STREAK_RESET
    node_type: rule
    layer: domain
    plane: PROD
    status: confirmed
    impact: 4
    confidence: 0.9
    label: streak.reset() runs when the last entry is older than yesterday in the user's time zone.
    verified_at: "2026-10-13"
    provenance:
      source: tests/test_streak.py
      locator: test_resets_after_a_day_with_no_entry
      method: "medição: pytest tests/test_streak.py, 6 cases passing"
  - id: A_STREAK_CODE
    node_type: artifact
    layer: domain
    plane: PROD
    status: confirmed
    impact: 3
    confidence: 0.9
    label: The streak implementation lives in app/streak.py.
    verified_at: "2026-10-13"
    verified_against: app/streak.py
    provenance:
      source: app/streak.py
      locator: reset function
      method: "leitura: code at the release commit"
edges:
  - from: R_STREAK_RESET
    to: D_STREAK_RESET
    edge_type: TRACES_TO
  - from: R_STREAK_RESET
    to: A_STREAK_CODE
    edge_type: TRACES_TO
```

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/streak.kg.yaml
```

```text
PASSA   docs/streak.kg.yaml
· 1 arquivos; 1 passam no MUST; 0 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

O contrato confere a forma, as arestas e a proveniência. Ele não roda o seu teste nem lê o seu código: quem roda
`tests/test_streak.py` é o CI do app. O grafo registra o que foi medido, quando e como (`method`), e o `verified_at`
diz há quanto tempo. Quando a regra mudar, o PR que muda o código muda o nó também, e o diff mostra os dois juntos.
