---
branch: chore/waha-caps-audit-read-1124
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: d48a15bc462f99b5dd951edb4ab3efdf2ac179dd8862dc7e5c7fc9c7bb2b223d
reviewed_code_sha256: 9c690e13217355ba2c1f28854dda7722a0af9af629b80c4af5af27ab62ce8431
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: true
elenxo_isolado: false
reviewer: "condutor (core), passada própria: cada linha conferida contra o código da peça antes de mudar o status"
nota: "só a declaração de capacidades do adapter WAHA; sem código"
---

# Passada: `chore/waha-caps-audit-read-1124`

Medido por leitura na origin/main ⟨commit⟩ da peça de mensageria (2026-11-24):
- `rule.audit_log`: `watcher/onion_watcher/reply.py` grava `kind: receive` (linha 179) além do envio e da resposta;
  o README descreve a linha sem número nem texto. Passa a `implemented`.
- `rule.read_marker`: `doorbell/server.ts` tem `read_by` (6 menções) e `queue/test/two_sessions_bench.py` tem os casos
  da marca e o limite `today_both_read_same_lease`, declarado na linha. Passa a `implemented`.

Tentei refutar: não rodei as bancadas da peça (dizem 11/11 e os casos `read_*` da campainha); a declaração diz «por
leitura do código», como as vizinhas.
