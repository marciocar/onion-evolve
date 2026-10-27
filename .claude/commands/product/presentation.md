---
name: presentation
description: |
  Ponte opcional para o serviço Gamma (externo, pago): apresentações via Gamma.app.
  Caminho local sem rede: /design:deck (HTML offline); pptx/docx via python-pptx/python-docx (receita provada na curadoria).
allowed-tools: Read Glob Grep

parameters:
  - name: topic
    description: Tema, task_id ou documento para a apresentação
    required: true
  - name: type
    description: Tipo (pitch/product/technical/business/report)
    required: false

category: product
tags:
  - presentation
  - gamma
  - content

version: "3.0.0"
updated: "2025-11-24"

related_commands:
  - /design/deck
  - /product/task
  - /docs/build-business-docs

related_agents:
  - presentation-orchestrator
  - storytelling-business-specialist
  - gamma-api-specialist
---

# 🎨 Criação de Apresentações

Wrapper para criação de apresentações via @presentation-orchestrator.

## 🎯 Objetivo

Criar apresentações profissionais pela **ponte opcional** do Gamma.app (externo, pago), de forma automatizada.

> 🔌 **Ponte opcional, não a capacidade de deck.** O Gamma é serviço **externo e pago**; pela
> doutrina [sem dependência de serviço externo](../../../docs/knowledge-base/concepts/no-external-service-dependency.md)
> (maestro, 2026-10-27), ele não é pré-requisito de apresentação. Sem `GAMMA_API_KEY` ou sem rede,
> o caminho local é o **`/design:deck`** (um HTML self-contained, offline) e, para pptx/docx,
> a geração em Python com `python-pptx`/`python-docx` (provada na curadoria (PR 137 de lá, mergeado em 2026-10-27; receita, sem gerador no core)).
> Sem a chave, este comando **para e devolve** esse caminho ao usuário; não gera nada sozinho.

## ⚡ Fluxo de Execução

### Passo 1: Identificar Tipo de Input

Analisar `{{topic}}` para determinar fonte:

| Pattern | Tipo | Ação |
|---------|------|------|
| `86adf...` | Task ID (ClickUp/Jira/Asana/Linear/Zoho/Zoho Projects) | Buscar dados via Task Manager |
| `docs/...` | Documento | Ler arquivo |
| Texto livre | Tema | Pesquisar codebase |

### Passo 2: Detectar Tipo de Apresentação

SE `{{type}}` fornecido → usar diretamente
SENÃO → inferir do contexto:

| Contexto | Tipo Inferido |
|----------|---------------|
| Investidores, funding | `pitch` |
| Novo recurso, release | `product` |
| Arquitetura, API | `technical` |
| Resultados, métricas | `business` |
| Status, progresso | `report` |

### Passo 3: Coletar Dados

#### Task (provider ativo)

```
Buscar a task via adapter do Task Manager ativo (getTaskManager().getTask) — REST API default:
- Nome e descrição
- Subtasks e progresso
- Comentários relevantes
- Métricas associadas
```

#### Documento

```
Ler arquivo e extrair:
- Título e resumo
- Pontos principais
- Dados e métricas
- Conclusões
```

#### Tema Geral

```
Pesquisar no codebase:
- Arquivos relacionados
- Documentação existente
- README e specs
```

### Passo 4: Estruturar Narrativa

Delegar para @storytelling-business-specialist:

```
Definir:
- Audiência-alvo
- Objetivo da apresentação
- Arco narrativo
- Pontos-chave (5-10)
```

### Passo 5: Gerar Apresentação

Invocar @presentation-orchestrator com:

```yaml
topic: [tema extraído]
type: [tipo detectado]
audience: [audiência]
key_points: [pontos-chave]
data: [dados coletados]
```

### Passo 6: Entregar Resultado

## 📤 Output Esperado

### Sucesso

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ APRESENTAÇÃO CRIADA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 [Título da Apresentação]

📋 Detalhes:
∟ Tipo: Product Launch
∟ Slides: 12
∟ Audiência: Stakeholders
∟ Fonte: Task #86adf8jj6

🎨 Assets:
∟ Gamma: https://gamma.app/docs/xxx
∟ PDF: apresentacao.pdf
∟ Outline: outline.md

🚀 Próximos Passos:
∟ Revisar conteúdo
∟ Ajustar design
∟ Compartilhar com equipe
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Tipos de Apresentação

| Tipo | Slides | Estrutura |
|------|--------|-----------|
| `pitch` | 10-15 | Problema → Solução → Mercado → Tração → Ask |
| `product` | 8-12 | Contexto → Feature → Demo → Benefícios → CTA |
| `technical` | 12-20 | Arquitetura → Componentes → Fluxos → API |
| `business` | 10-15 | Contexto → Resultados → Análise → Próximos |
| `report` | 5-10 | Status → Progresso → Bloqueios → Timeline |

## 🔗 Referências

- Agente principal: @presentation-orchestrator
- Storytelling: @storytelling-business-specialist  
- API técnica: @gamma-api-specialist

## ⚠️ Notas

- A ponte Gamma requer GAMMA_API_KEY; sem ela, use `/design:deck` (local, offline)
- Para config: `/meta/setup-integration gamma`
- Tempo médio: 2-5 minutos por apresentação
