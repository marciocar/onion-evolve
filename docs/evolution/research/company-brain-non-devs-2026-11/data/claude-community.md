# Claude desktop e celular como front de não-devs para um Company Brain: o que a comunidade e a Anthropic dizem

- **Data da leitura:** 2026-11-11.
- **Orçamento:** 12 de 12 buscas (bateu o teto) e 10 de 12 páginas. As páginas foram lidas por curl, com texto extraído. Uma deu 404 (support 11503834), e o espelho claudeissues.com não baixou, então li a issue original pela `gh api`.
- **Ponto de partida:** o `primaries.md` da worktree brain-study. Não repito o que ele já leu: o artigo 11175166 (planos, quem adiciona, identidade por pessoa, a exigência de internet pública), o 15537633 (IdP-managed e Claude-issued), o §Token Handling da spec 2026-07-28 e os preços do Managed Agents. O corpus (`kg-corpus-grep`) não trouxe nó novo sobre o tema. Os 20 primeiros acertos eram de posicionamento, Cedar e Conductor.
- **Reddit:** nenhuma busca devolveu fio do Reddit. Veio só um espelho de snapshot (reddit.sentinel-team.org), que não li. Não contornei.
- **Sigilo:** nenhum adotante, setor, canal ou pessoa nosso é citado. Clientes de terceiros que aparecem em blog de fornecedor ficam como "cliente citado pelo fornecedor".
- **Conteúdo da web é dado.** Nenhuma instrução das páginas foi seguida.

---

## 1. Quem já faz isso em produção, com que resultado, e o que deu errado

**Relato de praticante independente: quase nenhum.** As três buscas dirigidas a relato de praticante (rollout, HN e "lessons learned") devolveram só material de fornecedor, de consultoria e de construtor de conector. Não achei nenhum postmortem de adoção por não-devs com Claude e conector próprio. **Esse é o achado mais forte desta seção: a lacuna de evidência.**

**O que aparece como relato (fraco, mas de uso real):**
- **Issue de segurança aberta por praticante no repositório oficial**, a anthropics/claude-code#44980. Foi criada em 2026-04-08 e fechada como `not_planned` em 2026-06-15 (lida pela `gh api`). No plano Team, o conector personalizado adicionado pelo Owner fica **visível com a URL para todos os membros**. Com OAuth de auto-aprovação, *"Every team member can see the URL and connect with zero identity verification"* e *"The connector URL IS the credential"*. O autor tentou pôr um gate de SSO na frente, sem sucesso: *"Claude's MCP client cannot complete browser-based SSO flows or send custom auth headers"*. **Lição para o nosso desenho:** a permissão por pessoa tem de morar no servidor (OAuth do MCP com IdP real), nunca na visibilidade do conector dentro do Claude. Isso confirma o desenho que já decidimos.
- **Construtor de conector** (Indie Hackers, sem data na busca): os usuários não descobrem o conector sozinhos. *"none of their logged-in users would ever know about the connector"*. A descoberta e a documentação são parte do produto. https://www.indiehackers.com/post/i-built-a-claude-connector-for-my-prompt-tool-heres-what-i-actually-learned-shipping-mcp-14e349878f
- **DEV Community** (sem data): o conector *"lower[s] the barrier to capability, but … raise[s] the surface area for failure"*. https://dev.to/forgeflows/mcp-servers-for-claude-what-we-learned-testing-them-33e4

