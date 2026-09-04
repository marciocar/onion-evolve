# onion — o NÚCLEO do Sistema Onion como plugin: orquestrador mestre, runtime de knowledge graph
# (kg + radar soberano + freshness), sessões, diário, orquestração, condução (wizard/onboarding/retro),
# validação de meta-specs, co-evolução upstream e os adapters SDAAL (task-manager, forge).
# 2026-09-04 (F2 da revisão para o diretório oficial): ABSORVEU onion-work-tools — a pesquisa R1 mostrou que o
# canal premia bundle vertical coeso, e work-tools era um saco de ferramentas que duplicava skill/motor/KB do núcleo.
# REGRA 61: manifesto publicável NUNCA lista meta-fábrica (create-*/adopt/marketplace/decouple/evolve/absorb-skill/
# federation-*) nem docs/onion/graph/*. co-evolve/co-relay (upstream) são permitidos por desenho.

PLUGIN_NAME="onion"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Núcleo operacional do Sistema Onion: o orquestrador mestre (skill onion), runtime de knowledge graph (kg + radar soberano + kg-freshness), sessões e diário, orquestração de subagentes, condução (wizard/onboarding/retro), validação de meta-specs, co-evolução upstream e os adapters SDAAL de task-manager e forge."
KEYWORDS=(onion orchestration knowledge-graph sdaal dogfood elenxo runtime diary metaspec co-evolution)

# Ordem: o absorvido PRIMEIRO, o dono DEPOIS — na colisão de basename (README.md/help.md) o assembler deixa o último vencer.
COMMANDS=(
  ".claude/commands/meta/kg.md"
  ".claude/commands/meta/diary.md"
  ".claude/commands/meta/orchestrate.md"
  ".claude/commands/meta/analyze-complex-problem.md"
  ".claude/commands/meta/metaspec-validate.md"
  ".claude/commands/meta/recover.md"
  ".claude/commands/meta/all-tools.md"
  ".claude/commands/meta/kb-freshness.md"
  ".claude/commands/meta/context-freshness.md"
  ".claude/commands/meta/constellation.md"
  ".claude/commands/meta/setup-integration.md"
  ".claude/commands/meta/setup-code-review.md"
  ".claude/commands/meta/co-evolve.md"
  ".claude/commands/meta/co-relay.md"
  ".claude/commands/meta/backlog.md"
  ".claude/commands/quick/analysis.md"
  ".claude/commands/warm-up.md"
  ".claude/commands/catch-up.md"
  ".claude/commands/onion.md"
  ".claude/commands/meta/kg-freshness.md"
)
AGENTS=(
  ".claude/agents/meta/metaspec-gate-keeper.md"
  ".claude/agents/meta/onion.md"
)
SKILLS=(
  ".claude/skills/onion-orchestration"
  ".claude/skills/onion-wizard"
  ".claude/skills/onion-onboarding"
  ".claude/skills/onion-retro"
  ".claude/skills/onion"
  ".claude/skills/language-standards"
  ".claude/skills/onion-patterns"
  ".claude/skills/onion-validation"
)
HOOKS=(
  ".claude/hooks/bash-empty-result-guard.sh"
  ".claude/hooks/aside-router-hook.sh"
)
UTILS=(
  ".claude/utils/diagnose"
  ".claude/utils/task-manager"
  ".claude/utils/forge"
)
VALIDATION=(
  ".claude/validation/kg-radar.sh"
  ".claude/validation/kg-backlog-project.sh"
  ".claude/validation/kg-backlog-check.sh"
  ".claude/validation/lib/status-factor.awk"
  ".claude/validation/kg-console.sh"
  ".claude/validation/kg-view.sh"
  ".claude/validation/vendor/kg-console/cytoscape.min.js"
  ".claude/validation/kg-narrate-validate.sh"
  ".claude/validation/diary-index.sh"
  ".claude/validation/constellation-map.sh"
  ".claude/validation/session-beacon.sh"
  ".claude/validation/kg-provenance-coverage.sh"
  ".claude/validation/resolve-integration-branch.sh"
  ".claude/validation/aside-router.sh"
)
TEMPLATES=()
DOCS=(
  "docs/knowledge-base/concepts/knowledge-graph-sdaal.md"
  "docs/knowledge-base/concepts/onion-elenxo-doctrine.md"
  "docs/knowledge-base/concepts/onion-dogfooding-doctrine.md"
  "docs/knowledge-base/agentic-patterns/ai-strategies/behavior-over-declaration.md"
  "docs/knowledge-base/meta/onion-framework-identity.md"
)

# Capability Contract (ADR onion-adr-capability-contract-2026-06): provides=o que entrega · requires=deps (type:value) · loads=contexto condicional · conformance=tier
CONFORMANCE="silver"
PROVIDES=(
  "master-orchestration"
  "knowledge-graph-runtime"
  "kg-freshness-reverify"
  "sdaal-task-manager"
  "sdaal-forge"
  "session-runtime"
  "dogfood-doctrine"
  "language-standards"
  "knowledge-graph-sdaal"
  "learning-diary"
  "orchestration"
  "metaspec-validation"
  "freshness-audits"
  "constellation-map"
  "co-evolution-upstream"
  "guided-conduction"
  "guided-onboarding"
  "retro-feedback"
)
REQUIRES=(
  "skill:onion-orchestration"
  "agent:metaspec-gate-keeper"
)
LOADS=(
  "embed:kb/onion-dogfooding-doctrine.md"
  "embed:kb/knowledge-graph-sdaal.md"
  "embed:kb/behavior-over-declaration.md"
  "when:warm-up|catch-up -> read(KG) via validation/kg-radar.sh (motor; o adotante tem os proprios .kg.yaml)"
  "embed:kb/onion-elenxo-doctrine.md"
  "when:kg -> run:validation/kg-radar.sh (motor soberano; door gera seus proprios .kg.yaml)"
  "when:kg backfill -> run:validation/kg-provenance-coverage.sh (mede o passivo; --scope sem --baseline nao arma catraca)"
  "when:diary -> run:validation/diary-index.sh"
)
