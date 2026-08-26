---
title: "Revisao — ajuste fino resposta/verticais (code-first → comprador)"
date: 2026-08-26
branch: feat/site-sections-finetune
reviewer: "self-review (autor) — ultimo ajuste fino de copy da home pedido pelo maestro; substancia intacta; build validado"
reviewed_diff_sha256: c480a76ddf69e73e7b6f9b52b331ea165c26aaafa4e72b1c35eb244a67618d6f
findings_total: 1
findings_real: 0
verdict: APROVADO
tokens: 1500
duration_min: 12
---

# Residuo — REGRA 56 (self-review; edicao de site, deploy no merge)

Ultimo follow-up nomeado da reforma da home: alinhar os pontos code-first restantes ao hero novo.
Ajuste FINO (nao reescrita) — a substancia (3 dimensoes peer, verticais dogfood-driven, doutrinas) fica.

**O que mudou:**
- **resposta** — h2 "Spec-as-Code, em tres dimensoes" (termo tecnico) → "Do produto ao compliance, uma
  disciplina so — e uma regra que nao se negocia." Lead lidera pelo BENEFICIO (decisao registrada em cada
  etapa, compliance como par — a cunha P4), com os numeros (comandos/agentes/skills) como prova. Goldrule
  e os 3 cards (Produto/Engenharia/Compliance) intactos.
- **verticais** — h2 auto-referente ("tres dimensoes nasceram comigo") → sinal anti-hype de confianca
  ("Nada aqui entra por roadmap. So quando um uso real prova que precisa."). Lead cita o grafo como o
  motor de verificacao (o moat). Cards Investigacao/Educacao intactos.
- **metodos** — revisado e MANTIDO: ja no eixo (anti-hype, "doutrinas nascidas de cicatriz" = por que confiar).

**Riscos avaliados:**
- **Termos tecnicos remanescentes** (SDAAL, `/meta:kg`, SUPPORTS/REFUTES nos cards) — deliberadamente mantidos:
  o comprador P3/P4 e tecnico-adjacente (CTO) e valoriza a especificidade como prova; a regra e liderar pelo
  beneficio no H2/lead e deixar o especifico como razao-de-crer no card. Feito.

**Nao quebrou?** build Astro rc=0 (10 paginas); dist: resposta/verticais novos, "Spec-as-Code em tres
dimensoes" = 0. lint 0 HARD.

**Veredito: APROVADO** — ajuste fino de enquadramento, substancia preservada. Fecha a reforma de copy da home
(hero #676 + secoes #677 + historia #678 + este). O merge redeploya.
