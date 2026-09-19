---
title: 'Resíduo — a aritmética do registro, conferida contra o vivo'
date: 2026-09-19
branch: chore/registry-reconcile-after-849
reviewed_diff_sha256: 93024127f3c87f322230fdf6e54c39d832d25c8af142d6caab9317d71797909b
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 3
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  PR sem superfície executável — dois pins, dois números de catraca e as projeções que eles arrastam.
  A passada não é adversarial de agentes: é a conferência de cada número contra a FONTE VIVA (os
  carimbos publicados dos dois repos e a história do core). Declarado assim para o `elenxo: nao` não
  passar por descuido.
---

# O que havia para refutar, e como foi conferido

Este PR não muda comportamento: ajusta **registros**. O risco dele não é lógico, é de **afirmação
falsa** — um pin que diz uma coisa e o repo apontado que está em outra. Então a passada é uma só
pergunta, feita a cada número: *isso bate com o vivo?*

## As três verificações

**1. O pin da porta bate com o publicado?**

```
$ gh api repos/marciocar/onion-core/contents/.claude/.onion-version | base64 -d | grep onion_version
onion_version: adbd6e91b8e0
$ grep adbd6e91b8e0 docs/evolution/federation/members.yaml
    onion_version: adbd6e91b8e0   # pin da 8a materializacao
```
✅ Idênticos, e a leitura veio do **remoto**, não do disco.

**2. O pin do adotante bate com o carimbo dele?**

```
$ gh api repos/marciocar/vendas-pdi-enterprise/contents/.claude/.onion-version | base64 -d | grep onion_version
onion_version: 24118c5d7a97
$ grep "24118c5d7a97 # ATUALIZADO" docs/evolution/federation/members.yaml
    onion_version: 24118c5d7a97 # ATUALIZADO 2026-09-18
```
✅ Idênticos. Este era o registro **mais defasado dos dois**: o alvo rodava o framework novo desde
2026-09-18 e o `members.yaml` seguia no pin da adoção.

**3. Os dois pins existem na história do core?**

```
$ git cat-file -e adbd6e91b8e0 && echo OK   → OK
$ git cat-file -e 24118c5d7a97 && echo OK   → OK
```
✅ Não são pins forjados. (O precedente existe nesta casa: um pin forjado já foi detectado em 2026.)

**4. A catraca fecha sozinha?**

```
$ bash .claude/validation/door-staleness-check.sh
onion-standalone  ok  391/391
onion-core        ok  0/0
```
✅ O verificador determinístico confirma a aritmética que o PR declara.

## Por que `elenxo: nao`, declarado em vez de omitido

Não houve refutador de agentes, e a razão é de **objeto**: não há superfície de execução para atacar.
As três passadas adversariais desta onda renderam porque havia código mudando de comportamento —
aqui há dois números e duas datas. O que substituiu o refutador foi a **conferência contra a fonte
viva**, que é o teste que este PR de fato precisa passar.

> A distinção importa porque a alternativa preguiçosa seria carimbar `elenxo: sim` e chamar a
> conferência de passada. O campo é contrato de máquina; mentir nele para ficar bonito é a classe que
> esta onda inteira perseguiu.

## O que fica NÃO medido, declarado

Se a porta `onion-core` for republicada por outro caminho depois deste commit, o pin aqui envelhece
em silêncio — a catraca só mede defasagem em **commits do core**, não republicação do alvo. É o
mesmo teto que o `door-staleness-check` já declara; este PR não o move.
