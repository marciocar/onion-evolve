---
title: 'Resíduo — carimbo do pin do brain-granaai (6f3ab3a3)'
date: 2026-10-09
branch: chore/brain-granaai-pin-6f3ab3a3
reviewed_diff_sha256: a8fc689101e6421927178272d214255386be7c1e6440a5bb539a65c2b660b1a3
reviewed_code_sha256: 0f7cb2d8a5148b5c8bd84d6f92c480244cb9e477c101ed53be04c0e66a6ace25
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 5
verdict: CORRIGIDO
elenxo: nao
nota: >-
  PR só de registro. A passada conferiu o pin contra o stamp VIVO no remoto do adotante, não contra a
  mensagem da sessão dele.
---

# Conferência

- `git merge-base --is-ancestor a57041bed origin/onion/develop` deu ok: o merge do update está no remoto.
- `git show origin/onion/develop:.claude/.onion-version` mostra `source_commit: 6f3ab3a3905c`, `role: hub` e
  `updated_at: 2026-10-09`.

# Achado (real, curado)

- **Registro defasado de antes.** O `members.yaml` dizia `663fdbc5bdcc`, mas o stamp vivo do adotante antes
  deste update já era `1c459812f48b`, conforme o relatório do `--update`. Um update anterior não foi
  carimbado. Agora o pin está correto e o salto está declarado no comentário. A classe é "carimbo de
  adotante feito à mão apodrece". Para portas ela já tem cura, o `ops/door-seal-pin.sh`, mas os adotantes
  ainda não têm equivalente. Fica registrada no SAC-87.
