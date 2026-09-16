---
name: evolve
description: |
  Auto-auditoria do Sistema Onion via orquestração (fan-out-and-synthesize) que produz
  um backlog priorizado, com evidência citada, de refatorações de modernização.
  Read-only sobre .claude/: propõe, não muta. Escreve em DOIS lugares — o .kg.yaml de
  auditoria (destino dos achados) e o relatório em docs/analysis/ (projeção do grafo);
  mais a memória de sessão em D10, exceção declarada fora do repo.
category: meta
tags: [evolve, audit, orchestration, self-evolution, modernization]
version: "1.4.0"
updated: "2026-08-05"
allowed-tools: Read Write Grep Glob Bash(bash .claude/validation/*) Bash(find *) Bash(wc *) Bash(ls *) Bash(git log*) Bash(git ls-files*)
argument-hint: "[dimensão específica (D1..D10) | vazio = auditoria completa]"
related_commands:
  - /meta:orchestrate
  - /meta:kb-freshness
  - /meta:context-freshness
  - /meta:metaspec-validate
  - /meta:create-command
related_agents:
  - onion
  - metaspec-gate-keeper
---

# /meta:evolve — Auto-Auditoria e Backlog de Evolução

## 🎯 Objetivo

Olhar para o **próprio Sistema Onion** com fan-out de auditores e produzir um
**backlog priorizado de refatorações de modernização**, com evidência citada
(`arquivo:linha`) e o **padrão de refatoração** recomendado por item. É a
automação contínua da Baseline de V&V manual (`onion-vv-baseline-2026-06`, core-only):
em vez de auditar à mão, dispara uma orquestração e sintetiza.

**Read-only sobre `.claude/`.** O comando **nunca muta `.claude/`**. Ele escreve em
**dois** lugares, por desenho: o `.kg.yaml` de auditoria (**destino** dos achados, Passo 4.4)
e o relatório em `docs/analysis/` (**projeção** do grafo, nunca fonte paralela). A terceira
escrita é a memória de sessão no D10 — exceção declarada, fora do repo. Ele **propõe**; a
execução das correções é dos atuadores (`/meta:create-*`, ou `/product:spec → /engineer:plan`
para consolidações de cluster) sob validação do `@metaspec-gate-keeper`.

> **Nota de honestidade (2026-08-05).** Até esta versão a `description` dizia "a única escrita
> é o relatório", o que era **falso desde 2026-07-20** (o gate de grafo entrou em `0ea48df`).
> Era `behavior-over-declaration` violado no comando que prega a doutrina.

O **julgamento** de qual padrão aplicar a cada achado vem da
[Doutrina de Modernização](../../../docs/knowledge-base/concepts/onion-modernization-doctrine.md);
a **doutrina de orquestração** (padrões, tiering, tetos) vem de
[agent-orchestration.md](../../../docs/knowledge-base/concepts/agent-orchestration.md).
A orquestração roda **sempre no nível principal** (este comando + skill
`onion-orchestration`), nunca dentro de subagente ([commands.md §10.1](../../../docs/meta-specs/commands.md)).

## 🟢 Quando usar

- Auditoria periódica de saúde e peso do framework.
- Depois de uma rodada grande de mudanças (como o piloto git), para medir
  "depois" vs o backlog anterior.
- Antes de decidir o próximo cluster a modernizar.

## 📥 Input

```
/meta:evolve            # auditoria completa (10 dimensões)
/meta:evolve D2         # só uma dimensão (ex.: redundância)
```

## 🔬 Dimensões de auditoria (fan-out)

Top-level = **fan-out-and-synthesize** (1 worker por dimensão, barrier, fan-in em
JS no contexto principal). **D4, D5, D9 e D10 são composição** — delegam a comandos/rotina
existentes, **não** reimplementam (e não aninham orquestração dentro de orquestração).

| # | Dimensão | O que escaneia (evidência) | Tier |
|---|----------|----------------------------|------|
| D1 | **Peso/tamanho** | `find .claude/{agents,commands} -name '*.md'` + `wc -l` vs limites (agentes 1200/1500; comandos 500/800). Classifica refactor vs isento (template/README). | haiku |
| D2 | **Redundância/overlap** | Nomes + `description` próximos (clusters `branch-*`, testing-3, meta-creators). Agrupa por similaridade. | sonnet |
| D3 | **Duplicação >50 linhas** | Blocos repetidos entre comandos → candidatos a `common/templates` ou `common/prompts` ([commands.md §6](../../../docs/meta-specs/commands.md)). | haiku |
| D4 | **KBs stale** | **DELEGA a `/meta:kb-freshness`** — ingere o array `FreshnessSchema[]`. Não reimplementar. **Threshold canônico de data = item 6 da régua kb-freshness: ≤18 meses** (relativo a hoje); **NUNCA** usar ad-hoc tipo ">6 meses" (gera falso-positivo — calibração 2026-06-15). Se, por restrição de no-orchestration-in-orchestration, rodar como scan focado em vez de delegar, **herde o gate ≤18mo** explicitamente no prompt do worker. | (kb-freshness) |
| D5 | **Conformidade meta-spec** | **DELEGA a `/meta:metaspec-validate`** por artefato de alto risco — ingere os vereditos estruturados. Não reimplementar a constituição. | (metaspec-validate) |
| D6 | **Moderna vs legada + vazamento SDAAL** | Prosa/delegação sequencial que deveria ser `Workflow` fan-out; resíduo `.onion`/CLI/npm/multi-IDE ([architecture.md §7](../../../docs/meta-specs/architecture.md)). **Vazamento provider-specific / MCP-first:** chamada direta a provider (`mcp_<provider>_*`) ou "MCP como transporte default" em comandos/agentes fora de adapters/especialistas — viola API-first/agnosticismo (lint Regra 10; doutrina §consumo de integração). | sonnet |
| D7 | **Cross-refs / links** | `find .claude -xtype l` (symlinks quebrados) + links relativos `[..](..)` que apontam para arquivos inexistentes. | haiku |
| D8 | **Plataforma/frontmatter + inventário** | Cobertura de `allowed-tools`/`model:`, frontmatter completo, kebab-case ([commands.md §1](../../../docs/meta-specs/commands.md), [agents.md](../../../docs/meta-specs/agents.md)). **Inventário:** roda `bash .claude/validation/inventory.sh --markdown` e compara com `docs/onion/inventory.md` + contagens em `CLAUDE.md`; divergência = achado (atuador `/meta:inventory`, **não** edição manual — ver doutrina §regra de inventário). | haiku |
| D9 | **Frescor de contexto de domínio** | **DELEGA a `/meta:context-freshness`** — ingere `FreshnessSchema[]` dos `docs/*-context/`. Herda o threshold ≤18mo (item 1 da régua de contexto). No framework = **no-op** (contextos são templates, só README); o valor é em projeto-alvo que populou os contextos. Não reimplementar; não aninhar orquestração. | (context-freshness) |
| D10 | **Frescor da memória de sessão** | **CONTEXTO PRINCIPAL, não worker** (a memória `~/.claude/projects/<projeto>/memory/` é da sessão que roda o evolve; subagente não a enxerga). Para cada entrada do `MEMORY.md`: **1 teste barato de validade** conforme a classe de apodrecimento — estado-de-trabalho (`git log`/`ls` no artefato resolutor), preferência-do-maestro (**não expira sozinha** — só o maestro invalida). **Fato-de-ambiente** (exigiria `command -v`/`curl`) está **fora do `allowed-tools` por desenho**: devolva `UNVERIFIABLE` nomeando o comando que faltou, nunca um veredito adivinhado — carimbar sem medir é exatamente o que esta dimensão existe para impedir. Corrigir/apagar na hora; nunca re-carimbar sem re-testar. Carimbar a varredura no índice (`última varredura: <data>, N rot em M`). **No-op gracioso** se a sessão não tem memória. Reporta ao relatório só contagens/vereditos (privacidade — nunca colar conteúdo de memória). Doutrina: [session-memory-lifecycle.md](../../../docs/knowledge-base/concepts/session-memory-lifecycle.md). | (principal) |

## ⚡ Etapas de Execução

### Passo 0 — Health-check do substrato Workflow
Confirme a ferramenta nativa **Workflow**. Se ausente → **fallback serial**
(Passo 5) com aviso em pt-BR. Determinístico, não inferido.

### Passo 1 — Escopo
- `$ARGUMENTS` preenchido com `D1..D10` → roda só aquela dimensão.
- Vazio → roda as 10. Levante os alvos com `Glob`/`find`/`Grep`.

### Passo 2 — Delegar padrão à skill `onion-orchestration`
Acione **`onion-orchestration`** com: tarefa = "auditar o Onion em 10 dimensões
independentes"; independência = alta (cada dimensão é autônoma); padrão esperado
= **fan-out-and-synthesize**. A skill confirma elegibilidade e tiering.

### Passo 3 — Fan-out (workers de dimensão) + composição (D4/D5/D9/D10)
Autore o script `Workflow`. Cada worker de dimensão recebe a régua da sua linha e
devolve `FindingSchema[]`. **D4, D5, D9 e D10 NÃO são workers** — D4/D5/D9 são
chamados no fluxo principal (sequencialmente) e seus resultados mesclados, pois
`kb-freshness` já roda sua própria orquestração interna (aninhar violaria
`onion-orchestration`); **D10 roda no contexto principal por necessidade** — a
memória de sessão só é visível à sessão que executa o evolve (subagente não a
enxerga), e seus achados entram como `FindingSchema[]` com contagens/vereditos,
nunca conteúdo de memória.

```javascript
const FindingSchema = {
  id: "string",                      // chave ESTÁVEL de correlação — atribuída no fan-in (`${dimension}-${ordinal}`)
  dimension: "D1|D2|D3|D4|D5|D6|D7|D8|D9|D10",
  severity: "blocker|recommended|opportunistic",   // 🔴 | 🟡 | 🟢
  finding: "string",                 // descrição
  evidence: "string",                // arquivo:linha ou output
  doctrine_pattern: "string",        // regra da onion-modernization-doctrine
  target_artifact: "string",         // arquivo(s)-alvo
  effort: "S|M|L",
  exec_command: "string"             // comando atuador: /meta:create-* | /product:spec→/engineer:plan
};

// Dimensões "scan próprio" → fan-out com barrier
const SCAN_DIMS = ["D1","D2","D3","D6","D7","D8"];
const scanFindings = await parallel(
  SCAN_DIMS.map((d) => agent(
    `Audite o Sistema Onion na dimensão ${d} (ver régua). Liste achados como FindingSchema[] com evidência arquivo:linha.`,
    { schema: { type: "array", items: FindingSchema }, model: d === "D2" || d === "D6" ? "sonnet" : "haiku" }
  ))
);

// ⚠️ COMPOSIÇÃO — NÃO IMPLEMENTADA (medido 2026-08-05). `runCommand()` NÃO existe: aparece
// apenas nestas linhas, em todo o repo, e NENHUM artefato de .claude/ declara a tool
// `SlashCommand` (grep -rl em commands/agents/skills = vazio). Logo D4/D5/D9 NUNCA rodaram
// por este caminho — não é regressão, é mecanismo que nunca nasceu. O run de 2026-07-30
// registra o sintoma: "a 1ª rodada falhou (schema bug) e o '0 findings' era FALSO".
// Até o conserto (PR 3), execute D4/D5 como INVOCAÇÃO no contexto principal, antes do
// fan-out, e mescle os resultados à mão — e DECLARE no relatório que foram assim obtidos.
// Zero achados numa destas dimensões só é resultado válido se vier com o comando executado
// e o output verbatim que sustenta o zero.
const kbFindings = await runCommand("/meta:kb-freshness");         // D4 — ingere FreshnessSchema[]
const specFindings = await runCommand("/meta:metaspec-validate");  // D5 — por artefato de alto risco
const ctxFindings = await runCommand("/meta:context-freshness");   // D9 — FreshnessSchema[] dos docs/*-context/ (vazio no framework)
const memFindings = sweepSessionMemory();                          // D10 — CONTEXTO PRINCIPAL: 1 teste/entrada do MEMORY.md; só contagens/vereditos (no-op sem memória)

// Atribuir id ESTÁVEL a cada achado — é a única chave confiável de correlação
// entre achado e veredito no fan-in (o juiz reformula o texto; o id não muda).
const allFindings = [...scanFindings.flat(), ...kbFindings, ...specFindings, ...ctxFindings, ...memFindings]
  .map((f, i) => ({ ...f, id: `${f.dimension}-${i}` }));
```

### Passo 3.1 — Verificação adversarial (acionada automaticamente quando)
- proposta toca arquivo `engineer/*` ou `product/*` (risco de invariante);
- proposta é de **consolidação** (fundir artefatos);
- >30% de uma dimensão flagada.

Um juiz (opus) tenta **refutar** o achado e, sobretudo, **veta qualquer proposta
que funda fases de workflow faseado** ([commands.md §3](../../../docs/meta-specs/commands.md)) —
falha de modo mais grave. Achados que sobrevivem entram no backlog.

O veredito **DEVE ecoar o `id`** do achado (jamais reproduzir o texto como chave):

```javascript
const VerdictSchema = {
  finding_id: "string",        // ECOA FindingSchema.id — única chave de correlação válida
  refuted: "boolean",
  vetoed_phase_merge: "boolean",
  reasoning: "string"
};
```

### Passo 3.2 — Completeness critic (loop-until-done, budget-gated)
Antes do fan-in, um crítico confirma que as 10 dimensões rodaram e nenhuma
categoria de artefato foi pulada (incl. D9 — ausência de achados de contexto só é
válida se os `docs/*-context/` forem templates; em projeto-alvo populado, vazio
silencioso = falha, não sucesso). O que faltar vira nova rodada.

### Passo 4 — Fan-in: consolidar e priorizar (0 tokens)
No contexto principal, parta de `allFindings` (já com `id` estável):
1. **Remova refutados/vetados correlacionando por `id`** — **nunca** por texto:
   ```javascript
   const survived = allFindings.filter(f =>
     !verdicts.some(v => v.finding_id === f.id && (v.refuted || v.vetoed_phase_merge)));
   ```
   ⚠️ Casar por `finding.slice(...)` falha: o juiz reformula o texto do achado e a
   maioria dos refutados escaparia para o backlog (modo de falha real, jun/2026).
2. Agrupe por severidade: 🔴 blocker → 🟡 recommended → 🟢 opportunistic
   (hierarquia do `@metaspec-gate-keeper`).
3. Dedup transversal: 3+ achados com a mesma causa → **alerta sistêmico**.
4. **Grafo primeiro**: materialize `survived` via `/meta:kg` — cada achado sobrevivente vira nó
   (`claim`, `layer: audit`, `trace` para a evidência) no `.kg.yaml` de auditoria; `kg-radar.sh`
   deve fechar exit 0 antes de seguir. O grafo é o **destino** dos achados estruturados, não o
   relatório — senão ele vira predecessor da avaliação em vez de destino dela (lição do sinal de
   campo de um adotante regulado, 2026-07-20: 70 agentes/60 achados foram parar só em markdown).
5. Escreva o relatório — **projeção do grafo**, não fonte paralela — em
   `docs/analysis/onion-evolution-<YYYY-MM-DD>.md` (única escrita em **markdown**; **nunca** em
   `.claude/`).

### Passo 5 — Fallback serial (Workflow indisponível)
Avise em pt-BR; itere as dimensões com `Agent` uma a uma com o mesmo
`FindingSchema`; consolide igual ao Passo 4. Nunca finja paralelismo.

## 📤 Saída — `docs/analysis/onion-evolution-<data>.md`

```markdown
# Onion Evolution Backlog — <data>

## 0. Sumário
◆ Dimensões: 10  ◆ Padrão: fan-out-and-synthesize  ◆ Workers: N
◆ Budget: ~X tokens  ◆ Run ID: <id>  ◆ Agent View: <ref>

## 1. Backlog priorizado
| # | Sev | Dim | Achado (arquivo:linha) | Padrão (doutrina) | Artefato-alvo | Esforço | Comando de execução |
|---|-----|-----|------------------------|-------------------|---------------|---------|---------------------|
| 1 | 🔴 | D6 | ... | shed-ceremony→KB | ... | M | /meta:create-knowledge-base |

## 2. Achados por dimensão (D1–D10)
## 3. Alertas transversais (causa sistêmica)
## 4. Invariantes respeitadas
   - Nenhuma proposta funde fases de engineer/* ou product/* (verificado pelo juiz adversarial).
## 5. Próximos passos (cada item → seu comando atuador)
```

As duas últimas colunas do backlog **fecham o loop**: "Padrão (doutrina)" cita uma
regra da [Doutrina de Modernização](../../../docs/knowledge-base/concepts/onion-modernization-doctrine.md);
"Comando de execução" nomeia o atuador concreto.

## 💡 Exemplos

```bash
/meta:evolve            # auditoria completa → backlog priorizado
/meta:evolve D1         # só outliers de peso/tamanho
/meta:evolve D6         # só moderna-vs-legada + resíduo abandonado
```

## ⚠️ Notas

- **Read-only**: propõe, não muta `.claude/`. Só escreve o relatório em `docs/analysis/`. Exceção deliberada do D10: a **memória de sessão** (fora do repo) é corrigida/apagada na hora — é cache da sessão, não artefato do framework ([session-memory-lifecycle.md](../../../docs/knowledge-base/concepts/session-memory-lifecycle.md)).
- **Compõe, não duplica**: D4/D5/D9 reusam `/meta:kb-freshness`, `/meta:metaspec-validate` e `/meta:context-freshness` — nunca reimplementam, nunca aninham orquestração dentro de orquestração.
- **Invariante**: pode *reportar* sobre os workflows faseados, **nunca** propor fundir suas fases — o juiz adversarial veta.
- Orquestre **sempre no nível principal**; **não crie** um agente "evolve-worker".
- Doutrina de julgamento: `docs/knowledge-base/concepts/onion-modernization-doctrine.md`.

## 🔗 Referências

- Doutrina (qual padrão aplicar): [onion-modernization-doctrine.md](../../../docs/knowledge-base/concepts/onion-modernization-doctrine.md)
- Doutrina de orquestração: [agent-orchestration.md](../../../docs/knowledge-base/concepts/agent-orchestration.md)
- Composição: `/meta:kb-freshness` (D4) · `/meta:metaspec-validate` (D5) · `/meta:context-freshness` (D9)
- Atuadores: `/meta:create-command|agent|skill|abstraction|knowledge-base`
- Baseline manual que automatiza: `onion-vv-baseline-2026-06` (core-only)
- Skill de fan-out: `onion-orchestration` · Meta-spec: [commands.md §10](../../../docs/meta-specs/commands.md)
