# 🎲 Estimativa de Story Points — Invocação Compartilhada

> Fragmento canônico do **protocolo de estimativa** — como invocar o
> `@story-points-framework-specialist` e ler o seu output estruturado. Reutilizável
> por comandos que **PRODUZEM** estimativa (`product/estimate` — a aplicação
> interativa completa; `product/task` e `product/feature` — estimativa embutida no
> fluxo de criação). Citar como `common:prompts:story-points-estimation`.
>
> **Distinto do gate** (`common:prompts:story-points-gate`): o *gate* verifica se
> uma task **já tem** estimativa e reage (oferece estimar / alerta épico); este
> fragmento é o **como PRODUZIR** a estimativa. O gate CHAMA este protocolo.
>
> Framework completo: `docs/knowledge-base/frameworks/framework-story-points.md`.

## Pré-requisito

Carregar a base de conhecimento antes de estimar:

```
Read docs/knowledge-base/frameworks/framework-story-points.md
```

(E, se disponíveis, conferir métricas históricas do time — velocity, accuracy,
reference stories — que calibram a estimativa.)

## Invocação do especialista

Delegar ao `@story-points-framework-specialist`, passando:

- **descrição** do item (task / feature / subtask);
- **subtasks / action items** já decompostos, se houver;
- **senioridade** do responsável, se conhecida;
- **metodologia** sugerida (ou deixar em auto-detect).

Pedir o processo completo: análise de domínio → seleção metodológica → checklist
apropriado → contextualização por senioridade → validação final. O output segue o
template estruturado do agente.

> **Red flags** (requisitos nebulosos, tecnologia desconhecida, dependência não
> confirmada, impacto crítico sem rollback) → solicitar clarificação **antes** de
> estimar; não estimar no escuro.

## Output estruturado esperado

O agente retorna **story points**, **análise** (complexidade · risco · incerteza)
e **recomendações**. Referência visual:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 ANÁLISE DE STORY POINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ITEM: [nome]
🎲 STORY POINTS: [X]
⚡ ANÁLISE: Complexidade [.] | Risco [.] | Incerteza [.]
💡 RECOMENDAÇÕES: [.]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

> A formatação do comentário no provider ativo é resolvida pelo adapter — Unicode
> no ClickUp (via `common:prompts:clickup-patterns`), ADF no Jira, Markdown no
> Linear. Não re-soletrar o template por provider aqui.

## Validação de consistência (obrigatória)

- **Soma das subtasks > task principal** → ajustar a principal para a soma.
- **> 13 pontos → ÉPICO**: alertar e oferecer quebrar (`/product/refine`); sem
  confirmação explícita do usuário, **parar**. (Mesma fronteira que o gate
  `common:prompts:story-points-gate` aplica na entrada do desenvolvimento.)
- **1–13** → estimativa válida; seguir.
