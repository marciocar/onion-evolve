---
kg: docs/evolution/research/websearch-cap-2026-09/websearch-cap-2026-09.kg.yaml
run_id: "wf_9dad8645-eda (workflow salvo .claude/workflows/onion-research.js — 1º DOGFOOD do F2; rodada 1 falhou alto com 0 claims; rodada 2 relançada com cache após 3 correções)"
tokens: 1327788
agents: 31
duration_min: 14
verified_at: 2026-09-02
---

# Teto de WebSearch por sessão no Claude Code 2.1.258 — dogfood do `/onion-research` (projeção do grafo)

> **SSOT:** [`websearch-cap-2026-09.kg.yaml`](./websearch-cap-2026-09.kg.yaml) (radar exit 0; 8 nós: 6 da rodada
> do workflow + 2 emendas por **medição determinística no binário**). Pergunta escolhida por ser o
> NÃO-VERIFICADO #1 da pesquisa `meta-research-lens-2026-09`. `tokens:` é o total reportado pelo run
> retomado (inclui os 17 agentes da rodada 1 servidos do cache — a rodada 1 sozinha custou 1.078.684).

## A resposta

| pergunta | resposta | fonte / tier |
|---|---|---|
| existe teto? default? | **sim, 200** por sessão; `CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION` sobrescreve | **binário 2.1.258** (tier 10) — o workflow só tinha achado um agregador tier 3 (2.1.212) |
| ao esgotar | o modelo é instruído a seguir com o que já coletou e pedir ao usuário para subir a env — **degrada em silêncio narrativo**, não em erro | binário (mensagem literal) |
| soma subagentes? | **sim**: o contador vive em `taskRegistry` (registro da sessão) | binário (`incrementWebSearchCalls`) |
| `/clear` zera? | **não medido** — o que `/clear` faz com o `taskRegistry` fica aberto | — |
| custo/limite do WebFetch | **sem resposta** nesta rodada (a única fonte útil não fala de WebFetch; corpus só tem o cache de 15 min) | ausência verificada (high) |
| colateral | `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` existe, default **20** — fecha o NÃO-VERIFICADO #2 | binário (tier 10) |

**Mercado (invariante):** sem sinal — declarado, não omitido. Pergunta de parâmetro interno; o único vetor latente
(teto como alavanca de unit economics) é hipótese.

## O que o dogfood ensinou sobre o próprio workflow (o valor real desta rodada)

1. **Rodada 1 falhou alto e corretamente** — 17 agentes, 1,08 M tokens, **0 claims**: o orçamento de fetch era
   *first-come* (o primeiro ângulo a chegar tomou os 6 slots com 5 URLs de GitHub blob que o WebFetch não abre)
   e a doc oficial, presente em 6 ângulos, foi cortada por orçamento; o único primário aberto (changelog) devolveu
   0 claims porque o WebFetch foi chamado sem prompt dirigido. **Corrigido no script:** barreira justificada
   (o orçamento precisa ver todos os resultados) + ranking global (relevância, depois hosts primários) +
   **round-robin por ângulo** (todo eixo fixo ganha ≥ 1 fetch) + WebFetch com o prompt da pergunta + retry
   `raw.githubusercontent.com`. A rodada 2 reaproveitou os 10 coletores do cache.
2. **O tier segurou a confiança:** 3-0 nos votos **não** promoveu o achado a *high* porque a fonte era agregador
   tier 3 sobre a 2.1.212 — exatamente o comportamento que a REGRA 68 e a doutrina pedem.
3. **A pergunta aberta certa é determinística:** o sintetizador propôs "grep no binário" — 1 comando, tier 10,
   fechou duas lacunas que 1,3 M tokens de busca web não fecharam. **Lição para a doutrina:** para "qual é o
   valor de X no Claude Code Y", o corpus e o **artefato instalado** vêm antes da web (cláusula 2).
4. **Custo/nó: ~220 k por nó** (1,33 M ÷ 6) contra 68–74 k do censo — regressão declarada; a causa dominante é a
   rodada 1 desperdiçada. Custo marginal da rodada 2 ≈ 250 k para 3 achados + grafo.

## Lacunas declaradas

`/clear` × contador; custo/limite do WebFetch; nenhuma fonte primária **web** alcançada (a primária que fechou
foi o binário local); Reddit inalcançável (já no corpus); nada medido *rodando* 201 buscas.

## valeu-a-pena

Como pesquisa: 1 fonte tier 3 + 2 medições tier 10 por 1,3 M tokens — caro. Como dogfood: achou e curou 3
defeitos de desenho do workflow antes do primeiro uso real, e provou que write(KG) + radar + tier + revisita
(`review_after` 2026-10-02, cadência ferramenta 30 d) funcionam ponta a ponta. Valeu pelo segundo motivo.
