# Manifesto da vertical Engenharia → plugin onion-engineering (consumido por assemble-plugin.sh).
# SSOT = .claude/; o plugin é artefato gerado. Camada 1 só (o task-manager/forge do consumidor via SDAAL).
PLUGIN_NAME="onion-engineering"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Vertical de engenharia do Onion: fluxo faseado plan→start→work→pre-pr→pr→pr-update (GitFlow + sessoes persistentes) + especialistas de codigo (Node/React/Postgres/NX/Docker) e gates pre-PR. Camada 1; task-manager e forge do consumidor via SDAAL."
KEYWORDS=(engineering gitflow pull-request code-review nodejs react onion)

COMMANDS=(".claude/commands/engineer" ".claude/commands/git")
AGENTS=(
  ".claude/agents/git/gitflow-specialist.md"
  ".claude/agents/git/branch-code-reviewer.md"
  ".claude/agents/git/branch-documentation-writer.md"
  ".claude/agents/git/branch-metaspec-checker.md"
  ".claude/agents/git/branch-test-planner.md"
  ".claude/agents/review/code-reviewer.md"
  ".claude/agents/development/nodejs-specialist.md"
  ".claude/agents/development/react-developer.md"
  ".claude/agents/development/postgres-specialist.md"
  ".claude/agents/development/nx-monorepo-specialist.md"
  ".claude/agents/development/nx-migration-specialist.md"
  ".claude/agents/development/claude-code-specialist.md"
  ".claude/agents/development/linux-security-specialist.md"
  ".claude/agents/development/runflow-specialist.md"
  ".claude/agents/development/zen-engine-specialist.md"
  ".claude/agents/deployment/docker-specialist.md"
)
UTILS=()
VALIDATION=()

# Capability Contract (auto-descrição — ADR onion-adr-capability-contract-2026-06).
CONFORMANCE="silver"
PROVIDES=("gitflow-faseado" "pull-request-lifecycle" "code-review-pre-pr" "code-specialists-node-react-postgres-nx-docker")
REQUIRES=(
  "agent:gitflow-specialist"
  "agent:branch-code-reviewer"
  "agent:code-reviewer"
  "agent:nodejs-specialist"
  "agent:react-developer"
  "agent:postgres-specialist"
  "agent:docker-specialist"
)
LOADS=()
