# S1 — Interop ao vivo / A2A: evidência de mercado para o federation-transport do Onion

> Stream S1 do redesign da federação. Coleta de evidência (não decisão de doutrina).
> Cada achado material carrega FONTE (URL). Achados sem URL sólida = marcados como hipótese.
> Data da coleta: 2026-07-09. Priorização: 2025-2026.

## Resumo

O protocolo **A2A (Agent2Agent)** amadureceu de experimento (Google, abr/2025) a **standard de produção v1.0 (abr/2026)**, sob governança neutra da **Linux Foundation / Agentic AI Foundation (AAIF)** — a mesma fundação que agora abriga o **MCP da Anthropic** (o vetor do Onion). Isso é decisivo para o Onion: o desenho de referência da indústria para "IA-fala-IA entre fronteiras de sistema/vendor" **já resolve exatamente o par de resiliência que a federação Onion precisa** — *streaming quando conectado (SSE) + webhook push quando offline (PushNotificationConfig) + task lifecycle durável + retomada (resubscribe)*. E o padrão de **aceitação gated** que o Onion já pratica no `members.yaml`/trust é, na indústria, **policy-as-data (OPA/Rego) aplicada na camada de tool-calling** — o agente não decide, a política decide.

O encaixe é forte e de **reuso, não reinvenção**: (1) o par SSE+webhook do A2A é a formalização do que o doc-bridge git-async já faz na metade "offline" — falta só a metade "viva"; (2) o `members.yaml` já é um *agent-card registry* offline + policy-as-data; (3) o SDAAL (`task-manager/factory.md`, `forge/factory.md`) é o precedente pronto de um **`federation-transport` com adapters `git-async | local | a2a-live` gated**; (4) a VPS Hostinger KVM 8 (onde o `onion-bridge` já roda `@anthropic-ai/claude-agent-sdk` com `bypassPermissions`) é infraestrutura suficiente para hospedar tanto um endpoint A2A/webhook quanto um console/mapa derivado do `members.yaml`.

As 4 dores P0 do maestro mapeiam limpo: **D1 (Grana.Ai isolada, sem canal vivo core↔core)** → adapter `a2a-live` (SSE+webhook) sobre o SDK; **D2 (ruído no targeting "alvo:")** → policy-as-data OPA-style resolvendo destinatários por `specializations/mode/classificação` que o `members.yaml` já tem; **D3 (falta console/histórico/relações)** → task lifecycle + ledger observável, deployável na VPS; **D4 (falta mapa de adoções derivado)** → agent-card/registry derivado do `members.yaml`, servido na VPS.

---

## Achados

### F1 — A2A é governança neutra madura (LF/AAIF), v1.0 em abr/2026, 150+ orgs
**Claim:** Google lançou o A2A em abr/2025, doou-o à Linux Foundation em jun/2025, e em dez/2025 ele passou à **Agentic AI Foundation (AAIF)**; chegou a **v1.0 (produção) em abr/2026**, com **150+ organizações** e adoção em Azure AI Foundry/Copilot Studio, AWS Bedrock AgentCore e Google Cloud.
**Fontes:** <https://www.linuxfoundation.org/press/linux-foundation-launches-the-agent2agent-protocol-project-to-enable-secure-intelligent-communication-between-ai-agents> · <https://developers.googleblog.com/en/google-cloud-donates-a2a-to-linux-foundation/> · <https://www.linuxfoundation.org/press/a2a-protocol-surpasses-150-organizations-lands-in-major-cloud-platforms-and-sees-enterprise-production-use-in-first-year>
**Materialidade:** high.
**Implicação p/ Onion:** de-risca apostar num adapter `a2a-live` sobre um padrão estável e neutro (não refém de um vendor). Informa a estratégia geral do `federation-transport`: A2A é o "gramática" de referência a **imitar mesmo no modo git-async** (mesmos estados/campos), garantindo que o dia de ligar o `a2a-live` seja troca de transporte, não redesenho.

