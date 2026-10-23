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
| `title` | string | since v4.11: the human title of the graph. Not empty |
| `slug` | string | since v4.11: the short name. Not empty; SHOULD: lowercase words joined by hyphens (`my-graph`) |
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

## Canonical `x_` profiles (v4.11 and v4.12)

An `x_` key stays free in the MUST: it never fails. Some `x_` keys repeat across adopters with the same meaning, and
since v4.11 the SHOULD gives each one a shape. The profile is judged only when the key is present, and only warns. A
value outside the profile warns with the path inside it (`form.enum.node.x_term.labels.kind`), and an item of a list
inside the node carries the path too (`form.type.node.x_term.labels.item`). Inside a profile object, another `x_` key
is free, and any other key warns. Enum values are codes, in English, whatever the output language.

| Key | Where | What it is |
|---|---|---|
| `x_term` | node | a term of a domain vocabulary, with its synonyms and the source of each one |
| `x_mirror` | node | a copy of a record kept in another system (a ticket, a task, a card) |
| `x_doc_cycle` | node | the life cycle of an external document the node depends on (a rule, a policy, a contract) |
| `x_questionnaire` | node | the link between the node and the questions of an external questionnaire |
| `x_severity` | node | `critical` · `high` · `medium` · `low` · `info` |
| `x_criterion` | node | one version of a pre-registered criterion (v4.12) |
| `x_measured_under` | node | the criterion versions a result was measured under (v4.12) |
| `x_confidence` | edge | how sure the link is, from 0 to 1 |
| `x_provisional` | edge | `true` when the link still waits for a check |

### `x_term`

The term is a node (an `entity`) with `x_term`. The names follow SKOS: `pref` is the preferred label, and each synonym
is `alt` (an alternative label) or `hidden` (a form you search for but do not show, like a typo or an old column
name). What KG-SSOT adds is the verification per synonym: the source, the version of the document, the date it was
verified, and when to verify it again.

| Key | Type | Rule |
|---|---|---|
| `pref` | string | req. The preferred term |
| `lang` | string | a BCP 47 tag (`pt-BR`, `en`) |
| `definition` | string | |
| `notation` | string | a code that identifies the term (`GTIN`, a catalog number) |
| `labels` | list | the synonyms, each an object with the keys below |

| Key of a synonym | Type | Rule |
|---|---|---|
| `literal` | string | req. The synonym as written |
| `kind` | enum | req. `alt` · `hidden` |
| `source` | string | req. Where the synonym comes from: a URL, a document, a path |
| `locator` | string | where in the source |
| `version` | string | the version of the document (or its hash, when the document has no version) |
| `verified_at` | *date* | when the synonym was verified against the source |
| `reverify_every` | duration | the cadence; it needs `verified_at`, and `--due` lists the synonym when it is due |
| `scope` | map | `level`: `domain` (valid in the whole domain) or `case` (valid in one case only, named in `case`); `jurisdiction`, optional (`BR`, `BR-SP`) |
| `retired` | boolean | `true` for the old name: a retired synonym still resolves, marked as retired. `kg_vocab.py` reads a value that is not a boolean as retired, and so does a `status` other than `current` |
| `lang` | string | when it differs from the term's |

A retired term is the node with `status: superseded` and a `SUPERSEDES` edge from the term that replaces it.
`kg_vocab.py` lists the terms, resolves a text to its term, and exports to SKOS-XL and Apache Ossie (chapter 5).

```yaml
  - id: T_EAN
    node_type: entity
    plane: DEV
    status: open
    impact: 3
    confidence: 0.9
    label: "EAN code: the 13-digit code that identifies the country, the maker and the product."
    x_term:
      pref: "Código EAN"
      lang: pt-BR
      labels:
        - literal: "GTIN"
          kind: alt
          source: "https://dados.anvisa.gov.br/dados/TA_PRECO_MEDICAMENTO%20-%20Dicionario%20de%20Dados.pdf"
          locator: "items 9, 10 and 11"
          version: "sha256:44e8af589f6a0860"
          verified_at: "2026-10-22"
          reverify_every: P6M
          scope: {level: domain, jurisdiction: BR}
        - literal: "CO_EAN"
          kind: hidden
          source: "https://dados.anvisa.gov.br/dados/TA_PRECO_MEDICAMENTO%20-%20Dicionario%20de%20Dados.pdf"
          locator: "De/Para table: CO_EAN (previous) to EAN 1 (current)"
          retired: true
```

The whole example, from the open data dictionary of the Brazilian drug price regulator, is in
[`spec/vocab-examples/cmed-dictionary.kg.yaml`](../../spec/vocab-examples/cmed-dictionary.kg.yaml).

### `x_mirror`, `x_doc_cycle` and `x_questionnaire`

