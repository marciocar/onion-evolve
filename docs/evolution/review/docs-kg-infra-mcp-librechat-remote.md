---
reviewed_diff_sha256: aa354fe65dcd219a91fe1e139a101d2789c8d03ec56b916c8b767ba169d7fd68
reviewed_code_sha256: 3ebc15cbe6cc1c68d841eade71d7000765cf4bd48a3ee2ab27fdda156fa40b81
findings_total: 4
findings_real: 3
tokens: 84631
duration_min: 1
verdict: APROVADO
elenxo: sim
nota: >
  O refutador sonnet re-mediu cada afirmação do nó contra o vivo e APROVOU com ressalvas menores, todas
  curadas no nó. As que pesavam:
  - drift não registrado: a regra do ufw para a porta 3032 e o README do LibreChat ainda descrevem o MCP;
  - "de propósito" estava inferido, porque o comentário de 08-27 não cita o onion-kg pelo nome;
  - o momento em que o origin saiu não foi medido.
  A 4ª ressalva (o consumo remoto não é observável) ficou declarada na narrative.
---

# Resíduo — `docs/kg-infra-mcp-librechat-remote`

Medições do SAC-101 e do SAC-102 (2026-10-11, no host). O nó `E_ONION_KG_MCP_DESLIGADO_DE_PROPOSITO`
SUPERSEDES `Q_ONION_KG_MCP_NEXT`. O flip para superseded foi aprovado pelo maestro na pergunta
"registrar e investigar".

| # | achado | desfecho |
|---|---|---|
| 1 | a regra do ufw 3032 e o README do LibreChat ainda descrevem o MCP como vivo | declarado no nó como drift; nada encerrado (ferramenta da VPS só com o maestro) |
| 2 | "de propósito" estava inferido | curado: label e narrative dizem "coberto pela decisão de 08-27 que removeu o bloco do Onion" |
| 3 | "o origin saiu entre as duas medições" sem medição de quando | curado: "quando saiu não foi medido" |
| 4 | "nada o consome" só vale para o lado local | declarado: o consumo remoto não é observável daqui |
