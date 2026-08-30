---
title: "Revisão — censo lote 1: mortalidade 53% no topo do backlog, 15 flips selados"
date: 2026-08-30
branch: drive/census-batch1
reviewer: "3 camadas do desenho selado (C, 2026-08-30): 30 workers sonnet/medium com mandato procure-a-morte × 14 juízes opus/high sobre os CONFIRMED (o desfecho preguiçoso) × aplicação pela tabela de selagem; radar exit 0 nos 6 grafos tocados"
reviewed_diff_sha256: 73e860f58b7da40e75cc954f897c7b61bfa58b78c1ecd04a228771d04285c8f4
findings_total: 16
findings_real: 16
verdict: APROVADO
tokens: 3222219
duration_min: 20
---

# Resíduo — REGRA 56

Primeira execução de `D_CENSO_190_EM_LOTES` (selo C). Lote 1 = top-30 por atenção do
`docs/backlog.md`. **30/30 medidos, zero descartes** — primeiro run do schema curado sem
nenhuma perda.

## O número

**Mortalidade no topo: 16/30 = 53%** (15 DRIFTED + 1 REFUTED) — entre a amostra de 60% e
bem acima da baseline de 33%. O caso-sentinela confirmou: o item de atenção **119.0**
(`D_gate_oidc_dual`) estava morto — construído e superado pelo P11 em 08-13.

## Os 15 flips aplicados (9 → done · 6 → superseded)

Anatomia: **9 dos 15 são decisões do flip m2 entregues** (o P11 removeu o legado do binário;
as decisões ficaram abertas 17 dias depois de pagas). Os outros: `D_METHOD_KG` (o "candidato"
virou padrão com 76 grafos), `Q_IDENTITY` (respondida no próprio grafo), `ENT_email` (gap
dissolvido pelo redesenho `--enroll`), `C_SURFACE_REMAINS_GATED` (D_NO_COMMAND já fechara),
`D_D5`/`C_D5_rec` (ratificados/incorporados no grafo irmão), `D_proof_command_fixed`
(executado, E_p4 prova). Evidência integral por item: run `wf_87c4a44e-0ff`.

## O que NÃO flipou, e por quê

- **`D_default_deny_routes` REFUTED — retido para o maestro** (tabela: REFUTED para).
  O mecanismo descrito (default-deny por allowlist ancorada) não corresponde ao código nem a
  nenhum ponto do histórico.
- **11 CONFIRMED reprovados pelo juiz — sem carimbo.** O melhor achado: `D_spec_now_build_gated`
  declara "SEM construir" e o juiz provou que o command-side **foi construído** (OP-1,
  `/meta:federation-member`, PR #697) — o worker citou o nó que nomeia o drift e devolveu
  divergência vazia. Esses 11 ficam abertos e sem carimbo; a subcontagem persiste (juízes
  contaram 6-8 onde workers declararam 2-5).
- **3 CONFIRMED aprovados pelo juiz — carimbados** (`Q_GUARDAS_COERENTES`,
  `D_logto_same_protection_tier`, `D_middleware_order_first`).

## A calibração continua rendendo

Juiz: 11/14 reprovações, 3/14 aprovações — de novo não-unânime. Achou morte real que os
workers perderam (2 casos com evidência verbatim). Subcontagem dos workers no lote:
consistente com os 44-48% dos corpora anteriores.

## Gate mecânico

- radar `--integrity --schema` → **exit 0 nos 6 grafos tocados**
- `docs/backlog.md`: **190 → 175 abertos** (REGRA 62)
- baseline R49: 43 (estável — nenhum dos flips estava no passivo)
- custo do lote: 2,20M (workers) + 1,03M (juízes) = **3,22M** (projetado: ~3,6M)

## Próximo lote

Itens 31-60 por atenção (`resumeFromRunId` disponível). Orçamento restante suporta **2-3 lotes**;
o resto retoma em sessão futura, como o selo C determina.
