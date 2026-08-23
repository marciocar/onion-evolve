---
title: "Revisao — guarda anti-commit-na-default-branch (self-review)"
date: 2026-08-23
branch: chore/guard-no-commit-to-default-branch
reviewer: "self-review (autor) — guarda de 15 linhas no caminho de commit; edge-cases probados"
reviewed_diff_sha256: efe4a057e2406afc8c03e2ac4255828ed1ad1ffc63e925c25638e682e8d12412
findings_total: 6
findings_real: 0
tokens: 1800
duration_min: 4
verdict: APROVADO
---

# Resíduo de revisão — REGRA 56 (self-review, guarda de commit)

Guarda que BLOQUEIA commit local na default branch (fail-fast no pre-commit do core). Como toca o
CAMINHO DE COMMIT, o risco é (a) bloquear commit legítimo, ou (b) falhar em proteger. Probei 6 modos:

- **Branch de feature** — branch atual difere de main → passa. Não bloqueia trabalho normal (testado).
- **Em main** — branch igual ao default → exit 1 + mensagem de cura (testado por lógica + sim).
- **Detached HEAD** (o CI faz checkout do head.sha) — abbrev-ref devolve "HEAD", difere de main → passa.
  O CI NÃO é bloqueado.
- **Sem origin/HEAD** (repo fresco) — symbolic-ref falha → fallback para main. Degrada seguro.
- **Default diferente de main** (ex.: master) — origin/HEAD resolve o nome real, não hardcoda.
- **Escape consciente** (merge/hotfix) — commit --no-verify pula o hook inteiro. Documentado na mensagem.

**Adopter-safety:** CORE-ONLY — vive no .githooks/pre-commit do core, que DIFERE do template
vendorizado (githook-pre-commit-onion.tpl, inalterado). Adotante com fluxo trunk-based não é afetado
(a lição "o core é o pior oráculo do que viaja"). bash -n limpo.

**Veredito: APROVADO** — string-compare simples, degrada seguro em todo edge, não viaja ao adotante.
Cura a recorrência medida (2 commits diretos em main nesta sessão). A prova ao vivo é inerente: o
próximo slip é bloqueado (e visível).
