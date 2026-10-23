# 10. Glossary

**English** | [Português (Brasil)](pt-BR/10-glossario.md)

[← Troubleshooting](09-troubleshooting.md) · [Index](README.md)

| Term | Meaning |
|---|---|
| **Adopter** | A repository that brings in the contract by tag and runs the gate in CI |
| **Audit package** | One row per questionnaire item, with the question, the answer, the verdict, the dated evidence, the evidence requests, the owner, and the computed gaps, in CSV, XLSX, or JSON (`kg_audit.py`), since 4.22.0 |
| **Baseline** | The `.kg-ssot/gate/` folder with the debt the gate compares against: the contract identity and one record per graph (through 4.15.1, the single file `.kg-ssot/gate.json`) |
| **Canonical profile** | The shape the SHOULD gives to an `x_` key that adopters repeat (`x_term`, `x_mirror`, `x_severity`...), since v4.11; `x_criterion` and `x_measured_under` since v4.12. It only judges a key that is present, and only warns |
| **Class (of `method`)** | `medição` (measurement), `leitura` (reading), `juízes` (judges), `derivado` (derived), or `testemunho` (testimony) |
| **Code** | The stable identifier of a violation, such as `form.required.node.label` |
| **Conformance suite** | The cases in `spec/conformance/` that every reader must pass |
| **Contract** | The MUST and SHOULD schemas, plus the YAML profile rules and the integrity rules |
| **Corpus** | The set of graphs (`.kg.yaml` and `.kg.json`) in a repository |
| **External edge** | An edge in `external_edges`, with one end in another graph of the same repository |
| **`gate` profile** | The minimal part of the release: just enough to run the gate and the check |
| **Graph** | A `.kg.yaml` file, or its JSON form, a `.kg.json` file |
| **Inherited debt** | The graphs that already failed MUST when the baseline was recorded |
| **MUST** | The contract level that fails |
| **Node** | A typed claim in the graph |
| **Orphan** | A node with no edges. It fails |
| **Plane** | `DEV` or `PROD` |
| **Pre-registered criterion** | A yardstick fixed before the data, one node per version (`x_criterion`, with its `sha256`); a result cites the version it was measured under (`x_measured_under`), and a change after seeing the data is a dated amendment, since v4.12 |
| **Provenance** | The `provenance` object (`source`, `locator`, `method`): where the claim came from |
| **Ramp** | Two senses: (1) in the contract, a warning in one version about what will fail in the next; (2) in adoption, moving up a major version by recording what started to fail as debt, and paying it down over time |
| **Ratchet** | A check that only lets the measure improve or stay the same. The gate is the per-graph ratchet |
| **Reader** | Any program that reads `.kg.yaml` (or `.kg.json`). The reference reader is `kg_validate.py` |
| **Release** | A `kg-ssot-vX.Y.Z` tag with the surface listed in `spec/release.json` |
| **Runner** | The command that exposes a reader to the suite: `runner <case>` prints a JSON object with the verdict |
| **SHOULD** | The contract level that only warns |
| **SHOULD debt** | How many graphs (or occurrences) carry each warning |
| **Synonym** | An item of `x_term.labels`: another way to write the term, `alt` or `hidden`, with its own source, document version, and verification date |
| **Term** | A node with the `x_term` profile: the preferred label of a concept in a domain vocabulary, with its synonyms |
| **Testimony** | The `testemunho` class: an account from someone, or a third-party measurement that you only read |
| **Vendor** | The copy of the release inside the adopter, in `vendor/kg-ssot`, verified by `check` |
| **Vendor stamp** | The `.kg-ssot-version` file with the tag, the commit, the version, the contract, and the sha256 of each vendored file |
| **Verification stamp** | The pair `verified_at` and `verified_against` on a node |
| **`x_`** | The extension prefix: keys that start with it pass freely |
