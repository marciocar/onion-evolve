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
| `method` | string | req. Not empty. SHOULD: `<class>: <detail>`, with the class one of `measurement`, `reading`, `judges`, `derived`, or `testimony` (the Portuguese `medição`, `leitura`, `juízes`, `derivado`, `testemunho` are accepted aliases, since v4.16) |
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
repository root and written with `/`. Each segment starts with a letter, a digit, or `_`, or, since v4.15, with a dot
followed by one of them (`.github/`, `.config/`). An absolute path, the segments `.` and `..`, `\`, and
`:` fail.

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
| `notation` | string | a code that identifies the term (`GTIN`, a catalog number, `O1`) |
| `scheme` | slug | the vocabulary the term belongs to (v4.14): lowercase letters, digits, and hyphens. Without it, the scheme is the graph |
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

**A short code with a readable name (v4.14).** A code like `O1`, `V3`, or `r16` is fine as long as it has a name. Give
it a term: the code is the `notation`, the name is the `pref`, and the `scheme` says which vocabulary it belongs to, as
`skos:notation`, `skos:prefLabel`, and `skos:inScheme` do in SKOS. The id of the node stays short and stable. The same
code may mean two things in two schemes (the option `O1` of a decision and the wave `O1` of a recovery): outside its own
graph, cite it as `scheme:code`. Within one scheme a code names one concept, so two live terms with the same notation in
the same scheme warn as `integrity.term-notation-duplicate`; the graph's own scheme is named by its `meta.id`, so a
declared scheme with that name is the same scheme. `kg_vocab.py lint` checks the codes written in labels and
narratives against the vocabulary (chapter 5).

`kg_vocab.py` lists the terms, resolves a text to its term, and exports to SKOS-XL and Apache Ossie (chapter 5).

```yaml
  - id: T_EAN
    node_type: entity
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    verified_at: "2026-10-22"
    verified_against: "the data dictionary PDF downloaded on 2026-10-22"
    provenance:
      source: "https://dados.anvisa.gov.br/dados/TA_PRECO_MEDICAMENTO%20-%20Dicionario%20de%20Dados.pdf"
      locator: "items 9, 10 and 11"
      method: "reading: the downloaded PDF, entry by entry"
      locality: web
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

A term in force is `confirmed` with the `provenance` of the source it was adopted from, like any other fact. Leave it
`open` only while the definition is still being negotiated: `kg_vocab.py` resolves an open term the same way, but the
queue of open nodes (`kg_query --open`) would list a settled definition as pending work.

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

## Recording an external event (recommended shape, not normative)

An e-mail, a chat message, a wiki edit, a repository webhook or a cloud notification reaches a company brain through
a collector. This is the shape we recommend for the node that records it. It is **not** a canonical profile: the
contract does not judge `x_event`, and a graph that writes it another way keeps its verdict. The shape is here so that
collectors write the same names and readers can count on them.

**The node is an `evidence`.** No new node type: the `event` node type means a domain event that changes a `state`,
not a message that arrived.

**`x_event` uses the names of the CloudEvents 1.0 core context attributes.**

| Attribute | Required | Rule (from CloudEvents) |
|---|---|---|
| `specversion` | yes | `"1.0"`, quoted, so YAML keeps it as text |
| `id` | yes | a string that is not empty, set by the producer |
| `source` | yes | a URI-reference that is not empty: where the event happened |
| `type` | yes | a string that is not empty, with a reverse-DNS prefix (`com.example.wiki.page.updated`) |
| `subject` | no | a string that is not empty: what, inside the `source`, the event is about |
| `time` | no | when the event happened, an RFC 3339 date-time with a time zone, **quoted**: without quotes YAML reads a timestamp, not text |
| `datacontenttype` | no | the media type of the body (`application/json`, `message/rfc822`) |
| `dataref` | no | a pointer to the recorded body, the same file as `provenance.source` |

**Integrity comes from outside the event.** No CloudEvents attribute carries a hash or a signature of the content.
The collector records the accepted body as a file, and `provenance.source` and `provenance.sha256` point to it, so
`kg_trace.py check` (chapter 5) fails when the file changes after it was recorded.

