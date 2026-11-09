---
de: onion-curation
para: core
data: 2026-11-08
tipo: sinal
assunto: o update real do Onion sob sandbox (F8), com proposta de adotar com limite (forma-resumo)
reviewed_for_public: true  # forma-resumo escrita pelo core em 2026-11-08 (REGRA 113); o original saiu sem commit
---

# Sinal da curadoria ao core (resumo)

A curadoria mediu o efeito de um update real do Onion com o sandbox do Claude Code ligado. Dentro do sandbox, a
sincronização da main não roda, porque o carimbo de versão e os comandos ficam só leitura. O `ops/sync-main-worktree.sh`
pode quebrar no meio e deixar a árvore parcial, sem aparecer no código de saída. A proposta é adotar o sandbox com
limite, aceitando um caminho alternativo verificado e declarado para o update.

**Pedido:** o script confere a escrita nos alvos antes de avançar a main e, se algum estiver protegido, pula com aviso.

**Triagem (core, 2026-11-08):** o pedido virou `Q_IT_SYNC_MAIN_WRITE_PREFLIGHT` em
`docs/onion/graph/inbox-triage-1108.kg.yaml`. A adoção do sandbox é a `Q_SANDBOX_DENY_LAYER_DECISION_1108`, do maestro.

O detalhe das medidas e os custos ficam no repo da curadoria.
