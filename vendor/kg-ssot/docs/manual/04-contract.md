# 4. The contract

**English** | [Português (Brasil)](pt-BR/04-contrato.md)

[← Format reference](03-format.md) · [Contents](README.md) · [Tools →](05-tools.md)

## Two levels: MUST and SHOULD

| Level | File | Effect |
|---|---|---|
| **MUST** | `spec/kg-contract-v4.schema.json` | Fails the file. The reader exits with rc 1 |
| **SHOULD** | `spec/kg-contract-v4.should.schema.json` | Warns only. The file stays valid |

Both are hand-written JSON Schema 2020-12. On top of them, the contract has the **YAML profile** rules (a single
document, duplicate keys, the `on` key) and the **integrity** rules (ids, edge ends, orphans), which JSON Schema
cannot see. So a JSON Schema validator alone is not a complete reader: the reference reader applies all three
layers, and the conformance suite checks all three in every reader.

The schema's `format: date` is an **assertion**: the date must exist on the calendar (`2026-02-30` fails). Many
validators treat `format` as an annotation by default, so the suite has cases for it.

## Codes

Every violation has a stable code, shaped by its layer:

| Layer | Shape | Examples |
|---|---|---|
| parse | `parse.<reason>` | `parse.yaml-error`, `parse.duplicate-key`, `parse.not-single-document` |
| form | `form.<kind>.<scope>.<field>` | `form.required.node.label`, `form.enum.node.status`, `form.unknown-key.node.prioridade` |
| integrity | `integrity.<rule>` | `integrity.orphan-node`, `integrity.dangling-to` |
| yaml | `yaml.<rule>` | `yaml.forbidden-key-on` (MUST), `yaml.unquoted-date` (SHOULD) |

`<kind>` is one of `required`, `enum`, `type`, `pattern`, `range`, `const` or `unknown-key`. `<scope>` is one of
`top`, `meta`, `node` or `edge`. For a nested field, the path uses dots: `form.required.node.provenance.locator`.
In `external_edges`, the scope is `top` and the field carries the list name
(`form.enum.top.external_edges.edge_type`). A date that is not on the calendar (`format: date`) fails as
`form.pattern.<scope>.<field>`.

