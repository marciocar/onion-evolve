---
branch: fix/kg-pr-history-as-evidence
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: 56173973e553d35f95f9fb7e005c4ada16a741aa8e6f70d7ec8bd4c85f197749
reviewed_code_sha256: 9a5c7c4ef6767cb4fa0124ae179a5cb06543522912c7d7aaf2dce07e674bc29a
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: passada própria da sessão do core sobre o diff, sem revisor independente
nota: "tokens 0 = não medido. Troca mecânica de tipo e status em 672 nós, decidida pelo maestro com medida; sem código."
---

# Passada adversarial: `fix/kg-pr-history-as-evidence`

## O que muda

Em `docs/onion/graph/pr-decision-history-2026-08.kg.yaml`, os 672 nós `PR_*` passam de `decision`/`done` a
`evidence`/`confirmed`, e entra o selo do maestro `D_PR_HISTORY_AS_EVIDENCE_1112`.

## Por que (medido)

- O teste cego do kg-ssot (`D_BARE_DECISION_RULE_STAYS_1112`) manteve a regra `integrity.bare-decision`; 671
  das 736 dívidas do core estavam neste grafo.
- O grafo é escrito à mão (sem gerador); o corpo dos PRs descreve a mudança mais do que uma escolha; 26% da
  amostra de 19 cita adotante ou repo de terceiro no corpo, então copiar o corpo exigiria limpeza.
- O único leitor vivo (`site/src/lib/vitrines.ts`) lê por id e não pelo tipo; o decide-census e a triagem só
  leem nós `open`.

## Conferência

Radar `--integrity --schema` exit 0 e `kg-contract-check.sh` rc 0 no grafo; a mudança por nó é só
`node_type` e `status` (1.344 linhas).

## Mutantes

Não se aplica: nenhum código mudou.
