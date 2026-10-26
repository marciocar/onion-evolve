# Domain vocabulary: `x_term`

Use `x_term` on a node when the graph records a term of a domain vocabulary: the preferred name, its synonyms and
where they come from. It follows SKOS: `pref` is the preferred label, and each synonym is an `alt` (shown) or a
`hidden` (matched, never shown) label.

```yaml
- id: T_CHARGEBACK
  node_type: entity
  plane: DEV
  status: confirmed
  impact: 3
  confidence: 0.9
  label: "Chargeback is the payments term for a disputed card payment reversed to the cardholder."
  provenance:
    source: "Card network rulebook"
    locator: "section 4.2"
    method: "leitura: rulebook section on disputes"
  x_term:
    pref: "chargeback"
    scheme: "payments"
    labels:
      - literal: "payment dispute"
        kind: alt
        source: "Card network rulebook"
        locator: "section 4.2"
      - literal: "reversal"
        kind: alt
        source: "Card network rulebook"
        locator: "section 4.2"
```

- `pref` (required in the profile): the preferred term.
- `scheme`: the vocabulary the term belongs to, as a slug (lowercase letters, digits, hyphens). Without it, the
  vocabulary is the graph itself.
- `labels`: a list of objects, each with `literal` and `kind` (`alt` or `hidden`), and optionally `source`,
  `locator`, `version`, `verified_at`, `scope` and `retired: true` for a synonym no longer in use.
- Other optional keys: `lang`, `definition`, `notation` (a code; two live terms in the same scheme cannot share it).
- A retired term is a node with `status: superseded` and a `SUPERSEDES` edge from the new term. Never use a nested
  `status` key inside `x_term`.
- The node still needs an edge like any node (for example `TRACES_TO` to the question or claim that uses the term).

Check the vocabulary of a whole repository with `kg-vocab terms --root .` and `kg-vocab lint --root .`.
