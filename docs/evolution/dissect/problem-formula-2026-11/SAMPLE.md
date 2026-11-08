# Registro do sorteio

Semente: `f5153f6b37e7607198b000bd3b8a8514811716dd` (commit que introduz a fórmula). Lista completa: `python3 sample.py <semente>`.
Universo: 1.131 itens de texto, 35 nós `owner: maestro` (18 abertos), 21 selos com resposta livre (0 abertos).

| Estrato | Pool | Entraram | Pulados, com motivo |
|---|---|---|---|
| B | 683 | proposal-agent-transport, docs-exit2-coupling, fronteira-pessoa-empregador, chore-kg-migrate-keys | feat-wave6-seal-merged-items: só registro |
| C | 382 | fix-poda-placar, feat-r56-residue-generator, feat-a2a-queue-live | fronteira-pessoa-empregador: já tomado em B |
| D | 35 | Q_CREATE_VERTICAL…, Q_COORD_BRAIN_SEGREDO…, Q_CARIMBO_DO_ADOTADO_STANDALONE | Q_VITRINE_E_GPT…: aberto, sem desfecho |
| E | 21 | Q_AAIF_G4…, D_DISSECT_REGUA… | nenhum |
| A | 1.131 | docs-peer-protocol-triage, docs-seal-kg-read-leg, research-librechat-kg-runtime, docs-research-live-channel, fix-r16-cost-total, friccoes-f1-doutrina-plea, workflows-nao-vendorizados, docs-recover-interface-harness | já tomados: fix-poda, proposal-agent-transport, docs-exit2, fronteira, feat-r56, chore-kg-migrate, feat-a2a-queue. Só registro: metagamify-a2a-hello (handshake sem corpo), feat-wave7-fired-triggers, docs-a2a-a7c1-clock-after, feat-wave6 |

**Achado do instrumento:** os filtros de B e C quase não enriquecem. B casa 60% do universo (`merge` e `chave` estão em quase tudo) e C casa 34%. Dos três sorteados de C, só o primeiro é falso alarme de verdade. Logo P4 mede pouco; os falsos alarmes reais da amostra estão em A1, A5, C1 e D2 (leitura de quem sorteou).

**Redação:** fichas sem nome de adotante; a data vem da fonte. Quem redigiu conhece o desfecho, e vazamento é risco declarado. Duas fichas têm contexto que aponta a saída (B4 diz "é um PR", A1 cita a ordem permanente), porque era o que se sabia; ficam registradas como possível indução.
