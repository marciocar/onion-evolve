---
title: "Revisão adversarial — protocolo de dogfood da doutrina profunda (PR #649)"
date: 2026-08-21
branch: feat/librechat-dogfood-protocol
pr: 649
reviewer: "@branch-code-reviewer (passada adversarial, mandato REFUTAR)"
reviewed_diff_sha256: 5588e47d31d1fc4cf2cd1df401674be320a21035608bd38228b9f67fd0b78bd0
findings_total: 6
findings_real: 0
tokens: 54055
duration_min: 12
verdict: APROVADO
---

# Resíduo de revisão — REGRA 56

Passada adversarial sobre o diff `baee4ce5..HEAD` (excluído `docs/evolution/review/`), mandato de
**refutar**, default "achado real" só com evidência (arquivo:linha + modo-de-falha). **6 suspeitas
levantadas, 0 defeitos substantivos sobreviveram.**

## Verificações mecânicas (evidência, não declaração)

| Verificação | Resultado |
|---|---|
| `kg-radar.sh` no grafo F4b | **exit 0** — 12 nós / 16 arestas, 0 órfãos, schema v1, sem contradição |
| `kg-radar.sh` nas 2 propostas kg-inbox | exit 0, sem órfão |
| `kg-provenance-coverage.sh` | **117/117** — bate com o HTML; grafo-público verde |
| `lint-artifacts.sh` | 0 HARD real (a única HARD era o próprio resíduo desta revisão) |
| `.pyc` | 3 estavam rastreados na base; removidos + gitignored — higiene correta |

## Suspeitas refutadas (não viraram achado)

- *"Proposta de teste deletada viola Aufhebung"* → REFUTADO: `dogfood-prerun-test*` nunca foi
  commitada (fixture transitória no working tree), nada a preservar.
- *"67 grafos não bate com o repo"* → não-contraditado: é medição de runtime no escopo do server na
  VPS (`docs/onion/graph`=40 + `docs/evolution`=23), declarada com passos de repro.
- *"Propostas kg-inbox fora de escopo"* → REFUTADO: são load-bearing para `Q_SEALING_NO_MECHANISM` e
  seguem o lifecycle versionado do README da fila.
- *"Números do doc (103s, coverage) inflados"* → CONFEREM contra o vivo.
- *"status confirmed→done é drift"* → é FIX: o radar quer pergunta respondida como `done`.

## Nit cosmético sobrevivente (não-bloqueante, decisão registrada)

- **`.claude/session-lifecycle.jsonl` (+3) no PR** — churn de telemetria de sessão, alheio ao
  protocolo. Inócuo (append-only, não corrompe). **Decisão:** não removido — um force-push para
  reverter 3 linhas de telemetria custa mais que o ganho; registrado aqui em vez de escondido.

## Veredito

**APROVADO** — grafo coerente (radar exit 0, sem órfão, enums válidos), doc fiel ao grafo com escopo
**honestamente limitado** (Elenxo parcial, SDAAL conhecimento, MAP gated — buracos nascem como nós
`open`, não em prosa), higiene correta, coverage verificado. O `reviewed_diff_sha256` casa com o diff
deste PR.
