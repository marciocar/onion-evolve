---
name: branding
description: |
  Branding e Posicionamento de Marca.
  Trabalha identidade e posicionamento via @branding-positioning-specialist,
  usando docs/business-context/ como base de decisão.
model: sonnet
allowed-tools: Read Edit
category: product
tags: [branding, positioning, marketing]
version: "3.0.0"
updated: "2026-06-02"
related_agents:
  - branding-positioning-specialist
---

# Comando Branding e Posicionamento de Marca

Comando especializado para trabalhar com Branding e Posicionamento de Marca usando o agente `@branding-positioning-specialist`, com acesso ao contexto de negócio completo em `docs/business-context/` para tomada de decisões fundamentadas.

## Requisitos do Usuário
<requirements>
#Comando para usar o agente @branding-positioning-specialist para atuar na criação de Branding e Posicionamento de Marca, podendo também usar o contexto de negócio (`docs/business-context/`) como base para tomada de decisões
</requirements>

## Processo

### 1. Análise do Contexto de Negócio

**1.1. Carregar Contexto de Negócio**
- Ler arquivos em `docs/business-context/` para entender:
  - Estratégia de produto (`PRODUCT_STRATEGY.md`)
  - Posicionamento competitivo (`COMPETITIVE_LANDSCAPE.md`)
  - Framework de mensagens (`MESSAGING_FRAMEWORK.md`)
  - Personas de clientes (`CUSTOMER_PERSONAS.md`)
  - Jornada do cliente (`CUSTOMER_JOURNEY.md`)
  - Voz do cliente (`VOICE_OF_CUSTOMER.md`)
  - Processo de vendas (`SALES_PROCESS.md`)
  - Métricas de produto (`PRODUCT_METRICS.md`)
  - Tendências da indústria (`INDUSTRY_TRENDS.md`)

**1.2. Identificar Informações Relevantes**
- Extrair elementos que informam branding:
  - Proposta de valor atual
  - Posicionamento existente
  - Público-alvo e personas
  - Diferenciação competitiva
  - Mensagens-chave
  - Valores e propósito da marca

**1.3. Mapear Gaps e Oportunidades**
- Identificar o que está faltando em branding:
  - Posicionamento não definido ou vago
  - Identidade visual inconsistente
  - Mensagens não alinhadas com posicionamento
  - Falta de brand guidelines
  - Oportunidades de diferenciação não exploradas

### 2. Invocação do Agente Especializado

**2.1. Preparar Contexto para o Agente**
- Consolidar informações do business context em formato estruturado
- Identificar tipo de trabalho de branding necessário:
  - Brand Positioning Statement
  - Análise competitiva e matriz de posicionamento
  - Brand Guidelines completo
  - Estratégia de branding 2025
  - Rebranding ou reposicionamento
  - Validação de posicionamento existente

**2.2. Invocar @branding-positioning-specialist**
- Passar contexto de negócio consolidado
- Especificar objetivo do trabalho de branding
- Fornecer informações sobre:
  - Público-alvo (das personas)
  - Concorrentes (do competitive landscape)
  - Proposta de valor atual
  - Mensagens existentes
  - Valores e propósito

**2.3. Colaborar com Agentes Relacionados (quando necessário)**
- `@storytelling-business-specialist`: Para desenvolver narrativa de marca
- `@product-agent`: Para alinhar com estratégia de produto
- `@research-agent`: Para pesquisa adicional de mercado se necessário

### 3. Desenvolvimento de Branding

**3.1. Brand Positioning Statement**
- Criar posicionamento estratégico formal usando:
  - Público-alvo das personas
  - Categoria do mercado
  - Diferenciação competitiva
  - Razão para acreditar (proof points)
- Validar alinhamento com estratégia de produto

**3.2. Análise Competitiva e Posicionamento**
- Criar matriz de posicionamento usando:
  - Concorrentes identificados no competitive landscape
  - Dimensões relevantes para o mercado
  - Oportunidade de posicionamento único
- Validar viabilidade e sustentabilidade

**3.3. Brand Guidelines**
- Desenvolver identidade visual e verbal:
  - Logotipo e variações (quando aplicável)
  - Paleta de cores
  - Tipografia
  - Tom de voz (alinhado com messaging framework)
  - Elementos gráficos
