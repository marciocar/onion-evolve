# Mapa de Adoções — Federação Onion (GERADO; não editar à mão)

> Gerado por `.claude/validation/graph.sh --map` de `docs/evolution/federation/members.yaml` (SSOT).
> **Derivado**, não desenhado à mão — muda quando o `members.yaml` muda. Renderiza no GitHub sem build.

```mermaid
flowchart TD
  onion_evolve["onion-evolve<br/>source"]:::source
  metagamify["metagamify<br/>standalone · legacy"]:::standalone
  pulse_mais["pulse-mais<br/>standalone · greenfield"]:::standalone
  granaai["granaai<br/>standalone · regulated"]:::standalone
  gustavo_pulga["gustavo-pulga<br/>standalone · greenfield"]:::standalone
  onion_mini["onion-mini<br/>standalone · distilled"]:::standalone
  onion_standalone["onion-standalone<br/>standalone · greenfield"]:::standalone
  hub_operacoes_enterprise["hub-operacoes-enterprise<br/>hub · greenfield"]:::hub
  brain_granaai["brain-granaai<br/>hub · brownfield"]:::hub
  vendas_pdi_enterprise["vendas-pdi-enterprise<br/>standalone · greenfield"]:::standalone
  onion_core["onion-core<br/>hub · greenfield"]:::hub
  onion_codex["onion-codex<br/>standalone · distilled"]:::standalone
  marcio_pessoal["marcio-pessoal<br/>standalone · regulated"]:::standalone
  onion_pedro["onion-pedro<br/>standalone · greenfield"]:::standalone
  onion_arthur["onion-arthur<br/>standalone · greenfield"]:::standalone
  poc_venda_direta_pdi["poc-venda-direta-pdi<br/>standalone · greenfield"]:::standalone
  arandek["arandek<br/>standalone · legacy"]:::standalone
  onion_dist["onion-dist<br/>standalone · greenfield"]:::standalone
  sge["sge<br/>standalone · regulated"]:::standalone
  hub_formacao_enterprise["hub-formacao-enterprise<br/>hub · greenfield"]:::hub
  sacola_de_ideias["sacola-de-ideias<br/>standalone · greenfield"]:::standalone
  portal_gamificacao["portal-gamificacao<br/>standalone · greenfield"]:::standalone
  jogo_da_vida["jogo-da-vida<br/>standalone · greenfield"]:::standalone
  onion_slm["onion-slm<br/>standalone · greenfield"]:::standalone
  onion_curation["onion-curation<br/>standalone · greenfield"]:::standalone
  onion_kg_ssot["onion-kg-ssot<br/>standalone · greenfield"]:::standalone
  metagamify -->|adopts| onion_evolve
  pulse_mais -->|adopts| onion_evolve
  granaai -->|adopts| onion_evolve
  granaai -.->|can-correct| onion_evolve
  gustavo_pulga -->|adopts| onion_evolve
  onion_mini -->|adopts| onion_evolve
  onion_standalone -->|adopts| onion_evolve
  hub_operacoes_enterprise -->|adopts| onion_evolve
  brain_granaai -->|adopts| onion_evolve
  brain_granaai -.->|can-correct| onion_evolve
  vendas_pdi_enterprise -->|adopts| onion_evolve
  onion_core -->|adopts| onion_evolve
  onion_codex -->|adopts| onion_evolve
  marcio_pessoal -->|adopts| onion_evolve
  onion_pedro -->|adopts| onion_evolve
  onion_arthur -->|adopts| onion_evolve
  poc_venda_direta_pdi -->|adopts| onion_evolve
  arandek -->|adopts| onion_evolve
  onion_dist -->|adopts| onion_evolve
  sge -->|adopts| onion_evolve
  hub_formacao_enterprise -->|adopts| onion_evolve
  sacola_de_ideias -->|adopts| onion_evolve
  portal_gamificacao -->|adopts| onion_evolve
  jogo_da_vida -->|adopts| onion_evolve
  onion_slm -->|adopts| onion_evolve
  onion_curation -->|adopts| onion_evolve
  onion_kg_ssot -->|adopts| onion_evolve
  classDef source fill:#1f6feb,color:#fff,stroke:#0b3d91;
  classDef hub fill:#238636,color:#fff,stroke:#033a16;
  classDef standalone fill:#8957e5,color:#fff,stroke:#3c1e70;
```

