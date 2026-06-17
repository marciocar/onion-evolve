---
title: "Capacidade (RASCUNHO) — catálogo de playbooks de estratégia"
date: 2026-06-17
local-datetime: "2026-06-17 15:18 -03 (America/Sao_Paulo)"
type: capability-draft
status: proposed
authored-in: onion-evolve (sala de design)
for-instance: sala de obra (.claude/ implementação)
depends-on: ./onion-strategy-layer-adr-draft-2026-06-17.md
related:
  - ../../.claude/skills/onion-fleet/
  - ../../.claude/skills/onion-patterns/
  - ../../.claude/commands/meta/fleet.md
  - ../../.claude/commands/meta/analyze-complex-problem.md
---

# Capacidade (RASCUNHO) — catálogo de playbooks de estratégia

> **Doc 2 de 4** do handoff de 2026-06-17 15:18 -03. **Revisado** após esclarecimento do
> usuário: o primitivo central não é um *deliberador*, é um **catálogo de playbooks** que o
> agente **reconhece e aplica**. Deliberar é o fallback (Doc 1, Princípio 1), não o produto.
> Depende do Doc 1. Não implementar antes de a doutrina ser reconciliada.

## Problema que materializa

A doutrina (Doc 1) diz: **reconhecer antes de compor**. Falta o **artefato consultável** que
torna o reconhecimento possível — um catálogo onde `situação → fluxo nomeado → grupo de
ferramentas → sequência` está escrito, versionado e auditável. Sem ele, "catálogo-first" é
intenção sem suporte: o agente continua recompondo do zero porque não há catálogo para casar.

## Forma proposta: catálogo de playbooks (skill) + reconhecedor leve

### O artefato: `strategy-playbooks` (catálogo)

Um catálogo de **playbooks nomeados**, cada um uma entrada estruturada:

```yaml
- playbook: refatorar-feature-legada
  reconhece-quando:                 # gatilhos de match (o "caso")
    - "código existente + mudança de comportamento + sem cobertura de teste"
  fluxo:                            # a sequência validada
    - /engineer:plan
    - /engineer:start
    - review paralelo (branch-code-reviewer + branch-test-planner)
    - /engineer:pre-pr → /engineer:pr
  grupo-de-ferramentas: [Read, Edit, Bash(git *), @code-reviewer, @test-engineer]
  reroute-quando:                   # gatilhos de redirecionamento (Doc 1, Princípio 3)
    - "plano revela mudança arquitetural → escalar para /product:light-arch"
  custo: baixo-médio
```

Exemplos de playbooks que já existem **implícitos** no Onion e mereceriam entrada explícita:
- `descoberta-a-backlog` → `/product:collect → ... → /product:feature`
- `planejamento-a-entrega` → `/engineer:plan → start → work → pre-pr → pr`
- `auditoria-ampla` → `onion-fleet` fan-out-and-synthesize + juiz adversarial
- `hotfix-emergencial` → `/engineer:hotfix`
- `adoção-de-repo` → `/meta:adopt`

> Boa parte do trabalho é **destilar o que já é tácito** num catálogo legível, não inventar
> fluxos novos. O valor é tornar o reconhecimento **consultável**, não criar estratégia.

### O reconhecedor (leve, barato)

Não precisa de comando pesado. O reconhecimento pode ser:
- **Progressive disclosure via skill**: a skill `strategy-playbooks` injeta o índice de
  playbooks no contexto; o agente casa o objetivo contra `reconhece-quando` e aplica.
- Sem match → cai no fallback do Doc 1 (deliberação por risco) → o resíduo deliberado
  **vira proposta de novo playbook** (o catálogo aprende, fecha o ciclo).

### Por que skill, não comando novo (provável)

- O catálogo é **conhecimento consultável sob demanda** → é a definição de skill (carrega
  quando relevante, não polui contexto). Encaixa em `.claude/skills/`.
- Reconhecimento é leve; deliberação reusa `onion-fleet`/`Workflow` (não reinventa).
- Um **comando** (`/meta:strategize`) só se justifica se o usuário quiser *invocar
  explicitamente* "escolha a estratégia para isto" — provavelmente desnecessário no começo.

## Relação com o que já existe (não duplicar)

| Já existe | O que faz | O que o catálogo adiciona |
|-----------|-----------|---------------------------|
| `onion-fleet` (skill) | reconhece trabalho de fan-out → emite padrão de Workflow | catálogo por **caso de uso**, não só por forma de orquestração |
| `onion-patterns` (skill) | convenções de estrutura/nomenclatura | playbooks de **execução** (fluxo+ferramentas), não estrutura |
| padrões canônicos do Workflow | fan-out, judge panel, pipeline… | mapeia **situação → qual padrão**, em vez de listar padrões soltos |
| `/meta:analyze-complex-problem` | análise de UM problema | reconhecimento de caso → playbook, não análise |

> ⚠️ **Risco de sobreposição real**: `onion-fleet` + `onion-patterns` juntas já cobrem talvez
> 60% disto. A pergunta honesta para a sala de obra: o catálogo é uma **skill nova**, ou uma
> **extensão de `onion-patterns`** (adicionar seção "playbooks de estratégia")? Decidir contra
> "não inchar a frota sem ganho" (CLAUDE.md). Meu palpite: **estender `onion-patterns`** primeiro.

## Critério de aceitação (esboço)

1. ≥5 playbooks destilados do que já é tácito, com `reconhece-quando` + `fluxo` + `grupo` + `reroute`.
2. Reconhecimento funciona por skill (sem comando pesado obrigatório).
3. Sem match → fallback explícito para deliberação (Doc 1); resíduo vira proposta de playbook.
4. Não duplica `onion-fleet`/`onion-patterns` — estende ou se justifica.

## Decisão pendente para a sala de obra

- **Skill nova vs estender `onion-patterns`?** (recomendo estender primeiro.)
- O catálogo precisa de um **comando de invocação explícita** (`/meta:strategize`), ou a skill
  de reconhecimento automático basta? (recomendo: só skill no começo.)
- Quantos playbooks valem a pena destilar agora vs deixar o catálogo crescer por uso?