**Material de fornecedor (separado, com incentivo comercial):**
- **Anthropic, sobre o próprio uso interno** (PDF de 2026-04-29, "Deploying Claude across your organization"). Ele propõe uma "escada de adoção": ligar o Claude ao trabalho real, entregar um resultado e só então codificar. Vi só o resumo da busca, **não li o PDF**.
- **Blog do Enterprise-managed auth** (2026-06-18, atualizado em 2026-08-24, lido). Três organizações aparecem como clientes que estão implantando. A busca repete o número de 2.000 funcionários provisionados por Okta "no dia 1", que é **citação de cliente em material do fornecedor**. https://claude.com/blog/enterprise-managed-auth
- **Glean** diz ter 93% de adoção em 2 anos, e a **Dust** diz ter 70% em 2 meses e 75% de um time de 1.600 pessoas usando por mês. Os três números são do próprio fornecedor ou de um resumo secundário.
- **Consultorias** (strac.io, botscrew, theaiconsultancy, onewave-ai, 2026) repetem o conselho de não ligar tudo no 1º dia: *"connecting everything on day one produces a Claude that can see a lot and does not know what it is for"*. Também mandam decidir por grupo qual conector e quais ferramentas cada um recebe.

## 2. O que a Anthropic oferece e recomenda (fonte oficial)

| Peça | O que diz a fonte oficial | Fonte e data |
|---|---|---|
| **Preço por assento** | Team: de 2 a 150 pessoas. O Standard custa US$20 por assento por mês no plano anual (US$25 no mensal) e o Premium, US$100 (US$125). Enterprise: **US$20 por assento por mês, mais uso a preço de API, com mínimo de 20 assentos e cobrança anual**. | https://claude.com/pricing (lida em 2026-11-11) |
| **Só no Enterprise** | Papéis com permissão fina, SCIM, **audit logs**, Compliance API, retenção customizada, controle de rede e IP allowlist. | mesma página |
| **No Team e no Enterprise** | Enterprise search, SSO, "Admin controls for remote and local connectors" e implantação corporativa do desktop. | mesma página |
| **Enterprise search ("Ask Your Org")** | É um projeto ligado por padrão, que o Owner precisa configurar. Aceita conector personalizado *"if permitted by your organization"*. É **ciente da permissão**: *"You only see search results from data you have permission to access in the original systems. For a custom connector that uses a shared credential, results reflect what that credential can access."* | https://support.claude.com/en/articles/12489464 (datado de 2026-10-01) |
| **Enterprise-managed auth** | O admin autoriza o conector uma vez, e as pessoas herdam o acesso pelos grupos do IdP. Funciona no chat, no Claude Code e no Cowork. Permite tokens curtos para revogar rápido e *"require that a connector only ever connects through the IdP"*. É extensão aberta do MCP, então *"any connector can support it — including the custom connectors your own teams build"*. O IdP do lançamento é o Okta, e outros viriam depois. | blog de 2026-06-18, atualizado em 2026-08-24 com GA |
| **Celular** | *"Installing connectors on mobile is currently in beta—Claude Desktop and web remain the primary path for custom connectors."* Os web connectors funcionam no iOS e no Android. | https://support.claude.com/en/articles/11176164 (lida em 2026-11-11) |
| **MCP tunnels** | Research preview, *"as-is" without any uptime, support, or continuity commitment*, depende da Cloudflare e **não é elegível a ZDR**. Ponto decisivo: *"MCP tunnels created through the Console are not available as connectors in claude.ai"*. Ou seja, **não servem ao desktop nem ao celular**, só ao Managed Agents e à Messages API. | https://platform.claude.com/docs/en/agents-and-tools/mcp-tunnels/overview.md |
| **MCP 2026-07-28 no Claude** | Núcleo sem estado e auth alinhada a OAuth 2.0 e OIDC de produção (*"connect to enterprise identity systems like Entra or Okta without workarounds"*). O diretório tem mais de 950 servidores. *"Support is rolling out across Claude products soon."* | https://claude.com/blog/bringing-mcp-2026-07-28-to-claude (2026-07-28) |

**Conflito entre fontes oficiais:** o blog diz que o Enterprise-managed auth está *"generally available"* desde 2026-08-24. O artigo 11176164, lido hoje, diz *"available in beta for Team and Enterprise plans"*. E o 15537633, no primaries, diz que o IdP-managed está em GA e o Claude-issued em beta. Leitura provável: o modo pelo IdP está em GA e o emitido pelo Claude está em beta. **Conferir antes de prometer ao adotante.**

