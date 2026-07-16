---
title: "Rascunhos de post por canal — probe do adotante frio (Instrumento A)"
category: materials
tags: [cold-adopter, experimento-A, channel-posts, hacker-news, reddit, linkedin, outreach]
status: rascunho-pronto-para-o-maestro-postar
audience: INTERNO — drafts do maestro (o CORE não posta; postar é ação humana)
date: 2026-07-16
experimento: docs/analysis/onion-experiment-cold-adopter-2026-07.md (Instrumento A)
one_pager: docs/materials/cold-adopter-2026-07/one-pager-kg-reconciliation.md
landing: https://onionevolve.com/convite/
---

# Rascunhos de post por canal — probe do adotante frio

> **Postar é ação sua (maestro), não do core.** Estes são rascunhos prontos para copiar/colar e adaptar.
> **A guarda que decide tudo:** *arms-length* = estranho que não te deve nada e não foi empurrado. A rede
> pessoal é **órbita** → não conta como pull frio (`C_ORBIT_CAVEAT`). O sinal que conta: um estranho
> **(a)** tenta sem ser pedido **E (b)** volta com um `.kg.yaml` do domínio dele ou pergunta de adoção
> concreta. Upvote/"que legal!" **não conta** (anti-vaidade).

## Ressalvas estratégicas (ler antes de postar)

1. **Idioma ↔ canal.** HN e Reddit internacional são **inglês**; o `/convite/` está **pt-BR**. Um leitor de
   HN clica e cai numa página que não lê. Opções: (a) versão inglês do `/convite/` (`/invite/`); ou (b) mirar
   canais lusófonos (r/brdev, Discords BR) — mas esses têm **mais risco de órbita**. O pool frio de verdade
   está no inglês.
2. **onion-mini.** O CTA leva a `github.com/marciocar/onion-mini` (público). Conferir se o **README dele está
   em inglês** antes de mandar leitor internacional.
3. **LinkedIn = órbita.** Use para awareness; só conta como pull se vier de um **estranho** de verdade.
4. **Regras de cada sub/comunidade.** Vários barram self-promo — pode ser preciso postar como discussão
   (sem link no corpo) ou usar flair "I built".

---

## 1) Hacker News — *Show HN* (inglês)

**Título** (sem hype, ≤80 chars):

```
Show HN: Reconcile org knowledge as a typed graph (REFUTES/SUPERSEDES, not git merge)
```

**Primeiro comentário** (o HN espera você explicar):

```
I kept hitting the same problem: teams accumulate knowledge as prose — docs, ADRs, wikis,
prompts — and prose can't reconcile truth. Two sources contradict each other and the doc
doesn't know; a truth ages and nobody supersedes it; `git merge` merges *text*, not *what's
true* — editing a line in a 30KB doc erases the contradiction with no record.

RAG/GraphRAG don't fix this — they *retrieve*, they don't *reconcile* (recent work shows ~10%
accuracy on implicit version changes). Retrieval ≠ deciding what's true.

The method: model knowledge as a typed graph. Nodes: claim / evidence / decision / question.
Edges: SUPPORTS, REFUTES (contradiction as an explicit edge, not a deletion), SUPERSEDES (new
truth beats old without erasing it). A *deterministic* radar (not an LLM) reads the graph and
gives the verdict: what to look at, which contradictions to reconcile, what's orphaned. When a
claim falls, it becomes status: refuted with the edge that killed it — history reconciles, it
doesn't delete.

It's a schema + method, not a SaaS — it doesn't want your data. Born dogfooded on real
production audits, not on paper. Starting point (public, no signup):
https://github.com/marciocar/onion-mini — writeup: https://onionevolve.com/convite/

Genuinely curious where this breaks. If you try it on your own domain, I'd love to see the
.kg.yaml (anonymized) or what the radar caught that the prose was hiding.
```

*Tom HN: humilde, técnico, convida crítica ("where this breaks"). Sem emoji, sem "revolucionário".*

---

## 2) Reddit — r/AI_Agents (ou r/LLMDevs) (inglês)

**Título:**

```
git merge doesn't reconcile *truth* — so I model org knowledge as a typed graph instead
```

**Corpo:**

```
Working with AI-heavy teams, I kept seeing knowledge rot silently: contradictory "truths"
across docs, and no mechanism to confront them. `git merge` joins text, not truth — edit a
line and the contradiction vanishes with no trace. RAG retrieves, it doesn't reconcile.

So instead of prose, the knowledge lives as a typed graph:
- nodes: claim / evidence / decision / question
- edges: SUPPORTS, REFUTES (contradiction = an explicit edge, not a delete), SUPERSEDES

A deterministic radar (not an LLM) reads it and tells you what to reconcile, what's orphaned,
where the refuted-but-still-referenced claims are. A claim that falls becomes `refuted` with
the edge that killed it — nothing is erased.

It's schema + method (not a product, doesn't touch your data). Public starting point:
github.com/marciocar/onion-mini · 3-min writeup: onionevolve.com/convite/

Not selling anything — I want to see if it holds outside my own head. If you try it on a real
contradiction in your domain, tell me what the radar caught. What am I missing?
```

*Tom Reddit: primeira pessoa, "not selling anything", pergunta aberta. **Leia as regras do sub.***

---

## 3) LinkedIn (pt-BR) — ⚠️ órbita: alcance, não pull frio

```
"git merge não reconcilia verdades."

Foi a frase que me fez parar. Times que trabalham com IA acumulam conhecimento em prosa —
docs, ADRs, wikis, prompts. E a prosa não sabe reconciliar: duas fontes se contradizem e o
documento não percebe; uma verdade envelhece e ninguém supera a antiga; você edita uma linha e
a contradição some sem deixar rastro.

RAG não resolve — ele *recupera*, não *reconcilia*.

A alternativa que venho dogfoodando: modelar conhecimento como um grafo tipado, não prosa.
Afirmações, evidências e decisões viram nós; contradições viram arestas explícitas (REFUTES),
não deleções; uma verdade nova supera a velha sem apagá-la (SUPERSEDES). Um radar determinístico
— não um LLM — lê o grafo e dá o veredito: o que reconciliar, o que está órfão. Quando uma
verdade cai, ela fica registrada como refutada, com a aresta que a derrubou. História reconcilia,
não apaga.

É método aberto (schema + método, não um SaaS — não pede seus dados). Nasceu em auditorias de
produção reais.

Se isso ressoa com uma dor sua, o ponto de partida é público: onionevolve.com/convite/

Curioso pra ver funcionar fora da minha própria casa — se você testar num domínio seu, me mostra
o que o radar pegou.
```

*Tom LinkedIn: narrativo, primeira pessoa, hook forte. **Lembrete:** aqui é a sua rede = órbita.*
