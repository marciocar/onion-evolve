# 1. What it is and who it is for

**English** | [Português (Brasil)](pt-BR/01-o-que-e.md)

[← Index](README.md) · [Concepts →](02-concepts.md)

## The problem

A team, whether of people or of agents, piles up conclusions: "the retry is idempotent," "the cache needs a TTL,"
"we decided on three attempts." These usually live in meeting notes, tickets, and chat memories. Three things get
lost along the way:

1. **Where it came from.** The conclusion loses its source and turns into repeated opinion.
2. **When it was verified.** A fact that was true in March can be false in October, and nothing warns you.
3. **What depends on what.** When a piece of evidence falls, nobody knows which decisions fall with it.

Anything that writes knowledge, whether a person or a model, can produce convincing text with none of the three.
KG-SSOT treats this as a problem of **verifiable format**, not of good intentions.

## The thesis

Operational knowledge fits in a **graph stored as a text file**, versioned next to the code, where:

- each node is a short, typed claim (question, evidence, decision, artifact...);
- every `confirmed` or production node (unless it is `unverifiable`) says **where it came from** (`provenance`), and the verification stamp says
  **when** and **against what** it was verified (`verified_at`, `verified_against`);
- the edges say **what supports, refutes, supersedes, or depends on** what;
- a **formal contract** (JSON Schema 2020-12 plus integrity rules) decides what fails and what only warns, and any
  reader, in any language, proves it follows the contract by passing a **conformance suite**.

The result is a file that a machine can judge in CI, the same way it judges code.

## What comes in the product

| Piece | What it is |
|---|---|
| The contract | Two JSON Schemas, MUST (fails) and SHOULD (warns), plus the integrity rules the schema cannot reach |
| The conformance suite | 438 cases in `latest/`, as plain data, each with its expected verdict and codes |
| The reference reader | `kg_validate.py`, on Python 3.11 or later with PyYAML and jsonschema, and no other dependency |
| The adoption kit | `kg_vendor.py`, which brings in a release by tag, and `kg_gate.py`, the per-graph ratchet in CI |
| The gated store | `kg_store.py`, which writes graphs to disk, to a git repository, or to a versioned store, only after the contract returns PASS |
| The reference MCP server | `kg_mcp.py`, which gives a model the contract and the store over MCP, through stdio or local HTTP |
| Query and diff | `kg_query.py`, which selects nodes and projects their edges with the label of the other end, and `kg_diff.py`, the diff by id between revisions |
| The PROV-O exporter | `kg_prov_export.py`, which exports each node's provenance to the W3C PROV ecosystem as JSON-LD |

## Who it is for

- **Engineering teams** that record decisions and evidence and want CI to reject a claim that has no source.
- **People who build agents** and need a memory that the agent reads first and that refuses writes with no origin.
- **People who write graph tools** (viewers, extractors, ports to other languages) and want to prove compatibility
  with a suite, not with "it works on my machine."

## What KG-SSOT is not

- **It is not a graph database.** There is no database engine, query language, or index to run. It is a file format
  with a contract, and `kg_query.py` and `kg_mcp.py` read the files directly.
- **It is not a semantic web standard.** It is not RDF or OWL. The format is YAML with a small, closed vocabulary.
- **It does not decide whether a claim is true.** The contract checks that the claim **says** where it came from and
  when it was verified. Checking the source again is the reviewer's job.
- **It does not depend on an editor, an assistant, or a platform.** The contract and the reference reader run on
  Python with two libraries, PyYAML and jsonschema.
