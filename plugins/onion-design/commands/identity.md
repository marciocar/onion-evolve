---
name: identity
description: |
  Cria e desenvolve a identidade visual de um projeto como spec-as-code: brief
  (lê business-context) → develop (tokens W3C/DTCG na SSOT design-context, gate
  WCAG, materializa via design-sink) → material (reusa apresentação/Canva).
  Faseado e retomável. Fonte manual nesta versão; geração por IA (diverge/converge)
  chega numa fase futura. Delega a @design-system-specialist.
model: sonnet
allowed-tools: Read Write Edit Glob Grep Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/*) Bash(bash ${CLAUDE_PLUGIN_ROOT}/utils/design-sink/*)
category: design
tags: [design, tokens, identity, wcag, branding]
version: "0.1.0"
updated: "2026-06-22"
related_agents:
  - design-system-specialist
  - branding-positioning-specialist
  - presentation-orchestrator
related_commands:
  - /product:branding
  - /product:presentation
  - /meta:context-freshness
---

# /design:identity — Identidade visual como spec-as-code

## Objetivo

Operar o ciclo de vida da identidade visual de um projeto: do **brief** (intenção de marca)
até a identidade **materializada** (tema/CSS/componentes) e o **material** de comunicação —
tudo ancorado numa SSOT de **design tokens W3C/DTCG** (`docs/design-context/`). É o
**spec-as-code aplicado ao design**: os tokens são a fonte de verdade; CSS/componentes/
material são saída gerada e regenerável.

> **Princípio reitor.** A IA não inventa valores de design — lê a SSOT e a materializa.
> Contraste/refs/escala são **calculados** pelo gate determinístico (`lint-design-tokens.sh`),
> não estimados. Logos/pixels ficam fora da SSOT, sob gate humano.

## Fronteiras

- **NÃO** decide posicionamento/estratégia de marca → use `/product:branding` antes (alimenta o brief).
- **NÃO** é gerador-de-IA-de-design: usa **fonte manual** (você/o especialista edita tokens) ou
  **ingestão** (`design-source/`). A geração divergente (N identidades por IA) + convergência
  (gate + juiz) vive no comando irmão **[`/design:generate`](generate.md)** — cuja candidata
  vencedora alimenta o **DEVELOP** (Fase 2) daqui.
- **NÃO** crava o 4º peer: `docs/design-context/` é provisório (ver seu ADR de promoção).

## Workflow faseado (retomável)

Sessão em `.claude/sessions/design-<scope>/` (`STATE.md` aponta a fase). `<scope>` = `core` (default)
ou `<brand>`/`<product>` para multi-brand. Cada fase atualiza o ponteiro `NEXT`.

### Fase 1 — BRIEF (intenção + restrições)

1. Ler `docs/business-context/` se existir (posicionamento, personas, messaging) — a identidade
   visual **deriva** da estratégia de marca. Ausente → coletar o mínimo com o maestro (3-5 perguntas:
   personalidade da marca, público, tom, restrições, referências a evitar/buscar).
2. Ler `docs/design-context/` existente (não partir do zero se já há identidade).
3. Produzir/atualizar `docs/design-context/brief.md` (brief em prosa: intenção declarada
   — "confiável, moderno, acessível" — que vira **restrições verificáveis**, não estilo livre).
   _(Não usar `foundations/`: essa camada é só `*.tokens.json` — primitivos DTCG, não prosa.)_
4. Checkpoint: `NEXT: Fase 2`.

### Fase 2 — DEVELOP (tokens → SSOT → materializa)

1. Definir/editar os **tokens** em `docs/design-context/`:
   - `foundations/*.tokens.json` — primitivos (cores cruas, escala tipográfica, espaçamento).
   - `semantic/*.tokens.json` — papéis (`surface`, `on-surface`, `action`, `feedback`) → `{alias}` p/ foundations.
   - multi-brand/produto: `brands/<brand>/` e `products/<product>/` (overrides esparsos; herdam o core).
2. **Gate obrigatório** (não materializar se falhar):
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/validation/lint-design-tokens.sh
   ```
   DTCG bem-formado + referências resolvidas + contraste WCAG. Falhou → corrigir a SSOT (não contornar).
3. Delegar a **`@design-system-specialist`** a materialização via `design-sink`:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/utils/design-sink/tokens-to-css-vars.sh > <alvo>/theme.css   # css-vars (universal)
   ```
   Para Tailwind v4 / shadcn, o especialista mapeia os papéis semânticos (`@theme`, `--background`/`--primary`/…).
4. Carimbar frescor em `docs/design-context/index.md` (`Última Atualização`). Checkpoint: `NEXT: Fase 3`.

### Fase 3 — MATERIAL (opcional, reuso)

Gerar material de comunicação **on-brand** a partir dos tokens resolvidos por escopo — **reusa**
`/product:presentation` (Gamma) e o MCP Canva. NÃO cria gerador novo: o material lê a identidade
materializada. Ex.: deck, brand-book, social. Retomável.

## Auto-update / Task Manager

Não opera tasks — sem PASSO 0 de provider. Se a sessão for parte de uma feature com task, comente o
progresso na task via a abstração (`taskManager.addComment`) só se já houver `task-id` no contexto.

## Dogfood (padrão master)

Rodar **no próprio onion-evolve**: a identidade do Onion (`docs/design-context/` já tem foundations/
semantic reais — #D97757/#8A2BE2) é o caso de teste. Fase 2 → gate verde → materializar o `theme.css`
do Onion → aplicar num material (`docs/materials/landing-page.md`). Testar **modo de falha** (token
fora da escala, contraste insuficiente, alias órfão) — o gate deve barrar. Fix → re-rodar.

## Saída esperada

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/design:identity — <scope> — Fase <n>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
◆ Brief        : <intenção declarada / fonte business-context>
◆ Tokens       : <N foundations · M semantic · escopos>
◆ Gate WCAG    : ✅ passou / ❌ <violações>
◆ Materializado: <alvo(s) — theme.css / @theme / shadcn>
▶ Próximo      : <Fase n+1 | concluído>
```

## Referências

- SSOT + gate: `docs/design-context/` · `${CLAUDE_PLUGIN_ROOT}/validation/lint-design-tokens.sh`
- Sink: `${CLAUDE_PLUGIN_ROOT}/utils/design-sink/` · Especialista: `@design-system-specialist`
- Brief upstream: `/product:branding` (estratégia) · Material: `/product:presentation`
- Decisão de peer: `docs/design-context/decisions/onion-adr-design-peer-promotion.md` (provisório)
