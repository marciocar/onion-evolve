---
title: "Revisão — censo lote 3: mortalidade 47%, e o juiz começou a separar vida de TOTAL"
date: 2026-08-30
branch: drive/census-batch3
reviewer: "mesmo desenho selado: 30 workers procure-a-morte × 15 juízes opus/high nos CONFIRMED × tabela de selagem; radar exit 0 nos 12 grafos tocados"
reviewed_diff_sha256: 4ef79e58873e25802fc6970e702937128c4acb8fb3d0075b7d1be2fc074e7a63
findings_total: 14
findings_real: 14
verdict: APROVADO
tokens: 3307368
duration_min: 17
---

# Resíduo — REGRA 56

Lote 3 do `D_CENSO_190_EM_LOTES` (itens 61-90; faixa de atenção 7,0-8,1; **15 grafos** — a cauda
espalha mais que o topo). **30/30 medidos, zero descartes.**

## O número

**Mortalidade: 14/30 = 47%** + o **1º UNVERIFIABLE do censo** (`C_COMPLIANCE_RARE` — não toca
`verified_at`, pela tabela). **Acumulado: 45 mortos em 90 medidos = 50%**, estável nos 3 lotes
(53% · 50% · 47%) — a mortalidade não é fenômeno do topo, é do backlog inteiro.

## Os 14 flips (7 → done · 7 → superseded)

Destaques: `D_legacy_fn_defined`/`D_steps_renumbered` (o resto do plano m2 executado),
`Q_MARKET`/`Q_METHOD` (respondidas pelo norte NS1 selado), `C_METAGAMIFY_VENDOR_VNEXTPIN`
(pin já avançado), `Q_MONITORED_RUNG` (degrau entregue pela escada do drive). Um flip partiu de
`unverifiable` (não `open`): `D_email_plus_logto_connector` → superseded.

## O juízo — 12/15 REPROVADOS, 3 carimbados — e uma evolução

O juiz começou a **separar a vida do TOTAL**: em `Q_INDICE_DO_DIARIO_SEM_CATRACA` ele re-verificou
a vida por 4 caminhos próprios (incluindo inspecionar a branch `chore/graph-diary-index-ratchet`
— que contém só o nó, não a cura), CONFIRMOU o item vivo, e reprovou apenas a cobertura
("3 de 6 — dano zero por SORTE, não por método"). Vida certa + selo inflado = reprovado; o item
segue aberto e **sem carimbo**, correto dos dois lados.

## Gate mecânico

- radar `--integrity --schema` → **exit 0 nos 12 grafos tocados**
- `docs/backlog.md`: **160 → 146** (REGRA 62) · baseline R49: 43 (0 novas)
- custo: 2,18M + 1,13M = **3,31M** · runs `wf_8cf0e944-64b` + `wf_5f6d1c0f-ecd`

## Estado do censo

**90/190 medidos (47%) · 45 mortos selados · backlog 190 → 146.** Próximos lotes (91-190):
sessão futura, mesmo desenho, `resumeFromRunId` e os args de exclusão acumulados no scratchpad.
