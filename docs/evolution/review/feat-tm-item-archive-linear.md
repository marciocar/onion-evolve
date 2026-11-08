---
branch: feat/tm-item-archive-linear
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 4
findings_blocking: 0
findings_fixed: 4
tokens: 0
duration_min: 25
verdict: FIXED
elenxo: false
elenxo_isolado: false
reviewer: passada própria sobre o próprio diff (sem subagente, proibido pelo brief); bancada offline com mutantes e guardas das REGRAS 103 e 104
nota: "tokens 0 = não medido."
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

`item.archive` e `item.list` no executável do Linear, com bancada offline e declaração nos cinco adapters.

## Achados e curas

1. **A prosa afirmava o que não foi medido.** A primeira redação do `linear.md` dizia que a issue arquivada segue
   legível por id, e a mesma seção listava isso como não medido. Saiu a afirmação.
2. **Conclusão maior que a amostra.** "Arquivar não atualiza o `updatedAt`" veio de 5 linhas, e o filtro do teste
   exclui por `updatedAt`. Virou "nessas 5".
3. **Âncora de mutante alheio quebrada.** Meu `after = info["endCursor"]` duplicou a âncora do mutante (m2) da família
   do dispatcher. O nome da variável mudou para `cursor`, sem tocar a bancada existente.
4. **Mutante sem dentes.** O falso honrava `includeArchived` pela variável, sem olhar a consulta, e o mutante que tira o
   argumento seguia verde. O falso agora exige o argumento na consulta.

## Não medido

O `item.archive` não rodou contra o Linear real, por ser escrita: segue `unverified`. Depende disso a idempotência
ao vivo, que supõe `issue(id:)` achar issue arquivada. O `item.list` teve uma leitura real, sem a 2ª página.
