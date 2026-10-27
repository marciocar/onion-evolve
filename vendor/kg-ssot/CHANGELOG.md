# Changelog

**English** | [Português (Brasil)](CHANGELOG.pt-BR.md)

All notable changes to KG-SSOT are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and releases are tagged `kg-ssot-vX.Y.Z`.
The contract version (`v4.N`) is the version of the `.kg.yaml` / `.kg.json` contract that a release ships; it moves
only when the contract changes. Each release section is also the body of its GitHub release.
Releases before 4.16.0 are described in [ADOPTING.md](ADOPTING.md).

## [Unreleased]

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
