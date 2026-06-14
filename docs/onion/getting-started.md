# 🚀 Guia de Início Rápido

> **Versão**: 3.0.1 | **Última atualização**: 2026-06-14

Bem-vindo ao sistema Onion v3.0! Este guia vai te ajudar a começar rapidamente com os comandos `.claude/` e integração com gerenciadores de tarefas através do **Task Manager Abstraction**.

## 📊 Visão Geral v3.0

| Componente | Quantidade | Descrição |
|------------|------------|-----------|
| Comandos | 77 | Organizados em 9 categorias |
| Agentes | 49 | 9 categorias especializadas |
| Skills | 5 | Orquestração e validação |
| Knowledge Bases | 34 | Documentação estruturada |

## 📋 Checklist de Setup

### **✅ Pré-requisitos**
- [ ] **Node.js v22.14.0+** instalado
- [ ] Claude Code instalado e configurado
- [ ] Git inicializado no projeto
- [ ] Pasta `.claude/` presente no projeto

### **✅ Configuração de Integrações**

#### **⚙️ Método Recomendado: Comando `/meta/setup-integration`**

O Sistema Onion oferece um comando interativo para configurar todas as integrações de forma segura:

```bash
# Configuração interativa (recomendado)
/meta/setup-integration

# Ou especificar integração diretamente
/meta/setup-integration task-manager  # Configurar gerenciador de tarefas
/meta/setup-integration jira          # Configurar Jira especificamente
/meta/setup-integration clickup       # Configurar ClickUp especificamente
/meta/setup-integration asana         # Configurar Asana especificamente
/meta/setup-integration linear        # Configurar Linear especificamente
/meta/setup-integration gamma         # Configurar Gamma.App
```

**O que o comando faz:**
- ✅ **Guia passo a passo** na configuração de cada integração
- ✅ **Cria/atualiza `.env`** automaticamente
- ✅ **Valida segurança** (verifica `.gitignore`, protege credenciais)
- ✅ **Testa conectividade** quando aplicável
- ✅ **Fornece instruções** específicas para cada provedor

**Integrações suportadas:**
- **Task Managers**: Jira, ClickUp, Asana, Linear (via Task Manager Abstraction)
- **Gamma.App**: API para apresentações
- **PostgreSQL**: Banco de dados

#### **📝 Método Alternativo: Configuração Manual**

Se preferir configurar manualmente, edite o arquivo `.env`:

A primeira variável define **qual provedor está ativo**. Configure apenas o bloco
do provedor escolhido — os demais ficam comentados.

```bash
# ═══════════════════════════════════════
# GERENCIADOR DE TAREFAS (escolha UM provedor)
# ═══════════════════════════════════════
TASK_MANAGER_PROVIDER=jira  # jira | clickup | asana | linear | none

# ─── Opção: Jira ───
JIRA_HOST=https://your-domain.atlassian.net
JIRA_EMAIL=you@example.com
JIRA_API_TOKEN=xxxxx
# JIRA_PROJECT_KEY=PROJ
# JIRA_AUTH_TYPE=basic   # basic | bearer
# JIRA_API_VERSION=3     # 3 (Cloud) | 2 (Server/DC)

# ─── Opção: ClickUp ───
# CLICKUP_API_TOKEN=pk_xxxxx
# CLICKUP_WORKSPACE_ID=your_workspace_id
# CLICKUP_DEFAULT_LIST_ID=your_list_id

# ─── Opção: Asana ───
# ASANA_ACCESS_TOKEN=1/xxxxx
# ASANA_WORKSPACE_ID=1234567890
# ASANA_DEFAULT_PROJECT_ID=1234567890

# ─── Opção: Linear ───
# LINEAR_API_KEY=lin_api_xxxxx
# LINEAR_TEAM_ID=your_team_id

# ═══════════════════════════════════════
# OUTRAS INTEGRAÇÕES
# ═══════════════════════════════════════
GITHUB_TOKEN=ghp_xxxxx
GAMMA_API_KEY=gm_xxxxx
```

> **💡 Para trocar de provedor:** altere `TASK_MANAGER_PROVIDER`, descomente o
> bloco correspondente e comente o anterior. Nenhum comando ou workflow precisa
> mudar — a abstração resolve o roteamento.

> **💡 Dica:** Use `/meta/setup-integration` para garantir que todas as variáveis estão corretas e o `.env` está protegido no `.gitignore`.

> **Referência**: Veja `.env.example` para todas as variáveis disponíveis.

### **🔄 Task Manager Abstraction - Conceito Central**