### F2 — Agent Card: descoberta em `/.well-known/agent-card.json` (skills, transporte, security schemes)
**Claim:** Todo servidor A2A publica um **AgentCard** em `/.well-known/agent-card.json` declarando skills, MIME types suportados, **transport bindings** e **security schemes** — descritor de serviço legível por máquina, buscável sem autenticação.
**Fontes:** <https://agent2agent.info/specification/core/> · <https://a2a-protocol.org/latest/specification/>
**Materialidade:** high.
**Implicação p/ Onion (D4 + D2):** o `members.yaml` **já é um agent-card registry offline** — cada membro tem `specializations`, `role/tier`, `exposes`, `trust`. Derivar um agent-card por membro (e o **mapa de adoções**, D4) do `members.yaml` é gerar a mesma estrutura que o A2A padroniza. Reuso direto: `graph.sh` (que hoje NÃO ingere `members.yaml`) pode passar a ingeri-lo e emitir o agent-card/mapa como *seed* derivado — não desenhado à mão.

### F3 — Task lifecycle de 8 estados sobre JSON-RPC 2.0 / gRPC / HTTP+JSON
**Claim:** Agentes comunicam via **JSON-RPC 2.0** (ou gRPC / HTTP+JSON) usando um **Task de 8 estados**: `submitted, working, input_required, auth_required, completed, failed, canceled, rejected`. Cada Task tem ID único e progride pelo ciclo.
**Fontes:** <https://a2aprotocol.ai/blog/2025-part2-full-guide-a2a-protocol> · <https://agent2agent.info/specification/core/>
**Materialidade:** high.
**Implicação p/ Onion (D3):** dá o **vocabulário de estados** para o console/histórico ausente. Um anúncio de co-evolução (`/meta:co-announce` → outbox → inbound) ou um contrato de federação (`/meta:federation-publish`) pode ser modelado como um Task com esses estados — `input_required`/`auth_required` mapeiam ao **gate do maestro humano**; `rejected` mapeia ao **veto fail-safe** da federação formal. O ledger de contratos + CHANGELOG vira a fonte do "console" quando expõe estes estados.

### F4 — Streaming SSE conectado: `SendStreamingMessage` + `SubscribeToTask` (resubscribe)
**Claim:** Para updates incrementais, A2A usa **SSE** — cliente chama `SendStreamingMessage`, servidor mantém `text/event-stream` com `TaskStatusUpdateEvent`/`TaskArtifactUpdateEvent`; se a conexão cai com task ativa, o cliente **reconecta via `SubscribeToTask`**. Servidor sinaliza suporte com `capabilities.streaming: true` no Agent Card.
**Fontes:** <https://a2a-protocol.org/latest/topics/streaming-and-async/> · <https://github.com/a2aproject/A2A/blob/main/docs/topics/streaming-and-async.md>
**Materialidade:** high.
**Implicação p/ Onion (D1):** esta é a **metade "viva" que falta** ao Onion. O canal core↔core vivo que a Grana.Ai não tem (hoje só git-async manual) é precisamente um `SendStreamingMessage` + `SubscribeToTask` entre dois cores rodando o `claude-agent-sdk`. O `capabilities.streaming` no card = flag por membro no `members.yaml` (quem está apto ao modo vivo). Reuso: é o adapter `a2a-live` do `federation-transport`, ligado só para membros gated.

