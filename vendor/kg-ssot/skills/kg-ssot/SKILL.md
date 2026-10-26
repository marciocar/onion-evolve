---
name: kg-ssot
description: Write, fix, validate and query verifiable knowledge graphs in plain text (.kg.yaml, or the same model as .kg.json) with the KG-SSOT tools. Use when a task asks to record claims, evidence, decisions or open questions with their source and verification date, when a .kg.yaml or .kg.json file must pass the KG-SSOT contract, or when you need to answer a question from such graphs (what supports a decision, what was superseded, what is still open).
license: Apache-2.0
compatibility: Needs Python 3.11 or later and the kg-ssot package (pip install kg-ssot). Works offline.
metadata:
  homepage: https://github.com/marciocar/kg-ssot
  contract: "v4"
---

# KG-SSOT: verifiable knowledge graphs in plain text

A KG-SSOT graph is one file with a `meta` block, a list of `nodes` and a list of `edges`. Each node is a short claim
(`label`) with a status. A node that says it is `confirmed`, or that describes production (`plane: PROD`), must say
where it came from (`provenance`). A formal contract decides whether a file is well formed, and the reference reader
applies it.

Two formats carry the **same model**:

- `.kg.yaml` is for writing and reviewing by people and agents (restricted YAML 1.2: unique keys, dates in quotes);
- `.kg.json` is for programs at runtime (strict JSON: no comments, no trailing comma, no NaN, integers within ±(2^53−1)).

Pick the format the task names. If it names none, write `.kg.yaml`.

## Before you start

```bash
pip install kg-ssot        # the commands kg-validate, kg-query, kg-trace, kg-gate and more
kg-validate --help         # confirms the install
```

If the repository already vendors KG-SSOT, use `python3 -I vendor/kg-ssot/tools/kg_validate.py` (and the other tools
there) instead of the installed commands.

## Writing a graph

Start from this minimal graph. It passes the contract:

```yaml
meta:
  schema_version: "1"
  id: payments-review
nodes:
  - id: Q_RETRY
    node_type: question
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    label: "Is the payment retry safe to run twice?"
  - id: E_RETRY_TEST
    node_type: evidence
    plane: DEV
    status: confirmed
    impact: 4
    confidence: 0.9
    label: "The retry test passes with the same request sent twice."
    verified_at: "2026-10-26"
    verified_against: "tests/payment_retry_test.py"
    provenance:
      source: "tests/payment_retry_test.py"
      locator: "test_retry_is_idempotent"
      method: "medição: integration test in CI"
edges:
  - from: E_RETRY_TEST
    to: Q_RETRY
    edge_type: SUPPORTS
```

The same graph as `.kg.json` is the same keys and values as a JSON object: `{"meta": {...}, "nodes": [...],
"edges": [...]}`.

Rules that make a graph pass:

1. **Every node** has `id`, `node_type`, `plane`, `status`, `impact` (1 to 5), `confidence` (0 to 1) and `label`.
   Ids use letters, digits and `_`, start with a letter, and are unique in the file.
2. **Every edge** has `from`, `to` and `edge_type`, and both ends exist. **No node is left without an edge.**
3. **A `confirmed` node, or one in `plane: PROD`, has `provenance`** with `source` (what was read: a URL, a path, a
   command), `locator` (where in it) and `method` in the form `<class>: <detail>`. The class is one of `medição`
   (measurement), `leitura` (reading), `juízes` (judges), `derivado` (derived) or `testemunho` (testimony). These five
   words are literal contract values: keep them as written, even in an English graph. If you cannot name a real
   source, do not invent one: make the node `open` or `unverifiable`.
4. **Dates go in quotes** (`"2026-10-26"`). A bare date is read as a date object by some readers.
5. **The label is the claim, short** (up to 280 characters). Put the why and the context in `narrative`.
6. **A node that receives a `REFUTES` edge cannot stay `confirmed`.** Change its status to `refuted` or `superseded`.
   If the dissent only limits the claim, use `CONSTRAINS` instead of `REFUTES`.

The full list of node types, statuses, edge types and optional fields is in
[references/contract.md](references/contract.md).

## Validating and fixing

```bash
kg-validate team.kg.yaml            # or team.kg.json; several files at once also work
kg-validate --format json team.kg.yaml
```

- `PASS` means the file passes the MUST level. `SHOULD` lines are warnings: fix them when you can, but they do not
  fail the file.
- `FAIL` lists codes such as `form.required.node.provenance ×2`. Run `kg-validate --where team.kg.yaml` to get the
  line of each occurrence.
- Fix by code, not by guess. The fix for each common code is in [references/fixes.md](references/fixes.md).
- Validate again after every fix, until the result is `PASS`. Do not delete nodes to make a file pass, unless the task
  asks for it.

## Answering questions from graphs

`kg-query` reads one or more graphs (or every graph git tracks under `--root`) and projects the nodes:

```bash
kg-query --root . --text retry                     # nodes whose label has every word
kg-query --root . --type decision --status done    # filter by fields
kg-query --root . --around D_RELEASE --depth 2     # a node and its neighbourhood, with edge labels resolved
kg-query --root . --around E_OLD --edge-type SUPPORTS --direction out   # what this evidence supports
kg-query --root . --open --sort impact             # the open work, most important first
kg-query --format json ...                         # the same, as JSON for a program
```

To answer "which decisions rest on evidence that is now superseded", query the `superseded` evidence, then follow
its outgoing `SUPPORTS` edges with `--around ... --direction out`, and keep the targets whose `node_type` is
`decision`.

## Checking references

```bash
kg-trace check --root .     # every node's trace: field points to a file or URL that exists
```

## More capabilities: read the reference before you start

`--help` does not teach these. Read the matching file first:

| When the task asks for | Read |
|---|---|
| a domain vocabulary: a preferred term, its synonyms, a glossary (`x_term`) | [references/vocabulary.md](references/vocabulary.md) |
| a link to a node in **another** graph file, or one graph superseding a node of another (`external_edges`) | [references/cross-graph.md](references/cross-graph.md) |
| an acceptance rule fixed before the data, a versioned criterion, or a result measured under a criterion (`x_criterion`, `x_measured_under`) | [references/criteria.md](references/criteria.md) |
| the gate in CI: a baseline, a GitHub Actions workflow, adopting KG-SSOT in a repository | [references/ci-gate.md](references/ci-gate.md) |

## What not to do

- Do not write a second validator, or check the contract by reading the schema yourself: run `kg-validate`.
- Do not invent sources, dates or method classes to make a file pass.
- Do not edit a graph's history by hand to hide a change. Supersede the old node with a new one and a `SUPERSEDES`
  edge.
