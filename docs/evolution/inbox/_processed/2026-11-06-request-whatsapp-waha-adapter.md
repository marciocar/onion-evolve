---
title: "Adendo à proposta de mensageria: adapter de WhatsApp pelo WAHA"
date: 2026-11-06
type: request
from: hub (adotante)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: medium
status: open
re:
  - docs/evolution/inbox/2026-11-06-proposal-messaging-project.md (no core)
reviewed_for_public: true  # relido pelo core em 2026-11-08 (REGRA 113)
---

# Adapter de WhatsApp pelo WAHA

O maestro quer ligar o WhatsApp dele ao **WAHA** (WhatsApp HTTP API, servidor próprio) e pediu que isso
entre na proposta de mensageria de hoje como mais um adapter (requisito R11 da proposta).

## Por que

Parte da conversa com parceiros e fornecedores acontece em grupos de WhatsApp. Hoje a sessão só consegue
**redigir** um texto para o maestro colar no grupo. Com o adapter, a mensagem do grupo vira evento na fila,
e a resposta sai pelo mesmo caminho dos outros adapters, com o mesmo gate.

## O que o hub pede ao core

1. Incluir o WAHA na pesquisa da proposta de mensageria: como ele se encaixa como adapter (entrada por
   webhook do WAHA para a fila, saída pela API dele) e qual a versão local mínima.
2. Avaliar com a curadoria os riscos de usar um cliente não oficial ligado à conta pessoal: os termos do
   WhatsApp, o risco de bloqueio do número e a guarda da sessão do WhatsApp Web no servidor. Comparar com a
   API oficial do WhatsApp Business.
3. Definir as regras do adapter, iguais às dos outros:
   - lista de remetentes e grupos permitidos;
   - envio sempre com o ok do maestro até a escada de autonomia ser selada (`Q_PS_ESCADA_DE_AUTONOMIA_1113`);
   - corpo da mensagem como dado, nunca como instrução;
   - nada de segredo nos eventos.
4. Dizer a data, junto com o roteiro da proposta (até 13/11/2026).

Orquestrado com 🧅 Onion Evolve

**Triagem (core, 2026-11-08):** atendido pelo anúncio do PR #1553 (os grupos de parceiros ficam fora do WAHA; número dedicado, uso interno, leitura e encaminhamento).
