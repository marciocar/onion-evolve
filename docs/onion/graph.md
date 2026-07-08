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
- **onion** --has-member--> onion-orchestration
- **onion** --has-member--> onion-patterns
- **onion** --has-member--> onion-validation
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
- **onion** --serves--> maestro

## Capacidades por vertical (requires / provides / loads)

- onion-compliance **loads** when:framework=iso27001 -> template:compliance_iso27001_template.md
- onion-compliance **loads** when:framework=soc2 -> template:compliance_soc2_template.md
- onion-compliance **provides** build-compliance-docs
- onion-compliance **provides** iso-22301-bcms
- onion-compliance **provides** iso-27001-isms
- onion-compliance **provides** pmbok-governance
- onion-compliance **provides** soc2-tsc
- onion-compliance **requires** agent:iso-22301-specialist
- onion-compliance **requires** agent:iso-27001-specialist
- onion-compliance **requires** agent:pmbok-specialist
- onion-compliance **requires** agent:security-information-master
- onion-compliance **requires** agent:soc2-specialist
- onion-compliance **requires** command:build-compliance-docs
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
- onion-docs **provides** business-technical-context
- onion-docs **provides** c4-model-mermaid
- onion-docs **provides** docs-health-validacao
- onion-docs **provides** engenharia-reversa
- onion-docs **requires** agent:c4-architecture-specialist
- onion-docs **requires** agent:c4-documentation-specialist
- onion-docs **requires** agent:docs-reverse-engineer
- onion-docs **requires** agent:mermaid-specialist
- onion-engineering **provides** code-review-pre-pr
- onion-engineering **provides** code-specialists-node-react-postgres-nx-docker
- onion-engineering **provides** gitflow-faseado
- onion-engineering **provides** pull-request-lifecycle
- onion-engineering **requires** agent:branch-code-reviewer
- onion-engineering **requires** agent:code-reviewer
- onion-engineering **requires** agent:docker-specialist
- onion-engineering **requires** agent:gitflow-specialist
- onion-engineering **requires** agent:nodejs-specialist
- onion-engineering **requires** agent:postgres-specialist
- onion-engineering **requires** agent:react-developer
- onion-product **provides** apresentacoes
- onion-product **provides** decomposicao-de-tasks
- onion-product **provides** descoberta-a-backlog
- onion-product **provides** estimativa-story-points
- onion-product **provides** extracao-de-reunioes
- onion-product **requires** agent:extract-meeting-specialist
- onion-product **requires** agent:pain-price-specialist
- onion-product **requires** agent:product-agent
- onion-product **requires** agent:story-points-framework-specialist
- onion-product **requires** agent:task-specialist
- onion-testing **provides** estrategia-de-teste
- onion-testing **provides** geracao-testes-unit-integration-e2e
- onion-testing **provides** qa-story-points
- onion-testing **requires** agent:test-agent
- onion-testing **requires** agent:test-engineer
- onion-testing **requires** agent:test-planner

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
assistant	asks	maestro	conversa-plan-gate
assistant	evolves	onion	
assistant	executes	onion	
assistant	orchestrates-workers	subagent	orchestration
assistant	proposes	maestro	conversa-plan-gate
assistant	reports	maestro	conversa-plan-gate
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
linux-security-specialist	related	iso-27001-specialist	
maestro	approves	assistant	conversa-plan-gate
maestro	gates	assistant	conversa-plan-gate
maestro	orchestrates	assistant	
maestro	requests	assistant	conversa-plan-gate
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
onion	has-member	onion-orchestration	
onion	has-member	onion-patterns	
onion	has-member	onion-validation	
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
onion	serves	maestro	
onion-compliance	loads	when:framework=iso27001 -> template:compliance_iso27001_template.md	
onion-compliance	loads	when:framework=soc2 -> template:compliance_soc2_template.md	
onion-compliance	provides	build-compliance-docs	
onion-compliance	provides	iso-22301-bcms	
onion-compliance	provides	iso-27001-isms	
onion-compliance	provides	pmbok-governance	
onion-compliance	provides	soc2-tsc	
onion-compliance	requires	agent:iso-22301-specialist	
onion-compliance	requires	agent:iso-27001-specialist	
onion-compliance	requires	agent:pmbok-specialist	
onion-compliance	requires	agent:security-information-master	
onion-compliance	requires	agent:soc2-specialist	
onion-compliance	requires	command:build-compliance-docs	
onion-compliance	requires	template:compliance-context-template.md	
onion-compliance	requires	template:compliance_iso22301_template.md	
onion-compliance	requires	template:compliance_iso27001_template.md	
onion-compliance	requires	template:compliance_pmbok_template.md	
onion-compliance	requires	template:compliance_soc2_template.md	
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
onion-docs	provides	business-technical-context	
onion-docs	provides	c4-model-mermaid	
onion-docs	provides	docs-health-validacao	
onion-docs	provides	engenharia-reversa	
onion-docs	requires	agent:c4-architecture-specialist	
onion-docs	requires	agent:c4-documentation-specialist	
onion-docs	requires	agent:docs-reverse-engineer	
onion-docs	requires	agent:mermaid-specialist	
onion-engineering	provides	code-review-pre-pr	
onion-engineering	provides	code-specialists-node-react-postgres-nx-docker	
onion-engineering	provides	gitflow-faseado	
onion-engineering	provides	pull-request-lifecycle	
onion-engineering	requires	agent:branch-code-reviewer	
onion-engineering	requires	agent:code-reviewer	
onion-engineering	requires	agent:docker-specialist	
onion-engineering	requires	agent:gitflow-specialist	
onion-engineering	requires	agent:nodejs-specialist	
onion-engineering	requires	agent:postgres-specialist	
onion-engineering	requires	agent:react-developer	
onion-product	provides	apresentacoes	
onion-product	provides	decomposicao-de-tasks	
onion-product	provides	descoberta-a-backlog	
onion-product	provides	estimativa-story-points	
onion-product	provides	extracao-de-reunioes	
onion-product	requires	agent:extract-meeting-specialist	
onion-product	requires	agent:pain-price-specialist	
onion-product	requires	agent:product-agent	
onion-product	requires	agent:story-points-framework-specialist	
onion-product	requires	agent:task-specialist	
onion-testing	provides	estrategia-de-teste	
onion-testing	provides	geracao-testes-unit-integration-e2e	
onion-testing	provides	qa-story-points	
onion-testing	requires	agent:test-agent	
onion-testing	requires	agent:test-engineer	
onion-testing	requires	agent:test-planner	
pain-price-specialist	related	product-agent	
pain-price-specialist	related	research-agent	
pmbok-specialist	related	/docs/build-compliance-docs	
pmbok-specialist	related	product-agent	
pmbok-specialist	related	security-information-master	
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
react-developer	related	/engineer/start	
react-developer	related	/engineer/work	
react-developer	related	code-reviewer	
react-developer	related	nodejs-specialist	
research-agent	related	/meta/create-knowledge-base	
research-agent	related	product-agent	
research-agent	related	storytelling-business-specialist	
security-information-master	related	/docs/build-compliance-docs	
security-information-master	related	iso-22301-specialist	
security-information-master	related	iso-27001-specialist	
security-information-master	related	pmbok-specialist	
security-information-master	related	soc2-specialist	
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
whisper-specialist	related	/product/consolidate-meetings	
whisper-specialist	related	/product/convert-to-tasks	
whisper-specialist	related	/product/extract-meeting	
whisper-specialist	related	extract-meeting-specialist	
whisper-specialist	related	product-agent	
```
