# Changelog

**English** | [Português (Brasil)](CHANGELOG.pt-BR.md)

All notable changes to KG-SSOT are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases are tagged `kg-ssot-vX.Y.Z`.
The contract version (`v4.N`) is the version of the `.kg.yaml` / `.kg.json` contract that a release ships; it moves
only when the contract changes. Each release section is also the body of its GitHub release.
Releases before 4.16.0 are described in [ADOPTING.md](ADOPTING.md).

## [Unreleased]

## [4.22.0] - 2026-10-23

The audit package by question: one row per questionnaire item, with the answer, the dated evidence, and the gaps it
computes, in CSV, XLSX, or JSON. Contract v4.13: `x_questionnaire.role` in the SHOULD, nothing that passed fails.

### Added

- **The audit package by question (`kg_audit.py`).** An auditor asks for the package by question; until now an adopter
  kept it by hand next to the graph. The tool exports one row per questionnaire item (the pair of name and number that
  `x_questionnaire` gives): the question, the answer (by the profile, and a node without the profile by `DEPENDS_ON` in
  either direction), the verdict, the required evidence, the evidence (`SUPPORTS` to the answer, or `SUPPORTS` or
  `TRACES_TO` to the question, a request, or a requirement, also from another graph) with its date, scope, and due
  date, the contradictions (`REFUTES`), the evidence requests, the owner, and the gaps it computes: `no-answer` (no live
  answer: a `refuted` or `superseded` one does not count, nor does its evidence), `contradicted`, `no-confirmed-evidence`,
  `evidence-unstamped`, `evidence-cadence-invalid`, `evidence-due`, and `verdict-open`. What it cannot use (a `role`
  outside the enum, a question number that is not text, a malformed profile) comes out in `skipped`, in the package
  itself, never in silence. Formats:
  - CSV, with the questions or the evidence, and a leading apostrophe on a cell that would run as a formula;
  - XLSX with the questions, the evidence, and what was skipped, written with the standard library only, with stable bytes;
  - JSON, `kg-ssot.audit/1` (`spec/audit.schema.json`).

  `--column` brings an adopter's own key of the answer as a column, `--as-of` sets the day the evidence is due against,
  and `--fail-on-gap` gives rc 1 for CI. A graph that does not read gives rc 1, because the package would be incomplete
  in silence. Also on PyPI as `kg-audit`. Measured on an adopter's graphs before the cut.
- **`x_questionnaire.role` (contract v4.13).** `item`, the default; `evidence_request`, a request to a person for
  evidence; or `evidence_requirement`, the evidence an item requires. Without it, only an id prefix told them apart.
  SHOULD only: another value warns as `form.enum.node.x_questionnaire.role`, and nothing that passed fails.

## [4.21.1] - 2026-10-23

`kg_criterion.py check` reports what it cannot check instead of skipping it. Contract v4.12, unchanged.

### Fixed

- **`kg_criterion.py check` no longer skips a criterion it cannot check.** A `sha256` of digits alone without quotes
  reads as a number in YAML, and the version left the check with rc 0 and no finding. Now a version whose `sha256` is
  not text, or that lacks exactly one of `ref` and `text` in text, an `x_measured_under` that is not a map with a list
  of citation maps, and a citation of another graph whose `sha256` is not text (even when that graph was not given)
  come out as `integrity.criterion-malformed`, with rc 1. The reader already warned about the type
  (`form.type`); only the check passed in silence. Found by an adopter's test bench.

## [4.21.0] - 2026-10-23

A yardstick fixed before the data becomes part of the contract, and an adopter's own `x_` keys move into the
canonical profiles. Contract v4.12: two SHOULD profiles and five warnings, nothing that passed fails.

### Added

