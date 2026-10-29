---
title: "Plano do spike: o Onion por MCP num agente do Copilot Studio"
date: 2026-10-29
type: plan
status: proposto (a execução depende de autorização do maestro)
kg: docs/evolution/research/spike-copilot-studio-mcp-2026-10/spike-copilot-studio-mcp-2026-10.kg.yaml
---

# Plano do spike: o Onion por MCP num agente do Copilot Studio

**Pergunta do spike:** um agente do Copilot Studio consegue chamar os servidores MCP do Onion, e o veredito
determinístico do gate volta intacto ao usuário? Se sim, o Company Brain governado pode ter o Copilot como canal,
além do LibreChat.

> **Projeção do grafo.** A fonte é
> [`spike-copilot-studio-mcp-2026-10.kg.yaml`](spike-copilot-studio-mcp-2026-10.kg.yaml): cada linha [DOC] da
> tabela 1 é um nó `E_CS_*` com URL e `verified_at`; a autorização é `Q_SPIKE_COPILOT_STUDIO_MCP`; o furo da §3
> é `Q_RECUSA_DO_CHECKLIST_PELO_SCHEMA_OU_GUARDA`; a opção 1 de identidade da §2 é
> `C_IDENTIDADE_POR_CHAVE_POR_USUARIO`. Se este texto divergir do grafo, vale o grafo.

Legenda: **[EXISTE]** = caminho no repo ou fato medido; **[DOC]** = doc primária da Microsoft, lida em 2026-10-29;
**[INFERÊNCIA]** = conclusão minha, a testar.

## 0. Pré-condição: é uma decisão do maestro

- [EXISTE] A `D_ONION_BRAIN_MCP_REMOTO`, em
  `docs/evolution/research/onion-brain-mcp-remoto-2026-10/onion-brain-mcp-remoto-2026-10.kg.yaml`, foi selada em
  2026-10-12 em dois degraus. O **degrau 1** é rede privada, via LibreChat. O **degrau 2** é um endpoint público
  com TLS e o servidor como resource server OAuth 2.1 por org, e só vale **"quando houver demanda medida"**.
- [INFERÊNCIA] O Copilot Studio é um serviço de nuvem e só alcança o que está na internet. A doc não diz "precisa
  ser público", mas todos os exemplos usam `https://<host>/mcp`. **Este spike é, portanto, um degrau 2 de teste.**
  O maestro decide se o caso de consultoria conta como a demanda medida.
- [EXISTE] A decisão de 2026-05-18 é ficar só no Claude Code (`C_POSTURA_ACOPLAMENTO`, `C_CORE_NAO_E_FAMILIA`). O
  spike **não** a reabre. O servidor MCP é a metade agnóstica do Onion: stdlib, protocolo aberto e o veto dentro do
  próprio servidor. O que fica no Claude Code continua lá.

## 1. Pré-requisitos medidos na doc primária

| Item | Fato | Fonte |
|---|---|---|
| Suporte a MCP | [DOC] GA desde 2025-05-29. Hoje é recurso normal, para agentes do "standard harness". | blog de GA; learn: agent-extend-action-mcp (2026-08-26) |
| Transporte | [DOC] **Só Streamable HTTP**: "Copilot Studio no longer supports SSE for MCP after August 2025". | learn: mcp-add-existing-server-to-agent (2026-05-28) |
| Como ligar | [DOC] Pelo assistente (Tools > Add a tool > New tool > Model Context Protocol: nome, descrição e URL) ou por conector personalizado (Swagger 2.0 com `x-ms-agentic-protocol: mcp-streamable-1.0`). | idem |
| Autenticação | [DOC] None, **API key** (no header ou na query, **com nome livre**, "the user of the agent provides the API key") ou OAuth 2.0 (dynamic discovery, dynamic ou manual). Não achei tipo "Entra ID" dedicado. | idem |
| Identidade do usuário | [DOC] No OAuth, o token é delegado: "on behalf of the user". **Nenhum header com a identidade do usuário é documentado.** | idem |
| Orquestração | [DOC] "You must turn on generative orchestration to use MCP." | agent-extend-action-mcp |
| Primitivas | [DOC] Tools e resources; **prompts não**. O resource só vale como saída de uma tool. | mcp-add-components-to-agent (2026-05-15) |
| Licença de teste | [DOC] O trial cria e testa agentes no painel de teste, mas **não publica**. Exige conta de trabalho ou escola. O plano Teams/M365 não tem orquestração generativa nem conectores. | requirements-licensing-subscriptions (2026-10-27) |
| Cotas | [DOC] Ambiente trial ou dev: 10 mensagens de IA generativa por minuto e 200 por hora. O payload de conector vai até 5 MB. | requirements-quotas (2026-10-27) |
| DLP | [DOC] A política de dados dos conectores do Power Platform **também rege o MCP**. | mcp-add-existing-server-to-agent |
| Schema | [DOC] Há limitações: `exclusiveMinimum` inteiro quebra, tipo em array é truncado, input por referência é filtrado e enum vira string. | mcp-troubleshooting |
| Publicar no M365 Copilot e no Teams | [DOC] Possível pelo canal "Teams and Microsoft Copilot". [INFERÊNCIA] As tools MCP rodam quando o agente é invocado; a página não fala de MCP. | publication-add-bot-to-microsoft-teams (2026-10-20) |

