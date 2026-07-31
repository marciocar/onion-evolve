---
title: "Fonte de discussão — Ferramentas compartilhadas na VPS (federação + Onion) + a doutrina a derivar"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-31
branch: main
# ── bloco Tier-0 (o mapa da constelação lê SÓ isto) ──
phase: SEED            # SEED | EXPLORE | DEEP | CONVERGE | PROMOTE | PARK
next_action: "Rodar a Fase 0 (Elenxo de framing catálogo-vs-plataforma + confirmar 'P2') antes de qualquer pesquisa por-ferramenta; o plano só nasce após F1–F3."
scope_globs: ["docs/onion/graph/vps-shared-tools-2026-07.kg.yaml", "docs/onion/graph/m2-bridge-logto-2026-07.kg.yaml", "docs/evolution/research/whatsapp-api-2026-07/"]
objective_tags: ["vps-tools", "federation-substrate", "control-plane"]
kg: docs/onion/graph/vps-shared-tools-2026-07.kg.yaml
---

# 🧰 Ferramentas compartilhadas na VPS — SEED

> **Isolada. Pensa, não entrega.** SSOT no grafo
> [`vps-shared-tools-2026-07.kg.yaml`](../../onion/graph/vps-shared-tools-2026-07.kg.yaml)
> (radar exit 0). Este doc é o framing humano + a **estrutura de análise inicial** (não é o plano).

## O tema

Um **catálogo de ferramentas compartilhadas na VPS**, usáveis por **membros da federação E pelo
Onion** — e a **doutrina** que rege como uma ferramenta entra/vive/sai desse catálogo.

## Inventário (do gather 2026-07-31 — detalhe no KG)

| Ferramenta | Estado |
|---|---|
| **Auth/Identidade (Logto)** | ✅ **maduro/vivo** — flip P7 feito; `members.yaml`=SSOT, Logto=projeção |
| **WhatsApp** | 🟡 `whatsapp-sender` shipped (whatsapp-web.js não-oficial); WAHA/Cloud API pesquisados |
| **Email** | 🔴 **gap nomeado** — não existe; ausência do conector travou convite no Logto |
| **Monitoramento** | ⚪ candidato — P2(?) / Langfuse / OpenTelemetry / afins |
| **Tunneling** | ⚪ candidato — ngrok / alternativas |
| **Substrato** | ✅ Hostinger KVM8 + Caddy + onion-bridge + Logto |

## Direções do maestro (2026-07-31 — decisões no KG)

1. **MANTER** o `whatsapp-web.js` não-oficial **E ADICIONAR o adapter do WAHA como PADRÃO** (SDAAL: dois adapters, WAHA default).
2. **Construir EMAIL E ligar o conector de email no Logto** (destrava o convite por org — o gap medido).
3. **Monitoramento** (P2, Langfuse, OpenTelemetry e afins) **revisado e pensado**.
4. **Tunneling** (ngrok e afins) **avaliado**.
5. **Trazer tudo a um PLANO ESTRUTURADO + DERIVAR uma DOUTRINA**, usando todo o potencial do Onion (Elenxo, KG-SSOT first+runtime, pesquisas documentadas e mapeadas).

> **Caveat de disciplina (pull-not-push, do fio #4):** derivar **doutrina + estrutura AGORA**, mas o
> **plano é spec-now/build-gated por-ferramenta** — nunca uma **plataforma** empurrada por hipótese.
> Cada tool entra no catálogo por **demanda concreta**, não por completude.

## 🧭 Estrutura de análise inicial (as 4 fases ANTES do plano)

**Fase 0 — Frame & invariantes (Elenxo de framing).**
Fixar o que governa (SDAAL · Logto=projeção · spec-now/build-gated · pull-not-push · reuso-não-invenção)
e rodar o **Elenxo `catálogo-de-adapters` vs `plataforma`** (o anti-padrão dead-layer que o fio #4 nomeou).
Confirmar **"P2"** com o maestro. _Saída: as invariantes seladas + a fronteira do que NÃO é._

**Fase 1 — Pesquisa por-ferramenta (documentada, born-in-KG, `verify-external-for-current`).**
Uma pesquisa web-verificada por tool current/emerging, cada uma nascendo `.kg.yaml`:
WAHA (adapter + default) · Email (provider × conector Logto) · Observabilidade (Langfuse × OTel × P2 × afins) ·
Tunneling (ngrok × Cloudflare Tunnel × Tailscale × Caddy-só). _Saída: evidência mapeada, sem priors._

**Fase 2 — Arquitetura cross-tool (SDAAL).**
Cada ferramenta como **adapter** atrás do **bridge**, com o **Logto como espinha de identidade**
(membros + serviços M2M) e o **catálogo como SSOT**. _Saída: a forma comum + os pontos de reuso._

**Fase 3 — Elenxo por decisão-real.**
WAHA-default vs Cloud-API-para-regulado (já tem evidência) · stack de observabilidade · ngrok vs alternativas ·
provider de email + conector. Cada Elenxo → **decisão no KG**. _Saída: as escolhas, com dissent._

**Fase 4 — Síntese → DERIVA a doutrina + o plano.**
A doutrina reusável (**"ferramenta VPS compartilhada = adapter SDAAL atrás do bridge, auth via Logto,
spec-now/build-gated, pull-not-push, research-first-para-current"**) + o **plano faseado gated** por-tool.
_Saída: doutrina promovível a KB + o plano executável._

> Tudo **born-in-KG** (este seed cresce no grafo), **Elenxo** nas decisões, **pesquisa documentada+mapeada**
> (KG-linkada), **radar como runtime**. O plano se pede **após F1–F3** — nunca antes da evidência.
