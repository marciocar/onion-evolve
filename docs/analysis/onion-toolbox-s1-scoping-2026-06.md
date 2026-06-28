---
title: 'Discovery S1 — padrão "toolbox": régua de classificação + ciclo de vida sobre o substrato existente'
date: 2026-06-27
type: evolution-backlog
status: assess
decision-scope: meta / toolbox-lifecycle
deciders: maestro + sessão de evolução
context_freshness: 2026-06-27
related:
  - ../evolution/inbox/_processed/2026-06-24-sinal-padrao-toolbox.md (sinal S1 — origem)
  - onion-adr-manual-relay-subprotocol-2026-06.md (S2 — 1º caso concreto; destilou o critério)
  - onion-adr-domain-context-lifecycle-2026-06.md (modelo de ciclo de vida CRUD+ a reusar)
  - ../../.claude/skills/onion/SKILL.md (tabela de roteamento estática — onde a régua se ancora)
---

# Discovery S1 — padrão "toolbox"

> **Status: ASSESS** (orquestração fan-out-and-synthesize, read-only — `onion-orchestration` → `Workflow`, 3 workers +
> síntese). **Propõe, não muta.** A materialização é **gated** pela disciplina do radar (assess→trial→adopt,
> só com dogfood). Origem: sinal de campo S1 (`rhilo-metagamify`).

## Veredito em uma linha

**O "toolbox" do Onion NÃO é infraestrutura nova — é uma RÉGUA DE DECISÃO (4 perguntas) + cross-linkagem dos
átomos existentes, sobre o substrato que o core já tem** (`inventory.sh` SSOT + `lint-artifacts.sh` gate +
`/meta:evolve`/`*-freshness`). O padrão Agent Skills da Anthropic já resolveu o *container* (SKILL.md +
progressive disclosure) e o *carregamento*; deixou aberto exatamente o gap do S1: **classificação semântica +
gestão de ciclo de vida**.

## Problema (com evidência)

Os 7 comandos `/meta:create-*` são **átomos isolados**: cada um abre direto em "Análise de Contexto", sem etapa
que classifique *"que artefato eu devo criar?"*. A tabela de roteamento existe **estática** em
`onion/SKILL.md` (~L98-103), mas a **lógica** de classificação não vive em nenhum `create-*` nem no
orquestrador — o usuário já tem de saber a caixa antes de invocar. Três sintomas + dois outliers:

1. **Cross-links assimétricos** entre os `create-*` (ex.: `create-command`/`create-agent` não linkam
   `create-skill`; `create-knowledge-base` não linka irmãos) → o toolbox não "se enxerga como conjunto".
2. **Nenhum `create-*` re-roda o inventário SSOT no pós-criação** → como a Regra 8 (`check_inventory_sync`) é
   **HARD**, cada criação deixa o repo em **HARD-fail silencioso** até o próximo `/meta:inventory` manual.
3. **5 skills, todas SKILL.md flat, zero subpastas** — divergem do layout `scripts/`/`references/`/`examples/`
   documentado (não-usado; não é rejeição, é que nenhuma precisou — oportunidade, não dívida).
4. **Outlier A:** `create-agent-express` emite path **flat** `.claude/agents/<name>.md`, violando a estrutura
   categorizada `.claude/agents/<categoria>/`.
5. **Outlier B:** `create-task-structure` não cria artefato Onion (decompõe trabalho de produto → delega
   `@task-specialist`/`/product/task`) — pertence a `/product/`, não `/meta/`.

## A RÉGUA DE DECISÃO (4 perguntas) — ancorada no critério destilado pelo S2

- **P0 — JÁ EXISTE?** `grep`/`find` no namespace **antes** de criar. Se um artefato cobre, ou se é extensão
  natural (flag, parâmetro, seção a um SKILL.md) → **EXTEND/FIX, não crie**. Sinal de proliferação: o nome do
  "novo" começa igual/é subconjunto de um existente.
- **P1 — DETERMINÍSTICO ou JULGAMENTO?** Output idêntico p/ o mesmo input, sem contexto de sessão (regex,
  contagem, diff, SSOT) → **SCRIPT** (`.claude/validation/` p/ guards do CI; `.claude/utils/` p/ helpers
  reusados por comandos/agentes). Requer contexto/intenção/trade-off → P2.
- **P2 — ATIVA POR SEMÂNTICA ou INVOCAÇÃO EXPLÍCITA?** (a) semântica/domínio/expertise recorrente → **SKILL**
  (SKILL.md <500 linhas + `references/`/`scripts/` sob demanda); (b) ponto de entrada consciente `/nome`, com
  juízo de quando/como → **COMANDO** fino (cita KB, chama script, delega a agente; sem teoria embutida);
  (c) conhecimento de fundo lido pontualmente (doutrina/ADR/templates) → **KB** (litmus: se remover o bloco
  não quebra o grafo executável do comando, é KB); (d) especialista delegável → **AGENT**
  `.claude/agents/<categoria>/`; (e) façade multi-provider → **ABSTRACTION** SDAAL.
