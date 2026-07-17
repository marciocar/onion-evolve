# Economia de motores do Onion — qual motor para qual tarefa

> **Versão**: 1.0.0 | **Última atualização**: 2026-06-28 | **Categoria**: Conceitos
> O Onion realiza trabalho com **três motores de execução** e escolhe entre eles por critério explícito —
> "o recurso certo no lugar certo". É a instância Onion do consenso da indústria de 2026: *o LLM orquestra,
> o determinístico executa, o SLM especializado é ferramenta*. Esta KB **nomeia e consolida** uma doutrina
> que já existe dispersa (régua P0-P3, tese SDAAL, fail-safe do de-id, gate de dogfood) — não introduz motor novo.

---

## 📋 Metadata

- **Relacionadas:** [Transformer — o reasoner](transformer-architecture.md) · [SDAAL whitepaper](../../sdaal/sdaal.md) · [Doutrina de Dogfooding](onion-dogfooding-doctrine.md) · [Vocabulário de relações](onion-relation-vocabulary.md) · régua P0-P3 em [`onion/SKILL.md`](../../../.claude/skills/onion/SKILL.md) · [ADR SLM-como-ferramenta](../../analysis/onion-adr-slm-as-tool-de-identification-2026-06.md) · [ADR toolbox lifecycle](../../analysis/onion-adr-toolbox-lifecycle-2026-06.md)
- **Tese-mãe (SDAAL):** o Transformer é o reasoner, o Markdown é o bytecode — sem store externo.

---

## 1. Os três motores

| Motor | O que faz | Quando | Exemplos no Onion |
|---|---|---|---|
| **Transformer (Claude) — reasoner** | Juízo, orquestração, síntese, geração; raciocínio aberto/multi-hop | A tarefa exige contexto, trade-off, intenção | agentes lendo spec; orquestração da frota; geração de artefatos |
| **SLM — ferramenta via SDAAL** | Tarefa **estreita e esquematizada** (NER, PII contextual, classificação, extração); **nunca** orquestra | Padrão repetitivo de baixa variação, custo/latência/privacidade críticos | adapter `local-slm` do de-identification (gated, roda no adotante) |
| **Shell — determinístico** | O que o LLM **erra**: contagem, diff, drift, formato fixo, idempotência | Output idêntico p/ o mesmo input, sem contexto | `inventory.sh`, `graph.sh`, `lint-artifacts.sh`, `redact-deterministic.sh` |

**O classificador é a régua P0-P3** (canônica em [`onion/SKILL.md`](../../../.claude/skills/onion/SKILL.md)):
P0 já-existe?→*extend* · **P1 determinístico?→script** · P2 juízo→Claude / semântica→skill / invocação→comando / multi-provider→**SDAAL** · P3 irreversível?→*+gate humano*. Esta KB dá a **visão integrada de motores**; a régua é a porta de entrada operacional.

---

## 2. Ancoragem ao vocabulário canônico (indústria, jul/2026)

O Onion **mantém seus termos** com mapa explícito ao consenso — legibilidade externa, à prova de futuro (mesmo padrão "doméstico + âncora canônica" da [ontologia de orquestração](../../analysis/onion-orchestration-ontology-2026-06.md)).

| Conceito Onion | Termo canônico da indústria |
|---|---|
| Transformer reasoner + shell executa | **"LLM as orchestrator, deterministic tools as hands"** (consenso maduro 2026) |
| SLM-ferramenta via SDAAL | **SLM-as-tool** (NVIDIA "SLMs are the Future of Agentic AI", arXiv:2506.02153) |
| 3 motores compondo | **compound AI systems** (BAIR, 2024) |
| schema nos subagentes (ferramenta Workflow) | **constrained / structured decoding** (XGrammar, default 2026) — já coberto |
| adapters chamando provider | **MCP** como execution layer (padrão de facto, Linux Foundation) |
| `local-slm` no adotante p/ PII | **SLM on-device** para dado sensível (HIPAA/LGPD, padrão emergente) |

**O moat:** Gartner (2026) projeta que ~40% dos projetos agênticos falham — por **governança não-plugável**, não por tecnologia. O Onion ataca exatamente isso: spec-as-code + gates determinísticos + 1-escritor + co-evolução.

---

## 3. Composição, não substituição — o template do de-identification

