# Adopt the KG-SSOT contract

**English** | [Português (Brasil)](ADOPTING.pt-BR.md)

This guide is for a repository that keeps `.kg.yaml` graphs and wants to validate them against the formal contract:
the two-level JSON Schema 2020-12 (MUST and SHOULD), the conformance suite, and the reference reader. As an adopter,
you pin a **tag** of this repository and vendor the release surface with a script. You never copy the contract by
hand, and it is never shared code.

## What the release contains

The list lives in [`spec/release.json`](spec/release.json):
- contract v4, the current one (`spec/kg-contract-v4.schema.json` and `spec/kg-contract-v4.should.schema.json`);
- the conformance suite (`spec/conformance/`);
- the reference reader (`tools/kg_validate.py`, `tools/kg_conformance.py`);
- the gate (`tools/kg_gate.py`) and the vendor tool (`tools/kg_vendor.py`);
- the language of the human output (`tools/kg_i18n.py` and the pt-BR catalog in `locale/`): English by default,
  Brazilian Portuguese with `KG_SSOT_LANG=pt-BR` or a `pt_BR` locale;
- the gated store (`tools/kg_store.py`), for programs that write graphs: it only writes what the contract passes
  ([manual, chapter 5](docs/manual/05-tools.md));
- the reference MCP server (`tools/kg_mcp.py`), so a model can judge and write graphs through the contract, over stdio
  or local HTTP;
- the provenance exporter to PROV-O in JSON-LD (`tools/kg_prov_export.py`);
- the pinned dependencies (`tools/requirements.txt`: Python 3.11 or later with PyYAML and jsonschema). Each file
  carries its sha256, and pip checks it at install time; `--require-hashes` makes the install fail if the file ever
  loses its hashes;
- the PyPI package recipe (`packaging/python/`): the build script, the listing README, and the build tools pinned by
  hash. The same kit ships on PyPI as `kg-ssot`, to use as a library, a command, or an MCP server. For the gate in CI,
  vendoring by tag is still the recommended channel;
- the JS reader (`tools/runners/ajv/`) and the npm package recipe (`packaging/npm/`): the same reader ships on npm as
  `kg-ssot`, with the contract validator precompiled, for Node and React Native/Expo. In the vendor they travel as a
  recipe: to use the JS reader, install the package (`npm install kg-ssot`). An `npm install` or a build inside the
  vendor leaves extra files, and `kg_vendor.py check` reports them;
- the MCP Bundle recipe (`packaging/mcpb/`): the reference MCP server packaged for clients such as Claude Desktop,
  which install the `kg-ssot` package with `uv`, and the `server.json` template for the MCP Registry
  (`packaging/mcp-registry/`). These are recipes in the vendor too;
- this guide, `README.md`, and the product manual (`docs/manual/`), which explains the format, the contract, and the
  tools;
- `llms.txt` (an index for AI agents) and `llms-full.txt` (the whole documentation in one text, generated from the
  release files);
- the license (`LICENSE`, Apache-2.0) and `NOTICE`, which states its scope.

All of it is **Apache-2.0**, including the suite's `.kg.yaml` cases. Beyond copyright, Apache-2.0 grants a patent
license from the author and the contributors over what they contributed. That license ends for anyone who sues
claiming that the contract infringes a patent. If you write your own reader, you can use the contract and the suite,
commercially too, as long as you keep `LICENSE` and `NOTICE`.

On the maintainer's side, a hygiene check that does not ship verifies this list in CI:
- every entry is covered by a tracked file;
- the tag is `kg-ssot-v<version>` (up to 4.3.0, `contract-v<version>`; the old tags remain valid);
- the contract it names is the current one;
- no release file has a private reference.

As an adopter, you only use `update` and `check`.

## 1. Vendor the release

> **The tag name changed in 4.3.1:** from `contract-vX.Y.Z` to `kg-ssot-vX.Y.Z`, so the tag names the product in the
> adopter's stamp too. Nothing else changes: the old tags still exist, and your next update only changes the `--tag`
> string.

The public repository is `https://github.com/marciocar/kg-ssot`: each of its commits is a release, with its tag. The
first time, clone it outside your repository and run the vendor tool from the root of your repository (the adopter):

```bash
git clone https://github.com/marciocar/kg-ssot ../kg-ssot
python3 -I -B ../kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.19.1 --dest vendor/kg-ssot
```

To update, run it from the vendor, with `--source` required. It takes a path or a URL, and a URL becomes a
throwaway bare clone. Inside the vendor, the git repository is the adopter's, which does not have the tag:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.19.1 --source https://github.com/marciocar/kg-ssot
```

The published tags are listed by `git ls-remote --tags https://github.com/marciocar/kg-ssot`.

- **Reading:** the vendor tool reads the tag with `git archive`, never the working tree. Names are literal: a `*` in a
  file name does not become a glob.
- **What the release accepts:** regular files only. A symlink in the tag is broken input.
- **Swap:** the default `--dest` is `vendor/kg-ssot`. The directory is swapped by rename and is never left half
  written. A file that left the release disappears.
- **What the vendor tool refuses to replace:**
  - a directory without a stamp, because it never deletes someone else's directory;
  - a vendor that differs from its stamp, unless you pass `--force`. This keeps a local edit from vanishing
    silently.
- **Minimal profile:** if you only run the gate and the check, you can vendor the `gate` profile with
  `--profile gate`. It has 12 files: the contract (MUST and SHOULD), `release.json`, the reader, the gate, the vendor
  tool, the language module and its catalog (`tools/kg_i18n.py` and `locale/pt_BR/LC_MESSAGES/kg-ssot.po`),
  `requirements.txt`, this guide, `LICENSE`, and `NOTICE`. The conformance suite stays out, so `kg_conformance.py` and
  the `spec/conformance/README.md` that this guide cites do not come along. The stamp records the profile, `check`
  verifies only what the profile brought, and the next update **inherits** the profile from the stamp
  (`--profile full` goes back to the whole release).
  If you are on a tag earlier than `contract-v4.1.1`, migrate in two steps, because the old vendor tool does not know
  `--profile`: first the normal update to 4.1.1, then the update with `--profile gate`.
- **Stamp:** `vendor/kg-ssot/.kg-ssot-version` keeps the tag, the commit, and the sha256 of each file.
- **The stamp marks the vendor (public rule since 4.20.0):** a folder with `.kg-ssot-version` is the KG-SSOT vendor,
  wherever it lives, and no file inside it is one of your graphs. The tools that read a repository (`kg_gate.py`,
  `kg_query.py`, `kg_vocab.py`, `kg_migrate.py`, and `kg_diff.py --from`) leave it out by default, and
  `--no-default-excludes` brings it back; a stamp at the root of what is read does not count, so reading the vendor
  folder itself reads its graphs. The store
  (`kg_store.py`, and the MCP server over it) reads its own area, where no vendor lives, and does not apply the rule.
  A tool of your own that walks your graphs can follow the same rule with `kg_validate.find_vendor_dirs(root)` and
  `kg_validate.in_vendor(path, dirs)`, instead of a fixed `vendor/` path.
