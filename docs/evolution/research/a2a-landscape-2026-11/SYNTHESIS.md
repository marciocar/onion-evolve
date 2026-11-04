---
title: Panorama do A2A em novembro de 2026, com o Onion como lente
date: 2026-11-04
kg: docs/evolution/research/a2a-landscape-2026-11/a2a-landscape-2026-11.kg.yaml
run_id: wf_e7411d7e-52e
tokens: 9114365
agents: 125
duration_min: 17
review_after: 2026-12-04
type: research
mode: landscape
---

# Panorama do A2A em novembro de 2026

**A pergunta** (`Q_A2A_LANDSCAPE_2026_11`), feita pelo maestro em 2026-11-04: a nossa implementação do A2A pode
usar o Logto da VPS? Ainda é boa estratégia? Quem usa, quais são os caminhos consolidados e os cookbooks, e qual
é o mapa atual do A2A?

**Resposta curta:**
- **Estabilidade:** o A2A está estável e governado por uma fundação. A v1.0.0, primeira versão estável, saiu em
  12/03/2026, e a v1.0.1 em 28/05/2026. O projeto passou para a AAIF (Agentic AI Foundation) em 17/08/2026.
- **Autenticação:** fica fora do protocolo. O Agent Card declara esquemas no estilo OpenAPI, com Bearer, OAuth2
  (incluindo client credentials) e OIDC. Logo, um IdP OIDC self-hosted como o Logto pode emitir credenciais para
  agentes. Isso foi comprovado com o Keycloak e vale para o Logto por analogia, ainda sem medida.
- **Estratégia:** seguir o A2A é boa estratégia, e o que o Onion precisa é deixar de ser «perfil com semântica
  própria» nos pontos em que o padrão já tem resposta.

## O que o dado diz (26 achados confirmados, 4 refutados com superação)

| Eixo | Achado | Votos |
|---|---|---|
| Spec | v1.0.0 em 12/03/2026, a primeira estável e que quebra compatibilidade: `tasks/list`, multi-tenancy, negociação de versão, Signed Agent Cards | 3-0 |
| Spec | Última release visível: v1.0.1 (28/05/2026). Nada depois foi verificado | 2-1 |
| Spec | O `a2a.proto` (package `lf.a2a.v1`) é a fonte normativa, e a versão se declara por interface | 3-0 |
| Spec | Três bindings: JSON-RPC sobre HTTP/SSE, gRPC e REST. `GetTask`, `ListTasks` e `CancelTask` são RPCs da spec | 3-0 |
| Spec | O push é capacidade **opcional** (`C_SUPERACAO_20261104_PUSH_OPTIONAL_CAPABILITY`): o Onion fica conforme ao declarar `pushNotifications: false` | superação |
| Autenticação | `security_schemes` no estilo OpenAPI: API key, HTTP Bearer/Basic, OAuth2 (PKCE, client credentials, device code), OIDC e mTLS. Implicit e password ficaram depreciados, não removidos | 3-0 |
| Autenticação | Signed Agent Card = JWS (RFC 7515) sobre a forma canônica JCS (RFC 8785), com a chave por `jku` ou keystore | 3-0 |
| Autenticação | A assinatura prova a integridade do card, não a confiança no agente nem cada requisição; a autorização é do servidor | 3-0 (vendor) |
| Autenticação | Um IdP OIDC self-hosted (Keycloak) emite `client_credentials` para um servidor A2A (Quarkus) | 3-0 |
| Autenticação | AWS Bedrock AgentCore: o runtime com OAuth responde 401 e anuncia o servidor de autorização; com SigV4, nega sem cabeçalho | 3-0 |
| Gate humano | `TaskState` tem `INPUT_REQUIRED` e `AUTH_REQUIRED`, estados nativos para a pausa de aprovação. A spec não define JWT, `body_sha256`, `jti` nem gate humano | 3-0 |
| Governança | Hospedado pela AAIF desde 17/08/2026, depois de ter sido doado à Linux Foundation com AWS, Cisco, Microsoft, Salesforce, SAP e ServiceNow | 3-0 |
| Adoção | Mais de 150 organizações apoiam o A2A. Em produção: Huawei (HarmonyOS/Celia) e o WeChat da Tencent; nas três nuvens grandes | 3-0 |
| Segurança | Uma análise formal da spec (arXiv 2609.10871) achou 11 vulnerabilidades exploráveis por quem segue a spec, entre elas a injeção por `contextId` | 3-0 / 2-1 |
| Analistas | Thoughtworks Radar: Assess em 2025-11; o blip saiu da edição atual | 3-0 |

