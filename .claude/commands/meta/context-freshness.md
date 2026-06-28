---
name: context-freshness
description: |
  Audita o frescor dos contextos de domínio (docs/business-context/,
  docs/technical-context/, docs/compliance-context/) tratando-os como SSOT viva,
  não snapshot. Um worker por arquivo via onion-orchestration retorna veredito
  CURRENT/STALE/HISTORICAL + trechos desatualizados + direção de refresh; o fan-in
  consolida, detecta contradição cross-domínio e marca candidatos a remoção.
  É a fase *Manage* executável do ciclo de vida (ADR onion-adr-domain-context-lifecycle).
model: opus
category: meta
tags: [context, freshness, orchestration, validation, lifecycle]
version: "1.0.0"
updated: "2026-06-17"
allowed-tools: Read Grep Glob
argument-hint: "[caminho/glob de contexto específico | vazio = os 3 contextos]"
related_commands:
  - /meta:kb-freshness
  - /meta:evolve
  - /docs:build-business-docs
  - /docs:build-tech-docs
  - /docs:build-compliance-docs
related_agents:
  - onion
  - metaspec-gate-keeper
---

# /meta:context-freshness — Auditoria de Frescor de Contexto de Domínio

## Objetivo

Garantir que `docs/business-context/`, `docs/technical-context/` e
`docs/compliance-context/` permaneçam **fiéis à realidade do projeto** ao longo do
tempo. A geração (`/docs:build-*-docs`) é só o **primeiro tick**; este comando é a
fase **Manage** do ciclo de vida CRUD+ — a operação **Validar** (rastreabilidade +
frescor + contradição cross-domínio) que decide se o contexto ainda merece
confiança, e sinaliza a operação **Remover** (stale engana ativamente).

A premissa, da KB [domain-context-lifecycle.md](../../../docs/knowledge-base/concepts/domain-context-lifecycle.md):
**uma doc de contexto desatualizada é pior que ausente** — a IA age com confiança
sobre uma realidade que já não existe. Este comando **nunca muta** os contextos;
apenas audita e relata (para aplicar refreshes, use os `/docs:build-*-docs`).

Reusa o **molde** do [`/meta:kb-freshness`](kb-freshness.md) (fan-out-and-synthesize,
veredito CURRENT/STALE/HISTORICAL, threshold ≤18 meses, schema, tiering) — adaptado
ao alvo `docs/*-context/`.

---

## Quando usar

- Periodicamente, em projetos-alvo onde os contextos foram populados (não no
  framework, onde são templates).
- Após mudança grande no produto/código/regulação (pivot, refactor, novo
  framework de compliance) — para flagar o contexto que ficou para trás.
- Antes de confiar num contexto para uma decisão importante (gate de confiança).
- Composto pelo [`/meta:evolve`](evolve.md) (dimensão D9) numa auditoria ampla.

---

## Régua de Frescor de Contexto (2026)

Cada worker lê **um** arquivo de contexto e avalia os itens. **Só itens (!) são GATES**
— a falha neles eleva o veredito. Itens sem (!) são **pontos menores**: registre em
`stale_excerpts`, mas não rebaixe o veredito sozinho.

| # | Item | Critério | Gate? |
|---|------|----------|-------|
| 1 | **Carimbo de frescor (!)** | Campo de data (`Última Atualização`/`updated`/equivalente) presente e **≤18 meses** (relativo a hoje). Ausente ou >18 meses = STALE. (Threshold herdado de `kb-freshness` item 6.) | ✅ |
| 2 | **Rastreabilidade (!)** | Afirmação factual **externa** (claim de mercado, métrica, persona derivada de dado, regra de compliance) ancorada em fonte/issue/depoimento **ou** marcada. Afirmação externa sem fonte nem marcador = STALE. | ✅ |
| 3 | **Disciplina de inferência (!)** | `[INFERIDO]` aponta a evidência-base; `[TO BE COMPLETED]` indica lacuna real. Invenção apresentada como fato consumado = STALE. | ✅ |
| 4 | **Aderência à realidade (!)** | Descreve o estado **atual** do projeto — não feature removida, persona abandonada, stack trocada ou framework de compliance descontinuado. Worker **sinaliza suspeita**; confirmação fina é cross-ref no fan-in. | ✅ |
| 5 | **Formato/estrutura** _(menor)_ | Multi-arquivo linkado por `index.md`, kebab-case, um arquivo por preocupação (não monolito). Sozinho não rebaixa. | — |

