---
title: "Pesquisa F1 — WAHA (estado current) + a forma do adapter WhatsApp (SDAAL)"
category: research
date: 2026-07-31
status: sintese-ratificavel
method: "Elenxo orquestrado (fan-out-and-synthesize) — 3 workers: 2 research (sonnet/medium; WAHA web-verificado + forma do adapter repo-grounded) → 1 síntese (opus/high)"
run_id: wf_8f21c4da-3de
kg: docs/evolution/research/waha-adapter-2026-07/waha-adapter-2026-07.kg.yaml
---

# WAHA + a forma do adapter WhatsApp — síntese F1

> ## ⚑ CORREÇÃO 2026-07-31 (ratificada pelo maestro — SUPERSEDE a nomenclatura abaixo)
>
> Esta síntese recomendou domínio **`whatsapp`** (não `messaging`) e prefix `WA_`. **Estava errada** —
> foi produzida **sem** o ADR canônico [`onion-adr-sdaal-nested-two-level-2026-07.md`](../../../analysis/onion-adr-sdaal-nested-two-level-2026-07.md)
> em contexto (falha de aterramento da orquestração: os workers foram apontados a `task-manager`/`forge`/
> `integrations.md`, não ao ADR). A pergunta do maestro pegou a defasagem.
>
> **O correto (ADR 2026-07-17, `accepted`):** **SDAAL aninhado de 2 níveis — canal → solução.**
> **Nível-1 = CANAL** (`messaging`: whatsapp/sms/email/push) · **Nível-2 = SOLUÇÃO** (whatsapp → waha/web-js/cloud-api).
> Teste do Eixo é **recursivo** ("aninhar não relaxa o gate — multiplica-o"); canal→solução é **faceta** (escolhe-1);
> default de solução é **por canal**, declarado; fallback nos **dois** eixos. Validado por mercado (Novu/Knock).
>
> **Convenção de env ratificada** (recursiva, deriva da convenção viva `<DOMAIN>_PROVIDER`):
> `<CAMINHO>_PROVIDER` **seleciona** em cada nível · `<CAMINHO>_<SOLUÇÃO>_<CONFIG>` **configura**.
> ```
> MESSAGING_PROVIDER=whatsapp|ntfy|email
> MESSAGING_WHATSAPP_PROVIDER=waha|web-js
> MESSAGING_WHATSAPP_WAHA_BASE_URL / _API_KEY
> ```
> Diretórios espelham: `.claude/utils/messaging/` → `adapters/whatsapp.md`, que é sub-SDAAL em `messaging/whatsapp/`.
> **Bônus:** resolve melhor que o `WA_` a colisão real (o WAHA consome `WHATSAPP_HOOK_*` como config **do container**).
>
> **2ª correção ratificada:** o **`whatsapp-sender` é a APLICAÇÃO (consumidor)**; WAHA e whatsapp-web.js são os
> **meios** (soluções de nível-2). Isso **resolve o gap mais caro** ("nenhum consumidor real nomeado") — a régua (c)
> do Eixo ganha sujeito — e o trabalho vira **refatorar o sender para chamar a abstração** (hoje ele importa a lib
> direto = anti-padrão #2). **Metade do critério de retração abaixo já caiu**; resta só a degradação do `getSessionStatus`.
>
> **Ganho de ordem:** o gatilho do **nível-1** já está quase completo — `ntfy` (push) **já existe** ad-hoc em
> `mail-receiver.sh`; subir o WAHA dispara os **dois** níveis de uma vez.


> **Projeção do grafo.** SSOT: [`waha-adapter-2026-07.kg.yaml`](./waha-adapter-2026-07.kg.yaml).
> Contexto: F1 da investigação de ferramentas VPS (catálogo — ver
> [`vps-shared-tools-2026-07.kg.yaml`](../../../onion/graph/vps-shared-tools-2026-07.kg.yaml)).

## Veredito

**DOGFOOD PRIMEIRO, SDAAL DEPOIS.** O Teste do Eixo passou no papel (2 providers), mas o
**Teste do Gatilho não disparou**: hoje há **1 provider REAL rodando** (whatsapp-web.js na VPS) e
**1 DIRIGIDO** (WAHA, não deployado) — e `1 real + N prometidos = script`. Escrever a interface antes
do WAHA existir seria catedral, e escrita contra uma **doc**, não contra um **comportamento**
(behavior-over-declaration).

**Ordem a construir:**
1. **Deployar o WAHA na VPS e mandar 1 mensagem real** (`docker run` → `POST /api/sessions` → QR → `WORKING` → `POST /api/sendText`). **Isto é o gatilho**, não preparação.
2. **Medir as 2 degradações do wwebjs** — `getSessionStatus` sem subir Chromium é possível? `send.js` devolve id/exit-code útil? **Decide se o contrato mínimo tem 2 operações ou 1.**
3. Só então escrever `.claude/utils/whatsapp/{README,interface,types,detector,factory}.md` + `adapters/{waha,whatsapp-web,none}.md`, com a **tabela de assimetria no README**.
4. `.env.example`: `WA_PROVIDER` + vars dos dois adapters. **Sem `WA_TRANSPORT`** (env switch fictício = anti-padrão #3).
5. **Nomear o 1º consumidor cego** e ligá-lo (sem consumidor, a régua (c) do Eixo não tem sujeito).

### ⚠️ Critério de retração (escrito ANTES de construir — é o que separa isto de catedral)

Se no passo 2 o wwebjs **não** responder `getSessionStatus` a custo aceitável **E** no passo 5 **não**
houver 1 consumidor real que precise ser cego → o eixo **passou no papel e falhou no contrato**:
retrair para **script + env switch** (WAHA como ferramenta única; `whatsapp-sender` legado) e esperar o
2º consumidor. *Um adapter de uma operação, com um consumidor que sabe qual provider está ativo, é cerimônia.*

## 🐕 Dogfood LOCAL executado (2026-07-31) — comportamento, não doc

Rodei o WAHA de verdade (`docker run` + `curl` contra a API viva). **Três achados que só o comportamento dá:**

| Verificação | Resultado |
|---|---|
| `docker pull devlikeapro/waha` **sem login** | ✅ **funciona** → a contradição do README ("Plus" + `docker login`) é **doc velha**. Claim `C_waha_plus_contradiction` **refutada por comportamento** |
| Tamanho da imagem | ⚠️ **4.1 GB** — dado **novo e material** para a KVM8 |
| Auth `X-Api-Key` | ✅ sem key → **401**; com key → **200** |
| `POST /api/sessions {name,start:true}` | ✅ → `status: STARTING`, `engine: NOWEB` |
| `GET /api/sessions/default` | ✅ → **`SCAN_QR_CODE`** (o enum real) |
| `GET /api/{s}/auth/qr` | ✅ → **200 `image/png`, 5418 bytes** (QR real) |
| **Engine — a hypothesis virou número** | **NOWEB 420.7 MiB** × **WEBJS 788.8 MiB** → WEBJS é **~1,9× mais pesado** |

**Decide o engine default = `NOWEB`** (KVM8 tem RAM finita). **Efeito colateral que fortalece o design:** com NOWEB,
o WAHA **não** compartilha mecanismo com o `whatsapp-web.js` (browser-based) — o argumento de **isolamento** do
default WAHA se sustenta, e os dois providers são **genuinamente diferentes em ambiente** (régua (b) do Eixo).

> **⛔ Bloqueio medido (o que NÃO é desta sessão):** `ssh` com `id_ed25519` **e** com `onion_vps_deploy`
> (comentário `onion-kvm8(srv1812846)-deploy-2026-07-08`), usuários `onion`/`marcio`/`root` → **todos
> "Permission denied (publickey)"**; o alias `onion-kvm8` não resolve. Logo **o deploy em produção e o
> pareamento do número (QR) são atos do maestro**. O dogfood local cobriu tudo que não exige a VPS nem o telefone.

## WAHA — estado current (web-verificado, fontes primárias)

| Fato | Status |
|---|---|
| Release atual **2026.7.2** (29/07/2026) | ✅ confirmed — `github.com/devlikeapro/waha/releases` |
| **Plus fundido no Core na 2026.6.1** → 100% grátis | ✅ confirmed — changelog |
| Licença **Apache-2.0** | ✅ confirmed |
| Engines **WEBJS · NOWEB · GOWS** | ✅ confirmed |
| Docker `devlikeapro/waha`, :3000, volume `/app/.sessions`, dashboard `/dashboard` | ✅ confirmed — quick-start |
| Auth da API: header **`X-Api-Key`** (`WAHA_API_KEY`) | ✅ confirmed |
| Sessão: `POST/GET/PUT/DELETE /api/sessions[/{s}]`, `start\|stop\|restart\|logout`, `GET /api/{s}/auth/qr`, `POST /api/{s}/auth/request-code` | ✅ confirmed |
| Envio: `POST /api/sendText {chatId:"<num>@c.us", text, session}` | ✅ confirmed |
| Webhooks: `WHATSAPP_HOOK_URL/EVENTS/HMAC_KEY/RETRIES_*`; eventos `message`, `session.status`, `message.ack`, `call.*`… | ✅ confirmed |
| ⚠️ **Contradição residual:** README do repo ainda cita "WAHA Plus" + `docker login` | ✅ confirmed (o sinal) — decidir no deploy: `docker pull` funciona **sem** login? |
| "NOWEB/GOWS mais leves que WEBJS" | 🔶 **hypothesis** — não verificado |

## A forma do adapter (repo-grounded)

- **Domínio `whatsapp`** (não `messaging`): o eixo que varia é *gateway de WhatsApp*, não *canal*. `messaging` convidaria telegram/slack — que **não cumprem o mesmo contrato** (sem pareamento por QR, sem identidade de número), diluindo a interface e violando a régua (a) do Eixo.
- **Env prefix `WA_`** (não `WHATSAPP_`) — **motivo verificado**: o próprio WAHA consome `WHATSAPP_HOOK_*` como config **do container**; mesmo `.env` lido por duas autoridades sob o mesmo namespace é receita de confusão. Precedente: `de-identification` → `DEID_`.
- **Interface v0.1 (4 operações):** `sendText` (única de negócio que ambos cumprem) · `getSessionStatus` (enum com **`'unknown'`** — a forma honesta de acomodar assimetria) · `connect` (devolve **cerimônia de pareamento**, não imagem: `channel:'payload'|'tty'`) · `validateConfiguration`. `MessageReceipt.id` é **nullable por contrato** (o CLI do wwebjs pode não devolver id — prometer `string` vazaria a garantia do WAHA).
- **FORA da interface (declarado):** `logout()` (só WAHA) · inbound/webhook (1 implementação real ⇒ script) · `sendMedia`/grupos (gated) · multi-sessão.
- **`none` = no-op VISÍVEL:** imprime o que seria enviado + como configurar, retorna `status:'skipped'` — **jamais `'sent'`**.
- **WAHA default** por **superset estrito** (status, QR transportável, pairing-code, stop/logout/restart, multi-sessão, webhooks) + **isolamento** (container com volume vs Chromium dentro do host) + vivo/grátis/Apache-2.0.

## Gaps (o que decide, e ainda não sabemos)

1. **O gatilho não disparou** — WAHA não deployado. Ratificação exige o 1º `sendText` real.
2. **`whatsapp-sender` não está clonado localmente** (repo privado) — tudo sobre `client.js`/`login.js`/`send.js` veio do prompt, **não de leitura**. **É o gap mais caro:** decide se o contrato mínimo tem 2 operações ou 1.
3. **Engine default do WAHA não decidido** — escolher por **medição** na KVM8 (RAM finita; WEBJS carrega browser), não por presunção. *Nota:* se o default for WEBJS, WAHA e wwebjs compartilham o mesmo mecanismo por baixo — reforça intercambialidade, **enfraquece** o argumento de isolamento.
4. **Nenhum consumidor real nomeado** — candidatos (a nomear, não presumir): notificação de PR/CI, alerta de queda na VPS (hoje ntfy), hook "you have mail".
5. Contradição Plus/README; SDK Node oficial do WAHA não verificado; endpoints de mídia/grupo não verificados; política de throttling/anti-ban não definida.
6. **Ratificação do maestro pendente:** `whatsapp` vs `messaging` (domínio) e `WA_` vs `WHATSAPP_` (prefix).
