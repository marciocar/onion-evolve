---
title: 'Resíduo — o selo do maestro na decisão indivíduo × organização'
date: 2026-09-13
branch: docs/seal-sharing-criterion
reviewed_diff_sha256: 3949c62e7f96cc5d0596626e45e8cab33a1369246118131195daedbd463246b9
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 3
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Registro de um ato do maestro, não trabalho meu a refutar. O diff só escreve no grafo a decisão que ele
  tomou e projeta o mesmo na síntese. Sem passada adversarial por isso: não há tese minha aqui para derrubar.
  O que EU decidi foi a FORMA do registro (quais status, quais arestas), e isso é verificado por máquina —
  radar e realign, ambos declarados no gate abaixo.
---

# O selo: opção C como direção, rodada complementar como condição

O maestro selou `D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION` com as palavras *"opção C com a rodada
complementar"*. Este PR só escreve isso.

## O que o selo diz

**C — fluxo por propósito, com assimetria de padrão** é a direção:
- finalidade declarada antes, por fluxo, sem reuso incompatível;
- base legal nunca é consentimento sob subordinação;
- **organização→indivíduo** aberto **só para o dado da própria pessoa e as decisões que a afetam**;
- **indivíduo→organização** só como **predicado provado**;
- nenhum agregado comportamental que dependa só de limiar de contagem — times de 3 a 5 ficam fora.

**D — a rodada complementar é CONDIÇÃO, não alternativa.** Nada de C vira desenho antes de LGPD, ANPD, TST,
Deci e Ryan e as fontes de grupos pequenos serem lidas.

## Como ficou registrado

| nó | antes | depois |
|---|---|---|
| `D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION` | `open` | `done`, com `verified_at` e o selo em `verified_against` |
| `C_OPCAO_C_PURPOSE_BOUND_ASYMMETRIC_FLOW` | `open` | `confirmed` |
| `C_OPCAO_D_GATED_COMPLEMENTARY_ROUND` | `open` | `confirmed` (é condição, não rival) |
| `C_OPCAO_A_…` e `C_OPCAO_B_…` | `open` | `superseded`, com `SUPERSEDES` vindo da decisão |

**Aufhebung, não apagamento.** Os labels de A e B ganharam o que sobrevive de cada uma, em vez de sumirem:

- **A** (a tese do maestro) sobrevive dentro de C, que é A restringida por mecanismo. O que foi superado é
  A *como critério sem mecanismo*, que é o que a aritmética do adotante derruba.
- **B** (colaborador só como autor) entra em C pelo que tem de certo: no Company Brain a pessoa é **autora e
  identidade de ACL**, não sujeito de telemetria. O que não foi adotado é o absoluto *"nunca dado"*.

Em `fronteira-decision.kg.yaml`, a claim da posição do maestro e a pergunta da pesquisa carregam o selo. A
pergunta **segue `open`** de propósito: ela só fecha quando a rodada complementar rodar.

## Gate

```
radar --integrity --schema : exit 0 nos dois grafos
realign --check            : ALINHADO — (c)=0 (b)=0 (a)=0
backlog                    : regenerado (193 abertos)
```
