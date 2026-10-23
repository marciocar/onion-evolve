# KG-SSOT

<!-- mcp-name: io.github.marciocar/kg-ssot -->

**A verifiable knowledge graph: every claim says where it came from, when it was verified, and what depends on it.
Your CI rejects the claims that don't.**

This package ships the formal KG-SSOT contract and the tools that enforce it:

- the **reference reader**, which checks a `.kg.yaml` or `.kg.json` graph against the contract at two levels: MUST,
  which fails, and SHOULD, which warns;
- the **conformance suite**, as plain data, that every reader must pass;
- the **per-graph gate** for CI, with a ratchet: existing debt stays named and can't get worse;
- the **store**, which only writes what passes the contract;
- the **reference MCP server**, which gives a model the contract and the store over stdio or local HTTP;
- the **domain vocabulary**, with the source and verification date of each synonym, exported to SKOS-XL and Apache Ossie;
- the **provenance exporter** to PROV-O in JSON-LD.

The contract, the suite, and the verdict schema ship inside the package. The reader depends on no agent harness.
It needs Python 3.11 or later, PyYAML, and jsonschema.

## Install

```bash
pip install kg-ssot
```

To run the commands without installing them into your environment, use `pipx install kg-ssot` or
`uvx --from kg-ssot kg-validate`.

## Quickstart

Check your graphs against the current contract:

```bash
kg-validate graph.kg.yaml other.kg.json
```

```text
PASS graph.kg.yaml
FAIL other.kg.json
  MUST   form.range.node.impact ×1 · integrity.orphan-node ×1
· 2 files; 1 pass the MUST; 0 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

The exit code is 0 when every file passes the MUST, 1 when any file fails, and 2 on broken input. Two useful modes:

- `kg-validate --where` shows the node or edge of each occurrence and, for a MUST occurrence that has a canonical fix,
  the fix right below it;
- `kg-validate --format json` returns the structured verdict (code, path, line, message, and hint) in the versioned
  `kg-ssot.verdict/1` format.

Run the bundled conformance suite against the reference reader:

```bash
kg-conformance | tail -2
```

```text
latest: 438/438 (gates the rc)
optional: 10/24 (report only)
```

Only `latest/` sets the exit code. The `optional/` cases are reported and never change it.

## Commands

| Command | What it does |
|---|---|
| `kg-validate` | Checks `.kg.yaml` and `.kg.json` graphs against the current contract |
| `kg-conformance` | Runs the bundled conformance suite against the reference reader |
| `kg-gate` | Per-graph gate for CI: records a baseline (`--update`) and fails if anything gets worse |
| `kg-store` | A store on disk, in git, or versioned, that only writes what passes the contract |
| `kg-mcp` (and the `kg-ssot` alias) | Reference MCP server (stdio, or `--http` on loopback) with the tools `kg_validate`, `kg_write`, `kg_get`, `kg_list`, `kg_query`, `kg_terms`, `kg_history`, `kg_delete`, and `kg_schema_help` |
| `kg-query` | Queries and projects a corpus of graphs, with edges resolved to their labels |
| `kg-diff` | Diff by id between two graphs or between git revisions |
| `kg-vocab` | The domain vocabulary (the `x_term` profile): lists the terms and what is due, resolves a text to its term, and exports to SKOS-XL and Apache Ossie |
| `kg-criterion` | The pre-registered criterion: prints the `sha256` of a criterion version and checks each version against its text or file, and each citation of another graph |
| `kg-audit` | The audit package by question: one row per questionnaire item, with the answer, the verdict, the dated evidence, the gaps, and the owner, in CSV, XLSX, or JSON |
| `kg-prov-export` | Exports each node's provenance as `prov:Entity` and `prov:Derivation` in JSON-LD |

As a library, the modules live under `kg_ssot`: `kg_ssot.kg_validate`, `kg_ssot.kg_store`, `kg_ssot.kg_mcp`, and the
rest.

## MCP server

```bash
kg-mcp --root ./graphs --init
uvx kg-ssot --root ./graphs --init   # the same server, no install: kg-ssot is an alias for kg-mcp
```

The server speaks MCP over stdio. With `--http PORT`, it serves HTTP on loopback (`127.0.0.1`) by default, with no
TLS. To listen beyond loopback, you need `--allow-remote` plus a shared secret (`--secret-env`), and you still put a
proxy that handles TLS in front of it.

## Package or vendor

Use the package to run the reader as a library, a command, or an MCP server. For the gate in a repository's CI, the
recommended channel is still **vendoring by tag**: `kg_vendor.py` brings the release into your repository and verifies
the sha256 of every file. That way, the contract that judges your graph shows up in your diff. The
[adoption guide](https://github.com/marciocar/kg-ssot/blob/main/ADOPTING.md) covers both paths.

## Documentation

- [Manual](https://github.com/marciocar/kg-ssot/blob/main/docs/manual/README.md): the format, the contract, the tools,
  adoption, and troubleshooting
- [Adoption guide](https://github.com/marciocar/kg-ssot/blob/main/ADOPTING.md)
- [Conformance suite](https://github.com/marciocar/kg-ssot/blob/main/spec/conformance/README.md)
- [For AI agents (llms.txt)](https://github.com/marciocar/kg-ssot/blob/main/llms.txt)
- [Source and releases](https://github.com/marciocar/kg-ssot)

## License

Apache-2.0. See `LICENSE` and `NOTICE`.

Documentação em português: [README.pt-BR](https://github.com/marciocar/kg-ssot/blob/main/README.pt-BR.md).
