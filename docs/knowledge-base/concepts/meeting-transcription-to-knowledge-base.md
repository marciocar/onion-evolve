# Transcrições de Reuniões → Base de Conhecimento Estruturada

## 📋 Visão Geral

Metodologia para transformar transcrições brutas de reuniões em conhecimento estruturado, acionável e de alto valor para humanos, sistemas e IA.

**Problema Central**: Reuniões geram informação valiosa que se perde ou fica inacessível. Uma transcrição bruta é apenas texto não-estruturado — difícil de buscar, processar ou integrar.

**Solução**: Framework de extração estruturada que converte diálogos em artefatos de conhecimento padronizados.

---

## 🎯 Framework EXTRACT

Metodologia em 7 dimensões para máxima extração de valor:

```
E - Essência (Resumo Executivo)
X - eXpectativas (Objetivos & Resultados Esperados)
T - Tarefas (Ações & Responsáveis)
R - Resoluções (Decisões Tomadas)
A - Ambiguidades (Gaps & Pontos Não Resolvidos)
C - Conexões (Dependências & Relacionamentos)
T - Timeline (Datas & Marcos)
```

### Aplicação Prática

Para cada reunião transcrita, extrair sistematicamente cada dimensão:

| Dimensão | Pergunta-Chave | Output |
|----------|----------------|--------|
| **Essência** | "Do que tratou esta reunião em 3 linhas?" | Resumo executivo |
| **eXpectativas** | "Qual era o objetivo? Foi atingido?" | Goals + Status |
| **Tarefas** | "Quem faz o quê até quando?" | Action items |
| **Resoluções** | "O que foi decidido definitivamente?" | Decisões |
| **Ambiguidades** | "O que ficou em aberto ou confuso?" | Gaps + Dúvidas |
| **Conexões** | "Isso afeta/depende de quê/quem?" | Links |
| **Timeline** | "Quais datas foram mencionadas?" | Cronograma |

---

## ⚡ Template Universal de Saída

Schema estruturado para máxima interoperabilidade:

```yaml
meeting:
  # Metadados
  id: "uuid"
  date: "2025-12-01"
  duration_minutes: 60
  participants:
    - name: "João Silva"
      role: "Product Owner"
    - name: "Maria Santos"
      role: "Tech Lead"
  
  # EXTRACT Framework
  essence:
    summary: "Definição da arquitetura do módulo de pagamentos"
    context: "Sprint 12 - Q4 2025"
    type: "technical_decision" # types: planning, review, decision, brainstorm, status
  
  expectations:
    objectives:
      - description: "Escolher entre microserviços vs monolito"
        status: "achieved" # achieved, partial, not_achieved
      - description: "Definir stack de tecnologia"
        status: "partial"
    success_criteria:
      - "Decisão documentada"
      - "Próximos passos definidos"
  
  tasks:
    - id: "task-001"
      description: "Criar POC de integração com gateway"
      owner: "João Silva"
      deadline: "2025-12-15"
      priority: "high" # high, medium, low
      status: "pending"
      dependencies: ["task-002"]
    - id: "task-002"
      description: "Documentar requisitos de segurança"
      owner: "Maria Santos"
      deadline: "2025-12-08"
      priority: "high"
      status: "pending"
  
  resolutions:
    decisions:
      - id: "dec-001"
        statement: "Adotaremos arquitetura de microserviços"
        rationale: "Melhor escalabilidade para volume esperado"
        decided_by: ["João Silva", "Maria Santos"]
        reversible: true
        confidence: "high" # high, medium, low
      - id: "dec-002"
        statement: "Gateway de pagamento será Stripe"
        rationale: "Melhor documentação e suporte regional"
        decided_by: ["João Silva"]
        reversible: true
        confidence: "medium"
  
  ambiguities:
    gaps:
      - description: "Não definido: tratamento de chargebacks"
        impact: "high"
        resolution_needed_by: "2025-12-10"
        suggested_owner: "Maria Santos"
      - description: "Custos de infraestrutura não estimados"
        impact: "medium"
        resolution_needed_by: "2025-12-20"
    contradictions:
      - parties: ["João Silva", "Maria Santos"]
        topic: "Necessidade de redundância geográfica"
        position_a: "Sim, desde o início"
        position_b: "Não, otimização prematura"
        status: "unresolved"
    questions_raised:
      - "Qual o SLA mínimo aceitável?"
      - "Precisamos de PCI compliance desde o MVP?"
  
  connections:
    dependencies:
      - type: "blocks"
        from: "Módulo de pagamentos"
        to: "Feature de assinaturas"
      - type: "requires"
        from: "Gateway integration"
        to: "Ambiente de staging"
    related_meetings:
      - id: "meeting-prev-001"
        topic: "Kickoff do projeto"
    related_documents:
      - title: "RFC: Payment Architecture"
        url: "/docs/rfcs/payment-arch.md"
    stakeholders_mentioned:
      - name: "Equipe de Compliance"
        context: "Precisam validar requisitos PCI"
  
  timeline:
    milestones:
      - date: "2025-12-15"
        description: "POC finalizada"
      - date: "2025-12-31"
        description: "Arquitetura aprovada"
    deadlines_mentioned:
      - date: "2025-01-15"
        context: "Lançamento beta"
    recurring_meetings:
      - frequency: "weekly"
        day: "Tuesday"
        topic: "Sync de pagamentos"

  # Metadados de Qualidade
  extraction_metadata:
    confidence_score: 0.85
    processing_date: "2025-12-01"
    requires_review: true
    review_notes: "Validar decisão sobre Stripe com time financeiro"
```

