---
title: 'ADR — "Onion adota, não impõe": verticais opinativas deferem ao padrão do projeto na adoção (SDAAL no eixo design-system provider)'
date: 2026-06-24
type: adr
status: proposto
decision-scope: adoption / standard-deference (SDAAL)
supersedes: none
deciders: maestro + sessão de evolução
context_freshness: 2026-06-24
related:
  - ../sdaal/sdaal.md (padrão SDAAL — provider-agnóstico)
  - ../meta-specs/integrations.md (SDAAL aplicado: task-manager, forge)
  - ../../.claude/commands/meta/adopt.md (/meta:adopt — never-clobber, greenfield/legacy/regulated)
  - ../../.claude/commands/design/identity.md (/design:identity — vertical de design)
  - ../../.claude/utils/design-source/README.md (SDAAL design — eixo FORMATO, entrada)
  - ../../.claude/utils/design-sink/README.md (SDAAL design — eixo FORMATO, saída)
  - ../design-context/decisions/onion-adr-design-peer-promotion.md (precedente: vertical de design peer)
  - onion-adr-repo-adoption-2026-06.md (adoção = comando in-platform)
---

# ADR — "Onion adota, não impõe"

> **Status: PROPOSTO (provisório).** Nomeia um **princípio** e abre um **eixo SDAAL novo** + um **passo de
> validação de adoção**. NÃO crava constituição nem implementa código — a costura (heurística de detecção +
> passo no `/design:identity init` e `/meta:adopt`) fica **diferida ao gatilho**. Método igual aos ADRs
> provisórios recentes (PFR, ledger, vocabulário): nomear + costurar, evidência antes de lei.

## Contexto

O Onion tem **verticais opinativas** — a de **design** à frente: padrão nativo com SSOT spec-as-code
(`docs/design-context/`, W3C/DTCG), gate WCAG (`lint-design-tokens.sh`) e `@design-system-specialist`.
O risco aparece **na adoção de um projeto que já tem o próprio padrão de design** (shadcn em
`tailwind.config`, um `docs/design-system/shared.css` próprio, Figma tokens, MUI…): rodar a vertical nativa
crua **cria `design-context/` ao lado/por cima** do que já existe — **quebra, perturba ou troca** o padrão
que funciona.

### Evidência de campo (2026-06-24)

Investigando se valia o plugin `frontend-design@claude-plugins-official`, mapeei o `rhilo-app`
(`vite_react_shadcn_ts` — Vite + React + **shadcn/ui** + Tailwind, com a skill própria **`ux-flow`** que
mantém um design system em `docs/design-system/shared.css` como SSOT e tem passo de **Discovery** que
detecta shadcn/tailwind/figma antes de criar). Rodar `/design:identity` ali, cru, **duplicaria** a SSOT.
Ironia diagnóstica: o **adotante** (`ux-flow`) detecta design system alheio melhor que a **vertical do
core** hoje detecta — o inbound-detection do Onion é o elo fraco.

### O que o SDAAL já cobre vs o gap

- **Coberto — eixo FORMATO.** `design-source` (`figma`/`penpot`/`file` → DTCG) e `design-sink`
  (DTCG → `css-vars`/`tailwind`/`shadcn`) já são SDAAL anti-lock-in. A *materialização* já adapta ao stack.
- **Gap — eixo PADRÃO/AUTORIDADE, na adoção.** Não há (a) um provider que represente *qual design system o
  projeto já roda*, nem (b) um passo que **detecte do filesystem** e **decida deferir/estender/introduzir**
  sem clobber. `/design:identity` só lê `docs/design-context/` (o lugar **do Onion**) — é cego a um design
  system **alheio**.

O princípio já governa **implicitamente** outras verticais — task-manager e forge **detectam o provider**
(`TASK_MANAGER_PROVIDER`, `FORGE_PROVIDER`) e roteiam; `/meta:adopt` é **never-clobber** e greenfield-first.
Falta **nomear** o princípio e **fechá-lo na vertical de design**.

## Decisão

**1. Princípio (transversal, provisório): "Onion adota, não impõe".** Na adoção, toda vertical opinativa
**detecta o padrão estabelecido do projeto** e escolhe entre **deferir · estender · introduzir** —
**nunca clobber**. É a generalização explícita do que SDAAL (`provider-agnóstico`) + `/meta:adopt`
(`never-clobber`) já fazem por partes. O padrão nativo do Onion é **o default provider**, não a imposição.

**2. Eixo SDAAL novo na vertical de design: `design-system provider`** — distinto do eixo formato
(`source`/`sink`):

