# Doutrina de Abstração do Onion — quando algo vira SDAAL (e quando não vira)

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-17 | **Categoria**: Conceitos
> **Nomeia e consolida** o critério que já existe disperso (régua P0-P3, whitepaper §13, a generalização
> do eixo na KB do SDAAL, `integrations.md` §2/§9) — **não introduz padrão novo**. Terceira irmã das
> doutrinas de decisão: [Modernização](onion-modernization-doctrine.md) decide *o que* refatorar;
> [Dogfooding](onion-dogfooding-doctrine.md) decide *como sei que ficou certo*; **esta decide *o que
> merece virar abstração***.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-07-17 |
| **Categoria** | Conceitos |
| **Origem** | Auditoria do eixo (2026-07-17): o SDAAL bifurcou em 3 formatos sem ninguém decidir; 2 instâncias violam L0 |
| **Comando relacionado** | `/meta:create-abstraction` (o gerador — deve rodar o §Teste do eixo antes de gerar) |
| **Padrão-pai** | [SDAAL](specification-driven-ai-abstraction-layer.md) (o que é / anatomia) · [whitepaper](../../sdaal/sdaal.md) (a tese pública) |
| **Lei (L0)** | [`integrations.md`](../../meta-specs/integrations.md) §2 (estrutura), §3.4 (`.env`), §9 (proibições) |

---

## 🎯 Por que esta doutrina existe

O SDAAL tinha **referência** (o que é), **tese** (o whitepaper), **templates** e **catálogo** — e nada
que **decidisse**. O resultado, medido em 2026-07-17:

- o padrão **bifurcou em 3 formatos** sem decisão registrada;
- **2 instâncias violam a L0** que o próprio padrão escreveu;
- o único critério real do repo (whitepaper §13) **não é linkado por nada** — nem pelo gerador;
- o **catálogo cataloga ficção** (padrões propostos que nunca nasceram) e ignora instâncias reais.

Nenhum desses é erro de execução. Todos são o sintoma de **uma pergunta que ninguém tinha escrito**:
*quando isto merece virar abstração?*

---

## 🧭 O Teste do Eixo — as 3 condições (todas obrigatórias)

Uma capability só vira SDAAL se as **três** valem. Falhou uma → **não é SDAAL**.

| # | Condição | Se falhar |
|---|---|---|
| **a** | **≥2 implementações reais** e intercambiáveis do mesmo contrato — *reais*, não prometidas | **script** (o overhead de interface/factory não compensa — whitepaper §13) |
| **b** | A escolha é do **ambiente/consumidor** (uma variável no `.env`), não do autor | **script** (se quem escolhe é o autor, a escolha é uma chamada, não configuração) |
| **c** | O consumidor **precisa ser cego** à escolha — saber qual provider está ativo quebraria o código | **script chamado direto** (legítimo — cegueira sem necessidade é cerimônia) |

> **O eixo abstraído varia; o contrato não.** O `adapter` **não** precisa ser um provider externo. Já
> generalizamos para **papéis**: `trust` tem adapters por **tier**; `federation-transport`, por **via**.
> Provider externo, tier, topologia — **o eixo muda; interface + factory + adapters permanecem**.

## ⏳ O Teste do Gatilho

**1 provider real + N prometidos = script.** O 2º provider **real** é o gatilho da graduação a SDAAL.

Isto é [`gated-until-trigger`](onion-modernization-doctrine.md) aplicado à abstração: construir a
anatomia inteira para providers que ainda não existem é **catedral** — e o `.env.example` que oferece um
provider inexistente é **capability declarada e não verificada**.

> **Anti-simetria:** "ficaria simétrico com o task-manager" **não é gatilho**. Gatilho é o 2º provider
> existindo e alguém precisando trocar.

---

## 🧱 Os três formatos (o estado real, 2026-07-17)

