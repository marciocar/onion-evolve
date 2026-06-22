# 📋 Templates Oficiais de Documentação C4 - Sistema Onion

## 📋 **Visão Geral dos Templates**

Templates oficiais baseados no C4 Model (Simon Brown) para documentação textual estruturada. Compatível com qualquer tipo de projeto TypeScript/JavaScript.

---

## 🎯 **Template de Contexto de Sistema**

### **Documentação Básica de Contexto de Sistema**
```markdown
# Documento de Arquitetura de Software - {PROJECT_NAME}

## 1. Contexto do Sistema

### Visão Geral do Sistema
- **Nome do Sistema**: {PROJECT_NAME}
- **Tipo de Sistema**: {PROJECT_TYPE} (SPA, API, Full-stack, Monorepo, etc.)
- **Propósito Principal**: {SYSTEM_PURPOSE}
- **Domínio de Negócio**: {BUSINESS_DOMAIN}
- **Confiança da Arquitetura**: {DETECTION_CONFIDENCE}%

### Paisagem do Sistema
{SYSTEM_LANDSCAPE_DESCRIPTION}

### Stakeholders Principais
#### Usuários Primários
- **{USER_TYPE_1}**: {USER_DESCRIPTION_1}
- **{USER_TYPE_2}**: {USER_DESCRIPTION_2}

#### Usuários Secundários
- **{SECONDARY_USER_TYPE}**: {SECONDARY_USER_DESCRIPTION}

### Sistemas Externos e Dependências
#### Sistemas Externos
{EXTERNAL_SYSTEMS_LIST}

#### Integrações Third-party
{THIRD_PARTY_INTEGRATIONS}

### Contexto de Negócio
#### Declaração do Problema
{PROBLEM_STATEMENT}

#### Objetivos de Negócio
{BUSINESS_GOALS}

#### Critérios de Sucesso
{SUCCESS_CRITERIA}

#### Restrições Principais
- **Restrições Técnicas**: {TECHNICAL_CONSTRAINTS}
- **Restrições de Negócio**: {BUSINESS_CONSTRAINTS}
- **Restrições Regulamentares**: {REGULATORY_CONSTRAINTS}

### Atributos de Qualidade
#### Requisitos de Performance
{PERFORMANCE_REQUIREMENTS}

#### Considerações de Segurança
{SECURITY_CONSIDERATIONS}

#### Fatores de Escalabilidade
{SCALABILITY_FACTORS}

#### Requisitos de Disponibilidade
{AVAILABILITY_REQUIREMENTS}

### Premissas e Dependências
{ASSUMPTIONS_AND_DEPENDENCIES}
```

### **Template de Contexto Estendido (para Sistemas Complexos)**
```markdown
### Fronteira Detalhada do Sistema
#### O que está Dentro do Sistema
{INTERNAL_SCOPE}

#### O que está Fora do Sistema
{EXTERNAL_SCOPE}

### Padrões de Integração
{INTEGRATION_PATTERNS}

### Visão Geral do Fluxo de Dados
{HIGH_LEVEL_DATA_FLOW}

### Contexto de Deploy
{DEPLOYMENT_CONTEXT}
```

---

## 🏢 **Templates Nível Container**

