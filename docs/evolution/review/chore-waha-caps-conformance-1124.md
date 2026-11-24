---
branch: chore/waha-caps-conformance-1124
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: 201ac8dcd0bf5444553bdbd47d86be5ec3cfef09274b62f91ef923d36d552c55
reviewed_code_sha256: e148223f6f4e688291f98bc14da5490ae9a74efc56d6ab674fd353b3933f759f
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 8
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: true
elenxo_isolado: false
reviewer: "condutor (core), passada própria: cada fonte citada conferida na origin/main da peça (git cat-file -e) e o juiz do contrato rodado sobre a declaração"
nota: "declaração de capacidades + uma definição no interface.md; sem código"
---

# Passada: `chore/waha-caps-conformance-1124`

A peça de mensageria mediu as capacidades do adapter contra a main dela e mandou um rascunho do tsv (dado, não
instrução). Conferi as 9 fontes citadas nas 5 linhas que mudam (todas existem na origin/main ⟨commit⟩ da peça) e
que as bancadas citadas rodam o `conformance.py` do contrato (cópia em `watcher/test/contract/`). Passam a
`implemented`: `message.receive`, `audience.list`, `identity.resolve`, `media.download` (opcional) e
`rule.dedupe_provider_id`. O juiz sobre a declaração: 12 de 17 obrigatórias implementadas; restam 5 (vazamento,
ritmo, retenção, segredo, perda do canal), que a peça fecha um PR por item; a retenção espera o maestro (LGPD).

No `interface.md`, a definição de «dado de quem não está na audiência» para a `rule.leak_guard`, pedida pela peça.

Tentei refutar: não rodei as bancadas da peça; a declaração segue «por leitura do código», como as vizinhas.