O caso canônico de combinar motores é a abstração [`de-identification`](../../../.claude/utils/de-identification/) (#201):

```
texto → [regex P1 determinístico]  redige PII de formato fixo (email/CPF/CNPJ/tel/cartão/IP)
       → [local-slm P2 juízo]      redige PII contextual (nomes, endereços, organizações) — gated
       → [none P3 fail-safe]       recusa redigir-e-passar sem override humano explícito
```

Três lições reusáveis para **domínio sensível**:
1. **Determinístico primeiro, juízo depois** — regex resolve o formato fixo barato; o SLM entra só para o contextual.
2. **SLM é ferramenta atrás de adapter**, nunca agente/orquestrador. O runtime do modelo vive **no adotante** (como token de API), não no core.
3. **`none` fail-safe** (recusa) em vez de Null Object silencioso — porque vazar PII não se desfaz. Padrão para abstração de domínio sensível.

---

## 4. Checklist — NÃO use o Transformer para o que é determinístico

O motor errado mais comum é usar o LLM onde um script seria **mais correto, barato e auditável**. Antes de descrever um passo "à mão" (LLM), pergunte: **é determinístico?**

- [ ] **Contagem / agregação** (quantos X?) → script (`inventory.sh`), nunca "o LLM conta".
- [ ] **Diff / detecção de drift** (mudou vs SSOT?) → script (lint Regra 8/19/21).
- [ ] **Parsing / extração de formato fixo** (ID, data, enum, JSON) → regex/script.
- [ ] **Validação de schema / lógica booleana** (IF/THEN, regra fixa) → código determinístico.
- [ ] **Redação de PII de formato fixo** → `redact-deterministic.sh`.
- [ ] **Idempotência garantida** (mesma entrada → mesma saída sempre) → script.

> **Por que isto é checklist de revisão, e NÃO uma regra de lint automática:** no Onion o **LLM é o runtime**
> (tese SDAAL), não há uma "chamada de API ao modelo" no código para um lint interceptar — o Transformer
> simplesmente lê o Markdown e age. Guardar isto deterministicamente seria frágil (heurística de texto sobre
> intenção). Então a guarda é **doutrinária**: aplicada na régua P0-P3 (P1 é a primeira pergunta) e nesta
> revisão. A disciplina, não o gate, protege a fronteira.

---

## 5. Radar honesto — deferido vs rejeitado

**Deferido, com gatilho (radar, não roadmap):**
- `local-slm` ao vivo (dogfood com Ollama/vLLM) — gatilho: 1º adotante regulado com runtime.
- Abstração genérica `local-inference` — gatilho: 2º caso de uso de SLM além do de-id.
- Tracer de orquestração (alimentar o radar de promoção, hoje manual via `/meta:evolve`) — gatilho: dor concreta do radar manual. **Tensão doutrinária:** learnings automáticos foram rejeitados (humano-maestro é invariante) — um tracer pode *medir*, nunca *decidir*.
- Metadados `kind/status`; validação Luhn/CPF no regex.

**Rejeitado conscientemente (NÃO reabrir sem evidência nova):**
- **SLM-como-agente** (ex.: `@classifier-agent`→Qwen) — fere o invariante "SLM é ferramenta via adapter, não orquestrador". O ganho de custo captura-se pelo adapter.
- **Model-routing multi-LLM** — fere a identidade plataforma única (Claude Code).
- **Registry central** (SSOT é gerada do filesystem); **dedup por embedding** (custo>ganho); **learnings automáticos**; **A2A-autonomia** (humano-maestro invariante).

---

## 6. Fontes (estado da arte, jul/2026)

- *Small Language Models are the Future of Agentic AI* — NVIDIA, arXiv:2506.02153 (2025).
- *A Blueprint for Compound AI Systems* — Berkeley BAIR (2024).
- *FrugalGPT* (cascading/model-routing, ~80% economia) — TMLR (2024).
- *XGrammar-2* (constrained decoding default) — MLC.ai (2026).
- *Model Context Protocol* — Anthropic / Linux Foundation (2024–2025).
- *RedactOR* (de-id clínico on-device) — arXiv:2505.18380 (2025).
- *Hype Cycle for Agentic AI* — Gartner (2026).

> **Nota de método:** a pesquisa web confirma que o Onion **já é o padrão 2026** — a régua P0-P3 é a taxonomia
> "qual motor quando" que a indústria pratica mas não nomeou. O valor desta KB é **nomear o que já fazemos**,
> para o adotante e o futuro entenderem o porquê — não adicionar motor novo.
