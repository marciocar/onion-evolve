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

## Gate D — rodada de primárias (2026-10-12, run `wf_5ceb8e1b-6d6`)

Custo: 643.690 tokens, 8 agentes e 7 min. Entraram 16 nós, cerca de **40k por nó** (o modo `primaries` custa ~1/3 da varredura). Retorno completo em `data/run-wf_5ceb8e1b-6d6.json`.

Fontes:
- **3 fontes, todas alcançadas:** Arazzo 1.0.1 (OAI), Runme e a especificação CACAO v2.0.
- **14 claims ancoradas** e **3 rejeitadas como EXAGERADAS.** Duas eram do Runme, sobre estado e aprovação; uma era do CACAO, sobre o passo humano.

O que a rodada sustenta, a favor da opção A já selada:
- **Arazzo:** é aberto (Apache-2.0) e tem bom vocabulário de sucesso e falha (`successCriteria`, `goto`/`end`/`retry`). Mas é **orquestração de API**: todo passo é uma operação, as expressões são HTTP, e não há passo humano nem estado de instância. O que se costura dele é o **JSON Schema 2020-12** das entradas e o vocabulário de critério, como inspiração nomeada.
- **Runme:** é **executor** de markdown em células, não formato de playbook. Pode ser, no máximo, um substrato de execução plugável.
- **CACAO:** é a forma de passos mais próxima de um playbook genérico (`if`/`while`/`switch`/`parallel`/`playbook-action`). Pesam contra ele:
  - o vocabulário de tipos é só de segurança;
  - está em CS01, parado desde 2023-11, com inconsistência interna 2.0/2.1;
  - o estado de execução fica fora da spec.

**Nenhum dos três cobre os seis eixos.** Em todos faltam aprovação humana e estado de instância especificados.

Reconciliação: as 3 objeções do Elenxo de 2026-10-11 do tipo "primária citada, não lida" passam a `superseded`, com `SUPERSEDES` a partir das evidências ancoradas. Agora as primárias foram lidas.

**Proposta aberta (não é selo):** `Q_SUBDECISAO_3_FECHAMENTO_1012` fecha a sub-decisão (3) como "nenhum formato aberto cobre os 6 eixos; o template em PFR declara o que pegou emprestado". Antes, faltam 3 leituras curtas: as notas da Arazzo 1.1.0, a doc do Runme sobre estado e aprovação, e o §3.1 do CACAO.

## Leituras da sub-decisão (3) (2026-10-12, rodada B)

As 3 leituras pedidas por `Q_SUBDECISAO_3_FECHAMENTO_1012` foram feitas à mão no modo primaries. Foram 9 documentos, 0 inalcançáveis e 10 claims ancoradas. As 21 citações foram reconferidas por busca literal no documento baixado, e todas foram encontradas. A contabilidade está em `E_LACUNAS_SUBDECISAO_3_1012B`.

- **Arazzo 1.1.0** (2026-05-17): as notas trazem AsyncAPI v3, JSONPath/XPath, `querystring`, `$self` e inputs em ações de sucesso e falha. **Nenhum item acrescenta passo humano, aprovação ou estado persistido.** No texto inteiro da 1.1.0, o passo continua sendo operação OpenAPI, operação AsyncAPI ou outro workflow.
- **Runme:**
  - `interactive` é entrada no terminal, não aprovação. A doc se contradiz no default: a tabela diz `false` e a seção diz `true`.
  - Os prompts são de variável (`promptEnv`) e de autenticação, mais uma pergunta antes do Run All no VS Code. `skipPrompts` desliga todos.
  - O estado entre células é o da sessão de terminal (`$__`, variáveis de ambiente).
  - **Nuance:** o *Session Outputs* é um **log persistido** de execução, com hora, duração e exit code por célula. Vem desligado por padrão e não deve ir para o versionamento. É registro, não estado retomável.
  - O `version` da Lifecycle Identity é a versão do Runme, não a do runbook.
- **CACAO §3.1:** `playbook_types` é **opcional** (SHOULD) e de **vocabulário aberto** (§10.13: qualquer string em minúsculas e com hífen). Usar CACAO fora de segurança **é válido na letra**, com duas condições:
  - valor similar existente é obrigatório (§2.1);
  - a spec se contradiz sobre exigir `playbook_activities`: a §3.1 a exige só quando o tipo vem da lista, a §3.2.2 a exige sempre.

  Correção da seção anterior: onde se lê "o vocabulário de tipos é só de segurança", leia-se "o vocabulário **sugerido** é só de segurança, e é aberto".

**Veredito: as leituras SUSTENTAM a proposta.** Nenhum formato aberto cobre os 6 eixos. Faltam, em todos, aprovação humana e estado de instância especificados. O template em PFR deve declarar dois empréstimos a mais:

- o log de execução do Runme, no eixo estado;
- o vocabulário aberto do CACAO como precedente de tipo de playbook extensível.

**O selo segue com o maestro.** `Q_SUBDECISAO_3_FECHAMENTO_1012` e `D_PLAYBOOK_SDAAL_SAC52` continuam `open`.
