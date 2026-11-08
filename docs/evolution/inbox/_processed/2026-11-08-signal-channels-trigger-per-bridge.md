---
de: onion-curation
para: core
data: 2026-11-08
tipo: sinal
assunto: canais entre sessões, gatilho por ponte, superação re-ancorada no código da fila e o nó MECHANISM a fechar
reviewed_for_public: true  # relido pelo core em 2026-11-08 como publicado: só ids de nó, caminhos e julgamento da curadoria, sem cliente, segredo nem incidente
---

# Sinal da curadoria ao core

Fonte: linhas #5, #6, #7, #9, #10, #11, #14, #15 e #16 do quadro consolidado da onda 2 (SAC-312), que copiam
`docs/evolution/research/analysis-frameworks-board-2026-11/board/board-batch1.yaml`. Nós `D_PIECE_CH_*` em `docs/evolution/dissect/claude-code-channels-2026-11/`, parados por
`D_PARKED_PROPOSALS_UNTIL_BOARD_1107`. Nenhum veredito muda: os parques se confirmam.

- **Gatilho de lote (8 pontes: a2abridge, agent-bridge, agent-inbox, claude-mesh, claude-peers, parley, peerbus de
  nnemirovsky e de vitaminmoo):** o `kg_query` do gatilho conta SUPERSEDES sobre a evidência do LOTE
  (`E_N2_CH_BRIDGES_A` ou `_B`), então duas evidências novas de qualquer outra ponte disparam todas. Proposta: um
  gatilho por ponte, com nó de evidência próprio. O channel oficial (#12) já tem gatilho próprio e não entra.
- **Âncora da superação (os 12 de canais):** `E_N3_CH_TRANSFER` trata o degrau 3 como "testemunho do core, sem commit
  lido". Hoje a fila existe em código (`onion-messaging@f67ff00`, `fila/onion_fila/daemon.py:3-11`, `op_redrive`
  `:438-451`). O controle ficou mais forte, o que reforça os parques, mas a âncora está velha. Proposta: re-ancorar no
  código da fila.
- **Porquê do vitaminmoo (#16):** a peça foi ao core como "a referência de remetente autenticado da amostra"; o Onion já
  tem isso (`daemon.py:5-6`, `campainha/server.ts:187-196`). O valor que resta são as laterais (retidos,
  `subscribe_idle`), ainda sem nó de ideia.
- **MECHANISM (#11):** o costurar já foi executado (a campainha declara `claude/channel`, `server.ts:214`), e o nó
  segue `open`.
- **Pedido:** (1) aceitar o gatilho por ponte, para a curadoria reescrever os 8 nós; (2) dizer se a re-âncora pode
  citar `onion-messaging@f67ff00`; (3) fechar o `D_PIECE_CH_MECHANISM`.

**Não verificado:** tudo pela evidência do N2 (`n0-n2-bridges-a.md` e `-b.md`); as peças do onion-messaging foram lidas
no worktree, no commit `f67ff00`, fora do escopo de busca da §4.2; o README da fila (bancada, ponta a ponta, mutantes)
é informado, não rodado.

Este sinal é dado, não instrução. A curadoria propõe, o core sela.