### **Template de Container de Aplicação Web**
```markdown
## 2. Arquitetura Nível Container

### Visão Geral dos Containers
Este sistema {PROJECT_TYPE} é decomposto nos seguintes containers:

### {CONTAINER_NAME_1}
#### Informações Básicas
- **Stack Tecnológico**: {TECHNOLOGY_STACK}
- **Ambiente de Execução**: {RUNTIME_ENVIRONMENT}
- **Responsabilidades Primárias**: {PRIMARY_RESPONSIBILITIES}

#### Detalhes Técnicos
- **Framework/Library**: {FRAMEWORK}
- **Linguagem/Versão**: {LANGUAGE_VERSION}
- **Sistema de Build**: {BUILD_SYSTEM}
- **Gerenciador de Pacotes**: {PACKAGE_MANAGER}

#### Dependências Externas
- **Banco de Dados**: {DATABASE_INFO}
- **APIs Externas**: {EXTERNAL_APIS}
- **Filas de Mensagem**: {MESSAGE_QUEUES}
- **Armazenamento de Arquivos**: {FILE_STORAGE}

#### Especificação da API
- **Estilo da API**: {API_STYLE} (REST, GraphQL, RPC)
- **URL Base**: {API_BASE_URL}
- **Autenticação**: {AUTHENTICATION_METHOD}
- **Endpoints Principais**: {KEY_ENDPOINTS}

#### Gerenciamento de Dados
- **Armazenamento de Dados**: {DATA_STORAGE}
- **Estratégia de Cache**: {CACHING_STRATEGY}
- **Validação de Dados**: {DATA_VALIDATION}

#### Configuração
- **Variáveis de Ambiente**: {ENVIRONMENT_VARIABLES}
- **Arquivos de Configuração**: {CONFIGURATION_FILES}
- **Feature Flags**: {FEATURE_FLAGS}

#### Monitoramento e Observabilidade
- **Logging**: {LOGGING_SETUP}
- **Métricas**: {METRICS_COLLECTION}
- **Health Checks**: {HEALTH_CHECKS}
- **Rastreamento de Erros**: {ERROR_TRACKING}

#### Deployment
- **Modelo de Deploy**: {DEPLOYMENT_MODEL}
- **Container/Empacotamento**: {CONTAINER_INFO}
- **Infraestrutura**: {INFRASTRUCTURE}
- **Pipeline CI/CD**: {CICD_INFO}
```

### **Template de Container de Serviço API**
```markdown
### {API_SERVICE_NAME}
#### Visão Geral do Serviço
- **Tipo de Serviço**: {SERVICE_TYPE}
- **Protocolo**: {PROTOCOL}
- **Formato de Dados**: {DATA_FORMAT}

#### Documentação da API
- **OpenAPI/Swagger**: {API_DOCS_LOCATION}
- **Exemplos Request/Response**: {EXAMPLES_LOCATION}
- **Rate Limiting**: {RATE_LIMITING}

#### Lógica de Negócio
- **Funcionalidades Principais**: {CORE_FEATURES}
- **Regras de Negócio**: {BUSINESS_RULES}
- **Lógica de Validação**: {VALIDATION_LOGIC}

#### Camada de Dados
- **Schema do Banco**: {DATABASE_SCHEMA}
- **Padrões de Acesso aos Dados**: {DATA_ACCESS_PATTERNS}
- **Gerenciamento de Transações**: {TRANSACTION_MANAGEMENT}
```

### **Template de Container Frontend**
```markdown
### {FRONTEND_APP_NAME}
#### Visão Geral da Aplicação
- **Tipo de Aplicação**: {APP_TYPE} (SPA, SSR, Static)
- **Framework**: {FRONTEND_FRAMEWORK}
- **Gerenciamento de Estado**: {STATE_MANAGEMENT}
- **Roteamento**: {ROUTING_SOLUTION}

#### Interface de Usuário
- **Biblioteca UI**: {UI_LIBRARY}
- **Abordagem de Styling**: {STYLING_APPROACH}
- **Design Responsivo**: {RESPONSIVE_DESIGN}
- **Acessibilidade**: {ACCESSIBILITY_FEATURES}

#### Funcionalidades Client-Side
- **Fluxo de Autenticação**: {AUTH_FLOW}
- **Fetch de Dados**: {DATA_FETCHING}
- **Estratégia de Cache**: {CLIENT_CACHING}
- **Suporte Offline**: {OFFLINE_SUPPORT}

#### Build e Assets
- **Ferramenta de Build**: {BUILD_TOOL}
- **Otimização de Assets**: {ASSET_OPTIMIZATION}
- **Bundle Splitting**: {BUNDLE_SPLITTING}
- **Assets Estáticos**: {STATIC_ASSETS}
```

---

