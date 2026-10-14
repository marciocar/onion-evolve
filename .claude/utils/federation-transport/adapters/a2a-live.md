# adapter: a2a-live — endpoint VIVO desde 2026-07-09; ACEITAÇÃO segue humana (gated)

> **CORREÇÃO 2026-08-30 (censo, juiz adversarial): o endpoint ESTÁ implementado e VIVO.** A frase
> anterior — "ENDPOINT NÃO IMPLEMENTADO" — ficou CADUCA e quase virou carimbo: um worker a citou como
> evidência e o juiz mediu **200** em `GET /.well-known/agent-card.json` (serviço `onion-vps-bridge`
> ativo; `POST /a2a` com a2aGuard + pool de token dedicado; 1º handshake real registrado no diário em
> **2026-07-09**). O que SEGUE gated é a **ACEITAÇÃO**: todo payload entra em `data/a2a-pending/` e só
> vira inbox por ato humano (`a2a-accept.sh`) — o transporte nunca é auto-selecionado. Doutrina:
> declaração de doc ≠ estado do sistema ([[behavior-over-declaration]]); este cabeçalho agora descreve
> o que o sistema FAZ.


## Desenho (fundamentado — pesquisa `research/federation-2026/G1` + RFC-0004 §3)

- **Transporte:** A2A (JSON-RPC/HTTP + **SSE** quando conectado) + **`PushNotificationConfig` webhook** quando
  offline (recebe/retoma) + **checkpoint durável** (o `inbound/` commitado já é o checkpoint). Agent Card em
  `/.well-known/agent-card.json`. Hospedável atrás do Caddy já existente, sobre o `onion-bridge` (já roda).
- **Só SINAIS gated** (`Signal`), **nunca** conversa autônoma agente↔agente (A2A não protege prompt-injection
  cross-agent — `G1`). O gate humano = consumo idiomático dos estados A2A `input_required`/`auth_required`.
- **Verificação-antes-de-agir** (a spec A2A já exige do receptor): `pin-integrity-check.sh` + trust SDAAL +
  anti-replay (`jti`)/anti-SSRF/assinatura (JWS) **antes** de qualquer sinal virar ação. Ingestão remota =
  supply-chain não-confiável até verificada (`S4·F6`).
- **`never-live-pull`** p/ regulados (ex.: um adotante regulado): recebe sinal, mas só aplica pelo mesmo gate (proposta →
  confirmação do maestro). Nunca puxa framework ao vivo.

## deliver(signal)
Push A2A JSON-RPC/SSE quando conectado; senão `PushNotificationConfig` webhook (retoma quando o receptor
reconecta). O **checkpoint durável** é o `inbound/` commitado pelo destino (não este canal). Retorna
`DeliveryResult{ transport:'a2a-live', delivered, committed:false, gated:true }` — **committed SEMPRE false**
(I3, entrega-sem-commit: quem commita/tria é a sessão do destino) e **gated SEMPRE true** (nada é auto-aplicado).
Bridge down / qualquer falha de canal → **degrada p/ `git-async`** (o system-of-record e fallback — factory.md).
Nunca commita cross-repo; nunca dá ao transporte remoto poder de escrita (isolamento do bridge `bypassPermissions`).

## receive(memberId)
Antes de QUALQUER sinal virar ação, delega ao gate obrigatório **`a2a-verify.sh --receiver <self>`**
(verificação-antes-de-agir; a spec A2A a exige do receptor):
1. **trust policy** (compõe `trust-topology-check.sh`: origem ∈ policy-as-data do `members.yaml`) ·
2. **anti-replay** (`jti` single-use) · 3. **janela de timestamp** · 4. **anti-SSRF** (`a2a-ssrf-check.sh` na
URL do webhook) · 5. **assinatura JWS** (RS256, pubkey pinada por `kid` no JWKS fixture) · 5b. **corpo
assinado** (`body_sha256`, abaixo) · 6. **never-live-pull** (receptor `mode:regulated` → `apply_mode:propose-only`).

### O que é assinado (desde 2026-10-14)

Até 2026-10-14 a assinatura cobria **só os claims**: trocar `signal.body` depois de assinar devolvia
`verified:true`, e um JWS sem `exp` valia para sempre (achados F1 e F2 do spike A2A cross-user,
`docs/evolution/research/a2a-cross-user-spike-2026-10/`). Agora:

