---
title: "Revisao — passada de secoes da home (alinhamento ao hero novo)"
date: 2026-08-26
branch: feat/site-sections-buyer-aligned
reviewer: "self-review (autor) — revisao de copy das secoes pedida pelo maestro ('rever as secoes, principalmente a prova viva'); direcao travada nas iteracoes do hero; build validado"
reviewed_diff_sha256: 03379508079b5b3076605e7a5d6d788ad4f79da463e32e813a56859ec8b6de97
findings_total: 2
findings_real: 0
verdict: APROVADO
tokens: 2600
duration_min: 25
---

# Residuo — REGRA 56 (self-review; edicao de site, deploy no merge)

Segue o hero novo (#676): o hero mudou a tese (conhecimento-como-ativo / historico de decisoes /
comprador P3-P4), mas as secoes abaixo ainda falavam dev/codigo. Esta passada alinha as secoes.

**O que mudou (escopo verificado):**
- **A prova viva** — so o enquadramento (h2/lead/stamp), p/ fechar o laco do hero "voce audita, nao
  confia". Os 3 casos (pin forjado / commit duravel / radar fantasma) ficam intactos — sao a prova de
  verificacao-por-mecanismo e ja eram um historico de decisao (erro→porque→lei). O PR segue como RECIBO
  no rodape de cada caso (regra de copy travada com o maestro: PR e recibo de "va conferir", nunca manchete).
- **O problema** — as 4 DORs de engenheiro (prompt ad-hoc, codigo-antes-da-spec, integracao) viram as
  dores do comprador (personas.md P3/P4): conhecimento na cabeca das pessoas, documento≠decisao, cada um
  usa a IA de um jeito, nao da p/ auditar. Alinha o funil ao hero.
- **Numeros** — 7→8 caixas em grade 4×2 (a pedido do maestro): arsenal (comandos/agentes/KBs/skills) +
  rede (membros/linhagens/PRs/produtos). `inv.skills` e derivado, como os outros do inventario.

**Riscos avaliados:**
- **Numeros hardcoded (4/7/667/2)** — inalterados; ja eram congelados-no-tempo com carimbo de data. So
  acrescentei skills (derivado). Sem drift novo.
- **PR-as-receipt** — o ticker ja descreve a DECISAO em cada linha (o numero e recibo), entao nao mudou;
  a regra so reforcou que prova/historia mantem o PR no rodape/como link auditavel.

**Nao quebrou?** build Astro rc=0 (10 paginas); dist: 8 caixas de numero, prova/problema novos servidos,
copy antigo = 0. lint 0 HARD.

**Veredito: APROVADO** — revisao de copy + layout (4×2), escopo contido no funil da home. O merge
redeploya. Follow-ups nomeados: reframe da /historia/ (memoria → argumento); ajuste fino de
resposta/verticais/metodos p/ a linguagem do comprador (hoje coerentes mas code-first).
