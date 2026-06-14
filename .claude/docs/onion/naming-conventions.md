# 📐 Padrão de Nomenclatura - Sistema Onion

## 🎯 Termo Padrão: `<feature-slug>`

### Definição
- **Formato**: kebab-case (minúsculas, separado por hífen)
- **Uso**: Nomes de branches, sessões, referências em comandos
- **Geração**: Automática a partir do nome da task/feature
- **Padrão**: Claude Code compatible

---

## ✅ Exemplos Corretos

```bash
# Features
user-authentication
payment-integration
api-v2-migration
dashboard-filters-advanced
oauth-google-integration

# Hotfixes
fix-payment-timeout
fix-login-redirect
fix-data-validation

# Releases
release-v2-1-0
release-v3-0-0-beta
```

---

## ❌ Exemplos Incorretos

```bash
# ❌ Underscore (snake_case)
user_authentication
payment_integration

# ❌ CamelCase
userAuthentication
paymentIntegration

# ❌ Maiúsculas
USER-AUTH
PAYMENT-INTEGRATION

# ❌ Espaços
user authentication
payment integration

# ❌ Caracteres especiais
user@authentication
payment#integration
```

---

## 🔑 Diferenças Importantes

### `<feature-slug>` (Slug)
**O que é**: Nome kebab-case da feature  
**Onde usar**:
- Branches Git: `feature/<feature-slug>`
- Sessões: `.claude/sessions/<feature-slug>/`
- Comandos: `/engineer/start <feature-slug>`

**Exemplo**: `user-authentication`

### `<task-id>` (ID ClickUp)
**O que é**: ID alfanumérico único do ClickUp  
**Onde usar**:
- API calls do ClickUp MCP
- Arquivo `context.md` (Task ID: xxx)
- Referências diretas a tasks

**Exemplo**: `86acu8pdk`

---

## 📝 Conversão Automática

O sistema converte automaticamente nomes para kebab-case:

| Input (Nome da Task) | Output (feature-slug) |
|---------------------|----------------------|
| "Implementar Autenticação JWT" | `implementar-autenticacao-jwt` |
| "Adicionar Filtros Avançados" | `adicionar-filtros-avancados` |
| "Integração Payment Gateway" | `integracao-payment-gateway` |
| "Fix: Bug no Login" | `fix-bug-no-login` |

**Algoritmo:**
1. Converter para minúsculas
2. Remover acentos
3. Substituir espaços e caracteres especiais por `-`
4. Remover hífens duplicados
5. Remover hífens no início/fim

---

## 🌿 Padrões de Branch

### Feature Branches
```bash
feature/<feature-slug>

# Exemplos:
feature/user-authentication
feature/payment-integration
feature/api-v2-migration
```

### Hotfix Branches
```bash
hotfix/<fix-slug>

# Exemplos:
hotfix/fix-payment-timeout
hotfix/fix-login-redirect
hotfix/fix-data-validation
```

### Release Branches
```bash
release/<version>

# Exemplos:
release/v2.1.0
release/v3.0.0
release/v2.1.0-beta
```

---

## 📁 Estrutura de Sessões

```
.claude/sessions/<feature-slug>/
├── context.md          # Task context + ClickUp info
├── architecture.md     # Technical architecture
├── plan.md            # Implementation plan
├── temp/              # Temporary files
├── artifacts/         # Generated artifacts
└── decisions.md       # Technical decisions
```

**Exemplo:**
```
.claude/sessions/user-authentication/
.claude/sessions/payment-integration/
.claude/sessions/fix-login-redirect/
```

---

## 🔧 Uso em Comandos

### Comandos de Produto
```bash
# Criar task estruturada
/product/task "Implementar Autenticação JWT"
# → Cria: feature-slug = implementar-autenticacao-jwt

# Criar feature para backlog
/product/feature "OAuth Google Integration"
# → Cria: feature-slug = oauth-google-integration
```

### Comandos de Engenharia
```bash
# Iniciar desenvolvimento
/engineer/start user-authentication

# Trabalhar na feature
/engineer/work user-authentication

# Criar PR
/engineer/pr

# Hotfix
/engineer/hotfix fix-payment-timeout
```

### Comandos Git
```bash
# Feature branch (chamado automaticamente)
/git:flow feature start user-authentication

# Hotfix branch (chamado automaticamente)
/git:flow hotfix start fix-payment-timeout

# Release
/git:flow release start v2.1.0
```

---

## 💡 Best Practices

### ✅ Recomendações
1. **Use nomes descritivos**: `user-authentication` melhor que `auth`
2. **Seja específico**: `payment-stripe-integration` melhor que `payment`
3. **Use prefixos quando apropriado**: `fix-`, `feat-`, `refactor-`
4. **Mantenha comprimento razoável**: 2-5 palavras ideal
5. **Evite abreviações obscuras**: `authentication` melhor que `auth`

### ❌ Evitar
1. **Nomes genéricos**: `update`, `fix`, `change`
2. **Nomes muito longos**: `implement-user-authentication-with-jwt-and-refresh-tokens-using-redis`
3. **Números sem contexto**: `feature-123`, `fix-456`
4. **Caracteres especiais**: `user@auth`, `payment#gateway`
5. **Espaços ou underscores**: `user auth`, `user_auth`

---

## 🔍 Troubleshooting

### Problema: "Sessão não encontrada"
**Causa**: Nome da sessão não corresponde ao slug usado  
**Solução**: Verificar nome exato em `.claude/sessions/`

```bash
# Listar sessões disponíveis
ls .claude/sessions/

# Usar nome exato
/engineer/work nome-exato-da-sessao
```

### Problema: "Branch já existe"
**Causa**: Feature-slug já foi usado anteriormente  
**Solução**: Usar nome diferente ou deletar branch antiga

```bash
# Listar branches
git branch -a

# Deletar branch local
git branch -D feature/nome-antigo

# Deletar branch remota
git push origin --delete feature/nome-antigo
```

### Problema: "Caracteres inválidos no nome"
**Causa**: Nome contém caracteres especiais  
**Solução**: Sistema converte automaticamente, mas evite:
- Emojis: ❌ `feature-🚀-auth`
- Símbolos: ❌ `feature-user@auth`
- Acentos: ⚠️ Convertidos automaticamente

---

## 📚 Referências

- [Guia de Comandos](.claude/docs/onion/commands-guide.md)
- [Fluxos de Engenharia](.claude/docs/onion/engineering-flows.md)
- [Exemplos Práticos](.claude/docs/onion/practical-examples.md)
- [Configuração Inicial](.claude/docs/onion/getting-started.md)

---

**Última atualização:** 2025-01-27  
**Versão:** 2.0 (Claude Code)  
**Padrão:** `<feature-slug>` (kebab-case)

