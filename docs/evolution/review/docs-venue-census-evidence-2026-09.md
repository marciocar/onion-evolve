---
title: "Revisão — censo do venue (gh api) vira evidência nos grafos de idioma e MCP: gatilhos nomeados MEDIDOS"
date: 2026-09-04
branch: docs/venue-census-evidence-2026-09
reviewer: "condutor com medição EXECUTADA por agente read-only: gh api sobre claude-plugins-community (2.282) e claude-plugins-official (291), 4 páginas de doc oficial por WebFetch; 3 nós de evidência + arestas; radar exit 0 nos dois grafos; backlog regenerado"
reviewed_diff_sha256: f5b81d2fd47cf56eb4f86b89ffe7110142f22bd8754fcc495f882860360e3965
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 150000
duration_min: 8
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados
1. **O gatilho barato valeu mais que a rodada cara** — a CONSTRAIN 2 do idioma (censo do venue) e os gatilhos (i)/(ii) do MCP foram cumpridos por um agente de 147k tokens em 6 min, contra ~7M por rodada de pesquisa. Achado de método: quando o Elenxo nomeia "1 comando" como lacuna, rode o comando antes de outra rodada.
2. **A base rate refuta a premissa de (c) sem reabrir (b)** — 49% dos plugins oficiais embarcam MCP; a reprova de (b) COMO ESPECIFICADA (raiz do projeto, annotations, stdio) continua; o peso mudou: (b) é o padrão do venue, não exceção. Resta o gatilho (iii).
3. **Limites declarados** — heurística de idioma por stopwords com spot-check; amostra alfabética de 60 na community (README por idioma das 2.222 restantes NÃO MEDIDO); 3 × 404 no SHA pinado.

## Fora de escopo
- Gatilho (iii) de (b): raiz do projeto do adotante para um MCP stdio embarcado — medir no binário (`cwd` do servidor lançado pelo plugin).
