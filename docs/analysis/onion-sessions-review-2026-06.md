# 📊 Revisão do Sistema de Sessões do Onion — Junho/2026

> **Status:** efêmero (segue [analysis/README.md](README.md)) — relatório de diagnóstico que precede e justifica a refatoração `refactor/sessions-worklog-protocol`. Remover após a execução completa; as conclusões duradouras passam a viver na SSOT ([gitflow-patterns.md §Contrato de Sessão](../knowledge-base/frameworks/gitflow-patterns.md)) e no KB [worklog-protocol.md](../knowledge-base/concepts/worklog-protocol.md).
>
> **Data:** 2026-06-14 · **Método:** 3 Explore + 2 Plan agents, evidência citada em arquivos reais deste repo e dos projetos-alvo `rhilo-app`/`rhilo-metagamify`.

---

## 1. Por que esta revisão

O conceito de **sessão** (`.claude/sessions/`) é o **mecanismo central de estado persistente e resumabilidade** do Onion — é o que permite pausar e continuar workflows faseados (`engineer/plan→pr-update`), o coração da proposta de valor "workflows faseados retomáveis". A revisão confrontou a prática atual com as recomendações **oficiais** (Claude Code/Anthropic) e **populares** (comunidade Spec-Driven Development) para extrair o máximo potencial da IA.

**Veredito:** o conceito está funcional, mas com **drift estrutural sério**, **política de versionamento que contradiz a realidade**, **zero integração com o modelo nativo do Claude Code** e um **protocolo de leitura que viola as próprias KBs de higiene de contexto** do framework. Há ganho real de eficiência e eficácia a capturar.

---

## 2. Achados (com evidência)

### D1 — Cinco definições conflitantes de "estrutura de sessão"
Uma delas se autointitula "Fonte única" e ainda assim diverge das outras.

| Fonte | Estrutura declarada | Problema |
|---|---|---|
| `docs/knowledge-base/frameworks/gitflow-patterns.md` §Contrato (~870) | 3 arquivos: `context/plan/notes` — **sem** `architecture.md` | Diz ser SSOT, mas está fora de sincronia com os comandos |
| `.claude/skills/onion-patterns/SKILL.md:48-53` | 4 arquivos: + `architecture.md` | Redefine inline |
| `.claude/commands/docs/sync-sessions.md:64-74` | dir `YYYY-MM-DD_HHMM_topic/` + 7 arquivos | Esquema totalmente diferente |
| `docs/onion/engineering-flows.md:154-158` | `plan/context/decisions/progress` | 4ª variante (arquivos inexistentes em qualquer contrato) |
| `docs/onion/engineering-flows.md:286-291` | versão aparada do esquema de 7 | 5ª variante |

A **realidade dos comandos é 4 arquivos** — todos assumem `architecture.md`: `engineer/start.md:191`, `plan.md:21`, `onion-patterns SKILL:48-53`, `onion SKILL:201`, `task-check.md:339`, `warm-up.md:36`. Logo, o desatualizado é o `gitflow-patterns.md` (3 arquivos). **Decisão: unificar para 4, não apagar `architecture.md`.**

**Drift extra:** o **Phase-Subtask Mapping** — criado por `start.md:232-237`, consumido por `work.md:43-48` e `validate-phase-sync.md:59-64` — **nenhum contrato documenta**.

### D2 — Política de versionamento contradiz a realidade
`docs/meta-specs/architecture.md §6.2` e o Contrato dizem "sessão = estado runtime, gitignored por padrão". O `onion-plus/.gitignore` ignora tudo (linhas **3 e 33** — par redundante/contraditório) → **0** sessões versionadas neste repo. Mas o projeto-alvo `rhilo-app` **commita 1.640 arquivos** de sessão; na prática são artefato durável de time/auditoria. A evidência oficial+comunidade favorece sessões versionadas (handoff, histórico de decisão). **Decisão: escolha consciente por projeto, documentada.**

### D3 — Templates órfãos (peso morto)
`.claude/docs/templates/execution-plan-template.md` (13KB) e `phase-execution-prompt-template.md` (15KB): **zero referências** externas (só o próprio README). **Decisão: deletar.** (Flag fora de escopo: `adr/guide/reference/solution-template.md` também órfãos — follow-up separado.)