**Vereditos:**
- **CURRENT** — passa em todos os GATES (!); pode ter ponto menor (item 5).
- **STALE** — falha em 1-2 GATES; conteúdo ainda útil mas desatualizado → refresh via `/docs:build-*-docs`.
- **HISTORICAL** — falha em 3+ GATES ou descreve realidade **extinta** → candidato a **Remover/arquivar** (operação de maior valor: stale engana).

> ⚠️ **Anti-ruído.** Os 3 contextos no **framework** são templates (só `README.md`):
> não há o que auditar → reporte vazio, **não** erro. Placeholders de template
> (`[Persona Name]`, `__________`, `[TO BE COMPLETED]` ainda não preenchido em
> projeto novo) **não** são "afirmação sem fonte" — são scaffolding. Convenções e
> estrutura internas não exigem fonte (só afirmações factuais externas — item 2).

---

## Etapas de Execução

### Passo 0 — Verificar substrato Workflow
Confirme a ferramenta nativa **Workflow**. Ausente → **fallback serial** (Passo 5),
avisando em pt-BR.

### Passo 1 — Levantar o escopo com Glob
```
Argumento recebido: $ARGUMENTS
```
- **Preenchido**: trate como caminho/glob dentro de um `docs/*-context/`.
- **Vazio**: `Glob` em `docs/business-context/**/*.md`, `docs/technical-context/**/*.md`,
  `docs/compliance-context/**/*.md`, **excluindo** `README.md` e `index.md`.

Registre o conjunto como `CTX_FILES`. **Se vazio** (ex.: rodando no framework, onde
os contextos são templates), informe o usuário e **encerre sem erro** — não há
contexto populado para auditar.

### Passo 2 — Delegar padrão à skill `onion-orchestration`
Acione **`onion-orchestration`**: tarefa = "auditar frescor de cada arquivo em CTX_FILES
contra a régua de contexto"; independência = alta (cada arquivo é autônomo); padrão
= **fan-out-and-synthesize**. A skill confirma elegibilidade e tiering. Se reprovar,
serial (Passo 5).

### Passo 3 — Fan-out (um worker por arquivo)
Autore um script `Workflow` com `parallel()`. Cada worker recebe o caminho, a
**régua completa** (tabela acima) e o schema:

```javascript
const FreshnessSchema = {
  file: "string",            // caminho relativo a docs/
  context: "business|technical|compliance",
  verdict: "CURRENT|STALE|HISTORICAL",
  failed_items: ["string"],  // ids da régua que falharam
  stale_excerpts: [ { excerpt: "string", reason: "string" } ],
  refresh_direction: "string" // ação concreta (ou "none")
};
```

**Model tiering** (igual `kb-freshness`): workers → **haiku**; fan-in → **sonnet**;
verificação adversarial (se acionada) → **opus**. Teto **16 workers** concorrentes;
batchs de 16 para orquestrações maiores. Nunca modelos de outro provider.

### Passo 4 — Fan-in: consolidar, contradição cross-domínio, remover
No contexto principal (0 tokens de modelo):
1. Agrupe por veredito (`HISTORICAL` → `STALE` → `CURRENT`); dentro, por nº de `failed_items`.
2. **Contradição cross-domínio** (a operação Validar mais valiosa): compare afirmações
   entre `business` ↔ `technical` ↔ `compliance`. Fato afirmado por um e negado por
   outro = **alerta de contradição** (ex.: business diz "SOC2 certificado", compliance
   não tem evidência). É achado de fan-in, não de worker.