- **The pre-registered criterion (contract v4.12).** Changing a yardstick after seeing the data becomes a dated
  amendment instead of a rewrite, as in OSF Preregistration and the versioned amendments of a clinical trial registry.
  Two SHOULD profiles: `x_criterion`, one node per version of a criterion (`id`, `version`, `registered_at`, `sha256`,
  and either `ref` or `text`; `amends` with `reason` for an amendment), and `x_measured_under`, on the result
  (`measured_at`, and `criteria`, a list of `{criterion, sha256}`). Both readers, Python and JavaScript, warn about
  five things between nodes of the same graph, without computing a hash:
  - `integrity.criterion-unknown`: the cited criterion, or the `amends`, is not a criterion node of the graph;
  - `integrity.criterion-amends-mismatch`: the amendment points to a version of another criterion, or comes back to
    itself;
  - `integrity.criterion-sha-mismatch`: the cited `sha256` is not the one of the version;
  - `integrity.measured-post-hoc`: measured in the round that motivated the version, or before it was registered;
  - `integrity.measured-order-unknown`: the dates cannot tell the order (the same day, or a day apart when one of them
    has no time zone).

  `ref` and `text` together warn as `form.exclusive.node.x_criterion`, a new form kind. Requested by an adopter whose
  own reviewer caught a yardstick changed after the data.
- **`kg_criterion.py`** prints the `sha256` of a criterion (`digest`):
  - for `text`: UTF-8, LF, without trailing spaces;
  - for a whole file: the bytes, with CRLF turned into LF;
  - for a list item in a JSON or YAML file: its JCS form (RFC 8785), selected by JSON Pointer or by `id`.

  `check` verifies every version against its text or file, and every `<path>#<id>` citation of another graph
  (`kg-ssot.criterion/1`, `spec/criterion.schema.json`); it fails on a finding or on a graph that does not read, and
  belongs next to the gate in CI, because the reader computes no hash. It is also the `kg-criterion` command of the PyPI package.
- The suite goes from 390 to 438 cases (`latest/form/profiles/` and the new `latest/integrity/criterion/`).
- **`kg_migrate.py nest` moves an adopter's own `x_` keys into a canonical node profile** (`x_mirror`, `x_doc_cycle`,
  `x_questionnaire`), as a map says (`spec/kg-migrate-nest.schema.json`): each field from a constant, from an `x_` key
  that leaves the node, or from a key that stays, through an optional regex and value table. A key moved through a
  regex or a prefix needs `raw: true`, which keeps its original value in `x_raw`, so no text is lost. A value with no
  code, a missing required source, a profile that fails its schema, an alias, or a node in flow style goes to the
  reviewer in the plan, never guessed. Requested by an adopter; on a copy of their two graphs (108 nodes, 168 keys),
  106 profiles built and 2 left for review.

### Fixed

- **A missing required field counts once.** In the reference reader, an object with N required fields missing counted
  each of them N times: a `meta` with neither `schema_version` nor `id` showed `form.required.meta.id ×2`, and a node
  with three missing fields, `×3` for each. The JavaScript reader already counted right. The verdict, the set of codes,
  and the suite do not change; the counts in the summary, in `--where`, in the JSON verdict, and in the gate's
  per-occurrence baseline go down to the real number. Found by an adopter's test bench.

## [4.20.0] - 2026-10-23

The store stops re-judging graphs that did not change, the vendor stamp becomes a public rule in every tool, and
`kg_diff` names the working tree. Contract v4.11, unchanged.

### Added

- **`kg_diff.py` compares with the working tree by name.** `--to WORKTREE` is the same as leaving `--to` out, and
  `WORKTREE:PATH` reads the working-tree file, so `HEAD:x.kg.yaml WORKTREE:x.kg.yaml` reviews an edit before the commit
  (requested by an adopter; `--to WORKTREE` was a bad revision). `WORKTREE:PATH` starts from the repository root, like
  `REV:PATH`, and a path that leaves the repository is broken input. In the JSON, `after` is now `WORKTREE` instead of
  the Portuguese label the working tree had. A branch or tag named `WORKTREE` is now reached as `refs/heads/WORKTREE` or
  `refs/tags/WORKTREE`.

### Changed

- **The store no longer re-judges a graph that points to the written one and has not changed.** `kg_store` keeps the
  verdict of each judged graph in memory (`kg_validate.JudgeCache`), keyed by the text, both schemas, the language,
  the limit, and whether each external end resolves. With 50 pointing graphs of 820 KB, the second write of the target
  went from 41 s to 3.3 s, and writing the same text again from 44 s to 0.35 s; the first write in a process costs the
  same. A broken external end still fails, and a new contract judges everything again. `kg_validate.judge()` takes the
  cache as an optional `cache=` argument.
