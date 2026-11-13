# Backlog vivo — projeção dos grafos ⚙️ GERADO

> Gerado por `.claude/validation/kg-backlog-project.sh` a partir dos nós `status: open` da
> camada canônica (`docs/onion/graph/`, exceto arquivos opt-OUT) + grafos marcados. **Não editar à mão**: feche o
> item no grafo (status ≠ open, com carimbo) e ele sai daqui. Ordem = atenção (a régua do
> radar: impact × incerteza × status). Sem corte NO ESCOPO; 2 grafo(s) de arquivo (opt-OUT) ficam fora — visíveis via `kg-radar --open-tsv`.

## agent-requester-privilege-2026-11 — 17 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 207.0 | `Q_AGENT_REQUESTER_PRIVILEGE_1113` | agent-requester-privilege-2026-11 | Como um agente que atende várias pessoas (ex.: bot de Slack) age com o privilégio de quem pediu, e não com um privilégio próp |
| 60.0 | `C_ELENXO_RECOMMENDATION_1113` | agent-requester-privilege-2026-11 | Recomendação do Elenxo: delegação (sub=solicitante, act=agente), nunca impersonation; autorização a jusante; aprovação hum |
| 22.0 | `C_LESSER_OF_AGENT_AND_REQUESTER_1113` | agent-requester-privilege-2026-11 | Hipótese da pergunta: privilégio efetivo = menor entre agente e solicitante é o padrão de 2026. Sustentada como prática de me |
| 15.6 | `C_AUDIT_KIT_NORMATIVE_BASIS_1113` | agent-requester-privilege-2026-11 | Hipótese da pergunta: aprovação por papel e o kit de auditoria (política, inventário de contas, matriz de papéis, log por at |
| 3.0 | `C_SUPERACAO_20261113_ASI08_PER_ACT_LOG` | agent-requester-privilege-2026-11 | A trilha por ato vem do log, não do token: OWASP ASI08 item 10 pede logs à prova de adulteração, com carimbo de tempo, ligados |
| 3.0 | `C_SUPERACAO_20261113_HARDY_CLAUSE_VS_RESTRICTION` | agent-requester-privilege-2026-11 | Hardy, no mesmo parágrafo: cada cláusula nova abria falha de segurança em programa seguro, cada restrição nova quebrava progr |
| 3.0 | `C_SUPERACAO_20261113_HARDY_EXPLICIT_DESIGNATION` | agent-requester-privilege-2026-11 | Hardy, mesmo trecho: a cura é a designação explícita por ato; o deputado usa capability PRÓPRIA para os recursos dele (STAT)  |
| 3.0 | `C_SUPERACAO_20261113_ISO_5_15_FORMAL_APPROVAL` | agent-requester-privilege-2026-11 | INTERPRETAÇÃO DE GUIA (isms.online, 5.15): autorização formal e documentada, dada pelo pessoal apropriado. Ler isso como 'apro |
| 3.0 | `C_SUPERACAO_20261113_ISO_5_15_POLICY_REVIEWED` | agent-requester-privilege-2026-11 | INTERPRETAÇÃO DE GUIA (isms.online, 5.15, seção 'Access Control Policy'): a política de controle de acesso é desenvolvida, d |
| 3.0 | `C_SUPERACAO_20261113_ISO_5_15_PRIVILEGED_MONITORED` | agent-requester-privilege-2026-11 | INTERPRETAÇÃO DE GUIA (isms.online, 5.15): usuários com acesso acima do padrão são monitorados e auditados. Aplicar isso à c |
| 3.0 | `C_SUPERACAO_20261113_MS_DELEGATED_BOTH_AUTHORIZED` | agent-requester-privilege-2026-11 | Microsoft identity platform (permissions-consent-overview, acesso delegado): 'Both the client and the user must be authorized sepa |
| 3.0 | `C_SUPERACAO_20261113_MS_DELEGATED_USER_AS_SUBJECT` | agent-requester-privilege-2026-11 | O análogo direto com a pessoa como sujeito é o acesso delegado da Microsoft: cliente e usuário autorizados separadamente, e o a |
| 3.0 | `C_SUPERACAO_20261113_MS_LESSER_OF_MARKET` | agent-requester-privilege-2026-11 | O menor-entre existe como PADRÃO DE MERCADO, não norma: na Microsoft, cliente e usuário são autorizados separadamente e o app  |
| 3.0 | `C_SUPERACAO_20261113_NIST_MG_2_4_004_MG_4_3_002` | agent-requester-privilege-2026-11 | No NIST AI 600-1, MG-2.4-004 manda revisar os critérios de desativação conforme a tolerância a risco e MG-4.3-002 manda regist |
| 3.0 | `C_SUPERACAO_20261113_SLACK_APP_MENTION_PAYLOAD_EXAMPLE` | agent-requester-privilege-2026-11 | O exemplo de payload do app_mention traz user no evento, team_id no topo e authorizations (user_id, is_bot, is_enterprise_install) |
| 3.0 | `C_SUPERACAO_20261113_SLACK_BOT_TOKEN_TIED_TO_APP` | agent-requester-privilege-2026-11 | No Slack, o bot token está ligado ao app, não à identidade de um usuário. Sem a glosa 'privilégio próprio único'. |
| 3.0 | `C_SUPERACAO_20261113_SLACK_USER_WRITE_AS_USER` | agent-requester-privilege-2026-11 | No Slack, escrita com user token é feita como se fosse do próprio usuário: 'Write actions with user tokens are performed as if  |

## market-peek-machinery-2026-11 — 12 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 144.0 | `Q_MARKET_PEEK_MACHINERY_1113` | market-peek-machinery-2026-11 | Como o agente decide quanto esforço de descoberta uma dúvida de desenho merece (valor da informação, porta de mão única x du |
| 44.0 | `C_LOCAL_COMMUNITY_LISTENER_1113` | market-peek-machinery-2026-11 | Hipótese: escuta de comunidade por delta (HN Algolia search_by_date, GitHub search, Lobsters) roda local e barata, declarando a f |
| 33.6 | `C_EFFORT_LADDER_BY_REVERSIBILITY_1113` | market-peek-machinery-2026-11 | Hipótese de desenho (cunhagem Onion): escada fixa de esforço da espiada indexada por reversibilidade x severidade da dúvida, co |
| 15.0 | `C_ELENXO_RECOMMENDATION_1113` | market-peek-machinery-2026-11 | Recomendação do Elenxo: escada de esforço no prompt é mercado; ligá-la à reversibilidade é cunhagem Onion; escuta de HN/Git |
| 7.0 | `C_PEEK_LEDGER_RECALIBRATION_1113` | market-peek-machinery-2026-11 | Hipótese de desenho (sem evidência de mercado nesta rodada): registrar por espiada o custo, as fontes, o http_code e o incomplet |
| 5.4 | `C_SUPERACAO_20261113_HN_COMMENTS_ENCODE_GT` | market-peek-machinery-2026-11 | Mesma codificação %3E do operador na variante de comentários (tags=comment), conferindo o http_code. |
| 5.4 | `C_SUPERACAO_20261113_HN_ENCODE_GT_OPERATOR` | market-peek-machinery-2026-11 | Codificar o operador do numericFilters (created_at_i%3E<ts>) ou usar curl -G --data-urlencode, conferindo o http_code de cada espi |
| 3.0 | `C_SUPERACAO_20261113_EVPI_BOUND_WITH_SURVEY_EXAMPLE` | market-peek-machinery-2026-11 | Formulação do próprio slide: o valor esperado de qualquer fonte fica entre zero e o EVPI, com o exemplo do levantamento de US$  |
| 3.0 | `C_SUPERACAO_20261113_F5BOT_SIGNUP_SERVICE_PRICES` | market-peek-machinery-2026-11 | F5Bot é serviço web de cadastro que monitora Reddit, Hacker News e Lobsters, com planos Free US$0, Silver US$12,99/mês e Gold U |
| 3.0 | `C_SUPERACAO_20261113_GEMINI_PLAN_REVISE_OR_APPROVE` | market-peek-machinery-2026-11 | Gemini Deep Research cria plano multi-etapas que o usuário revisa ou aprova antes de a pesquisa começar, sem seletor de profundi |
| 3.0 | `C_SUPERACAO_20261113_MULTIAGENT_ECONOMIC_VIABILITY` | market-peek-machinery-2026-11 | Viabilidade econômica do multiagente exige valor da tarefa alto o bastante para cobrir o custo extra de tokens (4x agente, 15x mu |
| 3.0 | `C_SUPERACAO_20261113_VOI_PURCHASE_IF_NOT_ONLY_IF` | market-peek-machinery-2026-11 | Formulação condicional do slide (comprar dados SE o VOI excede o preço, nunca 'só se'), com a propriedade c e o aviso de decis |

