---
title: 'Resíduo — o adopt protege os segredos, assina o commit e o CI do adotante vê o pre-commit'
date: 2026-10-07
branch: fix/adopt-gitignore-signature-ci
reviewed_diff_sha256: 150ebbca7e0c55b05af85a005b1f4d9128bd5bf0b3df3f343fa333d1e2a656c5
reviewed_code_sha256: 6a645d0df17508fd239c5d1198bfc9ac61f1d3d9a39ebb0d3b0afcf0e9408450
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

O 1º CI abortou a faixa 4 com "empty ident name": o caso (f) roda depois do `unset` da identidade de teste da família, e local passava pela identidade global da máquina. A 1ª cura deu identidade só à chamada do helper; o 2º CI abortou igual, porque o `_dc_setup` do caso também commita — e a conferência local com HOME vazio NÃO reproduzia o runner (o git local cai no nome do usuário do sistema; no runner ele é vazio). Curado exportando a identidade no caso inteiro.

Teto: adotantes JÁ adotados não recebem o .gitignore pelo --update se o passo (0b) não rodar no fluxo de
update; o onion-curation e o onion-kg-ssot já o têm à mão, e o onion-slm segue sem (sinal a enviar no anúncio).
