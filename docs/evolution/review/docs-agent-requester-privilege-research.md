---
branch: docs/agent-requester-privilege-research
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: pendente
findings_total: 38
findings_real: 15
findings_blocking: 5
tokens: 1537345
duration_min: 15
findings_fixed: 0
verdict: APPROVED
elenxo: true
reviewer: "Elenxo do próprio workflow /onion-research (run wf_45f0fcd2-079, modo primárias): refutador sobre cada claim ancorada e sobre cada descarte, antes da escrita do grafo"
nota: "A passada adversarial deste PR é o Elenxo do próprio run, não uma passada separada sobre o diff. Ele levantou 38 objeções e 15 sobreviveram (5 bloqueiam, 10 limitam). As que bloqueiam bloqueiam HIPÓTESES da pergunta, não o PR: cada uma é nó E_OBJECAO com CONSTRAINS ao alvo, e a SYNTHESIS as lista sem afirmar o que elas negam. Por isso findings_fixed é 0 e o veredito é APPROVED do registro, não das hipóteses. Os tokens e a duração são os do run inteiro (a passada não tem custo separado medido)."
---

# Passada adversarial: `docs/agent-requester-privilege-research`

## O que muda

Entra o grafo da rodada de primárias `agent-requester-privilege-2026-11` (68 nós, 108 arestas, radar
`--integrity --schema` exit 0, `kg-contract-check` rc 0), a `SYNTHESIS.md` como projeção dele e o
`docs/backlog.md` regenerado com os nós abertos. Única edição no grafo depois do run: o `trace:` de
`C_ELENXO_RECOMMENDATION_1113` ganha o caminho da SYNTHESIS no MESMO valor (todos os 68 nós já tinham
`trace:`; acrescentar uma segunda chave a repetiria).

## Achados

Os cinco que bloqueiam (nós `E_OBJECAO_*`):

1. O token com `sub`/`act` não é trilha por ato; a trilha vem do log por chamada (OWASP ASI08).
2. O sucessor IETF vivo (`draft-ietf-wimse-aims-01`) foi achado e não ancorado.
3. Os campos de log de 8.15 são orientação da ISO 27002, não requisito do Anexo A da 27001.
4. "Menor entre agente e solicitante" não é norma: só mercado (Microsoft) e rascunho WG.
5. Aprovação por papel e o kit de auditoria não têm âncora normativa.

## Mutantes

Nenhum: o PR não traz código. O que foi conferido é o dado (radar e contrato antes e depois da edição do
`trace:`).

## Limites declarados

As dez objeções que limitam estão no grafo e resumidas na SYNTHESIS (escopo de `may_act`, chaves de contexto
da AWS que identificam recurso e não pessoa, citação de LLM06 possivelmente truncada, versões OWASP e NIST não
conferidas contra revisão posterior a 2026-11, entre outras). Nenhuma passada separada sobre o diff foi rodada.
