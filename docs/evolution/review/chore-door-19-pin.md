---
branch: chore/door-19-pin
pr: 870
date: '2026-09-24'
reviewed_diff_sha256: c81387b7a2cb401e5ac158252e50b855706ad7b1e0c2f4ed1dc6318b60a9b680
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 0
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Leva de CARIMBO, não de código: avança o pin da porta e o teto de uma catraca, e regenera três
  projeções geradas. A passada adversarial de PRODUTO desta frente já ocorreu no PR #869, com
  refutador independente em worktree isolada (8 achados, todos curados) — está registrada em
  `docs/evolution/review/chore-door-18-and-projections.md`. Repetir aqui um refutador sobre um diff
  que é pin + teto + projeção seria teatro. O que EXIGE verificação neste tipo de leva é outra coisa,
  e foi feita: a ORDEM (o pin só anda depois do push verificado no remoto) e a REGENERAÇÃO (rc e
  tamanho conferidos antes de tocar o alvo). Campos de custo em ZERO porque não houve run de modelo.
---

# Resíduo — pin da 19ª materialização

## Os dois pontos que esta classe de leva pode errar, e como verifiquei

**1. Pin que anda antes do push — ou depois de um push que não aconteceu.**
As duas direções mentem, e o baseline já registra as duas ocorrências: em 2026-09-18 o pin velho
escondeu porta nova; em 2026-09-19 quase aconteceu o inverso, avançar o pin sobre porta que ninguém
podia abrir. Verificação feita: `gh api repos/marciocar/onion-core/commits/main` devolveu
`f03726abc45d` **antes** de eu tocar o `members.yaml`. Fonte é o remoto, não o disco nem a nota
do script.

**2. Projeção gerada de árvore suja, ou gerador que falha e apaga o alvo.**
Nesta sessão os dois já aconteceram — inclusive o `graph.md` destruído (805 linhas) por um `cp`
sobre stderr silenciado. Verificação feita: cada projeção é gerada em arquivo temporário, com `rc`
e contagem de linhas conferidos, e **só então** copiada; `rc≠0` ou saída suspeita deixa o alvo
intocado. Resultado: 807 · 73 · 49 linhas, iguais ao anterior em tamanho e diferentes no conteúdo
(o pin).

## O dogfood que dá sentido à leva

O lint da porta, rodado **na árvore dela**: `rc=0`, 0 HARD, zero `MORREU`, sumário alcançado.
E o baseline da REGRA 89 chegou lá com 14 linhas **só de comentário** — que o `grep -v` reprova
igual ao arquivo vazio, confirmando que sem a cura a morte seria idêntica. Isto não é o lint do core
dizendo que está tudo bem: é o artefato publicado sendo invocado onde ele vive.

## O que fica aberto, com gatilho nomeado

**`D_ONDE_COBRAR_A_DEFASAGEM_DA_PORTA`** — esta leva custou DUAS materializações porque a REGRA 85
(Porta pública espelha o core, com catraca) cobra uma cura que só existe depois do merge. Decisão do
maestro, três opções nomeadas, recomendação registrada.
