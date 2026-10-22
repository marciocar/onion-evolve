# 5. Tools

**English** | [Português (Brasil)](pt-BR/05-ferramentas.md)

[← The contract](04-contract.md) · [Contents](README.md) · [Adoption and CI →](06-adoption-and-ci.md)

The tools that ship in the release live in `tools/`. They need only Python 3.11 or later and the pinned, hashed
versions in [`tools/requirements.txt`](../../tools/requirements.txt) (PyYAML and jsonschema, plus the jsonschema
dependencies).

```bash
python3 -m venv .venv && .venv/bin/pip install --require-hashes -r tools/requirements.txt
```

Every `rc` follows the same convention: **0** passed, **1** something failed, **2** the input is broken (an unreadable
file, a missing baseline, a tag that does not exist). An rc 2 never counts as green.

The examples below run in a demo repository with the kit in `vendor/kg-ssot`. In a clone of the product, replace
`vendor/kg-ssot/tools/` with `tools/`.

## Output language

Since 4.18.0, the tools print their human output in English by default, and in Brazilian Portuguese when you ask for
it. Each tool picks the language the gettext way and stops at the first variable that is set:

1. `KG_SSOT_LANG`, the override for KG-SSOT alone (`pt-BR`, `pt_BR`, or `en`);
2. `LANGUAGE`, a colon-separated list (`pt_BR:en`), where the first language with a catalog wins;
3. `LC_ALL`, then `LC_MESSAGES`, then `LANG` (`pt_BR.UTF-8`).

An empty variable counts as unset. `C` and `POSIX` mean English. So does a language with no catalog: the variable
that is set still decides, and the tools do not fall through to the next one. A bare `pt` matches `pt_BR`. A sentence that has no
translation yet prints in English. The catalog is `locale/pt_BR/LC_MESSAGES/kg-ssot.po`, and it travels in the
release and in the vendor (also in `--profile gate`).

```bash
KG_SSOT_LANG=pt-BR python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/broken.kg.yaml
KG_SSOT_LANG=en python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/broken.kg.yaml
```