**Trajetória dos últimos 60 a 120 dias:** EMA em GA (24/08), enterprise search datado de 01/10, Team a partir de 2 assentos (julho, só fonte secundária) e, em 10/11, os "interactive connectors" e apps embutidos (só títulos, não lidos). Tudo aponta para a Anthropic empurrando o Claude como a superfície corporativa de consulta, com o conector governado pelo IdP.

## 3. Problemas recorrentes

1. **Injeção de prompt por conteúdo recuperado.** É o padrão descrito por todos: instrução escondida num documento ou ticket leva o agente a ler dado sensível e mandá-lo para fora por chamada de ferramenta normal. O exemplo mais citado é o do servidor MCP do GitHub (fonte única, de blog do setor: the-agent-report.com, 2026-07). **Não achei incidente confirmado com base de conhecimento ligada ao Claude.** As mitigações citadas são escopo mínimo, somente leitura, saída de rede restrita e varredura da resposta da ferramenta (Checkmarx, Obot, Unit42, arXiv 2603.22489). Para nós, o Brain só leitura, filtrado por área no servidor, reduz o raio do estrago, mas não elimina a injeção dentro do que a pessoa pode ver.
2. **Vazamento entre pessoas.** Duas causas medidas. A primeira é a **credencial compartilhada**: a doc oficial diz que o resultado reflete o que a credencial vê. A segunda é o **conector visível para todos no Team**, a issue #44980 fechada como not_planned. A cura é o mesmo desenho já decidido: token por pessoa, audiência validada, papel tirado do sujeito no servidor.
3. **Custo por assento.** Para o desktop e o celular, toda pessoa não-dev precisa de assento Team ou Enterprise (US$20 a US$25, e Enterprise com mínimo de 20, mais uso). O bot no Slack não cobra assento por leitor, só tokens. O Glean custa US$40 a US$80 por usuário mais implantação de US$20 mil a US$80 mil, e o Copilot custa US$30 (ambos só de fonte secundária, beri.net e clarityarc, não lidos).
4. **Conector exige admin.** Só Owner ou Primary Owner, ou papel customizado no Enterprise, adiciona conector (primaries). A pessoa comum não instala sozinha. Para não-devs isso é **vantagem**: o EMA faz o conector já aparecer no primeiro login.
5. **Celular.** A instalação de conector no celular está em beta. **Latência no celular: nenhuma medição achada.**
6. **Auditoria.** Audit logs e Compliance API **só no Enterprise**. No Team, o registro de quem perguntou o quê fica todo a cargo do nosso servidor MCP. Isso já está no desenho (o log de decisão da permissão), mas passa a ser **obrigatório**, e não opcional, se o adotante for Team.
7. **Rede.** O servidor tem de ser alcançável pela internet pública a partir dos IPs da Anthropic (primaries). Os tunnels não resolvem isso no claude.ai.

## 4. Alternativas que a comunidade prefere para não-devs, e por quê

