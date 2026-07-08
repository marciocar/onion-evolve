---
name: consolidate-meetings
description: |
  Consolida múltiplas reuniões usando o Consolidador de Reuniões.
  Aceita pasta ou arquivos individuais para análise profunda, identificando divergências, convergências e insights estratégicos.
  Use para transformar múltiplas reuniões em conhecimento estratégico consolidado.
model: sonnet
allowed-tools: Read Write Bash(find *) Bash(ls *)

parameters:
  - name: source
    description: Pasta contendo reuniões ou arquivo(s) de reunião para consolidar
    required: true
  - name: focus
    description: Foco da consolidação (all|divergences|convergences|insights|gaps)
    required: false

category: product
tags:
  - meeting-consolidation
  - knowledge-synthesis
  - strategic-analysis
  - gap-analysis

version: "3.0.0"
updated: "2025-12-01"

related_commands:
  - /product/extract-meeting
  - /product/task
  - /docs/build-tech-docs

related_agents:
  - meeting-consolidator
  - extract-meeting-specialist
  - product-agent
---

# 🔄 Consolidar Reuniões

Comando para consolidar múltiplas reuniões usando o Consolidador de Reuniões (@meeting-consolidator).

## 🎯 Objetivo

Transformar múltiplas reuniões em conhecimento estratégico consolidado, identificando:
- **Divergências**: Conflitos e desalinhamentos entre participantes ou reuniões
- **Convergências**: Pontos de alinhamento e consenso
- **Insights Estratégicos**: Padrões não explícitos e conexões importantes
- **Pontos Não Ditos**: Assuntos que deveriam ter sido mencionados mas não foram
- **Pontos Não Compreendidos**: Decisões ou ideias que parecem não ter sido entendidas

## ⚡ Fluxo de Execução

### Passo 1: Detectar Tipo de Entrada

Carregue o fragmento `common:prompts:consolidation-prep` (steps de preparação compartilhados — Passo 1) e execute a detecção de tipo de entrada conforme descrito nele.

Complemento específico para reuniões:

**Se for pasta:**
- Filtrar por extensões de reunião: `.md`, `.txt`, `.transcript`, `.json`
- Padrões de nome relevantes: `*meeting*`, `*reunion*`, `*transcript*`, `*extract*`
- Ordenar por data (se disponível no nome ou conteúdo)

**Se for arquivo(s):**
- Validar que são arquivos de reunião válidos

### Passo 2: Coletar Arquivos de Reunião

**Cenário A: Pasta Fornecida**

```markdown
1. Listar arquivos na pasta
2. Filtrar arquivos de reunião:
   - Extensões: .md, .txt, .transcript, .json
   - Padrões de nome: *meeting*, *reunion*, *transcript*, *extract*
3. Ordenar por data (se disponível)
4. Validar que são arquivos de reunião válidos
5. Coletar lista de arquivos para processar
```

**Cenário B: Arquivo(s) Fornecido(s)**

```markdown
1. Validar que arquivo(s) existe(m)
2. Verificar se são arquivos de reunião válidos
3. Coletar lista de arquivos para processar
```

### Passo 3: Preparar Contexto para o Consolidador

Carregue o fragmento `common:prompts:consolidation-prep` (steps de preparação compartilhados — Passo 3) e monte o contexto estruturado conforme descrito nele.

Metadados adicionais específicos para reuniões:
- Data da reunião (se disponível)
- Participantes (se disponível)
- Tipo de reunião (se identificável)
- Duração (se disponível)

### Passo 4: Invocar o Consolidador de Reuniões

Invocar @meeting-consolidator com o contexto preparado:

```markdown
@meeting-consolidator

Consolidar as seguintes reuniões:

**Arquivos a Consolidar:**
{{lista_de_arquivos_com_paths}}

**Foco da Análise:**
{{focus}}

**Metadados:**
{{metadados_estruturados}}

Por favor, execute consolidação completa incluindo:
1. Classificação e categorização por tema
2. Identificação de divergências entre participantes/reuniões
3. Identificação de convergências e pontos de alinhamento
4. Geração de insights estratégicos não explícitos
5. Identificação de pontos não ditos ou não compreendidos
6. Principais pontos de atenção
7. Recomendações estratégicas

Gere output completo e estruturado conforme template de consolidação.
```

**Se foco específico for fornecido:**

```markdown
@meeting-consolidator

{{foco_especifico}} das seguintes reuniões:

**Arquivos:**
{{lista_de_arquivos}}

**Foco:**
- Se "divergences": Identificar apenas divergências e conflitos
- Se "convergences": Identificar apenas convergências e alinhamentos
- Se "insights": Gerar apenas insights estratégicos
- Se "gaps": Identificar apenas pontos não ditos/compreendidos
```

