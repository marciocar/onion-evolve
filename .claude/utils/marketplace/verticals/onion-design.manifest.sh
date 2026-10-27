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
# utils/design-setup: o motor do /design:setup · utils/scope: o resolve-context-dir.sh que o setup, a skill e a
# guarda do grafo chamam · utils/kg: a classe do caminho de máquina que o kg-contract-check.sh importa.
UTILS=(".claude/utils/design-source" ".claude/utils/design-sink" ".claude/utils/design-setup" ".claude/utils/scope" ".claude/utils/kg")
# design-context-check: a guarda do grafo do design-context (onda 1, 2026-10-27); o radar e o contrato que o
# /design:setup manda rodar no grafo viajam juntos (sem vendor/kg-ssot no projeto o contrato sai 2, declarado).
VALIDATION=(
  ".claude/validation/lint-design-tokens.sh"
  ".claude/validation/design-context-check.sh"
  ".claude/validation/design-context-check.py"
  ".claude/validation/kg-radar.sh"
  ".claude/validation/lib/status-factor.awk"
  ".claude/validation/kg-contract-check.sh"
)
# Skill de contexto: contrato SSOT mínimo + resolver do design-context (o brief, os tokens e o grafo).
SKILLS=(".claude/skills/onion-design-context")

# Capability Contract (auto-descrição — ADR onion-adr-capability-contract-2026-06).
# provides=o que entrega · requires=deps (type:value) · loads=contexto condicional · conformance=tier.
CONFORMANCE="gold"
PROVIDES=("design-tokens-w3c-dtcg" "wcag-contrast-gate" "materializacao-css-tailwind-shadcn" "design-setup" "ssot-context-resolver" "design-context-graph")
REQUIRES=(
  "agent:design-system-specialist"
  "agent:brand-generator"
  "agent:branding-positioning-specialist"
  "validation:lint-design-tokens.sh"
  "util:design-source"
  "util:design-sink"
  "util:design-setup"
  "skill:onion-design-context"
  "validation:design-context-check.sh"
)
LOADS=(
  "when:brief -> kb-or-context:business-context"
  "when:setup -> resolve:design-context (skill onion-design-context)"
  "when:material -> reuse:presentation/canva"
)