## Membros (derivado do SSOT)

| id | tier | mode | specializations | pin |
|----|------|------|-----------------|-----|
| onion-evolve | source |  | framework-template, sdaal, co-evolution, dogfooding, breadcrumbs | `—` |
| metagamify | standalone | legacy | gamification, nx-monorepo, asana-integration, metagamification | `21213cc6c3d6` |
| pulse-mais | standalone | greenfield | education, srl-plea, learning-materials | `c711baa17617` |
| granaai | standalone | regulated | regulated-fintech, canonicalization, ssot-governance | `6cc162f32d1c` |
| gustavo-pulga | standalone | greenfield | field-dogfood, greenfield-adoption | `c9eb2c40bc3b` |
| onion-mini | standalone | distilled | distilled-methodology, entry-level, multi-platform, task-management-lite, plea-cycles | `n/a` |
| onion-standalone | standalone | greenfield | framework-door, role-scoped-adopt, public-distribution, claude-code | `685140eadd7d` |
| hub-operacoes-enterprise | hub | greenfield | hub, task-manager-integration, itsm | `cff9214c3b9a` |
| brain-granaai | hub | brownfield | company-brain, clickup, pesquisa-primaria | `663fdbc5bdcc` |
| vendas-pdi-enterprise | standalone | greenfield | vendas, spec-as-code, rag-bridge | `24118c5d7a97` |
| onion-core | hub | greenfield | public-door, full-machinery, hub-role, deterministic-guards | `8278fee79d1c` |
| onion-codex | standalone | distilled | substrate-port, openai-codex, portability-proof, deterministic-guards | `n/a` |
| marcio-pessoal | standalone | regulated | life-kg, kg-sdaal-method, research-arm, n1-dogfood | `n/a` |
| onion-pedro | standalone | greenfield | field-dogfood, greenfield-adoption, compliance | `165e1e13b11f` |
| onion-arthur | standalone | greenfield | greenfield-adoption, design, branding, storytelling | `165e1e13b11f` |
| poc-venda-direta-pdi | standalone | greenfield | greenfield-adoption, document-comparison, compliance-nda, public-procurement | `219e9a5f365b` |
| arandek | standalone | legacy | field-dogfood, legacy-adoption, monorepo, upstream-signal | `65d8a7501a03` |
| onion-dist | standalone | greenfield | distribution-algorithms, kg-sdaal-method, research-arm, benchmarking | `e88c1e11e051` |
| sge | standalone | regulated | licitacao-publica, lei-14133, regulated-greenfield, analise-tecnica, checklist-qualidade | `ba0d2d423c17` |
| hub-formacao-enterprise | hub | greenfield | hub-de-adocao, formacao-hands-on, company-brain, spec-as-code | `f32e2f931c73` |
| sacola-de-ideias | standalone | greenfield | astro-site, institutional, greenfield-dogfood | `8e2517724c0a` |
| portal-gamificacao | standalone | greenfield | gamification, maagica, collaborator-layer, kg-sealing-field-signal, domain-kb-two-layers | `2e3f3a6f88ce` |
| jogo-da-vida | standalone | greenfield | gamification, maagica, expo-universal, turborepo, kg-radar-js-port, pre-adoption-dogfood | `2e3f3a6f88ce` |
| onion-slm | standalone | greenfield | slm, eval-de-dominio, roteiro-gradual | `9e75a73d0401` |
| onion-curation | standalone | greenfield | curadoria, dissecacao, mercado | `7818b8a25ae6` |
| onion-kg-ssot | standalone | greenfield | kg-ssot, schema, produto | `fe8359e38b43` |
