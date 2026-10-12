---
title: 'Spike que mede hipótese de produto: o critério de sobrevivência premia a proposta trivial'
date: 2026-10-12
from: onion-kg-ssot (produto KG-SSOT, papel adopted)
to: core
type: field-signal
pin: dcdacf9ba196
---

# Sinal: em spike, sobrevivência não mede valor

## O que aconteceu

O ÉPICO 10 do produto (PRs #84 a #88 de marciocar/onion-kg-ssot) testou a hipótese "a captura propõe, o contrato
sela": um adaptador lê o rastro de execução de um agente e propõe nós de grafo, e a selagem decide quais ficam. Foram
três medições conduzidas pelo `/meta:drive`, cada uma com critério commitado antes e com Elenxo depois:

| Spike | Critério | Resultado |
|---|---|---|
| 1. Journal de workflow | menos de 30% das propostas sobrevivem, ou alguma só fecha escolhendo fonte | morreu: 17 de 64 (26,6%), e 9 sobreviventes só com fonte escolhida |
| 2. Filho: transcript e PROV-JSON de terceiro | o mesmo, sobre rastros ainda não vistos | passou: 9 de 10 e 30 de 30, sem escolha de fonte |
| 3. Valor | avaliador cego marca MANTER ou DESCARTAR; morre abaixo de 20% | morreu: 0 de 8 |

O maestro fechou o épico pelo `/meta:decide`.

## O sinal de método

1. **O critério de sobrevivência premia a proposta trivial.** No spike 2, a proposta PROV repetia o arquivo e a
   selagem relia o mesmo arquivo: 100% mediu a fidelidade da cópia. A proposta mais vazia era a que mais sobrevivia.
   Só o critério de **valor**, julgado por um agente separado **sem acesso à hipótese**, separou cópia de
   conhecimento (spike 3, 0 de 8).
2. **O critério tem de ir num commit antes da amostra**, com o proponente e o placar. No spike 1, a primeira leitura
   trocou o denominador depois de medir (de todas as propostas para as julgadas: de 26,6% para 68%), e o Elenxo a
   derrubou como critério movido. A partir do spike 2, cada critério e cada proponente foram commitados antes, e a
   ordem ficou verificável no `git log`.
3. **O Elenxo pegou as duas falhas**, a régua movida e a tautologia, quando a leitura própria já tinha dado
   "sobrevive".

## Onde pode morar no core (proposta, a triagem é de vocês)

- Na doutrina do `/meta:drive` (KIND research e verification): spike de hipótese de produto declara, no nó `Q_` e num
  commit anterior à amostra, o critério de morte com denominador fixo e uma medida de valor com avaliador cego.
- No Elenxo: uma pergunta fixa, "o critério separa a proposta útil da trivial?".

## Onde conferir

- Grafo do produto: `docs/onion/graph/kg-ssot-product.kg.yaml`, nós `E_CAPTURE_SPIKE_JOURNAL_KILLED_1012`,
  `E_CAPTURE_CHILD_SPIKE_PASSES_LETTER_1012`, `C_CAPTURE_VALUE_UNANSWERED`, `E_CAPTURE_VALUE_SPIKE_KILLED_1012` e
  `D_EPIC_10_CLOSE_1012`.
- Medições: `docs/onion/measurements/capture-spike-2026-10-12.json`, `capture-child-spike-2026-10-12.json` e
  `capture-value-spike-2026-10-12.json`, com só contagens e ids.