### F5 — Push/webhook offline: `PushNotificationConfig` (url/token/authentication)
**Claim:** Para tasks longas ou clientes que não mantêm conexão, o servidor **notifica um webhook** do cliente via HTTP POST em mudanças significativas de estado (terminal, input-required, auth-required). Config: **`PushNotificationConfig` = { url (HTTPS), token opcional, authentication }`**. Servidor deve validar URL (anti-SSRF) e o receiver deve verificar JWT/timestamp (anti-replay), com rotação via JWKS.
**Fontes:** <https://a2a-protocol.org/latest/topics/streaming-and-async/> · <https://agent2agent.info/docs/topics/streaming-and-async/>
**Materialidade:** high.
**Implicação p/ Onion (D1 + resiliência):** é o **espelho formal do doc-bridge git-async**. O padrão da indústria é exatamente "streaming quando conectado, **webhook push quando offline**" — o Onion já vive na metade offline (entrega-sem-commit, `inbox/inbound`, um escritor por repo). Modelar o commit-no-`inbound/` como o "webhook offline" e o SSE como o "vivo" dá um **único `federation-transport` com dois adapters coerentes** (`git-async` = push offline durável; `a2a-live` = SSE). O `token`/`authentication` do PushNotificationConfig = onde o trust SDAAL (`.claude/utils/trust`) pluga.

### F6 — Autenticação A2A: OAuth 2.1 + JWT, auth-discovery via Agent Card; autorização é do agente remoto
**Claim:** A2A **não cria identidade nova** — reusa schemes OpenAPI (OAuth 2.0/2.1, OIDC, API keys, mTLS) declarados no Agent Card. Cliente descobre requisitos de segurança buscando o card (sem auth) e então inicia o fluxo. **Autenticado o cliente, a autorização/consent é responsabilidade do agente remoto** (lógica específica + políticas). O protocolo delega gestão de credencial aos implementadores (riscos: impersonation, card tampering, replay).
**Fontes:** <https://securew2.com/blog/a2a-protocol-security> · <https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security> · <https://a2a-protocol.org/latest/topics/enterprise-ready/>
**Materialidade:** high.
**Implicação p/ Onion (aceitação gated):** confirma que **"quem aceita o quê" é decisão do lado receptor, guiada por política declarada** — exatamente o desenho do bloco `trust:` do `members.yaml` (`can_receive_from`, `can_advise_to`, `can_correct_to`, `diary_readable_by`). O Onion já tem a política; o A2A mostra que a autorização mora no **agente remoto (o adotante)**, não no transporte. Reuso: trust SDAAL como o "authorization layer" do adapter a2a-live.

### F7 — MCP e A2A são complementares: stack de duas camadas (MCP=tools vertical, A2A=peer horizontal)
**Claim:** MCP padroniza **acesso a capacidades** (agente↔mundo/tools/dados); A2A habilita **colaboração entre agentes** (agente↔agente, descoberta/delegação através de fronteiras de vendor). São **complementares por desenho**, em camadas diferentes; a maioria dos sistemas multi-agente de produção em 2026 usa os dois.
**Fontes:** <https://onereach.ai/blog/guide-choosing-mcp-vs-a2a-protocols/> · <https://beam.ai/agentic-insights/agent2agent-vs-mcp-2026-ai-agent-stack>
**Materialidade:** high.
**Implicação p/ Onion (estratégia):** posiciona a federação Onion **na camada A2A** (coordenação core↔core, adotante↔adotante) — não é um problema de MCP. O Claude Code já é cliente MCP (tools); o que falta ao Onion é a **camada horizontal**. Isso valida um `federation-transport` separado do task-manager/forge SDAAL (que são "vertical/tools"), como peer deles.

### F8 — AAIF governa MCP **e** A2A sob uma fundação neutra; Anthropic é co-fundadora
**Claim:** A **Agentic AI Foundation (AAIF)** foi lançada em dez/2025 com 6 co-fundadores — **OpenAI, Anthropic, Google, Microsoft, AWS, Block** — recebendo o **MCP (Anthropic)**, goose (Block) e AGENTS.md (OpenAI); MCP e A2A são agora projetos LF **com esforço declarado de spec conjunta de interop**.
**Fontes:** <https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation> · <https://www.gingerlabs.ai/blog/agentic-ai-foundation-aaif-mcp-future-of-agentic-ai>
**Materialidade:** high.
**Implicação p/ Onion:** o vetor do Onion (Anthropic/Claude Code, via MCP) e o alvo do adapter (A2A) estão **sob a mesma governança convergente**. Reduz o risco de "apostar no A2A" ficar órfão do ecossistema Claude Code. Sinaliza que um `a2a-live` gated é aposta alinhada ao roadmap do próprio fornecedor.

### F9 — Claude Agent SDK: subagents headless + Workflow, o mecanismo real de "IA-fala-IA"
**Claim:** O **Claude Agent SDK** (renomeado de "Claude Code SDK" em set/2025) é a infra que roda o Claude Code, como lib (`@anthropic-ai/claude-agent-sdk`). **Subagents** isolam contexto e rodam em paralelo; para dezenas-centenas de agentes usa-se a **Workflow tool** (orquestração fora do contexto). Padrão headless de produção: **`allowedTools` + `permissionMode: "dontAsk"`** (deny-by-default).
**Fontes:** <https://code.claude.com/docs/en/agent-sdk/subagents> · <https://www.developersdigest.tech/blog/claude-agent-sdk-vs-claude-code>
**Materialidade:** high.
**Implicação p/ Onion (D1 + gated):** o Onion **já roda isto** — o `onion-bridge` na VPS usa `@anthropic-ai/claude-agent-sdk` com `bypassPermissions` e `ONION_CWD` num clone dedicado. É o motor pronto para um core "falar" ao vivo com outro core: um endpoint headless por core, `allowedTools` = a policy de aceitação gated (o "IA-fala-IA sem gate humano" hoje ausente vira "IA-fala-IA com gate = allowedTools + trust"). Reuso máximo: o bridge já existe; falta o protocolo entre bridges.

### F10 — Remote MCP + OAuth 2.1/PKCE: um core pode se expor como connector
**Claim:** MCP remoto exige **OAuth 2.1 com PKCE (S256)**, drop do implicit grant, redirect URI exato; Claude expõe "Integrations" (MCP connector) na API/Desktop para planos pagos, callback `https://claude.ai/api/mcp/auth_callback`.
**Fontes:** <https://platform.claude.com/docs/en/agents-and-tools/mcp-connector> · <https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp>
**Materialidade:** medium.
**Implicação p/ Onion (D1/D3 + VPS):** um core Onion na VPS pode se **expor como remote MCP/connector** (ex.: `mcp.onionevolve.com`) para que outros cores/adotantes consumam capacidades (ler changelog, submeter sinal) via OAuth 2.1 — caminho de menor atrito dentro do ecossistema Claude Code, complementar ao A2A. Viável na Hostinger KVM 8 (Caddy + TLS já em uso).

