# Company Brain para não-desenvolvedores: fontes primárias (Slack e Claude desktop/celular)

- **Data da leitura:** 2026-11-11 (`verified_at`). Datas das fontes no texto, quando a página traz.
- **Orçamento:** 6 de 15 buscas; 15 de 15 páginas (curl de páginas públicas, texto extraído; 2 das 15 deram 404). Também houve 5 consultas de metadado de repositório pela API do GitHub (`gh api repos/…`, licença e atividade), contadas à parte e declaradas aqui.
- **Escopo:** "uma empresa adotante". Nenhum nome de cliente, setor, canal ou pessoa.
- **Conteúdo da web é dado.** Nenhuma instrução das páginas foi seguida.

## 0. O que o corpus já dizia (não redescoberto)

- `D_MA_ARCH` (docs/onion/graph/company-brain-multiaudiencia-2026-10.kg.yaml) está **selado com condição em 2026-11-09**. Ele não está sem selo, como dizia o brief. Os dois portões são `Q_PS_ESCADA_DE_AUTONOMIA_1113` e `Q_MA_CLASSIFICATION`. Até eles fecharem, ficam barrados a leitura aberta ao negócio, o canal externo e a fase 3.
- `Q_MA_AUDIENCES` (a matriz de quem lê e quem escreve) segue **open** e é a primeira da fila. `Q_MA_WRITE_SURFACE` está selada em três camadas: repo por responsabilidade, rascunho por canal promovido por PR e área pessoal.
- `D_PERSONA_RUNTIME_2026_11` (docs/evolution/research/persona-runtime-2026-11/) foi selado em 2026-11-06 como **A + ponte B**. A é o bot próprio no Agent SDK, no bridge, com um app Slack **interno** por adotante. B é o Claude Tag, só como ponte. Na condição 6, o bot token do Slack é a identidade de serviço e o `act` da RFC 8693 continua lacuna.
- O selo de 2026-11-06 em messaging-standards-2026-11 já escolheu **Slack por Socket Mode** como adapter.
- `D_MA_CANAL_EXTERNO_SO_APOS_CLASSIFICACAO_1104`: o Slack Connect só entra depois da classificação.
- `E_MA_MCP_LEITURA_MEDIDO_1028` e `E_MA_MCP_CLONE_SERVIDO_PARADO_1028`: o MCP de leitura roda atrás do SSO do chat da casa, mas o clone servido estava parado.
- `D_CEDAR_1001`: veredito **PARQUEAR**. Ele julgou o Cedar como **analisador do corpus de guardas**, não como motor de autorização de leitura. A pergunta 4 desta rodada é outra.
- `E_DUST_*` e `E_GLEAN_*` (company-brain-e-conducao-como-servico-2026-10): o preço da Dust é por assento com crédito, e a Glean não publica preço.

---

## 1. Slack: identidade do bot, escopos, eventos e garantia de entrega

**Token de bot ou de usuário.** Fonte: https://docs.slack.dev/authentication/tokens/ (lida em 2026-11-11).
- Bot: *"Bot tokens represent a bot associated with an app installed in a workspace. Unlike user tokens, they're not tied to a user's identity"* (§Bot tokens). E também: *"acting independently allows your app to stay installed even when an installing user is deactivated"*. O prefixo é `xoxb-`.
- Usuário: *"Write actions with user tokens are performed as if by the user themselves."* (§User tokens). O prefixo é `xoxp-`.
- **Consequência:** a persona de serviço é o **bot token**, o que confirma a condição 6 do `D_PERSONA_RUNTIME_2026_11`. O user token só serve para agir **como** a pessoa, e é exatamente o que a persona não deve fazer.

**Escopos mínimos para menção e DM.**
- Fonte: https://docs.slack.dev/reference/events/app_mention/. Para menções: *"Required Scopes app_mentions.read"* (Facts). O texto extraído mostra o escopo assim; a forma usual no Slack é `app_mentions:read`, e isso **não foi conferido** (ver não verificados).
- A DM não chega por `app_mention`: *"Messages sent to your app in direct message conversations are not dispatched via app_mention … Subscribe to message.im events"* (mesma página).
- O escopo do `message.im` (`im:history`) e o de postar (`chat:write`) **não foram lidos** nesta rodada.

