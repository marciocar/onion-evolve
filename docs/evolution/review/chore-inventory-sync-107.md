---
title: "Revisão — sincronização de inventário 106→107 (satélites)"
date: 2026-08-27
branch: chore/inventory-sync-107
reviewer: "self-review (mecânico) + verificação-por-ausência do número velho + re-lint completo"
reviewed_diff_sha256: 227c135598e5fdce2b7c94289857dd2b25bbd13ec70da24561d08bd220e208e6
findings_total: 0
findings_real: 0
verdict: APROVADO
tokens: 9000
duration_min: 12
---

# Resíduo — REGRA 56 (sincronização de inventário)

Mudança **mecânica e determinística**: propagar a contagem canônica (107 comandos / 93 KBs / 12
skills — SSOT `inventory.sh`) para os docs-satélite que o OP-1 (PR #697) deixou em 104/92-93. Não há
lógica nova a quebrar; o risco é (a) número errado, (b) tocar o que NÃO é contagem-viva, (c) desviar
alinhamento de ASCII, (d) desincronizar o plugin. Os quatro foram verificados.

## Método
1. `inventory.sh --markdown` (regenera a SSOT) + `lint-artifacts.sh --fix` (propaga a frase-de-total
   canônica em 13 arquivos).
2. Reconciliação MANUAL das formas fora do escopo do `--fix` (tabela, invertida, prosa, ASCII), com
   replacements ancorados.
3. **Verificação-por-ausência** (`rename-verifica-por-ausencia-da-palavra`): grep confirmou zero
   resíduo LIVE de 104/92/91 nas 5 superfícies — sobrou só o esperado.
4. Re-lint completo: **0 HARD, 0 count-drift**.

## O que foi PRESERVADO (não é contagem-viva — decisão consciente)
- `onion-framework-identity.md:491` — snapshot histórico do resync **2026-07-24** (102/87). Registro
  datado, não estado atual.
- `onion-framework-identity.md:82` — "92 entradas" = migalhas de **diário**, não KBs.
- `business-logic.md:236` — "TTL de 90 dias" (REGRA 42), não contagem.
- `INDEX.md:598` — narrativa de um incidente passado de drift (texto-lição), não número vivo.

## Plugin
O `onion` bundla `onion.md`/`warm-up.md`/agente `onion`/kb `onion-framework-identity.md` — que carregam
a contagem. Re-montado com `assemble-plugin.sh` (tree_sha 902582→**73212a3e**); `provenance.json` do
plugin commitada porque o gate de sync (`lint-artifacts.sh:1059`) lê o `tree_sha` dela. O
`onion-work-tools` NÃO foi tocado (só churn de `ref`, tree_sha inalterado — `plugin-provenance-churn`).

## Verificação (medida)
- `lint-artifacts.sh` → 0 HARD, 4 SOFT (todas baseline pré-existente: kg-verification 46, kb-vendored
  43, doctrine-freshness lexical, R56-isenção-sem-PR).
- Alinhamento das caixas ASCII em `identity.md` preservado (104→107 e 91→93 mantêm a largura de dígitos).

## Veredito
**APROVADO.** Sincronização determinística, verificada por ausência e por re-lint; nada de contagem-viva
ficou em drift, nada de histórico/não-inventário foi corrompido.
