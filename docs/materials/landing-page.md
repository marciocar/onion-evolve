# Landing Page — Sistema Onion (Esqueleto)

**Status:** Esqueleto (Fase 4 — Materiais Derivados)
**Fonte:** [Onion: Identidade e Produto](../knowledge-base/meta/onion-framework-identity.md)
**Data:** 2026-06-15

> Este é um **outline estrutural** — sequência de seções com headlines propostas, bullets de copy/mensagens-chave e notas de elemento visual. **Não** é o texto final de marketing. Cada bullet cita entre parênteses a seção de origem na KB-fonte.

---

## 1. Hero

**Headline proposta:** "O ciclo completo de desenvolvimento orientado por IA — sem tocar numa linha do seu código."

**Subheadline proposta:** "Sistema Onion é um framework template que vive em `.claude/` e transforma o Claude Code no cérebro orquestrador do seu fluxo: produto, engenharia e compliance."

**Copy / mensagens-chave:**
- Instala num repositório o ciclo produto → engenharia → compliance sem alterar stack, linguagem ou infra (Seção 1, pitch de 30s; Seção 8, FAQ "Preciso mudar meu stack?").
- 82 comandos invocáveis, 49 agentes de IA, 5 skills de orquestração — três dimensões **peer**, não hierarquizadas (Seção 1, pitch de 2min; Seção 9, citação 2).
- Não é uma CLI, não tem pacote npm — é configuração pura sobre o Claude Code (Seção 1, pitch de 2min).

**CTA primário:** "Instale em menos de 2 horas" → âncora para seção CTA final / getting-started.
**CTA secundário:** "Veja como funciona" → âncora para seção "Como Funciona".

**Visual:** logo "🧅 Onion" + animação curta da pasta `.claude/` sendo "encaixada" num repositório existente sem mexer no resto. Selo discreto: "Plataforma: Claude Code".

---

## 2. O Problema

**Título proposto:** "Orquestrar IA no dia a dia ainda é manual demais."

**Copy / mensagens-chave (tabela "Sem Onion → Com Onion"):**
- Prompts ad-hoc por tarefa, sem memória de workflow → 82 comandos = workflows codificados (Seção 2, problema 1).
- Cada integração de task manager vira caso especial (Jira exige ADF, ClickUp Unicode, Asana HTML) → SDAAL roteia ao adapter certo por `.env` (Seção 2, problema 2).
- Trabalho interrompido = contexto perdido → sessões faseadas retomáveis com `STATE.md` (Seção 2, problema 3).
- Compliance vira silo criado depois, manualmente → 5 agentes ISO/SOC2 no mesmo ciclo (Seção 2, problema 4).

**Visual:** tabela de duas colunas "Sem Onion" (cinza, fricção) vs "Com Onion" (destaque). Ícone por linha (prompt, plug, sessão, escudo).

---

## 3. Como Funciona

**Título proposto:** "Uma pasta. Cinco camadas. O Claude Code no comando."

**Copy / mensagens-chave (visão de arquitetura sem jargão pesado):**
- Tudo vive em `.claude/` — você copia a pasta, configura o `.env` e roda `/warm-up` (Seção 8, FAQ "Qual é o esforço de instalação?").
- Camadas que se encaixam: **comandos** (o que fazer) → **agentes** (quem sabe fazer) → **skills** (orquestração de alto nível) → **abstrações** (conecta seu task manager e seu GitHub) → **documentação constitucional** (Seção 3, "As 5 camadas").
- O mesmo comando funciona em stacks diferentes: trocar de provider é mudar o `.env`, não o código (Seção 3, padrão SDAAL — "Por que importa").
- Você entra por onde quiser: produto, engenharia ou compliance são peers e adotáveis de forma independente (Seção 1, pitch de 10min).

**Visual:** diagrama simplificado das 5 camadas empilhadas (versão limpa do diagrama da Seção 3), com o Claude Code no topo. Mini-fluxo lateral: `/product:collect → /engineer:start → /engineer:pr → /git:sync`.

---

## 4. Feature Grid (Capacidades por Categoria)

**Título proposto:** "Cinco frentes, um só framework."