### F11 — Durable execution: persistir fronteiras de execução, retomar sem repetir efeitos
**Claim:** Durable execution cruzou para a "early majority" em 2025 (AWS **Lambda Durable Functions**, dez/2025; **Azure Durable Task for AI agents**, abr/2026; Temporal, Restate, Inngest, DBOS). Princípio convergente: **persistir fronteiras de execução completas e recuperar após crash sem repetir tool calls, mutações externas, aprovações humanas ou mensagens de saída**. Temporal usa Event History; Activities já concluídas são lidas do histórico, não re-executadas.
**Fontes:** <https://zylos.ai/research/2026-04-24-durable-execution-agent-runtimes/> · <https://www.inngest.com/blog/durable-execution-key-to-harnessing-ai-agents> · <https://learn.microsoft.com/en-us/azure/durable-task/sdks/durable-task-for-ai-agents>
**Materialidade:** high.
**Implicação p/ Onion (resiliência + retomada):** dá a doutrina para **checkpoint durável + retomada** que o par SSE/webhook exige. A garantia "não repetir mensagens de saída/aprovações" é a formalização exata do invariante **entrega-sem-commit (um escritor por repo)** e do gate do maestro — o Onion não pode reenviar um anúncio já entregue. As sessões persistentes (`.claude/sessions/`) e o `catch-up`/`co-evolve` já são um "event history" caseiro; o adapter `a2a-live` deve tratar o `inbound/` commitado como o **checkpoint durável** de onde o modo vivo retoma.

