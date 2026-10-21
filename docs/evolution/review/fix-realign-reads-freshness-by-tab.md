---
branch: fix/realign-reads-freshness-by-tab
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: 8bb4b1de8ed736e0bfe8c21d28806b38256b09f6bbfecb87d0de5bd8cdd82ed7
reviewed_code_sha256: 83246ed2de9c5607affee277dcb8134e739a2fded89a8d092c49f3f2e121c7a0
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 20
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, a partir de um /meta:realign que deu zero em tudo
nota: ""
---

# Passada adversarial: `fix/realign-reads-freshness-by-tab`

## Como apareceu

O maestro pediu `/meta:realign`. Nos 8 grafos tocados na sessão, o resultado foi ALINHADO com (c)=0, (b)=0 e
(a)=0 em todos. Zero em tudo é suspeito, porque no warm-up o radar do `fios-abertos` tinha acusado nós
`STALE-MISSING`. Conferi a entrada que o realign consome: o `--freshness-tsv` trazia os 3 na coluna 11.

## O defeito

O `awk` da classificação rodava com o separador padrão (espaço). O `--freshness-tsv` é separado por TAB, e as
colunas `verified_against` e `trace` têm espaços. Na passada 3, o `$11` era um pedaço do texto (`20`, `campo`)
e não o veredito. A camada 2 nunca via STALE, e o `trace` usado pela camada 3 também saía torto.

## A cura

A passada 3 divide a linha com `split($0, f, "\t")`. As passadas 1 e 2 ficam no separador padrão: o
`--status-tsv` não tem espaço nos campos, e o `--triples` é separado por espaço (conferido com `cat -A`).

## Achados

1. **REAL (curado):** o defeito acima. A fixture `drift-a-spaced`, com um nó PROD sem `verified_at` e com
   `verified_against` e `trace` de várias palavras, dá (a)=0 no código antigo e (a)=1 com a cura.
2. **Refutado:** "a cura muda o veredito dos grafos reais?" Não muda: os 8 seguem ALINHADO, sem (c). Passam a
   aparecer sinais informativos que estavam escondidos: fios-abertos (a)=3 e bind=1, rito-task-manager commit=2,
   kg-read-leg (a)=1 e bind=1. Todos ficam abaixo do limiar de histerese.

## Mutantes

Reverter a cura (voltar a `$11`) faz o caso `drift-a-spaced` reprovar. Família `realign`: 11/11.

## Limites declarados

Os sinais informativos que apareceram (STALE e commit/bind) não são reconciliados neste PR. Eles vão ao maestro
como resultado do `/meta:realign`.