The full list, with what each code catches, is in
[`spec/conformance/README.md`](../../spec/conformance/README.md#codes).

## What changed from v3 to v4

v4 is a **major** version: what used to warn now fails.

| Code | v3 | v4 |
|---|---|---|
| `form.required.node.provenance` (a `confirmed` or PROD node without `provenance`, except `unverifiable`) | SHOULD | **MUST** |
| `form.unknown-key.<scope>.<key>` (a key outside the grammar, without `x_`) | SHOULD | **MUST** |
| `form.pattern.<scope>.key` (a key name that is not a slug, without `x_`) | SHOULD | **MUST** |
| `form.pattern.node.provenance.source` (a placeholder `source`) | — | **MUST** |
| `form.pattern.node.provenance.method` (not in the `<class>: <detail>` form) | — | SHOULD (MUST in v5) |

The minor releases of the 4.x line added features without changing the MUST verdict of a well-written graph, with one
recorded exception: 4.11.0, 4.12.0 and 4.13.0 started to fail rare YAML constructs (the strict profile). They
were minor because none of the real graphs measured in four adopter repositories changed its verdict. Even so, they
count as new MUST rules for the stability criterion, and each one reset the 30-day clock. Since 4.11.0, the contract
has its own version label (v4.4 in 4.11.0, v4.5 in 4.12.0, v4.6 in 4.13.0, v4.7 in 4.14.0, v4.8 in 4.15.0, v4.9 in 4.15.1
and 4.16.0, v4.10 from 4.16.1 to 4.18.0, v4.11 in 4.19.0 and 4.20.0, v4.12 in 4.21.0, v4.13 since 4.22.0), which is not the release number.

| Release | What it added |
|---|---|
| 4.1 | Four SHOULD warnings: missing `verified_against` on a stamped claim, `testemunho` (testimony) in PROD, verification before the fact, a decision with no origin |
| 4.2 | `provenance.locality`, and the gate's SHOULD debt counted per occurrence, as an option |
| 4.3 | `external_edges`, with the external end verified against the corpus |
| 4.4 | The provenance exporter to PROV-O (`kg_prov_export.py`) |
| 4.5 | The structured verdict `kg-ssot.verdict/1` (`kg_validate.py --format json`) |
| 4.6 | The store that only writes what the contract approves (`kg_store.py`) |
| 4.7 | The reference MCP server (`kg_mcp.py`) and the reader's limits on nesting and aliases |
| 4.8 | `.kg.json` as a contract format, read under the JSON profile; the vendor with its own `.gitattributes` (4.8.1) and the verdict with the line of each occurrence (4.8.2) |
| 4.9 | The PyPI package (`kg-ssot`) and the npm package; in 4.9.1, the store on Windows |
| 4.10 | The production-ready MCP server: the behind-proxy profile, both protocol eras, the external gate by command and the OCI image |
| 4.11 | Contract v4.4: the `integrity.refutes-unreconciled` warning and the strict YAML profile on three rare constructs (new MUST) |
| 4.12 | Contract v4.5: `verified_scope`, `locality: privado`, external `REFUTES` edges counted with the corpus, and a tab at the start of a quoted continuation line (new MUST) |
| 4.13 | Contract v4.6: a quoted continuation indented more than its owning collection (new MUST) and `\r` as a line break in the JS reader; in 4.13.1, the contract identity flags a version that only the reader changes, and the migrator reads the gate's corpus |
| 4.14 | Contract v4.7: the external end can be a `.kg.json`; the store writes a set of graphs at once (`write_many`) |
| 4.15 | Contract v4.8: the verification cadence (`reverify_every`, `reverify_on`), retention (`retain_for`), `owner` as a role and the due report (`kg_validate.py --due`), outside the verdict; in 4.15.1, contract v4.9 stops warning about a cadence without `verified_at`, which is the initial state of a collection rule |
| 4.16 | Contract v4.9, unchanged. The frictionless gate: the baseline becomes a folder with one record per graph, and a contract identity change with no verdict change passes with a notice; in 4.16.1, contract v4.10 aligns the two readers on three points of the YAML profile, with no reference verdict changed |
| 4.17 | Contract v4.10, unchanged. Query and projection (`kg_query.py`, and the `kg_query` tool in the MCP server) and the diff by id between revisions (`kg_diff.py`); in 4.17.1, vendored code and fixtures left out of the corpus by default, and renamed fields detected by `kg_diff`; in 4.17.2, the tool annotations in the MCP server |
| 4.18 | Contract v4.10, unchanged. English becomes the source language of the docs, with the full pt-BR translation beside it; the tools print human output in English by default, and in pt-BR with `KG_SSOT_LANG=pt-BR` or a `pt_BR` locale |
| 4.19 | Contract v4.11: `meta.title` and `meta.slug` become known keys, and the SHOULD gets the canonical `x_` profiles (`x_term` for the domain vocabulary, `x_mirror`, `x_doc_cycle`, `x_questionnaire`, `x_severity`, and `x_confidence` and `x_provisional` on the edge); the vocabulary tool (`kg_vocab.py`, with exports to SKOS-XL and Apache Ossie, and the `kg_terms` tool in the MCP server) and `kg_migrate.py keys`, which renames a foreign key to `x_` |
| 4.20 | Contract v4.11, unchanged. The store keeps the verdict of each judged graph and stops judging again what did not change; the `.kg-ssot-version` stamp becomes the public vendor rule in every tool; `kg_diff.py` names the working tree (`WORKTREE`) |
| 4.21 | Contract v4.12: the pre-registered criterion, with the SHOULD profiles `x_criterion` and `x_measured_under`, five coherence warnings in both readers, and `kg_criterion.py`, which checks the `sha256` against the text or the file and follows a citation of another graph; `kg_migrate.py nest`, which moves an adopter's own `x_` keys into a canonical profile |
| 4.22 | Contract v4.13: `x_questionnaire.role` (`item`, `evidence_request`, or `evidence_requirement`) in the SHOULD; the audit package by question, `kg_audit.py`, in CSV, XLSX, or JSON |

## Versions and tags

A release is a `kg-ssot-vX.Y.Z` tag (up to 4.3.0, the name was `contract-vX.Y.Z`; the old tags still exist).
Going by the release history:

| Part | When it goes up |
|---|---|
| **X**, major | A MUST verdict changes: something that passed now fails |
| **Y**, minor | The kit gains a SHOULD warning, an optional field, or a new tool or format, and no MUST verdict of a well-written graph changes |
| **Z**, patch | A fix or an improvement to the kit, the guide or the cases, with the same contract |

The gate stores the sha256 of both schemas as the contract identity. A tag that changes the bytes of the schemas,
even only in the description text (4.7.2) or in `$id` (4.7.3), changes the identity. Since 4.16.0, the identity is
composite: the gate reports the change on a `· identity` line, but the comparison, made with the new contract,
decides the rc. A change that changes no verdict passes with rc 0, and `--update` records the new identity when
you choose to. A new rule that makes a graph worse fails through the comparison. `--strict-identity` restores rc 1 on
every change, as before 4.16.0. When it runs from a vendor, the gate checks the sha256 of both schemas against the
stamp and fails a hand-edited schema. A rule that only the reader sees (the YAML profile, the line break) also goes
into the description of the MUST schema, as a line that starts with "No v4.6 ..." (the schema descriptions are in
Portuguese): since 4.13.1, release hygiene requires that line for the
version the reader declares, so every contract version moves the identity.

A new SHOULD warning can raise the debt the gate measures. That is intentional: a contract's ramp is to warn in one
version and fail in the next, so you see the debt before it becomes an error.

The surface that travels in each tag is listed in [`spec/release.json`](../../spec/release.json). You do not
customize the contract in your repository: the vendor fails a local edit, and a needed change goes back to the
product as an issue in the public repository.

## The older contracts

The product repository keeps v1, v2 and v3 in `spec/` as history; the release ships only v4, the current one, which
is what the reader uses without `--schema`.
