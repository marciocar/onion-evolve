# Prompts de Geração de Documentação

Este diretório contém prompts abrangentes projetados para guiar o Claude Code na geração automática de arquiteturas completas de documentação para projetos. Estes prompts fazem engenharia reversa da estrutura de documentação multi-arquivo que desenvolvemos.

## Prompts Disponíveis

### 🧩 Prompts Modulares (Reutilizáveis)

| Arquivo | Propósito | Uso |
|---------|-----------|-----|
| `clickup-patterns.md` | Padrões de formatação ClickUp | Tasks, comments, tags |
| `validation-rules.md` | Regras de validação de inputs | Validação de parâmetros |
| `output-formats.md` | Formatos de saída padronizados | Outputs consistentes |
| `code-review-checklist.md` | Checklist de code review | Reviews de PR |
| `git-workflow-patterns.md` | Padrões de workflow Git | GitFlow, commits |
| `story-points-gate.md` | Gate de estimativa antes de iniciar dev | `engineer/start`, `work`, `hotfix` |

### 📄 Prompts de Geração

### 📋 `technical.md` - Gerador de Documentação Técnica
**Propósito**: Analisar um codebase e gerar documentação abrangente de contexto técnico

**Saída**: Documentação técnica completa seguindo a arquitetura multi-arquivo:
- Project charter e ADRs
- Guias de desenvolvimento IA e navegação do codebase
- Lógica de negócio e especificações de API  
- Workflow de desenvolvimento e guias de troubleshooting

**Melhor Para**: 
- Projetos de software precisando de documentação técnica
- Projetos open source requerendo onboarding de contribuidores
- Codebases complexos precisando de contexto otimizado para IA

### 🏢 `business.md` - Gerador de Contexto de Negócio  
**Propósito**: Analisar um produto/projeto e gerar documentação abrangente de inteligência de negócio

**Saída**: Contexto de negócio completo seguindo a arquitetura multi-arquivo:
- Personas de cliente e mapeamento de jornada
- Estratégia de produto e catálogos de funcionalidades
- Panorama competitivo e análise de mercado
- Processos de vendas e diretrizes de comunicação

**Melhor Para**:
- Produtos precisando de otimização de suporte ao cliente
- Inteligência de negócio e análise de mercado
- Sistemas de interação de IA com cliente
- Alinhamento de vendas e marketing

## Exemplos de Uso

### Geração de Documentação Técnica
```bash
# Para um projeto Python
claude --prompt .claude/commands/common/prompts/technical.md \
  --project-path ./my-python-project \
  --output-path ./my-python-project/docs/technical \
  --technology-stack "Python, FastAPI, PostgreSQL" \
  --focus-areas "performance,security"

# Para uma aplicação React  
claude --prompt .claude/commands/common/prompts/technical.md \
  --project-path ./my-react-app \
  --output-path ./docs/technical \
  --existing-docs ./current-docs \
  --focus-areas "scalability,testing"
```

### Geração de Documentação de Negócio
```bash
# Para um produto SaaS
claude --prompt .claude/commands/common/prompts/business.md \
  --project-path ./my-saas-product \
  --output-path ./docs/business \
  --business-model "B2B SaaS" \
  --target-market "Enterprise developers" \
  --competitive-analysis "Competitor1,Competitor2"

# For an open source project
claude --prompt .claude/commands/common/prompts/business.md \
  --project-path ./my-oss-project \
  --output-path ./specs/business \
  --business-model "Open Source" \
  --customer-research ./community-feedback.md
```

## Arquitetura de Prompts

Ambos os prompts seguem uma abordagem sistemática:

1. **Fase de Análise**: Compreensão profunda do projeto/produto
2. **Fase de Pesquisa**: Coleta de contexto de múltiplas fontes
3. **Fase de Geração**: Criação da estrutura de documentação multi-arquivo
4. **Garantia de Qualidade**: Garantindo precisão e otimização para IA

## Funcionalidades Principais

### 🎯 **Estrutura Multi-Arquivo**
- Gera arquivos de documentação vinculados e modulares
- Cada arquivo foca em um domínio ou camada específica
- Fácil de manter e atualizar

### 🤖 **Otimizado para IA**
- Conteúdo estruturado para consumo de IA
- Inclui diretrizes específicas de interação com IA
- Permite melhor desenvolvimento e suporte assistido por IA

### 📊 **Baseado em Evidências**
- Fundamentado em dados e artefatos reais do projeto
- Evita conselhos genéricos em favor de insights específicos do projeto
- Valida afirmações com código, configurações e feedback

### 🔄 **Integração com Templates**
- Referencia os templates abrangentes em `.claude/commands/common/templates/`
- Garante consistência entre diferentes projetos
- Segue melhores práticas estabelecidas

## Padrões de Qualidade

### Documentação Técnica
- ✅ Arquitetura corresponde à implementação real
- ✅ Exemplos funcionam e são testados
- ✅ Afirmações de performance apoiadas por evidências
- ✅ Workflows de desenvolvimento correspondem às práticas do projeto

### Documentação de Negócio  
- ✅ Insights de cliente baseados em feedback real
- ✅ Análise competitiva atual e precisa
- ✅ Estratégia de produto alinhada com direção real
- ✅ Diretrizes de comunicação correspondem às preferências do cliente

## Personalização

Os prompts são projetados para serem flexíveis e podem ser adaptados para:

### Tipos de Projeto
- Aplicações web
- Apps mobile
- APIs e serviços backend
- Bibliotecas e frameworks
- Ferramentas de desenvolvedor
- Software empresarial

### Modelos de Negócio
- B2B SaaS
- B2C applications
- Open source projects
- E-commerce platforms
- Marketplace platforms
- Developer tools

### Estágios da Empresa
- Early stage / startup
- Growth stage
- Enterprise / mature

## Integração com Templates

Estes prompts funcionam em conjunto com:
- `.claude/commands/common/templates/technical-context-template.md`
- `.claude/commands/common/templates/business-context-template.md`

Os templates fornecem a estrutura e frameworks, enquanto estes prompts fornecem a metodologia de análise e estratégia de execução.

## Resultados Esperados

O uso destes prompts deve resultar em:

### Para Equipes de Desenvolvimento
- Onboarding mais rápido de novos membros da equipe
- Melhor experiência de desenvolvimento assistido por IA
- Tomada de decisões técnicas consistentes
- Eficiência aprimorada na revisão de código

### Para Equipes de Negócio  
- Capacidades aprimoradas de suporte ao cliente com IA
- Mensagens alinhadas de vendas e marketing
- Decisões de produto baseadas em dados
- Inteligência competitiva abrangente

### Para Sistemas de IA
- Compreensão profunda do contexto do projeto
- Capacidade de fornecer assistência contextualmente apropriada
- Melhor geração de código e sugestões
- Capacidades aprimoradas de interação com cliente

## Meta-Documentação

Estes prompts representam uma abordagem "meta" para documentação - são prompts que geram a arquitetura de documentação que projetamos e validamos. Eles permitem escalar documentação de alta qualidade e otimizada para IA em múltiplos projetos, mantendo padrões de consistência e qualidade.