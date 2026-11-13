---
branch: docs/agent-requester-privilege-research
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: 646a25fade963863eb4b8d023c7295a1bf08938987743f7e63c906b292e4c166
reviewed_code_sha256: 7d2d5281ffeb11e0980c98bf703a9c8398bf79c6a471b25c3f6122de32e9b604
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

O pr-finalize reprovou a 1ª rodada no contrato do commit: o lint de nomes (`ops/kg-vocab-ci.sh`) achou 29
códigos novos sem termo (LLM06, ASI03, ASI08, T8, T9) na prosa que o workflow escreveu. A cura são 5 nós
`T_OWASP_*` com `x_term` e aresta TRACES_TO à pergunta (teto 68 → 73); o `write(KG)` do workflow confere radar
e contrato, mas não o lint de nomes, então a rodada saiu verde e o commit não.

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
