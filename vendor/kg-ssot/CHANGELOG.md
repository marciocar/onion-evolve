# Changelog

**English** | [Português (Brasil)](CHANGELOG.pt-BR.md)

All notable changes to KG-SSOT are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases are tagged `kg-ssot-vX.Y.Z`.
The contract version (`v4.N`) is the version of the `.kg.yaml` / `.kg.json` contract that a release ships; it moves
only when the contract changes. Each release section is also the body of its GitHub release.
Releases before 4.16.0 are described in [ADOPTING.md](ADOPTING.md).

## [Unreleased]

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

[Unreleased]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.19.0...HEAD
[4.19.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.18.0...kg-ssot-v4.19.0
[4.18.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.2...kg-ssot-v4.18.0
[4.17.2]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.1...kg-ssot-v4.17.2
[4.17.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.0...kg-ssot-v4.17.1
[4.17.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.1...kg-ssot-v4.17.0
[4.16.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.0...kg-ssot-v4.16.1
[4.16.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.15.1...kg-ssot-v4.16.0
