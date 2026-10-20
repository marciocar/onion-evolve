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
review_after: 2027-01-18
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

## Estado em 2026-10-20 (re-teste)

**O A/B de 08-16 segue válido como evidência:** injetar o veredito no `SessionStart` não mudou decisão em pergunta
dirigida. **O "NÃO CONSTRUIR vira definitivo" está superado.** Uma cura de outra forma foi construída: o
`.claude/hooks/kg-read-leg.sh` (`5930e7c9`, 2026-09-16), ligado no `PreToolUse` de Read e Bash
(`settings.json` l.195). Quando a sessão lê um arquivo que algum nó aponta por `trace:`, ele injeta "🗺️ O CORPUS
JÁ FALA DESTE ARQUIVO" com os ids dos nós. É um ponteiro por arquivo no meio da tarefa, que é justamente o modo de
falha que o meu A/B não testava ("consulta enquanto ocupado"). Ele nasceu de sinal de campo de 2026-09-11, não do
A/B tarefa-versus-nó que eu tinha nomeado. Disparou ao vivo várias vezes neste próprio re-teste.

**Selo do maestro (2026-10-20, `/meta:decide`, escolhida «Supera»):** o `kg-read-leg.sh` supera
`D_build_none_of_three`. O selo é o nó `D_KG_READ_LEG_HOOK_SUPERA_NENHUMA_DAS_TRES`, com aresta SUPERSEDES, em
`docs/evolution/research/kg-read-leg-2026-08/kg-read-leg-2026-08.kg.yaml`, entregue pelo PR #1217. Na hora deste
re-teste o PR estava aberto, e em `origin/main` o `D_build_none_of_three` ainda aparecia `confirmed`.

## Re-testada em 2026-10-20 — PARCIAL: (dynamic, observei o artefato disparar) o hook `kg-read-leg.sh` está ligado e injeta o ponteiro no `PreToolUse`. O maestro selou que ele supera o `D_build_none_of_three` (PR #1217). O A/B de 08-16 fica como evidência do que a injeção no `SessionStart` não faz.
