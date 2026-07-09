# G1 — Handshake `a2a-live` GATED em contexto regulado + Human-in-the-Loop

> **Stream G1 · 2ª rodada (fechar gaps) do redesign da Federação Onion (2026).**
> Objetivo desta rodada: **firmar** o desenho do handshake `a2a-live` **gated** para um adotante
> regulado (o caso **Grana.Ai**: fintech, monorepo nx privado, `integration_branch: develop`,
> **nunca live-pull**) e **fechar** o gap explícito do SYNTHESIS §"O que ainda falta pesquisar" —
> *"Especificação do handshake `a2a-live` gated … como o gate humano + `pin-integrity-check` se
> encaixam no lifecycle A2A."*
>
> **Natureza:** insumo de evidência para a decisão do maestro — **não decide doutrina**. Cada achado
> material tem FONTE (URL). Sem fonte sólida = `materiality: low` / hypothesis. Prioridade a fontes
> primárias (spec oficial A2A, IETF OAuth 2.1, docs de fornecedor) e ao recorte 2025-2026.

---

## Resumo

O gate humano assíncrono que o Onion precisa para o handshake regulado **já é um cidadão de primeira
classe da spec A2A** — não é um enxerto. A A2A modela dois **estados de interrupção** nativos
(`input-required` e `auth-required`) que **pausam a task** aguardando algo do lado do cliente, e é
exatamente aí que o **gate do maestro** se encaixa (G1·F1). Mais forte: a spec **delega ao cliente**,
"fora do protocolo A2A", a obtenção de credenciais/consentimento secundários (G1·F2) — ou seja, a A2A
já assume que a autorização mora **out-of-band**, que é precisamente onde o maestro (humano) e o
`pin-integrity-check` vivem. A autenticação A2A é **agent-card-driven** e **transport-only** (sem
identidade no payload), declarando `securitySchemes` OpenAPI (OAuth 2.0/2.1, OIDC, mTLS, apiKey)
(G1·F3), com PKCE **obrigatório** no substrato OAuth 2.1 (G1·F4).

Do lado do RECEPTOR — o ponto mais crítico para um regulado — a spec A2A **manda** verificar a
autenticidade **antes** de agir: webhook assina/valida **JWS/JWT** (`iss/aud/iat/exp/jti`, JWKS por
`kid`), rejeita notificação velha por timestamp, usa `jti` single-use anti-replay (G1·F5), e proíbe
confiar cegamente em URL de cliente contra **SSRF** (allowlist + ownership challenge + egress firewall)
(G1·F6). O reforço de fornecedor acrescenta **assinar o Agent Card** para integridade/autenticidade,
validar cert TLS contra CA confiável, manter o parser JSON-RPC patchado, e o cliente **verificar que a
notificação vem de servidor confiável E é relevante** (G1·F7). O padrão mecânico do "gate humano no
meio de um protocolo async" é o **durable-execution pause/resume por signal** (Temporal): a task
suspende com **zero compute**, estado persistido, aprovação chega como Signal, timer durável faz
SLA/escalonamento/auto-reject (G1·F8). Por fim, o achado **rebaixado** S1·F15 (AIP — delegação
verificável cross-MCP/A2A) foi **verificado** nesta rodada: o arXiv existe e afirma o que se disse,
mas é **preprint de autor único** → sobe de "id não-verificado" para "confirmado-mas-baixa-autoridade",
direção futura do bloco `trust:`, **não** doutrina (G1·F9).

**Veredito de desenho:** o handshake `a2a-live` gated para o Grana.Ai **não precisa inventar** o gate —
mapeia o `auth-required`/`input-required` da A2A ao gate do maestro, roda o `pin-integrity-check` (trust
SDAAL) como a verificação-antes-de-agir que a própria spec A2A já exige do receptor, e trata todo
payload remoto como supply-chain não-confiável até assinatura+anti-replay+anti-SSRF passarem. O
"nunca live-pull" do regulado é **compatível** com A2A: usa-se o par durável (webhook/push + `GetTask`)
como transporte de **sinais gated**, não de live-pull automático.

---

## Achados

