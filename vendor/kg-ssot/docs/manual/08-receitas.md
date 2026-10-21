# 8. Receitas

[← Conformidade e leitores](07-conformidade-e-leitores.md) · [Índice](README.md) · [Solução de problemas →](09-problemas.md)

## Escrever o primeiro grafo

Uma pergunta e a evidência que a sustenta. A evidência é `confirmed`, então leva `provenance`.

```yaml
meta:
  schema_version: "1"
  id: exemplo
  baseline: "2026-10-12"
  review_after: "2027-01-12"
nodes:
  - id: Q_CACHE_TTL
    node_type: question
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    label: O cache de sessão precisa de TTL?
  - id: E_CACHE_GROWTH
    node_type: evidence
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    label: Sem TTL, a memória do cache cresce 40 MB por hora no teste de carga.
    trace: bench/cache-load.md
    verified_at: "2026-10-12"
    provenance:
      source: bench/cache-load.md
      locator: tabela 2
      method: "medição: teste de carga de 4 horas"
edges:
  - from: E_CACHE_GROWTH
    to: Q_CACHE_TTL
    edge_type: SUPPORTS
```

Todo nó precisa de pelo menos uma aresta: um nó solto reprova como `integrity.orphan-node`. Por isso um grafo de
um nó só não passa, e o primeiro grafo já nasce com uma pergunta e o que a sustenta.

Com o venv da [adoção](06-adocao-e-ci.md) ativo (`. .venv/bin/activate`), ou com `.venv/bin/python3` no lugar de
`python3`:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/exemplo.kg.yaml
```

```text
PASSA   docs/exemplo.kg.yaml
· 1 arquivos; 1 passam no MUST; 0 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

## Consertar um nó que reprova

Este nó de produção reprovou com `form.required.node.provenance` e `form.unknown-key.node.prioridade`, e alertou
com `form.required.node.verified_against`:

```yaml
  - id: C_RETRY_SAFE
    node_type: claim
    plane: PROD
    status: confirmed
    impact: 4
    confidence: 0.8
    label: O retry do pagamento é idempotente.
    verified_at: "2026-10-01"
    owner: time-pagamentos
    prioridade: alta
```

O conserto: a chave própria ganha o prefixo `x_`, o carimbo ganha alvo, e a proveniência diz de onde veio.

```yaml
    verified_at: "2026-10-01"
    owner: time-pagamentos
    x_prioridade: alta
    verified_against: tests/payment_retry_test.py
    provenance:
      source: tests/payment_retry_test.py
      locator: test_retry_is_idempotent
      method: "medição: teste de integração no CI"
```

## Registrar um relato sem inventar medição

Alguém do time disse que o retry é idempotente, e ninguém rodou nada. A classe é `testemunho`:

```yaml
    provenance:
      source: time de pagamentos
      locator: conversa de 2026-10-01
      method: "testemunho: relato do time de pagamentos"
```

Num nó PROD, o contrato alerta (`integrity.testimony-in-prod`): produção apoiada só em relato é um risco que o
grafo deve mostrar, não esconder.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where testemunho.kg.yaml
```

```text
PASSA   testemunho.kg.yaml
  SHOULD integrity.testimony-in-prod ×1
    SHOULD integrity.testimony-in-prod  nó C_RETRY_SAFE
· 1 arquivos; 1 passam no MUST; 1 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

## Um nó sem fonte nenhuma

Não escreva `source: desconhecida`: isso reprova. Marque o nó como `unverifiable`, e ele fica válido sem
`provenance`, mesmo em PROD. O grafo passa a dizer a verdade: aquilo não tem origem recuperável.

## Entregar um nó a um agente sem perder o status

O label de um nó é uma afirmação, e o `status` diz em que pé ela está. Um label como `O fornecedor não atende o item
4.2` num nó `open` é uma afirmação em julgamento. Se a ferramenta que serve o grafo a um agente entrega só o label, o
agente lê aquilo como fato. Um adotante achou esse defeito no teste do chat: a leitura do grafo mandava o label de uma
`claim` `open`, e o modelo respondeu que o fornecedor não atendia.

**A afirmação nunca viaja sem o status dela.** Quem resume um nó para outra ferramenta (uma tool de MCP, um prompt, um
relatório) leva junto ao menos o `status`. Quando a resposta depende da força da evidência, leva também a classe do
`method`. E diz nas instruções do agente o que cada status quer dizer:

