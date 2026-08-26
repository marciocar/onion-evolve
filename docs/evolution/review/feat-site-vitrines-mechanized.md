---
title: "Revisao — projecao das vitrines mecanizada em build + prova 6 cards"
date: 2026-08-26
branch: feat/site-vitrines-mechanized
reviewer: "self-review (autor) — mecanizacao grafo-primeiro; guard anti-drift provado por comportamento; build validado"
reviewed_diff_sha256: 29b6129b4e1a4365b65041647f39f8557b9920f5a04a294c87a892149c1ae15d
findings_total: 1
findings_real: 0
verdict: APROVADO
tokens: 3200
duration_min: 35
---

# Residuo — REGRA 56 (self-review; edicao de site, deploy no merge)

Dois pedidos do maestro num movimento: mecanizar a projecao em build + prova com 6 criacoes ('show').

**1) MECANIZACAO (grafo-primeiro, ultimo degrau):**
- `src/lib/vitrines.ts` le `pr-decision-history-2026-08.kg.yaml` em build: SELECAO (aresta E_VITRINE_*),
  DATA (verified_at) e URL (trace) vem do GRAFO. O texto (one-liner/erro-aprendizado-lei) vive em
  `src/data/vitrines.ts` (camada editorial). `index.astro` renderiza via map.
- **GUARDA anti-drift PROVADA POR COMPORTAMENTO** (nao declarada): pus PR #3 (rotina, sem vitrine) na
  prova → `npm build` saiu **rc=1** com "PR #3 nao e publicavel no grafo"; revertido → rc=0. O site nao
  consegue mais mostrar um PR que o grafo nao selecionou — o hand-curar que envelheceu o ticker esta
  mecanicamente impedido. Datas nunca mais se digitam a mao (derivam do merge).

**2) PROVA = 6 CARDS das criacoes de mecanica/doutrina mais significativas (o maestro: 'tem que ser show'):**
#222 declarado≠verificado · #301 Commit Duravel · #398 o radar que sabe dizer 'nao sei' (o MOAT — leu 0 de
144 nos e disse OK, fechou o fail-open) · #623 behavior-over-declaration · #656 guarda anti-commit-main ·
#670 dogfood (guardas desligados, 'hoje'). Todos keep+prova no grafo (validado). Grid auto-fit 3x2.

**Achado (findings_real:0 — verificado, resolvido no desenho):** SUPERSEDES/REFUTES ja tratadas na fase 2b;
aqui a unica logica nova (parse do .kg.yaml em TS) foi validada por: (a) build derivou a data #398=2026-07-17
do grafo (nao do data file), provando o parse; (b) o guard falhou o build com PR fora da selecao.

**Nao quebrou?** build Astro rc=0 (10 paginas); guard negativo rc=1 provado + revert rc=0; lint 0 HARD.

**Veredito: APROVADO** — fecha o laco grafo-primeiro do hero de ponta a ponta: o hero promete 'historico de
decisoes como grafo verificavel' → o KG dos 672 PRs e o grafo → as vitrines PROJETAM dele em build, e a SSOT
recusa qualquer vitrine que a contradiga. Follow-up possivel: mecanizar tambem /historia/ e /provas/.
