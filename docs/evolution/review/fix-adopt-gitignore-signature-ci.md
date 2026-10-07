---
title: 'Resíduo — o adopt protege os segredos, assina o commit e o CI do adotante vê o pre-commit'
date: 2026-10-07
branch: fix/adopt-gitignore-signature-ci
reviewed_diff_sha256: fd70439b2a5c58c7a962e4e861a267607eedb2a047f0eed0bdadc4d01fd7344c
reviewed_code_sha256: fd9604d602672a138024b6b17f52d527409a90dafc05fc2b0b53e8431e5ef36a
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
  que não acrescenta, commit sem assinatura, CI sem .githooks). Nó da fila fechado com verified_at. Sem
  Elenxo, declarado.
---

# Resíduo — `fix/adopt-gitignore-signature-ci`

Teto: adotantes JÁ adotados não recebem o .gitignore pelo --update se o passo (0b) não rodar no fluxo de
update; o onion-curation e o onion-kg-ssot já o têm à mão, e o onion-slm segue sem (sinal a enviar no anúncio).