### G1·F1 — A A2A tem estados de interrupção nativos (`input-required`, `auth-required`) que PAUSAM a task — o ponto de acoplamento natural do gate humano assíncrono
**Claim:** O lifecycle A2A distingue **estados terminais** (`completed`, `canceled`, `failed`,
`rejected`) de **estados de interrupção** (`input-required`, `auth-required`). A spec: *"the agent will
process it through a defined lifecycle … until it reaches an **interrupted state** (e.g.,
`input-required`, `auth-required`) or a terminal state."* O `input-required` sinaliza que a task está
**pausada aguardando entrada** ("If there is ambiguity or insufficient context, the agent should respond
with an `input-required` task state to request clarification from the client").
**Fonte:** https://a2a-protocol.org/latest/topics/life-of-a-task/ (spec oficial A2A, primária)
**Materialidade:** HIGH (confirmed)
**Implicação p/ Onion:** o gate do maestro **não é enxerto no protocolo** — é o consumo idiomático de
`input-required`/`auth-required`. No handshake `a2a-live`, um contrato/sinal recebido do core entra como
task que **pausa em `input-required`** (maestro revisa) ou **`auth-required`** (falta consentimento/
verificação de integridade) antes de virar ação. Firma o mapeamento já esboçado no S1·F3 (lifecycle 8
estados) com a distinção explícita **interrupted ≠ terminal**, que é o que torna o gate **assíncrono e
retomável** (a task não morre; espera).

### G1·F2 — `auth-required` DELEGA ao cliente a obtenção de credenciais/consentimento "fora do protocolo A2A" — a autorização mora out-of-band (onde o maestro humano já está)
**Claim:** A spec enterprise-ready afirma que, quando o agente precisa de credenciais adicionais para
outro sistema durante a task, *"the client is then responsible for obtaining these secondary credentials
through a process **outside of the A2A protocol itself**."* Isto é o mecanismo do `auth-required`: o
servidor **não** resolve auth sozinho — ele **devolve a responsabilidade ao cliente** por um caminho
fora-de-banda.
**Fonte:** https://a2a-protocol.org/latest/topics/enterprise-ready/ (spec oficial A2A, primária)
**Materialidade:** HIGH (confirmed)
**Implicação p/ Onion:** é a **peça-chave do gap**. O "gate humano assíncrono" que o Onion queria não
contradiz a A2A — **é o desenho previsto**. O `auth-required` é onde o maestro + `pin-integrity-check`
(trust SDAAL) entram como o "processo fora do protocolo" que obtém/verifica a autorização antes de a
task prosseguir. Para o regulado (Grana.Ai), isto legaliza "sem live-pull automático": o consentimento é
**explicitamente** delegado ao lado que tem contexto e política (o maestro), não concedido pelo canal.

### G1·F3 — Auth A2A é agent-card-driven e transport-only (SEM identidade no payload); `securitySchemes` OpenAPI declaram OAuth2/OIDC/mTLS/apiKey
**Claim:** A2A trata agentes como **opacos** e **não carrega identidade no payload**: *"No Identity in
Payload: A2A protocol payloads … don't carry user or client identity information directly"* e
*"Credentials **must** be transmitted in standard HTTP headers"*. O Agent Card declara `security`/
`securitySchemes` alinhados a OpenAPI (`apiKey`, `http`, `oauth2`, `openIdConnect`, `mtls`), e o servidor
responde `401` (com `WWW-Authenticate`) / `403` conforme o caso. O cliente **descobre** o esquema
buscando o Agent Card público **sem autenticação** e então inicia o fluxo apropriado.
**Fonte:** https://a2a-protocol.org/latest/topics/enterprise-ready/ · corroboração:
https://a2a-protocol.org/latest/specification/ (spec oficial A2A, primária)
**Materialidade:** HIGH (confirmed)
**Implicação p/ Onion:** o `a2a-live` do Onion se hospeda atrás do Caddy já existente, publica Agent Card
em `/.well-known/agent-card.json` (path corrigido vs `agent.json` do S2·F12) declarando `oauth2`/`mtls`,
e **não** inventa sistema de identidade — reusa o transporte. O bloco `trust:` do `members.yaml` é a
camada de autorização **acima** do transporte (a spec explicitamente deixa a authz para a implementação
do agente: "Authorization is delegated to agent implementations … skill-level permissions via OAuth
scopes … least-privilege").

### G1·F4 — O substrato OAuth 2.1 torna PKCE OBRIGATÓRIO e exact-match de redirect — base de consentimento para o handshake gated
**Claim:** OAuth 2.1 (draft-ietf-oauth-v2-1, late-stage IETF) consolida OAuth 2.0 e torna **PKCE
obrigatório para todos os clientes** que usam authorization-code flow, exige **exact string matching** de
redirect URIs, e **remove** os grants Implicit e Resource-Owner-Password. "PKCE is required for all OAuth
clients using the authorization code flow … no exceptions."
**Fonte:** https://oauth.net/2.1/ · https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1 (IETF,
primária — ressalva: ainda é **draft**, não RFC final)
**Materialidade:** MEDIUM-HIGH (confirmed; ressalva de draft)
**Implicação p/ Onion:** quando/se o `a2a-live` ou o Remote-MCP-connector (S1·F10) expuser o core, o fluxo
de consentimento deve ser **OAuth 2.1 + PKCE** (não implicit, não password) — o padrão que o Claude Code
já usa para MCP remoto. Para o regulado, PKCE + exact-redirect fecham dois vetores clássicos (code
interception, open-redirect) **antes** do gate humano, deixando o gate para a decisão de negócio, não
para higiene de protocolo.

### G1·F5 — O receptor DEVE verificar autenticidade antes de agir: JWS/JWT assinado (`iss/aud/iat/exp/jti`, JWKS por `kid`) + anti-replay por timestamp e `jti` single-use
**Claim:** Na spec de streaming/async, *"The webhook endpoint **MUST rigorously verify the authenticity**
of incoming notification requests."* O fluxo assimétrico: servidor A2A assina JWT com chave privada
(claims `iss`, `aud`, `iat`, `exp`, `jti`), expõe chave pública via **JWKS**, receptor busca a chave pelo
`kid` e valida assinatura + claims. Anti-replay: *"Notifications SHOULD include a timestamp. The webhook
SHOULD reject notifications that are too old"* e *"consider using unique, single-use identifiers (for
example, JWT's `jti` claim or event IDs)."*
**Fonte:** https://a2a-protocol.org/latest/topics/streaming-and-async/ (spec oficial A2A, primária) ·
corroboração vendor: https://a2awire.com/content/a2a-push-notifications/
**Materialidade:** HIGH (confirmed)
**Implicação p/ Onion:** é o **`pin-integrity-check` do lado A2A**, já normativo na spec. Todo sinal que
chega pelo `a2a-live` passa por verificação de assinatura JWS + `jti` single-use + janela de timestamp
**antes** de virar task/ação — exatamente a doutrina "declarado ≠ verificado" do trust SDAAL. Fecha o
"como o `pin-integrity-check` se encaixa": ele roda **na fronteira do receptor**, na transição
transport→task, não depois.

### G1·F6 — Anti-SSRF é normativo: o servidor A2A NÃO deve confiar cegamente em URL de cliente (allowlist + ownership challenge + egress firewall)
**Claim:** *"Servers **SHOULD NOT blindly trust and send POST requests to any URL** provided by a client."*
Mitigações da spec: *"Allowlisting of trusted domains, ownership verification (for example,
challenge-response mechanisms), and network controls (e.g., egress firewalls)."* Reforço de fornecedor:
validar IP resolvido, **bloquear localhost, faixas privadas e metadata endpoints**; webhook HTTPS
obrigatório.
**Fonte:** https://a2a-protocol.org/latest/topics/streaming-and-async/ (spec oficial A2A, primária) ·
https://tyk.io/learning-center/a2a-security-the-developers-complete-guide/
**Materialidade:** HIGH (confirmed)
**Implicação p/ Onion:** o `PushNotificationConfig.url` de qualquer membro é **input não-confiável**. Para
o regulado, o allowlist de domínios de webhook sai direto do `members.yaml` (os hosts conhecidos dos
membros), e o egress da VPS Hostinger bloqueia faixas internas/metadata. Isto endurece o "receiver que
acorda a sessão" (candidato #4 do SYNTHESIS) contra ser usado como pivô SSRF.

### G1·F7 — Defesa-em-profundidade do receptor: Agent Card ASSINADO, TLS contra CA confiável, parser JSON-RPC patchado, e o cliente verifica "vem de servidor confiável E é relevante"
**Claim:** O Agent Card é *"the protocol's … primary attack surface"*; um card adulterado/spoofado
compromete toda a interação. Mitigações: *"signing an Agent Card can also provide for its authenticity
and integrity"*, validar o cert TLS do agente remoto contra CAs confiáveis, manter o parser JSON-RPC 2.0
sem vulnerabilidades conhecidas, replay via **nonce + timestamp + MAC**, e — crucial — *"the A2A client
**must verify that the notification comes from a trusted A2A server and must validate that the
notification is relevant**."* A A2A **não tem** controle nativo contra cross-agent prompt-injection;
recomenda-se defense-in-depth (TLS, trusted agents, authn/authz, least-privilege).
**Fonte:** https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security (Red Hat,
fornecedor reputado) · https://dev.to/kanywst/a2a-protocol-auth-taken-apart... (secundária)
**Materialidade:** HIGH (confirmed via fornecedor; a ausência de controle nativo de prompt-injection é o
ponto mais material)
**Implicação p/ Onion:** valida **verbatim** a cautela do SYNTHESIS (§P0-1) de que o `a2a-live` deve
**transportar sinais gated, não conversas autônomas**: como a A2A **não protege** contra prompt-injection
cross-agent, deixar IA-fala-IA autônoma expõe o receptor a payload hostil que vira ação. O gate humano +
`pin-integrity-check` + "notificação precisa vir de servidor confiável E ser relevante" são a defesa. O
Agent Card do core deve ser **assinado** (integridade), fechando o vetor "card spoofado".

### G1·F8 — O padrão "gate humano no meio de um protocolo async" é o durable-execution pause/resume por signal: suspende com zero compute, estado persistido, aprovação chega como Signal, timer durável faz SLA/escalonamento
**Claim:** Em durable execution (Temporal), o workflow chama `wait_condition()` e *"the Worker returns the
current task to the Temporal Server and becomes idle — consuming no compute"*; o estado persiste no
servidor. A decisão humana chega como **Signal** (`ApprovalDecision`), o servidor reescala a task, replay
do event-history reconstrói o estado e a execução **retoma exatamente do ponto de pausa**. **Timers
duráveis** impõem SLA: *"fire precisely when a deadline expires — no external scheduler, no polling loop,
no cron job"*; no timeout, escala para aprovador backup ou auto-rejeita. Anti-padrão explícito:
*"Patching this with a database, a cron job, a notification service, and custom reconciliation logic means
maintaining four systems to do one thing."*
**Fonte:** https://temporal.io/blog/human-in-the-loop-approvals · https://docs.temporal.io/ai-cookbook/human-in-the-loop-python
(docs/fornecedor primário de durable execution)
**Materialidade:** HIGH (confirmed)
**Implicação p/ Onion:** é o **modelo mecânico** do gate gated e a ponte conceitual com o A2A: o par
`input-required`/`auth-required` (G1·F1) **é** um `wait_condition`, e o "maestro transporta o anúncio"
**é** o Signal. O Onion **já tem** a metade durável em git-async (o `inbound/` commitado = checkpoint
persistido, entrega-sem-commit = idempotência ≈ "não repetir efeito de saída"). O achado firma que o gate
assíncrono do Onion **não precisa de Temporal/Kubernetes** — o padrão é o mesmo, e o substrato durável do
Onion (git append-only + inbox) já o realiza; o `a2a-live` só adiciona a **metade viva** (SSE/webhook)
para acordar o gate mais rápido, sem trair o "nunca live-pull".

### G1·F9 — [CONFIRMA rebaixado S1·F15] AIP (Agent Identity Protocol) existe e afirma delegação VERIFICÁVEL cross-MCP/A2A — mas é preprint de autor único → direção futura do `trust:`, não doutrina
**Claim:** O arXiv **2603.24775v1** ("AIP: Agent Identity Protocol for Verifiable Delegation Across MCP
and A2A", Sunil Prakash, gerado 2026-03-27, CC-BY-4.0) propõe propagar **identidade, consentimento e
autorização** por fronteiras de protocolo heterogêneas (MCP e A2A) via **delegation tokens** +
**scopes** (limites finos de permissão) + **verifiable credentials** (W3C DID). Na 1ª rodada, S1·F15
foi **rebaixado a hypothesis** por "arXiv IDs não verificados individualmente". Nesta rodada o PDF foi
**buscado e lido**: o paper **existe e afirma o que se disse** — porém é **preprint, autor único, não
peer-reviewed**.
**Fonte:** https://arxiv.org/pdf/2603.24775 (arXiv, primária — preprint; PDF verificado nesta rodada)
**Materialidade:** MEDIUM (o vínculo agora é confirmed; a **autoridade** permanece baixa — 1 autor,
preprint). Não sustenta decisão de doutrina.
**Implicação p/ Onion:** **refuta** a parte "id não-verificado" do rebaixamento (o paper é real e
sourceável), mas **mantém** a cautela: é sinal de que "delegação verificável cross-protocolo" é problema
**reconhecido e em pesquisa ativa** — direção plausível para evoluir o bloco `trust:`/`members.yaml`
(delegação com escopo, consentimento propagável) **quando/se** o mercado consolidar. Hoje, o Onion não
deve assumir AIP como padrão pronto; o `pin-integrity-check` + trust-log (reputação-por-evidência,
S4·F3) cobrem a necessidade atual. Alinha ao S2 alert "registry de capacidade governado é problema
não-resolvido" — manter `a2a-live`/delegação **gated**.

---

## Resolução do gap

**O que esta rodada FECHA do SYNTHESIS §"O que ainda falta pesquisar":**

- **[FECHADO] "Especificação do handshake `a2a-live` gated … como o gate humano + `pin-integrity-check`
  se encaixam no lifecycle A2A."** A evidência resolve as quatro pontas do FOCO:
  - **(a) estados A2A → gate humano assíncrono:** `input-required`/`auth-required` são **estados de
    interrupção nativos** que pausam a task de forma retomável (G1·F1), e `auth-required` **delega ao
    cliente, fora do protocolo**, a obtenção de consentimento/credenciais (G1·F2) — o gate do maestro é o
    consumo idiomático desses estados, não um enxerto. Mecanicamente, é um durable-pause por Signal
    (G1·F8), que o substrato git-async do Onion já realiza.
  - **(b) autenticação/consent/authz:** auth **agent-card-driven + transport-only**, `securitySchemes`
    OpenAPI (OAuth2/OIDC/mTLS/apiKey), authz delegada à implementação via scopes/least-privilege
    (G1·F3), sobre substrato **OAuth 2.1 + PKCE obrigatório** (G1·F4).
  - **(c) defesa do receptor antes de virar ação:** a própria spec A2A **manda** verificar autenticidade
    (JWS/JWT `iss/aud/iat/exp/jti`, JWKS por `kid`), anti-replay (`jti` single-use + janela de timestamp)
    (G1·F5) e anti-SSRF (não confiar em URL de cliente; allowlist + ownership challenge + egress firewall;
    bloquear metadata/privado) (G1·F6); fornecedor acrescenta **Agent Card assinado**, TLS contra CA,
    parser patchado, e "notificação de servidor confiável E relevante" (G1·F7). Isto é **onde** o
    `pin-integrity-check` roda: na fronteira transport→task do receptor.
  - **(d) gate humano no meio de async:** durable-execution pause/resume por signal com timer de SLA/
    escalonamento/auto-reject (G1·F8) — padrão maduro, e o Onion já tem a metade durável (inbox
    commitado = checkpoint; entrega-sem-commit = idempotência).

- **[FIRMADO — achado rebaixado] S1·F15 (AIP delegação verificável cross-MCP/A2A):** o arXiv 2603.24775v1
  foi **verificado** (PDF lido). Sobe de "id não-verificado" para **confirmed-mas-baixa-autoridade**
  (preprint, autor único) → direção futura do `trust:`, **não** base de doutrina (G1·F9).

**O que NÃO se reabriu (já sólido na 1ª rodada — não tocado):** par de resiliência A2A (SSE + webhook +
lifecycle 8 estados + resubscribe, S1·F2/F3/F4/F5), maturidade A2A/ACP-fundido (S1·F1/F13/F14), motor
`onion-bridge`/claude-agent-sdk (S1·F9), policy-as-data OPA (S1·F12). Esta rodada **acrescenta
granularidade normativa** sobre eles (o receptor A2A tem obrigações `MUST`/`SHOULD` de verificação),
não os substitui.

**Ganchos concretos para o desenho (dogfood, não pesquisa de mercado):**
1. O `federation-transport` SDAAL adapter `a2a-live` publica **Agent Card assinado** em
   `/.well-known/agent-card.json` com `securitySchemes: [oauth2 (2.1+PKCE), mtls]`.
2. Sinal recebido entra como task que **pausa em `input-required`/`auth-required`** → gate do maestro.
3. Na fronteira do receptor, **antes** de virar task: verificar JWS (`kid`→JWKS), `jti` single-use,
   janela de timestamp, allowlist de URL derivado do `members.yaml`, egress bloqueando privado/metadata —
   este é o `pin-integrity-check` do lado A2A.
4. Para o Grana.Ai regulado: o transporte carrega **sinais gated** (contrato/anúncio), nunca live-pull;
   o consentimento é **out-of-band** por construção da spec (`auth-required` delega ao cliente).

**Limites honestos:** OAuth 2.1 ainda é **draft** IETF (estável, mas não RFC final) — G1·F4. AIP é
**preprint autor-único** — G1·F9, não citar como padrão. O reforço de receptor mais rico (G1·F7) é
**fornecedor** (Red Hat), primário para a spec só onde cita a A2A diretamente. A A2A **não tem** controle
nativo de prompt-injection cross-agent (G1·F7) — este é o argumento técnico mais forte para o
`a2a-live` transportar **só sinais gated**, decisão que permanece do maestro.