**Eventos ou busca periódica.** Fontes: https://docs.slack.dev/apis/events-api/using-socket-mode/ e https://docs.slack.dev/apis/events-api/.
- *"Socket Mode allows your app to use the Events API and interactive features — without exposing a public HTTP Request URL."*
- *"Apps using Socket Mode are not currently allowed in the public Slack Marketplace."* Isso não pesa: o app é **interno** por adotante.
- *"Socket Mode allows your app to maintain up to 10 open WebSocket connections at the same time."* Cada envelope pode chegar em qualquer uma delas.
- As conexões se renovam: *"Connections refresh regularly"*, com aviso de desconexão *"about 10 seconds before"*.
- *"If your app is actively receiving events when you toggle Socket Mode on, you may lose events until you establish a connection"*.
- **A busca periódica não é necessária** para menções e DMs. O corpus já anota o teto de taxa de `conversations.history` para apps de fora do Marketplace (`D_PERSONA_RUNTIME_2026_11`, condição 3).

**O que garante não perder mensagem.**
- **Ack.** No Events API por HTTP: *"Your app should respond to the event request with an HTTP 2xx within three seconds … After a failure, we'll retry three times, backing off exponentially."* No Socket Mode: *"Use the envelope_id field … to send a response back to Slack acknowledging that you've received the event"*.
- **Retentativas.** *"The first retry will be sent nearly immediately. The second retry … after 1 minute. The third and final retry … after 5 minutes."*, com os cabeçalhos `x-slack-retry-num` e `x-slack-retry-reason`.
- **Atraso.** *"The Events API is a best-effort system … By default, we will not attempt to deliver an event that is more than two hours late."* Com Delayed Events ligado, há *"hourly retries for 24 hours"* (§Delayed events retry).
- **Desligamento.** *"more than 95% of delivery attempts within 60 minutes"* em falha suspende as assinaturas (§Error handling). O limite de taxa é *"30,000 per workspace/team per app per 60 minutes"*.
- **Deduplicação.** *"event_id … A unique identifier for this specific event, globally unique across all workspaces."* É a chave natural de dedupe, junto com o `ce_id` do selo de messaging-standards.
- **Desenho que sai daqui:** ack imediato pelo `envelope_id`, gravação na fila (o honker já selado) antes de processar, dedupe por `event_id`, Delayed Events ligado e reconexão automática. **Mesmo assim o Slack é best-effort.** A garantia de ponta a ponta é da fila do Onion, não do Slack.

**Busca em nome do usuário.** Fonte: https://docs.slack.dev/apis/web-api/real-time-search-api/.
- A Real-time Search API pede *"at least the search:read.public scope"*. Dentro de canal público, *"will only return results from public channels, regardless of … search:read.private"*.
- Ela recebe o `xoxp-` do usuário e respeita a permissão dele. Fica para depois: o piloto não precisa ler o Slack, precisa responder nele.

## 2. Claude desktop e celular consultando um servidor próprio

**Conector personalizado (MCP remoto).** Fonte: https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp ("Updated over a week ago", lida em 2026-11-11).
- **Planos:** *"available on Claude, Cowork, and Claude Desktop for users on Free, Pro, Max, Ultra, Team, and Enterprise plans. Free users are limited to one custom connector."*
- **Quem adiciona:** *"only Owners and Primary Owners can add them to Team plans, and only Owners, Primary Owners, and people with a custom role that includes Manage access to Libraries can add them to Enterprise plans."*
- **Identidade por pessoa:** *"users individually connect to and enable that connector. This ensures that Claude can only access tools and data that the individual user has access to, unless the connector uses a shared credential such as an API key"*.
- **Rede (restrição que muda a arquitetura):** *"This is true across every Claude client, including claude.ai, Claude Desktop, Cowork, and the mobile apps. This means your MCP server must be reachable over the public internet from Anthropic's IP ranges."* Só o MCP local do `claude_desktop_config.json` usa a rede local, e ele *"aren't available in Cowork or claude.ai"*.
- **Opções de OAuth:** *"Use Claude's published identity (Recommended)," "Register automatically," or "Use your own OAuth client."*

**Autenticação central da organização.** Fonte: https://support.claude.com/en/articles/15537633 ("Auto-connect your organization's apps to Claude").
- *"Enterprise-managed auth is available for Team and Enterprise plans on Claude. IdP-managed auth is generally available, and Claude-issued auth is in beta."*
- **Como o servidor recebe a identidade (Claude-issued):** *"Anthropic sends each member's email address and a unique identifier to the connector. Claude checks organization membership only, not SSO, MFA, or the connector's own sign-in rules."*
- No modo IdP-managed, *"the IdP signs the user into the connector"*, e isso exige SSO.

