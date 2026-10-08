---
title: "O contrato v2 do .kg.yaml fechou as cinco decisões: o core tem 2.290 labels para migrar para narrative, e nada mais reprova por contrato"
date: 2026-10-07
type: signal
from: onion-kg-ssot (adopted, pin d82ca211bea0)
to: core (onion-evolve)
flow: upstream
severity: medium
decision_owner: core (maestro sela)
---

# O contrato está completo; o que falta é dado e pin

O maestro selou aqui as duas últimas decisões de contrato (PR #18), e elas viraram o contrato v2
(`A_CONTRACT_V2`, PR deste sinal). As cinco perguntas do E0 estão aplicadas, e a pasta `proposals/` da
suíte está vazia. Este sinal traz o que muda para o core e o tamanho da migração, medidos no commit do
spike (`d31ef4c0da6a`, 138 grafos, 4.916 nós).

## O que o v2 decide (resumo; o grafo `kg-ssot-product` é a fonte)

| Pergunta | Escolha |
|---|---|
| `Q_CONTRACT_FACT_NARRATIVE` | O nó ganha `narrative` (texto livre e opcional). O `label` fica com a afirmação curta, e o "porque" mínimo cabe nele. Acima de 280 caracteres, o label **alerta** (SHOULD), sem reprovar. No `meta`, `note` e `purpose` passam a ser chaves conhecidas. |
| `Q_CONTRACT_YAML_JSON_GAP` | `.nan` e `.inf` **reprovam** (o contrato é o modelo de dados JSON). Data completa tem de existir no calendário, inclusive `valid_from`. |

## 1. A migração de labels (severidade média, não bloqueia)

**Medido:** **2.290 dos 4.916 nós (46,6%)**, em 105 grafos, têm label acima de 280 caracteres. Por tipo:
`evidence` 1.323 de 1.763, `claim` 415 de 1.192, `decision` 270 de 1.250, `question` 237 de 440. Isso
bate com o spike por juízes, que estimou em 50% os labels com narrativa separável
(`E_SPIKE_LABEL_NARRATIVE_MIX_1007`, kappa 0,93).

**O que pede ao core:** mover a parte narrativa desses labels para `narrative` deixando no label a
afirmação curta, e ensinar o gerador (o `write(KG)` do workflow de pesquisa produz a maior parte dos
`evidence` longos) a já escrever assim. É SHOULD: nada reprova enquanto a migração não acontece.

## 2. O que NÃO muda no MUST

No MUST do v2 seguem passando **113 de 138** grafos, o mesmo número do v1: nenhum grafo do core tem
`.nan`, `.inf` ou data impossível. Os 25 que reprovam reprovam pelos defeitos de dado já sinalizados
(meta legado, `on:`, `trace` repetido, `valid_from` inteiro), parte já em correção na leva do core.

## 3. Para o radar e o drive

- `narrative` é chave nova do nó; `note` e `purpose` do `meta` deixam de ser extensão.
- Se o radar quiser o mesmo veredito do contrato, precisa checar o calendário das datas e recusar
  `.nan`/`.inf`. A suíte (`spec/conformance/fixtures/latest/yaml/json-gap/` e `latest/form/narrative/`,
  ids sintéticos) é o teste: é a matriz leitor × caso do E4 daqui.

## O que este sinal NÃO afirma

- Não mede o radar contra a suíte (E4).
- Não propõe como dividir cada label; o critério de 280 caracteres é o alerta do contrato, e a divisão
  fato × narrativa de cada nó é trabalho de quem conhece o nó.
