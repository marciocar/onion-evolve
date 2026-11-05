---
branch: fix/door-standalone-lint
pr: pendente
date: 2026-11-05
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: PENDENTE
elenxo: nao
reviewer: PENDENTE
nota: "PASSADA ADVERSARIAL PENDENTE, declarada: nenhum revisor leu este diff. Os zeros são 'não medido', não 'sem achados'. O verdict fora do vocabulário é proposital: o --schema reprova até a passada rodar, e o PR não abre com este arquivo como está."
---

# Passada adversarial: `fix/door-standalone-lint` (PENDENTE)

## O que muda

As REGRAS 62 (Projeção GERADA em sincronia com a fonte) e 109 (CLAUDE.md não cresce sem tirar o equivalente
ou citar um nó) passam a declarar `# aplica-se: source`. Fora do core elas não rodam e saem contadas à parte.

A porta standalone tem IS_DERIVED=0, e o porteiro das duas regras era esse. Ela era julgada por objetos que
não recebe: a projeção dos termos depende de grafos que não viajam, e o teto mede o CLAUDE.md do core.

## Achados

Nenhum: a passada não rodou.

## Mutantes

Os casos de bancada (d-m) e (f-m) apagam a declaração de cada regra numa cópia do lint, e a acusação volta.

## Limites declarados

- O arquivo de teto segue viajando para as portas: a bancada role-cut (v) cobra isso, e sem objeto ele é inerte.
- A porta segue sem conferir se o house-codes.tsv que recebeu está em dia. Quem confere é o core, antes de publicar.
