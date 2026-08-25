# Manifesto do PLUGIN-NÚCLEO do Onion → plugin `onion` (o "plugin do Onion" em si).
# É a CAPACIDADE OPERACIONAL cross-cutting: o orquestrador mestre + as skills core + o runtime
# (warm-up/catch-up) + os motores (kg-radar = KG-SSOT/Elenxo runtime) + as guardas (hook exit-2,
# aside-router) + as abstrações SDAAL (task-manager/forge) + a doutrina embarcada (Dogfood, KG-SSOT,
# behavior-over-declaration). NÃO é meta-fábrica e NÃO carrega grafo privado do core (o grafo é do
# ADOTANTE — KG-SSOT-First: o plugin leva o MOTOR, não os dados). A guarda de MOAT (lint-artifacts.sh)
# reprova se este manifesto listar fonte de meta-fábrica (create-*/adopt/marketplace) ou docs/onion/graph/*.
PLUGIN_NAME="onion"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Nucleo operacional do Sistema Onion: o orquestrador mestre (skill onion) + skills core (language-standards, patterns, validation, orchestration) + runtime (warm-up/catch-up) + os motores (kg-radar: knowledge-graph SSOT como runtime, doutrina Elenxo/Dogfood) + guardas (hook exit-2 deterministico, aside-router) + abstracoes SDAAL (task-manager Jira/ClickUp/Asana/Linear, forge github). Instala a capacidade; o adotante gera os PROPRIOS grafos. Nao inclui a meta-fabrica."
KEYWORDS=(onion orchestration knowledge-graph sdaal dogfood elenxo runtime)

# Runtime: os pontos de entrada de sessão (root de commands/).
COMMANDS=(
  ".claude/commands/warm-up.md"
  ".claude/commands/catch-up.md"
  ".claude/commands/onion.md"
  # kg-freshness: a re-verificacao do grafo contra o vivo (mede+re-carimba). Runtime KG do ADOTANTE
  # (opera sobre os grafos DELE — KG-SSOT-First), par do kg-radar (o detector, ja em VALIDATION).
  ".claude/commands/meta/kg-freshness.md"
)
# O agente orquestrador mestre.
AGENTS=(
  ".claude/agents/meta/onion.md"
)
# As skills core: a mestre `onion` (orquestrador) + as convenções/guard-rails + orquestração.
SKILLS=(
  ".claude/skills/onion"
  ".claude/skills/language-standards"
  ".claude/skills/onion-patterns"
  ".claude/skills/onion-validation"
  ".claude/skills/onion-orchestration"
)
# Motor KG-SSOT (Elenxo/Dogfood-runtime). O status-factor.awk é SÍTIO ÚNICO — sem ele o radar sai 2.
VALIDATION=(
  ".claude/validation/kg-radar.sh"
  ".claude/validation/lib/status-factor.awk"
)
# As guardas de runtime: a guarda anti-fail-open (exit 2 determinístico) + o roteador de apartes.
HOOKS=(
  ".claude/hooks/bash-empty-result-guard.sh"
  ".claude/hooks/aside-router-hook.sh"
)
# Abstrações SDAAL (o consumidor liga o provider ativo pelo .env).
UTILS=(
  ".claude/utils/task-manager"
  ".claude/utils/forge"
)
# Doutrina embarcada (KB tipo A) — auto-suficiente sem /meta:adopt.
DOCS=(
  "docs/knowledge-base/concepts/onion-dogfooding-doctrine.md"
  "docs/knowledge-base/concepts/knowledge-graph-sdaal.md"
  "docs/knowledge-base/agentic-patterns/ai-strategies/behavior-over-declaration.md"
)

# Capability Contract.
CONFORMANCE="silver"
PROVIDES=("master-orchestration" "knowledge-graph-runtime" "kg-freshness-reverify" "sdaal-task-manager" "sdaal-forge" "session-runtime" "dogfood-doctrine" "language-standards")
REQUIRES=(
  "skill:onion-orchestration"
)
LOADS=(
  "embed:kb/onion-dogfooding-doctrine.md"
  "embed:kb/knowledge-graph-sdaal.md"
  "embed:kb/behavior-over-declaration.md"
  "when:warm-up|catch-up -> read(KG) via validation/kg-radar.sh (motor; o adotante tem os proprios .kg.yaml)"
)
