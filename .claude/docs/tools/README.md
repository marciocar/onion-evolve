# 🛠️ Documentação de Ferramentas - Sistema Onion

> Documentação completa de todas as ferramentas disponíveis no contexto do Claude Code organizadas por categoria.

## 📑 Índice Geral

### 🔌 [Ferramentas MCP](./mcps.md)
Integrações com Model Context Protocol - ClickUp, Postman, Nx
- **50+ funções** para gestão de projeto e workflow
- Integração completa com ClickUp (tasks, time tracking, docs)
- Postman API management (collections, mocks, monitors)
- Nx monorepo tools (generators, CI/CD)

### 🤖 [Agentes Especializados](./agents.md)
14+ agentes de IA especializados para tarefas específicas
- Gestão de Produto (@product-agent, @clickup-specialist)
- Desenvolvimento (@react-developer, @python-developer)
- Qualidade (@code-reviewer, @test-engineer)
- Arquitetura (@metaspec-gate-keeper)

### 📋 [Comandos .claude/](./commands.md)
46 comandos organizados em workflows automatizados
- **Product Workflow** (10 comandos) - Feature planning, specs
- **Engineer Workflow** (11 comandos) - Development, PR, versioning
- **Git Workflow** (11 comandos) - Feature/Release/Hotfix flows
- **Documentation** (9 comandos) - Docs generation & validation

### ⚙️ [Regras e Configurações](./rules.md)
Regras do workspace, padrões e convenções
- Convenções de linguagem (EN code, PT-BR docs)
- Estrutura de projeto
- Formatação ClickUp (Markdown vs Unicode)
- Padrões de código e testes

### 🛠️ [Ferramentas Core do Claude Code](./claude-code.md)
Ferramentas fundamentais do Claude Code
- Operações de codebase (search, read, edit)
- File operations (create, update, delete)
- Terminal commands
- Grep/search avançado
- Linting & validation

---

## 🎯 Guia Rápido de Uso

### Por Tipo de Tarefa

| Preciso... | Use... |
|-----------|--------|
| 🎯 Planejar feature | `@product-agent` + `/product/feature` |
| ✅ Criar task ClickUp | `mcp_ClickUp_clickup_create_task` |
| 💻 Desenvolver código | `@react-developer` ou `@python-developer` |
| 🔍 Buscar no código | `codebase_search` (semântico) ou `grep` (exato) |
| 📝 Editar arquivo | `search_replace` |
| 🧪 Criar testes | `@test-engineer` |
| 👀 Review código | `@code-reviewer` + `/git/code-review` |
| 🚀 Fazer deploy | `@deployment-specialist` |
| 📚 Gerar docs | `/docs/build-tech-docs` |
| 🔧 Problema técnico ClickUp | `@clickup-specialist` |
| ⚙️ Problema Claude Code | `@claude-code-specialist` |

### Por Fase do Projeto

#### 1️⃣ Discovery & Planning
```bash
@product-agent                 # Consultar especialista
/product/feature              # Iniciar planejamento
mcp_ClickUp_clickup_create_task  # Criar task
```

#### 2️⃣ Development
```bash
/engineer/start               # Setup sessão
@react-developer              # Consultar especialista
codebase_search()             # Explorar código
search_replace()              # Editar código
```

#### 3️⃣ Testing & Review
```bash
@test-engineer                # Criar testes
/engineer/pre-pr              # Validar
@code-reviewer                # Review
```

#### 4️⃣ Integration & Deploy
```bash
/engineer/pr                  # Criar PR
/git:flow feature finish           # Merge
@deployment-specialist        # Deploy
```

---

## 📊 Estatísticas

### Por Categoria

| Categoria | Quantidade | Uso Principal |
|-----------|------------|---------------|
| **MCP - ClickUp** | 50+ funções | Gestão de tasks, time tracking |
| **MCP - Postman** | 30+ funções | API management, testing |
| **MCP - Nx** | 10+ funções | Monorepo, generators, CI/CD |
| **Agentes** | 14+ agentes | Especialização em tarefas |
| **Comandos** | 46 comandos | Workflows automatizados |
| **Core Tools** | 15+ ferramentas | Operações fundamentais IDE |

### Mais Utilizados

#### Ferramentas MCP
1. `mcp_ClickUp_clickup_create_task`
2. `mcp_ClickUp_clickup_search`
3. `mcp_ClickUp_clickup_update_task`
4. `mcp_ClickUp_clickup_create_task_comment`
5. `mcp_ClickUp_clickup_get_task`

#### Agentes
1. `@product-agent`
2. `@react-developer`
3. `@code-reviewer`
4. `@clickup-specialist`
5. `@test-engineer`

#### Comandos
1. `/engineer/work`
2. `/product/feature`
3. `/git:flow feature start`
4. `/engineer/pr`
5. `/docs/build-tech-docs`

#### Core Tools
1. `codebase_search`
2. `read_file`
3. `search_replace`
4. `grep`
5. `run_terminal_cmd`

---

## 🎓 Melhores Práticas

### ✅ Fazer

1. **Use agentes especializados** para tarefas específicas
   ```markdown
   @product-agent planeje feature de autenticação
   @react-developer implemente componente
   @test-engineer crie os testes
   ```

