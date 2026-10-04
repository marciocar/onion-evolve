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
version: "2.0.0"
updated: "2026-10-04"
allowed-tools: Read Write Grep Glob Workflow Agent Skill Bash(bash .claude/validation/*) Bash(find *) Bash(wc *) Bash(ls *) Bash(git log*) Bash(git ls-files*)
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

## 🧬 O laço, e as peças que o compõem

Re-forjado em 2026-10-04 pelo `/meta:forge` (estava em **2/7** peças; a doutrina dele vivia numa KB
que nenhum outro comando conseguia citar). A doutrina inteira — a cláusula-mãe, as seis cláusulas e
o que ela **não** promete — está em [`common:prompts:evolve-doctrine`](../common/prompts/evolve-doctrine.md).
**Referencie, não copie.**

| peça | onde |
|---|---|
| 2 doutrina | [`common/prompts/evolve-doctrine.md`](../common/prompts/evolve-doctrine.md) |
| 3 contexto injetado | `.claude/validation/evolve-census.sh` — o raio-X, injetado abaixo |
| gatilho | REGRA 97 (A auto-auditoria do framework tem GATILHO) — `.claude/validation/evolve-staleness-check.sh` |
| 4 orquestração | `.claude/workflows/evolve.js` — o fan-out (D1 D2 D3 D6 D7 D8 + MAQ) com JSON Schema real e refutador por achado |
| 5 destino | o `.kg.yaml` de auditoria + `kg-radar` exit 0 + o contrato de custo (Passo 4) |
| 6 lente | `.claude/rules/evolve-lens.md` |
| 7 bancada | `run_evolve_census_selftests` |

## Contexto medido injetado (peça 3 — o raio-X roda ANTES de você pensar)

!`bash .claude/validation/evolve-census.sh . --markdown`

Leia o raio-X **como ele se declara**: ele compõe seis medidores (peças, guardas, dissecações,
doutrina que carrega, plano, idade desta própria auditoria) e mede o que eles **declaram** — não
julga qualidade e não prioriza. O valor do evolve é o **confronto** entre as seções, que nenhum
órgão isolado entrega. E a seção 4 mede se a doutrina **carregou**, nunca se **aterrissou**:
achado sobre doutrina diz qual das duas coisas mediu.

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
| D9 | **Frescor de contexto de domínio** | **DELEGA a `/meta:context-freshness`** — ingere `FreshnessSchema[]` dos `docs/*-context/`. Herda o threshold ≤18mo (item 1 da régua de contexto). ~~No framework = **no-op** (contextos são templates, só README)~~ — **FALSO, medido 2026-10-04**: o core tem `business-context` com 15 arquivos rastreados e `technical-context` com 9 e `design-context` com 7 (recursivo, `git ls-files`), populados. O D9 **roda aqui também**; vazio silencioso é falha, não no-op. Não reimplementar; não aninhar orquestração. | (context-freshness) |
| D10 | **Frescor da memória de sessão** | **CONTEXTO PRINCIPAL, não worker** (a memória `~/.claude/projects/<projeto>/memory/` é da sessão que roda o evolve; subagente não a enxerga). Para cada entrada do `MEMORY.md`: **1 teste barato de validade** conforme a classe de apodrecimento — estado-de-trabalho (`git log`/`ls` no artefato resolutor), preferência-do-maestro (**não expira sozinha** — só o maestro invalida). **Fato-de-ambiente** (exigiria `command -v`/`curl`) está **fora do `allowed-tools` por desenho**: devolva `UNVERIFIABLE` nomeando o comando que faltou, nunca um veredito adivinhado — carimbar sem medir é exatamente o que esta dimensão existe para impedir. Corrigir/apagar na hora; nunca re-carimbar sem re-testar. Carimbar a varredura no índice (`última varredura: <data>, N rot em M`). **No-op gracioso** se a sessão não tem memória. Reporta ao relatório só contagens/vereditos (privacidade — nunca colar conteúdo de memória). Doutrina: [session-memory-lifecycle.md](../../../docs/knowledge-base/concepts/session-memory-lifecycle.md). | (principal) |

## ⚡ Etapas de Execução

### Passo 0 — Health-check do substrato Workflow
Confirme a ferramenta nativa **Workflow**. Se ausente → **fallback serial**
(Passo 5) com aviso em pt-BR. Determinístico, não inferido.

### Passo 0.5 — Ler o raio-X e escolher onde gastar

A **seção 7 do raio-X** (CONFRONTO) nomeia os alvos: a doutrina com `paths:` que nunca casou, os
comandos só-superfície que uma guarda já vigia, e — nas seções 2 e 3 — o passivo de guardas e as
dissecações vencidas. **O dogfood é por censo, não por varredura** (cláusula 2 da doutrina): com
argumento vazio, comece pelos alvos nomeados ali; varrer `.claude/` inteiro (o Passo 1 abaixo) é a
exceção declarada, não o padrão.

> ⚠️ A 1ª redação deste passo prometia que o raio-X "aponta os alvos" quando ele só os CONTAVA —
> prosa prometendo o que o código não fazia, apontado pelo Elenxo da re-forja. O raio-X ganhou a
> seção 7 para a promessa virar verdade, em vez de a promessa ser apagada.

### Passo 1 — Escopo
- `$ARGUMENTS` preenchido com `D1..D10` → roda só aquela dimensão.
- Vazio → roda as 10. Levante os alvos com `Glob`/`find`/`Grep`.

### Passo 2 — Delegar padrão à skill `onion-orchestration`
Acione **`onion-orchestration`** com: tarefa = "auditar o Onion em 10 dimensões
independentes"; independência = alta (cada dimensão é autônoma); padrão esperado
= **fan-out-and-synthesize**. A skill confirma elegibilidade e tiering.

### Passo 2.5 — Composição no CONTEXTO PRINCIPAL (D4, D5, D9, D10), antes do fan-out

D4/D5/D9 são comandos com orquestração própria; invocá-los de dentro do workflow seria orquestração
aninhada. D10 só existe no contexto principal (subagente não enxerga a memória de sessão). Por isso
rodam **aqui**, um por vez (via `Skill`), e os achados entram à mão no fan-in no formato do schema
`FINDINGS` de `.claude/workflows/evolve.js`:

| dim | como | o que entra |
|---|---|---|
| D4 | invoque `/meta:kb-freshness` | KBs além do gate ≤18 meses |
| D5 | invoque `/meta:metaspec-validate` nos artefatos de alto risco | vereditos estruturados |
| D9 | invoque `/meta:context-freshness` (os `docs/*-context/` do core são POPULADOS) | `FreshnessSchema[]` |
| D10 | 1 teste barato por entrada do `MEMORY.md` (régua na tabela de dimensões) | só contagens/vereditos |

Dimensão que não rodou é **lacuna declarada** no relatório, nunca zero. Zero achados só vale com o
comando executado e a saída que o sustenta.

### Passo 3 — Fan-out (peça 4: `.claude/workflows/evolve.js`)

```javascript
Workflow({ scriptPath: '.claude/workflows/evolve.js',
  args: { dims: [],               // vazio = D1 D2 D3 D6 D7 D8 MAQ; ou ex. ['D1'] para uma só
          maqTargets: '<cole a seção 7 do raio-X>',   // sem isto a MAQ NÃO roda (nunca inventa alvo)
          cap: 8 } })             // achados por dimensão; o excedente sai em total_seen (corte declarado)
```

O script carrega os schemas reais (`FINDINGS`, `VERDICT`), atribui o `id` estável
(`<dim>-<ordinal>`) e passa todo achado `blocker`/`recommended` por um refutador `opus/high` — em
pipeline, sem barreira. Devolve `dims` (vistos × devolvidos, por dimensão), `skipped` (não pedida
ou sem alvo), **`lost`** (o worker lançou: lacuna, nunca zero), `survived`, **`unjudged`** (o juiz
devolveu nulo ou falhou: vai ao grafo como **não julgado**, nunca como sobrevivente), `refuted` e
`verdicts`. Entrada ruim (`args` que não é objeto nem JSON, `cap` fora de 1..30, dimensão D4/D5/D9/D10)
**recusa** com `{error}` — nunca roda tudo em silêncio.

> ⚠️ **Até 2026-10-04 este passo era um bloco de JS que não rodava:** o `FindingSchema` não era JSON
> Schema (`{id:"string"}` usado como `items:`, a forma ligada ao "0 findings FALSO" de 2026-07-30), e
> `runCommand()` ×3 e `sweepSessionMemory()` não existiam em lugar nenhum — quem copiasse o molde
> recebia ReferenceError. A rodada de 2026-10-04 autorou o script inline com schema real; ele virou a
> peça 4 (nós `C_FINDINGSCHEMA_DO_EVOLVE_NAO_E_JSON_SCHEMA` e `C_QUATRO_SIMBOLOS_FANTASMAS_NO_EVOLVE`).

### Passo 3.1 — Verificação adversarial (acionada automaticamente quando)
- proposta toca arquivo `engineer/*` ou `product/*` (risco de invariante);
- proposta é de **consolidação** (fundir artefatos);
- >30% de uma dimensão flagada.

Um juiz (opus) tenta **refutar** o achado e, sobretudo, **veta qualquer proposta
que funda fases de workflow faseado** ([commands.md §3](../../../docs/meta-specs/commands.md)) —
falha de modo mais grave. Achados que sobrevivem entram no backlog.

A correlação achado↔veredito é **por construção** no `evolve.js`: o refutador recebe UM achado e o
script grava `{ id, verdict }` ao lado — o juiz nunca precisa ecoar texto nem id. O schema do
veredito é o `VERDICT` do script (`refuted`, `vetoed_phase_merge`, `reasoning`, todos obrigatórios).
Na prática o script julga **todo** achado `blocker`/`recommended` **e** todo achado — de qualquer
severidade — cujo alvo, proposta ou texto toque `engineer/`, `product/`, fusão ou consolidação. Os
achados do Passo 2.5 **não** passam por juiz e o relatório diz isso. (A 1ª versão julgava só por
severidade, e um `opportunistic` que propusesse fundir fases escapava do veto — achado do Elenxo.)

### Passo 3.2 — Completeness critic (no contexto principal, sobre o retorno)
Não é um agente: é a conferência que **você** faz antes do fan-in, sobre o que o script devolveu.
As 10 dimensões têm de aparecer em exatamente um lugar — `dims` (rodou), `skipped`, `lost`, ou o
Passo 2.5 (rodou ou lacuna declarada). `lost` e `unjudged` não-vazios vão para o relatório **e** para
o grafo. Vazio silencioso numa dimensão é falha, não sucesso — vale também para o D9 no core, cujos
contextos são populados.

### Passo 4 — Fan-in: consolidar e priorizar (0 tokens)
No contexto principal, parta do `survived` que o workflow devolve **mais** os achados do Passo 2.5:
1. **Refutados/vetados já saíram por `id`** dentro do script — **nunca** por texto. Os achados do
   Passo 2.5 não passaram por refutador: marque-os assim no grafo.
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
Avise em pt-BR; itere as dimensões com `Agent` uma a uma com os mesmos
prompts do `.claude/workflows/evolve.js`, pedindo a saída no formato do schema `FINDINGS` (o `Agent`
não recebe schema: valide a forma ao receber); consolide igual ao Passo 4. Nunca finja paralelismo.

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
   - Nenhuma proposta funde fases de engineer/* ou product/* (verificado pelo juiz adversarial nos achados
     do workflow; os do Passo 2.5 e os `unjudged` NÃO foram julgados, e o relatório os nomeia).
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
