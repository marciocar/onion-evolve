# Mapa de Adoções — Federação Onion (snapshot congelado de 2026-07-10)

<!-- snapshot congelado — não regenerar; contexto no repo (site/README.md) -->

> Retrato de **10 de julho de 2026** — preservado como registro histórico.

```mermaid
flowchart TD
  onion_evolve["onion-evolve<br/>source"]:::source
  metagamify["metagamify<br/>hub · legacy"]:::hub
  pulse_mais["pulse-mais<br/>standalone · greenfield"]:::standalone
  granaai["granaai<br/>standalone · regulated"]:::standalone
  onion_mini["onion-mini<br/>standalone · distilled"]:::standalone
  metagamify -->|adopts| onion_evolve
  pulse_mais -->|adopts| onion_evolve
  granaai -->|adopts| onion_evolve
  granaai -.->|can-correct| onion_evolve
  onion_mini -->|adopts| onion_evolve
  classDef source fill:#1f6feb,color:#fff,stroke:#0b3d91;
  classDef hub fill:#238636,color:#fff,stroke:#033a16;
  classDef standalone fill:#8957e5,color:#fff,stroke:#3c1e70;
```

## Membros (derivado do SSOT)

| id | tier | mode | specializations | pin |
|----|------|------|-----------------|-----|
| onion-evolve | source |  | framework-template, sdaal, co-evolution, dogfooding, breadcrumbs | `—` |
| metagamify | hub | legacy | gamification, nx-monorepo, asana-integration, metagamification | `8e22352da32f` |
| pulse-mais | standalone | greenfield | education, srl-plea, learning-materials | `c711baa17617` |
| granaai | standalone | regulated | regulated-fintech, canonicalization, ssot-governance | `4332ac8d1884` |
| onion-mini | standalone | distilled | distilled-methodology, entry-level, multi-platform, task-management-lite, plea-cycles | `n/a` |
