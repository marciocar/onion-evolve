---
name: warm-up
description: |
  Preparação geral do projeto - contexto completo do Sistema Onion.
  Revisa README, estrutura de documentação e meta especificações.
model: sonnet
allowed-tools: Read Bash(ls *) Bash(find docs*) Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh*)
category: general
tags: [warmup, context, preparation, overview, kg-first]
version: "3.3.0"
updated: "2026-07-16"
---

# 🔥 Warm-up Geral do Projeto

Preparação completa do contexto geral do Sistema Onion para sessões de trabalho.

## 🎯 Objetivo

Estabelecer contexto completo do projeto incluindo:
- Visão geral do Sistema Onion
- Estrutura completa de documentação
- Meta especificações (constituição do sistema)
- Mapeamento de recursos disponíveis

## 📋 Checklist de Preparação

### 0. KG-first — o `.kg.yaml` é o SSOT vivo do estado/domínio (antes da prosa)
- ✅ **Se existir um `.kg.yaml` no repo, consulte-o PRIMEIRO** (`git ls-files '*.kg.yaml' | grep -v '/fixtures/'`
  — resolve AO VIVO; o glob hardcoded anterior enumerava só 31 de 49 grafos, **36% cegos**, e os invisíveis
  eram justamente os de `docs/evolution/research/<tema>/`) — ele é a fonte da verdade de estado/domínio, **acima**
  da prosa dos docs. Rode `bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh <arquivo>` e absorva o veredito (atenção,
  **estado**, reconciliação, integridade, frescor) citando **ids de nó**. A seção **ESTADO**
  lista o que segue `open` e que o radar afunda — o trabalho que sobrou, não o que pesa.
- ✅ **Drive-to-verify:** claims `plane: PROD` de alto impacto → cruzar contra o vivo antes de assumir; nó
  stale mente (`--freshness`). Sem `.kg.yaml` → siga para o item 1.
- ⚙️ **Mecanismo, não conselho** (sinal de campo 2026-07-16): consultar o KG **por padrão** é a forcing
  function contra a reincidência de "reconstruir da prosa". Doutrina: [knowledge-graph-sdaal.md](${CLAUDE_PLUGIN_ROOT}/kb/knowledge-graph-sdaal.md) §SSOT-as-runtime.

### 1. README Principal
- ✅ Revisar `README.md` na raiz do projeto
- ✅ Entender estrutura do Sistema Onion v3.0
- ✅ Identificar comandos e agentes principais
- ✅ Mapear integrações disponíveis (ClickUp, Asana, Linear)

### 2. Estrutura de Documentação
- ✅ Listar arquivos em `docs/` e manter no contexto
- ✅ Revisar `docs/INDEX.md` (índice central)
- ✅ Mapear estrutura:
  - `docs/onion/` - Sistema Onion (12 arquivos)
  - `docs/knowledge-base/` - Knowledge Bases (16 arquivos)
  - `docs/meta-specs/` - Meta Especificações
  - `docs/analysis/` - Análises
  - `docs/plans/` - Planos de execução

### 3. Meta Especificações
- ✅ Revisar `docs/meta-specs/index.md`
- ✅ Memorizar hierarquia: Meta Specs (L0) → Domain Specs (L1) → Feature Specs (L2) → Task Specs (L3)
- ✅ Entender arquivos planejados:
  - `architecture.md` - Padrões arquiteturais
  - `code-standards.md` - Padrões de código
  - `agents.md` - Padrões para agentes
  - `commands.md` - Padrões para comandos
  - `integrations.md` - Padrões para integrações
- ✅ Conhecer processo de validação via `@metaspec-gate-keeper`

### 4. Recursos Principais
- ✅ Comando `/onion` - ponto de entrada inteligente
- ✅ Agente `@onion` - orquestrador master
- ✅ Task Manager Abstraction (ClickUp, Asana, Linear)
- ✅ Framework EXTRACT para reuniões