---

## 🔧 Técnicas de Extração por Tipo

### 1. Extração de Decisões (Resolutions)

**Padrões linguísticos indicadores**:
- "Decidimos que..."
- "Ficou definido..."
- "Vamos com..."
- "A escolha foi..."
- "Concordamos em..."

**Framework DACI para decisões complexas**:
```yaml
decision:
  driver: "Quem conduz a decisão"
  approver: "Quem aprova"
  contributors: ["Quem contribui"]
  informed: ["Quem deve ser informado"]
```

### 2. Extração de Ações (Tasks)

**Padrões linguísticos indicadores**:
- "[Nome], você pode..."
- "Próximo passo é..."
- "Vou fazer..."
- "Fica com você..."
- "Até [data]..."

**Template SMART para cada ação**:
```yaml
task:
  specific: "Criar documento de requisitos de API"
  measurable: "Documento aprovado por 2 revisores"
  assignable: "João Silva"
  realistic: true
  time_bound: "2025-12-10"
```

### 3. Extração de Ambiguidades (Gaps)

**Padrões linguísticos indicadores**:
- "Não sei se..."
- "Precisa verificar..."
- "Ficou pendente..."
- "Não concordamos sobre..."
- "Talvez... ou talvez..."
- "Depende de..."

**Classificação de gaps**:
```yaml
gap_types:
  information: "Falta dado ou informação"
  decision: "Decisão não tomada"
  alignment: "Desalinhamento entre partes"
  resource: "Recurso não definido"
  scope: "Escopo indefinido"
```

### 4. Extração de Sobreposições

**Identificar quando**:
- Duas pessoas assumem mesma responsabilidade
- Mesma tarefa mencionada com descrições diferentes
- Datas conflitantes para mesmo entregável
- Decisões contraditórias

```yaml
overlap:
  type: "responsibility" # responsibility, timeline, scope
  items:
    - "João vai preparar apresentação"
    - "Maria também mencionou fazer o deck"
  resolution_needed: true
```

---

## 📊 Níveis de Saída

Adapte a profundidade conforme necessidade:

### Nível 1: Ultra-Compacto (30 segundos de leitura)
```markdown
## Reunião: [Título] | [Data]
**Decisão**: [Principal decisão tomada]
**Ações**: [Nome] faz [o quê] até [quando]
**Pendente**: [Principal gap]
```

### Nível 2: Executivo (2 minutos de leitura)
```markdown
## [Título] - [Data]

### Resumo
[3-5 linhas contextualizando]

### Decisões
- ✅ [Decisão 1]
- ✅ [Decisão 2]

### Ações
| Responsável | Ação | Prazo |
|-------------|------|-------|
| [Nome] | [Descrição] | [Data] |

### Pendências
- ⚠️ [Gap 1]
- ⚠️ [Gap 2]

### Próxima Reunião
[Data] - [Pauta]
```

### Nível 3: Completo (5-10 minutos de leitura)
Template YAML completo + transcrição segmentada por tópico.

