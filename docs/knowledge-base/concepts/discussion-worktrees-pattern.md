---
title: "Padrão — Discussion worktrees (frentes de discussão isoladas)"
category: concepts
tags: [worktree, discussao, exploracao, isolamento, paralelismo, branch-roles, seed]
status: candidato
date: 2026-07-11
---

# Padrão — Discussion worktrees (frentes de discussão isoladas)

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Categoria** | Concepts |
| **Aplicação** | Explorar N temas do Onion em paralelo, sem misturar assuntos e sem "surpreender" o core |
| **Estende** | [parallel-work-worktrees-pattern](parallel-work-worktrees-pattern.md) (a mecânica; este é o modo exploração) |
| **KBs irmãs** | [worktree-convention-2026](../../evolution/worktree-convention-2026.md) (layout SSOT) · [worklog-protocol](worklog-protocol.md) |

> É o `parallel-work-worktrees` **+ um contrato de isolamento + modo exploração**. Onde aquele entrega (feature
> → PR), este **pensa** (tema → notas/decisão) e só toca o core **sob pedido explícito** do maestro.

## 1. O problema

O maestro quer **pensar N temas do Onion em paralelo** (um app mobile, um Onion pessoal, guardrails, …) mas:
- **não misturar os assuntos** (cada tema uma conversa limpa);
- **não "surpreender" o core** — nada da exploração pode vazar pra `main` ou pra sessão-core sem ele querer;
- poder **trazer um tema pro core quando decidir** (pra verificar, cruzar ou promover a entrega).

Uma sessão-core só não resolve (mistura tudo no mesmo contexto). Worktrees de *entrega* também não (elas miram
merge). Falta uma variante **isolada e exploratória**.

## 2. O padrão

**1 tema = 1 worktree `discuss/<slug>` = 1 sessão Claude = 1 seed.** Cada frente vive na sua branch `discuss/*`,
**não pushada** (local-only), com um `SEED.md` que enquadra o tema. O maestro rotaciona entre elas (uma tela por
tema); o core não participa até ser chamado.

```bash
cd ~/<repo>
git worktree add -b discuss/<slug> ~/worktrees/<repo>/discuss-<slug> \
  "$(bash .claude/validation/resolve-integration-branch.sh)"
# escreve docs/discussions/<slug>/SEED.md (enquadramento) e commita NA branch (não pusha)
cd ~/worktrees/<repo>/discuss-<slug> && claude      # sessão dedicada, só este tema
```

## 3. O contrato de isolamento (o núcleo do padrão)

Quatro invariantes — é o que separa "discussão" de "frente de trabalho":

1. **Branch `discuss/*`, não pushada** — o conteúdo vive só local, na branch. Invisível pra `main`, pro remote
   e pra sessão-core (que só vê o working tree dela + o que está em `main`).
2. **Surfacing sob demanda** — o core **não lê** nenhuma discussão a menos que o maestro peça explicitamente
   ("verifica/traz o tema X pro core"). Sem pedido, o core nem olha.
3. **Assuntos não se misturam** — uma worktree = um tema; as sessões não se falam (o farol é por-worktree; ver
   caveat do padrão-pai).
4. **Nada promove sozinho** — nenhuma discussão vira PR/merge sem o maestro **promover** de propósito.

> A regra vale para o **agente-core** também: tratar uma `discuss/*` como leitura só quando convidado é
> aplicação direta do estudo [camadas de liberação](authorization-layers-intake-vs-execution.md) — o intake
> (ler/analisar) fica gated pelo pedido do dono, não é autônomo aqui **por escolha do maestro**.

## 4. O seed (`SEED.md`)

Cada worktree abre com um `docs/discussions/<slug>/SEED.md`: **enquadramento** (o que é o tema) · **por que
importa pro Onion** · **perguntas de partida** · **conexões** com o que já existe (pra a sessão nova começar
aterrada, não do zero). O seed é o análogo do `STATE.md` do worklog, mas para *explorar* em vez de *executar*.
Template: [`docs/discussions/_template/SEED.md`](../../discussions/_template/SEED.md).

