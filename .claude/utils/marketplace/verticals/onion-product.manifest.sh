# Manifesto da vertical Produto → plugin onion-product (consumido por assemble-plugin.sh).
# SSOT = .claude/; o plugin é artefato gerado. Camada 1 só (o task-manager do consumidor via SDAAL).
PLUGIN_NAME="onion-product"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Vertical de produto do Onion: descoberta a backlog (collect→refine→spec→feature), decomposicao de tasks agnostica, estimativas (story points), extracao de reunioes e apresentacoes. Camada 1; o task-manager do consumidor via SDAAL."
KEYWORDS=(product backlog task-management story-points discovery onion)

COMMANDS=(".claude/commands/product")
AGENTS=(
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
UTILS=()
VALIDATION=()
# Skill de contexto: contrato SSOT mínimo + resolver de business-context (auto-suficiente em repos
# não-adotados). Ver .claude/skills/onion-product-context/.
SKILLS=(".claude/skills/onion-product-context")
# KB de framework EMBARCADO (tipo A) — os mais citados: extração de reuniões (9×), story points (8×),
# pain-price (6×). SSOT segue em docs/knowledge-base/; o plugin leva cópia gerada → funciona sem adopt.
DOCS=(
  "docs/knowledge-base/concepts/meeting-transcription-to-knowledge-base.md"
  "docs/knowledge-base/frameworks/framework-story-points.md"
  "docs/knowledge-base/concepts/identificar-precificar-dor-cliente.md"
)

# Capability Contract (auto-descrição — ADR onion-adr-capability-contract-2026-06).
CONFORMANCE="silver"
PROVIDES=("descoberta-a-backlog" "decomposicao-de-tasks" "estimativa-story-points" "extracao-de-reunioes" "apresentacoes" "ssot-context-resolver")
REQUIRES=(
  "agent:product-agent"
  "agent:task-specialist"
  "agent:story-points-framework-specialist"
  "agent:pain-price-specialist"
  "agent:extract-meeting-specialist"
  "skill:onion-product-context"
)
# tipo A embarcado (kb/); tipo B resolvido pela skill (business-context do consumidor).
LOADS=(
  "embed:kb/framework-story-points.md"
  "embed:kb/identificar-precificar-dor-cliente.md"
  "when:spec -> resolve:business-context (skill onion-product-context)"
)
