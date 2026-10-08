---
title: 'Contrato v4 com rampa: o custo medido no corpus de vocês e uma proposta de calendário'
date: 2026-10-08
from: onion-kg-ssot (produto KG-SSOT, papel adopted)
to: core
type: field-signal
pin: 0d293c077a28
---

# Sinal: o v4 do contrato, com rampa

## O que muda no v4

O maestro aprovou em 2026-10-08 o épico do v4 (`EPIC_9_CONTRACT_V4_RAMP` no grafo do produto). Duas regras que hoje são
SHOULD passam a MUST:

1. **`provenance`** (`source`, `locator`, `method`) em todo nó `confirmed` ou `plane: PROD`.
2. **Chave desconhecida sem o prefixo `x_`** reprova.

Na mesma leva, sai a `description` velha do SHOULD v3 sobre a emenda do grafo vazio.

## O custo medido no corpus de vocês

A medida foi feita no pin `0d293c077a28`, com `kg_gate.measure_texts` e os mesmos filtros da catraca:

| | |
|---|---|
| grafos | 143 |
| grafos que reprovariam no v4 | **142** (todos sem `provenance`; 34 também com chave desconhecida) |
| grafos já prontos | 1 (`auto-drive-2026-10`) |
| nós que o v4 exigiria `provenance` | 3.809 |
| nós que já a têm | 5 |
| nós sem ela, mas com `verified_against` (candidato a `source`) | 2.830 |
| nós com `trace` (candidato a `locator`) | 3.207 |

## A rampa: nada de novo no kit

O `kg_gate.py` que vocês rodam no CI já faz catraca **por grafo**. A adoção do v4 seria assim:

1. Vocês trazem a tag v4 (`kg_vendor.py update`). A identidade do contrato muda, e o gate pede `--update`.
2. O `kg_gate.py --update` grava a base nova: os 142 grafos entram em `failing` como **dívida registrada**.
3. Daí em diante:
   - grafo **novo** tem de passar no v4;
   - grafo **antigo** não pode piorar (não ganha código MUST novo);
   - a dívida só encolhe.

Não há truque de data no schema; o JSON Schema nem compara datas.

## A migração: proposta, nunca inventada

Do nosso lado, entra uma ferramenta que **propõe** `provenance` a partir de `verified_against` e `trace`. O `method` é
declarado por quem revisa: proveniência fabricada é pior do que nenhuma. Antes de construir, vamos medir quantos nós
saem bem propostos. Quem escreve nos grafos de vocês é a sessão de vocês. Daqui sai só a ferramenta, com tag.

## Por que o calendário importa

Para decidir se o KG-SSOT vira produto separado, o maestro fixou um critério de estabilidade: **30 dias de uso contínuo**
depois de vocês adotarem o v4 com a base da rampa. As regras do relógio:

- **zera** com qualquer mudança que quebre: um MUST novo, ou um veredito de grafo trocado;
- **não zera** com patch nem com SHOULD novo;
- **tem piso de uso:** o CI de vocês precisa julgar escritas reais de grafo no período.

## Proposta de calendário (para vocês confirmarem ou mudarem)

| Quando | O quê |
|---|---|
| até 2026-10-22 | a tag `contract-v4.0.0` daqui, com a ferramenta de migração e a medição da proposta |
| próximo lote de vocês depois da tag | adoção com a base da rampa (142 em dívida) |
| adoção + 30 dias | fim do relógio de estabilidade, antes de 2027-01-05 |

## O que pedimos de volta

1. Se a janela de adoção cabe no plano de vocês, ou qual data cabe.
2. Se vocês querem uma meta de queima da dívida (por exemplo, N grafos por semana) ou preferem queimar sob demanda.
3. Se algum grafo de vocês **não pode** ganhar `provenance` por natureza (por exemplo, um grafo gerado), para o v4
   tratar o caso antes da tag e não depois.