O Sistema Onion v3.0 usa uma **camada de abstração** que permite trabalhar com múltiplos gerenciadores de tarefas sem modificar comandos ou workflows. Você escolhe o provedor e todos os comandos funcionam automaticamente.

**Como funciona:**
- ✅ **Interface unificada**: Comandos como `/product/task` funcionam com qualquer provedor
- ✅ **Troca fácil**: Mude `TASK_MANAGER_PROVIDER` no `.env` e tudo continua funcionando
- ✅ **Fallback gracioso**: Sistema funciona mesmo sem gerenciador configurado (modo offline)

**Provedores suportados:**

| Provedor | Configuração | Agente / roteamento | Notas |
|----------|--------------|---------------------|-------|
| **Jira** | `TASK_MANAGER_PROVIDER=jira` | `@jira-specialist` | REST v3/v2, JQL, ADF, transitions, bulk |
| **ClickUp** | `TASK_MANAGER_PROVIDER=clickup` | `@clickup-specialist` | API-first (transporte MCP opcional), formatação Unicode |
| **Asana** | `TASK_MANAGER_PROVIDER=asana` | `@task-specialist` (agnóstico) | Notes HTML / plain text |
| **Linear** | `TASK_MANAGER_PROVIDER=linear` | `@task-specialist` (agnóstico) | Markdown nativo |
| **None** | `TASK_MANAGER_PROVIDER=none` | `@task-specialist` (offline) | Modo local sem sincronização |

**Vantagens da abstração:**
- 🎯 **Flexibilidade**: Escolha o gerenciador que sua equipe já usa
- 🔄 **Portabilidade**: Troque de provedor sem refatorar código
- 🛡️ **Resiliência**: Funciona mesmo se o gerenciador estiver offline
- 🚀 **Consistência**: Mesmos comandos, mesma experiência, qualquer provedor

> **📚 Documentação completa**: `docs/knowledge-base/concepts/task-manager-abstraction.md`

### **✅ Validação**

Após configurar o Task Manager, valide a configuração:

```bash
# Verificar comandos disponíveis
/meta/all-tools  # Deve mostrar comandos disponíveis

# Testar integração de Task Manager (se configurado)
/product/task "Task de teste do sistema"
# → Deve criar task no provedor ativo (Jira, ClickUp, Asana ou Linear)

# Validar conectividade (depende do provedor configurado)
/warm-up  # Valida conectividade do Task Manager configurado
```

**Se algo não funcionar:**
- Execute `/meta/setup-integration` novamente para revisar configuração
- Verifique se `.env` está no `.gitignore` (o comando faz isso automaticamente)
- Consulte o roteamento conforme o provedor ativo:
  - `@jira-specialist` para problemas com Jira (verifique `JIRA_HOST`, `JIRA_EMAIL`, `JIRA_API_TOKEN`)
  - `@clickup-specialist` para problemas com ClickUp (verifique `CLICKUP_API_TOKEN`)
  - Para Asana, verifique a variável `ASANA_ACCESS_TOKEN` no `.env` (roteamento via `@task-specialist`)
  - Para Linear, verifique a variável `LINEAR_API_KEY` no `.env` (roteamento via `@task-specialist`)
  - Para modo offline, certifique-se que `TASK_MANAGER_PROVIDER=none`

---

## 🎯 Seus Primeiros 5 Minutos

### **1. Criar Sua Primeira Task (1 min)**
```bash
/product/task "Implementar página de sobre da empresa"
```

**Resultado esperado**: Task criada no gerenciador configurado com ID (ex: ABOUT-123)

### **2. Iniciar Desenvolvimento (1 min)**
```bash
/engineer/start
```

**Input quando solicitado**: `ABOUT-123`

**Resultado**: Ambiente configurado, sessão criada, plano gerado

### **3. Desenvolver Funcionalidade (2 min)**
```bash
/engineer/work .claude/sessions/about-page/
```

**Resultado**: Implementação guiada passo-a-passo

### **4. Criar Pull Request (1 min)**
```bash
/engineer/pr
```

**Resultado**: PR criado, Task Manager atualizado com status "in_review"

### **✨ Parabéns!** 
Você completou seu primeiro ciclo completo de desenvolvimento com integração ao Task Manager! 🎉

---

## 🏃‍♂️ Fluxos Rápidos por Cenário

### **🆕 Nova Funcionalidade**
```bash
/product/task "Nova funcionalidade X"      # → Task criada no Task Manager
/engineer/start                           # → Input: TASK-ID  
/engineer/work .claude/sessions/feature-x/ # → Desenvolvimento
/engineer/pr                              # → PR + Task Manager atualizado
```