- **Commit:** the vendor tool does not commit. In a PR of its own, you commit the whole directory with the stamp.

## 2. Write the baseline

At the adopter's root, **in this order**:

```bash
pip install --require-hashes -r vendor/kg-ssot/tools/requirements.txt         # or the venv from the environment note below
git add vendor/kg-ssot                                       # before the gate: it only measures tracked files
python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update      # writes the .kg-ssot/gate/ folder
```

The gate measures the `.kg.yaml` files that git tracks (`git ls-files`, read from the working tree). A file that is
not in git yet is left out. By default, `*/fixtures/*` and `docs/materials/*` are excluded, and so is the KG-SSOT vendor
itself, any folder with the `.kg-ssot-version` stamp (since 4.19.1; the 4.19.0 vendor brings an example graph outside
`fixtures/`). That is why
`git add vendor/kg-ssot` comes before `--update`: with the vendor tracked, the baseline you write is the same one CI
measures after the commit. A graph of yours that you have not added yet also needs `git add` first.

`--exclude GLOB` is repeatable and adds to those patterns. The glob is `fnmatch` over the relative path, and `*`
crosses `/`. `--no-default-excludes` turns the patterns off, and then the vendor's fixtures, broken on purpose, enter
the corpus.

The baseline is the `.kg-ssot/gate/` folder:
- `contract.json`: the contract identity (the name of the MUST schema and the sha256 of both schemas).
- `graphs/<meta.id>.json`: one record per graph, with the MUST codes it carries (the inherited debt) and the count of
  each SHOULD warning. The name is the `meta.id`, so a `git mv` does not change the record. A `meta.id` that repeats
  (even only in case, like `Foo` and `foo`, which macOS and Windows do not tell apart), that does not fit in a file
  name, or that is a Windows device name (`con`, `com1`) goes by the hash of the path.
- `accepted/`: one accepted regression per file, with its reason.

Nothing aggregated is written: the graph count and the debt per code come from the records. Two branches that touch
different graphs touch different files, and the git merge does not conflict. Commit the whole folder.

**Environment note.** On a system with PEP 668 (Ubuntu 24.04 and later, among others), `pip install` outside a venv
is refused (`externally-managed-environment`). Install the dependencies in a venv and run the kit with its Python:

```bash
python3 -m venv .venv && .venv/bin/pip install --require-hashes -r vendor/kg-ssot/tools/requirements.txt
echo .venv/ >> .gitignore                                    # the venv stays out of git
.venv/bin/python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update
```

On GitHub Actions with `actions/setup-python`, the `pip install` in the CI step works without a venv.

### Read what fails

After the comparison, the gate lists each graph that fails the MUST level with its codes (`new`, `regressed`, or
`inherited`) and the SHOULD debt per code. To see the occurrences in one graph, run the reference reader without
`--schema`: it uses the same contract and the same vocabulary as the gate (`parse.*`, `form.*`, `integrity.*`,
`yaml.*`), with the count of each code:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/my-graph.kg.yaml
# FAIL docs/my-graph.kg.yaml
#   MUST   form.required.node.provenance ×1 · yaml.forbidden-key-on ×1
#   SHOULD form.required.node.verified_at ×1 · integrity.testimony-in-prod ×1
# · 1 files; 0 pass the MUST; 1 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

To find out **which node or edge** each code comes from, add `--where`. The default output stays the same; each
occurrence gets a line with its place, and each MUST occurrence gets the fix below it:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where docs/my-graph.kg.yaml
# FAIL docs/my-graph.kg.yaml
#   MUST   form.required.node.provenance ×1 · yaml.forbidden-key-on ×1
#   SHOULD form.required.node.verified_at ×1 · integrity.testimony-in-prod ×1
#     MUST   form.required.node.provenance  nó C_RETRY_SAFE
#            → Add provenance with source, locator, and method; with no recoverable source, change the status to unverifiable.
#     MUST   yaml.forbidden-key-on  aresta #2 (C_X -> Q_A)
#            → Replace on: with trigger:.
#     SHOULD form.required.node.verified_at  nó C_RETRY_SAFE
#     SHOULD integrity.testimony-in-prod  nó C_SLA_99
# · 1 files; 0 pass the MUST; 1 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

The place is data, so it does not change with the output language: `nó <id>`, `aresta #<n> (<from> -> <to>)`,
`meta`, `topo` (the top level), or `arquivo` for what has no finer place (the parse error, `.nan`/`.inf`, and the
unquoted date).

rc 0 means every file passes the MUST level, 1 means some file fails, and 2 means broken input.

### The `on:` key on an edge becomes `trigger:`

`yaml.forbidden-key-on` is an edge with the `on:` key. It has been forbidden since v1 because a YAML 1.1 reader (the
default PyYAML, among others) reads `on` as the boolean `true`, so the referenced event looks orphaned to that reader
while another reader passes it. The trigger of a `TRANSITIONS` edge is written `trigger:`, and the integrity check
accepts `trigger` as a reference to the event:

```yaml
- from: ST_IDLE
  to: ST_BUSY
  edge_type: TRANSITIONS
  trigger: EV_START      # was: on: EV_START
```

The change is mechanical (only the key name), and it removes the code from the graph. If it comes after the baseline,
the gate shows the gain and asks you to lock it in with `--update`.

## 3. The CI step

On GitHub Actions, the whole workflow, in `.github/workflows/kg-ssot.yml`:

```yaml
name: KG-SSOT
on:
  pull_request:
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  kg-ssot:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-python@v6
        with:
          python-version: '3.12'
      - name: KG-SSOT contract (intact vendor + per-graph gate)
        run: |
          pip install --require-hashes -r vendor/kg-ssot/tools/requirements.txt
          python3 -I -B vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot
          python3 -I -B vendor/kg-ssot/tools/kg_gate.py
```

On another CI, the step is the same: Python 3.11 or later, the pinned dependencies with `--require-hashes`, and the
two commands.

**`check`** fails (rc 1) when a vendor file was edited, deleted, or added. That includes bytecode in a
`__pycache__`, which would swap the reader without changing the source, and symlinks. The kit's scripts do not write
bytecode when they run as scripts. But a tool of yours that **imports** a kit module writes that module's `.pyc` into
the vendor's `__pycache__`, because Python compiles a module before running it, and the next `check` fails. That is
why every command in this guide uses `python3 -I -B`, and why code that imports the kit should run with `-B` or
`PYTHONDONTWRITEBYTECODE=1`.

You do not customize the contract in your repository: a change you need goes back to the product as an issue in the
public repository and becomes a case or a contract decision.

Limit: the stamp vouches for itself. `check` catches an accidental edit, but not someone who edits a file and
recomputes the stamp. Review of the adopter's PR catches that, because the stamp diff is in plain sight.

**The gate** fails (rc 1) when:
- a graph outside `failing` fails the MUST level, including a new graph;
- a graph in `failing` gains a MUST code it did not have;
- the debt of a SHOULD code goes up, or a new code appears;
- the contract changed: the name of the MUST schema, or the sha256 of the schemas because of a new tag. The comparison
  still runs against the old baseline, and you write the new baseline with `--update` in the same PR.

