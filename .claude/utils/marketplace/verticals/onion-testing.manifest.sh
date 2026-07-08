# Manifesto da vertical Testes/QA → plugin onion-testing (consumido por assemble-plugin.sh).
# SSOT = .claude/; o plugin é artefato gerado. Camada 1 só.
# NOTA: os subcomandos aninhados de validate/ (collab/, qa-points/, test-strategy/) ficam para
# uma iteracao futura — o assembler achata a arvore, e o namespace aninhado exige tratamento proprio.
PLUGIN_NAME="onion-testing"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Vertical de testes/QA do Onion: geracao e execucao de testes (unit/integration/e2e) com deteccao de framework + validacao de workflow. Perspectivas White/Grey/Black-box e QA story points. Camada 1."
KEYWORDS=(testing qa unit integration e2e onion)

COMMANDS=(".claude/commands/test" ".claude/commands/validate")
AGENTS=(
  ".claude/agents/testing/test-agent.md"
  ".claude/agents/testing/test-engineer.md"
  ".claude/agents/testing/test-planner.md"
)
UTILS=()
VALIDATION=()

# Capability Contract (auto-descrição — ADR onion-adr-capability-contract-2026-06).
CONFORMANCE="silver"
PROVIDES=("geracao-testes-unit-integration-e2e" "estrategia-de-teste" "qa-story-points")
REQUIRES=(
  "agent:test-agent"
  "agent:test-engineer"
  "agent:test-planner"
)
LOADS=()
