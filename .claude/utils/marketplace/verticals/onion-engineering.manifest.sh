# onion-engineering — vertical de ENGENHARIA: fluxo faseado plan→start→work→pre-pr→pr→pr-update (GitFlow +
# sessões persistentes), gates pré-PR, especialistas de código E — desde 2026-09-04 (F2) — a geração e a
# estratégia de TESTES (unit/integration/e2e, validate:workflow, QA), absorvendo onion-testing.
# Ordem do COMMANDS[] é significativa (colisão de basename README.md/help.md — o último vence: engineer).
# NOTA: os subcomandos aninhados de validate/ (collab/, qa-points/, test-strategy/) continuam fora — o assembler
# achata a árvore; namespace aninhado exige tratamento próprio (dívida declarada, herdada do onion-testing).

PLUGIN_NAME="onion-engineering"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Vertical de engenharia do Onion: fluxo faseado plan→start→work→pre-pr→pr→pr-update (GitFlow + sessões persistentes), gates pré-PR, especialistas de código (Node, React, Postgres, NX, Docker, segurança) e testes (unit/integration/e2e, estratégia de teste, QA story points)."
KEYWORDS=(engineering gitflow pull-request code-review testing qa nodejs react onion)

# Ordem: o absorvido PRIMEIRO, o dono DEPOIS — na colisão de basename (README.md/help.md) o assembler deixa o último vencer.
COMMANDS=(
  ".claude/commands/test"
  ".claude/commands/validate"
  ".claude/commands/git"
  ".claude/commands/engineer"
)
AGENTS=(
  ".claude/agents/testing/test-agent.md"
  ".claude/agents/testing/test-engineer.md"
  ".claude/agents/testing/test-planner.md"
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
SKILLS=(
  ".claude/skills/onion-engineering-context"
)
HOOKS=()
UTILS=()
VALIDATION=(
  ".claude/validation/kg-radar.sh"
  ".claude/validation/lib/status-factor.awk"
)
TEMPLATES=()
DOCS=(
  "docs/knowledge-base/frameworks/gitflow-patterns.md"
  "docs/knowledge-base/concepts/worklog-protocol.md"
)

# Capability Contract (ADR onion-adr-capability-contract-2026-06): provides=o que entrega · requires=deps (type:value) · loads=contexto condicional · conformance=tier
CONFORMANCE="silver"
PROVIDES=(
  "gitflow-faseado"
  "pull-request-lifecycle"
  "code-review-pre-pr"
  "code-specialists-node-react-postgres-nx-docker"
  "ssot-context-resolver"
  "geracao-testes-unit-integration-e2e"
  "estrategia-de-teste"
  "qa-story-points"
)
REQUIRES=(
  "agent:gitflow-specialist"
  "agent:branch-code-reviewer"
  "agent:code-reviewer"
  "agent:nodejs-specialist"
  "agent:react-developer"
  "agent:postgres-specialist"
  "agent:docker-specialist"
  "skill:onion-engineering-context"
  "agent:test-agent"
  "agent:test-engineer"
  "agent:test-planner"
)
LOADS=(
  "embed:kb/gitflow-patterns.md"
  "embed:kb/worklog-protocol.md"
  "when:work -> resolve:technical-context (skill onion-engineering-context)"
)