| o quê | como entra na assinatura | sem isso |
|---|---|---|
| `iss`, `aud`, `jti` | claims do payload JWS | veto (`claim-iss-mismatch`, `claim-aud-mismatch`, `jws-missing-jti`) |
| `iat`, `exp` | claims **obrigatórios**, inteiros; `exp − iat ≤ teto` e `exp ≤ now + teto` (teto = `A2A_EXP_MAX_TTL`, default **3600 s**) | `jws-missing-exp`, `jws-missing-iat`, `jws-bad-exp`, `exp-not-after-iat`, `exp-beyond-ceiling` |
| o **corpo** `signal.body` | claim **obrigatório** `body_sha256` = sha256 (hex minúsculo) dos **bytes UTF-8 da string já decodificada** | `jws-missing-body-sha256` (remetente antigo) · `body-mismatch` (corpo trocado) · `body-not-string` |
| `signal.body_path`, `signal.thread` | se presentes no signal, têm de estar **iguais** como claim | `claim-body_path-mismatch`, `claim-thread-mismatch` |
| cópia `signal.body_sha256` | se presente, igual ao claim | `signal-body-sha256-mismatch` |
| chave JSON duplicada (envelope ou payload) | — | `duplicate-key:<onde>` |
| `signal.id`, `direction`, `kind`, `classification` | **NÃO assinados**; forma fechada: 1–128 de `[A-Za-z0-9._:-]` | `signal-field-unsafe:<campo>` |
| `signal.from`, `to`, `thread` / `body_path` | comparados com claims e, além disso, na mesma forma fechada / 1–256 de `[A-Za-z0-9._/-]` sem `..` | `signal-field-unsafe:<campo>` |
| tipo de `iss`/`aud`/`jti` | string, sem caractere de controle (C0, DEL, C1, U+2028/9) | `jws-bad-claim-type`, `jws-claim-control-char` |
| qualquer outra chave no `signal` | — | `signal-unknown-key:<chave>` |

- **Canonicalização (declarada):** o corpo é uma **string JSON**; o canônico são os bytes UTF-8 do valor
  decodificado, sem aspas e **sem normalização Unicode**. A forma de escape no transporte (`é` ou `é`)
  não entra no hash, que é o efeito que a JCS (RFC 8785) busca. Hash sobre os bytes crus do envelope não
  serviria: o bridge faz `JSON.parse` e re-serializa antes de chamar o gate. NFC e NFD do mesmo texto são
  bytes diferentes e dão `body-mismatch` (fail-closed: quem assina escolhe a forma).
- **Corpo ausente = corpo vazio:** o remetente assina `body_sha256` do vazio
  (`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`). Acrescentar um corpo depois quebra
  o hash. Um sinal sem corpo (ping, ou `body_path` de julho) continua possível, mas assinado como vazio.
- **NÃO assinados (declarado):** `signal.id`, `direction`, `kind`, `classification` e `pushNotificationConfig`.
  São metadados de roteamento, e quem os troca sem a chave muda a ETIQUETA, não o conteúdo. Como o
  `a2a-accept` os escreve no frontmatter e no título do doc de inbox, o gate fecha a forma deles (sem quebra de
  linha e sem espaço, então nada vira chave YAML nova) e recusa chave desconhecida no `signal`: uma injeção de linhas
  de YAML ou prosa num sinal verificado era possível antes disso (achado do refutador, 2026-10-14). Se um
  consumidor passar a DECIDIR por eles, o claim entra antes.
- **Sem modo legado:** remetente sem `body_sha256` é recusado, nunca aceito em silêncio. Os remetentes
  conhecidos são os membros com `a2a.keys` no `members.yaml`. Os dois de julho usam um
  `.onion-a2a/send-signal.sh` próprio, que **precisa** acrescentar ao payload `"body_sha256"` (sha256 do
  corpo, ou do vazio) e, se mandar `body_path`, o claim `"body_path"` igual; o `exp = now + 3600` deles já
  cabe no teto. O membro de teste do spike usa o `send-a2a.sh` do spike, que já está conforme. A mudança é no
  repo de cada remetente, pela sessão dele: o core não escreve lá.
- **Veredito `verified:false` → REJEITA** (fail-safe: ausência/erro nunca é aprovação; payload remoto =
  supply-chain não-confiável até verificado). Toda camada não-avaliável (ferramenta ausente) → VETO, nunca skip.
- **Veredito `verified:true` → ainda `gated:true`**: o sinal entra para triagem sob **gate humano** (consumo
  idiomático dos estados A2A `input_required`/`auth_required`), nunca auto-aplicado. Regulado → propose-only.
- O gate NÃO faz rede (JWKS é fixture local pinada); o fetch de JWKS ao vivo + o socket SSE/webhook são do
  **endpoint na VPS**, fora do core.

## Agent Card
Gerado por `.claude/validation/a2a-agent-card.sh` → `docs/onion/agent-card.json` (drift-guard REGRA 25):
projeção do SSOT **filtrada ao próprio core** (confidencialidade — zero dado de adotante), `skills` **signals-only**
(nunca conversa autônoma), `securitySchemes` oauth2(PKCE)+mTLS. O endpoint na VPS o serviria em
`/.well-known/agent-card.json`.

## Pré-condições p/ sair do stub (F2.2)
- **Fundação de segurança no core: ✅** (`a2a-verify.sh` + `a2a-ssrf-check.sh` + Agent Card + selftests +
  drift-guard REGRA 25) — de-risca o endpoint sem abrir canal.
- **Endpoint vivo (VPS): pendente, GATED** — RFC-0004 aceita ✅ · Fase 1 completa ✅ · falta **gate humano do
  maestro** + **dogfood do handshake com um adotante regulado**. Vive no repo privado `~/onion-bridge` (Hono/
  SSE/webhook), que serve o Agent Card e chama o `a2a-verify` do core na fronteira transport→ação.
- Fallback: sempre degrada p/ `git-async` (system-of-record).