| provider | significa | papel da SSOT |
|---|---|---|
| `onion-native` | usa `docs/design-context/` (DTCG) como SSOT | SSOT própria |
| `project-existing` | detecta o que o projeto roda: `shadcn-tailwind` · `ux-flow-sharedcss` · `figma-tokens` · `mui` · … | SSOT é a do projeto; `design-context/` vira ponteiro/extensão fina, não substituto |
| `none` | greenfield / sem design system | instala o nativo |

**3. Validação de adoção (detect → decide → never-clobber)** — passo no `/design:identity init` e no
`/meta:adopt` (Fase de integrações):

- **detect** (heurística de filesystem): `tailwind.config.*` + `components/ui/` → `shadcn-tailwind`;
  `docs/design-system/shared.css` (ou similar) → `ux-flow-sharedcss`; `*.tokens.json` / export Figma →
  `figma-tokens`; deps MUI → `mui`; nada → `none`.
- **decide** (human-gated, reporta ao maestro):
  - **defer** — projeto tem design system governado → Onion **usa-o como SSOT**; o `sink` aponta pra ele;
    `design-context/` não nasce como cópia.
  - **extend** — projeto tem tokens mas sem governança/WCAG → Onion **acrescenta o gate + governança por
    cima**, sem mover os tokens.
  - **introduce** — greenfield → instala o `design-context/` nativo.
- **never-clobber** — em `defer`/`extend`, jamais sobrescrever o que existe; só adicionar (ponteiro,
  gate, doc).

## Coerência (não contradiz)

- **SDAAL** (`sdaal.md`, `integrations.md`): é a aplicação canônica do padrão — consumidor chama a
  abstração; o adapter resolve o provider. O novo eixo é irmão do `task-manager`/`forge`.
- **`/meta:adopt`**: estende o **never-clobber** já implementado e os modos greenfield/legacy/regulated
  (legacy = onde o `defer`/`extend` mais aparece).
- **ADR design-peer** + doutrina de dogfooding: a vertical detecta o real e resolve no loop, não impõe papel.
- **`onion-adr-repo-adoption`**: adoção é in-platform, faseada, retomável — a validação encaixa como passo.

## Gatilho de promoção (quando construir a costura)

Disparar a implementação (heurística + passos + provavelmente um `design-system/factory.md` SDAAL) quando
**qualquer**: (a) `/design:identity` for de fato rodado num projeto **legacy com design system próprio**
(o `rhilo-app` é o caso vivo); (b) surgir um 2º adotante com design system pré-existente; (c) a vertical de
design graduar a promoção peer e precisar do inbound-detection para ser honesta. Até lá: **provisório** — o
princípio nomeado já orienta as sessões de adoção a **não impor**.

## Consequências

- ✅ Adoção **nunca quebra** o design que já funciona; o padrão Onion vira *default provider*, não imposição.
- ✅ **Nomeia** um princípio que já governa task-manager/forge por baixo — fecha a lacuna na vertical de design.
- ✅ Destila o melhor do `frontend-design`/`ux-flow` **para dentro do mecanismo governado** (em vez de adotar
  ferramenta externa cega ao SSOT — ver nota de método abaixo).
- ⚠️ Implementação **diferida** — este ADR só nomeia + costura. O `defer` (SSOT alheia) exige cuidado: o
  `sink` apontar pra fora do `design-context/` muda o contrato do gate WCAG (validar a SSOT alheia).
- ⚠️ "Provisório" até o gatilho — vive em `docs/analysis/`, não na constituição.

## Alternativas consideradas

1. **Sempre introduzir `design-context/`** (status quo) — rejeitado: clobber/duplicação (evidência rhilo-app).
2. **Sempre deferir ao projeto** (nunca oferecer o padrão nativo) — rejeitado: greenfield perde a vertical;
   o ponto é **detectar e decidir**, não capitular.
3. **Resolver ad-hoc a cada adoção, sem nomear** — rejeitado: deixa ao acaso, sem governança, repete o risco
   de clobber a cada vez.
4. **Restringir o princípio só a design** — rejeitado como *nome* (o "adota-não-impõe" é transversal: vale
   p/ outras verticais opinativas); mas o **build** começa pela vertical de design (onde a dor é viva).
5. **Adotar o plugin externo `frontend-design`** — rejeitado: cego ao SSOT, viés de tom, auto-update vs
   update-deliberado (ver avaliação que originou este ADR).

> **Nota de método.** Mesmo padrão do RFC-0002 (catálogo) e da avaliação do `frontend-design`: **não adotar
> a ferramenta externa; destilar a ideia útil para dentro do mecanismo governado.** Aqui, o mecanismo é a
> vertical de design nativa + o eixo SDAAL de adoção.