At the MUST level, the comparison is per graph: fixing one graph does not make up for breaking another. The SHOULD
debt is per code, a total across graphs. Removing a warning from one graph and adding the same warning to another is
a tie.

**Debt per node.** Per graph, a spread-out improvement shows up as a regression: fixing 3 occurrences in one graph and
creating 1 in another counts as +1 graph. Since `contract-v4.2.0`, `kg_gate.py --update --granularity node` counts and
locks the SHOULD debt per occurrence, summed across all graphs. The baseline keeps the granularity, and the gate uses
it without the option again; `--granularity graph` goes back to the default. Switching is not a regression: on the run
that switches, the debt is compared at the baseline's granularity, and `--update` only asks for a reason if it really
got worse. The MUST level stays per graph at both granularities. An occurrence is per node or edge for most codes; the
ones that apply to the whole file (`yaml.unquoted-date`, `form.range.top.nodes`) count 1 per graph.

A gain passes and asks you to lock it in: the graph left `failing` because it was fixed, or the debt went down. A
deleted graph does not count as a fix: the gate says it left the corpus, and it says when the corpus shrinks, so the
PR shows the removal. To lock it in, run `kg_gate.py --update` in the same PR.

About `--update`:
- with no baseline yet, it writes the first one (rc 0);
- with a regression and no `--accept-regression "<reason>"`, it refuses (rc 1) and writes nothing;
- with the reason, it writes, and the reason stays in the baseline (one file in `accepted/`; accepted regressions
  accumulate).

**rc 0:** nothing got worse, or the vendor is intact. **rc 1:** something got worse, or the vendor differs from its
stamp. **rc 2:** broken input, which never passes as green:
- in `kg_gate.py`:
  - `--repo` is not a git repository;
  - the baseline is missing (without `--update`), unreadable, or out of format. In the folder: `contract.json` with
    `contract` and `contract_sha256` as text and, optionally, `granularity` as `graph` or `node`; each record in
    `graphs/` with `graph` (the path), `id` (text or null), `must` as [codes], and `should` as code → integer > 0. In
    the file from before 4.16.0: `contract` as text, `failing` as path → [codes], `debt` as code → integer ≥ 0,
    `accepted_regressions` as a list and, optionally, `granularity`;
  - a `.kg.yaml` could not be read.
- in `kg_vendor.py`:
  - `--source` is not a git repository, the tag does not exist, or its `spec/release.json` is missing, unreadable, or
    declares another tag;
  - a release entry covers no file, or a member of the tag is not a regular file;
  - the stamp is missing, unreadable, or out of format;
  - in `update`: the destination is not a vendor, or it is an edited vendor without `--force`, or `--source` is
    missing inside a vendor.

## 4. Update the tag

The PR that changes the tag does three things:
1. runs `kg_vendor.py update` with the new tag, `git add vendor/kg-ssot` (the gate only measures tracked files), and
   `kg_vendor.py check --dest vendor/kg-ssot --index`, which verifies what the commit will carry. Since 4.8.1, the
   vendor brings its own `.gitattributes` (`* -text`), so the repository's line-ending rule does not rewrite the
   release bytes in the index. If you come from a tag earlier than 4.8.1, run `update` twice (the note below
   explains);
2. runs `kg_gate.py` and explains in the PR any difference that shows up;
3. writes the baseline with `--update` when the contract changes its identity. Since 4.16.0, this is not required:
   with no changed verdict, the gate passes with a `· identity` warning, and the `--update` can come later.

A new SHOULD warning raises the debt by design. The contract's ramps (SHOULD today, MUST later) arrive this way, as a
measured commitment.

From `contract-v4.0.x` to `contract-v4.1.x`, no verdict changes: four SHOULD warnings come in (a stamp without a
target, testimony in PROD, verification before the fact, and a decision without an origin; the table is in
[`spec/conformance/README.md`](spec/conformance/README.md)). If the SHOULD debt goes up (by design, when the corpus has
what the new warnings flag), that PR's `--update` goes with `--accept-regression "<reason>"`; if it does not, the
`--update` writes the new identity without a reason.

From `kg-ssot-v4.7.x` to `kg-ssot-v4.8.0`, the sha256 of the schemas does not change, and no MUST verdict on a
`.kg.yaml` changes. Three SHOULD warnings come into `.kg.yaml`, the points of the JSON profile on a ramp:
`yaml.unsafe-integer` (an integer outside ±(2^53−1)), `yaml.lone-surrogate` (a lone surrogate), and
`yaml.depth-over-128` (more than 128 nested collections). A graph that has one of them gains a new debt code, and
`kg_gate.py` fails until the `--update` with `--accept-regression "<reason>"`, or until the graph is fixed. 4.8.0 was
measured on the 454 `.kg.yaml` files of one adopter repository and on this repository's, and none of them triggers
the new warnings.

From `kg-ssot-v4.8.0` to `kg-ssot-v4.8.1`, neither the contract nor the reader changes. The vendor tool changes:
`update` writes `vendor/kg-ssot/.gitattributes` with `* -text`, and the stamp starts verifying it. In 4.8.0, a
repository with a line-ending rule for `*.json` (`*.json text eol=lf`, for example) normalized in the index the two
suite fixtures that have CRLF on purpose, and `kg_vendor.py check` failed on a fresh checkout, like CI's, even though
it passed on the working tree.

**From any tag earlier than 4.8.1, run the update twice.** `update` runs through the `kg_vendor.py` already in the
vendor, and the one from an earlier tag brings 4.8.1 without writing `.gitattributes`. The 4.8.1 `check` reports
this ("run the update again"). The second `update`, now with the new kit, writes the file without needing `--force`.
After `git add`, `check --index` confirms that the index holds the release bytes. Another way is to run the update
once, from the clone of the tag (`../kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.8.1 --dest vendor/kg-ssot`).
A rule of your own for the vendor in the root `.gitattributes` (`vendor/kg-ssot/** -text`) still works and can stay.

