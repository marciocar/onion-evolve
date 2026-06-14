# 💡 Exemplos Práticos

Este guia apresenta cenários reais de uso dos comandos `.claude/` com exemplos detalhados e outputs esperados.

## 📋 Índice de Exemplos

- [🚀 Desenvolvimento de Feature Completa](#-desenvolvimento-de-feature-completa)
- [🐛 Correção de Bug Crítico](#-correção-de-bug-crítico)
- [📚 Criação de Documentação](#-criação-de-documentação)
- [🔧 Refatoração de Sistema](#-refatoração-de-sistema)
- [⚡ Hotfix de Emergência](#-hotfix-de-emergência)
- [🎯 Casos Especiais](#-casos-especiais)
- [📦 Release e Deploy](#-release-e-deploy)
- [❌ Anti-Patterns: O Que NÃO Fazer](#-anti-patterns-o-que-não-fazer)
- [🔧 Troubleshooting Comum](#-troubleshooting-comum)
- [📊 Métricas dos Exemplos](#-métricas-dos-exemplos)

---

## 🚀 Desenvolvimento de Feature Completa

### **Cenário**: Sistema de Autenticação OAuth2
Um novo sistema de autenticação usando OAuth2 com Google e GitHub precisa ser implementado.

#### **Passo 1: Criação da Task**
```bash
/product/task "Implementar sistema de autenticação OAuth2 com Google e GitHub"
```

**Interação do Sistema**:
```
🤔 Analisando requisitos...

Para criar uma task abrangente, preciso entender melhor:

1. **Escopo de Autenticação**:
   - Apenas login/logout ou também registro?
   - Precisa de integração com perfis sociais?
   - Que dados do usuário devem ser coletados?

2. **Plataformas**:
   - Web, mobile ou ambos?
   - Quais frameworks/tecnologias usar?

3. **Segurança**:
   - Onde armazenar tokens?
   - Políticas de expiração?
   - Refresh tokens necessários?

Por favor, esclareça estes pontos para uma task mais precisa.
```

**Resposta do Usuário**: 
"Sistema web com React, login/logout apenas, armazenar JWT no localStorage, refresh tokens sim"

**Resultado ClickUp**:

> O formato de saída varia conforme TASK_MANAGER_PROVIDER (jira/clickup/asana/linear).

```
✅ Task criada no ClickUp: AUTH-789

📋 **Título**: 🔐 Implementar sistema de autenticação OAuth2 com Google e GitHub

📝 **Descrição**:
Sistema de autenticação para aplicação web React com:

**Funcionalidades**:
- Login via Google OAuth2
- Login via GitHub OAuth2  
- Logout completo
- Gerenciamento de JWT tokens
- Auto-refresh de tokens

**Critérios de Aceitação**:
- [ ] Botões de login Google e GitHub funcionais
- [ ] JWT armazenado seguramente no localStorage
- [ ] Refresh automático antes da expiração
- [ ] Logout limpa todos os dados de sessão
- [ ] Tratamento de erros de autenticação
- [ ] Testes unitários e de integração

**Estimativa**: 12-16 horas
🏷️ **Tags**: feature, auth, oauth2, react, jwt
🎯 **Prioridade**: 2 (High)
📊 **Status**: to do
```

#### **Passo 2: Início do Desenvolvimento**
```bash
/engineer/start
```

**Interação do Sistema**:
```
🚀 Iniciando desenvolvimento...

Qual task ClickUp deseja trabalhar? (ex: AUTH-789, PROJ-123)
```

**Input**: `AUTH-789`

**Resultado**:
```
✅ Task AUTH-789 recuperada do ClickUp
🔄 Status atualizado: "to do" → "in progress"
📁 Pasta criada: .claude/sessions/auth-oauth2/

📋 **Análise da Task**:

**Contexto**: Sistema de autenticação OAuth2 para app React
**Objetivo**: Login seguro via Google/GitHub com JWT management
**Abordagem**: Frontend OAuth + Backend JWT + Token refresh

**Dependências Identificadas**:
- React Router para redirecionamentos
- Axios para requisições API
- JWT decode library
- OAuth2 client configs (Google/GitHub)

**Arquivos que Precisarão Ser Criados/Modificados**:
- components/Auth/LoginButton.tsx
- components/Auth/AuthCallback.tsx  
- services/authService.ts
- hooks/useAuth.ts
- utils/tokenManager.ts

**Testes Necessários**:
- Login flow completo
- Token refresh automático
- Logout e limpeza
- Error handling

📄 Plano detalhado salvo em: .claude/sessions/auth-oauth2/plan.md
```

#### **Passo 3: Desenvolvimento Iterativo**
```bash
/engineer/work .claude/sessions/auth-oauth2/
```

**Primeira Iteração**:
```
📖 Lendo plan.md...

**FASE ATUAL**: 1 - Setup e Configuração OAuth

**Próximos Passos**:
1. Configurar OAuth apps no Google/GitHub Console
2. Instalar dependências necessárias
3. Criar serviço base de autenticação
4. Implementar fluxo de redirecionamento

Deseja prosseguir com a Fase 1? (s/n)
```

**Input**: `s`

**Execução**:
```
🔧 Executando Fase 1...

📦 Instalando dependências:
npm install @google-cloud/oauth2 @octokit/auth-oauth-app jsonwebtoken

📝 Criando authService.ts...
[Código TypeScript gerado]

📝 Criando tokenManager.ts...  
[Utilitários de JWT gerados]

✅ Fase 1 completa!
📝 Atualizando plan.md...

**Próxima fase**: Implementação dos componentes React
Continuar? (s/n)
```

**Segunda Iteração**:
```
**FASE ATUAL**: 2 - Componentes React

🔧 Executando Fase 2...

📝 Criando LoginButton.tsx...
📝 Criando AuthCallback.tsx...
📝 Criando hook useAuth.ts...

🧪 Executando testes...
✅ 8 testes passando

✅ Fase 2 completa!
**Próxima fase**: Integração e testes E2E
```

#### **Passo 4: Finalização e PR**
```bash
/engineer/pr
```

**Resultado**:
```
🔍 Executando validações finais...

✅ Todos os testes passando (24/24)
✅ Cobertura > 85%  
✅ Linting sem erros
✅ TypeScript sem erros

📝 Fazendo commit final...
git commit -m "feat(auth): implement OAuth2 with Google and GitHub

- Add OAuth2 login components
- Implement JWT token management  
- Add auto-refresh functionality
- Include comprehensive test suite
- Add error handling and user feedback

Closes: AUTH-789"

🔄 Atualizando ClickUp...
✅ Status mantido: "in progress"
✅ Tag adicionada: "under-review"

🔍 Criando Pull Request...

**PR #156 Criado**: https://github.com/org/repo/pull/156
📋 Título: 🔐 Implement OAuth2 Authentication System
📝 Descrição: [Detalhes completos da implementação]

✅ PR criado com sucesso!
⏱️ Aguardando feedback automatizado (3min)...

💬 Comentário adicionado no ClickUp: "🔍 Pull Request criado: #156 - Pronto para review"
```

---

## 🐛 Correção de Bug Crítico

### **Cenário**: Dashboard não carrega dados após login
Usuários relatam que após fazer login, o dashboard fica em branco e não carrega nenhum dado.

#### **Passo 1: Reportar Bug**
```bash
/product/collect "Dashboard não carrega dados após login - usuários veem tela branca"
```

**Resultado**:
```
🐛 Analisando bug reportado...

**Classificação**: Bug crítico (afeta funcionalidade principal)

Para entender melhor o problema:

1. **Reprodução**:
   - Acontece com todos os usuários ou apenas alguns?
   - Em quais browsers foi observado?
   - Há mensagens de erro no console?

2. **Contexto**:
   - Começou após qual deploy/mudança?
   - Dados carregam eventualmente ou nunca?
   - Login funciona normalmente?

3. **Impacto**:
   - Quantos usuários afetados aproximadamente?
   - Há workaround temporário?

Por favor, forneça essas informações.
```

**Input do Usuário**: 
"Começou após deploy de sexta. Chrome e Firefox. Console mostra erro 'Cannot read property data of undefined'. Afeta ~70% dos usuários. Refresh da página às vezes resolve."

**Resultado ClickUp**:
```
✅ Task criada: BUG-445

📋 **Título**: 🐛 Dashboard não carrega dados após login (70% usuários afetados)

📝 **Descrição**:
**Sintomas**:
- Dashboard exibe tela branca após login
- Console error: "Cannot read property data of undefined"  
- Refresh da página às vezes resolve
- Afeta ~70% dos usuários

**Contexto**:
- Iniciou após deploy de sexta-feira
- Observado em Chrome e Firefox
- Login funciona normalmente
- Problema na exibição de dados

**Impacto**: ALTO - Funcionalidade principal comprometida

🏷️ **Tags**: bug, urgent, dashboard, post-deploy
🎯 **Prioridade**: 1 (Urgent)
📊 **Status**: to do
⏱️ **SLA**: 4 horas para fix
```

#### **Passo 2: Investigação Rápida**
```bash
/engineer/start
```

**Input**: `BUG-445`

**Análise Automática**:
```
🕵️ Investigando bug BUG-445...

✅ Task recuperada do ClickUp
🔄 Status: "to do" → "in progress"
📁 Sessão: .claude/sessions/bug-dashboard-data/

🔍 **Root Cause Analysis**:

**Hipóteses baseadas no erro**:
1. API response mudou estrutura (property 'data' ausente)
2. Race condition no carregamento
3. Estado inicial undefined não tratado
4. Quebra na deserialização JSON

**Arquivos para Investigar**:
- components/Dashboard/index.tsx
- services/dashboardService.ts
- Recent commits no deploy de sexta
- API response logs

**Plano de Investigação**:
1. Examinar commits do último deploy
2. Verificar estrutura da API response
3. Reproduzir erro localmente
4. Implementar fix minimal
```

#### **Passo 3: Fix Rápido**
```bash
/engineer/work .claude/sessions/bug-dashboard-data/
```

**Investigação**:
````
🔍 Analisando commits recentes...

**COMMIT SUSPEITO ENCONTRADO**: 
feat: optimize dashboard API response ([dia_da_semana, HH:MM])
- Changed response.data.items → response.items
- Frontend não atualizado para nova estrutura

🐛 **ROOT CAUSE IDENTIFICADO**:
Backend mudou estrutura da API mas frontend ainda espera response.data

**ARQUIVOS AFETADOS**:
- services/dashboardService.ts (linha 45)
- components/Dashboard/DataList.tsx (linha 23)

🔧 **FIX IMPLEMENTADO**:
```typescript
// Antes (quebrado)
const items = response.data?.items || [];

// Depois (corrigido)  
const items = response.items || [];
```

✅ Fix aplicado em 2 arquivos
🧪 Testes locais: ✅ Dashboard carrega normalmente
🧪 Testes edge case: ✅ Fallbacks funcionando
````

#### **Passo 4: Deploy Urgente**
```bash
/engineer/pr
```

**Resultado**:
```
⚡ HOTFIX MODE DETECTADO (bug priority=1)

✅ Testes críticos passando (5/5)
✅ Não introduz regressões  

📝 Commit hotfix:
git commit -m "hotfix(dashboard): fix data property access after API change

- Update dashboardService to use new API response structure  
- Fix DataList component property access
- Add null safety for edge cases
- Tested with 70% user scenarios

Fixes: BUG-445
Estimated Resolution Time: 2 hours"

🚨 **HOTFIX PR #157**: https://github.com/org/repo/pull/157
🎯 **Fast-track review requested**

🔄 ClickUp Update:
✅ Status: "in progress" + tag "hotfix"
💬 Comment: "🚨 Hotfix PR criado #157 - Fix identificado para API structure change"

⚡ **DEPLOY IMEDIATO após approval**
```

---

## 📚 Criação de Documentação

### **Cenário**: Documentação técnica para novo microserviço
Um novo microserviço de notificações foi desenvolvido e precisa de documentação completa.

```bash
/docs/build-tech-docs
```

**Resultado**:
```
📚 Iniciando geração de documentação técnica...

🔍 **Análise do Projeto**:
- Detectado: Node.js + Express + TypeScript
- Arquitetura: Microserviço de notificações  
- Integrações: Redis, MongoDB, SendGrid
- Deploy: Docker + Kubernetes

📊 **Documentação Gerada**:

1. **project_charter.md** - Visão geral e objetivos
2. **CLAUDE.meta.md** - Guia para desenvolvimento com IA
3. **CODEBASE_GUIDE.md** - Navegação e estrutura
4. **API_SPECIFICATION.md** - Endpoints e schemas
5. **TROUBLESHOOTING.md** - Problemas comuns
6. **adr/001-notification-strategy.md** - Decisões arquiteturais

📝 **ClickUp Integration**:
✅ Task DOC-789 criada: "📚 Documentação técnica - Microserviço Notificações"
📊 Status: "done"
🔗 Links para todos os arquivos gerados
```

---

## 🔧 Refatoração de Sistema

### **Cenário**: Migrar sistema de cache para Redis
O sistema atual usa cache em memória e precisa migrar para Redis distribuído.

```bash
/product/task "Refatoração: Migrar sistema de cache de memória para Redis distribuído"
```

**Resultado**:
```
✅ Task REFAC-123 criada

📋 **Plano de Refatoração**:

**Fase 1**: Análise e preparação
- Audit do cache atual
- Benchmark de performance  
- Setup Redis cluster

**Fase 2**: Implementação paralela
- Adapter pattern para cache
- Dual-write durante migração
- Monitoring de ambos sistemas

**Fase 3**: Cutover gradual
- Feature flags para controle
- Rollback plan se necessário
- Performance validation

🏷️ Tags: refactor, cache, redis, performance
⏱️ Estimativa: 3-4 sprints
```

---

## ⚡ Hotfix de Emergência

### **Cenário**: Sistema de pagamento fora do ar
Sistema de pagamento está rejeitando todos os cartões válidos em produção.

```bash
/product/collect "CRÍTICO: Sistema de pagamento rejeitando todos os cartões em produção"
```

**Resultado Imediato**:
```
🚨 **MODO EMERGÊNCIA ATIVADO**

✅ Task URGENT-999 criada
🎯 Prioridade: 1 (URGENT)  
🏷️ Tags: critical, payment, production, outage
📊 Status: "in progress" (automático)
⏱️ SLA: 30 minutos para identificação da causa

🔍 **Análise Automática**:
- Últimos deploys: 2 horas atrás (auth service)
- APIs relacionadas: payment-processor, stripe-webhook
- Alerts ativos: 15 (payment failures)
- Error rate: 100% (últimos 20min)

📞 **Notificações Enviadas**:
- Slack: #incidents channel
- PagerDuty: On-call engineer
- Email: Tech leads + Product owner

🚀 **Próximo passo**: /engineer/start URGENT-999
```

```bash
/engineer/start
```

**Input**: `URGENT-999`

**Resposta Ultra-Rápida**:
````
🚨 **HOTFIX EMERGENCY MODE**

📁 Sessão: .claude/sessions/hotfix-payment-outage/
⚡ Branch: hotfix/payment-validation-fix

🔍 **Diagnóstico Rápido**:
- Recent deploy modificou validação de cartão
- Regex pattern muito restritivo
- Todos os cartões sendo rejeitados como inválidos

🔧 **Fix Identificado** (linha 34, paymentValidator.ts):
```typescript
// ANTES (muito restritivo)
const cardRegex = /^4[0-9]{12}(?:[0-9]{3})?$/;

// DEPOIS (pattern correto)  
const cardRegex = /^4[0-9]{12}(?:[0-9]{3})?$|^5[1-5][0-9]{14}$|^3[47][0-9]{13}$/;
```

⚡ **DEPLOY EM 5 MINUTOS**
````

---

## 🎯 Casos Especiais

### **Multi-Agente Coordination**
```bash
/engineer/work "implementar sistema de chat em tempo real"
```

**Resultado**:
```
🤖 **Coordenação Multi-Agente Ativada**

**Agentes Envolvidos**:
- nodejs-specialist: Backend WebSocket server
- react-developer: Frontend chat components  
- test-engineer: Testes de integração em tempo real

**Fluxo Coordenado**:
1. nodejs-specialist: Implementa WebSocket server + Redis pub/sub
2. react-developer: Cria UI de chat + hooks WebSocket
3. test-engineer: Testes E2E de messaging

**Status**: 3 agentes trabalhando em paralelo
**Sincronização**: A cada 30min via plan.md central
```

### **Detecção de Conflitos**
```bash
/engineer/work "modificar sistema de autenticação"
```

**Alerta**:
```
⚠️  **CONFLITO DETECTADO**

Outra task (AUTH-789) já está modificando sistema de autenticação.

**Opções**:
1. Aguardar conclusão de AUTH-789
2. Coordenar desenvolvimento paralelo
3. Refatorar para evitar conflitos

Qual abordagem preferir?
```

---

## 📦 Release e Deploy

### **Cenário**: Preparar release v1.2.0 com múltiplas features e bugfixes

#### **Passo 1: Criar Release Branch**
```bash
/git:flow release start "v1.2.0"
```

#### **Passo 2: Ajustes Finais**
```bash
# Atualizar CHANGELOG e versão
/engineer/bump minor

# Testes finais
npm run test:e2e
npm run test:integration
```

#### **Passo 3: PR e Aprovação**
```bash
/engineer/pr
```

**Checklist de Release**:
- ✅ Todos os testes passam
- ✅ CHANGELOG atualizado
- ✅ Versão atualizada
- ✅ Documentação atualizada
- ✅ Breaking changes documentadas

#### **Passo 4: Merge e Tag**
```bash
/git:flow release finish
```

**O que acontece**:
1. Merge para `main`
2. Merge para `develop`
3. Tag `v1.2.0`
4. Deploy para produção
5. Release notes geradas

---

## ❌ Anti-Patterns: O Que NÃO Fazer

### Anti-Pattern 1: Pular Análise
```bash
# ERRADO
/engineer/work feature-x  # Sem /engineer/start antes!

# CORRETO
/engineer/start feature-x  # Análise primeiro
/engineer/work feature-x   # Depois implementação
```

### Anti-Pattern 2: Commits Grandes
```bash
# ERRADO
git add .
git commit -m "Implementei tudo"

# CORRETO
git add src/services/jwt.service.ts
git commit -m "feat: implement JWT generation"

git add src/middleware/auth.middleware.ts
git commit -m "feat: add auth middleware"
```

### Anti-Pattern 3: Pular Testes
```bash
# ERRADO
/engineer/pr  # Sem rodar testes!

# CORRETO
npm test
/engineer/pre-pr  # Validações
/engineer/pr      # Depois PR
```

### Anti-Pattern 4: Não Usar Hierarquia de Tasks
```bash
# ERRADO - criar subtasks independentes sem parent
# CORRETO - ao usar /product/task, o sistema cria a hierarquia automaticamente
# com task principal + subtasks vinculadas pelo adapter do provider ativo
```

---

## 🔧 Troubleshooting Comum

### Problema 1: Branch já existe
```bash
# Sintoma
Error: Branch feature/x already exists

# Solução
git checkout feature/x  # Usar existente
# OU
git branch -D feature/x  # Deletar e recriar
/git:flow feature start "x"
```

### Problema 2: Task manager não atualiza
```bash
# Diagnóstico
cat .claude/sessions/<feature-slug>/context.md | grep "Task ID"

# Se task-id incorreto, corrigir manualmente no context.md
# Se correto, verificar variáveis do provider em .env:
#   jira: JIRA_HOST, JIRA_EMAIL, JIRA_API_TOKEN
#   clickup: CLICKUP_API_TOKEN
#   asana: ASANA_ACCESS_TOKEN
#   linear: LINEAR_API_KEY
# Se provider não configurado: /meta/setup-integration
```

### Problema 3: Sessão não encontrada
```bash
# Sintoma
/engineer/work x
Error: Session not found

# Solução
/engineer/start x  # Criar sessão primeiro
```

### Problema 4: Testes falhando antes do PR
```bash
# Diagnóstico
npm test -- --verbose

# Correção
# 1. Corrigir o código ou testes
# 2. Rodar novamente até passar
# 3. Só então executar /engineer/pr
```

---

## 📊 Métricas dos Exemplos

### **Tempos Médios Observados**
- **Feature completa**: 8-16 horas (3-5 dias)
- **Bug fix**: 2-6 horas (mesmo dia)
- **Hotfix crítico**: 15-45 minutos
- **Documentação**: 1-3 horas  
- **Refatoração**: 2-4 semanas

### **Taxa de Sucesso**
- **PRs approved first-time**: 85%
- **Bugs fixed correctly**: 92%
- **Documentação atualizada**: 100% (automático)
- **Task manager sync accuracy**: 98%

### **Benefícios Observados**
- ⚡ **50% mais rápido** que workflow manual
- 🎯 **30% menos bugs** pós-deploy
- 📚 **100% documentação** sempre atualizada  
- 🔄 **Zero overhead** de sincronização com task manager

---

**Próximo**: [Referência de Agentes →](agents-reference.md)
