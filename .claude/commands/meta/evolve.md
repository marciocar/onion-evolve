---
name: evolve
description: |
  Auto-auditoria do Sistema Onion via fleet (fan-out-and-synthesize) que produz
  um backlog priorizado, com evidência citada, de refatorações de modernização.
  Read-only: propõe, não muta (a única escrita é o relatório em docs/analysis/).
model: opus
category: meta
tags: [evolve, audit, fleet, self-evolution, modernization]
version: "1.0.0"
updated: "2026-06-13"
allowed-tools: Read Grep Glob Bash(find *) Bash(wc *) Bash(git log*) Bash(cat .env*)
argument-hint: "[dimensão específica (D1..D8) | vazio = auditoria completa]"
related_commands:
  - /meta:fleet
  - /meta:kb-freshness
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
automação contínua da [Baseline de V&V manual](../../../docs/analysis/onion-vv-baseline-2026-06.md):
em vez de auditar à mão, dispara uma frota e sintetiza.

**Read-only por contrato.** O comando **nunca muta `.claude/`**; a única escrita
é o relatório em `docs/analysis/`. Ele **propõe**; a execução das correções é dos
atuadores (`/meta:create-*`, ou `/product:spec → /engineer:plan` para
consolidações de cluster) sob validação do `@metaspec-gate-keeper`.

O **julgamento** de qual padrão aplicar a cada achado vem da
[Doutrina de Modernização](../../../docs/knowledge-base/concepts/onion-modernization-doctrine.md);
a **doutrina de frota** (padrões, tiering, tetos) vem de
[agent-fleet-orchestration.md](../../../docs/knowledge-base/concepts/agent-fleet-orchestration.md).
A orquestração roda **sempre no nível principal** (este comando + skill
`onion-fleet`), nunca dentro de subagente ([commands.md §10.1](../../../docs/meta-specs/commands.md)).

## 🟢 Quando usar

- Auditoria periódica de saúde e peso do framework.
- Depois de uma rodada grande de mudanças (como o piloto git), para medir
  "depois" vs o backlog anterior.
- Antes de decidir o próximo cluster a modernizar.

## 📥 Input

```
/meta:evolve            # auditoria completa (8 dimensões)
/meta:evolve D2         # só uma dimensão (ex.: redundância)
```

## 🔬 Dimensões de auditoria (fan-out)

Top-level = **fan-out-and-synthesize** (1 worker por dimensão, barrier, fan-in em
JS no contexto principal). **D4 e D5 são composição** — delegam a comandos
existentes, **não** reimplementam (e não aninham frota dentro de frota).

| # | Dimensão | O que escaneia (evidência) | Tier |
|---|----------|----------------------------|------|
| D1 | **Peso/tamanho** | `find .claude/{agents,commands} -name '*.md'` + `wc -l` vs limites (agentes 1200/1500; comandos 500/800). Classifica refactor vs isento (template/README). | haiku |
| D2 | **Redundância/overlap** | Nomes + `description` próximos (clusters `branch-*`, testing-3, meta-creators). Agrupa por similaridade. | sonnet |
| D3 | **Duplicação >50 linhas** | Blocos repetidos entre comandos → candidatos a `common/templates` ou `common/prompts` ([commands.md §6](../../../docs/meta-specs/commands.md)). | haiku |
| D4 | **KBs stale** | **DELEGA a `/meta:kb-freshness`** — ingere o array `FreshnessSchema[]`. Não reimplementar. | (kb-freshness) |
| D5 | **Conformidade meta-spec** | **DELEGA a `/meta:metaspec-validate`** por artefato de alto risco — ingere os vereditos estruturados. Não reimplementar a constituição. | (metaspec-validate) |
| D6 | **Moderna vs legada** | Prosa/delegação sequencial que deveria ser `Workflow` fan-out; resíduo `.onion`/CLI/npm/multi-IDE ([architecture.md §7](../../../docs/meta-specs/architecture.md)). | sonnet |
| D7 | **Cross-refs / links** | `find .claude -xtype l` (symlinks quebrados) + links relativos `[..](..)` que apontam para arquivos inexistentes. | haiku |
| D8 | **Plataforma/frontmatter** | Cobertura de `allowed-tools`/`model:`, frontmatter completo, kebab-case ([commands.md §1](../../../docs/meta-specs/commands.md), [agents.md](../../../docs/meta-specs/agents.md)). | haiku |

## ⚡ Etapas de Execução

### Passo 0 — Health-check do substrato Workflow
Confirme a ferramenta nativa **Workflow**. Se ausente → **fallback serial**
(Passo 5) com aviso em pt-BR. Determinístico, não inferido.

### Passo 1 — Escopo
- `$ARGUMENTS` preenchido com `D1..D8` → roda só aquela dimensão.
- Vazio → roda as 8. Levante os alvos com `Glob`/`find`/`Grep`.

