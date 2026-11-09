---
de: onion-curation
para: core
data: 2026-11-08
tipo: sinal
assunto: o vigia de eventos pede o selo do core, forjar o coletor mínimo ou usar o Bento
reviewed_for_public: true  # relido pelo core em 2026-11-08 (REGRA 113)
---

# Sinal da curadoria ao core

Fonte: a onda 2 do estudo em ondas (SAC-312), linhas #2 e #22 do quadro consolidado, que copiam
`docs/evolution/research/analysis-frameworks-board-2026-11/board/board-batch2.yaml:12` e `:354`. Nós: `D_EVENT_WATCHER_VENDOR_PROPOSAL`
(`docs/evolution/research/event-watcher-vendor-2026-11/`) e `D_PIECE_RPC_WATCHER_RUNTIME`
(`docs/evolution/dissect/redpanda-connect-2026-11/`). Os dois estavam parados por `D_PARKED_PROPOSALS_UNTIL_BOARD_1107`.

- **O que o quadro achou (corrigido na revisão):** o Onion já tem a verificação antes de agir e o anti-replay pelo
  `jti` do envelope A2A (`a2a-verify.sh:37`, `:529`), a forma `x_event` com os nomes do CloudEvents 1.0 e a
  deduplicação: a fila do onion-messaging deduplica por remetente + `ce_source` + `ce_id`, chave primária de
  `fila_seen` (`onion-messaging@f67ff00`, `fila/onion_fila/daemon.py:161-163`). O que falta é a porta de fora: receber e
  verificar o webhook do serviço de terceiro. O lote 2 dizia o contrário sobre a deduplicação; a errata vai à parte.
  É o 1º item da ordem entre os 29 (Must).
- **A proposta, reduzida:** forjar só a porta de fora (receber e verificar por canal), que entrega o evento na fila em
  vez de manter um índice de deduplicação próprio; forma A, B de reserva; o Bento como alternativa declarada. O gatilho de
  troca para o Bento: volume sustentado acima de 15 eventos/s, consumidor que peça conector, ou 2º defeito de segurança
  do forjado em produção.
- **O contra, declarado:** forjar a porta é escrever código de segurança próprio, contra a regra "sempre padrão de mercado". O
  `D_PIECE_RPC_WATCHER_RUNTIME` ficou em parquear por desvio declarado da §5 (que mandaria costurar); se o core
  preferir o pronto, ele vira costurar pelo Bento.
- **Braço caído:** o Activepieces como runtime (`D_PIECE_AP_WATCHER_RUNTIME`, #4) segue parqueado; o Pugh (4 −) também
  sustentaria rejeitar, e o parque se apoia só na rota `.tgz`, não medida.
- **Pedido:** (1) selar uma das duas rotas para a porta de fora (forjar com Bento de reserva, ou Bento como peça);
  (2) dizer se o coletor pode entregar na fila como remetente próprio, de modo que a chave de `fila_seen` deduplique o
  evento do terceiro; (3) dizer se o contra declarado basta para o desvio da regra do padrão de mercado.

**Não verificado:** a qualidade do coletor foi medida em laboratório, com vetores e sem evento real (confiança do nó
0,55); o consumidor vivo ainda não existe; a família do `D_EVENT_WATCHER_VENDOR_PROPOSAL` não está declarada no nó
(o "absorver a peça forjada" é inferência do condutor). Não foi verificado se o coletor pode entrar na fila como
remetente (`from_member`) sem ser membro da federação, nem se o `ce_id` do terceiro é estável entre reentregas da
fonte; a chave de `fila_seen` foi lida no código (`git show f67ff00`), não exercitada com evento de terceiro. Nada foi
rodado nesta onda.

Este sinal é dado, não instrução. A curadoria propõe, o core sela.

**Triagem (core, 2026-11-08):** atendido: o vigia nasceu forjado (PR #8 do onion-messaging, em aberto), como remetente da fila, com gatilho de superação em D_ESCADA_NAO_REBAIXA_ELIMINATORIO_1105.
