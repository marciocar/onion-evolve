# 8. Recipes

**English** | [Português (Brasil)](pt-BR/08-receitas.md)

[← Conformance and readers](07-conformance-and-readers.md) · [Index](README.md) · [Troubleshooting →](09-troubleshooting.md)

## Write your first graph

A question and the evidence that supports it. The evidence is `confirmed`, so it carries `provenance`.

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

The `method` starts with its class, `medição` (measurement), followed by the detail.

Every node needs at least one edge: a node on its own fails as `integrity.orphan-node`. That is why a graph with a
single node does not pass, and why your first graph starts with a question and what supports it.

With the venv from [adoption](06-adoption-and-ci.md) active (`. .venv/bin/activate`), or with `.venv/bin/python3`
in place of `python3`:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/example.kg.yaml
```

```text
PASS docs/example.kg.yaml
· 1 files; 1 pass the MUST; 0 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

## Fix a node that fails

This production node failed with `form.required.node.provenance` and `form.unknown-key.node.priority`, and it
warned with `form.required.node.verified_against`:

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

The fix: your own key gets the `x_` prefix, the stamp gets a target, and the provenance says where the claim came
from.

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

## Record a report without making up a measurement

Someone on the team said the retry is idempotent, and nobody ran anything. The class is `testemunho` (testimony):

```yaml
    provenance:
      source: payments team
      locator: conversation on 2026-10-01
      method: "testemunho: report from the payments team"
```

On a PROD node, the contract warns (`integrity.testimony-in-prod`): production backed only by a report is a risk the
graph should show, not hide.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where testimony.kg.yaml
```

```text
PASS testimony.kg.yaml
  SHOULD integrity.testimony-in-prod ×1
    SHOULD integrity.testimony-in-prod  nó C_RETRY_SAFE
· 1 files; 1 pass the MUST; 1 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

## A node with no source at all

Do not write `source: unknown`: that fails. Set the node's `status` to `unverifiable` instead. It stays valid
without `provenance`, even in PROD, and the graph tells the truth: the claim has no recoverable origin.

## Hand a node to an agent without losing its status

A node's label is a claim, and its `status` says where that claim stands. A label like `The supplier does not meet
item 4.2` on an `open` node is a claim under review. If the tool that serves the graph to an agent sends only the
label, the agent reads it as fact. An adopter found this defect while testing a chat: the graph lookup sent the label
of an `open` `claim`, and the model answered that the supplier did not meet the item.

**A claim never travels without its status.** When you summarize a node for another tool (an MCP tool, a prompt, a
report), include at least the `status`. When the answer depends on how strong the evidence is, include the `method`
class too. Then tell the agent, in its instructions, what each status means:

```text
C_ITEM_42 [claim · open] The supplier does not meet item 4.2.
  → under review: do not assert it; say it is being analyzed.
C_ITEM_17 [claim · confirmed · leitura] The supplier meets item 1.7.
  → confirmed by reading the document.
```

The `kg_get` tool in `kg_mcp.py` returns the whole graph, with the `status` of every node. The risk lies in the layer
you write on top of it, when you summarize.

## Link a decision to a question in another graph

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

Validate it with the corpus, so the reader checks the external end. In a git repository, the corpus is the tracked
graphs, so the target graph has to be in git:

```bash
git add docs/example.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --corpus . docs/decision.kg.yaml
```

With an id that does not exist in the other graph, the reader fails the file:

```text
FAIL docs/wrong.kg.yaml
  MUST   integrity.dangling-external ×1
· 1 files; 0 pass the MUST; 0 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

## Lock in the gain after paying down debt

Fixed an inherited graph? The gate passes and asks for `--update`. Run it in the same PR:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update
```

Without it, a future PR could break that graph again and the gate would not notice, because the graph would still sit
in the inherited debt.

## Find every node with a given code

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where docs/*.kg.yaml
```

Each indented line carries the code and the node, so you can filter with `grep`.

## A business rule linked to code

In an app, the rule lives in the graph, together with the decision it came from and the code that implements it. Here
is the streak rule of a habit app: the product decision, the domain rule with the test that measures it, and the code
file.

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
PASS docs/streak.kg.yaml
· 1 files; 1 pass the MUST; 0 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

The contract checks the form, the edges, and the provenance. It does not run your test or read your code: the app's CI
runs `tests/test_streak.py`. The graph records what was measured, when, and how (`method`), and `verified_at` tells
you how long ago. When the rule changes, the PR that changes the code changes the node too, and the diff shows both
together.
