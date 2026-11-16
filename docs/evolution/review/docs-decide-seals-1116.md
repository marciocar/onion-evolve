---
branch: docs/decide-seals-1116
pr: pendente
date: 2026-11-16
reviewed_diff_sha256: a494490f844bbeda430241c49264367ebffc870aeb81f66f82f1815446e09d49
reviewed_code_sha256: 4db0cca1b5f2d0e867faef7c45af5b241661c16e9a7bf854a54e1bf547548359
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "Quatro selos gravados pelo kg-decide-seal.sh (o selador sai 0 só com radar --integrity --schema exit 0, contrato rc 0 e lint de nomes sem achado novo; saiu 0 nos quatro) e um carimbo de medição no nó do gatilho do rea-method (kg-radar rc 0 e kg-contract-check rc 0 no grafo). Voz única do core; só grafos, nenhuma guarda tocada."
nota: "Os quatro selos são respostas do maestro por pergunta com opções no /meta:decide de 2026-11-16. Três foram para o grafo de arquivo de selos porque o grafo de coordenação está no teto de nós e o selador recusou gravar lá."
---

# Selos do /meta:decide de 2026-11-16 e carimbo do rea-method

## O que muda

- `D_ISOLATED_REFUTER_CRITERION_1116` (review-gate-saldo-2026-09): conta como refutador isolado o agente separado de quem escreveu, só leitura, com mandato de refutar.
- `D_ISOLATION_ROUND3_CURATION_WRITES_CASES_1116`: na rodada 3 do arnês de isolamento, a curadoria escreve os casos e a sessão de operações da VPS julga.
- `D_RITUAL_PROFILE_ISO8601_EVENT_RRULE_1116`: o ritual do agente é perfil sobre tipo existente; cadência por duração ISO 8601 e gatilho por evento, mais RRULE da RFC 5545 validada na forma.
- `D_SESSION_CAP_8_AND_TMUX_MIGRATION_1116`: teto de sessões interativas de 4 para 8 e migração das quatro sessões fora do tmux.
- `Q_REABRIR_PARIDADE_POS_FORGE` (rea-method): re-medido, o gatilho não disparou; segue aberto com a medição de 2026-11-16.

## Achados

Nenhum.

## Limites declarados

- Os selos registram a decisão; a execução de cada uma (casos da rodada 3, desenho do perfil, mudança do teto no pulso, migração para tmux) é trabalho à parte.
