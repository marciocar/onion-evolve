---
title: "Revisão — F2 da lente de pesquisa: workflow /onion-research (derivado do /deep-research), skill auto-ativada, roster de fontes, --axis; dogfood ao vivo"
date: 2026-09-02
branch: feat/research-lens-f2
reviewer: "condutor com dogfood EXECUTADO: Workflow wf_9dad8645-eda em 2 rodadas (1ª falhou alto: 17 agentes/1,08M/0 claims → 3 defeitos corrigidos; 2ª retomada do cache: 31 agentes acumulados/1,33M, grafo websearch-cap-2026-09 escrito com radar exit 0, 3 achados, mercado declarado); medição determinística no binário 2.1.258 fechou 2 NÃO-VERIFICADOS; bancada run_research_workflow_selftests 5/5 isolada (sem variável predefinida); lint --only rc=0 em skill/roster/CLAUDE.md/SYNTHESIS; inventário e graph.md regenerados (12→13 skills); radar exit 0 nos 2 grafos tocados; backlog LC_ALL=C"
reviewed_diff_sha256: 67409c4667d6273c86caf57928f8b5a121e719b1228e752e278045b3abe493d9
findings_total: 5
findings_real: 5
verdict: APROVADO
tokens: 1600000
duration_min: 60
---

# Resíduo — REGRA 56

F2 do plano `meta-research-lens-2026-09` (`D_F2`, selo do maestro). O motor: `.claude/workflows/onion-research.js`
derivado do `/deep-research` embutido no 2.1.258 (helpers R15 reescritos, votação 3/2 mantida) + eixos fixos
(Claude Code atual · **mercado/capital** · trajetória · analistas · comunidade) + tier/kind/validFrom por fonte +
orçamento nomeado + tiering por fase + fase `write(KG)` com radar; skill `onion-research` auto-ativada que injeta
corpus/data/versão com `!cmd`; `docs/onion/radar-sources.yaml` (7 eixos, tier por fonte); `/meta:radar --axis`.

## Achados

1. **A 1ª rodada do dogfood falhou alto com 0 claims (1,08 M tokens)** — 3 defeitos de desenho: orçamento de
   fetch *first-come* (o 1º ângulo tomou os 6 slots com GitHub blobs que o WebFetch não abre; a doc oficial,
   presente em 6 ângulos, foi cortada), WebFetch sem prompt dirigido (changelog tier 9 → 0 claims), sem retry
   `raw.githubusercontent.com`. Cura: barreira justificada + ranking global + round-robin por ângulo + prompt da
   pergunta no WebFetch + retry. Rodada 2 reaproveitou 10 coletores do cache.
2. **O tier segurou a confiança**: 3-0 nos votos não promoveu achado de agregador tier 3 (2.1.212) a *high* —
   REGRA 68 e doutrina funcionando no primeiro uso.
3. **Artefato instalado antes da web**: a pergunta aberta certa do sintetizador ("grep no binário") fechou 2
   NÃO-VERIFICADOS (teto 200 + contador de sessão; MAX_CONCURRENT_SUBAGENTS=20) com 1 comando, tier 10.
   Cláusula 2 da doutrina emendada.
4. **`node --check` mente para script de workflow** (top-level `return`): a bancada embrulha o corpo em async
   como o runtime; e regex com U+2028/2029 literais quebra — escapes `\u2028`.
5. **Custo/nó ~220 k** (1,33 M ÷ 6) vs 68–74 k do censo — regressão declarada (causa: rodada 1). `tokens:` do
   frontmatter é o total do run retomado (inclui cache); a rodada 1 sozinha foi 1.078.684.

## Não mudou

- Skill `onion-research` **fora** do plugin `onion` (o manifest enumera skills; entra quando o maestro decidir).
- `/clear` × contador e custo/limite do WebFetch seguem abertos no grafo da pesquisa.
- `D_BUSCA_COMO_SDAAL_GATED` continua gated: o teto não mordeu nesta rodada.
- F3 (modo decisão) e F4 (revisita) seguem `open`.
