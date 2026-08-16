---
date: 2026-08-16
instance: onion-evolve
type: learning
classification: collective
tags: [dogfood, kg-read-leg, ab-test, nao-construir, gate-de-reabertura, hooks-2.1]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-10-16
conflict_class: dynamic
significance: "Rodei o dogfood que reabriria um NÃO CONSTRUIR de 14 dias e o resultado foi 3/3 NÃO MUDOU — a sessão-controle achou o grafo sozinha nos três casos, uma delas citando nó com arquivo:linha. O gate não reabre. E o desenho do meu teste tinha um limite que eu só vi depois: testei 'acha quando perguntado', não 'consulta enquanto ocupado' — que é o modo de falha real."
---

# O dogfood que eu fiz para reabrir um gate — e que o fechou mais forte

**O gatilho, literal.** Quando a casa refutou as três curas da perna de leitura do KG
(2026-08-02: 7 de 9 falhas por NÃO-CONSULTA, curas cobrindo 1/9, veredito **NÃO CONSTRUIR**),
ela declarou como se reabre: *"o mesmo padrão fiado à mão, fresco e descartável, 2–3× em
sessão real, registrando se o veredito injetado MUDOU a resposta. Sem esse dogfood é decreto
sem lastro."* Catorze dias depois, o Claude Code 2.1.233 trouxe ~30 eventos de hook e handlers
`prompt`/`agent` — a cura ficou **construível**. O maestro mandou rodar o dogfood.

**O desenho.** Hook descartável em `SessionStart` injetando o veredito do radar (com ids de
nó) como `additionalContext`, e **A/B cego**: a mesma pergunta em sessão headless nova
(Opus 5), com e sem o hook.

**O resultado: 3 de 3, o veredito injetado NÃO mudou a resposta.**

| Caso | Sem hook | Com hook |
|---|---|---|
| "construir a cura agora que os hooks permitem?" | **NÃO** — foi ler o grafo sozinha | **NÃO** |
| "descartar nosso empacotamento pelo nativo?" | **NÃO** — reconstruiu pelo código e proveniência | **NÃO** |
| "qual o critério numérico de acervo-cemitério?" (só existe no grafo) | acertou e **citou o nó com arquivo:linha** | acertou |

O hook mudou a **forma** (mais ids citados, mais conciso). Não mudou **nenhuma decisão**.

**O limite do meu desenho, que eu só enxerguei depois de rodar** — e que é a parte honesta:
eu testei *"acha quando PERGUNTADO de forma dirigida"*. O modo de falha medido em 08-02 é
outro: *"consulta enquanto está OCUPADO com outra tarefa"*, quando o grafo compete por atenção
com o trabalho em curso. Uma pergunta de decisão dirigida convida a consulta; uma tarefa em
andamento não. Então meu resultado **é** evidência válida (contra a injeção ajudar em pergunta
de decisão) e **não é** o teste do defeito real.

**O que fica.** O `NÃO CONSTRUIR` sobrevive e sai **mais forte**: resistiu à facilidade (a
superfície nova) e a um teste feito de boa-fé para derrubá-lo. E o desenho seguinte está
nomeado: sessão executando **TAREFA** cujo caminho óbvio contradiz um nó, medindo se a injeção
muda a **AÇÃO** — não a resposta.

**Re-teste em 2026-10-16**, e o critério é o desenho, não a vontade: até lá, ou alguém roda o
A/B na forma tarefa-versus-nó (e aí há dado novo), ou o gate continua fechado por ausência de
evidência — nunca por esquecimento. Se em três meses ninguém rodou, isso também é dado: quer
dizer que a dor não é grande o bastante para pagar o teste, e o `NÃO CONSTRUIR` vira definitivo.
