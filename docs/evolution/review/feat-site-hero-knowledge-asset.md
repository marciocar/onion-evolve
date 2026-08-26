---
title: "Revisao — novo hero da home (conhecimento como ativo verificavel)"
date: 2026-08-26
branch: feat/site-hero-knowledge-asset
reviewer: "self-review (autor) — reposicionamento do hero co-criado com o maestro ao vivo; direcao e estetica aprovadas em mockup; build validado"
reviewed_diff_sha256: c86a808c61c8e7d210a6bf512ced5cea204f2e3abfa7467a157bcf64e0647d9b
findings_total: 2
findings_real: 0
verdict: APROVADO
tokens: 4200
duration_min: 40
---

# Residuo — REGRA 56 (self-review; edicao de site, deploy no merge)

O maestro pediu revisao de copy da home ("nao esta atraente; venda para quem tem a dor e o dinheiro,
nao compra tecnica"). Direcao travada ao vivo por 6 iteracoes sobre um mockup (artifact privado),
ancorada em: pesquisa externa 2026 (2 frentes) + SDT do livro do maestro "O Jogo dos Negocios" +
messaging-framework.md (SSOT de marca) + personas.md (P3/P4 = comprador). Hero aprovado: **"opcao 1"**
(risco do ativo) + estetica dark/laranja-vivo/alto-contraste.

**Escopo (contido, verificado):**
- **So o hero + title/description + typewriter morto.** As demais secoes da home ficam intactas nesta
  passada (reordenacao das secoes e reframe da /historia/ ficaram como follow-up nomeado, nao entraram).
- **Laranja vivo #FF6A2B escopado ao `.hero`** (variaveis `--h-*` locais) — o token global `--orange`
  (#C2410C) NAO mudou, logo as outras paginas (doutrinas/historia/maquinaria/estado/migalhas) seguem
  identicas. Sem ripple.
- **`.btn-p` do resto da home preservado** — override so em `.hero .btn-p`; o botao da secao #comecar
  segue no rust do site.

**Riscos avaliados:**
- **Faixa dark sobre site creme** — decisao de design (hero dark → corpo claro, padrao premium). Transicao
  limpa: hero → ticker (branco) → secoes creme. Nao e bug; e a escolha aprovada no mockup. Se destoar ao
  vivo, o follow-up "site inteiro dark" resolve.
- **Typewriter orfao** — `#type` saiu do H1; o script `getElementById('type')` vira no-op (guarda `if(el)`).
  Removi o bloco morto + a string antiga "erra, aprende e vira lei" (estava no title, no script e no H1).

**Nao quebrou?** build Astro rc=0 (10 paginas); dist serve o hero novo (h1/sub/terminal), title novo, e
0 ocorrencia do posicionamento antigo. lint 0 HARD.

**Veredito: APROVADO** — reposicionamento de copy + estetica do hero, escopo contido, sem ripple no resto
do site. O merge redeploya (deploy-site.sh na KVM 8). Follow-ups nomeados p/ o maestro: (1) reordenar as
secoes na jornada SDT; (2) reframe da /historia/ (memoria → argumento); (3) opcao de levar o site inteiro
p/ dark. Absorve tambem o fix anterior do carimbo 448→667 (commit irmao nesta branch).
