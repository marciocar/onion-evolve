---
title: 'Proposta da curadoria: Tessl → PARQUEAR, com costura mínima de distribuição (estudo C, família C, até o N3)'
date: 2026-10-15
from: onion-curation (consumidor)
to: core (onion-evolve)
type: proposal
flow: upstream (consumidor→core)
---

# Proposta: PARQUEAR a Tessl, com gatilho datado e três gatilhos de evento

O veredito foi escolhido pelo maestro em 2026-10-15, entre parquear e enviar, parquear sem enviar, costurar e esperar, e selado aqui em `D_TESSL_STUDY_C`.

O estudo C da curadoria disseca a Tessl (Tessl Holdings, Inc., fundador Guy Podjarny), que é ator da família C.
Por `D_FAMILY_C_NO_ABSORB`, o estudo não tem `absorver` nem N4 de absorção e termina no N3. A curadoria
propõe; quem decide é o core.

- **Grafo:** `onion-curation:docs/evolution/dissect/tessl-2026-10/tessl-2026-10.kg.yaml` (nó `D_TESSL_STUDY_C`)
- **Linha de base:** `onion-curation:docs/evolution/research/tessl-baseline-2026-10/` (run `wf_645d8c3a-2bb`,
  decisão `D_TESSL_BASELINE_2610`)
- **Resíduo da revisão:** `docs/evolution/review/research-study-c-tessl.md`. O Elenxo pediu CORRIGIR, com 6
  achados, todos aplicados. Nenhum número estava errado.

## Veredito proposto

**PARQUEAR a Tessl**, admitindo a **costura mínima e reversível de distribuição** que vem da linha de base. O
estudo **sustenta** a decisão da linha de base e acrescenta a ela o gatilho datado e três nós de N2 que ela não
tinha.

## O que o estudo mediu

| Nível | Resultado | Nó |
|---|---|---|
| N0 | Capital **medido em filing**: US$ 124,5M em dois Form D de 2024 (US$ 25,0M e US$ 99,5M), com receita "Decline to Disclose". Nenhum Form D em 2025 ou 2026. | `E_N0_IDENTITY_CAPITAL` (tier 10) |
| N1 | Vende reviews, evals e sessões de agente cobrando por créditos (Free com 1.000 créditos; Team a US$ 100/mês; Enterprise). Publicar e instalar é grátis. Preço estável desde 2026-07-18 (Wayback). | `E_N1_JOB_AND_PRICE` |
| N2 | A subsidiária britânica tem contas **sem auditoria**. Nos 11 meses até jan/2025: 14 funcionários, prejuízo de £2,71M, caixa de £8,8M e dívida de £12,5M com a holding. | `E_N2_UK_ACCOUNTS` (tier 10) |
| N2 | Em jan/2026, emissão de cerca de £17,46M em ações "for cash", provável conversão de dívida (NÃO VERIFICADO). | `E_N2_UK_CAPITAL_2026` (conf. 0,6) |
| N2 | Downloads no npm subiram de cerca de 2 mil para 64 a 69 mil por mês em um ano. Downloads não são usuários, e o número pode ser inflado por CI. | `E_N2_TRACTION_NPM` |
| N2 | O núcleo é **fechado**: o GitHub público só tem skills, actions e demos. Costura, só pela CLI ou pela API. | `E_N2_CLOSED_CORE` |
| N3 | É DIFERENTE do Onion: o Onion não compete como registry. O espaço dele é o gate no repo, sem crédito, e o compliance. | `E_N3_POSITIONING` |

## Gatilhos de reabertura

1. **Datado: 2026-11-15**, depois do prazo das contas da subsidiária, que vence em 2026-10-31 (exercício até
   jan/2026). A reabertura olha receita e headcount novos.
2. **Por evento, o que vier antes:**
   - Form D novo;
   - a Tessl abrir o registry;
   - fusão ou aquisição (M&A).

## NÃO VERIFICADO

- Receita.
- Burn e caixa do grupo.
- Natureza do aporte de jan/2026.
- Total do registry (o piso é de 1.274 no sitemap).
- Usuários reais por trás dos downloads.
- Custo da costura de distribuição: termos de uso e lock-in (`E_N2_GAPS`).

## Relação com o sinal do panorama

O sinal `2026-10-14-landscape-tessl-findings` já foi triado pelo core no PR #1106 (merge commit `4fc0f61f`: o "10k+" e o `B5_17` refutado). Esta proposta trata só do veredito do estudo C.

## Bilhetagem

O estudo não abre via nova para o Onion. O modelo da Tessl, com registry grátis como funil e cobrança só no que
executa, foi para o panorama como hipótese, não como transferência.
