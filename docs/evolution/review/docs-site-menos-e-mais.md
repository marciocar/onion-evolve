---
title: "Revisao — 'menos e mais' na raiz do site (self-review)"
date: 2026-08-26
branch: docs/site-menos-e-mais
reviewer: "self-review (autor) — corte cirurgico da landing, aprovado pelo maestro (depth=cirurgico); build validado"
reviewed_diff_sha256: 65e2981fff91b576d4f3acbdfeea44611931b1f686487e5acd80e68f263f1852
findings_total: 1
findings_real: 0
verdict: APROVADO
tokens: 700
duration_min: 4
---

# Residuo — REGRA 56 (self-review; edicao de site, deploy no merge)

O maestro pediu 'menos e mais' na raiz (revisao ao vivo achou a landing verbosa: 14 blocos, prova de 7
casos, 8 metodos). Depth confirmada: CIRURGICO.

- **So redundancia cortada?** SIM — cada bloco reduzido JA TEM pagina dedicada: prova 7→3 + link p/
  /provas; metodos 8→3 + link p/ /doutrinas; verticais sem belief-box/badge; ecossistema 4→2. O
  esqueleto (hero, tese, 3 dimensoes, CTA) e a densidade que ja acertava (as migalhas) ficam intactos.
- **Nada orfanado?** VERIFICADO — o corte tirou o unico link p/ /pulse-mais; reancorei no card Educacao
  (contexto certo). Todos os destinos internos seguem alcancaveis (doutrinas/federacao/historia/
  migalhas/provas/mini/pulse-mais).
- **Numeros?** Refrescados do git de HOJE: 448→667 PRs, 951→1384 commits, carimbo 07-22→08-26 (o 
  visto no fetch era count-up pre-JS, nao bug — anota o meu proprio engano da duvida).
- **Nao quebrou?**  Complete (10 paginas); lint 0 HARD. Raiz 415→365 linhas.

**Veredito: APROVADO** — corte de densidade, nao de conteudo (o conteudo vive nas paginas dedicadas,
agora LINKADAS). O merge redeploya a landing enxuta. Fecha a tarefa que herdei da sessao perdida do site.
