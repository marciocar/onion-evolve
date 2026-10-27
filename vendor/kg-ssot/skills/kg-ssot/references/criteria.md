# Pre-registered criteria: `x_criterion` and `x_measured_under`

Use these when an acceptance rule must be fixed **before** the data, and a result must say which version of the rule
it was measured under. Changing the rule after seeing the data becomes a dated amendment, not a silent rewrite.

1. Write the rule's text, and get its sha256 with the kit:

   ```bash
   kg-criterion digest --text "p95 latency under 200 ms"
   ```

2. Put the criterion on its own node, one node per version:

   ```yaml
   - id: C_LATENCY_RULE_V1
     node_type: claim
     plane: DEV
     status: open
     impact: 3
     confidence: 0.8
     label: "Acceptance rule: p95 latency under 200 ms."
     x_criterion:
       id: "LATENCY"
       version: 1
       registered_at: "2026-10-26T09:00:00Z"
       sha256: "<the 64 hex characters that digest printed>"
       text: "p95 latency under 200 ms"
   ```

   - `id` stays the same across versions; `version` is a text or an integer.
   - Give exactly one of `text` (the rule itself) or `ref` (a file under the root that holds it), never both.
   - Quote the sha256, so it is never read as a number.
   - A new version is a new node with `amends: "<id of the previous version's node>"`, a `reason`, and a
     `SUPERSEDES` edge to the old node. Never edit a registered criterion in place.

3. Record the result on another node, citing the criterion it was measured under:

   ```yaml
   - id: E_LATENCY_RESULT
     node_type: evidence
     plane: DEV
     status: confirmed
     impact: 3
     confidence: 0.9
     label: "The measured p95 latency was 180 ms."
     provenance:
       source: "reports/latency-2026-10-26.md"
       locator: "p95 table"
       method: "measurement: load test"
     x_measured_under:
       measured_at: "2026-10-26T10:00:00Z"
       criteria:
         - criterion: "C_LATENCY_RULE_V1"
           sha256: "<the same sha256>"
       verdict: "pass"
   ```

   - `measured_at` must be later than the criterion's `registered_at`; give both a time with a time zone (RFC 3339)
     when they fall on the same day.
   - Link the two nodes with an edge (for example `TRACES_TO` from the result to the criterion).

4. Check the hashes and the citations:

   ```bash
   kg-validate latency.kg.yaml          # no integrity.criterion-* or integrity.measured-* line
   kg-criterion check latency.kg.yaml   # rc 0: each sha256 matches its text or file
   ```
