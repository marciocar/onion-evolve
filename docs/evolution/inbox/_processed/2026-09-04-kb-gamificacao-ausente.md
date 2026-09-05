---
title: 'Core tem education/ em duas camadas, mas não tem KB de gamificação — nasceu uma no adotante'
date: 2026-09-04
from: portal-gamificacao (consumidor)
to: core (onion-evolve)
type: field-signal
flow: upstream (consumidor→core)
---

## O que aconteceu
`docs/knowledge-base/education/{theories,applications}/` existe e é ótimo como padrão (fonte ≠ derivação). Não há
nada de gamificação no core além do agente `@zen-engine-specialist` (JDM). Este adotante criou
`docs/knowledge-base/gamification/{sources,theories,applications,graph}/` seguindo o mesmo README de duas camadas,
para mapear o MAAGICA (metodologia do maestro, MPIE/IFRS) e dois livros autorais em `.kg.yaml`.

## Risco que registramos
`docs/knowledge-base/` é path vendorizado no `--update`; `gamification/` não existe no core, então o never-clobber
preserva. Se o core criar `gamification/` um dia, vira conflito de merge em `onion/vendor` — avisar.

## Proposta
Quando `D_IP_LICENSE` deste projeto for selada, a camada 1 (`theories/`) pode subir ao core como vertical
`onion-gamification` (mesma rampa gated da education). Até lá, só o README de duas camadas já valeria como
template para "KB de domínio de adotante".

---

## Triagem do core — 2026-09-05

**Veredito: BACKLOG GATED, com gatilho nomeado** — no
`I_KB_GAMIFICACAO_RAMPA_GATED` de `docs/onion/graph/fios-abertos.kg.yaml` (projetado em `docs/backlog.md`).
Não subimos a camada 1 agora, e a razão é sua: `theories/` mapeia metodologia e livros AUTORAIS. Subir
doutrina de propriedade de terceiro antes da licença é o erro. **GATILHO: a selagem do `D_IP_LICENSE` no
grafo DE VOCÊS** — quando ele selar, a rampa gated de vertical (a mesma da `education`) abre para um
plugin `onion-gamification`.

**Risco registrado, independente do gatilho** (e obrigado por levanta-lo): `docs/knowledge-base/` é path
vendorizado no `--update`. Hoje o never-clobber preserva a sua pasta porque `gamification/` NÃO existe no
core — medido. Se o core criar essa pasta, o merge em `onion/vendor` conflita no seu repo; ficou escrito no
no que quem criar avisa antes.

O ganho que colhemos JA, sem gatilho: o seu uso confirma o README de duas camadas como template de
"KB de domínio de adotante".
