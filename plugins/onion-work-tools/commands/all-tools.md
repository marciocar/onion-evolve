---
name: all-tools
description: Apresenta, sob demanda, as ferramentas disponíveis no contexto atual (nativas do Claude Code + MCP) e defere ao inventário canônico para comandos/agentes/skills do Onion. Não gera arquivos.
model: sonnet
allowed-tools: Read
category: meta
tags: [tools, reference, discovery, on-demand]
version: "4.0.0"
updated: "2026-06-21"
---

# /meta:all-tools — Catálogo de Ferramentas (sob demanda)

## 🎯 Objetivo

Apresentar, **na própria sessão**, o catálogo de ferramentas disponíveis **neste contexto**.
É uma resposta **efêmera** — **não gera nem versiona arquivos**. (A versão anterior gravava
snapshots em `.claude/docs/tools/` que **drifavam** da realidade; isso viola o princípio
"documentação deriva, não repete" e foi removido.)

## 🧭 Princípio

- **Inventário do próprio Onion** (comandos, agentes, skills, contagens) → **NÃO re-documentar
  aqui**. É derivado da SSOT; aponte para o canônico:
  - Contagens: `docs/onion/inventory.md` (SSOT gerada por `/meta:inventory`)
  - Comandos: `docs/onion/commands-guide.md`
  - Agentes: `docs/onion/agents-reference.md`
- **Ferramentas nativas do Claude Code + MCP disponíveis** → **este é o valor único**: não
  vivem em `docs/onion/` e mudam por sessão/contexto. Enumere-as **dinamicamente do contexto
  atual**, nunca de uma lista hardcoded.

## ⚡ Execução

1. **Ferramentas nativas do Claude Code** — agrupe em **núcleo** (carregadas de imediato,
   com nome + descrição real) e **estendidas/deferidas** (surgem via `ToolSearch`). As
   deferidas são conhecidas **só por nome** até o fetch — **liste-as por nome e NÃO invente
   descrição** (busque via `ToolSearch` só se precisar do detalhe). Use sempre os nomes reais
   do contexto — **sem assinaturas TypeScript inventadas e sem nomes de outras IDEs** (ex.:
   nada de `read_file`/`codebase_search` estilo-Cursor; o formato válido é o nativo).
2. **Ferramentas MCP** — agrupe por servidor e **marque o status de conexão**: *conectado*
   (toolset completo disponível agora) vs *exige autenticação* (só expõe `authenticate`/
   `complete_authentication` até conectar). Formato dos nomes: `mcp__<server>__<tool>`.
   Listar um servidor sem o status engana o leitor (um `Jira`/`Slack` "disponível" mas não
   autenticado não é acionável). Quando relevante, cite a coerência com o `.env` (ex.:
   `TASK_MANAGER_PROVIDER` ativo via API-first, MCP opcional).
3. **Recursos do Onion** — apresente um resumo curto + os **links** para o canônico acima.
   **Não** recopie listas nem contagens (elas derivam da SSOT).
4. **Saída**: tudo na resposta da sessão. **Não escreva arquivos.**

## ⚠️ Notas

- **Efêmero por natureza**: a disponibilidade de ferramentas/MCP é de runtime. Materializá-la
  num arquivo versionado reintroduz drift — por isso este comando só apresenta.
- **Sem contagens hardcoded**: se precisar citar totais do Onion, leia `docs/onion/inventory.md`.
- **Relacionados**: `/meta:inventory` (SSOT de comandos/agentes/skills/KBs do Onion).
