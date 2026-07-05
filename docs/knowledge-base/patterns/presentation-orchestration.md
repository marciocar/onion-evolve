# Orquestração de Apresentações — contratos de delegação, templates e casos de uso

> **Versão**: 1.1.0 | **Última atualização**: 2026-07-04 | **Categoria**: Patterns
> Conhecimento de orquestração **extraído do agente `@presentation-orchestrator`** na rodada
> shed-ceremony de 2026-07-04. O agente mantém o grafo executável (7 fases) e cita esta KB para
> contratos de delegação, templates de prompt/config, matriz de erros e casos de uso.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2026-07-04 |
| **Última Atualização** | 2026-07-04 |
| **Fonte** | Extração de `.claude/agents/product/presentation-orchestrator.md` v3.0.0 |
| **KB irmã** | [gamma-app-api.md](../platforms/gamma-app-api.md) (spec técnica da API) |

---

## 1. Contratos de delegação (o que cada especialista recebe/entrega)

### `@storytelling-business-specialist` 🎭 [NARRATIVA]

```yaml
Quando chamar: início do processo · definição de audiência/objetivo · storyline · conteúdo de slides
Você fornece:  objetivo claro · audiência-alvo · dados brutos/contexto · nº de slides · tom
Você recebe:   estrutura narrativa completa · storyline (setup → conflito → resolução) ·
               conteúdo por slide (título + 2-4 bullets + mensagem-chave) · sugestões de visuais
Você valida:   coerência · adequação à audiência · quantidade de slides · qualidade
```

### `@mermaid-specialist` 📊 [CÓDIGO DE DIAGRAMAS]

```yaml
Quando chamar: após narrativa definida, para fluxos/arquiteturas/processos
Você fornece:  tipo de diagrama · conteúdo a visualizar · estilo · nome/caminho do .mmd
Você recebe:   código Mermaid VALIDADO (o agente declara: ele NÃO renderiza/exporta SVG —
               fronteira de design; ver mermaid-specialist.md §"O Que Você NÃO Faz")
Você valida:   sintaxe validada · até ~50 nós · salvo em .tmp/assets/<nome>.mmd
⚠️ CONVERSÃO A SVG É DO ORQUESTRADOR (passo determinístico próprio):
   npx -y @mermaid-js/mermaid-cli -i <nome>.mmd -o <nome>.svg
   Fallback se mmdc falhar (ex.: sem chromium): export manual via mermaid.live,
   ou prosseguir sem diagrama (imagens AI do Gamma). Gamma só aceita SVG.
```

> **Histórico deste contrato:** a versão 1.0.0 desta KB (herdada do agente v3.0.0) exigia
> "converter para SVG" do mermaid-specialist — contradizendo a fronteira declarada do agente.
> Gap descoberto pelo dogfood da shed-ceremony (claim `C_MERMAID_SVG_GAP` no KG) e corrigido
> aqui: quem converte é o pipeline, não o especialista de sintaxe.

### `@gamma-api-specialist` 🚀 [GERAÇÃO]

```yaml
Quando chamar: após narrativa E diagramas prontos · verificar status · obter links/export
Você fornece:  inputText completo · configurações (tema/formato/idioma) · assets SVG
Você recebe:   generationId · status (processing → completed) · links (view/edit/export)
Você valida:   status = completed · links funcionais · nº de slides · sem erros
Spec técnica:  ver KB gamma-app-api.md (payload, temas, rate limits, matriz de erros)
```

### Especialista do provider ativo 📋 [DADOS DE TAREFAS]

```yaml
Via adapter (REST API; MCP opcional):
  taskManager.getTask(id) · taskManager.searchTasks(query) · taskManager.addComment(id, text)
Delegar ao especialista (clickup→@clickup-specialist, jira→@jira-specialist, demais→@task-specialist)
quando: bulk · custom fields · formatação rica (ADF/Unicode) · automações avançadas
```

### `@product-agent` 📦 [ESTRATÉGIA]

```yaml
Quando chamar: alinhamento estratégico no início · validação de objetivos de negócio antes de publicar
```

## 2. Templates de prompt por fase

### FASE 2 — brief ao storytelling

```markdown
@storytelling-business-specialist
## Contexto
Crie estrutura narrativa para apresentação: **Título** [x] · **Audiência** [x] · **Objetivo** [x]
· **Tom** [x] · **Slides estimados** [N]
## Dados Disponíveis
[dados de tasks/projetos/métricas]
## Requisitos
- Estrutura setup → conflito → resolução · cada slide: título + 2-4 bullets + mensagem-chave
## Diagramas Planejados
[lista — para referência na narrativa]
Entregue: 1) storyline 2) estrutura de slides 3) mensagens-chave 4) onde inserir diagramas
```

### FASE 3 — pedido ao mermaid (código) + conversão do orquestrador

```markdown
@mermaid-specialist
Crie diagrama [tipo] mostrando [conteúdo]. **Contexto:** [objetivo]
**Requisitos:** tipo [flowchart/sequence/...] · elementos [lista] · estilo [x]
· salvar o CÓDIGO validado em .tmp/assets/[nome].mmd
Entregue: 1) código Mermaid validado 2) confirmação de compatibilidade (GitHub/Live)
```

```bash
# Conversão a SVG — passo do ORQUESTRADOR, após receber o .mmd:
npx -y @mermaid-js/mermaid-cli -i .tmp/assets/[nome].mmd -o .tmp/assets/[nome].svg
# falhou? → fallback: export manual via mermaid.live OU prosseguir sem diagrama (avisar maestro)
```

