# Roadmap — Redesign da Federação Onion (2026)

> Sequência de implementação decorrente de **RFC-0004** (topologia + interop ao vivo, accepted 2026-07-09)
> e da pesquisa em `docs/evolution/research/federation-2026/`. **Reuso, não invenção:** cada item apoia numa
> fundação existente (`graph.sh`, SDAAL, doc-bridge, Federação formal dormente). Cada slice segue o padrão
> **dogfood-first** (helper/artefato testável → fiação → validação de campo), como o Achado #2.

## Princípio de ordenação
Menor dependência de decisão de doutrina × maior alívio de dor. **Fase 1 não requer a RFC-0004** (é derivação
pura do SSOT) → libera valor imediato. **Fase 2 é gated na RFC-0004** (transporte ao vivo, sob gate humano).

---

## FASE 1 — independente de doutrina (o SSOT já basta)

### F1.1 — `graph.sh` ingere `members.yaml` → mapa de adoções derivado (P0-4) · SEMENTE
- **O quê:** 5ª fonte de triplas no `graph.sh` lendo `members.yaml` (nós = membros; arestas = `parent`→adopts,
  `specializations`→tags, `trust.*`→confiança, `lineages`→sub-nós). Emissor **Mermaid** (`map.mmd`) renderizável
  em docs/GitHub sem build; opcional `file_server` num subdomínio.
- **Por quê primeiro:** é o **pré-requisito técnico único** de F1.2/F1.3 e mata o SVG desenhado à mão do site.
- **Reuso:** `graph.sh` (motor BFS já existe) · `members.yaml` (SSOT rico). **Evidência:** `S3·F6/F8`, `S2·F1/F2`.
- **Esforço:** pequeno. **Gate:** nenhum (derivação). **Dogfood:** rodar contra o `members.yaml` real (5 membros).

### F1.2 — Targeting fino por seletor no `alvo:` (P0-2)
- **O quê:** `/meta:co-announce` resolve `alvo:` como **query** sobre `specializations`/`mode`/`tier`/`trust`
  (padrão ApplicationSet/policy-as-data), em vez de per-id OU broadcast. Ex.: `alvo: {mode: regulated}`,
  `{specialization: nx-monorepo}`. **Zero campo novo** no SSOT — o `members.yaml` já é policy-as-data.
- **Reuso:** o closure gated do `graph.sh` (pós-F1.1) avalia a política sobre o grafo de membros.
- **Design/dogfood pendente (o único gap "não-pesquisa"):** sintaxe do seletor, precedência, closure gated.
- **Esforço:** médio. **Gate:** nenhum (doutrina não muda). **Evidência:** `S2·F3`, `S1·F12`, `S4·F2`.

### F1.3 — Console read-only da federação (P0-3)
- **O quê:** projeção estática (CQRS leve) sobre o event-log que **já existe** (git/CHANGELOG append-only):
  script → `feed.json` + `members.json`; página HTML + filtro/timeline/side-drawer servida pelo **Caddy**
  (`console.onionevolve.com`), regenerada por hook/cron. **Zero backend, zero DB.** Superfície visual do
  `/meta:federation-status`. O filtro por `specialization`/`mode` **expõe visualmente** o fix de F1.2.
- **Reuso:** CHANGELOG/`inbox`/`inbound` como event-store · `federation-status` como monitor · Caddy na VPS.
- **NÃO fazer:** plataforma tipo Backstage/Port (over-engineering p/ 5 membros — `S3·F1`). Tooling exato do
  front-end fica em aberto (`S3·F11` era hipótese). **Esforço:** pequeno-médio. **Evidência:** `S3·F3/F5/F10/F12`.

### F1.4 — Receiver que acorda a sessão (P0-1 parcial)
- **O quê:** evoluir o hook "you have mail" (📬/📥) de "contar arquivos" para **acordar a sessão do adotante**
  quando há sinal — mantém pull/git-async como SSOT, ganha responsividade **sem** virar push nem quebrar I3.
- **Reuso:** o hook já é um proto-webhook-receiver local (`S2·F6`). **Esforço:** pequeno. **Gate:** nenhum.

---

## FASE 2 — gated na RFC-0004 (transporte ao vivo, sob gate humano)

### F2.1 — `federation-transport` SDAAL (git-async | local | a2a-live)
- **O quê:** abstrair o transporte atrás de `interface.md`/`factory.md`/adapters (padrão `task-manager`), com
  `detectTransport()` lendo `members.yaml`. Unifica os scripts `co-deliver`/`co-relay` soltos + habilita o
  `a2a-live` como 3º adapter. **Reuso:** `task-manager/factory.md` (precedente pronto). **Evidência:** `S1·F7`, `G1`.

