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
      method: "measurement: 4-hour load test"
edges:
  - from: E_CACHE_GROWTH
    to: Q_CACHE_TTL
    edge_type: SUPPORTS
```

The `method` starts with its class, `measurement`, followed by the detail.

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
      method: "measurement: integration test in CI"
```

## Record a report without making up a measurement

Someone on the team said the retry is idempotent, and nobody ran anything. The class is `testimony`:

```yaml
    provenance:
      source: payments team
      locator: conversation on 2026-10-01
      method: "testimony: report from the payments team"
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
      method: "reading: product decision record"
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
      method: "measurement: pytest tests/test_streak.py, 6 cases passing"
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
      method: "reading: code at the release commit"
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

## Record an external event that arrived by a signed message

An e-mail, a chat message, a wiki edit or a cloud notification often reaches a company brain through an inbox, after a
signed envelope was checked and accepted. Record it as an `evidence` node, with no new node type: the `event` node
type already exists, and it means a domain event that changes a `state`.

- Put the event attributes in `x_event`, with the context attribute names of CloudEvents 1.0.2. CloudEvents requires
  `specversion`, `id`, `source` and `type`, and makes `subject`, `time`, `datacontenttype` and `dataschema` optional.
  The contract does not judge `x_event`: these rules come from CloudEvents. A resend should keep the same `source` +
  `id`, so that the consumer can treat it as a duplicate.
- The `provenance` points at the document that the inbox accepted. Its `sha256` is the hash of that file, so
  `kg_trace.py check` catches an edit made after acceptance. The `method` says that the accept step checked the
  signature and the body hash.
- The identifier of the delivery (the `jti` of the signed token) and the hash of the message body go as `x_jti` and
  `x_body_sha256` inside `provenance`. The contract accepts `x_` keys there without a warning. The body hash is not
  the `sha256` of the source, because the accepted document wraps the body.

The accepted document, `docs/inbox/2026-10-30-a2a-billing-agent-3f9c2a1b7d4e5f60.md`:

```markdown
---
from: billing-agent
---
Invoice 4512 was paid on 2026-10-29.
```

The file ends with a line break, and `sha256` is the hash of the whole file. The body is the last line, without
the line break, and `x_body_sha256` is its hash.

```yaml
meta:
  schema_version: "1"
  id: events
nodes:
  - id: Q_INVOICE_4512_PAID
    node_type: question
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    label: Was invoice 4512 paid?
  - id: E_INVOICE_4512_PAID
    node_type: evidence
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    label: Invoice 4512 was paid on 2026-10-29, as the billing agent reported.
    verified_at: "2026-10-30"
    verified_against: the accepted inbox document, with the signature and the body hash checked again on acceptance
    x_event:
      specversion: "1.0"
      id: "pay-4512-001"
      source: "https://billing.example.com/invoices"
      type: "com.example.billing.invoice.paid"
      subject: "invoice/4512"
      time: "2026-10-29T14:03:00Z"
    provenance:
      source: docs/inbox/2026-10-30-a2a-billing-agent-3f9c2a1b7d4e5f60.md
      locator: "the last line"
      method: "measurement: the accept step checked the signed envelope and the body hash again"
      sha256: "56a7861a08417a4fc45bd86f5268f33f8e38836cff6a98678151ff71c87ed281"
      x_jti: "nb-7c1e9a04d2b3"
      x_body_sha256: "fe4fcd74067bb4a644273109f601905615c27fc964cfb41d8201840fd7f746a6"
      locality: repo
edges:
  - from: E_INVOICE_4512_PAID
    to: Q_INVOICE_4512_PAID
    edge_type: SUPPORTS
```

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/events.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_trace.py check --root .
```

```text
PASS docs/events.kg.yaml
· 1 files; 1 pass the MUST; 0 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
· 1 source(s) read by scheme or sha256: 1 ok, 0 failed (1 sha256 checked); not judged (counted): 0 form only, 0 URL with no --with, 0 source not found, 0 malformed scheme, locator or hash, 0 other
· 0 trace(s) judged: 0 resolve, 0 missing; not judged (counted): 0 absolute or URL, 0 external root, 0 not a path, 0 not text
```

If someone edits the accepted document later, `kg_trace.py check` fails (rc 1):

```text
integrity.trace-sha256-mismatch  docs/events.kg.yaml#E_INVOICE_4512_PAID  → docs/inbox/2026-10-30-a2a-billing-agent-3f9c2a1b7d4e5f60.md [sha256] the last line  The provenance.sha256 of the node differs from the hash of the file it names: the source changed after it was read.
```