## 2. Qual servidor usar e onde ele roda

- [EXISTE] O **`ops/mcp-onion-kg-writer/server.py`** é o alvo. Ele usa Streamable HTTP stateless, que é o único
  transporte que o Studio aceita.
  - Tools: `kg_validate` (dry-run do radar e do contrato), `kg_write` (só grava com APROVADO, num commit com autor
    igual ao e-mail), `kg_delete`, `kg_schema_help` e as de leitura da área.
  - A autenticação usa o header `X-Api-Key`, que o Studio envia, porque o nome do header é livre.
- [EXISTE] O **`ops/mcp-onion-kg/server.py`** é só leitura, também com `X-Api-Key`. Entra como 2ª conexão, se a
  consulta precisar do corpus inteiro.
- [EXISTE] O **`vendor/kg-ssot/tools/kg_mcp.py`** é a peça do produto, que grava só com PASS do contrato.
  - Não é o alvo: falta o radar e a área por usuário que o writer do core soma.
- **O furo de identidade:** o writer exige `X-User-Email`, um header por usuário que o LibreChat preenche e o
  Copilot Studio não preenche ([DOC]: nenhum header de identidade).
  - Opção 1 do spike, sem OAuth: **uma API key por usuário**. A doc diz que quem fornece a chave é o usuário do
    agente. O servidor do spike mapeia a chave para o e-mail, e o autor do commit sai da chave, não de um header
    livre. É uma mudança pequena, só na instância do spike, atrás de uma variável. [INFERÊNCIA: a medir]
  - Opção 2: OAuth 2.0 manual com o Logto, que é o desenho do degrau 2, com o servidor validando o JWT. O custo é
    maior, e ela fica como 2º passo, se a opção 1 passar.
- **Onde roda:** uma **instância separada só do spike** na VPS.
  - Área de dados sintética própria, fora de `/var/lib/onion-chat-kg` de produção.
  - Exposta por um vhost no Caddy (`https://<sub>.onionevolve.com/mcp`) com TLS, mais um token de spike. O DNS e o
    vhost têm precedente na autorização de 2026-10-22 e são ato do maestro.
  - Desligada no fim do spike.
- **Risco da exposição:**
  - endpoint público com escrita;
  - nesta VPS, o Docker fura o ufw;
  - token vazado vira escrita no grafo de teste.
  - Mitigação [PLANO]:
    - dados só sintéticos e servidor de uso único;
    - chaves com prazo;
    - rate limit no Caddy;
    - restringir a origem às faixas de saída do Power Platform, se a Microsoft publicar essas faixas (a confirmar);
    - log de cada chamada;
    - revogar e derrubar no fim.

## 3. Grafo-semente genérico (sem nada de cliente)

Um `.kg.yaml` de exemplo, "avaliação de iniciativa de IA", com:

