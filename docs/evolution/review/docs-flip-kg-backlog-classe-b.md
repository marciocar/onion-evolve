---
title: "Revisão — flip aprovado: Q_KG_BACKLOG parte em duas classes (A curada, B aberta e estreitada)"
date: 2026-09-04
branch: docs/flip-kg-backlog-classe-b
reviewer: "condutor: flip APROVADO pelo maestro ('aprovado, faz o PR do flip'); Aufhebung (antigo → superseded, novo SUPERSEDES); radar exit 0 (17 nós/17 arestas); censo READY com o nó novo; reprodução declarada com o teto de poder"
reviewed_diff_sha256: 74090f8d594471a918b6bc2bea6eef3889db0e809db6ca4d81b93a3a8d66fa94
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 60000
duration_min: 40
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados

1. **Fechar o nó como "respondido" seria overclaim.** A causa medida hoje (veredito por pipe para leitor multi-thread) explica `line-limits (d2)` e `graph: atores`, mas o caso `(e)` **não decide por `grep -q`** — extrai dois contadores com `_emit | sed -n | tail -1`, sem fechador precoce. A pergunta abrangia uma classe; a medição a partiu em duas.
2. **A reprodução que eu disparei não tinha poder estatístico** — 20 execuções para uma taxa de ~1/100. O número entra no nó com o teto dito; a migalha do diário registra a regra (calcular o N pela taxa antes de rodar, e instrumentar quando o N for inviável).
3. **A atenção do nó novo é menor (4,5 contra 6,0)** porque ele nasce com menos arestas — e isso é correto: o peso acompanha a evidência acumulada, não a idade da pergunta.

## Fora de escopo
- Investigar a classe B agora: sem ocorrência nova, não há dado. O gatilho está instrumentado no próprio caso.
