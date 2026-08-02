---
description: >
  Padrões de nomenclatura, estrutura e convenções do Sistema Onion. Use ao
  criar ou editar comandos, agentes, skills, sessions ou qualquer artefato em
  `.claude/`. Cobre estrutura de diretórios, kebab-case slugs, YAML headers
  obrigatórios, limites de linhas, formatação de comments ClickUp e fluxos
  principais. Ative mesmo sem o usuário mencionar "padrão" explicitamente.
paths: [".claude/**", "docs/onion/**"]
---

## Estrutura de Diretórios

### `.claude/commands/` (comandos invocáveis em 9 categorias + root; contagem canônica em `docs/INDEX.md`)
```
.claude/commands/
├── engineer/        # Fluxos de desenvolvimento
├── product/         # Gestão de produto e descoberta
├── git/             # GitFlow (feature/, hotfix/, release/)
├── docs/            # Documentação técnica e business
├── meta/            # Meta-comandos (criar agente, skill, command)
├── validate/        # Validações (test-strategy/, qa-points/, collab/)
├── test/            # Test unit, integration, e2e
├── common/          # Templates e prompts compartilhados
├── development/     # Comandos de desenvolvimento (runflow-dev)
└── quick/           # Ações rápidas
```

### `.claude/agents/` (51 agentes em 9 categorias)
```
.claude/agents/
├── development/     # 20 — React, Node, Jira, ClickUp, infra
├── product/         # 8 — product-agent, whisper, branding, etc.
├── meta/            # 5 — onion, agent-creator, skills-creator, etc.
├── compliance/      # 5 — ISO 27001/22301, SOC2, PMBOK
├── git/             # 4 — branch reviewers
├── testing/         # 3 — test-agent, test-engineer, test-planner
├── review/          # 2 — code-reviewer, compliance-reviewer
├── research/        # 1 — research-agent
└── deployment/      # 1 — docker-specialist
```

### `.claude/skills/<nome>/`
Cada skill em pasta própria com `SKILL.md`. Opcionalmente:
- `scripts/` — código executável (Python/Bash)
- `references/` — docs adicionais carregadas sob demanda
- `examples/` — exemplos de output

### `.claude/sessions/<feature-slug>/` (worklog)
Estrutura definida pela **SSOT** — não redefina aqui: [gitflow-patterns.md §Contrato de Sessão](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento). Worklog ACTIVE = `STATE.md` (índice Tier-0, ponto de resume) + `context.md` (+ Phase-Subtask Mapping) + `architecture.md` + `plan.md` + `notes.md`. Mecânica de leitura/resume: [worklog-protocol.md](../../../docs/knowledge-base/concepts/worklog-protocol.md).

## Nomenclatura

### Feature slugs — kebab-case obrigatório
```
✅ user-authentication
✅ payment-integration
✅ onion-v3-refactoring

❌ UserAuth          (PascalCase)
❌ payment_integration (snake_case)
❌ feature123          (não descritivo)
```

### Comandos
- Arquivo: `nome-comando.md` em kebab-case
- Caminho de invocação: `/categoria/nome-comando` ou `/categoria:subcategoria:nome`
- Ex: `/engineer/start`, `/product/task`, `/git:flow feature start`, `/meta:create-skill`

### Agentes
- Arquivo: `nome-especialista.md` em kebab-case
- Referência inline: `@nome-especialista` (sem extensão)
- Ex: `@react-developer`, `@jira-specialist`, `@onion`

### Skills
- Pasta: `nome-skill/SKILL.md` em kebab-case
- Invocação: `/nome-skill` (Claude Code mescla skills e commands)

## YAML Headers Obrigatórios

### Comando (`.claude/commands/*.md`)
```yaml
---
name: nome-comando
description: Descrição curta (1-2 linhas)
model: sonnet
category: engineer|product|git|docs|meta|validate|quick|test|common|development
tags: [tag1, tag2, tag3]
version: "3.0.0"
updated: "YYYY-MM-DD"
---
```

### Agente (`.claude/agents/<categoria>/*.md`)
```yaml
---
name: nome-agente
description: Descrição da especialização
model: sonnet|opus|haiku
category: development|product|meta|compliance|review|testing|research|git|deployment
tags: [tag1, tag2]
expertise: [area1, area2, area3]
version: "3.0.0"
updated: "YYYY-MM-DD"
---
```

### Skill (`.claude/skills/<nome>/SKILL.md`)
```yaml
---
description: >
  [Verbo imperativo] [o que faz]. Use quando [contexto explícito],
  mesmo que o usuário não mencione [keyword] diretamente.
paths: ["glob/opcional"]  # opcional, ativa só com arquivos matching
allowed-tools: Tool1 Tool2(arg*)  # opcional, escopo mínimo
---
```

## Limites e Métricas

| Métrica | Limite | Razão |
|---------|--------|-------|
| Comando | < 400 linhas | Otimização de tokens |
| Agente | < 300 linhas | Foco e clareza |
| Skill | < 500 linhas | Lifecycle persistente em contexto |
| Expertise/agente | 3-5 áreas | Especialização real |
| Tags/arquivo | 3-7 | Organização sem ruído |
| Description em skill | < 1024 chars | Trigger budget |