- **P3 — É IRREVERSÍVEL?** Muta estado externo sem undo (deletar branch, push --force, deploy, merge de
  release, bulk task-manager) → **HUMAN GATE** obrigatório. É **camada ortogonal**, soma-se a qualquer caixa.

**Combinação canônica** (procedimento completo quase sempre é combinação): **CONTROLE** (script) + **JUÍZO**
(comando) + **DOUTRINA** (KB/ADR) + **GATE** (humano, se irreversível). Template de referência já no core: a
vertical **co-*** (`co-relay.sh`/`co-deliver.sh` + `co-*.md` + ADR + human-gate no `co-announce`). Regra dura:
nunca script órfão sem comando (não é descoberto), nem comando de consequência permanente sem KB de doutrina.

## Ciclo de vida — reusando o substrato (zero infra nova)

- **Inventário (SSOT):** `inventory.sh` já computa do filesystem. **Gap:** nenhum `create-*` re-roda no
  pós-criação. **Fix:** passo final padrão em cada `create-*` ("rodar `inventory.sh` → regravar `inventory.md`;
  Regra 8 é HARD"), no modelo *entrega-sem-commit* do co-deliver (ato determinístico, sincronia explicitada).
- **Classificação (`kind`) e status (`draft→stable→deprecated`):** campos **opcionais** no frontmatter,
  espelhando `disable-model-invocation`/`user-invocable` do padrão Agent Skills. Enforce pela **mesma via** que
  já existe (lint + `manifest.tsv`), não um enforcement novo. Formaliza o que hoje vive informal ("provisório"/
  "gated").
- **Frescor:** `/meta:kb-freshness` + `/meta:context-freshness` já cobrem; estender escopo (ou cross-linkar)
  p/ skills/comandos datados. **Sem** mecanismo de expiração novo.
- **Dedup:** **NÃO automatizar agora** (o ecossistema não resolveu; embedding-similarity tem custo alto p/ o
  tamanho atual). Manter gate manual P0 (grep) + `/meta:evolve` periódico. `inventory.md` já é o catálogo.

## Caminho recomendado (gated por dogfood)

1. **ASSESS** ✅ (este doc) — recorrência confirmada (7 átomos + tabela estática, todos sem classificador).
2. **TRIAL camada 1 (o gap real):** a régua P0-P3 como **seção no `onion/SKILL.md`** (estender o skill, **não**
   criar 8º átomo — aplicar P0 a si mesmo). Dogfoodar em 2-3 casos reais antes de declarar pronto.
3. **TRIAL camada 2 (coesão pós-criação, baixo risco/alto retorno):** passo `inventory.sh` em cada `create-*`.
4. **TRIAL camada 3 (outliers, paralelo):** (a) `create-agent-express` → path categorizado; (b)
   `create-task-structure` → `/product/`; (c) fechar cross-links faltantes. Cada um muta inventário → re-rodar
   `inventory.sh` + lint; fechar o loop fix→re-dogfood (grep de referências antes de mover).
5. **TRIAL camada 4 (metadados `kind`/`status`, opcional):** só pelos provisórios conhecidos primeiro; não
   migrar tudo de uma vez.
6. **ADOPT** — só após gate mecânico VERDE + gate de uso; registrar fixtures, citar a régua/ADR no SKILL.md.
7. **NÃO FAZER agora:** dedup por embedding; registry externo (a SSOT já existe); migração big-bang das 5
   skills flat p/ subpastas (incremental, só >500 linhas ou com deps externas).

## Riscos

- **Proliferação de átomos** — criar `/meta:create` orquestrador agravaria o problema diagnosticado →
  estender o SKILL existente (a régua ativa por semântica → caixa SKILL).
- **Over-engineering de governança** — `kind`/`status`/`semver` virando ritual stale → campos opcionais,
  enforce só onde o lint já roda, começar pelos provisórios.
- **Dedup prematuro** — custo que nem o ecossistema resolveu → gate manual.
- **HARD-fail mascarado** — o passo `inventory.sh` nos `create-*` é conveniência, **não** substitui a Regra 8
  (a rede de CI permanece).
- **Regressão nos outliers** — mover/renomear quebra referências → grep antes, re-rodar lint, re-revisar o fix.
- **Descasamento com o padrão externo** — `kind` é convenção local → **mapear** p/ os campos oficiais
  (`reference`→`user-invocable:false`; `command`→`disable-model-invocation:true`), não inventar taxonomia paralela.

## Próximo passo concreto

Abrir o **ADR de ciclo de vida do toolbox** (reusando o modelo `onion-adr-domain-context-lifecycle-2026-06.md`)
selando as **2 decisões baratas e de alto retorno**: (1) a régua de 4 perguntas como seção no `onion/SKILL.md`;
(2) o passo pós-criação `inventory.sh` em cada `create-*`. Outliers entram em TRIAL em paralelo. Tudo
**human-gated** — propõe, não muta.
