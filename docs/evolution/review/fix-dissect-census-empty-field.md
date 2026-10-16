---
branch: fix/dissect-census-empty-field
pr: 1166
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 1
tokens: 107946
duration_min: 4
findings_fixed: 1
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose opus (mandato refutar)
nota: "findings_total conta o achado real e a ressalva menor sobre o tipo da aresta do grafo (CONSTRAINS), mantida e declarada"
---

# Passada adversarial: `fix/dissect-census-empty-field`

## O que muda

`dissect-census.sh` lia os campos do nó do veredito negativo (id, critério, superação, medida) com
`IFS` de tab, e tab é IFS-whitespace: tabs seguidos colapsam e o campo vazio some. Sinal da sessão de
curadoria (DADO, reproduzido no `origin/main` 64e84e59): critério vazio saía com
`sem-x_dissect_criterion,superacao-id-invalido`. Medido também: veredito no `meta:` (id vazio) com
`nenhuma` medida saía RECUSADO, e overcoming vazio saía `superacao-id-invalido`. Cura: separador
`\037` entre o awk e o `read`. Caso `(og-e1)` na família `dissect`.

Classe medida: os demais reads de tab (o do `--check-verdict` no mesmo script, `dissect-plans.sh`
l.142 e l.171, `evolve-census.sh`, `kg-census-parity-check.sh`) não têm campo vazio possível — toda
coluna nasce com padrão, ou o vazio só cabe no último campo. O do `--check-verdict` ganhou o
comentário da invariante. `forge-census.sh` e `decide-census.sh` não têm read com tab.

## Achados

1. **REAL, curado.** Com o id vazio de verdade (veredito no `meta:`), `d=""` fazia uma aresta sem
   `to:` casar `to == d`, e a busca de circularidade semeava do vazio: um `rejeitar` com superação por
   id e aresta malformada CONTAVA (no main era recusado, pelo motivo errado). Cura: motivo
   `superacao-sem-id-do-veredito` quando o veredito não tem id e a superação é por id; `nenhuma`
   medida segue valendo no `meta:`. Fixture `metasup` no `(og-e1)` e mutante `(og-e1m2)`.
2. **Ressalva menor, mantida.** O refutador acha `CONSTRAINS` (evidência → decisão) defensável mas
   discutível: é defeito da implementação, não restrição à decisão. Mantido: a evidência limita o que
   a decisão garantia sem a derrubar, que é o que `CONSTRAINS` diz na gramática.

## Mutantes

Todos por `ops/mutate-and-restore.sh` no SUT real, `LC_ALL=C`, família `dissect` (61/0 com a cura):
- M1 (só o read volta a tab): 55/5, `(og-e1)` reprova.
- M2 (só o produtor volta a tab): 55/5, `(og-e1)` reprova.
- M3 fiel ao bug (produtor E read em tab, dois mutate-and-restore aninhados): 59/1, só `(og-e1)`.
- M4 (sem a recusa do veredito sem id): 59/2, `(og-e1)` reprova.
Restauração conferida: zero `ONION_MUTANTE` no SUT depois de cada um. Na bancada, `(og-e1m)` e
`(og-e1m2)` plantam os mesmos mutantes por sed e conferem a âncora.

## Limites declarados

- Valor de YAML contendo o byte `\037` deslocaria campos; não ocorre em grafo real, não tratado.
- Sem medir o corpus vivo de adotantes: a medição foi em fixtures e no corpus do core (CI).

## Re-revisão (rebase sobre origin/main 66d27350)

O PR #1166 ficou em conflito com a main (entraram #1165 e #1167, que tocam `lint-selftest.sh`, moat e o
grafo chat-agent-isolation). Rebase feito: os dois commits do fix aplicaram sem conflito (o bloco
`(og-e1)` mora ao lado do `(og-d1m)`, longe das âncoras novas); o único conflito foi o commit de
projeções geradas, descartado e regenerado pelo pr-finalize. `reviewed_diff_sha256` volta a pendente e
o pr-finalize recarimba. A família `dissect` foi re-rodada depois do rebase: 61/0.
