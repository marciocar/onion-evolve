# Grafo do Onion — lente sócio-técnica (GERADO; não editar à mão)

> Gerado por `.claude/validation/graph.sh` da spec-as-code (actors.yaml + capability contracts +
> frontmatter + inventário). SSOT = spec-as-code; este arquivo é **derivado**. Sem store externo.
> TBox: `docs/knowledge-base/concepts/onion-relation-vocabulary.md`. Duplo público: o Transformer
> navega para achar caminho/solução/orquestração; o script responde impacto/órfão/caminho.

## Atores e canais (o sistema sócio-técnico)

- **adopter** --adopts--> onion
- **adopter** --signals--> core _(via doc-bridge)_
- **assistant** --asks--> maestro _(via conversa-plan-gate)_
- **assistant** --evolves--> onion
- **assistant** --executes--> onion
- **assistant** --orchestrates-workers--> subagent _(via orchestration)_
- **assistant** --proposes--> maestro _(via conversa-plan-gate)_
- **assistant** --reports--> maestro _(via conversa-plan-gate)_
- **core** --announces--> adopter _(via doc-bridge)_
- **core** --co-evolves--> adopter
- **maestro** --approves--> assistant _(via conversa-plan-gate)_
- **maestro** --gates--> assistant _(via conversa-plan-gate)_
- **maestro** --orchestrates--> assistant
- **maestro** --requests--> assistant _(via conversa-plan-gate)_
- **onion** --evolves-via--> dogfood
- **onion** --has-member--> agent-creator-specialist
- **onion** --has-member--> agent-skills-specialist
- **onion** --has-member--> branch-code-reviewer
- **onion** --has-member--> branch-documentation-writer
- **onion** --has-member--> branch-metaspec-checker
- **onion** --has-member--> branch-test-planner
- **onion** --has-member--> brand-generator
- **onion** --has-member--> branding-positioning-specialist
- **onion** --has-member--> c4-architecture-specialist
- **onion** --has-member--> c4-documentation-specialist
- **onion** --has-member--> claude-code-specialist
- **onion** --has-member--> clickup-specialist
- **onion** --has-member--> code-reviewer
- **onion** --has-member--> command-creator-specialist
- **onion** --has-member--> corporate-compliance-specialist
- **onion** --has-member--> design-system-specialist
- **onion** --has-member--> docker-specialist
- **onion** --has-member--> docs-reverse-engineer
- **onion** --has-member--> extract-meeting-specialist
- **onion** --has-member--> gamma-api-specialist
- **onion** --has-member--> gitflow-specialist
- **onion** --has-member--> iso-22301-specialist
- **onion** --has-member--> iso-27001-specialist
- **onion** --has-member--> jira-specialist
- **onion** --has-member--> language-standards
- **onion** --has-member--> linux-security-specialist
- **onion** --has-member--> meeting-consolidator
- **onion** --has-member--> mermaid-specialist
- **onion** --has-member--> metaspec-gate-keeper
- **onion** --has-member--> nodejs-specialist
- **onion** --has-member--> nx-migration-specialist
- **onion** --has-member--> nx-monorepo-specialist
- **onion** --has-member--> onion
- **onion** --has-member--> onion-compliance-context
- **onion** --has-member--> onion-engineering-context
- **onion** --has-member--> onion-onboarding
- **onion** --has-member--> onion-orchestration
- **onion** --has-member--> onion-patterns
- **onion** --has-member--> onion-product-context
- **onion** --has-member--> onion-publish
- **onion** --has-member--> onion-research
- **onion** --has-member--> onion-retro
- **onion** --has-member--> onion-validation
- **onion** --has-member--> onion-wizard
- **onion** --has-member--> pain-price-specialist
- **onion** --has-member--> pmbok-specialist
- **onion** --has-member--> postgres-specialist
- **onion** --has-member--> presentation-orchestrator
- **onion** --has-member--> product-agent
- **onion** --has-member--> react-developer
- **onion** --has-member--> research-agent
- **onion** --has-member--> runflow-specialist
- **onion** --has-member--> security-information-master
- **onion** --has-member--> soc2-specialist
- **onion** --has-member--> story-points-framework-specialist
- **onion** --has-member--> storytelling-business-specialist
- **onion** --has-member--> system-documentation-orchestrator
- **onion** --has-member--> task-specialist
- **onion** --has-member--> test-agent
- **onion** --has-member--> test-engineer
- **onion** --has-member--> test-planner
- **onion** --has-member--> whisper-specialist
- **onion** --has-member--> zen-engine-specialist
- **onion** --loads--> embed:kb/behavior-over-declaration.md
- **onion** --loads--> embed:kb/knowledge-graph-sdaal.md
- **onion** --loads--> embed:kb/onion-dogfooding-doctrine.md
- **onion** --loads--> embed:kb/onion-drive-doctrine.md
- **onion** --loads--> embed:kb/onion-elenxo-doctrine.md
- **onion** --loads--> embed:kb/onion-kg-ontology-hierarchy.md
- **onion** --loads--> when:diary -> run:validation/diary-index.sh
- **onion** --loads--> when:drive -> run:validation/kg-drive-project.sh (censo determinístico) + validation/kg-seal-exception.sh (predicado do selo)
- **onion** --loads--> when:kg -> run:validation/kg-radar.sh (motor soberano; door gera seus proprios .kg.yaml)
- **onion** --loads--> when:kg backfill -> run:validation/kg-provenance-coverage.sh (mede o passivo; --scope sem --baseline nao arma catraca)
- **onion** --loads--> when:realign -> run:validation/kg-realign-project.sh (verificador-por-turno; --check é o dente)
- **onion** --loads--> when:warm-up|catch-up -> read(KG) via validation/kg-radar.sh (motor; o adotante tem os proprios .kg.yaml)
- **onion** --provides--> co-evolution-upstream
- **onion** --provides--> constellation-map
- **onion** --provides--> dogfood-doctrine
- **onion** --provides--> freshness-audits
- **onion** --provides--> guided-conduction
- **onion** --provides--> guided-onboarding
- **onion** --provides--> kg-freshness-reverify
- **onion** --provides--> knowledge-graph-runtime
- **onion** --provides--> knowledge-graph-sdaal
- **onion** --provides--> language-standards
- **onion** --provides--> learning-diary
- **onion** --provides--> master-orchestration
- **onion** --provides--> metaspec-validation
- **onion** --provides--> orchestration
- **onion** --provides--> plan-graph-drive
- **onion** --provides--> plan-graph-realign
- **onion** --provides--> retro-feedback
- **onion** --provides--> sdaal-forge
- **onion** --provides--> sdaal-task-manager
- **onion** --provides--> session-runtime
- **onion** --related--> /engineer/pr
- **onion** --related--> /engineer/start
- **onion** --related--> /engineer/work
- **onion** --related--> /git/flow
- **onion** --related--> /product/task
- **onion** --related--> clickup-specialist
- **onion** --related--> code-reviewer
- **onion** --related--> gitflow-specialist
- **onion** --related--> jira-specialist
- **onion** --related--> product-agent
- **onion** --related--> task-specialist
- **onion** --related--> test-engineer
- **onion** --requires--> agent:metaspec-gate-keeper
- **onion** --requires--> skill:onion-orchestration
- **onion** --serves--> maestro

