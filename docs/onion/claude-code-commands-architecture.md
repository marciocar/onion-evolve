# 🎮 Claude Code Commands Architecture - Sistema Onion

Este documento explica como funcionam os comandos do Sistema Onion e a diferença crítica entre **Claude Code Commands** e comandos de terminal.

## ⚡ **CONCEITO FUNDAMENTAL: Claude Code Commands**

### 🎯 **O que são Claude Code Commands**
Claude Code Commands são comandos personalizados executados diretamente no **chat da Claude Code**, conforme a [documentação oficial da Claude Code](https://docs.claude.com/en/docs/claude-code/slash-commands).

### ✅ **Como Usar (CORRETO)**
```markdown
# No chat da Claude Code:
/git/init                        # Inicializar Git Flow
/git:flow feature start "login"  # Criar feature branch (dispatcher GitFlow)
/engineer/work "implement API"   # Iniciar desenvolvimento
/product/task "add dashboard"    # Criar task no ClickUp
```

### ❌ **Como NÃO Usar (INCORRETO)**
```bash
# ❌ NO TERMINAL - NÃO FUNCIONA:
$ /git/init                    # Comando não encontrado
$ ./git/flow                   # Arquivo não executável
$ bash /git/init               # Não é script bash direto
```

---

## 🏗️ **Arquitetura do Sistema**

### 📁 **Estrutura de Arquivos**
```
.claude/commands/
├── git/
│   ├── init.md               # Define /git/init command
│   ├── help.md               # Define /git/help command
│   ├── sync.md               # Define /git/sync command
│   └── flow.md               # Dispatcher: /git:flow <feature|release|hotfix> <start|publish|finish>
├── engineer/
│   ├── start.md              # Define /engineer/start command
│   └── work.md               # Define /engineer/work command
└── product/
    ├── task.md               # Define /product/task command
    └── spec.md               # Define /product/spec command
```

### 🔄 **Fluxo de Execução**

| Passo | Camada | Tecnologia | Função |
|-------|--------|------------|--------|
| 1 | **Interface** | Claude Code Chat | Usuário digita `/git/init` |
| 2 | **Detecção** | Claude Code AI | Reconhece comando personalizado |
| 3 | **Carregamento** | File System | Lê `.claude/commands/git/init.md` |
| 4 | **Interpretação** | Claude Code AI | Analisa workflow definido |
| 5 | **Execução** | Scripts | Executa bash/python dentro do workflow |
| 6 | **UX** | Modern CLI | `.claude/utils/modern-cli-ux.sh` |
| 7 | **Feedback** | Claude Code Chat | Resposta rica e educativa |

---

## 🎯 **Exemplo Detalhado: `/git/init`**

### 📝 **1. Usuário Executa Comando**
```markdown
# No chat da Claude Code:
User: /git/init
```

### 📄 **2. Claude Code Carrega Definição**
```markdown
# Arquivo: .claude/commands/git/init.md
# Define workflow completo de inicialização Git Flow
```

### 🧠 **3. Claude Code AI Interpreta Workflow**
```bash
# Bash scripts embutidos no markdown executam:
# - Detecção master/main
# - Criação develop branch  
# - Configuração Git Flow
# - Validações de segurança
```

### 💬 **4. Resposta Rica no Chat**
```markdown
🔧 GIT FLOW - Modern Initialization Wizard
━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 REPOSITORY ANALYSIS:
   ▶ Primary branch: ✅ main detected
   ▶ Git Flow status: ⚠️ Not initialized
   
❓ Initialize Git Flow in this repository? [Y/n]
```

---

## 🎨 **Vantagens dos Claude Code Commands**

### 🤖 **AI-Powered Intelligence**
-  **Context Awareness**: Claude Code entende arquivos abertos, histórico, projeto
-  **Adaptive Execution**: Workflows se adaptam ao contexto atual
-  **Error Recovery**: Sugestões inteligentes para problemas
-  **Educational Feedback**: Explica o que está fazendo

### 🎯 **Developer Experience**
-  **Natural Interface**: Chat natural, sem sintaxe complexa
-  **Rich Responses**: Feedback visual rico com cores e formatação
-  **Context Preservation**: Mantém estado entre comandos
-  **Universal Access**: Funciona em qualquer pasta, qualquer projeto

### 🔒 **Enterprise Features**
-  **Safety First**: Confirmações para operações críticas
-  **Team Integration**: ClickUp, sessions, project management
-  **Audit Trail**: Histórico completo no chat da Claude Code
-  **Knowledge Sharing**: Comandos compartilháveis entre equipe

---

## 🛠️ **Para Desenvolvedores do Sistema**

### 📝 **Criando Novos Comandos**
```markdown
# 1. Criar arquivo markdown:
.claude/commands/category/command.md

# 2. Definir cabeçalho com metadados
# 3. Escrever workflow em bash/python
# 4. Usar funções UX: cli_header, cli_success_box, etc.
# 5. Testar via chat: /category/command
```

### 🎨 **Padrões UX**
```bash
# Usar funções da biblioteca UX:
source "$HOME/.claude/utils/modern-cli-ux.sh"

cli_header "TITLE" "color"          # Headers consistentes
cli_success_box "TITLE" "message"   # Success feedback  
cli_error_box "TITLE" "message"     # Error handling
cli_progress_start "message"        # Progress indicators
```

### 🔗 **Integrações**
```bash
# ClickUp MCP
clickup_get_task_id_from_session    # Detectar task ativa
clickup_add_comment $TASK_ID        # Adicionar comentário
clickup_update_task $TASK_ID        # Atualizar status

# Session Management  
session_create $NAME                # Criar sessão desenvolvimento
session_update $NAME                # Atualizar contexto
```

---

## 📚 **Recursos Adicionais**

### 🔗 **Documentação Oficial**
- [Claude Code Commands Documentation](https://docs.claude.com/en/docs/claude-code/slash-commands)
- [Sistema Onion Commands Guide](commands-guide.md)
- [Engineering Flows](engineering-flows.md)

### 🎯 **Exemplos Práticos**
- [Practical Examples](practical-examples.md)
- [ClickUp Integration](clickup-integration.md)
- [Tools Reference](tools-reference.md)

### 🚀 **Getting Started**
- [Configuração Inicial](getting-started.md)
- [Primeiro Uso](getting-started.md#primeiro-uso)
- [Troubleshooting](getting-started.md#troubleshooting)

---

## ⚠️ **Avisos Importantes**

### 🔴 **NÃO Confundir Com:**
- ❌ **Bash scripts diretos** (não são executáveis de terminal)
- ❌ **NPM scripts** (não estão no package.json)  
- ❌ **Make targets** (não usam Makefile)
- ❌ **CLI tools globais** (não são instalados via npm/pip)

### ✅ **São Claude Code Commands Porque:**
-  **Executados no chat** da Claude Code
-  **Definidos em markdown** na pasta `.claude/commands/`
-  **Interpretados pela Claude Code AI** com context awareness
-  **Integrados ao ambiente** de desenvolvimento

---

**🎯 Lembre-se sempre: Sistema Onion = Claude Code Commands executados no chat da Claude Code!** 🚀
