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

`<kind>` is one of `required`, `enum`, `type`, `pattern`, `range`, `const`, `unknown-key`, `exclusive` (two fields that exclude each other, v4.12), `misplaced` (a key out of place, v4.20) or `deprecated` (an accepted form on its way out, v4.21). `<scope>` is one of
`top`, `meta`, `node` or `edge`. For a nested field, the path uses dots: `form.required.node.provenance.locator`.
In `external_edges`, the scope is `top` and the field carries the list name
(`form.enum.top.external_edges.edge_type`). A date that is not on the calendar (`format: date`) fails as
`form.pattern.<scope>.<field>`.

The full list, with what each code catches, is in
[`spec/conformance/README.md`](../../spec/conformance/README.md#codes).

## Where in the source (v4.17)

A `locator` was free text: "lines 10 to 12", "the License section". People read it; a tool could not check it. Since
v4.17, a node can say how to read it, and keep a hash of what it read. Both are optional and only warn: nothing that
passed fails.

```yaml
provenance:
  source: "https://github.com/acme/brain/blob/9f2c1e0/docs/payments.md"
  locator: "line=41,44"
  method: "reading: the retry section"
  scheme: text
  sha256: "3f1d…"   # 64 lowercase hex digits: the SHA-256 of the file at that commit
```

| `scheme` | Standard | Locator | Counts from |
|---|---|---|---|
| `json-pointer` | RFC 6901 | `/a/b`, or `#/a/b` as a fragment (percent-encoded, no raw space) | — |
| `text` | RFC 5147 | `line=10`, `line=10,20`, `char=5,9`, with an optional `;length=N` | 0, positions between lines or characters; `char` counts code points, and each line ending (CRLF, LF or CR) is one character |
| `csv` | RFC 7111 | `row=4;6-*`, `col=2`, `cell=4,2-6,3`: one kind of selection each, `*` for the last | 1 |
| `pdf` | RFC 8118 and ISO 32000-2 | `page=3`, among other parameters | 1, the physical page |
| `media` | W3C Media Fragments | `t=10,20`, `t=npt:1:02:03` | seconds; the end is excluded |
| `quote` | W3C TextQuoteSelector | the exact text | — |
| `html` | an HTML fragment | `#id` | — |
| `kg-node` | this contract | `#ID` or `ID`, a node of the graph named in `source` | — |

The `conformsTo` URIs of the W3C Web Annotation model count as aliases, including the RFC 3778 URI that its table still
uses for PDF. The hash goes in its own field: the `md5=` of RFC 5147 is not used, because MD5 does not resist
collisions (RFC 6151). Warnings: `form.enum.node.provenance.scheme`, `form.pattern.node.provenance.locator` (the locator
does not fit its scheme) and `form.pattern.node.provenance.sha256`. `kg_trace check` then opens the source and checks
the locator and the hash (chapter 5). What the standards leave open is a decision of this contract, written as such: a
JSON Pointer that does not resolve in a JSON source fails `kg_trace`, `char` counts code points in every reader, rows
and columns of a CSV count from 1 and are written without a leading zero (RFC 7111 allows `0` and `01`), and the
media interval excludes its end. The form does not check what only the
source can say, such as a start after the end or a line that does not exist: that is the job of `kg_trace`.

## The hash of a cited node (v4.18)

A bridge to another graph (`scheme: kg-node`) points to one node inside a file. The `sha256` of the file breaks as soon
as any node of that file changes, even one the bridge does not cite. Since v4.18, `provenance.node_sha256` hashes only
the cited node: the SHA-256 of its canonical form by RFC 8785 (JCS, the JSON Canonicalization Scheme), computed over the
model the reader extracts from the graph, with keys in UTF-16 order and numbers and strings in ECMAScript form.

```yaml
provenance:
  source: "https://github.com/acme/core/blob/9f2c1e0/docs/graph/seals.kg.yaml#D_RETRY_POLICY"
  locator: "#D_RETRY_POLICY"
  method: "testimony: the seal of the core"
  scheme: kg-node
  node_sha256: "d4d7…"   # kg_trace.py digest docs/graph/seals.kg.yaml#D_RETRY_POLICY
```

It goes only with `scheme: kg-node` and only warns: `form.pattern.node.provenance.node_sha256` out of form,
`form.required.node.provenance.scheme` without a scheme, `form.const.node.provenance.scheme` with another one.
`kg_trace check` compares it with the cited node (chapter 5).

## What changed from v3 to v4

v4 is a **major** version: what used to warn now fails.

| Code | v3 | v4 |
|---|---|---|
| `form.required.node.provenance` (a `confirmed` or PROD node without `provenance`, except `unverifiable`) | SHOULD | **MUST** |
| `form.unknown-key.<scope>.<key>` (a key outside the grammar, without `x_`) | SHOULD | **MUST** |
| `form.pattern.<scope>.key` (a key name that is not a slug, without `x_`) | SHOULD | **MUST** |
| `form.pattern.node.provenance.source` (a placeholder `source`) | — | **MUST** |
| `form.pattern.node.provenance.source` (a `private-cite:` marker out of form, v4.22) | — | SHOULD |
| `form.pattern.node.provenance.method` (not in the `<class>: <detail>` form) | — | SHOULD (MUST in v5) |

Since v4.21, two SHOULD warnings prepare v5. `form.deprecated.node.provenance.method`: the Portuguese class of `provenance.method` (`medição`, `leitura`, `juízes`, `derivado`, `testemunho`) still passes, and the reader asks for the English one. In the JSON Schema it is a `not` with the alias form and the `deprecated` keyword of the 2020-12 meta-data vocabulary, which only annotates; a value that already fails the form keeps only `form.pattern.node.provenance.method`. The alias leaves in v5, not before 2027-03-31, and only when the measurement on the first adopter and on its curation repository reaches zero. And `form.required.node.provenance` at the SHOULD level (provenance always): an `evidence` node without `provenance` in any status except `unverifiable`, and a `decision` `done` without it. It is the code of the MUST rule above, on purpose: the field and the fix are the same, and the code will not change when v5 promotes the rule. The MUST does not change, and on a node where the MUST already flags the code, the reader does not repeat it as a warning; on another node of the same document it still warns, because the deduplication is per occurrence. Demoting a node without giving it a source trades the MUST for a SHOULD on the same node: a `confirmed` `evidence` that goes to `open`, or a `decision` `done` that leaves PROD, still lacks `provenance`, and the gate reports `form.required.node.provenance` as new SHOULD debt and asks for `--accept-regression`. The path of the hints passes clean: `unverifiable` for an `evidence` with no recoverable source, and, for a decision, its source as who decided, with method `testimony`.

Since v4.22, a SHOULD rule for citing a node in a private repository. A public graph that cites a node of a private repository leaked the name and path of that repository, and sometimes a guessable content hash. The citation becomes the marker `private-cite:<id>`: `private-cite:` followed by a random id of at least 128 bits, one per citation, in base64url (`A-Z`, `a-z`, `0-9`, `-`, `_`) of 22 to 43 characters, such as the output of `kg_trace.py private-cite-id` (`secrets.token_urlsafe(16)`, 22 characters). The resolution of the id to repository, commit, and path lives in a table in the private repository of whoever owns the citation, never in the graph. `provenance.node_sha256` is left out (there is no salted opt-in in this version), and so is the real locator: since the MUST asks for a `locator` whenever there is a `provenance`, the public graph writes the marker there too. The marker is valid in `provenance.source`, `provenance.locator`, `trace`, `verified_against`, and in the detail of `provenance.method`; in prose (`narrative`, `label`), only the repository name is swapped for the marker, and the rest stays byte for byte. The reader judges the form only in `provenance.source`: a value that starts with `private-cite:` (case-sensitive, with no leading space) and does not have the form warns as `form.pattern.node.provenance.source`, the code of the placeholder rule, with a hint of its own; in the JSON Schema it is an `if` on the prefix with a `then` on the form. `kg_trace.py` never reads the marker in form, never counts it as missing, and never goes to the network for it; a value out of form is checked as an ordinary source and counts as missing. The form does not prove randomness or uniqueness; the id comes from `private-cite-id`. Knowing that a repository is private is not the graph's business, so the check of a private repository cited without the marker is a tool option, `kg_gate.py --private-repos FILE` (chapter 5), outside the verdict. Nothing that passed fails.

A known limit: a literal U+2028 inside a YAML string is a line break for the parser of the Python reference and ordinary text for the JavaScript reader. Right after `<class>: `, the reference warns `form.pattern.node.provenance.method`, and the JavaScript reader does not (with an alias, it warns `form.deprecated.node.provenance.method`). Both keep the file valid, and they already differed before v4.21. Written as the escape `\u2028`, both read the same value.

The minor releases of the 4.x line added features without changing the MUST verdict of a well-written graph, with one
recorded exception: 4.11.0, 4.12.0 and 4.13.0 started to fail rare YAML constructs (the strict profile). They
were minor because none of the real graphs measured in four adopter repositories changed its verdict. Even so, they
count as new MUST rules for the stability criterion, and each one reset the 30-day clock. Since 4.11.0, the contract
has its own version label (v4.4 in 4.11.0, v4.5 in 4.12.0, v4.6 in 4.13.0, v4.7 in 4.14.0, v4.8 in 4.15.0, v4.9 in 4.15.1
and 4.16.0, v4.10 from 4.16.1 to 4.18.0, v4.11 in 4.19.0 and 4.20.0, v4.12 in 4.21.0, v4.13 in 4.22.0, v4.14 from 4.23.0 to 4.26.0, v4.15 from 4.27.0 to 4.31.1, v4.16 from 4.32.0 to 4.36.0, v4.17 in 4.37.0, v4.18 from 4.38.0 to 4.45.0, v4.19 from 4.46.0 to 4.48.0, v4.20 and v4.21 from 4.49.0 to 4.50.0, v4.22 since 4.51.0), which is not the release number.

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
| 4.23 | Contract v4.14: `x_term.scheme` and the warning `integrity.term-notation-duplicate`, so a short code carries a readable name in its own vocabulary; `kg_vocab.py` resolves a code (`scheme:code`) and gains `lint`, with a ratchet, for codes in prose; `kg_query.py --text` without accents, through the vocabulary, and with a hint on zero |
| 4.24 | `kg_vendor.py update --ref` for the bench before a tag; `check` and `kg_gate.py` refuse a bench vendor without `--allow-unreleased` |
| 4.25 | `kg_trace.py`, the trace that does not resolve: each node's `trace:` anchor against the files of the repository |
| 4.26 | `kg_query --semantic`, the optional search by similarity (the `vector` extra, `kg_vector.py`), fused with `--text` by RRF |
| 4.27 | Contract v4.15: an external end can start with a dot folder (`.github/`, `.config/`); `kg_trace` exits 3 on an empty corpus |
| 4.28 | Contract v4.15, unchanged. `kg_prov_export.py --edges`: the edges go to PROV-O as qualified relations |
| 4.29 | Contract v4.15, unchanged. The `rdf` extra reads the PROV export, and `kg_prov_export.py --full` exports the whole document; in 4.29.1, a malformed edge end goes as a literal |
| 4.30 | Contract v4.15, unchanged. The agent skill (`skills/kg-ssot/`, Agent Skills format) and the Claude Code plugin marketplace |
| 4.31 | Contract v4.15, unchanged. The documentation site and the demo, published only in the public repository (`mirror_only`); in 4.31.1, the site renders code blocks |
| 4.51 | Contract v4.22, SHOULD only: the `private-cite:<id>` marker for a node in a private repository, whose `provenance.source` out of form warns as `form.pattern.node.provenance.source`; `kg_trace.py` counts it and never reads it, `kg_trace.py private-cite-id` makes a new one, and `kg_gate.py --private-repos FILE` fails a private repository cited without the marker |
| 4.49 | Contracts v4.20 and v4.21, SHOULD only: `x_classification` in `meta` (`form.misplaced.node.x_classification` on a node); the Portuguese class of `provenance.method` warns as `form.deprecated.node.provenance.method`, and an `evidence` that is not `unverifiable` or a `decision` `done` without `provenance` warns as `form.required.node.provenance` |
| 4.46 | Contract v4.19, SHOULD only: `integrity.bare-decision` (a decision `done` with no `narrative` and no `SUPPORTS` reaching it) and `integrity.superseded-without-successor` (a `superseded` node that no `SUPERSEDES` reaches); `kg_trace projection` lists `superseded_cited`, the page that cites a node its graphs replaced or overturned |
| 4.40 | Contract v4.18, unchanged. `kg_query --revisit` gains `pin-changed`, the decision whose pinned version changed (`kg-ssot.revisit/2`); `kg_trace.py digest` takes a batch where a missing or non-UTF-8 file is a result of its own reference (`kg-ssot.digest/2`) |
| 4.38 | Contract v4.18, SHOULD only: `provenance.node_sha256`, the canonical hash of the cited node (RFC 8785); `kg_query --revisit` and `--decision` read a support of another repository at its pinned commit with `--with`, and list the decisions whose support changed upstream; `kg_trace.py digest` |
| 4.37 | Contract v4.17, SHOULD only: `provenance.scheme` (how to read the locator: `json-pointer`, `text`, `csv`, `pdf`, `media`, `quote`, `html`, `kg-node`) and `provenance.sha256` (the hash of what was read, in its own field); `kg_trace check` reads the source by its scheme and hash, also at a pinned commit of another repository with `--with` |
| 4.36 | Contract v4.16, unchanged. `kg_query --sort attention` (the radar's formula), `--decision` (the history of a decision) and `--revisit` (the live decisions to revisit, with the reason) |
| 4.35 | Contract v4.16, unchanged. Python 3.12 or later. `kg_query --chain --with` follows a chain into another repository at the cited commit; `kg_trace.py projection` checks Markdown pages that declare `projection_of`; `kg_trace check` follows a JSON Pointer `provenance.locator` inside the JSON file |
| 4.34 | Contract v4.16, unchanged. `kg_query --chain` follows `provenance.source` first, and an origin with no `provenance.source` is marked and makes the chain `weak` |
| 4.33 | Contract v4.16, unchanged. `kg_query --chain`: the transmission chain from a node to its origin, with the weakest link and the strength of the origin on separate axes, and a strict and a lenient grade |
| 4.32 | Contract v4.16: the class of `provenance.method` has a canonical English form (`measurement`, `reading`, `judges`, `derived`, `testimony`), and the Portuguese words stay accepted as aliases |

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