- `rule` (camada domain): `R_CHECKLIST_IA_*`, um por item. Exemplos:
  - dado pessoal identificado e com base legal;
  - dono do processo nomeado;
  - avaliação de risco feita;
  - humano no loop para decisão com efeito externo;
  - fornecedor e modelo declarados;
  - plano de desligamento.
- Uma `entity` "iniciativa" com os campos que o checklist cobra.
- Duas iniciativas de exemplo:
  - uma completa, que o gate deve **aceitar**;
  - uma sem dono e sem base legal, que o gate deve **recusar**.

Pergunta em aberto [INFERÊNCIA]: hoje o radar e o contrato julgam a **forma** do grafo, como nó sem trace, aresta
pendente e campo obrigatório. Eles **não** julgam o checklist de negócio. Para a recusa (c) sair do checklist, há
dois caminhos:

- (i) modelar o item obrigatório como campo exigido pelo schema da entidade, se o contrato v4.18 permitir;
- (ii) escrever uma guarda nova no writer da instância do spike.

**Isto é o 1º item a medir antes do dia do spike**, porque decide se a recusa é do gate que já existe ou de código
novo.

## 4. Roteiro de teste, com critério de PASSA ou FALHA

| # | Passo | PASSA | FALHA |
|---|---|---|---|
| a | No painel de teste do agente: "quais itens o checklist exige?" | o agente chama a tool e responde com os `R_` do grafo, citando os ids | não chama a tool, ou responde de memória |
| b | Registrar a iniciativa completa | `kg_write` devolve `APROVADO`, com `commit` e `autor` iguais ao e-mail mapeado da chave do usuário, e o `git log` da área confirma | grava sem veredito, ou com o autor errado |
| c | Registrar a iniciativa incompleta | `kg_write` devolve `REPROVADO`, `isError: true` e as linhas do motivo; **o usuário vê o motivo no chat**; o disco não muda | o agente esconde o erro, inventa sucesso, ou algo é gravado |
| d | Identidade | dois usuários com chaves diferentes geram dois autores diferentes; uma chave inválida é recusada | os dois aparecem com o mesmo autor, ou a chave não chega |
| e | Opcional: publicar no Copilot do M365 e repetir (a) | a tool roda invocada por @ | sem licença de publicação, sai como "não medido" |

## 5. Esforço, riscos e o que fica fora

- **Esforço [INFERÊNCIA]:**
  - meio dia de preparo no core: a instância do spike, o mapeamento chave→e-mail atrás de variável, o grafo-semente
    e a medida da recusa por schema;
  - meio dia do maestro e de quem tem o tenant: trial do Copilot Studio com conta de trabalho, DNS e vhost, criação
    do agente e execução do roteiro.
- **Riscos:**
  - a identidade: sem header, ela sai pela chave por usuário ou pelo OAuth;
  - o endpoint público;
  - a cota de 10 mensagens por minuto no trial;
  - limitações de schema nas tools: o schema de entrada do writer tem de passar pelo filtro do Studio, e isso se
    mede no item a;
  - o trial não publica, então o item (e) pode ficar sem medida;
  - o DLP do tenant pode barrar o conector.
- **Fora, explicitamente:**
  - os comandos, os hooks com veto `exit 2`, os subagentes, o Workflow e a injeção de contexto, que continuam só no
    Claude Code;
  - o OAuth e o Entra ID de produção;
  - qualquer dado de cliente;
  - o porte do `onion-plugins` para o VS Code.

## 6. Registro

Este plano entra no core como `docs/evolution/research/spike-copilot-studio-mcp-2026-10/` com:

- um grafo pequeno, com as evidências [DOC] acima, cada uma com URL e data;
- um nó `Q_SPIKE_COPILOT_STUDIO_MCP` aberto, de autorização do maestro;
- um nó `Q_RECUSA_DO_CHECKLIST_PELO_SCHEMA_OU_GUARDA` aberto, o furo da §3 a medir antes;
- um nó `C_IDENTIDADE_POR_CHAVE_POR_USUARIO`, a inferência da opção 1 de identidade, aberta;
- `external_edges` para `D_ONION_BRAIN_MCP_REMOTO` (é o degrau 2) e para `C_POSTURA_ACOPLAMENTO` (não reabre a
  decisão de 2026-05-18).
