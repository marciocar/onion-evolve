---
name: fleet
description: |
  Orquestra uma frota de agentes em paralelo (fan-out/fan-in) sobre uma tarefa,
  via a ferramenta nativa Workflow. Use para auditorias, migrações, review e
  pesquisa amplas.
model: opus
category: meta
tags: [fleet, orchestration, parallel, workflow]
version: "1.0.0"
updated: "2026-06-13"
allowed-tools: Read Grep Glob
argument-hint: "<tarefa a paralelizar>"
related_commands:
  - /meta:create-agent
  - /meta:metaspec-validate
related_agents:
  - onion
  - metaspec-gate-keeper
---

# 🚀 Frota de Agentes (fan-out / fan-in)

Ponto de entrada invocável para orquestrar uma **frota de subagentes em
paralelo** sobre uma única tarefa ampla, usando a ferramenta nativa **Workflow**
do Claude Code. A coordenação roda em JavaScript e custa **0 tokens de modelo**.

## 🎯 Objetivo

Transformar uma tarefa que se decompõe em **N subtarefas independentes** em um
script Workflow que dispara os workers concorrentemente (fan-out), agrega os
resultados em um único veredito (fan-in) e, quando o risco justifica, submete a
saída a uma **verificação adversarial** antes de relatar.

A orquestração mora **sempre no nível principal** (este comando + a skill
`onion-fleet`), nunca dentro de um subagente. Por
[architecture.md §4.2](../../../docs/meta-specs/architecture.md) a dependência
`agents/* → commands/*` é proibida — um agente sugere, não invoca comando. Logo
**não existe** nem deve ser criado um agente "fleet-orchestrator".

## 🟢 Quando usar (e quando NÃO)

**Use quando** o trabalho tem *independência real* entre as subtarefas:

- Auditoria ampla — "para cada agente/comando/módulo, valide contra a régua X".
- Migração mecânica — aplicar a mesma transformação a muitos arquivos.
- Review multi-dimensão — segurança, performance e estilo do mesmo diff em paralelo.
- Pesquisa fan-out — varrer N fontes e sintetizar um relatório citado.
- Padrão decompor → delegar → sintetizar / verificar.

**NÃO use quando** o trabalho é **serial dependente**:

- Há dependência de ordem ou estado compartilhado mutável entre as etapas.
- Cada passo precisa ler a saída do anterior (pipeline humano, não fan-out).
- São os workflows faseados canônicos `engineer/*` e `product/*` — eles
  permanecem sequenciais; a frota paraleliza *dentro* de uma fase, não funde fases.

> Fan-out é **opt-in**, nunca default. Paralelizar trabalho dependente corrompe o
> resultado e desperdiça budget. Na dúvida sobre independência, mantenha serial.

## ⚡ Etapas

### Passo 1 — Receber a tarefa

Capture `$ARGUMENTS` como a descrição da tarefa a paralelizar. Se vier vazia,
peça ao usuário o que paralelizar antes de prosseguir (não invente escopo).

```
/meta:fleet <tarefa a paralelizar>
```

Levante o conjunto de itens (arquivos, módulos, PRs, fontes) com `Glob`/`Grep`
quando o alvo for "para cada X" — esse é o material do fan-out.

### Passo 2 — Delegar seleção de padrão e elegibilidade à skill `onion-fleet`

Acione a skill **`onion-fleet`**, que é o cérebro operacional do fan-out. Ela:

1. Confirma a **elegibilidade** (independência real entre subtarefas).
2. Escolhe **1 dos 6 padrões canônicos** conforme a forma do trabalho:

| Padrão canônico | Primitiva | Forma |
|---|---|---|
| classify-and-act | `agent()` → `parallel()` | classifica, depois roteia branches |
| fan-out-and-synthesize | `parallel()` + fan-in | barreira, depois síntese |
| adversarial verification | `parallel()` (gerador + verificador) | gera e contesta |
| generate-and-filter | `parallel()` → filtro JS | gera muitos, retém poucos |
| tournament | `parallel()` em rodadas | eliminação par-a-par |
| loop-until-done | `loop` budget-gated | refina até convergir |

Se a skill concluir que **não há independência**, ela recomenda manter serial —
respeite e encerre o fan-out.

### Passo 3 — Autorar e disparar o Workflow (fan-out)

Com o padrão escolhido, autore um script da ferramenta **Workflow**. Use:

- `parallel([thunks])` quando precisa de **barreira** (todos terminam antes do fan-in).
- `pipeline(items, stage1, stage2, ...)` quando o fluxo corre **sem barreira**
  entre itens (estágios encadeados por item).
- `schema` por worker para **output estruturado e validado**.
- `isolation:'worktree'` quando múltiplos workers **escrevem** no repositório
  (evita corrida de escrita; consolide os diffs no fan-in).