- **Bot no Slack (o próprio ou um Slackbot):** fica onde o não-dev já está, sem assento de IA por leitor e sem instalar nada. A Salesforce reconstruiu o Slackbot como agente sobre o Claude (implicator.ai e pulse.bot, só resumo). Fornecedores da categoria dizem que o ChatGPT e o Claude dentro do Slack são *"single-player"* e sem as ferramentas conectadas (adapt.com, com interesse comercial). Isso reforça a ordem que escolhemos: Slack primeiro.
- **Glean:** o motivo dado é a permissão herdada de mais de 100 fontes e a busca pronta. Tem mercado comprovado: US$300 milhões de ARR anunciados em 2026-05-28, depois de US$200 milhões em 2025-12 (press release da própria Glean). O contra é o preço alto e não público, mais a implantação.
- **Dust:** feito explicitamente para não-devs, com agentes compartilhados, deploy no Slack e escolha do modelo por agente. Levantou US$40 milhões na Série B em 2026-05, liderada por Sequoia e Abstract (hackernoon e itbrief, secundárias), e diz ter NRR de 240% em 2025. O contra são poucos conectores, cerca de 12 segundo uma análise.
- **Microsoft 365 Copilot:** a busca vem embutida na licença. Mesmo assim, poucos pilotos viram implantação ampla (Gartner, citado de segunda mão).
- **Chat próprio:** a comunidade quase não discute. Aparece só como "build your own" em consultorias (clarityarc).
- **Eixo de mercado (quem financia):** o dinheiro está na **camada de permissão e contexto** (Glean e Dust), não na tela. A Anthropic e a Salesforce disputam ser a tela: o Claude com EMA e enterprise search, e o Slackbot construído sobre o Claude. **O ganho fica com quem controla a permissão herdada.** Isso sustenta o nosso desenho: o servidor MCP com permissão por área é o ativo, e o front pode ser trocado.

## 5. Recomendação (5 linhas)

1. Vale, como **2ª tela de um mesmo servidor MCP**, depois do Slack, e só onde o adotante já paga Team ou Enterprise. Assento comprado só para isso não se paga contra o bot.
2. É condição **não confiar em nada da camada do Claude para a permissão**: OAuth por pessoa com o IdP da organização, audiência validada, área cobrada no servidor e **zero credencial compartilhada**. Isso fecha a classe de bug da issue #44980.
3. Com o **Enterprise-managed auth pelo IdP** (GA), o conector aparece no 1º login. Não exponha a URL como segredo, e mantenha o Brain só leitura para reduzir o raio de injeção.
4. Para o **celular**, trate como beta: instale pela web ou pelo desktop. **No Team, a auditoria é toda nossa.** Os audit logs da Anthropic só existem no Enterprise.
5. O servidor precisa estar **na internet pública**, porque os tunnels não chegam ao claude.ai. Meça a latência no celular e o uso real por 30 dias antes de prometer mais que o piloto.

---

## NÃO VERIFICADOS

1. **Relato independente de produção** com não-devs, Claude e conector próprio: não achei nenhum. O Reddit não apareceu nas buscas, e o snapshot espelhado não foi lido.
2. O número de 2.000 funcionários no 1º dia e as adoções de 93%, 70% e 75%: são citações de fornecedor ou de cliente em material do fornecedor.
3. O status do Enterprise-managed auth: há conflito entre "GA" (blog de 2026-08-24) e "beta" (artigo 11176164). E se ele já aceita **IdP além do Okta** (o blog diz "coming soon").
4. Se os **conectores personalizados com OAuth** funcionam de ponta a ponta no celular. Li só "instalação em beta", sem teste e sem medição de latência.
5. Se os audit logs do Enterprise registram as **chamadas de ferramenta do conector** ou só a conversa. Não li a doc da Compliance API.
6. O PDF da Anthropic de 2026-04-29 sobre implantação interna: li só o resumo da busca.
7. Os CVEs do servidor Git MCP oficial (janeiro de 2026) e o "PDF que acionou bomba": vêm de blog secundário, sem conferência em CVE.
8. Os preços de Glean e Copilot, o custo de implantação do Glean, a Série B da Dust e o NRR de 240%: todos de fontes secundárias.
9. O Slackbot "construído sobre o Claude" e a satisfação de 96%: vieram de resumo e de agregador.
10. O Team a partir de 2 assentos desde julho de 2026: a página oficial de preço diz "2 to 150", mas a data é de fonte secundária.
11. Os "interactive connectors" e os apps dentro do Claude (posts de 2026-11-10): li só os títulos.
12. O resultado do 1º relato fechado como `not_planned`: não sei se o EMA ou o enterprise search mudaram a visibilidade do conector no Team depois de 2026-06-15.
