---
title: 'RFC-0004 — Topologia de federação + interop ao vivo (single-source + mesh de comunicação + a2a-live gated)'
status: accepted (2026-07-09) — fundamentada em pesquisa orquestrada (2 rodadas, 18 agentes)
canonical-in: onion-evolve (core) — série de RFCs de co-evolução
drafted-in: onion-evolve (stub 2026-07-08 → decidida 2026-07-09)
grounded-in: docs/evolution/research/federation-2026/ (SYNTHESIS.md + GAPS-ADDENDUM.md + S1-S4 + G1-G4)
origin-signal: docs/evolution/inbox/_processed/2026-07-08-proposta-branch-onion-vendor.md
evolves: RFC-0001 (git-async: de invariante para default-com-exceção-gated — o moat sobrevive)
defers-to: RFC-0003 (identidade federada / tiers T0-T3 / trust SDAAL)
---

# RFC-0004 — Topologia de federação + interop ao vivo

> **Estado: ACCEPTED.** Substitui o stub de 2026-07-08. A decisão é **fundamentada em evidência**
> (2 rodadas de pesquisa orquestrada + verificação adversarial em `docs/evolution/research/federation-2026/`),
> não em opinião. Onde a evidência era fraca, foi rebaixada e **não** sustenta a decisão.

## 1. Decisão (headline)

**Manter SSOT single-source para IDENTIDADE/CONTRATOS; federar apenas a COMUNICAÇÃO** — o git-async atual
como mesh canônico, evoluído com um transporte **`a2a-live` gated** (fase-2). **Grana.Ai (e qualquer core
próprio noutra máquina) opera como data-plane subordinado**, não como `role: source`. O moat sobrevive
porque **a aceitação continua gated por humano/tipo** — muda a latência, não o controle.

## 2. Veredito de topologia — single-source + mesh de comunicação

**Por que não federação-de-federações (multi-source).** O corte não é escala, é **natureza do dado** (CAP):
- **Identidade/contratos = recurso-exclusivo** → consistência forte, single-writer. É o `members.yaml` +
  o ledger de contratos: um dono, append-only, versionado. (`G3·B1/B4` confirmed.)
