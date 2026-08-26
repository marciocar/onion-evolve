---
title: "Revisao — /historia/ vira argumento de venda"
date: 2026-08-26
branch: feat/site-historia-argument
reviewer: "self-review (autor) — reframe de copy pedido pelo maestro ('a historia tambem nao vende'); regra do PR-recibo aplicada; build validado"
reviewed_diff_sha256: 50226120ee55fbf03d4154cd8a9c06e5008509675621ea5881d89dc521da337f
findings_total: 2
findings_real: 0
verdict: APROVADO
tokens: 2400
duration_min: 22
---

# Residuo — REGRA 56 (self-review; edicao de site, deploy no merge)

O maestro: "a pagina de historico tambem e uma historia que nao vende". Reframe do ENQUADRAMENTO
(os 11 capitulos-prova ficam intactos — sao o ouro, cada um ja e um historico de decisao erro→porque→lei).

**O que mudou:**
- **Hero** — callback-memoir ("e o proximo capitulo ainda nao foi escrito. Foi." — so funciona p/ quem
  ja leu a autobiografia anterior) → TENSAO DE CATEGORIA + virada p/ o leitor ("Todo framework promete que
  evolui. Este te deixa auditar o erro." / "nao vim contar uma historia bonita — vim te mostrar os erros...
  antes de confiar o conhecimento da sua empresa a um metodo, veja como ele trata o proprio"). Voz em 1a
  pessoa preservada (Autobiographical Marketing).
- **Fecho** — virada p/ o leitor + CTA primario movido p/ o produto (/mini/, era "Ler as Migalhas").
- **Title/description** — reescritos p/ o argumento.
- **Typo 'Evolute'→'Evolve'** — corrigido no title E no footer (2 ocorrencias; o grep pegou a 2a que eu ia
  deixar passar). Footer "capitulo publicado em julho de 2026" (defasado — o maestro pegou) → "autobiografia
  viva, atualizada quando o campo ensina".

**Riscos avaliados:**
- **"julho de 2026" restante no dist** — e a data LEGITIMA do capitulo de julho (ch-date), nao o footer
  defasado. Verificado: o footer foi corrigido; a ocorrencia restante e conteudo correto.
- **PR-as-receipt** — a /historia/ referencia PRs como marcos com link auditavel; a regra (PR e recibo,
  nao manchete) ja era respeitada; sem mudanca necessaria nos capitulos.

**Nao quebrou?** build Astro rc=0 (10 paginas); dist: hero/sub/fecho novos, 'Evolute'=0, callback antigo=0,
13 ch-date (capitulos intactos). lint 0 HARD.

**Veredito: APROVADO** — reframe de copy do enquadramento, capitulos-prova preservados. O merge redeploya.
Follow-up remanescente: ajuste fino de resposta/verticais/metodos na home (code-first).