From `kg-ssot-v4.21.1` to `kg-ssot-v4.22.0`, the contract goes to v4.13, and only the SHOULD level changes: nothing that
passed fails, and the gate notes the new contract identity without asking for `--update` while no verdict changes
(measured on the core's 184 graphs before the tag). What you may see and do:

- `x_questionnaire` gets `role`: `item` (the default), `evidence_request` (a request to a person for evidence), or
  `evidence_requirement` (the evidence an item requires). Another value warns as `form.enum.node.x_questionnaire.role`.
  If you tell requests or requirements apart by an id prefix, give them the `role` (`kg_migrate.py nest` with a `const`
  field does it).
- If an auditor asks for the package by question, `kg_audit.py --root .` exports it (CSV, XLSX, or JSON). Write the
  numbers in `questions` as text (`["7"]`, not `[7]`): a number that is not text is skipped and reported. Set
  `KG_SSOT_LANG=pt-BR` for headers in Portuguese. In CI, `--fail-on-gap` gives rc 1 when an item has a gap or something
  was skipped.

From `kg-ssot-v4.21.0` to `kg-ssot-v4.21.1`, the contract does not change (still v4.12), and the gate asks for no
`--update`. Only `kg_criterion.py check` changes: what it cannot check now comes out as `integrity.criterion-malformed`,
with rc 1, instead of leaving the check in silence. The typical case is a `sha256` of digits alone without quotes,
which YAML reads as a number. If you run the check in CI and it fails after the update, quote the `sha256` and give
each version exactly one of `ref` and `text`.

From `kg-ssot-v4.20.0` to `kg-ssot-v4.21.0`, the contract goes to v4.12, and only the SHOULD level changes: nothing that
passed fails, and the gate notes the new contract identity without asking for `--update` while no verdict changes.
What you may see and do:

- If your graphs record a yardstick and results measured under it, use `x_criterion` (one node per version, with its
  `sha256` from `kg_criterion.py digest`) and `x_measured_under` on the result. Then add
  `python3 -I -B vendor/kg-ssot/tools/kg_criterion.py check --root .` next to the gate in CI: the reader computes no
  hash, so a criterion edited in place is caught only there.
- If your graphs carry `x_` keys of your own that match a canonical profile (`x_mirror`, `x_doc_cycle`,
  `x_questionnaire`), `kg_migrate.py nest --map <map>` shows the plan and, with `--apply`, moves them.
- The reference reader now counts a missing required field once; counts in a per-occurrence baseline only go down.
- Since 4.20.0, `kg_store` calls `kg_validate.judge(..., cache=...)`. A test double that replaces `judge` with the old
  signature fails with `TypeError`, and the store answers "not judged": accept `cache=None` in the double.

From `kg-ssot-v4.19.1` to `kg-ssot-v4.20.0`, the contract does not change (still v4.11), and nothing in your graphs
needs editing. A folder with the `.kg-ssot-version` stamp is now left out by `kg_query.py`, `kg_vocab.py`,
`kg_migrate.py`, and `kg_diff.py --from` too, not only by the gate; a stamp at the root of what is read no longer counts
in any tool. If a tool of your own walks your graphs with a fixed `vendor/` path, it can switch to
`kg_validate.find_vendor_dirs(root)` and `kg_validate.in_vendor(path, dirs)`. A long process that keeps a `kg_store`
object open (the MCP server, an app) now judges a pointing graph once while it does not change. In `kg_diff --format
json` without `--to`, `after` is now `WORKTREE`.

From `kg-ssot-v4.19.0` to `kg-ssot-v4.19.1`, the contract does not change (still v4.11). The gate leaves out of its
corpus, by default, every file in a folder with the vendor stamp `.kg-ssot-version`, wherever the vendor lives. The
4.19.0 vendor brings an example graph (`spec/vocab-examples/cmed-dictionary.kg.yaml`) outside `fixtures/`, and the
gate counted it as one of your graphs: a `--update` on 4.19.0 would write it into your baseline. If you already ran
`--update` on 4.19.0, run it again on 4.19.1: the example leaves the corpus, and the gate reports that graph as gone.

From `kg-ssot-v4.18.0` to `kg-ssot-v4.19.0`, contract v4.11 comes in. The gate reports the new identity on the
`· identity` line and decides by what each graph gets, as since 4.16.0:
- **`meta.title` and `meta.slug` become known keys.** A graph that failed the MUST only because of one of them now
  passes; the gate shows the gain and asks you to lock it in with `--update`.
- **The canonical `x_` profiles are SHOULD,** and they only judge a key that is present: `x_term`, `x_mirror`,
  `x_doc_cycle`, `x_questionnaire`, and `x_severity` on the node, `x_confidence` and `x_provisional` on the edge
  ([manual, chapter 3](docs/manual/03-format.md)). If you already use one of these names with another shape, the new
  warning is a new debt code, and the gate fails. Either convert the values (an `x_severity` written in another
  language becomes `critical`, `high`, `medium`, `low`, or `info`) or accept it once with
  `kg_gate.py --update --accept-regression "<reason>"`. Measured before the tag on the three adopters: one uses one of
  the names (`x_severity` with values in Portuguese, already converted); the other graphs keep their verdict and their codes.
- **`kg_migrate.py keys`** renames to `x_<key>` each key the contract does not know, which is what kept most of the
  inherited MUST debt in one adopter. Run the plan first, then `--apply`.
- **The due report** (`--due`) also lists the synonyms of `x_term`, `x_mirror`, and `x_doc_cycle`, with `subject` and
  `detail` in the JSON; a node's entry is unchanged, and so is `schema_version`.
- **The release brings** `tools/kg_vocab.py`, `spec/vocab.schema.json`, and `spec/vocab-examples/`; the `gate` profile
  does not change. The MCP server gets the read tool `kg_terms`.

One `update` is enough. The gate needs `--update` only to lock in a gain, or to accept a profile warning.

From `kg-ssot-v4.17.2` to `kg-ssot-v4.18.0`, the contract does not change (still v4.10, with the same identity), and
no verdict or code changes. What changes is the language of the human output:
- **The tools print in English by default.** They pick the language the gettext way: `KG_SSOT_LANG`, then
  `LANGUAGE`, `LC_ALL`, `LC_MESSAGES`, and `LANG`. A `pt_BR` locale or `KG_SSOT_LANG=pt-BR` gives Brazilian
  Portuguese; `C`, `POSIX`, and any language without a catalog give English. A CI runner with `LANG=C.UTF-8` gets
  English.
- **If your CI searches the human output for text**, set `KG_SSOT_LANG=pt-BR` on that step, or match both languages:
  `PASS` or `PASSA`, `FAIL` or `REPROVA`, `✗ WORSE` or `✗ PIOROU`, `BROKEN INPUT` or `ENTRADA QUEBRADA`. Better yet,
  decide on the exit code.
- **Data does not change language.** JSON keys and structure, codes, exit codes, the verdict `place` (`nó X`,
  `aresta #n`, `arquivo`) and `path`, and the `kg_migrate` TSV stay exactly as before. The `message`, `hint` and
  `error` strings inside JSON are text for people: they were always Portuguese and now follow the language, so compare
  by code, never by message. The MCP server speaks English in every locale.
- **The vendor brings two more files:** `tools/kg_i18n.py` and the catalog `locale/pt_BR/LC_MESSAGES/kg-ssot.po`. Both
  are in the `gate` profile, which now has 12 files. The vendored tools do not start without `kg_i18n.py`, and without
  the catalog they print only in English.
- **A partial vendor takes both files too.** `kg_store.py` imports `kg_i18n` since 4.18.0, so a harness that copies
  only `kg_store.py` (or any single tool) fails with `ModuleNotFoundError`: copy `tools/kg_i18n.py` and `locale/`
  along with it.

One `update` is enough, and the gate does not need `--update`.

From `kg-ssot-v4.17.1` to `kg-ssot-v4.17.2`, the contract does not change (still v4.10), and neither does the gate.
The MCP server starts announcing tool annotations: the six read tools are marked read-only and idempotent, and
`kg_write` and `kg_delete` as destructive, all of them without an open world. An MCP client can skip the confirmation
for what only reads.

From `kg-ssot-v4.17.0` to `kg-ssot-v4.17.1`, the contract does not change (still v4.10), and the gate changes neither
verdict nor identity. Two field fixes in the read tools, found by adopters on first use:
- **`kg_query --root` leaves out the vendor and the fixtures by default** (`vendor/*`, `fixtures/*`, `*/fixtures/*`,
  `docs/materials/*`). In one adopter, `--root` read 411 graphs for 29 real ones, and 35 of the first 50 open nodes came
  from fixtures. `--no-default-excludes` reads everything again. `kg_diff --from` without paths gets the same default,
  so the vendor update does not drown the graph diff. The query JSON now states the root it read (`root`).
- **A renamed field with the same value shows up as a rename** in `kg_diff`, and no longer as a separate removal and
  addition: in one adopter, two key renames showed up 21 times each. In the JSON both entries stay, linked by
  `renamed_to` and `renamed_from`, so anyone who already read the `kg-ssot.diff/1` format loses nothing; only a
  non-trivial value that is unique on both sides is paired. The query and diff tests now run in CI.

From `kg-ssot-v4.16.1` to `kg-ssot-v4.17.0`, the contract does not change (still v4.10, with the same identity). Two
read tools come in, and they neither judge nor write:
- **`kg_query.py`, the query and the projection.** It selects nodes across a whole corpus (id, prefix, type, status,
  plane, layer, words in the label, the queue of open nodes, nodes without a stamp or verified before a date, the
  neighborhood of a node) and projects each edge with the label of the other end, local or external, paginated, in the
  `kg-ssot.query/1` format. In the MCP server, it is the `kg_query` tool, over the store's area; in the behind-proxy
  profile, only the identity's area.
- **`kg_diff.py`, the diff by id.** It compares two graphs, or everything that changed between two git revisions, node
  by node and field by field, in the `kg-ssot.diff/1` format; `--ignore` drops from the comparison a field that a
  generator restamps.
- **The suite gains 2 cases** (356), two findings from the v4.10 review that only had unit tests: two repeated keys in
  document order, and the escaped line break in a flow mapping at the root. No reference verdict changes, and the gate
  keeps its identity. In 4.16.1, the README and `llms-full.txt` still said 349 cases in two places; 4.17.0 fixes that.

From `kg-ssot-v4.16.0` to `kg-ssot-v4.16.1`, contract v4.10 comes in: three points of the YAML profile where the
reference reader and the JS reader disagreed, found by fuzzing and settled by the YAML specification. None of the real
graphs measured has these cases, and no verdict of the reference reader changes.
- **Error order follows the document.** A repeated key that comes before a repeated anchor or an undefined alias gives
  `parse.duplicate-key`, as in the JS reader; before, the reference gave `parse.yaml-error`. The repeated anchor, the
  undefined alias, and the alias followed by `:` (`*x:`, which in YAML 1.2 is an alias named `x:`) are still refused.
- **An empty line after an escaped line break inside double quotes becomes `\n`**, as the specification requires and
  as the reference already read it; the JS reader (the npm package) folded it into a space.
- **The BOM at the start of the file does not count as a column.** The JS reader refused a document indented after
  it; the reference already accepted it.
- **The suite gains 5 cases** (354). The contract identity changes, and `kg_gate.py` shows the identity line with rc 0,
  without asking for `--update`. The exception is an inherited graph that failed with `parse.yaml-error` and now fails
  with `parse.duplicate-key`: the verdict is the same, but the code changed, and the gate reports a regression until
  `--update` records the switch. None of the 1,633 real graphs measured across four repositories has the case.

From `kg-ssot-v4.15.1` to `kg-ssot-v4.16.0`, the contract does not change (still v4.9, with the same identity). The
gate changes, on the two pains that the three adopters measured.
- **The baseline becomes a folder, `.kg-ssot/gate/`, with one record per graph.** The single file conflicted in
  almost every merge between branches that rewrote the baseline: in one adopter, all 4 merges of the week. Redone with
  the folder, the same 4 merge without conflict, and the gate passes on the merged tree. The 4.16.0 gate still reads
  `gate.json`, and the first `--update` writes the folder and deletes the file, with no changed verdict (measured in
  the three adopters). Commit the folder and the file removal together.
- **The first merge between an already migrated branch and one that still touches `gate.json` conflicts once.** Git
  sees the file removal as a rename to `.kg-ssot/gate/contract.json` (both are small and similar), or as
  modify/delete, and the conflict lands on one of them. Measured in one adopter: it happened when merging the long
  branch after the migration. The cure is the same in both cases: keep the migrated branch's folder
  (`git checkout --theirs .kg-ssot/gate`, or `--ours`, depending on the side), remove `gate.json`
  (`git rm .kg-ssot/gate.json`), and run `kg_gate.py --update`, which rewrites the records with the merged corpus. To
  avoid the conflict, migrate the live branches before merging between them: with both on the folder, the merge does
  not conflict.
- **A `trace:` that points to `.kg-ssot/gate.json` loses its target after the migration.** Change it to
  `.kg-ssot/gate/` (or `.kg-ssot/gate/contract.json`) in the same PR. Found by an adopter whose trace lint flagged the
  moved path: `git grep -n 'kg-ssot/gate.json' -- '*.kg.yaml' '*.kg.json'` lists the cases before the update.
- **A change of contract identity with no changed verdict passes with a warning.** The gate still reports the identity
  on a `· identity` line, but the rc comes from the comparison, made with the new contract: a new rule that makes a
  graph worse still fails. A tag that only changes the schemas without changing a verdict no longer requires a PR just
  for the `--update`. If you want the old behavior, pass `--strict-identity`. What the identity change used to protect,
  a vendored schema edited by hand, the gate now verifies on its own: when it runs from a vendor, it compares the sha256
  of both schemas with the stamp (`.kg-ssot-version`) and fails when they differ or when the stamp is gone, and
  `--update` refuses to write the baseline, even with `--accept-regression`. Someone who edits the schema and rewrites
  the stamp along with it gets past the gate, as they used to by editing the schema and the baseline: the defense there
  is the PR diff, which shows the touched stamp.
- **The baseline keeps the kit version** (`kit` in `contract.json`). Measuring with a kit older than the baseline's
  fails: a rule that only the new release had would stop being measured. A deliberate rollback passes with
  `--update --accept-regression "<reason>"`.
- **The record follows the `meta.id` through a `git mv`.** The gate reports the mapping on a line
  `· A → B: the baseline record followed meta.id`. It cannot tell a `git mv` from "delete a graph and create another
  with the same `meta.id`", and that is why the line exists: whoever reviews the PR sees where the inherited debt came
  from. A `meta.id` that repeats in the baseline is never followed.
- **After a merge, `contract.json` can come from one side and a record from the other**, measured with the old
  contract. The verdict stays correct, because the comparison is always made with the current contract. What can go
  stale is the recorded identity; the next `--update` fixes it.
- **A script that passes `--baseline <file>.json`** still reads and writes the single file. Without `--baseline`, the
  default is the folder.

From `kg-ssot-v4.15.0` to `kg-ssot-v4.15.1`, contract v4.9 comes in. It fixes a design flaw in 4.15.0 that an adopter
found while writing evidence-collection rules.
- **`reverify_every` without `verified_at` no longer warns.** A rule with a cadence and no collection yet is in its
  initial state, not in debt: in 4.15.0, `kg_gate.py` reported a regression in `form.required.node.verified_at` for
  every new rule. The due report (`kg_validate.py --due`, in the `unstamped` list) lists this case, outside the
  verdict. A PROD node without `verified_at` still warns.
- **The suite stays at 349 cases**, and the case of a cadence without a stamp becomes valid, with no warning. The
  contract identity changes (`kg_gate.py` asks for `--update`). The SHOULD debt can only go down, and no MUST verdict
  changes.

From `kg-ssot-v4.14.0` to `kg-ssot-v4.15.0`, contract v4.8 comes in: the verification keys, designed with two adopters
from a real continuous-audit case. All of them are optional, and if you do not use them you gain no debt.
- **`reverify_every`**: how often a node's verification has to be redone, as an ISO 8601 date-only duration (`P3M`,
  `P1Y`). Zero (`P0D`) warns. In 4.15.0 it also warned without `verified_at`; 4.15.1 removed that warning.
