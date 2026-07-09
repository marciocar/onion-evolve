---
name: onion-engineering-context
description: >
  Contrato de SSOT mínimo e resolver de contexto da vertical de engenharia do Onion.
  Use ao rodar qualquer comando de engenharia (plan/start/work/pre-pr/pr, flow, hotfix)
  para localizar o contexto técnico do projeto — mesmo quando o repo NÃO segue o layout
  Onion padrão (sem docs/technical-context/, sem docs/meta-specs/). Resolve onde ler/gravar
  o contexto vivo, faz bootstrap de um stub mínimo quando ausente, e aponta o KB de
  framework embarcado (GitFlow, worklog). Ative mesmo sem o usuário mencionar "contexto"
  ou "SSOT".
---

# Contexto de Engenharia — contrato SSOT mínimo + resolver

Esta skill garante que a vertical de engenharia **sabe onde está o seu SSOT** em qualquer
projeto — adotado pelo Onion ou não. Separa dois tipos de conhecimento:

- **KB de framework (tipo A)** — conhecimento estável do próprio Onion (GitFlow, worklog).
  **Viaja embarcado no plugin.** Nunca depende do projeto do consumidor.
- **Contexto vivo (tipo B)** — a arquitetura/decisões do projeto DO CONSUMIDOR. É dado dele;
  **não** viaja no plugin. Esta skill o **resolve** (ou faz bootstrap).

## 1. KB de framework (tipo A) — onde consultar

O motor e os protocolos que os comandos citam estão **embarcados**:

- **Como plugin**: em `${CLAUDE_PLUGIN_ROOT}/kb/` — ex.: `${CLAUDE_PLUGIN_ROOT}/kb/gitflow-patterns.md`,
  `${CLAUDE_PLUGIN_ROOT}/kb/worklog-protocol.md`.
- **No Onion completo**: em `docs/knowledge-base/frameworks/` e `docs/knowledge-base/concepts/`.

Ao precisar do motor GitFlow (branch/merge/tag/semver/sessão) ou do protocolo de worklog,
**leia do KB embarcado** — não assuma que existe `docs/knowledge-base/` no projeto do consumidor.

## 2. Contexto técnico do consumidor (tipo B) — resolver

Para ler/gravar o contexto técnico vivo (arquitetura, decisões, estado), resolva o caminho
**nesta ordem** e use o primeiro que existir:

1. **Layout Onion padrão**: `docs/technical-context/` (índice em `docs/technical-context/index.md`).
2. **Mapa explícito**: chave `context.technical` em `.onion-version` (JSON) ou `.claude/onion-context.yaml`,
   se o consumidor declarou um caminho próprio.
3. **Heurística de layout comum** (projetos não-Onion), em ordem: `contexto-projeto.md` ·
   `docs/INDEX.md` (catálogo) · `ARCHITECTURE.md` · `docs/architecture*` · `README.md`.
4. **Bootstrap** (só com confirmação do usuário): criar o stub mínimo (seção 3) e passar a usá-lo.
5. **Degradação honesta**: se nada existe e o usuário recusa o bootstrap, **prossiga declarando**
   "não encontrei SSOT de contexto técnico — operando sem ele" e **nunca invente** arquitetura.

> **RAG/KB do consumidor** (se houver, ex.: `docs/base-conhecimento-*.md`): trate como fonte de
> leitura complementar quando o resolver a encontrar; não é o contexto técnico, é conhecimento de domínio.

## 3. SSOT mínimo (o "estrutura mínima" garantido)

O contexto técnico mínimo que a vertical precisa manter é **um arquivo** com estas seções.
No bootstrap, criar em `docs/technical-context/index.md` (ou no caminho resolvido/declarado):

```markdown
# Contexto Técnico — <projeto>

## Stack & Arquitetura
<linguagens, frameworks, topologia — 1 parágrafo>

## Decisões (ADRs curtos)
<lista: decisão · porquê · data>

## Estado atual
<o que existe, o que está em andamento>

## Convenções
<branch/commit, testes, lint — ou "herdadas do Onion (GitFlow)">
```

Manter este arquivo **vivo** (atualizar ao entregar features) é o contrato. É o piso, não o teto:
num projeto adotado, `docs/technical-context/` completo o supera.

## 4. Regra de ouro

- **Tipo A** (framework) → sempre do KB embarcado; independe do consumidor.
- **Tipo B** (consumidor) → resolver → bootstrap → degradar **honesto**. Nunca assumir path fixo.
- Ao não achar, **dizer** — declarado ≠ verificado. Ver `[[onion-dogfooding-doctrine]]`.