### F12 — Policy-as-data (OPA/Rego): a política decide, não o agente; enforcement na camada de tool-calling
**Claim:** **OPA (Open Policy Agent)** com linguagem **Rego** aplica autorização **na camada de tool-calling, não no agente** — "o agente não decide o que é permitido; a política decide". Quando o agente vai chamar uma tool, a decisão é avaliada contra a policy **antes** de executar; regras versionadas como código. OWASP Top 10 for Agentic Apps (2026) enfatiza minimizar capacidade desnecessária do agente.
**Fontes:** <https://codilime.com/blog/why-use-open-policy-agent-for-your-ai-agents/> · <https://gokhan-gokalp.com/runtime-governance-for-ai-agents-policy-as-code-with-opa/> · <https://www.openpolicyagent.org/docs>
**Materialidade:** high.
**Implicação p/ Onion (D2 + aceitação gated):** este é o **modelo canônico da aceitação gated** que o maestro quer. O `members.yaml` (bloco `trust:` + `specializations` + `mode` + `role`) **já é policy-as-data** — falta ser *avaliado como política* no momento do targeting. Resolve D2 (ruído): em vez de `alvo:` per-id OU broadcast, um resolver estilo OPA computa os destinatários por `specializations`/`mode`/classificação que o `members.yaml` já carrega. Reuso: o `graph.sh` (motor BFS impact/path/closure) é o candidato natural a **avaliar essa política sobre o grafo de membros** — ingerir `members.yaml` + resolver "quem recebe o quê" é um query de closure gated.

### F13 — Convergência de protocolos: ACP (IBM) fundiu no A2A (ago/2025)
**Claim:** O **ACP (Agent Communication Protocol) da IBM fundiu-se no A2A em ago/2025**; a narrativa 2026 é de convergência do stack (MCP + A2A + WebMCP/A2UI) rumo a um "momento TCP/IP" da IA agêntica.
**Fontes:** <https://zylos.ai/research/2026-03-26-agent-interoperability-protocols-mcp-a2a-acp-convergence/> · <https://www.aimagicx.com/blog/mcp-vs-a2a-vs-acp-ai-agent-protocols-guide-2026>
**Materialidade:** medium.
**Implicação p/ Onion:** reduz o risco de fragmentação — há **um alvo dominante** (A2A) para o adapter `a2a-live`, não três. Justifica não gastar esforço em múltiplos protocolos peer; costurar A2A (como o forge SDAAL costura github e deixa gitlab/bitbucket "🔜") é a aposta certa.

### F14 — A2A em produção enterprise; AP2 (pagamentos) com 60+ orgs
**Claim:** A2A tem **deployments de produção** em supply chain, financial services, insurance e IT operations; o repo core passou de **22.000 stars**; a iniciativa irmã **AP2 (Agent Payments Protocol)** reúne 60+ organizações.
**Fonte:** <https://www.linuxfoundation.org/press/a2a-protocol-surpasses-150-organizations-lands-in-major-cloud-platforms-and-sees-enterprise-production-use-in-first-year>
**Materialidade:** medium.
**Implicação p/ Onion:** sinal de maturidade — A2A não é vaporware; é seguro modelar o `federation-transport` sobre seus conceitos (Task/Card/SSE/PushNotification) mesmo antes de implementar o transporte vivo. O modo git-async pode adotar **o vocabulário A2A já hoje** (custo baixo, dividendo alto na migração).

### F15 — Identidade/delegação verificável cross-MCP/A2A é área de pesquisa ativa (hipótese)
**Claim:** Trabalhos recentes (arXiv 2026) propõem **AIP (Agent Identity Protocol) para delegação verificável entre MCP e A2A** e frameworks composicionais de autorização/escopo para delegação em IA agêntica, além de modelos formais de consent ("Anumati: proof of adherence"). Ainda são propostas acadêmicas, não standards.
**Fontes:** <https://arxiv.org/pdf/2603.24775> · <https://arxiv.org/pdf/2606.03518> · <https://arxiv.org/pdf/2604.16524>
**Materialidade:** medium (estágio de pesquisa — tratar como hipótese, não como spec estável).
**Implicação p/ Onion (aceitação gated):** aponta para onde a fronteira de **consent/delegação verificável** vai — relevante quando o Onion for gatear "core A delega a core B falar em seu nome". Por ora, o gate humano do maestro + trust SDAAL cobrem; monitorar sem adotar. Encaixa como direção futura do bloco `trust:`.