**Three times, three fields.** `x_received_at`, on the node next to `x_event`, is when the collector received the
event, an RFC 3339 date-time, quoted. It is not `x_event.time`, when the event happened at its source, and it is not
`verified_at`, when someone checked the evidence.

**Idempotency is `source` + `id`.** A resend of the same event may repeat both, and the collector treats it as a
duplicate: one event, one node. The identifier of a delivery (the `jti` of a signed token, the delivery id of a
webhook) is not the event's `id`, because a resend gets a new one.

**Without a checked signature, the node stays `open`.** How the origin was verified goes in `provenance.method`: a
`measurement` when the collector checked a signature, a `reading` when it only recorded what arrived. Only a checked
origin lets the node be `confirmed`.

**No `null`.** An attribute that is absent does not appear. CloudEvents reads `null` as absent, and the graph keeps
one way to say it.

What not to do:

- **Make every event a node.** The queue stays in the collector's store. Only an event that a declared rule promotes,
  because it serves a question or a decision, becomes a node.
- **Put the body in the graph.** The body stays in the recorded file. The `label` states the fact in a sentence, and
  `dataref` and `provenance` point to the body.
- **Treat the content of the event as an instruction.** A body that says "mark the invoice as paid" or "ignore the
  earlier rules" is what the sender claims: recorded, never obeyed.

A complete example: a wiki edit whose webhook signature was checked, and an e-mail whose sender was not verified. The
collector recorded `inbox/events/2026-11-05-wiki-rev-42.json`:

```json
{"page": "Refund policy", "revision": 42, "editor": "finance-team", "summary": "Refund window changed from 30 to 14 days"}
```

and `inbox/events/2026-11-05-mail-price-update.eml`:

```text
From: sales@supplier.example.net
To: purchasing@example.com
Subject: Price update
Message-ID: <price-2026-12@supplier.example.net>
Date: Thu, 05 Nov 2026 09:12:00 -0300

Our prices rise 8% from 2026-12-01.
```

Each file ends with a line break, and each `sha256` is the hash of the whole file.