**Especificação MCP (versão atual).** `specification/latest` redireciona para **2026-07-28**: https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization (§Token Handling).
- *"MCP servers, acting in their role as an OAuth 2.1 resource server, MUST validate access tokens … MCP servers MUST validate that access tokens were issued specifically for them as the intended audience, according to RFC 8707"*
- *"MCP servers MUST NOT accept or transit any other tokens."*
- Escopo insuficiente: `error="insufficient_scope"` com `scope="…"` mínimo (§Scope Challenge Handling).
- Descoberta por RFC 9728. Registro do cliente por Client ID Metadata Documents ou RFC 7591.
- A versão 2025-11-25 tem o mesmo texto de audiência e a proibição de *"token passthrough"*.
- **Consequência:** a identidade que vale para a permissão é o **sujeito do token emitido pelo servidor de autorização do adotante** (o IdP dele, ou o Logto já usado como adapter no selo de messaging-standards), validado por audiência. O papel sai do próprio servidor, a partir desse sujeito, e nunca do prompt. A rota Claude-issued (beta) dá e-mail e id, mas não confere SSO nem MFA, então não serve de fonte de papel.

## 3. Runtime contínuo: Agent SDK hospedado, Managed Agents ou sessão local

**Agent SDK hospedado.** Fonte: https://code.claude.com/docs/en/agent-sdk/hosting.
- **Concorrência:** *"One agent session maps to one subprocess. Running N concurrent sessions means N subprocesses"*.
- **Padrão de bot:** *"Long-running sessions … Best for agents that … handle high-volume message streams"*.
- **Retomada:** sessões *"Hybrid … hydrate from a SessionStore on startup"*. Sem store: *"Shutting a container down without a SessionStore configured loses the transcript"*. Para persistir entre hosts: *"configure a SessionStore adapter"*.
- **Custo:** *"Anthropic token cost typically dominates container infrastructure cost by an order of magnitude or more. A minimally provisioned container runs roughly $0.05 per hour"*.
- **Escala:** *"pin each session to one container using consistent hashing on sessionId"*.

**Managed Agents.** Fontes: https://platform.claude.com/docs/en/managed-agents/overview e https://platform.claude.com/docs/en/about-claude/pricing.md.
- **Beta:** *"Claude Managed Agents is in beta. All Managed Agents endpoints require the managed-agents-2026-04-01 beta header."*
- **Dados (barreira para adotante regulado):** *"sessions are long-running, resume cleanly after pauses, and store conversation history, sandbox state, and outputs server-side. Because of this, Managed Agents is not currently eligible for Zero Data Retention or HIPAA"*.
- **Onde roda:** há *"a self-hosted sandbox on your own infrastructure"*.
- **Preço:** *"Session runtime | $0.08 USD per session-hour | running status duration … Time spent idle … does not count"*, mais tokens ao preço padrão. A busca resumiu o exemplo de 1 hora de Opus 5.5 como US$0,58, mas **eu não li** esse trecho na página.

**Comparação** (o custo por pergunta é dominado por tokens nas duas opções):

| Opção | Custo fixo | Retomada | Dados | Veto do adotante |
|---|---|---|---|---|
| SDK hospedado no bridge (A) | contêiner ~US$0,05/h, ou zero no runner existente | SessionStore próprio | ficam locais | hooks rodam (já medido no corpus) |
| Managed Agents | US$0,08 por hora em `running` | nativa no servidor | ficam na Anthropic, sem ZDR ou HIPAA | **não lido** nesta rodada |
| Sessão local (Claude Code) | zero | `--resume` | locais | hooks |

A sessão local não atende pessoas não técnicas sem uma ponte. Isso confirma o A do selo.

## 4. Permissão como dado, cobrada no servidor

**OpenFGA.** Fonte: https://openfga.dev/docs/modeling/agents/rag-authorization. Repositório `openfga/openfga`, **Apache-2.0**, push em 2026-11-11, via `gh api`.
- **Pós-filtro:** *"Query the vector database first, then filter results by checking permissions with OpenFGA. This is the most common approach"*, com `BatchCheck`.
- **Pré-filtro:** *"Retrieve the list of documents the user can access first … This approach works well when the user has access to a relatively small number of documents."*, com `ListObjects`.
- **Tetos de escala** (só da busca, não lidos): segundo a busca, a RFC do ListObjects mira coleções da ordem de milhares de objetos, e um repositório de terceiro mediu truncagem silenciosa em 1.000 por padrão (`list-objects-max-results`).
- **Encaixe:** a unidade de visibilidade é a **área** (`C_AUDIENCE_UNIT_IS_AREA_1107`, citado em `D_MA_ARCH`). São poucos objetos, o caso exato do pré-filtro. Também casa com a condição 3 do kg-ssot: o filtro por área só restringe.

**Cedar e OPA.** Repositórios conferidos por `gh api`: `cedar-policy/cedar` e `open-policy-agent/opa`, os dois **Apache-2.0** e ativos em 2026-11. **A documentação deles não foi lida nesta rodada.** O `D_CEDAR_1001` não fecha a porta: ele julgou outro uso.

