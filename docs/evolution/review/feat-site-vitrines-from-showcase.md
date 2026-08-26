---
title: "Revisao — projeta ticker+prova do showcase do KG (valida vitrines)"
date: 2026-08-26
branch: feat/site-vitrines-from-showcase
reviewer: "self-review (autor) — projecao das vitrines a partir do showcase 2b + validacao das atuais; build validado"
reviewed_diff_sha256: 7370fbe7a4c9aeb6940f2749a885dd436e027cc776fdf225f3c912ceb4959669
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 2200
duration_min: 25
---

# Residuo — REGRA 56 (self-review; edicao de site, deploy no merge)

O maestro: "projete as vitrines do showcase e valide as atuais". Fecha o laco grafo-primeiro do hero
(as vitrines de PR PROJETAM da SSOT verificavel, nao hand-curam — foi assim que o ticker driftou).

**VALIDACAO (o achado real, findings_real:1 — drift confirmado):**
- Ticker atual: #326/#324/#321/#320/#268/#266/#265/#258 — **7 de 8 NAO estao na selecao refinada** (so #258).
- Prova atual: #222 ✅, #301 ✅, **#324 ❌** (nao entrou na selecao). Eram PRs de jun/jul escolhidos a mao
  ha meses; o KG tem **85 incidentes ate #600+**, mais fortes e on-message. Drift real, curado.

**PROJECAO (do showcase 2b):**
- **TICKER** — 8 recentes (#674/#672/#671/#670/#667/#664/#657/#656), pulso real, frase curta derivada dos
  one-liners do showcase.
- **PROVA** — trio do MECANISMO VERIFICAVEL (o que o hero novo vende): #222 (adotante verifica carimbo
  forjado = declarado≠verificado) · #623 (instalador mentia 'sucesso' com a guarda morta → provar por
  COMPORTAMENTO, nao exit 0) · #670 (dogfood de install: 2 guardas viajaram desligados, so rodar achou).
  Datas REAIS de merge (2026-07-02 / 08-16 / 08-25). Estrutura erro→aprendizado→lei mantida; #670 e o case-hoje.

**Criterio da selecao:** diversidade (adotante-verifica / doutrina-comportamento / dogfood-roda) + on-message
com o moat + span origem→recente (mostra que AINDA se pega). #301 (commit duravel) e #324 (radar fantasma)
saem da home mas seguem na /historia/ e no /provas/ (nao se perdem).

**Nao quebrou?** build Astro rc=0; dist: ticker/prova novos, antigos = 0. lint 0 HARD. PR segue como recibo.

**Veredito: APROVADO** — drift das vitrines validado e curado por projecao da SSOT. O merge redeploya.
Follow-up possivel: gerar o ticker/prova em BUILD direto do .kg.yaml (hoje a projecao foi manual-do-showcase;
mecaniza-la e o proximo degrau do grafo-primeiro).
