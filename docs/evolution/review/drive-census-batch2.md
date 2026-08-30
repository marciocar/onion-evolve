---
title: "Revisão — censo lote 2: mortalidade 50%, e o juiz achou a morte que o glob escondia"
date: 2026-08-30
branch: drive/census-batch2
reviewer: "mesmo desenho selado do lote 1: 30 workers procure-a-morte × 15 juízes opus/high nos CONFIRMED × tabela de selagem; radar exit 0 nos 9 grafos tocados"
reviewed_diff_sha256: d028f81395466ee3e755d2ad52c44f453d58b4382a7c5d02e8cff1fe488adba8
findings_total: 15
findings_real: 15
verdict: APROVADO
tokens: 3270302
duration_min: 15
---

# Resíduo — REGRA 56

Lote 2 do `D_CENSO_190_EM_LOTES` (itens 31-60 por atenção, excluídos os 30 já medidos —
guarda de repetição do drive). **30/30 medidos, zero descartes.**

## O número

**Mortalidade: 15/30 = 50%** (15 DRIFTED, 0 REFUTED) — consistente com o lote 1 (53%).
Acumulado do censo: **31/60 = 52%** no topo do backlog.

## Os 15 flips (11 → done · 4 → superseded)

Padrão idêntico: trabalho pago e não carimbado. Destaques: `Q_monitoring_stack` (pesquisa JÁ
executada com Elenxo), `Q_instrument_value_per_adopter` (4/4 scripts entregues),
`D_ARISTOTLE_HOME_IS_KB` (KB criada), `C_R45_COBERTURA_FALSA` (as 3 claims morreram na correção
de 08-03) — e a morte poética: `Q_juiz_adversarial_nao_rodou_m8` morreu **pelo selo B desta
manhã** (o limiar de 30% que ele denunciava caiu).

## O juízo — 14/15 REPROVADOS, 1 carimbado

O melhor achado é de novo do juiz: `C_op_update` afirma "100% edição manual" e o
**`/meta:personality-sync` já escreve** `personality_summary` no ledger (members.yaml:46-48,
dogfoodado no core desde 07-24). O worker não podia achar: seu `find` filtrava por
`*federation*` — **a conclusão de ausência era artefato do glob, não medição**. Os 14 ficam
abertos e sem carimbo. `C_op_promote` aprovado e carimbado.

Subcontagem persistente: juízes contaram 4-10 onde workers declararam 2-5.

## Gate mecânico

- radar `--integrity --schema` → **exit 0 nos 9 grafos tocados**
- `docs/backlog.md`: **175 → 160** (REGRA 62) · baseline R49: 43 (estável, 0 novas)
- custo: 2,17M (workers) + 1,10M (juízes) = **3,27M** · runs `wf_df073bae-4ba` + `wf_8906ab14-786`

## Estado do censo

60/190 medidos (32%) · 31 mortos selados · próximo lote: itens 61-90.
