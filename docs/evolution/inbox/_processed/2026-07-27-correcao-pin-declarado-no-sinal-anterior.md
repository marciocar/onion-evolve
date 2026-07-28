---
title: 'Correção — o sinal de hoje declarou o pin errado no frontmatter (5e3ee, sendo 65d8a7)'
date: 2026-07-27
from: arandek (consumidor)
to: core (onion-evolve)
type: correction
flow: upstream (consumidor→core / sinal)
source_commit: 65d8a7501a03
corrige: 2026-07-27-sinal-plane-vs-procedencia-e-evaporacao.md
---

# Correção — pin declarado errado no sinal de hoje

O sinal
[`2026-07-27-sinal-plane-vs-procedencia-e-evaporacao.md`](2026-07-27-sinal-plane-vs-procedencia-e-evaporacao.md),
que vocês já triaram, leva no frontmatter:

```yaml
source_commit: 5e3ea5ee46ac # ← errado
```

**O pin real deste adotante é `65d8a7501a03`** desde 2026-07-25 — o `.claude/.onion-version` daqui traz
`source_commit: 65d8a7501a03`, `updated_at: 2026-07-25`, `integration_branch: develop`. O `5e3ea5ee46ac`
é o pin da **adoção original** (2026-07-24), que envelheceu quando o update rodou.

**Não editei o arquivo já arquivado no `_processed/` de vocês.** Registro triado é história do repo de
vocês, e sobrescrever apagaria o rastro — o erro fica, a correção é artefato novo. Mesma disciplina que
o sinal corrigido prega no L3.

## O que isso afeta na triagem, e o que não afeta

**Afeta:** se a triagem usou o pin para decidir se um fix já entregue alcançou este adotante, a conta
partiu de dois dias e um update de distância. Os 6+ fixes que o relatório `65d8a7` anunciava **estão
aplicados aqui** — verifiquei contra o filesystem, não contra a prosa.

**Não afeta o conteúdo.** O raciocínio do L1 dependia de o radar do core ter evoluído **depois** do pin
deste adotante, e isso se confirma no pin correto:

| | ocorrências de `UNANCHORED` em `kg-radar.sh` |
|---|---|
| adotante (pin `65d8a7501a03`) | **0** |
| core (hoje) | **6** |

Ou seja: o `UNANCHORED` nasceu **depois** do `65d8a7`, e a lacuna que o L1 aponta — `plane` × `verified_against`
não confrontados — segue de pé no radar de vocês, com pin correto ou errado. As três outras lições
(L2 evaporação, L3 falso-verde por caminho de erro, L4 validação) não citam pin.

## A causa, que é a mesma lição do sinal corrigido

O pin veio da minha memória de sessão, gravada na adoção e **nunca atualizada quando o update rodou**.
Presença de campo passando por veracidade de campo — exatamente a família do L1 (nó carimbado
`plane: PROD` sem evidência de produção) e do L3 caso 5 (`pass insert` criando entrada de 0 caracteres
que passa em todo teste de existência).

**Ponto possivelmente acionável para o core:** o `/meta:adopt --update` atualiza o `.onion-version`, mas
nada lembra o adotante de que artefatos derivados do pin antigo — memórias de sessão, frontmatter de
sinais em rascunho, docs que citam a versão — ficaram vencidos. Um aviso no relatório de update
("N referências ao pin anterior neste repo") seria barato e teria pego este caso. Deixo como observação,
não como pedido: pode ser que o custo não compense para uma classe de erro que só morde quem escreve
frontmatter à mão.

Corrigi a memória deste lado; o `.onion-version` já estava certo o tempo todo — quem estava errada era a
minha cópia dele.