- **`reverify_on`**: the event trigger, as text ("on hire", "on every configuration change").
- **`retain_for`**: how long the evidence has to be kept, in the same duration format.
- **`owner`** is the role answerable for the node, not a person. It changes nothing in the verdict.
- **`kg_validate.py --due YYYY-MM-DD`**: the due report, which never changes the gate's verdict. A verdict that changed
  with the calendar, without a commit, would break the baseline and the ratchet. Run the report in a scheduled job if
  you want to enforce the cadence.
- **The suite gains 13 cases** (349). The contract identity changes (`kg_gate.py` asks for `--update`), with no
  changed verdict.

From `kg-ssot-v4.13.1` to `kg-ssot-v4.14.0`, contract v4.7 and set writes in the store come in. Both gaps were found
by an adopter that writes part of its graphs as `.kg.json`.
- **The external end of `external_edges` can be a `.kg.json`** (`<path>.kg.json#<id>`), the JSON format of the same
  model. The corpus that verifies the end (`kg_gate.py`, the `--corpus` of both readers, and `kg_store.py`) now reads
  both formats. It is a widening: nothing that passed fails. The contract identity changes (`kg_gate.py` asks for
  `--update`), with no changed verdict.
- **`kg_store.write_many`** (and `kg_store.py write-many`) writes a set of graphs at once, or nothing. It is the way to
  regenerate graphs that cite each other.
