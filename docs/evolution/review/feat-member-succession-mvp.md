---
title: "Revisão — o lote de update fechou: 3 adotantes no pin novo + sucessão poc→mvp no ledger"
date: 2026-08-31
branch: feat/member-succession-mvp
reviewer: "cada alvo dogfoodado no próprio lint pós-update (mvp 0 HARD; arandek 89→4, todos locais/transição; granaai 56→6, todos locais); members-validate rc=0; pin-integrity do mvp pin-ok"
reviewed_diff_sha256: 30bfabc29f1e5f51811e81a1ff2624abf105076423a9d8ae4e5106bcf9d3fa7b
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 0
duration_min: 75
---

# Resíduo — REGRA 56

Selo do maestro: `adopt --update` em **mvp → arandek → granaai** ("ataca direto o mvp"; a PoC
vira peça de arquivo). Executado com dogfood por alvo, e o lote **melhorou o mecanismo 3 vezes**
no caminho (PRs #728/#729 + este).

## Os 3 alvos

| alvo | pin | dogfood | entrega |
|---|---|---|---|
| **mvp** (local) | `219e9a5f` | **0 HARD** | merge limpo ×2, gate vivo provado, baselines semeados (incl. R64 via `--ensure-from` — o mecanismo inteiro fechou ponta a ponta) |
| **arandek** | `219e9a5f` | 89 → **4** (2 traces + 1 mail + 1 transição de escopo — todos locais) | branch `chore/onion-update-3ed62001` no remoto deles; **gate religado via husky** (estava INERTE: `hooksPath=.husky/_`); 38 exposições de compose toleradas por catraca |
| **granaai** | `219e9a5f` | 56 → **6** (nuclea + 5 traces — todos locais) | branch `chore/onion-update-158f47c7` no remoto; `.gitignore` que **ignorava `.claude/` inteiro** escopado (classe REGRA 40); `D_ADOPT_MUST_EMIT_MISSING_BASELINES` **fechado** (29 chaves do corpus deles) |

## O que o lote devolveu ao mecanismo (fix-must-become-mechanism, 3×)

1. **R64 ganhou catraca** (#728) — 38 HARD legados no 1º contato provaram a falta.
2. **`.claude/rules` entrou no manifesto de vendor** (#729) — a KB de ontologia apontava o vazio
   em TODO adotante (2×2 medido).
3. **Baseline R64 vazio no core** (#729) — o `--ensure-from` agora semeia em pré-catraca.

## Este PR

Sucessão **poc→mvp** no `members.yaml` (slug preservado — identificador de NDA, não de fase;
`local_path` → mvp; `onion_version` → `219e9a5f`; a PoC arquivada com pin congelado).
`members-validate` rc=0 · `pin-integrity-check` do mvp: **pin-ok**.

## Honestidade

- 3 tentativas de edição do YAML falharam por INDENTAÇÃO (o membro usa 4 espaços; escrevi 6) —
  o `members-validate` pegou todas; a 4ª, por número de linha, passou.
- Os HARD restantes de arandek/granaai são dívida local **deles**, nomeada nos relatórios
  `inbound/` de cada um — o merge das branches é deles.
