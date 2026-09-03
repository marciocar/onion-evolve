---
name: runflow-dev
description: |
  Desenvolvimento Runflow — comando especializado para criar projetos, agentes, workflows, RAG e integrações com Runflow SDK.
  Delega para o agente especialista @runflow-specialist.
allowed-tools: Read
category: development
tags: [runflow, sdk, workflows]
version: "1.1.0"
updated: "2026-07-23"
---

# Desenvolvimento Runflow

Comando especializado para desenvolvimento completo com Runflow SDK usando o agente especialista `@runflow-specialist`. Facilita criação de projetos, agentes, workflows, RAG e integrações, sempre orientando próximos passos e fechamento de tarefas.

> **SSOT verificada**: `@runflow-ai/sdk` **1.6.2** — base de conhecimento `docs/knowledge-base/platforms/runflow.md` (verified_at 2026-07-23, fonte `docs.runflow.ai` + registry npm). API atual: `new Agent({...})` + `agent.process(...)`, `main.ts` como entrypoint, workflows via `flow(...).step(...).build().execute(...)` (a antiga `createWorkflow` está **deprecada**). Requisito de runtime: **Node.js >= 22**.

## Requisitos do Usuário
<requirements>
{$INPUT}
</requirements>

## Processo

### 1. Invocar Agente Especialista

**SEMPRE** invoque o agente `@runflow-specialist` para todas as operações:

```
@runflow-specialist [sua solicitação detalhada]
```

O agente possui conhecimento completo da base de conhecimento em `docs/knowledge-base/platforms/runflow.md` e padrões do projeto.

### 2. Operações Disponíveis

#### 2.1. Criar Novo Projeto Runflow

**Quando usar**: Iniciar um novo projeto do zero com Runflow SDK

**Comando**:
```
@runflow-specialist Criar novo projeto Runflow com nome [nome-do-projeto]. Deve incluir: estrutura de diretórios, package.json, tsconfig.json, arquivo main.ts com agente básico, configuração .runflow/rf.json, e README.md
```

**O que o agente fará**:
1. Criar estrutura de diretórios completa
2. Configurar `package.json` com dependências Runflow
3. Configurar `tsconfig.json` para TypeScript
4. Criar `main.ts` com agente básico seguindo padrões
5. Criar `.runflow/rf.json` com template de configuração
6. Gerar `README.md` com instruções
7. Validar código e sugerir próximos passos

**Exemplo de uso**:
```
@runflow-specialist Criar novo projeto Runflow chamado "assistente-juridico" para ajudar com processos jurídicos
```

#### 2.2. Criar Novo Agente Runflow

**Quando usar**: Adicionar novo agente a projeto existente

**Comando**:
```
@runflow-specialist Criar novo agente Runflow chamado [nome] com as seguintes características: [descrição detalhada das funcionalidades, tools necessárias, se precisa RAG, memory, etc.]
```

**O que o agente fará**:
1. Analisar requisitos e consultar base de conhecimento
2. Verificar padrões existentes no projeto (`main.ts`)
3. Criar agente seguindo estrutura do projeto
4. Implementar tools customizadas se necessário
5. Configurar memory e RAG conforme especificado
6. Validar código e criar testes básicos
7. Documentar uso e próximos passos

**Exemplo de uso**:
```
@runflow-specialist Criar agente chamado "ProcessAnalyzer" que analisa processos jurídicos. Precisa de: tool para buscar processos por número, RAG com base "processos", memory para lembrar análises anteriores, e responder em português brasileiro
```

#### 2.3. Conectar Agentes (Multi-Agent System)

**Quando usar**: Criar sistema com múltiplos agentes especializados e supervisor

**Comando**:
```
@runflow-specialist Criar sistema multi-agente com supervisor que roteia para: [lista de agentes especializados]. Supervisor deve: [critérios de roteamento]. Cada agente especializado: [descrição de cada um]
```

**O que o agente fará**:
1. Criar agentes especializados individuais
2. Criar agente supervisor com lógica de roteamento
3. Implementar função de roteamento inteligente
4. Configurar comunicação entre agentes
5. Criar exemplo de uso completo
6. Documentar arquitetura e fluxo
7. Sugerir melhorias e otimizações

**Exemplo de uso**:
```
@runflow-specialist Criar sistema multi-agente com supervisor que roteia para: SalesAgent (vendas), SupportAgent (suporte técnico), BillingAgent (cobrança). Supervisor analisa intenção e roteia automaticamente. Cada agente tem suas próprias tools e RAG específicos
```

#### 2.4. Criar Projeto RAG (Base de Conhecimento)