- `budget` (teto de tokens) — **obrigatório** em qualquer `loop-until-done`.

Aplique **model tiering**: Opus orquestra no nível principal; workers mecânicos
(extração, classificação, varredura) vão para Haiku 4.5; raciocínio médio para
Sonnet 4.6; reserve Opus 4.8 para orquestração e juízes adversariais críticos.
Lineup válido: **Fable 5, Opus 4.8, Sonnet 4.6, Haiku 4.5** — nunca ofereça
modelo de outro provider como worker. Tetos: até **16 subagentes concorrentes** e
**1.000 agregados** por run.

```javascript
// fan-out-and-synthesize: auditar N arquivos em paralelo (com barreira)
const findings = await parallel(
  files.map((f) => agent(
    `Audite ${f} contra a régua. Liste violações com evidência arquivo:linha.`,
    { schema: FindingSchema, model: "haiku" }
  ))
);

// verificação adversarial sobre a saída agregada (alto risco)
const verdict = await agent(
  `Conteste estas violações. Aponte falsos positivos e lacunas: ${JSON.stringify(findings)}`,
  { schema: VerdictSchema, model: "opus" }
);

// fan-in no contexto principal (0 tokens): consolida num resultado único
return consolidate(findings, verdict);
```

```javascript
// pipeline: sem barreira entre itens — cada item flui estágio → estágio
await pipeline(
  modules,
  (m) => agent(`Extraia a API pública de ${m}.`, { schema: ApiSchema, model: "haiku" }),
  (api) => agent(`Gere os testes de contrato para esta API.`, { schema: TestSchema, model: "sonnet" })
);
```

Mudanças amplas, irreversíveis ou de compliance ganham obrigatoriamente a etapa
de **verificação adversarial** (ou painel de juízes) sobre a saída agregada — um
agente independente tenta refutar o resultado antes de consolidá-lo.

### Passo 4 — Consolidar (fan-in)

Todo fan-out converge em **um único resultado** — nunca N saídas soltas. Agregue,
deduplique e ranqueie no contexto principal, em JavaScript (custo 0 tokens). Use
o veredito adversarial para descartar falsos positivos e marcar lacunas.

### Passo 5 — Relatório

Apresente ao usuário, em pt-BR: padrão escolhido, nº de workers, tier de modelo
por etapa, budget gasto e o **resultado consolidado**.

## 🛟 Fallback — substrato Workflow indisponível

Se a ferramenta nativa **Workflow** não estiver disponível neste ambiente,
**degrade graciosamente** para **delegação sequencial a subagentes** com a
ferramenta `Agent`:

1. Avise o usuário em pt-BR que o substrato de frota não está disponível e que o
   trabalho seguirá serial (mais lento, sem paralelismo real).
2. Itere os itens chamando `Agent` um a um, mantendo o mesmo `schema` por item.
3. Consolide as saídas no contexto principal exatamente como no Passo 4.
4. Nunca finja paralelismo nem invente concorrência que o ambiente não oferece.

## 📤 Saída esperada

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 FROTA EXECUTADA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

▶ Tarefa: <descrição>
◆ Padrão: fan-out-and-synthesize
◆ Workers: 12 (haiku) + 1 verificador adversarial (opus)
◆ Budget gasto: ~X tokens

∟ Resultado consolidado:
  ✅ [achado/decisão 1]
  ⚠️ [achado/decisão 2]
  ❌ [violação bloqueante, se houver]

∟ Verificação adversarial: [falsos positivos removidos / lacunas apontadas]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 💡 Exemplos

```bash
# Auditoria de conformidade ampla (fan-out-and-synthesize + verificação adversarial)
/meta:fleet auditar conformidade de todos os agentes contra as meta-specs

# Migração mecânica multi-arquivo (parallel + isolation:'worktree')
/meta:fleet adicionar o campo `version` ao frontmatter de todos os comandos sem versão

# Pesquisa fan-out citada (fan-out-and-synthesize)
/meta:fleet pesquisar e comparar 5 fontes sobre padrões de orquestração de agentes em 2026
```

## 🔗 Referências

- KB de doutrina e mapeamento de padrões:
  `docs/knowledge-base/concepts/agent-fleet-orchestration.md`
- Skill operacional do fan-out: `onion-fleet`
- Meta-spec de comandos (orquestração em fleet): `docs/meta-specs/commands.md`
- Meta-spec de arquitetura (§4.2 dependências): `docs/meta-specs/architecture.md`

## ⚠️ Notas

- Fleet é **opt-in**, nunca default — fan-out é decisão explícita.
- Orquestre **sempre no nível principal** (comando/skill); nunca dentro de um
  subagente, e **não crie** um agente "fleet-orchestrator".
- Mutação concorrente de arquivos exige `isolation:'worktree'`.
- `loop-until-done` sempre com `budget` — sem teto não há loop.
