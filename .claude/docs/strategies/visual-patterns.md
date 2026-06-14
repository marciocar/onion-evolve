# 🎨 Visual Patterns - Padrões Visuais ClickUp

## 🎯 Objetivo

Definir **padrões visuais consistentes** para todos os comentários ClickUp do Sistema Onion, garantindo uniformidade e legibilidade em toda a integração.

---

## 🔲 Separadores

### Tamanho Padrão

Todos os comentários devem usar separadores com **exatamente 14 caracteres** (underscore):

```
━━━━━━━━━━━━━━
```

### ✅ Correto
```
🔧 FASE COMPLETADA: Backend Implementation

━━━━━━━━━━━━━━

📁 ARQUIVOS MODIFICADOS:
   ∟ src/auth/service.ts

━━━━━━━━━━━━━━

⏰ Completado: 2025-11-05 16:45
```

### ❌ Errado (Tamanho Antigo)
```
🔧 FASE COMPLETADA: Backend Implementation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  (← 34 caracteres - DESATUALIZADO)

📁 ARQUIVOS MODIFICADOS:
   ∟ src/auth/service.ts
```

---

## 🎨 Emojis Padrão

### Mapa de Emojis por Contexto

| Emoji | Significado | Uso | Exemplo |
|-------|-------------|-----|---------|
| 🔧 | Implementação/Fase | Início de seções sobre implementação | `🔧 FASE COMPLETADA` |
| 📝 | Progresso/Atualização | Status geral da task | `📝 PROGRESSO: Fase 1/4` |
| 🚀 | Launch/PR/Início | Novos Pull Requests ou inicios | `🚀 PR CRIADA` |
| 🔍 | Validação/Review | Verificações de qualidade | `🔍 VALIDAÇÃO PRE-PR` |
| ✅ | Completo/OK | Checkboxes e confirmações | `✅ TESTES ADICIONADOS` |
| ⏰ | Tempo/Timestamp | Data/hora de atividades | `⏰ Completado: 2025-11-05` |
| 📊 | Estatísticas/Métricas | Dados quantitativos | `📊 QUALIDADE DO CÓDIGO` |
| 🎯 | Meta/Próximo Passo | Objetivos e ações futuras | `🎯 Próximo: Fase 2` |
| 📁 | Arquivos | Estrutura de arquivos | `📁 ARQUIVOS MODIFICADOS` |
| 🔧 | Implementação | Funcionalidades técnicas | `🔧 IMPLEMENTAÇÕES` |
| 💡 | Decisão/Insight | Decisões técnicas | `💡 DECISÕES TÉCNICAS` |
| 🚫 | Bloqueio/Erro | Problemas e impedimentos | `🚫 BLOQUEIO` |
| ⏮️ | Reversão/Rollback | Desfazendo mudanças | `⏮️ ROLLBACK REALIZADO` |
| 📋 | Checklist/Lista | Listas de verificação | `📋 MUDANÇAS IMPLEMENTADAS` |

---

## 📐 Estrutura de Seções

### Padrão Geral de Seção

```
[EMOJI] [TÍTULO EM MAIÚSCULAS]

━━━━━━━━━━━━━━

[CONTEÚDO DA SEÇÃO]
  ∟ Item 1
  ∟ Item 2

━━━━━━━━━━━━━━
```

### Exemplo Completo

```
🔧 FASE COMPLETADA: Backend Implementation

━━━━━━━━━━━━━━

📁 ARQUIVOS MODIFICADOS:
   ∟ src/auth/service.ts
   ∟ src/auth/routes.ts
   ∟ src/auth/middleware.ts

🔧 IMPLEMENTAÇÕES:
   ▶ JWT generation com expiração
   ▶ Refresh token mechanism
   ▶ Password hashing

✅ TESTES ADICIONADOS:
   ∟ auth.service.spec.ts (12 testes)
   ∟ auth.routes.spec.ts (8 testes)
   ∟ Cobertura: 95%

💡 DECISÕES TÉCNICAS:
   ∟ Usamos jsonwebtoken v9.0.0
   ∟ Access token: 15min, Refresh: 7 dias

🚀 PRÓXIMOS PASSOS:
   ∟ Fase 2: Frontend Integration

━━━━━━━━━━━━━━

⏰ Completado: 2025-11-05 16:45 | 🎯 Status: Done
```

---

## ▶️ Símbolos de Indentação

Use os símbolos corretos para indentação de listas:

### Símbolos Principais
- `∟` - Item filho (principal)
- `▶` - Item de implementação/ação
- `◆` - Item de checklist
- `▪` - Ponto de lista (alternativo)

