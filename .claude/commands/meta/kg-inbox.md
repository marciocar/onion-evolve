---
name: kg-inbox
description: Processa a fila de propostas de escrita no grafo (docs/evolution/kg-inbox/) — a perna de SELAGEM do write-leg (F4b). Lista as propostas pendentes, roda o radar advisory em cada uma, e para cada decide SELAR (integrar no grafo vivo + git mv → _sealed/) ou REJEITAR (git mv → _rejected/ com motivo). É o mecanismo que impede a fila de acumular sem controle. Human-in-the-loop na TRIAGEM (o que mora no core é juízo), mecânico no resto.
category: meta
tags: [kg, kg-inbox, write-leg, sealing, i3, self-evolution, sdaal]
version: "1.0.0"
updated: "2026-08-21"
allowed-tools: Read Write Edit Grep Glob Bash(ls docs/evolution/kg-inbox/*) Bash(git mv docs/evolution/kg-inbox/*) Bash(bash .claude/validation/kg-radar.sh*) Bash(bash .claude/validation/onion-version.sh) Bash(git -C * log*)
argument-hint: "[--list | <slug-da-proposta>]  (sem arg = processa TODA a fila; --list = só mostra sem decidir)"
---

# 🧅 /meta:kg-inbox — selar a fila de propostas de escrita no grafo

A perna que faltava do **write-leg (F4b)**: `propose_kg_write` (via MCP `onion-exec`, ou qualquer
produtor) grava uma **proposta** em `docs/evolution/kg-inbox/<slug>-<ts>.proposal.kg.yaml` — **nunca
no grafo vivo** (I3, um escritor por repo). Este comando é o **selo**: o único ato que integra uma
proposta ao grafo vivo, ou a recusa. Sem ele a fila acumula sem controle (o gatilho que o criou:
2 propostas paradas, medido 2026-08-21).

> **O que este comando NÃO é.** Não é `propose_kg_write` (o *produtor* da proposta). Não é
> `/meta:co-evolve` (fila de mensagens entre repos). É o **consumidor** da fila `kg-inbox`, o
> equivalente do "core sela" que o README da fila descreve.

## Passo 1 — Guarda de papel (só CORE)

Ler `role:` do stamp `.claude/.onion-version` (só se ausente, cair para
`bash .claude/validation/onion-version.sh`). `role: adopted|hub` → **parar**: o adotante tem a
própria fila; a sessão do core não sela grafo alheio (I3). `role: source` → segue.

## Passo 2 — Levantar a fila

Listar `docs/evolution/kg-inbox/*.proposal.kg.yaml` (a raiz da fila — **não** `_sealed/`/`_rejected/`).
Fila vazia → reportar "nada a selar" e parar. Com `--list`: só mostrar o inventário (Passo 3 sem decidir).

Para cada proposta, ler o **cabeçalho** (`# origem: … · recebida: …`) — a proveniência importa na triagem.

## Passo 3 — Radar advisory + triagem (o juízo)

Para cada proposta:
1. `bash .claude/validation/kg-radar.sh <proposta>` — advisory, **não** gate (a proposta é fragmento;
   órfãos/impact são esperados). Absorver integridade e o teor dos nós.
2. Ler os `nodes:`/`edges:` e **decidir** por estes critérios, nesta ordem:

   **(a) FRONTEIRA DE REPO (I3) — o filtro mais importante.** Este conhecimento mora no CORE?
   - Contexto de **negócio de adotante/tenant** (mapeamento de produto, mercado, cliente de um
     adotante) → **REJEITAR**: mora no repo do adotante, não no core. Selar aqui seria fonte paralela
     (anti-padrão fonte-diferente-de-derivação) e violaria a fronteira. *(Caso-semente: um chat no
     papel-de-negócio propôs mapeamento de um site de cliente — recusado do core.)*
   - Conhecimento sobre o **próprio framework** (capacidade, gap, doutrina, decisão de arquitetura)
     → candidato a SELAR.

   **(b) SINAL vs RUÍDO.** Artefato de teste, duplicata de nó já vivo, trivialidade → **REJEITAR** com motivo.

   **(c) SINAL REAL DO CORE** → **SELAR**.

## Passo 4 — Executar a decisão

**SELAR** (a proposta é sinal real do core):
1. Escolher o **grafo vivo alvo** (o mais próximo do domínio; prefira consolidar em grafo existente a
   proliferar grafos minúsculos). Se nenhum couber, um novo `docs/onion/graph/<slug>.kg.yaml`.
2. Integrar os `nodes:`/`edges:` no alvo — **renomear id na colisão**, e **conectar** cada nó novo ao
   grafo (nunca deixar órfão grau 0). Ajustar `impact` para 1-5 se vier fora.
3. `bash .claude/validation/kg-radar.sh <alvo>` → **DEVE exit 0**. Se reprovar, a selagem não fecha —
   corrigir a integração antes de mover.
4. `git mv docs/evolution/kg-inbox/<proposta> docs/evolution/kg-inbox/_sealed/` e **prepend** ao
   arquivo movido uma linha `# SELADO em <alvo> · <AAAA-MM-DD> · sessão do core` (Aufhebung: não some).

**REJEITAR** (fronteira/ruído):
1. `git mv docs/evolution/kg-inbox/<proposta> docs/evolution/kg-inbox/_rejected/` e **prepend**
   `# REJEITADO: <motivo em uma linha> · <AAAA-MM-DD>` (a genealogia fica; nada se apaga).
2. Se a rejeição revela um **gap real** (ex.: a escrita de um papel-de-negócio precisa de destino
   fora do core), **registrar esse gap** como nó `open` no grafo de estado apropriado — o motivo não
   evapora em prosa.

## Passo 5 — Fechar o backlog

Se este comando **construiu ou consumiu** o mecanismo de um nó `open` (ex.: `Q_SEALING_NO_MECHANISM`),
carimbar esse nó para `done` no grafo de estado + rodar o radar (exit 0). O grafo é o backlog: nada
fica parado sem o nó refletir.

Saída:
```
🧅 kg-inbox — N proposta(s) processada(s)
   ✅ SELADAS (M): <slug> → <grafo alvo>
   ⊘ REJEITADAS (K): <slug> (<motivo>)
   📭 fila agora: 0 pendentes
   ▶ grafo(s) tocado(s): radar exit 0
```

## ⚠️ Notas

- **Selar é o único ato que escreve o grafo vivo a partir da fila** — e é do CORE. O produtor
  (`propose_kg_write`) nunca escreve o vivo; este comando é o portão.
- **Radar exit 0 no alvo é gate de selagem** (não da proposta): integração que quebra o grafo não sela.
- **Human-in-the-loop na triagem**, mecânico no `git mv` — a fronteira de repo (I3) é juízo, não regra
  de lista.
- Verbo solto em `meta/`; não funde nem dispara workflows faseados.

## 🔗 Referências

- Produtor da fila: `ops/mcp-onion-exec/server.py` (`propose_kg_write`) · README: `docs/evolution/kg-inbox/README.md`
- Doutrina write-leg: `docs/evolution/research/librechat-kg-runtime-2026-08/` (`D_WRITE_LEG_AS_PROPOSAL`, `Q_SEALING_NO_MECHANISM`)
- Fronteira I3 / um escritor por repo: `docs/knowledge-base/concepts/knowledge-graph-sdaal.md`
