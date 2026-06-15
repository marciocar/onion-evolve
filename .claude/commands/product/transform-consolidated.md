---
name: transform-consolidated
description: |
  Transforma documentos consolidados (reuniões ou documentos) em contexto estruturado para criação de tasks.
  Interage com usuário de forma padronizada para extrair ações acionáveis e gerar contexto para /product/collect ou /product/task.
model: sonnet
allowed-tools: Read Write Bash(find *) Bash(mkdir *) Bash(ls *)

parameters:
  - name: source
    description: Arquivo consolidado (de consolidate-meetings ou consolidate-documents) ou pasta contendo consolidações
    required: true
  - name: mode
    description: Modo de transformação (interactive|auto|tasks-only|context-only)
    required: false
  - name: output_format
    description: Formato de saída (tasks|context|both)
    required: false

category: product
tags:
  - knowledge-transformation
  - task-generation
  - consolidated-processing
  - interactive-refinement
  - product-workflow

version: "3.0.0"
updated: "2025-12-02"

related_commands:
  - /product/consolidate-meetings
  - /docs/consolidate-documents
  - /product/collect
  - /product/task
  - /product/estimate

related_agents:
  - product-agent
  - meeting-consolidator
  - extract-meeting-specialist
---

# 🔄 Transformar Documentos Consolidados

Transforma conhecimento consolidado (de reuniões ou documentos) em contexto
estruturado e tasks acionáveis, preenchendo o gap entre consolidação e criação de tasks.

> **Convenções de comunicação Claude Code, nomenclatura e formatação:** seguir a skill `onion-patterns`.
> **Frameworks de transformação (prompt de extração, template de validação, templates de output, modos, persistência):** ver KB [`docs/knowledge-base/concepts/consolidated-to-tasks-patterns.md`](../../../docs/knowledge-base/concepts/consolidated-to-tasks-patterns.md).

## 🎯 Objetivo

1. **Ler** documentos consolidados (output de `/product/consolidate-meetings` ou `/docs/consolidate-documents`)
2. **Interagir** com o usuário para refinar e priorizar
3. **Transformar** o conhecimento em contexto estruturado
4. **Gerar** contexto pronto para `/product/collect` ou `/product/task`

## ⚡ Fluxo de Execução

### Fase 1 — Detecção e Carregamento

```bash
if [ -f "$source" ]; then
  CONSOLIDATED_FILE="$source"            # arquivo único
elif [ -d "$source" ]; then
  CONSOLIDATED_FILES=$(find "$source" -name "*consolidation*.md" -o -name "*consolidated*.md")
  # se múltiplos, perguntar qual usar
else
  echo "❌ Source deve ser arquivo ou pasta"; exit 1
fi
```

Validar estrutura: confirmar seções esperadas (Tarefas, Decisões, Gaps, Insights),
identificar tipo (reuniões vs documentos) e extrair metadados (data, participantes, temas).

### Fase 2 — Análise Automática (sempre executada)

Independente do modo, invocar `@product-agent` com o **Framework de Extração Acionável**
do KB para extrair tarefas, decisões, gaps, insights e dependências em YAML.
Salvar em `.claude/sessions/consolidated-transform/analysis-<timestamp>.yaml`.

### Fase 3 — Validação Interativa (modo `interactive`, obrigatória)

Apresentar a análise usando o **Template de Validação Interativa** do KB e coletar as
aprovações/ajustes do usuário (IDs aprovados, prioridades, owners, deadlines,
dependências, quebra em subtasks) por bloco, encerrando com a confirmação final.

### Fase 4 — Modos de Processamento

Aplicar o modo solicitado (`interactive` padrão, `auto`, `tasks-only`, `context-only`)
conforme a tabela de modos e heurísticas do KB.

### Fase 5 — Gerar Output Final

Com base nos elementos validados (ou na análise automática no modo `auto`) e no
`output_format`, gerar os artefatos usando os **Templates de Output** do KB:

- **Contexto estruturado** (`context`/`both`) → `context-<ts>.md`
- **Lista de tasks + comandos prontos** (`tasks`/`both`) → `tasks-<ts>.yaml`, `commands-<ts>.sh`
- Para cada tarefa aprovada, montar invocação de `/product/collect` ou `/product/task`
  com contexto completo e referência ao documento de origem.

```bash
OUTPUT_DIR=".claude/sessions/consolidated-transform/"; mkdir -p "$OUTPUT_DIR"
```

## 📤 Outputs Esperados

- **Contexto estruturado**: tarefas priorizadas, decisões acionáveis, gaps por impacto, insights, dependências e matriz de priorização.
- **Lista de tasks** (opcional): YAML pronto para criação, com metadados e referência ao original.
- **Comandos prontos** (opcional): chamadas `/product/collect` e `/product/task` prontas para execução.

## 🚀 Invocação

```bash
# Após consolidar reuniões (interativo)
/product/transform-consolidated "docs/meet/consolidation-2025-12-02-sprint-planning.md" --mode=interactive

# Após consolidar documentos (auto, ambos os outputs)
/product/transform-consolidated "docs/consolidated/business-context/" --mode=auto --output_format=both

# Lote sem interação, só tasks
/product/transform-consolidated "docs/consolidated/" --mode=auto --output_format=tasks-only

# Apenas contexto, sem tasks
/product/transform-consolidated "docs/meet/consolidation-*.md" --mode=context-only
```

## ⚙️ Parâmetros

- **`source`**: arquivo consolidado `.md`, pasta com consolidações, ou múltiplos arquivos.
- **`mode`**: `interactive` (padrão) · `auto` · `tasks-only` · `context-only` — ver tabela no KB.
- **`output_format`**: `tasks` · `context` · `both` (padrão).

## 🔗 Relacionamentos

**Antes:** `/product/consolidate-meetings`, `/docs/consolidate-documents`
**Depois:** `/product/collect`, `/product/task`, `/product/estimate`, `/product/refine`

Tasks criadas são sincronizadas automaticamente com o Task Manager configurado,
preservando o contexto e a referência ao documento consolidado de origem.

---

**Versão:** 3.0.0 · **Última atualização:** 2025-12-02
