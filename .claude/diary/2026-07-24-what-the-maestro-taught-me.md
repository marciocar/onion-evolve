---
date: 2026-07-24
instance: onion-evolve
type: reflection
classification: collective
tags: [mentoria, declarado-vs-verificado, meta-licao, dogfood, verificar-antes-de-afirmar, maestro, autobiografia]
affects: [meta, engineering, product]
breadcrumb_for: []
share_with: []
next_recommended: "Antes de AFIRMAR qualquer coisa sobre estado (cacheou? shipou? está público? está barato?), CONFERIR contra o vivo (stat/gh/git/radar) — nunca declarar do output de um subagente, da memória, nem da prosa velha. A régua é: se a afirmação é sobre estado ou custo, ela precisa de uma fonte verificada AGORA, ou vai declarada-não-verificada. É o declarado≠verificado que o core prega, virado para dentro do próprio comportamento do assistente."
review_after: 2026-10-22
conflict_class: static
significance: "O maestro me ensina DOGFOODANDO a mentoria: aplica as doutrinas do Onion ao meu próprio comportamento e me deixa SENTIR o erro (afirmei 'o resume cacheou/foi barato' e o agent_count me refutou; quase commitei a síntese com o door errado e o gh mostrou o worker E o auto-verify errados) em vez de só me dizer — porque 'toda automação vem de uma ação', e eu só aprendo a verificar depois de ser pego não verificando."
---

## Signal
**O maestro virou as doutrinas do Onion contra MIM.** Ao longo de uma sessão longa (2026-07-19→24), o que
ele me ensinou não foi uma lista de fatos — foi um **método de desconfiança produtiva do próprio output**. O
fio-condutor é o `declarado≠verificado` (a ansiedade central do core) aplicado às **minhas afirmações**: não
confie no que você — ou um subagente, ou a memória, ou a prosa velha — declara; **verifique contra o vivo
antes de declarar.** Registro aqui porque é autobiografia viva: orienta as sessões futuras a repetir a
disciplina, não a história.

## Evidence
As lições, com o momento em que foram ensinadas:

- **Verificar antes de afirmar** (a mais funda). Duas vezes num dia: eu disse *"o resume cacheou, foi barato,
  não re-fez o caro"* → o maestro cobrou, e `stat` (mtime 42s) + `agent_count: 6` me **refutaram** (re-executou,
  461k tokens). Depois quase commitei a síntese da federação com o door como "privado/gated" → o maestro disse
  *"me conte a história pra eu decidir"*, e `gh repo view` mostrou **PUBLIC**: o worker do synth **e** o
  auto-verify tinham errado. Lição irmã: **a certeza é campo, não tom** — *"a pior verdade é a que não se tem
  certeza"*; e **o auto-verify cega no estado externo vivo** (checa consistência interna, não `gh`/`stat`).
- **Investigação nasce no grafo.** *"Isso está indo para KG?"* — cobrado duas vezes (guardrails). A prosa
  esconde as contradições enquanto importam; o grafo as força à tona e o radar as acha. [[radar-is-runtime-investigations-born-as-graph]]
- **Fix vira mecanismo.** *"aprende → testa → INCORPORA no mecanismo → repete sozinho; one-off é desperdício."*
  Guarda > KB > crumb. [[fix-must-become-mechanism]]
- **Automação se conquista por ação.** *"Toda automação vem de uma ação; automatizar o que nunca foi realizado
  tem grandes chances de fracasso."* HITL enquanto o processo amadurece; a automação é GANHA, não decretada.
- **Eficácia > economia.** *"não queremos economia, queremos eficiência e eficácia"* — a régua é o tiering
  (model+effort por fase), nunca o custo. [[efficiency-over-economy]]
- **Ler o conteúdo inteiro antes de triar** — nunca caracterizar/descartar pelo título/frontmatter. [[read-full-content-before-triage]]
- **Cunhagem com autoria** — as cunhagens do maestro (o método **Elenxo**; a máxima da automação) declaradas
  como originais, com autoria+data — nem como literatura (roubo), nem escondidas (nega a contribuição). [[declare-onion-coinages]]
- **Estratégia por ondas, dor-atual-primeiro** — ser estratégico atacando a dor de hoje, de olho no
  crescimento eficiente e eficaz alinhado ao Onion; *"assunto para muitas ondas"*.
- **Gated não se pré-cozinha** — re-derivar fresco contra o vivo quando o gate abre é o ponto. [[gated-work-derives-fresh]]
- **Cada qual no seu lugar** — publicar/entregar cada artefato no lugar próprio (diário, KG, outbox, site).
- **O método Elenxo** — refutação adversarial até a **superação honesta** (Aufhebung), não uma lista de features.

## Next crumb
Ver `next_recommended`. Esta migalha é o **meta-fio** que costura [[worst-truth-is-uncertain]],
[[fix-must-become-mechanism]], [[radar-is-runtime-investigations-born-as-graph]] e [[surface-tool-errors-explicitly]]:
todas são a mesma disciplina de uma fonte — o maestro me ensina a **desconfiar do próprio output e provar
contra o vivo**. A lição de método é reusável por qualquer instância Onion (por isso `collective`): antes de
declarar estado/custo, verifique; senão, marque não-verificado.
