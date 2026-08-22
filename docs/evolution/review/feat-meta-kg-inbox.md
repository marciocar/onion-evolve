---
title: "Revisão adversarial — /meta:kg-inbox, a perna de selagem (PR #650)"
date: 2026-08-22
branch: feat/meta-kg-inbox
pr: 650
reviewer: "@branch-code-reviewer (passada adversarial, mandato REFUTAR)"
reviewed_diff_sha256: 59444d295407707dba5e06eae7f5368790d54bf9205fdf168853cb250148f297
findings_total: 5
findings_real: 2
tokens: 62179
duration_min: 11
verdict: APROVADO-COM-RESSALVAS
---

# Resíduo de revisão — REGRA 56

Passada adversarial sobre `origin/main...HEAD` (excluído `docs/evolution/review/`), mandato refutar.
**5 eixos investigados, 2 achados reais.**

## Verificações que PASSARAM (tentei refutar, não consegui)

| Eixo | Resultado |
|---|---|
| Radar exit 0 no grafo F4b | ✅ 17 nós / 22 arestas, sem órfão, enums válidos, `Q_SEALING_NO_MECHANISM` → done com aresta `E_SEALING_MECHANISM SUPPORTS` |
| Lint count-drift | ✅ 0 HARD de contagem (a propagação 102→103 não quebrou guarda) |
| Linha histórica "o pitch dizia 102" | ✅ PRESERVADA (identity:492) + os `.kg.yaml` históricos não tocados |
| Triagem I3 | ✅ grana-ai-mapeamento → _rejected (fronteira de repo); gap-web-search → _sealed; headers de genealogia presentes; `Q_TENANT_WRITE_DESTINATION` nasceu open |
| Comando cumpre o que promete | ✅ guarda de papel (só source), gate "radar exit 0 na selagem" descrito, produtor/README existem |

## Achados

**M1 (MÉDIO) — CORRIGIDO.** `onion-framework-identity.md:491`: a propagação 102→103 vazou para um
**registro de changelog congelado** (v1.3.0, 2026-08-03 — o "87 KBs" ao lado prova o snapshot), que
passou a contradizer as linhas 492-493 (o resync reconciliou em 102). **Revertido para 102** — registro
histórico datado, não SSOT viva. (Dogfood req 4: veredito verificado com evidência — o 87 intocado — e
então corrigido.)

**O1 (LOW) — reconhecido, não corrigido (com razão).** `.kg.yaml` snapshots datados
(`technical-context-core-2026-07:68`, `bridge-produto-2026-08:38`) seguem em 102 enquanto os `.md`
irmãos foram a 103. É **ponto-cego pré-existente do count-drift** (documentado no próprio nó :68),
**não introduzido por este PR** — e são registros datados defensáveis. Fora de escopo.

## Veredito

**APROVADO-COM-RESSALVAS** → M1 corrigido antes do merge; O1 é dívida pré-existente rastreada. O
mecanismo (comando, grafo, selagem, gate radar exit 0, guarda de papel) está correto e **verificado por
execução, não por declaração**.