### D4 — Colisão de nomes + zero integração nativa
"Sessão" significa duas coisas nunca distinguidas: a **pasta** do Onion vs. o **transcript nativo** do Claude Code (`claude --resume`/`-c`, JSONL em `~/.claude/projects/`). Nenhum comando menciona `--resume`, `/compact`, import de `CLAUDE.md` ou ordenação prompt-cache-friendly. **Decisão: terminologia `worklog` (pasta) vs `transcript` (nativo), camadas complementares e explícitas.**

### D5 — Protocolo "ler tudo" estoura o contexto
`engineer/work.md:24` manda "Ler **todos** os arquivos markdown na pasta". Arquivos reais: `architecture-v2.md` = 49KB, `plan.md` = 44KB, um guia = **150KB**. Isso **viola** as próprias KBs do framework: `context-window-optimization.md` §Progressive Loading (182-200) e §Anti-pattern "Context Dump" (523-535). **Decisão: protocolo de leitura escalonado (Tier 0→3) com índice `STATE.md` de ~1KB.**

### D6 — Badges de fase não-determinísticos e auto-contraditórios
Num único `plan.md` real (`wrr-fair-queue-distribution-service`, 1149 linhas): header da Fase 2 = `[Não Iniciada ⏳]` mas a tabela-resumo = `🚧 Em Andamento`; Fase 4 header = `[Em Progresso 🚀]` mas tabela = `⏳ Não Iniciada`. "Concluído" aparece como `Completada ✅` (49×) **e** `Concluída ✅` (30×); "em progresso" como `⏰`/`🚀`/`🚧`. Consequência: **um Claude novo (sem transcript) não consegue determinar a próxima ação só pelos arquivos.** **Decisão: vocabulário ASCII normalizado `[DONE]/[ACTIVE]/[TODO]` + ponteiro único `STATE.md.NEXT` canônico.**

---

## 3. Benchmark — oficial vs. popular

- **Claude Code nativo** oferece resumabilidade de **transcript** (`--resume`/`-c`/`--continue`), `/clear`, `/compact` + auto-compaction, `CLAUDE.md` auto-carregado, plan mode, TodoWrite, Skills, subagentes e prompt caching (reuso de prefixo estável). **Não** oferece gestão explícita de "sessão de feature" em arquivo — é exatamente a lacuna que o worklog do Onion preenche legitimamente.
- **Comunidade SDD** (Spec-Kit, OpenSpec, Kiro) converge em: arquivos de plano/checklist em Markdown como estado retomável; separação "o que temos" (spec) vs "o que mudamos" (delta); checkboxes legíveis por humano e máquina; **anti-padrão** de over-specification e de "context dump".
- **Síntese:** o worklog do Onion **agrega valor** onde o nativo é ausente (metadados, decisões, handoff), mas hoje **briga** com o nativo (duplica resumabilidade sem citá-lo) e **se sabota** (lê 50KB quando o nativo+KB pedem carga progressiva). A refatoração torna as camadas **complementares**.

---

## 4. Decisão de design (resumo)

1. **Contrato unificado** com dois estados de ciclo de vida: **ACTIVE** (slug, 5 arquivos incl. `STATE.md` novo) e **ARCHIVED** (timestamp, 7 arquivos), numa única SSOT que todos os outros arquivos **citam**.
2. **`STATE.md`** — índice Tier-0 (~1KB) com ponteiro `NEXT` autoritativo, resolvendo D5/D6; resume passa de ~12–40K para ~300 tokens.
3. **Terminologia** `worklog`/`transcript` + integração nativa documentada (resume frio vs. quente, checkpoint antes de `/compact`).
4. **Vocabulário** `[DONE]/[ACTIVE]/[TODO]` (token ASCII; emoji decorativo).
5. **Versionamento** = escolha consciente por projeto, documentada na SSOT.
6. **Poda** dos 2 templates órfãos.

Plano de execução faseado e verificação: ver o plano aprovado da sessão (`refactor/sessions-worklog-protocol`).