---

## Encaixe nas fundações / viabilidade VPS

### Mapa achado → dor P0 → fundação reusada

| Dor P0 do maestro | Achados que informam | Fundação Onion a reusar (não reinventar) |
|---|---|---|
| **D1** — Grana.Ai isolada, sem canal vivo core↔core | F4 (SSE), F5 (webhook), F8 (AAIF), F9 (Agent SDK), F10 (remote MCP), F11 (durable) | `onion-bridge` (já roda `claude-agent-sdk`/`bypassPermissions` na VPS) + **novo adapter `a2a-live`** no `federation-transport` SDAAL |
| **D2** — ruído no targeting `alvo:` | F2 (Agent Card), F12 (OPA policy-as-data) | `members.yaml` (`specializations`/`mode`/`role`/`trust` = policy-as-data) + **`graph.sh` ingerindo `members.yaml`** para resolver destinatários por closure gated |
| **D3** — falta console/histórico/relações | F3 (task lifecycle 8 estados), F14 (produção) | ledger de contratos + CHANGELOG + `federation-status` expostos com o **vocabulário de estados A2A**, servidos como console na VPS |
| **D4** — falta mapa de adoções derivado | F2 (Agent Card/registry), F7 (camada A2A) | **agent-card/mapa derivado do `members.yaml`** via `graph.sh` (gerador-de-seed), servido em subdomínio de `onionevolve.com` |

### O `federation-transport` SDAAL (a costura central)

O precedente está pronto: `task-manager/factory.md` já abstrai transporte `api|mcp` com fallback gracioso, e `forge/factory.md` já mostra que **o default de transporte pode divergir por domínio** com justificativa (forge default = `cli`). Um `federation-transport` segue o mesmo molde:

- **`detectTransport()`** resolve o transporte efetivo por membro (lê `members.yaml`: `capabilities.streaming`/flag por membro + trust);
- **Adapters:** `git-async` (default, sempre disponível — é o doc-bridge atual, o "webhook push offline durável" da F5) · `local` (carteiro-local `co-deliver`/`co-relay` na mesma máquina) · **`a2a-live`** (gated — SSE F4 + push F5 sobre o `claude-agent-sdk` F9);
- **Fallback gracioso idêntico** ao dos irmãos: membro sem `a2a-live` apto → cai para `git-async` (nunca inventa canal, avisa em pt-BR);
- **Aceitação gated** (F6, F12): a autorização mora no **lado receptor** (o adotante), avaliada como policy-as-data do `trust:`/`members.yaml` — o transporte só entrega; o `allowedTools` do SDK headless (F9) é o enforcement concreto.

### Resiliência: o par que o Onion já tem pela metade

A indústria convergiu (F4+F5+F11) em: **SSE quando conectado · webhook push quando offline · checkpoint durável · retomada por resubscribe**. O Onion já opera a metade offline/durável — `inbound/` commitado é o checkpoint; entrega-sem-commit é a garantia "não repetir efeito de saída" (F11). Falta a metade viva (SSE) e a retomada explícita (`SubscribeToTask` ↔ ler o `inbound/` como ponto de retomada). Modelar as duas metades como **um transporte, dois modos** evita bifurcar a doutrina.

### Viabilidade na VPS Hostinger KVM 8 (build-on-VPS leve)

Infra já provada no host `srv1812846` (8 vCPU/32 GB): Caddy com `file_server` + TLS Let's Encrypt automático serve o site; `app.onionevolve.com` já faz `reverse_proxy` para o `onion-bridge` (systemd, `claude-agent-sdk`); DNS via API Hostinger. Isso é suficiente para, **sem infra nova**:

