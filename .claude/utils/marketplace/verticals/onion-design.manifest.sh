# Manifesto da vertical Design → plugin onion-design (consumido por assemble-plugin.sh).
# SSOT = .claude/; o plugin é artefato gerado. Camada 1 só (design-context = camada 2 do consumidor).
PLUGIN_NAME="onion-design"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Vertical de design do Onion: identidade visual como spec-as-code (tokens W3C/DTCG), gate WCAG e materializacao via design-sink. Auto-adapta ao design-context do consumidor."
KEYWORDS=(design design-tokens wcag dtcg onion sdaal)

COMMANDS=(".claude/commands/design")
AGENTS=(
  ".claude/agents/development/design-system-specialist.md"
  ".claude/agents/development/brand-generator.md"
  ".claude/agents/product/branding-positioning-specialist.md"
)
UTILS=(".claude/utils/design-source" ".claude/utils/design-sink")
VALIDATION=(".claude/validation/lint-design-tokens.sh")

# Capability Contract (auto-descrição — ADR onion-adr-capability-contract-2026-06).
# provides=o que entrega · requires=deps (type:value) · loads=contexto condicional · conformance=tier.
CONFORMANCE="gold"
PROVIDES=("design-tokens-w3c-dtcg" "wcag-contrast-gate" "materializacao-css-tailwind-shadcn")
REQUIRES=(
  "agent:design-system-specialist"
  "agent:brand-generator"
  "agent:branding-positioning-specialist"
  "validation:lint-design-tokens.sh"
  "util:design-source"
  "util:design-sink"
)
LOADS=(
  "when:brief -> kb-or-context:business-context"
  "when:material -> reuse:presentation/canva"
)
