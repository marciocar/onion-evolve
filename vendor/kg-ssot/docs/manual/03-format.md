# 3. Format reference

**English** | [Português (Brasil)](pt-BR/03-formato.md)

[← Concepts](02-concepts.md) · [Contents](README.md) · [The contract →](04-contract.md)

This page comes from [`spec/kg-contract-v4.schema.json`](../../spec/kg-contract-v4.schema.json) (MUST) and
[`spec/kg-contract-v4.should.schema.json`](../../spec/kg-contract-v4.should.schema.json) (SHOULD). If this page
and the schema disagree, the schema wins.

Conventions: **req.** = required; *date* = a `YYYY-MM-DD` string that exists on the calendar.

## File

- YAML, **a single document**, with a map at the root.
- YAML 1.2 booleans: only `true` and `false` (also as `True`, `TRUE`, `False`, `FALSE`). `yes`, `no`, `on`, and
  `off` are strings.
- Keys are compared in their JSON form: `1` and `"1"` collide (`parse.duplicate-key`).
- `.nan` and `.inf` fail anywhere, because JSON cannot represent them.
- A quoted string over several lines: indent each continuation line deeper than the map or list that holds it.
- Tabs are allowed only inside quotes (but not in the leading whitespace of a continuation line), inside a literal
  block (`|` or `>`), and inside a comment. A tab used as a space (after `:`, at the end of a line, between the date
  and the time) or inside an unquoted string fails (`parse.yaml-error`). Use a space.
- The bare `!` tag (also `!<!>`) fails, and an explicit `!!timestamp` accepts only date-shaped text (`YYYY-M-D`,
  with an optional `H:MM:SS` time, a fraction with at least one digit, and a `Z` or `±H[:MM]` zone up to ±29). The
  shape is checked; the calendar is not. Without a tag, write the date in quotes.
- The JSON profile also applies to `.kg.yaml`, as a warning: an integer outside ±(2^53−1) (`yaml.unsafe-integer`),
  a lone surrogate (`yaml.lone-surrogate`), and more than 128 nested collections (`yaml.depth-over-128`).

### The same model in `.kg.json`

A graph can also come as JSON, in a `.kg.json` file (the extension is case-sensitive), with the same fields and the
same rules. A JSON parser reads it under the contract's JSON profile, and every point of the profile fails:

- RFC 8259 syntax: no comments, trailing commas, single quotes, `NaN`, or `Infinity`. Whitespace is only space, tab,
  LF, and CR, and a leading BOM is accepted and dropped;
- I-JSON (RFC 7493): no lone surrogate, in a key or a value, and every integer-valued number within ±(2^53−1),
  whether written as an integer or as a float (`9007199254740993` and `1e20` fail);
- at most 128 nested collections, counting the root;
- unique keys in each object, compared after escapes (`"label"` and `"\u006cabel"` collide).

Invalid syntax reports `parse.yaml-error`, because the code vocabulary has no JSON-specific code. When the syntax
fails, it decides before any duplicate key. The gate (`kg_gate.py`) and `external_edges` work with `.kg.yaml`
only.

## Top level

| Key | Type | Rule |
|---|---|---|
| `meta` | map | req. |
| `nodes` | list of nodes | req. An empty list is valid but warns (`form.range.top.nodes`) |
| `edges` | list of edges | req. Can be empty |
| `external_edges` | list of external edges | optional (since 4.3) |
| `x_*` | any | free extension |

In the top level, in `meta`, in a node, in an edge, and in an external edge, any other key without `x_` fails
(`form.unknown-key.<scope>.<key>`, or `form.pattern.<scope>.key` when the name is not a slug).

## `meta`

| Key | Type | Rule |
|---|---|---|
| `schema_version` | string | req. Exactly `"1"` |
| `id` | string | req. Not empty |
| `baseline` | *date* | when the graph was first measured |
| `date` | *date* | |
| `review_after` | *date* | when the graph should be reviewed |
| `layer` | `audit` · `domain` | |
| `note` · `purpose` | string | the graph's narrative |
| `x_*` | any | |

## Node

