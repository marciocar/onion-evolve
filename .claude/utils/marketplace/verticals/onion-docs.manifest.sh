# Manifesto da vertical Documentação → plugin onion-docs (consumido por assemble-plugin.sh).
# SSOT = .claude/; o plugin é artefato gerado. Camada 1 só (business/technical-context = camada 2 do consumidor).
# NOTA: build-compliance-docs.md NÃO entra aqui — é da vertical onion-compliance (evita sobreposicao).
PLUGIN_NAME="onion-docs"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Vertical de documentacao do Onion: contexto de negocio/tecnico como spec-as-code, C4 (Context/Container/Component) + Mermaid, health/validacao de docs e engenharia reversa. Camada 1; business/technical-context = camada 2 do consumidor."
KEYWORDS=(docs c4 mermaid spec-as-code documentation onion)

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
)
AGENTS=(
  ".claude/agents/development/c4-architecture-specialist.md"
  ".claude/agents/development/c4-documentation-specialist.md"
  ".claude/agents/development/docs-reverse-engineer.md"
  ".claude/agents/development/mermaid-specialist.md"
  ".claude/agents/development/system-documentation-orchestrator.md"
)
UTILS=()
VALIDATION=()

# Capability Contract (auto-descrição — ADR onion-adr-capability-contract-2026-06).
CONFORMANCE="silver"
PROVIDES=("business-technical-context" "c4-model-mermaid" "docs-health-validacao" "engenharia-reversa")
REQUIRES=(
  "agent:c4-architecture-specialist"
  "agent:c4-documentation-specialist"
  "agent:mermaid-specialist"
  "agent:docs-reverse-engineer"
)
LOADS=()