3. **Remover**: todo `HISTORICAL` vira recomendação explícita de arquivar/remover
   (stale engana ativamente → remoção É frescor).
4. **Verificação adversarial** (opus) acionada quando: >30% STALE/HISTORICAL, ou
   contradição cross-domínio detectada. O juiz tenta refutar antes de consolidar.

### Passo 5 — Fallback serial (Workflow indisponível)
Avise em pt-BR; itere `CTX_FILES` com `Agent`, mesmo `FreshnessSchema`; consolide
igual ao Passo 4. Nunca finja paralelismo.

---

## Saída Esperada

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CONTEXT FRESHNESS REPORT — AAAA-MM-DD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
◆ Arquivos auditados : N (business X · technical Y · compliance Z)
◆ Padrão             : fan-out-and-synthesize
◆ Workers            : N × haiku + 1 fan-in sonnet

─── HISTORICAL (remover/arquivar) ─────────────
❌ technical-context/03-domain/api-specification.md
   Falhou: #1 (>18 meses), #4 (descreve API v1 removida na v3)
   Ação  : arquivar — descreve realidade extinta

─── STALE (refresh) ───────────────────────────
⚠  business-context/01-customer/personas.md
   Falhou: #1 (sem Última Atualização)
   Ação  : /docs:build-business-docs (re-tick) + carimbar data

─── CURRENT ───────────────────────────────────
✅ compliance-context/iso27001/controls.md

─── CONTRADIÇÃO CROSS-DOMÍNIO ─────────────────
⚠  business diz "SOC2 Type II certificado"; compliance não tem evidência → reconciliar

─── PRÓXIMOS PASSOS ───────────────────────────
1. Arquivar HISTORICAL (operação Remover)
2. Refresh STALE via /docs:build-*-docs + carimbar data
3. Reconciliar contradição cross-domínio
4. Re-executar /meta:context-freshness para confirmar
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Exemplos

```bash
/meta:context-freshness                                   # os 3 contextos
/meta:context-freshness docs/business-context/            # só negócio
/meta:context-freshness docs/technical-context/03-domain/ # um subdiretório
```

---

## Notas

- **Nunca cria nem modifica** contextos — só audita e relata. Refresh = `/docs:build-*-docs`.
- **No framework**, os 3 contextos são templates (só `README.md`) → `CTX_FILES` vazio
  → encerra sem erro. O valor real é em **projetos-alvo** que populam os contextos.
- **Orquestração opt-in**: alvo único → executa direto com `Agent` (sem overhead de Workflow).
- Orquestre **sempre no nível principal** — nunca dentro de subagente; **não crie** um
  agente "context-freshness-worker".
- **Contrato de composição (D9 do `/meta:evolve`)**: quando invocado por `/meta:evolve`,
  retorne o **array `FreshnessSchema[]` cru** (não só o relatório Unicode), para o
  `evolve` mesclar no backlog. `/meta:evolve` chama no **fluxo principal** e ingere o
  array — nunca aninha esta orquestração dentro da dele (mesma regra do D4/`kb-freshness`).

---

## Referências

- Doutrina do ciclo de vida: [domain-context-lifecycle.md](../../../docs/knowledge-base/concepts/domain-context-lifecycle.md)
- ADR: [onion-adr-domain-context-lifecycle-2026-06.md](../../../docs/analysis/onion-adr-domain-context-lifecycle-2026-06.md) (§Gatilho — este comando é o Tijolo 2)
- Molde reusado: [`/meta:kb-freshness`](kb-freshness.md)
- Geradores (primeiro tick): `/docs:build-business-docs` · `/docs:build-tech-docs` · `/docs:build-compliance-docs`
- Doutrina de orquestração: [agent-orchestration.md](../../../docs/knowledge-base/concepts/agent-orchestration.md) · Skill: `onion-orchestration`
