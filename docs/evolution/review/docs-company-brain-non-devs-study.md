---
branch: docs/company-brain-non-devs-study
pr: pendente
date: 2026-11-11
reviewed_diff_sha256: 9811cba9cd83fb9d07700694f8ede1c47acc4058ead30ded46ec1d825654015f
reviewed_code_sha256: a971c3c29d47c81186b643671baed84d5f0cc4a7e0887f626d36c61fcf18e175
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

## Limites declarados

- Sem revisor independente. As evidências de sessões pares são testemunho, e estão marcadas assim na
  proveniência.