| Profile | Required | Optional |
|---|---|---|
| `x_mirror` | `system`, `ref`, `state` (the status as copied), `synced_at` (*date*) | `url`, `resync_every` (duration) |
| `x_doc_cycle` | `issuer`, `state`: `draft` `enacted` (published, in force from a future `effective_from`) `in_force` `suspended` `revoked` `expired` `superseded` | `ref`, `version`, `effective_from`, `effective_to`, `updated_at`, `checked_at` (*dates*), `recheck_every` (duration, needs `checked_at`) |
| `x_questionnaire` | `name`, `questions` (a list that is not empty) | `answer_draft`, `verdict`: `meets` `partial` `does_not_meet` `not_applicable` `unknown`, `answered_at` (*date*), `role`: `item` `evidence_request` `evidence_requirement` (v4.13) |

A mirror goes stale without warning: `synced_at` plus `resync_every` puts it in the due report, and so does
`checked_at` plus `recheck_every` for a document.

`x_questionnaire.role` tells a questionnaire item from the evidence around it. `item`, the default, is the question
node or the answer to it; `evidence_request` is a request to a person for evidence, and `evidence_requirement` says what
evidence an item requires. The `questions` of both are the items they serve. Without the field, only an id prefix
tells them apart, and a prefix is one adopter's convention, not part of the contract. The audit package
(`kg_audit.py`, chapter 5) reads it.

### `x_criterion` and `x_measured_under` (v4.12)

A criterion fixed before the data is a pre-registration, as in
[OSF Preregistration](https://www.cos.io/initiatives/prereg) and in the versioned amendments of a clinical trial
registry. Changing it after seeing the data is an amendment with a date and a reason, never a rewrite. Each version is
a node, and the result cites the node of the version it was measured under, with that version's `sha256`. An old
result stays tied to the old version, so the old verdict never changes in silence.

| Profile | Required | Optional |
|---|---|---|
| `x_criterion` | `id` (stable across versions), `version` (text or integer), `registered_at` (a date, or an RFC 3339 date-time with a time zone), `sha256` (64 lowercase hex), and either `ref` or `text` | `amends` (the id of the node of the previous version; needs `reason`), `reason`, `round` (text: the round that motivated the amendment) |
| `x_measured_under` | `measured_at` (a date or a date-time), `criteria` (a list of `{criterion, sha256}` that is not empty) | `subject` (a free map: scenario, replica, target), `verdict`, `round` (text) |

`criterion` is the id of a node of the same graph with `x_criterion`, or `<path>#<id>` for a criterion in another
graph. `ref` is a path from the repository root, optionally with a fragment (`#/criteria/0` or the `id` of a list
item); `text` is the criterion itself. The amendment also gets a `SUPERSEDES` edge to the previous version.

```yaml
  - id: C_A7_V2
    node_type: claim
    plane: DEV
    status: open
    impact: 3
    confidence: 0.8
    label: "Criterion A7, version 2: passes with 8 of 10 replicas."
    x_criterion:
      id: A7
      version: 2
      registered_at: "2026-10-22T10:00:00-03:00"
      sha256: "7fb806ea1c06b6816ad43681d179143472b3c2a48b69f422c05b08339b48305a"
      text: "Passes with 8 of 10 replicas."
      amends: C_A7_V1
      reason: "Replica 3 showed that the limit was wrong."
      round: r3
  - id: E_A7_R4
    node_type: evidence
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.8
    label: "Round r4 passes criterion A7 with 9 of 10 replicas."
    x_measured_under:
      measured_at: "2026-10-23T09:00:00Z"
      round: r4
      criteria:
        - criterion: C_A7_V2
          sha256: "7fb806ea1c06b6816ad43681d179143472b3c2a48b69f422c05b08339b48305a"
      verdict: passes
```

The reader compares dates and rounds without computing a hash. Both with a time compare as instants in UTC; both only
dates compare by the written day, which assumes both were written in the same time zone, and the same day cannot
tell the order; with one only a date, whose time zone is
unknown, the other counts by its day in UTC, and a gap of up to one day cannot tell the order either. Only the same
`round` decides (the round that motivated the amendment): rounds are labels, not an order. A date on a day that does
not exist (February 30) is not compared. The `sha256` against the text or the file, and a
citation of another graph, are checked by `kg_criterion.py` (chapter 5).

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
| a cited criterion, or an `amends`, that is not a node of this graph with `x_criterion` | SHOULD | `integrity.criterion-unknown` |
| an amendment that points to a version of another criterion (another `x_criterion.id`), or whose chain of `amends` comes back to itself | SHOULD | `integrity.criterion-amends-mismatch` |
| a cited `sha256` that is not the one of the cited version | SHOULD | `integrity.criterion-sha-mismatch` |
| measured in the same `round` as the cited version, or before it was registered (see below) | SHOULD | `integrity.measured-post-hoc` |
| the dates cannot tell whether the result came before or after the cited version | SHOULD | `integrity.measured-order-unknown` |

An external edge counts as a link: a node linked only by one is not an orphan.
