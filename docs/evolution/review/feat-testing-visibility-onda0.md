---
title: 'Resíduo adversarial — Onda 0 de testes, R0 e a triagem dos dez sinais'
date: 2026-09-11
branch: feat/testing-visibility-onda0
reviewed_diff_sha256: 606a77ec2cc0952003551c32f85c53e885eebf60ae5789eabb0353d0bc8e0846
findings_total: 14
findings_real: 14
findings_fixed: 14
tokens: 1870191
duration_min: 16
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Seis dimensões com mandato de REFUTAR; cada achado passou por um verificador com viés
  INVERTIDO (default: derrubar). 14 sobreviveram — precisão de 100%, que é anômala e vale
  desconfiança: ou os revisores foram disciplinados, ou o verificador não refutou o bastante.
---

# A passada adversarial REPROVOU a entrega, e isso é o resultado

14 achados, 14 confirmados como reais, zero descartados no verify. 11 ALTA, 3 MEDIA.

## O que dói, e por que este resíduo não é rotina

Eu entreguei uma onda inteira sobre *declarado ≠ verificado* e cometi a MESMA CLASSE
**quatro vezes dentro dela**:

1. O gerador da SSOT afirmava, por **string estática**, que `selftest-runs.jsonl` não
   existia — um commit depois de ele passar a existir. A REGRA 80 (Números do harness saem
   de SSOT gerada, nunca de comentário) ficava VERDE porque compara o `.md` com o gerador,
   e era o **gerador** que mentia.
2. e 3. Os dois casos `(MUT)` das REGRAS 80 e 81 **não executavam o mutante** — asseriam
   que o `sed` casou a âncora, e o próprio rótulo admitia *"a mutação foi APLICÁVEL"*.
   Apresentei isso ao maestro como prova de mutação. Não era.
4. O nó `E_SERIE_DA_BANCADA_EXISTE` citava `1148/158/905` contra o envelope commitado
   `1164/160/750`.

E o mais grave, que nenhum lint pegaria: a **REGRA 81 (Painel de estado é GERADO dos
produtores, nunca redigido) nunca era exercitada pela bancada**. O verificador provou
desligando a guarda inteira e rodando a família: 6 PASS / 0 FAIL. Duas causas somadas, as
duas minhas — o `--only` que adicionei para curar performance tornou a regra inalcançável
pelo único caminho que as fixtures usam, e as duas famílias de lint completo carimbam
`role: adopted`, disparando o outro early-return.

## Curar expôs três defeitos que ninguém sabia que existiam

- **O sandbox da família `selftest_series` nunca teve git.** Toda asserção de idempotência
  rodava com `sha=nao-declarado` — a chave degenerada. Testava-se o caminho errado desde
  que a família nasceu.
- **Uma asserção casava o símbolo `✅`, não a posição onde ele significa veredito.** Reprovou
  certo pelo motivo errado: o caractere estava na prosa de aviso. Asserção assim **proíbe o
  texto de explicar a si mesmo**.
- **O `inventory.sh` devolve saída VAZIA com rc=0** quando faltam as árvores que ele varre.

## Colheita (REGRA 63 — Colheita de grafo emite os ids colhidos no resíduo de revisão)

Nove nós removidos, todos meus, todos por estarem no grafo errado — eu os escrevi em
`fios-abertos` e `audit-textual-gates` e **depois** criei o grafo dedicado
`inbox-sinais-2026-09`, produzindo dois conjuntos sobrepostos para os mesmos sinais
(`Q_AGENTE_EXPO_REACT_NATIVE` chegou a existir nos dois arquivos).

De `docs/onion/graph/fios-abertos.kg.yaml`:
`E_AUSENCIA_LIDA_COMO_RESULTADO_TEM_DOIS_SITIOS` · `I_CARTEIRO_VALIDA_POR_EVIDENCIA_DE_ADOCAO` ·
`I_ANUNCIO_DERIVA_O_NUMERO_DA_MEDICAO` · `E_SINAL_CURADO_SEM_NINGUEM_AVISAR_O_REMETENTE` ·
`Q_DESIGN_SINK_TEMA_DUPLO` · `Q_AGENTE_EXPO_REACT_NATIVE` · `E_TRIAGEM_DO_INBOX_2026_09_10`

De `docs/evolution/research/audit-textual-gates-2026-09/audit-textual-gates-2026-09.kg.yaml`:
`E_LABEL_ESCONDE_NO_FANTASMA_DO_CENSO` · `D_PARIDADE_DE_CENSO_VIRA_REGRA`

Os dois últimos **foram reescritos** em `inbox-sinais-2026-09.kg.yaml`, com o conteúdo
preservado. Os sete primeiros têm equivalentes de conteúdo naquele mesmo grafo, sob ids que
descrevem melhor o que foi medido (ex.: `..._EM_TRES_SITIOS`, porque o terceiro sítio
apareceu depois).

## O que o PR entrega

Onda 0 completa (painel gerado e catracado, SSOT do harness, série histórica, evidência de
terminal no CI, ledger dos 262 resíduos), o R0 com 16 nós re-medidos, a triagem dos dez
sinais de adotantes com cada afirmação verificável medida contra o vivo, e a cura de raiz da
classe *ausência lida como resultado* nos três sítios onde ela mora.
