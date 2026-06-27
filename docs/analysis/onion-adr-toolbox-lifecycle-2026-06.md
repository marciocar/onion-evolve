---
title: 'ADR — Ciclo de vida do toolbox: régua de classificação P0-P3 + coesão dos create-* sobre o substrato existente'
date: 2026-06-27
type: adr
status: accepted
decision-scope: meta / toolbox-lifecycle
supersedes: none
deciders: maestro + sessão de evolução
context_freshness: 2026-06-27
related:
  - onion-toolbox-s1-scoping-2026-06.md (discovery S1 — ASSESS; origem do critério)
  - onion-adr-manual-relay-subprotocol-2026-06.md (S2 — 1º caso concreto do critério)
  - onion-adr-domain-context-lifecycle-2026-06.md (modelo CRUD+ com fase Manage — espelhado aqui)
  - ../../.claude/skills/onion/SKILL.md (régua P0-P3 vive aqui — TRIAL camada 1, PR #184)
  - ../../.claude/commands/common/prompts/inventory-sync-after-create.md (passo pós-criação — camada 2, PR #183)
  - ../knowledge-base/concepts/onion-dogfooding-doctrine.md (gate mecânico vs gate de uso)
---

# ADR — Ciclo de vida do toolbox

> **Status: ACEITO** (2026-06-27) para a **doutrina + as 3 camadas trialadas e mergeadas** (régua P0-P3,
> passo inventory-sync, fixes de outlier). **Provisório/deferido** para os metadados de governança
> (`kind`/`status`), dedup e registry — gated por **gate-de-uso** (radar: trial→adopt só com uso real).
> Honesto: a régua acabou de aterrar; este ADR **registra a decisão e fixa o critério de promoção**, não
> declara canon battle-tested.

## Contexto / Origem (sinal S1)

Sinal de campo S1 (`rhilo-metagamify`): os 7 `/meta:create-*` eram **átomos isolados** — sem etapa que
classificasse "que artefato eu devo criar?", sem coesão entre si, e sem fechar o ciclo de vida (a criação
deixava o inventário em **HARD-fail silencioso** da Regra 8). O discovery S1 (frota fan-out-and-synthesize,
PR #181) destilou o veredito: **o toolbox não é infraestrutura nova — é uma régua de decisão + cross-linkagem
dos átomos existentes, sobre o substrato que o core já tem** (`inventory.sh` SSOT + `lint-artifacts.sh` gate +
`/meta:evolve`/`*-freshness`). O critério já tinha um 1º caso concreto provado: o S2 (`/meta:co-relay`).

## Decisão 1 — A régua de classificação P0-P3 é a porta de entrada do toolbox (TRIALADA, PR #184)

Antes de criar um procedimento recorrente, decidir **a caixa** com 4 perguntas (vivem em `onion/SKILL.md`,
seção "Criar Componentes"):
- **P0 — Já existe?** → EXTEND/FIX, não crie (anti-proliferação de átomos).
- **P1 — Determinístico ou juízo?** → **script** (`.claude/validation/` guards de CI; `.claude/utils/` helpers) vs P2.
- **P2 — Semântica ou invocação?** → **skill** / **comando** / **KB** / **agente** / **abstração SDAAL**.
- **P3 — Irreversível?** → **+ gate humano** (camada ortogonal).

**Combinação canônica:** procedimento completo ≈ script (controle) + comando (juízo) + KB/ADR (doutrina) +
gate (se irreversível). Template de referência: a vertical `co-*` (`co-*.sh` + `co-*.md` + ADR + human-gate).

## Decisão 2 — Criar acopla a sincronizar a SSOT (TRIALADA, PR #183)

Todo `/meta:create-*` que gera artefato **contado pela SSOT** (command/agent/skill/KB) executa o passo final
`common:prompts:inventory-sync-after-create` (rodar `inventory.sh` → regravar `inventory.md`; a Regra 8 é
HARD). Fecha o **HARD-fail silencioso**. Modelo: *entrega-sem-commit* do co-deliver (o ato carrega sua
consequência explícita). `create-abstraction`/`create-task-structure` ficam de fora (não contados).

## Decisão 3 — Coesão dos átomos + correção de outliers (TRIALADA, PR #185)

O toolbox "se enxerga como conjunto": cross-links `related_commands` fechados entre os `create-*`;
`create-agent-express` passa a emitir **path categorizado** (`.claude/agents/<categoria>/`); e
`create-task-structure` move para `/product/` (decompõe trabalho de produto, não cria artefato Onion).

## Decisão 4 — Ciclo de vida reusa o substrato (sem infra nova)

- **Inventário/SSOT:** `inventory.sh` + Regra 8 (HARD) — já é o catálogo canônico.
- **Frescor:** `/meta:kb-freshness` + `/meta:context-freshness` (fan-out 1-worker-por-arquivo) — estender
  escopo a skills/comandos datados quando preciso.
- **Dedup:** **manual** (gate P0 grep + `/meta:evolve` periódico). **NÃO** automatizar (custo que nem o
  ecossistema resolveu).
- **Promoção:** disciplina do radar (assess→trial→adopt), espelhando o modelo do
  `onion-adr-domain-context-lifecycle` (fase Manage de 1ª classe).

## Decisão 5 — Deferido (gated por gate-de-uso) — NÃO adotar agora

- **Metadados `kind`/`status`** no frontmatter (`script|workflow|reference|command|agent|abstraction` +
  `draft→stable→deprecated`): governança que **ninguém exerceu ainda** → risco de virar ritual stale. Quando
  promover: começar só pelos provisórios conhecidos; mapear `kind` p/ os campos oficiais do Agent Skills
  (`disable-model-invocation`/`user-invocable`), não inventar taxonomia paralela.
- **Dedup automático por embedding** e **registry externo:** rejeitados (a SSOT já existe; custo alto).

## Gatilho de promoção (das Decisões 5)

Promover `kind`/`status` quando a régua P0-P3 acumular **uso real** (algumas criações guiadas por ela) E
houver dor concreta de governança (artefato provisório esquecido, drift de status). Até lá, "provisório/gated"
vive informal na memória + neste ADR.

## Coerência com invariantes

- **Dogfood é o padrão master:** Decisões 1-3 são TRIALADAS + mergeadas (gate mecânico verde: lint 0/0,
  selftest verde). O gate-de-uso da régua **começa agora** — este ADR não o antecipa.
- **Anti-proliferação:** a régua foi materializada **estendendo `onion/SKILL.md`**, não criando um 8º átomo —
  aplicou P0 a si mesma.
- **SSOT deriva, não repete:** o passo inventory-sync reforça a Regra 8, não a substitui.

## Consequências

- Os `/meta:create-*` agora têm porta de entrada (régua) + fecho (inventory-sync) + coesão (cross-links).
- O critério "script (controle) + comando (juízo) + ADR (doutrina) + gate" vira a referência de como o Onion
  cria capacidades — destilado do S2, generalizado pelo S1.
- Nada de governança `kind`/`status` até o gate-de-uso disparar.

## Referências

- Discovery (ASSESS): [`onion-toolbox-s1-scoping-2026-06.md`](onion-toolbox-s1-scoping-2026-06.md)
- 1º caso concreto: [`onion-adr-manual-relay-subprotocol-2026-06.md`](onion-adr-manual-relay-subprotocol-2026-06.md)
- TRIAL: PRs #183 (inventory-sync), #184 (régua P0-P3), #185 (outliers)
- Régua viva: `.claude/skills/onion/SKILL.md` (seção "Criar Componentes")