- Criar manual completo de aplicação

**3.4. Estratégia de Experiência**
- Desenvolver estratégia omnicanal:
  - Mapear pontos de contato
  - Garantir consistência
  - Personalização por público-alvo
- Brand storytelling framework

### 4. Integração com Contexto Existente

**4.1. Atualizar Documentos de Negócio**
- Atualizar `MESSAGING_FRAMEWORK.md` com:
  - Brand Positioning Statement formal
  - Posicionamento estratégico atualizado
  - Brand guidelines quando aplicável
- Atualizar `COMPETITIVE_LANDSCAPE.md` com:
  - Análise de posicionamento competitivo
  - Matriz de posicionamento visual
  - Diferenciação estratégica

**4.2. Validar Consistência**
- Garantir que branding está alinhado com:
  - Estratégia de produto
  - Mensagens existentes
  - Personas e público-alvo
  - Valores e propósito
- Identificar e resolver inconsistências

**4.3. Documentar Decisões**
- Criar ou atualizar documentação de branding:
  - Brand Positioning Statement
  - Brand Guidelines (quando completo)
  - Estratégia de posicionamento
  - Análise competitiva
- Manter histórico de evolução

### 5. Validação e Próximos Passos

**5.1. Revisar Output**
- Validar que branding desenvolvido:
  - Está fundamentado no contexto de negócio
  - É diferenciado e sustentável
  - Está alinhado com estratégia
  - É aplicável e acionável

**5.2. Identificar Próximos Passos**
- Sugerir ações concretas:
  - Implementar identidade visual
  - Aplicar em materiais existentes
  - Treinar equipe sobre branding
  - Validar com público-alvo
  - Medir impacto

---

## Guidelines

### ✅ Boas Práticas

**Uso do Contexto de Negócio:**
- ✅ Sempre consultar documentos de business context antes de desenvolver branding
- ✅ Usar informações de personas para definir público-alvo do posicionamento
- ✅ Aproveitar análise competitiva existente para matriz de posicionamento
- ✅ Alinhar branding com proposta de valor e estratégia de produto
- ✅ Considerar mensagens existentes ao desenvolver tom de voz

**Colaboração com Agentes:**
- ✅ Usar @branding-positioning-specialist para expertise técnica em branding
- ✅ Colaborar com @storytelling-business-specialist para narrativa de marca
- ✅ Consultar @product-agent quando necessário alinhamento estratégico
- ✅ Solicitar @research-agent para dados adicionais quando faltarem

**Desenvolvimento de Branding:**
- ✅ Criar posicionamento específico e diferenciado
- ✅ Fundamentar decisões em dados e contexto de negócio
- ✅ Garantir sustentabilidade do posicionamento
- ✅ Documentar todas as decisões e justificativas
- ✅ Validar alinhamento com estratégia existente

**Integração:**
- ✅ Atualizar documentos de negócio com branding desenvolvido
- ✅ Manter consistência entre branding e mensagens
- ✅ Garantir que branding suporta objetivos de negócio
- ✅ Criar links entre documentos relacionados

### ⚠️ Atenções Especiais

**Contexto de Negócio:**
- ⚠️ Se documentos de business context não existirem, solicitar criação primeiro
- ⚠️ Validar que informações do contexto estão atualizadas
- ⚠️ Identificar gaps no contexto que podem afetar branding
- ⚠️ Não assumir informações não documentadas

**Posicionamento:**
- ⚠️ Garantir que posicionamento é diferenciado dos concorrentes
- ⚠️ Validar que posicionamento é sustentável com recursos disponíveis
- ⚠️ Considerar evolução futura ao posicionar marca
- ⚠️ Evitar posicionamento genérico ou não diferenciado

**Consistência:**
- ⚠️ Garantir alinhamento entre posicionamento e mensagens existentes
- ⚠️ Validar que branding não contradiz estratégia de produto
- ⚠️ Considerar impacto em diferentes públicos-alvo
- ⚠️ Manter consistência em todos os pontos de contato

**Validação:**
- ⚠️ Validar posicionamento com stakeholders antes de implementar
- ⚠️ Considerar feedback de clientes e mercado
- ⚠️ Testar mensagens e identidade com público-alvo quando possível
- ⚠️ Medir impacto de mudanças de branding

