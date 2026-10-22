# 2. Concepts

**English** | [Português (Brasil)](pt-BR/02-conceitos.md)

[← What it is](01-what-it-is.md) · [Index](README.md) · [Format reference →](03-format.md)

## The graph

A graph is **one file**, `.kg.yaml` (or its JSON twin, `.kg.json`), with three required top-level keys: `meta` (the
graph's identity), `nodes` (the claims), and `edges` (the relations between them). A fourth key, `external_edges`, is
optional and links a node in this file to a node in another one. A repository can hold as many graphs as you want.

```yaml
meta:
  schema_version: "1"
  id: example
nodes:
  - id: Q_CACHE_TTL
    node_type: question
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    label: Does the session cache need a TTL?
edges: []
```

Does this graph pass the MUST level? No. A node with no edge is an **orphan**, and it fails
(`integrity.orphan-node`): every node needs at least one edge. The full example, with a piece of evidence linked to
the question, is in [chapter 8](08-recipes.md#write-your-first-graph).

## The node

Each node is a short claim. It has seven required fields:

| Field | What it says |
|---|---|
| `id` | A unique identifier within the file: a letter first, then letters, digits, and `_` |
| `node_type` | What kind of claim it is (table below) |
| `plane` | `DEV` or `PROD` |
| `status` | Where the claim stands (table below) |
| `impact` | An integer from 1 to 5: how much it costs if the claim is wrong |
| `confidence` | A number from 0 to 1: how much you trust it today |
| `label` | The claim itself, as short text |

### Node types (`node_type`)

The contract closes the list at eleven types, in two families. The names come from the contract; the usage shown is
the convention.

| Family | Type | Usage |
|---|---|---|
| Investigation | `question` | An open question |
| | `claim` | A statement that needs evidence |
| | `evidence` | Something observed or measured that supports or refutes something else |
| | `decision` | A choice, open or sealed |
| | `artifact` | A thing that exists (a file, a service, a release) |
| | `entity` | A domain entity that other nodes refer to |
| Domain | `state` | A state of an entity |
| | `event` | An event that triggers transitions |
| | `rule` | A business rule |
| | `invariant` | Something that must always hold |
| | `policy` | A policy that governs rules |

The optional `layer` field (in `meta` or on a node) declares the layer: `audit` (investigation) or `domain` (domain
model).

### Status

The list comes from the contract; the usage shown is the convention. The requirements in bold come from the contract.

| Status | Usage |
|---|---|
| `open` | Still open |
| `confirmed` | Verified, with a source. **Requires `provenance`** |
| `drifted` | It was true, and the live system has changed since it was verified |
| `unverifiable` | No recoverable source exists. This is the honest end state for a node with no origin, and it **does not require `provenance`** |
| `refuted` | The opposing evidence won |
| `superseded` | Another node took this one's place (a `SUPERSEDES` edge) |
| `done` | Finished (a task, an epic) |

### Planes: `DEV` and `PROD`

`PROD` marks a claim about what runs **in production**, or one that production depends on. It carries more weight:
every PROD node requires `provenance` (MUST, unless it is `unverifiable`), and the contract warns when it has no
`verified_at` (SHOULD). `DEV` is everything else: hypotheses, investigations, plans.

## Edges

An edge has `from`, `to`, and `edge_type`, plus an optional `label` and `trigger`. Both ends must exist in the file.

| Type | How to read it |
|---|---|
| `SUPPORTS` | `from` supports `to` |
| `REFUTES` | `from` contradicts `to` |
| `SUPERSEDES` | `from` replaces `to` |
| `CAUSES` | `from` causes `to` |
| `DEPENDS_ON` | `from` depends on `to` |
| `TRACES_TO` | `from` originates in `to` |
| `CONSTRAINS` | `from` constrains `to` |
| `HAS_STATE` | the entity `from` has the state `to` |
| `TRANSITIONS` | the state `from` moves to `to`; the event that triggers it goes in `trigger` |
| `EMITS` | `from` emits the event `to` |
| `READS` · `WRITES` | `from` reads or writes `to` |

The key `on` is forbidden on an edge (`yaml.forbidden-key-on`): a YAML 1.1 reader reads `on` as the boolean `true`,
and the key disappears. Put the trigger of a transition in `trigger`.

### Edges between graphs (`external_edges`)

Since 4.3.0, a graph can point to a node in another graph of the same repository. Each external edge has **exactly
one** external end, written `<path from the repository root>#<id>`. The path can end in `.kg.yaml` or, since 4.14.0,
in `.kg.json`. The other end is an id in this file. When the external end is `to`, you can leave out `from`, and the
edge then stands for the whole graph. Only six types cross graphs: `SUPERSEDES`, `CONSTRAINS`, `SUPPORTS`, `REFUTES`,
`TRACES_TO`, and `DEPENDS_ON`.

```yaml
external_edges:
  - from: D_CACHE_TTL_15MIN
    to: docs/example.kg.yaml#Q_CACHE_TTL
    edge_type: TRACES_TO
```

The reader verifies the external end only when you give it the repository root (`--corpus`). In a git repository, it
reads only the tracked `.kg.yaml` and `.kg.json` files: a target graph that has not been through `git add` yet does
not count. Outside a git repository, it reads them all. Without `--corpus`, the reader verifies the shape and the
local end, and its output says that it did not verify the rest.

## Provenance

`provenance` says **where the claim came from**. It has three fields, all required and non-empty whenever the object
is present:

| Field | What it says | Example |
|---|---|---|
| `source` | The source: a file, an address, a person | `tests/payment_retry_test.py` |
| `locator` | Where, inside the source | `test_retry_is_idempotent` |
| `method` | How the claim came out of the source, in the form `<class>: <detail>` | `medição: integration test in CI` |

`source` cannot be an empty placeholder: `desconhecida`, `unknown`, `n/a`, `none`, `null`, `tbd`, `sem fonte`,
one or more hyphens, an em dash, an en dash, or `?` fail (`form.pattern.node.provenance.source`). If there is no
source, the node is `unverifiable`, not `confirmed`.

### The five `method` classes

The class names are literal contract values, so you write them in Portuguese, exactly as shown.

| Class | When to use it |
|---|---|
| `medição` (measurement) | You ran something and observed the result: a test, a benchmark, a query |
| `leitura` (reading) | You read the primary source, and the claim is in it |
| `juízes` (judges) | More than one independent evaluator voted |
| `derivado` (derived) | The claim was deduced from other nodes, with no new verification |
| `testemunho` (testimony) | Someone reported it. This includes a measurement made by someone else that you only read |

A `method` outside this form **warns** in contract v4 (`form.pattern.node.provenance.method`). In v5 it will fail.

A fourth, optional field, `locality`, says whether a third party can re-verify the source: `repo` (a versioned file in
the same repository), `web` (a public address), `host` (exists on one machine only), `pessoa` (a person's report) or,
since 4.12.0, `privado` (private: outside the repository and not public, but re-verifiable by anyone with access, such
as a company Google Drive).

## The verification stamp

| Field | What it says |
|---|---|
| `verified_at` | The date of the last verification, `YYYY-MM-DD` |
| `verified_against` | What it was verified against: the command, the file, the version |
| `valid_from` | Since when the fact holds (`YYYY`, `YYYY-MM`, or `YYYY-MM-DD`) |

A `claim` with `verified_at` and no `verified_against` warns (`form.required.node.verified_against`): a stamp with no
target cannot tell what was verified from what was only declared. A `verified_at` earlier than `valid_from` also warns
(`integrity.verified-before-fact`).

Write dates **in quotes**: `verified_at: "2026-10-12"`. Without quotes, a YAML reader can turn the date into a date
object, and the contract warns (`yaml.unquoted-date`).

## Label and narrative

`label` is the **fact**, kept short. The contract warns above 280 characters (`form.range.node.label`). The story, the
context, and the reasoning go in `narrative`, a free-form field. This split keeps the label comparable and the
narrative free.

## Extensions: the `x_` prefix

A key outside the grammar fails (`form.unknown-key.<scope>.<key>`) at the top level, in `meta`, on a node, and on an
edge. To store data of your own, use the `x_` prefix: `x_priority: high` passes. Inside `provenance`, an unknown key
only warns.
