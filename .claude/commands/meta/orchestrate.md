---
name: orchestrate
description: |
  Orquestra subagentes em paralelo (fan-out/fan-in) sobre uma tarefa,
  via a ferramenta nativa Workflow. Use para auditorias, migrações, review e
  pesquisa amplas.
model: opus
category: meta
tags: [orchestrator-worker, orchestration, parallel, workflow]
version: "1.2.0"
updated: "2026-07-18"
allowed-tools: Read Write Grep Glob Bash(bash .claude/validation/kg-radar.sh*)
argument-hint: "<tarefa a paralelizar>"
related_commands:
  - /meta:create-agent
  - /meta:metaspec-validate
related_agents:
  - onion
  - metaspec-gate-keeper
---

# 🚀 Orquestração de Subagentes (fan-out / fan-in)

Ponto de entrada invocável para orquestrar **subagentes em
paralelo** sobre uma única tarefa ampla, usando a ferramenta nativa **Workflow**
do Claude Code. A coordenação roda em JavaScript e custa **0 tokens de modelo**.

## 🎯 Objetivo

Transformar uma tarefa que se decompõe em **N subtarefas independentes** em um
script Workflow que dispara os workers concorrentemente (fan-out), agrega os
resultados em um único veredito (fan-in) e, quando o risco justifica, submete a
saída a uma **verificação adversarial** antes de relatar.

A orquestração mora **sempre no nível principal** (este comando + a skill
`onion-orchestration`), nunca dentro de um subagente. Por
[architecture.md §4.2](../../../docs/meta-specs/architecture.md) a dependência
`agents/* → commands/*` é proibida — um agente sugere, não invoca comando. Logo
**não existe** nem deve ser criado um agente "worker-orchestrator".

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
  permanecem sequenciais; a orquestração paraleliza *dentro* de uma fase, não funde fases.

> Fan-out é **opt-in**, nunca default. Paralelizar trabalho dependente corrompe o
> resultado e desperdiça budget. Na dúvida sobre independência, mantenha serial.

## ⚡ Etapas

### Passo 0 — Health-check do substrato

Antes de tudo, confirme que a ferramenta nativa **Workflow** está disponível. Se não estiver, acione imediatamente o **Fallback serial** (abaixo) de forma determinística — não dependa de inferência. Degrade com aviso ao usuário em pt-BR.

### Passo 1 — Receber a tarefa

Capture `$ARGUMENTS` como a descrição da tarefa a paralelizar. Se vier vazia,
peça ao usuário o que paralelizar antes de prosseguir (não invente escopo).

```
/meta:orchestrate <tarefa a paralelizar>
```

Levante o conjunto de itens (arquivos, módulos, PRs, fontes) com `Glob`/`Grep`
quando o alvo for "para cada X" — esse é o material do fan-out.

### Passo 2 — Delegar seleção de padrão e elegibilidade à skill `onion-orchestration`

Acione a skill **`onion-orchestration`**, que é o cérebro operacional do fan-out. Ela:

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
- **Mutação (workers escrevem):** **particione por arquivos disjuntos** (sem
  corrida → **dispensa worktree**); use `isolation:'worktree'` **só** quando há
  sobreposição real ou branches independentes a fundir. Consolide numa **única
  branch** → fluxo normal. Playbook completo + `DiffSchema`: [agent-orchestration.md §7](../../../docs/knowledge-base/concepts/agent-orchestration.md).
- `budget` (teto de tokens) — **obrigatório** em qualquer `loop-until-done`.

Aplique **model tiering**: opus orquestra no nível principal; workers mecânicos
(extração, classificação, varredura) vão para haiku; raciocínio médio para
sonnet; reserve opus para orquestração e juízes adversariais críticos.
Tiers de worker (uso geral): **opus, sonnet, haiku**; `fable` só onde permitido
(disponibilidade restrita — ver `agent-orchestration.md` → "Disponibilidade
de modelos", fonte única). Nunca ofereça modelo de outro provider como worker. Tetos: até **16 subagentes concorrentes** e
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

```javascript
// MUTAÇÃO partição-primeiro (prova operacional): adicionar `version:` ao
// frontmatter de N comandos sem ele. Cada worker cuida de arquivos DISJUNTOS →
// sem corrida → SEM worktree. Consolida numa única branch → fluxo normal de PR.
const targets = glob(".claude/commands/**/*.md").filter(noVersionField);     // levantado no Passo 1
const partitions = chunk(targets, Math.ceil(targets.length / 8));            // ≤16 workers; aqui 8
const results = (await parallel(
  partitions.map((files) => agent(
    `Adicione \`version: "1.0.0"\` ao frontmatter SOMENTE destes arquivos (não toque em outros): ${files.join(", ")}. Retorne DiffSchema.`,
    { schema: DiffSchema, model: "haiku", budget: 50_000 }
  ))
)).filter(Boolean);                                                          // worker morto → null

// fan-in em JS (0 tokens): garantir partição limpa antes de consolidar
const paths = results.flatMap((r) => r.files.map((f) => f.path));
const collided = paths.filter((p, i) => paths.indexOf(p) !== i);
if (collided.length) return gateHumano(collided, results);                  // partição falhou → humano decide

// partição limpa → 1 branch de consolidação → entra no fluxo faseado normal:
//   /git:flow feature finish   ou   /engineer:pr  (via forge adapter)
return { branch: "orchestration/add-version-field", changed: paths.length };