### ❌ O Que Evitar

**Contexto:**
- ❌ Desenvolver branding sem consultar contexto de negócio
- ❌ Ignorar informações existentes sobre posicionamento
- ❌ Criar branding desconectado da estratégia de produto
- ❌ Assumir informações não documentadas

**Posicionamento:**
- ❌ Criar posicionamento genérico ou não diferenciado
- ❌ Posicionar marca em espaço já ocupado por concorrentes
- ❌ Criar posicionamento que não pode ser sustentado
- ❌ Ignorar análise competitiva ao posicionar

**Consistência:**
- ❌ Criar branding que contradiz mensagens existentes
- ❌ Desenvolver identidade inconsistente com valores da marca
- ❌ Ignorar alinhamento com estratégia de produto
- ❌ Criar guidelines que não são aplicáveis

**Implementação:**
- ❌ Implementar branding sem validar com stakeholders
- ❌ Fazer mudanças radicais sem justificativa clara
- ❌ Ignorar impacto em diferentes públicos-alvo
- ❌ Não documentar decisões e justificativas

---

## Exemplos

### Exemplo 1: Criar Brand Positioning Statement

**Input:**
```
/product/branding criar brand positioning statement para Facilitação usando contexto de negócio
```

**Processo:**
1. Carregar contexto de negócio (PRODUCT_STRATEGY, CUSTOMER_PERSONAS, COMPETITIVE_LANDSCAPE)
2. Identificar público-alvo: startups e empresas que precisam capacitar equipes
3. Extrair diferenciação: curadoria + metodologia + evidências + custo acessível
4. Invocar @branding-positioning-specialist com contexto consolidado
5. Desenvolver Brand Positioning Statement formal
6. Atualizar MESSAGING_FRAMEWORK.md com posicionamento

**Output:**
- Brand Positioning Statement completo e fundamentado
- Documentação atualizada em MESSAGING_FRAMEWORK.md
- Análise de posicionamento usando frameworks (Porter, Matriz)

---

### Exemplo 2: Análise Competitiva e Matriz de Posicionamento

**Input:**
```
/product/branding criar análise competitiva e matriz de posicionamento usando business context
```

**Processo:**
1. Carregar COMPETITIVE_LANDSCAPE.md para identificar concorrentes
2. Extrair dimensões relevantes do mercado
3. Invocar @branding-positioning-specialist para análise competitiva
4. Criar matriz de posicionamento visual
5. Identificar oportunidade de posicionamento único
6. Atualizar COMPETITIVE_LANDSCAPE.md com análise

**Output:**
- Matriz de posicionamento completa
- Análise detalhada de cada concorrente
- Oportunidade de posicionamento identificada
- Recomendações estratégicas

---

### Exemplo 3: Desenvolver Brand Guidelines Completo

**Input:**
```
/product/branding desenvolver brand guidelines completo usando contexto de negócio e mensagens existentes
```

**Processo:**
1. Carregar MESSAGING_FRAMEWORK.md para entender tom de voz existente
2. Carregar PRODUCT_STRATEGY.md para valores e propósito
3. Carregar CUSTOMER_PERSONAS.md para público-alvo
4. Invocar @branding-positioning-specialist para desenvolver guidelines
5. Colaborar com @storytelling-business-specialist para narrativa
6. Criar manual completo de brand guidelines
7. Atualizar MESSAGING_FRAMEWORK.md com guidelines

**Output:**
- Brand Guidelines completo (identidade visual e verbal)
- Manual de aplicação
- Exemplos de uso
- Documentação atualizada

---

### Exemplo 4: Estratégia de Branding 2025

**Input:**
```
/product/branding desenvolver estratégia de branding alinhada com tendências 2025 usando business context
```

**Processo:**
1. Carregar INDUSTRY_TRENDS.md para tendências do mercado
2. Carregar contexto completo de negócio
3. Invocar @branding-positioning-specialist para estratégia 2025
4. Aplicar tendências relevantes (sustentabilidade, personalização, omnicanal, etc.)
5. Desenvolver plano de implementação
6. Documentar estratégia

**Output:**
- Estratégia de branding 2025 completa
- Tendências aplicáveis identificadas
- Plano de implementação
- Métricas de sucesso

