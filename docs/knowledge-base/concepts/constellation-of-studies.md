---
title: "Constelação de Estudos — modelo operacional do maestro (estudos isolados + core observatório sob convite)"
category: concepts
tags: [orquestracao, estudos-isolados, worktree, kg, reconciliacao, maestro, macro, anti-divergencia]
status: candidato
date: 2026-07-11
---

# Constelação de Estudos

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Categoria** | Concepts |
| **Aplicação** | O maestro roda N estudos isolados em paralelo; o core assiste sob convite (macro, reconciliação, surfacing) |
| **Compõe** | [discussion-worktrees](discussion-worktrees-pattern.md) · [worklog-protocol](worklog-protocol.md) · [knowledge-graph-sdaal](knowledge-graph-sdaal.md) · [authorization-layers](authorization-layers-intake-vs-execution.md) · doc-bridge ([co-evolution-reference](../../onion/co-evolution-reference.md)) |
| **ADR** | [onion-adr-constellation-operating-model-2026-07](../../analysis/onion-adr-constellation-operating-model-2026-07.md) (decisões, trade-offs, rollout gated) |

> Este KB **nomeia e amarra** o que já existe num **modelo operacional**. Não inventa mecanismo — compõe seis
> camadas maduras. As três ferramentas do core (mapa/radar/carteiro) são **design-alvo gated** (ver ADR); a
> Fase 0 entrega a doutrina + o schema (bloco Tier-0 do SEED) que o resto consome.

## 1. O problema

O maestro explora **N temas do Onion em paralelo** — cada um numa worktree `discuss/*` isolada. Isso resolve o
isolamento (assuntos não se misturam), mas abre quatro dores que o isolamento **sozinho** não cobre:

1. **Visão macro** — "o que está em andamento em TODAS as frentes?" (o `catch-up` vê uma; não há painel das N).
2. **Retrabalho / bases frágeis** — dois estudos podem, sem saber, resolver a mesma coisa ou construir soluções
   distintas sobre a **mesma premissa não-confirmada**, e só descobrir tarde demais (**dificuldade de
   convergência ou superação**).
3. **Assistência do core** — trazer um estudo pro core (verificar, cruzar) hoje é manual, e o core não pode
   "bisbilhotar" um estudo isolado sem quebrar o domínio do maestro.
4. **Profundidade** — descer fundo numa estrela e voltar ao macro sem perder o fio.

## 2. A metáfora (papéis)

| Papel | Quem | O que faz |
|---|---|---|
| ☀️ **Sol / dono** | o **maestro** | orquestra, rotaciona entre estrelas, é o **único** que promove ou descarta. Domínio soberano. |
| ⭐ **Estrela** | cada **estudo** | uma worktree `discuss/*` isolada, com seu **SEED** (enquadramento + Tier-0) e sua profundidade própria. |
| 🔭 **Observatório** | o **core** | observador-reconciliador **sob convite**. Nunca puxa uma estrela sozinho; oferece **3 serviços** quando chamado. |

**Os 3 serviços do observatório** (cada um estende uma peça existente — ver §4):
- 🗺️ **Mapa** — a visão macro: o Tier-0 de todas as estrelas ativas.
- 🔬 **Radar** — reconciliação cross-study: confronta premissas rivais e bases frágeis compartilhadas (via KG).
- 📬 **Carteiro** — surfacing: traz uma estrela pro core **sob convite**, sem quebrar isolamento (via doc-bridge).

## 3. O loop do maestro

```
isolar  →  explorar fundo  →  recolher ao macro  →  reconciliar  →  promover / descartar
  │             │                    │                   │                    │
 discuss/*    Tier-0→3 na          o MAPA da            o RADAR             → feat/* (promove)
 + SEED       estrela              constelação          cross-graph         ou remove wt (descarta)
```

O maestro **desce** numa estrela (aplica o [worklog-protocol](worklog-protocol.md) Tier-0→3 dentro dela),
**recolhe** atualizando o Tier-0 do SEED (handoff-commitado, como o `## NEXT` do STATE.md antes de rotacionar),
e o **mapa re-lê o SEED atualizado** — o mapa **é o Tier-0 dos Tier-0** (o `catch-up` do maestro entre N frentes).

## 4. Composição — cada peça nova ESTENDE uma existente

