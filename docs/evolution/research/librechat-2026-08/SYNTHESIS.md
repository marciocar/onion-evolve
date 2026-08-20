---
kg: docs/evolution/research/librechat-2026-08/librechat-2026-08.kg.yaml
run_id: "agent-fanout-2026-08-20 (3 Explore agents em paralelo; sem Workflow — plan mode)"
tokens: 218864
agents: 3
duration_min: 7
---

# LibreChat × Onion — pesquisa de instalação e integração (ago/2026)

> **Fonte é o grafo** (`librechat-2026-08.kg.yaml`, radar exit 0) — este doc é projeção.
> Três explorações paralelas: (1) padrão Onion VPS + headroom (repo/host), (2) estado do
> LibreChat em ago/2026 (externa, URL por claim), (3) mapa de integração Onion→LibreChat.
> Plano de execução aprovado pelo maestro: `~/.claude/plans/elegant-inventing-sutherland.md`.

## O achado que muda o desenho

O LibreChat v0.8.6+ adotou **Agent Skills no formato `SKILL.md`** — o MESMO padrão do Claude
Code (frontmatter `name`/`description`/`allowed-tools`, + `always-apply`/`user-invocable`) — e o
**`skillSync.github`** (librechat.yaml ≥1.3.13): aponta `owner/repo/paths` e as skills sincronizam
por intervalo. **O Onion não exporta para o LibreChat; é LIDO por ele.** Único ajuste: skills que
citam ferramentas do harness (Workflow/Bash) precisam de `compatibility`/normalização.
Fontes: librechat.ai/docs/features/skills · changelog v0.8.6 · PR #13293.

## Estado do LibreChat (verificado 2026-08-20)

- **v0.8.7 stable** (23-24/jun/2026), v0.8.8-rc1 em 14/ago; cadência ~1 minor/4-6 semanas.
  **Adquirido pela ClickHouse (nov/2025)**, segue MIT; sinais enterprise: Prometheus/OTel,
  Admin Panel, role sync OIDC, PII filtering, Langfuse. Caso citável: DWAINE na ClickHouse
  (200+ usuários, ~70% das queries do DW, 33M tokens/dia).
- **OIDC genérico de 1ª classe** (bloco `OPENID_*` completo, PKCE, role sync) — mas **não existe
  guia Logto** em doc nem comunidade: a instalação da casa é pioneira. Riscos herdados do
  precedente Vaultwarden: issuer com sufixo `/oidc`, **sem** `offline_access`, **Logto assina
  ES384** (a prova é o login real). Com OIDC, "1º usuário vira admin" NÃO funciona
  (Discussion #12884) → janela de admin LOCAL.
- **Plugins legado deprecado** → o caminho é **Agents + MCP (streamable-http p/ produção) +
  OpenAPI Actions**. MCP: por-usuário e global, OAuth completo, `customUserVars`,
  `serverInstructions`, on-behalf-of token exchange.
- **Anthropic**: família Claude 5 no catálogo (fable/opus/sonnet), prompt caching com TTL
  configurável, extended thinking adaptativo, perfil 1M/128K nos modelos de fronteira.
- **Roadmap manda ESPERAR**: Admin Panel (gestão programática), Workflows/approval gates (Q2),
  Code Interpreter open-source (`ClickHouse/code-interpreter`). H2/2026 prometido e não
  publicado até 20/ago.
- **Pegadinhas neutralizadas no plano**: `latest` quebra upgrade (→ pins); Meili indexa VAZIO
  em silêncio (#12538 → verificação por busca real); Mongo sem auth por default (→ sem-ports +
  rede isolada + limite declarado); `MEILI_MASTER_KEY` idêntica nos 2 serviços.

## O mapa Onion→LibreChat (lente Aristóteles)

**TRANSFERE**: 11 skills (skillSync, quase 1:1) · 92 KBs → File Search (knowledge owned-by-agent)
· comandos-prompt → Prompts Library · integrações OpenAPI → Actions · Whisper → STT nativo ·
decks HTML → Artifacts · multiusuário/OIDC/ACL = ganho puro.
**DESENHA (pouco)**: MCP `onion-kg` read-only (kg_radar/kb_search/diary/inventory) ·
**Bridge-como-MCP** = o braço executor (o Bridge tem filesystem/git/agentes; o LibreChat não).
**NÃO-VALE**: portar comandos que mutam repo — a fronteira honesta é **LibreChat = face de
consulta/distribuição/multiusuário; Claude Code/Bridge = face de execução**.
**Top-5 por valor**: skillSync [BAIXO] → agente Onion-KB [BAIXO/MÉDIO] → MCP onion-kg [MÉDIO] →
Bridge-MCP [MÉDIO/ALTO] → 5-8 agentes-vitrine à mão [BAIXO; nunca os 51 — sem import/export].

## O padrão Onion VPS aplicado (execução em curso)

Repo `/home/marcio/onion-vps-librechat` (commit `7338dcb`): 5 serviços **pinados** (api v0.8.7 ·
mongo 8.0.20 · meili v1.35.1 · pgvector 0.8.0-pg15 · rag lite v0.9.0 — tags conferidas no
registry), bind único `127.0.0.1:3025` (Caddy expõe `chat.onionevolve.com`), data stores
sem-ports em rede própria, `mem_limit` em tudo (swap do host 100% — medido), `${VAR:?}`
fail-closed (provado por recusa), 8 segredos `onion/librechat-*` no pass, app OIDC
`sqov79y2x3s6qawreafga` provisionado via Management API (molde `logto-provision.sh`) e
verificado por releitura.

## Fronteira aberta (a etapa do maestro)

**F4b — KG-SSOT first/map/runtime DENTRO do LibreChat**: read-first via skill `always-apply` +
tools do MCP `onion-kg`; `map` só via Bridge; **write(KG) é a perna crítica** (I3) — as duas
formas candidatas são write-via-Bridge com gate ou write-como-proposta que o core sela (rima com
a federação). Risco nomeado: o "memory" nativo virar fonte paralela ao grafo. Pesquisa própria em
`librechat-kg-runtime-2026-08/` quando o gatilho abrir (stack no ar + MCP desenhado).
