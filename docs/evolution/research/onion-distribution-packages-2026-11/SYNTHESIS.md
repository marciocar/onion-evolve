---
title: Distribuição do Onion — pacotes, MCP ou portas e marketplace
date: 2026-11-05
kg: docs/evolution/research/onion-distribution-packages-2026-11/onion-distribution-packages-2026-11.kg.yaml
run_id: wf_615a4f2b-024
tokens: 0
agents: 106
duration_min: 0
review_after: 2026-12-05
type: decision
mode: decision
---

# Distribuição do Onion — pacotes, MCP ou portas e marketplace

**A pergunta:** distribuir o Onion também como pacote npm, pacote Python e servidor MCP, ou manter as portas e o marketplace?

**O selo do maestro** (`D_ONION_DISTRIBUTION_CHANNELS_2026_11`, 2026-11-05): "Diretório e parque". Mantém as portas e o marketplace, candidata `onion-plugins` ao diretório oficial e mede as portas. npm, MCP e MCPB ficam em parque com gatilho; PyPI fica fora.

## Achados

- O plugin já entrega hooks, comandos, agentes e skills pelo marketplace, sem pacote.
- O npm é fonte aceita de plugin, mas nenhuma das 315 entradas do marketplace oficial o usa (medido em 2026-11-05). O PyPI não é fonte.
- Worm em npm e PyPI em 2026, por fontes secundárias: mais de 170 pacotes em maio e 2.225 versões em agosto.
- Adoção por canal é o ponto fraco: há só `bmad-method` (23.215) e `task-master-ai` (12.484) em downloads semanais, sem número de plugin para comparar.
- Tráfego das portas em 14 dias (`E_TRAFEGO_DAS_PORTAS_1105`): cerca de 100 clones únicos em cada uma, com números quase iguais, e 1 visitante único no `onion-plugins`. A forma sugere robô ou maquinaria própria; a origem não foi verificada, logo não serve de base para gatilho.

## Gatilhos propostos, não medidos

- **npm como fonte de plugin:** 2 adotantes distintos relatam que o caminho git não serve no ambiente deles.
- **npm como instalador fino:** o degrau anterior não resolve o caso medido; reabre a decisão "sem CLI standalone".
- **Servidor MCP só de leitura e veredito:** consumidor real fora do harness que precise do veredito e não possa rodar o shell. Não entrega veto.
- **PyPI:** só com biblioteca Python e consumidor real.

## NÃO-VERIFICADOS

- `unverified` do retorno: vazio. `notVerifiedByBudget` e `budgetDropped`: nomeados no retorno do run, entre eles a API de estatísticas do PyPI e a do GitHub para o spec-kit.
- Refutadas por voto: entre elas, a leitura do Radar sobre "MCP by default" (0-3).
- Não cobertos: contêiner, MCPB além da licença, spec-kit, SuperClaude, Agent OS, instalações de plugin, quem paga pelo canal. Custo contínuo de manutenção não medido.
- A premissa "pacote Python do kg-ssot" não se confirma: o repo tem `package.json` em quatro pontos e nenhum `pyproject.toml` nem `server.json` rastreado. Publicação desses pacotes não verificada.

## valeu-a-pena

`tokens` e `duration_min` em 0 = não medidos: o run atravessou a queda de uma sessão, e o journal não traz contagem. 106 agentes para 105 nós. Decidiu a pergunta, mas não respondeu qual canal concentra adoção.