- **The suite gains 8 cases** (336), three of them to refuse an extension out of shape (`.kg.yml`, `.KG.JSON`) and a
  `.kg.json` that does not exist when only the `.kg.yaml` with the same base name exists.

From `kg-ssot-v4.13.0` to `kg-ssot-v4.13.1`, the contract identity starts reporting v4.6. The two new rules of 4.13.0
live only in the reader, and the sha256 of the schemas, which `kg_gate.py` keeps as the identity, did not change: a
baseline written on 4.12.0 kept judging with a new rule without the identity reporting it. The description of the
MUST schema now declares v4.6, and the release hygiene requires every contract version to appear in the description
of one of the schemas. `kg_gate.py` shows the new identity and asks for `--update`; no verdict changes.
- **`kg_migrate.py` reads the same corpus as the gate.** Without a list of graphs, the `kg_gate.py` patterns
  (`*/fixtures/*`, `docs/materials/*`) and `vendor/*` are left out, and `--exclude` uses the gate's semantics (`*`
  crosses `/`), without losing the earlier `**/`, which matches zero folders;
  `--no-default-excludes` removes the patterns. Before, the plan picked up the fixtures, and `*/fixtures/*` did not
  match a nested path.
- **`kg_migrate.py` does not write bytecode into the vendor**, even when run without `-B`; before, the next `check`
  failed because of the `kg_validate` `.pyc` in `__pycache__`.
- **A node whose `verified_scope` already matches the profile shows up as `same`** in the plan, apart from what
  changes.

From `kg-ssot-v4.12.0` to `kg-ssot-v4.13.0`, contract v4.6 (a rare YAML MUST and `\r` normalized in the JS reader)
and the profile-driven migrator come in.
- **`kg_migrate.py`** proposes the `provenance` that v4 requires, from the rules of a profile you keep under version
  control ([manual, chapter 5](docs/manual/05-tools.md); example in `spec/migrate-examples/`). `plan` writes nothing,
  and `apply` writes only what the plan proposed. The acceptance fixture, an anonymized real corpus of 1,024 nodes,
  lives in `tools/fixtures/migrate/adopter-hub/`.
- **The continuation line of a quoted string** has to be indented more than the mapping or list that contains it;
  less than that fails as `parse.yaml-error`, as the specification requires.
- **The JS reader treats `\r\n` and a lone `\r` as line breaks**, like the reference, and refuses a quoted string that
  does not close (an escaped quote at the end of the line), which it used to cut there.
- **The suite gains 16 cases** (328).
- **On Windows, the update to 4.13.0 or later runs through the new tag's kit.** The `kg_vendor.py` of earlier tags
  passes `git archive` the whole list of release files, and in 4.13.0 that list exceeds the Windows command-line limit
  (`WinError 206`). Run the update from the clone of the tag (`../kg-ssot/tools/kg_vendor.py update --tag
  kg-ssot-v4.19.1 --dest vendor/kg-ssot`). Since 4.13.0, the kit passes only the release entries. On Linux and macOS
  the limit is much higher, and the usual update works.

Measured on 2026-10-20, none of the 1,507 `.kg.yaml` files in four adopter repositories changes at the MUST or SHOULD
level. The sha256 of the schemas did not change in 4.13.0, and `kg_gate.py` did not ask for `--update`: the identity
did not report the reader's new rules. 4.13.1 fixes that.

From `kg-ssot-v4.11.0` to `kg-ssot-v4.12.0`, contract v4.5 comes in: a rare YAML MUST and three SHOULD widenings.
- **A tab in the leading whitespace of a quoted string's continuation line** fails as `parse.yaml-error`.
- **`verified_scope`**, optional: `fato`, `mecanismo`, or `nenhum`, the reach of `verified_at`.
- **`locality: privado`**, for a document outside the repository, not public, and re-verifiable by whoever has access.
- **With `--corpus`, a `REFUTES` that arrives from another graph** at a live node counts toward
  `integrity.refutes-unreconciled`.
- **The suite gains 18 cases** (312).

Measured on 2026-10-20, none of the 1,457 `.kg.yaml` files in four adopter repositories changes at the MUST or SHOULD
level. The sha256 of both schemas changes, so the `update` PR runs `kg_gate.py --update` after vendoring the tag;
without the case in the corpus, no reason is needed.

