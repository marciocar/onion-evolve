---
title: Padrões de Testing Colaborativo (Pair Testing e Three Amigos)
category: frameworks
status: active
version: "1.0.0"
updated: "2026-06-02"
maintained_by: Sistema Onion
related:
  - docs/knowledge-base/frameworks/framework-testes.md
  - .claude/commands/validate/collab/pair-testing.md
  - .claude/commands/validate/collab/three-amigos.md
---

# Padrões de Testing Colaborativo (Pair Testing e Three Amigos)

Knowledge base de referência com os **protocolos de colaboração**, **definições de papel**, **agendas detalhadas**, **templates de documentação** e **checklists de execução** usados pelas sessões de teste colaborativo do Sistema Onion.

Esta KB é consumida pelos comandos `/validate/collab/pair-testing` e `/validate/collab/three-amigos`. Os comandos atuam como **orquestradores** — carregam estes padrões quando precisam montar a agenda, gerar o template de documentação ou guiar a execução. O **framework canônico** de testes (perspectivas White/Grey/Black-box, QA Story Points, técnicas, casos de teste) vive em [`framework-testes.md`](framework-testes.md) — esta KB **não duplica** esse conteúdo, apenas operacionaliza a colaboração.

---

## 1. Perspectiva → Combinação de Participantes

Quando os participantes não são fornecidos, infira a combinação a partir da perspectiva:

| Perspectiva | Combinação | Foco | Atividades-chave |
|-------------|------------|------|------------------|
| 🔧 **Grey-box** | Dev + Dev | Contratos de API, integrações, performance | Code review com olhar de teste, integration testing, knowledge transfer técnico |
| 🧪 **White-box** ou **Black-box** (com Dev+QA) | Dev + QA | Lógica interna + experiência do usuário | Feature walkthrough, edge cases discovery, test data preparation |
| 👥 **Black-box** (com QA+QA) | QA + QA | Experiência do usuário, fluxos, usabilidade | Exploratory testing, user journey validation, cross-validation de findings |

**Sugestão de participantes (output):**

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👥 PARTICIPANTES SUGERIDOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Perspectiva: {{perspective}}
Combinação: [Dev+Dev | Dev+QA | QA+QA]
Participante 1: [NOME/ROLE]
Participante 2: [NOME/ROLE]

💡 Para customizar: use --participants "nome1,nome2"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 2. Agendas por Perspectiva

Toda sessão dura **1-2 horas** e usa **rotação Driver/Navigator** para manter o engajamento.

### 2.1 Grey-box (Dev + Dev)

```markdown
🔧 GREY-BOX PAIR TESTING (Dev + Dev)

1️⃣ SETUP E CONTEXTO (10-15min)
   ∟ Revisar código da feature
   ∟ Identificar pontos de integração
   ∟ Preparar ambiente de teste
   ∟ Definir contratos de API a validar

2️⃣ INTEGRATION TESTING (30-40min)
   ∟ Testar contratos de API
   ∟ Validar fluxos de integração
   ∟ Verificar tratamento de erros
   ∟ Testar timeouts e limites
   ∟ Rotação Driver/Navigator a cada 15min

3️⃣ PERFORMANCE & STRESS (20-30min)
   ∟ Testes de carga básicos
   ∟ Validação de fronteiras
   ∟ Análise de performance
   ∟ Identificação de bottlenecks

4️⃣ DOCUMENTAÇÃO (10-15min)
   ∟ Documentar findings
   ∟ Criar/atualizar casos de teste
   ∟ Estimar QA points para integração
   ∟ Definir próximos passos
```

### 2.2 White-box / Black-box (Dev + QA)

```markdown
🧪 WHITE-BOX + BLACK-BOX PAIR TESTING (Dev + QA)

1️⃣ FEATURE WALKTHROUGH (15-20min)
   ∟ Dev explica implementação técnica
   ∟ QA entende lógica interna
   ∟ Identificar pontos críticos
   ∟ Mapear fluxos de dados

2️⃣ EDGE CASES DISCOVERY (30-40min)
   ∟ Explorar casos limite juntos
   ∟ Validar tratamento de erros
   ∟ Testar dados inválidos
   ∟ Verificar validações
   ∟ Rotação Driver/Navigator a cada 20min

3️⃣ TEST DATA PREPARATION (15-20min)
   ∟ Criar datasets de teste
   ∟ Preparar cenários complexos
   ∟ Documentar pré-condições
   ∟ Validar setup de ambiente

4️⃣ VALIDATION & DOCUMENTATION (15-20min)
   ∟ Validar findings juntos
   ∟ Criar casos de teste
   ∟ Estimar QA points colaborativamente
   ∟ Priorizar bugs encontrados
```

