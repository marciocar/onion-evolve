# onion — o NÚCLEO do Sistema Onion como plugin: orquestrador mestre, runtime de knowledge graph
# (kg + radar soberano + freshness), sessões, diário, orquestração, condução (wizard/onboarding/retro),
# validação de meta-specs, co-evolução upstream e os adapters SDAAL (task-manager, forge).
# 2026-09-04 (F2 da revisão para o diretório oficial): ABSORVEU onion-work-tools — a pesquisa R1 mostrou que o
# canal premia bundle vertical coeso, e work-tools era um saco de ferramentas que duplicava skill/motor/KB do núcleo.
# 2026-09-06: ABSORVEU a CONDUÇÃO DE PLANO-GRAFO (/meta:drive + /meta:realign + os dois motores + o predicado
# de selo). Decisão do maestro, com a fronteira medida: o drive conduz o plano-grafo DO REPO QUE O HOSPEDA
# (zero ocorrências de DEST/TARGET/INSTALL_DIR nele) — não é MOAT; o /meta:adopt é o oposto e continua fora.
# O /meta:kg-inbox NÃO entra, e a razão foi CORRIGIDA por revisor adversarial no mesmo PR: o 1º argumento
# escrito aqui ("o produtor da fila vive em ops/, logo ninguém alimenta") é FALSO — o próprio comando diz,
# desde 2026-09-05, que num repo adotado a proposta nasce à mão e que a ausência do cabeçalho nunca é
# motivo de rejeição. O bloqueador REAL é outro e é mecânico: o `allowed-tools` do comando cita
# `.claude/utils/adopt/starter-kg-inbox.sh`, caminho de meta-fábrica que a REGRA 61 barra do bundle; ele
# ficaria NU no plugin e cai na classe ALLOWED-TOOLS da REGRA 74 — permissão que não casa no consumidor,
# comando NASCIDO MORTO. Some-se a isso a pergunta de desenho que o fio já nomeia (onde o INSTALADOR
# guarda fila e grafo). Ver Q_KG_INBOX_FORA_DO_PLUGIN em docs/evolution/research/librechat-kg-runtime-2026-08/.
# REGRA 61: manifesto publicável NUNCA lista meta-fábrica (create-*/adopt/marketplace/decouple/evolve/absorb-skill/
# federation-*) nem docs/onion/graph/*. co-evolve/co-relay (upstream) são permitidos por desenho.

PLUGIN_NAME="onion"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Núcleo operacional do Sistema Onion: o orquestrador mestre (skill onion), runtime de knowledge graph (kg + radar soberano + kg-freshness), sessões e diário, orquestração de subagentes, condução (wizard/onboarding/retro), validação de meta-specs, co-evolução upstream e os adapters SDAAL de task-manager e forge."
KEYWORDS=(onion orchestration knowledge-graph sdaal dogfood elenxo runtime diary metaspec co-evolution)

