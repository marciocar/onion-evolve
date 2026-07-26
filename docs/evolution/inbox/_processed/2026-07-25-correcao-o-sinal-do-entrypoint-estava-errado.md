---
title: 'CORREÇÃO — o sinal do entrypoint estava errado; a causa era auto-shutdown'
date: 2026-07-25
from: arandek (consumidor) / mesma sessão que emitiu o sinal corrigido
to: core (onion-evolve)
type: field-signal
flow: upstream (consumidor→core / correção de sinal já triado)
corrige: 2026-07-25-logto-core-e-licao-do-pin-herdado.md
source_commit: be285633
contexto: >-
  O sinal anterior afirmava que o 503 do staging do Arandek era causado pelo
  entrypoint do Logto encadear provisionamento antes do start. Era inferência
  apresentada como diagnóstico. A medição chegou depois e não a sustenta.
---

# O que eu afirmei, e o que a medição mostrou

O sinal anterior dizia, com `confidence: 0.95`:

> O 503 do staging do Arandek não é o Logto: o entrypoint encadeia
> `seed && node init.mjs && npm start` — provisionamento antes do start com `&&`,
> logo falha de config vira indisponibilidade de auth.

**Está refutado.** Três chamadas read-only contra a AWS mostraram os três services do staging
com autoscaling `min=0/max=0` e o Logto em `desired=0 / running=0`. O
`infra/staging-scheduler.ts` do Arandek documenta o comportamento na própria fonte:
*"fora da janela os endpoints respondem 503 até o próximo UP"*, janela seg–sex 07:00–21:00.

Não havia avaria. Havia auto-shutdown funcionando como projetado, num sábado.

## O erro que gerou o erro

O nó que sustentava tudo não era o do entrypoint — era o anterior, `E_SAME_IMAGE_BOOTS_CLEAN`:
*"a mesma imagem sobe limpa aqui, **o que isola a causa no desenho do entrypoint**"*.

A observação era verdadeira. A inferência, não: subir limpo aqui isola **qualquer** diferença
entre os dois ambientes, e *"quantas tarefas estão rodando"* era uma delas. Uma observação
correta foi promovida a causa, e a causa foi relayada como fato.

Pior: a **premissa** também era falsa, e uma refutação adversarial é que a pegou. Não é a
mesma imagem. O core roda `1.41.0` vanilla; o Arandek constrói uma imagem própria
(`FROM ghcr.io/logto-io/logto:1.36.0` + `COPY init.mjs`). Eu comparei duas coisas diferentes e
chamei o resultado de isolamento de variável.

## O que vale como sinal (não como desculpa)

**1. Um falso-verde por vacuidade, provavelmente presente em qualquer adotante em ECS.**
`aws ecs wait services-stable` não exige `desiredCount > 0`. O acceptor de sucesso é
`deployments == 1 && runningCount == desiredCount` — e `0 == 0` satisfaz. **Um serviço
desligado é trivialmente "estável".** O gate carimbou verde com o Logto em `0/0` e o deploy só
quebrou lá adiante. Confirmado lendo `botocore/data/ecs/2014-11-13/waiters-2.json`, não de
memória. É a espécie que já nomeamos — falso-verde por vacuidade — com um exemplar novo e caro.

**2. "Pular" que vira verde.** O smoke test do Arandek tinha um check que imprimia *"skip em
CI"* e fazia `return` — e o runner, que só distingue lançar de não-lançar, somava aquilo em
`passed`. Um ambiente sem o serviço produzia o mesmo `N passed` de um ambiente saudável. Onde
não existe um terceiro desfecho, "não verifiquei" se disfarça de "verifiquei e está bom".

**3. A lição de processo, que é a que interessa ao core.** Diagnosticar aquilo custava um
deploy inteiro (~15min), porque só o job de deploy tinha credencial AWS. Foi esse custo que
empurrou para o palpite. As três chamadas que resolveram levam **~1min** — o instrumento era
barato e eu não o construí antes de afirmar.

> Quando medir custa mais que supor, a suposição vira o padrão — e viaja como fato.
> **O instrumento vem antes da causa.**

Isso conversa direto com a doutrina de KG (`declarado ≠ verificado`): o `plane: PROD` existe
justamente para marcar "isto foi cruzado com o vivo". Meus nós tinham `plane: PROD` e
`verified_at` **porque um `curl` respondera** — mas o `curl` verificava o *core*, não a claim
sobre o *Arandek*. O carimbo estava no artefato errado. Vale considerar se o radar consegue
apertar isso: `verified_against` que aponte o alvo da claim, não o que estava à mão.

## O que a correção já produziu (verificável)

No repo do Arandek, PR [#181](https://github.com/ArandekBR/arandek/pull/181):
instrumento read-only de estado de energia, gate por asserção de capacidade,
`NÃO VERIFICADO` como desfecho de primeira classe e devolução do staging a zero
após deploy fora da janela.

No stack do core (`/home/marcio/onion-logto`, commits `a2654e0`, `0a96897`, `17f4ecd`):
grafo reconciliado (37 nós / 37 arestas, radar limpo) e README corrigido no lugar do erro,
não no lugar do erro apagado.

## O que continua em aberto — de propósito

Por que as 2 tarefas do Logto **drenaram** no deploy enquanto Api e Web ficaram de pé? Clamp do
autoscaling ou falha de health check. A segunda hipótese **reabre** o entrypoint. Não há
medição que distinga, então fica como `Q_POR_QUE_DRENOU` no grafo. Enterrar o entrypoint agora
seria repetir o mesmo erro com o sinal trocado.

Achado colateral para quem herda pins: o Arandek roda Logto **1.36.0** — o mesmo pin obsoleto
que auditamos e corrigimos aqui. A lição do pin herdado volta para a origem de onde ele foi
herdado.
