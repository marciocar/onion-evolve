# Conformance suite for `.kg.yaml` and `.kg.json`

**English** | [Português (Brasil)](README.pt-BR.md)

> The cases measure contract v4: `spec/kg-contract-v4.schema.json` (MUST) and
> `spec/kg-contract-v4.should.schema.json` (SHOULD).

Every `.kg.yaml` reader must pass this suite: the reference reader `tools/kg_validate.py`, a viewer, a graph
extractor, or a port to another language. The cases are **pure data**, modeled on the
[JSON-Schema-Test-Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite), and they do not depend on any
agent harness.

## Format

A **group** is a folder with a `manifest.json` and one real `.kg.yaml` (or `.kg.json`) file per case. Each case is a
real file, not text embedded in the JSON, so any CLI can take the path and read it the way it reads a real graph.

```json
{
  "description": "enums do nó",
  "layer": "form",
  "pending_on": [],
  "cases": [
    { "file": "bad-node-type-enum.kg.yaml",
      "description": "node_type fora do enum",
      "valid": false,
      "codes": ["form.enum.node.node_type"],
      "warnings": [] }
  ]
}
```

| Field | Rule |
|---|---|
| `description` | Group and case. Required, non-empty text. It can carry the contract-version mark described below. |
| `layer` | Group. `parse`, `form`, `integrity`, `yaml`, or `semantic`: the layer the group exercises. `semantic` exists only in `optional/`. |
| `pending_on` | Group. Ids of the open decisions the verdict depends on. Empty in `latest/`, non-empty in `proposals/`. |
| `cases` | Group. The list of cases, with at least one. |
| `file` | Case. The case file, next to the manifest: a lowercase slug ending in `.kg.yaml`, `.yaml`, or `.kg.json`. |
| `corpus` | Case, optional (v4.3). A directory, relative to the manifest, that acts as the repository root when the reader checks the external end of `external_edges`. |
| `valid` | Case. `true` requires `codes: []`. `false` requires at least one code. |
| `codes` | Case. **MUST** violations: they fail the file. |
| `warnings` | Case. **SHOULD** violations: they only warn, and the file stays valid. Optional; when absent, it counts as `[]`. |

`manifest.schema.json` (JSON Schema 2020-12) validates every manifest. The suite validates itself with the same
technology as the contract, the way the JSON-Schema-Test-Suite does in its own CI. `metaschema-tests/` holds the
manifests the metaschema must accept (`good/`) and the ones it must reject (`bad/`).

**One case, one defect.** A reader passes a case when the **set** of codes it emits **equals** the expected set, in
both `codes` and `warnings`. Equality, not inclusion: a reader that flags everything cannot pass. Order and repetition
do not count.

**The description marks the contract version a case requires**, at the group or case level, in one of these forms:
"Desde o v4.6", "(v4.6)", or "do v4.6". The maintainer's check requires the highest mark to equal the version the
reference reader declares (`CONTRACT_VERSION` in `tools/kg_validate.py`), and requires the description of one of the
schemas to declare it ("No v4.6"). This way, a new rule that only the reader sees still changes the bytes of the
schemas, which `kg_gate.py` keeps as the contract identity.

## Codes

Each code is a stable slug per layer, and the metaschema checks its shape.

| Layer | Shape | Examples |
|---|---|---|
| parse | `parse.<reason>` | `parse.yaml-error`, `parse.duplicate-key`, `parse.empty-document`, `parse.not-single-document`, `parse.root-not-mapping` |
| form | `form.<kind>.<scope>.<field>` | `form.required.node.label`, `form.enum.node.node_type`, `form.range.node.impact`, `form.pattern.edge.to`, `form.type.node.item` |
| integrity | `integrity.<rule>` | `integrity.duplicate-id`, `integrity.dangling-from`, `integrity.dangling-to`, `integrity.dangling-trigger`, `integrity.orphan-node` (MUST); `integrity.testimony-in-prod`, `integrity.verified-before-fact`, `integrity.untraced-decision`, `integrity.refutes-unreconciled`, and the five `integrity.criterion-*` and `integrity.measured-*` codes of v4.12 (SHOULD) |
| yaml | `yaml.<rule>` | `yaml.forbidden-key-on` (MUST), `yaml.unquoted-date` (SHOULD) |
| semantic | `semantic.<rule>` | `semantic.contradiction` (MUST); `semantic.supersedes-unreconciled`, `semantic.answered-question-open`, `semantic.decision-done-dev`, `semantic.stale-missing`, `semantic.stale-old`, `semantic.review-overdue`, `semantic.testimony-unmarked`, and the `semantic.domain-*` codes of the domain layer (SHOULD), only in `optional/` |

