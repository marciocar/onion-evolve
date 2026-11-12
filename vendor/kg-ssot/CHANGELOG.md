# Changelog

**English** | [Português (Brasil)](CHANGELOG.pt-BR.md)

All notable changes to KG-SSOT are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases are tagged `kg-ssot-vX.Y.Z`.
The contract version (`v4.N`) is the version of the `.kg.yaml` / `.kg.json` contract that a release ships; it moves
only when the contract changes. Each release section is also the body of its GitHub release.
Releases before 4.16.0 are described in [ADOPTING.md](ADOPTING.md).

## [Unreleased]

## [4.50.0] - 2026-11-12

No contract change (still v4.21), and no verdicts of the contract change. What changes for an adopter: the `kg-mcp`
area policy, where a repeated key or a file larger than 1 MiB now makes the policy invalid; and `kg_gate.py --touched`,
which no longer counts the `kg_migrate.py methods` swap as a touch.

- `kg-mcp`: roles in the area policy, with a ceiling by role (item 1 of the first piece of the Company Brain). Two
  optional keys in `--area-policy`: `roles` gives each role `read` (the shared areas it reads), `write` (only `[]` or
  `["own"]`, the identity's own area: it restricts or declares, and never widens writing) and `ceilings` (a ceiling for
  an area the role reads, equal to or below the ceiling of the area); `members` gives roles to an e-mail or to every
  member of a group. A person's access is the union of the grants, and a group is the same as a role that reads the
  area with the area's ceiling. When two grants give different ceilings to the same area, the higher one wins, never
  above the ceiling of the area. With only `write: []` roles, `kg_write` and `kg_delete` leave the tool list and the
  own area is not created. The five read tools apply the ceiling of each person, with the same answer as a graph that
  does not exist. A malformed role (no area, an unknown level, a ceiling above the area's, a role that does not exist,
  a wrong type, a key repeated in the same object, a file larger than 1 MiB) makes the policy invalid, which closes
  reading as before; while it is closed, nobody writes if the last valid policy had `roles`. On load, stderr names each
  member (by e-mail, personal data in the operator's log) for whom another grant overrides a role ceiling. Without
  `roles`, the verdicts are those of 4.49.0 but one: a key repeated in the same object and a file larger than 1 MiB now
  make a policy without roles invalid too. The server does not start with such a file, and one already running closes
  on the next reload: check the policy before you update. No contract change.
- `kg_gate.py --touched`: the `provenance.method` class swapped between a Portuguese alias and its canonical English
  class (`medição`/`measurement`, `leitura`/`reading`, `juízes`/`judges`, `derivado`/`derived`,
  `testemunho`/`testimony`), with the detail after `: ` byte for byte the same, no longer touches a node, as the
  freshness stamp does not. A `kg_migrate.py methods apply` batch measured on a large corpus swapped 5,327 aliases and
  failed on 718 old debts it did not create. Any other change still touches the node, in the method too: another
  detail, another canonical class, a change of case, accent or spacing, or a provenance added or removed. The alias
  map now lives in `kg_validate.py`, which both tools read. `kg_migrate.py methods apply --manifest-out FILE.tsv`
  writes `graph`, `id`, `old` and `new` of each swap written, the receipt for the pull request. No contract change.
- Docs: in a sandbox where the user cache (`.cache` in the home directory) is read-only, run `kg_vendor.py update --verify-attestation` with `XDG_CACHE_HOME`
  pointing to a writable directory (ADOPTING and manual chapter 6).

### Added

- `kg_capture.py cloudevents`, in the maintainer's capture adapter, which is not part of the release: it reads
  CloudEvents 1.0 in structured JSON (one object, an array or JSON Lines, UTF-8 with or without a BOM, up to 64 MiB,
  from a file or from `-`, standard input) and writes PROV-JSON for `kg_capture.py prov`, which is still the step that
  proposes nodes. Each event becomes the activity `ce:<source>#<id>`, with `type` as `prov:type` and `prov:label` and
  `time` as `prov:startTime`; it used the `source`, the `subject` and the `dataschema`, when they come.
  - Identity: the same raw (`source`, `id`) pair in a batch becomes one activity (the first one wins), and stderr gives
    the count and, when the repeat differs in `type`, `time`, `subject` or a `--fields` value, the pair and what
    differs. In the ids, `%`, `#`, `|`, `~` and control characters are percent-encoded (a newline becomes `%0A`), so
    different parts never give the same id (the `dataschema` too). The userinfo, the query and the fragment leave the
    `source`, and the id then carries a `~<8 hex>` suffix, an HMAC-SHA256 of the raw `source`, so sources that differ
    only in what left stay apart. In labels, control characters become spaces.
  - The HMAC key is local: `--key-file FILE` (which wins) or `KG_CAPTURE_KEY`, at least 32 bytes once the spaces at the
    ends are trimmed and 16 distinct bytes (the error names the minimum, never the key; the minimum is about length and
    variety, not entropy: generate the key with `secrets`, do not type it), kept by whoever runs the capture, outside
    the graph and the repository. `--key-file` must be a regular file (a symlink is refused, not followed, and the file
    opened must be the one checked, so a FIFO swapped in does not hang), at most 4 KiB, outside the git tree of the
    working directory (the guard refuses only a file inside the git tree of the working directory; a file from another
    repository or a hard link passes), and it warns when the group or others can read it; an unsalted short hash would
    give a weak password or a short query back to a dictionary. Without a key, a batch where some `source` needs
    cleaning is refused (rc 2, fail closed); with no such `source`, no key is needed. The same key gives the same
    proposal; changing or losing it changes the suffix, and with it the ids of the next captures of those sources.
  - Data minimization covers `data` only: only the top-level fields named in `--fields` go in (none by default; a dot
    is part of the name, not a nested path), and only scalar values (up to 60 characters); an object or a list becomes
    `<objeto omitido>` or `<lista omitida>`. The raw body, `data_base64` and extension attributes never go in;
    `source`, `id`, `type`, `subject` and `dataschema` go in as they come.
  - Rejecting the whole batch (rc 2), naming each event: a missing `specversion` "1.0", `id`, `source` or `type`; a
    `source` that is not a URI-reference (its value is not echoed); a `subject`, `dataschema` or `time` that is not a
    non-empty string; a `time` outside the RFC 3339 form or impossible on the calendar (second 60 is accepted; second 60
    and the offset minute are checked only against the range that `datetime.fromisoformat` accepts, with no leap-second
    table); an empty batch. The 64 MiB ceiling is checked with `stat` before reading a regular file, and standard input
    or a FIFO is read up to the ceiling plus one byte and refused above it.
  - The proposals keep the sealed rules: born `open`, method `derived: runtime capture`, and the label says the event
    type and the source. A bench of 64 mutants, one per rule, all killed; the one for unindented lists needs the radar
    in the checkout.
- `kg_capture.py prov` writes the lists indented (`nodes:` / `  - id:`), the form the radar reads; a label that does
  not fit keeps the activity's name and cuts a long id in the middle, keeping its tail, so two steps with similar ids
  no longer get the same label. Text that is not valid UTF-8 (a lone surrogate) gives rc 2 in every subcommand,
  instead of a traceback or an empty file, and `--out` is written as UTF-8 with LF line endings on every system.

## [4.49.0] - 2026-11-11

Contracts v4.20 and v4.21, SHOULD only: no graph that passed fails.

### Contract v4.21

The plan for the `provenance.method` vocabulary, agreed with the first adopter and its curation repository. Two new
warnings, the same codes in both readers (Python and JavaScript), and 17 new cases in the suite (555 in `latest/`).

- The Portuguese class of `provenance.method` (`medição`, `leitura`, `juízes`, `derivado`, `testemunho`) still passes,
  and now warns as `form.deprecated.node.provenance.method`: write the class in English (`measurement`, `reading`,
  `judges`, `derived`, `testimony`). `form.deprecated` is a new kind of form code: in the JSON Schema, a `not` with the
  alias form and the `deprecated` keyword of the 2020-12 meta-data vocabulary, which only annotates. A value that
  already fails the form (an embedded quote, a class outside the list, no `: <detail>`) keeps only
  `form.pattern.node.provenance.method`, with no second warning, and `testemunho` still counts like `testimony` for
  `integrity.testimony-in-prod`. The alias leaves in v5, not before 2027-03-31, and only when the measurement on the
  first adopter and on its curation repository reaches zero.
- Provenance always: an `evidence` node without `provenance`, in any status except `unverifiable`, and a `decision`
  `done` without `provenance` warn as `form.required.node.provenance`, the code the MUST already gives a `confirmed` or
  `PROD` node. Same field, same fix, and the code stays the same when v5 promotes the rule. The MUST does not change. On a node where the MUST already flags that
  code, the reader does not repeat it as a warning; on another node of the same document it still warns, because
  the deduplication is per occurrence (code and path), so paying the MUST debt does not show up as new SHOULD debt.
- The suite fixtures that are not about the alias now write the class in English (293 files, only the `method` line
  changes), and 45 fixtures gained a `provenance`, so each case keeps testing what it tested. The five alias cases are now `warn-method-alias-*`.
- `kg_migrate.py plan` writes the English class when the profile still names the Portuguese one (`class:
  leitura` becomes `reading: <detail>`): a proposal with the alias would carry the new warning and go to review.
- The new debt, measured with `kg_validate` on the `.kg.yaml` graphs that the gate measures: on this repository (37
  graphs), the alias in 0 graphs and 0 occurrences (the 1230 aliases went to the English class with
  `kg_migrate.py methods apply`), and provenance always in 10 graphs and 102 nodes (98 `evidence`,
  4 `decision` `done`); on the first adopter, at the version this repository pins (239
  graphs), the alias in 205 graphs and 5318 occurrences, and provenance always in 60 graphs and 157 nodes (42 `evidence`,
  115 `decision` `done`); on its curation repository (75 graphs), the
  alias in 41 graphs and 433 occurrences, and provenance always in 29 graphs and 97 nodes (83 `evidence`, 14 `decision`
  `done`). No other code changes on the three, and no MUST verdict changes.
- **Your gate sees new debt.** When your graphs carry them, both are new SHOULD debt codes, so `kg_gate.py` fails
  after the update, with a baseline per graph or per node (`--granularity node`). Accept them as baseline with the reason, which keeps the
  ratchet against growth: `python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update --accept-regression "contract v4.21:
  the Portuguese method alias and provenance always, debt that already existed"`, or your own gate's equivalent. To pay the alias
  instead, `kg_migrate.py methods apply` swaps it for the English class. Demoting a node without giving it a source
  (a `confirmed` `evidence` to `open`, a `decision` `done` out of PROD) trades the MUST for this SHOULD on the same
  node and asks for `--accept-regression`; the path of the hints (`unverifiable`, or the decision's source as
  `testimony`) passes clean.

### Contract v4.20 and the rest

- Contract: the canonical profile `x_classification`, in `meta` only and judged only when present. It is the
  sensitivity level of the whole graph, as text in slug form (lowercase, digits, and hyphens), such as `confidential`.
  Outside that form it warns as `form.pattern.meta.x_classification`, and a value that is not text as
  `form.type.meta.x_classification`. The levels and their order belong to the organization and live in the policy of
  the server, not in the graph; the TLP 2.0 of FIRST is an example of mapping in the manual, not the standard. On a node,
  `x_classification` warns as `form.misplaced.node.x_classification`, a new kind of form code: the unit is the graph, and
  a node more sensitive than its graph goes to a graph of its own. Both readers emit the same codes, and the suite has
  14 new cases (538).
- `kg-mcp`: the ceiling by area. The area policy takes three optional keys that come together: `levels` (the ordered
  levels), `ceilings` (each shared area to its highest level), and `default_level` (the level of a graph without
  `x_classification`). In an area with a ceiling, a graph above it, or with a level that `levels` does not know, leaves
  `kg_list`, `kg_get` (with `ref` too, where the current and the asked version are both judged), `kg_history`,
  `kg_query`, and `kg_terms`, and answers like a graph that does not exist; the edges and pointers to it leave with the
  area filter's cut. The identity's own area has no ceiling, and without `ceilings` nothing changes. The label is a
  marking the policy enforces, not access control node by node, and the git history still holds a node that was moved
  to another file.
- `kg_gate.py --sources`: the gate also runs the source check of `kg_trace.py check --strict-sources` on the `.kg.yaml`
  graphs it measures, with its own excludes, and fails (rc 1) when a cited `sha256` or `node_sha256` does not match, a
  locator read by its `scheme` is not found, or the cited file is gone from git. With `--touched`, only the changed graphs
  and the nodes whose cited source changed. No network: a URL source is counted as not checked. Off by default, so
  nothing changes for an adopter that does not turn it on.
- Security fix in `kg_trace.py`: inside a git repository, a `provenance.source` is read only from the index. Before, a
  node could name `.git/config/.` (where `actions/checkout` keeps the token), a file the CI created, or a tracked file the
  CI rewrote, and a `quote` locator turned it into a yes or no in the log. Now what is read is the blob in the index, never
  the disk, and a source that is not in the index is missing, whether or not the file exists on disk, with no look at the
  history. A path with a `.git` segment in any case, or with a `.` or `..` segment, is counted in `outside_root`, and a
  file in a submodule that is not checked out, or a tracked link that leaves the root or points into `.git`, is counted in
  `schemes.skipped.untracked`; none of them is read, and the same goes for a JSON locator reached through `trace:`. The
  `untracked` key appears only when it is above 0, so an output without one still validates against the 4.48 schema.
  What a local user can see change: a cited source that has not gone through `git add` now counts as missing (rc 4 with
  `--strict-sources`; before, it was read from the disk), a generated or ignored file counts as missing too (leave those
  graphs out with `--exclude`), and a file edited without `git add` is judged by its version in the index, which also
  applies to the pins that `kg_query --revisit` compares. Measured with the 4.48.0 `kg_trace check` against this one, with
  and without `--strict-sources`: on this repository, with the default excludes and with `--no-default-excludes`
  (1 source read, 30 missing, 5 JSON locators missing), and on the first adopter (4 JSON locators read), the rc and every
  count are the same, because every cited source there is tracked and unchanged on disk. The check reads the index once
  per run: on the first adopter it took 6.9 to 7.9 s against 6.4 to 6.8 s before.
- `kg_migrate.py methods plan|apply`: swaps the Portuguese alias of the `provenance.method` class (`medição`,
  `leitura`, `juízes`, `derivado`, `testemunho`) for the canonical English one, by text, so a graph pays the alias that contract v4.21 now
  warns on. Only the class changes; the detail after `: ` stays byte for byte, and comments and quoting stay. The
  tail (a value that starts with a quote inside the string, a class outside the list, no `: ` after the class,
  uppercase in the class) is only pointed out. `apply` writes under the same checks as `keys`, and `--confirmed-out`
  lists the `confirmed` nodes touched. No contract change, and no verdicts change.

## [4.48.0] - 2026-11-09

No contract change (still v4.19), and no verdicts change. Everything here applies only when you ask for it.

- `kg-mcp`: the area filter (`--area-policy FILE`, on top of `--identity-header`). A JSON file outside the root names the
  shared areas each identity reads: the canonical one and the groups it belongs to. Reading is the union of the identity's
  own area and those areas, whose graphs appear as `@<area>/<graph>`, and only those areas are opened. An edge with an end
  that no readable node resolves leaves `kg_get`, `kg_list`, `kg_history`, `kg_query`, and `kg_terms` whole, with no id, no
  file, and no count, and so does a pointer to such a graph in `provenance`, `trace`, `verified_against`, `verified_scope`,
  or `reverify_on`. Writing stays in the identity's own area. Without the flag, nothing changes. An id written in free text,
  in an `x_` field, or in a commit message is not filtered.

## [4.47.0] - 2026-11-09

No contract change (still v4.19), and no verdict changes. What a consumer can see: `kg-mcp` may withhold a text, the
default output of `kg_prov_export.py` now carries the value of `sealed_by` and `owner`, and the release assets gain the
vendor manifest (`<tag>.vendor-manifest.json`). The other additions apply only when you ask for them.

- `kg-mcp`: the content screen (`tools/kg_screen.py`). Every text returned by the tools that read users' content
  is screened; a text with concealment and an instruction together is withheld, and anything found is listed in a new
  `kg_screen` key. A `pass` does not cover homoglyphs, encoded payloads or other languages.
- `kg_trace projection`: a page that declares `projection_faithful: true` has every prose block checked, and a block
  that cites no node id (nor sits under a heading that cites one) is listed in `unanchored`
  (`integrity.projection-unanchored`) and fails. Opt-in per page; additive in `kg-ssot.projection/1`.
- `kg_prov_export.py` emits `prov:Agent`: `sealed_by` as `prov:wasAttributedTo` (role `kg:SealerRole`) and `owner` as
  `prov:wasInfluencedBy` (role `kg:OwnerRole`), each with its qualified form. `owner` is not an attribution because
  attribution in PROV implies taking part in generating the entity. The default output changes only for nodes with
  those fields, and it now carries their values, which `--full` already did: keep `sealed_by` a role or a reference.
- `kg_vendor.py update --verify-attestation`: the vendored tree must match a manifest the release attested
  (`<tag>.vendor-manifest.json`, new in the release assets from this version on), or the update gives rc 2 and leaves
  the vendor untouched. Optional, since it needs `gh` and the network; the stamp records it and the next update
  inherits it.
- `kg_gate.py --touched <base>`: a CI mode, with no baseline, that fails only when a node touched since the common
  ancestor of `<base>` and `HEAD` carries `integrity.bare-decision` or `integrity.superseded-without-successor`. Old debt
  stays accepted until someone works on that node, and re-stamping `verified_at` or `verified_against` alone does not count. Needs the git history (`fetch-depth: 0` on GitHub Actions).

## [4.46.0] - 2026-11-09

Contract v4.19, SHOULD only: nothing that passed fails, and no MUST verdict changes.

- Two new warnings in both readers (Python and JavaScript), with 12 new cases in the suite (524 in `latest/`):
  `integrity.bare-decision`, a decision `done` with no `narrative` and no `SUPPORTS` edge reaching it (closed without
  saying why or on what it rests), and `integrity.superseded-without-successor`, a `superseded` node that no
  `SUPERSEDES` edge reaches (the graph does not say what replaced it). Both count the edge declared in the graph
  itself, local or in `external_edges` with an external `from`, with or without the corpus.
- `kg_trace projection` lists `superseded_cited`: an id cited by a page that resolves only to `superseded` or
  `refuted` nodes of its graphs. It is a warning, the rc does not change, and the key is additive in
  `kg-ssot.projection/1`.
- Six older suite fixtures gained a `narrative` or a successor, so each keeps testing what it tested.

## [4.45.0] - 2026-11-07

No contract change (still v4.18), and no verdict changes. Nothing that a reader, the gate or the store prints changes.

- Every artifact of the release has an SBOM in CycloneDX 1.7 JSON: the wheel and the sdist on PyPI, the npm tarball, the
  MCP Bundle and the OCI image. Each `<artifact>.cdx.json` is attached to the GitHub release and attested with the
  CycloneDX predicate (`gh attestation verify <artifact> --repo marciocar/kg-ssot --predicate-type
  https://cyclonedx.org/bom`); the image SBOM is also attested in the registry. It lists the dependencies that the
  artifact declares, read from inside it, as external (`isExternal`, with the declared range in `versionRange`), with
  the license, the tested version and the transitive dependencies of the environment where the suite passed. The
  bundle SBOM lists every package of its `uv.lock`, with the hash of each file, and the image SBOM lists the base
  image by digest, its Debian packages (with the source package in the purl `upstream` qualifier, which is how a scanner
  finds the Debian advisory), the Python interpreter (with its CPE) and every installed Python distribution. A declared
  range carries no purl: a purl without a version would match every version in a scanner. On grype 0.121.2 the image
  SBOM gives the same 189 matches as syft's, and the wheel, sdist, npm and bundle SBOMs give none below the declared
  range.
- The build lockfile of the JavaScript reader moves `fast-uri` to 3.1.9, within ajv's range.
- The generator is `packaging/sbom/sbom.py`, with the Python standard library only, and it ships in the release. It
  refuses an artifact that embeds third-party code (`node_modules`, `site-packages`, a wheel inside a package): none
  does today, and the SBOM's claim is checked on every release.
- `SECURITY.md` is new: only the latest release gets security fixes, reports go through GitHub Private Vulnerability
  Reporting on the public repository (no e-mail), with acknowledgement within 7 days, a first assessment within 14
  and a fix within 90, the scope, and a 90-day coordinated disclosure.
- The release hygiene fails a release without `SECURITY.md` (with its five sections and the private channel), without
  the generator, or with a release workflow that does not generate, attach and attest the SBOM of each artifact.
- The manual has a new section, "Verify a release: provenance and SBOM", in chapter 6.
- **The recommended shape of `x_event`, not normative** ([manual, chapter 3](docs/manual/03-format.md#recording-an-external-event-recommended-shape-not-normative)).
  An external event is an `evidence` node whose `x_event` uses the CloudEvents 1.0 core names (`id`, `source`, `type`,
  `specversion: "1.0"`, and optionally `subject`, a quoted RFC 3339 `time`, `datacontenttype` and `dataref`). The
  collector records the body as a file that `provenance.source` and `provenance.sha256` point to; `x_received_at` is
  apart from `time` and `verified_at`; `source` + `id` is the idempotency key; without a checked signature the node
  stays `open`. With a complete example that passes `kg_validate` and `kg_trace check`. The contract does not change
  (still v4.18): with two adopters, or 50 real nodes in this shape, it becomes a canonical profile in the SHOULD.
- **The recommended shape of `x_change`, not normative** ([manual, chapter 3](docs/manual/03-format.md#recording-a-planned-change-recommended-shape-not-normative)),
  the sibling of `x_event`. A planned change to a system, a policy or a process is a `decision` whose `x_change` has
  `state` (`planned`, `communicated`, `applied`, `verified`, `reverted`), `target`, a quoted RFC 3339 `window`,
  `rollback_plan` (a pointer), and optionally `kind` (the ITIL 4 types), `ref` and `communicated_by` (the `evidence`
  with the `x_event` of the notice). Each transition is an `evidence` with `x_change_transition` (`to`, `at`) that
  `SUPPORTS` the decision; `verified` needs a `measurement`, and a reversion `SUPERSEDES` the application it undoes.
  Who approved goes in `sealed_by`, by reference, never by name. `kg_query --where x_change.state=applied` lists the
  changes by state. With a complete example that passes `kg_validate` and `kg_trace check`. The contract does not
  change (still v4.18): with two adopters, or 50 real nodes in this shape, it becomes a canonical profile in the SHOULD.
- Why: a buyer subject to the EU Cyber Resilience Act owes due diligence on the free components it integrates, and
  will ask for an SBOM and a vulnerability policy. The maintainer of a free project outside commercial activity has no
  legal duty here; the release ships both anyway.
- **Personal data, LGPD and GDPR** ([ADOPTING.md](ADOPTING.md#personal-data-lgpd-and-gdpr)): a new section on erasure
  by design, with no contract change. The adopter is the controller of the personal data in the graph and in its git
  history, and the tools send the graph to no one on their own; a person enters by reference, with the table that maps
  the reference to the person kept out of git, and the reference stays pseudonymous personal data while that table
  exists, so `label` and `narrative` must not identify the person either; a `node_sha256` published over a node that
  can identify a person is itself personal data and stays out of a public mirror (a salted hash is not in the contract
  yet); no public mirror holds personal data; rewriting history breaks hash verification and does not reach forks or
  archives; `owner` is a role; and an account handle or a machine path with a user name is personal data too.

## [4.44.0] - 2026-11-05

No contract change (still v4.18), and no verdict changes. `kg_query` prints the same, and `kg_trace check` without `--strict-sources` keeps its exit codes and, in a corpus without the form `repo#id@commit`, the same `kg-ssot.trace/1`.

- `kg_refs.py` (`kg-refs`) is new, with a new output, `kg-ssot.refs/1` (`spec/refs.schema.json`). It reads a declared list of
  local clones (`--repo NAME=FOLDER`, or `--repos FILE`), only from git objects, without network. `cited-by REPO:ID` says who
  cites a node, in any node field and in which form, and `--at NAME=COMMIT` reads an earlier state. `pins` compares each
  citation to another repository of the list, at its pinned commit, against the tip: `same`, `changed` (`status`, `text`,
  `edges`, `file`, `stamp_only`, `other`, with the current status of the node), `gone`, `ambiguous` or `unchecked`, which also covers a graph that writes the id and does not read, and objects missing, as in a partial clone. `--from REPO`
  and `--status gone,changed` only cut what it lists; the scan, `summary` and the rc stay those of the whole list, with `gone` and
  `status` first.
- It is a query, not an alarm: a change never alters the exit code, and no option makes it. Every output has `scanned` and
  `not_scanned`, because an empty answer does not prove absence: rc 0 complete, rc 3 partial (a folder missing or unreadable, no graph read where one was needed, because the file rules took them all out, an `--at` read a state with none, the `cited-by` target has none or the whole scan has none, a pinned commit missing in any form, a `--known` repository with no folder, a name
  cited with a commit outside the list), rc 4 only in `pins`, on a complete scan, when something is `ambiguous` or `unchecked`, and
  rc 2 without a declared list. `--known NAME` declares the network, with a folder or without one: with it, the names outside go to
  `mentioned_undeclared` and their citations with an id to `outside_citations`, without changing the rc. `cited-by` also lists who cites the whole file that contains the node
  (`contains_file`).
- `kg_trace check` counts `provenance.source` in the form `repo#id@commit`, without changing any rc: when the form occurs, a new line
  in the human output and `schemes.repo_refs` in the JSON, which is then `kg-ssot.trace/2`. `--strict-sources` lists each source with a
  scheme or a sha256 that is absent and gives its own rc, 4, with `kg-ssot.trace/2` too; a source with neither is not judged, and that
  includes a URL with a commit and no hash.
- The limit: it finds a wrong citation, not a missing one. It reads node fields and the folders you list, and it says nothing
  about a repository you have no folder for; it has not been tried by a third party without access to them.
  Why: the five losses measured in 157 citations across three repositories were an answer nobody looked up, not a broken file.

## [4.43.0] - 2026-11-04

No contract change (still v4.18), and no verdict changes. A query that worked in 4.42.0 prints the same `kg-ssot.query/1`, except for the two new refusals at the end of this list.

- `kg_query --due [--as-of YYYY-MM-DD]` lists the nodes of any type whose `verified_at` plus `reverify_every` is due, the
  most overdue first, with `due_on` and `days_late`. The sum is that of `kg_validate --due`, called, not copied; what that
  report adds for `x_term`, `x_mirror` and `x_doc_cycle` stays there. Only this query prints `kg-ssot.query/2`: the schema
  is closed and the new fields need a new version. A consumer that uses `--due` and checks `schema_version` should accept `/2`.
- The node `--where` and `--group-by` take the degree derived from the internal edges of the node's graph: `degree.in`,
  `degree.out`, `degree.total`, with an optional edge type. `--where degree.in.SUPPORTS=0` finds the nodes with no internal
  `SUPPORTS` edge in their own graph. A `SUPPORTS` from another graph is not counted: complete it with
  `--edges --where edge_type=SUPPORTS --where scope=external`; every answer with the degree says so in its `hint`. An edge
  type that no internal edge has counts 0 with a
  `hint`, and in `--revisit`, which has no `hint`, it is refused (rc 2).
- `--has FIELD` and `--missing FIELD` (repeatable, a dot for a nested key) test any field of a node. A missing field and
  `null` are the same; empty text and `0` have a value. Only when asked, the request echo gains `has` and `missing`. A path
  that no node of the corpus has with a value gets a `hint`, and a path that starts with `degree` is refused (rc 2).
- `--group-by` takes `label` and `narrative`, with the whole text: with `--min-count 2`, the nodes with the same text.
- `--where` takes `KEY^=VALUE` (starts with) and `KEY*=VALUE` (contains), for nodes and edges: case-sensitive, in NFC, and
  only text matches, as Cypher's `STARTS WITH` and `CONTAINS`. After the `=`, the value is literal.
- `--chain` is repeatable, up to 50 ids, and more than one prints the new `kg-ssot.chains/1` (`spec/chains.schema.json`):
  one `kg-ssot.chain/1` per id, with the status of each origin. One id still prints `kg-ssot.chain/1`.
- The MCP `kg_query` tool takes `due`, `as_of`, `has`, `missing` and `chain`, and its description gives the new grammar.
- The `kg_query --help` no longer describes the tool as of release 4.17.
- New refusal: a `--where` key that still ends in `^ * $ ! < > ~ |` after the operator is read is rc 2, for nodes and edges.
  `x_n!=12` used to look for a key named `x_n!` and answer 0 without a word; no real key ended that way in the corpora measured.
- New refusal: the MCP `kg_query` tool with `edges` no longer takes `open`, `in_narrative` or `narrative`, which it used to ignore.
  Why: how many finished decisions have no internal `SUPPORTS` edge, a question no single query answered, now comes out of
  one, with the same 14 as an answer key and an independent count on a real corpus.

## [4.42.0] - 2026-11-04

No contract change (still v4.18), and no verdict changes. `kg-ssot.query/1` does not change.

- `kg_query --edges` counts and lists edges instead of nodes: the internal and the external ones. `--where` and
  `--group-by` take `edge_type`, `scope`, `file`, `meta.<key>`, and `from.<field>` and `to.<field>` (`id`, `file`,
  `found`, `node_type`, `status`, `plane`, `layer`, `owner`, `x_*` or `provenance.<key>`). Without `--group-by` it
  prints the paged list `kg-ssot.edges/1` (`spec/edges.schema.json`).
- `--count-distinct FIELD` (repeatable) counts the distinct values or combinations in each group; a null value does not
  count, as in Cypher's `count(DISTINCT)`, and neither does a combination with any null, as in SQL's
  `COUNT(DISTINCT a, b)`; `--min-count N` keeps the groups from N, as SPARQL's `HAVING`. Both work for nodes and
  edges. Together they give the in-degree of a node from distinct sources.
- The node `--where` and `--group-by` take `provenance.<key>`, such as `provenance.locality`.
- The grouped output moves to `kg-ssot.groups/2`: it gains `subject` (`nodes` or `edges`) and `counted` (`rows` or
  `distinct:<fields>`), and a distinct count can be 0. A consumer that checks `schema_version` should accept `/2`.
- The MCP `kg_query` tool takes `edges`, `count_distinct` and `min_count`.
  Why: in the curation's bench of 15 counting questions over a corpus, five more now come out of `kg_query` alone,
  equal to the answer key (counts by edge type, in-degree, external targets, provenance and supersession).

## [4.41.0] - 2026-11-03

No contract change (still v4.18), and no verdict changes. `kg-ssot.query/1` does not change.

- `kg_query --group-by FIELD` counts the nodes a query finds, by the value of a field, instead of listing them: `file`,
  `node_type`, `status`, `plane`, `layer`, `owner`, an `x_*` field (a dot for a nested key) or `meta.<key>` of the
  node's graph, repeatable up to 5 for the combination. The filters apply first, every group comes out without pages,
  a missing field is its own `null` group, and the counts add up to `total`. The output is the new
  `kg-ssot.groups/1`, with its schema in `spec/groups.schema.json`. The MCP `kg_query` tool takes the same fields in
  `group_by`. It does not combine with `--semantic`, `--cursor`, `--decision`, `--chain` or `--revisit` (rc 2).
  Why: in a test where an agent answered 15 counting and filtering questions over a corpus, it wrote code over the
  YAML instead of using `kg_query`, which skips the reader of the contract. The in-degree of a node is not covered yet.

## [4.40.2] - 2026-11-03

No contract change (still v4.18), and no verdict changes.

- The manual shows how to count every owner's queue from one query: the JSON output of `kg_query --open` carries `owner`
  only when asked, with `--fields owner`, which returns it in each node's `extra`, with `--limit` up to 1000 and `next_cursor` past that.
- A term in force is `confirmed` with the `provenance` of its source. The term example in the manual and the terms of
  `spec/vocab-examples/cmed-dictionary.kg.yaml` were `open`, which put settled definitions in the queue of open nodes.

## [4.40.1] - 2026-10-30

No contract change (still v4.18), and no verdict changes.

- The README and the package descriptions on PyPI, npm, the MCP Registry and the MCPB bundle now say what KG-SSOT is
  for: the trust layer for a company brain, where a confirmed claim cites its source, a decision records what it
  replaced and what it rests on, and a decision comes back for review when a source it pinned by hash changes. A new section maps each need to the
  command that answers it.
- The manual has a recipe for an external event (an e-mail, a chat message, a wiki edit) that arrived by a signed
  message: an `evidence` node with the CloudEvents 1.0.2 names in `x_event`, pinned to the accepted inbox document.
- `kg-query --revisit --help` now names the reasons it really uses, including `pin-changed`; it named a refuted or
  superseded support, which was never a reason (4.36.0 left it out before the release).

## [4.40.0] - 2026-10-30

No contract change (still v4.18). An approved document now comes back to the review queue when it changes.

- `kg_query --revisit` gains the `pin-changed` reason: a live decision comes back when a support, or the node that
  support cites by `kg-node` one step away, no longer matches the version it was pinned to, by
  `provenance.node_sha256` (the node was rewritten) or by `provenance.sha256` (the text of the file changed without
  touching the graph). It is the same check as `kg_trace check`, and the item says what changed, which pin, the
  recorded hash and the current one; a pinned node that disappeared from its document fires too, with `current`
  null. A pin that cannot be checked goes to `unresolved` (`pin_malformed`, `pin_source_missing`, `pin_unchecked`).
  Pins are checked with `--root`; a support read through `--with` is not checked yet. This is the approval of a controlled document: the decision is the testimony, and an
  evidence that supports it pins the approved version. The JSON is now `kg-ssot.revisit/2`.
- `kg_trace.py digest` takes a batch: a file that does not exist is `file_missing`, and a file that is not UTF-8 is
  `unreadable` with `code` `encoding.not-utf8` (or `io.unreadable`), each as the result of its own reference, and the batch goes on (rc
  1). Only a path outside the root, or a reference without `FILE#ID`, stops the batch with rc 2. The schema now ties
  `node_sha256` to `ok`. The JSON is now `kg-ssot.digest/2`.
- From now on, a JSON output with a closed schema that gains a value or a field moves to a new schema version. The
  4.39.1 widened `kg-ssot.digest/1` in place, which broke a consumer that validated strictly against the 4.39.0
  schema; it stays as published, and this release names the change.

## [4.39.1] - 2026-10-29

No contract change (still v4.18).

- `kg-trace digest`: a graph that does not parse is now `unreadable`, with the reader's `code` (text: `UNREADABLE
  FILE#ID CODE`), and no longer `not_found`. The node was not looked for, so it is not missing. The exit code stays 1.
  Found in a field test of 4.39.0.

## [4.39.0] - 2026-10-29

No contract change (still v4.18). When several long-lived sessions share one coordination graph, each with its
`owner`, each one opens with its own queue.

- `kg_query --where KEY=VALUE`: only the nodes where `owner` or an `x_*` field (a dot for a nested key, such as
  `x_raci.responsible`) has the value; a list matches when one of its items does, and the conditions add up. It works
  with `--open`, the other filters and `--revisit`, which then judges only the matching decisions; the JSON echoes the
  conditions in `where`, and the MCP `kg_query` tool takes the same filter. On the Onion core, the queue of each of its
  five owners matches an independent count exactly.
- `kg-trace digest --format json` returns `kg-ssot.digest/1` (`spec/digest.schema.json`), with `node_sha256` and a
  `status` per reference, so nobody has to split the text line. With a broken input, `digest` now stops before
  printing any result, in both formats (it used to print the good lines before the error).
- Left out before any code, with the trigger written: turning a REFUTES between graphs of different verticals into a
  `question` with an owner (no such edge exists yet in the corpus it was meant for), and a `--due` listing of overdue
  nodes of any type (no overdue cadence there yet).

## [4.38.0] - 2026-10-28

Contract v4.18, SHOULD only: nothing that passed fails. A company brain spans several repositories, and a decision in one
rests on a seal in another. This release reads that support where it was pinned, says when its source moved, and gives a
bridge to a node a hash that only that node can break.

- `kg_query --revisit` and `--decision` accept `--with PREFIX=FOLDER`: a support given by a `provenance.source` URL is
  read at its pinned commit from a local clone. `--revisit` judges only local decisions, and a support that does not
  resolve carries its reason (`no_with`, `not_found`, `not_pinned_url`, `unpinned`, `outside_corpus`); a support read
  without a real pin is never judged against the working tree.
- `upstream_changed` lists, apart and never as a reason to revisit, the local decisions whose support has another
  status, or is gone, at the head of the clone; `--decision` shows that status as `head_status`.
- `provenance.node_sha256` is the SHA-256 of the RFC 8785 (JCS) canonical form of the cited node, with `scheme: kg-node`:
  a change in a neighbor node of the same file does not break it. `kg_trace check` compares it
  (`integrity.trace-node-sha256-mismatch`), `kg_trace.py digest FILE#ID` prints it, and the JavaScript reader exports
  `nodeCanonical`. There is one JCS in the product, the strict one of `kg_criterion`, and a node with no JCS form
  (a repeated id, an integer value outside ±(2^53−1)) counts as `not_canonical` instead of failing.
- `kg_trace` no longer emits the Python 3.15 `DeprecationWarning` of a positional `maxsplit`.
- The conformance suite goes from 508 to 512 cases.

## [4.37.0] - 2026-10-28

Contract v4.17, SHOULD only: nothing that passed fails. A claim already says where it came from; now it can say exactly
where in the source, and keep a hash of what it read, so a tool can check both.

- `provenance.scheme` says how to read the locator: `json-pointer` (RFC 6901), `text` (RFC 5147, positions from 0,
  characters as code points and each line ending as one), `csv` (RFC 7111, one kind of selection, from 1), `pdf` (RFC
  8118, the physical page from 1), `media` (Media Fragments, npt, the end excluded), `quote` (the exact text), `html`
  (`#id`) and `kg-node` (a node of the graph named in `source`). The W3C Web Annotation `conformsTo` URIs count as
  aliases, including the RFC 3778 one. A locator that does not fit its scheme warns as
  `form.pattern.node.provenance.locator`.
- `provenance.sha256` is the SHA-256 of what was read, in its own field (`form.pattern.node.provenance.sha256`);
  `kg_trace` hashes a repository source as git stores it, so the hash is the same on Windows and on Linux.
- `kg_trace check` reads the source by its scheme and hash: the line, character, row, column, quote, node or JSON
  Pointer exists, and the hash matches (`integrity.trace-locator-out-of-range`, `integrity.trace-quote-missing`,
  `integrity.trace-sha256-mismatch`). With `--with PREFIX=FOLDER`, a source given by URL is read at its pinned commit
  from the root of a local git clone; a commit the clone does not have, or a folder that is not the root of a clone,
  is never read from the working tree, and a branch name (`main`) counts as `unpinned`. What is not judged is counted
  (`form_only`, `unpinned`, `malformed`, `not_json`, `not_text`), never as ok. The JSON output gains `schemes`.
- The JS reader exports `textInRange`, which counts code points and line endings like the Python reader. The
  conformance suite goes from 463 to 508 cases.
- The open tension between two claims, planned for this release, was measured against its pre-registered criterion and
  left out (2 of 10 with a blind evaluator, against a floor of 3).

## [4.36.0] - 2026-10-28

Contract v4.16, unchanged. A graph already keeps the history of its decisions: a new decision supersedes the old one,
a refutation keeps the refuted node, and nothing is deleted. This release makes that history something you can ask.

- `kg_query --sort attention` orders nodes by their weight on the radar, `impact × confidence × status factor × (1 +
  degree)`, with the degree scoped to the node's file and ties broken by id in descending order, so it gives the same
  queue as the radar of the framework where the format was born on a graph that passes the MUST.
- `kg_query --decision <id>` gives the history of a decision: what it replaced and what replaced it along the whole
  `SUPERSEDES` line, what refutes and supports it, and what it rests on, with the status of each
  (`kg-ssot.decision/1`).
- `kg_query --revisit [--as-of DATE]` lists the live decisions to revisit, by attention, with the reason:
  `evidence-due`, `review-due` or `contested`, where the support is what reaches the decision by `SUPPORTS` and what it
  traces to or depends on; a support that was refuted or superseded is history shown by `--decision`, not a reason; decisions that wait for an event, have a cadence
  but no stamp, or rest on something outside the corpus are listed apart (`kg-ssot.revisit/1`).
- `kg_trace.py projection`: an id of a page whose declared graph does not read is no longer `missing`; the graph error
  still fails the page.

## [4.35.0] - 2026-10-27

Contract v4.16, unchanged. **Python 3.12 or later** (it was 3.11): the package, the MCPB bundle and the docs say so, CI
runs 3.12, 3.14 and 3.15, and the optional `vector` extra stops at 3.14 until `onnxruntime` ships for 3.15.

- `kg_query --chain --with PREFIX=FOLDER` follows a `provenance.source` URL into a graph of another repository, read
  only, at the commit the URL cites when the folder has it (`pinned`), otherwise from the working tree with a warning.
  A ref that is absent, or a file that is not at it, gives a broken link; a ref that starts with `-` is refused.
- `kg_trace.py projection` checks Markdown pages that declare `projection_of` in their front matter: each node id they
  cite between backticks is `resolved`, `elsewhere` (a warning), `outside` (in another repository not read) or
  `missing` (`integrity.projection-id-missing`, rc 1). Contract words and `projection_ignore` are counted apart.
  `--format json` gives `kg-ssot.projection/1` (`spec/projection.schema.json`).
- `kg_trace check` follows a JSON Pointer `provenance.locator` (`#/a/b`) inside the `.json` file the node's source
  names: `integrity.trace-locator-missing` and `integrity.trace-locator-unreadable`, rc 1. The output gains
  `locators`, additive.
- `kg_hygiene` fails a release file that still cites the old Python floor.

## [4.34.0] - 2026-10-27

Contract v4.16, unchanged. `kg_query --chain` follows `provenance.source` first: a node with a `provenance.source`
takes only its `#<id>` fragment as the next step, and a `source` that names no graph node makes the node the origin,
whatever edges leave it. Edges (`TRACES_TO`, or `--edge-type`) are followed only for a node with no
`provenance.source`, and the ones a node's provenance leaves out are named (`edges_not_followed`). An origin with no
`provenance.source` comes out with `declared: false` and makes the chain `weak` in both modes. Found in a field test
on real graphs: a decision sealed by its owner that traces to the question it answers showed up as the first link of
the question's history instead of the origin.

## [4.33.0] - 2026-10-27

Contract v4.16, unchanged. `kg_query --chain <id>` projects the transmission chain from a node back to its origin: each
path in edge order (`TRACES_TO` by default, `--edge-type` for others), and the `provenance.source` fragment when it
names a node of a graph. Each path carries a status (`complete`, `broken`, `cycle`, `too_long`), the weakest link and
the strength of the origin on separate axes, and two grades: strict, which counts the origin, and lenient, which leaves
it out. A broken, cyclic or too long chain is `weak` in both modes, and a link with no numeric `confidence` is the
weakest one. The output is human or `--format json` (`kg-ssot.chain/1`), with caps of 200 steps and 1000 paths. The
criteria were committed before the code, and the projection passes them on the probes of an outside session.

## [4.32.0] - 2026-10-27

Contract v4.16: the class of `provenance.method` has a canonical English form, `measurement`, `reading`, `judges`,
`derived` and `testimony`, and the five Portuguese words (`medição`, `leitura`, `juízes`, `derivado`, `testemunho`)
stay accepted as aliases, with no warning. `testimony` and `testemunho` count the same for
`integrity.testimony-in-prod`, in the Python and the JavaScript readers. The examples, the agent skill, the
`kg_schema_help` example (now `spec/examples/minimal.kg.yaml`), `kg_capture.py` and the demo use the English form; six
new conformance cases (463 in `latest/`). No existing graph changes its verdict, except a PROD node that already
used `testimony:`, which now gets `integrity.testimony-in-prod` (see ADOPTING.md).

## [4.31.1] - 2026-10-27

The documentation site renders code blocks and diagrams: without declared Markdown extensions, Zensical left the fenced
code of the README and the manual as raw backticks. `zensical.toml` now declares them, and the site check in CI fails on
raw Markdown in the HTML. The README's first links are now one Documentation link to the site, in place of a separate docs-site
link and a manual link that opened the same pages. Contract v4.15, unchanged.

## [4.31.0] - 2026-10-26

A documentation site at https://marciocar.github.io/kg-ssot/, built from the README, the adoption guide, the changelog
and the manual by `tools/kg_site.py` and Zensical, and published to GitHub Pages by the release workflow; a 40-second
demo in the README, recorded from `docs/demo/demo.sh` and listed in the new `mirror_only` of `spec/release.json`, so it is
published in the public repository and on the site but not vendored by adopters. The README and the manual counted the conformance suite as 438
cases while `latest/` had 457; the count is fixed and the hygiene check now ties it to the suite manifests. Contract
v4.15, unchanged.

## [4.30.0] - 2026-10-26

The release carries the agent skill `skills/kg-ssot/` (Agent Skills format) and a Claude Code plugin marketplace in
`.claude-plugin/`. In a pre-registered test, agents with the skill matched the agents without it (12 of 12) with 45%
of the output tokens and 54% of the tool calls. Contract v4.15, unchanged.

## [4.29.1] - 2026-10-26

`kg_prov_export.py` no longer emits a broken IRI for a malformed edge end. Contract v4.15, unchanged.

### Fixed

- **`kg_prov_export.py` no longer emits a broken IRI for a malformed edge end.** With `--edges` or `--full`, an end
  that was neither a valid node id nor an external reference (an absolute path, for example, which the contract
  rejects) became a local IRI with `/` or a second `#`. rdflib kept that triple, but pyoxigraph and pyrudof dropped it
  without an error, so the same output became different graphs depending on the reader. Such an end now goes as the
  literal `kg:fromRef` or `kg:toRef`. Found by a dissection of the RDF readers in another repository that uses KG-SSOT.

## [4.29.0] - 2026-10-26

The `rdf` extra brings rdflib to read the PROV export, with a CI job that rebuilds every edge from the RDF; and
`kg_prov_export.py --full` exports the whole document, so the loaded YAML can be rebuilt from the RDF. Contract v4.15,
unchanged.

### Added

- **`kg_prov_export.py --full` exports the whole document.** It implies `--edges` and also carries every field of
  every node and of `meta` as `kg:<key>` (text as a literal, anything else as JSON typed `kg:json`). So the loaded YAML
  can be rebuilt from the RDF, for SPARQL or SHACL over the same data. Measured against criteria registered in
  advance:
  - **Correctness:** structural equality of the loaded YAML in 209 graphs.
  - **Cost:** 0.25 s and 19.7 MB for the whole core corpus on a CI runner, against ceilings of 10 s and 100 MB.

  A first series failed on a ceiling of 3 times the plain export: the real ratio is about 3.6. That ceiling was
  replaced, after the result, by absolute ceilings set knowing the cost was about 1 s. The measurement page says so,
  and the code was frozen before the second series ran.
- **The `rdf` extra.** `pip install "kg-ssot[rdf]"`, or `tools/requirements-rdf.txt` with hashes in the vendor,
  brings rdflib, to read the `kg-prov-export --edges` output in RDF tools. It stays out of the gate profile. A new CI
  job reads the `--edges` output of every valid suite case and of the repository's graphs, rebuilds every edge from
  the RDF alone, checks the standard triples, and serializes to N-Triples.

## [4.28.0] - 2026-10-25

`kg_prov_export.py --edges` exports the edges, with `cito:supports`, `cito:refutes` and `dcterms:replaces` where a
standard term exists; without the option the output does not change. Contract v4.15, unchanged.

### Added

- **`kg_prov_export.py --edges` exports the edges.** By default the exporter still leaves the edges out, since
  derivation in PROV is production, not evidential support, and PROV has no pair for `REFUTES`. With `--edges`, every
  edge, from `edges` and `external_edges`, becomes a `kg:Edge` resource with its type, ends and every key, so it can be
  rebuilt from the RDF. Between two local nodes, `SUPPORTS`, `REFUTES` and `SUPERSEDES` also get the standard
  `cito:supports`, `cito:refutes` and `dcterms:replaces` triples. No edge produces `prov:wasDerivedFrom`, and without
  the option the output does not change.
  - **How it was measured:** against criteria registered before the measurement, on 213 graphs and 9,988 edges. Every
    edge came back from the RDF read by rdflib 7.6.0, every standard triple had the right direction, and the cost was
    1.7 times the plain export.

## [4.27.0] - 2026-10-25

Contract v4.15: an external end can live in a dot folder such as `.github/`, while `.` and `..` still fail; the git
store judges with the same corpus as the gate; `kg_trace` exits 3 on an empty corpus.

### Changed

- **Contract v4.15: an external end can live in a dot folder.** `<path>#<id>` used to require every segment to start
  with a letter, a digit, or `_`, so `.github/` and `.config/`, where a repository keeps its machinery,
  could not be pointed at. A segment can now start with a dot followed by one of those; the segments `.` and `..`
  still fail, since the rule exists to stop traversal. Nothing that passed fails. Both readers change together, for the
  outgoing and the incoming end, with eight new cases in the suite (five of form, three of corpus with a target in a
  dot folder). Found by an adopter whose studies point to a registry under a dot folder.
- **The git store judges with the same corpus as the gate.** `kg_store` (`GitStore`) now reads the tracked graphs
  in dot folders when it checks external ends, so a graph that points there can be written, and a change there can stop
  a write that would leave an end dangling. It still never writes in a dot folder, and `list()`, `read()` and the MCP
  `kg_query` and `kg_terms` tools see only the store's own names.
- **`kg_trace.py check` exits 3 when no graph was read.** It used to print "no graph read" with rc 0, which a CI that
  reads only the rc took as "every trace resolves". The JSON already said `graphs: 0`.

## [4.26.0] - 2026-10-25

`kg_query --semantic` finds the node when the question uses other words than the label, fusing the text search and a
local embedding model; optional, and outside every verdict. Contract v4.14, unchanged.

### Added

- **`kg_query --semantic`, the search by meaning.** A question with other words than the label used to find nothing:
  `--text` matches words. `--semantic "<question>"` orders the nodes that pass the other filters by similarity, using
  a local multilingual embedding model; with `--text <term>`, both lists are fused by RRF (k=60). On a curator's
  pre-registered bench of 20 questions, the fusion found 14, the vector alone 12 and the text alone 9. The JSON gains
  `semantic` (mode, model with revision and sha256, index use) and a `rank` per node; rc 3 says the vector cannot run
  here, so a caller falls back to `--text` and says so. Without `--semantic`, the output does not change. The MCP
  `kg_query` tool takes `semantic` too.
- **`kg_vector.py`, the model and the index.** `fetch` downloads the ONNX model pinned by revision and sha256, and
  `index` keeps a cache in `.kg-ssot/vector/` that redoes only the nodes that changed. Optional: `pip install
  "kg-ssot[vector]"` (onnxruntime, tokenizers, numpy), or `tools/requirements-vector.txt` with hashes in the vendor.
  Nothing here enters a verdict. Also on PyPI as `kg-vector`. The `gate` profile carries `tools/kg_vector.py` and
  `tools/requirements-vector.txt` (17 files), because `kg_query` imports the module for `--semantic`.

### Fixed

- **`kg_query`, `kg_diff` and `kg_migrate` write UTF-8 when the output goes to a file or a pipe.** On Windows the
  default was cp1252, and a label with `→` or a character outside it crashed the command; an accented label came out
  in another encoding. Found by the new CI job, which saved a query's JSON to a file.

## [4.25.1] - 2026-10-24

`kg_trace.py` now says where each trace resolves, and the `gate` profile carries what it needs to run. Contract v4.14,
unchanged.

### Added

- **`kg_trace.py` lists where each trace resolves.** The JSON (`kg-ssot.trace/1`) gains `resolved_targets`: for each
  trace that resolves, the file, the node id and type, the judged target, the `path` of what the check saw exist,
  relative to the root and with links followed, and its `kind` (`file` or `dir`). An adopter that builds a read index from the traces no longer needs
  its own resolver. The field is additive and not required, so the output of 4.25.0 stays valid.

### Fixed

- **The `gate` profile carries what `kg_trace.py` imports.** The profile now has 15 files: `tools/kg_trace.py`,
  `tools/kg_query.py`, which it imports, and `spec/trace.schema.json`, which defines its output, come along. Before, an adopter on `--profile gate` could not run the trace
  check. The release check now requires every tool of a profile to bring the `kg_*` modules it imports.

## [4.25.0] - 2026-10-24

A node's `trace:` that points to a moved file no longer passes in silence: `kg_trace.py` checks each anchor against the
files of the repository. Contract v4.14, unchanged.

### Added

- **`kg_trace.py`, the trace that does not resolve.** A node's `trace:` that points to a moved or renamed file passed
  the gate in silence: the reader does not touch the disk. `kg_trace.py check --root .` checks each anchor from the
  repository root and reports `integrity.trace-target-missing` (`kg-ssot.trace/1`). It judges only the text that looks
  like a path of the repository, and counts apart what it does not judge (absolute or URL, a declared
  `--external-root`, not a path). A name without a slash comes in only as a file tracked at the root with the exact
  name. It resolves at the root, in the graph's folder, or in its parent, and a target that leaves the root does not
  resolve. The rules are an adopter's resolver, measured on thousands of traces; on that adopter's corpus the tool
  judges the same 2,500 nodes, with 0 missing. Also on PyPI as `kg-trace`.

## [4.24.0] - 2026-10-24

An adopter can bench a commit before its tag without retagging it, and the bench vendor never passes for a release.
Contract v4.14, unchanged.

### Added

- **`kg_vendor.py update --ref <commit>`, for the bench before a tag.** An adopter that tests a release before it
  exists had to retag a commit locally, because `--tag` rightly refuses a commit whose `spec/release.json` declares
  another version. `--ref` brings the tree of a commit as it is; the stamp says `unreleased` and keeps the commit, and
  `check` fails on that vendor (`UNRELEASED VENDOR`, rc 1) unless `--allow-unreleased` is given, so a bench vendor
  never passes for a release in CI. `kg_gate.py` refuses one the same way (`--allow-unreleased`, and never
  `--update` from a bench vendor), so a CI that runs only the gate does not take the bench for a release. A later
  `update --tag` replaces it without `--force`. Requested by an adopter's bench.

## [4.23.0] - 2026-10-23

A short code gets a readable name in its own vocabulary, and the codes in prose are checked against it, with a
ratchet. Contract v4.14: `x_term.scheme` and one warning in the SHOULD, nothing that passed fails.

### Added

- **A short code with a readable name (contract v4.14).** A code like `O1` or `r16` keeps its short, stable id and
  gets a name in a vocabulary: the code is the `notation` of an `x_term`, the name is the `pref`, and the new
  `x_term.scheme` (a slug) says which vocabulary it belongs to, as `skos:notation`, `skos:prefLabel`, and
  `skos:inScheme` do in SKOS. Without a scheme, the scheme is the graph. Both readers warn
  `integrity.term-notation-duplicate` when two live terms share a notation in the same scheme (SKOS §6.5.3). SHOULD
  only: nothing that passed fails. Measured before the design: 71 opaque codes in the product's own graphs, with two
  real collisions (`O1` and `V1` each meant two things), and hundreds in an adopter's.
- **`kg_vocab.py` resolves codes and checks them in prose.** `lookup` matches a `notation` exactly, alone or as
  `scheme:notation`; `terms` gives each term its effective `scheme`; `export --to skos` writes `skos:inScheme` and the
  `skos:ConceptScheme`. The new `lint` reads labels and narratives, finds codes by a regex (`--pattern`), and reports
  `vocab.notation-duplicate` across the corpus, `vocab.code-unresolved`, and `vocab.code-ambiguous` (a code in two
  schemes, none of them the graph's own). `--external soc2='CC[0-9]+'` declares an outside code system, and
  `--baseline <file> [--update]` is the gate's ratchet: the codes that exist do not block, a new one must be born with
  a name, and naming the first term of a colliding code does not charge for the old mentions (`reclassified`).

### Changed

- **`kg_query.py --text` no longer gives a silent zero.** It compares without case or accents (`verificacao` matches
  `Verificação`); when the whole text is a term of the vocabulary (its `pref`, a current synonym, or its `notation`),
  the term and every node with any of its forms as a whole word match too (`expanded`; a case-scoped or retired synonym
  does not expand, and a notation matches exactly); and an empty result carries a `hint` that says when the zero comes
  from the other filters. Requested
  by an adopter that measured «PDF digitalizado», «reconhecimento óptico», and «verificacao» each giving 0 in silence.

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