| Camada existente | Papel na Constelação | Peça do core (fase) |
|---|---|---|
| [discussion-worktrees](discussion-worktrees-pattern.md) — isolamento (4 invariantes) | a **estrela** isolada | frontmatter **Tier-0 no SEED** (Fase 0) |
| [worklog-protocol](worklog-protocol.md) — Tier-0→3, `## NEXT` | **profundidade** dentro da estrela | SEED = Tier-0 da estrela (Fase 0) |
| [knowledge-graph-sdaal](knowledge-graph-sdaal.md) + `kg-radar.sh` — REFUTES/SUPERSEDES | **reconciliador** epistêmico | 🔬 `kg-constellation-radar.sh` (Fase 2) |
| [authorization-layers](authorization-layers-intake-vs-execution.md) — intake × execução | core lê **só sob convite** | o gate do mapa e do carteiro |
| doc-bridge — `co-deliver.sh`, entrega-sem-commit (I3), W6 propor→confirmar | **surfacing** estrela→core | 📬 `study-deliver.sh` (Fase 3) |
| `federation-status-scan.sh` — scan determinístico + `--json` | molde da **agregação** | 🗺️ `constellation-map.sh` (Fase 1) |

## 5. A tensão-chave — visão macro SEM quebrar o isolamento

O isolamento diz "o core não lê uma estrela sem convite". Como, então, ter visão macro? **Só-metadados:** o
mapa lê **apenas o frontmatter + o bloco Tier-0 do SEED** (no disco, entre worktrees irmãs — não faz checkout,
não pusha), **nunca o corpo** da discussão. É **intake de metadados**, exatamente a linha do
[authorization-layers](authorization-layers-intake-vs-execution.md): guardar/ler o Tier-0 é intake seguro;
ler o conteúdo profundo ou **agir** exige o convite/gate. O SEED foi desenhado pra isso — ele é o Tier-0
público da estrela; o corpo é o Tier-1→3 privado.

## 6. Anti-divergência — o mecanismo (o que o maestro mais teme)

"Evitar que dois estudos construam soluções sobre bases frágeis que não convergem" **emerge da composição
mapa + radar**, disparando **antes** da divergência irreparável (hoje só notado post-hoc):

| Sinal | Fonte | Alerta |
|---|---|---|
| **Colisão de escopo** | mapa compara `scope_globs:` entre estrelas | "A e B tocam `docs/kg/`" — o um-escritor-por-escopo não é protegido pelo isolamento de *assunto* |
| **Convergência de objetivo** | mapa compara `objective_tags:` | "A e B miram NS2 — risco de duas soluções sobre a mesma tese" |
| **Premissas rivais** | radar: aresta `REFUTES`/`SUPERSEDES` cross-study | "`C_X`@A refuta `C_Y`@B — vão ter dificuldade de convergir" |
| **Base frágil compartilhada** | radar: `DEPENDS_ON` comum a nó `refuted`/baixa-confiança | "ambos apoiam-se em X não-confirmado" |

O **mapa** roda barato e cedo (metadados) → o maestro vê a colisão no macro diário. O **radar** roda sob
convite para o confronto epistêmico profundo. **KG reconcilia; git merge não** — o join cross-study é um
**overlay curado** (`docs/onion/graph/constellation.kg.yaml`, um "grafo-de-grafos" cujos nós são premissas de
estudos distintos e cujas arestas são REFUTES/SUPERSEDES entre elas), nunca merge de texto.

## 7. Gestão de profundidade cross-context

- **Descer** numa estrela = abrir a sessão da worktree e aplicar o Tier-0→3 **dentro** dela. O SEED é o Tier-0;
  as notas (`NOTE-*`, `research/`) são Tier-1→3.
- **Recolher** = atualizar o bloco Tier-0 do SEED (`next_action:` = o ponteiro durável, como o `## NEXT`) e sair.
- **Sem perder o fio** = o mapa re-lê o SEED atualizado. O `catch-up` reorienta **uma** frente; o **mapa
  reorienta a constelação** (os N Tier-0 num só painel).

## 8. Fronteiras (o que a Constelação NÃO é)

- **Não é a Federação.** Constelação = N estudos do **maestro numa máquina** (worktrees do mesmo repo).
  Federação = N **instâncias/repos** (cross-máquina, `members.yaml`, `federation-console`). Eixos ortogonais.
- **Não é fan-out de Workflow.** A `onion-orchestration` é fan-out de subagentes **efêmeros dentro de uma
  fase**; a Constelação é o eixo **worktree/tmux durável** que o maestro rotaciona à mão.
- **Não quebra isolamento.** Mapa e carteiro operam por metadados/convite; nunca pusham `discuss/*`, nunca
  auto-ingerem, nunca promovem sozinhos.

## 9. Resumo executável

| Faça | Não faça |
|---|---|
| Um SEED com bloco **Tier-0** por estrela (o Tier-0 público) | deixar o core ler o corpo de um estudo sem convite |
| Recolher = atualizar o `next_action:` do SEED (handoff-commitado) | rotacionar sem atualizar o Tier-0 (o mapa fica cego) |
| Reconciliar premissas rivais no **overlay KG** (REFUTES/SUPERSEDES) | mergear estudos via git (git merge não reconcilia verdades) |
| Deixar o **maestro** promover/descartar | o core promover uma estrela sozinho |
| Ver colisão de escopo/objetivo no mapa **cedo** | descobrir a divergência post-hoc, tarde demais |
