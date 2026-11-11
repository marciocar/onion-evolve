# Deriva de API dos 6 canais do vigia (2025-11-11 a 2026-11-11)

Medido em 2026-11-11, só changelogs oficiais lidos por WebFetch (resumos de página, não o HTML cru). Nenhuma escrita no repositório.

## 1. Os 6 canais

Fonte: `event-watcher-vendor-2026-11.kg.yaml` (curadoria, origin/main), nós E_EWV_V2_CHANNELS e Q_EWV_WHATSAPP_ONION_EVOLVE, e `evidence/research-v2-channels.md` ("os seis canais", tabela canal x verificação). O pedido cita 5 provedores; o sexto canal vem do WhatsApp em duas formas, e a tabela da curadoria lista:

1. Slack (Events API / Socket Mode)
2. WhatsApp Cloud API (Meta)
3. WAHA (WhatsApp não oficial)
4. ClickUp
5. Microsoft Teams via Graph (change notifications)
6. Linear

(O grep `seis canais|6 canais` em `onion-evolve/docs/evolution/research` não achou arquivo; a fonte é só a curadoria. Quem escolhe Cloud API ou WAHA é o maestro, pergunta Q_EWV_WHATSAPP_ONION_EVOLVE; contei os dois.)

## 2. Régua de contagem

- **Estrito (webhook/evento)**: mudança que o coletor sente ao RECEBER: payload, cabeçalho, assinatura, limite de entrega, formato de id, evento que deixa de existir. Inclui as marcadas "breaking" e as "possivelmente quebra" quando afetam o receptor.
- **Amplo**: estrito + quebras de API geral do provedor (campos removidos, versão desativada, escopo) que um coletor que também consulta a API sentiria. Exclui MCP do Linear (o Onion não o usa no coletor): 5 quebras de MCP ficam fora.
- 1 quebra = 1 ponto (sem ajuste). Trimestre = quebras / 4.

## 3. Tabela por provedor

| Canal | Quebras estrito | Quebras amplo | Aditivas (webhook/evento) | Pontos/trim. estrito | Pontos/trim. amplo |
|---|---|---|---|---|---|
| Slack | 1 (2026-06-17) | 1 | 1 (2026-02-05) | 0,25 | 0,25 |
| WhatsApp Cloud API (Meta) | 0 | 3 (sunsets Graph) | 1 (2025-11-25) | 0 | 0,75 |
| WAHA | 2 | 6 | 12 | 0,5 | 1,5 |
| ClickUp | 0 (sem dado) | 0 (sem dado) | n/d | n/d | n/d |
| Teams / Graph | 0 (lido parcialmente) | 0 | 3 (Mar, Ago, Set 2026) | 0 | 0 |
| Linear | 2 | 10 | 11 | 0,5 | 2,5 |
| **Total** | **5** | **20** | **28+** | **1,25** | **5,0** |

### Quebras citadas (data e URL)

**Slack** (arquivo do changelog lido inteiro: 57 entradas, só títulos)
- Quebra: 2026-06-17, mensagens de sistema (entrada/saída de membro, grupos) passam a vir do usuário `USLACK` em vez do Slackbot; quem filtra pelo id do Slackbot quebra. https://docs.slack.dev/changelog/tags/breaking-change (entrada /changelog/2026/06/17/system-notifications). Marginal para um vigia.
- Aditiva: 2026-02-05 "Retry delayed events" (/changelog/2026/02/05/retry-events-feature). Sem alteração de assinatura, de Socket Mode ou de tipo de evento no período.
- Neutra: 2025-12-08 "Classic apps deprecation paused" (a retirada que cortaria eventos em 2026-11-16 foi suspensa). https://docs.slack.dev/changelog/archive

**WhatsApp Cloud API (Meta)**
- Webhooks: nenhuma quebra no changelog da Cloud API; última entrada 2026-05-12, sem relação com webhook. Aditiva: 2025-11-25, eventos de edição e revogação de mensagem (Coexistence). A mudança de payload de 2025-11-03 (status `played`) cai fora da janela. https://developers.facebook.com/docs/whatsapp/cloud-api/changelog
- Amplo (versão desativada): Graph v18 em 2026-01-26, v19 em 2026-05-21, v20 em 2026-09-24; v25 lançada 2026-02-18 e v26 em 2026-07-29. https://developers.facebook.com/docs/graph-api/changelog. Só quebra o coletor se ele fixa versão para enviar ou consultar; o recebimento segue a versão configurada no app.

**WAHA** (releases do GitHub; datas de página, sem rótulo oficial de breaking)
- Estrito 1: 2025-12-01 (2025.11.4), `requestId` do webhook do GOWS passa a `uniqid`: quebra a deduplicação por formato de id. https://github.com/devlikeapro/waha/releases
- Estrito 2: 2026-09-01 (2026.8.2), `url` de mídia vira `null` quando não baixada e `mimetype`/`filename` sempre presentes.
- Possíveis, não contadas no estrito: 2026-02-02 (2026.2.1) GOWS deixa de emitir eventos AppState; 2026-01-12 (2026.1.2) Core deixa de emitir `session.status` duplicado; 2025-12-17 webhook passa a ignorar erros de SSL.
- Amplo (+4): 2026-10-28 (2026.10.1) `POST /api/{session}/events` valida `event`, e rejeita `x-api-key` não string; 2026-05-26 (2026.5.1) `chats/overview` exige paginação; 2026-02-18 (2026.2.2) endurece autenticação e guarda do WebSocket.
- Sem mudança de HMAC em nenhuma versão lida.