1. **Endpoint A2A/webhook** (F5): novo `reverse_proxy` (ex.: `a2a.onionevolve.com` → porta local) recebendo push e validando JWT/token do `PushNotificationConfig` — o trust SDAAL provê a verificação.
2. **Console + mapa de adoções** (D3/D4): estáticos gerados por `graph.sh` a partir do `members.yaml` + ledger, servidos como `file_server` (ex.: `federation.onionevolve.com`) — build leve, mesmo padrão do site atual.
3. **Remote MCP connector** (F10): opcionalmente expor o core como connector OAuth 2.1 (`mcp.onionevolve.com`) para consumo idiomático por Claude Code de outros cores.

Nenhum item exige Temporal/Kubernetes; o padrão é **build estático + reverse_proxy leve** sobre o que já roda. O `a2a-live` vivo é o único que exige processo headless persistente — e esse processo (o bridge) **já existe**.

### Riscos e lacunas a vigiar (não decididos aqui)

- **Segurança do webhook** (F5/F6): SSRF na validação de URL, replay sem verificação de timestamp/JWT, card tampering. O trust SDAAL precisa cobrir isso antes de ligar `a2a-live`.
- **Identidade/delegação verificável** (F15): ainda pesquisa; o gate humano do maestro segue necessário — não presumir "IA-fala-IA sem humano" como seguro no curto prazo.
- **`graph.sh` ainda não ingere `members.yaml`**: é a peça-ponte para D2/D4 e precisa dessa costura para virar o resolver de policy/registry.

---

## Verificação adversarial

> Verificador adversarial do stream S1 (2026-07-09). Doutrina: "evidência ou abstenção" — o objetivo foi **refutar**, não confirmar por gentileza. Fontes checadas via WebFetch/WebSearch contra os primários (press releases LF, spec oficial `a2a-protocol.org`, docs Anthropic/AWS). Na dúvida → `hypothesis`.

