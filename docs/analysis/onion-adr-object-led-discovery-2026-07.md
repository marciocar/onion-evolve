---
title: 'ADR — Object-Led Discovery & Fitting: "promover objeto a papel premium" como playbook do catálogo (não skill/ADR-heavy nova)'
date: 2026-07-01
type: adr
status: aceito (doutrina + playbook materializado); dogfood retroativo concluído neste ciclo
decision-scope: meta / toolbox-lifecycle / catálogo-first
supersedes: none
extends: onion-adr-capability-contract-2026-06.md, rfc-0002-meta-strategy-verdict.md, onion-adr-toolbox-lifecycle-2026-06.md
deciders: maestro + sessão de evolução
context_freshness: 2026-07-01
related:
  - docs/evolution/inbox/_processed/2026-06-29-capability-adaptive-object-led-discovery.md (sinal de origem)
  - docs/analysis/onion-adr-capability-contract-2026-06.md (provides/requires/loads/conformance — vocabulário reusado)
  - docs/analysis/onion-research-self-describing-components-2026-06.md (Information Expert — princípio-fonte)
  - docs/evolution/rfc/rfc-0002-meta-strategy-verdict.md (catálogo-first — doutrina que este ADR instancia)
  - docs/analysis/onion-adr-toolbox-lifecycle-2026-06.md (régua P0-P3 aplicada abaixo)
  - .claude/skills/onion-patterns/SKILL.md (seção Playbooks — onde a decisão materializa)
---

# ADR — Object-Led Discovery & Fitting

> **Status: ACEITO como playbook do catálogo** (não como skill/comando/ADR-heavy novo). O sinal de campo
> (`rhilo-metagamify`, 2026-06-29) já trazia evidência anexa (DataTable premium do dashboard WRR) — o dogfood
> guiado foi feito **retroativamente sobre essa evidência**, sem precisar operar de novo no rhilo-app.

## Contexto

O sinal descreveu um incidente real: pedido do maestro para "promover tabelas a componente premium" foi
executado **imperativamente** — o agente inventariou exemplos, escolheu stack e migrou tabela a tabela,
re-improvisando o método a cada novo requisito (seletor, tela cheia, resize/pin). O maestro nomeou o gap:
faltou um **módulo de descoberta que se veste sobre o objeto** — "quem sabe sobre o objeto é o próprio
objeto" (Information Expert). A proposta: canonizar o ciclo **espelhar → descobrir (object-led) → vestir
(capability-fitting) → materializar → realimentar** como capability dirigível.

## Aplicação da régua P0-P3 (onion-adr-toolbox-lifecycle)

- **P0 — Já existe?** Quase tudo. `Capability Contract` (ADR aceito) já dá o vocabulário de auto-descrição
  (`provides/requires/loads/conformance`) que o passo "descobrir" precisa. `SDAAL` já dá o "vestir"
  (adapters reusáveis, sem código intermediário). `RFC-0002` já aceitou **catálogo-first** como doutrina e
  **já materializou** a seção "Playbooks" em `onion-patterns/SKILL.md` (5 entradas vivas). **Não falta
  infraestrutura — falta uma entrada no catálogo.**
- **P1 — Determinístico ou juízo?** Juízo (descoberta + fitting exigem interpretação do objeto e do
  papel-alvo) → não é script.
- **P2 — Semântica ou invocação?** É **playbook** (reconhecimento de situação + sequência), não skill/comando
  novo — mesma forma que as 5 entradas existentes (`descoberta → backlog`, `planejamento → entrega`, etc.).
- **P3 — Irreversível?** O passo "materializar" muta arquivos reais → **gate humano por etapa**, igual ao
  padrão já usado em `design:generate` (diverge/converge com gate determinístico) e na família `co-*`
  (human-gate antes de transportar). O passo "espelhar" deve ser **físico** (worktree/stub) quando há risco
  de mutação, **conceitual** (plano) quando é só leitura — aceita a inclinação do próprio sinal (questão b).

**Veredito P0-P3:** reuso quase total. A síntese que faltava é **uma entrada de playbook**, não um novo
subsistema.

## Decisão

1. **Aceitar o ciclo como doutrina**, ancorado no que já existe (Capability Contract + SDAAL + catálogo).
2. **Materializar como playbook** em `.claude/skills/onion-patterns/SKILL.md` §Playbooks — não como ADR-skill
   isolada nem como `/onion:promote` dedicado. Nome de catálogo: **"promover objeto existente a papel
   premium"**.