## Capacidades por vertical (requires / provides / loads)

- onion **loads** embed:kb/behavior-over-declaration.md
- onion **loads** embed:kb/knowledge-graph-sdaal.md
- onion **loads** embed:kb/onion-dogfooding-doctrine.md
- onion **loads** embed:kb/onion-drive-doctrine.md
- onion **loads** embed:kb/onion-elenxo-doctrine.md
- onion **loads** embed:kb/onion-kg-ontology-hierarchy.md
- onion **loads** when:diary -> run:validation/diary-index.sh
- onion **loads** when:drive -> run:validation/kg-drive-project.sh (censo determinístico) + validation/kg-seal-exception.sh (predicado do selo)
- onion **loads** when:kg -> run:validation/kg-radar.sh (motor soberano; door gera seus proprios .kg.yaml)
- onion **loads** when:kg backfill -> run:validation/kg-provenance-coverage.sh (mede o passivo; --scope sem --baseline nao arma catraca)
- onion **loads** when:realign -> run:validation/kg-realign-project.sh (verificador-por-turno; --check é o dente)
- onion **loads** when:warm-up|catch-up -> read(KG) via validation/kg-radar.sh (motor; o adotante tem os proprios .kg.yaml)
- onion **provides** co-evolution-upstream
- onion **provides** constellation-map
- onion **provides** dogfood-doctrine
- onion **provides** freshness-audits
- onion **provides** guided-conduction
- onion **provides** guided-onboarding
- onion **provides** kg-freshness-reverify
- onion **provides** knowledge-graph-runtime
- onion **provides** knowledge-graph-sdaal
- onion **provides** language-standards
- onion **provides** learning-diary
- onion **provides** master-orchestration
- onion **provides** metaspec-validation
- onion **provides** orchestration
- onion **provides** plan-graph-drive
- onion **provides** plan-graph-realign
- onion **provides** retro-feedback
- onion **provides** sdaal-forge
- onion **provides** sdaal-task-manager
- onion **provides** session-runtime
- onion **requires** agent:metaspec-gate-keeper
- onion **requires** skill:onion-orchestration
- onion-compliance **loads** when:build -> resolve:compliance-context (skill onion-compliance-context)
- onion-compliance **loads** when:framework=iso27001 -> template:compliance_iso27001_template.md
- onion-compliance **loads** when:framework=soc2 -> template:compliance_soc2_template.md
- onion-compliance **provides** build-compliance-docs
- onion-compliance **provides** iso-22301-bcms
- onion-compliance **provides** iso-27001-isms
- onion-compliance **provides** pmbok-governance
- onion-compliance **provides** soc2-tsc
- onion-compliance **provides** ssot-context-resolver
- onion-compliance **requires** agent:iso-22301-specialist
- onion-compliance **requires** agent:iso-27001-specialist
- onion-compliance **requires** agent:pmbok-specialist
- onion-compliance **requires** agent:security-information-master
- onion-compliance **requires** agent:soc2-specialist
- onion-compliance **requires** command:build-compliance-docs
- onion-compliance **requires** skill:onion-compliance-context
- onion-compliance **requires** template:compliance-context-template.md
- onion-compliance **requires** template:compliance_iso22301_template.md
- onion-compliance **requires** template:compliance_iso27001_template.md
- onion-compliance **requires** template:compliance_pmbok_template.md
- onion-compliance **requires** template:compliance_soc2_template.md
- onion-design **loads** when:brief -> kb-or-context:business-context
- onion-design **loads** when:material -> reuse:presentation/canva
- onion-design **provides** design-tokens-w3c-dtcg
- onion-design **provides** materializacao-css-tailwind-shadcn
- onion-design **provides** wcag-contrast-gate
- onion-design **requires** agent:brand-generator
- onion-design **requires** agent:branding-positioning-specialist
- onion-design **requires** agent:design-system-specialist
- onion-design **requires** util:design-sink
- onion-design **requires** util:design-source
- onion-design **requires** validation:lint-design-tokens.sh
- onion-engineering **loads** embed:kb/gitflow-patterns.md
- onion-engineering **loads** embed:kb/worklog-protocol.md
- onion-engineering **loads** when:work -> resolve:technical-context (skill onion-engineering-context)
- onion-engineering **provides** code-review-pre-pr
- onion-engineering **provides** code-specialists-node-react-postgres-nx-docker
- onion-engineering **provides** estrategia-de-teste
- onion-engineering **provides** geracao-testes-unit-integration-e2e
- onion-engineering **provides** gitflow-faseado
- onion-engineering **provides** pull-request-lifecycle
- onion-engineering **provides** qa-story-points
- onion-engineering **provides** ssot-context-resolver
- onion-engineering **requires** agent:branch-code-reviewer
- onion-engineering **requires** agent:code-reviewer
- onion-engineering **requires** agent:docker-specialist
- onion-engineering **requires** agent:gitflow-specialist
- onion-engineering **requires** agent:nodejs-specialist
- onion-engineering **requires** agent:postgres-specialist
- onion-engineering **requires** agent:react-developer
- onion-engineering **requires** agent:test-agent
- onion-engineering **requires** agent:test-engineer
- onion-engineering **requires** agent:test-planner
- onion-engineering **requires** skill:onion-engineering-context
- onion-product **loads** embed:kb/framework-story-points.md
- onion-product **loads** embed:kb/identificar-precificar-dor-cliente.md
- onion-product **loads** when:spec -> resolve:business-context (skill onion-product-context)
- onion-product **provides** apresentacoes
- onion-product **provides** business-technical-context
- onion-product **provides** c4-model-mermaid
- onion-product **provides** decomposicao-de-tasks
- onion-product **provides** descoberta-a-backlog
- onion-product **provides** docs-health-validacao
- onion-product **provides** engenharia-reversa
- onion-product **provides** estimativa-story-points
- onion-product **provides** extracao-de-reunioes
- onion-product **provides** ssot-context-resolver
- onion-product **requires** agent:c4-architecture-specialist
- onion-product **requires** agent:c4-documentation-specialist
- onion-product **requires** agent:docs-reverse-engineer
- onion-product **requires** agent:extract-meeting-specialist
- onion-product **requires** agent:mermaid-specialist
- onion-product **requires** agent:pain-price-specialist
- onion-product **requires** agent:product-agent
- onion-product **requires** agent:story-points-framework-specialist
- onion-product **requires** agent:task-specialist
- onion-product **requires** skill:onion-product-context