### Passo 5: Validar Output do Consolidador

Verificar se a consolidação criada contém:

- ✅ **Classificação por Tema**: Temas agrupados e categorizados
- ✅ **Divergências**: Conflitos e desalinhamentos identificados
- ✅ **Convergências**: Pontos de alinhamento identificados
- ✅ **Insights Estratégicos**: Padrões e conexões revelados
- ✅ **Pontos Não Ditos/Compreendidos**: Sessão exclusiva criada
- ✅ **Principais Pontos de Atenção**: Priorizados por criticidade
- ✅ **Recomendações Estratégicas**: Ações sugeridas

### Passo 6: Salvar Consolidação

Salvar a consolidação criada em arquivo estruturado:

```markdown
# Salvar em: docs/meet/consolidation-[data]-[tema].md

# Consolidação de Reuniões: [Tema Principal]

**Data da Consolidação**: {{data_atual}}
**Reuniões Consolidadas**: {{numero}} reuniões
**Período**: {{data_inicial}} - {{data_final}}
**Participantes**: {{lista_participantes}}

{{conteudo_da_consolidacao}}
```

## 📤 Output Esperado

O comando deve produzir:

1. **Consolidação Completa** seguindo template estruturado
2. **Classificação por Tema** com categorização clara
3. **Divergências Identificadas** com recomendações
4. **Convergências Identificadas** para capitalizar
5. **Insights Estratégicos** não explícitos
6. **Sessão Exclusiva** com pontos não ditos/compreendidos
7. **Principais Pontos de Atenção** priorizados
8. **Recomendações Estratégicas** acionáveis

## 🔗 Referências

- **Agente**: @meeting-consolidator
- **Comando Relacionado**: /product/extract-meeting (extração estruturada)
- **Knowledge Base**: `docs/knowledge-base/concepts/meeting-transcription-to-knowledge-base.md`

## ⚠️ Notas Importantes

### Regras Críticas

1. **Sempre validar arquivos** antes de processar
2. **Sempre coletar metadados** quando disponíveis
3. **Sempre identificar foco** se especificado
4. **Sempre salvar output** em local apropriado
5. **Sempre incluir sessão exclusiva** com pontos não ditos/compreendidos

### Quando Usar Este Comando

Use `/product/consolidate-meetings` quando:

- Há múltiplas reuniões sobre o mesmo tema
- Necessita identificar padrões entre reuniões
- Quer descobrir divergências ou convergências
- Precisa de insights estratégicos não explícitos
- Quer identificar pontos não ditos ou não compreendidos
- Necessita visão consolidada de múltiplas discussões

### Exemplos de Uso

```bash
# Consolidar todas as reuniões de uma pasta
/product/consolidate-meetings "docs/meet/gamification-meetings/"

# Consolidar arquivos específicos
/product/consolidate-meetings "docs/meet/meeting-1.md docs/meet/meeting-2.md docs/meet/meeting-3.md"

# Foco em divergências
/product/consolidate-meetings "docs/meet/gamification-meetings/" --focus="divergences"

# Foco em insights estratégicos
/product/consolidate-meetings "docs/meet/strategic-planning/" --focus="insights"

# Foco em pontos não ditos/compreendidos
/product/consolidate-meetings "docs/meet/audio-recording-dec-1-9-38-extract.md" --focus="gaps"
```

### Focos Disponíveis

| Foco | Descrição |
|------|-----------|
| `all` | Consolidação completa (padrão) |
| `divergences` | Apenas divergências e conflitos |
| `convergences` | Apenas convergências e alinhamentos |
| `insights` | Apenas insights estratégicos |
| `gaps` | Apenas pontos não ditos/compreendidos |

## 🎯 Checklist de Validação

Antes de considerar a consolidação completa, verificar:

- [ ] Arquivos de reunião identificados e validados
- [ ] Metadados coletados quando disponíveis
- [ ] Classificação por tema realizada
- [ ] Divergências identificadas
- [ ] Convergências identificadas
- [ ] Insights estratégicos gerados
- [ ] Pontos não ditos/compreendidos identificados
- [ ] Principais pontos de atenção priorizados
- [ ] Recomendações estratégicas fornecidas
- [ ] Output salvo em local apropriado

---

**Última Atualização**: 2025-12-01  
**Versão**: 3.0.0  
**Agente Relacionado**: @meeting-consolidator