**Bloco 1 — Produto & Discovery:** coletar requisitos, refinar spec, transcrever reuniões, converter em tasks no task manager ativo (Seção 4, "Produto & Discovery").
**Bloco 2 — Engenharia & GitFlow:** planejar feature em fases retomáveis, abrir PR via forge adapter, hotfix fast-track (Seção 4, "Engenharia & GitFlow").
**Bloco 3 — Qualidade & Compliance:** code review, testes unitários, ISO 27001, SOC2 Type II, validação arquitetural (Seção 4, "Qualidade & Compliance").
**Bloco 4 — Orquestração & Subagentes:** fan-out paralelo de subagentes, sessões retomáveis, federation multi-repo, Agent Teams opt-in (Seção 4, "Orquestração & Subagentes").
**Bloco 5 — Meta (Auto-Evolução):** `/meta:evolve` audita 8 dimensões, frescor de KBs, criar novo agente/comando, inventário automático (Seção 4, "Meta").

**Visual:** grid de 5 cards com ícone, título e 3 bullets cada. Cada card linka para a seção correspondente do manual.

---

## 5. Prova Social (Citações + Métricas)

**Título proposto:** "O framework que se diagnostica sozinho — com números."

**Métricas em destaque (cards numéricos):**
- 82 comandos · 49 agentes · 5 skills (Seção 6, inventário).
- 4 task managers suportados: Jira, ClickUp, Asana, Linear (Seção 6).
- Auto-auditoria real: 28 agentes · 1.27M tokens · 635 tool-uses · ~26 min (Seção 6; Seção 9, citação 5).
- 49/49 agentes migrados Cursor→native · 82/82 comandos com `allowed-tools` (Seção 6).

**Citações em destaque:**
- *"As três dimensões são peer, não hierarquizadas."* (Seção 9, citação 2).
- *"Workflow = orquestração que o orquestrador desenha. Agent Teams = coordenação que emerge."* (Seção 9, citação 3).
- *"Conserta o propagador, não só as folhas."* (Seção 9, citação 7).

**Visual:** faixa de contadores numéricos animados no topo + 2-3 citações em cards estilo "quote". Selo "auditado por `/meta:evolve`".

---

## 6. FAQ (Teaser)

**Título proposto:** "As três perguntas que todo mundo faz primeiro."

**Perguntas selecionadas (as mais decisivas da Seção 8):**
- **Preciso mudar meu stack para usar o Onion?** Não — vive inteiramente em `.claude/`; código, linguagem e infra não são tocados (Seção 8).
- **Funciona com qualquer gerenciador de tarefas?** Sim, para Jira, ClickUp, Asana ou Linear via `TASK_MANAGER_PROVIDER` no `.env`; modo `none` para uso offline (Seção 8).
- **Posso usar só partes do Onion?** Sim — as três dimensões são peer; pode começar só com `/engineer:*`; adapters só ativam se o `.env` estiver configurado (Seção 8).

**Visual:** acordeão de 3 itens, com link "Ver FAQ completo" para o manual/press kit.

---

## 7. CTA Final

**Headline proposta:** "Copie a pasta. Configure o `.env`. Comece."

**Copy / mensagens-chave:**
- Instalação em menos de 2 horas para um dev experiente (Seção 8, FAQ "Qual é o esforço de instalação?").
- Funciona em qualquer projeto: novo, legado ou regulado (Seção 9, citação 1).

**CTA primário:** "Começar agora" → `docs/onion/getting-started.md`.
**CTA secundário:** "Falar com quem mantém" → contato/comunidade.

**Visual:** bloco final de alto contraste com o logo, o snippet de 3 passos (`cp .claude/` → editar `.env` → `/warm-up`) e o botão principal.

---

## Notas para a versão final

- Substituir bullets por copy de marketing acabado, mantendo a rastreabilidade às seções da KB-fonte.
- Validar headlines com o público-alvo prioritário (dev/tech lead com legado; startup técnica; time regulado — Seção 7).
- Confirmar contagens (82/49/5/4) contra `/meta:inventory` antes de publicar — números são SSOT do filesystem.
