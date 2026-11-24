---
branch: chore/waha-caps-reply-1124
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: true
elenxo_isolado: false
reviewer: "condutor (core), passada própria: cada linha nova conferida contra o código da peça (origin/main 517d498 de lá) antes de mudar o status"
nota: "só a declaração de capacidades do adapter WAHA; sem código"
---

# Passada: `chore/waha-caps-reply-1124`

A peça de mensageria entregou o `watcher reply` (PR #73 de lá, merge 15:49 UTC de 24/11). Medi na origin/main 517d498
dela: `watcher/onion_watcher/reply.py` existe; o README descreve `/api/sendText` com `reply_to`, o «Serviu?» com
`--no-served` e motivo, a latência (`requested_at`/`seen_at` do vínculo, `replied_at` depois do envio) e o
`chat-audit.jsonl`. Por isso `message.reply_thread`, `served.ask` e `rule.latency_field` passam a `implemented`, e o
`rule.audit_log` segue `partial` (a recepção ainda não registra quem pediu), agora citando a resposta também.
As famílias de bancada que cobrem o chat passaram (179, 0 falha).

Tentei refutar: não rodei o `reply` contra o WAHA (a peça diz bancada 51/51 e 40 mutantes, fora do CI até a decisão
do custo); a declaração diz «medido por leitura do código», como as linhas vizinhas.
