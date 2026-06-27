# Manifesto da vertical Compliance → plugin onion-compliance (consumido por assemble-plugin.sh).
# SSOT = .claude/; o plugin é artefato gerado. Camada 1 só (compliance-context = camada 2 do consumidor).
# Shape distinto do design: agentes-pesado, sem SDAAL utils, sem gate — prova de generalização.
PLUGIN_NAME="onion-compliance"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Vertical de compliance do Onion: documentacao de conformidade como spec-as-code (ISO 27001/22301, SOC2, PMBOK) via agentes especialistas + build-compliance-docs. Auto-adapta ao compliance-context do consumidor (SDAAL)."
KEYWORDS=(compliance iso-27001 iso-22301 soc2 pmbok onion)

COMMANDS=(".claude/commands/docs/build-compliance-docs.md")
AGENTS=(
  ".claude/agents/compliance/security-information-master.md"
  ".claude/agents/compliance/iso-27001-specialist.md"
  ".claude/agents/compliance/iso-22301-specialist.md"
  ".claude/agents/compliance/soc2-specialist.md"
  ".claude/agents/compliance/pmbok-specialist.md"
)
UTILS=()
VALIDATION=()