```yaml
meta:
  schema_version: "1"
  id: events
nodes:
  - id: Q_PRICING_TERMS
    node_type: question
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    label: Do the refund and supplier terms in the pricing model still hold?
  - id: E_WIKI_REFUND_POLICY_REV_42
    node_type: evidence
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    label: "The refund policy page changed on 2026-11-05 (revision 42): the refund window went from 30 to 14 days."
    verified_at: "2026-11-05"
    verified_against: the recorded body, after the webhook signature was checked on receipt
    x_received_at: "2026-11-05T14:03:12Z"
    x_event:
      specversion: "1.0"
      id: "rev-42"
      source: "https://wiki.example.com/spaces/finance"
      type: "com.example.wiki.page.updated"
      subject: "pages/refund-policy"
      time: "2026-11-05T14:03:07Z"
      datacontenttype: "application/json"
      dataref: "inbox/events/2026-11-05-wiki-rev-42.json"
    provenance:
      source: inbox/events/2026-11-05-wiki-rev-42.json
      locator: "the whole file"
      method: "measurement: the collector checked the webhook HMAC signature against the shared secret before recording the body"
      sha256: "4abc0a46c949c6425bd1c438dfc0353b8082731837e103e9c2a8dbaaabc0dfed"
      locality: repo
  - id: E_MAIL_SUPPLIER_PRICE_UPDATE
    node_type: evidence
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    label: "An e-mail from the supplier says its prices rise 8% from 2026-12-01; the sender was not verified."
    x_received_at: "2026-11-05T12:12:41Z"
    x_event:
      specversion: "1.0"
      id: "<price-2026-12@supplier.example.net>"
      source: "imap://mail.example.com/purchasing"
      type: "com.example.mail.received"
      time: "2026-11-05T09:12:00-03:00"
      datacontenttype: "message/rfc822"
      dataref: "inbox/events/2026-11-05-mail-price-update.eml"
    provenance:
      source: inbox/events/2026-11-05-mail-price-update.eml
      locator: "the whole file"
      method: "reading: the collector recorded the message as received; no signature was checked"
      sha256: "8bd9767d59723248b6acde789c58e2c6d7e1f31f77def0bf949493ca00df7585"
      locality: repo
edges:
  - from: E_WIKI_REFUND_POLICY_REV_42
    to: Q_PRICING_TERMS
    edge_type: SUPPORTS
  - from: E_MAIL_SUPPLIER_PRICE_UPDATE
    to: Q_PRICING_TERMS
    edge_type: SUPPORTS
```

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/events.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_trace.py check --root .
```

```text
PASS docs/events.kg.yaml
· 1 files; 1 pass the MUST; 0 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
· 2 source(s) read by scheme or sha256: 2 ok, 0 failed (2 sha256 checked); not judged (counted): 0 form only, 0 URL with no --with, 0 source not found, 0 malformed scheme, locator or hash, 0 other
· 0 trace(s) judged: 0 resolve, 0 missing; not judged (counted): 0 absolute or URL, 0 external root, 0 not a path, 0 not text
```

When the event arrives wrapped in a signed envelope that an inbox accepted, the source is the accepted document and
the body hash goes in `provenance.x_body_sha256`: see the recipe in
[chapter 8](08-recipes.md#record-an-external-event-that-arrived-by-a-signed-message).

When two adopters, or 50 real nodes, use this shape, it becomes a canonical profile in the SHOULD, judged only when
present.

## Recording a planned change (recommended shape, not normative)

A change to a system, a policy or a process is planned, told to the people it affects, applied, checked and, sometimes,
undone. This is the shape we recommend for the nodes that record it, and it is the sibling of the shape of `x_event`
above. It is **not** a canonical profile either: the contract does not judge `x_change`, and a graph that writes it
another way keeps its verdict.

**The change is a `decision`, and each transition is an `evidence`.** The `decision` is the choice to change, and its
`x_change.state` says where the change stands, so `kg_query` lists the changes by state. Each transition past
`planned` is an `evidence` node with `x_change_transition` and a `SUPPORTS` edge to the decision: the evidence is the
proof, and the state is only what the proof allows. The history of a change is its evidence nodes in the order of
`at`, not a list inside the decision, and the earlier values of `state` stay in the git history.

**Five states.** No standard names them. ITIL 4 change enablement assesses the risk, authorizes the change and keeps
the change schedule, and ISO/IEC 20000-1 also asks that the remedy of an unsuccessful change be planned; neither names
the states of the record. The OpenTelemetry semantic conventions have `vcs.change.state` (`open`, `wip`, `closed`,
`merged`), which is about a change of code under review, and `deployment.status` (`succeeded`, `failed`), which is
the outcome of one deployment; neither covers a change of a policy or a process. So the names are ours:

| State | What it means | What the graph has |
|---|---|---|
| `planned` | recorded, with its target, window and rollback plan | the decision with `x_change` |
| `communicated` | the people it affects were told | an `evidence` with the `x_event` of the notice, and `communicated_by` pointing to it |
| `applied` | it was done in the target | an `evidence` of the application (a deployment record, a line of a log), and the approval in `sealed_by` |
| `verified` | a check measured that it took effect | an `evidence` whose `provenance.method` is a `measurement`, with `status: confirmed` |
| `reverted` | it was undone | an `evidence` of the reversion, with a `SUPERSEDES` edge to the evidence of the application it undoes, which goes to `status: superseded` |

The state moves in that order. `communicated` can be skipped when no one has to be told, as in a standard change, and
`reverted` comes after `applied` or `verified`. A change dropped before it was applied is none of the five: the
decision closes with `status: done`, the state stays where it stopped, and `narrative` says why.

**`x_change`, on the decision:**

| Key | Required | Rule |
|---|---|---|
| `state` | yes | one of the five. It is `state`, not `status`: some readers read a nested `status` as the status of the node |
| `target` | yes | what changes: a URI-reference that is not empty, or the id of the node in this graph that stands for it (a `policy`, an `artifact`) |
| `window` | yes | `start` and `end`, RFC 3339 date-times with a time zone, **quoted**, with `end` after `start`: when the change may be applied. A change without a window is not planned yet |
| `rollback_plan` | yes | a pointer to the plan (a path in the repository, or a URL), not the plan itself |
| `kind` | no | `standard` (low risk, authorized in advance), `normal` or `emergency`: the change types of ITIL 4 |
| `ref` | no | the id of the change in the tool that records it (`CHG-0142`) |
| `communicated_by` | from `communicated` on | the id, in this graph, of the `evidence` node with the `x_event` of the notice |

**`x_change_transition`, on each evidence:** `to` (required) is `communicated`, `applied`, `verified` or `reverted`,
and `at` (required) is when the transition happened, an RFC 3339 date-time, quoted. On the node with `x_event`, `at` is
the `x_event.time`.

**Who approved goes in `sealed_by`, by reference.** The contract already has `sealed_by` and `sealed_at` on a
decision: here they are the change authority and the date of the authorization. Write a role
(`role:change-advisory-board`) or a reference that a table outside git resolves to a person (`person:p-0042`), never a
name: the graph and its git history are a record that does not forget, and a name written there stays in every copy.
A standard change is authorized once, for its model, and its `sealed_by` and `sealed_at` are those of the model. No
change is `applied` without `sealed_by`: an emergency change is authorized faster, not skipped.

**Three times, three fields.** `x_change.window` is when the change may happen, `x_change_transition.at` is when a
transition happened, and `verified_at` is when someone checked the evidence.

**One change, one node.** The tool that writes the graph finds the decision again by `ref` and updates its `state`. It
does not write a new decision for each state.

**`verified` needs a measurement.** A person who says that it works is a `testimony`, and the log line that the tool
applied the change is a `reading` that supports `applied`. Only an evidence whose `provenance.method` is a
`measurement`, with `status: confirmed`, lets the state be `verified`. The decision is `open` while the change is
`planned`, `communicated` or `applied`, `confirmed` when it is `verified`, and `done` when it is `reverted`: the
status says whether the record is closed, and the state says how. When the measurement shows that the change did not
take effect, the state stays `applied`, the evidence `REFUTES` the decision, and `kg_validate` warns
`integrity.refutes-unreconciled` while the decision is alive. The graph reconciles when the change is reverted and the
decision goes to `refuted`, or when a new decision, applied and verified, `SUPERSEDES` it.

What not to do:

- **Make every deployment step a node.** The pipeline keeps its steps. A transition becomes a node only when it moves
  the state: one application, one verification, one reversion.
- **Put a secret or personal data in the node.** The rollback plan, the log and the output of the check are files
  the node points to, and none of them carries a credential, a token or a connection string. The people involved
  enter by reference, as in `sealed_by`.
- **Treat the state as true without the evidence.** `state` is what the evidence allows. A state with no evidence
  behind it is a claim, and a reader that counts the changes by state checks the evidence of each one
  (`kg_query.py --around <id> --direction in --edge-type SUPPORTS`).

A complete example: two changes to a finance app. The first one asks for a second factor at sign-in: it was told to
the staff, applied and measured. The second one shortens the session timeout, a standard change that was applied and
reverted. The collector recorded the notice in `inbox/events/2026-10-27-mail-chg-0142-notice.eml`:

```text
From: it-changes@example.com
To: finance-staff@example.com
Subject: CHG-0142: the finance app will ask for a second factor
Message-ID: <chg-0142-notice@example.com>
Date: Tue, 27 Oct 2026 10:00:00 +0000