- **Comunicação = estado-colaborativo** → replicação otimista. O doc-bridge git-async **já é** replicação
  otimista canônica (modelo copy-modify-merge; "conflitos raros" garantido por **um-escritor-por-repo**),
  agora com o never-clobber **estrutural** do vendor-branch merge (Achado #2). (`G3·B3` confirmed.)
- Para **N≈5 membros**, control-plane central único é o ótimo; full-mesh/CRDT é over-engineering (SPOF
  mitigado por HA + ledger versionado). O padrão **control-plane + agente remoto** (Argo CD Agent) resolve
  "core próprio noutra máquina" sem segundo soberano. (`G3·B5`, `S2·F5/F10` confirmed.)

**O que se troca no mesh:** conhecimento **destilado** (sinais, migalhas, vereditos, `personality_summary`)
— nunca o repo bruto (federated learning cross-silo; `S4·F11`). É exatamente o `exposes:` + entrega-sem-commit.
Grana.Ai (monorepo nx privado, regulado) é o caso cross-silo canônico: **partilha aprendizado, não código**.

**Gatilho de revisão:** se surgir um 2º hub com sub-adotados próprios **escrevendo identidade concorrente**
e operando desconectado por períodos longos, reabrir — aí o custo do mesh descentralizado passa a valer.

## 3. `a2a-live` — o transporte ao vivo, gated (fase-2)

Um adapter **`a2a-live`** dentro de um `federation-transport` SDAAL (irmão do `task-manager`/`forge`, que
já abstraem transporte), com adapters **`git-async`** (default, menor superfície de ataque) | **`local`**
(carteiro `co-deliver`/`co-relay`, já existe) | **`a2a-live`** (gated). Sobre o `onion-bridge` que **já roda**
na VPS (`claude-agent-sdk`, systemd, atrás do Caddy).

**Regra dura (evidência `G1`):** o `a2a-live` transporta **só SINAIS GATED, nunca conversas autônomas** —
o A2A **não** protege contra prompt-injection cross-agent (`G1`), e a própria Anthropic marca "multi-agente
autônomo" como anti-padrão de custo/fragilidade (`S4·F1/F2`). O handshake gated:
- **Gate humano = consumo idiomático dos estados A2A** `input_required`/`auth_required` — o protocolo já tem
  o "pausa esperando humano" no lifecycle (`S1·F3`, `G1`).
- **`pin-integrity-check` = a "verificação-antes-de-agir"** que a spec A2A já **exige** do receptor
  (JWS/`jti`/anti-SSRF) — o Onion já a implementa (`G1`, `S1·F5/F6`).
- **`never-live-pull` compatível por construção**: o adotante regulado recebe sinal, mas só aplica pelo
  mesmo gate (proposta → confirmação do maestro), nunca puxa framework ao vivo.

## 4. Modelo de aceitação (o moat, preservado)

`members.yaml` (`trust:` — `can_receive_from`/`can_advise_to`/`can_correct_to`) **já é a política de
aceitação** (policy-as-data). Nenhuma mensagem ao vivo é auto-aplicada: entra pelo **mesmo gate tipado** do
doc-bridge. Fail-safe herdado do `federation-check`: **sem gate válido / sem output tipado = veto** (ausência
nunca é aprovação). Ingestão remota é tratada como **supply-chain não-confiável até verificada** (`S4·F6`;
correção: ~5,5% dos servidores MCP com tool-poisoning, e ~2.000 **sem auth** — reforça a verificação gated).
**Reputação-por-evidência** (`declarado≠verificado` + `trust-log` + `can_correct_to` elevado por rigor) pode,
no futuro, condicionar o veto/urgência (`G3·A`, RepuNet/Attention-Trust) — **permanece gated atrás de dogfood**.

## 5. O que muda na RFC-0001 (e o que NÃO muda)

- **Muda:** git-async deixa de ser **invariante absoluto** e passa a **default com exceção gated** (o
  `a2a-live`). O "A2A é não-objetivo" da RFC-0001 é **revisado**: A2A gated **é** objetivo, fase-2.
- **NÃO muda (invariantes preservadas):** maestro humano no ato irreversível · entrega-sem-commit (I3) ·
  um-escritor-por-repo · never-clobber · append-only auditável · fail-safe > fail-open · sem IA-fala-IA
  **autônoma**. O moat é a aceitação gated, não a lentidão — então a latência menor não o fere.

## 6. Não-objetivos

- IA-fala-IA **autônoma** (conversas sem gate) — fora de cogitação (`G1`, `S4·F1`).
- Auto-aplicação de mensagem ao vivo — viola o gate humano.
- Substituir o doc-bridge git-async — ele continua system-of-record **e** fallback.
- Promover Grana.Ai (ou outro) a `role: source` — contradiz o veredito §2.
- Assumir um padrão pronto de **descoberta governada** — o mercado **não** o resolve em escala (`G2`):
  o A2A registry/discovery fica **gated + curado à mão**.

## 7. Faseamento e gates (detalhe no roadmap)

- **Fase 1 — independente de doutrina, SEM `a2a-live`** (derivação pura do SSOT): `graph.sh` ingere
  `members.yaml` → mapa · targeting fino por seletor · console estático · receiver-que-acorda. Não requer
  esta RFC; libera valor imediato. Ver `docs/evolution/federation-roadmap-2026.md`.
- **Fase 2 — gated NESTA RFC:** `federation-transport` SDAAL + endpoint `a2a-live` no bridge (Agent Card em
  `/.well-known/agent-card.json`) + veto reputação-condicionado. Só após Fase 1, sob gate humano e dogfood.

## 8. Fundamentação (pesquisa)

Decisão ancorada em `docs/evolution/research/federation-2026/` (2 rodadas, 18 agentes, verificação
adversarial). O pilar do veredito (`S2·F11` mesh-vs-SSOT) foi **confirmado** com fonte primária na 2ª rodada
(`G3·B`, CAP). Achados sem fonte sólida (`S1·F8` AAIF↔A2A refutado no claim forte; estatísticas fabricadas
corrigidas) **não** sustentam nada aqui. Direções ativas mas imaturas (`S1·F15` delegação verificável;
reputação como condicionante) ficam **gated atrás de dogfood**.

## 9. Relacionados

- RFC-0001 (git-async — revisado por esta) · RFC-0003 (tiers/trust — base da aceitação) · `/meta:federation-*`
  (control-plane: veto fail-safe + rollback) · `members.yaml` (policy-as-data) · Achado #2 vendor-branch
  (never-clobber estrutural do mesh) · SDAAL `task-manager/factory.md` (precedente do `federation-transport`).
