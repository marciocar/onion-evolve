---
reviewed_diff_sha256: 52adc16593b493d04892df28f7d114f3a26fa2a5f1a4ea4f95e4f342a99b059c
findings_total: 7
findings_real: 7
tokens: 115149
duration_min: 5
verdict: APROVADO
elenxo: sim
nota: >
  O juiz fixo do eixo E3 (opus, worktree isolada, mandato de refutar, abriu as fontes) reprovou 2 de
  5 nós e o supersedes_none da 1a redação, todos por generalizar além do medido. Os sete pontos foram
  incorporados ao grafo antes de selar a baseline. APROVADO é o estado depois disso.
---

# Resíduo — `docs/radar-e3-2026-10-05`

Rodada 7 do eixo E3 (2.1.288 → 2.1.289). O juiz reproduziu o bloco da versão (27/27, diff idêntico),
conferiu a contiguidade em três fontes e a atribuição de versão de todo item citado (zero erro desta
vez, contra quatro na r6).

## O que ele derrubou, e o desfecho

| # | achado | desfecho |
|---|---|---|
| 1 | "seis furos deny/ask" — eram quatro | corrigido |
| 2 | "a classe não existe no veto próprio" — 15 formas escapam, inclusive `git push origin +main` | reproduzido no contexto principal; nó `E_VETOS_PROPRIOS_TEM_A_MESMA_CLASSE` + `Q_CURAR_OS_VETOS_DE_MERGE_E_PUSH` (gatilho disparado) |
| 3 | o core não instala deny, mas o `@claude-code-specialist` os recomenda a adotantes | incorporado ao nó |
| 4 | "contiguidade da r6 respondida" — a pergunta era sobre o mecanismo | corrigido; o nó da r6 segue aberto |
| 5 | composição 6/2 não fechava (5/3) | corrigido |
| 6 | `supersedes_none` ignorava a evidência nova sobre mods | nó `E_MODS_FALHAM_ABERTO_NO_UPGRADE` |
| 7 | `agent.spawn` é API de mods, não dos hooks de shell | ressalva no nó |

## Os `confirmed` do grafo da baseline anterior

Os 15 nós da r6 foram lidos pelo juiz; nenhum é derrubado. `Q_MOD_YOU_SHOULD_KNOW_E_UM_ELENXO_FRACO` e
`Q_FLUXO_NAO_CHECA_CONTIGUIDADE_DE_VERSAO` seguem abertos, o primeiro com evidência nova.
