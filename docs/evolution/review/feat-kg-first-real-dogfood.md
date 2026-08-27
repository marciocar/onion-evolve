---
title: "Revisão — primeiro dogfood real da catraca REGRA 49 (baseline 47→46 por medição)"
date: 2026-08-27
branch: feat/kg-first-real-dogfood
reviewer: "self-review (autor) — medição read-only contra o vivo (kg.md), verificada por comportamento"
reviewed_diff_sha256: cf6321b1a5489b2b7427de29ab4e5790595f397e592824e014b3bdfe5865e1b3
findings_total: 2
findings_real: 0
verdict: APROVADO
tokens: 40000
duration_min: 20
---

# Resíduo — REGRA 56 (primeiro dogfood real da catraca)

Surgido do 1º `/meta:realign` invocado pelo maestro, que flagou `Q_PRIMEIRO_DOGFOOD_REAL_DAS_CINCO_CLASSES`
(catraca REGRA 49) como commitment-drift. Levei adiante: medi um nó real do baseline contra o vivo,
carimbei, e o baseline encolheu — a propriedade fundadora da catraca ("só encolhe por MEDIÇÃO") executou
sobre dado real pela 1ª vez (antes 100% sintética).

## O que mudou
- `kg-diagnose-automation-2026-07.kg.yaml`: `D_linha_vermelha` ganhou `verified_at: 2026-08-27` +
  `verified_against` (o único edit in-place que kg-freshness permite para CONFIRMED).
- `kg-verification-baseline.txt`: 47 → 46 (regenerado por `--emit-baseline`; a entrada de kg-diagnose saiu).
- `catraca-regra49-2026-08.kg.yaml`: `E_PRIMEIRO_DOGFOOD_REAL` (evidence) + aresta SUPPORTS → a Q.

## Medição (comportamento, não declaração)
- **Claim medido:** `D_linha_vermelha` — "a automação substitui só o fan-out mecânico; NUNCA o selo na
  PAUSA; não existe `--auto` de diagnóstico (≠ transform)".
- **Método:** leitura read-only do `kg.md` vivo. **Observado:** L434 (fan-out mecânico automatizável),
  L454 ("Nunca o selo humano na PAUSA. Não existe `--auto` de [diagnóstico]"), L435-436 ("o humano sela",
  transform tem auto legítimo), L358 ("o humano sela"). **Veredito: CONFIRMED** — o label bate verbatim.
- **Encolhimento provado:** `coverage rc=0` após regenerar (a catraca aprovou: só encolheu, por medição).
  Radar `--integrity --schema` rc=0 nos dois grafos. `--emit-baseline` reidempotente estável em 46.
- **Auto-verificação do realign:** re-rodado no catraca, o commit-drift caiu 2→1 — a Q deixou de ser
  "objetivo abandonado" porque agora recebe SUPPORTS. A máquina reflete a realidade que a medição mudou.

## Achados (nenhum é defeito)
1. **PARCIAL declarado:** exercí 1 dos 5 caminhos (PASSIVO→medido→removido). As 2 classes HARD
   (NO-BASELINE, REGRESSÃO) e as demais seguem sem execução de campo — por isso a Q permanece `open` e o
   `E_PRIMEIRO_DOGFOOD_REAL` diz isso na cara. Não fechei o que não completei.
2. **Alvo escolhido por mensurabilidade, não conveniência:** `D_RUNTIME_CONTRACT` (o nó que o realign
   marcou ATENCAO) seria a convergência óbvia, mas é decisão *proposed-GATED* ("sela só após Fase 2") —
   não mensurável a carimbar agora, e reetiquetar PROD→DEV seria FUGA (HARD). Escolhi `D_linha_vermelha`
   por ser afirmação viva verificável contra artefato do repo. Declarado para não parecer cherry-pick.

**Veredito: APROVADO** — carimbo lastreado em medição executada (não fabricado), encolhimento provado por
comportamento (coverage rc=0), reconciliação grafo-primeiro honesta sobre a parcialidade.