## O perfil Onion A2A diante da spec

O quadro abaixo projeta o corpus (`a2a-configurator-2026-10`, `a2a-cross-user-spike-2026-10`,
`a2a-empresa-adotante-2026-10`) sobre os achados.

| Peça do Onion | Na spec | Leitura |
|---|---|---|
| Convite com bearer | HTTP Bearer é nativo | **igual, transfere**. O bearer sem dono nem validade (`E_LACUNAS_DO_A2A_MEDIDAS`) é que é dívida |
| JWT RS256 assinado pelo remetente | Bearer com formato JWT, ou OIDC | **igual na forma** |
| `body_sha256` e `jti` anti-replay | não existem | **cunhagem do Onion**: declarar como extensão A2A (URI no Agent Card), como a seção 7.6.4 pede |
| Fila com aceite humano | `INPUT_REQUIRED` / `AUTH_REQUIRED` | **mapeável**: o estado já existe, falta expor a fila como Task |
| Sem `tasks/get`, `ListTasks`, `CancelTask` | RPCs da spec | **lacuna confirmada** |
| Sem push | opcional | **conforme**, desde que declarado no card |
| Sem Signed Agent Card | v1.0 | **lacuna**: o keygen já gera o par RS256 que poderia assinar |

## Mercado e capital

- **Capital:** nenhum sinal direto, nem rodada, nem M&A, nem valuation ligados ao A2A. O dinheiro corre pelas
  plataformas (nuvens, gateways e IdPs), e o protocolo é um bem comum de fundação.
- **Adoção institucional:** forte. São mais de 150 organizações, as três nuvens grandes e produção de consumo de
  massa na China.
- **Analistas:** o Thoughtworks só deu Assess, e não há sinal de Gartner ou Forrester no material verificado.

## Perguntas abertas, que viram candidatas a decisão ou spike

1. Fazer do `body_sha256` e do `jti` uma extensão A2A declarada.
2. Trocar o convite com bearer sem dono por `client_credentials` por membro, emitido pelo **Logto da VPS** e
   declarado como esquema OAuth2/OIDC no Agent Card. É o **spike recomendado**, porque responde à pergunta do
   maestro com medida.
3. Implementar `GetTask`, `ListTasks` e `CancelTask` no onion-bridge, expondo a fila como `INPUT_REQUIRED`.
4. Assinar o Agent Card com o par RS256 do keygen, e decidir a política de confiança (`jku` ou keystore no
   `members.yaml`).
5. Conferir quais das 11 vulnerabilidades do arXiv 2609.10871 atingem o perfil Onion, a começar pelo `contextId`.
6. Identificar a pessoa por trás do agente (on-behalf-of, token exchange RFC 8693). A spec cobre só o agente.
7. A composição A2A+MCP e os SDKs dominantes ficaram sem achado confirmado nesta rodada (ver abaixo).

## NÃO-VERIFICADOS

- **50 claims cortadas pelo orçamento de verificação** (`maxVerify` 30) e **31 fontes cortadas pelo de busca**
  (`maxFetch` 20). Entre elas estão os SDKs (Python, JS, Java, Go, .NET), o cliente Java com Keycloak, a demo entre
  nuvens na v1.0, o cabeçalho `A2A-Version` e a federação OIDC do Google com a AWS.
- **O eixo 3** (cookbooks, composição com MCP, frameworks como ADK, LangGraph e CrewAI) ficou **sem achado
  confirmado**. Pede uma rodada `primaries` com essas fontes nomeadas.
- **Versões:** não foi verificado se saiu uma 1.1 ou algum rascunho entre junho e novembro de 2026.
- **Logto:** não houve fonte direta. A capacidade M2M dele, o formato do token e a integração com o bridge não
  foram medidos.
- **Escala dos casos de produção:** foi declarada pelas próprias fundações, sem métrica independente.
- **Quatro refutações**, todas com superação e nenhuma por fonte fraca:
  - push «obrigatório» → opcional;
  - OAuth implicit e password «removidos» → depreciados;
  - «lacuna de input_required» → a lacuna é de consulta (`GetTask`);
  - suporte do gateway AISIX à 0.3 e à 1.0 → só autodeclarado pelo fornecedor.

## Valeu a pena

São 9,1 milhões de tokens, 125 agentes e 17 minutos, para 33 nós, cerca de 276 mil tokens por nó: no patamar da
varredura larga. O ganho foi o mapa da spec com a fonte normativa e as superações que corrigem quatro leituras
comuns. Os eixos de SDK e cookbook pedem a rodada `primaries`, que custa cerca de 42 mil tokens por nó.