### 2.3 Black-box (QA + QA)

```markdown
👥 BLACK-BOX PAIR TESTING (QA + QA)

1️⃣ EXPLORATORY SETUP (10-15min)
   ∟ Revisar critérios de aceitação
   ∟ Definir charters de exploração
   ∟ Preparar checklist de validação
   ∟ Identificar user journeys

2️⃣ EXPLORATORY TESTING (40-50min)
   ∟ Explorar feature livremente
   ∟ Validar user journeys
   ∟ Testar diferentes cenários
   ∟ Cross-validar findings
   ∟ Rotação Driver/Navigator a cada 25min

3️⃣ USABILITY & UX VALIDATION (20-30min)
   ∟ Validar experiência do usuário
   ∟ Verificar feedback visual
   ∟ Testar acessibilidade básica
   ∟ Validar mensagens de erro

4️⃣ CONSOLIDATION (15-20min)
   ∟ Consolidar findings
   ∟ Priorizar bugs
   ∟ Criar casos de teste
   ∟ Estimar QA points
   ∟ Documentar próximos passos
```

---

## 3. Template de Documentação em Tempo Real

Use durante a sessão para capturar findings por rotação. Salve como `pair-testing-session-{{feature}}.md`.

```markdown
# 📝 Pair Testing Session: {{feature}}

**Data:** [DATA]
**Participantes:**
- [Participante 1] ([Role])
- [Participante 2] ([Role])
**Perspectiva:** {{perspective}}
**Duração:** [DURAÇÃO]

## 📋 Feature Context
- **Nome:** {{feature}}
- **ID:** {{feature-id}} (se disponível)
- **Descrição:** [DESCRIÇÃO]

## 🎯 Objetivos da Sessão
- [ ] Objetivo 1
- [ ] Objetivo 2
- [ ] Objetivo 3

## 🔍 Findings por Rotação

### Rotação 1 (Driver: [Nome], Navigator: [Nome])
**Tempo:** [INÍCIO] - [FIM]

#### ✅ Validações Bem-sucedidas
- [ ] Validação 1: [Descrição]

#### 🐛 Bugs Encontrados
- [ ] **Bug #1:** [Título]
  - **Severidade:** [Crítica|Alta|Média|Baixa]
  - **Passos para reproduzir:**
    1. [Passo 1]
    2. [Passo 2]
  - **Comportamento esperado:** [Descrição]
  - **Comportamento atual:** [Descrição]
  - **Screenshots/Logs:** [Links]

#### 💡 Edge Cases Identificados
- [ ] Edge case 1: [Descrição]

#### 📝 Notas e Observações
- [Nota 1]

### Rotação 2 (Driver: [Nome], Navigator: [Nome])
[Repetir estrutura acima]

## 📊 Resumo Consolidado

### Bugs por Severidade
- **Crítica / Alta / Média / Baixa:** [X cada]

### Validações Realizadas
- **Total / Passou / Falhou / Bloqueado:** [X cada]

### Edge Cases Identificados
- **Total / Documentados / Priorizados:** [X cada]

## 🧪 Casos de Teste Criados/Atualizados
1. **TC-001:** [Nome]
   - Tipo: [White-box|Grey-box|Black-box]
   - Prioridade: [P1|P2|P3|P4]
   - Status: [Criado|Atualizado]

## 📈 Estimativa QA Story Points
**Estimativa Inicial:** [X] pontos
**Estimativa Após Sessão:** [Y] pontos
**Justificativa:** [Razão da mudança]

### Breakdown por Área
- **Testes Funcionais / Integração / Exploratórios / Edge Cases:** [X cada]

## ✅ Próximos Passos
- [ ] [Ação] - Responsável: [Nome] - Prazo: [Data]

## 🔗 Referências
- Feature: [Link] | Test Strategy: [Link] | Documentação: [Links]
```

