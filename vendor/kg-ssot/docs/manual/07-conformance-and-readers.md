# 7. Conformance and readers

**English** | [Português (Brasil)](pt-BR/07-conformidade-e-leitores.md)

[← Adoption and CI](06-adoption-and-ci.md) · [Index](README.md) · [Recipes →](08-recipes.md)

The contract applies to **every reader** of `.kg.yaml`: a viewer, an extractor, a JavaScript port, a Go validator.
A reader proves it follows the contract by passing the suite, not by reading the specification and feeling sure it
understood. The full reference is [`spec/conformance/README.md`](../../spec/conformance/README.md).

## How the suite is built

- Each **group** is a folder with a `manifest.json` and one real `.kg.yaml` (or `.kg.json`) per case. The file is
  real so that any CLI reads it the way it would read an actual graph.
- Each case declares `valid`, the expected `codes` (MUST), and the expected `warnings` (SHOULD). `warnings` is
  optional, and a missing list counts as `[]`.
- **One case, one defect.** A reader passes a case when the **set** of codes it emits **equals** the expected set.
  Equality, not inclusion: a reader that flags everything does not pass. Order and repetition do not count.
- The suite validates itself: `manifest.schema.json` checks every manifest, and `metaschema-tests/` holds manifests
  the schema must accept and others it must reject.

```json
{
  "description": "Os enums do nó.",
  "layer": "form",
  "pending_on": [],
  "cases": [
    {
      "file": "bad-node-type-enum.kg.yaml",
      "description": "node_type fora do enum",
      "valid": false,
      "codes": [
        "form.enum.node.node_type"
      ]
    }
  ]
}
```

| Folder | What it means |
|---|---|
| `fixtures/latest/` | The current contract. Every reader **must** pass |
| `fixtures/optional/` | Behavior a reader **may** implement. It reports and does not fail |
| `fixtures/proposals/` | Cases that depend on an open decision. It is empty today |

## Write a reader

1. **Parse.** Read YAML with YAML 1.2 booleans, a single document, and a mapping at the root. A duplicate key
   fails (`1` and `"1"` collide). `.nan` and `.inf` fail. A `.kg.json` file goes through a JSON parser under the
   contract's JSON profile.
2. **Form.** Convert to canonical JSON (dates as ISO text, keys as text) and validate against
   `kg-contract-v4.schema.json`, with `format` as an **assertion**. Warnings come from
   `kg-contract-v4.should.schema.json`.
3. **Integrity.** Check unique ids, existing endpoints (`from`, `to`, `trigger`), no node of degree 0, the endpoints
   of `external_edges`, and the `integrity.*` warnings that span fields or edges.
4. **Codes.** Map each error to its stable code. The code table and the naming rules are in
   [chapter 4](04-contract.md#codes) and in the suite reference.

The reference reader, [`tools/kg_validate.py`](../../tools/kg_validate.py), is the model. Its comments explain
each rule, so you can read it alongside the suite.

### Three traps the suite catches

- **Text length in code points.** The 280-character limit on `label` counts code points, like JSON Schema
  `maxLength`. An emoji counts as 1. JavaScript `str.length` counts it as 2.
- **`format: date` as an annotation.** Many validators skip format checks by default. Here a bad date fails.
- **`$` before a line break.** The `pattern` values follow ECMA-262 semantics: `$` does not match before a trailing
  line break, unlike Python's `re`.

## Run the suite with your reader

`kg_conformance.py` runs only the reference reader, and the kit ships no tool that runs an outside reader over the
suite. Your reader runs the suite with its own code: it iterates over the `manifest.json` files in `fixtures/latest/`, judges each case
(with the repository root at `<manifest folder>/<corpus>` when the case declares `corpus`), and compares the sets of
`codes` and `warnings` for equality. A reader that does not expose codes compares only the verdict: `valid: true`
means accept, and `valid: false` means reject.

## The runner contract

So that the maintainer can measure your reader next to the reference reader, case by case, your reader exposes a
**runner**: `runner <case>` prints one JSON object on the last line of stdout and exits with rc 0.

```json
{"verdict": "accept", "codes": [], "warnings": [], "detail": ""}
```

- `verdict`: `accept`, `reject`, or `error`. This is level 1, and every reader has it.
- `codes` and `warnings`: the lists of codes, or `null` if the reader does not say why. This is level 2.
- A case that declares `corpus` in its manifest arrives as `runner <case> --corpus <dir>`.
- Output that is not JSON, an unknown `verdict`, an rc other than 0, or a timeout counts as `error`.

A reader that only gives the verdict is already comparable at level 1. Exposing the codes is level 2, and it is what
lets you diagnose a divergence.
