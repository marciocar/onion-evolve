---
branch: feat/dissect-family-pattern
pr: pendente
date: 2026-11-27
reviewed_diff_sha256: pendente
findings_total: 8
findings_real: 8
findings_blocking: 1
tokens: 127029
duration_min: 5
findings_fixed: 8
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "subagente general-purpose isolado (não-fork), mandato REFUTAR, sem o raciocínio de quem escreveu"
nota: "O refutador reprovou por 1 bloqueante (a porta da longevidade não tinha piso: 0 usos e since 2099 passavam) e 7 menores. Os 8 foram curados e cada um ganhou caso na bancada (162 para 179 casos). A cura não passou por 2ª refutação; os casos novos são a prova. tokens = só o refutador. PR empilhado sobre feat/dissect-family-media."
---

# Passada adversarial: `feat/dissect-family-pattern`

## O que muda

- Família `padrao` no registro, com `n2_proof` (C_PATTERN_MECHANISM_GATED, selo Q_PATTERN_SEAL_REVISION) e
  `n2_ratchet` {known_uses_min 3, known_uses_min_derived 2, longevity, longevity_min_years 10}; a contestação do
  limiar é o nó `C_PATTERN_THRESHOLD_CONTESTED`, com aresta `CONSTRAINS` para a família.
- Item 13 do checador: a catraca disjuntiva sobre o estudo (N do registro). Item 12: a forma da catraca e a
  contestação vinda de nó vivo.
- Doutrina §6: linha da tabela, a regra da catraca e a ordem de predicados renumerada (`padrao` antes de `pratica`).

## Achados

1. BLOQUEANTE: a longevidade não tinha piso; `since: 2026-11-27` ou `2099` com 0 usos passava. Curado:
   `longevity_min_years` (10) no registro, data futura recusada, código `longevidade-curta`, dois casos.
2. Menor: "fontes distintas" comparava o texto cru (URL com `#x` ou barra; linhas do mesmo arquivo). Curado:
   fonte normalizada; dois casos.
3. Menor: usos em nós refutados contavam. Curado: `refuted`/`superseded` não contam; um caso.
4. Menor: o derivado era só `true`. Curado: `x_dissect_derived: {from: <fonte do pai>}`, código
   `derivado-mal-formado`; um caso.
5. Menor: a bancada não matava o mutante da porta `longevity` nem o `x >= 1`. Curado: casos com a porta desligada,
   N zero, porta em texto e sem o piso de anos.
6. Menor: a aresta CONSTRAINS valia vinda de nó inexistente. Curado: tem de vir de claim/question vivo; um caso.
7. Cosmético: a mensagem não distinguia a porta desligada. Curado.
8. Desenho: a doutrina não dizia que padrão sem recorrência fica no N1. Curado na §6 e no texto do N2.

## Mutantes

- Cada código dos itens 12 e 13 tem caso que o acusa e mutante calado que o deixa passar (179 casos + 6 de rc 3).
- Tirar a prova N2 do `padrao` reprova (`familia-sem-prova-n2`); com o código calado, rc 0.
- O N sai do registro: com `known_uses_min: 4`, os 3 usos do estudo reprovam.

## Limites declarados

- O piso de 10 anos é parâmetro do core, não da fonte (a fonte diz "sucesso de longo prazo"); está em `limits`.
- "Fontes distintas" é a forma normalizada, não a independência real dos usos, que é do Elenxo.
- A leitura primária direta de GoF e de Alexander não foi feita (limite da evidência).
- Empilhado: mergear o PR da `midia` antes; depois, rebase deste sobre a main.
