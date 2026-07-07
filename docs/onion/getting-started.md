# 🚀 Guia de Início Rápido

> **Versão**: 3.0.1 | **Última atualização**: 2026-06-14

Bem-vindo ao sistema Onion v3.0! Este guia vai te ajudar a começar rapidamente com os comandos `.claude/` e integração com gerenciadores de tarefas através do **Task Manager Abstraction**.

## 📊 Visão Geral v3.0

| Componente | Quantidade | Descrição |
|------------|------------|-----------|
| Comandos | 84 | Organizados em 9 categorias |
| Agentes | 49 | 9 categorias especializadas |
| Skills | 5 | Orquestração e validação |
| Knowledge Bases | 35 | Documentação estruturada |

## 📋 Checklist de Setup

### **✅ Pré-requisitos**

#### Software necessário

| Ferramenta | Versão mínima | Verificar |
|-----------|---------------|-----------|
| **Claude Code** | v0.43+ | `claude --version` |
| **Node.js** | v22.14.0+ | `node --version` |
| **Git** | v2.30+ | `git --version` |

```bash
# Verificar todas as dependências de uma vez
node --version   # v22.x.x
git --version    # git version 2.30.x ou superior
```

#### Checklist de pré-requisitos
- [ ] **Node.js v22.14.0+** instalado
- [ ] Claude Code instalado e configurado
- [ ] Git inicializado no projeto
- [ ] Pasta `.claude/` presente no projeto

### **📁 Estrutura de Diretórios**

Após instalar o Sistema Onion no projeto, você deve ver a seguinte estrutura:

```
seu-projeto/
├── .claude/
│   ├── commands/           # 95 comandos em 10 categorias
│   ├── agents/             # 51 agentes especializados
│   ├── skills/             # 5 skills de orquestração
│   ├── sessions/           # Sessões de desenvolvimento
│   └── utils/              # Task Manager + Forge adapters
├── docs/
│   ├── onion/              # Documentação do framework
│   ├── meta-specs/         # Constituição do sistema (L0)
│   └── knowledge-base/     # 63 Knowledge Bases estruturadas
├── .env                    # Variáveis de ambiente (NÃO commitar)
├── .env.example            # Template de variáveis
├── .claudeignore           # Otimização do context window
└── CLAUDE.md               # Regras do projeto para Claude Code
```

> **Dica:** Se `.claudeignore` não existir, crie-o para melhorar a performance do Claude Code:
> ```
> node_modules/
> .pnpm-store/
> dist/
> build/
> .next/
> .nuxt/
> *.log
> logs/
> .DS_Store
> .vscode/
> .idea/
> *.tmp
> *.temp
> .cache/
> *.mp4
> *.zip
> *.tar.gz
> ```

---

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

#### Script de validação automática

```bash
#!/bin/bash
# validate-onion.sh

echo "Validando Sistema Onion..."

# 1. Estrutura
if [ -d ".claude/commands" ] && [ -d ".claude/agents" ]; then
  echo "OK: Estrutura de diretórios"
else
  echo "ERRO: Estrutura de diretórios incompleta"
  exit 1
fi

# 2. Contar comandos e agentes
COMMANDS=$(find .claude/commands -name "*.md" | wc -l)
AGENTS=$(find .claude/agents -name "*.md" | wc -l)
echo "OK: $COMMANDS comandos encontrados"
echo "OK: $AGENTS agentes encontrados"

# 3. Git
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "OK: Git inicializado"
else
  echo "ERRO: Git não inicializado"
  exit 1
fi

# 4. Node.js
if command -v node > /dev/null 2>&1; then
  echo "OK: Node.js $(node --version)"
else
  echo "AVISO: Node.js não encontrado"
fi

# 5. .env
if [ -f ".env" ]; then
  echo "OK: .env presente"
else
  echo "AVISO: .env não encontrado — execute /meta/setup-integration"
fi

echo "Validacao completa!"
```