**Quando usar**: Configurar RAG para busca semântica em base de conhecimento

**Comando**:
```
@runflow-specialist Configurar RAG para base de conhecimento "[nome-da-base]" com as seguintes características: [tipo de conteúdo, threshold, k resultados, quando usar busca]. Integrar com agente [nome-do-agente]
```

**O que o agente fará**:
1. Verificar se base de conhecimento existe na plataforma Runflow
2. Configurar RAG no agente com parâmetros otimizados
3. Criar searchPrompt apropriado para o contexto
4. Implementar exemplo de uso
5. Documentar configuração e ajustes recomendados
6. Sugerir otimizações de threshold e k

**Exemplo de uso**:
```
@runflow-specialist Configurar RAG para base "processos-juridicos" no agente ProcessAnalyzer. Threshold 0.2, k=3 resultados. Buscar quando usuário perguntar sobre processos, previdência, intimações. Criar searchPrompt apropriado
```

#### 2.5. Criar Workflow Completo

**Quando usar**: Orquestrar múltiplos passos com agentes e conectores

**Comando**:
```
@runflow-specialist Criar workflow "[nome]" que: [descrição passo a passo do fluxo]. Incluir: [agentes envolvidos, conectores necessários, passos condicionais se houver]
```

**O que o agente fará**:
1. Definir schema de entrada e saída com Zod
2. Criar agentes necessários para cada passo
3. Configurar connectors (dinâmicos, definidos no backend Runflow) via `createConnectorTool`/`connector`
4. Implementar workflow com passos sequenciais/paralelos
5. Adicionar passos condicionais se necessário
6. Criar exemplo de execução
7. Documentar fluxo completo

**Exemplo de uso**:
```
@runflow-specialist Criar workflow "lead-qualification" (via flow().step().build()) que: 1) qualifica lead com agente, 2) se nota >= 7 cria contato no HubSpot via connector, 3) cria deal, 4) notifica a equipe. Se nota < 7, apenas registra
```

#### 2.6. Orientar Próximos Passos

**Quando usar**: Após qualquer operação, pedir orientação sobre próximos passos

**Comando**:
```
@runflow-specialist Quais são os próximos passos após [o que foi feito]? Sugerir: comandos para testar, melhorias possíveis, integrações recomendadas, e próximas tarefas
```

**O que o agente fará**:
1. Analisar o que foi criado/modificado
2. Sugerir comandos de teste apropriados
3. Identificar melhorias e otimizações
4. Recomendar integrações úteis
5. Criar TODO list se necessário
6. Fornecer comandos específicos para próximas ações

**Exemplo de uso**:
```
@runflow-specialist Quais são os próximos passos após criar o agente ProcessAnalyzer? Sugerir comandos para testar, melhorias e próximas tarefas
```

#### 2.7. Fechar Tarefa / Finalizar Desenvolvimento

**Quando usar**: Quando uma feature está completa e precisa ser finalizada

**Comando**:
```
@runflow-specialist Finalizar desenvolvimento de [feature/tarefa]. Verificar: código completo, testes, documentação, validação, e criar resumo do que foi implementado
```

**O que o agente fará**:
1. Revisar código completo criado
2. Validar com linter
3. Verificar se testes estão implementados
4. Confirmar documentação atualizada
5. Criar resumo executivo do que foi feito
6. Sugerir comandos para deploy/teste final
7. Marcar tarefas como concluídas

**Exemplo de uso**:
```
@runflow-specialist Finalizar desenvolvimento do sistema multi-agente de suporte. Verificar tudo e criar resumo
```

### 3. Fluxo de Trabalho Recomendado

#### Para Novo Projeto Completo:
1. **Criar projeto**: `@runflow-specialist Criar novo projeto Runflow...`
2. **Criar agente inicial**: `@runflow-specialist Criar agente...`
3. **Configurar RAG**: `@runflow-specialist Configurar RAG...`
4. **Testar**: `@runflow-specialist Quais são os próximos passos...`
5. **Finalizar**: `@runflow-specialist Finalizar desenvolvimento...`

#### Para Adicionar Feature:
1. **Criar agente/feature**: `@runflow-specialist Criar [tipo]...`
2. **Integrar**: `@runflow-specialist Conectar [agentes/workflows]...`
3. **Orientar**: `@runflow-specialist Quais são os próximos passos...`
4. **Finalizar**: `@runflow-specialist Finalizar desenvolvimento...`

## Guidelines

### ✅ Boas Práticas