### 4.5 Identidade e Ecossistema (quem o Onion É — não só o que tem)
- ✅ Revisar `${CLAUDE_PLUGIN_ROOT}/kb/onion-framework-identity.md` — **SSOT de identidade/posicionamento** (pitch, invenções nomeadas, materiais derivados)
- ✅ Conhecer `docs/applying/onion-adoption-manual.md` — a **persona autobiográfica** (1ª pessoa) + ecossistema vivo: adotantes reais, **Onion-Bridge** (mobile via Agent SDK) e o site **`onionevolve.com`** (autobiografia pública; backend `app.onionevolve.com` com clone do core no VPS)
- ✅ Sem esta etapa, a sessão sabe *operar* o framework mas não sabe *quem ele é* — perguntas de identidade/persona/site ficam sem resposta

### 4.6 Aparte do Maestro — canal lateral tipado (side-channel)
- ✅ Conhecer `docs/knowledge-base/agentic-patterns/harness/maestro-aside.md` — o vocabulário de **marcadores tipados** que o maestro usa no meio da sessão para rotear a intenção (dúvida/correção/lembrete/etapa/memória/pesquisa-paralela) ao mecanismo certo **sem descarrilhar** a tarefa.
- ✅ Marcadores (no início da mensagem): `dúvida:` `corrige:` `reforço:` `nota:` `guarda:` `+etapa:` `-etapa:` `paralelo:` `guarda-regra:`. O hook `UserPromptSubmit` (`${CLAUDE_PLUGIN_ROOT}/hooks/aside-router-hook.sh`) injeta a **rota canônica** como recall (nunca gate; os irreversíveis pedem confirmação — Ato 3/W6).

### 5. Co-evolução (se `docs/evolution/` existir)
- ✅ Reconhecer o papel do repo: `source` (core) · `adopted` (consumidor) — via `.claude/.onion-version` ou `${CLAUDE_PLUGIN_ROOT}/validation/onion-version.sh`
- ✅ Conferir os canais de co-evolução: `docs/evolution/inbox/` (upstream, sinal/feedback) e, em consumidores, `docs/evolution/inbound/` (downstream, relatório de update/anúncio do core). O hook SessionStart "you have mail" já avisa a **contagem** no boot (📬 inbox / 📥 inbound); o warm-up apenas **orienta** — não re-conta.
- ✅ Havendo mensagens, rodar `/meta:co-evolve` para ler/gerenciar. O protocolo canônico (3 fluxos) vive em `docs/evolution/README.md`.

## 🔍 Contexto a Manter

### Documentação Essencial
- `README.md` - Visão geral completa
- `docs/INDEX.md` - Hub de navegação
- `docs/onion/commands-guide.md` - Todos os comandos
- `docs/onion/agents-reference.md` - Todos os agentes
- `docs/meta-specs/index.md` - Meta especificações
- `${CLAUDE_PLUGIN_ROOT}/kb/onion-framework-identity.md` - SSOT de identidade/posicionamento
- `docs/applying/onion-adoption-manual.md` - Persona autobiográfica + ecossistema (Onion-Bridge, onionevolve.com)
- `docs/evolution/README.md` - Modelo de co-evolução core↔derivados (se presente)

### Estrutura de Comandos
- 104 comandos em 10 categorias
- 51 agentes especializados em 9 categorias
- Knowledge Bases estruturadas para IA

## 💡 Quando Usar Este Warm-up

- ✅ Primeira vez no projeto
- ✅ Retorno após período ausente
- ✅ Mudança de contexto de trabalho
- ✅ Necessidade de visão geral completa

## 🔗 Próximos Passos

Após este warm-up geral, use warm-ups específicos:
- `/product/warm-up` - Para trabalho de produto
- `/engineer/warm-up` - Para trabalho de engenharia
- `/meta:co-evolve` - Se o hook "you have mail" (📬 inbox / 📥 inbound) sinalizou mensagens nos canais de co-evolução

## ⚠️ Notas

- Este warm-up fornece contexto geral, não técnico profundo
- Para trabalho específico, use warm-ups de categoria
- Mantenha lista de arquivos `docs/` no contexto para referência rápida