# Ordem: o absorvido PRIMEIRO, o dono DEPOIS — na colisão de basename (README.md/help.md) o assembler deixa o último vencer.
COMMANDS=(
  ".claude/commands/meta/kg.md"
  ".claude/commands/meta/diary.md"
  ".claude/commands/meta/orchestrate.md"
  ".claude/commands/meta/analyze-complex-problem.md"
  ".claude/commands/meta/metaspec-validate.md"
  ".claude/commands/meta/recover.md"
  ".claude/commands/meta/all-tools.md"
  ".claude/commands/meta/kb-freshness.md"
  ".claude/commands/meta/context-freshness.md"
  ".claude/commands/meta/constellation.md"
  ".claude/commands/meta/setup-integration.md"
  ".claude/commands/meta/setup-code-review.md"
  ".claude/commands/meta/co-evolve.md"
  ".claude/commands/meta/co-relay.md"
  ".claude/commands/meta/backlog.md"
  ".claude/commands/meta/drive.md"
  ".claude/commands/meta/realign.md"
  ".claude/commands/quick/analysis.md"
  ".claude/commands/warm-up.md"
  ".claude/commands/catch-up.md"
  ".claude/commands/onion.md"
  ".claude/commands/meta/kg-freshness.md"
  # ── Acrescentados em 2026-09-15, e foi a REGRA 37 (Mapa role→bundle (roles.yaml) consistente com
  #    os verticais) que os cobrou: o conjunto `work_tool_sets.full` ganhou a maquinaria do método, e
  #    a guarda reprovou na hora por eles não estarem empacotados aqui. Exatamente o trabalho que eu
  #    havia declarado que ela faz — declaração que só vale porque foi exercida.
  ".claude/commands/meta/inventory.md"
  ".claude/commands/meta/graph.md"
  ".claude/commands/meta/kg-inbox.md"
  ".claude/commands/meta/radar.md"
  ".claude/commands/meta/census.md"
)
AGENTS=(
  ".claude/agents/meta/metaspec-gate-keeper.md"
  ".claude/agents/meta/onion.md"
)
SKILLS=(
  ".claude/skills/onion-orchestration"
  ".claude/skills/onion-wizard"
  ".claude/skills/onion-onboarding"
  ".claude/skills/onion-retro"
  ".claude/skills/onion"
  ".claude/skills/language-standards"
  ".claude/skills/onion-patterns"
  ".claude/skills/onion-validation"
)
HOOKS=(
  ".claude/hooks/bash-empty-result-guard.sh"
  ".claude/hooks/aside-router-hook.sh"
)
UTILS=(
  ".claude/utils/diagnose"
  ".claude/utils/task-manager"
  ".claude/utils/forge"
  # Motor do /meta:census, que entrou em work_tool_sets.full. Sem ele o comando viaja e não roda —
  # dead-ref, que é a REGRA 27 (Dependência de script de comando empacotado) na forma mais crua:
  # entregar metade do comando. UTILS aceita DIRETÓRIO (o assemble valida com `-d`).
  ".claude/utils/census"
)
VALIDATION=(
  # ⚠️ EMPACOTAR o script que a skill CITA, senão a guarda nasce MORTA no consumidor. Medido em
  # 2026-09-22: a skill onion-orchestration passou a mandar rodar `workflow-syntax-check.sh` e o
  # assembler reescreveu o caminho para `${CLAUDE_PLUGIN_ROOT}/validation/…` — mas o arquivo não
  # estava nesta lista, então o plugin publicava uma instrução para um arquivo inexistente. Nenhum
  # gate pegava: a REGRA 74 (Caminho .claude/ NU dentro de plugin só resolve no core) cobre caminho
  # NU, e este fora reescrito; e o plugin-dead-link-check.sh exclui `${…}` por desenho.
  ".claude/validation/workflow-syntax-check.sh"
  ".claude/validation/kg-radar.sh"
  ".claude/validation/kg-backlog-project.sh"
  ".claude/validation/kg-fixture-paths.sh"
  ".claude/validation/kg-backlog-check.sh"
  ".claude/validation/kg-drive-project.sh"
  ".claude/validation/kg-realign-project.sh"
  ".claude/validation/kg-seal-exception.sh"
  ".claude/validation/lib/status-factor.awk"
  ".claude/validation/kg-console.sh"
  ".claude/validation/kg-view.sh"
  ".claude/validation/vendor/kg-console/cytoscape.min.js"
  ".claude/validation/kg-narrate-validate.sh"
  ".claude/validation/diary-index.sh"
  ".claude/validation/constellation-map.sh"
  ".claude/validation/session-beacon.sh"
  ".claude/validation/kg-provenance-coverage.sh"
  ".claude/validation/resolve-integration-branch.sh"
  ".claude/validation/aside-router.sh"
  # ── Motores dos comandos acrescentados em 2026-09-15. A REGRA 27 (Dependência de script de comando
  #    empacotado) os cobrou: comando que declara um script em allowed-tools e cujo motor não viaja
  #    no bundle é DEAD-REF — o adotante recebe o comando e ele não roda. Entregar meio comando é a
  #    mesma classe de entregar a guarda sem o comando da cura.
  ".claude/validation/inventory.sh"
  ".claude/validation/graph.sh"
  ".claude/validation/kg-census-extract.sh"
)
TEMPLATES=()
DOCS=(
  "docs/knowledge-base/concepts/knowledge-graph-sdaal.md"
  "docs/knowledge-base/concepts/onion-elenxo-doctrine.md"
  "docs/knowledge-base/concepts/onion-drive-doctrine.md"
  "docs/knowledge-base/concepts/onion-kg-ontology-hierarchy.md"
  "docs/knowledge-base/concepts/onion-dogfooding-doctrine.md"
  "docs/knowledge-base/agentic-patterns/ai-strategies/behavior-over-declaration.md"
  "docs/knowledge-base/meta/onion-framework-identity.md"
)

# Capability Contract (ADR onion-adr-capability-contract-2026-06): provides=o que entrega · requires=deps (type:value) · loads=contexto condicional · conformance=tier
CONFORMANCE="silver"
PROVIDES=(
  "master-orchestration"
  "knowledge-graph-runtime"
  "kg-freshness-reverify"
  "sdaal-task-manager"
  "sdaal-forge"
  "session-runtime"
  "dogfood-doctrine"
  "language-standards"
  "knowledge-graph-sdaal"
  "learning-diary"
  "orchestration"
  "metaspec-validation"
  "freshness-audits"
  "constellation-map"
  "co-evolution-upstream"
  "plan-graph-drive"
  "plan-graph-realign"
  "guided-conduction"
  "guided-onboarding"
  "retro-feedback"
)
REQUIRES=(
  "skill:onion-orchestration"
  "agent:metaspec-gate-keeper"
)
LOADS=(
  "embed:kb/onion-dogfooding-doctrine.md"
  "embed:kb/knowledge-graph-sdaal.md"
  "embed:kb/behavior-over-declaration.md"
  "when:warm-up|catch-up -> read(KG) via validation/kg-radar.sh (motor; o adotante tem os proprios .kg.yaml)"
  "embed:kb/onion-elenxo-doctrine.md"
  "when:kg -> run:validation/kg-radar.sh (motor soberano; door gera seus proprios .kg.yaml)"
  "when:kg backfill -> run:validation/kg-provenance-coverage.sh (mede o passivo; --scope sem --baseline nao arma catraca)"
  "when:diary -> run:validation/diary-index.sh"
  "embed:kb/onion-drive-doctrine.md"
  "embed:kb/onion-kg-ontology-hierarchy.md"
  "when:drive -> run:validation/kg-drive-project.sh (censo determinístico) + validation/kg-seal-exception.sh (predicado do selo)"
  "when:realign -> run:validation/kg-realign-project.sh (verificador-por-turno; --check é o dente)"
)