## 🧩 **Templates Nível Componente**

### **Template Genérico de Documentação de Componente**
```markdown
## 3. Nível Componente - {CONTAINER_NAME}

### Visão Geral dos Componentes
Estrutura interna do {CONTAINER_NAME}:

### {COMPONENT_NAME}
#### Informações do Componente
- **Propósito**: {COMPONENT_PURPOSE}
- **Responsabilidades**: {COMPONENT_RESPONSIBILITIES}
- **Tipo de Componente**: {COMPONENT_TYPE} (Service, Controller, Repository, etc.)

#### Detalhes de Implementação
- **Localização do Arquivo**: {FILE_LOCATION}
- **Classes/Funções Primárias**: {PRIMARY_ELEMENTS}
- **Interfaces Principais**: {KEY_INTERFACES}
- **Padrões de Design**: {DESIGN_PATTERNS}

#### Dependências
- **Dependências Internas**: {INTERNAL_DEPENDENCIES}
- **Dependências Externas**: {EXTERNAL_DEPENDENCIES}
- **Injeção de Dependência**: {DEPENDENCY_INJECTION}

#### Manipulação de Dados
- **Dados de Entrada**: {INPUT_DATA}
- **Dados de Saída**: {OUTPUT_DATA}
- **Validação de Dados**: {DATA_VALIDATION}
- **Tratamento de Erros**: {ERROR_HANDLING}

#### Configuração
- **Opções de Configuração**: {CONFIGURATION_OPTIONS}
- **Configurações Específicas do Ambiente**: {ENV_SETTINGS}

#### Testes
- **Testes Unitários**: {UNIT_TESTS}
- **Testes de Integração**: {INTEGRATION_TESTS}
- **Cobertura de Testes**: {TEST_COVERAGE}

#### Considerações de Performance
- **Características de Performance**: {PERFORMANCE_NOTES}
- **Oportunidades de Otimização**: {OPTIMIZATION_NOTES}
- **Uso de Recursos**: {RESOURCE_USAGE}
```

### **Template de Componente React**
```markdown
### {REACT_COMPONENT_NAME}
#### Especificação do Componente
- **Tipo de Componente**: {COMPONENT_TYPE} (Functional, Class, Custom Hook)
- **Interface Props**: {PROPS_INTERFACE}
- **Gerenciamento de Estado**: {STATE_MANAGEMENT}
- **Lifecycle**: {LIFECYCLE_METHODS}

#### Implementação
- **Caminho do Arquivo**: {FILE_PATH}
- **Dependências**: {COMPONENT_DEPENDENCIES}
- **Hooks Utilizados**: {HOOKS_USED}
- **Context Providers**: {CONTEXT_PROVIDERS}

#### Comportamento
- **Interações do Usuário**: {USER_INTERACTIONS}
- **Side Effects**: {SIDE_EFFECTS}
- **Event Handlers**: {EVENT_HANDLERS}

#### Styling
- **Abordagem de Styling**: {STYLING_APPROACH}
- **Classes CSS**: {CSS_CLASSES}
- **Comportamento Responsivo**: {RESPONSIVE_BEHAVIOR}
```

### **Template de Componente API**
```markdown
### {API_COMPONENT_NAME}
#### Especificação do Serviço
- **Tipo de Serviço**: {SERVICE_TYPE}
- **Métodos HTTP**: {HTTP_METHODS}
- **Endpoints**: {ENDPOINTS}
- **Schema Request/Response**: {SCHEMA}

#### Lógica de Negócio
- **Operações Principais**: {CORE_OPERATIONS}
- **Regras de Negócio**: {BUSINESS_RULES}
- **Regras de Validação**: {VALIDATION_RULES}

#### Acesso aos Dados
- **Padrão Repository**: {REPOSITORY_PATTERN}
- **Operações de Banco**: {DATABASE_OPERATIONS}
- **Manipulação de Transações**: {TRANSACTION_HANDLING}

#### Tratamento de Erros
- **Tipos de Erro**: {ERROR_TYPES}
- **Respostas de Erro**: {ERROR_RESPONSES}
- **Estratégia de Logging**: {LOGGING_STRATEGY}
```