### Nível 4: Grafo de Conhecimento
Entidades e relacionamentos para integração com sistemas:
```json
{
  "entities": [
    {"id": "person-1", "type": "Person", "name": "João Silva"},
    {"id": "task-1", "type": "Task", "description": "Criar POC"},
    {"id": "decision-1", "type": "Decision", "statement": "Usar microserviços"}
  ],
  "relationships": [
    {"from": "person-1", "to": "task-1", "type": "OWNS"},
    {"from": "task-1", "to": "decision-1", "type": "IMPLEMENTS"}
  ]
}
```

---

## 🤖 Prompt Engineering para IA

### Prompt Base de Extração

```markdown
Analise a transcrição de reunião abaixo e extraia informações estruturadas seguindo o framework EXTRACT:

## Framework EXTRACT
- **E**ssência: Resumo executivo em 3 linhas
- **X**pectativas: Objetivos da reunião e se foram atingidos
- **T**arefas: Ações definidas (quem, o quê, quando)
- **R**esoluções: Decisões tomadas com justificativa
- **A**mbiguidades: Gaps, contradições, pontos não resolvidos
- **C**onexões: Dependências, stakeholders, documentos relacionados
- **T**imeline: Datas e marcos mencionados

## Regras
1. Se informação não estiver clara, marque como "[INFERIDO]" ou "[NÃO ESPECIFICADO]"
2. Para decisões, indique nível de confiança (alta/média/baixa)
3. Para gaps, indique impacto (alto/médio/baixo)
4. Identifique padrões de fala: "decidimos", "ficou pendente", "você faz"
5. Preserve citações importantes entre aspas

## Output Format
[Schema YAML definido acima]

## Transcrição
"""
[TRANSCRIÇÃO AQUI]
"""
```

### Prompt de Validação

```markdown
Revise a extração abaixo e identifique:
1. Informações extraídas que podem estar incorretas
2. Informações da transcrição que foram omitidas
3. Ambiguidades que precisam validação humana
4. Sugestões de melhoria na estruturação
```

---

## 🔄 Fluxo de Processamento

```
┌─────────────────┐
│ 1. TRANSCRIÇÃO  │ Audio → Texto (Whisper, Transkriptor)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. PRÉ-PROCESSO │ Limpeza, identificação de falantes
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. SEGMENTAÇÃO  │ Dividir por tópicos/momentos
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. EXTRAÇÃO     │ Aplicar framework EXTRACT via LLM
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 5. VALIDAÇÃO    │ Review humano de itens críticos
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 6. INTEGRAÇÃO   │ Exportar p/ KB (Notion/Obsidian) + task manager (abstração TASK_MANAGER_PROVIDER)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 7. INDEXAÇÃO    │ RAG / Vector DB para busca semântica
└─────────────────┘
```

---

## 💡 Best Practices

### Durante a Reunião
1. **Identificar participantes** claramente no início
2. **Verbalizar decisões**: "Então decidimos que..."
3. **Confirmar ações**: "João, você assume X até dia Y, certo?"
4. **Sinalizar gaps**: "Isso fica pendente de verificação"

### No Processamento
1. **Processar em até 24h** enquanto contexto está fresco
2. **Validar decisões críticas** com participantes
3. **Linkar** com reuniões anteriores e documentos relacionados
4. **Versionar** quando houver atualizações

### Na Estruturação
1. **Consistência**: Usar sempre mesmo schema
2. **IDs únicos**: Para rastreabilidade de decisões/tarefas
3. **Timestamps**: Quando possível, referenciar momento na gravação
4. **Confiança**: Indicar certeza das extrações

---

## ⚠️ Anti-Patterns a Evitar

| ❌ Anti-Pattern | ✅ Alternativa |
|-----------------|----------------|
| Transcrição literal sem estrutura | Extração estruturada com framework |
| Resumo genérico "foi discutido X" | Decisões específicas e acionáveis |
| Ações sem responsável ou prazo | Template SMART para cada ação |
| Ignorar ambiguidades | Documentar explicitamente como gaps |
| Processar semanas depois | Processar em 24h |
| Não validar com participantes | Review de decisões críticas |

---

## 🛠️ Ferramentas Recomendadas

### Transcrição
- **OpenAI Whisper**: Open-source, alta qualidade
- **AssemblyAI**: API com speaker diarization
- **Transkriptor**: 100+ idiomas, timestamps

### Processamento LLM
- **Claude** — recomendação primária (no Sistema Onion, plataforma única Claude Code). Use por **tier**: `opus` p/ análise profunda, `sonnet` p/ extração estruturada de alto volume, `haiku` p/ classificação. Contexto longo nativo.
- *Fora do Onion*, outras famílias (GPT-*, Llama 3 auto-hospedado) podem servir; dentro do Onion o substrato é Claude Code.

