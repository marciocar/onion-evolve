---
kg: docs/evolution/research/playbook-sdaal-2026-10/playbook-sdaal-2026-10.kg.yaml
run_id: wf_790beee5-fa8
tokens: 7275424
agents: 104
duration_min: 18
---

# SDAAL de playbooks (SAC-52): decisão aberta

Esta é a rodada `/onion-research` em modo `decision`. O grafo traz **1 nó de decisão aberto**,
`D_PLAYBOOK_SDAAL_SAC52`. Quem sela é o maestro; esta sessão não sela.

Números da rodada:

- 15 fontes lidas e 64 claims extraídas.
- Das 25 claims verificadas pela votação 3/2, 17 foram confirmadas e 8 refutadas.
- O Elenxo levantou 52 objeções e 45 sobreviveram. Delas, 28 viraram nós `CONSTRAINS` e 17 estão
  nomeadas em `E_LACUNAS_PLAYBOOK_SDAAL_1011`.
- O grafo tem 57 nós.
- O retorno completo está em `data/run-wf_790beee5-fa8.json`.

**A premissa da issue estava errada.** O SAC-52 diz que "o core não tem nenhum conceito de
playbook", mas o catálogo recognition-primed da `onion-patterns` existe desde o PR #164. Ele cobre o
trabalho do próprio Onion, não o domínio do adotante. É uma diferença de objeto, e não ausência.

## As opções

| | Opção |
|---|---|
| **A** | Não criar `.claude/utils/playbook/` com adapters por framework. O playbook de domínio vira um template (skill ou markdown com esquema) instanciado num PFR, com o estado na sessão e no KG. |
| **B** | A SDAAL completa nos 4 domínios, como a issue pede. |
| **C** | O CACAO v2.0 (OASIS) como primeiro adapter, na fatia de compliance e segurança. |
| **D** | Adiar com gate: ler antes o Arazzo 1.0.1, o runme e a especificação técnica do CACAO. |
| **E** | Unificar tudo no catálogo da `onion-patterns`. |

**Recomendação do Elenxo** (um agente, sem votação): ficar com **A**, mais o gate de **D**, e
rejeitar B e C por ora.

- **Framework é conteúdo, não provider com transporte.** Por isso não existe "adapter por
  framework": não há capacidade a declarar nem uma catraca no molde da REGRA 103 (Adapter do
  task-manager declara todas as capacidades da interface, com fonte).
- **O escopo assume 4 domínios peer.** Isso promoveria GTM a 4ª dimensão, que é decisão do maestro e
  não pode entrar pela porta dos fundos de uma issue.
- **Não há consumidor medido.** O único playbook de domínio vindo de um adotante coube no catálogo
  que já existe.
- **Plugins de primeira parte já entregam** skills de incidente e runbook. O capital de AI SRE ocupa
  o motor, e o diferencial do Onion é seleção, estado verificável e gate.
- **Sub-decisões:**
  - **(1)** o template se instancia num PFR. O estado é observado por hook, nunca autodeclarado, e o
    task manager é só projeção.
  - **(2)** a primeira fatia sai de um incidente real do próprio core, como o bypass do ufw na VPS,
    usando a NIST 800-61r3 como checklist.
  - **(3)** nada a costurar até ler o Arazzo e o runme.
  - **(4)** um formato, dois catálogos (o do Onion e o de domínio), com gatilho de frescor para os
    de domínio.

## Mercado

- **Engenharia e ops concentram o capital.** A categoria de AI SRE tem a Resolve AI (US$125M, fev/2026,
  TechCrunch) e a Traversal (Sequoia).
- **Em GTM, o conteúdo é proprietário.** O MEDDICC vive na plataforma mOS, sem formato aberto.
- **Em segurança, o formato aberto é institucional.** É o caso do CACAO, da OASIS e da OCA.
- **Não houve sinal de M&A nem rodada** sobre playbook executável agnóstico.

## NÃO-VERIFICADOS

- **Refutadas (8).** As mais relevantes são as do Temporal como substrato de processo vivo com estado,
  todas 1-2. Elas morreram por fonte e não por evidência contrária, então a pergunta "onde mora o
  estado" segue aberta.
- **Cortadas por orçamento (39 claims, 40 fontes).** As de relevância alta são a **Arazzo 1.0.1**, o
  **runme**, a **especificação técnica do CACAO v2.0**, o "playbook drift" e o Gartner Hype Cycle de
  automação agêntica. São exatamente o gate da opção D.
- **Recomendação do Elenxo truncada.** O prompt do write(KG) a cortou em 1.500 de 3.107 caracteres.
  O complemento foi relido do retorno e apendado ao `D_`. A causa é curada no #1036.

## valeu-a-pena

O run gastou 7.275.424 tokens para 57 nós, cerca de **128k por nó**.

Isso fica abaixo do SAC-70 (154k) e da varredura de decisão de setembro (291k). As lacunas agora têm
nome, então a revisita do gate D deve rodar no modo `primaries`.
