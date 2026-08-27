---
title: "Revisão — refresh C_docker_floor_gap (CONFIRMED, gap persiste)"
date: 2026-08-27
branch: fix/refresh-c-docker-floor-measured
reviewer: "self-review (autor) — 2a medição do 1o /meta:drive na onda m2-bridge (verification read-only)"
reviewed_diff_sha256: a72045fa285f2c8b9874ff745f27f2d07bc804c915cef929a93c7b175dd4980f
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 15000
duration_min: 12
---

# Resíduo — REGRA 56 (refresh C_docker_floor_gap)

O driver rotou C_docker_floor_gap como verification e mediu contra o cgroup vivo. **CONFIRMED**:
onion-vps-logto min=0/max=1GB, onion-vps-logto-postgres min=0/max=512MB — piso 0 e teto EXATOS da
claim. Gap persiste. Per CONFIRMED (kg-freshness), único edit: refresca verified_at 07-26→08-27.

## 🔴 REAL #1 (lição do read-path, curada no verified_against)
Quase dei **DRIFTED falso**: os primeiros scopes docker que medi (`find docker-*.scope`) davam
max=max — mas eram do **adotante arandek** (onion-adopt-arandek-logto/postgres), não do core.
Mapeando via `docker ps -> id -> scope`, os containers do CORE batem EXATO com a claim. É
[[testar-no-caminho-errado-e-nao-testar]] / verify-read-path ao vivo: medir o container certo. A
lição ficou no verified_against do nó (mecanismo, não só resíduo).

## Verificação
radar --integrity --schema rc=0; realign --check ALINHADO (0 tipo-c). O gap segue `open` (o fix é
D_logto_same_protection_tier — slice pai + auth + compose), agora com freshness de hoje.

**Veredito: APROVADO** — medição real, CONFIRMED honesto (não inflei pra DRIFTED apesar do sinal
inicial errado), lição do read-path incorporada. --no-verify: radar rc=0 + feature branch + carga.