## Formatação por Provider (ClickUp)

Quando `TASK_MANAGER_PROVIDER=clickup`, comments seguem padrão visual Unicode:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ FASE N CONCLUÍDA — Nome da Fase
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 YYYY-MM-DD | Status: DONE

📊 Resultados:
∟ Item 1: valor
∟ Item 2: valor

🚀 Próxima: Fase N+1 — Nome
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Regras**:
- **Subtask**: comentário **detalhado** (métricas, arquivos, decisões)
- **Task principal**: comentário **resumido** (fase, status, próximo)
- Sempre incluir **timestamp** e **status**

Para Jira (`TASK_MANAGER_PROVIDER=jira`), usar **ADF** (JSON estruturado) — não Markdown nem Unicode.

## Fluxos Principais

### Feature Development
```
/product/task "descrição" → /engineer/start <slug> → /engineer/work → /engineer/pre-pr → /engineer/pr
```

### Hotfix
```
/engineer/hotfix → /engineer/work → /engineer/pr → /git:flow hotfix finish
```

### Criação de componentes Onion
```
/meta:create-agent      # novo agente especializado
/meta:create-skill      # nova skill
/meta:create-command    # novo comando
/meta:create-knowledge-base  # nova KB em docs/knowledge-base/
```

## Playbooks (recognition-primed — catálogo, blip #9)

> **Doutrina (RFC-0002):** dado um objetivo, **reconheça** a situação contra este catálogo e **aplique** o
> playbook (barato); só **delibere** (fan-out/juízes — caro) quando não há match, e o resíduo vira playbook
> novo (o catálogo aprende). É **seleção** (qual aplicar) + **execução** (rodar) — a execução não-trivial
> costuma ser um **PFR** (workflow faseado retomável: `reconheça o caso → rode o fluxo`).

### descoberta → backlog
Situação: ideias/reuniões brutas a virar backlog priorizado.
```
/product/collect → /product/spec → /product/feature   (bruto: /product/extract-meeting → /product/consolidate-meetings → /product/convert-to-tasks)
```

### planejamento → entrega  (é um PFR)
Situação: feature definida a implementar com rastreabilidade.
```
/engineer/plan → /engineer/start <slug> → /engineer/work → /engineer/pre-pr → /engineer/pr
```

### assumir um repo  ("adota não impõe")
Situação: instalar/operar o Onion num projeto novo ou legado — **detectar o padrão do projeto, não impor**.
```
/meta:adopt (detect → defer/extend/introduce, never-clobber) → /docs/reverse-consolidate → /docs/build-tech-docs
```

### agir em ambiente compartilhado / prod-durante-dev  (guarda — sinal de campo)
Situação: incidente em prod enquanto se desenvolve; HML = prod-real + homolog; `.env`/flags ambíguos.
Playbook (disciplina, não-comando): **declarar `{ambiente, branch, reversível?}` antes de agir** · **verificar
antes de escrever em prod** (nunca agir sob suposição não-verificada) · **separar frentes** (incidente ≠ feature).

### laço de realimentação sem guarda  (guarda — sinal de campo)
Situação: laço de alto ganho sobre estado/sinal **sem amortecimento** (sem clamp, cap-de-profundidade,
dead-letter, anti-windup).
Playbook: reconheça → **clamp / anti-windup / estado-mínimo / dead-letter**; **guarde primeiro o laço de
maior ganho/raio-de-dano** (kill-switch antes de afinar). Implementação concreta = engenharia local do adotante.

### promover objeto existente a papel premium  (object-led discovery & fitting — sinal de campo)
Situação: maestro pede para elevar um objeto existente e solto (ex.: uma `<table>`) a um componente/papel
reutilizável e rico ("premium") — diferente de `create-*` (que parte do zero).
Playbook: **espelhar** (stub/worktree se a migração muta N arquivos; plano se for leitura) → **descobrir
object-led** (Capability Contract do objeto: `provides/requires`/tier atual; inventariar pares no repo) →
**vestir** (resolver o **perfil completo** do papel-alvo de saída — não por pedido sucessivo — reusando
catálogo/SDAAL antes de introduzir dependência nova) → **materializar** (gate por etapa + verificação) →
**realimentar** (o perfil descoberto vira entrada de catálogo para a próxima promoção do mesmo tipo de objeto).

### validação de doutrina — o **ELENXO** (superação de alto risco — sinal de campo)

> **O nome é PRESCRIÇÃO, não rótulo.** *Elenxo* (do grego *élenchos*, a refutação socrática) não batiza
> o que já se fazia — **define as etapas que uma superação de doutrina tem de cumprir para valer**.
> A diferença não é semântica: como descrição, "esta corrida pulou a refutação" seria só uma
> imprecisão de nome; como prescrição, é **não-conformidade** — e é isso que permite reprovar.
> Mesmo padrão do **Teste do Eixo** (SDAAL), que não descreve abstrações existentes: define 3
> condições, e por isso pôde reprovar 3 propostas em 3 dias.

