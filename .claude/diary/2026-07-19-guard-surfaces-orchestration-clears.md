---
date: 2026-07-19
instance: onion-evolve
type: observation
classification: collective
tags: [self-reinforcing-loop, provenance, orchestration, dogfood, kg-radar, guard, write-kg]
affects: [meta, orchestration]
breadcrumb_for: []
share_with: []
next_recommended: "Reconhecer o play como repetível: ao adicionar uma GUARDA advisory nova ao motor soberano (kg-radar), a dívida que ela revela é trabalho de fan-out imediato — construir a guarda e limpar o que ela acha fecham no MESMO loop (fix→re-dogfood), não em sessões separadas. Próxima guarda advisory que nascer, já orquestrar o sweep da dívida na sequência."
review_after: 2026-10-15
conflict_class: static
---

## Signal
**O loop auto-reforçante rodou de ponta a ponta numa sessão:** ITEM2 **construiu** a guarda de
proveniência no `kg-radar` → a guarda **achou** 13 decisões sem chão em 3 grafos reais → **orquestrei**
(fan-out-and-synthesize, 3 workers) para ancorá-las → a **mesma** guarda **verificou** verde
(`--provenance` ✅ em todo o corpus, integridade exit 0). Construir a guarda e limpar o que ela revela
fecharam no MESMO loop — é o `write(KG)` do próprio motor de percepção sobre si.

## O que isto confirma (não é ideia nova — é a prova em ação)
- Irmão vivo de [[self-reinforcing-radar-loop]]: o radar que a sessão cria descobre+navega o próprio fio.
  Aqui o mesmo, aplicado à dimensão *proveniência* e cruzando o **dogfood da orquestração**.
- **Honesto-acima-de-verde segurou o gate:** os workers foram instruídos a DEIXAR o aviso em decisão
  sem origem real (dívida = falta criar artefato, não anchor a inventar). Aconteceu de as 13 terem
  fonte verificável — mas a regra estava armada; a guarda não foi domada pra ficar verde.
- **Fan-in que adjudica, não rubber-stampa:** a orquestração PROPÔS com evidência (§/verbatim/decision-id);
  o contexto principal confirmou os alvos em disco + spot-check verbatim antes de aplicar. Divergência
  declarado≠verificado tratada na fronteira, não presumida.

## Evidence
- Guarda: `feat(kg-radar)` PR #435 (mergeado `1870ef8`); doutrina não-HARD, mesmo gênero do FRESCOR.
- Sweep: `docs(kg): anchor 13 orphan decisions` (`6c01740`) — 13 `trace:` para research-doc/migalha/ADR.
- Orquestração: fan-out-and-synthesize, 3 workers sonnet/medium, 145.889 tokens, 57s, 0 erros
  (run `wf_fa1aa6b0-3ea`). Padrão via [[write-kg-closing-step-bookend]] — o write(KG) fechou nos grafos.

## Next crumb
Ver `next_recommended`. A lição operacional: **guarda advisory nova → sweep da dívida no mesmo loop**.
A guarda não é o fim; é a forcing function que gera o próximo trabalho — e esse trabalho é fan-out.
Origem: o maestro pediu "atacar todos e dogfoodar orquestração" (2026-07-19) — o #2 virou a prova viva.