---

### Exemplo 5: Rebranding ou Reposicionamento

**Input:**
```
/product/branding analisar posicionamento atual e desenvolver estratégia de reposicionamento
```

**Processo:**
1. Carregar contexto completo de negócio
2. Analisar posicionamento atual vs desejado
3. Identificar necessidade de reposicionamento
4. Invocar @branding-positioning-specialist para análise
5. Desenvolver novo posicionamento
6. Criar plano de transição
7. Atualizar documentos de negócio

**Output:**
- Análise de posicionamento atual
- Novo posicionamento proposto
- Plano de transição
- Documentação atualizada

---

## Checklist de Validação

### Contexto de Negócio
- [ ] Documentos de business context foram consultados
- [ ] Informações relevantes foram extraídas
- [ ] Gaps no contexto foram identificados
- [ ] Contexto está atualizado e completo

### Branding Desenvolvido
- [ ] Posicionamento é específico e diferenciado
- [ ] Está fundamentado em dados e contexto
- [ ] É sustentável e viável
- [ ] Está alinhado com estratégia de produto
- [ ] Suporta objetivos de negócio

### Integração
- [ ] Documentos de negócio foram atualizados
- [ ] Consistência foi validada
- [ ] Links entre documentos foram criados
- [ ] Decisões foram documentadas

### Validação
- [ ] Posicionamento foi validado com stakeholders
- [ ] Alinhamento com estratégia foi confirmado
- [ ] Próximos passos foram identificados
- [ ] Métricas de sucesso foram definidas

---

## Comandos Relacionados

- `/product/spec` - Especificar features de produto
- `/product/task` - Criar tasks de desenvolvimento
- `/docs/build-business-docs` - Construir contexto de negócio
- `/docs/generate` - Gerar documentação

## Troubleshooting

### Problema: Documentos de business context não existem
**Solução**: Primeiro executar `/docs/build-business-docs` para criar contexto de negócio completo

### Problema: Informações conflitantes no contexto
**Solução**: Identificar conflitos, consultar stakeholders, atualizar documentos antes de desenvolver branding

### Problema: Posicionamento não está diferenciado
**Solução**: Revisar análise competitiva, identificar atributos únicos, ajustar posicionamento

### Problema: Branding não está alinhado com estratégia
**Solução**: Revisar estratégia de produto, ajustar branding para alinhamento, validar com stakeholders

---

## FAQ

**P: Preciso ter business context completo antes de usar este comando?**  
R: Recomendado, mas o comando pode trabalhar com contexto parcial. Gaps serão identificados.

**P: Posso usar este comando para rebranding?**  
R: Sim! O comando suporta análise de posicionamento atual e desenvolvimento de novo posicionamento.

**P: O comando atualiza automaticamente os documentos de negócio?**  
R: Sim, o comando atualiza MESSAGING_FRAMEWORK.md e COMPETITIVE_LANDSCAPE.md com branding desenvolvido.

**P: Posso desenvolver apenas parte do branding (ex: só posicionamento)?**  
R: Sim! Especifique no input o que deseja desenvolver. O comando se adapta ao escopo.

**P: Como valido o branding desenvolvido?**  
R: O comando inclui checklist de validação e sugere próximos passos, incluindo validação com stakeholders e público-alvo.

---

## Resumo de Uso

**Sintaxe básica:**
```
/product/branding [tipo de trabalho] usando contexto de negócio
```

**Tipos de trabalho disponíveis:**
- `criar brand positioning statement`
- `criar análise competitiva e matriz de posicionamento`
- `desenvolver brand guidelines completo`
- `desenvolver estratégia de branding 2025`
- `analisar posicionamento atual`
- `reposicionar marca`

**O que acontece:**
1. Carrega contexto de negócio completo
2. Identifica informações relevantes
3. Invoca @branding-positioning-specialist com contexto
4. Desenvolve branding fundamentado
5. Atualiza documentos de negócio
6. Valida e sugere próximos passos

**Output:**
- Branding desenvolvido e documentado
- Documentos de negócio atualizados
- Análise e justificativas
- Próximos passos identificados

---

**Exemplo de uso:**
```
/product/branding criar brand positioning statement para Facilitação usando contexto de negócio
```

