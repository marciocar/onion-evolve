---
branch: fix/adopter-shape-na-derived
pr: pendente
date: 2026-11-10
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_blocking: 1
tokens: 0
duration_min: 40
findings_fixed: 2
verdict: FIXED
elenxo: false
reviewer: agente de execução da sessão do core (passada própria, não independente; o brief proibiu subagente)
nota: "tokens 0 = não medido. Acompanhamento do #1576 (REGRA 121), mergeado com a cura que fixava o número."
---

# Passada adversarial: `fix/adopter-shape-na-derived`

## O que muda

O caso `adopter-shape: (g)` da bancada deixa de fixar quais REGRAS saem «NÃO SE APLICA» no adotante. Até o #1576
ele exigia as REGRAS 62, 85, 92 e 109 e o total 4. A REGRA 121 (`aplica-se: source`) o reprovou no CI (job
129849771543), e a cura que entrou no merge só trocou o 4 por 5. O próximo `aplica-se: source` quebraria o caso de
novo, pelo mesmo motivo.

Agora o esperado vem das declarações `# aplica-se:` do próprio lint que rodou no clone, e o caso cobra o
comportamento:

1. a regra declarada fora do papel `adopted`, cuja função começa por `_na_for_role`, sai «NÃO SE APLICA»;
2. nenhuma regra declarada fora do papel sai VIOLATION;
3. toda linha «NÃO SE APLICA» é de regra declarada;
4. o total do sumário é o número dessas linhas.

A regra declarada que não chama `_na_for_role` (hoje a 117 e a 119) só imprime a linha quando tenta acusar, e por
isso é cobrada por (2), não por (1).

## Dogfood

- A derivação, rodada no lint, dá as declaradas 62, 85, 92, 109, 117, 119 e 121, e as que chamam `_na_for_role`
  62, 85, 92, 109 e 121. É o que o adotante imprime.
- **Morde:** o bloco do caso rodou contra três saídas sintéticas. A saída do CI antigo, sem a 121, reprova em (1).
  Uma saída com VIOLATION da 121 reprova em (2). A saída certa passa.
- A família `adopter_shape` passa 36 de 36 duas vezes na branch, e 36 de 36 na `origin/main` (3994f6f02).

## Achados

1. **BLOQUEANTE, curado.** O caso fixava o número e a lista, e a cura do merge repetiu o defeito com outro número.
   Cura: o conjunto passa a ser derivado do lint, e o caso cobra os quatro comportamentos acima.
2. **Real, sem mudança (intermitente).** No pré-voo do `pr-finalize`, o `adopter-shape: (i6-MUT recusa-x_pin)`
   saiu com `setup`: a preparação do caso falhou, não o mutante. O mesmo caso passa na `origin/main` e duas vezes
   na branch, e esta mudança não toca o (i6). Fica registrado como intermitente da preparação do (i6), sem cura
   neste PR.
