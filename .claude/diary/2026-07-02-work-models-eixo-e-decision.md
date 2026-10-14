---
date: 2026-07-02
instance: onion-evolve
type: decision
classification: public
tags: [work-models, session-topology, federation, responder-gated]
affects: [meta, engineering, product]
breadcrumb_for: [meta:co-evolve, meta:adopt, meta:diary]
share_with: [collective]
next_recommended: ""
review_after: 2027-01-12
conflict_class: conditional
valid_when: "o fluxo segue human-gated e soberano (sem servico vivo de vendor no loop)"
---

## Signal
Os "modelos de trabalho" da federação agora são o **Eixo E** (valores W1-W7) — ADR
`onion-adr-work-models-session-topologies-2026-07`. W6 (responder-gated: sessão propõe rascunho,
maestro confirma) é o modelo (c); W7 (cron) rejeitado como base; ⏰ + `/meta:diary review` é o
gatilho invariável de reflexão.

## Evidence
- Taxonomia costurada de 5 fragmentos existentes (adopt, handoff, sala-design/obra, carteiro, remoto).
- Decisões fundamentadas em pesquisa verificada (ver migalha `sovereign-lazy-triggers-research`).
- Enablers entregues: ⏰ no hook (+4 guardas selftest), Passo 3.5 no co-evolve, sub-comando review no diary.
- Roadmap gated: consolidação estruturada (30+ migalhas OU F4), gate git-nativo por prefixo (1ª automação
  que commita), W7 rascunho-only (necessidade nomeada), carteiro distribuído (graduação).

## Next crumb
Antes de desenhar qualquer fluxo entre sessões/repos: classificar na topologia W1-W7 primeiro — se não
couber em nenhuma, é sinal de revisão do ADR, não de improviso.

## Re-testada em 2026-10-14: (conditional, só o `valid_when`) o ADR `onion-adr-work-models-session-topologies-2026-07` segue ACEITO, com o §3 "W7 rejeitado como base" intacto (adendos de 07-02 e 07-10 não o revogam). Os únicos workflows agendados do CI são determinísticos (`onion-selftest.yml`); o revisor Anthropic do CI roda por PR e não entra no fluxo entre sessões. O fluxo segue human-gated e soberano.