### FASE 4 — inputText consolidado (formato Gamma)

```markdown
# [Título]
## Sobre a Audiência
[descrição]
## Objetivo
[objetivo]
---
# Slide 1: [Título]
[bullets]
[IMAGEM: diagrama-1.svg - descrição]
---
[... demais slides ...]
---
# Slide Final: Call to Action
[CTA]
```

### FASE 4 — configuração Gamma (payload de referência)

```typescript
{ inputText, format: "presentation", themeName: "Oasis", numCards: N,
  textMode: "generate",
  textOptions: { amount: "medium", tone: "professional, inspiring", audience, language: "pt-BR" },
  imageOptions: { source: "aiGenerated", style: "professional, modern" },
  cardOptions: { dimensions: "16x9" } }
// Campos completos, temas válidos e constraints: KB gamma-app-api.md §1-2
```

### FASE 5 — pedido ao gamma-api-specialist

```markdown
@gamma-api-specialist
Gere apresentação: **inputText** [caminho .tmp/gamma-input-*.txt] · formato presentation ·
tema [x] · idioma pt-BR · slides [N] · tom [x] · audiência [x] · imagens AI 16x9
Assets: [SVGs e instruções]. Por favor: gere via API, monitore status, retorne generationId + link.
```

## 3. Matriz de erros do pipeline

```yaml
Erro em Narrativa:  revisar especificações · mais contexto ao storytelling · pedir ajuste específico
Erro em Diagrama:   verificar compatibilidade SVG · re-gerar · simplificar se complexo
Erro Gamma 400:     analisar campo problemático · voltar à fase relevante · corrigir e retentar
Erro Gamma 500:     aguardar e retentar (até 3×) · informar usuário se persistir
Tema inválido:      fallback "Oasis" e retentar
Timeout:            aguardar/verificar status · retentar após delay · avisar se >5min
```

### Limitações do pipeline

1. **Gamma**: máx 60-75 slides (por plano) · só SVG (não PNG/Mermaid cru) · tema deve existir · idioma ISO (`pt-BR`).
2. **Mermaid**: o especialista entrega código, não render — conversão é do pipeline via `mmdc`
   (exige chromium headless; pode falhar em ambientes mínimos → fallback mermaid.live) · conversão
   demora em diagramas complexos · nem todo tipo é suportado pelo Gamma.
3. **Narrativa**: pode exceder limite de chars do Gamma → condensar.

## 4. Casos de uso canônicos

| Caso | Pipeline |
|---|---|
| **Tema geral → apresentação** | coletar info (Grep/Read) → storytelling (pitch) → mermaid (arquitetura/roadmap SVG) → gamma → entregar |
| **Task → apresentação** | `taskManager.getTask` → storytelling (narrativa dos dados) → [mermaid se preciso] → gamma → `addComment` com link |
| **Doc técnica → apresentação** | `Read(doc)` → storytelling (adaptar p/ executivo) → mermaid (C4 SVG) → gamma formato `document` |
| **Métricas → apresentação** | coletar dados → storytelling data-driven → mermaid (gráficos SVG) → gamma com ênfase em dados |
| **Case study** | histórico (git/tasks/docs) → storytelling (desafio→solução→resultados) → mermaid (before/after) → gamma |

### Re-execução parcial (ajustes)

```yaml
Pedido de ajuste (ex.: "tom mais inspirador + slide novo"):
  preservar narrativa original → re-executar SÓ as fases afetadas (storytelling p/ tom/conteúdo;
  gamma p/ re-geração) → manter diagramas existentes
```

## 5. Templates de saída

### Status durante o processo

```markdown
## 🎬 Gerando Apresentação: [Título]
### ✅ Concluído      - [x] Fase 1: Estratégia · [x] Fase 2: Narrativa (N slides)
### ⏳ Em Andamento   - [ ] Fase 3: Diagramas (2/3)
### ⏸️ Pendente       - [ ] Fases 4-6
**Estimativa:** [tempo]
```

### Entrega final

```markdown
# 🎉 Apresentação Gerada com Sucesso!
**🌐 Visualizar:** [viewLink] · **✏️ Editar:** [editLink] · **📥 Export:** PDF/PPTX
| Slides | Formato | Tema | Idioma | Dimensões |
|---|---|---|---|---|
## 🎨 Assets: narrativa (.tmp/presentation-narrative-*.md) · SVGs (.tmp/assets/) · config (.tmp/gamma-*)
**Generation ID:** `[id]` · docs/presentations/generated/[timestamp]-[title].md
## 🚀 Próximos passos: revisar → ajustar no editor → exportar → compartilhar
```

## 6. Referências rápidas

```
.tmp/
├── presentation-narrative-[timestamp].md   # narrativa estruturada
├── gamma-input-[timestamp].txt             # inputText consolidado
├── gamma-config-[timestamp].json           # payload usado
└── assets/*.svg                            # diagramas
```

- Temas recomendados: Oasis (versátil) · Monochrome (minimalista) · Corporate (formal) · Bold (impacto) · Elegant (clean) — catálogo completo na [KB da API](../platforms/gamma-app-api.md) §2.
- Formatos: `presentation` (slides) · `document` (relatório) · `social` (posts).
- Registro de gerações: `docs/presentations/generated/`.

## 7. Relações

- Agente executor: `.claude/agents/product/presentation-orchestrator.md` (grafo de 7 fases que cita esta KB)
- Spec técnica da API: [gamma-app-api.md](../platforms/gamma-app-api.md)
- Orquestração paralela (quando etapas são independentes): `docs/knowledge-base/concepts/agent-orchestration.md`