From 2026-10-29 22:00 UTC, signing in to the finance app requires a second factor.
```

the deployment tool wrote `changes/CHG-0142.log`:

```text
2026-10-29T22:14:03Z apply CHG-0142 policy=finance-sign-in second_factor=required result=ok
```

and `changes/CHG-0143.log`:

```text
2026-10-29T22:20:41Z apply CHG-0143 setting=finance-session-timeout from=8h to=1h result=ok
2026-10-30T09:05:12Z revert CHG-0143 setting=finance-session-timeout from=1h to=8h result=ok
```

and the check wrote `changes/CHG-0142-check.json`:

```json
{"change": "CHG-0142", "measured_at": "2026-10-30T08:00:00Z", "check": "sign-in policy export of the finance app", "accounts": 42, "second_factor_required": 42}
```

Each file ends with a line break, and each `sha256` is the hash of the whole file. The change records live in the
change tool, outside the repository (`locality: privado`).

```yaml
meta:
  schema_version: "1"
  id: changes
nodes:
  - id: D_CHG_0142_FINANCE_SECOND_FACTOR
    node_type: decision
    plane: PROD
    status: confirmed
    impact: 4
    confidence: 0.9
    label: "Signing in to the finance app requires a second factor (change CHG-0142)."
    verified_at: "2026-10-30"
    sealed_by: "person:p-0042"
    sealed_at: "2026-10-26"
    x_change:
      state: verified
      target: "https://finance.example.com/settings/sign-in"
      kind: normal
      ref: "CHG-0142"
      window:
        start: "2026-10-29T22:00:00Z"
        end: "2026-10-29T23:00:00Z"
      rollback_plan: "https://changes.example.com/CHG-0142#rollback"
      communicated_by: E_CHG_0142_NOTICE
    provenance:
      source: "https://changes.example.com/CHG-0142"
      locator: "the change record, with its approval"
      method: "reading: the change record in the change tool"
      locality: privado
  - id: E_CHG_0142_NOTICE
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 3
    confidence: 0.9
    label: "The finance staff were told on 2026-10-27 that the finance app would ask for a second factor from 2026-10-29 22:00 UTC."
    verified_at: "2026-10-27"
    x_received_at: "2026-10-27T10:00:04Z"
    x_event:
      specversion: "1.0"
      id: "<chg-0142-notice@example.com>"
      source: "imap://mail.example.com/it-changes"
      type: "com.example.mail.sent"
      time: "2026-10-27T10:00:00Z"
      datacontenttype: "message/rfc822"
      dataref: "inbox/events/2026-10-27-mail-chg-0142-notice.eml"
    x_change_transition:
      to: communicated
      at: "2026-10-27T10:00:00Z"
    provenance:
      source: inbox/events/2026-10-27-mail-chg-0142-notice.eml
      locator: "the whole file"
      method: "measurement: the collector checked the DKIM signature of example.com before recording the message"
      sha256: "f6adb2d2565f84f4d8d09a0eefb3530389d2dd6f7bcdb8a529b8becc15d6e8ad"
      locality: repo
  - id: E_CHG_0142_APPLIED
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 3
    confidence: 0.8
    label: "The deployment log says the second-factor sign-in policy of the finance app was applied at 2026-10-29 22:14 UTC."
    verified_at: "2026-10-29"
    x_change_transition:
      to: applied
      at: "2026-10-29T22:14:03Z"
    provenance:
      source: changes/CHG-0142.log
      locator: "line=0"
      scheme: text
      method: "reading: the line the deployment tool wrote when it applied the change"
      sha256: "07888a04da6abf1b52170fe640782f9ed6739d86218d6d4284d7c73a7ecdc755"
      locality: repo
  - id: E_CHG_0142_VERIFIED
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 4
    confidence: 0.95
    label: "On 2026-10-30, the sign-in policy export of the finance app requires a second factor on all 42 accounts."
    verified_at: "2026-10-30"
    x_change_transition:
      to: verified
      at: "2026-10-30T08:00:00Z"
    provenance:
      source: changes/CHG-0142-check.json
      locator: "the whole file"
      method: "measurement: the check exported the sign-in policy and counted the accounts that require a second factor"
      sha256: "73df0837c693dd0a24c04b2b9fd5f6de2407bd94f3284eceb9a475225b179e35"
      locality: repo
  - id: D_CHG_0143_FINANCE_SESSION_TIMEOUT
    node_type: decision
    plane: PROD
    status: done
    impact: 3
    confidence: 0.9
    label: "The finance app session timeout went from 8 hours to 1 hour (change CHG-0143), and the change was reverted."
    narrative: "The overnight reconciliation job keeps one session open for more than an hour, and it stopped on 2026-10-30. The timeout went back to 8 hours."
    verified_at: "2026-10-30"
    sealed_by: "role:change-advisory-board"
    sealed_at: "2026-09-14"
    x_change:
      state: reverted
      target: "https://finance.example.com/settings/session"
      kind: standard
      ref: "CHG-0143"
      window:
        start: "2026-10-29T22:00:00Z"
        end: "2026-10-29T23:00:00Z"
      rollback_plan: "https://changes.example.com/standard/session-timeout#rollback"
    provenance:
      source: "https://changes.example.com/CHG-0143"
      locator: "the change record, under the standard change model it follows"
      method: "reading: the change record in the change tool"
      locality: privado
  - id: E_CHG_0143_APPLIED
    node_type: evidence
    plane: PROD
    status: superseded
    impact: 3
    confidence: 0.8
    label: "The deployment log says the finance app session timeout was set to 1 hour at 2026-10-29 22:20 UTC."
    verified_at: "2026-10-29"
    x_change_transition:
      to: applied
      at: "2026-10-29T22:20:41Z"
    provenance:
      source: changes/CHG-0143.log
      locator: "line=0"
      scheme: text
      method: "reading: the line the deployment tool wrote when it applied the change"
      sha256: "6e732995a0bc52533899832bde3258ff205c497d2d958128cb9002edd2f592a4"
      locality: repo
  - id: E_CHG_0143_REVERTED
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 3
    confidence: 0.8
    label: "The deployment log says the finance app session timeout went back to 8 hours at 2026-10-30 09:05 UTC."
    verified_at: "2026-10-30"
    x_change_transition:
      to: reverted
      at: "2026-10-30T09:05:12Z"
    provenance:
      source: changes/CHG-0143.log
      locator: "line=1"
      scheme: text
      method: "reading: the line the deployment tool wrote when it ran the rollback plan"
      sha256: "6e732995a0bc52533899832bde3258ff205c497d2d958128cb9002edd2f592a4"
      locality: repo
