---
branch: docs/close-doorbell-clauses-1117
pr: pendente
date: 2026-11-17
reviewed_diff_sha256: 6ef5c367ddff61ad7f8565d5d9b183604f4d66aa8f01f8a7b53c938f453639ed
reviewed_code_sha256: 64bdf18010bf1987391046c5b5a08644281139b58d700b3a4c17921942271cc4
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "Um nó de pergunta fechado por medição: o core leu, na main do repositório da mensageria depois do merge do PR dele, as duas cláusulas no texto de instructions do servidor da campainha, os dois casos de bancada e os dois mutantes. kg-radar --integrity --schema rc 0 e kg-contract-check rc 0. Voz única do core; só grafo."
nota: "O repositório da mensageria é privado: o nó não leva URL nem commit dele, só o número do PR e a data do merge."
---

# Fecha a pergunta das cláusulas da campainha

## O que muda

`Q_IT_DOORBELL_INSTRUCTION_CLAUSES` (inbox-triage-1108) passa de aberta a feita, com a medição de 2026-11-17: as instructions da campainha têm a cláusula contra ação destrutiva e a cláusula contra autoescalada, com caso de bancada e mutante para cada uma.

## Achados

Nenhum.

## Limites declarados

- O core leu o texto, os casos e a lista de mutantes; não rodou a bancada da mensageria.
