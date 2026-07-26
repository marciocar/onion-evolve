---
title: "M2 — DESENHO de auth do Onion-Bridge (Logto OIDC, grant DUPLO) + perguntas abertas ao host"
category: meta
tags: [seguranca-defensiva, onion-bridge, logto, oidc, pkce, authorization-code, m2m, client-credentials, jwt, jwks, rfc8707, route-scoping, path-traversal, middleware-order, fail-closed, auth-token, bypasspermissions, systemd, cgroup-v2, memorymin, turnkey, spec-as-code]
status: DESENHO verificado + BRIDGE LIDO (4/5 perguntas respondidas — ver §0.0/§0.2; premissa do "buraco" corrigida)
date: 2026-07-26
revision: "v3 — corrigido após o 2º verify adversarial (14 fixes A–N), com achados MEDIDOS ao vivo neste host: teto de ancestral zerando os floors, path-traversal furando a allowlist, ordem de registro do middleware, slice path errado, comando de prova do RFC 8707 quebrado"
deciders: maestro (Marcio)
context_freshness: 2026-07-26
kg: docs/onion/graph/m2-bridge-logto-2026-07.kg.yaml
---

# M2 — desenho de auth do Onion-Bridge (+ perguntas abertas)

## §0 — O que este documento É e o que NÃO é (leia antes de executar qualquer coisa)

> ## ⚠️ §0.0 — LEIA PRIMEIRO: o bridge FOI LIDO (2026-07-26) e a premissa deste doc estava ERRADA
>
> **Tudo abaixo desta caixa foi escrito ANTES de ler o código do bridge.** O bridge é legível deste
> host com `sudo` (`sudo ls /home/onion/onion-bridge/`) — a sessão não tentou, e por isso três rodadas
> especificaram *em volta* de desconhecidos que eram **um comando de distância**. As respostas estão
> em **§0.2**, que **SUPERSEDE** o que o corpo do documento afirma sobre rotas, ambiente e SSE.
>
> **A correção que mais importa — o buraco NÃO era o que se afirmou.** Este doc (e o plano que o
> originou) descreve `app.onionevolve.com` como tendo o Agent SDK **"sem gate de identidade"**.
> **Falso.** Toda rota sensível já exige `Bearer` hoje: `/chat` e `/commands` (`authGuard`),
> `/a2a` (`a2aGuard`), `/admin/*` (`adminGuard`) — e o `serveStatic` catch-all é o **último**
> registrado (ordem já correta). O que **falta é IDENTIDADE, não gate**: `AUTH_TOKEN` é segredo
> **compartilhado** e os `INVITE_TOKENS_{COURTESY,BYOK,A2A}` são **convites**, não usuários.
> Logo o M2 é **melhoria** (trocar segredo compartilhado por identidade por-pessoa), **não incêndio**.
> O risco real e nomeável é `PERMISSION_MODE` default = **`bypassPermissions`** (`src/config.ts:26`):
> quem porta qualquer token válido executa irrestrito no clone do core — e hoje **não se sabe quem**.
>
> ---
>
> ### §0.2 — RESPOSTAS medidas (superseden o corpo)
>
> **1. Rotas** — inventário real (`src/server.ts`). **Não existe `/invoke`**; o doc o inventou.
>
> | Rota | Estado HOJE |
> |---|---|
> | `POST /chat` | **já protegida** (`authGuard`) — é aqui que o Agent SDK roda |
> | `GET /commands` | **já protegida** (`authGuard`) |
> | `POST /a2a` | **já protegida** (`a2aGuard`, pool `INVITE_TOKENS_A2A` dedicado) |
> | `/admin/*` | **já protegida** (`adminGuard`) |
> | `GET /health` | aberta (correto) |
> | `GET /.well-known/agent-card.json` | aberta **por design** (descoberta A2A) |
> | `/*` | `serveStatic` da PWA — **último registrado** |
>
> Bônus medido: `/chat` já tem **rate-limit** (janela deslizante, `RATE_LIMIT_PER_MIN`, default 20).
>
> **2. Ambiente** — `process.loadEnvFile()` (Node 22 nativo, `src/config.ts:6`) lendo
> **`/home/onion/onion-bridge/.env`** (existe, 671 B; há 4 `.env.bak-*` de rotações anteriores).
> **Não é `EnvironmentFile=` do systemd** — a unit só tem `Environment=NODE_ENV=production`.
> ⇒ `BRIDGE_AUTH_MODE` vai no **`.env`**, e o rollback é editar/remover a linha + `systemctl restart onion-bridge`.
>
> **3. SSE** — **já resolvido no código, sem trabalho a fazer.** `POST /chat` responde SSE via
> `streamSSE` (Hono), e a PWA consome com **`fetch` + `ReadableStream`** — não `EventSource`.
> O comentário em `web/src/runtime/sse.ts:2` e `public/app.js:2` diz o porquê ("EventSource só faz GET
> sem body"). ⇒ o header `Authorization` **já trafega**; a preocupação do corpo **não se aplica**.
>
> **4. `/a2a`** — tem guard próprio, pool de token dedicado, e **rejeita explicitamente** courtesy/byok
> (*"um remetente a2a não ganha acesso ao /chat"*). **Não é buraco**; não precisa de cobertura dupla.
>
> **5. Usuário no Logto** — ÚNICA ainda aberta (é no tenant Logto, não no bridge).
>
> ### §0.3 — O que isso muda no trabalho
>
> O desenho de auth (grant duplo PKCE+M2M, fail-closed, alg pinado, escada do `resource=`) **permanece
> válido**. O que encolhe é a **execução**: não há default-deny a construir (as rotas certas já estão
> protegidas, na ordem certa), não há SSE a migrar, e o inventário de rotas é o da tabela acima.
> **O trabalho real é: adicionar validação de JWT como caminho alternativo dentro do `authGuard` que
> já existe** (`src/server.ts`), preservando os tokens legados atrás do `BRIDGE_AUTH_MODE` até o P9.
> As seções §3.4/§3.4b/§3.4c (route-scoping, canonicalização, ordem de registro) viram
> **defesa-em-profundidade opcional**, não pré-requisito.
>
> ---

> **Correção de moldura (2026-07-26).** Este documento nasceu rotulado "SPEC TURNKEY" e passou por **três
> rodadas de verificação adversarial**. As duas primeiras corrigiram o desenho; a terceira concluiu que os
> passos prescreviam comandos contra um sistema que a sessão **não havia lido** — conclusão correta na
> época, mas o motivo estava errado: não era *impossível* ler, era *não-tentado* (ver §0.0). Medições que
> derrubaram passos "turnkey": o serviço roda `tsx src/server.ts` (**não há `dist/`**, então o dump de
> rotas do P0.2 não roda), a unit **não tem `EnvironmentFile=`** (só `Environment=NODE_ENV=production`,
> então o flip e o rollback "por uma linha" não têm base), e `crontab -l` como `marcio` volta **vazio**
> (as entradas vivem no crontab do **root**).
>
> **O que ISTO É — e vale:**
> - **O DESENHO de auth**, verificado 3×: grant **duplo** (Authorization Code + PKCE para o humano na PWA;
>   client_credentials M2M para o serviço), **default-deny** de rotas com allowlist ancorada,
>   **fail-closed no parsing** (ausente/typo ⇒ enforce; o flip é *remover* a linha), **algoritmo pinado**,
>   recusa explícita de downgrade, escada `A→B1→B2→B3` para o `resource=` (RFC 8707) com prova antes.
>   Nada disso depende dos desconhecidos do host.
> - **As PERGUNTAS CERTAS** a responder ao abrir o bridge (§0.1).
> - **Achados medidos** no host que valem por si (§5).
>
> **O que ISTO NÃO É:** um runbook pronto para colar. Os passos **P0–P9 são ESQUELETO** — a sequência e a
> intenção estão certas; **cada comando precisa ser validado contra o bridge real** antes de rodar.
>
> ### §0.1 — Perguntas abertas ~~(respondê-las converte o esqueleto em runbook)~~
>
> ✅ **4 das 5 RESPONDIDAS em 2026-07-26 — ver §0.2.** Restou só a (4) Logto. As perguntas ficam
> registradas abaixo como estavam (append-mostly: a história da investigação não se apaga), mas
> **o que vale hoje é o §0.2**.
> 1. **Rotas:** qual o inventário real de rotas do app Hono, e quais tocam o Agent SDK? (o default-deny
>    depende disso — e `app.use('*', …)` precisa ser o **primeiro** handler registrado)
> 2. **Ambiente:** de onde vem `process.env` no bridge — drop-in systemd, `.env` + dotenv, outro? (define
>    onde mora `BRIDGE_AUTH_MODE` e como o rollback funciona)
> 3. **SSE:** como a PWA consome o stream? `EventSource` **não envia** header `Authorization` — se for o
>    caso, migrar para `fetch` + `ReadableStream` (token em query string está **recusado**: vaza em log/Referer)
> 4. **Logto:** o usuário do maestro já existe no tenant? (o P3.4 desliga o sign-up **antes** do login
>    humano do P4.2 — se o usuário não existir, fecha o caminho)
> 5. **`/a2a`:** tem gate próprio de 6 camadas — cobertura dupla ou exceção documentada?
>
> ---

> **Postura de execução:** **segurança defensiva**. O documento desenha o fecho do buraco
> de identidade do bridge e entrega os **passos numerados, reversíveis** do flip — mas **quem executa o flip
> de auth ao vivo é o maestro**. A razão é **risco de lockout**, não uma proibição genérica de operar o host:
> uma sessão que erra o gate de identidade da própria porta de entrada pode se trancar (e trancar o maestro)
> fora da conveniência mobile, e o rollback exige acesso ao host por outro canal. Vale também a doutrina
> **"o servidor é o verificado"** (`2026-07-05-vps-lineage-odyssey.md:48`): docs de deploy são declaração;
> o estado real mora em `srv1812846`.
> **Este spec NÃO promete o SSOT de inferência L1–L6** nem qualquer camada de autorização fina de produto:
> o escopo é trocar um segredo compartilhado por uma identidade emitida/validada, e endurecer o host.
> Tudo que depende do estado real de produção que **esta sessão não mediu** (Caddyfile, valor do token,
> config do Agent SDK, **inventário de rotas do app Hono**) segue marcado como **VPS-declarado**.

> **Fronteira honesta de execução (o que já foi aplicado, e por quem) — [CORRIGIDO H].** Este VPS
> (`srv1812846`) **é a casa do core**: a sessão do core roda **dentro dele**. O endurecimento **não-auth**
> descrito no §5 (crontab do verifier, drop-ins de memória de Caddy e bridge) foi **aplicado AO VIVO por uma
> sessão ANTERIOR do core**, não pelo maestro à mão — os drop-ins em `/etc/systemd/system/*.service.d/10-memory-protection.conf`
> (mtime `2026-07-25 19:00`) carregam o comentário-narrativa em pt-BR da própria sessão. A fronteira real,
> portanto, **não é "a sessão nunca toca o host"** — é: **hardening não-auth, a sessão aplica e mede; FLIP DE
> AUTH, não** (risco de lockout). Confundir as duas foi o que produziu o erro do §5 desta v2, corrigido em A.

> **Invariante I3 — citação corrigida [CORRIGIDO G].** As versões anteriores citaram "I3" como *"a sessão do
> core não opera o host"*. **Errado.** O I3 canônico é **"um escritor por repo / entrega-sem-commit — o core
> nunca commita em repo alheio"** (`docs/technical-context/03-domain/business-logic.md:179`;
> `docs/evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md:233`). A postura de
> não-flipar-auth **se mantém**, mas ancorada onde de fato se ancora: **"o servidor é o verificado"** +
> **risco de lockout**. A citação errada foi corrigida nos 4 lugares (aqui, §4 preâmbulo, e 2 nós do KG).