```bash
chmod +x validate-onion.sh
./validate-onion.sh
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

## 📐 Padrões de Nomenclatura

O Sistema Onion usa **kebab-case** (`feature-slug`) para todos os identificadores: branches, sessões e referências a features.

### Formato `feature-slug`

```
<feature-slug>  →  minúsculas, palavras separadas por hífen, sem espaços
```

**Correto:**
```bash
user-authentication
payment-integration
api-v2-migration
fix-payment-timeout
```

**Incorreto:**
```bash
user_authentication    # snake_case
userAuthentication     # camelCase
USER-AUTH              # maiúsculas
user auth              # espaços
```

### Conversão automática

O sistema converte o nome da task para `feature-slug` automaticamente:

| Input (nome da task) | Output (feature-slug) |
|---------------------|----------------------|
| "Implementar Autenticação JWT" | `implementar-autenticacao-jwt` |
| "Adicionar Filtros Avançados" | `adicionar-filtros-avancados` |
| "Fix: Bug no Login" | `fix-bug-no-login` |

### Onde cada identificador é usado

| Identificador | Exemplo | Onde usar |
|--------------|---------|-----------|
| `feature-slug` | `user-authentication` | Branch Git, sessão `.claude/sessions/`, argumento de comandos |
| `task-id` | `PROJ-123` (Jira), `86acu8pdk` (ClickUp) | API calls, `context.md`, referências diretas a tasks |

---

## 🎯 Seus Primeiros 5 Minutos

### **1. Criar Sua Primeira Task (1 min)**
```bash
/product/task "Implementar página de sobre da empresa"
```

**Resultado esperado:**
```
Task criada no gerenciador configurado
Branch sugerida: feature/implementar-pagina-sobre
Sessão: .claude/sessions/implementar-pagina-sobre/
ID no Task Manager: ABOUT-123 (ou equivalente do provedor)
```

### **2. Iniciar Desenvolvimento (1 min)**
```bash
/engineer/start
```

**Input quando solicitado**: `ABOUT-123` (ou o ID gerado)

**O que acontece:**
1. Análise da task no Task Manager
2. Questões de clarificação (se necessário)
3. Geração de arquitetura e plano
4. Criação da sessão em `.claude/sessions/`
5. Task Manager atualizado para `in_progress`

### **3. Desenvolver Funcionalidade (2 min)**
```bash
/engineer/work .claude/sessions/about-page/
```

**Ciclo de desenvolvimento:**
1. Lê plano da sessão
2. Implementa fase atual
3. Pede validação
4. Atualiza Task Manager
5. Próxima fase

### **4. Criar Pull Request (1 min)**
```bash
/engineer/pr
```

**Resultado**: PR criado, Task Manager atualizado com status `in_review`

### **5. Finalizar após Merge**
```bash
/git/sync
```

**Resultado:**
- Branches sincronizadas com `main`/`develop`
- Sessão arquivada
- Task Manager atualizado para `done`

### **Parabéns!**
Você completou seu primeiro ciclo completo de desenvolvimento com o Sistema Onion!

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
@nodejs-specialist "implementar API de usuários"   # Node.js backend
@react-developer "criar dashboard interativo"      # React frontend
```

### **🧪 Para Testes**
```bash
@test-engineer "adicionar testes para função X"    # Testes unitários
@test-agent "estratégia de testes para módulo Y"   # Plano de testes
```

### **🔍 Para Pesquisa e Review**
```bash
@research-agent "melhores práticas OAuth2 2025"    # Pesquisa tecnológica
@code-reviewer "revisar qualidade do código Z"     # Code review
```

### **🗂️ Para Gerenciamento de Tasks**
```bash
@jira-specialist "criar épico de autenticação"     # Operações Jira (JQL, ADF, bulk)
@clickup-specialist "mover tasks para In Progress" # Operações ClickUp
@task-specialist "decompor feature em subtasks"    # Decomposição agnóstica
```

> **Referência completa**: [agents-reference.md](agents-reference.md) — 51 agentes em 9 categorias

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

**Sintomas:** Comandos não são reconhecidos ou retornam "Command not found"

```bash
# Verificar se está na pasta correta (deve ter .claude/ na raiz)
pwd
ls .claude/

# Listar comandos disponíveis
/meta/all-tools

# Se o problema persistir, recarregar o Claude Code
# Cmd/Ctrl + Shift + P → "Reload Window"
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

Se as variáveis estiverem corretas mas a conexão falhar, reexecute `/meta/setup-integration` para reconfigurar.

### **❌ Problema: Task não encontrada**

```
# Verificar formato do ID conforme o provedor
Jira:    AUTH-123, BUG-456, PROJ-789  (PROJETO-NÚMERO)
ClickUp: 86acu8pdk                    (alfanumérico)
Asana:   1234567890123456             (numérico longo)
Linear:  ABC-123                      (TEAM-NÚMERO)
```

### **❌ Problema: PR falha**
```bash
# Executar validações antes
/engineer/pre-pr

# Se testes falharem, corrigir primeiro
npm test  # ou o comando de testes do seu projeto
```

### **❌ Problema: GitFlow não inicializado**

**Sintomas:** Erro ao criar feature branches, branch `develop` não existe

```bash
# Inicializar GitFlow via comando Onion
/git/init

# Ou manualmente:
git flow init -d  # -d para defaults

# Verificar branches criadas:
git branch -a
# Deve mostrar: * main, develop
```

### **❌ Problema: Sessão não criada / engineer/work falha**

**Sintomas:** Diretório `.claude/sessions/` vazio, erro ao retomar trabalho

```bash
# Executar /engineer/start para criar a sessão
/engineer/start <feature-slug>

# Ou criar manualmente e reexecutar:
mkdir -p .claude/sessions/<feature-slug>
/engineer/start <feature-slug>
```

### **❌ Problema: Performance lenta do Claude Code**

**Sintomas:** Indexação demorada, respostas lentas

```bash
# 1. Verificar se .claudeignore existe e inclui node_modules/, dist/, etc.
cat .claudeignore

# 2. Limpar cache
# Cmd/Ctrl + Shift + P → "Clear Cache"

# 3. Reduzir context window
# Settings → Context → Reduce size
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
2. **Referência de Ferramentas** - rode `/meta:all-tools` para listar (sob demanda) as ferramentas disponíveis no contexto atual
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
5. **Adicionar comandos customizados**: `/meta/create-command`
6. **Criar agentes especializados**: `/meta/create-agent`
7. **Ajustar regras do projeto**: editar `CLAUDE.md`

### **🔄 Integrar com CI/CD**
- Configurar GitHub Actions / GitLab CI para testes automáticos
- Deploy automático após merge
- Notificações automáticas no Task Manager

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
