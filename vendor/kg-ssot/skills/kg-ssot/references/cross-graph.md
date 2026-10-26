# Edges between graphs: `external_edges`

An edge to a node in **another file** goes in the top-level list `external_edges`, never in `edges`. One end is a node
of this file (its id); the other is `<path relative to the repository root>#<id>`.

```yaml
edges: []          # the edges inside this file; keep the key, even empty
external_edges:
  - from: C_NEW_LIMIT
    to: "docs/old.kg.yaml#C_OLD_LIMIT"
    edge_type: SUPERSEDES
```

- Allowed types: `SUPERSEDES`, `CONSTRAINS`, `SUPPORTS`, `REFUTES`, `TRACES_TO`, `DEPENDS_ON`.
- Omit `from` to mean "this whole graph".
- The path is relative to the repository root, uses `/`, and ends in `.kg.yaml` or `.kg.json`. A folder that starts
  with a dot (`.github/`) is fine; `.` and `..` segments are not.
- The local end counts as an edge for the node, so it is not left without an edge.
- **Keep both files coherent.** When the new node supersedes the old one, also change the old node's `status` to
  `superseded` in its own file. When it refutes it, use `refuted` (or `superseded`).
- Validate with the corpus so the external end is checked: from the repository root, `git add` both files first (the
  corpus is the set of files git tracks), then run `kg-validate --corpus . new.kg.yaml old.kg.yaml`. Without
  `--corpus` the external end is not verified, and a file git does not track yet shows up as
  `integrity.dangling-external`.
