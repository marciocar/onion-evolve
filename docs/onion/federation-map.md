# Mapa de Adoções — Federação Onion (GERADO; não editar à mão)

> Gerado por `.claude/validation/graph.sh --map` de `docs/evolution/federation/members.yaml` (SSOT).
> **Derivado**, não desenhado à mão — muda quando o `members.yaml` muda. Renderiza no GitHub sem build.

```mermaid
flowchart TD
  onion_evolve["onion-evolve<br/>source"]:::source
  metagamify["metagamify<br/>hub · legacy"]:::hub
  pulse_mais["pulse-mais<br/>standalone · greenfield"]:::standalone
  granaai["granaai<br/>standalone · regulated"]:::standalone
  gustavo_pulga["gustavo-pulga<br/>standalone · greenfield"]:::standalone
  onion_mini["onion-mini<br/>standalone · distilled"]:::standalone
  onion_standalone["onion-standalone<br/>standalone · greenfield"]:::standalone
  marcio_pessoal["marcio-pessoal<br/>standalone · regulated"]:::standalone
  metagamify -->|adopts| onion_evolve
  pulse_mais -->|adopts| onion_evolve
  granaai -->|adopts| onion_evolve
  granaai -.->|can-correct| onion_evolve
  gustavo_pulga -->|adopts| onion_evolve
  onion_mini -->|adopts| onion_evolve
  onion_standalone -->|adopts| onion_evolve
  marcio_pessoal -->|adopts| onion_evolve
  classDef source fill:#1f6feb,color:#fff,stroke:#0b3d91;
  classDef hub fill:#238636,color:#fff,stroke:#033a16;
  classDef standalone fill:#8957e5,color:#fff,stroke:#3c1e70;
```

## Membros (derivado do SSOT)

| id | tier | mode | specializations | pin |
|----|------|------|-----------------|-----|
| onion-evolve | source |  | framework-template, sdaal, co-evolution, dogfooding, breadcrumbs | `—` |
| metagamify | hub | legacy | gamification, nx-monorepo, asana-integration, metagamification | `9547ca7b3f72` |
| pulse-mais | standalone | greenfield | education, srl-plea, learning-materials | `c711baa17617` |
| granaai | standalone | regulated | regulated-fintech, canonicalization, ssot-governance | `6cc162f32d1c` |
| gustavo-pulga | standalone | greenfield | field-dogfood, greenfield-adoption | `c9eb2c40bc3b` |
| onion-mini | standalone | distilled | distilled-methodology, entry-level, multi-platform, task-management-lite, plea-cycles | `n/a` |
| onion-standalone | standalone | greenfield | framework-door, role-scoped-adopt, public-distribution, claude-code | `514dda85833a` |
| marcio-pessoal | standalone | regulated | life-kg, kg-sdaal-method, research-arm, n1-dogfood | `n/a` |
