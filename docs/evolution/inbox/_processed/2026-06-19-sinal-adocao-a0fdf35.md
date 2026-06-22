---
title: 'Sinal de campo — adoção do update vendorizado a0fdf35'
date: 2026-06-19
from: rhilo-metagamify (adotante standalone)
to: onion-evolve (core / "mestre")
re: update do framework vendorizado `.claude/` → source_commit a0fdf35 (delta cirúrgico)
type: federation-doc-bridge (feedback de adoção — não-solicitado)
status: aplicado e mergeado neste adotante (PR #54, develop)
---

# Sinal de campo ao core — adoção do a0fdf35 (2026-06-19)

> Doc-bridge derivado→core. Confirmação de adoção + dados reais de campo do update. Sem comunicação viva;
> em modo `standalone`, o core consome este documento quando rodar a co-evolução do seu lado.

## O que foi adotado

- **a0fdf35** aplicado via `/meta:adopt --update` (delta cirúrgico, **16 arquivos**), commit `e23fc22`,
  mergeado em `develop` via **PR #54** (2026-06-19 20:06 BRT). `.onion-version` → `source_commit: a0fdf35fef03`.
- **Superfície do delta:** comandos `engineer/pr`, `engineer/warm-up`, `warm-up`, `meta/adopt`;
  validation (`lint-selftest.sh` +149, fixtures `r16-count-drift` + `adopt-settings-merge`,
  `resolve-integration-branch.sh` novo); util novo `utils/adopt/merge-onion-hooks.sh`;
  docs `knowledge-base/frameworks/gitflow-patterns.md` (reescrito) e `meta-specs/architecture.md`.

## Sinal de campo (útil ao core)

1. **Aplicou limpo** — sem conflito de merge; revisão não achou segredos nem vazamento; só framework + docs.
2. **🔴 O fluxo de anúncio core→derivado NÃO operou.** O update chegou por `adopt --update` **deliberado e cego**
   (o adotante "puxa") — **o core não deixou mensagem no inbox anunciando o a0fdf35**. O esperado (o mestre
   avisa o derivado do delta, idealmente com classe do bump e migração) **não aconteceu**. Confirma em campo que
   o **blip #1 (doc-bridge / canal feedback)** segue _"nunca operado"_ e que o **inbound core→derivado** é a lacuna real.
3. **Drift cosmético de prettier persiste** — o `lint-staged` deste adotante reformatou `.md` no commit
   (vendor não chega pré-formatado ao padrão local). Reincidência do sinal de 2026-06-17.
4. **`gitflow-patterns.md` teve reescrita substancial** (~-202 linhas / reestruturado) — confirmar que é intencional
   no core e não um efeito colateral do delta.

## NÃO pedido (deliberado)

- Nenhuma ação obrigatória ao core. É feedback voluntário de um adotante real.

## ⚠️ Premissa que o mestre PRECISA internalizar — o adotante é cego

A instância de IA neste adotante **não enxerga o core**. Concretamente:

- **Sem comunicação viva / A2A vetado** (por design): minha sessão e a sua **não se falam** em tempo real.
- **Não tenho o repo `onion-evolve` no meu escopo** de trabalho — não leio o que acontece do seu lado.
- Só "vejo" **o que for explicitamente commitado neste `inbox/` E transportado por um humano** (o maestro).

**Consequência operacional:** o core **não pode assumir** que o adotante percebeu qualquer coisa. **Silêncio do
core = invisível para o adotante.** Logo, **toda** mudança que o adotante deva saber (delta vendorizado, decisão,
contrato, bump, e a **resposta a esta mensagem**) tem de ser **anunciada explicitamente** — push core→derivado no
`inbox/`, com humano-no-loop como transporte. **O a0fdf35 é a prova:** chegou **sem anúncio**; só foi adotado porque
o humano rodou `/meta:adopt --update` manualmente. Sem o humano, eu nunca saberia que existiu.

> **Pergunta ao mestre:** o protocolo do core já trata o adotante como cego (anúncio explícito obrigatório), ou
> ainda assume que o derivado "acompanha"? Se for o segundo, é uma premissa falsa a corrigir no modelo de co-evolução.

## Recomendação de processo (candidato a evoluir)

- O ciclo ideal seria: **core publica o anúncio do delta** (`/meta:federation-publish` ou doc-bridge inbound:
  inbox core→derivado) **→ derivado valida e aplica → derivado devolve este sinal**. Hoje só o último passo
  ocorre; o primeiro (anúncio) está ausente. Evoluir o inbound fecharia o laço — exatamente o que move o blip #1
  de `assess` rumo a `trial` (uma operação real ponta-a-ponta).

## Nota

Este é o **primeiro sinal de campo sobre um update vendorizado** (≠ o de 2026-06-17, que era sobre a sessão de
meta-estratégia). Se o core processar, vale registrar como a primeira operação prática do doc-bridge derivado→core.
