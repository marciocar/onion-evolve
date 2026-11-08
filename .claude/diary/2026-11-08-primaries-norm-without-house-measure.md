---
date: 2026-11-08
instance: onion-evolve
type: learning
classification: public
tags: [research, primaries, elenxo, method, cost]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "Dar à leitura de primárias uma etapa que meça a casa, e só então julgar a claim"
review_after: 2027-02-06
conflict_class: dynamic
kg: "docs/evolution/research/outside-in-primaries-2026-11/outside-in-primaries-2026-11.kg.yaml"
---

## Signal
A leitura de primárias descreve a norma e não mede a casa. Quem pergunta "estamos alinhados?" precisa de um juiz que
abra o repositório; sem isso, o veredito por escolha sai errado. Veredito de grafo também envelhece no mesmo dia:
ATRÁS só vira compromisso depois de medido de novo no vivo.

## Evidence
- Rodada `wf_d23ecc85-e21`: 11 de 12 fontes lidas, 46 claims ancoradas, 32 objeções sobreviventes, 13 bloqueantes.
- As objeções bloqueantes nasceram de o juiz medir a casa (Agent Card, ruleset da main, pins, portas), não da norma.
- 18 claims rejeitadas na ancoragem: 15 exageradas, 2 sem citação, 1 não encontrada; o padrão dominante foi tratar
  SHOULD como MUST.
- Custo: 2.240.751 tokens, 27 agentes, 22 min; ≈22,2 mil por nó, mas ≈48,7 mil por claim ancorada, porque só 46 dos
  101 nós são evidência. Tokens por nó sozinho engana quando o modo produz objeção e superação.
- O vendor do kg-ssot lido pelo juiz era 4.44 e o core já estava em 4.46 no fechamento. Os 7 itens ATRÁS sobreviveram à
  nova medida, feita pela API e pelo vivo, e o do ruleset foi curado minutos depois dela: 6 ficaram abertos; 2 "alinhados" do vigia só valem no PR #8, ainda aberto.

## Next crumb
Medir, na próxima rodada `primaries`, quantas objeções bloqueantes somem se o leitor receber o caminho da peça da casa
junto da fonte. Comparar por claim ancorada, não por nó.
