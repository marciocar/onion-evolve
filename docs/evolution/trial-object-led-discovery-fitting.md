---
title: 'Trial — Capability "Object-Led Discovery & Fitting" (promover objeto a papel)'
date: 2026-07-01
veredito: resolvido — aceito como playbook do catálogo
resolvido-em: 2026-07-01
origem: docs/evolution/inbox/_processed/2026-06-29-capability-adaptive-object-led-discovery.md
from: rhilo-metagamify (adotante standalone)
gate: dogfood com DataTable premium (rhilo-app `feat/gamification-dose-viz`) antes de canonizar forma
resultado: ../analysis/onion-adr-object-led-discovery-2026-07.md (PR #213 MERGED d24f03a) — anunciado via federation/CHANGELOG.md 2026-07-01 + outbox/rhilo-metagamify/_processed/
---

# Trial — Capability "Object-Led Discovery & Fitting"

> **RESOLVIDO (2026-07-01):** as questões (a)–(d) abaixo foram respondidas e o dogfood guiado foi feito
> **retroativamente** sobre a evidência que o próprio sinal já trazia (sem precisar operar de novo no
> rhilo-app) — ver [`onion-adr-object-led-discovery-2026-07.md`](../analysis/onion-adr-object-led-discovery-2026-07.md)
> (PR [#213](https://github.com/marciocar/onion-evolve/pull/213), merged `d24f03a`). Este documento fica
> como **registro da triagem original** (por que `trial`, não `accept`/`defer` direto); o veredito final e
> a forma materializada vivem no ADR.
>
> **Veredito de triagem original (2026-07-01):** `trial` — sinal bem fundamentado, evidência empírica concreta,
> peças do core já existem. A **forma final** (ADR próprio? extensão RFC-0002? skill fina?) precisava de um
> dogfood guiado antes de canonizar. O DataTable premium foi o caso piloto usado.

## Por que trial (não accept nem defer)

| Critério | Situação |
|---|---|
| Gap real e recorrente? | Sim — "promover objeto a papel" é feito imperativamente hoje, sem ciclo canonizado |
| Peças de grounding existem no core? | Sim — Capability Contract, Self-Describing Components, SDAAL, catálogo-first (RFC-0002) |
| Evidência empírica? | Sim — DataTable premium (rhilo-app) construído de forma imperativa; resultado à mão |
| Forma canonizável agora? | Não — 4 questões abertas pelo próprio sinal (a)–(d) que o maestro precisa decidir |
| Risco de inchaço se aceito precipitadamente? | Médio — skill nova sem dogfood pode virar superfície desnecessária |

Conclusão: sinal promissor que merece espaço no roadmap, mas **a canonização espera uma rodada de
dogfood guiado** que responda as questões de forma antes de qualquer PR de implementação.

## Resumo do gap (destilado do sinal S2026-06-29)

Quando o maestro pede "promova este objeto a um padrão premium" (ex.: `<table>` solta →
`<DataTable>` reutilizável e rico), o agente improvisa imperativamente: lê exemplos, infere
requisitos, escolhe ferramentas e migra à mão. Funciona — mas é não-reproduzível, não-catalogado
e dependente da atenção pontual do operador.

A causa-raiz: falta canonizar o ciclo **object-led discovery + capability-fitting** como uma
capability dirigível (human-in-the-loop), ancorada nas peças que o core já tem.

## Ciclo proposto (nome de trabalho)

```
espelhar → descobrir (object-led) → vestir (capability-fitting) → materializar → realimentar
```

1. **Espelhar** — stub/draft descartável do objeto (worktree/clone), sem tocar o original
2. **Descobrir** — introspectar o objeto e pares no repo; montar Capability Contract (provides/requires/tier)
3. **Vestir** — selecionar do catálogo/SDAAL os adapters/estratégias que o papel-alvo exige; reuso-first
4. **Materializar** — aplicar sob direção do maestro (gates por etapa), com verificação (tsc/build/test)
5. **Realimentar** — resíduo sem match vira novo playbook no catálogo (fecha loop do RFC-0002)

## Grounding (síntese, não invenção)

- **Information Expert / Self-Describing Components** — "quem responde sobre o objeto é o objeto"
- **Capability Contract** (ADR aceito) — `provides/requires/loads` + Bronze/Silver/Gold
- **SDAAL** — adapters provider-agnósticos; LLM=runtime, Markdown=bytecode; "vestir" sem código intermediário
- **Catálogo-first / Strategy-Playbooks** (RFC-0002) — reconhece situação → reroute; resíduo → novo playbook
- **Economia de motores** — Transformer dirige o fluxo; SLM-como-ferramenta executa os passos; SDAAL é o contrato

## Questões respondidas (era "pré-dogfood"; ver ADR para o texto completo da resposta)

| # | Pergunta | Inclinação do sinal | Resposta final (ADR) |
|---|---|---|---|
| **(a)** Forma: ADR + skill própria ou extensão RFC-0002 + Strategy-Playbooks + skill fina de orquestração? | Extensão (menor superfície, casa com catálogo-first) | ✅ Confirmada — playbook em `onion-patterns/SKILL.md`, sem skill/comando novo |
| **(b)** "Espelho/stub": artefato físico (worktree descartável) ou conceitual (plano)? | Físico quando há risco de mutação (N arquivos); conceitual quando é só leitura | ✅ Confirmada — mesma régua |
| **(c)** Gate assess→trial: caso piloto = DataTable premium do rhilo-app? | Sim — resultado à mão, bom baseline "dirigido vs improvisado" | ✅ Confirmada — usado **retroativamente** (evidência já anexada ao sinal, sem operar de novo no rhilo-app) |
| **(d)** Relação com `create-*`: "promover" (objeto existe) vs "criar" (do zero) — mesmo toolbox, gatilho diferente? | Mesmo toolbox; gatilho `--from <objeto>` vs `--new` | Parcial — mesma régua P0-P3, mas **não** entrou no toolbox `create-*`; vive como playbook próprio e paralelo |

## Próximo passo concreto (histórico — já executado)

1. ~~Maestro responde (a)–(d)~~ — respondido no ADR
2. ~~Dogfood guiado~~ — feito retroativamente sobre a evidência do próprio sinal (§6)
3. ~~PR de implementação~~ — [#213](https://github.com/marciocar/onion-evolve/pull/213), merged `d24f03a`
4. Loop fechado com anúncio downstream a `rhilo-metagamify` (`federation/CHANGELOG.md` 2026-07-01 +
   entrega via `/meta:co-deliver` no `inbound/` de lá)

## Rejeições registradas (anti-inchaço)

- Não criar skill `/onion:promote` sem dogfood primeiro — superfície antes de prova é inchaço
- Não reclassificar como accept só porque o sinal é bem escrito — forma canonizável é gate separado
- Não juntar com `create-*` toolbox antes de clareza sobre questão (d)
