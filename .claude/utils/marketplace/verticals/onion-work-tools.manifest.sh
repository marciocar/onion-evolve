# Manifesto do bundle CROSS-CUTTING de ferramentas de trabalho → plugin onion-work-tools.
# NÃO é vertical de domínio NEM meta-fábrica: são os comandos de commands/meta que são ferramentas de
# TRABALHO (kg/diary/orchestrate/metaspec-validate/...), distribuídos a source/hub/standalone (o reframe
# 2026-07-19: std=solo-completo). SSOT do CONJUNTO por papel = roles.yaml (work_tool_sets.full). Este
# manifesto é a materialização (comandos + motores + agente que os comandos arrastam).
PLUGIN_NAME="onion-work-tools"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Ferramentas de trabalho cross-cutting do Onion (nao meta-fabrica): knowledge-graph (kg + radar soberano), diario de aprendizado, orquestracao, validacao de metaspec, freshness de KB/contexto, constelacao de estudos, recover, setup de integracoes, e co-evolucao upstream (co-evolve/co-relay). Distribuido a source/hub/standalone."
KEYWORDS=(work-tools knowledge-graph diary orchestration metaspec co-evolution onion)

# Os 14 comandos do conjunto `full` (roles.yaml work_tool_sets.full). Downstream (co-deliver/co-announce)
# e meta-fabrica NAO entram aqui — sao core-only/gated.
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
  # backlog: projeta o trabalho ABERTO dos grafos DO ADOTANTE (pareia com kg/kg-radar; runtime KG)
  ".claude/commands/meta/backlog.md"
  # analise rapida generica (template padrao)
  ".claude/commands/quick/analysis.md"
)
# Agente que metaspec-validate delega.
AGENTS=(
  ".claude/agents/meta/metaspec-gate-keeper.md"
)
# O scaffold do store de diagnose (o modo `kg diagnose` o cabeia — sem ele o door teria a referência
# quebrada). O dir inteiro viaja (helper + templates/), copiado com estrutura preservada.
UTILS=(".claude/utils/diagnose")
# Motores determinísticos que os comandos cabeiam (kg→radar+console; diary→index; constellation→map).
VALIDATION=(
  ".claude/validation/kg-radar.sh"
  # motores do /meta:backlog (projeta o backlog dos grafos do adotante)
  ".claude/validation/kg-backlog-project.sh"
  ".claude/validation/kg-backlog-check.sh"
  # SITIO UNICO do fator de status — sem ele o radar e a lente saem 2 (fail-loud, nunca default).
  ".claude/validation/lib/status-factor.awk"
  ".claude/validation/kg-console.sh"
  # O console rico depende da lente (kg-view --json) e do renderer VENDORIZADO inline.
  # Sem estes dois, o kg-console.sh degrada gracioso (exit 3) — o door perderia a visualização.
  ".claude/validation/kg-view.sh"
  ".claude/validation/vendor/kg-console/cytoscape.min.js"
  # Validador da narração pré-cozida (REGRA 47, modo `kg narrate`): o door que autora narração
  # precisa do guard que garante "cita ids que existem" — senão o console dele dropa id morto em silêncio.
  ".claude/validation/kg-narrate-validate.sh"
  ".claude/validation/diary-index.sh"
  ".claude/validation/constellation-map.sh"
  # Gate de proveniência invertido (modo `kg backfill`). O resolve-integration-branch
  # vai JUNTO de propósito: sem o irmão, o coverage cai para a catraca FRACA (compara
  # contra HEAD, onde um baseline que cresceu e já foi commitado passa despercebido).
  # Degradar em silêncio para catraca fraca num adotante seria o no-op de sempre.
  ".claude/validation/kg-provenance-coverage.sh"
  ".claude/validation/resolve-integration-branch.sh"
)
# Skills de trabalho: orquestração (orchestrate depende dela) + condução (o wizard "ajuda a FAZER"
# os movimentos da família — projeta da topologia-SSOT; par futuro: onion-onboarding "ajuda a CONHECER")
# + retro (retro/feedback como spec-as-code — o adotante que a inspirou topou co-evoluí-la).
SKILLS=(".claude/skills/onion-orchestration" ".claude/skills/onion-wizard" ".claude/skills/onion-onboarding" ".claude/skills/onion-retro")
# KB tipo A embarcado — a doutrina que kg/diary mais citam (auto-suficiência sem /meta:adopt).
DOCS=(
  "docs/knowledge-base/concepts/knowledge-graph-sdaal.md"
  # A doutrina do Elenxo: as skills embarcadas (onion-onboarding, onion-wizard) têm seções `## Elenxo`
  # e o kg cita a etapa 5 dela. Sem embarcar, os links viram MORTOS dentro do plugin — medido no PR
  # #630, e o achado veio do revisor do CI depois de a minha passada manual contar 1 onde eram 3.
  "docs/knowledge-base/concepts/onion-elenxo-doctrine.md"
)

# Capability Contract.
CONFORMANCE="silver"
PROVIDES=("knowledge-graph-sdaal" "learning-diary" "orchestration" "metaspec-validation" "freshness-audits" "constellation-map" "co-evolution-upstream" "guided-conduction" "guided-onboarding" "retro-feedback")
REQUIRES=(
  "agent:metaspec-gate-keeper"
  "skill:onion-orchestration"
)
LOADS=(
  "embed:kb/knowledge-graph-sdaal.md"
  "embed:kb/onion-elenxo-doctrine.md"
  "when:kg -> run:validation/kg-radar.sh (motor soberano; door gera seus proprios .kg.yaml)"
  "when:kg backfill -> run:validation/kg-provenance-coverage.sh (mede o passivo; --scope sem --baseline nao arma catraca)"
  "when:diary -> run:validation/diary-index.sh"
)