### 4.1 Bloco Tier-0 do SEED (o que o mapa da constelação consome)

O frontmatter do SEED carrega um **bloco Tier-0** — o "STATE.md-de-exploração" da estrela, e o **único** que o
mapa macro lê (metadados, nunca o corpo):

```yaml
phase: SEED            # SEED | EXPLORE | DEEP | CONVERGE | PROMOTE | PARK
next_action: "próximo passo imperativo (análogo ao ## NEXT do STATE.md)"
scope_globs: ["docs/kg/"]     # globs que o estudo tende a tocar → detecta COLISÃO DE ESCOPO entre estrelas
objective_tags: ["NS1"]        # objetivo/north-star → detecta CONVERGÊNCIA DE OBJETIVO entre estrelas
```

**Recolher = atualizar `phase` + `next_action` antes de rotacionar** (handoff-commitado, como o `## NEXT` do
STATE.md). Os campos `scope_globs`/`objective_tags` alimentam a **anti-divergência** do modelo
[Constelação de Estudos](constellation-of-studies.md) — o mapa cruza-os entre estrelas pra alertar colisão de
escopo e convergência de objetivo **antes** de dois estudos divergirem sobre bases frágeis.

## 5. Ciclo de vida (pode nunca mergear — e tudo bem)

Uma discussão pode terminar como: **notas/uma decisão** (fica na branch como registro), **semente de feature
futura** (vira `feat/*` quando promovida), ou **descartada** (remove a worktree). Diferente da frente de
entrega, **merge não é o objetivo** — o objetivo é *pensar até clarear*.

**Promover pra o core**, quando o maestro decidir:
- *ler/cruzar:* `git -C ~/<repo> log discuss/<tema>` ou pedir ao core "verifica o tema X";
- *virar entrega:* renomear/cortar `feat/*` ou `docs/*` da branch e seguir o fluxo normal de PR.

## 6. Encaixe no branch-roles (faceta `exploration`)

No SDAAL de [branch-roles](../../analysis/onion-adr-branch-roles-sdaal-2026-07.md), `discuss/*` é uma **faceta
nova, `exploration`**: uma linha que existe pra **pensar, não pra versão nem entrega**. Distinta de `flow`
(integração), `environment` (deploy) e `lineage` (cliente). Não é protegida, não é base de PR, não sincroniza
com `main` — é estado de pensamento do maestro.

## 7. Disparo em lote (fleet)

Um bootstrap (ex.: `fleet-up.sh`) sobe uma sessão tmux com **uma janela por worktree** (discussão + trabalho),
cada uma no diretório certo. O maestro dá `attach`, navega (`Ctrl-b w`) e roda `claude` na frente que quiser.
Ver [remote-parallel-operation](../../onion/remote-parallel-operation.md) para a operação remota (tmux/mosh).

## 8. Quando NÃO usar

- Tema que **já é entrega** decidida → use frente de trabalho (`feat/*`/`docs/*`), não `discuss/*`.
- Assuntos que **precisam** do contexto-core junto → discuta na própria sessão-core (não isole por isolar).
- Frentes que tocam **os mesmos arquivos** → o isolamento é de *assunto*, não protege de colisão de escopo
  (vale o invariante um-escritor-por-escopo do padrão-pai).

## 9. Resumo executável

| Faça | Não faça |
|---|---|
| `discuss/<slug>` local, **não pushada** | pushar/PR-ar uma discussão sem promover |
| um `SEED.md` por tema (enquadramento) | abrir a sessão sem seed (começa do zero) |
| core lê só **sob pedido** do maestro | deixar o core ingerir discussões sozinho |
| um tema por worktree | misturar assuntos numa worktree |
| promover conscientemente (→ `feat/*` ou "traz pro core") | assumir que discussão vira entrega automática |