From `kg-ssot-v4.10.0` to `kg-ssot-v4.11.0`, contract v4.4 comes in: one SHOULD warning and three rare YAML MUST
verdicts.
- **`integrity.refutes-unreconciled`:** a node that receives `REFUTES` and stays live (neither `superseded` nor
  `refuted`; only a `question` that is `done` does not warn). The graph asserts and refutes the same thing. One
  adopter's radar already fails this case as a contradiction; here it warns now and becomes MUST in a future version.
- **The strict YAML profile:** the unnamed `!` tag (also `!<!>`), a `!!timestamp` whose text is not a date, and a tab
  outside quotes, blocks, and comments fail as `parse.yaml-error`, in the reference and in the JS reader. The tab
  already failed in the reference; the `!` tag and `!!timestamp` change. Measured on 2026-10-20, none of the 1,391
  `.kg.yaml` files in four adopter repositories changes verdict.
- **The suite gains 31 cases** (294): 10 in `latest/integrity/coherence/` and 21 in `latest/yaml/strict-profile/`.

The sha256 of the SHOULD schema changes, so the `update` PR runs `kg_gate.py --update` after vendoring the tag. If the
corpus does not have the case, it writes the new identity without a reason. If it does, the debt goes up by design,
and the `--update` goes with `--accept-regression "<reason>"`; or reconcile the target first (`refuted` or
`superseded`).

From `kg-ssot-v4.9.1` to `kg-ssot-v4.10.0`, no MUST verdict changes. The MCP server and the JS reader change:
- **The "behind proxy" profile of `kg_mcp.py`** (`--identity-header`, `--secret-env`): a header identity that refuses
  by default, a secret compared with hmac, one area and one author per identity, per request, the limits
  `--max-graphs` and `--max-concurrent`, and the `untrusted_data` envelope. Outside the profile, nothing changes.
- **The two eras of the MCP protocol:** `kg_mcp.py` speaks 2026-07-28, stateless (`server/discover` and the
  per-request `_meta`), and still speaks 2025-11-25, with `initialize` and no session. The era is chosen per request.
- **The external gate** (`--gate-cmd`, in `kg_store.py` and `kg_mcp.py`): a command of yours, without a shell, that
  judges after the contract on every write and delete and returns a `kg-ssot.verdict/1`. The store only writes with a
  PASS from both, and a gate that crashes never becomes a PASS. This is how you plug a gate of your own (a radar, a
  policy) into the server. Without the option, nothing changes. Since 4.18.0, a gate that `kg_mcp.py` runs gets
  `KG_SSOT_LANG=en`, because its verdict goes to the model; from `kg_store.py` it inherits your language.
- **The OCI image** `ghcr.io/marciocar/kg-ssot:4.10.0`: the `kg-mcp` from the same PyPI wheel, without root, with the
  store in `/data` and the MCP Registry ownership label, to run next to LibreChat (the manual, under "The OCI image",
  has the compose file and `librechat.yaml`).
- **A behavior change:** `--allow-remote` now requires `--secret-env`. If you served beyond loopback without a secret,
  behind a proxy, you need to set a secret and send it in the header (`--secret-header`, default `X-Api-Key`).
- **The JS reader measures the SHOULD warnings,** with the same codes as the reference on every suite case, and the
  npm package carries `should.mjs` precompiled.
- **The suite gains 2 cases** (263), about a `trace` that is only whitespace.

One `update` is enough, and the gate does not need `--update`.

From `kg-ssot-v4.9.0` to `kg-ssot-v4.9.1`, no verdict changes. The store and the MCP server change:
- **The store runs on Windows.** In 4.9.0 it refused to open there, and the MCPB in Claude Desktop on Windows started
  with judging only. On Windows, which has no `dir_fd`, each step of the path is checked with `lstat` (symlinks,
  junctions, and mount points are refused; an on-demand OneDrive file passes), the opened file has to be the one that
  `lstat` saw, and the path is checked again after the read and before the final swap on a write. The cross-process
  lock is `msvcrt`'s. It is weaker than on POSIX, and the manual says where.
- **Portable names.** The store refuses to create a name with a reserved Windows segment (`CON`, `NUL`, `COM1`...) or
  one that ends in a dot; a name like that already in the store still reads, writes, and can be removed. No operation
  (read, write, delete, history) accepts a name that differs only in case from one in the store: on Windows and macOS
  the two would be the same file, and deleting `ALVO.kg.yaml` would erase `alvo.kg.yaml` without judging who points to
  it. An old pair with both cases, on a disk that tells them apart, keeps working by exact case.
- **The server says why it started without a store.** With `--store-optional`, a root that does not open does not
  bring `kg_mcp.py` down: it starts with only `kg_validate` and `kg_schema_help` and puts the reason in the
  instructions, in the description of both tools, and in `kg_schema_help`. Without the option, a root without
  permission now gives rc 2 with the message, instead of a traceback. The MCPB uses the option, and a root that arrives
  with an unexpanded `${...}` does not create a store.
- **The modules find `spec/` from their own path.** `kg_store.py`, `kg_mcp.py`, and `kg_conformance.py` stop using
  the `_ROOT` of the imported `kg_validate`; a fake `kg_validate` in a test no longer diverts its neighbors' spec.

One `update` is enough, and the gate does not need `--update`.

From `kg-ssot-v4.8.2` to `kg-ssot-v4.9.0`, no verdict changes. On a value that ends with `\n`, the reference stops
emitting a redundant code: it now matches regexes in full, like the ECMA-262 of the contract's patterns. The kit also
ships on PyPI as `kg-ssot`, the JS reader on npm as `kg-ssot`, and the MCP server as an MCP Bundle (the recipes in
`packaging/` travel with the release), and the modules find `spec/` next to themselves in the installed package or in
the parent directory in the vendor. If you use the vendor, nothing changes: one `update` is enough, and the gate does
not need `--update`.

From `kg-ssot-v4.8.1` to `kg-ssot-v4.8.2`, no verdict or code changes. Only the output improves: the `.kg.json`
verdict now carries the line of each occurrence, the hint for `integrity.orphan-node` carries the node id and the edge
that fixes it, the message and hint for `integrity.verified-before-fact` state both readings (future validity or
swapped dates), and `--where` shows the fix below each MUST occurrence. One `update` is enough, and the gate does not
need `--update`.

**`.kg.json`.** 4.8.0 reads the same data model from a `.kg.json` file, with a JSON parser, under the contract's JSON
profile: RFC 8259 with a leading BOM accepted, I-JSON (RFC 7493, no lone surrogate and integers within ±(2^53−1)), at
most 128 nested collections, and unique keys. In `.kg.json`, these points fail (MUST). `kg_validate.py`,
`kg_conformance.py`, `kg_store.py`, and `kg_mcp.py` read both formats by extension (case-sensitive: `.kg.json`).
**The gate still measures only `.kg.yaml`**: a `.kg.json` committed to the repository is not measured by
`kg_gate.py`. Since 4.14.0 (contract v4.7), `external_edges` can also point to `.kg.json`, and the gate reads those as
targets. If you keep `.kg.json` in the repository and want CI to enforce it, run `kg_validate.py` on them in a step of
its own.

