---
verified_at: 2026-11-18
source: "https://code.claude.com/docs/en/hooks"
applies_to: "Claude Code 2.1.326 (binário medido em 2026-11-18; CHANGELOG oficial no topo em 2.1.327). Escrita contra a doc de 2026-06-15, verificada em 2026-07-23 e reverificada em 2026-11-18"
---

# Claude Code Commands Best Practices (atualizado em 2026-06-15, reverificado em 2026-11-18)

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2025-11-24 |
| **Última Atualização** | 2026-11-18 (reverificação: hooks, deep links, menções `@`, regras, nesting, agent view, fontes) |
| **Categoria** | Tools |
| **Aplicação** | Sistema Onion - Comandos e Agentes |

### Fontes

- [Claude Code Official Documentation](https://code.claude.com/docs/en/overview) (reverificado 2026-11-18, HTTP 200; `docs.claude.com/en/docs/claude-code/*` redireciona para cá)
- [Claude Code CHANGELOG](https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md) (reverificado 2026-11-18, HTTP 200, topo 2.1.327; `docs.claude.com/en/release-notes/claude-code` redireciona para o CHANGELOG no GitHub)
- [Hooks reference](https://code.claude.com/docs/en/hooks) · [Deep links](https://code.claude.com/docs/en/deep-links) · [Memory e `.claude/rules/`](https://code.claude.com/docs/en/memory) · [Interactive mode](https://code.claude.com/docs/en/interactive-mode) (reverificados 2026-11-18, HTTP 200)
- [Dynamic Workflows](https://code.claude.com/docs/en/workflows) (lançado em research preview em 28/mai/2026; reverificado 2026-11-18)
- [How we built our multi-agent research system — Anthropic](https://www.anthropic.com/research/multi-agent-research-system) — substitui o link anterior `anthropic.com/engineering/multi-agent-orchestration`, que dá **HTTP 404** (2026-11-18)
- [Agent view — observabilidade de sessões](https://code.claude.com/docs/en/agent-view) — **segue em research preview** (desde 2.1.139); a redação antiga dizia "GA mai/2026" (reverificado 2026-11-18)

---

## 🎯 Visão Geral

Este documento consolida as melhores práticas para criação e uso de comandos personalizados no Claude Code, focando em eficiência, manutenibilidade e integração com sistemas de IA.

> **Refresh 2026-06-13 (v1.1.0)**: além das práticas de comandos individuais, esta KB agora cobre o substrato nativo de orquestração — a ferramenta **Workflow** (Dynamic Workflows, research preview de 28/mai/2026), a ferramenta **Agent** (subagente único; nesting até 3 camadas por default desde 2.1.219) e o papel das **Skills** como ponto de orquestração no nível principal. O lineup de modelos **à época desta KB** (jun/2026) era Opus 4.8, Sonnet 4.6 e Haiku 4.5; em 2026-11-18 é Opus 5.5, Sonnet 5.5, Haiku 5.5 e Fable 5.2. Ele drifta: cite por tier e consulte a fonte única [`agent-orchestration.md` §Disponibilidade de modelos](../concepts/agent-orchestration.md).

---

## 📁 Estrutura de Comandos

### Localização Padrão

```
projeto/
├── .claude/
│   ├── commands/           # Comandos personalizados
│   │   ├── categoria/      # Organização por categoria
│   │   │   └── comando.md  # Arquivo do comando
│   │   └── common/         # Recursos compartilhados
│   │       ├── prompts/    # Prompts reutilizáveis
│   │       └── templates/  # Templates de código
│   ├── agents/             # Agentes especializados
│   ├── skills/             # Skills (<nome>/SKILL.md); o formato que a doc recomenda hoje
│   ├── hooks/              # Scripts de hook (registrados no settings.json)
│   ├── rules/              # Regras de comportamento (*.md, opcionalmente com `paths`)
│   └── sessions/           # Contexto de sessões
```

### Convenções de Nomenclatura

| Elemento | Padrão | Exemplo |
|----------|--------|---------|
| Comando | `kebab-case.md` | `create-task.md` |
| Categoria | `lowercase` | `product/`, `engineer/` |
| Agente | `kebab-case.md` | `code-reviewer.md` |
| Regra | `kebab-case.md` em `.claude/rules/` | `language-rules.md` |

> Reverificado em 2026-11-18: o Claude Code descobre `.claude/rules/*.md` ([memory](https://code.claude.com/docs/en/memory)); `.mdc` é a extensão de regras do Cursor e não é lida pelo Claude Code. A doc também diz que um arquivo em `.claude/commands/` "é o formato mais antigo e ainda funciona"; a skill (`.claude/skills/<nome>/SKILL.md`) é o formato atual e aceita arquivos de apoio.

---

## 📝 Anatomia de um Comando

### Estrutura Recomendada

```markdown
# Nome do Comando

Descrição breve do propósito (1-2 linhas).

## 🎯 Objetivo
[Descrição detalhada do que o comando faz]

## 📋 Inputs
[Parâmetros esperados do usuário]

## 🔄 Processo
[Etapas de execução]

## 📤 Outputs
[O que será gerado/retornado]

## ⚠️ Validações
[Regras de validação]

## 💡 Exemplos
[Casos de uso práticos]
```

### Limite de Tamanho

| Classificação | Linhas | Recomendação |
|---------------|--------|--------------|
| **Ideal** | < 300 | ✅ Melhor performance |
| **Aceitável** | 300-500 | ⚠️ Considerar modularização |
| **Problemático** | > 500 | ❌ Deve ser refatorado |

**Motivo**: Comandos longos consomem mais tokens e podem exceder limites de contexto.

---

## 🔧 Funcionalidades do Claude Code (reverificadas 2026-11-18)

### 1. Hooks

Permitem observar, controlar e estender o loop do Agente. Não são beta: a [referência de hooks](https://code.claude.com/docs/en/hooks) os documenta como recurso estável, com eventos como `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SessionStart`, `TeammateIdle` e `TaskCompleted`. Um hook que sai com **código 2** num `PreToolUse` **bloqueia** a chamada da ferramenta.

**Casos de Uso:**
- Auditoria de atividades do Agente
- Bloqueio de comandos arriscados
- Aplicação de lógica personalizada
- Logging de operações

**Exemplo de Hook** (forma da doc oficial, 2026-11-18). O hook é registrado no `settings.json` e aponta para um script; o script lê o JSON do evento na entrada padrão e sai com código 2 para bloquear:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(rm *)",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.sh"
          }
        ]
      }
    ]
  }
}
```

> Corrigido em 2026-11-18: a versão anterior mostrava um YAML em `.claude/hooks/audit-hook.yaml` com `trigger: before_shell_command`. Esse formato não existe no Claude Code. O core segue a forma acima: os scripts moram em `.claude/hooks/*.sh` e o registro, no `settings.json`.

### 2. Deep Links para Prompts

Gera links que abrem prompts diretamente no Claude Code.

**Benefícios:**
- Reutilização de prompts complexos
- Onboarding de novos membros
- Documentação interativa
- Compartilhamento de workflows

**Formato** (reverificado 2026-11-18 em [deep links](https://code.claude.com/docs/en/deep-links)):
```
claude-cli://open?repo=<owner/repo>&q=<prompt-url-encoded>
```

O link abre o Claude Code num terminal novo, no repositório indicado, com o prompt preenchido e **não enviado** até o usuário apertar Enter. A versão anterior desta KB mostrava `claude://prompt?text=…&files=…`, que não é o esquema documentado.

### 3. Menções de contexto (`@`)

No Claude Code, `@` dispara o **autocomplete de caminho de arquivo** ([interactive mode](https://code.claude.com/docs/en/interactive-mode)): `@src/arquivo.ts` ou `@src/components/` põe o arquivo ou a pasta no contexto. Recursos de servidores MCP também entram por menção `@`. No CLAUDE.md, `@caminho` **importa** outro arquivo ([memory](https://code.claude.com/docs/en/memory)).

> Corrigido em 2026-11-18: a tabela anterior listava `@Files`, `@Folders`, `@Code`, `@Docs`, `@Web` e `@Codebase`. São menções do Cursor, não do Claude Code. Para busca na web o Claude Code usa as ferramentas `WebSearch` e `WebFetch`; para busca no projeto, `Grep` e `Glob`.

### 4. MCP (Model Context Protocol) Servers

Fornecem contexto adicional e ferramentas para o modelo.

**Integração (transporte opcional).** No Onion, task managers são consumidos pela **Task Manager Abstraction** plugável (`TASK_MANAGER_PROVIDER` = jira|clickup|asana|linear|none): o consumidor chama `taskManager.*` via o adapter (`.claude/utils/task-manager/`) — **REST API por default; MCP é transporte opcional**. O exemplo de MCP abaixo é **um** transporte de **um** provider (ClickUp), não o caminho canônico:
```json
{
  "mcpServers": {
    "clickup": {
      "command": "npx",
      "args": ["-y", "<pacote-do-servidor-mcp-do-clickup>"],
      "env": {
        "CLICKUP_API_TOKEN": "${CLICKUP_API_TOKEN}"
      }
    }
  }
}
```
> Nunca hardcode um provider no comando/agente — roteie pela abstração. Ver [task-manager-abstraction.md](../concepts/task-manager-abstraction.md).
>
> Corrigido em 2026-11-18: o exemplo citava o pacote `@anthropic/clickup-mcp-server`, que **não existe** no registry npm (HTTP 404). O nome do pacote ficou como marcador; o adapter do ClickUp (`.claude/utils/task-manager/adapters/clickup.md`) é a fonte do transporte MCP opcional.

---

## 🚢 Orquestração (Claude Code 2026)

A partir de meados de 2026, o Claude Code traz orquestração **nativa**. Em vez de descrever delegação em prosa e disparar subagentes um a um de forma manual e sequencial, o desenvolvedor declara a topologia da orquestração em código e a engine executa o fan-out, a sincronização e a validação por você.

### Ferramenta Workflow (Dynamic Workflows, 28/mai/2026)

A ferramenta **Workflow** (lançada em research preview em 28/mai/2026; hoje disponível em todos os planos pagos, reverificado 2026-11-18) é o substrato nativo de orquestração no Claude Code. A coordenação roda em **JavaScript** e custa **0 tokens de modelo** — só os subagentes consomem tokens. Isso torna topologias complexas baratas e determinísticas.

Primitivas expostas:

| Primitiva | Assinatura | O que faz |
|-----------|------------|-----------|
| `agent` | `agent(prompt, opts)` | Dispara **1 subagente** com o prompt e opções fornecidas |
| `parallel` | `parallel([thunks])` | **Barreira / fan-out**: executa thunks concorrentemente e aguarda todos terminarem |
| `pipeline` | `pipeline(items, stage1, stage2, ...)` | Processa itens em estágios encadeados **sem barreira entre itens** (streaming por item) |
| `schema` | — | Define **structured output validado** na saída de um agente ou do workflow |
| `isolation` | `isolation: 'worktree'` | Isola cada execução em um **git worktree** dedicado (evita colisão de arquivos entre subagentes) |
| `budget` | — | Saldo de tokens do run, lido no script (`budget.remaining()`) |

> Alcance (2026-11-18): a [doc pública](https://code.claude.com/docs/en/workflows) documenta `agent()`, `parallel()`, `pipeline()`, `phase()`, `log()`, `args` e as opções `schema` e `label`. `isolation: "worktree"` e `budget.remaining()` foram conferidos como strings do binário 2.1.326, não na doc; a referência completa é a skill embutida `/workflow-authoring`. O exemplo abaixo, que passa `budget: 200_000` a um `agent()`, segue a redação de jun/2026 e não foi confirmado como opção por agente.

Limites (reverificados 2026-11-18): **16 agentes concorrentes por default** (ajustável de 1 a 256 por `CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS`), **1.000 agentes por run** e até **4.096 itens** por `parallel()`/`pipeline()`.

```javascript
// Fan-out-and-synthesize: revisar N módulos em paralelo, depois consolidar.
const reviews = await parallel(
  modules.map((mod) => () =>
    agent(`Revise o módulo ${mod.path} buscando bugs e dívida técnica.`, {
      isolation: 'worktree',
      schema: reviewSchema,
    })
  )
);

// A barreira garante que todos os reviews terminem antes da síntese.
const summary = await agent(
  `Consolide os ${reviews.length} reviews em um relatório priorizado.`,
  { schema: reportSchema, budget: 200_000 }
);
```

```javascript
// Pipeline: cada arquivo flui por estágios sem esperar os demais (sem barreira).
await pipeline(
  files,
  (file) => agent(`Extraia símbolos públicos de ${file}.`, { schema: symbolSchema }),
  (symbols) => agent(`Gere docs em pt-BR para ${symbols.length} símbolos.`)
);
```

Padrões canônicos de orquestração da Anthropic (2026) que mapeiam diretamente nessas primitivas: **classify-and-act**, **fan-out-and-synthesize**, **adversarial verification**, **generate-and-filter**, **tournament** e **loop-until-done**. A doutrina da "orchestration era" recomenda **control before autonomy**, atenção ao **delegation gap**, **hierarchical model tiers** (Opus orquestrando + Sonnet/Haiku como workers) e **prompt caching** para reduzir custo.

### Ferramenta Agent e subagentes

A ferramenta **Agent** dispara **1 subagente especializado** — é a unidade básica de delegação. Nesting reverificado em 2026-11-18 ([sub-agents](https://code.claude.com/docs/en/sub-agents)): desde **2.1.219**, até **3 camadas abaixo da conversa principal** por default (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`); a nota antiga de "5 níveis desde v2.1.172" foi superada. Há teto de **20 subagentes concorrentes** (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`) e nenhum teto total por sessão.

Contraste prático:

| Aspecto | Ferramenta **Agent** | Ferramenta **Workflow** |
|---------|----------------------|--------------------------|
| Cardinalidade | 1 subagente por chamada | Workers (16 concorrentes por default / 1.000 por run) |
| Concorrência | Várias chamadas podem rodar em paralelo ou em background, até 20 concorrentes, mas cada uma é decidida pelo modelo | Fan-out paralelo nativo (`parallel`) |
| Coordenação | Implícita no modelo (consome tokens) | JavaScript (0 tokens de modelo) |
| Isolamento / budget / schema | Manual | Declarativo (`isolation`, `budget`, `schema`) |
| Quando usar | Delegar uma tarefa pontual | Distribuir/sincronizar trabalho em escala |

Regra de ouro: orquestração é **mais barata e mais limpa no nível principal** (skill/comando), não dentro de um subagente. Use `Agent` quando precisa de uma delegação única; use `Workflow` quando precisa de paralelismo, barreiras ou pipelines.

### Skills como ponto de orquestração

No nível principal, **Skills** são o lugar canônico para orquestrar workers. Uma skill pode invocar comandos e agentes e, portanto, hospedar a lógica de `Workflow`/`Agent`. No Sistema Onion (framework template em `.claude/` sobre Claude Code), a arquitetura (architecture.md §4.2) **proíbe** `agents/* → commands/*` — um agente **sugere**, mas não invoca um comando. Skills, por outro lado, **podem orquestrar** (`skills/* → commands/*, agents/*`).

Consequência direta: a orquestração mora em **SKILL + COMANDO**, nunca em um agente. **Não** crie um agente do tipo `worker-orchestrator` — ele seria incapaz de invocar comandos e violaria a §4.2.

### Observabilidade: agent view (research preview)

Com workers rodando em paralelo, a visibilidade de cada sessão é essencial. O **agent view** (`claude agents`, em research preview desde 2.1.139; a redação antiga dizia "GA desde mai/2026", reverificado 2026-11-18) oferece observabilidade de sessões paralelas — acompanhar o que cada subagente está fazendo, custo por sessão e estado da orquestração em tempo real. Para os agentes de um workflow, a view é `/workflows`. Superfícies relacionadas (estado de preview de jun/2026, não reconferido): **Managed Agents** (beta, abr/2026) e **Routines** (research preview, mai/2026).

---

## ✨ Boas Práticas de Prompt Engineering

### 1. Especificidade

**❌ Ruim:**
```
Crie um componente
```

**✅ Bom:**
```
Crie um componente React funcional chamado UserCard que:
- Receba props: { name: string, email: string, avatar?: string }
- Use Tailwind CSS para estilização
- Inclua fallback para avatar ausente
- Exporte como default
```

### 2. Princípio MECE (Mutually Exclusive, Collectively Exhaustive)

Divida instruções em partes que não se sobrepõem mas cobrem tudo.

**Exemplo:**
```markdown
## Requisitos do Componente

### Layout (visual)
- Card com bordas arredondadas
- Sombra sutil

### Comportamento (funcional)
- Clicável para expandir detalhes
- Animação de hover

### Dados (props)
- Nome obrigatório
- Email obrigatório
- Avatar opcional
```

### 3. Iteração e Refinamento

Prefira múltiplas interações curtas a uma única longa.

```
Interação 1: "Crie a estrutura base do componente"
Interação 2: "Adicione os estilos Tailwind"
Interação 3: "Implemente a lógica de hover"
Interação 4: "Adicione testes unitários"
```

### 4. Contexto Relevante

Use `@mentions` para fornecer contexto específico:

```
Usando o padrão de @src/components/Button.tsx,
crie um componente similar para Card.
```

---

## 🚀 Patterns de Comandos Eficientes

### Pattern 1: Comando com Delegação

**Delegação sequencial manual** (legado) — uma tarefa por vez, descrita em prosa:

```markdown
# Comando Principal

## Processo
1. Analisar requisitos
2. **Delegar para @agente-especialista** se necessário
3. Validar resultado
4. Retornar output
```

**Paralelismo nativo via Workflow** (recomendado a partir de 2026) — quando o trabalho se divide em itens independentes, declare a orquestração e deixe a engine fazer o fan-out e a barreira. A coordenação roda em JavaScript (0 tokens) e o `schema` valida cada saída:

```javascript
// Em vez de N delegações sequenciais ao @agente-especialista,
// distribua os N itens em paralelo e sincronize com a barreira.
const results = await parallel(
  items.map((item) => () =>
    agent(`Processe o item ${item.id} segundo o padrão do projeto.`, {
      schema: itemSchema,
    })
  )
);
const consolidated = await agent('Consolide os resultados em um único output.', {
  schema: outputSchema,
});
```

Use a delegação sequencial quando há **dependência de ordem** ou uma **única** tarefa; use `Workflow`/`parallel` quando os itens são **independentes** e o paralelismo reduz latência e custo.

### Pattern 2: Comando com Contexto Externo

```markdown
# Comando com Integração

## Integrações Opcionais
Se disponível, utilize (sempre via adapter, nunca o provider direto):
- Task Manager via adapter agnóstico (`TASK_MANAGER_PROVIDER`: jira|clickup|asana|linear) para gestão de tasks
- Forge via adapter (GitHub/GitLab) para PRs

## Fallback
Sem integrações, gere output em formato compatível.
```

### Pattern 3: Comando Modular

> ⚠️ Reverificado em 2026-11-18: `@include` **não é sintaxe do Claude Code**. O bloco abaixo é convenção textual da casa, que o modelo lê e segue; o harness não o expande. O documentado é `@caminho` como import no CLAUDE.md e a referência `@arquivo` num comando ou skill.

```markdown
# Comando Modular

## Prompts Compartilhados
@include common/prompts/validation-rules.md
@include common/prompts/output-formats.md

## Processo
[Lógica específica do comando]
```

### Pattern 4: Comando com Sessão

```markdown
# Comando com Contexto de Sessão

## Verificar Sessão
1. Buscar `.claude/sessions/<feature>/context.md`
2. Carregar contexto existente
3. Atualizar com novas informações

## Auto-Save
Ao finalizar, salvar estado em context.md
```

---

## ⚠️ Anti-Patterns a Evitar

### 1. Comandos Monolíticos

**❌ Problema:** Um comando faz tudo
```markdown
# super-comando.md
[1000+ linhas cobrindo criação, teste, deploy, documentação...]
```

**✅ Solução:** Dividir em comandos menores
```
/criar-componente → /testar-componente → /documentar-componente
```

### 2. Repetição de Instruções

**❌ Problema:** Mesmas regras em múltiplos comandos
```markdown
# comando-a.md
## Regras de Formatação
[50 linhas de regras]

# comando-b.md
## Regras de Formatação
[Mesmas 50 linhas copiadas]
```

**✅ Solução:** Extrair para `common/prompts/`
```markdown
@include common/prompts/formatting-rules.md
```

### 3. Instruções Vagas

**❌ Problema:**
```
Faça o melhor possível com o código
```

**✅ Solução:**
```
Refatore o código para:
- Extrair funções com mais de 20 linhas
- Adicionar tipagem TypeScript
- Documentar funções públicas com JSDoc
```

### 4. Excesso de Condicionais

**❌ Problema:**
```markdown
Se X, faça A.
Se Y e não X, faça B.
Se Z e X mas não Y, faça C.
[...20 condicionais aninhadas...]
```

**✅ Solução:** Criar comandos específicos ou usar tabela de decisão

---

## 📊 Métricas de Qualidade

### Checklist de Comando

- [ ] Objetivo claro em uma linha
- [ ] Inputs bem definidos
- [ ] Processo com etapas numeradas
- [ ] Output esperado documentado
- [ ] Exemplos de uso
- [ ] < 500 linhas
- [ ] Sem repetição de prompts
- [ ] Validações incluídas

### Indicadores de Performance

| Métrica | Meta | Como Medir |
|---------|------|------------|
| Tokens/execução | < 2000 | Observar consumo |
| Tempo resposta | < 30s | Cronometrar |
| Taxa sucesso | > 90% | Registrar falhas |
| Satisfação | > 4/5 | Feedback usuário |

---

## 🔗 Integração com Sistema Onion

### Aplicação Direta

1. **Comandos**: Seguir estrutura e limites definidos
2. **Agentes**: Usar patterns de delegação
3. **Sessions**: Implementar contexto persistente
4. **MCPs**: Integrar como "Integrações Opcionais"

### Template Recomendado para Onion

```markdown
# Nome do Comando

[Descrição breve]

## 🎯 Objetivo
[O que faz]

## 📥 Entrada
[Parâmetros do usuário]

## 🔄 Processo
1. Etapa 1
2. Etapa 2
3. ...

## 📤 Saída
[O que retorna]

## 🔌 Integrações Opcionais
| Integração (via adapter) | Uso |
|-----|-----|
| Task Manager (`TASK_MANAGER_PROVIDER`) | Gestão de tasks |
| Forge | PRs / CI |

## 💡 Exemplos
[Casos de uso]
```

---

## 📚 Recursos Adicionais

- [Claude Code Documentation](https://code.claude.com/docs/en/overview)
- [Claude Code CHANGELOG](https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md)
- [Hooks reference](https://code.claude.com/docs/en/hooks)
- [Dynamic Workflows](https://code.claude.com/docs/en/workflows)
- [Agent view — observabilidade de sessões](https://code.claude.com/docs/en/agent-view)
- [How we built our multi-agent research system — Anthropic](https://www.anthropic.com/research/multi-agent-research-system)

---

**Próxima Atualização Planejada**: Dezembro 2026
**Responsável**: Sistema Onion

