# Manifesto da vertical Design → plugin onion-design (consumido por assemble-plugin.sh).
# SSOT = .claude/; o plugin é artefato gerado. Camada 1 só (design-context = camada 2 do consumidor).
PLUGIN_NAME="onion-design"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Vertical de design do Onion: identidade visual como spec-as-code (tokens W3C/DTCG), gate WCAG e materializacao via design-sink. Auto-adapta ao design-context do consumidor (SDAAL)."
KEYWORDS=(design design-tokens wcag dtcg onion sdaal)

COMMANDS=(".claude/commands/design")
AGENTS=(
  ".claude/agents/development/design-system-specialist.md"
  ".claude/agents/development/brand-generator.md"
  ".claude/agents/product/branding-positioning-specialist.md"
)
UTILS=(".claude/utils/design-source" ".claude/utils/design-sink")
VALIDATION=(".claude/validation/lint-design-tokens.sh")