2. **Combine ferramentas** para workflows completos
   ```typescript
   // 1. Buscar contexto
   codebase_search({query: "Como funciona autenticação?"})
   
   // 2. Criar task
   mcp_ClickUp_clickup_create_task({name: "Implementar JWT"})
   
   // 3. Desenvolver
   search_replace({file_path: "auth/service.ts", ...})
   
   // 4. Documentar
   mcp_ClickUp_clickup_create_task_comment({...})
   ```

3. **Siga workflows estabelecidos** para consistência
   ```bash
   /product/feature → /engineer/start → /engineer/work → /engineer/pr
   ```

4. **Paralelizar operações** independentes
   ```typescript
   Promise.all([
     read_file({target_file: "file1.ts"}),
     read_file({target_file: "file2.ts"}),
     read_file({target_file: "file3.ts"})
   ])
   ```

### ❌ Evitar

1. ❌ Usar ferramentas genéricas quando há especializadas
   - Prefira `@clickup-specialist` a perguntas gerais sobre ClickUp
   - Use `codebase_search` em vez de grep para busca semântica

2. ❌ Pular etapas de validação
   - Sempre use `/engineer/pre-pr` antes de PR
   - Valide com `@metaspec-gate-keeper` mudanças arquiteturais

3. ❌ Criar arquivos temporários sem cleanup
   - Delete scripts helper após uso
   - Mantenha workspace limpo

4. ❌ Misturar idiomas
   - Código sempre em inglês
   - Comentários e commits em português

---

## 🔗 Links Rápidos

### Documentação Detalhada
- [🔌 MCP Tools (ClickUp, Postman, Nx)](./mcps.md)
- [🤖 Agentes Especializados](./agents.md)
- [📋 Comandos .claude/](./commands.md)
- [⚙️ Regras e Configurações](./rules.md)
- [🛠️ Ferramentas Core](./claude-code.md)

### Recursos Externos
- [ClickUp API Docs](https://clickup.com/api)
- [Postman API Docs](https://www.postman.com/postman/workspace/postman-public-workspace/documentation/12959542-c8142d51-e97c-46b6-bd77-52bb66712c9a)
- [Nx Documentation](https://nx.dev)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code/overview)

---

## 🆘 Precisa de Ajuda?

### Por Tipo de Problema

| Problema | Solução |
|----------|---------|
| 🔌 Erro ClickUp MCP | `@clickup-specialist` |
| 🖥️ Problema Claude Code | `@claude-code-specialist` |
| 💻 Dúvida técnica React | `@react-developer` |
| 🐍 Dúvida técnica Python | `@python-developer` |
| 🏗️ Validação arquitetura | `@metaspec-gate-keeper` |
| 📝 Ajuda com documentação | `/docs/help` |
| 🔀 Ajuda com Git | `/git/help` |
| 🔍 Pesquisa geral | `@research-agent` |

### Comandos de Ajuda
```bash
/docs/help        # Comandos de documentação
/git/help         # Comandos Git
/product/README   # Workflow de produto
/engineer/README  # Workflow de engenharia
```

---

## 🚀 Começando

### Setup Inicial
1. ✅ Verifique regras do workspace em [rules.md](./rules.md)
2. ✅ Explore comandos disponíveis em [commands.md](./commands.md)
3. ✅ Conheça os agentes em [agents.md](./agents.md)
4. ✅ Configure integrações MCP em [mcps.md](./mcps.md)

### Primeira Feature
```bash
# 1. Planeje
/product/feature

# 2. Configure ambiente
/engineer/start

# 3. Desenvolva
/engineer/work

# 4. Finalize
/engineer/pr
/git:flow feature finish
```

### Warm-up Rápido
```bash
/warm-up                    # Contexto geral
/product/warm-up            # Contexto de produto
/engineer/warm-up           # Contexto técnico
```

---

## 📈 Roadmap

### Próximas Adições
- [ ] Workflows de deployment
- [ ] Mais templates de documentação
- [ ] Automações de CI/CD
- [ ] Integrações adicionais MCP

### Melhorias Planejadas
- [ ] Otimização de performance
- [ ] Mais exemplos práticos
- [ ] Troubleshooting guides
- [ ] Video tutorials

---

## 🎉 Contribuindo

Esta documentação é viva e evolui com o projeto. Para sugestões:
1. Use `@product-agent` para planejar melhorias
2. Documente mudanças em `/docs/`
3. Mantenha sincronizado com código

---

## 📝 Notas da Versão

### v1.0.1 - Atualização (2025-01-27)
- ✅ Adicionadas ferramentas MCP gerais (list_mcp_resources, fetch_mcp_resource)
- ✅ Validação completa de todas as ferramentas disponíveis
- ✅ Documentação sincronizada com contexto atual

### v1.0.0 - Setup Inicial (2025-01-27)
- ✅ 50+ ferramentas MCP documentadas
- ✅ 14+ agentes especializados catalogados
- ✅ 46 comandos organizados por categoria
- ✅ Guias de uso e melhores práticas
- ✅ Índice central de recursos

---

<div align="center">

**Sistema Onion** 🧅  
*Eficiência • Qualidade • Automação Inteligente*

[Início](#-documentação-de-ferramentas---sistema-onion) • [MCP](./mcps.md) • [Agentes](./agents.md) • [Comandos](./commands.md) • [Regras](./rules.md) • [Core](./claude-code.md)

</div>

