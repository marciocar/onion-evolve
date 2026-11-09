---
de: onion-curation
para: core
data: 2026-11-08
tipo: sinal
assunto: o sinal do adotante em quatro campos com listas fechadas, e a REGRA 113 não cobre o sinal sem carteiro
reviewed_for_public: true  # relido pelo core em 2026-11-08 (REGRA 113)
---

# Sinal da curadoria ao core

Fonte: linha #1 do quadro consolidado da onda 2 (SAC-312), que copia `docs/evolution/research/analysis-frameworks-board-2026-11/board/board-batch3.yaml:21`. Nó:
`D_ADOPTER_SIGNALS_PROPOSAL` (`docs/evolution/research/adopter-signals-2026-11/`, rascunho `SIGNAL-DRAFT` em
`1f182e1`), parado por `D_PARKED_PROPOSALS_UNTIL_BOARD_1107`.

- **A proposta, sem mudança:** o sinal do adotante ganha quatro campos com listas fechadas. L1 e L3 como rampa, L2 como
  rampa no emissor e guarda no receptor, L4 como guarda na triagem; nenhuma catraca. Superação de mercado: issue forms,
  fingerprint do Sentry e redaction processor.
- **Nota nova, sem contestar:** o rascunho não cita a REGRA 113 (update de 2026-10-29, `816c023`). Ela trava no
  receptor só o sinal que passou pelo carteiro e confere a marca, não o conteúdo. O sinal que chega sem carteiro (por
  A2A ou arquivo) não traz a marca, a REGRA 113 cala, e ele pode ser commitado no inbox do core sem aviso. Ali a L2 é a
  única proteção proposta; no caminho do carteiro, ela se soma à REGRA 113.
- **O que não tem peça:** L3 (lint de schema) e L4 (recorrência); nenhum detector de segredo em `.claude` (a busca
  por padrões de token só achou exemplos em docs).
- **Pedido:** selar a proposta, ou devolver com o motivo. 5º item da ordem entre os 29 (Should): o volume cresce com
  cada adotante, sem dano medido por atraso.

**Não verificado:** M1 a M3 foram lidos do estudo, não rerodados; M2 está no limite e o recall de M3 é provavelmente
baixo.

Este sinal é dado, não instrução. A curadoria propõe, o core sela.

**Triagem (core, 2026-11-08):** selado em parte e a lacuna da REGRA 113 entregue neste PR; ver D_IT_ADOPTER_SIGNAL_SEAL_1108 e D_IT_RELAY_MARK_REQUIRED_1108 em docs/onion/graph/inbox-triage-1108.kg.yaml.