### F2.2 — Endpoint `a2a-live` gated no bridge (P0-1 completo)
- **O quê:** endpoint A2A (JSON-RPC/HTTP+SSE + `PushNotificationConfig` webhook) atrás do Caddy; Agent Card em
  `/.well-known/agent-card.json`; sobre o `onion-bridge` (já roda). **Só SINAIS GATED** (nunca conversa
  autônoma). `pin-integrity-check` = verificação-antes-de-agir; gate humano = estados `input_required`/
  `auth_required`; `never-live-pull` p/ regulados. **Gate:** RFC-0004 + gate humano + dogfood. **Evidência:** `G1`, `S1·F4/F5/F9`.
- **Fundação segura no core — ✅ (2026-07-09), dogfood-first:** o **gate de verificação-antes-de-agir** já
  existe e é testado no core, SEM abrir canal: `a2a-verify.sh` (6 camadas fail-fast — trust policy compondo
  `trust-topology-check.sh` · anti-replay `jti` · janela de timestamp · anti-SSRF · assinatura JWS RS256 ·
  never-live-pull; **fail-safe = VETO, nunca skip**) + `a2a-ssrf-check.sh` + Agent Card gerado
  (`a2a-agent-card.sh` → `docs/onion/agent-card.json`, filtrado ao core) + contrato do adapter completo +
  **27 selftests** + drift-guard **REGRA 25**. De-risca o endpoint.
- **Endpoint vivo — ✅ (2026-07-09, verificado 2026-07-10):** rota `/a2a` no ar atrás do Caddy (401 sem auth =
  gate correto) + Agent Card servido em `app.onionevolve.com/.well-known/agent-card.json` (capabilities
  streaming/pushNotifications declaradas). **1º handshake real validado ponta-a-ponta** (metagamify→core:
  `verified:true` + `input_required`, nada auto-aplicado) — e o dogfood expôs+fechou o gap de kid-binding no
  mesmo loop (diário `2026-07-09-first-live-a2a-handshake`). O endpoint chama o `a2a-verify` do core na
  fronteira transport→ação; `a2a-accept.sh` fecha a outra ponta (fila→inbox sob ato humano).
- **Dogfood com adotante REGULADO — ✅ (2026-07-10) → F2.2 COMPLETO:** handshake granaai→core validado ao
  vivo sob autorização explícita do maestro (cobertura da ponta adormecida, commit isolado `cd60d103c` na
  branch `onion/a2a-sender-granaai`): keypair self-gerado lá, pubkey pinada aqui (`dc489b4`), sinal assinado
  → `/a2a` público → verificado (7 camadas, incl. a guarda **clock-trust** estreada no mesmo dia, `e750023`)
  → fila gated → `a2a-accept` → inbox → triado. Nota honesta: `apply_mode:propose-only` é caminho de
  **receptor** regulado (coberto por selftest); o vivo exercitou kid-binding+clock com membro regulado real.
  Diário: `2026-07-10-first-regulated-a2a-handshake`. Follow-ups FECHADOS (mesmo dia): token a2a
  DEDICADO da granaai provisionado (gesto humano do maestro: env+restart; re-dogfood verde com o token
  novo — `verified:true`, aceito e triado) · sender da granaai em PR (`GranaAi/granaai#1135`, base
  develop; a sessão da granaai acordou e roda `/meta:adopt --update` — coordenação viva).

### F2.3 — Veto reputação-condicionado (evolução futura)
- **O quê:** ligar reputação-por-evidência (`trust-log` + `can_correct_to`) como condicionante do veto/urgência
  do `federation-check`. **Permanece gated atrás de dogfood** (números de `G3·A` são de simulação). **Evidência:** `G3·A`, `S4·F3`.

---

## Fora de escopo do roadmap (mercado não resolve → curar à mão, gated)
- **Descoberta governada em escala** (registry de capacidade com curadoria/confiança) — problema aberto no
  mercado (`G2`); o Onion mantém A2A/registry **gated + curado**, não assume padrão pronto.

## Verificação (por slice)
Cada slice: gate mecânico (`lint-artifacts` + `lint-selftest` verdes) + **dogfood do artefato de verdade**
(F1.1 contra o `members.yaml` real; F1.3 servido pelo Caddy; F2.2 handshake com um adotante regulado sob gate).
Nada de "declarado" sem "verificado".