| Key | Type | Rule |
|---|---|---|
| `id` | string | req. `^[A-Za-z][A-Za-z0-9_]*$`, unique in the file |
| `node_type` | enum | req. `entity` `claim` `decision` `question` `evidence` `artifact` `state` `event` `rule` `invariant` `policy` |
| `plane` | enum | req. `DEV` · `PROD` |
| `status` | enum | req. `open` `confirmed` `drifted` `unverifiable` `refuted` `superseded` `done` |
| `impact` | integer | req. 1 to 5 |
| `confidence` | number | req. 0 to 1 |
| `label` | string | req. Not empty. SHOULD: up to 280 characters |
| `provenance` | map | **req. when `status: confirmed` or `plane: PROD`, except with `status: unverifiable`** |
| `trace` | string | where the claim appears (file, path) |
| `verified_at` | *date* | SHOULD on a PROD node |
| `verified_against` | string | SHOULD on a `claim` with `verified_at` |
| `verified_scope` | enum | optional, since v4.5: the reach of `verified_at`. `fato` (fact: what the node states was verified), `mecanismo` (mechanism: only the mechanism, such as code or configuration, was verified; the fact depends on another environment), or `nenhum` (none: verified against the repository on that date, and nothing there supports or refutes the fact). A value outside the enum warns; without `verified_at`, it warns |
| `reverify_every` | duration | optional, since v4.8: how often the verification must be redone, as a date-only ISO 8601 duration (`P3M`, `P1Y`, `P2W`, `P1Y6M`). Off that shape, or zero like `P0D`, it warns. Since v4.9, it no longer warns without `verified_at`: that is a rule that has not had its first verification yet, and `--due` lists it as unstamped. Being due never changes the verdict: `kg_validate.py --due` lists it |
| `reverify_on` | string | optional, since v4.8: the event trigger ("on every configuration change", "on each hire") |
| `retain_for` | duration | optional, since v4.8: how long the evidence must be kept, in the same duration format |
| `valid_from` | partial date | `YYYY`, `YYYY-MM`, or `YYYY-MM-DD` |
| `source_tier` | integer | 1 to 10 |
| `source_kind` | string | |
| `owner` | string | the role that answers for the node (`cto`, `engineering`), not a person's name: people change, the role stays |
| `drive_kind` · `evidence_class` | string | |
| `sealed_by` · `sealed_at` | string | who sealed the decision, and when |
| `narrative` | string | the story behind the `label` |
| `layer` | `audit` · `domain` | |
| `x_*` | any | |

### `provenance`

| Key | Type | Rule |
|---|---|---|
| `source` | string | req. Not empty and not a placeholder (`unknown`, `n/a`, `tbd`, `?`...) |
| `locator` | string | req. Not empty |
| `method` | string | req. Not empty. SHOULD: `<class>: <detail>`, with the class one of `medição` (measurement), `leitura` (reading), `juízes` (judges), `derivado` (derived), or `testemunho` (testimony) |
| `locality` | enum | optional. `repo` `web` `host` `pessoa` (person) `privado` (private); a value outside the enum warns. It describes where the copy you read lives, not how the document is classified |
| `x_*` | any | any other key warns; it does not fail |

`provenance: null` fails. Either the whole object is there, or it is absent.

## Edge

| Key | Type | Rule |
|---|---|---|
| `from` | id | req. Must exist in the file |
| `to` | id | req. Must exist in the file |
| `edge_type` | enum | req. `SUPPORTS` `REFUTES` `SUPERSEDES` `CAUSES` `DEPENDS_ON` `TRACES_TO` `CONSTRAINS` `HAS_STATE` `TRANSITIONS` `EMITS` `READS` `WRITES` |
| `label` | string | |
| `trigger` | id | the event of a `TRANSITIONS` edge. Must exist in the file |
| `on` | — | **forbidden** (`yaml.forbidden-key-on`): use `trigger` |
| `x_*` | any | |

## External edge

| Key | Type | Rule |
|---|---|---|
| `from` | id or reference | an id in this file, or absent (the whole graph), or the external end |
| `to` | id or reference | req. Exactly one of the two ends is external |
| `edge_type` | enum | req. `SUPERSEDES` `CONSTRAINS` `SUPPORTS` `REFUTES` `TRACES_TO` `DEPENDS_ON` |
| `label` | string | |
| `x_*` | any | |

An external reference is `<path>.kg.yaml#<id>`, or `<path>.kg.json#<id>` since v4.7, with the path relative to the
repository root and written with `/`. Each segment starts with a letter, a digit, or `_`. An absolute path, `..`,
`\`, and `:` fail.

## Integrity (outside the schema)

The schema cannot express these rules, and every reader must apply them:

| Rule | Level | Code |
|---|---|---|
| ids are unique in the file | MUST | `integrity.duplicate-id` |
| `from`, `to`, and `trigger` point to an existing node | MUST | `integrity.dangling-from` · `-to` · `-trigger` |
| no node without an edge (degree 0) | MUST | `integrity.orphan-node` |
| the local end of an external edge exists | MUST | `integrity.dangling-external-local` |
| the external end exists (only with the corpus) | MUST | `integrity.dangling-external` |
| a PROD node backed only by testimony | SHOULD | `integrity.testimony-in-prod` |
| `verified_at` earlier than `valid_from` | SHOULD | `integrity.verified-before-fact` |
| a live `decision` with no `trace`, no `provenance`, and no outgoing `TRACES_TO` | SHOULD | `integrity.untraced-decision` |
| a node that receives `REFUTES` and stays live (neither `superseded` nor `refuted`; a `done` `question` is already answered) | SHOULD (MUST later) | `integrity.refutes-unreconciled` |

An external edge counts as a link: a node linked only by one is not an orphan.