## Triplas (cruas — para consumo determinístico)

```tsv
# subject	predicate	object	via
adopter	adopts	onion	
adopter	signals	core	doc-bridge
agent-creator-specialist	related	/meta/create-agent	
agent-creator-specialist	related	/meta/create-agent-express	
agent-creator-specialist	related	command-creator-specialist	
agent-creator-specialist	related	onion	
agent-skills-specialist	related	/meta/create-agent	
agent-skills-specialist	related	/meta/create-command	
agent-skills-specialist	related	/meta/create-skill	
agent-skills-specialist	related	agent-creator-specialist	
agent-skills-specialist	related	claude-code-specialist	
agent-skills-specialist	related	command-creator-specialist	
arandek	adopts	onion-evolve	
arandek	mode	legacy	
arandek	pin	65d8a7501a03	
arandek	specialization	field-dogfood	
arandek	specialization	legacy-adoption	
arandek	specialization	monorepo	
arandek	specialization	upstream-signal	
arandek	tier	standalone	
arandek	trust-advises	onion-evolve	
assistant	asks	maestro	conversa-plan-gate
assistant	evolves	onion	
assistant	executes	onion	
assistant	orchestrates-workers	subagent	orchestration
assistant	proposes	maestro	conversa-plan-gate
assistant	reports	maestro	conversa-plan-gate
brain-granaai	adopts	onion-evolve	
brain-granaai	mode	brownfield	
brain-granaai	pin	663fdbc5bdcc	
brain-granaai	specialization	clickup	
brain-granaai	specialization	company-brain	
brain-granaai	specialization	pesquisa-primaria	
brain-granaai	tier	hub	
brain-granaai	trust-advises	onion-evolve	
brain-granaai	trust-corrects	onion-evolve	
branch-code-reviewer	related	/engineer/pre-pr	
branch-code-reviewer	related	branch-test-planner	
branch-code-reviewer	related	code-reviewer	
branch-documentation-writer	related	/engineer/pre-pr	
branch-documentation-writer	related	branch-code-reviewer	
branch-documentation-writer	related	system-documentation-orchestrator	
branch-metaspec-checker	related	/engineer/pre-pr	
branch-metaspec-checker	related	branch-code-reviewer	
branch-metaspec-checker	related	metaspec-gate-keeper	
branch-test-planner	related	/engineer/pre-pr	
branch-test-planner	related	branch-code-reviewer	
branch-test-planner	related	test-planner	
brand-generator	related	branding-positioning-specialist	
brand-generator	related	design-system-specialist	
branding-positioning-specialist	related	/docs/generate	
branding-positioning-specialist	related	/product/spec	
branding-positioning-specialist	related	/product/task	
branding-positioning-specialist	related	product-agent	
branding-positioning-specialist	related	research-agent	
branding-positioning-specialist	related	storytelling-business-specialist	
c4-architecture-specialist	related	/docs/build-tech-docs	
c4-architecture-specialist	related	c4-documentation-specialist	
c4-architecture-specialist	related	mermaid-specialist	
c4-architecture-specialist	related	system-documentation-orchestrator	
c4-documentation-specialist	related	/docs/build-tech-docs	
c4-documentation-specialist	related	c4-architecture-specialist	
c4-documentation-specialist	related	mermaid-specialist	
c4-documentation-specialist	related	system-documentation-orchestrator	
claude-code-specialist	related	/meta/create-agent	
claude-code-specialist	related	/meta/create-command	
claude-code-specialist	related	agent-creator-specialist	
claude-code-specialist	related	command-creator-specialist	
clickup-specialist	related	/product/check	
clickup-specialist	related	/product/task	
clickup-specialist	related	product-agent	
clickup-specialist	related	task-specialist	
code-reviewer	related	/engineer/pre-pr	
code-reviewer	related	branch-code-reviewer	
code-reviewer	related	test-engineer	
command-creator-specialist	related	/meta/create-command	
command-creator-specialist	related	agent-creator-specialist	
command-creator-specialist	related	claude-code-specialist	
command-creator-specialist	related	gitflow-specialist	
core	announces	adopter	doc-bridge
core	co-evolves	adopter	
corporate-compliance-specialist	related	/docs/build-compliance-docs	
corporate-compliance-specialist	related	iso-27001-specialist	
corporate-compliance-specialist	related	security-information-master	
design-system-specialist	related	brand-generator	
design-system-specialist	related	branding-positioning-specialist	
design-system-specialist	related	react-developer	
docker-specialist	related	devops-engineer	
docker-specialist	related	postgres-specialist	
docs-reverse-engineer	related	/docs/reverse-consolidate	
docs-reverse-engineer	related	c4-architecture-specialist	
docs-reverse-engineer	related	system-documentation-orchestrator	
extract-meeting-specialist	related	/docs/build-tech-docs	
extract-meeting-specialist	related	/product/task	
extract-meeting-specialist	related	product-agent	
extract-meeting-specialist	related	storytelling-business-specialist	
extract-meeting-specialist	related	task-specialist	
gamma-api-specialist	related	/product/presentation	
gamma-api-specialist	related	presentation-orchestrator	
gamma-api-specialist	related	storytelling-business-specialist	
gitflow-specialist	related	/git/flow	
gitflow-specialist	related	/git/init	
gitflow-specialist	related	code-reviewer	
granaai	adopts	onion-evolve	
granaai	lineage	leonardo-offline	
granaai	lineage	mauricio	
granaai	mode	regulated	
granaai	pin	6cc162f32d1c	
granaai	specialization	canonicalization	
granaai	specialization	regulated-fintech	
granaai	specialization	ssot-governance	
granaai	tier	standalone	
granaai	trust-advises	onion-evolve	
granaai	trust-corrects	onion-evolve	
gustavo-pulga	adopts	onion-evolve	
gustavo-pulga	mode	greenfield	
gustavo-pulga	pin	c9eb2c40bc3b	
gustavo-pulga	specialization	field-dogfood	
gustavo-pulga	specialization	greenfield-adoption	
gustavo-pulga	tier	standalone	
gustavo-pulga	trust-advises	onion-evolve	
hub-formacao-enterprise	adopts	onion-evolve	
hub-formacao-enterprise	mode	greenfield	
hub-formacao-enterprise	pin	f32e2f931c73	
hub-formacao-enterprise	specialization	company-brain	
hub-formacao-enterprise	specialization	formacao-hands-on	
hub-formacao-enterprise	specialization	hub-de-adocao	
hub-formacao-enterprise	specialization	spec-as-code	
hub-formacao-enterprise	tier	hub	
hub-formacao-enterprise	trust-advises	onion-evolve	
hub-operacoes-enterprise	adopts	onion-evolve	
hub-operacoes-enterprise	mode	greenfield	
hub-operacoes-enterprise	pin	cff9214c3b9a	
hub-operacoes-enterprise	specialization	hub	
hub-operacoes-enterprise	specialization	itsm	
hub-operacoes-enterprise	specialization	task-manager-integration	
hub-operacoes-enterprise	tier	hub	
hub-operacoes-enterprise	trust-advises	onion-evolve	
iso-22301-specialist	related	/docs/build-compliance-docs	
iso-22301-specialist	related	iso-27001-specialist	
iso-22301-specialist	related	security-information-master	
iso-27001-specialist	related	/docs/build-compliance-docs	
iso-27001-specialist	related	security-information-master	
iso-27001-specialist	related	soc2-specialist	
jira-specialist	related	/product/check	
jira-specialist	related	/product/task	
jira-specialist	related	product-agent	
jira-specialist	related	task-specialist	
jogo-da-vida	adopts	onion-evolve	
jogo-da-vida	mode	greenfield	
jogo-da-vida	pin	2e3f3a6f88ce	
jogo-da-vida	specialization	expo-universal	
jogo-da-vida	specialization	gamification	
jogo-da-vida	specialization	kg-radar-js-port	
jogo-da-vida	specialization	maagica	
jogo-da-vida	specialization	pre-adoption-dogfood	
jogo-da-vida	specialization	turborepo	
jogo-da-vida	tier	standalone	
jogo-da-vida	trust-advises	onion-evolve	
linux-security-specialist	related	iso-27001-specialist	
maestro	approves	assistant	conversa-plan-gate
maestro	gates	assistant	conversa-plan-gate
maestro	orchestrates	assistant	
maestro	requests	assistant	conversa-plan-gate
marcio-pessoal	adopts	onion-evolve	
marcio-pessoal	mode	regulated	
marcio-pessoal	pin	n/a	
marcio-pessoal	specialization	kg-sdaal-method	
marcio-pessoal	specialization	life-kg	
marcio-pessoal	specialization	n1-dogfood	
marcio-pessoal	specialization	research-arm	
marcio-pessoal	tier	standalone	
marcio-pessoal	trust-advises	onion-evolve	
meeting-consolidator	related	/docs/build-tech-docs	
meeting-consolidator	related	/product/consolidate-meetings	
meeting-consolidator	related	/product/extract-meeting	
meeting-consolidator	related	/product/task	
meeting-consolidator	related	extract-meeting-specialist	
meeting-consolidator	related	product-agent	
meeting-consolidator	related	storytelling-business-specialist	
mermaid-specialist	related	/docs/build-business-docs	
mermaid-specialist	related	/docs/build-tech-docs	
mermaid-specialist	related	c4-architecture-specialist	
mermaid-specialist	related	presentation-orchestrator	
metagamify	adopts	onion-evolve	
metagamify	lineage	framework	
metagamify	lineage	production	
metagamify	mode	legacy	
metagamify	pin	21213cc6c3d6	
metagamify	specialization	asana-integration	
metagamify	specialization	gamification	
metagamify	specialization	metagamification	
metagamify	specialization	nx-monorepo	
metagamify	tier	standalone	
metagamify	trust-advises	onion-evolve	
metaspec-gate-keeper	related	/engineer/pre-pr	
metaspec-gate-keeper	related	c4-architecture-specialist	
metaspec-gate-keeper	related	onion	
nodejs-specialist	related	/engineer/start	
nodejs-specialist	related	/engineer/work	
nodejs-specialist	related	nx-monorepo-specialist	
nodejs-specialist	related	react-developer	
nx-migration-specialist	related	nx-monorepo-specialist	
nx-monorepo-specialist	related	nx-migration-specialist	
nx-monorepo-specialist	related	system-documentation-orchestrator	
onion	evolves-via	dogfood	
onion	has-member	agent-creator-specialist	
onion	has-member	agent-skills-specialist	
onion	has-member	branch-code-reviewer	
onion	has-member	branch-documentation-writer	
onion	has-member	branch-metaspec-checker	
onion	has-member	branch-test-planner	
onion	has-member	brand-generator	
onion	has-member	branding-positioning-specialist	
onion	has-member	c4-architecture-specialist	
onion	has-member	c4-documentation-specialist	
onion	has-member	claude-code-specialist	
onion	has-member	clickup-specialist	
onion	has-member	code-reviewer	
onion	has-member	command-creator-specialist	
onion	has-member	corporate-compliance-specialist	
onion	has-member	design-system-specialist	
onion	has-member	docker-specialist	
onion	has-member	docs-reverse-engineer	
onion	has-member	extract-meeting-specialist	
onion	has-member	gamma-api-specialist	
onion	has-member	gitflow-specialist	
onion	has-member	iso-22301-specialist	
onion	has-member	iso-27001-specialist	
onion	has-member	jira-specialist	
onion	has-member	language-standards	
onion	has-member	linux-security-specialist	
onion	has-member	meeting-consolidator	
onion	has-member	mermaid-specialist	
onion	has-member	metaspec-gate-keeper	
onion	has-member	nodejs-specialist	
onion	has-member	nx-migration-specialist	
onion	has-member	nx-monorepo-specialist	
onion	has-member	onion	
onion	has-member	onion-compliance-context	
onion	has-member	onion-engineering-context	
onion	has-member	onion-onboarding	
onion	has-member	onion-orchestration	
onion	has-member	onion-patterns	
onion	has-member	onion-product-context	
onion	has-member	onion-publish	
onion	has-member	onion-research	
onion	has-member	onion-retro	
onion	has-member	onion-validation	
onion	has-member	onion-wizard	
onion	has-member	pain-price-specialist	
onion	has-member	pmbok-specialist	
onion	has-member	postgres-specialist	
onion	has-member	presentation-orchestrator	
onion	has-member	product-agent	
onion	has-member	react-developer	
onion	has-member	research-agent	
onion	has-member	runflow-specialist	
onion	has-member	security-information-master	
onion	has-member	soc2-specialist	
onion	has-member	story-points-framework-specialist	
onion	has-member	storytelling-business-specialist	
onion	has-member	system-documentation-orchestrator	
onion	has-member	task-specialist	
onion	has-member	test-agent	
onion	has-member	test-engineer	
onion	has-member	test-planner	
onion	has-member	whisper-specialist	
onion	has-member	zen-engine-specialist	
onion	loads	embed:kb/behavior-over-declaration.md	
onion	loads	embed:kb/knowledge-graph-sdaal.md	
onion	loads	embed:kb/onion-dogfooding-doctrine.md	
onion	loads	embed:kb/onion-drive-doctrine.md	
onion	loads	embed:kb/onion-elenxo-doctrine.md	
onion	loads	embed:kb/onion-kg-ontology-hierarchy.md	
onion	loads	when:diary -> run:validation/diary-index.sh	
onion	loads	when:drive -> run:validation/kg-drive-project.sh (censo determinístico) + validation/kg-seal-exception.sh (predicado do selo)	
onion	loads	when:kg -> run:validation/kg-radar.sh (motor soberano; door gera seus proprios .kg.yaml)	
onion	loads	when:kg backfill -> run:validation/kg-provenance-coverage.sh (mede o passivo; --scope sem --baseline nao arma catraca)	
onion	loads	when:realign -> run:validation/kg-realign-project.sh (verificador-por-turno; --check é o dente)	
onion	loads	when:warm-up|catch-up -> read(KG) via validation/kg-radar.sh (motor; o adotante tem os proprios .kg.yaml)	
onion	provides	co-evolution-upstream	
onion	provides	constellation-map	
onion	provides	dogfood-doctrine	
onion	provides	freshness-audits	
onion	provides	guided-conduction	
onion	provides	guided-onboarding	
onion	provides	kg-freshness-reverify	
onion	provides	knowledge-graph-runtime	
onion	provides	knowledge-graph-sdaal	
onion	provides	language-standards	
onion	provides	learning-diary	
onion	provides	master-orchestration	
onion	provides	metaspec-validation	
onion	provides	orchestration	
onion	provides	plan-graph-drive	
onion	provides	plan-graph-realign	
onion	provides	retro-feedback	
onion	provides	sdaal-forge	
onion	provides	sdaal-task-manager	
onion	provides	session-runtime	
onion	related	/engineer/pr	
onion	related	/engineer/start	
onion	related	/engineer/work	
onion	related	/git/flow	
onion	related	/product/task	
onion	related	clickup-specialist	
onion	related	code-reviewer	
onion	related	gitflow-specialist	
onion	related	jira-specialist	
onion	related	product-agent	
onion	related	task-specialist	
onion	related	test-engineer	
onion	requires	agent:metaspec-gate-keeper	
onion	requires	skill:onion-orchestration	
onion	serves	maestro	
onion-arthur	adopts	onion-evolve	
onion-arthur	mode	greenfield	
onion-arthur	pin	165e1e13b11f	
onion-arthur	specialization	branding	
onion-arthur	specialization	design	
onion-arthur	specialization	greenfield-adoption	
onion-arthur	specialization	storytelling	
onion-arthur	tier	standalone	
onion-arthur	trust-advises	onion-evolve	
onion-codex	adopts	onion-evolve	
onion-codex	mode	distilled	
onion-codex	pin	n/a	
onion-codex	specialization	deterministic-guards	
onion-codex	specialization	openai-codex	
onion-codex	specialization	portability-proof	
onion-codex	specialization	substrate-port	
onion-codex	tier	standalone	
onion-codex	trust-advises	onion-evolve	
onion-compliance	loads	when:build -> resolve:compliance-context (skill onion-compliance-context)	
onion-compliance	loads	when:framework=iso27001 -> template:compliance_iso27001_template.md	
onion-compliance	loads	when:framework=soc2 -> template:compliance_soc2_template.md	
onion-compliance	provides	build-compliance-docs	
onion-compliance	provides	iso-22301-bcms	
onion-compliance	provides	iso-27001-isms	
onion-compliance	provides	pmbok-governance	
onion-compliance	provides	soc2-tsc	
onion-compliance	provides	ssot-context-resolver	
onion-compliance	requires	agent:iso-22301-specialist	
onion-compliance	requires	agent:iso-27001-specialist	
onion-compliance	requires	agent:pmbok-specialist	
onion-compliance	requires	agent:security-information-master	
onion-compliance	requires	agent:soc2-specialist	
onion-compliance	requires	command:build-compliance-docs	
onion-compliance	requires	skill:onion-compliance-context	
onion-compliance	requires	template:compliance-context-template.md	
onion-compliance	requires	template:compliance_iso22301_template.md	
onion-compliance	requires	template:compliance_iso27001_template.md	
onion-compliance	requires	template:compliance_pmbok_template.md	
onion-compliance	requires	template:compliance_soc2_template.md	
onion-core	adopts	onion-evolve	
onion-core	mode	greenfield	
onion-core	pin	8278fee79d1c	
onion-core	specialization	deterministic-guards	
onion-core	specialization	full-machinery	
onion-core	specialization	hub-role	
onion-core	specialization	public-door	
onion-core	tier	hub	
onion-core	trust-advises	onion-evolve	
onion-curation	adopts	onion-evolve	
onion-curation	mode	greenfield	
onion-curation	pin	7818b8a25ae6	
onion-curation	specialization	curadoria	
onion-curation	specialization	dissecacao	
onion-curation	specialization	mercado	
onion-curation	tier	standalone	
onion-curation	trust-advises	onion-evolve	
onion-design	loads	when:brief -> kb-or-context:business-context	
onion-design	loads	when:material -> reuse:presentation/canva	
onion-design	provides	design-tokens-w3c-dtcg	
onion-design	provides	materializacao-css-tailwind-shadcn	
onion-design	provides	wcag-contrast-gate	
onion-design	requires	agent:brand-generator	
onion-design	requires	agent:branding-positioning-specialist	
onion-design	requires	agent:design-system-specialist	
onion-design	requires	util:design-sink	
onion-design	requires	util:design-source	
onion-design	requires	validation:lint-design-tokens.sh	
onion-dist	adopts	onion-evolve	
onion-dist	mode	greenfield	
onion-dist	pin	e88c1e11e051	
onion-dist	specialization	benchmarking	
onion-dist	specialization	distribution-algorithms	
onion-dist	specialization	kg-sdaal-method	
onion-dist	specialization	research-arm	
onion-dist	tier	standalone	
onion-dist	trust-advises	onion-evolve	
onion-engineering	loads	embed:kb/gitflow-patterns.md	
onion-engineering	loads	embed:kb/worklog-protocol.md	
onion-engineering	loads	when:work -> resolve:technical-context (skill onion-engineering-context)	
onion-engineering	provides	code-review-pre-pr	
onion-engineering	provides	code-specialists-node-react-postgres-nx-docker	
onion-engineering	provides	estrategia-de-teste	
onion-engineering	provides	geracao-testes-unit-integration-e2e	
onion-engineering	provides	gitflow-faseado	
onion-engineering	provides	pull-request-lifecycle	
onion-engineering	provides	qa-story-points	
onion-engineering	provides	ssot-context-resolver	
onion-engineering	requires	agent:branch-code-reviewer	
onion-engineering	requires	agent:code-reviewer	
onion-engineering	requires	agent:docker-specialist	
onion-engineering	requires	agent:gitflow-specialist	
onion-engineering	requires	agent:nodejs-specialist	
onion-engineering	requires	agent:postgres-specialist	
onion-engineering	requires	agent:react-developer	
onion-engineering	requires	agent:test-agent	
onion-engineering	requires	agent:test-engineer	
onion-engineering	requires	agent:test-planner	
onion-engineering	requires	skill:onion-engineering-context	
onion-evolve	lineage	product	
onion-evolve	lineage	vps-bridge	
onion-evolve	lineage	workstation	
onion-evolve	specialization	breadcrumbs	
onion-evolve	specialization	co-evolution	
onion-evolve	specialization	dogfooding	
onion-evolve	specialization	framework-template	
onion-evolve	specialization	sdaal	
onion-evolve	tier	source	
onion-kg-ssot	adopts	onion-evolve	
onion-kg-ssot	mode	greenfield	
onion-kg-ssot	pin	fe8359e38b43	
onion-kg-ssot	specialization	kg-ssot	
onion-kg-ssot	specialization	produto	
onion-kg-ssot	specialization	schema	
onion-kg-ssot	tier	standalone	
onion-kg-ssot	trust-advises	onion-evolve	
onion-mini	adopts	onion-evolve	
onion-mini	mode	distilled	
onion-mini	pin	n/a	
onion-mini	specialization	distilled-methodology	
onion-mini	specialization	entry-level	
onion-mini	specialization	multi-platform	
onion-mini	specialization	plea-cycles	
onion-mini	specialization	task-management-lite	
onion-mini	tier	standalone	
onion-mini	trust-advises	onion-evolve	
onion-pedro	adopts	onion-evolve	
onion-pedro	mode	greenfield	
onion-pedro	pin	165e1e13b11f	
onion-pedro	specialization	compliance	
onion-pedro	specialization	field-dogfood	
onion-pedro	specialization	greenfield-adoption	
onion-pedro	tier	standalone	
onion-pedro	trust-advises	onion-evolve	
onion-product	loads	embed:kb/framework-story-points.md	
onion-product	loads	embed:kb/identificar-precificar-dor-cliente.md	
onion-product	loads	when:spec -> resolve:business-context (skill onion-product-context)	
onion-product	provides	apresentacoes	
onion-product	provides	business-technical-context	
onion-product	provides	c4-model-mermaid	
onion-product	provides	decomposicao-de-tasks	
onion-product	provides	descoberta-a-backlog	
onion-product	provides	docs-health-validacao	
onion-product	provides	engenharia-reversa	
onion-product	provides	estimativa-story-points	
onion-product	provides	extracao-de-reunioes	
onion-product	provides	ssot-context-resolver	
onion-product	requires	agent:c4-architecture-specialist	
onion-product	requires	agent:c4-documentation-specialist	
onion-product	requires	agent:docs-reverse-engineer	
onion-product	requires	agent:extract-meeting-specialist	
onion-product	requires	agent:mermaid-specialist	
onion-product	requires	agent:pain-price-specialist	
onion-product	requires	agent:product-agent	
onion-product	requires	agent:story-points-framework-specialist	
onion-product	requires	agent:task-specialist	
onion-product	requires	skill:onion-product-context	
onion-slm	adopts	onion-evolve	
onion-slm	mode	greenfield	
onion-slm	pin	9e75a73d0401	
onion-slm	specialization	eval-de-dominio	
onion-slm	specialization	roteiro-gradual	
onion-slm	specialization	slm	
onion-slm	tier	standalone	
onion-slm	trust-advises	onion-evolve	
onion-standalone	adopts	onion-evolve	
onion-standalone	mode	greenfield	
onion-standalone	pin	685140eadd7d	
onion-standalone	specialization	claude-code	
onion-standalone	specialization	framework-door	
onion-standalone	specialization	public-distribution	
onion-standalone	specialization	role-scoped-adopt	
onion-standalone	tier	standalone	
onion-standalone	trust-advises	onion-evolve	
pain-price-specialist	related	product-agent	
pain-price-specialist	related	research-agent	
pmbok-specialist	related	/docs/build-compliance-docs	
pmbok-specialist	related	product-agent	
pmbok-specialist	related	security-information-master	
poc-venda-direta-pdi	adopts	onion-evolve	
poc-venda-direta-pdi	mode	greenfield	
poc-venda-direta-pdi	pin	219e9a5f365b	
poc-venda-direta-pdi	specialization	compliance-nda	
poc-venda-direta-pdi	specialization	document-comparison	
poc-venda-direta-pdi	specialization	greenfield-adoption	
poc-venda-direta-pdi	specialization	public-procurement	
poc-venda-direta-pdi	tier	standalone	
poc-venda-direta-pdi	trust-advises	onion-evolve	
portal-gamificacao	adopts	onion-evolve	
portal-gamificacao	mode	greenfield	
portal-gamificacao	pin	2e3f3a6f88ce	
portal-gamificacao	specialization	collaborator-layer	
portal-gamificacao	specialization	domain-kb-two-layers	
portal-gamificacao	specialization	gamification	
portal-gamificacao	specialization	kg-sealing-field-signal	
portal-gamificacao	specialization	maagica	
portal-gamificacao	tier	standalone	
portal-gamificacao	trust-advises	onion-evolve	
postgres-specialist	related	nodejs-specialist	
presentation-orchestrator	related	/product/presentation	
presentation-orchestrator	related	gamma-api-specialist	
presentation-orchestrator	related	mermaid-specialist	
presentation-orchestrator	related	product-agent	
presentation-orchestrator	related	storytelling-business-specialist	
product-agent	related	/product/feature	
product-agent	related	/product/spec	
product-agent	related	/product/task	
product-agent	related	clickup-specialist	
product-agent	related	storytelling-business-specialist	
product-agent	related	task-specialist	
pulse-mais	adopts	onion-evolve	
pulse-mais	mode	greenfield	
pulse-mais	pin	c711baa17617	
pulse-mais	specialization	education	
pulse-mais	specialization	learning-materials	
pulse-mais	specialization	srl-plea	
pulse-mais	tier	standalone	
pulse-mais	trust-advises	onion-evolve	
react-developer	related	/engineer/start	
react-developer	related	/engineer/work	
react-developer	related	code-reviewer	
react-developer	related	nodejs-specialist	
research-agent	related	/meta/create-knowledge-base	
research-agent	related	product-agent	
research-agent	related	storytelling-business-specialist	
sacola-de-ideias	adopts	onion-evolve	
sacola-de-ideias	mode	greenfield	
sacola-de-ideias	pin	8e2517724c0a	
sacola-de-ideias	specialization	astro-site	
sacola-de-ideias	specialization	greenfield-dogfood	
sacola-de-ideias	specialization	institutional	
sacola-de-ideias	tier	standalone	
sacola-de-ideias	trust-advises	onion-evolve	
security-information-master	related	/docs/build-compliance-docs	
security-information-master	related	iso-22301-specialist	
security-information-master	related	iso-27001-specialist	
security-information-master	related	pmbok-specialist	
security-information-master	related	soc2-specialist	
sge	adopts	onion-evolve	
sge	mode	regulated	
sge	pin	ba0d2d423c17	
sge	specialization	analise-tecnica	
sge	specialization	checklist-qualidade	
sge	specialization	lei-14133	
sge	specialization	licitacao-publica	
sge	specialization	regulated-greenfield	
sge	tier	standalone	
sge	trust-advises	onion-evolve	
soc2-specialist	related	/docs/build-compliance-docs	
soc2-specialist	related	iso-27001-specialist	
soc2-specialist	related	security-information-master	
story-points-framework-specialist	related	/product/feature	
story-points-framework-specialist	related	/product/spec	
story-points-framework-specialist	related	/product/task	
story-points-framework-specialist	related	product-agent	
story-points-framework-specialist	related	task-specialist	
storytelling-business-specialist	related	/docs/build-business-docs	
storytelling-business-specialist	related	/product/task	
storytelling-business-specialist	related	gamma-api-specialist	
storytelling-business-specialist	related	presentation-orchestrator	
storytelling-business-specialist	related	product-agent	
storytelling-business-specialist	related	research-agent	
system-documentation-orchestrator	related	/docs/build-tech-docs	
system-documentation-orchestrator	related	/docs/reverse-consolidate	
system-documentation-orchestrator	related	c4-architecture-specialist	
system-documentation-orchestrator	related	c4-documentation-specialist	
system-documentation-orchestrator	related	mermaid-specialist	
system-documentation-orchestrator	related	nx-monorepo-specialist	
task-specialist	related	/product/create-task-structure	
task-specialist	related	/product/task	
task-specialist	related	clickup-specialist	
task-specialist	related	product-agent	
test-agent	related	/engineer/pre-pr	
test-agent	related	/engineer/work	
test-agent	related	/validate/qa-points/estimate	
test-agent	related	/validate/test-strategy/create	
test-agent	related	code-reviewer	
test-agent	related	test-engineer	
test-agent	related	test-planner	
test-engineer	related	/engineer/work	
test-engineer	related	code-reviewer	
test-engineer	related	test-planner	
test-planner	related	/engineer/pre-pr	
test-planner	related	branch-test-planner	
test-planner	related	test-engineer	
vendas-pdi-enterprise	adopts	onion-evolve	
vendas-pdi-enterprise	mode	greenfield	
vendas-pdi-enterprise	pin	24118c5d7a97	
vendas-pdi-enterprise	specialization	rag-bridge	
vendas-pdi-enterprise	specialization	spec-as-code	
vendas-pdi-enterprise	specialization	vendas	
vendas-pdi-enterprise	tier	standalone	
vendas-pdi-enterprise	trust-advises	onion-evolve	
whisper-specialist	related	/product/consolidate-meetings	
whisper-specialist	related	/product/convert-to-tasks	
whisper-specialist	related	/product/extract-meeting	
whisper-specialist	related	extract-meeting-specialist	
whisper-specialist	related	product-agent	
```
