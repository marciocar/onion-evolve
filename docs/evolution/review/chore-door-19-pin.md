---
branch: chore/door-19-pin
pr: 870
date: '2026-09-24'
reviewed_diff_sha256: ed333eec9e500c9f279c9d0da06169611483e683f8ad45a8805abc7f2efbf1cf
findings_total: 3
findings_real: 3
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
\n
## Achado 3 — a armadilha de ordem já é CLASSE, não caso

**Quarta ocorrência nesta sessão**, sempre igual: `docs/onion/testing-state.md` e
`docs/onion/testing-inventory.md` são projeções que contam, entre outras coisas, **os resíduos de
revisão e seus vereditos** — então gerá-las antes de escrever o resíduo do próprio PR as deixa
defasadas, e o gate reprova. Ocorrências medidas hoje: (1) 313→314 resíduos no #869, (2) veredito
`CORRIGIDO`→`REPROVADO_E_CURADO` no mesmo PR, (3) 136→137 fixtures rastreadas (gerador rodado antes
do `git add`), (4) este PR, ao criar `chore-door-19-pin.md`.

Não é descuido de uma vez: é **ordem estrutural**. A projeção depende de artefatos que nascem no
fim da leva, então gerá-la no meio é sempre errado.

**Cura proposta, e deliberadamente NÃO implementada aqui:** um `ops/regen-generated-projections.sh`
que regenere as cinco projeções com `rc` e tamanho conferidos — hoje eu repito um laço à mão a cada
vez, e repetir laço à mão é o que produz a 5ª ocorrência. **Gatilho nomeado:** a 5ª ocorrência, ou o
maestro mandar. Não implemento agora porque este PR é um carimbo, e enfiar script novo + família de
bancada aqui é a catedral que a doutrina desta casa manda evitar — `pull-not-push` aplicado à minha
própria recomendação.
