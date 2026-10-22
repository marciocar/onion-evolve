# 9. Troubleshooting

**English** | [Português (Brasil)](pt-BR/09-problemas.md)

[← Recipes](08-recipes.md) · [Index](README.md) · [Glossary →](10-glossary.md)

Run `kg_validate.py --where <file>` first. It tells you the code and the node.

## Common MUST codes

| Code | What it means | How to fix it |
|---|---|---|
| `form.required.node.provenance` | A `confirmed` or PROD node has no `provenance` | Add `source`, `locator` and `method`. If there is no source, change the status to `unverifiable` |
| `form.pattern.node.provenance.source` | `source` is a placeholder (`unknown`, `n/a`, `tbd`, `?`...) | Use the real source. If no source can be recovered, remove the `provenance` and use `unverifiable` |
| `form.unknown-key.node.<key>` | The key is not in the grammar | Prefix it with `x_`, or use the contract field (for example, `narrative`) |
| `form.required.node.<field>` | One of the seven required fields is missing | Add the field |
| `form.enum.node.<field>` | The value is not in the list (`node_type`, `plane`, `status`) | See the lists in [chapter 3](03-format.md) |
| `form.pattern.node.verified_at` | The date has the wrong format, or does not exist on the calendar | Use `YYYY-MM-DD`, in quotes |
| `integrity.orphan-node` | A node has no edge at all | Every node needs at least one edge: in `edges`, set `from:` to its id, `to:` to the id of another node, and `edge_type` to the relation (`TRACES_TO`, `SUPPORTS`, `DEPENDS_ON`...). If there is no relation, remove the node. `--where` shows the fix with the id |
| `integrity.dangling-to` · `-from` · `-trigger` · `-on` | The edge (or its trigger) points to an id that does not exist | Fix the id, or create the node |
| `integrity.duplicate-id` | Two nodes have the same id | Rename one of them |
| `integrity.dangling-external-local` | The local end of an `external_edges` entry does not exist in this file | Fix the id |
| `integrity.dangling-external` | The external end does not exist in the corpus | Fix the path or the id after `#`. Or the target graph is not in git yet (`git add`) |
| `yaml.forbidden-key-on` | An edge has the `on` key | Replace it with `trigger` |
| `parse.duplicate-key` | A key repeats in the same mapping | Remove the duplicate |
| `parse.not-single-document` | The file has more than one YAML document (`---`) | Keep one graph per file |
| `parse.yaml-error` | The YAML does not parse (or goes past the nesting or alias limit). In the contract profile, this also covers a tab outside quotes, block scalars and comments, a `!` tag with no name, and a `!!timestamp` that is not a date | Fix the syntax on the line the error points to. Replace the tab with spaces, and put the date in quotes |
| `parse.empty-document` · `parse.root-not-mapping` | The file is empty, or the root is not a mapping | A graph starts with `meta:`, `nodes:` and `edges:` |

The full list, with the shape of each code, is in
[`spec/conformance/README.md`](../../spec/conformance/README.md#codes).

## Common SHOULD warnings

| Code | How to fix it |
|---|---|
| `yaml.unquoted-date` | Put dates in quotes: `"2026-10-12"` |
| `yaml.unsafe-integer` | An integer goes past ±(2^53−1), and a JavaScript reader loses the exact value. Write it as text, in quotes. In `.kg.json`, it fails |
| `yaml.lone-surrogate` | The text has a lone surrogate (U+D800 to U+DFFF without its pair). Fix the text. In `.kg.json`, it fails |
| `yaml.depth-over-128` | The file nests more than 128 collections. Flatten the structure. In `.kg.json`, it fails |
| `form.range.node.label` | Shorten the `label` to 280 characters or less, and move the rest to `narrative` |
| `form.pattern.node.provenance.method` | Use `<class>: <detail>`, with the class in `medição` (measurement), `leitura` (reading), `juízes` (judges), `derivado` (derived) or `testemunho` (testimony). It fails in v5 |
| `form.required.node.verified_against` | Add `verified_against`: say what you checked on the `verified_at` date |
| `form.required.node.verified_at` | A PROD node has no `verified_at`, or has `verified_scope` without the date. Stamp the last check |
| `form.enum.node.verified_scope` | Use `fato`, `mecanismo` or `nenhum` |
| `integrity.untraced-decision` | Give the decision an origin: `trace`, `provenance` or a `TRACES_TO` edge |
| `integrity.refutes-unreconciled` | The node receives `REFUTES` and is still live: the graph asserts and refutes the same thing. If the refutation holds, change the target's status to `refuted` or `superseded`. If it does not, remove the edge or change the status of the refuting node. Today this is a warning, and it will fail in a future contract version |
| `integrity.verified-before-fact` | `verified_at` is earlier than `valid_from`. If the fact takes effect in the future (a regulation read before it comes into force), the warning is expected and can stay in the gate baseline. If not, the dates are swapped: `valid_from` is when the fact started to hold, and `verified_at` is when you checked it |
| `integrity.testimony-in-prod` | Measure it and change the class to `medição`, or accept the risk in plain sight |

## The gate

| Symptom | Cause | What to do |
|---|---|---|
| `GATE BROKEN  missing baseline (.kg-ssot/gate): write the first one with --update` (pt-BR: `GATE QUEBRADO  linha de base ausente`) | There is no `.kg-ssot/gate/` (and no `.kg-ssot/gate.json` from before 4.16.0) | Run `kg_gate.py --update` and commit the baseline |
| `· identity contract_sha256: the baseline is from …` (pt-BR: `· identidade contract_sha256: a base é de …`) | The new tag changed the schemas, but no verdict changed | Nothing to do. Write the new identity with `kg_gate.py --update` whenever you want |
| Merge conflict in `.kg-ssot/gate.json` | The baseline from before 4.16.0 is a single file | Upgrade to 4.16.0 or later and run `kg_gate.py --update`: the baseline becomes the folder, with one record per graph |
| Conflict in `.kg-ssot/gate/contract.json`, or modify/delete on `gate.json`, in the first merge after the migration | One branch migrated to the folder while the other still changed `gate.json` | Keep the folder, run `git rm .kg-ssot/gate.json` and `kg_gate.py --update`. Migrate the live branches before you merge to avoid the conflict |
| A new graph does not show up in the measurement | The gate only measures tracked files | Run `git add` on the graph |
| `✗ WORSE` (pt-BR: `✗ PIOROU`) on a graph you did not touch | The contract moved to a new tag, and the graph now fails | Write the new baseline with `--update`. A regression needs `--accept-regression "<reason>"` |
| The vendor's fixtures ended up in the corpus | You used `--no-default-excludes` | Drop the option, or pass `--exclude` |

## The vendor

| Symptom | Cause | What to do |
|---|---|---|
| `check` returns rc 1 even though you edited nothing | A tool that imported the kit wrote a `.pyc` into the vendor | Delete the `__pycache__` and run everything with `python3 -I -B` |
| `update` refuses to replace the vendor | The target has no stamp, or the vendor diverges from it | With no stamp, the target is not a vendor, and `--force` does not help: pick another `--dest`, or move the directory out of the way yourself. If it diverges, run `check` to see what changed. Use `--force` only if the local edit can go away |
| `update` fails when run from inside the vendor | `--source` is missing | Pass `--source https://github.com/marciocar/kg-ssot` |

## Environment

`pip install` fails with `externally-managed-environment`: create a venv (`python3 -m venv .venv`) and use its
Python. See the details in [chapter 6](06-adoption-and-ci.md#environment-note).
