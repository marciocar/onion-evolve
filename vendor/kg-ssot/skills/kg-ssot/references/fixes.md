# Fixes for the common codes

Each line is the code `kg-validate` prints and the fix. The text comes from the KG-SSOT reference MCP server
(`kg_schema_help`), so it matches the tools of the release.

| Code | Fix |
|---|---|
| `form.pattern.node.provenance.method` | Use the form '<class>: <detail>', with class measurement, reading, judges, derived, or testimony. |
| `form.pattern.node.provenance.source` | Write the source of truth (URL, path, command); with no recoverable source, remove provenance and change the status to unverifiable. |
| `form.range.node.label` | Shorten the label to 280 characters and move the rest to narrative. |
| `form.required.node.label` | Add label: the node's short claim, up to 280 characters. |
| `form.required.node.provenance` | Add provenance with source, locator, and method; with no recoverable source, change the status to unverifiable. |
| `integrity.criterion-amends-mismatch` | Point amends to the previous version of the same criterion (never to itself or to a later one), with the same x_criterion.id. |
| `integrity.criterion-digest` | If the criterion changed, register an amendment (a new node with amends and reason) instead of editing it in place; if not, write the sha256 that kg_criterion.py digest prints. |
| `integrity.criterion-malformed` | Quote the sha256 (a hash of digits alone reads as a number) and give exactly one of ref and text, in text. |
| `integrity.criterion-ref-unreadable` | Point ref to a file under the root; a fragment is a JSON Pointer (/a/0) or the id of a list item, in a .json, .yaml, or .yml file. |
| `integrity.criterion-sha-mismatch` | Do not edit a criterion in place: register an amendment (a new node with amends, reason, and SUPERSEDES to the old one) and keep the old result tied to the old sha256. |
| `integrity.criterion-unknown` | Cite the id of the node that holds the criterion version (x_criterion); a criterion in another graph is <path>#<id>, which kg_criterion.py check verifies. |
| `integrity.duplicate-id` | Give each node a unique id. |
| `integrity.measured-order-unknown` | Give registered_at and measured_at a time with a time zone (RFC 3339). |
| `integrity.measured-post-hoc` | The criterion was set after seeing the data. Measure again under it, or keep the result and say so in the narrative. |
| `integrity.orphan-node` | Every node needs at least one edge. Link it to another node in edges (from: its id, to: the other id, edge_type: TRACES_TO, SUPPORTS, or DEPENDS_ON, whichever states the relation), or remove the node. |
| `integrity.refutes-unreconciled` | If the refutation holds, change the status of the target to refuted or superseded; if not, remove the edge or use CONSTRAINS (the dissent that limits without overturning). |
| `integrity.term-notation-duplicate` | Give one of them another notation, put them in different schemes (x_term.scheme), or retire the old term (status superseded, with SUPERSEDES from the new one). |
| `integrity.testimony-in-prod` | Keep the node in DEV, or back it with a verified measurement or reading. |
| `integrity.trace-target-missing` | Point trace: to where the file is now (it was moved or renamed?), or to the commit that had it. |
| `integrity.untraced-decision` | Add trace, provenance, or a TRACES_TO edge leaving the decision. |
| `integrity.verified-before-fact` | If the fact takes effect in the future (a rule read before it comes into force), the warning is expected and can stay in the gate baseline. If not, the dates are swapped: valid_from is when the fact started to hold, and verified_at is when it was verified. |
| `yaml.depth-over-128` | Flatten the structure: a real graph stays within 3 or 4 levels. |
| `yaml.forbidden-key-on` | Replace on: with trigger:. |
| `yaml.lone-surrogate` | Replace the lone escape with the whole character (the high and low pair) or remove it. |
| `yaml.unquoted-date` | Put the date in quotes, for example verified_at: "2026-10-13". |
| `yaml.unsafe-integer` | Write the number in quotes, as text, or use a value within ±9007199254740991. |

## Formats

- **.kg.yaml:** the .kg.yaml: restricted YAML 1.2 core (unique keys, no .nan or .inf, quoted dates); an integer outside ±(2^53−1), a lone surrogate and more than 128 levels only warn
- **.kg.json:** the .kg.json: the same model in JSON, in the contract profile (RFC 8259 and I-JSON). It fails an integer outside ±(2^53−1) (form.type), a lone surrogate, more than 128 levels, NaN, a comment, a trailing comma, whitespace outside the RFC and a BOM that is not the leading one (parse.yaml-error), and a repeated key (parse.duplicate-key). kg_validate asks for format: json; kg_write reads by the extension of the name.

## Integrity rules

- a single document (YAML, or a JSON object in the .kg.json), with a map at the root
- unique node ids; every edge links two ids that exist; no node is left without an edge
- the external end (other.kg.yaml#ID or other.kg.json#ID) must exist in the store
- quoted dates ("2026-10-13"), never bare