**Sempre**:
- ✅ Use o agente `@runflow-specialist` para todas as operações Runflow
- ✅ Seja específico e detalhado nas solicitações
- ✅ Mencione requisitos técnicos (RAG, memory, tools, etc.)
- ✅ Peça orientação de próximos passos após criar algo
- ✅ Finalize tarefas explicitamente para documentação

**Estrutura de Solicitações**:
- ✅ Inclua nome do projeto/agente/feature
- ✅ Descreva funcionalidades desejadas
- ✅ Especifique tools necessárias
- ✅ Mencione se precisa RAG, memory, workflows
- ✅ Indique integrações (connectors dinâmicos definidos no backend Runflow; ex. citado na doc: HubSpot)

**Desenvolvimento**:
- ✅ Teste incrementalmente após cada criação
- ✅ Valide código antes de continuar
- ✅ Documente decisões importantes
- ✅ Siga padrões do projeto (`main.ts`)

### ⚠️ Atenções Especiais

**Configuração**:
- ⚠️ Verifique `.runflow/rf.json` ou variáveis de ambiente antes de executar
- ⚠️ Confirme a versão do SDK no `package.json` (SSOT: `@runflow-ai/sdk` 1.6.2)
- ⚠️ `observability` aceita `'full' | 'standard' | 'minimal'` — escolha o preset pelo volume de trace desejado
- ⚠️ Node.js `>= 22` é obrigatório

**RAG**:
- ⚠️ Base de conhecimento deve existir na plataforma Runflow antes de configurar
- ⚠️ Ajuste threshold e k baseado no tipo de conteúdo
- ⚠️ Crie searchPrompt específico para o contexto

**Multi-Agent**:
- ⚠️ Defina claramente critérios de roteamento no supervisor
- ⚠️ Cada agente especializado deve ter tools e RAG apropriados
- ⚠️ Teste roteamento com diferentes tipos de input

**Workflows**:
- ⚠️ Defina schemas de entrada/saída claros com Zod
- ⚠️ Trate erros em cada passo do workflow
- ⚠️ Teste passos condicionais com diferentes cenários

### ❌ O Que Evitar

**Solicitações**:
- ❌ Não seja vago: "criar agente" → "criar agente X que faz Y com tools Z"
- ❌ Não pule etapas: configure RAG antes de usar no agente
- ❌ Não ignore validação: sempre teste após criar código

**Código**:
- ❌ Não use `createWorkflow(...)` em código novo — está deprecada; use `flow(...).step(...).build().execute(...)`
- ❌ Não preencha assinatura de API de memória — se a KB não cobre, marque "verificar com a IFTL"
- ❌ Não ignore tratamento de erros em tools nem a validação de `input.message` no `main()`

**Integração**:
- ❌ Não configure conectores sem credenciais válidas
- ❌ Não use RAG sem base de conhecimento criada
- ❌ Não conecte agentes sem definir roteamento claro

## Exemplos

### Exemplo 1: Criar Projeto Completo do Zero

**Input**:
```
/development/runflow-dev Criar projeto completo "assistente-juridico" para análise de processos. Incluir: agente principal, RAG com base "processos-juridicos", tool para buscar processos, memory para contexto
```

**Processo**:
1. Invoca `@runflow-specialist` para criar projeto
2. Agente cria estrutura completa
3. Invoca novamente para criar agente principal
4. Configura RAG
5. Cria tool de busca
6. Orienta próximos passos
7. Finaliza com resumo

**Output esperado**:
- Projeto criado com estrutura completa
- Agente configurado e funcionando
- RAG conectado
- Tool implementada
- README com instruções
- Comandos para testar

---

### Exemplo 2: Adicionar Sistema Multi-Agente

**Input**:
```
/development/runflow-dev Criar sistema multi-agente com supervisor que roteia para Sales, Support e Billing. Cada um com suas próprias tools e RAG
```

**Processo**:
1. Invoca `@runflow-specialist` para criar agentes especializados
2. Cria agente supervisor
3. Implementa roteamento
4. Configura RAG específico para cada agente
5. Cria exemplo de uso
6. Orienta testes e melhorias

**Output esperado**:
- 3 agentes especializados criados
- Supervisor com roteamento inteligente
- Função de roteamento implementada
- Exemplo completo de uso
- Documentação da arquitetura

---

### Exemplo 3: Configurar RAG e Orientar Próximos Passos

**Input**:
```
/development/runflow-dev Configurar RAG no agente ProcessAnalyzer com base "processos". Depois orientar próximos passos
```

**Processo**:
1. Invoca `@runflow-specialist` para configurar RAG
2. Ajusta parâmetros (threshold, k, searchPrompt)
3. Valida configuração
4. Invoca novamente para orientar próximos passos
5. Sugere comandos de teste e melhorias

