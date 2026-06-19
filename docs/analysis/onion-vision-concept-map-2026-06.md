---
title: "Mapa de conceitos e relações do Onion — norte vivo (revisável)"
date: 2026-06-19
type: analysis
status: living            # NÃO é spec congelada — revisável e retroagível
authority: norte de visão; NÃO sobrepõe meta-specs (L0) nem ADRs aceitos
---

# 🧭 Mapa de conceitos e relações do Onion — norte vivo

> **Leia isto primeiro.** Este doc é um **mapa vivo**, não uma especificação. Ele organiza as
> relações entre os conceitos do Onion (framework + adoção + federação + comercialização) **com status**,
> para que possam ser **revistas e retroagidas com liberdade** — é tudo novo. Nada aqui é compromisso
> congelado. Quando um conceito estabiliza, ele **gradua** para um artefato formal (ADR/RFC/meta-spec) —
> até lá, vive aqui como relação em aberto. Mesma disciplina do "gatilho de graduação" da federação e do
> "won't-do com gatilho": **o registro não vai à frente da realidade.**

**Legenda de status:** 🟢 gravado/decidido · 🟡 decidido-visão (design pendente) · 🟠 parcial/a-desenhar ·
🔵 novo/explorar · ⚠️ risco/contradição.

---

## 1. Landscape & naming — como o mundo chama isso (jun/2026)

> Pesquisa datada (jun/2026; fontes ao fim da seção). Honestidade: o que é **nosso** vs **derivado**.

| Peça do Onion | Nome da indústria | Derivação |
|---|---|---|
| Framework que vira o "cérebro" do ciclo | **agent harness** (técnico, OpenAI 2026) · **agentic SDLC framework** (funcional, Forrester) | alto — somos uma instância |
| `docs/` specs como SSOT | **Spec-Driven Development (SDD)** — categoria consolidada (GitHub Spec Kit, AWS Kiro, BMAD) | alto |
| Agentes especialistas por função | padrão estabelecido (BMAD, CrewAI, MAF) | alto |
| Humano-maestro / HITL | consenso da comunidade | muito alto |
| Co-evolução por git+markdown async | sem nome de categoria; **MCP Agent Mail** chegou à mesma solução independente | médio — não estamos sós |
| Federação por contratos versionados | **GitOps + schema registry + contract testing** (Pact, Confluent) aplicado a frameworks | território novo |
| "Cérebro central hospedado" | **Agent Control Plane** — categoria QUENTE 2026 | ver ⚠️ abaixo |
| Open-core local + coordenação hospedada paga | consenso de mercado (PostHog, Terraform/HCP, Confluent) | muito alto |

**⚠️ Cautela de naming — "control plane":** a categoria de 2026 (OpenHands, Galileo, Fiddler, Salesforce,
Google Next) governa **runtime de agentes** (deploy/monitor/kill). O nosso "cérebro central" governaria a
**evolução do framework** entre repos soberanos — mais perto de um **registry de schema/contratos com
governança**. **Usar "control plane" sem qualificar confunde com a concorrência.** → decisão futura: nomear o nosso distinto.

**O combo genuinamente nosso (sem precedente junto):**
1. **Config pura como runtime** do coding agent (sem SDK intermediário) — BMAD é o mais perto, mas não é isso.
2. **Adoção vendorizada + co-evolução git-async** entre instâncias (existe em infra; não em agent frameworks).
3. **Três dimensões peer: produto + engenharia + compliance** — ninguém cobre compliance como first-class.

**Resposta à pergunta "tem nome?":** o **projeto** tem (Onion). A **categoria do combo**, não — somos
composição de padrões nomeados + um arranjo novo. **Nomear nossa categoria é decisão futura** (ver §5).

**Fontes-chave:** Forrester "Agentic Software Development Takes The Lead"; OpenAI "Harness Engineering";
GitHub Spec Kit (blog); AWS Kiro (AWS Summit NY 2026); BMAD (pasqualepillitteri.it); OpenHands "Agent
Control Plane"; Futurum "Agent Control Plane Framework"; IBM "What is an Agent Control Plane?"; Linux
Foundation "A2A surpasses 150 orgs"; "2026 MCP Roadmap"; GitHub `mcp_agent_mail`.

---

## 2. A espinha (o eixo da visão)

```
  instância STANDALONE  ──┐
  (cada repo tem o seu     │   coordena via
   Onion soberano,         ├── FEDERAÇÃO PEER ──── (contratos + ledger git, humano-maestro)
   roda sozinho)           │
                           └── pode se beneficiar de ──► CÉREBRO CENTRAL (hospedado, futuro)
                                                          = coordenação/governança de EVOLUÇÃO
                                                            do framework (≠ runtime de agentes)
```

Eixo: **uma instância trabalha sozinha (sem federação) OU se beneficia da ajuda do cérebro central.**
É a direção já gravada no reposicionamento (open-core local livre/BSL + camada hospedada paga).

---

## 3. Cards de relação

