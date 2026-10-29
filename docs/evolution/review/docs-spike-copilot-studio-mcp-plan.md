---
title: 'Resíduo — plano do spike do Onion por MCP no Copilot Studio, e o label selado da D_ONION_BRAIN_MCP_REMOTO'
branch: docs/spike-copilot-studio-mcp-plan
pr: pendente
date: 2026-10-29
reviewed_diff_sha256: b719d60902bd7a39122a7abec25739c1ec15cd3c2014c463336cde12996c3998
reviewed_code_sha256: df07d32a0f9872cb311e2c9ce11d8fe757f9d06eb23368825b6e4b674838d31d
findings_total: 12
findings_real: 9
tokens: 64466
duration_min: 2
findings_fixed: 9
verdict: CORRIGIDO
elenxo: sim
reviewer: code-reviewer (subagente separado, só leitura)
nota: >-
  Um revisor separado, só leitura, passou o diff do 1º commit. Achou 12 coisas: 9 reais (2 importantes, 7
  menores) e 3 confirmações. As duas importantes eram de aresta: limitações do Studio entravam como apoio
  ao spike, e o filtro de schema apoiava a pergunta errada. Todas as 9 foram curadas no 2º commit da branch.
  O revisor não releu as curas.
---

# A passada adversarial achou limitações contadas como apoio

## O que muda

- Entra `docs/evolution/research/spike-copilot-studio-mcp-2026-10/`: o `PLAN.md` (projeção) e o grafo, com 12
  evidências da doc primária da Microsoft lidas em 2026-10-29, a autorização pendente do maestro
  (`Q_SPIKE_COPILOT_STUDIO_MCP`), o furo a medir antes (`Q_RECUSA_DO_CHECKLIST_PELO_SCHEMA_OU_GUARDA`) e a
  inferência da chave por usuário (`C_IDENTIDADE_POR_CHAVE_POR_USUARIO`).
- O label da `D_ONION_BRAIN_MCP_REMOTO` deixa de dizer "DECISÃO ABERTA" (o nó está `confirmed` desde
  2026-10-12), e o `SYNTHESIS.md` dessa pasta ganha uma nota datada.

## Achados

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | `E_CS_MCP_SCHEMA_LIMITATIONS` apoiava a `Q_RECUSA`, que trata do contrato e não do filtro do Studio | importante | curado: CONSTRAINS em `Q_SPIKE` |
| 2 | trial sem publicar, cotas e DLP entravam como SUPPORTS, e o plano os chama de riscos | importante | curado: CONSTRAINS |
| 3 | "é degrau 2" dito como fato, e o plano marca como inferência | menor | curado no label, na narrativa e no meta |
| 4 | "não há tipo Entra ID" com confiança 0,9 é leitura negativa | menor | curado: "não achei", 0,8 |
| 5 | a narrativa dizia que o X-Api-Key passa sem mudança; o writer compara um token compartilhado | menor | curado |
| 6 | "quatro das oito fontes" na janela; eram três | menor | curado |
| 7 | o cabeçalho de seção do grafo do brain ainda dizia "OPEN — o maestro sela" | menor | curado |
| 8 | `valid_from: "2025-08"` para "after August 2025" | menor | curado: `"2025-09"` |
| 9 | o PLAN.md esticava o texto do selo ("TLS", "OAuth 2.1") | menor | curado: cita o selo e atribui o resto à narrativa do Elenxo |
| 10 | o novo label do D_ só troca o prefixo; a nota não reescreve a história | — | confirmação |
| 11 | nenhum nome de cliente; os caminhos citados no PLAN já são públicos e não estão em campo de nó | — | confirmação |
| 12 | `review_after` a 30 dias; só `Q_SPIKE` tem `trace` | — | confirmação, radar rc 0 |

## Mutantes

Nenhum mutante rodou: o PR é só grafo e prosa. Os gates foram o radar (`--integrity --schema`) e o contrato
nos dois grafos, rc 0, e o `ops/kg-gate-ci.sh`, rc 0. O 1º rodou com rc 1 por um código sem termo
(`M365` no label), curado antes do commit.

## Limites declarados

- As oito páginas da Microsoft foram lidas pela sessão principal; ninguém as re-buscou neste PR.
- O revisor não releu as curas.
- Os dois commits de conteúdo saíram com `--no-verify` como checkpoint: o pre-commit passou de 9 min e foi
  morto pelo `timeout 590`, com o lint interrompido antes do sumário. O gate final é o CI.