> **Revisão v3 (2026-07-26).** A v2 foi **reprovada por um 2º verify adversarial**, com achados **medidos ao
> vivo neste host**. Os erros e seus fechos estão inline, marcados como **[CORRIGIDO A…N]** — sem apagar a
> posição anterior. Os três mais graves: **(A)** os floors de memória "JÁ FEITOS" **não protegem**, porque
> em cgroup v2 a proteção efetiva é limitada pela do **ancestral**, e `system.slice` tem `memory.min=0`
> (medido); **(B)** a allowlist de rotas é **furável por path-traversal** (`/assets/%2e%2e/invoke`
> reproduzido em node v22.23.1); **(C)** no Hono, um handler registrado **antes** do middleware responde
> **sem passar por ele** — bypass total do default-deny por ordem de registro.
> O que os verifies **aprovaram segue intacto**: grant duplo, default-deny com allowlist, enforcement
> fail-closed, `alg` pinado, escada A→B1→B2→B3 do `resource=`, recusa do downgrade, reversibilidade por
> passo, honestidade verificável×VPS-declarado, e não prometer L1–L6.

---

## 1. Sumário — o buraco e o fecho

**O buraco (risco vivo, plane PROD).** O Onion-Bridge (`app.onionevolve.com`) expõe o framework via mobile:
Node 22 + Hono (SSE) + PWA Android estático, rodando `@anthropic-ai/claude-agent-sdk` com `cwd`/`ONION_CWD`
apontando para um clone dedicado do core no VPS (`/home/onion/onion-evolve`), lido AO VIVO. O backend roda
com `--permission-mode bypassPermissions` — **toda** execução de agente/comando contra esse clone corre
**sem gate de permissão do Claude Code**, e o **único portão de entrada é a posse de um `AUTH_TOKEN`
estático** (um segredo compartilhado do serviço, não uma identidade). Consequência exata:

- **(a) não há QUEM** — o token não carrega usuário/papel/tier; "quem tem o token, tem tudo";
- **(b) não há RBAC/escopo** — o bridge não distingue "ler" de "mutar", nem por membro da federação;
- **(c) não há vínculo com a SSOT** — nenhuma amarra a `members.yaml` (SSOT de identidade/confiança) nem ao
  Logto que já vive em `auth.onionevolve.com` **sem nenhum consumidor** plugado.

Isto não é hipotético: há **precedente real** de escrita de código de um celular por esse caminho
(SDK bypassPermissions + git local no VPS — `onion-parecer-whatsapp-sender-2026-07.md:69`). O gate A2A
(`a2a-verify.sh`, 6 camadas) cobre **só** o canal `/a2a` (handshake entre cores federados, propose-only) —
**não** é o mesmo caminho do bridge/PWA, que segue autenticado só por `AUTH_TOKEN` + bypassPermissions.

**O fecho (este spec).** Trocar o `AUTH_TOKEN` estático por **identidade emitida pelo Logto já vivo**, com
**dois grants** porque há **dois tipos de chamador** (§3.1): **Authorization Code + PKCE** para o **humano**
na PWA (identidade **por usuário**, client público, **zero segredo distribuído**) e **Client Credentials**
para a **automação/serviço** (segredo fica no servidor). Ambos pedem token para a **mesma audiência** — o
bridge registrado como **API Resource**. O middleware do bridge **valida o JWT** a cada request (assinatura
por JWKS remoto, **algoritmo pinado**, `iss`/`aud`/`exp`/`scope`), com **default-deny por rota**,
**guarda de canonicalização de path** (§3.4b, novo) e **enforcement fail-closed por padrão**. Sem token
válido → **401**. O `bypassPermissions` do Agent SDK **permanece** (é outro eixo — decisão gated do maestro);
o que muda é que o **portão de entrada deixa de ser um segredo compartilhado e passa a ser uma identidade
verificável, atribuível e revogável**. Em paralelo, endurecer o host (pin+verifier do Logto, floors de
memória **que de fato protegem** — §5 — e console com auto-desligamento).

**O ganho que a v1 não tinha (efeito colateral do grant duplo).** Com PKCE, o alvo **(a) não há QUEM** fecha
de verdade: cada invocação do Agent SDK passa a carregar um `sub` de **usuário**, logável e revogável
individualmente — não um `client_id` de serviço compartilhado.

**O custo novo que o PKCE traz (e que a v2 não nomeava) — [CORRIGIDO I].** Com PKCE, o **material bearer
passa a viver no browser da PWA**, com o **mesmo poder de execução** que o `AUTH_TOKEN` tinha
(`bypassPermissions` + o único scope existente). Isso **move**, não elimina, a superfície: de "um segredo
num arquivo de env no servidor" para "um token num device". §3.10 nomeia e mitiga.

**Por que agora, e por que só isto.** O spec M3 formaliza que "auth real só se torna necessária no gatilho
multi-operador". Ainda há **um** operador humano (o maestro), então RBAC **multi-operador** segue **gated**.
Mas identidade **de um** operador não espera gatilho nenhum: trocar segredo-estático por identidade-emitida é
higiene defensiva que reduz o raio de dano hoje, sem construir a plataforma admin do M3.

---

## 2. Estado atual honesto — verificável, MEDIDO ao vivo, VPS-declarado

Três categorias, não duas. A v2 tinha só duas e por isso conseguiu carimbar como "verificado" uma coisa
**configurada mas inefetiva** (§5, fix A).

### 2.1 Verificável (lido no filesystem do repo do core)

- **O que o bridge é** e que usa **`AUTH_TOKEN` próprio, não Logto/OIDC** — repetido em
  `onion-m3-federation-admin-spec-2026-07.md:156-159`, espelhado no KG M3 (linhas 50, 274) e confirmado em
  campo pelo diário `2026-07-09-first-live-a2a-handshake.md:43` ("dogfood usou o AUTH_TOKEN admin").
- **O buraco exato** (`bypassPermissions` + token como único portão) — `members.yaml:24`,
  `S1-a2a-live-interop.md:71`, `S4-competitors-academia-governance.md:130`,
  `2026-07-09-security-gate-degrades-to-veto.md:42-43`, precedente real em
  `onion-parecer-whatsapp-sender-2026-07.md:69`.
- **Decisão doutrinária de não fechar antes** (gatilho multi-operador) —
  `onion-m3-federation-admin-spec-2026-07.md §4.1`.
