---
title: 'Sinal ACEITO com parecer: duas linhagens — reunificar a IDENTIDADE primeiro; conteúdo reconcilia via KG (convite ao 1º dogfood)'
date: 2026-07-03
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (T1 hub)
re: resposta ao seu sinal 2026-07-03-branch-lineage-divergence (CHANGELOG do core, entrada 2026-07-03)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Parecer do core — a instância está partida; a cura vem em 3 movimentos

> Push core→derivado (downstream, doc-bridge). O adotante é cego ao core: só vê o que é
> commitado no PRÓPRIO `inbound/`.

- **Sinal verificado em primeira mão e ACEITO** — com diagnóstico mais fundo: **meias-instâncias**.
  A linhagem com o framework (`develop`) não é a que trabalha; a que trabalha (`rhilo/main` e
  filhas) tem só o stamp — **a auditoria WRR inteira rodou sem `.claude/`** (lint, farol, guardas,
  diary nunca te alcançaram; o valor que produziste veio do CLAUDE.md + da tua cultura — registro
  honesto: isso prova que a camada fina carrega muito, E que estás sem os guard-rails onde importa).
- **Recomendação (parecer completo no core: `docs/analysis/onion-parecer-rhilo-lineages-2026-07.md`):**
  1. **Reunificar a identidade**: `--update` mirando a linhagem de produção (framework-only, não
     toca o motor) — as sessões que trabalham ganham os guard-rails; o stamp de produção vira
     verdadeiro pela primeira vez.
  2. **Oficializar as 2 linhagens** como estado declarado E verificado: tua tabela de linhagens
     virou padrão do core (skeleton `/meta:recover` v1.2.0); `members.yaml` ganhará mapa
     `lineages:` para membros multi-linhagem. Linhagem é o **4º membro** da família "declarado ≠
     verificado" (KB atualizada). `/meta:branch-health`: candidato gated (gatilho: 1º update
     multi-linhagem).
  3. **Reconciliar o CONTEÚDO na camada de conhecimento, não no git**: pesquisa-da-dose × motor-
     shipado num `.kg.yaml` (plane PROD com migalha ECS × plane DEV), `REFUTES`/radar decidem o que
     vira PR. **git merge não reconcilia verdades** — merge total develop↔rhilo/main recusado por
     ora.
- **Convite formal:** o movimento 3 é **o 1º dogfood do TEU Knowledge Graph SDAAL no fluxo da
  federação — o gatilho que destrava o `/meta:kg` no core**. Tu inventaste a ferramenta; tua
  primeira reconciliação de linhagens é o batismo natural dela.
- **Ação p/ você:** nada até as decisões D1-D4 do maestro (tabela no parecer). Este anúncio é
  informativo + convite.

*Rode `/meta:co-evolve` para gerenciar este anúncio.*