**Output esperado**:
- RAG configurado no agente
- Parâmetros otimizados
- Lista de comandos para testar
- Sugestões de melhorias
- Próximas tarefas recomendadas

---

### Exemplo 4: Finalizar Feature Completa

**Input**:
```
/development/runflow-dev Finalizar desenvolvimento do sistema de suporte completo. Verificar tudo e criar resumo
```

**Processo**:
1. Invoca `@runflow-specialist` para revisar código
2. Valida com linter
3. Verifica testes
4. Confirma documentação
5. Cria resumo executivo
6. Sugere deploy/teste final

**Output esperado**:
- Código validado
- Testes verificados
- Documentação atualizada
- Resumo executivo criado
- Comandos para deploy/teste final
- Tarefas marcadas como concluídas

## Checklist de Validação

### Antes de Criar
- [ ] Definiu claramente o que quer criar
- [ ] Especificou requisitos técnicos (RAG, memory, tools)
- [ ] Mencionou integrações necessárias
- [ ] Verificou se projeto Runflow existe (para novos agentes)

### Durante Criação
- [ ] Agente `@runflow-specialist` foi invocado corretamente
- [ ] Solicitação foi específica e detalhada
- [ ] Código gerado segue padrões do projeto
- [ ] Validação foi executada

### Após Criação
- [ ] Código compila sem erros
- [ ] Linter não mostra problemas críticos
- [ ] Configuração `.runflow/rf.json` está correta
- [ ] Próximos passos foram orientados
- [ ] Documentação foi atualizada

### Para Finalizar
- [ ] Todo código foi revisado
- [ ] Testes foram implementados/verificados
- [ ] Documentação está completa
- [ ] Resumo executivo foi criado
- [ ] Comandos de teste/deploy foram fornecidos

## Comandos Relacionados

- `/meta/create-agent` - Criar agente Claude Code especializado
- `/development/runflow-dev` - Este comando (desenvolvimento Runflow)
- `/meta/create-knowledge-base` - Criar base de conhecimento

## Troubleshooting

### Problema: Agente não encontra base de conhecimento
**Solução**: Verifique se base existe na plataforma Runflow antes de configurar RAG

### Problema: Volume de traces alto demais
**Solução**: Ajuste `observability` para o preset `'minimal'` (ou use config granular). Os presets válidos são `'full' | 'standard' | 'minimal'`.

### Problema: Agente não segue padrões do projeto
**Solução**: Mencione explicitamente "seguir padrões de main.ts" na solicitação

### Problema: Roteamento multi-agente não funciona
**Solução**: Verifique critérios de roteamento no supervisor e teste com diferentes inputs

### Problema: Workflow falha em algum passo
**Solução**: Revise schemas de entrada/saída e tratamento de erros em cada passo

## FAQ

**P: Posso criar múltiplos agentes de uma vez?**  
R: Sim! Use solicitação detalhada listando todos os agentes e suas características.

**P: Como testar agentes criados?**  
R: Use `rf test` após criar, ou peça orientação: `@runflow-specialist Quais são os próximos passos...`

**P: Posso modificar código gerado pelo agente?**  
R: Sim! O agente cria código seguindo padrões, mas você pode ajustar conforme necessário.

**P: Como conectar agentes existentes?**  
R: Use: `@runflow-specialist Conectar agente [A] com agente [B] através de [método: supervisor/workflow]`

**P: RAG precisa ser configurado antes ou depois do agente?**  
R: Pode ser configurado junto na criação do agente, ou adicionado depois modificando o código.

---

## Resumo de Uso

**Sintaxe básica**:
```
/development/runflow-dev [sua solicitação detalhada para @runflow-specialist]
```

**Operações principais**:
1. Criar novo projeto Runflow
2. Criar novo agente
3. Conectar agentes (multi-agent)
4. Configurar RAG
5. Criar workflows
6. Orientar próximos passos
7. Finalizar desenvolvimento

**O que acontece**:
1. Comando invoca `@runflow-specialist` com sua solicitação
2. Agente consulta base de conhecimento e padrões do projeto
3. Cria/modifica código seguindo melhores práticas
4. Valida e orienta próximos passos
5. Finaliza com resumo quando solicitado

**Output**:
- Código Runflow seguindo padrões do projeto
- Configurações apropriadas
- Documentação atualizada
- Orientação de próximos passos
- Resumo executivo quando finalizar

---

**Exemplo de uso completo**:
```
/development/runflow-dev Criar projeto "assistente-juridico" com agente que analisa processos usando RAG na base "processos-juridicos"
```

