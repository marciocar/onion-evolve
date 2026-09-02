---
title: "Revisão — a diretriz de pesquisa vira maquinaria: grafo + plano F1-F4 (pesquisa de 4 workers)"
date: 2026-09-02
branch: research/meta-research-lens
reviewer: "condutor com medição executada: 4 workers opus (inventário interno read-only; Claude Code 2.1.258 em fontes primárias; estado da arte deep research + KG temporal; mercado/capital) + WebFetch do deepdive e da doc de workflows + script do /deep-research extraído do binário 2.1.258; radar --integrity --schema exit 0 (26 nós/34 arestas); backlog regenerado LC_ALL=C; diary-index rc=0"
reviewed_diff_sha256: bf0031dd8c1c58bcf46785a60d149e7e51e20c545b9c9ea972d973cbdf15d24d
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 1200000
duration_min: 45
---

# Resíduo — REGRA 56

Pesquisa ordenada pelo maestro ("paralelo"), entregue como grafo (SSOT) + plano de execução (projeção) +
dado bruto em `data/`. Nenhuma decisão selada: os nós `D_F1..F4` nascem `open` para o maestro.

## Achados

1. **Não há doutrina de escolha de fontes no core** (pergunta do maestro): grep por tier/hierarquia/
   credibilidade/fonte primária só acha a worktree velha; R15 é confiança no conteúdo, não seleção.
   Virou nó de evidência + peça do plano (roster + tier + guarda).
2. **O Claude Code 2.1.258 já traz `/deep-research` como workflow embutido** (3 votos/2 refutações,
   15 fetch, 25 claims): a base a derivar, não reescrever — o plano compõe sobre ele.
3. **Contra-sinal institucional**: Thoughtworks Radar v34 tem *agent instruction bloat* em CAUTION e
   descreve as 52k linhas de markdown do core; logo a diretriz não vai para o CLAUDE.md, e nasce o fio
   de poda (gated).
4. **`tokens:` do frontmatter é estimativa**: o `Agent` tool não reporta custo por worker (o
   `Workflow` reporta) — declarado na SYNTHESIS; o próprio plano corrige ao usar `Workflow`.

## Não mudou

- Nenhum artefato de `.claude/` (comando, skill, hook, lint) foi criado: só grafo, projeção, dado e migalha.
- 13 NÃO-VERIFICADOS dos workers preservados como lacunas de 1ª classe (Gartner 403, SO Survey 2026 sem
  resultados, teto de WebSearch não lido em fonte primária…).