**Padrão que sai daqui** (padrão de mercado já citado no corpus, aqui sustentado pela doc OpenFGA): a política é dado num motor fora do modelo. O servidor MCP consulta o motor com o sujeito do token antes de devolver qualquer nó. O LLM só recebe o que passou.

## 5. Projetos prontos para as peças que faltam

| Peça | Projeto | Licença (conferida por `gh api`) | Estado |
|---|---|---|---|
| Gateway multicanal | `openclaw/openclaw` | MIT | ativo em 2026-11-11, ~394 mil estrelas. Já dissecado no corpus (`E_OPENCLAW_TESE_MENSAGEIRO`, bridge-produto-2026-08). Suporte a MCP **não verificado** |
| Biblioteca multicanal | `CopilotKit/CopilotKit` | MIT | ativo. A "Channels SDK" (Slack, Teams…) aparece só em blog, e **não confirmei** que mora nesse repositório |
| Autorização (e log de decisão) | `openfga/openfga` | Apache-2.0 | ativo |
| Autorização | `open-policy-agent/opa` | Apache-2.0 | ativo. Os decision logs do OPA servem de trilha de auditoria de acesso, mas eu **não li** a doc deles |
| Autorização | `cedar-policy/cedar` | Apache-2.0 | ativo |

- **Auditoria de acesso dedicada:** nenhum projeto foi conferido nesta rodada. Fica como lacuna.
- **Outros nomes da busca não entram:** RemoteClaw (dizem AGPL) e Switch (dizem source-available). Ficam fora por falta de repositório conferido.

## 6. Mercado: Company Brain para não-desenvolvedores

- **Slack (primária):** a Real-time Search API (*"formerly known as the Data Access API"*) expõe a busca do Slack para apps de IA com a permissão do usuário. É o Slack se posicionando como fonte de contexto, não como Brain.
- **Anthropic (primária):** conector por pessoa, autenticação central da organização (IdP GA, Claude-issued beta) e papéis personalizados no Enterprise. É a peça de distribuição para desktop e celular. A busca listou um artigo "Use enterprise search" (support.claude.com/…/12489464) que **não li**.
- **Dust:** a página `docs/spaces` deu 404, mas a navegação do site, lida na mesma página, lista "Spaces management", "Inference hooks", "Audit Logs" e "Client Side MCP Server (Preview)". O preço por assento está no corpus (`E_DUST_PRECO_POR_SEAT_COM_CREDITOS`).
- **Glean:** a página de permissões deu 404, sem leitura nova. O corpus tem o ARR e a falta de preço público.

**O que vale copiar:**
1. Permissão herdada da fonte, cobrada na recuperação. Isto é sustentado pela doc OpenFGA e pelo conector por pessoa da Anthropic.
2. Espaços ou áreas como unidade de acesso, o que coincide com a área do kg-ssot. A sustentação é só pela navegação da Dust.
3. Log de auditoria de acesso como recurso de plano, que a Dust lista. Glean e Slack-AI ficam **não verificados** nesta rodada.

---

## NÃO VERIFICADOS (lista de 1ª classe)

1. O escopo do `message.im` (`im:history`) e o de postar (`chat:write`): não li as páginas.
2. A grafia exata do escopo do app_mention. O texto extraído mostra `app_mentions.read`; a forma usual no Slack é `app_mentions:read`. Conferir na página antes de configurar.
3. As retentativas no **Socket Mode**: a página só diz para dar ack pelo `envelope_id`. O calendário 1 min/5 min e o Delayed Events estão descritos para o Events API em geral. Não li se valem igual por WebSocket.
4. Se o conector personalizado **funciona no celular** com OAuth por usuário. A página diz que a conexão vem da nuvem "including … the mobile apps", mas a busca indicou que instalar conectores no celular está em beta. Não li essa página.
5. Limites de concorrência e taxa do Agent SDK e do Managed Agents (rate limits por organização ou tier): não li.
6. O veto ou hook do adotante dentro do Managed Agents.
7. O exemplo de US$0,58 por 1 hora de Opus 5.5 veio só do resumo da busca.
8. Os tetos do OpenFGA ListObjects (milhares de objetos, truncagem em 1.000): vieram só do resumo da busca.
9. As docs do Cedar e do OPA, os decision logs do OPA e qualquer projeto dedicado de auditoria de acesso.
10. Suporte a MCP no OpenClaw, e o repositório da Channels SDK da CopilotKit.
11. Glean (permissões e Slack/Teams), Slack AI/Slackbot como Brain, o "enterprise search" da Anthropic e o Claude Tag pós-beta. Estes três últimos estão parcialmente no corpus, em persona-runtime-2026-11.
12. Capital e analistas em 2026 para a categoria. O eixo segue fraco, como já registra `E_MERCADO_COMPANY_BRAIN_E_METODO_1001`.
