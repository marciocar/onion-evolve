# Spec-Driven Development (SDD)

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2025-12-02 |
| **Última Atualização** | 2025-12-02 |
| **Categoria** | Concepts |
| **Aplicação** | Metodologia emergente de desenvolvimento com IA |
| **Status** | Em evolução (revalidar periodicamente) |

### Fontes Principais

- [Martin Fowler - Understanding Spec-Driven-Development](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)
- [GitHub Spec-Kit](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- [Thoughtworks Radar - Spec-Driven Development](https://www.thoughtworks.com/pt-br/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices)
- [Marmelab - Waterfall Strikes Back](https://marmelab.com/blog/2025/11/12/spec-driven-development-waterfall-strikes-back.html)
- [Zencoder.ai - SDD Guide](https://docs.zencoder.ai/user-guides/tutorials/spec-driven-development-guide)

---

## 🎯 Visão Geral

**Spec-Driven Development (SDD)** é uma abordagem emergente de desenvolvimento de software que enfatiza a criação de **especificações estruturadas antes da implementação do código**, especialmente em contextos de desenvolvimento assistido por IA.

### Definição

```
Spec-Driven Development = Especificação Estruturada + IA Coding Agents + Manutenção Contínua
```

**Princípio Central**: A especificação serve como **fonte única da verdade** tanto para humanos quanto para agentes de IA, permitindo que o código seja gerado e mantido de forma consistente.

### Contexto Histórico

SDD emerge como resposta ao crescimento do desenvolvimento assistido por IA:
- **2024-2025**: Crescimento exponencial de ferramentas de IA para código
- **Problema**: Como manter controle e qualidade quando IA gera código?
- **Solução**: Especificações estruturadas como guia para IA

---

## 📐 Níveis de Implementação SDD

Com base na análise de ferramentas existentes, identificam-se **três níveis progressivos** de implementação:

### 1. **Spec-First** (Especificação Primeiro)

**Características**:
- ✅ Especificação bem pensada escrita **antes** do código
- ✅ Usada durante desenvolvimento assistido por IA
- ❌ Especificação **descartada** após conclusão da tarefa

**Quando usar**:
- Tarefas pontuais e isoladas
- Features pequenas (< 5 story points)
- Prototipagem rápida

**Exemplo**:
```markdown
# Feature: Login com OAuth2

## Requisitos
- Login com Google
- Login com GitHub
- Refresh token automático

## Critérios de Aceitação
- [ ] Usuário consegue fazer login em < 3 cliques
- [ ] Sessão persiste por 7 dias
```

### 2. **Spec-Anchored** (Especificação Ancorada)

**Características**:
- ✅ Especificação mantida **após** conclusão
- ✅ Especificação **evolui** junto com o código
- ✅ Usada para manutenção e evolução contínua

**Quando usar**:
- Features médias (5-13 story points)
- Funcionalidades que evoluem ao longo do tempo
- Sistemas com múltiplas integrações

**Exemplo** (worklog — estrutura canônica na [SSOT §Contrato de Sessão](../frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento)):
```
.claude/sessions/auth-oauth2/
├── STATE.md        # Índice de resume (ponteiro NEXT)
├── context.md      # Spec inicial + Phase-Subtask Mapping
├── plan.md         # Plano de fases
└── notes.md        # Decisões arquiteturais (append-only)

# Especificação é atualizada quando:
# - Novos requisitos surgem
# - Bugs são corrigidos
# - Refatorações são feitas
```

### 3. **Spec-as-Source** (Especificação como Fonte)

**Características**:
- ✅ Especificação é o **único artefato editado por humanos**
- ✅ Código é **100% gerado** a partir da spec
- ✅ Humanos **nunca editam código diretamente**

**Quando usar**:
- Sistemas muito complexos
- Domínios bem definidos
- Quando abstração técnica é desejável

**⚠️ Aviso**: Nível mais arriscado devido a:
- Não-determinismo de LLMs
- Perda de controle direto sobre código
- Paralelos com Model-Driven Development (MDD) que não vingou

---

## 🔍 O Que É Uma Spec?

### Definição Operacional

Uma **spec** é um artefato estruturado, orientado a comportamento, escrito em linguagem natural que expressa funcionalidade de software e serve como guia para agentes de IA.

### Diferença: Spec vs Memory Bank

| Tipo | Escopo | Duração | Exemplo |
|------|--------|---------|---------|
| **Spec** | Funcionalidade específica | Temporária ou permanente | `feature-auth.md` |
| **Memory Bank** | Contexto geral do projeto | Permanente | `AGENTS.md`, `architecture.md` |

**Memory Bank** = Contexto geral (regras, arquitetura, padrões)  
**Spec** = Funcionalidade específica (requisitos, design, tarefas)

### Estrutura Típica de uma Spec

```markdown
# Feature: [Nome]

## 📋 Requisitos Funcionais
- [ ] Requisito 1
- [ ] Requisito 2

## 🎯 Critérios de Aceitação
- [ ] Critério 1 (GIVEN... WHEN... THEN...)
- [ ] Critério 2

## 🏗️ Design
- Componentes principais
- Fluxo de dados
- Tratamento de erros

## ✅ Tarefas
- [ ] Task 1 (relacionada ao Requisito 1.1)
- [ ] Task 2 (relacionada ao Requisito 1.2)
```

---

## 🛠️ Ferramentas SDD Disponíveis

### 1. **Kiro** (Mais Simples)

**Características**:
- Workflow: **Requirements → Design → Tasks**
- 3 documentos Markdown por feature
- Memory Bank: `steering/` (product.md, tech.md, structure.md)
- Nível: **Spec-First**

**Estrutura**:
```
feature-name/
├── requirements.md  # User Stories + Acceptance Criteria
├── design.md        # Arquitetura + Data Flow + Testing
└── tasks.md         # Lista de tarefas rastreáveis
```

**Quando usar**:
- Features pequenas e bem definidas
- Equipes iniciantes em SDD
- Prototipagem rápida

**Limitações**:
- Não menciona estratégia de manutenção (spec-anchored)
- Pode ser verboso demais para bugs simples

### 2. **Spec-Kit (GitHub)**

**Características**:
- CLI que cria estrutura de workspace
- Integração com múltiplos assistentes (Copilot, Claude Code, etc.)
- Workflow extenso: Research → Planning → Design → Implementation
- Nível: **Spec-First** (com potencial para Spec-Anchored)

**Estrutura**:
```
.specify/
├── memory/          # Memory Bank
│   ├── constitution.md
│   ├── product.md
│   └── tech.md
├── scripts/         # Scripts de automação
└── templates/       # Templates de specs

.github/prompts/     # Prompts para assistentes
```

**Quando usar**:
- Projetos maiores e mais complexos
- Equipes que querem customização total
- Integração com múltiplos assistentes

**Limitações**:
- Pode gerar **muitos arquivos** para revisar
- Workflow pode ser overkill para tarefas pequenas
- Agentes podem ignorar instruções mesmo com contexto grande

### 3. **Tessl Framework** (Mais Completo)

**Características**:
- Framework completo com múltiplas camadas
- Suporte a Spec-as-Source
- Paralelos com Model-Driven Development (MDD)
- Nível: **Spec-as-Source**

**Quando usar**:
- Sistemas muito complexos
- Domínios bem definidos
- Quando abstração técnica é desejável

**⚠️ Avisos**:
- Risco de combinar desvantagens de MDD + não-determinismo de LLMs
- Requer disciplina rigorosa da equipe

---

## ⚖️ SDD vs Outras Metodologias

### SDD vs TDD (Test-Driven Development)

| Aspecto | TDD | SDD |
|---------|-----|-----|
| **Artefato Principal** | Testes | Especificações |
| **Ordem** | Teste → Código → Refatoração | Spec → Código (IA) → Validação |
| **Foco** | Comportamento do código | Funcionalidade completa |
| **IA** | Não necessariamente | Essencial |

**Relação**: SDD pode **complementar** TDD - spec define o quê, testes validam o como.

### SDD vs BDD (Behavior-Driven Development)

| Aspecto | BDD | SDD |
|---------|-----|-----|
| **Formato** | GIVEN/WHEN/THEN estruturado | Linguagem natural estruturada |
| **Escopo** | Cenários de comportamento | Funcionalidade completa |
| **IA** | Não necessariamente | Essencial |

**Relação**: BDD pode ser **parte** de uma spec SDD (critérios de aceitação).

### SDD vs MDD (Model-Driven Development)

| Aspecto | MDD | SDD |
|---------|-----|-----|
| **Formato** | DSL/Modelos formais (UML) | Linguagem natural |
| **Geração** | Code generators determinísticos | LLMs não-determinísticos |
| **Adoção** | Limitada (nível de abstração incômodo) | Emergente (2024-2025) |

**Paralelo Histórico**: MDD não vingou para aplicações de negócio. SDD tenta resolver problemas similares com LLMs, mas mantém riscos.

---

## ✅ Benefícios do SDD

### 1. **Alinhamento Estratégico**
- ✅ Garante que código reflita estratégia de negócio
- ✅ Reduz riscos de desalinhamento
- ✅ Protege valor a longo prazo

### 2. **Colaboração Aprimorada**
- ✅ Facilita comunicação entre Product, Engineering e QA
- ✅ Compreensão compartilhada desde o início
- ✅ Reduz ambiguidades e mal-entendidos

### 3. **Qualidade do Código**
- ✅ Comportamento esperado definido antes da codificação
- ✅ Código mais consistente
- ✅ Menos retrabalho por ambiguidade

### 4. **Manutenibilidade**
- ✅ Especificações servem como documentação viva
- ✅ Mudanças futuras com maior confiança
- ✅ Menor risco de introduzir erros

### 5. **IA-Friendly**
- ✅ Contexto estruturado para agentes de IA
- ✅ Geração de código mais precisa
- ✅ Redução de alucinações

---

## ⚠️ Desafios e Limitações

### 1. **Overhead de Revisão**

**Problema**: Especificações podem ser **muito verbosas** e difíceis de revisar.

**Exemplo**:
- Spec-kit pode gerar 10+ arquivos Markdown
- Conteúdo repetitivo entre specs e código existente
- Revisar markdown pode ser mais trabalhoso que revisar código

**Mitigação**:
- Usar SDD apenas para problemas de tamanho apropriado
- Manter specs concisas e focadas
- Ferramentas devem melhorar experiência de revisão

### 2. **Falsa Sensação de Controle**

**Problema**: Mesmo com specs detalhadas, agentes podem:
- Ignorar instruções explícitas
- Seguir instruções demais (over-engineering)
- Não capturar nuances importantes

**Exemplo**:
- Agente pesquisa código existente
- Mas ignora que são descrições de classes existentes
- Gera código duplicado

**Mitigação**:
- Validação contínua em pequenos passos
- Não confiar cegamente em specs extensas
- Manter iterações pequenas

### 3. **Separação Funcional vs Técnica**

**Problema**: Difícil separar completamente requisitos funcionais de detalhes técnicos.

**Exemplo**:
- Quando especificar "login com OAuth2" (funcional)?
- Quando especificar "usar biblioteca X" (técnico)?
- Documentação inconsistente sobre limites

**Mitigação**:
- Estabelecer guidelines claras de separação
- Revisar specs com múltiplas perspectivas
- Aceitar que separação perfeita pode não ser possível

### 4. **Tamanho e Tipo de Problema**

**Problema**: Não está claro para que tamanho/tipo de problema SDD é adequado.

**Matriz de Decisão**:

| Tamanho | Clareza | Adequação SDD |
|---------|---------|---------------|
| Pequeno | Alta | ⚠️ Pode ser overkill |
| Pequeno | Baixa | ✅ Útil para clarificar |
| Médio | Alta | ✅ Ideal |
| Médio | Baixa | ⚠️ Requer mais trabalho |
| Grande | Alta | ✅ Benefício significativo |
| Grande | Baixa | ❌ Requer skills especializadas |

**Recomendação**: SDD funciona melhor para problemas **médios a grandes** com **clareza média a alta**.

### 5. **Spec-as-Source: Riscos**

**Problema**: Spec-as-Source combina riscos de:
- **MDD**: Inflexibilidade, overhead, abstração incômoda
- **LLMs**: Não-determinismo, alucinações, falta de controle

**Mitigação**:
- Começar com Spec-First ou Spec-Anchored
- Avaliar cuidadosamente antes de adotar Spec-as-Source
- Manter capacidade de editar código diretamente quando necessário

---

## 🎯 Quando Usar SDD

### ✅ Casos Ideais

1. **Features Médias (5-13 story points)**
   - Complexidade suficiente para se beneficiar de especificação
   - Não tão grande que requeira análise extensa de produto

2. **Integrações Complexas**
   - Múltiplos sistemas envolvidos
   - Contratos de API precisam ser definidos
   - Fluxos de dados complexos

3. **Refatorações Significativas**
   - Mudanças arquiteturais importantes
   - Migração de tecnologias
   - Reestruturação de domínios

4. **Desenvolvimento com IA**
   - Quando usando agentes de IA para gerar código
   - Necessidade de contexto estruturado
   - Múltiplos desenvolvedores usando IA

### ❌ Quando Evitar

1. **Bugs Simples**
   - Correções pontuais (< 2 horas)
   - Overhead não justifica

2. **Features Muito Pequenas**
   - < 3 story points
   - Especificação pode ser mais trabalho que implementação

3. **Problemas Muito Ambíguos**
   - Requisitos completamente indefinidos
   - Requer pesquisa e análise de produto primeiro
   - SDD não substitui discovery de produto

4. **Equipes Sem Experiência**
   - Requer disciplina e entendimento
   - Começar com práticas mais simples primeiro

---

## 🔄 Workflow SDD Recomendado

### Fase 1: Descoberta e Requisitos

```bash
# Coletar requisitos
/product/collect "Feature: sistema de notificações"

# Refinar requisitos
/product/refine

# Criar spec inicial
/product/spec
```

**Output**: `feature-notifications.md` com requisitos funcionais claros.

### Fase 2: Design e Planejamento

```bash
# Arquitetura leve
/product/light-arch

# Planejamento detalhado
/engineer/plan
```

**Output**: Design de componentes, fluxos de dados, estratégia de testes.

### Fase 3: Implementação Assistida por IA

```bash
# Iniciar desenvolvimento
/engineer/start

# Trabalhar com IA
/engineer/work
```

**Output**: Código gerado seguindo a spec.

### Fase 4: Validação e Refinamento

```bash
# Testes
/test/unit
/test/integration

# Validação
/validate/workflow
```

**Output**: Código validado contra critérios de aceitação.

### Fase 5: Manutenção (Spec-Anchored)

```bash
# Atualizar spec quando necessário
# Evoluir funcionalidade baseada em spec
```

**Output**: Spec mantida como fonte da verdade.

---

## 📊 Métricas de Sucesso SDD

### Indicadores de Qualidade

| Métrica | Meta | Como Medir |
|---------|------|------------|
| **Conformidade Spec-Código** | > 90% | Revisão de código vs spec |
| **Tempo de Revisão** | < 30% do tempo total | Tracking de tempo |
| **Retrabalho** | < 10% | Issues reabertas |
| **Cobertura de Critérios** | 100% | Testes vs critérios de aceitação |

### Indicadores de Eficiência

| Métrica | Meta | Como Medir |
|---------|------|------------|
| **Tempo até Primeira Implementação** | Redução 20% | Comparação com desenvolvimento tradicional |
| **Qualidade de Código Gerado** | > 80% aprovação | Code review scores |
| **Satisfação da Equipe** | > 7/10 | Pesquisas periódicas |

---

## 🔗 Integração com Sistema Onion

### Relação com Spec-as-Code Strategy

SDD é **complementar** à estratégia Spec-as-Code do Sistema Onion:

| Conceito | Spec-as-Code | SDD |
|----------|--------------|-----|
| **Foco** | Metodologia de especificação | Abordagem de desenvolvimento |
| **Escopo** | Estrutura e versionamento | Workflow e ferramentas |
| **IA** | Suporte a IA | Essencial para IA |

**Uso Conjunto**: Spec-as-Code define **como estruturar** specs, SDD define **como usar** specs no desenvolvimento.

### Comandos Relacionados

| Comando | Uso em SDD |
|---------|------------|
| `/product/spec` | Criar spec inicial |
| `/product/refine` | Refinar spec |
| `/engineer/plan` | Planejar implementação baseada em spec |
| `/engineer/start` | Iniciar desenvolvimento com spec |
| `/engineer/work` | Implementar seguindo spec |

### Agentes Relacionados

| Agente | Uso em SDD |
|--------|------------|
| `@product-agent` | Criar e refinar specs |
| `@metaspec-gate-keeper` | Validar conformidade de specs |
| `@code-reviewer` | Validar código vs spec |

---

## 📚 Referências e Recursos

### Artigos e Documentação

1. **[Martin Fowler - Understanding Spec-Driven-Development](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)**
   - Análise detalhada de 3 ferramentas SDD
   - Níveis de implementação
   - Desafios e limitações

2. **[GitHub Spec-Kit Documentation](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)**
   - Guia oficial do Spec-Kit
   - Workflow completo
   - Exemplos práticos

3. **[Thoughtworks Radar - Spec-Driven Development](https://www.thoughtworks.com/pt-br/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices)**
   - Análise de tendências
   - Benefícios e riscos
   - Recomendações práticas

4. **[Marmelab - Waterfall Strikes Back](https://marmelab.com/blog/2025/11/12/spec-driven-development-waterfall-strikes-back.html)**
   - Crítica construtiva ao SDD
   - Comparação com Waterfall
   - Quando evitar

### Ferramentas

- **Kiro**: [Website](https://kiro.ai) - Ferramenta mais simples
- **Spec-Kit**: [GitHub](https://github.com/github/spec-kit) - Ferramenta GitHub
- **Tessl**: Framework completo (menos documentação pública)

### Conceitos Relacionados

- **Spec-as-Code Strategy** (`docs/knowledge-base/concepts/spec-as-code-strategy.md`)
- **Specification-Driven AI Abstraction Layer** (`docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`)
- **AI Agent Design Patterns** (`docs/knowledge-base/concepts/ai-agent-design-patterns.md`)

---

## 🚀 Próximos Passos

### Para Começar com SDD

1. **Escolher Ferramenta**:
   - Kiro para começar simples
   - Spec-Kit para customização
   - Sistema Onion para integração completa

2. **Começar Pequeno**:
   - Feature de 5-8 story points
   - Requisitos claros
   - Equipe pequena e alinhada

3. **Iterar e Aprender**:
   - Revisar specs regularmente
   - Ajustar nível de detalhe
   - Coletar feedback da equipe

4. **Evoluir Gradualmente**:
   - Spec-First → Spec-Anchored → (Opcional) Spec-as-Source
   - Não pular etapas
   - Avaliar riscos em cada nível

---

## ⚠️ Avisos Finais

### Não É Panaceia

SDD não resolve todos os problemas de desenvolvimento:
- ❌ Não substitui discovery de produto
- ❌ Não elimina necessidade de code review
- ❌ Não garante qualidade automática
- ❌ Não funciona bem para todos os tipos de problema

### Requer Disciplina

SDD funciona melhor quando:
- ✅ Equipe comprometida com processo
- ✅ Specs são mantidas atualizadas
- ✅ Revisão é feita seriamente
- ✅ Feedback é incorporado

### Evolução Contínua

SDD está em evolução (2025):
- Terminologia ainda não estável
- Ferramentas mudam rapidamente
- Melhores práticas emergindo
- Requer experimentação e adaptação

---

**Última atualização**: 2025-12-02  
**Versão**: 1.0.0  
**Mantido por**: Sistema Onion  
**Status**: Em evolução - revisar periodicamente conforme ferramentas e práticas evoluem

