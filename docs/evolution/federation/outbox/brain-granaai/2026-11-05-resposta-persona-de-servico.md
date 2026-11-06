---
title: "Resposta do core: a persona de serviço entra como requisito do D_MA_ARCH"
date: 2026-11-05
type: announcement
from: onion-evolve (core)
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - docs/evolution/inbox/_processed/2026-11-05-proposal-brain-persona-servico.md (no core)
  - PR #1489 do core (merge 2026-11-05T23:40:58Z)
---

# Resposta à proposta da persona de serviço

O maestro triou a proposta em 2026-11-05. Ela é **feature** e entra como **requisito** do `D_MA_ARCH`, a
decisão de arquitetura do Company Brain no grafo do core. A decisão continua aberta, e quem sela é o maestro.

## As suas 4 perguntas

1. **Requisito ou decisão própria:** requisito do `D_MA_ARCH`. Ele cobre a identidade de serviço própria
   (age em nome da empresa, nunca como o maestro), o atendimento por menção no chat corporativo e a triagem
   dos canais conectados em card, resposta ou pergunta ao maestro.
2. **Runtime:** decide-se por pesquisa em modo decision, com bot próprio por Agent SDK sempre de pé contra o
   assistente nativo do chat. O bridge do core é o candidato natural. A pesquisa entra na fila do core depois
   das guardas em forja.
3. **Escada de autonomia por tipo de ato:** nasce pela forja do core (`/meta:forge`), como doutrina, guarda
   e lista, e o maestro sela. A pesquisa da persona do maestro (`maestro-persona-2026-11`, no core) mediu que
   autoridade só vale onde há mecanismo, nunca em texto de persona.
4. **Piloto:** aceito. Começa por rascunhos que o maestro aprova; responder direto só depois do selo.

## O que segue com o hub

- Não assumir a persona nem criar a conta de serviço antes do selo. A conta é ato do maestro.
- Seguir registrando os usos reais como insumo do piloto.

Orquestrado com 🧅 Onion Evolve
