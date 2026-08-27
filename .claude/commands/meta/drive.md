---
description: Conduz um plano-grafo até o fim com rigor Onion — censo→avança→Elenxo→dogfood→realign→checkpoint (degrau AUDIT)
allowed-tools: Bash, Read, Edit, Write, Task
model: opus
---

# 🚗 /meta:drive — conduzir um plano-grafo até o fim

Invocado na execução de um plano, este comando usa **todo o poder do Onion** (dogfood, KG-SSOT-first/
runtime, Elenxo, orquestração, SDAAL) para **avançar o plano** — pesquisando, medindo, executando,
achando superação — com o `/meta:realign` como **verificador-por-turno**. É o reforço-prosa do maestro
(*"siga até o final… nada parado sem controle"*) virado **maquinaria verificável e retomável**.

> **Contrato canônico:** [`onion-drive-doctrine.md`](../../../docs/knowledge-base/concepts/onion-drive-doctrine.md)
> (a escada, o laço, o roteamento por KIND, a tabela de selagem, as 6 regras, os anti-padrões). Este
> comando é a versão EXECUTÁVEL desse contrato; a KB é a doutrina. Leia-a antes de conduzir.

## Degrau e limites (não negociáveis)

- Opera no degrau **AUDIT**: conduz cada fio **até PR-verde sozinho**; **merge no main é 100% humano, em LOTE** num checkpoint.
- **Maestro-invocado.** Nunca auto-inicia, nunca `/loop`/`schedule`/cron sobre si (W7 = MOAT).
- **Budget-capped, retomável.** Sem budget não há laço. Retomada = re-censo (o status do nó É o progresso) + o checkpoint pendente no `STATE.md`.
- **MOAT (PARA sempre):** deploy · escrever repo alheio (I3) · merge de path vendorizado/outward-facing · agendar por relógio.

## Uso

```
/meta:drive [<grafo.kg.yaml>=fios-abertos] [--max-nodes N=4] [--node <id>] [--budget <tokens>]
```

## O laço (P0-P6)

### P0 — Legibilidade (para se falhar)
```bash
bash .claude/validation/kg-radar.sh <grafo> --integrity --schema   # exit≠0 → PARE
```
Não se conduz grafo que o motor não lê.

### P0.5 — Checkpoint pendente (guarda 1-passada/checkpoint)
Se `.claude/sessions/<drive-slug>/STATE.md` tem um lote **não-selado**, **PARE** e reporte: o maestro
sela o lote anterior antes de nova passada. (Anti-thrashing; o degrau AUDIT é batch-confirm.)

### P1 — Censo (determinístico)
```bash
bash .claude/validation/kg-drive-project.sh <grafo>        # FILA-PRONTA + BLOQUEADOS
```
`DONE` → nada a conduzir, encerre. `DEADLOCK` → **PARE** (predecessor travado; o bloqueador vira item
de alta atenção). `READY` → siga. Complete o censo com os fios em-voo: `git worktree list`, `gh pr list`,
inbox.

### P2 — Selecionar o lote
Top `--max-nodes` da FILA-PRONTA (ordem = atenção). Respeite `--budget` (pare de selecionar ao projetar
estouro). Um nó **em-voo nunca é re-selecionado** (status monotônico).

### P3 — Por nó (orquestra via `onion-orchestration`; teto 16 workers, budget/worker)
1. **CLASSIFICAR** `drive_kind` (campo do nó, senão julgue: `question`→research · `claim`→verification · `decision`→execution/decision).
2. **BEACON** `bash .claude/validation/session-beacon.sh check <repo>` **antes** de qualquer switch de worktree (I3).
3. **AVANÇAR** — roteie por KIND:
   | KIND | avançar = | delega a |
   |---|---|---|
   | **research** | colher evidência vs o vivo/externo | `onion-orchestration` fan-out-and-synthesize (+ WebSearch/WebFetch) + `write(KG)` |
   | **verification** | MEDIR o nó contra o vivo | `/meta:kg-freshness --node <id>` (mede, propõe — worker nunca escreve) |
   | **execution** | trabalho em **worktree própria até PR-verde** + dogfood | orquestração de execução (molde de fases do `/engineer:work`, conduzido até 1 PR) |
   | **decision** | enquadrar opções + Elenxo, **propor** a chamada | `adversarial-verification` |
