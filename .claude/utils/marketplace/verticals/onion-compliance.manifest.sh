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
TEMPLATES=(
  ".claude/commands/common/templates/compliance-context-template.md"
  ".claude/commands/common/templates/compliance_iso27001_template.md"
  ".claude/commands/common/templates/compliance_iso22301_template.md"
  ".claude/commands/common/templates/compliance_soc2_template.md"
  ".claude/commands/common/templates/compliance_pmbok_template.md"
)
# Skill de contexto: contrato SSOT mínimo + resolver de compliance-context (auto-suficiente em repos
# não-adotados). tipo A (frameworks) = os TEMPLATES acima, já embarcados → sem DOCS. Ver
# .claude/skills/onion-compliance-context/.
SKILLS=(".claude/skills/onion-compliance-context")

# Capability Contract (auto-descrição — ADR onion-adr-capability-contract-2026-06).
CONFORMANCE="gold"
PROVIDES=("iso-27001-isms" "iso-22301-bcms" "soc2-tsc" "pmbok-governance" "build-compliance-docs" "ssot-context-resolver")
REQUIRES=(
  "agent:security-information-master"
  "agent:iso-27001-specialist"
  "agent:iso-22301-specialist"
  "agent:soc2-specialist"
  "agent:pmbok-specialist"
  "command:build-compliance-docs"
  "skill:onion-compliance-context"
  "template:compliance-context-template.md"
  "template:compliance_iso27001_template.md"
  "template:compliance_iso22301_template.md"
  "template:compliance_soc2_template.md"
  "template:compliance_pmbok_template.md"
)
LOADS=(
  "when:framework=iso27001 -> template:compliance_iso27001_template.md"
  "when:framework=soc2 -> template:compliance_soc2_template.md"
  "when:build -> resolve:compliance-context (skill onion-compliance-context)"
)