---

## 4. Checklist de Execução

Salve como `pair-testing-checklist-{{feature}}.md`.

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ CHECKLIST DE EXECUÇÃO - PAIR TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 PREPARAÇÃO
  ✅ Ambiente de teste configurado
  ✅ Feature deployada/acessível
  ✅ Critérios de aceitação revisados
  ✅ Test data preparado
  ✅ Ferramentas de documentação prontas

🎯 DURANTE A SESSÃO
  ✅ Rotação Driver/Navigator a cada 20-30min
  ✅ Findings documentados em tempo real
  ✅ Bugs reportados imediatamente
  ✅ Edge cases capturados
  ✅ Dúvidas esclarecidas em tempo real

📝 DOCUMENTAÇÃO
  ✅ Template preenchido completamente
  ✅ Bugs documentados com repro steps
  ✅ Casos de teste criados/atualizados
  ✅ QA points estimados
  ✅ Próximos passos definidos

🔗 INTEGRAÇÃO
  ✅ Findings sincronizados com task manager
  ✅ Bugs criados como tasks/issues
  ✅ Test cases atualizados
  ✅ Comentários adicionados na feature
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 5. Integração com Task Manager

Quando `feature-id` é fornecido, comente na feature e crie subtasks (preparação, execução, follow-up de bugs), aplicando tags `pair-testing` e `{{perspective}}`.

**Formato de comentário (ClickUp — Unicode):**

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤝 PAIR TESTING SESSION SCHEDULED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Feature: {{feature}}
👥 Participantes: [Participante 1] + [Participante 2]
🎯 Perspectiva: {{perspective}}
📅 Data: [DATA]
⏱️  Duração: 1-2 horas

🎯 OBJETIVOS:
∟ Validação colaborativa da feature
∟ Descoberta de edge cases
∟ Refinamento de test strategy
∟ Estimativa colaborativa de QA points

📝 Documentação: [LINK para template]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

> Para Jira, ClickUp, Asana ou Linear, respeite o provider ativo (`TASK_MANAGER_PROVIDER`) e a formatação correspondente — ver `CLAUDE.md` e `.claude/utils/task-manager/adapters/`.

---

## 6. Integração com Calendar

Quando `--schedule` é fornecido:

- Criar evento: título `Pair Testing: {{feature}} ({{perspective}})`, duração 1-2h, participantes, descrição com agenda + link do template.
- Enviar convite e criar reminder 15min antes.
- Sem `--schedule`: gerar `.ics` para importação manual ou instruir criação manual.

---

## 7. Boas Práticas

- **Duração:** 1-2 horas por sessão.
- **Rotação Driver/Navigator:** a cada 20-30min (ajustar por agenda).
- **Documentação em tempo real:** sempre capturar findings durante a sessão, não depois.
- **Cross-validation:** em sessões QA+QA, validar findings entre participantes.
- **Sincronização:** manter task manager refletindo o estado real (bugs, casos de teste, QA points).

---

## 8. Three Amigos (PO + Developer + QA)

Sessão de **refinement** de user stories conduzida pelas três perspectivas (Product Owner, Developer, QA), focada em refinar critérios de aceitação, estimar pontos (Dev + QA + Cross) e definir test strategy + Definition of Done.

- **Duração recomendada:** 60-90 minutos por story.
- **Timing ideal:** Sprint Planning ou Story Refinement.
- **Participantes obrigatórios:** PO + Developer + QA.
- **Outputs críticos:** estimativas (Dev + QA + Cross) e test strategy.

### 8.1 Agenda Three Amigos

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 THREE AMIGOS SESSION — Story: {{story_id}}
👥 PO + Developer + QA  ⏱️  60-90min
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1️⃣ PERSPECTIVA PO (15-20min)
   ∟ Requisitos e valor de negócio · Critérios de aceitação
   ∟ Dependências de produto · Prioridade e contexto

2️⃣ PERSPECTIVA DEVELOPER (15-20min)
   ∟ Viabilidade e riscos técnicos · Estimativa Dev Story Points
   ∟ Dependências técnicas · Arquitetura proposta

3️⃣ PERSPECTIVA QA (15-20min)
   ∟ Cenários de teste · Estimativa QA Story Points
   ∟ Riscos de qualidade · Test strategy · Edge cases