### **🐛 Correção de Bug**
```bash
/product/collect "Bug: X não funciona"    # → Bug task criada
/engineer/start                           # → Fix mode ativo
/engineer/work "corrigir bug X"           # → Implementação rápida
/engineer/pr                              # → Hotfix PR
```

### **📚 Documentação**
```bash
/docs/build-tech-docs                     # → Docs técnicos
/docs/build-business-docs                 # → Docs de negócio
/docs/build-index                         # → Índice de projetos
```

### **⚡ Emergência**
```bash
/product/collect "CRÍTICO: Sistema fora do ar" # → Priority 1 automático
/engineer/start                                 # → Hotfix mode
/engineer/work "fix crítico"                    # → Solução rápida
/engineer/pr                                    # → Deploy imediato
```

---

## 🎯 Comandos Essenciais

### **📋 Mais Usados (80% dos casos)**
| Comando | Uso | Frequência |
|---------|-----|------------|
| `/product/task` | Criar nova task | 35% |
| `/engineer/start` | Iniciar desenvolvimento | 25% |
| `/engineer/work` | Desenvolver funcionalidade | 20% |
| `/engineer/pr` | Criar Pull Request | 15% |
| `/all-tools` | Ver comandos disponíveis | 5% |

### **🔧 Para Situações Específicas**
| Comando | Quando Usar |
|---------|-------------|
| `/product/collect` | Reportar bugs ou ideias rápidas |
| `/product/refine` | Melhorar especificação existente |
| `/product/light-arch` | Esboçar arquitetura inicial |
| `/engineer/pre-pr` | Validações antes do PR |
| `/docs/build-*` | Gerar documentação automática |

---

## 🤖 Agentes - Quando Usar

### **🔵 Para Desenvolvimento**
```bash
@python-developer "implementar API de usuários"    # Python backend
@react-developer "criar dashboard interativo"      # React frontend  
```

### **🧪 Para Testes**
```bash
@test-engineer "adicionar testes para função X"    # Testes unitários
@test-planner "estratégia de testes para módulo Y" # Plano de testes
```

### **🔍 Para Pesquisa**
```bash
@research-agent "melhores práticas OAuth2 2024"    # Pesquisa tecnológica
@code-reviewer "revisar qualidade do código Z"     # Code review
```

---

## 📊 Integração com Task Manager - Visão Rápida

O Sistema Onion sincroniza automaticamente com o Task Manager ativo (Jira, ClickUp, Asana ou Linear), atualizando status, comentários e tags conforme você desenvolve.

### **Estados Automáticos**
```mermaid
graph LR
    A[/product/task] --> B[to do]
    B --> C[/engineer/start] --> D[in progress]  
    D --> E[/engineer/pr] --> F[in progress + under-review]
    F --> G[Merge] --> H[done]
```

**Status normalizados** (funcionam em qualquer provedor):
- `backlog` → `todo` → `in_progress` → `in_review` → `done`
- `blocked` e `cancelled` também suportados

### **Tags Automáticas**
- **Por tipo**: `feature`, `bug`, `refactor`, `docs`
- **Por status**: `development`, `under-review`, `blocked`
- **Por prioridade**: `urgent`, `high`, `normal`, `low`

### **Comentários Automáticos**
- 🚀 Desenvolvimento iniciado
- 📊 Progresso por fase
- 🔍 PR criado com detalhes
- ✅ Conclusão com métricas

**Nota:** Todos esses recursos funcionam igualmente com Jira, ClickUp, Asana ou Linear através da abstração. A *forma* de cada recurso adapta-se ao provedor — por exemplo, descrições em ADF no Jira (Cloud), Markdown nativo no ClickUp/Linear e notes HTML no Asana —, mas o comportamento do workflow permanece o mesmo.

---

## 🔧 Troubleshooting Rápido

### **❌ Problema: Comando não encontrado**
```bash
# Verificar se está na pasta correta
pwd  # Deve estar na raiz do projeto com .claude/

# Listar comandos disponíveis
/all-tools
```

