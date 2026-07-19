---
name: kb-freshness
description: |
  Audita cada KB em docs/knowledge-base/ contra o fluxo ATUAL do Sistema Onion
  (ferramenta Workflow nativa, padrões canônicos 2026, lineup de modelos Claude
  vigente referenciado por tier (opus/sonnet/haiku/fable) ou "mais recente"). Usa fan-out-and-synthesize
  via onion-orchestration: um worker por KB (ou por diretório), retornando veredito
  CURRENT/STALE/HISTORICAL + pontos desatualizados + direção de atualização.
  Consolida tudo num relatório priorizado de ações de refresh.
model: opus
category: meta
tags: [kb, freshness, orchestration, validation]
version: "1.0.0"
updated: "2026-06-13"
allowed-tools: Read Grep Glob
argument-hint: "[caminho de KB específica | vazio = todas]"
related_commands:
  - /meta:orchestrate
  - /meta:create-knowledge-base
related_agents:
  - onion
  - metaspec-gate-keeper
---

# /meta:kb-freshness — Auditoria de Frescor de Knowledge Bases

## Objetivo

Garantir que nenhuma KB em `docs/knowledge-base/` acumule **vaporware, modelos
extintos ou padrões abandonados**. O comando executa um fan-out de auditores —
um worker por arquivo — cada um comparando o conteúdo da KB contra a **régua de
frescor canônica 2026** (detalhada abaixo). Ao final, o fan-in sintetiza um
relatório priorizado com veredito, pontos desatualizados e direção de
atualização para cada KB.