**AS 5 ETAPAS.** Uma corrida só é Elenxo se cumpriu **todas**. Falhou uma → foi
`fan-out-and-synthesize`, que é legítimo e mais barato — **use o nome certo**.

| # | Etapa | O que reprova |
|---|---|---|
| **1** | **Fan-out de lentes INDEPENDENTES** — cegas entre si, cada uma com um eixo próprio (absorção, coerência-doutrinária, mercado/prior-art, risco-adversarial) | lentes que se leem = uma lente com N vozes |
| **2** | **Steelman** — a versão mais forte de cada posição, não a de palha | atacar a versão fraca é vitória vazia |
| **3** | **Refutação adversarial** — worker(s) cujo mandato é **REFUTAR**, com default `refutado` na dúvida | sem esta etapa **não é Elenxo** — é síntese |
| **4** | **Síntese que arbitra por RAZÃO e preserva DISSENT** — a objeção sobrevivente mais forte **contra a própria conclusão** fica no artefato | placar de votos; síntese sem dissent |
| **5** | **`write(KG)` com `SUPERSEDES`/`REFUTES`** — a ideia nova supera a antiga **sem apagá-la** (Aufhebung); genealogia auditável | **refutação narrada em prosa e grafo em 0/0/0/0** |

⚠️ **A etapa 5 é a que mais falha, e é medida.** Em 2026-08-02, de 6 corridas que declararam Elenxo,
**2 narravam refutação em prosa com o grafo vazio** — 5ª e 6ª ocorrência da cicatriz de
[`kg-born-marker.sh:26`](../../validation/kg-born-marker.sh). Refutação que não virou **aresta** não
é consultável: o próximo a perguntar *"isso já foi testado?"* re-deriva do zero.

**Por que NÃO há gate mecânico disto** (medido, não presumido): testou-se exigir rastro de refutação
de quem declara "Elenxo" no `method:`. O candidato **não separa** — das corridas COM etapa
adversarial, 2 de 4 **falhariam**; das SEM, 2 de 2 **passariam**. Correlação zero a invertida: o gate
puniria justamente quem refutou. E `method:` tem **zero consumidores** no repo — ninguém lê, logo
ninguém foi enganado (portão 1 fecha com N=0 provado). **A conformidade aqui é lida por humano
contra esta tabela**, e isso está declarado, não escondido.

**Aristóteles ao invocar:** o Elenxo é caro (fan-out orquestrado + tier `opus/high` na refutação).
`efficiency-over-economy` **não** significa usar sempre — significa usar **onde o custo de errar é
doutrinário**. Para escolha reversível de baixo risco, fan-out simples basta.


Situação: uma decisão de **doutrina** de alto risco está na mesa (nomear um conceito, um invariante novo, uma
ideia que **supera** uma anterior) — onde a qualidade da superação importa e o custo de errar é doutrinário.
Não decida por prior/estética/votação.
Playbook: **fan-out de lentes independentes** (ex.: absorção-pelo-Transformer, coerência-doutrinária,
mercado/prior-art, risco-adversarial) → **síntese** que arbitra por razão (não placar) → **verificação
adversarial** que tenta REFUTAR e faz a ideia *merecer* selar (é ela que acha os furos reais) → **`write(KG)`**
com arestas **`SUPERSEDES`**: a ideia nova supera a antiga **sem apagá-la** (Aufhebung), e a genealogia fica
**auditável** no KG-SSOT (*"git merge não reconcilia verdades"*). Gate: **não sela** até o adversário passar +
1 dogfood de uso. É o motor de **qualidade da superação de doutrina** — decisões "já existem" como evolução de
ideias; isto as faz evoluir com rigor. **Tiere** (`efficiency-over-economy`): é caro (fan-out orquestrado) — só
para superações de alto risco, nunca toda escolha. 1º dogfood: a doutrina do `telescópio`
(`docs/analysis/onion-adr-telescope-session-observation-2026-07.md`).

## Gotchas

- **Feature slug com underscore quebra GitFlow**: branches Git e pastas de sessão usam o mesmo slug — kebab-case é obrigatório
- **Categoria inválida derruba o gate-keeper**: `@metaspec-gate-keeper` valida `category` no YAML header
- **Tag count fora de 3-7 reduz searchability**: muitas tags poluem, poucas não cobrem
- **YAML sem `updated` impede tracking**: sempre incluir data ISO

## Referências

- Knowledge Base: `docs/knowledge-base/concepts/task-manager-abstraction.md`
- Templates: `.claude/commands/common/templates/`
- Skill relacionada: `language-standards` (idioma e docs)
- Skill relacionada: `onion-validation` (regras de validação)
- Agente: `@metaspec-gate-keeper` (valida conformidade)
- Playbooks/catálogo (#9): `docs/evolution/rfc/rfc-0002-meta-strategy-verdict.md` (doutrina) · `docs/analysis/onion-adr-phased-resumable-pattern-2026-06.md` (PFR = execução)
