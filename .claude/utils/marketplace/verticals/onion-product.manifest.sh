# onion-product — vertical de PRODUTO: descoberta a backlog (collect→refine→spec→feature), decomposição
# de tasks agnóstica, story points, extração de reuniões, apresentações E — desde 2026-09-04 (F2) — a
# DOCUMENTAÇÃO de contexto (business/technical context, C4 + Mermaid, engenharia reversa, docs-health),
# absorvendo onion-docs: descoberta→backlog→docs de contexto é um ciclo só.
# Ordem do COMMANDS[]: docs/ primeiro, product/ depois (o último vence na colisão de README.md).

PLUGIN_NAME="onion-product"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Vertical de produto do Onion: descoberta a backlog (collect→refine→spec→feature), decomposição de tasks agnóstica ao provider, story points, extração de reuniões, apresentações e documentação de contexto (business/technical context, C4 + Mermaid, engenharia reversa, docs-health)."
KEYWORDS=(product backlog task-management story-points discovery docs c4 mermaid spec-as-code onion)

# Ordem: o absorvido PRIMEIRO, o dono DEPOIS — na colisão de basename (README.md/help.md) o assembler deixa o último vencer.
COMMANDS=(
  ".claude/commands/docs/build-business-docs.md"
  ".claude/commands/docs/build-tech-docs.md"
  ".claude/commands/docs/build-index.md"
  ".claude/commands/docs/consolidate-documents.md"
  ".claude/commands/docs/docs-health.md"
  ".claude/commands/docs/validate-docs.md"
  ".claude/commands/docs/refine-vision.md"
  ".claude/commands/docs/reverse-consolidate.md"
  ".claude/commands/docs/sync-sessions.md"
  ".claude/commands/docs/help.md"
  ".claude/commands/product"
)
AGENTS=(
  ".claude/agents/development/c4-architecture-specialist.md"
  ".claude/agents/development/c4-documentation-specialist.md"
  ".claude/agents/development/docs-reverse-engineer.md"
  ".claude/agents/development/mermaid-specialist.md"
  ".claude/agents/development/system-documentation-orchestrator.md"
  ".claude/agents/product/product-agent.md"
  ".claude/agents/product/task-specialist.md"
  ".claude/agents/product/story-points-framework-specialist.md"
  ".claude/agents/product/pain-price-specialist.md"
  ".claude/agents/product/storytelling-business-specialist.md"
  ".claude/agents/product/presentation-orchestrator.md"
  ".claude/agents/product/extract-meeting-specialist.md"
  ".claude/agents/product/meeting-consolidator.md"
  ".claude/agents/development/clickup-specialist.md"
  ".claude/agents/development/jira-specialist.md"
  ".claude/agents/development/gamma-api-specialist.md"
  ".claude/agents/development/whisper-specialist.md"
)
SKILLS=(
  ".claude/skills/onion-product-context"
)
HOOKS=()
UTILS=()
VALIDATION=()
TEMPLATES=()
DOCS=(
  "docs/knowledge-base/concepts/meeting-transcription-to-knowledge-base.md"
  "docs/knowledge-base/frameworks/framework-story-points.md"
  "docs/knowledge-base/concepts/identificar-precificar-dor-cliente.md"
)

# Capability Contract (ADR onion-adr-capability-contract-2026-06): provides=o que entrega · requires=deps (type:value) · loads=contexto condicional · conformance=tier
CONFORMANCE="silver"
PROVIDES=(
  "descoberta-a-backlog"
  "decomposicao-de-tasks"
  "estimativa-story-points"
  "extracao-de-reunioes"
  "apresentacoes"
  "ssot-context-resolver"
  "business-technical-context"
  "c4-model-mermaid"
  "docs-health-validacao"
  "engenharia-reversa"
)
REQUIRES=(
  "agent:product-agent"
  "agent:task-specialist"
  "agent:story-points-framework-specialist"
  "agent:pain-price-specialist"
  "agent:extract-meeting-specialist"
  "skill:onion-product-context"
  "agent:c4-architecture-specialist"
  "agent:c4-documentation-specialist"
  "agent:mermaid-specialist"
  "agent:docs-reverse-engineer"
)
LOADS=(
  "embed:kb/framework-story-points.md"
  "embed:kb/identificar-precificar-dor-cliente.md"
  "when:spec -> resolve:business-context (skill onion-product-context)"
)
