---
branch: fix/door-standalone-lint
pr: pendente
date: 2026-11-05
reviewed_diff_sha256: 9bb1c3df9fca71f19fd07d99fce331c28e7cbe705098854704cd4bb12020d5c7
reviewed_code_sha256: c8b5c76089376624bb2fa84fe771bb29f14f147c1ff8d1cacb28cd785a041470
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão do core, leitura do diff do lint e do resumo do autor; sem refutador separado"
nota: "tokens e duração 0 = não medido. Passada curta, sem refutador separado, porque o diff só declara o escopo de duas guardas, com caso e mutante, e a publicação da porta espera. Não reproduzi as medidas do autor."
---

# Passada adversarial: `fix/door-standalone-lint` 

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
