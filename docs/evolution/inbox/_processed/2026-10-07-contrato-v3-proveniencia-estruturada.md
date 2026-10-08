---
title: "O contrato v3 do .kg.yaml estrutura a proveniência: 3.739 nós do core pedem provenance, com rampa até o v4"
date: 2026-10-07
type: signal
from: onion-kg-ssot (adopted, pin d82ca211bea0)
to: core (onion-evolve)
flow: upstream
severity: medium
decision_owner: core (maestro sela)
---

# A proveniência deixa de ser texto livre

O maestro selou aqui `Q_CONTRACT_STRUCTURED_PROVENANCE` (PR #21) pela régua do que é melhor para o
produto KG-SSOT — um grafo cuja origem a máquina consegue conferir —, e não pelo custo de migração do
core. O contrato v3 (`A_CONTRACT_V3`, PR #22) a aplica.

## O que muda

O nó ganha `provenance`, um objeto com três campos, todos obrigatórios quando o objeto existe:

| Campo | O que é |
|---|---|
| `source` | o que foi consultado: URL, caminho@commit, comando |
| `locator` | onde dentro dele: linha, seção, citação |
| `method` | como: medição, leitura, juízes |

`verified_at` segue no nó. **Rampa:** no v3, nó `confirmed` ou PROD sem `provenance` alerta (SHOULD); no
v4, reprova (MUST). `verified_against` em texto continua aceito no v3.

## 1. A migração medida (severidade média, não bloqueia no v3)

No commit do spike (`d31ef4c0da6a`): **3.739 dos 4.916 nós (76,1%)**, em 133 dos 138 grafos, são
`confirmed` ou PROD e hoje só têm `verified_against` em texto livre. O MUST segue em 113/138. É a
segunda migração do core, depois da de labels para `narrative` (sinal anterior), e as duas podem andar
juntas no mesmo passe por nó.

**O que pede ao core:** ensinar os geradores (o `write(KG)` do workflow de pesquisa, o `/meta:drive`
quando carimba `verified_at`) a escrever `provenance` estruturada; o `verified_against` atual já carrega
quase sempre a fonte e o comando, que viram `source` e `method`.

## 2. Para o radar e o drive

`provenance` é chave nova do nó; numa aresta é extensão desconhecida. Os casos estão em
`spec/conformance/fixtures/latest/form/provenance/` (ids sintéticos), para a matriz leitor × caso do E4.

## O que este sinal NÃO afirma

- Não mede o radar contra os casos (E4).
- A contagem é do commit do spike, não do core vivo, que já mudou parte do dado.
