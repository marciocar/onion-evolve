---
branch: docs/seal-privilege-aws-1120
pr: pendente
date: 2026-11-20
reviewed_diff_sha256: 39aaea43138b6ebf4990f90ece4be312b9e4d7d1865e69d1414708bb820c07e0
reviewed_code_sha256: ceccff2aa903880b68e96fcd92e4450b91092ee2859ef80a2e3e0172b682066a
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 3
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: true
elenxo_isolado: false
reviewer: "Passada da própria sessão do core, só leitura: seis nós novos pelo kg-decide-seal (radar exit 0) com as respostas do maestro em 20/11 no /meta:decide (privilégio de quem pede, Drive, spike no Slack, sombra e recibo da migração do brain-granaai, dona dos repos de serviço)."
nota: "tokens 0 = não medido. Não toca guarda."
---

# Passada adversarial: `docs/seal-privilege-aws-1120`

## O que muda

Seis selos no grafo de selos de coordenação: token da pessoa só para ler e escrita como Brain (revisa a regra de 13/11,
com conexão super fácil); Drive por OAuth por pessoa; spike no Slack já; sombra passiva de 5 dias úteis e corte travado
pelo recibo na migração do brain-granaai para a AWS; repos de serviço da VPS com a vps-ops como dona.

## O que se tentou refutar

Algum selo afirma escolha que o maestro não fez? O da regra de 13/11 registra a opção 1 com o acréscimo dele («maneira
super fácil de conectar e ajudar»). O do recibo veio depois de ele perguntar o padrão de mercado e escolher a opção
recomendada na pergunta seguinte. Os nós vivem no grafo de coordenação porque o grafo do privilégio está no teto de nós.