### Exemplo de Hierarquia

```
📋 LISTA PRINCIPAL:
   ∟ Item 1 (nível 1)
      ▶ Subitem 1.1 (nível 2)
      ▶ Subitem 1.2 (nível 2)
   ∟ Item 2 (nível 1)
      ◆ [ ] Checkbox item 2.1
      ◆ [x] Checkbox item 2.2
```

---

## 📏 Espaçamento e Formatação

### Espaçamento Entre Seções
```
[SEÇÃO 1 COM CONTEÚDO]

[LINHA EM BRANCO]

[SEÇÃO 2 COM CONTEÚDO]
```

### Linha em Branco Obrigatória
- Após título + emoji
- Entre seções principais
- Antes de timestamp final

### Sem Espaçamento (Contíguo)
- Entre linhas dentro de mesma seção
- Entre indentações de subitens

---

## 🏷️ Tags e Flags

### Tags Recomendadas em Comentários

```
🚀 [emoji] [TEXTO]
   ✅ Sucesso
   ⏳ Em progresso
   ❌ Falha
   🔧 Configuração
   📊 Dados/Métricas
```

### Flags Especiais

```
[✅/❌] - Status booleano (✅=done, ❌=failed)
[→] - Fluxo/direção (não usar em comentários)
[*] - Importante/crítico
```

---

## 🔄 Comparação Antes vs Depois

### ❌ Antes (Desatualizado)

```
🔧 FASE COMPLETADA: Backend Implementation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 ARQUIVOS MODIFICADOS:
   ∟ src/auth/service.ts

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⏰ Completado: 2025-11-05 16:45
```

**Problemas:**
- Separadores com 34 caracteres (muito longos)
- Visualmente pesado no ClickUp
- Não segue novo padrão centralizado

### ✅ Depois (Correto)

```
🔧 FASE COMPLETADA: Backend Implementation

━━━━━━━━━━━━━━

📁 ARQUIVOS MODIFICADOS:
   ∟ src/auth/service.ts

━━━━━━━━━━━━━━

⏰ Completado: 2025-11-05 16:45
```

**Melhorias:**
- Separadores com 14 caracteres (compacto)
- Mais legível e organizado
- Segue padrão centralizado

---

## 📋 Checklist Visual

Use checkboxes para rastreamento:

```
✅ CRITÉRIOS DE ACEITAÇÃO:
   ◆ [x] Critério 1 - Completo
   ◆ [x] Critério 2 - Completo
   ◆ [ ] Critério 3 - Pendente

📊 QUALIDADE:
   ◆ [x] Testes passando (95%)
   ◆ [x] Lint errors: 0
   ◆ [x] Documentação atualizada
```

---

## 🎯 Exemplo Completo Corrigido

### Template Completo com Todos os Padrões

```
🔧 FASE COMPLETADA: Database Layer Implementation

━━━━━━━━━━━━━━

📁 ARQUIVOS MODIFICADOS:
   ∟ src/database/connection.ts
   ∟ src/database/migrations/001_initial.sql
   ∟ src/database/seeds/users.sql
   ∟ src/models/user.model.ts
   ∟ src/models/organization.model.ts

🔧 IMPLEMENTAÇÕES:
   ▶ PostgreSQL connection pool
   ▶ Prisma ORM configuration
   ▶ Database migrations system
   ▶ Seeds para dados de teste
   ▶ Model definitions

✅ TESTES ADICIONADOS:
   ∟ database.connection.spec.ts (6 testes, 98%)
   ∟ user.model.spec.ts (12 testes, 95%)
   ∟ Cobertura Total: 96%

💡 DECISÕES TÉCNICAS:
   ∟ PostgreSQL escolhido (melhor suporte relacional)
   ∟ Prisma v5.7.0 (latest, bom TS support)
   ∟ Connection pooling: 20 conexões min, 100 max
   ∟ Migrations automáticas no startup

🚀 PRÓXIMOS PASSOS:
   ∟ Fase 3: Authentication Service
   ∟ Implementar JWT strategy
   ∟ Setup 2FA

━━━━━━━━━━━━━━

⏰ Completado: 2025-11-05 16:45 | 🎯 Status: Done
```

---

## 📚 Relacionado

- **Padrões de Formatação ClickUp**: `.claude/commands/common/prompts/clickup-patterns.md`
- **Adapter ClickUp**: `.claude/utils/task-manager/adapters/clickup.md` (API-first; MCP opcional)

---

**Status**: Padrões visuais documentados e centralizados  
**Última atualização**: 2025-11-05  
**Versão**: 1.0 - FASE 2 Completa