A node alone fails as `integrity.orphan-node`: an event always serves a question or a decision, so link it. The
recommended shape of `x_event`, and when it becomes a canonical profile, is in
[chapter 3](03-format.md#recording-an-external-event-recommended-shape-not-normative).

## Handle a small request from a person to an agent

A person asks an agent for a small service: a personal summary every working day. The request is done when the person
who asked accepts it, after a real test. Record it with what the contract already has: no new node type and no new
profile. A small, new request needs **two nodes**:

- **The request**, a `question` with `owner` (the role that answers for it). The narrative holds what was agreed with
  the person: when, what and from which sources, with the access to those sources checked. Commit this node **before**
  the test, with `status: open`; it becomes `done` in the commit that adds the acceptance. The git history then shows
  that the agreement came first. The contract does not check this order today.
- **The acceptance**, an `evidence` with `provenance.method` of class `testimony`: the person who asked, with a
  `locator` that points at the reply. It comes after a real test, never before. The agent does not testify to its own
  acceptance: `testimony` comes from an outside party, and the agent that did the work is not one (see
  [who did it](03-format.md#who-did-it-the-subagent-rule-v423)). Here the test is a real summary sent on 2026-11-18,
  before the first scheduled run.

Two more nodes appear only when they are needed:

- **When the request recurs**, the service itself is a ritual: a `rule` with
  [`x_ritual`](03-format.md#x_ritual-v425) and a `TRACES_TO` edge to the request. The contract judges
  `x_ritual` from v4.25 on; with an earlier contract, the key is free and is not judged.
- **When something blocks the request**, the blocker is a `question` with a `CONSTRAINS` edge to the request, and
  `x_essential` says whether it is essential to the agreed minimum. A blocker that is not essential does not stop the
  service: the agent delivers the agreed minimum, or asks the person, and never waits in silence. `x_essential` is a
  free `x_` key: the contract does not judge it.

A larger request adds what it needs: a separate pre-registered criterion
([`x_criterion`](03-format.md#x_criterion-and-x_measured_under-v412)), an
[`x_questionnaire`](03-format.md#x_mirror-x_doc_cycle-and-x_questionnaire) with several evidence requests, domain
states, a test separate from the acceptance, and more than one approver.

```yaml
meta:
  schema_version: "1"
  id: requests
nodes:
  - id: Q_REQUEST_DAILY_SUMMARY
    node_type: question
    plane: DEV
    status: done
    impact: 2
    confidence: 0.8
    owner: assistant-operator
    label: "The finance lead asked for a personal summary every working day: is it agreed, tested and accepted?"
    narrative: "Agreed with the finance lead on 2026-11-17, before any test: every working day at 08:00 (America/Sao_Paulo), by direct message; content: overdue invoices, payments received the day before and open approvals; sources: the billing system and the approval queue, read with the lead's own access, checked on 2026-11-17."
  - id: R_DAILY_SUMMARY_FINANCE
    node_type: rule
    plane: DEV
    status: open
    impact: 2
    confidence: 0.8
    owner: assistant-operator
    label: "Every working day at 08:00 (America/Sao_Paulo), the finance lead gets the personal summary by direct message."
    reverify_every: P3D
    x_ritual:
      purpose: "the finance lead starts the day knowing what is overdue, paid and waiting for approval"
      kind: deterministic
      autonomy: notify
      emits: com.example.ritual.finance-summary.completed
      calendar:
        rrule: "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYHOUR=8;BYMINUTE=0;BYSECOND=0"
        dtstart: "20261119T080000"
        tz: America/Sao_Paulo
  - id: Q_BLOCKER_PAYMENTS_CHART
    node_type: question
    plane: DEV
    status: open
    impact: 1
    confidence: 0.5
    label: "Drawing the payments chart as an image needs a library that is not installed yet."
    narrative: "Not essential to the agreed minimum: the summary goes as text now, and the chart comes later."
    x_essential: false
  - id: E_ACCEPTED_DAILY_SUMMARY
    node_type: evidence
    plane: DEV
    status: confirmed
    impact: 2
    confidence: 0.9
    label: "The finance lead got a real test summary on 2026-11-18 and accepted it as agreed."
    verified_at: "2026-11-18"
    verified_against: "the reply of the finance lead to the test summary"
    provenance:
      source: "the finance lead, by direct message"
      locator: "reply of 2026-11-18 09:12 to the test summary, in the direct-message thread"
      method: "testimony: acceptance by the person who asked, after a real test"
      locality: pessoa
edges:
  - from: R_DAILY_SUMMARY_FINANCE
    to: Q_REQUEST_DAILY_SUMMARY
    edge_type: TRACES_TO
  - from: Q_BLOCKER_PAYMENTS_CHART
    to: Q_REQUEST_DAILY_SUMMARY
    edge_type: CONSTRAINS
  - from: E_ACCEPTED_DAILY_SUMMARY
    to: Q_REQUEST_DAILY_SUMMARY
    edge_type: SUPPORTS
```

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/requests.kg.yaml
```

```text
PASS docs/requests.kg.yaml
· 1 files; 1 pass the MUST; 0 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

The contract checks the form, the edges and the provenance. It does not check that the test was real, that the reply
came from that person, or that the agent did not wait on a blocker that was not essential. The graph keeps those facts
where a person can read them, with dates. This recipe is a guide, not a contract rule: the warnings for a request
closed without an outside acceptance will come only if use shows that they are needed.
