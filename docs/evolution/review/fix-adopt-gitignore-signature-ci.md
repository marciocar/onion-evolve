---
title: 'Resíduo — o adopt protege os segredos, assina o commit e o CI do adotante vê o pre-commit'
date: 2026-10-07
branch: fix/adopt-gitignore-signature-ci
reviewed_diff_sha256: 8f6d8b50d0a8b8d439cddf71849016a07cbe10de491146ee9c82b8f6b6f6f0c1
reviewed_code_sha256: e07968993f972148b786892815cd0b46b7731506c01a5a2ce20a16ff7a113879
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 25
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Item 2 da fila-2026-10-06 (Q_ADOPT_TRES_DEFEITOS, impacto 4), medido nas adoções do onion-curation e do
  onion-kg-ssot, que curaram à mão os três no próprio repo. (1) Helper novo ensure-secret-gitignore.sh, chamado
  no passo (0b) do /meta:adopt: never-clobber e idempotente; cria ou completa o bloco .env/.env.*/!.env.example;
  regra própria do adotante que já cubra .env é respeitada; um .env JÁ versionado não é desfeito, mas o script
  avisa em voz alta com o comando e o alerta de segredo vazado. (2) durable-commit.sh anexa a assinatura do
  PRÓPRIO adotante (attribution.commit do settings.json dele, que o merge never-clobber preserva desde o #936);
  sem ela, o commit sai sem assinatura. (3) O template de CI do adotante dispara também em .githooks/**.
  Bancada: família nova secret_gitignore (a-g) e o caso (f) do durable_commit. O caso (g) nasceu com defeito
  próprio: o padrão começava com '-' e o grep o leu como opção; curado com '--'. Três mutantes mordem (helper
  que não acrescenta, commit sem assinatura, CI sem .githooks). Nó da fila fechado com verified_at; os
  `confirmed` que o sustentam foram relidos e seguem como estavam: E_ADOPT_SEM_GITIGNORE_DE_SEGREDOS (impacto 4),
  E_DURABLE_COMMIT_SEM_ASSINATURA e E_CI_TEMPLATE_IGNORA_GITHOOKS. Sem Elenxo, declarado.
---

# Resíduo — `fix/adopt-gitignore-signature-ci`

O 1º lint do commit acusou o limite de linhas do adopt.md (802 de 800) — a chamada ficou em uma linha, com o porquê no cabeçalho do helper.

Teto: adotantes JÁ adotados não recebem o .gitignore pelo --update se o passo (0b) não rodar no fluxo de
update; o onion-curation e o onion-kg-ssot já o têm à mão, e o onion-slm segue sem (sinal a enviar no anúncio).
