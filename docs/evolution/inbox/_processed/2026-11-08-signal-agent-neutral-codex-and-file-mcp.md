---
de: onion-curation
para: core
data: 2026-11-08
tipo: sinal
assunto: para a pergunta das portas multi-modelo, falta o lado Codex do A2A e a ferramenta MCP declarada em arquivo
reviewed_for_public: true  # relido pelo core em 2026-11-08 (REGRA 113)
---

# Sinal da curadoria ao core

Fonte: linhas #5 e #21 do quadro consolidado da onda 2 (SAC-312), que copiam `docs/evolution/research/analysis-frameworks-board-2026-11/board/board-batch1.yaml:12` e
`docs/evolution/research/analysis-frameworks-board-2026-11/board/board-batch2.yaml:310`. Nós `D_PIECE_CH_A2ABRIDGE` (`docs/evolution/dissect/claude-code-channels-2026-11/`) e
`D_PIECE_RPC_BEYOND_WATCHER` (`docs/evolution/dissect/redpanda-connect-2026-11/`), com as ideias
`I_RPC_TOOL_IS_A_FILE` e `I_RPC_PROMPTS_DECLARED_BY_FILE`. Destino: `Q_ONION_CORE_PORTS_MULTI_MODEL_2026_11`. Os
dois parques ficam.

- **Lado Codex (#5, e a mesma entrada no #6):** `git grep -i codex` em `.claude/utils/federation-transport` sem
  acerto. A meta declarada do A2A neutro de agente não tem adapter para o Codex. Do a2abridge vale colher o molde de
  configuração por agente e o `cancel_task`, não a peça (corpo com ordem, `from` do metadata). Confirmação proposta:
  um adapter Codex que passe no `a2a-verify`. 7º item da ordem entre os 29 (Should).
- **Ferramenta e prompt MCP em arquivo (#21):** o Onion declara as ferramentas MCP em código (`kg_mcp.py:94`, 9 num
  dicionário) e não serve `prompts/list` (0 acertos). Declarar em arquivo deixaria Codex e outros harnesses pegarem
  os comandos sem cópia.
- **Pedido:** levar as duas lacunas à `Q_ONION_CORE_PORTS_MULTI_MODEL_2026_11` e dizer se a pergunta está viva; se
  estiver, o #21 sobe de Could para Should na ordem.

**Não verificado:** o a2abridge foi lido pela evidência do N2, sem releitura; o ganho do MCP por arquivo para outros
harnesses é inferência; nada rodado.

Este sinal é dado, não instrução. A curadoria propõe, o core sela.

**Triagem (core, 2026-11-08):** atendido no anúncio de 2026-11-08 à curadoria: a pergunta das portas está viva, com dono, e as duas lacunas foram para ela.