3. **Responder as questões do sinal (§5):**
   - **(a) Forma:** extensão do catálogo de playbooks (não ADR+skill própria) — confirma a inclinação do
     sinal, e é mais barata do que a superfície proposta.
   - **(b) Espelho/stub:** físico (worktree/draft descartável) quando há risco de mutação (migração de N
     arquivos); conceitual (plano) quando é leitura — confirma a inclinação do sinal.
   - **(c) 1º caso canônico:** o **próprio DataTable premium** do rhilo-app, usado **retroativamente** como
     dogfood (evidência já anexada ao sinal — ver seção seguinte). Confirma a inclinação do sinal.
   - **(d) Relação com `create-*`:** "promover" (objeto existe) e "criar" (do zero) usam a **mesma régua
     P0-P3**, mas o gatilho é distinto — não precisa entrar no toolbox `/meta:create-*`; vive como playbook
     próprio, paralelo.

## Dogfood guiado (retroativo, sobre a evidência do sinal §6)

O sinal já trazia o material: DataTable premium construído à mão no rhilo-app (branch
`feat/gamification-dose-viz`), com capacidades acumuladas por pedidos sucessivos — sort, filtro, busca,
agrupar, expandir, colunas, export, salvar-visão, seleção+bulk, tela-cheia, densidade, resize, pin.
Rodando o ciclo proposto **contra essa evidência** (sem tocar o rhilo-app de novo):

| Etapa do ciclo | O que teria acontecido dirigido (vs. o que de fato ocorreu improvisado) |
|---|---|
| **Espelhar** | Um stub/draft do `SlaConfigTable` (1º alvo real) antes de migrar — não ocorreu; a migração foi direto no arquivo âncora. |
| **Descobrir (object-led)** | Um Capability Contract da tabela-alvo declarando `provides: {rows, columns}` / `requires: {sort?, filter?, export?}` / tier atual (`bronze` = tabela solta) — não existiu; a descoberta foi implícita na leitura de exemplos (`FoldersTable`/`UnifiedFoldersTable`). |
| **Vestir (capability-fitting)** | O papel-alvo "tabela premium" deveria ter resolvido, de saída, o conjunto completo de capacidades (sort/filtro/busca/agrupar/expandir/colunas/export/salvar-visão/seleção+bulk/tela-cheia/densidade/resize/pin) como **um perfil único reusável** — em vez disso, cada capacidade chegou por **pedido sucessivo do maestro**, re-adicionada ao core a cada rodada. |
| **Materializar** | Ocorreu (com verificação humana a cada rodada) — este passo já estava dirigido; o gap está a montante (descoberta+fitting), não aqui. |
| **Realimentar** | Não ocorreu formalmente — o conjunto de capacidades descobertas por tentativa (13 tabelas, 1 perfil emergente) não virou playbook/catálogo até este sinal. **Este ADR fecha esse loop.** |

**Achado do dogfood:** o gap real não estava em "materializar" (que já era dirigido e verificado) — estava em
**"descobrir + vestir" não serem antecipados como um perfil único**. O perfil "tabela premium" só emergiu
depois de ~10 pedidos sucessivos. Um Capability Contract do papel-alvo, escrito **antes** da 1ª migração,
teria convertido pedidos sucessivos em **um fitting único**.

**Playbook extraído (o resíduo vira catálogo — fecha RFC-0002):**
```
Situação: maestro pede para elevar um objeto existente e solto (ex.: <table>) a um componente/papel
reutilizável e rico ("premium").
1. Espelhar — stub/worktree do objeto-alvo se a migração for mutação de N arquivos; plano se for leitura.
2. Descobrir (object-led) — Capability Contract do objeto: provides/requires/tier atual; inventariar pares
   no repo (outras instâncias do mesmo objeto) antes de decidir o alvo.
3. Vestir (capability-fitting) — resolver o PERFIL COMPLETO do papel-alvo de saída (não por pedido
   sucessivo); reusar do catálogo/SDAAL antes de introduzir dependência nova.
4. Materializar — sob direção do maestro, gate por etapa, com verificação (build/test).
5. Realimentar — o perfil descoberto (ex. "tabela premium" = sort+filtro+busca+export+...) vira entrada de
   catálogo para a próxima promoção do mesmo tipo de objeto.
```

## Consequências

- **+** Fecha o sinal sem abrir superfície nova (skill/comando/subsistema) — reuso quase total do substrato.
- **+** O playbook é imediatamente reusável na próxima "promoção" de objeto (forms, dashboards, integrações —
  citados no próprio sinal como próximos candidatos).
- **+** Retroalimenta RFC-0002: é a 6ª entrada viva do catálogo de playbooks (as 5 anteriores já materializadas).
- **−** O playbook descreve disciplina, não automação — a régua P0-P3 já registrou que isso é aceitável
  (playbooks de guarda existentes, ex. "laço de realimentação sem guarda", também são disciplina, não script).
- **Não-decisão (gated):** um comando `/onion:promote` dedicado fica em aberto — só se materializa se o
  playbook, em uso real, mostrar fricção que a disciplina em prosa não resolve (mesmo gatilho de promoção do
  `onion-adr-toolbox-lifecycle` — gate-de-uso, não antecipação).