### 1. Adoção standalone / in-place — 🟢 GRAVADO
Repo vira Onion soberano (durável) ou opera in-place (efêmero). Fonte: `onion-adr-repo-adoption-2026-06.md`.

### 2. Federação vertical (core ↔ consumidor) — 🟢 GRAVADO · ⏸️ INATIVA
Contratos versionados (spec-as-code + tests/fixtures) num ledger git; ciclo publish/check/status/rollback.
Liga no **gatilho de graduação** (contrato breaking OU >5 projetos). Fontes: `onion-federation-design-v2-2026-06.md`, `docs/knowledge-base/concepts/multi-repo-federation.md`, RFC-0001.

### 3. Cérebro central / Control Plane (evolução do framework) — 🟡 DECIDIDO-VISÃO · ⚠️ renomear
Camada hospedada futura: hospeda/sincroniza ledger, monitora drift, alerta breaking, compliance-at-scale.
Fronteira comercial: local livre/BSL · hospedado SaaS. **≠ "agent control plane" de runtime** (ver §1).
Design **não escrito** (proposto FASE 3 do reposicionamento). Fonte: `onion-repositioning-sdaal-session-2026-06-17.md` §6.

### 4. Comercialização — 🟡 DECIDIDO · ⚠️ material em drift
BSL (open-core), monetização faseada (licença → control plane), ICP = orgs reguladas + multi-repo.
Fonte: `onion-repositioning-sdaal-session-2026-06-17.md` §5. **Pendências:** ADR de reposicionamento nunca
escrito (FASE 0); ver §4 (contradições).

### 5. Integração cross-consumer (A ↔ B se ajudam) — 🔵 NOVO / EXPLORAR
Dois projetos adotantes, cada um com seu Onion, ajudando-se a integrar as duas pontas. **Não está gravado**
— a federação hoje é só vertical (core↔consumidor). Alinhado em espírito (o **contrato** poderia se
estender horizontalmente), mas é **topologia nova**. Gradua para RFC quando estabilizar.

### 6. Adoção: qualidade + direção + consciência — 🟠 PARCIAL / A-DESENHAR
O requisito do maestro: **entrar e deixar o projeto limpo e auto-suficiente — com consciência do outro lado.**
- **Assumir-e-limpar é OPÇÃO, nunca destruir cego.** Limpeza de IDE legada (`.cursor/.windsurf/copilot`)
  precisa de **etapas muito bem definidas** (hoje **não existe** — gap confirmado).
- **Direção-aware** (fora-pra-dentro vs dentro-pra-fora): quem melhor sabe o que limpar/configurar é **o
  outro lado**; ele precisa **saber** da nova config — nada espalhado sem consciência.
- **Dois modos de comando, saídas distintas:**
  - **Onion autônomo** → **relatório** obrigatório (o que foi feito · novidades · do que ele é capaz agora).
  - **Consumidor no comando** → **onboarding assistido** (o Claude+Onion local dele guiando a descoberta,
    consciente do que faz).
- **Relink** hoje é só implícito (via `--update`) — falta semântica explícita.
- **Dogfooding:** o Onion é codado COM Claude Code (aderir ao máximo de eficiência/eficácia).
Gradua para um ADR/design de "adoção consciente" quando as etapas estiverem desenhadas.

### 7. Canal de aprendizado bidirecional + cross-consumer — 🔵 NOVO
Pelo menos no início, o **onion-evolve** recebe (opcional) os problemas/melhorias da comunicação
**consumidor ↔ consumidor**, além do fluxo B já existente — para **aprender de tudo** e **depois escalonar
papéis**. Extensão do inbox de co-evolução. Gradua quando houver volume real.

---

## 4. Contradições / drift a resolver (listar, não corrigir aqui)

- ⚠️ **`docs/materials/press-kit.md`** FAQ ainda diz "não é produto comercial" → **contradiz** a decisão BSL
  de 2026-06-17.
- ⚠️ **ADR de reposicionamento como produto** — proposto (FASE 0), **nunca escrito**.

---

## 5. Log de decisões / perguntas abertas (revisável, datado)

- **2026-06-19** — Mapa criado. Confirmado: visão "instâncias sozinhas OU ajudadas pelo central" já é a
  direção gravada (reposicionamento). Federação cross-consumer e barra-de-qualidade-da-adoção entram como
  NOVO/EXPLORAR. Naming: combo sem nome de categoria.
- **Aberta:** nomear a **categoria** do Onion (hoje: "agent harness" técnico / "agentic SDLC" funcional)?
- **Aberta:** nomear o **"control plane" do Onion** de forma distinta (evitar colisão com a categoria de runtime)?
- **Aberta:** federação cross-consumer — vira RFC própria? quando?
- **Aberta:** desenhar as etapas de "adoção consciente" (limpeza opcional + relatório/onboarding + relink explícito).

> Para retroagir um conceito: edite o card + registre aqui a data e o porquê. Liberdade total — é tudo novo.
