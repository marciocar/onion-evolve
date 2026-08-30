---
title: "Revisão — censo lote 4: 53%, o experimento que a decisão atropelou, e mais um fail-open de worker pego"
date: 2026-08-30
branch: drive/census-batch4
reviewer: "mesmo desenho selado: 30 workers × 13 juízes opus/high nos CONFIRMED × tabela de selagem; radar exit 0 nos grafos tocados"
reviewed_diff_sha256: fa8ec617f4a6c34d5722df1ca94e9e320e8793a8a29b9425cbbdc26915ea2ad1
findings_total: 16
findings_real: 16
verdict: APROVADO
tokens: 3163215
duration_min: 18
---

# Resíduo — REGRA 56

Lote 4 (itens 91-120; faixa 5,4-7,0). **30/30 medidos, zero descartes.**

## O número

**Mortalidade: 16/30 = 53%** + 1 UNVERIFIABLE (`C_commodity_vs_diff`). **Acumulado: 61 mortos em
120 medidos = 51%** (53 · 50 · 47 · 53) — placar estável em toda a fila.

## Os 16 flips (12 → done · 4 → superseded)

O achado do lote: **`D_COLD_ADOPTER_EXP`** — o experimento nunca rodou (posts em
`rascunho-pronto-para-o-maestro-postar`, o `/convite/` foi reaproveitado pelo site novo) e a
pergunta que ele existia para desempatar (NS1 vs NS3) foi **respondida por decisão direta do
maestro em 08-06**. Obsoleto por mudança de mecanismo de decisão. Também: `C_real_precedent`
(o precedente motivava o flip de identidade — executado até o P11), `D_rbac_two_layers` e o
resto da cauda do m2.

## O juízo — 8/13 REPROVADOS, 5 carimbados — e mais um fail-open de worker

O juiz pegou um worker fazendo `grep` em **`docs/diary/` — diretório inexistente** — com
`2>/dev/null`, e reportando o silêncio como "nenhuma entrada menciona": o diário vive em
`.claude/diary/`, onde a entrada existia. *"O vazio da ferramenta virou afirmação sobre o
mundo"* — a classe `exit-code-nao-e-a-verificacao`, no worker, pega pelo juiz re-executando.
Reprovações continuam majoritariamente do tipo "vida certa, selo TOTAL inflado".

## Gate mecânico

- radar exit 0 nos grafos tocados · `docs/backlog.md`: **146 → 130** (REGRA 62) · baseline R49 estável
- custo: 2,20M + 0,97M = **3,16M** · runs `wf_058cbded-e55` + `wf_da7d6a16-49e`

## Estado do censo

**120/190 medidos (63%) · 61 mortos selados · backlog 190 → 130.** Restam ~70 (atenção ≤5,4 — a
cauda fina). Retomável pelo mesmo desenho; args de exclusão acumulados no scratchpad da sessão.

## Achado do CI deste próprio PR (e a cura, no mesmo lote)

O `selftest` REPROVOU o lote: o caso **status-factor (c)** usava um **grafo vivo como fixture**
("o grafo com nó `unverifiable`" = `vps-shared-tools`) — e o censo do lote 3 flipou o **último**
`unverifiable` daquele arquivo. Sem a classe no insumo, o mutante produz saída idêntica e a
prova-de-mutação morre por vácuo. **Fixture viva é empréstimo com prazo.** Cura: o caso agora
SINTETIZA o próprio grafo (como o caso (d) já fazia). Dogfood provado nos dois lados:
`rc_int=0` · `rc_mut=1`.