### Passo 2 — Delegar padrão à skill `onion-fleet`
Acione **`onion-fleet`** com: tarefa = "auditar o Onion em 8 dimensões
independentes"; independência = alta (cada dimensão é autônoma); padrão esperado
= **fan-out-and-synthesize**. A skill confirma elegibilidade e tiering.

### Passo 3 — Fan-out (workers de dimensão) + composição (D4/D5)
Autore o script `Workflow`. Cada worker de dimensão recebe a régua da sua linha e
devolve `FindingSchema[]`. **D4 e D5 NÃO são workers** — são chamados no fluxo
principal (sequencialmente) e seus resultados mesclados, pois `kb-freshness` já
roda sua própria frota interna (aninhar violaria `onion-fleet`).

```javascript
const FindingSchema = {
  dimension: "D1|D2|D3|D4|D5|D6|D7|D8",
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

// Composição (NÃO fan-out): delega aos comandos existentes no fluxo principal
const kbFindings = await runCommand("/meta:kb-freshness");        // ingere FreshnessSchema[]
const specFindings = await runCommand("/meta:metaspec-validate"); // por artefato de alto risco
```

### Passo 3.1 — Verificação adversarial (acionada automaticamente quando)
- proposta toca arquivo `engineer/*` ou `product/*` (risco de invariante);
- proposta é de **consolidação** (fundir artefatos);
- >30% de uma dimensão flagada.

Um juiz (opus) tenta **refutar** o achado e, sobretudo, **veta qualquer proposta
que funda fases de workflow faseado** ([commands.md §3](../../../docs/meta-specs/commands.md)) —
falha de modo mais grave. Achados que sobrevivem entram no backlog.

### Passo 3.2 — Completeness critic (loop-until-done, budget-gated)
Antes do fan-in, um crítico confirma que as 8 dimensões rodaram e nenhuma
categoria de artefato foi pulada. O que faltar vira nova rodada.

### Passo 4 — Fan-in: consolidar e priorizar (0 tokens)
No contexto principal, mescle `scanFindings` + `kbFindings` + `specFindings`:
1. Agrupe por severidade: 🔴 blocker → 🟡 recommended → 🟢 opportunistic
   (hierarquia do `@metaspec-gate-keeper`).
2. Dedup transversal: 3+ achados com a mesma causa → **alerta sistêmico**.
3. Escreva o relatório em `docs/analysis/onion-evolution-<YYYY-MM-DD>.md`
   (única escrita; **nunca** em `.claude/`).

### Passo 5 — Fallback serial (Workflow indisponível)
Avise em pt-BR; itere as dimensões com `Agent` uma a uma com o mesmo
`FindingSchema`; consolide igual ao Passo 4. Nunca finja paralelismo.

## 📤 Saída — `docs/analysis/onion-evolution-<data>.md`

```markdown
# Onion Evolution Backlog — <data>

## 0. Sumário
◆ Dimensões: 8  ◆ Padrão: fan-out-and-synthesize  ◆ Workers: N
◆ Budget: ~X tokens  ◆ Run ID: <id>  ◆ Agent View: <ref>

## 1. Backlog priorizado
| # | Sev | Dim | Achado (arquivo:linha) | Padrão (doutrina) | Artefato-alvo | Esforço | Comando de execução |
|---|-----|-----|------------------------|-------------------|---------------|---------|---------------------|
| 1 | 🔴 | D6 | ... | shed-ceremony→KB | ... | M | /meta:create-knowledge-base |

## 2. Achados por dimensão (D1–D8)
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

- **Read-only**: propõe, não muta `.claude/`. Só escreve o relatório em `docs/analysis/`.
- **Compõe, não duplica**: D4/D5 reusam `/meta:kb-freshness` e `/meta:metaspec-validate` — nunca reimplementam, nunca aninham frota dentro de frota.
- **Invariante**: pode *reportar* sobre os workflows faseados, **nunca** propor fundir suas fases — o juiz adversarial veta.
- Orquestre **sempre no nível principal**; **não crie** um agente "evolve-worker".
- Doutrina de julgamento: `docs/knowledge-base/concepts/onion-modernization-doctrine.md`.

## 🔗 Referências

- Doutrina (qual padrão aplicar): [onion-modernization-doctrine.md](../../../docs/knowledge-base/concepts/onion-modernization-doctrine.md)
- Doutrina de frota: [agent-fleet-orchestration.md](../../../docs/knowledge-base/concepts/agent-fleet-orchestration.md)
- Composição: `/meta:kb-freshness` (D4) · `/meta:metaspec-validate` (D5)
- Atuadores: `/meta:create-command|agent|skill|abstraction|knowledge-base`
- Baseline manual que automatiza: [onion-vv-baseline-2026-06.md](../../../docs/analysis/onion-vv-baseline-2026-06.md)
- Skill de fan-out: `onion-fleet` · Meta-spec: [commands.md §10](../../../docs/meta-specs/commands.md)