### Armazenamento
- **Notion**: Bases de dados flexíveis
- **Obsidian**: Markdown local + links
- **Vector DB**: Qdrant, Pinecone para RAG

### Integração
- **Zapier/n8n**: Automação de workflows
- **APIs REST**: Integração com sistemas internos

---

## 📐 Métricas de Qualidade

Avaliar qualidade da base de conhecimento:

```yaml
quality_metrics:
  completeness:
    description: "% de reuniões processadas"
    target: "> 90%"
  
  accuracy:
    description: "% de decisões validadas como corretas"
    target: "> 95%"
  
  timeliness:
    description: "Tempo médio de processamento"
    target: "< 24h"
  
  usability:
    description: "% de ações com owner + deadline definidos"
    target: "> 85%"
  
  searchability:
    description: "Tempo médio para encontrar informação"
    target: "< 30s"
  
  coverage:
    description: "% de gaps com owner para resolução"
    target: "> 80%"
```

---

## 🎓 Exemplo Completo

### Input: Transcrição Bruta
```
João: Pessoal, vamos começar. O objetivo de hoje é definir como vamos fazer o módulo de notificações.

Maria: Certo. Eu fiz um estudo e temos duas opções: usar Firebase ou implementar com WebSockets próprio.

João: Qual sua recomendação?

Maria: Firebase é mais rápido de implementar, mas WebSockets nos dá mais controle. Depende do prazo.

Pedro: O prazo é apertado, precisamos entregar até dia 20.

João: Então vamos com Firebase por agora. Maria, você consegue fazer um POC até sexta?

Maria: Consigo, mas preciso saber se vai ter push notification também ou só in-app.

João: Boa pergunta. Pedro, você sabe?

Pedro: Não foi definido ainda. Vou verificar com o cliente.

João: Ok, fica pendente então. Maria faz o POC considerando só in-app por enquanto.
```

### Output: Conhecimento Estruturado
```yaml
meeting:
  id: "mtg-2025-12-01-001"
  date: "2025-12-01"
  duration_minutes: 15
  participants:
    - {name: "João", role: "PM"}
    - {name: "Maria", role: "Dev"}
    - {name: "Pedro", role: "Account Manager"}

  essence:
    summary: "Definição da estratégia para módulo de notificações. Escolhido Firebase por prazo apertado."
    type: "technical_decision"

  expectations:
    objectives:
      - description: "Definir abordagem técnica para notificações"
        status: "achieved"
    
  tasks:
    - id: "task-001"
      description: "Criar POC de notificações com Firebase (apenas in-app)"
      owner: "Maria"
      deadline: "2025-12-06" # sexta-feira
      priority: "high"
      status: "pending"
    - id: "task-002"
      description: "Verificar com cliente se precisa push notification"
      owner: "Pedro"
      deadline: "[NÃO ESPECIFICADO]"
      priority: "high"
      status: "pending"

  resolutions:
    decisions:
      - id: "dec-001"
        statement: "Usar Firebase para notificações (vs WebSockets próprio)"
        rationale: "Prazo apertado - Firebase mais rápido de implementar"
        decided_by: ["João"]
        confidence: "high"

  ambiguities:
    gaps:
      - description: "Necessidade de push notification não definida"
        impact: "medium"
        suggested_owner: "Pedro"
    questions_raised:
      - "Push notification ou apenas in-app?"

  timeline:
    deadlines_mentioned:
      - date: "2025-12-20"
        context: "Prazo de entrega do módulo"
      - date: "2025-12-06"
        context: "POC Firebase (sexta)"
```

---

## 🔗 Referências

- [Reconstruct Before Summarize - Meeting Summarization](https://arxiv.org/abs/2305.07988)
- [Generating Abstractive Summaries from Meeting Transcripts](https://arxiv.org/abs/1609.07033)
- [Collective Knowledge Framework](https://arxiv.org/abs/2011.01149)
- [Amazon Bedrock Knowledge Bases](https://aws.amazon.com/bedrock/knowledge-bases/)
- [DACI Decision Framework](https://www.atlassian.com/team-playbook/plays/daci)

---

**Última atualização**: 2025-12-01  
**Versão**: 1.0.0  
**Autor**: Knowledge Base System

