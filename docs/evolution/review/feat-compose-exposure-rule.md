---
title: "Revisão — a classe virou mecanismo: REGRA 64 + branch na granaai + pacote arandek"
date: 2026-08-31
branch: feat/compose-exposure-rule
reviewer: "REGRA 64 provada por mutação nos dois lados (4/4 no ruim, 0 no curado) + bancada auto-contida 3/3 no padrão awk-extração; o pre-commit vendorizado da granaai foi respeitado e o bypass documentado no próprio commit deles"
reviewed_diff_sha256: f9d521d18be5f95a03631a3400d00cfd823c2253c50cc2c8de20b82f0257f357
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 0
duration_min: 25
---

# Resíduo — REGRA 56

Selo do maestro: "comunicação + correção como proposta aplicável + regra de classe". As 3 pernas:

## 1. granaai — branch pushed (a correção como proposta)

`fix/compose-bind-and-secret-fallback` @ `1b5afab00` em GranaAi/granaai: 2 binds `127.0.0.1:` +
`DB_PASSWORD` obrigatória. **Via worktree temporária de `origin/develop`** — o checkout do time
(em `kg/domain-ssot-remap`) ficou intocado. O pre-commit vendorizado deles bloqueou por 3 HARD
**pré-existentes do develop** (inventário/graph/link — nada do diff de 3 linhas); bypass com a
justificativa escrita no próprio commit. O merge é deles.

## 2. arandek — pacote PRONTO-RETIDO

Medido no clone: **portas já limpas**; restam 3 fallbacks de senha. Mensagem + patch em
`docs/analysis/arandek-compose-fallbacks-message-2026-08.md` (`REDIGIDO-PRONTO-PARA-ENVIO`) com o
comando de publicação no outbox — **o envio segue sendo ato do maestro**, como no achado-mãe.

## 3. REGRA 64 [HARD] — a cura de classe

Compose **rastreado** com porta sem prefixo de bind ou segredo em `${VAR:-literal}` reprova.
Provas: dogfood 4/4 no ruim + 0 no curado (o `127.0.0.1:` e o `:?` calam); bancada auto-contida
3/3 (acusa · cura passa · **untracked fica fora** — escopo declarado); registry regenerado com a
64 em "Projeção & privacidade". Vendoriza via plugin → o 3º caso é pego pelo CI de qualquer
adotante antes de existir.

## O contexto que recalibrou tudo (maestro, 2026-08-31)

Produção de ambos roda na **AWS, outras contas** — SG fica fora do host e o Docker não a fura
(a metade das portas é risco de dev/VPS/CI, mitigado na produção); o **fallback de senha viaja
intacto** para qualquer ambiente, SG não cobre. Incorporado nos dois docs e no nó do grafo.

## Gate

radar exit 0 · bancada da 64 3/3 · assemble do plugin (R19) · backlog em dia (R62)