edges:
  - from: E_CHG_0142_NOTICE
    to: D_CHG_0142_FINANCE_SECOND_FACTOR
    edge_type: SUPPORTS
  - from: E_CHG_0142_APPLIED
    to: D_CHG_0142_FINANCE_SECOND_FACTOR
    edge_type: SUPPORTS
  - from: E_CHG_0142_VERIFIED
    to: D_CHG_0142_FINANCE_SECOND_FACTOR
    edge_type: SUPPORTS
  - from: E_CHG_0143_APPLIED
    to: D_CHG_0143_FINANCE_SESSION_TIMEOUT
    edge_type: SUPPORTS
  - from: E_CHG_0143_REVERTED
    to: D_CHG_0143_FINANCE_SESSION_TIMEOUT
    edge_type: SUPPORTS
  - from: E_CHG_0143_REVERTED
    to: E_CHG_0143_APPLIED
    edge_type: SUPERSEDES
```

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/changes.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_trace.py check --root .
python3 -I -B vendor/kg-ssot/tools/kg_query.py --root . --type decision --has x_change --group-by x_change.state
```

```text
PASS docs/changes.kg.yaml
· 1 files; 1 pass the MUST; 0 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
· 5 source(s) read by scheme or sha256: 5 ok, 0 failed (5 sha256 checked); not judged (counted): 0 form only, 0 URL with no --with, 0 source not found, 0 malformed scheme, locator or hash, 0 other
· 0 trace(s) judged: 0 resolve, 0 missing; not judged (counted): 0 absolute or URL, 0 external root, 0 not a path, 0 not text
     1  x_change.state=reverted
     1  x_change.state=verified
· only the nodes that have x_change
· 2 node(s) in 1 graph(s), in 2 group(s) by x_change.state
```

`--where x_change.state=applied` lists the changes applied and not yet verified, and `--where x_change.kind=emergency`
lists the emergency ones.

When two adopters, or 50 real nodes, use this shape, it becomes a canonical profile in the SHOULD, judged only when
present.

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