- **A folder with the `.kg-ssot-version` stamp is the vendor, in every tool that reads a repository.** Since 4.19.1
  only `kg_gate.py` left it out of the corpus; `kg_query.py`, `kg_vocab.py`, `kg_migrate.py`, and `kg_diff.py --from`
  excluded only `vendor/*` at the root, so a vendor elsewhere brought its example graphs in. A stamp at the root of
  what is read does not count, in every tool, the gate included: reading a folder that is the vendor reads its graphs.
  The rule is now public (`kg_validate.VENDOR_STAMP`, `vendor_dirs`, `in_vendor`, `find_vendor_dirs`) and documented
  in ADOPTING, for an adopter's own tools to follow
  (requested by an adopter whose trace resolver counted the vendor's example graph).

### Fixed

- **A gate test depended on the date.** Each accepted regression lives in `accepted/<hash>.json`, and the hash
  includes the date, so the reading order changed from one day to the next. The test now checks that the regressions
  accumulate, not their order.

## [4.19.1] - 2026-10-22

The gate leaves the KG-SSOT vendor out of the adopter's corpus. Contract v4.11, unchanged.

### Fixed

- **`kg_gate.py` counted the vendor's example graph as an adopter graph.** The 4.19.0 vendor brings
  `spec/vocab-examples/cmed-dictionary.kg.yaml` outside `fixtures/`, and a `--update` would write it into the baseline
  (found by an adopter before any `--update`). The gate now leaves out, by default, every file in a folder with the
  `.kg-ssot-version` stamp, wherever the vendor lives; `--no-default-excludes` brings it back.

## [4.19.0] - 2026-10-22

A domain vocabulary you can verify, synonym by synonym, and a shape for the `x_` keys that adopters repeat. Contract
v4.11.

### Added

- **The `x_term` profile (contract v4.11, SHOULD):** a term is a node with the preferred label (`pref`) and its
  synonyms, each with `kind` (`alt` or `hidden`, as in SKOS), `source`, `locator`, the `version` of the document,
  `verified_at`, `reverify_every`, `scope` (`domain`, or `case` with the case named, and an optional jurisdiction)
  and `retired` (`true` for the old name). A retired term is the node with `status: superseded` and a `SUPERSEDES` edge
  from the term that replaces it. A real example from the open data dictionary of the Brazilian drug price regulator
  ships in `spec/vocab-examples/cmed-dictionary.kg.yaml`.
- **`kg_vocab.py`:** `terms` lists the terms and what is due, `lookup` resolves a text to its term (without case,
  accents or repeated spaces; a case-scoped synonym only with `--case`), and `export` writes SKOS-XL with the
  ISO 25964 names in Turtle (`--to skos`) or one item per term for Apache Ossie, with `ai_context.synonyms` and the
  provenance of each synonym in `custom_extensions` (`--to ossie`). JSON output: `kg-ssot.vocab/1`
  (`spec/vocab.schema.json`). It also ships as the `kg-vocab` command in the PyPI package.
- **The `kg_terms` tool in the MCP server:** the same lookup over the store, read-only, with the synonyms' provenance
  and the term that replaces a superseded one.
- **The other canonical `x_` profiles (SHOULD, judged only when the key is present):** `x_mirror` (a record copied
  from another system, with `synced_at` and `resync_every`), `x_doc_cycle` (the life cycle of an external document),
  `x_questionnaire` (the link to the questions of an external questionnaire), `x_severity` (`critical` to `info`), and
  `x_confidence` and `x_provisional` on the edge.
- **`kg_migrate.py keys`:** renames each key the contract does not know to `x_<key>`, by text and with invariance
  checks; the known keys come from the MUST schema. Measured on a copy of the core's 15 graphs that failed the MUST on
  a foreign key: 14 pass afterwards.
- **`meta.title` and `meta.slug`** become known keys (MUST, a widening: nothing that passed fails).

### Changed

- **The due report** (`kg_validate.py --due`) also lists the synonyms of `x_term`, `x_mirror` and `x_doc_cycle`,
  with `subject` and `detail`; a node's entry and `schema_version` stay the same.
- **A list item inside a node keeps its path in the code** (`form.type.node.x_term.labels.item`), in both readers.
- **Upgrade note:** if you already use one of the profile names with another shape, the gate shows a new SHOULD code.
  Measured before the tag on the three adopters: one does (`x_severity` with values in Portuguese, already converted). Convert
  the values or accept it once with `--accept-regression`. The suite goes to 390 cases.

## [4.18.0] - 2026-10-22

KG-SSOT now speaks English first. The tools, the documentation and the listings are in English, and the full
Brazilian Portuguese translation ships next to them. Contract v4.10, unchanged.

### Changed

- **The tools print in English by default.** `kg_validate`, `kg_gate`, `kg_vendor`, `kg_store`, `kg_migrate`,
  `kg_query`, `kg_diff`, `kg_conformance`, `kg_mcp`, `kg_prov_export`, `kg_release_notes` and the npm CLI pick the
  language the gettext way: `KG_SSOT_LANG`, then `LANGUAGE`, `LC_ALL`, `LC_MESSAGES` and `LANG`. A `pt_BR` locale (or
  `KG_SSOT_LANG=pt-BR`) gives Brazilian Portuguese; `C`, `POSIX` and anything without a catalog give English.
- **Upgrade note:** machine-readable data does not change with the language: JSON keys and structure, error codes,
  exit codes, the verdict `place` (`nó X`, `aresta #n`) and `path`, the `--where` location and the `kg_migrate` TSV.
  Human text does: the terminal output and, inside JSON, the `message`, `hint` and `error` strings, which were always
  Portuguese before and are now English unless the locale is `pt_BR` (a CI runner with `LANG=C.UTF-8` gets English).
  Compare by code, never by message. If your CI greps the human output (`PASSA`, `✗ PIOROU`, `ENTRADA QUEBRADA`),
  either set `KG_SSOT_LANG=pt-BR` or match both languages (`PASS`, `✗ WORSE`, `BROKEN INPUT`); better yet, decide on
  the exit code.
- The MCP server speaks English in every locale: tool descriptions, instructions, errors and the text inside results
  are protocol (and prompt for the model), so they no longer depend on the server's environment. An external gate
  (`--gate-cmd`) run by the server gets `KG_SSOT_LANG=en` for the same reason. The Claude Desktop listing is
  translated by the extension's localization instead.
- As in gettext, `LANGUAGE` only applies when the effective locale is not `C`: `LC_ALL=C` forces English even on a
  desktop with `LANGUAGE=pt_BR:en`.
- The documentation is written in English and translated to Brazilian Portuguese: `README.md` and `README.pt-BR.md`,
  `ADOPTING.md` and `ADOPTING.pt-BR.md`, `spec/conformance/README.md` and its `.pt-BR.md`, and the manual in
  `docs/manual/` with the translation in `docs/manual/pt-BR/`. The manual chapters have English file names now
  (`04-contract.md`, `05-tools.md`, ...); the Portuguese chapters keep their old names under `pt-BR/`.
- The listings are in English: the PyPI and npm READMEs, the MCP Registry description and the Claude Desktop extension
  (`.mcpb`), which carries a pt-BR localization (`mcpb-resources/pt-BR.json`) for clients set to Portuguese.
- `llms.txt` and `llms-full.txt` are in English and read the English documentation.

### Added

- `tools/kg_i18n.py` and the catalog `locale/pt_BR/LC_MESSAGES/kg-ssot.po` (gettext format, 446 messages). They ship
  in the release, in the `gate` profile and in the Python package; `kg_vendor.py update` brings them with the tag.
  Without them, the vendored tools cannot start.
- `kg_migrate plan --json` reports broken input as JSON too (`{"error": ..., "reason": "broken_input"}`, exit 2).
  A usage error from the argument parser also exits 2 but writes nothing to stdout, so a script can tell them apart
  without matching text.
- `kg_store.InsideGitWorktree`, a `StoreError` subclass for a disk or versioned root inside a git worktree, so code
  that picks the backend decides by type instead of by message.

## [4.17.2] - 2026-10-22

The MCP server tells clients which tools only read. Contract v4.10, unchanged.

### Added

- Every tool in `kg_mcp` now announces MCP tool annotations: `kg_validate`, `kg_get`, `kg_list`, `kg_query`,
  `kg_history` and `kg_schema_help` are read-only and idempotent; `kg_write` and `kg_delete` are destructive. None
  reaches outside the local store (`openWorldHint: false`). A client can skip confirmation for reads and ask before a
  write or delete. They are hints; the store gate still decides what is written.

## [4.17.1] - 2026-10-22

Field fixes to the query and diff tools, found by adopters on their first real use of 4.17.0. Contract v4.10, unchanged.

### Changed

- `kg_query --root` and `kg_diff --from` now leave vendored code and test fixtures out by default (`vendor/*`,
  `fixtures/*`, `*/fixtures/*`, `docs/materials/*`). In one adopter, `--root` read 411 graphs for 29 real ones.
  `--no-default-excludes` reads everything; a path given explicitly is never excluded.
- `kg_query` JSON output now reports the corpus `root`.

### Added

- `kg_diff` marks a field renamed with the same value as a rename (`renamed_from` / `renamed_to`). Both entries stay in
  the JSON, so the `kg-ssot.diff/1` format is unchanged; only a non-trivial value that is unique on both sides is paired.
- The query and diff tests run in CI.

## [4.17.0] - 2026-10-21

Query, projection and diff for a whole corpus of graphs. Contract v4.10, unchanged.

### Added

- `kg_query.py`: select nodes across many graphs (id, prefix, type, status, plane, layer, label words, the open
  queue, nodes not verified since a date, the neighborhood of a node) and project every edge with the label of the
  other end, local or external, with cursor pagination. Output format `kg-ssot.query/1` (`spec/query.schema.json`).
- `kg_query` tool in the MCP server, scoped to the caller's store area, with a byte ceiling per page.
- `kg_diff.py`: diff two graphs, or everything that changed between two git revisions, aligned by node id and field by
  field, read from git without a checkout. `--ignore` drops a field a generator re-stamps. Output format
  `kg-ssot.diff/1` (`spec/diff.schema.json`).
- PyPI commands `kg-query` and `kg-diff`; the MCPB lists 8 tools.
- Two conformance cases (356 in `latest/`).

## [4.16.1] - 2026-10-21

Contract v4.10: the reference reader and the JavaScript reader agree on three rare YAML cases. No reference verdict
changes, and none of the 1,633 real graphs measured in four repositories changes its codes.

### Fixed

- Error order follows the document: a duplicate key that comes before a duplicate anchor or an undefined alias gives
  `parse.duplicate-key`, as in the JavaScript reader.
- JavaScript reader: an empty line after an escaped line break inside double quotes is a line feed, as the YAML spec
  says; a leading byte-order mark does not count as a column.
- Five conformance cases (354).

## [4.16.0] - 2026-10-21

The frictionless gate. Contract v4.9, unchanged.

### Changed

- The gate baseline is a folder, `.kg-ssot/gate/`, with one record per graph keyed by `meta.id`: branches that touch
  different graphs touch different files, so the baseline merges without conflict.
- A contract identity change with no verdict change passes with a notice (rc 0); `--strict-identity` restores the old
  behavior. The vendor checks the schemas against their stamp.

[Unreleased]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.19.1...HEAD
[4.19.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.19.0...kg-ssot-v4.19.1
[4.19.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.18.0...kg-ssot-v4.19.0
[4.18.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.2...kg-ssot-v4.18.0
[4.17.2]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.1...kg-ssot-v4.17.2
[4.17.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.0...kg-ssot-v4.17.1
[4.17.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.1...kg-ssot-v4.17.0
[4.16.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.0...kg-ssot-v4.16.1
[4.16.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.15.1...kg-ssot-v4.16.0
