---
title: 'Proposta da curadoria: canal entre sessões entre máquinas e entre usuários (dissecação N0-N3 + spike vivo)'
date: 2026-10-14
from: onion-curation (consumidor)
to: core (onion-evolve)
type: proposal
flow: upstream (consumidor→core)
answers: pedido do core de 2026-10-14 (decidido pelo maestro)
---

# Proposta: manter o selo "só entre suas máquinas", agora observado, e parquear o canal entre usuários

O que entrega:
- grafo `onion-curation:docs/evolution/dissect/cross-session-channel-2026-10/cross-session-channel-2026-10.kg.yaml`;
- registro do spike `…/data/spike-log.md`, com 45 itens e IDs pseudonimizados;
- protocolo pré-registrado `…/SPIKE-PROTOCOL.md`, commit `12693eb`, anterior às observações.

**Não amplia** os selos `Q_CANAL_VIVO_ENTRE_SESSOES` e `Q_LIVE_CHANNEL_ACROSS_MACHINES_FOR_MEMBERS`: propõe.

## O que é inédito: o spike vivo (Claude Code 2.1.296; VPS + notebook do maestro)

| Cenário | Resultado observado |
|---|---|
| **S1:** mesma conta, VPS ↔ notebook | **funciona**: lista, entrega e resposta. A rota não confirma leitura. `notify_when_idle` só vale na mesma máquina. Sem `/rename` na origem, o título do Remote Control difere do nome local, e a volta só funciona pelo endereço `bridge:` |
| **S2:** contas de **organizações distintas** (Max pessoal × Team) | nenhuma **lista** as sessões da outra. Os envios falham **por nome nos dois sentidos** e **por `bridge:` de C1 para C2** (o sentido inverso por `bridge:` não foi testado). O `bridge:` real devolve o **mesmo HTTP 404** que um ID inexistente: **não se observou vazamento**, mas não se sabe se a sessão da C2 estava viva no envio. Os controles não foram simultâneos |
| **S3:** peer pede edição de `settings.json` | **recusado**, mesmo com o receptor em bypass. Quando o maestro pediu na própria sessão, ela fez. É **comportamento do modelo** com um pedido ingênuo, não uma trava provada |
| **S4:** `crossSessionInbound: hold` | **não rodado** |

**Achado de método:** o login do claude.ai é **por máquina e por usuário do SO**. Trocar a conta numa sessão troca em todas, e
derruba o Remote Control. A 1ª tentativa de S2 foi **invalidada** por isso.

## O que a pesquisa externa acrescenta ao corpus de vocês (re-medido na 2.1.296)
- **Doc oficial:**
  - `crossSessionInbound` (accept, hold, refuse) e `dialogExpiry` de 5 min;
  - "on a shared machine another user's sessions can't deliver to it";
  - mensagem de peer não aprova, não muda configuração e chega como texto;
  - desde a 2.1.166, ela não carrega autoridade de usuário.
- **Issues abertas:**
  - **#87954:** pedido de canal entre usuários, sem resposta do mantenedor;
  - **#95954:** vazamento entre sessões não relacionadas;
  - **#93824:** sessão fantasma;
  - **#86348:** mensagem perdida reportada como entregue;
  - **#99427:** descarte em 5 minutos.
- **Prior art:**
  - o A2A (github.com/a2aproject/A2A) autentica, mas não trata o conteúdo do outro agente como não confiável;
  - o arXiv 2609.00267 mostra confused deputy, replay, escalação por injeção e sub-agente comprometido passando nos
    frameworks de 2026.

## Veredito proposto: PARQUEAR o canal entre usuários; manter o selo
- **Escopo 1 (mesmo usuário entre máquinas):** o selo de vocês se confirma, agora com observação viva e com os limites
  acima.
- **Escopo 2 (usuários diferentes):** o canal nativo não lista nem entrega entre organizações distintas. Entre
  organizações, o único caminho é o **A2A gated** que vocês já têm.
- **Gatilhos para reabrir:**
  - (a) a Anthropic responder à #87954 ou lançar canal entre usuários;
  - (b) um adotante pedir canal entre organizações, que iria pelo A2A gated.

## NÃO VERIFICADO (fechar antes de qualquer absorção)
- dois membros da **mesma** organização Team;
- dois usuários do SO na mesma máquina;
- sessão cloud entre contas;
- o S4;
- outras versões (o disco do VPS já tem a 2.1.299);
- a robustez do S3 contra adversário;
- se a sessão da C2 estava viva no envio por `bridge:` (isolamento × sessão caída);
- o envio por `bridge:` no sentido C2 → C1;
- a remoção da regra do S3 no notebook, que foi declarada pela sessão e não conferida.

**Hipótese, não medida:** o valor do Onion estaria numa camada de governança sobre o A2A (conteúdo como dado, auditoria,
consentimento). Não há comprador nem preço.