// Variante worktree (só quando há sobreposição): trocar a chamada acima por
//   agent(..., { isolation: "worktree", schema: DiffSchema })
// e fundir as worktrees na branch de consolidação após a barreira (KB §7.4).
```

Mudanças amplas, irreversíveis ou de compliance ganham obrigatoriamente a etapa
de **verificação adversarial** (ou painel de juízes) sobre a saída agregada — um
agente independente tenta refutar o resultado antes de consolidá-lo. Mutação com
conflito de partição ou operação irreversível → **gate humano** (KB §7.5).

### Passo 4 — Consolidar (fan-in)

Todo fan-out converge em **um único resultado** — nunca N saídas soltas. Agregue,
deduplique e ranqueie no contexto principal, em JavaScript (custo 0 tokens). Use
o veredito adversarial para descartar falsos positivos e marcar lacunas.

### Passo 4.5 — `write(KG)`: persistir o conhecimento (o último ato, não opção)

Se a orquestração **produziu conhecimento** (pesquisa, auditoria, investigação, design) — e não só
uma mutação de código que já termina em branch/PR — o resultado consolidado é uma **obrigação de
`write(KG)`**, não uma opção:

1. **Persista a síntese no repo** — `docs/**/research/*.md` (ou local durável apropriado). **Nunca**
   deixe o resultado só no `/tmp/.../tasks/*.output` **efêmero** do harness: ele **drifta** e o SSOT
   nunca o vê.
2. **Materialize/atualize o `.kg.yaml`** dos achados/decisões via `/meta:kg` e valide com
   `bash .claude/validation/kg-radar.sh <arquivo>` (**exit 0**).

Fecha o ciclo `read(KG)→verify→act→write(KG)`
([knowledge-graph-sdaal.md](../../../docs/knowledge-base/concepts/knowledge-graph-sdaal.md)
§SSOT-as-runtime) — é o **bookend simétrico** do read(KG) já cabeado como passo 0 em
`warm-up`/`catch-up`/`engineer:work`. **Mecanismo, não conselho:** a skill `deep-research` é do
**harness**, despeja em `/tmp` e não persiste — a orquestração **Onion** é dona deste leg. O modo-de-falha
"advice-que-depende-de-lembrar" falhou empiricamente (3 pesquisas perderam o write até o próprio maestro —
sinal de campo 2026-07-18). Delega a `onion-orchestration` (passo 7).

### Passo 5 — Relatório

Apresente ao usuário, em pt-BR: padrão escolhido, nº de workers, tier de modelo
por etapa, budget gasto, o **resultado consolidado** e — quando a orquestração produziu conhecimento
— **onde o `write(KG)` persistiu** (path do `.md` + `.kg.yaml` + veredito do `kg-radar`).

## 🛟 Fallback — substrato Workflow indisponível

Se a ferramenta nativa **Workflow** não estiver disponível neste ambiente,
**degrade graciosamente** para **delegação sequencial a subagentes** com a
ferramenta `Agent`:

1. Avise o usuário em pt-BR que o substrato de orquestração não está disponível e que o
   trabalho seguirá serial (mais lento, sem paralelismo real).
2. Itere os itens chamando `Agent` um a um, mantendo o mesmo `schema` por item.
3. Consolide as saídas no contexto principal exatamente como no Passo 4.
4. Nunca finja paralelismo nem invente concorrência que o ambiente não oferece.

## 📤 Saída esperada

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 ORQUESTRAÇÃO EXECUTADA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

▶ Tarefa: <descrição>
◆ Run ID: <id-do-run>
◆ Padrão: fan-out-and-synthesize
◆ Workers: 12 (haiku) + 1 verificador adversarial (opus) · 0 descartados
◆ Budget gasto: ~X tokens
◆ Agent View: <referência do trace para inspeção>

∟ Resultado consolidado:
  ✅ [achado/decisão 1]
  ⚠️ [achado/decisão 2]
  ❌ [violação bloqueante, se houver]

∟ Verificação adversarial: [falsos positivos removidos / lacunas apontadas]
∟ write(KG): docs/**/research/<síntese>.md · <área>.kg.yaml (radar exit 0)  ← se produziu conhecimento
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 💡 Exemplos

```bash
# Auditoria de conformidade ampla (fan-out-and-synthesize + verificação adversarial)
/meta:orchestrate auditar conformidade de todos os agentes contra as meta-specs

# Migração mecânica multi-arquivo (mutação partição-primeiro → 1 branch; ver script no Passo 3)
/meta:orchestrate adicionar o campo `version` ao frontmatter de todos os comandos sem versão

# Pesquisa fan-out citada (fan-out-and-synthesize)
/meta:orchestrate pesquisar e comparar 5 fontes sobre padrões de orquestração de agentes em 2026
```

## 🔗 Referências

- KB de doutrina e mapeamento de padrões:
  `docs/knowledge-base/concepts/agent-orchestration.md`
- Skill operacional do fan-out: `onion-orchestration`
- Meta-spec de comandos (orquestração): `docs/meta-specs/commands.md`
- Meta-spec de arquitetura (§4.2 dependências): `docs/meta-specs/architecture.md`

## ⚠️ Notas

- A orquestração é **opt-in**, nunca default — fan-out é decisão explícita.
- Orquestre **sempre no nível principal** (comando/skill); nunca dentro de um
  subagente, e **não crie** um agente "worker-orchestrator".
- Mutação concorrente de arquivos exige `isolation:'worktree'`.
- `loop-until-done` sempre com `budget` — sem teto não há loop.
