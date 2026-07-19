---
description: 🗺️ O MAPA da Constelação de Estudos — visão macro das N estrelas (estudos discuss/*) lendo SÓ os metadados (frontmatter+Tier-0) de cada SEED. Painel com phase · next_action · colisão de scope_globs · convergência de objective_tags · presença (farol vivo por worktree). Read-only, sob convite.
name: constellation
model: sonnet
allowed-tools: Read Bash(bash .claude/validation/constellation-map.sh*)
argument-hint: "[--json]"
category: meta
tags: [constelacao, estudos, worktree, macro, anti-divergencia, farol, presenca]
version: "1.0.0"
updated: "2026-07-19"
---

# /meta:constellation — o 🗺️ Mapa da Constelação de Estudos

O **catch-up das N frentes**: o "Tier-0 dos Tier-0". Enquanto o `/catch-up` reorienta **uma**
estrela, este comando reorienta a **constelação** — o painel macro de todos os estudos
`discuss/*` do maestro, **gerado** por `.claude/validation/constellation-map.sh` a partir do
frontmatter + bloco Tier-0 de cada `docs/discussions/*/SEED.md`.

> Doutrina: [constellation-of-studies.md](../../../docs/knowledge-base/concepts/constellation-of-studies.md)
> · ADR: [onion-adr-constellation-operating-model-2026-07.md](../../../docs/analysis/onion-adr-constellation-operating-model-2026-07.md)
> · Schema Tier-0: [docs/discussions/_template/SEED.md](../../../docs/discussions/_template/SEED.md)

## Invariantes (não-negociáveis — ADR §NÃO-fazer)

- **Read-only estrito** — o mapa nunca escreve, nunca faz checkout, **nunca pusha** estrela alheia.
- **Só-metadados** — lê APENAS o bloco frontmatter (1º `---` … 2º `---`) de cada SEED; o **corpo**
  da discussão **nunca** é lido. É intake de metadados ([authorization-layers](../../../docs/knowledge-base/concepts/authorization-layers-intake-vs-execution.md)),
  não leitura de conteúdo — é assim que o macro **não quebra o isolamento** da estrela.
- **Single-machine** — lê SEEDs/beacons entre worktrees irmãs na mesma máquina (o eixo
  cross-máquina é a **Federação**, ortogonal).

## Quando usar

- **Macro diário:** "o que está em andamento em TODAS as frentes?" (phase + next_action das N).
- **Anti-divergência (cedo, não post-hoc):** ver **colisão de escopo** (`scope_globs` em ≥2
  estrelas → um-escritor-por-escopo não é dado pelo isolamento de *assunto*) e **convergência de
  objetivo** (`objective_tags` em ≥2 → risco de duas soluções sobre a mesma tese).
- **Presença:** quais estrelas têm **farol vivo** agora (🕯️) — dobra o beacon key-by-worktree.

## Uso

```bash
# Painel humano das estrelas (default: <repo>/docs/discussions)
bash .claude/validation/constellation-map.sh

# JSON estruturado (stars[], scope_collisions[], objective_convergences[])
bash .claude/validation/constellation-map.sh --json

# Um dir de discussões alternativo (ex.: teste)
bash .claude/validation/constellation-map.sh --dir <path>
```

## Passos

1. Rodar `constellation-map.sh` (determinístico, sem LLM) — `--json` quando for compor/filtrar.
2. **Ler o painel a serviço do maestro:** destacar as fases em `PROMOTE`/`CONVERGE` (prontas p/
   decidir), as **colisões de escopo** (coordenar o um-escritor-por-escopo) e as **convergências**
   (candidatas a reconciliar).
3. Numa **colisão/convergência real**, oferecer o próximo serviço do observatório: 🔬 **radar**
   (`kg-constellation-radar.sh`, Fase 2 **gated** — reconciliação epistêmica cross-study) — **sob
   convite**, nunca automático.
4. **Nunca** promover/descartar uma estrela pelo maestro — o mapa **informa**, o sol decide.

## Notas

- **Recolher antes de rotacionar:** o mapa só enxerga o que o SEED declara. Ao sair de uma
  estrela, atualize `phase` + `next_action` do SEED (handoff-commitado) — senão o macro fica cego.
- O verbo de coordenação de sessão (isolar/ceder/sweep) **não** vive aqui: o mapa **substitui** o
  farol como sinal de colisão entre estrelas via `scope_globs` (ADR §trade-offs).
- Presença usa o TTL do farol (`ONION_BEACON_TTL_MIN`, default 480 min).