### **❌ Problema: Task Manager não conecta**
```bash
# Validar configuração
/warm-up

# Verificar provedor configurado primeiro:
echo $TASK_MANAGER_PROVIDER

# Se falhar, verificar variáveis conforme o provedor ativo:

# Para Jira:
echo $JIRA_HOST; echo $JIRA_EMAIL; echo $JIRA_API_TOKEN

# Para ClickUp:
echo $CLICKUP_API_TOKEN; echo $CLICKUP_WORKSPACE_ID

# Para Asana:
echo $ASANA_ACCESS_TOKEN; echo $ASANA_WORKSPACE_ID

# Para Linear:
echo $LINEAR_API_KEY; echo $LINEAR_TEAM_ID
```

### **❌ Problema: Task não encontrada**
```
# Verificar formato do ID
Correto: AUTH-123, BUG-456, PROJ-789
Incorreto: 123, auth123, AUTH123
```

### **❌ Problema: PR falha**
```bash
# Executar validações antes
/engineer/pre-pr

# Se testes falharem, corrigir primeiro
npm test  # ou comando apropriado do projeto
```

---

## 💡 Dicas Pro

### **🚀 Para Eficiência Máxima**
1. **Use aliases** para comandos frequentes:
   ```bash
   alias pt="/product/task"
   alias es="/engineer/start" 
   alias ew="/engineer/work"
   alias epr="/engineer/pr"
   ```

2. **Prepare templates** para tasks comuns:
   ```bash
   pt "Feature: Nova página X com layout responsivo e formulário de contato"
   pt "Bug: Problema Y em ambiente Z com logs detalhados"
   ```

3. **Monitore métricas** no seu Task Manager:
   - Cycle time por feature
   - Bug rate pós-deploy
   - Review time médio

### **🎯 Para Qualidade**
1. **Sempre execute pre-pr** antes de PR crítico
2. **Use code-reviewer** para mudanças arquiteturais
3. **Documente decisões** importantes com `/docs/build-*`

### **🔄 Para Colaboração**
1. **Tags consistentes** facilitam filtros no Task Manager
2. **Comentários descritivos** em PRs
3. **Sincronização regular** com workspace/projeto configurado

---

## 📚 Próximos Passos

### **📖 Aprofundar Conhecimento**
1. **[Guia de Comandos](commands-guide.md)** - Documentação completa
2. **[Referência de Ferramentas](tools-reference.md)** - Todas as ferramentas disponíveis em TypeScript
3. **[Fluxos de Engenharia](engineering-flows.md)** - Workflows detalhados  
4. **[Task Manager Abstraction](../knowledge-base/concepts/task-manager-abstraction.md)** - Entenda como funciona a abstração
5. **Adapters por provedor** - Detalhes específicos de cada um em `.claude/utils/task-manager/adapters/` (`jira.md`, `clickup.md`, `asana.md`, `linear.md`)

### **🎯 Cenários Avançados**
1. **[Exemplos Práticos](practical-examples.md)** - Casos reais de uso
2. **[Referência de Agentes](agents-reference.md)** - Especialistas disponíveis

### **🔧 Personalização**
1. Configurar webhooks do Task Manager (Jira, ClickUp, Asana ou Linear)
2. Customizar templates de PR
3. Criar dashboards/relatórios específicos no seu gerenciador
4. Ajustar notificações e workflows

---

## 🆘 Suporte e Ajuda

### **📞 Onde Buscar Ajuda**
1. **Comandos**: `/meta/all-tools` lista tudo disponível
2. **Status**: `/warm-up` valida configuração do Task Manager
3. **Documentação**: Arquivos nesta pasta `docs/`
4. **Task Manager**: Interface web do seu gerenciador (Jira, ClickUp, Asana ou Linear) para validar dados

### **🐛 Reportar Problemas**
Se algo não funciona:
1. Execute `/warm-up` e cole o resultado
2. Descreva o comando executado
3. Inclua mensagem de erro completa
4. Mencione ID da task e provedor configurado (Jira, ClickUp, Asana ou Linear)
5. Verifique se `TASK_MANAGER_PROVIDER` está configurado corretamente

### **💬 Comunidade**
- Compartilhe workflows que funcionam
- Suggira melhorias nos comandos
- Documente casos especiais descobertos

---

## 🎉 Você Está Pronto!

Agora você tem tudo para ser produtivo com o sistema Onion:

-  **Setup validado** e funcionando
-  **Primeiros comandos** executados com sucesso  
-  **Fluxos principais** compreendidos
-  **Task Manager configurado** e sincronizando (Jira, ClickUp, Asana, Linear ou modo offline)
-  **Troubleshooting** na ponta da língua

**Comece pequeno, pratique os fluxos básicos, e gradualmente explore funcionalidades mais avançadas!**

---

**Sistema Onion** - Desenvolvimento inteligente com IA 🧅 🚀
