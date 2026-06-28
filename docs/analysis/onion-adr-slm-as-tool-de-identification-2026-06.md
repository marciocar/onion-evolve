---
title: 'ADR — SLM como ferramenta via SDAAL: de-identificação de PII (o "segundo runtime", não o orquestrador)'
date: 2026-06-27
type: adr
status: aceito
decision-scope: sdaal-extension / compliance / privacy / runtime-boundary
supersedes: none
extends: ../sdaal/sdaal.md
deciders: maestro + sessão de evolução
context_freshness: 2026-06-27
related:
  - panorama-ia-generativa-2026-06.md (insumo: tese SLM — modelo pequeno p/ tarefa de schema fixo)
  - ../sdaal/sdaal.md (SDAAL — "LLM=runtime, Markdown=bytecode"; esta ADR estende a tese)
  - ../meta-specs/integrations.md (invariantes §9 do SDAAL; estrutura de adapter)
  - onion-review-2026-05.md (identidade canônica: plataforma única Claude Code; A2A-autonomia abandonada)
  - onion-adr-capability-contract-2026-06.md (fiação na vertical = follow-up gated)
  - ../../.claude/utils/de-identification/ (protótipo: abstração + adapters + script determinístico)
---

# ADR — SLM como ferramenta via SDAAL: de-identificação de PII

> **Status: ACEITO.** Nomeia a doutrina **runtime-vs-ferramenta** e entrega um protótipo
> dogfoodável (adapter `regex` determinístico + abstração SDAAL `de-identification`). O adapter
> `local-slm` e a fiação na vertical ficam **gated**.

## Contexto

Na discussão "Cowork + o que é melhor p/ Claude e Onion" (insumo: `panorama-ia-generativa-2026-06.md`, seção **SLMs** — "a tese mais subestimada do ano: para agentes com schema/API fixos, um modelo pequeno ganha do gigante, 10–30x mais barato"), o maestro levantou a tese: **um SLM local pode ser uma _ferramenta que o Onion usa_** — para de-identificar PII localmente, superando a crítica de compliance de "rodar dado sensível fora da empresa". Um modelo treinado academicamente, local, como ferramenta — não um rival do orquestrador.

A leitura inicial da sessão resistiu, confundindo isto com **multi-provider routing** (trocar o cérebro orquestrador entre Claude/GPT/Gemini). O maestro corrigiu: é **SDAAL usando um SLM como ferramenta**. A correção procede e reabre uma distinção que faltava ser nomeada.

**Evidência de campo (exploração 2026-06-27, 3 lentes):**
- Não existe hoje **nenhuma** abstração de inferência/IA no Onion — esta é a primeira.
- A dimensão **compliance** é robusta (ISO 27001/22301, SOC2, PMBOK, LGPD com notificação T+72h à ANPD) **mas não tem nenhum mecanismo de de-identificação/anonimização** — gap nomeado; hoje a proteção é "deixada ao projeto-alvo".
- O que foi abandonado em 2026-05-18 foi **multi-IDE** (dilui a plataforma) e **A2A-autonomia / aprendizado contínuo** ("beira agente autônomo fora de controle; humano-maestro é invariante") — **não** ferramentas auxiliares. O Onion já é agnóstico a providers (task-manager, forge) via SDAAL.

## Decisão

### 1. Fronteira runtime-vs-ferramenta (a invariante)
Um modelo auxiliar (SLM local) entra no Onion **como ferramenta atrás de um adapter SDAAL**, **nunca** como orquestrador. Claude/o Transformer continua o runtime de orquestração; o humano-maestro continua invariante. **SLM-como-substituto-do-orquestrador é rejeitado explicitamente** — é o que mata o multi-provider routing e o que a identidade de "plataforma única" protege. A linha não é "qual modelo", é **quem orquestra**.

### 2. SDAAL admite um "segundo runtime" para capacidade estreita
A tese-núcleo do SDAAL é `LLM = runtime, Markdown = bytecode` — e até aqui assumia **um** runtime (o Transformer interpretando specs). Esta ADR **estende** a tese: os _providers_ de uma abstração podem ser **runtimes diferentes**. Mapeado na régua P0–P3 (`onion-adr-toolbox-lifecycle`):
- **`regex`** = determinístico → **script** (P1). Roda no core, dogfoodável.
- **`local-slm`** = juízo → **runtime de inferência** (P2). Roda no alvo.
- **`none`** = fail-safe (P3, irreversível-ish: vazar PII não se desfaz) → recusa sem override humano.

### 3. Placement
Abstração SDAAL **`de-identification`** em `.claude/utils/` (estrutura canônica do `abstraction-template`). A capacidade pertence à dimensão **compliance**; a **fiação na vertical `onion-compliance`** (manifesto + Capability Contract REGRA 20) é **follow-up gated** — o protótipo prova primeiro.