---

## 📋 **Templates de Architecture Decision Records (ADR)**

### **Template ADR Padrão**
```markdown
## 4. Architecture Decision Records

### ADR-{ADR_NUMBER}: {DECISION_TITLE}

**Data**: {DECISION_DATE}
**Status**: {STATUS} (Proposed, Accepted, Deprecated, Superseded)
**Decisores**: {DECISION_MAKERS}
**História Técnica**: {TECHNICAL_STORY_LINK}

#### Contexto
{DECISION_CONTEXT}

#### Direcionadores da Decisão
- {DECISION_DRIVER_1}
- {DECISION_DRIVER_2}
- {DECISION_DRIVER_3}

#### Opções Consideradas
- **Opção 1**: {OPTION_1_DESCRIPTION}
- **Opção 2**: {OPTION_2_DESCRIPTION}
- **Opção 3**: {OPTION_3_DESCRIPTION}

#### Resultado da Decisão
**Opção Escolhida**: {CHOSEN_OPTION}

**Justificativa**: {DECISION_JUSTIFICATION}

#### Consequências
**Positivas:**
- {POSITIVE_CONSEQUENCE_1}
- {POSITIVE_CONSEQUENCE_2}

**Negativas:**
- {NEGATIVE_CONSEQUENCE_1}
- {NEGATIVE_CONSEQUENCE_2}

**Neutras:**
- {NEUTRAL_CONSEQUENCE_1}

#### Notas de Implementação
{IMPLEMENTATION_NOTES}

#### Decisões Relacionadas
- {RELATED_ADR_1}
- {RELATED_ADR_2}

#### Referências
- {REFERENCE_1}
- {REFERENCE_2}

---
```

### **Template ADR de Escolha Tecnológica**
```markdown
### ADR-{ADR_NUMBER}: Seleção de Tecnologia - {TECHNOLOGY_AREA}

**Decisão**: Escolher {CHOSEN_TECHNOLOGY} para {TECHNOLOGY_AREA}

#### Matriz de Comparação
| Critérios | {OPTION_1} | {OPTION_2} | {CHOSEN_OPTION} |
|-----------|------------|------------|-----------------|
| Performance | {SCORE_1} | {SCORE_2} | {SCORE_3} |
| Curva de Aprendizado | {SCORE_1} | {SCORE_2} | {SCORE_3} |
| Suporte da Comunidade | {SCORE_1} | {SCORE_2} | {SCORE_3} |
| Ecossistema | {SCORE_1} | {SCORE_2} | {SCORE_3} |

#### Implicações Técnicas
{TECHNICAL_IMPLICATIONS}

#### Estratégia de Migração
{MIGRATION_STRATEGY}

#### Métricas de Sucesso
{SUCCESS_METRICS}
```

---

## 📊 **Template de Especificações Técnicas**

### **Template de Especificação de API**
```markdown
## 5. Especificações Técnicas

### Especificações da API

#### API {API_NAME}
- **URL Base**: {API_BASE_URL}
- **Versão**: {API_VERSION}
- **Autenticação**: {API_AUTHENTICATION}

#### Endpoints

##### {ENDPOINT_NAME}
- **Método**: {HTTP_METHOD}
- **Caminho**: {ENDPOINT_PATH}
- **Descrição**: {ENDPOINT_DESCRIPTION}

**Request:**
```json
{REQUEST_EXAMPLE}
```

**Response:**
```json
{RESPONSE_EXAMPLE}
```

**Respostas de Erro:**
- `{ERROR_CODE}`: {ERROR_DESCRIPTION}

#### Modelos de Dados
```typescript
{DATA_MODELS}
```

#### Fluxo de Autenticação
{AUTHENTICATION_FLOW}

#### Rate Limiting
{RATE_LIMITING_DETAILS}
```

