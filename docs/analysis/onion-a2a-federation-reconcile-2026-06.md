---
title: "A2A/federação — reconciliação do sinal externo com a doutrina (já adjudicada) + fechamento do radar de orquestração"
date: 2026-06-21
type: analysis
status: proposed / living
authority: leitura-de-sinal contra doutrina existente; NÃO redefine a decisão A2A (essa é do ADR)
research: conversa externa (share 332f6246) confrontada com a doutrina A2A/federação do Onion
last-review: 2026-06-21
next-review-trigger: "se o gatilho do ADR A2A disparar (1º consumer não-Onion / interop real nomeada) · OU nova evidência que reabra runtime vs formato"
relates:
  - ./onion-federation-adr-a2a-format-interop-2026-06.md
  - ./onion-adr-comms-transport-vs-execution-2026-06.md
  - ./onion-orchestration-external-radar-2026-06.md
  - ../evolution/rfc/rfc-0001-co-evolution-comms.md
  - ../knowledge-base/concepts/multi-repo-federation.md
---

# A2A/federação — reconciliação do sinal externo + fechamento do radar

> **Natureza:** nota de **leitura-de-sinal**, não de doutrina. A decisão A2A já existe e é canônica —
> esta nota **defere** a ela e apenas reconcilia o que a conversa externa trouxe. Aprofunda o item 🟡
> A2A do [radar de orquestração](./onion-orchestration-external-radar-2026-06.md) e o **fecha** (3º/último eixo).

## 1. O eixo já está adjudicado (SSOT)

Diferente de TOPO e MATH, **A2A não é questão aberta**. A SSOT é o
[**ADR — A2A como projeção de formato, não runtime**](./onion-federation-adr-a2a-format-interop-2026-06.md)
(✅ aceito 2026-06-15), reforçado por [RFC-0001](../evolution/rfc/rfc-0001-co-evolution-comms.md),
[ADR de comms](./onion-adr-comms-transport-vs-execution-2026-06.md), os comandos `/meta:federation-*`
e a KB [`multi-repo-federation.md §7`](../knowledge-base/concepts/multi-repo-federation.md).

**Posição canônica (1 frase):** *Runtime A2A (IA-fala-IA em tempo real) é linha vermelha inegociável
(Fase 5 abandonada); o **formato** A2A (Agent Card como projeção one-way do `members.yaml`) é permitido
em princípio, mas **diferido** até surgir o 1º consumer não-Onion OU necessidade real de interop
externa.* (Detalhe, mapeamento campo-a-campo e alternativas: no ADR — **não repetidos aqui**.)

## 2. Reconciliação: o que a conversa externa acertou — e o que perdeu

- ✅ **Acertou:** A2A é interop maduro (Linux Foundation, 150+ orgs); o stack de 2 camadas (MCP
  vertical + A2A horizontal) é uma leitura real do mercado 2026.
- ❌ **Perdeu (e aqui o Onion está À FRENTE):** a conversa tratou A2A como **monólito** ("camada
  horizontal a adotar"). O Onion **já partiu a linha vermelha em duas** (`ADR:78-85`): **runtime**
  (proibido) × **formato/descoberta** (permitido-diferido) — distinção que a conversa não fez. Ou
  seja, o sinal **não traz delta**; o Onion já decidiu com mais granularidade do que ele propõe.
- ❌ **"Use A2A, não MCP, para coordenação" (peers com estado/lifecycle próprios)** é precisamente o
  **runtime cross-repo** que o Onion rejeita — é o "ato 3 vivo e distribuído". Resposta do Onion:
  runtime **não**; formato **talvez-depois**.

## 3. Desambiguação crítica (corrige leitura comum)

A linha vermelha **não** é "agentes não podem se falar". Pelo [ADR de comms](./onion-adr-comms-transport-vs-execution-2026-06.md),
A2A é **ortogonal ao risco**: o risco é o **ato 3** (ler+interpretar+**executar** automático sem gate)
somado à atomicidade multi-repo inexistente no git — não a troca de mensagens em si. Dá para ter A2A
sem auto-executar (seguro) e auto-execução sem A2A nenhum (perigoso). Por isso a federação é
**git-async + maestro humano**, e o runtime A2A fica `hold` pela **razão certa**.

## 4. Estado atual e gatilho (não é dívida ativa)

Hoje há **um** consumidor (`rhilo-metagamify`), que é **Onion** — logo o gatilho do ADR **não disparou**.
A projeção de formato é "🟢 oportunística no backlog", não dívida; **construí-la antes do gatilho seria
especulação**. Nada a fazer neste eixo agora.

## 5. Síntese — fechamento do radar de orquestração (3 eixos percorridos)

| Eixo | Veredito após aprofundar | Artefato |
|---|---|---|
| **TOPO** (topologia hierárquica) | Falso conflito — confundia *locus* (invariante) com *forma de grafo* (já permitida no nível principal). | ADR-rascunho de topologia (#123) |
| **MATH** (transição de fase) | Paper **verificado**; modela o **judge-panel** (binário+maioria), não o fan-out geral. Lente qualitativa. | nota de transição de fase (#124) |
| **A2A** (esta) | **Já adjudicado**; o Onion está **à frente** do sinal (separou runtime×formato). Sem delta. | esta nota + ADR A2A (SSOT) |

**Padrão que atravessa os 3:** o sinal externo, mesmo sem conhecer o Onion, **valida** o que o framework
faz — ou o Onion **já está à frente**. Nenhum eixo virou adoção cega; cada delta ou já estava coberto,
ou virou lente qualitativa, ou ficou parqueado com gatilho preciso. O radar cumpriu seu papel: manter as
possibilidades perto, sem inflar o framework. **Os 3 eixos estão tratados; o radar segue vivo** para
quando algum gatilho disparar.

## 6. Log / revisibilidade

- **2026-06-21** — Eixo A2A aprofundado. Achado: **já adjudicado** pelo ADR A2A (SSOT, 2026-06-15) — o
  aprofundamento é reconciliação, não nova doutrina. Onion à frente do sinal externo (runtime×formato).
  Radar fechado nos 3 eixos. Para retroagir: editar com data + porquê.

## 7. Fontes

- **SSOT da decisão:** [ADR — A2A como projeção de formato, não runtime](./onion-federation-adr-a2a-format-interop-2026-06.md) (aceito 2026-06-15).
- **Complementos:** [RFC-0001](../evolution/rfc/rfc-0001-co-evolution-comms.md) (git-async > A2A-runtime), [ADR comms](./onion-adr-comms-transport-vs-execution-2026-06.md) (A2A ortogonal ao risco), [KB multi-repo-federation](../knowledge-base/concepts/multi-repo-federation.md) §7, design de federação v2 (Fase 5 abandonada).
- **Sinal:** conversa externa (share `claude.ai/share/332f6246…`) — ver [radar](./onion-orchestration-external-radar-2026-06.md) §2.
