# KG-SSOT manual

**English** | [Português (Brasil)](pt-BR/README.md)

KG-SSOT is a **verifiable knowledge graph** in a plain text file. Each claim can carry its source, the date it was
verified, and what it was verified against. A formal contract decides whether the file is well formed. This manual
covers the `.kg.yaml` format, the contract, the tools, and how to adopt KG-SSOT in a repository.

This manual describes release **4.22.0** (tag `kg-ssot-v4.22.0`). The current contract in this release is **v4**.

The manual is also available in Brazilian Portuguese, in [`docs/manual/pt-BR/`](pt-BR/README.md). When the two
differ, the English text wins.

## Chapters

| # | Chapter | What it covers |
|---|---|---|
| 1 | [What it is and who it is for](01-what-it-is.md) | The problem, the thesis, and who benefits |
| 2 | [Concepts](02-concepts.md) | Graph, node, types, status, planes, edges, provenance, verification stamp |
| 3 | [Format reference](03-format.md) | Every `.kg.yaml` field, taken from the schema |
| 4 | [The contract](04-contract.md) | MUST vs. SHOULD, error codes, versions, and tags |
| 5 | [Tools](05-tools.md) | `kg_validate`, `kg_conformance`, `kg_gate`, `kg_vendor`, `kg_store`, `kg_mcp`, `kg_query`, `kg_diff`, `kg_prov_export`, `kg_migrate`, with real output |
| 6 | [Adoption and CI](06-adoption-and-ci.md) | The short path to bring the contract into a repository |
| 7 | [Conformance and readers](07-conformance-and-readers.md) | The case suite and how to write your own reader |
| 8 | [Recipes](08-recipes.md) | Common tasks, step by step |
| 9 | [Troubleshooting](09-troubleshooting.md) | What each error means and how to fix it |
| 10 | [Glossary](10-glossary.md) | The terms used in this manual |

## Quick start

- **Writing a graph?** Read chapters 2 and 3, and turn to chapter 9 when the reader fails your file.
- **Adopting KG-SSOT in a repository?** Start with chapter 6, then move on to [`ADOPTING.md`](../../ADOPTING.md).
- **Writing a reader in another language?** Read chapter 7 and [`spec/conformance/README.md`](../../spec/conformance/README.md).

## Sources of truth

This manual is explanatory, not normative. When it differs from one of these files, the files win:

- the contract: [`spec/kg-contract-v4.schema.json`](../../spec/kg-contract-v4.schema.json) (MUST) and
  [`spec/kg-contract-v4.should.schema.json`](../../spec/kg-contract-v4.should.schema.json) (SHOULD);
- the suite: [`spec/conformance/`](../../spec/conformance/README.md);
- the release surface: [`spec/release.json`](../../spec/release.json).

Every command output in this manual was pasted from a real run, on Python 3.12 with the versions pinned in
[`tools/requirements.txt`](../../tools/requirements.txt). The tools print human-readable output in English by default,
and in Brazilian Portuguese when you set `KG_SSOT_LANG=pt-BR` or run under a `pt_BR` locale. Error codes, exit codes
and JSON keys never change language; only the human text does.
