# The contract, field by field

Generated from the KG-SSOT contract v4 (`spec/kg-contract-v4.schema.json`). The `kg-validate` command applies it;
this page only helps you write a graph that passes.

## The file

- `meta` (required): `schema_version` (the text `"1"`) and `id` (a name for the graph), plus optional keys.
- `nodes` (required): the list of nodes.
- `edges`: the list of edges inside the file.
- `external_edges`: edges to a node in another graph, written `<relative path>#<id>` (for example `docs/other.kg.yaml#C_OLD`).
- Any extra key you add yourself starts with `x_`.

## Node

Required: `id`, `node_type`, `plane`, `status`, `impact`, `confidence`, `label`.

- `node_type`: `entity`, `claim`, `decision`, `question`, `evidence`, `artifact`, `state`, `event`, `rule`, `invariant`, `policy`. The first six are the audit layer (what was claimed, measured and decided); the rest describe a domain (`layer: domain`).
- `status`: `open`, `confirmed`, `drifted`, `unverifiable`, `refuted`, `superseded`, `done`.
- `plane`: `DEV`, `PROD`. `PROD` means the node describes something live in production.
- `impact`: an integer from 1 to 5. `confidence`: a number from 0 to 1.
- `label`: the short claim (up to 280 characters is the recommended form). `narrative`: the context and the why.
- `verified_at` (a quoted date) and `verified_against` (what you checked it against): when and against what the claim was last verified.
- `provenance`: `source`, `locator` and `method` (`<class>: <detail>`, class one of `measurement`, `reading`, `judges`, `derived`, `testimony`; the Portuguese `medição`, `leitura`, `juízes`, `derivado`, `testemunho` are accepted aliases since v4.16), and optionally `locality`: `repo` (a file in this repository), `web` (a public address), `privado` (a document others can read only with access), `host` (only on one machine) or `pessoa` (a person's account). Required on a `confirmed` node and on a `PROD` node.
- `valid_from` (a quoted date or year), `source_tier` (1 to 10) and `source_kind`: optional, on evidence, for when the fact became true and how strong the source is.
- `verified_scope`: optional, `fato` (the claim itself was checked), `mecanismo` (only the mechanism, such as code) or `nenhum`.
- `trace`: a file path or URL the node points to; `kg-trace check` verifies it exists.
- `reverify_every` (an ISO 8601 duration such as `"P30D"`), `reverify_on` and `owner` (a role, never a person's name): optional, for re-verification cadence.

## Edge

Required: `from`, `to`, `edge_type`.

- `edge_type`: `SUPPORTS`, `REFUTES`, `SUPERSEDES`, `CAUSES`, `DEPENDS_ON`, `TRACES_TO`, `CONSTRAINS`, `HAS_STATE`, `TRANSITIONS`, `EMITS`, `READS`, `WRITES`.
- In the audit layer: `SUPPORTS` (evidence backs a claim), `REFUTES` (it contradicts it; the target cannot stay `confirmed`), `SUPERSEDES` (a new node replaces an old one, which stays recorded), `CONSTRAINS` (it limits without overturning), `DEPENDS_ON`, `CAUSES` and `TRACES_TO`.
- In the domain layer: `HAS_STATE`, `TRANSITIONS` (with `trigger:` naming an `event` node), `EMITS`, `READS`, `WRITES`.
- `label`: optional, a short phrase for the relation.

