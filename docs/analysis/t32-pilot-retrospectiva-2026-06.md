---
title: Retrospectiva T3.2 — Validação de /docs:build-*-docs (auto-piloto)
date: 2026-06-02
status: executado
tarefa: T3.2 (plano de saneamento) + Fase 3 do plano de V&V
piloto: auto-piloto no próprio onion-claude (cenário legacy)
desbloqueia: T3.6 (definição de piloto) resolvido via auto-piloto
---

# Retrospectiva T3.2 — Validação de `/docs:build-*-docs`

Validação ponta a ponta dos comandos de geração de documentação do Onion,
usando o **próprio repositório `onion-claude`** como projeto-alvo piloto
(cenário **legacy**: repo real com código em `.claude/` e docs). Executado em
**worktree descartável** (`/tmp/onion-t32-pilot`, removido ao final) para não
poluir o repo-mãe.

## Método

| Comando | Como foi validado |
|---|---|
| `/docs:build-index` | **Execução ao vivo** do scan não-interativo (coleta de dados real) |
| `/docs:build-tech-docs` | **Probe de geração real**: fase de descoberta sobre o repo + geração de fatia representativa (index + charter + 1 ADR + codebase-guide) ancorada em evidência |
| `/docs:build-business-docs` | Validação de prontidão (agentes + template + estrutura); geração plena requer sessão interativa |
| `/docs:build-compliance-docs` | **Fora de escopo** do auto-piloto legacy — exige projeto regulado; follow-up |

> Os comandos `build-*-docs` são **interativos** (discovery → discussion →
> generation, com ≥10 perguntas ao usuário). A geração plena das 4 camadas
> requer uma sessão interativa; o probe prova que o **pipeline e a estrutura**
> funcionam.

## Resultados

### Pré-checagem (prontidão) — ✅ PASSOU

- **15/15 agentes** referenciados pelos build commands existem e carregam
  (business: product-agent, research-agent, storytelling-business-specialist,
  branding-positioning-specialist; tech: c4-architecture-specialist,
  c4-documentation-specialist, docs-reverse-engineer,
  system-documentation-orchestrator, mermaid-specialist; compliance:
  security-information-master, iso-27001/22301, soc2, pmbok,
  corporate-compliance-specialist em `review/`).
- **2/2 templates** resolvem (`business-context-template.md`,
  `technical-context-template.md`).

### `build-index` — ✅ EXECUTÁVEL

Scan não-interativo coletou corretamente: 77 comandos invocáveis, 49 agentes,
4 skills, 89 docs markdown, índices de seção (knowledge-base, meta-specs, onion).
Comando apto.

### `build-tech-docs` (probe) — ✅ APTO COM RESSALVAS

Gerou fatia representativa (281 linhas, 4 arquivos) seguindo a estrutura de 4
camadas sem ambiguidade bloqueante. A própria geração **expôs inconsistências
reais do repo** (ver achados) — evidência de que o comando entrega valor.

## Achados (gaps)

### No comando/template — ✅ RESOLVIDOS em 2026-06-02

1. ✅ **Divergência de convenção de nomes template ↔ comando.** O template sugeria
   `UPPERCASE`; o comando usa kebab-case. **Resolvido:** `build-tech-docs.md`
   Fase 3 agora declara que sua convenção (kebab-case) **tem precedência** sobre
   o template.
2. ✅ **Stack non-code não coberta pela descoberta.** **Resolvido:** Fase 1.1
   ganhou ramo explícito para projetos doc-as-code/sem manifesto/build.
3. ✅ **Sem regra de precedência para evidência conflitante.** **Resolvido:**
   nova Fase 1.4 (precedência: código > `CLAUDE.md` > docs atuais > sem-marcação
   > históricas) em `build-tech-docs.md` **e** `build-business-docs.md`.
4. ✅ **Modo não-interativo ausente.** **Resolvido:** Fase 2 documenta modo
   "infer-from-evidence" (`[INFERIDO]` + seção "Pendências de validação") em
   ambos os comandos.

### Inconsistências reais do repo descobertas pelo probe

5. ✅ **`CONTRIBUTING.md` descrevia "Onion v4.0 / onion-cli / Node ≥16"** —
   **Resolvido em 2026-06-02:** reescrito alinhado à identidade atual (framework
   template, sem npm/CLI).
6. ✅ **`CLAUDE.md` desatualizado** (afirmava "1 skill"; há 4) —
   **Resolvido:** CLAUDE.md/INDEX sincronizados (4 skills; 77 comandos invocáveis).
7. ✅ **Artefatos do saneamento não commitados** —
   **Resolvido:** commitados em `50cc326` (saneamento 2026-05).

## Veredito

`build-index`, `build-tech-docs` e `build-business-docs` (por prontidão) estão
**aptos para projeto-alvo**. Todos os gaps 1-4 e inconsistências 5-7 foram
**resolvidos em 2026-06-02**. T3.6 fica **resolvido** via auto-piloto.
`build-compliance-docs` permanece **pendente de piloto regulado** (gap conhecido,
não bloqueia uso geral).