A premissa de frescor é simples: **uma KB que ensina o que não existe mais ou
omite o que existe hoje é pior que nenhuma KB** — ela induz agentes e humanos ao
erro. A obrigação de manter KBs vivas está documentada em
`docs/knowledge-base/concepts/agent-orchestration.md` e no comando
`/meta:create-knowledge-base` (seção "Manter viva: revisar quando o tema
evolui").

---

## Quando usar

- Após qualquer mudança arquitetural no Sistema Onion (novo comando, agente
  deprecado, mudança de provider).
- Quando o Claude Code lança novas primitivas (ex.: a ferramenta Workflow em
  mai/2026) que podem tornar seções de KBs obsoletas.
- Em auditorias periódicas de saúde documental (ex.: junto com `/docs:docs-health`).
- Antes de criar uma nova KB — para saber se já existe uma desatualizada sobre o
  tema que vale atualizar em vez de duplicar.
- Sempre que uma KB específica for citada num PR e houver dúvida sobre sua
  aderência ao estado atual.

---

## Régua de Frescor Canônica (2026)

Cada worker avalia a KB contra os itens abaixo. **Só itens marcados (!) são GATES**
— a falha neles eleva o veredito para STALE/HISTORICAL. Itens **sem (!)** (4 e 7) são
**pontos menores**: registre em `stale_excerpts`, mas **não** rebaixe o veredito por
eles sozinhos — uma KB que só falha em item menor permanece **CURRENT**.

| # | Item | Critério |
|---|------|----------|
| 1 | **Lineup de modelos (!)** | Usa o lineup Claude vigente referenciado por tier (opus/sonnet/haiku/fable) ou "mais recente" — não fixa versão exata como única referência. FALHA = famílias retiradas (Claude 3.x, claude-v1/v2) ou modelo de outro provider (GPT-*, Gemini, Llama) citado como modelo Claude. |
| 2 | **Ferramenta Workflow (!)** | Se a KB trata de orquestração de agentes, orquestração de subagentes ou paralelismo: deve referenciar a ferramenta nativa `Workflow` (research preview mai/2026). Ausência = STALE. |
| 3 | **Itens formalmente abandonados (!)** | Não contém referências positivas a `.onion/`, CLI standalone, plano v4.0 FASES 5-9, multi-IDE — itens abandonados em 2026-05-18. |
| 4 | **Plataforma única** | Afirma Claude Code como plataforma única (não "qualquer IDE"). |
| 5 | **Task Manager Abstraction (!)** | Se menciona task manager: cita a camada plugável (Jira/ClickUp/Asana/Linear) via `TASK_MANAGER_PROVIDER`. Referência a provider único hardcoded = STALE. |
| 6 | **Data de atualização (!)** | Campo `Última Atualização` presente e ≤ 18 meses atrás (relativo a 2026-06-13). Ausente ou > 18 meses = STALE. |
| 7 | **Fontes rastreáveis** _(ponto menor — não gate)_ | Exige fonte (URL ou `[INFERÊNCIA]`) **apenas para afirmações factuais EXTERNAS verificáveis** (claim de mercado, dado quantitativo, citação de terceiro, "tendência 20XX"). Convenções, templates, exemplos e processos **internos do Onion NÃO exigem URL**. FALHA só se houver afirmação externa **sem nenhuma** fonte — e mesmo assim é ponto menor (não eleva a STALE sozinho). |
| 8 | **Workflows canônicos (!)** | Se descreve workflows `engineer/*` ou `product/*`: não os funde — são faseados retomáveis. Fusão = STALE. |

**Vereditos possíveis:**

- **CURRENT** — passa em todos os itens GATE (!); pode ter pontos menores (itens 4/7).
- **STALE** — falha em 1-2 itens GATE (!); conteúdo ainda válido mas desatualizado.
- **HISTORICAL** — falha em 3+ itens GATE (!) ou trata exclusivamente de vaporware
  abandonado (ex.: CLI standalone, `.onion/`); candidata a arquivamento.

> ⚠️ **Anti-ruído** (calibração 2026-06-15): GATES = itens (!) = {1,2,3,5,6,8}. Itens
> **4** (plataforma única) e **7** (fontes) são **pontos menores** — sozinhos nunca
> produzem STALE; só descrevem polimento. Isso impede o falso-positivo recorrente de
> worker `haiku` (flagar template/convenção/exemplo interno por "falta de URL", ou
> tratar descrição de ferramenta externa como violação de plataforma única).

---

## Etapas de Execução

### Passo 0 — Verificar substrato Workflow

Antes de qualquer coisa, confirme se a ferramenta nativa **Workflow** está
disponível neste ambiente. Se não estiver, acione o **fallback serial** (Passo 5)
e avise o usuário em pt-BR.

### Passo 1 — Levantar o escopo com Glob

```
Argumento recebido: $ARGUMENTS
```

**Se `$ARGUMENTS` estiver preenchido:**
- Trate como caminho de KB específica ou glob pattern dentro de
  `docs/knowledge-base/`.
- Resolva os arquivos `.md` correspondentes.

**Se `$ARGUMENTS` estiver vazio (modo completo):**
- Use `Glob` para listar todos os arquivos `.md` dentro de
  `docs/knowledge-base/**/*.md`, excluindo `index.md`.

Registre o conjunto final como `KB_FILES` — esse é o material do fan-out.
Se `KB_FILES` estiver vazio, informe o usuário e encerre sem erro.

### Passo 2 — Delegar elegibilidade e padrão à skill `onion-orchestration`

Acione a skill **`onion-orchestration`** passando:

- Tarefa: "Auditar frescor de cada KB listada em KB_FILES contra a régua
  canônica 2026."
- Independência: cada arquivo é autônomo — auditoria de um não depende de outro.
- Padrão esperado: **fan-out-and-synthesize** (barrier + fan-in).
- A skill confirmará a elegibilidade. Se reprovar, mantenha serial (Passo 5).

### Passo 3 — Fan-out de workers (um por KB)

Autore um script Workflow com `parallel()`. Cada worker recebe:

1. O caminho absoluto da KB.
2. A **régua de frescor completa** (tabela acima) como contexto.
3. Um schema de saída estruturado:

```javascript
const FreshnessSchema = {
  file: "string",           // caminho relativo a docs/knowledge-base/
  verdict: "CURRENT|STALE|HISTORICAL",
  failed_items: ["string"], // ids dos itens da régua que falharam
  stale_excerpts: [         // trechos concretos desatualizados
    { excerpt: "string", reason: "string" }
  ],
  refresh_direction: "string" // ação concreta recomendada (ou "none")
};
```

**Model tiering:**
- Workers de leitura/classificação → **haiku** (custo mínimo, alta
  throughput).
- Fan-in de síntese → **sonnet** (raciocínio adequado, custo controlado).
- Verificação adversarial (se acionada) → **opus**.
- Nunca use modelos de outros providers como workers.

Teto: até **16 workers concorrentes**. Para orquestrações maiores (>16 KBs),
processe em batchs de 16.

```javascript
// Exemplo de script Workflow para fan-out de auditoria de KB
const findings = await parallel(
  KB_FILES.map((kb) => agent(
    `Leia a KB em "${kb}". Avalie cada item da régua de frescor canônica 2026.
     Retorne o schema FreshnessSchema preenchido.`,
    { schema: FreshnessSchema, model: "haiku" }
  ))
);
```

### Passo 4 — Fan-in: consolidar e priorizar

No contexto principal (custo 0 tokens de modelo), consolide `findings`:

1. Agrupe por veredito: `HISTORICAL` → `STALE` → `CURRENT`.
2. Dentro de cada grupo, ordene por número de `failed_items` (decrescente).
3. Deduplicar razões comuns (ex.: "modelo GPT mencionado" pode afetar várias KBs
   — agrupe na seção de padrões transversais).
4. Se houver 3+ KBs com o mesmo `failed_item`, adicione um **alerta transversal**
   no relatório (indica problema sistêmico, não pontual).

**Verificação adversarial (opcional, acionada automaticamente quando):**
- Mais de 30% das KBs retornam STALE ou HISTORICAL.
- Algum `failed_item` é o item 1 (lineup de modelos) ou item 3 (vaporware).

Nesse caso, passe o conjunto de findings para um agente adversarial (opus)
que tenta refutar vereditos, detectar falsos positivos e apontar lacunas antes
de consolidar.

### Passo 5 — Fallback serial (substrato Workflow indisponível)

Se a ferramenta Workflow não estiver disponível:

1. Avise o usuário em pt-BR que o substrato de orquestração não está disponível e que
   a auditoria seguirá serial via ferramenta `Agent`.
2. Itere `KB_FILES` chamando `Agent` um a um com o mesmo schema `FreshnessSchema`.
3. Consolide exatamente como no Passo 4.
4. Nunca finja paralelismo.

---

## Saída Esperada

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
KB FRESHNESS REPORT — 2026-06-13
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ KBs auditadas : 35
◆ Padrão usado  : fan-out-and-synthesize
◆ Workers       : 35 × haiku + 1 fan-in sonnet
◆ Budget gasto  : ~X tokens

─── HISTÓRICAL (arquivar ou reescrever) ───────
❌ frameworks/<kb-de-visão-abandonada>.md
   Falhou: #3 (vaporware: multi-IDE / CLI standalone), #4 (plataforma única)
   Trecho: "suporte a Cursor, Zed e VS Code como alvos"
   Ação  : remover (git arquiva) ou converter em nota histórica explícita
   (Ex.: as KBs de visão multi-IDE/orchestrator de 2025 foram removidas
    na curadoria de 2026-06-14 — ver onion-review-2026-05.md.)

─── STALE (atualizar) ─────────────────────────
⚠  concepts/context-window-optimization.md
   Falhou: #1 (menciona "claude-3-opus")
   Trecho: "use claude-3-opus-20240229 para tarefas complexas"
   Ação  : substituir lineup por tiers evergreen opus/sonnet/haiku/fable (sem fixar versão exata)

⚠  concepts/ai-agent-design-patterns.md
   Falhou: #2 (trata orquestração sem mencionar ferramenta Workflow)
   Ação  : adicionar seção "Substrate nativo: ferramenta Workflow (mai/2026)"

─── CURRENT ───────────────────────────────────
✅ concepts/agent-orchestration.md
✅ concepts/task-manager-abstraction.md
✅ ... (N KBs)

─── ALERTAS TRANSVERSAIS ──────────────────────
⚠  Item #1 (lineup de modelos) falhou em 4 KBs — revisão em lote recomendada.
   Sugestão: /meta:orchestrate substituir referências a modelos obsoletos em lote

─── PRÓXIMOS PASSOS ───────────────────────────
1. Arquivar/reescrever KBs HISTORICAL (2 arquivos)
2. Atualizar KBs STALE em lote via /meta:orchestrate
3. Rodar /docs:build-index após os refreshes
4. Re-executar /meta:kb-freshness para confirmar frescor

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Exemplos

```bash
# Auditar todas as KBs (modo completo)
/meta:kb-freshness

# Auditar uma KB específica
/meta:kb-freshness docs/knowledge-base/concepts/ai-agent-design-patterns.md

# Auditar um diretório inteiro
/meta:kb-freshness docs/knowledge-base/frameworks/

# Auditar usando glob pattern
/meta:kb-freshness docs/knowledge-base/concepts/*.md
```

---

## Notas

- Este comando **nunca cria nem modifica KBs** — apenas audita e relata. Para
  aplicar os refreshes, use `/meta:create-knowledge-base` (atualizar KB
  existente) ou `/meta:orchestrate` (atualização em lote de muitas KBs de uma vez).
- A doutrina de orquestração (fan-out-and-synthesize, model tiering, teto de 16
  workers, verificação adversarial) vem de
  `docs/knowledge-base/concepts/agent-orchestration.md` — consulte-a se
  precisar ajustar o Workflow gerado.
- A orquestração é **opt-in**: se `$ARGUMENTS` apontar para uma única KB, o comando
  executa diretamente com `Agent` (sem overhead de Workflow).
- Orquestre **sempre no nível principal** — nunca dentro de um subagente e
  **não crie** um agente "kb-freshness-worker".
- **Contrato de composição (D4 do `/meta:evolve`)**: quando invocado por
  `/meta:evolve`, retorne o **array `FreshnessSchema[]` cru** (não apenas o
  relatório Unicode), para que o `evolve` mescle os vereditos direto no backlog
  sem reparsear. O schema (acima) é o contrato. `/meta:evolve` chama este comando
  no **fluxo principal** e ingere o array — nunca aninha esta orquestração dentro da dele.

---

## Referências

- KB de doutrina de orquestração: `docs/knowledge-base/concepts/agent-orchestration.md`
- Skill operacional do fan-out: `onion-orchestration`
- Comando de geração de KB: `/meta:create-knowledge-base`
- Saúde documental ampla: `/docs:docs-health`
- Atualização em lote: `/meta:orchestrate`
- Índice mestre: `docs/knowledge-base/index.md` (atualizar via `/docs:build-index`)