**ClickUp**
- Sem changelog público de API achado (developer.clickup.com/changelog e /docs/changelog dão 404; a busca não achou página). Não confirmei nenhuma quebra; não equivale a zero. Ver seção 6.

**Teams / Graph** (change notifications)
- Nenhuma quebra de notificação nas entradas lidas (2026-02 a 2026-11). Aditivas: 2026-03 transcrições e gravações de chamadas ad hoc; 2026-08 entrega a endpoints Web Push; 2026-09 `unknownFutureValue` em `changeType` (v1.0). https://learn.microsoft.com/en-us/graph/whats-new-overview e https://learn.microsoft.com/en-us/graph/whats-new-earlier
- A última quebra de notificação achada, presença e reuniões sem `resourceData`, é de 2024-09-01 (fora da janela). https://devblogs.microsoft.com/microsoft365dev/breaking-changes-to-microsoft-graph-presence-and-online-meeting-basic-change-notifications/

**Linear** (https://linear.app/changelog, páginas 1 a 4; ver lacunas)
- Estrito: 2026-01-22 `userId` de `AgentActivityWebhookPayload` deixa de ser nulo; 2026-10-08 cotas de webhook (30 por time, 50 por workspace).
- Operacional, não contada: novos IPs de saída de webhook (sem data, entre 2026-09-03 e 2026-09-14), pede atualização de allowlist.
- Amplo (+8, API geral): 2026-02-13 remoção de `CustomerNeed.url`; 2026-03-24 iniciativas com múltiplos pais e validação estrita de templates; 2026-05-21 `/oauth/migrate_old_token` devolve 410; 2026-06-18 `templateCreate/Update` rejeitam campos; 2026-10-08 PKCE exige S256; 2026-11-05 erro de rate limit passa de HTTP 400 a 429 e limite de 200 comentários por minuto por issue; (+ `airbyteIntegrationConnect`, 2026-11-05, contada no amplo.)
- Fora da conta (MCP): `/sse` removido 2026-02-05, `save_issue` unificado 2026-02-26, e duas de 2026-05-14.
- Aditivas de webhook (11): ProjectLabel 2025-12-04; promptContext 2025-12-17; `user` no AgentActivity e rotação de segredo de assinatura 2026-01-22; milestone/relation e `diffMarkdown` 2026-02-26; retry de delegação 2026-04-23; ator externo e `url` em remoções 2026-07-02; `documentCreated` 2026-11-05.

## 4. Total e comparação

| | Quebras/ano | Pontos/trimestre |
|---|---|---|
| Medido, estrito | 5 | **1,25** |
| Medido, amplo | 20 | **5,0** |
| Estimativa sem medida | n/d | 5 a 7 |

Os 5 pontos do amplo vêm 50% do Linear e 30% do WAHA; os dois canais com changelog mais rico são os que mais "quebram", e Slack, Meta e Graph quase não quebram webhook num ano. O custo inicial (2 a 3 pontos por canal, 12 a 18 no total) não foi medido aqui.

## 5. Veredito do portão

**TOLERÁVEL.** O pior cenário medido (amplo, 5,0 pontos por trimestre) fica no piso da faixa estimada (5 a 7), e o estrito (1,25) fica bem abaixo. Mesmo supondo 2 quebras por ano em cada um dos canais sem dado (ClickUp, Teams), soma-se 1 ponto por trimestre no amplo, 6,0, ainda dentro da faixa. O portão não reprova o coletor próprio por custo de deriva. Ressalva: o veredito vale para o dado lido, com as lacunas da seção abaixo; a quebra que mais custa (mudança de assinatura ou de cabeçalho) não ocorreu em nenhum canal no ano.

## 6. NÃO-VERIFICADOS

- **ClickUp**: sem changelog público de API achado (404 nas duas URLs; só a busca, sem página oficial de mudanças). Zero quebras aqui é ausência de dado, não de mudança.
- **Teams / Graph**: lidos Jun a Nov 2026 e Fev a Mai 2026 (whats-new); **não lidos** Nov 2025 a Jan 2026 (o histórico tem 936 mil caracteres, li os primeiros 200 mil). O API changelog (developer.microsoft.com/graph/changelog) devolveu só navegação. Não li "subscription lifecycle" nem Bot Framework/outgoing webhook do Teams.
- **Linear**: a página 4 cobre 2025-11-13 a 2025-12-17 e a página 3 começa em 2026-01-22: **faltam 2025-12-18 a 2026-01-21**. Datas de itens sem cabeçalho próprio foram atribuídas ao cabeçalho de data mais próximo. Há inconsistência de datas entre `linear.app/changelog` e `linear.app/now`; usei a primeira e citei a segunda só para novembro.
- **WAHA**: nenhum dado de 2025-11-11 a 2025-11-13 (a 2025.11.1 não aparece); changelog oficial em waha.devlike.pro deu 404, usei o GitHub. Rótulo de "quebra" é inferência minha; o projeto não os marca. WAHA Plus x Core não distinguido.
- **Meta / WhatsApp**: o resumo diz que a última entrada é de 2026-05-12; não li as páginas de Instagram e Messenger. O conflito de retries (36 h contra 7 dias) segue em aberto na curadoria.
- **Slack**: arquivo lido só por título e URL; "Retry delayed events" classificada como aditiva por inferência do título. A data de corte das classic apps é conflitante entre fontes (suspensa em 2025-12-08).
- Os changelogs foram lidos por um modelo que resume páginas; nenhuma entrada foi conferida no HTML cru. Eventos fora de changelog (mudança sem aviso, hotfix) não aparecem em nenhuma fonte.
- Não medi o custo de 1ª construção por canal nem pontos reais por quebra: 1 quebra = 1 ponto é premissa do pedido.
