---
title: "Revisão — R64 ganha catraca: o 1º update de adotante mediu 38 HARD legados de uma vez"
date: 2026-08-31
branch: feat/r64-ratchet
reviewer: "dogfood da bancada 5/5 (incl. paridade emissor↔lint POR EXECUÇÃO e o caso de crescimento, que a 1ª redação media pelo conteúdo que a mensagem não carrega — pego pela própria bancada)"
reviewed_diff_sha256: 73baa2474d7b86393a11a2c9cef8f61437077b338bb99e0738e981d264b634a6
findings_total: 2
findings_real: 2
verdict: APROVADO
tokens: 0
duration_min: 20
---

# Resíduo — REGRA 56

O 1º `adopt --update` real com a R64 a bordo (arandek) acertou **38 HARD legados de uma vez** —
guarda sem catraca sobre dívida pré-existente **pune quem obedece e ensina o `--no-verify`**
(doutrina medida da casa). Cura no mecanismo, mesmo dia:

## O que mudou

- **R64 agora tem catraca** (`compose-exposure-baseline.txt`, padrão das irmãs): chave legada =
  tolerada com SOFT agregado ("a métrica é DIMINUIR"); linha nova = HARD. Curou a linha → a chave
  sai do baseline junto.
- **Emissor novo** `compose-exposure-check.sh --emit-baseline` — o `regen-baselines.sh` o resolve
  por convenção (baseline novo entra coberto por construção, incl. adotantes pré-catraca via
  `--ensure-from`).
- **Paridade emissor↔lint provada POR EXECUÇÃO** na bancada (a receita da chave vive em 2 sítios;
  a bancada é o que os mantém iguais): o que o emissor emite, o lint tolera; linha nova segue HARD.

## O achado da própria bancada

O caso de crescimento da 1ª redação media pelo **conteúdo da linha** (`grep 7777`) — que a
mensagem da violação **não carrega** (só nº+chave). A bancada reprovou a si mesma; o caso agora
mede o que a guarda emite (1 HARD exato + SOFT agregado presente). `exit-code-nao-e-a-verificacao`,
aplicado ao próprio teste.

## Gate

bancada 5/5 · bash -n ok · assemble (R19) · a R64 no core segue 0 ocorrências (sem compose rastreado)
