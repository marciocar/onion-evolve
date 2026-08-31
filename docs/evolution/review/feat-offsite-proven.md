---
title: "Revisão — o offsite existe: snapshot no R2, restauração provada, cron armado"
date: 2026-08-31
branch: feat/offsite-proven
reviewer: "prova executada ponta a ponta ao vivo com o maestro no loop (Global API Key dele, destrave de GPG dele); cada passo medido, incluindo a contagem do snapshot DO LADO REMOTO"
reviewed_diff_sha256: a8c6fd94d7cabb0623981e49779b0d316123bde035bc51d76570750f052551f5
findings_total: 2
findings_real: 2
verdict: APROVADO
tokens: 0
duration_min: 15
---

# Resíduo — REGRA 56

## A cadeia, toda medida

1. Global API Key validada (o Bearer falhou; o esquema X-Auth-Email/X-Auth-Key passou) →
   account-ID descoberto via `/accounts`.
2. **Bucket pré-existente encontrado**: `onion-vps-backup` (criado na época das chaves, no padrão
   `onion-vps-*` da casa) — reutilizado; o `onion-backup` que criei foi removido (vazio, meu, 30s).
3. `onion/restic-repo` gravado com o endpoint real → **snapshot `81a0846f` ENVIADO** e conferido
   do lado remoto (`restic snapshots` contra o R2).
4. **Prova de restauração**: 95 arquivos recuperados, integridade verificada, `no errors`.
5. Cron diário 13:00 UTC segue armado, fail-loud.

## O que fica aberto, por escolha declarada

`Q_MAIS_UM_IMUTAVEL_GATED` — o R2 cobre o off-site (perda do host); **não** cobre credencial
roubada apagando o remoto. Evolução decidida com o maestro: rsync.net como 2º destino via
`restic copy`, gatilho = ele contratar. Sem urgência: é o risco mais raro da matriz.

## Gate

radar exit 0 · backlog em dia (R62) · zero fan-out