| ID | Veredito | Nota (evidência / lacuna) |
|----|----------|---------------------------|
| **F1** | **confirmed** | Press release LF (abr/2026) sustenta o núcleo material: **v1.0 "first stable specification"**, **150+ orgs** (de 50+ para 150+), clouds nomeadas (**Azure AI Foundry/Copilot Studio, AWS Bedrock AgentCore Runtime**), 22k stars. Ressalva: o passo **"→ AAIF dez/2025"** e a **doação jun/2025** NÃO estão nesse press release; a doação à LF é evento real (projeto A2A lançado ~jun/2025), mas o vínculo A2A↔AAIF é corroborado só por fontes secundárias (ver F8). |
| **F2** | **confirmed** | Spec oficial confirma AgentCard como documento JSON com identidade/capabilities/skills/endpoint/**security schemes**; §14.3 registra a well-known URI. A grafia exata `/.well-known/agent-card.json` não aparece literal no trecho, mas o mecanismo (descriptor buscável sem auth) está confirmado. |
| **F3** | **confirmed** | Spec lista os **8 estados exatos** (`SUBMITTED/WORKING/INPUT_REQUIRED/AUTH_REQUIRED/COMPLETED/FAILED/CANCELED/REJECTED`) e os 3 bindings (§9 JSON-RPC, §10 gRPC, §11 HTTP+JSON/REST). |
| **F4** | **confirmed** | Spec: `SendStreamingMessage`/`SubscribeToTask` gated por `AgentCard.capabilities.streaming` (`false`/ausente → `UnsupportedOperationError`). Reconexão via `SubscribeToTask` confirmada. |
| **F5** | **confirmed** | Spec define `PushNotificationConfig` com `url` (req), `token` (opt), `authentication` (opt). Push em mudanças significativas de estado confirmado no tópico streaming-and-async. |
| **F6** | **confirmed** | A2A reusa schemes OpenAPI declarados no card; autorização/consent no lado receptor é doutrina consistente com o tópico enterprise-ready da spec. Claim descritivo, sem exagero. |
| **F7** | **confirmed** | Framing MCP=vertical/tools · A2A=horizontal/peer é **consenso** repetido em múltiplas fontes 2026 (dev.to, zylos, onereach). Não é controverso. |
| **F8** | **hypothesis** | **Refutação parcial do primário.** A formação da **AAIF em 09-dez-2025** e os co-fundadores (OpenAI, Anthropic, Google, Microsoft, AWS, Block — subconjunto correto dos 8 platinum, que somam ainda Bloomberg/Cloudflare) estão **confirmados**. PORÉM o press release primário da AAIF **NÃO menciona A2A** — os projetos-âncora são **só MCP, goose, AGENTS.md** — e **não declara spec conjunta de interop MCP↔A2A**. A afirmação "AAIF governa MCP **e** A2A" e o "esforço declarado de spec conjunta" vêm **apenas de fontes secundárias/terciárias** (intuitionlabs, zylos), não do primário citado. Rebaixado a hypothesis: o vínculo A2A↔AAIF é plausível mas não sustentado pela fonte citada. |
| **F9** | **confirmed** | Rename **Claude Code SDK → Claude Agent SDK em 29-set-2025** confirmado (docs Anthropic + npm `@anthropic-ai/claude-agent-sdk`). Subagents paralelos + contexto isolado confirmados. `permissionMode: dontAsk`/Workflow tool são detalhes plausíveis não literalmente re-verificados, mas o núcleo é sólido. |
| **F10** | **confirmed** | Remote MCP exige OAuth 2.1 + PKCE (spec MCP) e o Claude expõe MCP connector/Integrations — amplamente documentado. Materialidade medium, claim sem exagero. |
| **F11** | **confirmed** | **AWS Lambda Durable Functions anunciado no re:Invent (dez/2025)** confirmado (InfoQ 2025/12 + AWS what's-new 2025/12): checkpoints + replay pulando trabalho concluído = exatamente "retomar sem repetir efeitos". Azure Durable Task for AI agents (abr/2026) citado via learn.microsoft.com; o pilar AWS está sólido. |
| **F12** | **confirmed** | OPA/Rego como policy-as-data avaliada na camada de tool-calling antes da execução é descrição correta e bem-documentada do OPA. A aplicação a agentes de IA é área emergente (não madura), mas o mecanismo canônico está certo. |
| **F13** | **confirmed** | **ACP (IBM) fundiu no A2A em ago/2025** confirmado pelo primário **LFAI & Data ("ACP Joins Forces with A2A", 29-ago-2025)** + repo ACP arquivado 27-ago-2025; Kate Blair (IBM) entrou no TSC do A2A. |
| **F14** | **confirmed** | Mesmo press release LF sustenta: produção em supply chain/finance/insurance/IT ops, **22.000+ stars**, **AP2 com 60+ orgs**. Sinal de maturidade real. |
| **F15** | **hypothesis** | Auto-rotulado hypothesis pelo próprio pesquisador (correto). Os **arXiv IDs citados (2603.24775, 2606.03518, 2604.16524) NÃO foram verificados individualmente** — risco residual de citação frágil. A direção (identidade/delegação verificável = pesquisa ativa, não standard; gate humano segue necessário) é prudente. Mantido hypothesis. |

**Síntese do verificador:** o núcleo material do stream é **sólido e reusável** — todas as 5 afirmações de nível-spec (F2–F5) e o lifecycle (F3) batem literalmente com a spec oficial; a maturidade de mercado (F1/F14), a convergência (F13) e o motor de execução (F9/F11) estão confirmados em primários. **Duas ressalvas** que não derrubam a tese mas exigem honestidade no texto: (a) **F8** superdimensiona o primário da AAIF — A2A **não** figura entre os projetos-âncora nem há "spec conjunta" declarada na fonte citada; tratar o vínculo A2A↔AAIF como corroborado-por-secundárias, não como fato do primário; (b) **F15** carrega arXiv IDs não verificados — manter como direção, nunca como base de decisão. Nenhum achado material foi **refutado por completo**; o encaixe Onion (adapter `a2a-live` gated sobre `claude-agent-sdk`, `members.yaml` como policy-as-data) permanece bem-fundado.