- **Invariante I3** — `docs/technical-context/03-domain/business-logic.md:179` e
  `rfc-0003-federated-identity-collective-intelligence.md:233` (é **um escritor por repo**, não "não operar
  o host" — fix G).

**Higiene de fonte — [CORRIGIDO N].** O sinal citado por este spec para "Logto vivo + lição do pin herdado"
(`docs/evolution/inbox/_processed/2026-07-25-logto-core-e-licao-do-pin-herdado.md`) **recebeu uma correção
formal** em `docs/evolution/inbox/2026-07-25-correcao-o-sinal-do-entrypoint-estava-errado.md`. A correção
**refuta o diagnóstico do entrypoint** ("o 503 do staging do Arandek vinha do entrypoint encadear
`seed && node init.mjs && npm start`") — a causa real era **auto-shutdown agendado** (`min=0/max=0`,
`desired=0`, num sábado fora da janela seg–sex 07:00–21:00). **Isso NÃO atinge** o que o M2 cita daquele
sinal (Logto 1.41.0 vivo em `auth.onionevolve.com`, pin + verifier), mas **as duas fontes têm de ser citadas
juntas** — citar o sinal sem a correção reintroduz, por transporte, uma inferência já refutada. É a mesma
classe de erro que este spec vinha cometendo: **observação correta promovida a causa**.

### 2.2 MEDIDO ao vivo neste host (2026-07-26, comandos read-only)

Esta sessão roda **em** `srv1812846`. O que segue foi lido do kernel, não de documentação:

| O que | Medida | Comando |
|---|---|---|
| kernel / systemd | `6.8.0-134-generic` / systemd `255 (255.4-1ubuntu8.16)` | `uname -r`, `systemctl --version` |
| RAM do host | 32094 MiB total | `free -m` |
| montagem do cgroup v2 | `rw,nosuid,nodev,noexec,relatime,nsdelegate,`**`memory_recursiveprot`** | `findmnt -no OPTIONS /sys/fs/cgroup` |
| `caddy.service` (configurado **e** escrito no cgroup) | `memory.min=67108864` · `memory.low=134217728` · `OOMScoreAdjust=-500` · `Slice=system.slice` | `systemctl show caddy …` + `cat /sys/fs/cgroup/system.slice/caddy.service/memory.min` |
| `onion-bridge.service` (idem) | `memory.min=268435456` · `memory.low=536870912` · `OOMScoreAdjust=-500` · `Slice=system.slice` | idem |
| **ancestral `system.slice`** | **`memory.min=0` · `memory.low=0`** | `cat /sys/fs/cgroup/system.slice/memory.min` |
| viés de OOM efetivo no processo | `/proc/<pid do caddy>/oom_score_adj` = **-500** | `cat /proc/63903/oom_score_adj` |
| `onion-auth.slice` (o do §5b′) | **`Slice=onion.slice`**, e `onion.slice` tem `MemoryMin=0`; **nenhuma unit em disco** (`/etc/systemd/system/onion*.slice` não existe) | `systemctl show onion-auth.slice -p Slice` |
| slice **sem hífen** (ex. `onionauth.slice`) | `Slice=-.slice` — **filho direto do root** | `systemctl show onionauth.slice -p Slice` |
| driver de cgroup do Docker | containers aparecem como `/sys/fs/cgroup/system.slice/docker-<hash>.scope` e **não existe** `/sys/fs/cgroup/docker` → **driver `systemd`** | `ls -d /sys/fs/cgroup/system.slice/docker-*.scope` |
| containers do Logto | `memory.min=0` `memory.low=0`; `memory.max` = `1073741824` (logto) e `536870912` (postgres) | `cat /sys/fs/cgroup/system.slice/docker-*.scope/memory.*` |
| node no host | `v22.23.1` (reproduziu o path-traversal do fix B e o parse do fix E) | `node --version` |
| `jq` no host | `jq-1.7` (o `@base64d` **não** aceita o alfabeto base64url — fix E) | `jq --version` |

**Não re-medido nesta rodada** (o sandbox desta sessão bloqueou a leitura): o **crontab** do verifier do
Logto. Ele segue como **declarado por sessão anterior**, não como medido hoje — e por isso desce de nível
no §5(a).

### 2.3 VPS-declarado (não medido — confirmar no host antes de agir)

- Valor real do `AUTH_TOKEN` vivo; conteúdo exato do **systemd unit** do bridge e do **Caddyfile**;
  config real de `bypassPermissions`/`allowedTools` do Agent SDK no processo.
- **Inventário exato das rotas do app Hono** — a lista de §3.4 é o **contrato** que o flip precisa cumprir,
  mas as rotas reais só existem no host. **P0.2** enumera com comando e confere contra a lista.
- **A ORDEM DE REGISTRO dos handlers no app Hono** — load-bearing (§3.4c, fix C). Um `app.route()` ou um
  `serveStatic` montado antes do `app.use('*', requireIdentity)` **não passa pelo middleware**.
- **Como a PWA consome o SSE** — se via `EventSource`, ela **não consegue** mandar header `Authorization`
  e o desenho exige migrar para `fetch` + `ReadableStream`. **P0.3 confirma** (§3.4d, fix M).
- **Modo cortesia-login / BYOK (`X-Anthropic-Key`)**: a citação "2 modos" vem do app-irmão
  `onion-pessoal-app` (`SEED.md:9`), **não** do bridge. Tratar como **inferência a verificar**.
- **`resource indicators` (RFC 8707)** no Logto 1.41.0 self-hosted: **load-bearing** — o `aud`-binding do
  §3.3 depende disso. **P4.1 PROVA antes de o desenho depender** e §3.6 traz o **plano-B**.
- **`default API resource` do tenant** (o plano B1): **também VPS-declarado**, e com **prova própria**
  (§3.6, fix J) — a v2 o apresentava como fallback preferido sem verificação nenhuma, o que o tornava tão
  "declarado" quanto o RFC 8707 que ele deveria substituir.
- **Estado do sign-up no Logto** (auto-registro aberto?) e usuários existentes. Com PKCE isso vira crítico.
- **Onde `/a2a` vive** e se ele **segue gateado depois do flip** (fix L1 — hoje era "caso à parte" sem teste).

### 2.4 Resolvido pelo maestro (entrada de decisão, não inferência)

- **O chamador é HÍBRIDO** — **(a) humano** operando a PWA no celular **e (b) automação/serviço**.
  Isto **refuta** a premissa da v1 ("o consumidor do bridge é outro processo/serviço") e é a origem do
  desenho de **grant duplo** (§3).

---

## 3. Desenho do gate OIDC — **grant DUPLO** (humano + serviço)

### 3.1 Os dois chamadores, e por que cada grant serve o seu

> **Posição superada (v1):** "O consumidor do bridge é outro processo/serviço, não um humano interativo. O
> encaixe correto é M2M." — **falso**. O maestro resolveu: o chamador é **híbrido**. Um desenho M2M-só teria
> obrigado a **distribuir um `client_secret` para dentro da PWA no celular** (client público não guarda
> segredo: qualquer pessoa com o device, ou com o bundle JS, o extrai) — trocando um segredo compartilhado
> por outro, **pior**, porque agora com aparência de identidade. E não fecharia o alvo (a) "não há QUEM".

| | **Chamador (a) — HUMANO na PWA** | **Chamador (b) — automação/serviço** |
|---|---|---|
| Quem é | o maestro (hoje, N=1) no celular | o core, um job, um adotante autorizado |
| Tem browser/redirect? | **sim** | não |
| Pode guardar segredo? | **não** (código roda no device) | **sim** (segredo no servidor) |
| Grant | **Authorization Code + PKCE** | **Client Credentials** |
| Tipo de client no Logto | **público** (SPA/Native) — `client_secret` **inexistente** | **M2M** (confidencial) — `client_secret` no `pass` do VPS |
| O que o token carrega | `sub` = **id do usuário** → há QUEM, por pessoa | `sub` = `client_id` → identidade do **serviço** |
| Revogação | por **usuário** (suspender/deletar no Logto) | por **application** (rotacionar/deletar o secret) |
| Onde o bearer repousa | **no device** (localStorage por padrão no SDK do Logto) → §3.10 | em memória do processo servidor |
| Por que este grant | PKCE amarra o `code` à instância que o pediu (`code_verifier` nunca trafega no primeiro leg), então **não há segredo distribuído a vazar**; e o login real produz identidade de pessoa | não há humano nem redirect; o segredo **nunca sai do servidor**; nada de browser flow para um processo |

**Invariante do par:** os dois pedem token para a **mesma audiência** (o API Resource do bridge) e passam
pelo **mesmo middleware**. O bridge **não tem dois caminhos de validação** — tem um só, que distingue
*quem* pelo formato do claim (`sub` de usuário vs `sub == client_id` de serviço) **depois** de validar.
Menos código de auth = menos superfície.

### 3.2 Provisionamento no Logto (1 recurso + 2 clients)

1. **API Resource** — identifier `https://bridge.onionevolve.com`; scope `bridge:invoke` (e, se P0 revelar
   rotas de leitura separáveis, `bridge:read`). É a **audiência** dos dois grants.
2. **Client A — SPA/Native público (PWA)**: sem `client_secret`; PKCE obrigatório;
   `redirect_uri = https://app.onionevolve.com/callback`; `post_logout_redirect_uri = https://app.onionevolve.com/`.
3. **Client B — M2M**: `client_id` + `client_secret`, guardados no `pass` do VPS (mesmo gestor do `up.sh` do
   Logto). **Nunca** embarcado em cliente, nunca em repo.
4. **RBAC mínimo (2 camadas, não 1)**: criar role `bridge-operator` que concede o scope `bridge:invoke`;
   atribuí-la **só** ao usuário do maestro e ao client M2M. Usuário sem a role recebe token **sem** o scope →
   o middleware devolve **403**.
5. **Sign-up DESLIGADO** na Sign-in Experience do Logto (+ conferir a lista de usuários). Com PKCE, deixar
   auto-registro aberto significaria: qualquer pessoa cria conta → obtém token válido → passa no `iss`/`aud`.
   A role/scope (item 4) é a segunda camada que sustenta o fecho mesmo se o sign-up for reaberto por engano.

### 3.3 Validação do token no bridge (o que substitui o `AUTH_TOKEN`)

Middleware do bridge, a **cada request protegida** (§3.4):

1. extrair `Authorization: Bearer <token>`;
2. buscar chaves públicas no **JWKS** `https://auth.onionevolve.com/oidc/jwks` (cache remoto — em Node,
   `createRemoteJWKSet` da lib `jose`, com cache **explicitamente configurado**, §3.7);
3. verificar **assinatura** com **`algorithms` PINADO** — `['RS256']` (ou `['ES256']`, conforme o `alg` real
   que o Logto emitir, provado em **P4**). Nunca deixar a lib herdar o `alg` do header do token: é o
   endurecimento padrão contra **confusão de algoritmo** (`alg: none`, HS256-com-chave-pública);
4. verificar `iss == https://auth.onionevolve.com/oidc`;
5. verificar `aud` inclui o **resource identifier** do bridge (§3.6 se o `aud`-binding não vier);
6. verificar `exp` (+ `clockTolerance` pequena, 5s);
7. verificar `scope` contém `bridge:invoke` → senão **403 `insufficient_scope`**;
8. registrar o **QUEM** no log de auditoria da request (`sub`, `client_id`, `kind`, rota).

Falha em 1–6 → **401** (fail-closed). O JWT é **assinado** (não opaco), então a validação é local ao
processo, sem round-trip de introspecção.

```ts
import { createRemoteJWKSet, jwtVerify } from 'jose'
import type { Context, MiddlewareHandler } from 'hono'

const ISSUER   = 'https://auth.onionevolve.com/oidc'
const AUDIENCE = 'https://bridge.onionevolve.com'   // identifier do API Resource
const SCOPE    = 'bridge:invoke'

// JWKS com cache EXPLÍCITO: sob Logto-down, tokens já emitidos seguem validando (§3.7)
const jwks = createRemoteJWKSet(new URL(`${ISSUER}/jwks`), {
  cacheMaxAge: 10 * 60_000,   // 10 min de cache de chaves
  cooldownDuration: 30_000,   // no mínimo 30s entre refetches (anti-stampede)
})

// ── DEFAULT-DENY: allowlist ANCORADA do que é ABERTO; todo o resto é PROTEGIDO (§3.4)
const OPEN_EXACT  = new Set(['/', '/index.html', '/health', '/callback',
                             '/manifest.webmanifest', '/sw.js', '/favicon.ico'])
const OPEN_PREFIX = ['/assets/', '/icons/', '/.well-known/']

/**
 * GUARDA DE CANONICALIZAÇÃO — [CORRIGIDO B]. Devolve o path canônico se, e só se, ele é
 * inequivocamente seguro de comparar contra a allowlist; devolve `null` (⇒ PROTEGIDO) em
 * qualquer dúvida. NUNCA "conserta" o path: rejeita.
 *
 * Reproduzido em node v22.23.1 (o runtime deste host):
 *   decodeURI('/assets/%2e%2e/invoke') === '/assets/../invoke'   e  .startsWith('/assets/') === true
 *   decodeURIComponent('/assets/%2f%2f..%2finvoke') === '/assets///../invoke'  → também true
 *   '/assets/..%2finvoke'.startsWith('/assets/') === true         (fura sem decode nenhum)
 * Ou seja: um prefixo ABERTO vira caminho para /invoke — que aciona o Agent SDK sob
 * bypassPermissions. É bypass total do default-deny por um prefixo "aberto".
 */
function canonicalPath(raw: string): string | null {
  // 1) decodificar em laço curto (pega %252e = duplo-encode); erro de decode ⇒ PROTEGIDO
  let p = raw
  for (let i = 0; i < 3; i++) {
    let next: string
    try { next = decodeURIComponent(p) } catch { return null }   // '%zz' malformado ⇒ PROTEGIDO
    if (next === p) break
    p = next
    if (i === 2) return null            // ainda mudando na 3ª volta ⇒ suspeito ⇒ PROTEGIDO
  }
  // 2) qualquer sinal de travessia/ambiguidade, no RAW ou no DECODIFICADO ⇒ PROTEGIDO
  //    (inclui bytes de controle U+0000–U+001F, que truncam comparacoes downstream)
  const suspect = /(\.\.|\/\/|\\|%2e|%2f|%5c|[\u0000-\u001f])/i
  if (suspect.test(raw) || suspect.test(p)) return null
  // 3) precisa ser absoluto e ASCII-imprimível
  if (!p.startsWith('/')) return null
  return p
}

function isOpen(method: string, rawPath: string): boolean {
  if (method !== 'GET' && method !== 'HEAD') return false          // nenhuma mutação é aberta, nunca
  const p = canonicalPath(rawPath)
  if (p === null) return false                                     // dúvida ⇒ PROTEGIDO (fail-closed)
  if (OPEN_EXACT.has(p)) return true
  return OPEN_PREFIX.some((pre) => p.startsWith(pre))
}

/**
 * Ramo legado da janela de coexistência — [CORRIGIDO K: era usado e nunca definido].
 * Compara o AUTH_TOKEN antigo em tempo CONSTANTE e some inteiro no P9.
 * Vive numa função só, nomeada, para que "apagar o legado" seja uma exclusão cirúrgica.
 */
function legacyAuthTokenOk(c: Context): boolean {
  const expected = process.env.AUTH_TOKEN
  if (!expected) return false                                      // sem segredo configurado ⇒ nega
  const got = c.req.header('x-auth-token')
           ?? (c.req.header('authorization') ?? '').replace(/^Bearer /, '')
  if (!got || got.length !== expected.length) return false
  // comparação em tempo constante (evita oráculo por timing)
  const a = Buffer.from(got), b = Buffer.from(expected)
  return require('node:crypto').timingSafeEqual(a, b)
}

export const requireIdentity: MiddlewareHandler = async (c, next) => {
  if (isOpen(c.req.method, c.req.path)) return next()

  // ── FAIL-CLOSED: env AUSENTE ou com qualquer outro valor = ENFORCE (§3.5)
  const mode = process.env.BRIDGE_AUTH_MODE === 'dual-legacy' ? 'dual-legacy' : 'enforce'

  const header = c.req.header('authorization') ?? ''
  const bearer = header.startsWith('Bearer ') ? header.slice(7) : null
  if (!bearer) {
    if (mode === 'dual-legacy' && legacyAuthTokenOk(c)) return next()   // janela de coexistência (some no P9)
    return c.json({ error: 'unauthorized' }, 401)
  }

  try {
    const { payload } = await jwtVerify(bearer, jwks, {
      issuer: ISSUER,
      audience: AUDIENCE,
      algorithms: ['RS256'],        // ← PINADO. Conferir o alg real em P4.1 e ajustar aqui.
      clockTolerance: 5,
    })
    const scopes = String(payload.scope ?? '').split(' ')
    if (!scopes.includes(SCOPE)) return c.json({ error: 'insufficient_scope' }, 403)

    // QUEM: humano (PKCE) traz sub de USUÁRIO; serviço (M2M) traz sub == client_id
    const clientId = String(payload.client_id ?? '')
    c.set('caller', {
      sub: String(payload.sub ?? ''),
      clientId,
      kind: payload.sub === clientId ? 'service' : 'human',
    })
    return next()
  } catch {
    return c.json({ error: 'unauthorized' }, 401)   // assinatura/iss/aud/exp/alg — tudo cai aqui
  }
}
```

Fontes: `docs.logto.io/authorization/validate-access-tokens`, `docs.logto.io/api-protection/nodejs/express`.

### 3.4 Escopo por rota — **default-deny + allowlist enumerada**

> **Erro da v1:** o middleware era descrito como "a cada request", sem escopo de rota. Aplicado literalmente
> a um app que **também serve a PWA estática**, ele exigiria Bearer para o `index.html` — e o browser **não
> tem token antes de logar**. Resultado: tela branca, login impossível, e a pressão prática de desligar o
> gate "só para os assets" — que é como um gate morre.

**O mecanismo escolhido — e por que ele, e não uma lista de rotas protegidas.** O middleware **é montado
globalmente** (`app.use('*', requireIdentity)`), e o que existe é uma **allowlist do que é ABERTO**. Assim:

- **rota nova nasce PROTEGIDA.** Uma rota de `invoke` acrescentada meses depois e esquecida na revisão fica
  coberta **por construção** — não por disciplina.
- o inverso (lista de rotas protegidas) falha do lado errado: **esquecer** uma rota = **bypass total** do
  `bypassPermissions`. Um único `POST /invoke` fora da lista devolve o buraco inteiro.

**INVARIANTE (não negociável):** *toda* rota que aciona o Agent SDK está coberta. O default-deny é o que a
torna verificável em vez de aspiracional — a pergunta de auditoria deixa de ser "listei todas?" e vira
"a allowlist tem alguma coisa que não devia?", que é uma lista curta e fixa.

**Contrato de rotas (a conferir contra o host em P0.2 — inventário é VPS-declarado):**

| Classe | Rotas | Regra |
|---|---|---|
| **PROTEGIDAS** (Bearer obrigatório) | `POST /invoke` (ou o nome real do endpoint que chama `query()` do Agent SDK) | 401 sem JWT válido |
| | rota de **stream/SSE** do turno do agente (`/stream`, `/sse`, `/events`, …) | idem — ver §3.4d |
| | controle de sessão do SDK: `/session*`, `/abort`, `/interrupt`, `/resume` | idem |
| | **qualquer** rota que leia/escreva o clone do core (`/files*`, `/git*`, `/exec*`, `/api/*`) | idem |
| | **qualquer** método mutante (`POST`/`PUT`/`PATCH`/`DELETE`), sem exceção — inclusive em prefixo aberto | idem |
| | upload/anexos | idem |
| | **qualquer path que não canonicalize limpo** (`..`, `//`, `%2e`, `%2f`, `\`, controle) — §3.4b | idem, **mesmo sob prefixo aberto** |
| **ABERTAS** (sem Bearer, só `GET`/`HEAD`) | assets da PWA: `/`, `/index.html`, `/assets/*`, `/icons/*`, `/manifest.webmanifest`, `/sw.js`, `/favicon.ico` | o browser precisa carregar o app **para poder logar** |
| | `/health` | liveness; **sem** dado sensível e **sem** depender do Logto (§3.7) |
| | `/callback` (o `redirect_uri` do OIDC) | recebe o `code`; por definição **ainda não há token** |
| | `/.well-known/*`, se servido pelo app | metadados públicos |
| **DUPLO GATE** | `/a2a` (se vive no mesmo app) | **cobertura dupla é o default agora** (fix L1): passa pelo `requireIdentity` **e** pelo gate próprio `a2a-verify.sh` (6 camadas). A exceção (só a2a-verify) exige justificativa escrita **e** o teste #23. **Não** pode ser aberto pela allowlist |

### 3.4b Guarda de canonicalização de path — **[CORRIGIDO B, bypass REAL reproduzido]**

> **Erro da v2 (bypass real, não teórico):** o comentário `// c.req.path já vem normalizado` (v2, linha 207)
> era **confiança sem prova**, e a comparação era `path.startsWith('/assets/')` sobre um path possivelmente
> percent-encoded. **Reproduzido em node v22.23.1 neste host:**
>
> ```
> decodeURI('/assets/%2e%2e/invoke')              === '/assets/../invoke'   → startsWith('/assets/') = true
> decodeURIComponent('/assets/%2f%2f..%2finvoke') === '/assets///../invoke' → startsWith('/assets/') = true
> '/assets/..%2finvoke'                                                     → startsWith('/assets/') = true
> ```
>
> Ou seja: **um prefixo ABERTO alcança `/invoke`** — o endpoint que aciona o Agent SDK sob
> `bypassPermissions`. O default-deny inteiro cai por uma string.

**Regra dura (não negociável):**

1. **Qualquer** path que, no bruto **ou** em qualquer rodada de decodificação, contenha `..`, `//`, `\`,
   `%2e`, `%2f`, `%5c`, ou byte de controle → é **PROTEGIDO**. Não se normaliza, não se "conserta": **nega**.
2. Erro de decodificação (`%zz` malformado) → **PROTEGIDO**.
3. Ainda mudando depois de 3 rodadas de decode (encoding recursivo) → **PROTEGIDO**.
4. **Nunca** assumir "`c.req.path` já vem normalizado" sem prova. Se o host provar em P0.2b que o Hono
   normaliza, a guarda **permanece assim mesmo** — ela é defesa em profundidade, custa microssegundos, e a
   premissa "o framework normaliza" é exatamente o tipo de coisa que muda numa bump de versão sem aviso.

**A guarda foi RODADA contra um corpus, não só escrita** (node v22.23.1, este host, 2026-07-26):
**12/12 ataques bloqueados** — `/assets/%2e%2e/invoke`, `/assets/../invoke`, `/assets/..%2finvoke`,
`/assets/%2f%2f..%2finvoke`, `/assets//../invoke`, `/assets/%252e%252e/invoke` (duplo-encode),
`/icons/../invoke`, `/.well-known/../invoke`, `/assets/%2e%2e%2finvoke`, `/assets/%zz` (decode inválido),
`/assets/%00/invoke`, `/assets/%5c..%5cinvoke` — **e 11/11 paths legítimos seguem abertos**, incluindo
`/assets/logo%20final.svg` (espaço percent-encoded **não** é traversal e não pode ser negado, senão a
guarda quebra a PWA). `POST /assets/x` → negado. **O corpus é parte do contrato:** o teste #12 do §6 o
executa contra o host real, com `--path-as-is`.

**Propriedade de segurança que torna a guarda segura de adicionar:** a guarda só sabe **negar mais**. Ela
nunca abre nada que o router fecharia, e nunca reescreve o path que o router usa para despachar. Um
descasamento entre "o que a guarda viu" e "o que o router despachou" só pode produzir **um 401 a mais**,
nunca **um 401 a menos**. É por isso que ela pode ser adicionada sem medo de desviar o roteamento.

**Prova obrigatória:** testes #12 e #13 do §6.

### 3.4c Ordem de registro do middleware no Hono — **[CORRIGIDO C]**

**O Hono compõe os handlers na ORDEM DE REGISTRO.** Um handler registrado **antes** do
`app.use('*', requireIdentity)` responde **sem passar por ele** — o que é **bypass total do default-deny**,
silencioso, e invisível para qualquer teste que só exercite as rotas que alguém lembrou de listar.

**Exigência no P5 (não negociável):**

- `app.use('*', requireIdentity)` é registrado **antes de toda rota** (`app.get/post/...`), **antes de todo
  `app.route()`/`app.mount()`**, e **antes de qualquer `serveStatic`**.
- Nada de "quase no topo": **primeiro handler do arquivo**, imediatamente após a criação do `app`.
- Sub-apps montados por `app.route('/x', sub)` herdam o middleware **só** se o `app.use` global vier antes
  do `app.route`. Se um sub-app precisar do gate por conta própria, ele registra o **mesmo** `requireIdentity`
  no topo dele também (custa uma verificação a mais; o inverso custa o buraco inteiro).

**Isto vira MECANISMO, não disciplina** — assertion no boot, que derruba o serviço se a ordem quebrar:

```ts
// Logo depois de montar TODAS as rotas, antes de app.fire()/serve():
const first = app.routes.findIndex((r) => r.handler === requireIdentity)
if (first !== 0) {
  console.error(`[FATAL] requireIdentity está no índice ${first} de app.routes, não 0. ` +
                `Handlers registrados antes dele respondem SEM gate de auth. Abortando.`)
  process.exit(1)
}
```

Sem a assertion, "o middleware é o primeiro" é uma afirmação de code review — a classe de garantia que
o repo já decidiu não aceitar (`fix-must-become-mechanism`). **Prova:** teste #14 do §6.

### 3.4d SSE / EventSource — **achado mantido e destacado [M]**

`EventSource` **não permite** headers customizados → **não manda `Authorization`**. É limitação da API do
browser, não do desenho. Consequência: se a PWA consome o SSE por `EventSource`, o **caminho humano não
funciona** depois do flip.

- **Caminho correto:** migrar o consumo de SSE para **`fetch` + `ReadableStream`** (aceita header
  `Authorization`, e dá controle de reconexão/abort que o `EventSource` não dá).
- **RECUSADO explicitamente:** token por **query string**. Vaza no **log de acesso do Caddy**, no header
  **Referer** de qualquer recurso carregado a partir dali, e no histórico. Um bearer com poder de
  `bypassPermissions` num log de acesso é o mesmo buraco com outra roupa.
- Se um **ticket de curta duração** por query for a única saída técnica, é **decisão do maestro** com risco
  declarado e prazo, não default deste spec — e entra no KG como item aberto.
- **P0.3 confirma qual dos dois casos é o real, e P6 executa a migração se for o caso.**

### 3.5 Enforcement é **fail-closed por padrão**

> **Erro da v1:** `OIDC_ENFORCE=false` como default, com o texto "com `OIDC_ENFORCE` ausente o caminho legado
> é o padrão". Isso significa: **a env var sumir num update do systemd/EnvironmentFile → o bridge volta
> sozinho, em silêncio, ao segredo compartilhado**. Regressão silenciosa embutida no desenho.

**Inversão:**

- a variável é **`BRIDGE_AUTH_MODE`**, e **ausente = `enforce`**. Qualquer valor que não seja exatamente
  `dual-legacy` (typo, string vazia, `false`, `0`) também cai em `enforce`. **Falhar fechado inclui falhar
  fechado no parsing.**
- o **opt-out é explícito, nomeado e temporário**: `BRIDGE_AUTH_MODE=dual-legacy` só existe durante a janela
  de coexistência (P5→P7). A linha carrega comentário com **data de expiração CONCRETA** (fix K):
  `# EXPIRA 2026-08-08 — remover no P7 (flip). Sem esta linha, o modo é enforce.`
- no **boot**, se o modo for `dual-legacy`, o serviço **loga um WARN a cada start**
  (`AUTH DEGRADADO: dual-legacy ativo — AUTH_TOKEN legado ainda aceito`). Modo degradado que não grita vira
  permanente.
- **o flip (P7) é REMOVER a linha**, não trocar `false` por `true`. Ou seja: o estado seguro é o estado
  **sem configuração**, e o rollback é **re-adicionar** a linha. Isto é o que faz o desenho resistir a um
  update que zera o environment.

E o corolário operacional: **P9 (remover o ramo legado do código) vem IMEDIATAMENTE após P8 verde**, na mesma
janela — não "depois de dias". Enquanto `legacyAuthTokenOk()` (§3.3) existir no binário, uma variável mal
reposta a reativa.

### 3.6 Resource Indicators (RFC 8707) é **load-bearing** — prova antes, plano-B pronto

O `aud`-binding do §3.3 (passo 5) **depende** de o Logto 1.41.0 self-hosted honrar `resource=<api-identifier>`
no token request. Se não honrar, o Logto tende a emitir um token **opaco** (para o userinfo), não um JWT com
`aud` do bridge — e a validação local do §3.3 **não funciona**. Portanto: **prova antes do desenho depender**
(P4.1), com **comando que não mente** (fix E, abaixo), e plano-B escolhido **antes** de escrever o middleware.

| Plano | Quando | O que fazer | Custo/risco |
|---|---|---|---|
| **A (default)** | `resource=` honrado; volta JWT com `aud` correto | §3.3 como escrito | nenhum |
| **B1 (preferido se A falhar)** | `resource=` ignorado, mas o console permite **"default API resource"** | marcar o API Resource do bridge como **default do tenant** → tokens saem com o `aud` correto mesmo sem o parâmetro. **Exige a PROVA B1 (P4.1b) — fix J** | tenant tem **um** resource default; aceitável hoje (é o único consumidor). Reavaliar quando entrar um 2º recurso |
| **B2** | token volta **opaco** e não há default resource | validar por **userinfo**: `GET /oidc/me` com o Bearer → 200 + `sub` prova o token; cachear o resultado por ~60s | **round-trip por request** (latência) e **acoplamento forte**: Logto down = entrada fechada **imediatamente** (não só na expiração — §3.7). Fail-closed, porém mais frágil |
| **B3 (último recurso)** | nem A, nem B1, nem B2 | validar `iss` + `exp` + `scope` (`bridge:invoke`) + **allowlist de `client_id`/`sub`** mantida pelo bridge (control-plane Onion, não Logto) | **risco declarado**: sem `aud`-binding, um token emitido para **outra** audiência do mesmo tenant poderia ser replayed no bridge. Só se sustenta porque o tenant tem um consumidor só e a allowlist é curta. **Exige data de revisão** e vira item aberto no KG |

**Regra de decisão:** A → B1 → B2 → B3, nessa ordem, e **B3 só com aceite explícito do maestro**. Em nenhum
cenário o plano-B afrouxa para "aceita qualquer JWT do issuer" — isso reintroduziria o buraco com outra cara.

#### 3.6a O comando de prova — **[CORRIGIDO E: o da v2 estava QUEBRADO]**

> **Erro da v2 (reproduzido neste host):** `echo "$TOK" | cut -d. -f2 | base64 -d 2>/dev/null | jq .`
>
> Dois defeitos que **se somam para produzir um FALSO-VERMELHO**:
> 1. **`base64 -d` não lê base64url sem padding.** Medido: GNU coreutils 9.4 devolve
>    `base64: invalid input` (rc=1) sempre que o comprimento não é múltiplo de 4 — o caso de **2 em cada 3**
>    JWTs reais — e quebra de vez quando o payload contém `-`/`_` (alfabeto base64url). Com um payload
>    realista contendo `-`, o pipeline inteiro deu **`jq: parse error: Unfinished string at EOF`, exit 5**.
> 2. **`2>/dev/null` esconde exatamente o erro que explicaria o vermelho.**
>
> **Por que isso é grave, e não cosmético:** o P4.1 **ROTEIA** a decisão A→B1→B2→B3. Um falso-vermelho aqui
> empurra o desenho para um **plano-B mais fraco** (B2 acopla mais; B3 abre mão do `aud`-binding) **sem
> nenhum motivo real** — perde-se segurança por causa de um bug de shell.

**E o "fix óbvio" também não serve.** `jq -R 'split(".")|.[1]|@base64d|fromjson'` **falha igual**: medido
neste host, `jq-1.7` implementa `@base64d` como **base64 estrito**, não base64url — com um payload contendo
`-`, retorna `jq: error … is not valid base64 data`, exit 5. (Ele *tolera* padding ausente; o que ele não
tolera é o alfabeto.)

**Comandos corretos (os dois validados neste host):**

```sh
# ── PRIMÁRIO: node. É o MESMO runtime do bridge (v22.23.1 medido aqui) e tem base64url nativo.
decode_jwt() {   # uso: decode_jwt "$TOK"
  printf '%s' "$1" | node -e '
    const t = require("fs").readFileSync(0, "utf8").trim().split(".");
    if (t.length !== 3) { console.error("NAO E JWT: " + t.length + " partes (token opaco?)"); process.exit(2) }
    const dec = (s) => JSON.parse(Buffer.from(s, "base64url"));
    console.log(JSON.stringify({ header: dec(t[0]), payload: dec(t[1]) }, null, 2));
  '
}

# ── FALLBACK: jq puro, com base64url→base64 + repadding EXPLÍCITOS (sem 2>/dev/null).
decode_jwt_jq() {
  printf '%s' "$1" | jq -R 'split(".") | { header: .[0], payload: .[1] }
    | map_values( gsub("-";"+") | gsub("_";"/")
                | . + ("=" * ((4 - (length % 4)) % 4))
                | @base64d | fromjson )'
}
```

**Regra:** o passo de prova **nunca** silencia stderr, e **sempre** distingue os três vereditos —
`3 partes + aud correto` (plano A) · `3 partes + aud errado/ausente` (→ B1) · `não é JWT / token opaco`
(→ B1, depois B2/B3). Um comando que confunde "token opaco" com "meu decoder quebrou" **não é prova**.

### 3.7 Acoplamento bridge→Logto: o que acontece com o **Logto down**

O flip **cria uma dependência dura** que não existia: hoje o bridge autentica sozinho (compara uma string);
depois, o caminho de entrada depende de um serviço externo. Isto precisa estar escrito, não descoberto às 3h.

| Situação | Efeito |
|---|---|
| Logto down, **JWKS em cache**, chaves **não rotacionadas**, token **ainda válido** | ✅ requests **continuam passando** — a validação é local (assinatura + claims). Janela ≈ `min(cacheMaxAge do JWKS, exp do token)` |
| Logto down, token **expirou** | ❌ o cliente **não consegue renovar** → 401. Entrada fecha |
| Logto down + chaves rotacionadas / cache expirado | ❌ `createRemoteJWKSet` não busca a chave nova → 401 |
| Plano **B2** (userinfo) ativo | ❌ fecha **imediatamente** — cada request depende do Logto |

**Postura declarada: indisponível é aceitável; bypass não é.** A degradação é **fail-closed** — segura,
porém **indisponível**. E o que este spec **recusa explicitamente**: qualquer fallback do tipo *"se o Logto
não responder, aceita o `AUTH_TOKEN`"*. Isso seria um **downgrade acionável por atacante** (derrubar/isolar o
IdP para reativar o segredo compartilhado) — o pior padrão possível numa camada de auth.

**Mitigações (todas neste spec):**

1. **JWKS com cache explícito** (`cacheMaxAge` 10min, `cooldownDuration` 30s) — janela real de sobrevivência
   a uma queda curta, em vez de depender do default da lib.
2. **`/health` do bridge NÃO consulta o Logto.** Se consultasse, Logto down marcaria o bridge unhealthy e o
   supervisor entraria em loop de restart — transformando uma falha de auth numa falha de serviço.
3. **O maestro nunca fica trancado fora da máquina:** o SSH do VPS é por chave e **independe** do Logto. A
   indisponibilidade atinge a **conveniência mobile**, não a operação do host. É o que torna o fail-closed
   aceitável em N=1 — **e é também o que sustenta o rollback do flip**, já que o P7-rollback é uma edição de
   arquivo no host.
4. **Logto sobe ao MESMO patamar de proteção** de Caddy e bridge (§5). A v1 dizia que "Logto está um degrau
   abaixo na hierarquia de proteção" — **isso deixou de ser verdade no instante em que ele virou o portão de
   entrada**. Sob pressão de memória, o OOM killer escolheria justamente o componente que, morto, fecha a
   entrada inteira. *(Mas atenção: §5 mostra que o patamar dos "nativos" era **menor do que se pensava** —
   igualar-se a um floor inefetivo não teria adiantado nada.)*

### 3.8 Onde o Caddy entra (e onde NÃO entra)

- **Neste flip:** o Caddy segue como `reverse_proxy 127.0.0.1:8787` — **não** gateia OIDC. A validação vive
  **dentro do processo do bridge** (§3.3), inclusive para o caminho humano: quem faz o PKCE é a **própria
  PWA** (SDK do Logto no browser), e o `Authorization: Bearer` vai nas chamadas de API. Caddy **não** tem OIDC
  nativo.
- **Não confundir com o gated:** `forward_auth` + **oauth2-proxy** só entraria se fosse preciso proteger uma
  superfície **server-rendered** com **sessão de cookie** — outra arquitetura. Com a PWA fazendo PKCE
  in-app, é redundante. Fica em §7.
- **O que o Caddy DEVE fazer no flip:** repassar o header `Authorization` intacto (default do
  `reverse_proxy`, mas **conferir** se há `header_up` removendo algo) e **não** logar query strings com
  material sensível — reforço da recusa de token-por-query (§3.4d).

### 3.9 Invariante herdada (não negociável)

**Logto = emissor/validador de identidade (commodity-BUY); NUNCA SSOT de autorização fina.** A autorização
de domínio (quem é membro, qual tier, qual escopo) é do control-plane Onion (`members.yaml` / scopes do
bridge) — espelha a invariante do M3 §4.3 ("Logto Orgs = PROJEÇÃO, `members.yaml` = SSOT"). O scope do JWT é
um **espelho** de permissão, não a fonte da verdade. (Vale também para o plano B3: a allowlist de
`client_id` mora **no bridge/control-plane**, não no Logto.)

### 3.10 Risco NOVO que o PKCE traz — **[CORRIGIDO I]**

O flip fecha o alvo "não há QUEM", mas **move** a superfície de credencial. A v2 não nomeava isso; um spec de
segurança que só lista ganhos não é um spec de segurança.

**O que muda materialmente:** o `AUTH_TOKEN` vivia num `EnvironmentFile` no servidor, alcançável só por
quem já tinha o host. Depois do flip, o **access token do humano vive no browser da PWA** — e o SDK do Logto
guarda por padrão em **`localStorage`**. Esse token carrega **o mesmo poder de execução**: `bridge:invoke` é
o **único scope**, e por trás dele está o Agent SDK em `bypassPermissions`. Não há "token de leitura".

| Risco | Por que morde aqui | Mitigação neste spec |
|---|---|---|
| **Armazenamento do token** | `localStorage` é legível por **qualquer** JS na origem, persiste entre sessões e sobrevive ao fechar o app | **access token CURTO** (10–15 min) + **rotação do refresh token** (Logto suporta refresh rotation — ligar). Preferir memória + refresh, se o SDK permitir, e aceitar re-login mais frequente como custo de segurança |
| **XSS na PWA** | um `<script>` injetado (dependência comprometida, `sw.js` envenenado) **exfiltra o bearer** e ganha execução de agente no clone do core | **CSP restritiva** servida pelo Caddy (`default-src 'self'`, sem `unsafe-inline`/`unsafe-eval`), **SRI** nos assets, e **lockfile auditado** na build da PWA. A PWA passa a ser **parte da base de confiança do bridge** — tratá-la como tal |
| **Perda/roubo do device** | o token válido vai junto; o atacante herda a sessão até expirar | expiração curta (acima) + **revogação por usuário no Logto** (suspender a conta invalida a renovação) + **procedimento escrito**: perdeu o device → suspender o usuário **antes** de qualquer outra coisa |
| **Base de confiança ampliada** | antes: `host + AUTH_TOKEN`. Depois: `host + Logto + PWA + device` | **declarado, não escondido.** É um trade real: ganha-se QUEM/revogação/atribuição; paga-se com uma superfície de cliente. Em N=1, com device gerenciado pelo maestro, o saldo é positivo — **e essa avaliação muda se entrar um 2º operador** (vira input do M3) |

**Não-objetivo declarado:** este spec **não** transforma a PWA num cliente endurecido. Ele **nomeia** que a
PWA entrou na base de confiança e fixa as três mitigações baratas (token curto, refresh rotation, CSP).
Endurecimento de cliente é trabalho próprio, e fica **gated** (§7).

---

## 4. Passos TURNKEY do flip (numerados, cada um reversível)

> Executados **pelo maestro no VPS** — porque errar um gate de identidade na porta de entrada é **risco de
> lockout**, e o rollback exige acesso ao host por outro canal (§3.7 item 3). Cada passo tem seu **rollback**
> explícito. O flip é **reversível** por construção: nada é destrutivo, e o `AUTH_TOKEN` só é aposentado no
> fim, depois da validação verde.

> **[CORRIGIDO F] A ORDEM ESTAVA CIRCULAR.** Na v2, o **P1.2** (prova do `resource=`) exigia o client M2M
> que só nascia no **P2**, **e** o scope concedido pela role que só nascia no **P3.2** — e o **P2** mandava
> atribuir uma role que **ainda não existia**. Duas dependências para trás. **Nova ordem, linear:**
> **API Resource → M2M App → role/permissão → PROVA do RFC 8707.** A prova é agora o **P4**, depois de
> existir tudo que ela consome.

### P0 — Pré-flight (só leitura; resolve o VPS-declarado do §2.3)

- **P0.1** Ler o **systemd unit** e o **Caddyfile** reais do bridge; anotar valor/mecanismo do `AUTH_TOKEN`;
  conferir se o `reverse_proxy` preserva o header `Authorization`.
- **P0.2** **ENUMERAR AS ROTAS REAIS** e conferir contra o contrato de §3.4. Preferir o **dump de runtime**
  (comportamento, não declaração) e usar o grep como rede:
  ```sh
  # (a) autoritativo — Hono expõe as rotas registradas em app.routes
  cd /home/onion/onion-bridge && node -e "
    const app = require('./dist/app.js').default ?? require('./dist/app.js').app;
    console.table(app.routes.map((r, i) => ({ i, method: r.method, path: r.path })));
  "
  # (b) rede de segurança (fonte) — pega também app.use/app.route/serveStatic
  grep -rnE "\.(get|post|put|patch|delete|all|on|use|route|mount)\(\s*['\"\`]" \
       /home/onion/onion-bridge/src --include='*.ts' --include='*.js'
  ```
  **Saída esperada:** cada rota classificada PROTEGIDA/ABERTA/DUPLO-GATE. Toda rota que toca o Agent SDK →
  PROTEGIDA. Qualquer rota fora do contrato → decidir **antes** de seguir.
- **P0.2b** **ORDEM DE REGISTRO (fix C):** no mesmo dump, anotar o **índice** de cada handler. Confirmar que
  não há `app.route()`/`serveStatic`/rota alguma **antes** da posição onde o `requireIdentity` vai entrar.
  Se houver, o P5 **precisa reordenar o arquivo**, não só acrescentar o `app.use`.
- **P0.2c** **`/a2a` (fix L1):** localizar onde ele vive (mesmo app Hono? outro processo? outro vhost no
  Caddy?) e registrar a decisão **cobertura dupla** (default) vs **exceção documentada**. O teste #23 depende
  desta resposta.
- **P0.3** Confirmar **como a PWA consome o SSE** (`EventSource` vs `fetch`+stream) — §3.4d. Determina se há
  trabalho de migração no cliente antes do P6.
- **P0.4** Confirmar se o bridge tem os modos **cortesia/BYOK** e se ambos devem passar pelo gate.
- **P0.5** No console do Logto: estado do **sign-up** (aberto?) e lista de usuários existentes.
- **P0.6** **Driver de cgroup do Docker (fix L2)** — a semântica de `cgroup_parent` (§5c) **depende** dele:
  ```sh
  docker info --format '{{.CgroupDriver}}'          # esperado: systemd
  # fallback read-only (se `docker info` não estiver disponível ao usuário):
  ls -d /sys/fs/cgroup/system.slice/docker-*.scope 2>/dev/null | head -1   # existe ⇒ driver systemd
  ls -d /sys/fs/cgroup/docker 2>/dev/null                                  # existe ⇒ driver cgroupfs
  ```
  **Medido nesta sessão (2026-07-26): driver = `systemd`** (há `docker-<hash>.scope` sob `system.slice` e
  **não** há `/sys/fs/cgroup/docker`). **Por que importa:** com o driver **systemd**, `cgroup_parent` recebe
  um **nome de slice** (`onion-auth.slice`); com o driver **cgroupfs**, recebe um **caminho** (`/onion-auth`).
  Errar isso **não dá erro** — os containers simplesmente ficam onde estavam, e o floor não se aplica.
  **Re-confirmar no dia**: um `daemon.json` novo muda o driver sem aviso.
- *Rollback P0: nenhuma mudança — passo só de leitura.*

### P1 — API Resource (nada no bridge muda; não-disruptivo)

- **P1** Criar **API Resource** `https://bridge.onionevolve.com` + scope `bridge:invoke`.
  *Rollback: deletar o API Resource.*

### P2 — M2M Application (o chamador **b**)

- **P2** Criar **M2M Application**; guardar `client_id`/`client_secret` no `pass` do VPS.
  **Sem atribuir role ainda** — a role nasce no P3. *Rollback: deletar a M2M App / revogar o secret.*

### P3 — Role, permissão e o client humano

- **P3.1** Criar a role **`bridge-operator`** concedendo o scope `bridge:invoke` do API Resource do P1.
  *Rollback: deletar a role.*
- **P3.2** **Atribuir** a role ao **client M2M do P2** e ao **usuário do maestro**.
  *Rollback: remover as atribuições.*
- **P3.3** Criar **SPA/Native Application pública** (chamador **a**, a PWA): sem secret, PKCE,
  `redirect_uri = https://app.onionevolve.com/callback`. *Rollback: deletar a application.*
- **P3.4** **Desligar o sign-up** na Sign-in Experience; conferir que a lista de usuários tem só quem deve.
  *Rollback: reativar (não recomendado).*
- **P3.5** Ligar **token de acesso curto** (10–15 min) e **rotação de refresh token** (§3.10).
  *Rollback: restaurar os tempos default.*

### P4 — PROVA (o gate do §3.6; agora depois de tudo que ela consome)

- **P4.1** **PROVAR o RFC 8707** — com o comando que **não mente** (§3.6a):
  ```sh
  set -o pipefail
  TOK=$(curl -sS -X POST https://auth.onionevolve.com/oidc/token \
     -d grant_type=client_credentials \
     -d resource=https://bridge.onionevolve.com \
     -d scope=bridge:invoke \
     -u "$CLIENT_ID:$CLIENT_SECRET" | jq -r .access_token)
  [ -n "$TOK" ] && [ "$TOK" != "null" ] || { echo "FALHOU no token endpoint — ler o corpo do erro"; exit 1; }
  decode_jwt "$TOK"      # função de §3.6a — node, base64url nativo, SEM 2>/dev/null
  ```
  **Três vereditos possíveis, e para onde cada um roteia:**
  - **3 partes + `aud` contém `https://bridge.onionevolve.com` + `scope` contém `bridge:invoke`** →
    **plano A**. Anotar o **`alg`** do header e **pinar** em §3.3.
  - **3 partes, mas `aud` errado/ausente** → **B1** (P4.1b).
  - **`NAO E JWT` (token opaco)** → **B1** (P4.1b); se B1 falhar, **B2**; só então **B3**, com aceite
    explícito do maestro.
  *Rollback: nenhum — só verificação.*
- **P4.1b** **PROVA DO B1 — [CORRIGIDO J].** O "default API resource do tenant" era apresentado como fallback
  **preferido sem verificação nenhuma** — ou seja, tão VPS-declarado quanto o RFC 8707 que ele deveria
  substituir. Ele passa a ter **passo de prova próprio**:
  ```sh
  # 1) no console do Logto: marcar o API Resource do bridge como DEFAULT do tenant.
  # 2) pedir token SEM o parametro resource= — é isto que o B1 promete resolver:
  TOK_NOR=$(curl -sS -X POST https://auth.onionevolve.com/oidc/token \
     -d grant_type=client_credentials -d scope=bridge:invoke \
     -u "$CLIENT_ID:$CLIENT_SECRET" | jq -r .access_token)
  decode_jwt "$TOK_NOR"
  ```
  **Verde do B1** = 3 partes **e** `aud` contém `https://bridge.onionevolve.com` **sem** ter mandado
  `resource=`. **Qualquer outra coisa = B1 REPROVADO** → descer para B2. *(Sem esta prova, adotar B1 é trocar
  uma suposição por outra.)*
  *Rollback: desmarcar o default resource no console.*
- **P4.2** **Emissão HUMANA:** login real no browser pela PWA de teste/página de callback, obter
  `getAccessToken('https://bridge.onionevolve.com')` no SDK do Logto e decodificar com `decode_jwt`:
  esperar `sub` = **id do usuário** (**≠** `client_id`), `aud` = bridge, `scope` = `bridge:invoke`.
  **É este passo que prova que o alvo (a) "não há QUEM" fechou.**
  *Rollback: nenhum — só verificação.*
- **P4.3** **Registrar no spec e no KG** qual plano (A/B1/B2/B3) foi adotado, com a saída do `decode_jwt`
  colada. **Antes** de escrever o middleware.

### P5 — Introduzir o middleware (default-deny já ativo, legado ainda aceito)

- **P5** Adicionar o middleware de §3.3/§3.4 ao bridge, com **todos** estes requisitos:
  1. **`app.use('*', requireIdentity)` como PRIMEIRO handler registrado** — antes de toda rota, de todo
     `app.route()`/`app.mount()` e de todo `serveStatic` (§3.4c). **Reordenar o arquivo se P0.2b pediu.**
  2. **Assertion de boot** do §3.4c (`app.routes.findIndex(...) === 0`, senão `process.exit(1)`).
  3. **Guarda de canonicalização** (`canonicalPath`, §3.4b) — allowlist só é consultada sobre path canônico.
  4. **`algorithms` pinado** conforme o `alg` medido no P4.1.
  5. **`legacyAuthTokenOk()` definido** (§3.3), numa função só, para o P9 ser uma exclusão cirúrgica.
  6. Modo lido de `BRIDGE_AUTH_MODE` com **default `enforce`**. No EnvironmentFile, escrever
     **explicitamente** (com **data concreta**, fix K):
     ```
     # EXPIRA 2026-08-08 — janela de coexistência do flip M2. Remover no P7.
     # Sem esta linha o modo é ENFORCE (fail-closed). Não converter em "false".
     BRIDGE_AUTH_MODE=dual-legacy
     ```
  Deploy pelo mecanismo já usado (edição do clone + `systemctl restart onion-bridge`). Conferir no log de
  boot o **WARN de modo degradado** e a **ausência do FATAL** da assertion.
  *Rollback: reverter o commit do bridge + restart.*

### P6 — Os dois chamadores passam a mandar Bearer

- **P6** A **PWA** (login PKCE + `Authorization` nas chamadas de API; **migrar o SSE para `fetch`+stream se
  P0.3 pediu**, §3.4d) e a **automação** (token M2M). Confirmar 200 fim-a-fim nos dois.
  *Rollback: chamadores voltam ao `AUTH_TOKEN` (ainda aceito no P5).*

### P7 — O FLIP (remover o opt-out)

- **P7** **Apagar a linha `BRIDGE_AUTH_MODE=dual-legacy`** do EnvironmentFile (`systemctl edit onion-bridge`
  / arquivo de env) + `systemctl restart onion-bridge`. Sem a linha, o default é **enforce**: só JWT válido
  passa; request só com `AUTH_TOKEN` → **401**; o WARN de degradação some do boot.
  *Rollback IMEDIATO: re-adicionar a linha + restart — volta ao dual-legacy em segundos.*

### P8 — Verificação completa

- **P8** Rodar **os 23 testes do §6**. *Rollback: se algo falhar, P7-rollback.*

### P9 — Aposentar o segredo compartilhado (imediatamente após o verde)

- **P9** Na **mesma janela** do P8 verde (não "dias depois"): remover do código `legacyAuthTokenOk()` e a
  leitura de `BRIDGE_AUTH_MODE`, e **rotacionar/apagar** o `AUTH_TOKEN` do ambiente e do `pass`. Deploy +
  restart. Rodar de novo a verificação. *Rollback: reintroduzir o ramo legado + repor um `AUTH_TOKEN` novo —
  é o passo menos trivial de reverter, por isso é o ÚLTIMO e só após P8 verde.*

**Reversibilidade global:** até **P8** inclusive, o flip é **totalmente reversível em segundos** (uma linha
de env). **P9** é o único que aposenta o caminho antigo; mesmo ele é reversível (repor um token novo), apenas
não instantâneo.

---

## 5. Endurecimento do host — **o que estava errado, e o fecho real**

> ✅ **APLICADO EM 2026-07-26** (sessão do core, com permissão explícita do maestro; é hardening
> **não-auth**, sem risco de lockout — a fronteira do preâmbulo). O drop-in
> `/etc/systemd/system/system.slice.d/10-memory-protection.conf` (`MemoryMin=384M`, `MemoryLow=768M`)
> foi criado + `daemon-reload`. **Verificado no EFETIVO**, lendo o cgroup (não `systemctl show`):
>
> | | antes | depois |
> |---|---|---|
> | `/sys/fs/cgroup/system.slice/memory.min` | `0` | **`402653184`** (384 MiB) |
> | `/sys/fs/cgroup/system.slice/memory.low` | `0` | **`805306368`** (768 MiB) |
> | `…/caddy.service/memory.min` | `67108864` (limitado a 0 pelo pai) | `67108864` **agora com ancestral que concede** |
> | `…/onion-bridge.service/memory.min` | `268435456` (idem) | `268435456` **idem** |
>
> **Reverter:** `sudo rm /etc/systemd/system/system.slice.d/10-memory-protection.conf && sudo systemctl daemon-reload`.
> O que permanece **aberto** é a *classe* do problema (varredura dos demais floors do host — `Q_floors_effective`),
> não este caso.

> **[CORRIGIDO A] — O ACHADO MAIS IMPORTANTE DESTA RODADA.** A v2 declarava, como **verificado ao vivo**,
> que os floors de memória estavam *"JÁ FEITOS para Caddy e bridge"*. **Medido hoje neste host:**
>
> ```
> systemctl show caddy -p MemoryMin                        → MemoryMin=67108864
> cat /sys/fs/cgroup/system.slice/caddy.service/memory.min  → 67108864     ← escrito no cgroup, sim
> cat /sys/fs/cgroup/system.slice/memory.min                → 0            ← O ANCESTRAL
> ```
>
> **Em cgroup v2, a proteção efetiva de um cgroup é LIMITADA pela do ancestral.** O kernel calcula a
> proteção efetiva descendo a árvore: quando a soma reivindicada pelos filhos excede o que o pai afora,
> cada filho recebe **uma fração proporcional do que o PAI tem**. Com o pai em **0**, a fração é **0**.
> Logo: `caddy.service` e `onion-bridge.service` têm `memory.min` **configurado e escrito**, e
> **proteção efetiva ZERO**.
>
> **Configurado ≠ protegido.** O erro de método foi ler `systemctl show` (declaração) e até o `memory.min`
> do próprio cgroup (também declaração, num nível só) e chamar aquilo de "verificado". A verificação de
> proteção **tem de percorrer a cadeia inteira de ancestrais** — e não existe arquivo `memory.min.effective`
> no cgroup v2 (conferido: só `memory.min`, `memory.low`, `memory.high`, `memory.max`, `memory.current`).

**A condição que a v2 mandava conferir estava ERRADA.** Ela dizia para checar se `memory_recursiveprot`
estava montado, e tratava a **ausência** dele como o gate. **Medido:**

```
findmnt -no OPTIONS /sys/fs/cgroup
→ rw,nosuid,nodev,noexec,relatime,nsdelegate,memory_recursiveprot     ← ESTÁ PRESENTE
```

`memory_recursiveprot` **está ativo** e **não é o problema**. O que ele faz é o contrário do que a v2
sugeria: ele faz a proteção **não reivindicada** pelo pai **descer** para os descendentes, sem que cada um
precise declarar a sua. Ele **não levanta o teto do ancestral** — proteção zero no pai continua sendo zero
para distribuir. **O que morde é `memory.min` do ANCESTRAL, não a opção de montagem.**

**O que NÃO estava quebrado:** `OOMScoreAdjust=-500` funciona e é independente disso — medido no processo
real (`cat /proc/63903/oom_score_adj` → `-500`). Ou seja, **metade** do endurecimento (o **viés de quem
morre** no OOM killer) está de pé; a outra metade (**proteção contra reclamação de página**) está zerada.
Essa distinção importa: o risco residual não é "nenhuma proteção", é "sem floor de reclaim".

### 5a — Pin + verifier do Logto

**Estado: declarado por sessão anterior; NÃO re-medido nesta rodada.** `check-version.sh` no crontab
(segundas 09:00, `--quiet` → `logger`) + backup diário 03:20; `./check-version.sh` → `✓ em dia (1.41.0)`.
O sandbox desta sessão **bloqueou a leitura do crontab**, então isto desce de "medido" para "declarado" —
**re-medir no P0** com `crontab -l | grep -i logto` e `ls -la /home/marcio/onion-logto/backups/`.

Guardrail herdado (lição do pin herdado): qualquer decisão de **pin de versão do Logto** exige checar o
delta de release **antes** de subir, com peso extra por ser componente de auth — **PROPOSTA** do inbox
2026-07-25, ainda **não** ratificada em `code-standards.md`/KB; citar como proposta, não regra vigente.
*(Com o flip, este guardrail ganha peso: o Logto deixa de ser opcional. E ver §2.1 sobre a **correção** que
aquele sinal recebeu — fix N.)*

### 5b — Floors de memória: o fix REAL (`system.slice` + a cadeia inteira)

**O fix não é mexer em Caddy/bridge** (eles já estão corretos no nível deles). **É declarar a proteção
também no ANCESTRAL.** `system.slice` é filho direto de `-.slice` (a raiz) — medido:
`systemctl show system.slice -p Slice` → `Slice=-.slice`. Filho direto da raiz **não tem teto acima**: o
kernel usa o caminho curto (`pai == raiz`) e a proteção efetiva do slice é **a que ele mesmo declara**.
Então basta um nível.

**Comando (o maestro executa):**

```sh
sudo mkdir -p /etc/systemd/system/system.slice.d
sudo tee /etc/systemd/system/system.slice.d/10-memory-protection.conf >/dev/null <<'EOF'
# Teto de ancestral — adicionado 2026-07-26 (fix A do spec M2).
#
# Sem estas linhas, os MemoryMin/MemoryLow de caddy.service e onion-bridge.service
# ficam com proteção EFETIVA ZERO: em cgroup v2 a proteção de um cgroup é limitada
# pela do ancestral, e system.slice tinha memory.min=0. Configurado != protegido.
#
# DIMENSIONAMENTO — memory.min é reserva DURA e não-reclamável: inflá-la aproxima o
# OOM global. Manter APERTADO, = a soma do que os descendentes de fato reivindicam:
#   MemoryMin  = caddy 64M + bridge 256M            = 320M  (+64M de folga = 384M)
#   MemoryLow  = caddy 128M + bridge 512M           = 640M  (+128M de folga = 768M)
# Ao acrescentar um serviço com floor sob system.slice, SOMAR aqui também.
[Slice]
MemoryMin=384M
MemoryLow=768M
EOF
sudo systemctl daemon-reload
sudo systemctl set-property --runtime system.slice MemoryMin=384M MemoryLow=768M   # aplica sem reboot
```

**Verificação — lendo o cgroup EFETIVO, nunca só `systemctl show` (esta é a lição do fix A):**

```sh
# Caminhador de cadeia: falha se QUALQUER ancestral estiver abaixo do floor do filho.
check_floor() {                       # uso: check_floor /sys/fs/cgroup/system.slice/caddy.service
  local p="$1" want min
  want=$(cat "$p/memory.min")
  echo "alvo: $p  memory.min=$want"
  while [ "$p" != "/sys/fs/cgroup" ]; do
    p=$(dirname "$p")
    min=$(cat "$p/memory.min" 2>/dev/null || echo "n/a(raiz)")
    printf '  ancestral %-52s memory.min=%s\n' "$p" "$min"
    case "$min" in
      n/a*) ;;                                                   # raiz não tem o arquivo: ok
      *) [ "$min" -ge "$want" ] 2>/dev/null || { echo "  ✗ TETO DE ANCESTRAL: $p ($min) < alvo ($want) — proteção efetiva REDUZIDA/ZERADA"; return 1; } ;;
    esac
  done
  echo "  ✓ cadeia inteira sustenta o floor"
}
check_floor /sys/fs/cgroup/system.slice/caddy.service
check_floor /sys/fs/cgroup/system.slice/onion-bridge.service
```

**Estado atual medido (2026-07-26), para o maestro comparar depois de aplicar:**

```
alvo: /sys/fs/cgroup/system.slice/caddy.service        memory.min=67108864
  ancestral /sys/fs/cgroup/system.slice                memory.min=0        ← ✗ TETO
alvo: /sys/fs/cgroup/system.slice/onion-bridge.service memory.min=268435456
  ancestral /sys/fs/cgroup/system.slice                memory.min=0        ← ✗ TETO
```

*Rollback: apagar o drop-in + `daemon-reload` + `systemctl set-property --runtime system.slice MemoryMin=0 MemoryLow=0`.
Nenhum estado persistente fica.*

### 5c — Logto + Postgres (docker): elevar ao MESMO patamar — **com o path CORRIGIDO**

**Estado medido:** só teto duro. Os containers vivem em `/sys/fs/cgroup/system.slice/docker-<hash>.scope`
com `memory.min=0 memory.low=0`; `memory.max` = `1073741824` (logto) e `536870912` (postgres). O nome do
scope muda a cada recriação, então o padrão de drop-in fixo de Caddy/bridge **não se aplica**.

> **Raciocínio superado (v1):** *"aceitável, pois Logto está um degrau abaixo de Caddy/bridge na hierarquia
> de proteção"*. **Incoerente depois do flip:** o Logto passa a ser o **portão de entrada**; matá-lo por
> pressão de memória fecha o bridge inteiro (§3.7).

> **[CORRIGIDO D] — O PATH DO SLICE ESTAVA ERRADO.** A v2 mandava criar `onion-auth.slice` e verificar em
> `/sys/fs/cgroup/onion-auth.slice/memory.min`. **Esse caminho não existe.** Medido:
> `systemctl show onion-auth.slice -p Slice` → **`Slice=onion.slice`**. No systemd, o hífen é **separador de
> hierarquia** em nomes de slice: `onion-auth.slice` é filho de `onion.slice`, que é filho de `-.slice`.
> O cgroup real é **`/sys/fs/cgroup/onion.slice/onion-auth.slice/`**. A verificação #18 da v2 lia um caminho
> inexistente — e um `cat` de arquivo ausente teria dado "erro", não "gap", mascarando a causa.
>
> **E o erro composto (fix A + fix D juntos):** `onion.slice` **não tem unit em disco** (medido:
> `/etc/systemd/system/onion*.slice` não existe; o `LoadState=loaded` era o systemd **sintetizando um slice
> implícito**) e portanto teria **`MemoryMin=0`** — exatamente o teto de ancestral do fix A, repetido. Criar
> só `onion-auth.slice` teria produzido **outro floor decorativo**.

**Fecho em três camadas (todas reversíveis):**

**Camada 1 — o slice PAI, explícito** (`/etc/systemd/system/onion.slice`) — sem ele, a Camada 2 é decorativa:
```ini
[Unit]
Description=Slice raiz dos servicos Onion no host

[Slice]
# Teto de ancestral (fix A): tem de ser >= ao que onion-auth.slice reivindica.
MemoryMin=512M
MemoryLow=768M
```

**Camada 2 — o slice do provedor de identidade** (`/etc/systemd/system/onion-auth.slice`):
```ini
[Unit]
Description=Slice do provedor de identidade (Logto + Postgres) — portao de entrada do bridge

[Slice]
MemoryMin=512M
MemoryLow=768M
```
```sh
sudo systemctl daemon-reload
sudo systemctl start onion.slice onion-auth.slice
```

**Camada 3 — os containers, via chaves oficiais da Compose Spec** (não exigem Swarm), em
`/home/marcio/onion-logto/docker-compose.yml`:
```yaml
  logto-postgres:
    mem_limit: 512m          # já existe
    mem_reservation: 256m    # NOVO — soft-floor (mapeia memory.low no cgroup v2)
    oom_score_adj: -500      # NOVO — MESMO viés de Caddy/bridge (este funciona: medido)
    cgroup_parent: onion-auth.slice   # NOVO — NOME de slice, porque o driver é systemd (P0.6)
  logto:
    mem_limit: 1g            # já existe
    mem_reservation: 512m    # NOVO
    oom_score_adj: -500      # NOVO
    cgroup_parent: onion-auth.slice   # NOVO
```
Depois, aplicar com `./up.sh` (recria os containers **dentro** do slice).

> **`cgroup_parent` depende do driver (fix L2):** com driver **`systemd`** (medido hoje), o valor é um
> **nome de slice** (`onion-auth.slice`). Com driver **`cgroupfs`**, seria um **caminho** (`/onion-auth`).
> Errar **não gera erro** — os containers ficam onde estavam e o floor não se aplica. **P0.6 re-confere.**

**Verificação — no path REAL, e percorrendo a cadeia:**
```sh
systemctl show onion-auth.slice -p Slice        # esperado: Slice=onion.slice  (confirma o path)
cat /sys/fs/cgroup/onion.slice/memory.min                    # 536870912
cat /sys/fs/cgroup/onion.slice/onion-auth.slice/memory.min   # 536870912
systemd-cgls /sys/fs/cgroup/onion.slice/onion-auth.slice     # os DOIS containers dentro?
check_floor /sys/fs/cgroup/onion.slice/onion-auth.slice      # ✓ cadeia inteira (função de §5b)
docker inspect onion-logto --format '{{.HostConfig.MemoryReservation}} {{.HostConfig.OomScoreAdj}}'
# deixa de ser "0 0"
```

**Gap residual, se algo falhar:** se os containers **não** aparecerem dentro do slice (driver errado,
`cgroup_parent` ignorado), fica só o `oom_score_adj -500` (que funciona) e o **gap é DECLARADO E ABERTO no
KG** — não silenciado. Alternativa mais pesada (**cgroup delegation ao dockerd**) fica **gated**.

*Rollback: remover as 6 linhas NOVO do compose + `./up.sh`; `systemctl stop onion-auth.slice onion.slice` +
apagar as duas units + `daemon-reload`. Nenhum estado persistente fica.*

### 5d — Console auto-off por timeout — NÃO EXISTE ainda

`console.sh` só tem on/off/status manuais (medido: o `case` tem `on)`, `off)`, `status)`); console
**desligado** agora. **Fecho concreto:** no `case on)`, após o `reload`, agendar um desligamento transiente
com `systemd-run` em modo **SYSTEM** (`sudo`, **não** `--user` — timers de usuário morrem ao fim da sessão
SSH; os de sistema não), com nome de unit fixo para poder cancelar/resetar:
```sh
# cancela um autooff pendente de um 'on' anterior e agenda um novo
sudo systemctl stop onion-logto-console-autooff.timer 2>/dev/null || true
sudo systemd-run --unit=onion-logto-console-autooff \
  --on-active="${CONSOLE_AUTOOFF:-30m}" \
  /home/marcio/onion-logto/console.sh off
echo "  auto-desligamento agendado em ${CONSOLE_AUTOOFF:-30m}"
```
E no `case off)`, acrescentar `sudo systemctl stop onion-logto-console-autooff.timer 2>/dev/null || true`
para não deixar o timer disparando sobre um console já desligado. `--on-active` aceita `30m`/`1h`.
*Rollback: reverter o patch do `console.sh`; nenhum estado persistente fica.*

---

## 6. Verificação (o que prova o fecho) — 23 testes

**Identidade — emissão (P4):**

1. **Serviço (M2M):** `curl` do P4.1 + `decode_jwt` (§3.6a — **node/base64url**, nunca `base64 -d`, nunca
   `2>/dev/null`) → JWT de 3 partes, `aud=https://bridge.onionevolve.com`, `scope=bridge:invoke`,
   `sub == client_id`, `expires_in` curto.
2. **Humano (PKCE):** login real na PWA → `getAccessToken('https://bridge.onionevolve.com')` → `decode_jwt`:
   `sub` = **id do usuário** (**≠** `client_id`), `aud` = bridge, `scope` = `bridge:invoke`.
   *(Prova do alvo (a): agora há QUEM, por pessoa.)*
3. **Prova do B1, se o A falhar (fix J):** token pedido **SEM** `resource=`, após marcar o default resource
   → `aud` correto. Se não vier, **B1 reprovado** — descer para B2.

**Identidade — enforcement (após P7):**

4. **401 sem token:** `curl -s -o /dev/null -w '%{http_code}\n' https://app.onionevolve.com/<rota-de-invoke>` → **401**.
5. **401 com token inválido:** `Authorization: Bearer deadbeef` → **401**.
6. **401 com token expirado** → **401**.
7. **401 com token de audiência errada** (pedir token com outro `resource=`, se o tenant tiver outro) →
   **401**. *(É o teste que prova o `aud`-binding do §3.3 — e o que fica mais fraco sob o plano B3;
   registrar o resultado.)*
8. **403 com JWT válido sem o scope:** usuário sem a role `bridge-operator` → **403 `insufficient_scope`**
   (≠ 401 — prova que as duas camadas do §3.2 item 4 estão distintas).
9. **200 com JWT humano** e **200 com JWT M2M** na rota de invoke, fim-a-fim.

**Route-scoping:**

10. **Assets abertos:** `GET /`, `/index.html`, `/assets/<algum>.js` **sem** token → **200**.
    *(Se der 401, o login é impossível — é a falha exata que a v1 embutia.)*
11. **`/health` sem token → 200**, e **sem** depender do Logto (§3.7).
12. **PATH-TRAVERSAL NEGADO — [fix B, o teste que a v2 não tinha].** Todos **sem** token, todos → **401**:
    ```sh
    # o MESMO corpus de 12 que a guarda de §3.4b já passou em bancada — agora contra o host real
    for p in '/assets/%2e%2e/invoke' '/assets/../invoke' '/assets/..%2finvoke' \
             '/assets/%2f%2f..%2finvoke' '/assets//../invoke' '/assets/%252e%252e/invoke' \
             '/icons/../invoke' '/.well-known/../invoke' '/assets/%2e%2e%2finvoke' \
             '/assets/%zz' '/assets/%00/invoke' '/assets/%5c..%5cinvoke'; do
      printf '%-34s → %s\n' "$p" \
        "$(curl -s -o /dev/null -w '%{http_code}' --path-as-is "https://app.onionevolve.com$p")"
    done
    # TODOS devem dar 401 (ou 404). Um 200 aqui = allowlist furada = o buraco de volta.
    ```
    **`--path-as-is` é obrigatório** — sem ele, o próprio `curl` normaliza o path e o teste vira teatro.
    E o **contra-teste que impede a guarda de virar zelo cego**: `GET /assets/logo%20final.svg` (espaço
    percent-encoded, **não** é traversal) tem de seguir **200 sem token** — uma guarda que nega isso quebra
    a PWA e será desligada na primeira sexta-feira.
13. **Nenhum 5xx no traversal:** os mesmos paths não podem gerar exceção não-tratada (um `decodeURIComponent`
    que estoura sem `try` viraria 500 e, dependendo do handler de erro, poderia contornar o gate).
14. **ORDEM DE REGISTRO — [fix C].** No boot, a assertion do §3.4c **não** dispara (sem `[FATAL]` no log); e
    o dump `app.routes` mostra `requireIdentity` no **índice 0**. Teste negativo (em dev, nunca em prod):
    mover o `app.use` para depois de uma rota → o serviço **tem de morrer no boot**.
15. **Mutação em prefixo aberto é negada:** `POST /assets/x` sem token → **401** (a allowlist só abre
    `GET`/`HEAD`).
16. **Rota nova nasce protegida:** conferir que **toda** rota do dump de runtime que não está na allowlist
    devolve 401 sem token — inclusive as que não estavam na tabela do §3.4.

**Fail-closed:**

17. **Env some → enforce:** remover `BRIDGE_AUTH_MODE` do ambiente + restart → request sem token segue **401**.
18. **Valor lixo → enforce:** `BRIDGE_AUTH_MODE=false` + restart → **401** sem token.
19. **`AUTH_TOKEN` recusado após P9:** request só com o header/token legado → **401**.

**Acoplamento:**

20. **Logto down, token válido em mãos:** parar o container do Logto e repetir o teste 9 dentro da janela de
    cache do JWKS → **200** (degradação graciosa esperada). Depois da expiração do token → **401**
    (fail-closed). Religar. *Registrar a janela real medida.*

**Endurecimento (host) — agora lendo o EFETIVO:**

21. **Floors efetivos (fix A):** `check_floor /sys/fs/cgroup/system.slice/caddy.service` e
    `check_floor /sys/fs/cgroup/system.slice/onion-bridge.service` → **`✓ cadeia inteira sustenta o floor`**.
    *(Antes do fix, medido: `✗ TETO DE ANCESTRAL: /sys/fs/cgroup/system.slice (0)`.)*
    E `cat /proc/$(pgrep -x caddy | head -1)/oom_score_adj` → `-500` (esta metade já passava).
22. **Slice do Logto no path REAL (fix D):** `systemctl show onion-auth.slice -p Slice` → `Slice=onion.slice`;
    `cat /sys/fs/cgroup/onion.slice/onion-auth.slice/memory.min` → `536870912`;
    `check_floor /sys/fs/cgroup/onion.slice/onion-auth.slice` → `✓`;
    `systemd-cgls /sys/fs/cgroup/onion.slice/onion-auth.slice` mostra os **dois** containers;
    `docker inspect onion-logto --format '{{.HostConfig.MemoryReservation}} {{.HostConfig.OomScoreAdj}}'`
    deixa de ser `0 0`. *(Se os containers não estiverem dentro: conferir `docker info --format
    '{{.CgroupDriver}}'` — P0.6 — e registrar o gap no KG.)*
23. **`/a2a` segue gateado depois do flip — [fix L1].** Conforme a decisão do P0.2c:
    - **cobertura dupla (default):** `POST /a2a` com payload válido de a2a **sem** Bearer → **401**;
      com Bearer válido **mas** envelope a2a inválido → **rejeitado pelo `a2a-verify.sh`** (não 200).
      *Prova que as duas camadas estão vivas e independentes.*
    - **exceção documentada:** `POST /a2a` sem Bearer **não** dá 200 por conta do gate a2a, e o teste 16
      confirma que `/a2a` **não** entrou na allowlist de rotas abertas.
    Além disso: `./check-version.sh` → `✓ em dia (<versão>)`; `crontab -l | grep -i logto` mostra o verifier
    (re-medição do §5a); `systemctl list-timers | grep onion-logto` mostra o autooff agendado com o console
    ligado.

---

## 7. O que fica GATED (não faz parte deste flip)

- **RBAC multi-operador humano / plataforma admin (M3).** Mapear a topologia da federação em **Logto
  Organizations** só quando a plataforma pedir — i.e., no **gatilho multi-operador** (1º `role:consumer` real
  em `members.yaml`). Enquanto houver **um** operador, Logto Orgs = PROJEÇÃO, `members.yaml` = SSOT; não se
  constrói agora (anti-padrão `gated-work-derives-fresh`). **Nota:** o login humano por PKCE **saiu** do
  gated (entrou no escopo, §3) — o que segue gated é a **malha multi-operador**, não a identidade de um.
- **Endurecimento da PWA como cliente** (§3.10): CSP completa, SRI, auditoria de dependência, storage do
  token fora do `localStorage`. Este spec fixa as três mitigações baratas e **nomeia** que a PWA entrou na
  base de confiança; o endurecimento em si é trabalho próprio.
- **Caddy `forward_auth` + oauth2-proxy.** Só faria sentido para uma superfície **server-rendered com sessão
  de cookie**. Com a PWA fazendo PKCE in-app, é redundante (§3.8).
- **RBAC fino por operação no bridge** (distinguir "ler" de "mutar" por membro/tier) e **vínculo profundo a
  `members.yaml`**. Este flip entrega o eixo **identidade** (quem, revogável, atribuível) + o **gancho** de
  `scope` com duas camadas (role → scope); a malha de autorização por operação é trabalho do control-plane.
- **Revisão do `bypassPermissions` do Agent SDK.** É um eixo **separado** (o gate de execução do Claude Code),
  decisão do maestro; este spec fecha o **portão de entrada**, não altera o modo de permissão do SDK.
- **Aposentar o BYOK / redesenhar cortesia-login.** Depende de confirmar no host (VPS-declarado).
- **cgroup delegation ao dockerd** (para `memory.min` nativo por container, caso `cgroup_parent` não pegue).
  Muda como o dockerd gerencia cgroups; só com necessidade demonstrada (§5c).
- **Auditoria dos DEMAIS floors do host.** O fix A é uma **classe**, não um caso: qualquer `MemoryMin`/
  `MemoryLow` declarado em qualquer unit deste VPS pode estar decorativo pelo mesmo motivo. Varrer com o
  `check_floor` do §5b é trabalho próprio, fora deste flip.

---

## 8. Guardrail final

Segurança **defensiva**: nada aqui abre superfície, coleta credencial sob pretexto, nem promete camadas de
inferência de produto. O fecho é **substituição de um segredo compartilhado por identidades emitidas e
validadas** — uma **por pessoa** (PKCE) e uma **por serviço** (M2M) — com **default-deny por rota**,
**guarda de canonicalização de path**, **ordem de registro do middleware verificada por assertion**,
**enforcement fail-closed por ausência de configuração**, **algoritmo pinado**, **plano-B provado** para a
dependência de RFC 8707, **risco de armazenamento de token nomeado** e **comportamento sob queda do IdP
escrito antes de acontecer**; mais endurecimento de host **que agora protege de fato**, porque a verificação
passou a ler o cgroup **efetivo** em vez do **configurado**.

**A lição que atravessa esta revisão inteira:** *configurado não é protegido, e declarado não é verificado.*
Ela apareceu três vezes nesta rodada — no floor de memória que o ancestral zerava, na allowlist que uma
string com `%2e%2e` atravessava, e no comando de prova que teria roteado o desenho para um plano-B mais
fraco por um bug de shell. As três só apareceram porque alguém **rodou o comando**, em vez de reler o texto.

Reversível por uma linha de env até P8. **O maestro executa o flip de auth; a sessão do core especifica,
mede o host e prova.**