| Formato | Eixo do adapter | Instâncias | Anatomia exigida |
|---|---|---|---|
| **SDAAL-provider** | provider externo | `task-manager` · `forge` · `de-identification` | completa (interface · types · factory · detector · adapters · **`none`**) |
| **SDAAL-papel** | tier / via (interno) | `trust` · `federation-transport` | completa, **menos o `none`** quando um adapter real **já é** o fallback total (`standalone`, `git-async`) — **a dispensa deve estar escrita no README**, como a divergência `cli`-default do forge (`integrations.md` §1.0) |

> ⚠️ **Correção factual (2026-07-17):** a KB do SDAAL afirmava que *"interface + factory + detector +
> adapters + Null Object **permanecem**"* em todas as instâncias. **Era falso** — `trust` e
> `federation-transport` não têm `none.md`; `federation-transport` detecta por script. A doutrina **não
> retro-condena**: reconhece o formato-papel e exige que a dispensa seja **declarada**, não silenciosa.

**Não existe "SDAAL-transformação".** Transformação determinística sem LLM é **script** (P1 da régua).
Ver §Anti-padrões.

---

## 🚫 Anti-padrões (todos pegos pelo dogfood, nenhum hipotético)

1. **SDAAL-por-declaração** — README dizendo "Abstração SDAAL" sem interface/factory/adapters. O rótulo
   não cria o padrão; **viola `integrations.md` §2**.
2. **Provider hardcoded no consumidor** — o comando chama o script do provider concreto
   (`.../tokens-to-css-vars.sh`) em vez do factory. **Viola §9** — e costuma contradizer o README da
   própria abstração.
3. **Env switch fictício** — `X_PROVIDER` anunciado como mecanismo anti-lock-in que **nenhum script lê**
   e que **não está no `.env.example`**. É `declarado ≠ verificado` aplicado a capability. **Viola §3.4.**
   **Teste:** trocar a variável **muda a saída**? Se não, a capability não existe.
4. **Adapter prometido no `.env`** — oferecer `gitlab | bitbucket` sem o arquivo do adapter. Costura é
   legítima; **anunciá-la como capability, não**.
5. **Catálogo de ficção** — catalogar abstrações propostas como se fossem o inventário. O catálogo
   descreve **o que existe**; o que não existe é backlog, e vive gated.

---

## 📡 Radar honesto

**Deferido (com gatilho nomeado):**
- `design-source` / `design-sink` → graduam a SDAAL **quando o 2º provider real nascer** (figma/penpot).
  Hoje: 1 provider real cada → **script**, per §Teste do Eixo (a).
- `branch-roles` (ADR, `proposto/gated`) → gatilho: 2ª topologia real de branching em uso.
- `forge`: `gitlab`/`bitbucket` → gatilho: um adotante que os use.

**Rejeitado conscientemente (não reabrir sem evidência nova):**
- Abstrair capability de **provider único estável** — whitepaper §13 (*"o overhead de Adapter/Factory não
  compensa"*).
- **SLM-como-orquestrador** — o SLM entra como *ferramenta atrás de adapter*, nunca como runtime de
  orquestração (ADR `slm-as-tool-de-identification`). A linha não é "qual modelo", é **quem orquestra**.

---

## 📚 Fontes

- **Critério original:** [whitepaper §13](../../sdaal/sdaal.md) — *"Use SDAAL quando… / Não use quando…"*
  (esta doutrina é a **SSOT operacional** do critério; o whitepaper é a tese pública e **cita** daqui —
  [fonte ≠ derivação](source-vs-derivation.md)).
- **Classificador de entrada:** régua **P0-P3** — [`onion/SKILL.md`](../../../.claude/skills/onion/SKILL.md)
  (P1 determinístico→script · P2 façade multi-provider→SDAAL) · visão integrada:
  [Engine Economy](onion-engine-economy.md).
- **Anatomia e exemplos:** [SDAAL KB](specification-driven-ai-abstraction-layer.md) ·
  [sdaal-examples](../patterns/sdaal-examples.md) · instância canônica: [task-manager](task-manager-abstraction.md).
- **Lei:** [`integrations.md`](../../meta-specs/integrations.md) §2 · §3.4 · §9.
- **Irmãs:** [Modernização](onion-modernization-doctrine.md) · [Dogfooding](onion-dogfooding-doctrine.md).
