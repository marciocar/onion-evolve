---
title: 'ADR — Modelo operacional "Constelação de Estudos" (estudos isolados + core observatório sob convite)'
date: 2026-07-11
type: adr
status: proposto
decision-scope: meta / modelo operacional de orquestração do maestro
supersedes: none
deciders: maestro + sessão de evolução
context_freshness: 2026-07-11
related:
  - ../knowledge-base/concepts/constellation-of-studies.md (a doutrina nomeada)
  - ../knowledge-base/concepts/discussion-worktrees-pattern.md (a estrela isolada)
  - ../knowledge-base/concepts/knowledge-graph-sdaal.md (o reconciliador)
  - ../knowledge-base/concepts/authorization-layers-intake-vs-execution.md (intake sob convite)
---

# ADR — Constelação de Estudos (modelo operacional)

> **Status: PROPOSTO (design-only, gated).** A **Fase 0** entrega doutrina + schema (Tier-0 do SEED); as três
> ferramentas do core (mapa/radar/carteiro) ficam **diferidas ao gatilho** (§Rollout). Nada de código executável.

## Contexto

O maestro roda N estudos isolados (`discuss/*`) e pediu para **padronizar e documentar** a estratégia — com
visão macro, assistência do core sob convite, e **anti-divergência** (evitar duas soluções sobre bases frágeis
que não convergem). Dois Explore + um Plan confirmaram: as peças existem (isolamento, worklog Tier-0→3, KG
SDAAL, camadas-de-liberação, doc-bridge), **dispersas**; falta o **modelo que as amarra** e o tooling dos gaps
(macro cross-worktree, reconciliador cross-study, carteiro entre-worktrees, detector de convergência).

## Decisão

**1. Nomear e documentar o modelo — "Constelação de Estudos"** (KB
[constellation-of-studies](../../knowledge-base/concepts/constellation-of-studies.md)): maestro = sol/dono,
estudo = estrela, core = observatório sob convite (3 serviços: mapa/radar/carteiro). Loop: isolar → explorar
fundo → recolher ao macro → reconciliar → promover/descartar.

**2. Cada peça nova ESTENDE uma existente** — nunca reinventa. Invariante de reuso.

**3. Visão macro = só-metadados.** O mapa lê apenas o **frontmatter + bloco Tier-0 do SEED** (no disco, sem
checkout/push), nunca o corpo. Resolve a tensão isolamento × visibilidade pela linha do `authorization-layers`
(intake de metadados é seguro; conteúdo/ação exige convite).

**4. Anti-divergência = composição mapa + radar** (colisão de escopo · convergência de objetivo · premissas
rivais · base frágil compartilhada), disparando **antes** da divergência (hoje só post-hoc).

**5. O join cross-study é KG, não git.** Um **overlay curado** `docs/onion/graph/constellation.kg.yaml`
(grafo-de-grafos: nós = premissas de estudos distintos; arestas = REFUTES/SUPERSEDES entre elas). Preserva
"git merge não reconcilia verdades".

**6. Fase 0 agora — schema do SEED Tier-0:** estender o SEED com `phase` · `next_action` · `scope_globs` ·
`objective_tags`. É o que o mapa (Fase 1) consome.

## Trade-offs (honestidade)

- **Overlay curado × auto-detecção.** O join cross-study começa **curado à mão** (soberano, determinístico,
  exige curadoria) + heurística de candidato (overlap de tokens → ⚠ humano confirma). Embeddings/cosseno =
  **Fase 4 gated** (espelha a "Fase 2 semântica" já anotada no KG; cada instância implementa com seu stack).
- **Single-machine.** Ler SEEDs entre worktrees só funciona numa máquina — e tudo bem: a Constelação é do
  maestro numa máquina; o cross-máquina é a **Federação** (eixo ortogonal, `federation-console`).
- **Custo de autoria.** O bloco Tier-0 no SEED custa ~4 campos por estrela × o ganho do macro. Mitigado por
  `_template/SEED.md` mínimo.
- **Isolamento × visibilidade.** Resolvido por **só-metadados** (frontmatter/Tier-0, nunca corpo, nunca push).
- **Beacon cego entre worktrees irmãs** (per-working-tree) — o mapa **substitui** o farol como sinal de
  colisão entre estrelas (via `scope_globs`), sem precisar do farol-compartilhado (que fica gated).

## Rollout faseado (gated)

- **Fase 0 — AGORA (doc/doutrina, zero código):** a KB + este ADR + o schema Tier-0 no SEED + `docs/discussions/`
  (README + `_template/SEED.md`) em `main`.
- **Fase 1 — `constellation-map.sh` + `/meta:constellation`** (🗺️ mapa). Gatilho: **já cumprido** (5 estrelas
  vivas, macro manual dolorido) — mas o maestro escolheu doc-primeiro; abre no "vai". Read-only, molde
  `federation-status-scan.sh`. Maior valor/menor risco.
- **Fase 2 — `kg-constellation-radar.sh`** (🔬 radar) + wiring de colisão/convergência no mapa. Gatilho: **duas
  estrelas colidirem/divergirem de fato** ≥1 vez **E** ≥2 estrelas terem `.kg.yaml`. Reusa `kg-radar.sh`.
- **Fase 3 — `study-deliver.sh` + `/meta:study-surface`** (📬 carteiro) + hook 📥. Gatilho: maestro copiar um
  estudo pro core à mão ≥2×. Reusa `co-deliver.sh` (I3 + W6).
- **Fase 4 — candidatos por embeddings** (radar semântico). Gatilho: ruído do overlay curado pedir.

## O que explicitamente NÃO fazer agora (guardas anti-v4.0)
- **Não** construir mapa/radar/carteiro nesta fase (design-alvo, gated).
- **Não** o farol-compartilhado entre worktrees irmãs (anotado em `worktree-convention-2026` §caveat; só em colisão real).
- **Não** auto-ingerir estudos no core (fere intake-sob-convite).
- **Não** mergear grafos via git (o overlay curado é o único join).
- **Não** embeddings na Fase 1 (determinístico primeiro).
- **Não** o mapa escrever nada (read-only estrito).

## Consequências
- **Positivas:** nomeia e padroniza uma prática já viva (5 estrelas); dá ao maestro um modelo de macro +
  anti-divergência reusando peças provadas; o schema Tier-0 destrava o mapa quando o maestro quiser.
- **Custo:** a Fase 0 entrega doutrina, não o painel — o macro segue manual (`ls ~/worktrees/` + ler SEEDs) até
  a Fase 1. Deliberado: o maestro pediu documentar primeiro; construir o painel à frente do "vai" seria o erro v4.0.