`<kind>` ∈ `required enum type pattern range const unknown-key exclusive`. `<scope>` ∈ `top meta node edge`.
In a nested object, `<field>` is the dotted path: `form.required.node.provenance.locator`.
`range` also covers text length: `label: ""` (MUST) and a `label` longer than 280 characters (SHOULD, because the
narrative goes in `narrative`). Length counts code points, like JSON Schema's `maxLength`: an emoji counts as 1, not
as 2 UTF-16 units (JavaScript's `str.length` would get it wrong), and there is no normalization.
A full date must exist on the calendar, and the code is `form.pattern`: the schema's `format: date` is an
**assertion**, and every reader must check it. `.nan` and `.inf` fail as `form.type` in any position, including under
an `x_` key and inside a list, because JSON cannot represent them. A list item that is not a mapping uses the `item`
field (`form.type.node.item`). A key name that is not a slug (`<<`, `1.0`, `a.b`) fails as `form.pattern.<scope>.key`;
with the `x_` prefix, it only warns. Keys are compared in their JSON form: `1` and `"1"` collide
(`parse.duplicate-key`), and `true` becomes `true`, not `True`. An edge with `on` fails with `yaml.forbidden-key-on`;
if the target of `on` does not exist, `integrity.dangling-on` comes out too. The `pattern` keywords follow ECMA-262
semantics, as in JSON Schema: `$` does not match before a final line break.

What v4 changed in severity, and what it added:

| Code | In v3 | In v4 |
|---|---|---|
| `form.required.node.provenance` (a `confirmed` or PROD node without `provenance`; `unverifiable` does not require it) | SHOULD | **MUST** |
| `form.unknown-key.<scope>.<key>` (a key outside the grammar and without `x_`, at the top level, in meta, in a node, or in an edge) | SHOULD | **MUST** |
| `form.pattern.<scope>.key` (a name that is not a slug, without `x_`) | SHOULD | **MUST** (with `x_`, still SHOULD) |
| `form.pattern.node.provenance.source` (a placeholder `source`: whitespace only, `desconhecida`, `unknown`, `n/a`, `none`, `null`, `sem fonte`, `tbd`, hyphens, an em dash, `?`...) | — | **MUST** (an empty value still gives `form.range`) |
| `form.pattern.node.provenance.method` (not in the form `'<class>: <detail>'`, with the class one of `medição` (measurement), `leitura` (reading), `juízes` (judges), `derivado` (derived), or `testemunho` (testimony)) | — | SHOULD (MUST in v5) |
| `form.unknown-key.node.provenance.<key>` (an unknown key inside `provenance`) | SHOULD | SHOULD |

v4.1 adds four SHOULD warnings (no verdict changes; `latest/form/unanchored/` and `latest/integrity/coherence/`).
The three `integrity.*` codes cross fields or edges, so the reader computes them outside the schema:

| Code | When it warns |
|---|---|
| `form.required.node.verified_against` | a `claim` with `verified_at` and without `verified_against`: a stamp with no target (the other node types already anchor themselves through another field) |
| `integrity.testimony-in-prod` | a PROD node whose basis is testimony (`evidence_class: testimony` or a `method` of class `testemunho`) |
| `integrity.verified-before-fact` | `verified_at` earlier than `valid_from`, compared at the granularity of the shorter one (`YYYY`, `YYYY-MM`, `YYYY-MM-DD`); a date outside these forms is not compared |
| `integrity.untraced-decision` | a `decision` that is neither `superseded` nor `refuted`, with no `trace`, no `provenance`, and no outgoing `TRACES_TO` edge |

v4.3 adds `external_edges`, optional, at the top level: edges between graphs with **exactly one** external end,
`<path relative to the repository root>#<id>`, while the other end is an id in this file or absent (an absent `from`
stands for the whole graph). The types are `SUPERSEDES`, `CONSTRAINS`, `SUPPORTS`, `REFUTES`, `TRACES_TO`, and
`DEPENDS_ON`. The cases live in `latest/form/external-edges/`, `latest/integrity/external-local/`, and
`latest/integrity/external-corpus/`.

| Code | When it fails |
|---|---|
| `form.pattern.top.external_edges.to` (or `.from`) | both ends external, both ends local, or a reference outside the form (an absolute path, or no `.kg.yaml#` or `.kg.json#`) |
| `form.enum.top.external_edges.edge_type` | a type outside the six (the domain-layer types do not cross graphs) |
| `integrity.dangling-external-local` | the local end does not exist in this file |
| `integrity.dangling-external` | **with the corpus**: the file or the id of the external end does not exist |

An external edge counts as a link: a node linked only by one is not an orphan. Without the corpus, the reader does
not check the external end, and it says so in its output. The reference is relative and uses `/`: segments start with
a letter, a digit, or `_`, with no `.` or `..` segments, no `\`, and no `:`.

**The `.kg.json` format.** The same data model can come as JSON, in a `.kg.json` file, read by a JSON parser under
the contract's **JSON profile** (`latest/json/`). In it, these points are **MUST**:

| Point | What fails | Code |
|---|---|---|
| Numbers per I-JSON (RFC 7493) | an integer-valued number with magnitude above 2^53−1, written as an integer or as a float (`9007199254740992`, `1e20`); a value that overflows a double (`1e400`, a 401-digit integer) is already non-finite | `form.type.<scope>.<field>`, the same path as `.nan` |
| Strings without a lone surrogate (I-JSON) | `\ud800` without its pair, in a key or a value; the pair `😀` is a single character | `parse.yaml-error` |
| Depth | more than 128 nested collections (the root counts as 1) | `parse.yaml-error` |
| RFC 8259 whitespace | only space, tab, LF, and CR; a leading BOM is accepted and dropped, and anything else fails (NBSP and `\x1c` are not whitespace) | `parse.yaml-error` |
| RFC 8259 syntax | a comment, a trailing comma, an unquoted key, single quotes, `NaN`, `Infinity` | `parse.yaml-error` |
| Unique keys (ADR 002) | the same key twice in an object, compared after escapes are resolved | `parse.duplicate-key` |

An empty document, one with only RFC whitespace, or `null` is `parse.empty-document`. Invalid JSON syntax uses
`parse.yaml-error`: the vocabulary has no `parse.json-error`. In `.kg.yaml`, the first three points are **SHOULD**, and
the YAML MUST verdict does not change (`latest/yaml/json-profile/`):

| Code | When it warns |
|---|---|
| `yaml.unsafe-integer` | an integer-valued number outside ±(2^53−1) |
| `yaml.lone-surrogate` | a lone surrogate in a key or a text value |
| `yaml.depth-over-128` | more than 128 nested collections (the YAML parse limit stays at 1000) |

v4.2 adds `provenance.locality`, optional, with the enum `repo`, `web`, `host`, or `pessoa`. A value outside the enum
warns as `form.enum.node.provenance.locality` (`latest/form/provenance-locality/`), and no verdict changes.

v4.4 adds `integrity.refutes-unreconciled` (`latest/integrity/coherence/`): a node that receives `REFUTES` and stays
alive, that is, neither `superseded` nor `refuted`. A `question` that is `done` does not warn, because it is already
answered. The graph asserts and refutes the same thing. In `optional/semantic/`, the same graph fails as
`semantic.contradiction`, which is what the radar does; in the contract the case is SHOULD for now, and it becomes
MUST in a future version, after adopters measure their own debt.

v4.4 also closes three rare YAML constructs where readers disagreed (`latest/yaml/strict-profile/`), taking the
strictest verdict in all three, by a contract decision of 2026-10-19. All of them fail as `parse.yaml-error`:
- the unnamed `!` tag, also in the form `!<!>`, on a scalar or a collection;
- an explicit `!!timestamp` whose text is not a date in the strict form: the intersection of PyYAML's constructor and
  the one in the JavaScript `yaml` package (two-digit minute and second, a fraction with at least one digit, a time
  zone up to ±29, and only a space between the date and the time);
- a tab outside quotes, a literal block, or a comment (as whitespace or inside an unquoted text value), as in PyYAML's
  pure parser.

Measured on 2026-10-20: none of the 1,391 `.kg.yaml` files in four adopter repositories changes its verdict.

v4.5 adds four things:
- `verified_scope`, optional, the reach of `verified_at` (`latest/form/verified-scope/`). The MUST level only accepts
  the key; at the SHOULD level, the enum is `fato`, `mecanismo`, or `nenhum` (a value outside it warns as
  `form.enum.node.verified_scope`), and `verified_scope` without `verified_at` warns as
  `form.required.node.verified_at`.
- `privado` in the `provenance.locality` enum: a document outside the repository, not public, and re-verifiable by
  whoever has access.
- With the corpus, a `REFUTES` that arrives from another graph through `external_edges` at a live node counts toward
  `integrity.refutes-unreconciled` (`latest/integrity/external-corpus/`); without the corpus, it does not count.
- A tab in the leading whitespace of a continuation line of a quoted text value fails as `parse.yaml-error`, in both
  readers and by the same explicit rule (`latest/yaml/strict-profile/`).

Measured on 2026-10-20: none of the 1,457 `.kg.yaml` files in four adopter repositories changes at the MUST or SHOULD
level.

v4.6 closes three more YAML differences between the readers (`latest/yaml/strict-profile/`):
- the continuation line of a quoted text value must be indented more than the block collection that contains it (the
  column of the mapping or of the list's `-`; at the root, at least one space), as the specification requires; less
  than that fails as `parse.yaml-error`. A whitespace-only line does not count;
- `\r\n` and a lone `\r` are line breaks in both readers, as in the specification: the JavaScript reader no longer
  keeps `\r` as a character inside quotes;
- a quoted text value must close: an escaped quote (`''` or `\"`) at the end of a line does not close it, and the
  JavaScript reader no longer cuts the scalar there.

Measured on 2026-10-20: none of the 1,507 `.kg.yaml` files in four adopter repositories changes at the MUST or SHOULD
level.

v4.7 lets the external end of an edge point to a `.kg.json` file (`latest/form/external-edges/` and
`latest/integrity/external-corpus/`). Only `.kg.yaml` and `.kg.json` belong to the contract: `.kg.yml` and an
uppercase extension fail as `form.pattern.top.external_edges.to`. With the corpus, the extension is not normalized: a
reference to `alvo.kg.json` when only `alvo.kg.yaml` exists fails as `integrity.dangling-external`.

v4.8 adds three optional node keys for verification (`latest/form/reverify/`): `reverify_every`, the cadence;
`reverify_on`, the event trigger; and `retain_for`, the retention. The SHOULD level judges the values, and being due
never enters the verdict:
- `reverify_every` and `retain_for` warn when they are not an ISO 8601 duration with date parts only (uppercase, with
  at least one component), or when they are zero, like `P0D` (`form.pattern.node.reverify_every`,
  `form.pattern.node.retain_for`); a number instead of a duration warns as `form.type.node.reverify_every`;
- an empty `reverify_on` warns as `form.range.node.reverify_on`.

v4.9 stops warning about `reverify_every` without `verified_at`: a cadence with no verification yet is the starting
state of a collection rule. The due report lists it (`kg_validate.py --due`, in the `unstamped` list), outside the
verdict. A PROD node without `verified_at` still warns.

v4.10 aligns the reference reader and the JavaScript reader on three rare YAML points (`latest/yaml/profile/`):
- errors follow document order: a duplicate key that comes before a duplicate anchor or an undefined alias gives
  `parse.duplicate-key` (after them, `parse.yaml-error`);
- an empty line after an escaped line break inside double quotes becomes `\n`, as the specification requires;
- a leading BOM does not count as a column.

v4.12 adds the pre-registered criterion, so that changing the yardstick after seeing the data becomes a dated
amendment instead of a rewrite. Two SHOULD profiles (`latest/form/profiles/`): `x_criterion` on the node of each
criterion version (`id`, `version`, `registered_at`, `sha256`, and either `ref` or `text`; `amends` needs `reason`;
`ref` and `text` together warn as `form.exclusive.node.x_criterion`), and `x_measured_under` on the result
(`measured_at` and `criteria`, a list of `{criterion, sha256}`). Five coherence warnings between nodes of the same
graph (`latest/integrity/criterion/`):
- `integrity.criterion-unknown`: the cited criterion, or the `amends`, is not a node of this graph with `x_criterion`;
- `integrity.criterion-amends-mismatch`: the amendment points to a version of another criterion, or its chain of
  `amends` comes back to itself;
- `integrity.criterion-sha-mismatch`: the cited `sha256` is not the one of the version;
- `integrity.measured-post-hoc`: measured in the same `round` as the cited version (the round that motivated it), or
  before it was registered;
- `integrity.measured-order-unknown`: the dates cannot tell the order.

How the dates compare: both with a time, the instant in UTC; both only dates, the written day (the same day is
`measured-order-unknown`); one only a date, whose time zone is unknown, the day in UTC with a day of slack, so a gap of
up to one day is `measured-order-unknown` and `measured-post-hoc` takes two days or more. A different `round` does not
tell the order, because rounds are labels. A date on a day that does not exist (February 30) is not compared.

A reader computes no hash and reads no corpus for these: a `<path>#<id>` citation and the `sha256` against the text
or the file belong to `kg_criterion.py`, which is not part of the suite. No verdict changes.

v4.13 adds `role` to the `x_questionnaire` profile, in the SHOULD (`latest/form/profiles/`): `item`, the default,
`evidence_request` (a request to a person for evidence), or `evidence_requirement` (the evidence an item requires), which
tell those apart from a questionnaire item. Another value warns as
`form.enum.node.x_questionnaire.role`, and nothing that passed fails.

The same code can be MUST in one case and SHOULD in another, because severity belongs to the case, not to the code.

## Folders

The cases live in `fixtures/`, the test-directory convention that repository validators usually exempt. Without that,
the graphs that are broken on purpose would fail the repository itself. The exception is
`latest/parse/document/bad-yaml-syntax.yaml`: some validators scan every tracked `.kg.yaml` file without honoring the
convention, so the only unparseable case uses the `.yaml` extension (the metaschema accepts both). Inside each folder,
you can lay out groups freely; by convention, `latest/<layer>/<group>/`.

| Folder | What it means |
|---|---|
| `fixtures/latest/` | The current contract. A reader **must** pass every case. |
| `fixtures/optional/` | Behavior a reader **may** implement; today, `semantic/`, the semantic layer of the radar (the reader in the framework where the format was born). It runs and reports, but never fails the run. |
| `fixtures/proposals/` | The verdict depends on an open decision (`pending_on`). It runs and reports, but never fails the run. |

**Promotion rule.** A group moves from `proposals/` to `latest/` only when **all** the decisions in `pending_on` are
sealed, that is, merged into the product graph, **and** the schema in `spec/` already accepts what the group requires
(for example, `trigger` in `integrity-trigger`). The promotion PR empties `pending_on` and cites the sealed node.
Nothing gets ahead of an open decision.

**Today's score.** The reference reader passes 100% of `latest/`: 438 cases against contract v4, 32 of them
`.kg.json`. The groups from the v4 draft moved from `proposals/` to `latest/form/` (`provenance-required`,
`placeholder-source`, `unknown-key`, `method-vocabulary`, `should-remains`), and the cases inherited from v3 whose
verdict v4 changes became `bad-*` cases. Every case uses a canonical `method` (`medição: caso de conformidade`), so
the vocabulary warning shows up only where a case asks for it. `proposals/` is empty.

## Run

```bash
pip install --require-hashes -r tools/requirements.txt          # PyYAML and jsonschema, exact versions
python3 -I tools/kg_conformance.py             # --suite DIR, --schema F, --should-schema F, --json OUT
# proposals/ against a candidate contract, when there is a draft of a future version
python3 -I tools/kg_conformance.py --proposals-schema <candidate>.schema.json \
  --proposals-should-schema <candidate>.should.schema.json
```

The two `--proposals-*` options go together and measure only `proposals/` against a candidate contract; `latest/` and
`optional/` stay on `--schema`, and the rc does not change.

The tool prints one `PASS` or `FAIL` line per case, with the expected and emitted codes for each failure, and ends
with one summary line per folder. The human output is in English by default, and in pt-BR with `KG_SSOT_LANG=pt-BR`
or a `pt_BR` locale. Today the run ends like this:

```text
—
latest: 438/438 (gates the rc)
optional: 10/24 (report only)
```

The rc is `0` if all of `latest/` passes, `1` if any `latest/` case fails, and `2` if the suite itself is broken: an
unreadable or invalid metaschema or manifest, a `pending_on` that breaks the rule, an unknown folder, a case file that
is missing, repeated, or outside every manifest, a `corpus` that is not a directory, a contract schema that is not a
valid JSON Schema, or an empty `latest/`. Each defect of a broken suite prints as a `BROKEN SUITE` line. A reader
that crashes on a case counts as a failure of that case. `optional/` (today only the `semantic` layer, which the
reference reader does not implement) and `proposals/` report and never change the rc.

## A reader in another language

`kg_conformance.py` runs only the reference reader. A reader in another language runs the suite with its own code: it
iterates over the `manifest.json` files in `fixtures/latest/`, judges each case (with the repository root at
`<manifest folder>/<corpus>` when the case declares `corpus`), and compares the sets of `codes` and `warnings` for
equality. A reader that does not expose codes compares only the verdict: `valid: true` accepts, `valid: false`
rejects.

To compare readers side by side, the maintainer uses a **runner contract**, and any reader that implements it can be
measured the same way: `runner <case>` prints ONE JSON object on the last line of stdout and exits with rc 0:

```json
{"verdict": "accept" | "reject" | "error", "codes": [...] | null, "warnings": [...] | null, "detail": "..."}
```

- `verdict` is level 1, and every reader has it: does it accept or reject the file? A case with MUST `codes` expects
  `reject`; a valid case, even one with `warnings`, expects `accept`.
- `codes` is level 2, only for readers that expose a reason, compared as a set in the layers the reader implements.
  `null` means the reader does not say why.
- **Corpus case** (v4.3): a case that declares `corpus` in the manifest is judged with that directory as the
  repository root, and the runner gets `runner <case> --corpus <dir>`. A reader that does not check the external end
  of `external_edges` is `n/a` on these cases.
- `error` means the reader crashed. Output that is not JSON, an unknown `verdict`, a non-zero rc, or a timeout also
  becomes `error`. It is a divergence, not an absence of opinion.

## Hygiene

The cases are written here, without copying third-party graphs, and they use synthetic ids (`Q_A`, `EV_A`...), with no
machine paths and no private node ids. This file ships in the release (`spec/release.json`), and the maintainer's
hygiene check fails any private reference in `spec/` and in the release files.