```text
C_ITEM_42 [claim · open] O fornecedor não atende o item 4.2.
  → em julgamento: não afirme; diga que está em análise.
C_ITEM_17 [claim · confirmed · leitura] O fornecedor atende o item 1.7.
  → confirmado por leitura do documento.
```

O `kg_get` do `kg_mcp.py` devolve o grafo inteiro, com o `status` de cada nó. O risco está na camada que o adotante
escreve em cima dele, quando resume.

## Ligar uma decisão a uma pergunta de outro grafo

```yaml
meta:
  schema_version: "1"
  id: decisao
nodes:
  - id: D_CACHE_TTL_15MIN
    node_type: decision
    plane: DEV
    status: open
    impact: 3
    confidence: 0.7
    label: TTL de 15 minutos no cache de sessão.
    trace: docs/adr/0009-cache-ttl.md
edges: []
external_edges:
  - from: D_CACHE_TTL_15MIN
    to: docs/exemplo.kg.yaml#Q_CACHE_TTL
    edge_type: TRACES_TO
```

Confira com o corpus, para a ponta externa ser checada. Num repo git, o corpus são os grafos rastreados, então o
grafo alvo precisa estar no git:

```bash
git add docs/exemplo.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --corpus . docs/decisao.kg.yaml
```

Com um id que não existe no outro grafo, o leitor reprova:

```text
REPROVA docs/errado.kg.yaml
  MUST   integrity.dangling-external ×1
```

## Travar o ganho depois de pagar dívida

Consertou um grafo herdado? O gate passa e pede `--update`. Rode no mesmo PR:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update
```

Sem isso, um PR futuro pode voltar a quebrar aquele grafo sem que o gate perceba, porque ele continuaria na
dívida herdada.

## Achar todos os nós com um código

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where docs/*.kg.yaml
```

Cada linha indentada traz o código e o nó, e dá para filtrar com `grep`.

## Uma regra de negócio ligada ao código

Num app, a regra fica no grafo com a decisão de onde veio e o código que a implementa. Aqui, a regra da sequência
de um app de hábitos: a decisão de produto, a regra de domínio com o teste que a mede, e o arquivo do código.

```yaml
meta:
  schema_version: "1"
  id: sequencia
  baseline: "2026-10-13"
  review_after: "2027-01-13"
nodes:
  - id: D_STREAK_RESET
    node_type: decision
    plane: PROD
    status: done
    impact: 4
    confidence: 0.9
    label: A sequência zera depois de um dia inteiro sem registro, no fuso do usuário.
    trace: docs/decisoes/2026-10-sequencia.md
    verified_at: "2026-10-13"
    provenance:
      source: docs/decisoes/2026-10-sequencia.md
      locator: seção Decisão
      method: "leitura: registro da decisão de produto"
  - id: R_STREAK_RESET
    node_type: rule
    layer: domain
    plane: PROD
    status: confirmed
    impact: 4
    confidence: 0.9
    label: streak.reset() roda quando o último registro é anterior a ontem no fuso do usuário.
    verified_at: "2026-10-13"
    provenance:
      source: tests/test_streak.py
      locator: test_zera_depois_de_um_dia_sem_registro
      method: "medição: pytest tests/test_streak.py, 6 casos passando"
  - id: A_STREAK_CODE
    node_type: artifact
    layer: domain
    plane: PROD
    status: confirmed
    impact: 3
    confidence: 0.9
    label: A implementação da sequência mora em app/streak.py.
    verified_at: "2026-10-13"
    verified_against: app/streak.py
    provenance:
      source: app/streak.py
      locator: função reset
      method: "leitura: código no commit da release"
edges:
  - from: R_STREAK_RESET
    to: D_STREAK_RESET
    edge_type: TRACES_TO
  - from: R_STREAK_RESET
    to: A_STREAK_CODE
    edge_type: TRACES_TO
```

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/sequencia.kg.yaml
```

```text
PASSA   docs/sequencia.kg.yaml
· 1 arquivos; 1 passam no MUST; 0 com aviso SHOULD (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

O contrato confere a forma, as arestas e a proveniência, e não roda o seu teste nem lê o seu código: quem roda
`tests/test_streak.py` é o CI do app. O grafo registra o que foi medido, quando e como (`method`), e o `verified_at`
diz há quanto tempo. Quando a regra mudar, o PR que muda o código muda o nó também, e o diff mostra os dois juntos.