4️⃣ PERSPECTIVA CROSS (15-20min)
   ∟ Integrações · Cross-testing points
   ∟ Dependencies entre equipes · Definition of Done · Riscos compartilhados

5️⃣ CONSOLIDAÇÃO (10-15min)
   ∟ Alinhamento final · Story refinada · Pontos acordados · Próximos passos
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 8.2 Template de Ata Three Amigos

Salve como `three-amigos-ata-{{story_id}}.md`.

```markdown
# 📝 Ata - Three Amigos: {{story_id}}

**Data:** [DATA] | **Participantes:** PO: [NOME] · Dev: [NOME] · QA: [NOME]

## 📋 Story Context
- **ID:** {{story_id}} · **Título:** [TÍTULO] · **Descrição:** [DESCRIÇÃO]

## 🎯 Perspectiva PO
- **Requisitos:** [ ] Req 1 · [ ] Req 2
- **Critérios de Aceitação:** 1. [...] 2. [...]
- **Valor de Negócio:** [...] · **Dependências de Produto:** [...]

## 🔧 Perspectiva Developer
- **Viabilidade Técnica:** [...]
- **Riscos Técnicos:** [ ] Risco 1 · [ ] Risco 2
- **Dev Story Points:** [X] — Justificativa: [...]
- **Dependências Técnicas:** [...] · **Arquitetura Proposta:** [...]

## 🧪 Perspectiva QA
- **Cenários de Teste:** 1. [Descrição] (Tipo: White/Black/Grey-box · Complexidade: B/M/A)
- **QA Story Points:** [X] — Justificativa: [...]
- **Riscos de Qualidade:** [ ] Risco 1 · [ ] Risco 2
- **Test Strategy:** Abordagem [...] · Cobertura [...] · Ferramentas [...]
- **Edge Cases:** [...]

## 🔄 Perspectiva Cross
- **Integrações Necessárias:** [...]
- **Cross-Testing Points:** [X] — Justificativa: [...]
- **Dependencies Entre Equipes:** [...] · **Riscos Compartilhados:** [ ] [...]

## ✅ Consolidação
- **Story Refinada:** [...]
- **Estimativas Finais:** Dev [X] · QA [X] · Cross [X] · **Total [X]**
- **Definition of Done:** [ ] Critério 1 · [ ] Critério 2 · [ ] Critério 3
- **Próximos Passos:** 1. [Ação] — Resp: [NOME] — Prazo: [DATA]
- **Riscos Consolidados:** | Risco | Impacto | Probabilidade | Mitigação |

## 📌 Observações
[Notas adicionais]
```

### 8.3 Checklist de Outputs Three Amigos

Salve como `three-amigos-checklist-{{story_id}}.md`.

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ CHECKLIST DE OUTPUTS - THREE AMIGOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 STORY REFINEMENT
  ✅ Descrição atualizada · Critérios testáveis · Dependências · Prioridade
📊 ESTIMATIVAS
  ✅ Dev Points · QA Points · Cross-Testing Points · Total documentado
🧪 TEST STRATEGY
  ✅ Cenários · Abordagem (White/Black/Grey-box) · Edge cases · Ferramentas
⚠️ RISCOS
  ✅ Técnicos · Qualidade · Compartilhados · Plano de mitigação
📝 DOCUMENTAÇÃO
  ✅ Ata completa · DoD acordada · Próximos passos · Story atualizada
🔗 INTEGRAÇÕES
  ✅ Dependências técnicas · de produto · integrações documentadas
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 8.4 Comentário de Conclusão (ClickUp — Unicode)

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤝 THREE AMIGOS SESSION COMPLETED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Data: [DATA] · 👥 PO + Dev + QA

📊 ESTIMATIVAS: Dev [X] · QA [X] · Cross [X] · Total [X]
✅ OUTPUTS: Story refinada ✓ · Test strategy ✓ · Riscos ✓ · DoD ✓
📝 Ata completa: [LINK ou anexo]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Na integração com task manager: atualizar descrição com story refinada, criar subtasks (Desenvolvimento/Dev points, Testes/QA points, Cross-testing/Cross points), aplicar tags `three-amigos` + `refined` e custom fields (Dev/QA/Cross Points) quando disponíveis. Respeitar o provider ativo conforme seção 5.
