# Changelog

**English** | [Português (Brasil)](CHANGELOG.pt-BR.md)

All notable changes to KG-SSOT are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases are tagged `kg-ssot-vX.Y.Z`.
The contract version (`v4.N`) is the version of the `.kg.yaml` / `.kg.json` contract that a release ships; it moves
only when the contract changes. Each release section is also the body of its GitHub release.
Releases before 4.16.0 are described in [ADOPTING.md](ADOPTING.md) (Portuguese).

## [Unreleased]

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

[Unreleased]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.2...HEAD
[4.17.2]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.1...kg-ssot-v4.17.2
[4.17.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.17.0...kg-ssot-v4.17.1
[4.17.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.1...kg-ssot-v4.17.0
[4.16.1]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.16.0...kg-ssot-v4.16.1
[4.16.0]: https://github.com/marciocar/kg-ssot/compare/kg-ssot-v4.15.1...kg-ssot-v4.16.0