## 5. From v3 to v4

v4 is a major version: what warned in v3 now fails. If you are on a `contract-v3.x` tag (earlier than the public
repository, which starts at v4), you move up through the gate's **ramp**, with no date trick in the schema and without
fixing the whole corpus at once. If you are adopting now, you start on v4 and can skip to the list of what changes,
which also works as a summary of the contract.

What changes in v4:
- **`provenance` is MUST** on a `confirmed` or PROD node (`form.required.node.provenance`), with non-empty `source`,
  `locator`, and `method`. An `unverifiable` node does not require it, not even in PROD.
- **A placeholder `provenance.source` fails** (`form.pattern.node.provenance.source`): only whitespace,
  `desconhecida`, `desconhecido`, `unknown`, `n/a`, `na`, `n.a.`, `none`, `null`, `sem fonte`, `tbd`, hyphens, a dash,
  or `?`, case-insensitive and ignoring trailing punctuation and surrounding whitespace.
- **An unknown key without the `x_` prefix fails** at the top level, in `meta`, in a node, and in an edge
  (`form.unknown-key.<scope>.<key>`), and a name without `x_` that is not even a slug fails as
  `form.pattern.<scope>.key`. Inside `provenance`, an unknown key still only warns.
- **`provenance.method` has a vocabulary** (SHOULD in v4, MUST in v5): `'<class>: <detail>'`. The class says **what
  kind of evidence supports the claim**: `medição` (measurement: whoever established the claim ran and recorded the
  command), `leitura` (reading: a primary document), `juízes` (judges: a panel of agents or judges), `testemunho`
  (testimony: a person or session stated it; this includes a third party's measurement read here), or `derivado`
  (derived: the claim is concluded from other claims or fields, with no evidence of its own). Anything else warns as
  `form.pattern.node.provenance.method`.
  When a migration fills `provenance` from what the node already had, the class is that of the original evidence, and
  the detail says the migration did not re-verify, for example
  `medição: <what was measured>; não reverificado na migração` (maintainer decision, 2026-10-09).
  Your team's internal prose (a `docs/*.md` written by someone on the team) is `testemunho`, not `leitura`: it is the
  account of whoever wrote it, and that way the radar shows which `confirmed` nodes have only prose behind them.
  **Watch out:** if your CI requires new graphs to come out clean at the SHOULD level too, this warning already fails
  there in v4, not only in v5. Adjust the generators that write `provenance` first.

The path, in a single PR:
1. `python3 -I -B vendor/kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.19.1 --source https://github.com/marciocar/kg-ssot`
   twice (the v3 kit does not write the vendor's `.gitattributes`, and the second update, now with the new kit,
   does), `git add vendor/kg-ssot`, and `kg_vendor.py check --dest vendor/kg-ssot --index`;
2. `python3 -I -B vendor/kg-ssot/tools/kg_gate.py` shows the new contract identity and the graphs that start failing
   the MUST level;
3. `python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update --accept-regression "<reason>"` writes those graphs into
   `failing`, as **inherited debt**. Without the reason, `--update` refuses, because a graph that passed and now fails
   is a regression. From then on the ratchet applies: a new graph has to pass v4, a graph in `failing` gains no new MUST
   code, and the debt only shrinks, with an `--update` after each fix.

**Where the source lives** (`provenance.locality`, optional, since `contract-v4.2.0`): `repo` (a versioned file in
the repository itself), `web` (a public address), `host` (exists only on one machine: a local journal, a path outside
the repository), or `pessoa` (someone's account). Any other value warns as `form.enum.node.provenance.locality`. It
lets you measure what a third party can re-verify and block `host` when the graph goes public. Since v4.5 there is
also `privado`: a document outside the repository, not public, and re-verifiable by whoever has access (Google Drive,
an internal wiki). The value follows where the copy you read lives, not the document's classification: a PDF that the
issuer marks as public, read from a copy in Drive, is `privado` until someone finds the public URL, when it becomes
`web` with the new locator.

**A reference to a node in another graph** (`external_edges`, optional, since `contract-v4.3.0`): a list at the top of
the graph, each edge with exactly one external end `<path relative to the repository root>#<id>` and the other end an
id in this file. Without `from`, the whole graph is what points.

```yaml
external_edges:
  - to: docs/research/other.kg.yaml#C_OLD          # this graph supersedes a node in another graph
    edge_type: SUPERSEDES
  - from: docs/graph/ports.kg.yaml#D_MATRIX        # a node from outside constrains a node here
    to: D_CUT
    edge_type: CONSTRAINS
```

The types are `SUPERSEDES`, `CONSTRAINS`, `SUPPORTS`, `REFUTES`, `TRACES_TO`, and `DEPENDS_ON`. The gate checks the
target against the repository's tracked `.kg.yaml` and `.kg.json` files, including the ones `--exclude` removes from
the corpus, and reads only the ones some reference cites: a target that does not exist, or a deleted target graph,
fails the graph that points (`integrity.dangling-external`). Outside the gate, `kg_validate.py --corpus <repository
root>` does the same check: in a git repository, against the tracked `.kg.yaml` and `.kg.json` files; outside one,
against every graph under the directory. Without `--corpus`, the reader checks only the shape and the local end, and
it says how many files were left with an unchecked external end. A reference to the same file passes as external; use
`edges` for that. A custom `x_` key that played this role migrates here; one that only declares something, without
being an edge, stays as `x_`.

**Corrected label.** When a revision changes a node's label, the previous label goes into `narrative`, starting with
`label anterior: …`. Git keeps the rest of the history; the contract has no dedicated field for it.

What to do with a `confirmed` or PROD node **with no recoverable source**:
- **the default is to downgrade** the `status` to `unverifiable`, which does not require `provenance`: what cannot be
  traced is not confirmed;
- **when the origin is a recoverable person or session**, `provenance` points to that origin, with a `method` of
  class `testemunho`, and the node stays `confirmed`;
- **never a placeholder** in `source`: it fails.

Changing a node's `status` is a decision about the truth of the graph, and it belongs to whoever owns the graph. A
migration can propose `provenance` from fields the node already has, but the `method` is declared by whoever reviews
it, never invented. `kg_migrate.py` does this from a profile you write: `plan` shows the proposal for each node
without writing anything, and `apply` writes only what the plan proposed, verifying that nothing else changed
([manual, chapter 5](docs/manual/05-tools.md)). A custom key without `x_` is resolved by renaming it to `x_<name>`.

## Conformance of another reader

To prove that a reader of your own agrees with the contract, run the suite with the reference reader, **after**
`git add vendor/kg-ssot`:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_conformance.py
```

The order matters: the corpus cases check the external end against the tracked graphs when the suite lives in a git
repository, and with the vendor still outside git, those cases fail (`latest: 384/390`). Then compare with the codes
your reader emits. The case format, and how to run the suite with a reader in another language, are in
[`spec/conformance/README.md`](spec/conformance/README.md).
