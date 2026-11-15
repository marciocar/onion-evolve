---
branch: research/agent-privilege-nist-1115
pr: pendente
reviewed_diff_sha256: 872d97974ba0af51381048f0743dfda1bd81b806d0be1c4716003a226d5a3518
date: 2026-11-15
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 660655
duration_min: 16
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: true
reviewer: "round de primárias do workflow onion-research (wf_d942cc72-e05, 8 agentes, 660.655 tokens): 1 leitor + 1 verificador separado por fonte (OWASP LLM03:2026, NIST AI RMF/600-1), ancoragem reabrindo o documento; radar --integrity --schema exit 0 e contrato rc 0 pelo verificador do motor. Claim só com quote verbatim + locator. Fecha as DUAS metades da objeção E_OBJECAO_OWASP_NIST_VERSION_UNCHECKED (conteúdo OWASP 2026 + atualidade NIST). O SELO do maestro (D_AGENT_PRIVILEGE_ADOPTED_1115) foi gravado por kg-decide-seal.sh (radar 0, contrato 0, vocab limpo), testemunho por pergunta com opções."
nota: "PR de ROUND de pesquisa (Aufhebung) + SELO do maestro. O grafo +13 nós (9 evidências ancoradas, 1 contabilidade, 1 superação, 1 objeção-limite, 1 pergunta de revisão de selo) + 1 nó decision selado. 5 nós LLM06:2025 passam a superseded pela edição 2026. TETO subido de 105 a 107 (+13 round já contado na justificativa, +1 selo). O selo é ato do MAESTRO via /meta:decide (escolhida 'Selar: adotar o padrão/kit'); o grafo nunca sela no fluxo da pesquisa. Destrava a ponte (bridge #106/#107) + bump do SDK 0.3.325."
---

# Round NIST + SELO do privilégio do agente

## O que muda

Apêndice (Aufhebung) ao grafo `agent-requester-privilege-2026-11`: +13 nós, fechando as DUAS metades da objeção de atualidade `E_OBJECAO_OWASP_NIST_VERSION_UNCHECKED` — conteúdo OWASP (LLM06:2025 → LLM03:2026 Excessive Agency, texto ancorado) e atualidade NIST (AI RMF 1.0 vigente, em revisão). Mais o **SELO do maestro** `D_AGENT_PRIVILEGE_ADOPTED_1115` (adotar o padrão/kit), via /meta:decide. SYNTHESIS atualizada com a seção do round + selo.

## Achados

Nenhum defeito. Round de pesquisa com verificador separado por fonte e radar exit 0; selo gravado por kg-decide-seal (radar 0, contrato 0). A objeção fecha nas 2 metades; sobrevive só em grau limite (etiqueta "novo na 2026").

## Limites declarados

- O selo é do MAESTRO (testemunho por pergunta com opções), não da pesquisa; o grafo nunca sela no fluxo de pesquisa.
- A superação "menor-entre agente e solicitante como norma" segue sem fonte normativa que a enuncie literal (composição Onion, declarada).
