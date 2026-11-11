---
branch: docs/company-brain-non-devs-study
pr: pendente
date: 2026-11-11
reviewed_diff_sha256: 4e149abb47858ef852c0099fc31a1edd42e91bad4063697d6b1e09b7a91b3db1
reviewed_code_sha256: 2a13dc3d440a86fbfbeb0de27a3992ba9da4a144ff33753ec34c2c504ea36a62
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: passada própria da sessão do core sobre o diff, sem revisor independente
nota: "tokens 0 = não medido. O diff é um grafo de estudo, a SYNTHESIS que o projeta e dois relatórios de primárias; sem código."
---

# Passada adversarial: `docs/company-brain-non-devs-study`

## O que muda

O estudo do Company Brain para quem não é dev: 25 nós, com seis selos do maestro (gravados pelo
`kg-decide-seal.sh`), a leitura do kg-ssot sobre a matriz v1, a SYNTHESIS e os relatórios de primárias.

## Achados

Nenhum. Conferi três coisas. Nenhum nome comercial de cliente aparece: o piloto é "o primeiro cliente" e a
matriz concreta fica no repositório privado do adotante. Radar e contrato estão verdes. Cada selo é a
resposta do maestro na rodada.

## Mutantes

Não se aplica: nenhum código mudou.

## Re-revisão de 2026-11-11

O único acréscimo depois da revisão: `trace:` nos nós `E_PRIMARIAS_SLACK_MCP_RUNTIME_PERMISSAO_1111` e `E_COMUNIDADE_CLAUDE_COMO_FRONT_1111`, apontando os dois relatórios de `data/` (REGRA 29 (Gate de PROVENIÊNCIA INVERTIDO, com catraca)). Radar `--integrity --schema` exit 0.

## Re-revisão 2 de 2026-11-11

Dois selos novos do maestro pelo `kg-decide-seal.sh`: `D_PROMOCAO_POR_PR_COM_HASH_DO_NO_1111` e `D_REPO_POR_AUDIENCIA_PLANO_B_1111`, sobre os vereditos da curadoria. Radar e contrato verdes pelo selador.

## Limites declarados

- Sem revisor independente. As evidências de sessões pares são testemunho, e estão marcadas assim na
  proveniência.