Data does not change language. The JSON structure and its keys, the codes (`form.required.node.label`), the exit
codes, the place of an occurrence (`nó C_RETRY_SAFE`, `aresta #3`, `arquivo`), and the TSV sheet of `kg_migrate.py`
stay the same in every language. The `message` and `hint` fields of a verdict are text for people: they follow the
language on the command line. The MCP server speaks English in every locale, because its descriptions, errors and
results are protocol and prompt for the model. As in gettext, `LANGUAGE` only applies when the effective locale is
not `C`, so `LC_ALL=C` forces English. To make a CI step independent of the language, decide on the rc, as
[chapter 6](06-adoption-and-ci.md#output-language-in-ci) shows.

## `kg_validate.py`: the reference reader

Validates one or more files against the current contract.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py docs/example.kg.yaml docs/broken.kg.yaml
```

```text
PASS docs/example.kg.yaml
FAIL docs/broken.kg.yaml
  MUST   form.required.node.provenance ×1 · form.unknown-key.node.priority ×1
  SHOULD form.required.node.verified_against ×1 · integrity.untraced-decision ×1 · yaml.unquoted-date ×1
· 2 files; 1 pass the MUST; 1 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

rc 1. To see **which node** each code comes from, use `--where`:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where docs/broken.kg.yaml
```

```text
FAIL docs/broken.kg.yaml
  MUST   form.required.node.provenance ×1 · form.unknown-key.node.priority ×1
  SHOULD form.required.node.verified_against ×1 · integrity.untraced-decision ×1 · yaml.unquoted-date ×1
    MUST   form.required.node.provenance  nó C_RETRY_SAFE
           → Add provenance with source, locator, and method; with no recoverable source, change the status to unverifiable.
    MUST   form.unknown-key.node.priority  nó C_RETRY_SAFE
           → Rename the key with the x_ prefix (an extension that readers ignore) or remove it.
    SHOULD form.required.node.verified_against  nó C_RETRY_SAFE
    SHOULD integrity.untraced-decision  nó D_RETRY_POLICY
    SHOULD yaml.unquoted-date  arquivo
· 1 files; 0 pass the MUST; 1 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
```

Useful options:

| Option | Effect |
|---|---|
| `--where` | One line per occurrence, with the node or the edge; on a MUST occurrence, the fix comes right below |
| `--corpus DIR` | Checks the external end of each `external_edges` entry against the `.kg.yaml` and `.kg.json` files that git tracks under `DIR` (outside a git repository, all of them) |
| `--schema F` | Validates against another MUST schema (the SHOULD schema next to it comes along, if there is one) |
| `--format json` | The structured verdict on stdout (see below), for tools and MCP servers |
| `--limit N` | With `--format json`, how many occurrences per file (default 50); the summary counts all of them |
| `-` in place of the file | Reads the graph from stdin, with no temporary file; `--stdin-format json` reads a `.kg.json` graph (default `yaml`) |
| `--should-schema F` | With `--schema`, the SHOULD schema that goes with it (in place of the one next to it) |
| `--due YYYY-MM-DD` | Instead of the verdict, the due report on that date (since 4.15.0): each node with `reverify_every` whose `verified_at` plus the cadence falls on or before the date, each node that has a cadence but no stamp, and each node that has only `reverify_on`. The rc is 0 (or 2 on broken input): being due never fails, and the report does not judge the graph (the gate is still `kg_gate.py`). A file that does not parse shows up as `UNREADABLE`; in a scheduled job, check that list, because the rc does not flag it. A malformed or zero cadence stays out of the report (the SHOULD warning flags it), and so does a due date after the year 9999. With `--format json`, the output uses the `kg-ssot.due/1` format (`spec/due.schema.json`) |

The `--json OUT`, `--spike`, `--git`, `--rev`, and `--list` options belong to the measurement instrument that gave
rise to the contract (the "spike"). They write and replay a frozen legacy format and are not part of the stable
interface. For tools, use `--format json`.

With `external_edges` and no `--corpus`, the reader warns that it did not check the external end:

```text
PASS docs/decision.kg.yaml
· 1 files; 1 pass the MUST; 0 with a SHOULD warning (kg-contract-v4.schema.json + kg-contract-v4.should.schema.json)
· 1 file(s) with external_edges: the external end was NOT verified (run with --corpus <repository root>)
```

### The structured verdict (`--format json`)

If you call the reader from a program (a CI job, an MCP server, a chat), `--format json` returns the verdict in a
versioned format, `kg-ssot.verdict/1`, with a JSON Schema in `spec/verdict.schema.json`. Real output for a suite
case:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_validate.py --format json \
  vendor/kg-ssot/spec/conformance/fixtures/latest/form/minimal/bad-node-missing-label.kg.yaml
```

```text
{
 "schema_version": "kg-ssot.verdict/1",
 "contract": {
  "must": "spec/kg-contract-v4.schema.json",
  "should": "spec/kg-contract-v4.should.schema.json",
  "release": "kg-ssot-v4.18.0",
  "sha256": { "must": "6a05cb1e…", "should": "04327d29…" }
 },
 "results": [
  {
   "source": "…/bad-node-missing-label.kg.yaml",
   "verdict": "FAIL",
   "summary": { "MUST": { "form.required.node.label": 1 }, "SHOULD": {} },
   "occurrences": [
    {
     "level": "MUST",
     "code": "form.required.node.label",
     "place": "nó Q_A",
     "path": "nodes[0]",
     "line": 5,
     "message": "Missing required field \"label\" in the node.",
     "hint": "Add label: the node's short claim, up to 280 characters."
    }
   ],
   "total": 1,
   "truncated": false,
   "external_checked": true
  }
 ]
}
```

(The two sha256 values and the path are shortened here, and a few objects sit on one line.)

- **What is stable:** `code` is the vocabulary of the suite and the gate, and a tool decides by it. `message` and
  `hint` are text for people: they follow the [output language](#output-language) and may change.
- **Where the occurrence is:** `path` points into the document (`nodes[7].provenance.method`) and `line` is the line
  in the file, in `.kg.yaml` and in `.kg.json`, so an editor can fix the right spot without rewriting the graph.
- **The cutoff:** `summary` counts every occurrence. `occurrences` holds up to `--limit`, and `truncated` and `total`
  tell you whether the list was cut. That way a large graph does not flood a model's context.
- **The contract that judged:** `contract` holds the path, the sha256 of each schema, and the release, for anyone who
  needs to prove which contract judged.
- **The rc:** 0 when every file passes, 1 when any file fails (a file that does not parse fails with `parse.*`, as in
  the suite), and 2 when the input is broken (an unreadable file, an invalid option).
- **Performance:** with libyaml installed (the common case for PyYAML), parsing uses the C parser with the same YAML
  1.2 profile. It falls back to the slower pure parser only for the rare texts where the two can differ (a tab,
  `%YAML`, a surrogate or `\U` escape, a BOM past the start).

## `kg_conformance.py`: the suite

Runs the conformance suite against the reference reader. First the metaschema tests itself, then each manifest is
validated, then each case runs.

```bash
python3 -I tools/kg_conformance.py
```

The last lines:

```text
—
latest: 356/356 (gates the rc)
optional: 10/24 (report only)
```

rc 0. `latest/` is the current contract, and a case that fails there fails the run (rc 1). `optional/` is behavior
that a reader **may** implement (today, the semantic layer of freshness and domain, which the reference reader does
not implement), and it never changes the rc. rc 2 means the suite itself is broken: an invalid manifest, a file
outside any manifest, an unknown folder.

## `kg_gate.py`: the per-graph ratchet

The gate is for the CI of a repository that keeps graphs. It measures every `.kg.yaml` file **that git tracks** and
compares the result with a baseline (the `.kg-ssot/gate/` folder). The rule: **nothing gets worse**. A graph that
already failed is recorded as inherited debt; a new graph has to pass.

Without a baseline, the gate refuses to run:

```text
GATE BROKEN  missing baseline (.kg-ssot/gate): write the first one with --update
```

rc 2. The first baseline:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_gate.py --update
```

```text
  MUST   docs/broken.kg.yaml (inherited): form.required.node.provenance · form.unknown-key.node.priority
  SHOULD form.required.node.verified_against: 1 graph
  SHOULD integrity.untraced-decision: 1 graph
  SHOULD yaml.unquoted-date: 1 graph
baseline written: .kg-ssot/gate (2 graphs, 1 in the inherited debt)
```

A new graph that fails, after `git add`:

```text
✗ WORSE  docs/new.kg.yaml fails MUST: form.required.node.provenance, form.unknown-key.node.priority
✗ WORSE  debt.form.required.node.verified_against: 1 → 2
✗ WORSE  debt.integrity.untraced-decision: 1 → 2
✗ WORSE  debt.yaml.unquoted-date: 1 → 2
· 3 graphs; 1 pass MUST; 1 in the inherited debt
  MUST   docs/broken.kg.yaml (inherited): form.required.node.provenance · form.unknown-key.node.priority
  MUST   docs/new.kg.yaml (new): form.required.node.provenance · form.unknown-key.node.priority
  SHOULD form.required.node.verified_against: 2 graphs
  SHOULD integrity.untraced-decision: 2 graphs
  SHOULD yaml.unquoted-date: 2 graphs
```

rc 1. And when the debt is paid (the inherited graph fixed):

```text
↑ improved docs/broken.kg.yaml: passes MUST (lock in the gain: kg_gate.py --update)
↑ improved debt.form.required.node.verified_against: 1 → 0 (lock in the gain: kg_gate.py --update)
↑ improved debt.integrity.untraced-decision: 1 → 0 (lock in the gain: kg_gate.py --update)
↑ improved debt.yaml.unquoted-date: 1 → 0 (lock in the gain: kg_gate.py --update)
· 2 graphs; 2 pass MUST; 0 in the inherited debt
```

rc 0, with a request to lock in the gain. Run `--update` in the same PR so the debt does not come back.

| Option | Effect |
|---|---|
| `--update` | Writes the baseline. If something got worse, it refuses unless you pass `--accept-regression` |
| `--accept-regression "<reason>"` | Accepts a regression; the reason is recorded in the baseline |
| `--exclude GLOB` | Removes paths from the corpus (repeatable). `*/fixtures/*` and `docs/materials/*` are excluded by default |
| `--granularity node` | With `--update`: counts the SHOULD debt per occurrence, not per graph |
| `--no-default-excludes` | Turns off the default excludes (and then the vendor fixtures enter the corpus) |
| `--repo DIR` · `--baseline FILE` | Another repository, another baseline |

## `kg_vendor.py`: bring in and verify the release

An adopter never copies the contract by hand. The vendor tool reads a **tag** with `git archive` and writes a stamp
with the sha256 of each file.

Run it from the adopter's root, with a clone of the public repository in `../kg-ssot`. The outputs below come from
real runs of the 4.18.0 tool (both `update` and `check`) with tag `kg-ssot-v4.17.2`. Tools from releases before 4.18.0
print in Portuguese. With a newer release, the tag, the commit, and the file count change:

```bash
git clone https://github.com/marciocar/kg-ssot ../kg-ssot
python3 -I -B ../kg-ssot/tools/kg_vendor.py update --tag kg-ssot-v4.17.2 --dest vendor/kg-ssot
```

```text
vendor updated: vendor/kg-ssot ← kg-ssot-v4.17.2 (d5a6cab1cb09), 504 files
```

`update` also writes `vendor/kg-ssot/.gitattributes` with `* -text`. A nested attribute wins over the repository's,
so the adopter's line-ending rules (`*.json text eol=lf`, `core.autocrlf`) do not rewrite the release bytes in the
index. The suite has fixtures with CRLF on purpose, and without this they would reach CI altered.

`check` recomputes the sha256 values and compares them with the stamp. A file that was edited, deleted, or added
(including bytecode in a `__pycache__`) gives rc 1, and `check` also verifies the vendor's `.gitattributes`. With
`--index`, `check` verifies the blobs in the git index, which is what the commit will carry, instead of the working
tree. Run it after `git add vendor/kg-ssot`: it catches, before the commit, a normalization that the working tree
hides.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_vendor.py check --dest vendor/kg-ssot
```

```text
✓ vendor intact: vendor/kg-ssot = kg-ssot-v4.17.2 (d5a6cab1cb09), 504 files
```

| Option | Effect |
|---|---|
| `--source REPO` | The repository (a path or a URL, such as `https://github.com/marciocar/kg-ssot`) that has the tag. Required when you run it from inside a vendor |
| `--dest DIR` | Where the vendor lives (default `vendor/kg-ssot`) |
| `--profile gate` | Brings only the minimum to run the gate and the check (12 files since 4.18.0, without the suite); `--profile full` goes back to the whole release |
| `--force` | Replaces a locally edited vendor |
| `--index` (on `check`) | Verifies the git index instead of the working tree |

**Why `-B`?** The kit's scripts do not write bytecode, but a tool of yours that **imports** a kit module writes the
`.pyc` file inside the vendor, and the next `check` fails. Run everything with `python3 -I -B`, or with
`PYTHONDONTWRITEBYTECODE=1`.

## `kg_store.py`: the store that writes only what passes

If you write graphs from a program (a write server, a chat, a pipeline that generates the graph of a case),
`kg_store.py` is a library, with a CLI on top, that writes only after the contract's PASS verdict. There are three
stores with the same interface (`read`, `list`, `write`, `delete`, `history`). The format comes from the name:
`.kg.yaml` is judged under the YAML profile and `.kg.json` under the contract's JSON profile
([chapter 3](03-format.md#the-same-model-in-kgjson)):

- `DiskStore`: only the head on disk, with no history;
- `GitStore`: one commit per write or delete. Git runs isolated at the store root and never climbs up to an outer
  repository. The author comes from the writer (`author="Name <email>"`), and the committer is a fixed service
  identity;
- `VersionedStore`: the head on disk plus an event log and the versions in the hidden `.kg-store/` directory, with no
  git.

From the PyPI package, it is `from kg_ssot import kg_store`. To import it from the vendor, put `vendor/kg-ssot/tools`
on `sys.path` and run without writing bytecode, as in [chapter 6](06-adoption-and-ci.md#in-an-app):

```python
import kg_store

store = kg_store.GitStore("areas/ana", init=True)
r = store.write("graphs/case.kg.yaml", text, message="first graph", author="Ana <ana@example.org>",
                expected_sha256=kg_store.NEW)
if not r["written"]:
    print(r["reason"], r["verdict"])   # "gate", "conflict", "missing", or "not_judged"
```

The gate judges more than the candidate. The external end of each `external_edges` entry is checked against the
store itself, with the candidate already in place. Every graph that points to the written name is judged again,
because replacing or deleting a graph can leave another graph's external edge without an end. The store writes only
when all of them PASS.

The corpus is the same one the repository gate would see. In `GitStore`, that means only what is tracked: a
`.kg.yaml` file on disk with no commit does not count, not in the list, not in the judgment, and not in the lock (for
the lock, the name is free, and the write replaces the file). `DiskStore` and `VersionedStore` refuse a root inside a
git repository, where the gate would read what is tracked and the store would read the disk. And the head changes
only once the record is made: if the commit or the event fails, the head goes back to what it was, and the exception
reaches the caller.

To regenerate graphs that cite each other, use `write_many` (since 4.14.0). One at a time, replacing the first graph
would leave the second graph's external edge without an end, and the re-judgment would block it. The whole set,
including removals (text `None`), is judged at once with every change in place, and it goes into a single record (one
commit, or one block of events), or nothing goes in:

```python
r = store.write_many([("case.kg.yaml", case), ("crossing.kg.json", crossing), ("old.kg.yaml", None)],
                     message="regenerate the case", expected={"case.kg.yaml": sha_read})
if not r["written"]:
    print(r["reason"], [x["reason"] for x in r["results"]])
```

On `conflict` and `missing`, the name that blocked the set carries the reason, and the others come back as
`skipped`. On `gate` and `not_judged`, the judgment covers the whole set, and every name comes back with that reason.
The external gate (`--gate-cmd`), if there is one, judges each change on its own, as in `write`. Names in the set that
differ only by case are refused, as in the store.

The CLI has one subcommand per operation, with JSON output on stdout:

```text
kg_store.py --backend disk|git|versioned --root DIR [--init] [--gate-cmd CMD [--gate-timeout S]] list
kg_store.py ... read NAME [--ref REF]
kg_store.py ... write NAME [FILE|-] [--message M] [--author "Name <email>"] [--expected-sha256 S|new]
kg_store.py ... delete NAME [--message M] [--author A] [--expected-sha256 S]
kg_store.py ... write-many SET.json [--message M] [--author A]
kg_store.py ... history NAME
```

From the CLI, a graph that passes and one that fails:

```bash
python3 -I -B vendor/kg-ssot/tools/kg_store.py --backend git --root areas/ana --init \
  write graphs/valid-minimal.kg.yaml vendor/kg-ssot/spec/conformance/fixtures/latest/form/minimal/valid-minimal.kg.yaml \
  --author "Ana <ana@example.org>" --message "first graph"
```

```text
{
 "written": true,
 "reason": null,
 "name": "graphs/valid-minimal.kg.yaml",
 "sha256": "b725f37669f2e5979ed8c02eaae3c59ba80a490177e2f28c0cb8a580cf51cfd7",
 "ref": "2c6e97cc668be073020246d673228ec11dddb9aa",
 "verdict": { … },
 "error": null,
 "unchanged": false
}
```

```bash
python3 -I -B vendor/kg-ssot/tools/kg_store.py --backend git --root areas/ana \
  write graphs/x.kg.yaml vendor/kg-ssot/spec/conformance/fixtures/latest/form/minimal/bad-node-missing-label.kg.yaml
```

```text
{
 "written": false,
 "reason": "gate",
 "name": "graphs/x.kg.yaml",
 ...
 "verdict": { "results": [ { "source": "graphs/x.kg.yaml", "verdict": "FAIL",
              "summary": { "MUST": { "form.required.node.label": 1 }, "SHOULD": {} }, ... } ] }
}
```

(The `verdict` is shortened here; it is the whole `kg-ssot.verdict/1` document.)

- **`reason`:** `null` when the write happened. `"gate"` means the contract failed the graph, and the `verdict` says
  where. `"conflict"` means `expected_sha256` does not match the head. `"missing"` shows up when you remove something
  that does not exist. `"not_judged"` shows up when the judgment failed or came out outside
  `spec/verdict.schema.json`: it never turns into PASS or `"gate"`, so the caller can tell "failed" from "could not be
  judged". With an external gate, `"gate"` with `error: "rejected by the external gate"` means the contract passed
  and the outside gate failed the graph; the `verdict` is the external gate's.
- **Optimistic locking:** `expected_sha256` is the sha256 of the head the writer read, or `NEW` (on the CLI, `new`) to
  require that the name does not exist yet. Writing the same text as the head returns `written` with `unchanged` and
  no commit.
- **The path:** the name is relative, ends in `.kg.yaml` or `.kg.json`, and has no `..` and no hidden segment. To keep
  a store portable across systems, it refuses to create a name with a reserved Windows segment (`CON`, `NUL`,
  `COM1`...) or one that ends in a period (what already exists keeps working), and no operation accepts a name that
  differs only by case from one already in the store. The root, the folders, and the file cannot be links:
  - **on macOS and Linux (POSIX),** everything opens through `dir_fd` with `O_NOFOLLOW`, and swapping a folder in the
    middle of an operation redirects nothing;
  - **on Windows,** which has no `dir_fd`, each step of the path is checked with `lstat` (symbolic links, junctions,
    and mount points are refused; a reparse point that does not redirect the name, such as a OneDrive on-demand file,
    passes), the opened file has to be the same one `lstat` saw, and the path is checked again after the read and, on
    a write, before the final swap. This is weaker: someone who can write inside the root can swap a folder between
    the check and the use. On a file system with no file id (the FAT of a USB drive), comparing the opened file proves
    nothing, and only the link refusal remains. In a single-person store, in that person's folder, this changes
    nothing; for a shared store, prefer POSIX.
- **History:** `history(name)` lists the operations, newest first, with `ref`, `op` (`write` or `delete`), author,
  date, and message. `read(name, ref=...)` reads an earlier version: the commit sha in git, the event `seq` in the
  versioned store.
- **Isolated git:** `GitStore` reads neither the system config nor the user config (no hooks, no gpg, no `autocrlf`,
  no excludes file), so what it stores is byte for byte the approved text, with the sha256 of the result.
- **The external gate (`--gate-cmd`):** the hook through which an adopter plugs in a second gate, its own, without
  the product depending on that gate. The command runs after the contract passes, on every write and every delete,
  and the store writes only when both PASS. A graph that the contract fails never reaches the command. A gate run by
  `kg_mcp.py` gets `KG_SSOT_LANG=en`, because its verdict goes to the model; run by `kg_store.py`, it inherits your
  language.
  - **Input:** the candidate text goes in on stdin as UTF-8 (empty on a delete); read it as bytes and decode it, so
    you do not depend on the system code page. The name and the operation go in the environment, as `KG_GATE_NAME`
    and `KG_GATE_OP` (`write` or `delete`). The command inherits the rest of the process environment, except the
    `kg_mcp` secret variable (`--secret-env`).
  - **Output:** a `kg-ssot.verdict/1` document that is valid under `spec/verdict.schema.json`, with at least one
    result, rc 0 when everything passes and rc 1 when something fails, and at most 16 MiB (the cap applies while it
    runs). The gate's stderr is discarded: to diagnose, run the command by hand with the same stdin and the same
    environment. An occurrence code has to start with a contract layer (`parse.`, `form.`, `integrity.`, or
    `yaml.`); an outside gate uses, for example, `integrity.external.<name>`.
  - **Fail-closed:** a command that does not run, that runs past `--gate-timeout` (default 60 s, at most 86,400), that
    exits with no JSON, with output that is too large, with JSON outside the schema or with no result, with an rc
    other than 0 or 1, or with an rc that does not match the verdict gives `"not_judged"`, never PASS, and nothing is
    written. On a timeout, an interrupt (Ctrl+C), a SIGTERM to the process, or output that is too large, the command
    and the processes it started are killed. On Windows, killing the process by force ("End task") gives no handler a
    chance to act, and a gate that is running may stay behind. On macOS and Linux, a process the gate leaves running
    after it ends cleanly is killed too (its process group); on Windows it is not, so an adopter's gate should leave
    nothing behind. `--gate-cmd ""` gives rc 2, so an empty variable never starts a server without its gate;
    `--gate-timeout` without `--gate-cmd` and, in `kg_mcp.py`, `--gate-cmd` with `--read-only` (the gate would never
    run) also give rc 2.
  - **The lock:** the gate runs under the write lock. A slow gate holds the other writes to the same store until
    `--gate-timeout`; over stdio, it holds the server.
  - **The same text:** writing the text of the latest version again also goes through the gate. If the gate fails it
    now, the answer is `"gate"`, even with nothing to change.
  - **No shell:** the command is a list of arguments, never a shell line. On macOS and Linux, the line follows the
    `shlex` rules (a backslash escapes; put the path in quotes). On Windows, double quotes group and a backslash stays
    as it is, as in the command `"C:\Program Files\Python\python.exe" C:\gates\x.py`. Quotes count around the whole
    argument: `--opt="a b"` becomes two arguments, and single quotes do not group. The graph text arrives only on
    stdin, so `$(...)` or `;` inside it runs nothing.
  - **From the library:** `open_store(..., gate=CommandGate(argv, timeout))`, or any callable
    `(name, text, op) -> (verdict, error)`. A callable that raises also gives `"not_judged"`.

  An example gate, with only the standard library, that fails any text containing the word FORBIDDEN:

  ```python
  import json, os, sys
  bad = "FORBIDDEN" in sys.stdin.buffer.read().decode("utf-8")
  occ = [{"level": "MUST", "code": "integrity.external.forbidden-word", "place": "arquivo", "path": "",
          "line": None, "message": "the text has a forbidden word"}] if bad else []
  print(json.dumps({"schema_version": "kg-ssot.verdict/1",
                    "contract": {"must": None, "should": None, "release": None, "sha256": {"must": None, "should": None}},
                    "results": [{"source": os.environ["KG_GATE_NAME"], "verdict": "FAIL" if bad else "PASS",
                                 "summary": {"MUST": {occ[0]["code"]: 1} if bad else {}, "SHOULD": {}},
                                 "occurrences": occ, "total": len(occ), "truncated": False,
                                 "external_checked": False}]}))
  sys.exit(1 if bad else 0)
  ```

  ```bash
  python3 -I tools/kg_store.py --backend versioned --root areas/ana --init \
    --gate-cmd "python3 -I gates/forbidden.py" write graphs/a.kg.yaml graph.kg.yaml
  ```
- **What stays with the adopter, on purpose:** authentication, identity, a per-user area (one root per user), maximum
  size, number of graphs, timeout, and the cross-process lock where there is neither `flock` nor `msvcrt`.
- **The CLI rc:** 0 written or read, 1 refused (`gate`, `conflict`, `missing`, a name that does not exist), and 2
  broken input or `not_judged`.

## `kg_mcp.py`: the reference MCP server

To give a model the contract and the store without writing a server, `kg_mcp.py` speaks the
[Model Context Protocol](https://modelcontextprotocol.io) over stdio (one JSON-RPC message per line) or over HTTP
(`POST /mcp`, JSON response, no stream). It uses only the standard library, the reader, and the store, and it is an
adapter: the product does not depend on it, and it does not depend on any particular client.

| Tool | What it does |
|---|---|
| `kg_validate` | Judges `.kg.yaml` text without writing it and returns the `kg-ssot.verdict/1` (with the store as the corpus, if there is a store) |
| `kg_write` | Writes through the store, only on PASS; returns the `kg_store` result with the verdict |
| `kg_delete` | Removes through the store, if no graph that points to the name fails without it |
| `kg_get` | Reads a graph, or an earlier version with `ref` |
| `kg_list` | Lists the graphs in the store |
| `kg_history` | The operations on a graph, newest first |
| `kg_query` | The `kg_query.py` query and projection over the store: filters, the open queue, the neighborhood, and `fields`, paginated by cursor |
| `kg_schema_help` | The current contract, for a model: the full MUST and SHOULD schemas, a minimal example that passes, the integrity rules, and the fix for the most common codes |

Since 4.17.2, each tool announces the MCP annotations in `tools/list`: the read tools (`kg_validate`, `kg_get`,
`kg_list`, `kg_query`, `kg_history`, `kg_schema_help`) with `readOnlyHint` and `idempotentHint`, and `kg_write` and
`kg_delete` with `destructiveHint`; all of them with `openWorldHint: false`, because the store is local. They are
hints for the client to ask for or skip confirmation; the store's gate still decides what gets written.

Without `--root`, only `kg_validate` and `kg_schema_help` appear. With `--read-only`, `kg_write` and `kg_delete` drop
out of the list.

With `--store-optional`, a root that does not open (a file in place of the folder, a folder without permission) does
not bring the server down. It starts with only `kg_validate` and `kg_schema_help` and tells the model why, in the
instructions, in the description of those two tools, and in a `store` field of `kg_schema_help`. That way the model
tells the user why there is no `kg_write`, instead of assuming a read-only mode. Without the option, a root that does
not open is rc 2, with the message on stderr.

A client configuration over stdio, with a versioned store outside the repository:

```json
{
  "mcpServers": {
    "kg-ssot": {
      "command": "python3",
      "args": ["-I", "-B", "vendor/kg-ssot/tools/kg_mcp.py",
               "--root", "/path/to/store", "--backend", "versioned", "--init",
               "--author", "Assistant <assistant@example.org>"]
    }
  }
}
```

| Option | Effect |
|---|---|
| `--root DIR` | The store. Without it, only `kg_validate` and `kg_schema_help` |
| `--backend disk\|git\|versioned` | The kind of store (default `disk`) |
| `--init` | Creates the root if it does not exist |
| `--author "Name <email>"` | Who signs the writes |
| `--read-only` | Removes `kg_write` and `kg_delete` |
| `--http PORT` · `--host H` · `--allow-remote` | HTTP instead of stdio; off the loopback, only with `--allow-remote`, which requires `--secret-env` |
| `--secret-env VAR` · `--secret-header H` | The shared secret, read from the variable `VAR`, that each HTTP request carries in header `H` (default `X-Api-Key`), compared with hmac |
| `--identity-header H` | The "behind a proxy" profile: each request's identity comes from header `H` (an email address), with its own area and author; requires `--secret-env` |
| `--max-bytes N` | The maximum size of a graph (default 2,000,000) |
| `--max-graphs N` | Graphs per store, or per area in the profile; past that, a new name is refused |
| `--max-concurrent N` | HTTP requests at the same time; past that, 503 |
| `--store-optional` | A root that does not open does not bring the server down: it starts without a store and tells the model why |
| `--gate-cmd CMD` · `--gate-timeout S` | An external gate after the contract, on every write and removal, also per area in the profile (see `kg_store.py`) |

A refused write, as the model receives it (the `structuredContent`, shortened):

```text
{
 "written": false,
 "reason": "gate",
 "name": "graphs/x.kg.yaml",
 "verdict": { "results": [ { "verdict": "FAIL",
   "occurrences": [ { "code": "form.required.node.label", "place": "nó Q_A", "path": "nodes[0]", "line": 5,
                      "message": "Missing required field \"label\" in the node.",
                      "hint": "Add label: the node's short claim, up to 280 characters." } ] } ] },
 ...
}
```

The `tools/call` response carries the same object in `structuredContent` and, as JSON text, in `content`. A refused
write or a name that does not exist comes with `isError: true`, so the model can fix it and try again.

- **Who signs:** the author of the writes is the server's `--author` or, in the "behind a proxy" profile, the
  request's authenticated identity. It is never a tool argument: the model does not choose who signs.
- **Limits:** `--max-bytes` (default 2,000,000) caps the text of a graph. The arguments are checked against the
  `inputSchema` that `tools/list` announces: a wrong type, a missing required field, and an unknown field come back
  as `isError`. An internal failure becomes JSON-RPC error -32603, and the process keeps serving.
- **The reader behind it:** a document that opens more than 1,000 collections at once (in flow style, in block style,
  or by indentation), or whose aliases expand to more than twice the size of the text, fails with `parse.yaml-error`
  before it is built. Without that cap, a 60 KB message brought the process down. A bracket inside text does not
  count.
- **The protocol:** one message at a time; a JSON-RPC batch is refused (it left MCP in 2025-06-18), and the id has to
  be a string or an integer. The stdio transport reads and writes UTF-8 as bytes, whatever the locale, and the
  response goes out as ASCII JSON.
- **HTTP:** listens on `127.0.0.1` by default. It refuses an `Origin` whose host is not loopback (against DNS
  rebinding), an unknown `MCP-Protocol-Version` (400), and a body without `Content-Length`. There is no TLS: the
  server leaves the loopback only with `--allow-remote`, which requires `--secret-env`, to run on a private network
  behind a proxy with TLS.
- **The "behind a proxy" profile (`--identity-header`):** the mode for a client with many users, such as LibreChat,
  that sends the logged-in user in a header.
  - **Refuses by default:** every request carries the identity (an email address) and the shared secret. With no
    identity, with an empty identity (LibreChat replaces a missing placeholder with empty text) or a malformed one, or
    with the wrong secret, the response is 401, before any tool runs.
  - **Area and author:** each identity writes to its own area under `--root`, in a `u-<name>-<hash>` directory, and
    cannot see anyone else's. Its writes are signed in the form `local-part <email>`. The email address is not
    case-sensitive: `Ana@X.org` and `ana@x.org` are the same identity.
  - **Per request:** identity, area, and author travel in a per-request context, never in a server attribute, which
    is shared across threads. Keeping them on the server would let a concurrent request write to another request's
    area, the class of CVE-2026-25536 in the TypeScript SDK. A deterministic test verifies that no request leaves or
    changes state on the server, and another test, with two identities in parallel, exercises the isolation end to
    end. A repeated identity or secret header is refused, so a proxy that appends the header instead of replacing it
    does not let the client choose the identity.
  - **The trust model:** whoever holds the secret can claim any identity. The secret authenticates the proxy
    (LibreChat), and the proxy authenticates the user. That is why the secret never goes to an end client, and the
    server sits on a network that only the proxy can reach.
  - **Limits:** `--max-graphs` applies per area and is counted under the write lock, so parallel writes cannot get
    past it together. `initialize`, `ping`, and notifications neither open nor create an area, and with
    `--read-only` an area that does not exist yet is not created. The number of areas has no limit: whoever holds the
    secret creates one per new identity (the trust model above), and the server keeps the open areas in memory while
    it runs.
  - **The root of the areas:** checked at startup. An empty value, a missing root without `--init`, a file, or a link
    gives rc 2, unless you pass `--store-optional`, as with a root outside the profile.
  - **The `untrusted_data` envelope:** `kg_get`, `kg_list`, and `kg_history` return `{"untrusted_data": ...,
    "notice": ...}`, so the model treats text written by others as data, never as instructions.
  - **What the profile is not:** it is "behind a proxy", on a private network. It is not the OAuth profile of the MCP
    specification, which waits until there is a measured matrix of clients.
- **The OCI image:** `ghcr.io/marciocar/kg-ssot:<version>` ships `kg-mcp` ready to run as a service next to a client
  without Python, such as LibreChat. It is built from the same wheel as PyPI, with the dependencies pinned by hash and
  the base pinned by digest (`packaging/oci/Dockerfile`), runs as an unprivileged user (uid 10001), and keeps the
  store in the `/data` volume. It carries the `io.modelcontextprotocol.server.name` label, which the MCP Registry uses
  to verify ownership. The mirror workflow publishes it behind an approval, with the provenance attestation
  (`gh attestation verify oci://ghcr.io/marciocar/kg-ssot:<version> --repo marciocar/kg-ssot`).
  - **Over stdio:** `docker run -i --rm ghcr.io/marciocar/kg-ssot:<version>` only judges. With `-v kg-data:/data` and
    `--root /data/graphs --init`, it writes.
  - **Next to LibreChat:** the "behind a proxy" profile, on the compose network and with no port published on the
    host:

    ```yaml
    # docker-compose.override.yml
    services:
      kg-ssot:
        image: ghcr.io/marciocar/kg-ssot:<version>
        command: ["--http", "8080", "--host", "0.0.0.0", "--allow-remote",
                  "--identity-header", "X-User-Email", "--secret-env", "KG_MCP_SECRET",
                  "--root", "/data/areas", "--init", "--backend", "versioned"]
        environment:
          KG_MCP_SECRET: ${KG_MCP_SECRET}
        volumes:
          - kg-data:/data
    volumes:
      kg-data:
    ```

    ```yaml
    # librechat.yaml
    mcpSettings:
      allowedDomains:  # a CLOSED list: only the listed domains pass, for every MCP server reached by URL
        - kg-ssot        # the service name in compose
        # - the domains of the other MCP servers this librechat.yaml already uses
    mcpServers:
      kg-ssot:
        type: streamable-http
        url: http://kg-ssot:8080/mcp
        headers:
          X-User-Email: "{{LIBRECHAT_USER_EMAIL}}"
          X-Api-Key: "${KG_MCP_SECRET}"
    ```

    An `allowedDomains` list that is not empty is closed: only its domains pass, for every MCP server reached by URL.
    If your `librechat.yaml` already has other servers, put their domains in the same list, or they stop working.

    The `--host 0.0.0.0` is the one inside the container: with no published port, only the containers on the compose
    network can reach the service (the default compose network is not `internal`, so the container can still reach
    the internet). Without `KG_MCP_SECRET`, the container exits with rc 2 and serves nothing. The secret lives in the
    compose `.env`, never in the versioned `librechat.yaml`. Like any container environment variable, it shows up in
    `docker inspect`: anyone with access to the host's docker can read it, just as they can already read the `.env`.
  - **The volume:** with a named volume, as in the compose file above, `/data` starts out owned by the image's user.
    With a host folder mounted at `/data`, the folder has to belong to uid 10001 (`chown 10001:10001 <folder>`);
    otherwise the container exits with rc 2 and `Permission denied`.
  - **The platform:** the image ships only for `linux/amd64`.
  - **What the image does not do:** TLS and exposure outside the compose network stay with the adopter's proxy, as
    in the profile.
- **In a repository:** the disk store and the versioned store refuse a root inside a git repository (see
  `kg_store.py`). Inside the repository, use `--backend git --root .`, which makes one commit per write on the current
  branch, outside any PR (run it on a work branch), or run without `--root` to only judge.
- **What stays with the adopter, on purpose:** TLS, the OAuth profile, per-user quotas, and per-tool timeouts.
- **A client that caches `tools/list`:** some clients, such as LibreChat, validate arguments against the
  `tools/list` they cached at startup. After an update that changes a tool's `inputSchema` (a new argument, a new
  value in an enum), restart the client, or it refuses the new argument before it calls the server. An adopter has
  already tripped on this and now restarts the client on deploy whenever `tools/list` changes.
- **The two protocol eras:** the server speaks both, and each request picks its era.
  - **The new era, `2026-07-28`, stateless:** every request carries in `params._meta` the version
    (`io.modelcontextprotocol/protocolVersion`) and the client capabilities
    (`io.modelcontextprotocol/clientCapabilities`).
    - **What the server implements:** `server/discover`.
    - **What every result carries:** `resultType` and the `serverInfo` in `_meta`.
    - **Cache hints:** `server/discover` and `tools/list` carry `ttlMs` and `cacheScope`, which is `private` in the
      "behind a proxy" profile, because the list depends on the area.
    - **Errors, with the HTTP status from the specification:**
      - a required `_meta` field is missing: -32602, with 400;
      - a version the server does not support: -32022, with 400 and, in `data.supported`, the same list as
        `server/discover` (both eras), by any path; a version from the old era requested in `_meta` also gives
        -32022, with a message saying it only works through `initialize`;
      - an unknown method: -32601, with 404;
      - a header that is missing or differs from the body (`MCP-Protocol-Version`, `Mcp-Method`, `Mcp-Name`, with the
        base64 sentinel): -32020, with 400.
  - **The old era (`2025-11-25`, `2025-06-18`, `2025-03-26`, `2024-11-05`):** keeps using `initialize`, which answers
    with the requested version when it knows it. The server never issues `Mcp-Session-Id`, and GET and DELETE give
    405.
  - **Measured with official clients:** the Python `mcp` SDK 2.3.0, which is v2, in the new era, over stdio and over
    HTTP; and the TypeScript SDKs 1.30.0, the one LibreChat uses, and 1.32.1 in the old era. CI runs all three.

## `kg_query.py`: query and projection over the corpus

Reads many graphs at once and selects nodes, without judging them (the verdict belongs to `kg_validate.py`). Each node
comes out projected: its outgoing and incoming edges, with the other end resolved to its label, local or external,
and whether that end exists in the corpus that was read. With `--root`, the corpus is the `.kg.yaml` and `.kg.json`
files that git tracks under the folder (outside git, all of them under it), and paths come out relative to it, since
it is the root that an external end `<path>#<id>` resolves against.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_query.py --root . --open --sort impact          # the open queue
python3 -I -B vendor/kg-ssot/tools/kg_query.py --root . --around alvo.kg.yaml#EV_A    # the neighborhood of a node
python3 -I -B vendor/kg-ssot/tools/kg_query.py --root . --text "gate base" --type decision --format json
```

Real output in the suite's `external-corpus` folder (trimmed):

```text
alvo.kg.yaml  EV_A  evidence/confirmed/DEV imp=3  A evidência sintética que sustenta A.
    → SUPPORTS Q_A  A pergunta sintética A.
    → REFUTES valid-corpus-external-refutes-refuted.kg.yaml#EV_A  A evidência sintética que sustenta A.
    → REFUTES warn-corpus-external-refutes-live.kg.yaml#EV_A  A evidência sintética que sustenta A.
    ← REFUTES valid-corpus-external-refutes-outgoing.kg.yaml#EV_A  A evidência sintética que sustenta A.
    ← SUPERSEDES valid-corpus-target-exists.kg.yaml (the whole graph)
```

| Option | What it does |
|---|---|
| `--root DIR` or files | The corpus. With `--root`, the vendor and the fixtures stay out by default (`vendor/*`, `fixtures/*`, `*/fixtures/*`, `docs/materials/*`); `--exclude GLOB` (repeatable) removes more paths, and `--no-default-excludes` reads everything. A file you name one by one is never excluded |
| `--id`, `--id-prefix`, `--type`, `--status`, `--plane`, `--layer`, `--file` | Filters, all combined with AND |
| `--text WORDS` | Words that the label contains, all of them, case-insensitive; `--in-narrative` also searches the narrative |
| `--open` | The open queue (status `open`) |
| `--verified-before YYYY-MM-DD` | Nodes with no `verified_at`, or verified before the date |
| `--around ID` | The neighborhood: `<path>#<id>`, or an id that is unique in the corpus; `--depth`, `--edge-type` (repeatable), `--direction out\|in\|both` |
| `--sort corpus\|impact` | Corpus order, or declared impact. The attention formula stays with the radar of whoever uses it |
| `--limit N` and `--cursor C` | The page (up to 1000) and the cursor for the next one, valid for the same query over the same corpus |
| `--fields GLOB` | Node keys that come out in `extra`, as they are in the graph: `--fields 'x_*'` |
| `--narrative` | Includes each node's narrative |
| `--format json` | The stable `kg-ssot.query/1` format (`spec/query.schema.json`) |

A graph that does not parse shows up in `unreadable`, with its `parse.*` code, and does not bring the query down. The
label of the other end of each edge is cut at 200 characters: a node with a long label cited by thousands of edges
does not multiply the response. rc 0 when the query ran, even with no node; 2 on broken input. In the MCP server, the
same query is the `kg_query` tool, over the store: the page stops at the server's byte cap (with at least one node),
and `next_cursor` picks up where it stopped. Each call rereads and reparses the area's store, and in a store of tens
of MB the first call takes tens of seconds; the judgment cache comes in 4.19.

## `kg_diff.py`: diff by id between revisions

Compares two graphs, or every graph that changed between two git revisions, aligning nodes by id and edges by their
ends and type. Whatever exists on only one side was added or removed, and whatever exists on both sides comes out with
each field that changed, before and after. Node order in the file does not count; an id change is a removal plus an
addition; a list inside a node is compared as a whole; an edge that changes type with the same ends comes out as an
`edge_type` change. The revision is read with `git show`, with no checkout. It is not a patch: the diff informs, it
does not apply.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_diff.py notice.kg.yaml erratum.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_diff.py HEAD~1:docs/x.kg.yaml HEAD:docs/x.kg.yaml
python3 -I -B vendor/kg-ssot/tools/kg_diff.py --from origin/main --ignore verified_at      # everything that changed on the branch
```

Real output, between two suite cases:

```text
valid-node-touched-only-as-target.kg.yaml (modified)
  ~ meta.id: valid-chain → valid-node-touched-only-as-target
  + C_ALVO  Nó sintético C_ALVO.
  - C_B  Nó sintético C_B.
  + edge EV_A -SUPPORTS-> C_ALVO
  - edge C_B -SUPPORTS-> EV_A
· 1 graph(s): 1 modified, 0 added, 0 removed, 0 unreadable; nodes +1 -1 ~0; edges +1 -1 ~0
```

A field that leaves one path and enters another with the same value, in a node, an edge, or the meta, shows up as a
rename (`x_location → x_storage (renamed)`) when the value is not trivial and is unique on both sides. In the JSON,
both entries stay, each with the value at its own path, linked by `renamed_to` and `renamed_from`; the human text and
the per-field summary show a single line. With `--from` and no paths, the vendor and the fixtures stay out (also a
`fixtures/` folder at the root), as in `kg_query`: a vendor update changes the suite fixtures by the hundreds.
`--exclude` and `--no-default-excludes` work the same way. The meta comes out together with the other root keys,
values are compared in the contract's JSON form, a renamed file comes out as a removal plus an addition, and without
`--to` the new graphs not yet added to git come in too. A side that cannot be read (not UTF-8, or does not parse)
shows up in `unreadable` and counts as a difference; a revision that starts with `-` is broken input. In an argument,
a path that exists on disk wins over a `REV:PATH` read.

`--ignore FIELD` (repeatable) removes a field from the comparison, together with everything below it (`provenance`
removes all three; in the meta, `meta.date`): a `verified_at` that a generator restamps on every run hides the signal,
and the summary counts nodes per changed field to show it. `--format json` gives `kg-ssot.diff/1`
(`spec/diff.schema.json`). rc 0 with no difference, 1 with a difference, 2 on broken input.

## `kg_prov_export.py`: provenance in PROV-O

Exports a `.kg.yaml` to [PROV-O](https://www.w3.org/TR/prov-o/) in JSON-LD, for anyone who already uses tools from the
W3C PROV ecosystem. Each node becomes a `prov:Entity`. A node with `provenance` gets `prov:wasDerivedFrom` pointing to
the source and a `prov:Derivation` whose activity carries the `method`; `locator` and `locality` go in as `kg:`
properties. A source that is entirely one http(s) URL becomes the IRI itself; any other source (a path, a command, two
URLs together) becomes a labeled blank node, one per distinct text, so nodes with the same source point to the same
entity.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_prov_export.py \
  vendor/kg-ssot/spec/conformance/fixtures/latest/form/method-vocabulary/valid-method-leitura.kg.yaml
```

An excerpt of the output, the node with `provenance`:

```text
   "@id": "urn:kg-ssot:graph:valid-method-leitura#EV_A",
   "@type": "prov:Entity",
   ...
   "prov:wasDerivedFrom": {
    "@id": "_:source0"
   },
   "prov:qualifiedDerivation": {
    "@type": "prov:Derivation",
    "prov:entity": {
     "@id": "_:source0",
     "rdfs:label": "Fonte A"
    },
    "prov:hadActivity": {
     "@type": "prov:Activity",
     "rdfs:label": "leitura: seção 3 do documento A"
    },
    "kg:locator": "caso de conformidade"
   }
```

What it does **not** export, on purpose:

- **The edges.** `SUPPORTS`, `REFUTES`, and the others are evidence relations, and derivation in PROV is a production
  relation. Exporting them as `wasDerivedFrom` would say something the graph does not say.
- **The stamp as a generation time.** `verified_at` comes out as `kg:verifiedAt` (typed `xsd:date` when it is a
  date), not as `prov:generatedAtTime`: in PROV, the generation time marks when the entity came into existence, not
  when it was verified.

The exporter does not validate the graph: run `kg_validate.py` first. `--base IRI` changes the prefix of the node IRIs
(the default is `urn:kg-ssot:graph:`, and each node sits at `<base><meta.id>#<id>`); the `kg:` vocabulary lives at
`urn:kg-ssot:vocab#`, outside that space. rc 2 when the file is unreadable, is not a single YAML document, or has a
malformed `meta` or `nodes`.

## `kg_migrate.py`: the profile-driven migrator

Proposes the `provenance` that contract v4 requires on `confirmed` or PROD nodes that do not have it yet, from a
**profile** that the adopter writes and versions: an ordered list of rules (`spec/kg-migrate-profile.schema.json`),
where the first rule that matches decides. There is a commented example in
`spec/migrate-examples/company-brain.profile.yaml`, measured on a real corpus of 25 graphs and 1,024 nodes.

```bash
python3 -I -B vendor/kg-ssot/tools/kg_migrate.py plan  --profile kg-migrate.profile.yaml --out proposals.tsv
python3 -I -B vendor/kg-ssot/tools/kg_migrate.py apply --profile kg-migrate.profile.yaml
```

- **`plan` writes nothing.** It prints the counts per rule and, with `--out`, writes the proposal sheet, one row per
  node, with what goes to the reviewer and why. Read the sheet before you run `apply`.
- **Each rule does one of three things:** propose the `provenance`, demote the node to `unverifiable` (the source is
  unrecoverable, which is the contract's default), or only send the node to review. A node that no rule matches also
  goes to review and gets nothing.
- **`when` matches on what the node already carries:** the trace (empty, URL, path, glob, existence in the tree,
  regular expression), the type, the status, the plane, `verified_against`, `source_kind`, and the `SUPPORTS` edges
  that reach the node, with `not` and `any_of`.
- **Templates use the node's fields:** `{trace}`, `{trace_path}`, `{trace_line}`, `{verified_against}`, `{supports}`,
  and `{source_kind}`, and `{a|b}` takes the first one that is not empty. The profile's `note` goes at the end of
  every `method` detail, for example `não reverificado na migração de 2026-10-20` (the note in the example profile).
- **`scopes` gives `verified_scope` only by a list of ids**, never by a text pattern.
- **The profile chooses within the contract and never relaxes it.** Every proposal is checked against the MUST schema
  and the SHOULD form schema before it becomes a proposal. A proposal that would fail goes to review with the reason,
  and so does a template that resolves to empty. A coherence warning that the proposal raises does not block it,
  because the warning tells the truth about the node. For example, a `testemunho` (testimony) on a PROD node raises
  `integrity.testimony-in-prod`: the proposal goes ahead, and the node goes to the reviewer with the warning named.
- **`apply` writes file by file, as text, and comments stay.** Afterward it rereads the file and checks the
  invariance: each node stays as it was, except the keys the action authorizes, and the diff only adds lines, except
  the line of a demoted status. A file that would gain a new MUST code, or a SHOULD warning that the plan did not
  announce, stays as it was. The file's line ending is kept (CRLF stays CRLF), and a file with mixed line endings is
  refused. Running it again changes nothing.
- **Without a list of graphs, the tool reads the `.kg.yaml` files from `git ls-files`.** It leaves out the
  `kg_gate.py` patterns (`*/fixtures/*` and `docs/materials/*`), `vendor/*`, and the `--exclude` globs, with the
  gate's semantics: `fnmatch` on the relative path, where `*` crosses `/`; the profile dialect's `**/`, which matches
  zero folders, also works. `--no-default-excludes` removes the patterns. Note: in the profile's `trace_path_glob`,
  `*` does not cross `/`. A listed graph that does not parse becomes a review row and does not abort the run.
- **A node whose `verified_scope` already matches the profile comes out as `same`**, separate from the nodes that change, and
  `apply` does not touch it.
- **The trace path is lexical and stays inside the repository root.** It is normalized (`./`, `a/../b`), and a path
  that leaves the root with `../` stops being a path. An absolute path or one with `~` counts as nonexistent, without
  looking at the machine's disk.

What stays out, on purpose, because it is judgment: rewriting a label, changing a plane, re-measuring, refuting,
reconciling with `SUPERSEDES`, and promoting an `unverifiable` node. rc 0 when the plan comes out or `apply`
finishes; rc 1 when `apply` refused a file, which stays as it was, with the reason in the report; rc 2 on broken input
(a profile outside the schema, a repeated rule or id, an invalid regular expression, a `when` that would match every
node, a graph given on the command line that does not parse). The migrator travels in the vendor, not in the PyPI or
npm package.
