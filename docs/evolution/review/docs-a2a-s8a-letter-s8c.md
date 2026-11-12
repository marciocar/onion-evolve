---
branch: docs/a2a-s8a-letter-s8c
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_blocking: 2
tokens: 0
duration_min: 10
findings_fixed: 2
verdict: FIXED
elenxo: true
reviewer: "sessão principal, provocada pelo maestro («tem certeza que é o melhor?»)"
nota: "tokens 0 = não medido"
---

# Passada adversarial: `docs/a2a-s8a-letter-s8c`

## O que muda

Emenda 5 do pré-registro do teste de ida e volta entre a VPS e o notebook, e o selo `D_A2A_S8A_LETTER_S8C_1112`:
- o S8a, a entrega à sessão de destino fechada pelo canal nativo, fecha pela letra como não cumprido por limite do canal;
- a máquina offline com a sessão viva vira o critério novo S8c, registrado antes da rodada de hoje.

## Achados

1. **Bloqueante, curado.** A primeira redação criava o S8c depois que as rodadas de 09/11 já tinham mostrado a máquina offline entregando. Isso é viés de olhar o resultado (HARKing). Cura: as rodadas de 09/11 contam só como piloto, e só a rodada feita depois da emenda, com o juiz rodando, decide o S8c.

2. **Bloqueante, curado (pergunta da curadoria).** A emenda mandava o `judge-attempts.sh` julgar o S8c, mas ele lê o hook das sessões de teste do a2a-rt, que a sessão normal do destino não tem, e o DADO dele exige que uma ferramenta tenha rodado. Cura: o juiz novo `session/judge-native-delivery.sh` lê o transcript da sessão de destino. O critério ficou escrito na emenda e o passo a passo foi para o CARD-MAESTRO, os dois antes da rodada.

## Mutantes

`judge-native-delivery.sh --selftest` passa 6/6. Os mutantes morrem: sem o corte na próxima entrada de usuário, o caso `after` reprova; sem a recusa de entrega repetida, o caso `dup` reprova. O juiz rodou contra um transcript real desta máquina e deu AGIU certo (a sessão chamou ferramentas depois da mensagem).

## Limites declarados

- O S8c mede o canal nativo com a máquina fora da rede; não mede a perda da fila do remetente se ele também reiniciar.