### 4. `none` é fail-safe, não no-op
Diferente do Null Object das outras abstrações (degradam em silêncio), o `none` da de-identification **recusa redigir-e-passar**: emite aviso de risco de vazamento de PII e exige **override humano explícito** (`allowUnredacted`). Compliance falha **seguro**: na dúvida, não vaze.

## Por que (rejeições explícitas)

- **Multi-provider routing de orquestração** — rejeitado (Decisão 1): fere a identidade de plataforma única; o ganho do panorama (roteamento por custo/modalidade) é para quem **constrói produtos de IA**, não para um framework de orquestração no Claude Code.
- **Abstração genérica `local-inference`** (infer/classify/redact, N providers) — **prematura** com 1 só caso de uso. Espelha o histórico do design (1 vertical provou → assembler genérico só com a 2ª). Gated até um 2º consumidor além de de-id.
- **Registry/roteamento dinâmico de modelos** — fora de escopo; o contrato (provides/requires) é o substrato, igual ao Capability Contract.

### Tensão com "manter apenas Task Manager Abstraction" (resolvida)
`onion-review-2026-05.md:418` lista como abandonado *"Abstractions extras (FASE 6) | Manter apenas Task Manager Abstraction"* — a objeção mais literal a criar uma abstração SDAAL nova. **Não se aplica aqui:** essa linha é contextual à FASE 6 do **plano v4 abandonado** (abstrações como entregável de um roadmap fechado), não uma proibição de toda nova abstração. A régua **viva** é "o SDAAL generaliza", já ratificada em campo: a **Forge Abstraction** foi adicionada em 2026-06-13 (`integrations.md:46-48`, *"segunda instância comprovando que o padrão generaliza"*) e o whitepaper `sdaal.md:308-316` lista 7 abstrações planejadas — incluindo, explicitamente, **`llm-provider | Anthropic, OpenAI, Google, local, none`**. Ou seja: "um provider que é um modelo, inclusive **local**" já era doutrina antecipada do SDAAL. Este ADR **instancia** o roadmap (de forma estreita: só de-id), não fura a régua de 2026-05-18.

## Consequências

- **+** Primeira abstração de IA do Onion; preenche o gap de de-identificação na 3ª dimensão peer (compliance) e dá um unlock concreto de adoção regulada.
- **+** O baseline `regex` é **determinístico e dogfoodável no core** (selftest `run_de_identification_selftests`: redação + round-trip + no-op + determinismo + dedupe). O gate mecânico cobre a peça executável.
- **+** Doutrina runtime-vs-ferramenta reutilizável — abre a porta para outros "segundos runtimes" estreitos sem ameaçar a identidade.
- **−** O `local-slm` ao vivo é **dependência do alvo** (runtime/modelo não vivem no core) — igual a credenciais (a Fase 4 da adoção configura `.env` do alvo). O core entrega a spec; o adotante provê o runtime.
- **−** Mais uma abstração para manter; mitigado por reusar a maquinaria existente (template, factory/detector, selftest).

## Protótipo (mesmo ciclo)

- Abstração `.claude/utils/de-identification/` (README + interface + types + factory + detector + adapters `regex`/`local-slm`/`none`).
- Script determinístico `scripts/redact-deterministic.sh` (e-mail, CPF, CNPJ, telefone BR, cartão, IPv4; placeholders tipados + round-trip reversível).
- Guarda `run_de_identification_selftests` em `lint-selftest.sh` (5 asserções, modo-de-falha incluso) → **selftest 100/100**.
- `.env.example`: bloco `DEID_PROVIDER` (none | regex | local-slm).

## Não-decisões (gated — nomeadas, não construídas)

- **Comando `/compliance:de-identify`** + categoria `compliance/` de comandos (entry point consciente). Gatilho: primeiro fluxo que precise redigir antes de enviar.
- **Agente `pii-de-identification-specialist`** — juízo de jurisdição (o que é PII em LGPD vs GDPR vs HIPAA). Gatilho: idem.
- **Adapter `local-slm` _ao vivo_** — dogfood com modelo real (Ollama/vLLM no alvo). Gatilho: 1º adotante regulado com runtime de modelo.
- **Fiação na vertical `onion-compliance`** (manifesto + Capability Contract REGRA 20: `PROVIDES+=("pii-de-identification")`, `REQUIRES`, `LOADS when:framework=lgpd`). Gatilho: o protótipo provar em uso.
- **Abstração genérica `local-inference`** — só após um 2º caso de uso além de de-id.
- **Validação de dígito (Luhn/CPF)** no baseline regex — hoje casa por forma, não validade. Refinamento gated.
- **Precedente do `none` fail-safe na meta-spec** — esta é a 2ª divergência intencional do padrão SDAAL base (a 1ª foi a Forge com `transport=cli`): aqui o `none` **recusa** em vez de degradar em silêncio (`sdaal.md:180` define Null Object silencioso). Justificada (compliance falha seguro), mas vale registrar em `sdaal.md` que **abstrações de domínio sensível podem ter `none` fail-safe** — para a 3ª não parecer ad-hoc. Gated (edição de meta-spec).