4. **ELENXO** (só peso doutrinário — nomear/invariar/superar): worker adversarial com mandato de **REFUTAR**, **default = REPROVADO na dúvida**; a objeção sobrevivente vira **nó preservado**, nunca descartada. Cumpra as 5 etapas (`onion-elenxo-doctrine.md`) — a 5ª (`write(KG)` com `SUPERSEDES`/`REFUTES`) é a que mais falha.
5. **VEREDITO-DE-ESCRITA** — aplique a **tabela de selagem** (§ abaixo).
6. **ABORT-ON-ANOMALY** — colisão de beacon · CI vermelho inesperado · Elenxo reprovado → **PARE e reporte**. Retome a fase quebrada, **nunca contorne a jusante**.

### P4 — Fechar o loop (dogfood)
Toda execução: **rodou o artefato de verdade** + o **modo-de-falha** (não só happy-path)? Se corrigiu,
**fix→re-dogfood no MESMO loop**. **Lint-verde ≠ pronto** — o gate mecânico é uma camada; o uso vivo é a outra.

### P5 — Checkpoint em lote (escreve o `STATE.md` pendente)
Consolide: PRs-verdes **para merge humano** · vereditos **DRIFTED/REFUTED para selo** · decisões propostas · C-gated. Feche a reconciliação:
```bash
bash .claude/validation/kg-radar.sh <grafo> --integrity --schema   # exit 0 obrigatório
bash .claude/validation/kg-realign-project.sh <grafo> --check       # drift residual do lote
```

### P6 — Pare
Nenhuma passada nova enquanto o checkpoint pende. Reporte ao maestro: o que avançou, o que precisa de selo/merge, o budget gasto, e o próximo censo.

## Tabela de SELAGEM (postura AUDIT — mata o carimbo-automático)

**AUTO-avança:** append de `evidence` (research) · **CONFIRMED** com medição executada (carimba `verified_at`) · **DRIFTED** apenda nó-medido + `SUPERSEDES` (alvo fica `confirmed`) · execução até **PR-verde** · reparo determinístico de drift tipo-(c).
**PARA para o maestro selar:** **merge no main** · **REFUTED** (apendar solto quebra `--integrity`) · flip de status de verdade (→`superseded`/→`refuted`) · **decisão não-tomada** · **MOAT**.
**Invariante:** *o único caminho para um `verified_at` novo passa por uma medição executada* — o driver **apenda**, o humano **flipa** o status de verdade no checkpoint.

## Guardas de parada (stopping-conditions)
`DONE` (censo sem pronto) · `--max-nodes`/passada · `--budget` esgotado · checkpoint pendente · abort-on-anomaly · repetição idêntica (nó re-selecionado ⇒ pare). *"Confie num verificador determinístico, nunca no auto-relato do agente"* — o gate é `kg-radar`/`realign --check`, não a impressão de "feito".

## ⚠️ Honestidade declarada
- **Confia no substrato de ESCRITA, não de leitura.** O driver É o forcing-function `read(KG)→act→write(KG)` (o Censo é obrigatório), mas não força absorção no lado humano (`onion-drive-doctrine.md §5`).
- **Ordenação é GUARDA, não topológica** (Fase 1): `DEPENDS_ON` segura o dependente, não reordena. Topológica dirigida + degrau AUTOMATE + ponte prosa→grafo são **Fase 2 (gated)**.

## 🔗 Referências
- Contrato/doutrina: [`onion-drive-doctrine.md`](../../../docs/knowledge-base/concepts/onion-drive-doctrine.md)
- Censo: `.claude/validation/kg-drive-project.sh` · Verificador-por-turno: [`/meta:realign`](realign.md)
- Motores adapter: [`/meta:kg-freshness`](kg-freshness.md) · skill `onion-orchestration` · [`/meta:backlog`](backlog.md)
- Escada/precedente: `docs/analysis/onion-adr-autonomous-thread-runtime-2026-07.md`