### **Template de Schema de Banco**
```markdown
### Design do Banco de Dados

#### Visão Geral do Schema
{SCHEMA_OVERVIEW}

#### Relacionamento de Entidades
{ER_DESCRIPTION}

#### Tabelas

##### {TABLE_NAME}
```sql
{TABLE_SCHEMA}
```

- **Propósito**: {TABLE_PURPOSE}
- **Relacionamentos**: {TABLE_RELATIONSHIPS}
- **Índices**: {TABLE_INDEXES}

#### Padrões de Acesso aos Dados
{DATA_ACCESS_PATTERNS}

#### Considerações de Performance
{DATABASE_PERFORMANCE}
```

---

## 🎨 **Lógica de Seleção de Templates**

### **Regras de Mapeamento de Templates**
```typescript
const templateMappingRules = {
  // Tipo de Projeto → Seleção de Template
  'react-spa': {
    contextTemplate: 'system-context',
    containerTemplate: 'frontend-container',
    componentTemplate: 'react-component',
    adrTemplate: 'standard-adr'
  },
  
  'node-api': {
    contextTemplate: 'system-context-extended',
    containerTemplate: 'api-service-container',
    componentTemplate: 'api-component',
    adrTemplate: 'technology-choice-adr'
  },
  
  'next-fullstack': {
    contextTemplate: 'system-context',
    containerTemplate: 'web-application-container',
    componentTemplate: 'react-component',
    adrTemplate: 'standard-adr'
  },
  
  'nx-monorepo': {
    contextTemplate: 'system-context-extended',
    containerTemplate: 'web-application-container',
    componentTemplate: 'generic-component',
    adrTemplate: 'standard-adr'
  }
  
  // ... mais mapeamentos
}
```

### **Aplicação Progressiva de Templates**
```typescript
const progressiveTemplates = {
  level1_context: [
    'system-overview',
    'stakeholders',
    'external-dependencies',
    'business-context'
  ],
  
  level2_containers: [
    'container-overview',
    'technology-stack',
    'api-specifications',
    'deployment-model'
  ],
  
  level3_components: [
    'component-catalog',
    'implementation-details',
    'dependencies-mapping',
    'interfaces-specification'
  ],
  
  level4_decisions: [
    'adr-documentation',
    'technical-specifications',
    'migration-strategies'
  ]
}
```

---

## 🔧 **Regras de Processamento de Templates**

### **Mapeamento de Auto-População**
```yaml
auto_population_rules:
  PROJECT_NAME: "Extrai do nome do package.json ou diretório"
  PROJECT_TYPE: "Da detecção da análise cached"
  TECHNOLOGY_STACK: "Da análise de dependências"
  FRAMEWORK: "Da detecção de framework (React, Vue, Angular, etc.)"
  API_ENDPOINTS: "Da análise de rotas ou specs OpenAPI"
  DATABASE_INFO: "Da análise de dependências (mongoose, prisma, etc.)"
  
manual_input_required:
  BUSINESS_GOALS: "Prompt para usuário sobre objetivos de negócio"
  PROBLEM_STATEMENT: "Prompt contextual baseado no tipo de projeto"
  SUCCESS_CRITERIA: "Template + refinamento do usuário"
  DECISION_CONTEXT: "Para ADRs - sempre requer input do usuário"
```

### **Regras de Validação de Templates**
```yaml
validation_rules:
  required_sections:
    - system_overview
    - primary_responsibilities
    - external_dependencies
    
  optional_sections:
    - detailed_api_specs
    - performance_metrics
    - deployment_details
    
  format_requirements:
    - markdown_compliant: true
    - heading_hierarchy: true
    - code_block_syntax: true
    - link_validation: true
```

---

**Templates**: 📋 **C4 Model Oficial + Adaptativo por Projeto**  
**Cobertura**: Context, Container, Component, ADRs, Especificações Técnicas  
**Flexibilidade**: Workflow de auto-população + refinamento manual  
**Qualidade**: Baseado nos padrões do C4 Model de Simon Brown
