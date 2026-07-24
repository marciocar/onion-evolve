---
date: 2026-07-24
instance: onion-evolve
type: innovation
classification: collective
tags: [federation, identity, personality-sync, rfc-0003, declared-vs-verified, dogfood, emergent]
affects: [meta, federation]
breadcrumb_for: []
share_with: []
next_recommended: "Ao dar personalidade a uma instância (core ou adotante), NUNCA declare à mão — rode /meta:personality-sync: a personalidade EMERGE da evidência de uso (diário + .onion-version + 30 primeiros commits), com âncora obrigatória (afirmação sem fonte no diário/git não entra, mesmo rigor do pin-que-prova-ser-commit). É projeção one-way (a2a_card_projection), não fonte de verdade — nunca derive gate/decisão dela. Cada sync REGENERA. Adotante: gera na PRÓPRIA sessão e relaya o summary upstream (I3); o core nunca sintetiza a personalidade alheia."
review_after: 2026-10-22
conflict_class: static
significance: "A Fase 2 (personality-sync) shipou virando o declarado≠verificado — a ansiedade central do core — para dentro, sobre a PRÓPRIA identidade: a personalidade do onion-evolve deixou de ser um seed manual e passou a EMERGIR de 74 migalhas do diário, dogfoodada, com as 27 âncoras todas reais. A ferramenta que torna a identidade honesta foi validada tornando a identidade do core honesta."
---

## Signal
**A doutrina do core virada sobre o próprio rosto.** O `personality_summary` de toda instância no
`members.yaml` era um **seed manual pré-F2** — declarado à mão, nunca emergido do uso: o `declarado≠verificado`
aplicado à identidade, e ainda aberto (`C_PERSONALITY_SEEDS`). A Fase 2 da RFC-0003 fechou isso construindo
`/meta:personality-sync` e **dogfoodando no core**: a personalidade do onion-evolve agora EMERGE da evidência,
não da declaração.

## Evidence
- **O comando** (`.claude/commands/meta/personality-sync.md`, RFC-0003 §2.4): gera
  `.claude/identity/personality.md` (5 seções, projeção A2A-card one-way) a partir de 3 fontes de uso — diário,
  `.onion-version`, os 30 primeiros commits. **Regra de âncora dura:** afirmação sem fonte no diário/git/stamp
  **não entra** (o mesmo rigor do pin-que-prova-ser-commit; personalidade inventada é o modo-de-falha). Cada
  sync **regenera** (a personalidade acompanha o uso).
- **O dogfood:** a personality.md do core sintetizada de **74 migalhas** + a semente git. O caráter que emergiu
  é honesto e verificável: **nasceu ClickUp-pragmático** (os 30 primeiros commits — migração/specialists/`sync` —
  confirmam literalmente) e virou um framework auto-verificador cuja ansiedade central é o declarado≠verificado.
- **Verify adversarial (aprovado):** as **27 `[[slug]]` todas mapeiam a migalhas reais** (zero âncora fabricada);
  4 migalhas amostradas sustentam suas afirmações (várias palavra-por-palavra na linha `significance:`); fiel à
  RFC-0003 §2.4; sem vazamento de nome de cliente. Único defeito (low) — uma contagem "8 adotantes" onde há 7 —
  corrigido antes de fechar. O rigor que o comando prega foi exercido CONTRA o comando.
- **Fechamento honesto no grafo:** `E_PERSONALITY_SYNC_BUILT` SUPERSEDES `C_PERSONALITY_SEEDS`;
  `C_ADOPTER_PERSONALITY_SEEDS_PENDING` registra o resíduo real (6 dos 7 adotantes ainda seed-manual + 1 gated) —
  por-instância, não dívida do core. Gate humano do maestro (RFC-0003 §4) confirmou o retrato. Lint 0-HARD.

## Next crumb
Ver `next_recommended`. É o `declarado≠verificado` da [[declared-vs-verified-family]] fechando o loop sobre a
própria identidade, e mais um caso de [[fix-must-become-mechanism]] — só que aqui o "fix" é epistemológico
(a identidade emerge, não se declara). Irmã de [[mechanism-beats-prose]] (a durabilidade vem de onde a coisa
foi parar — aqui, no grafo/diário, não na prosa do seed). Rollout aos adotantes é por-instância (gated na
sessão de cada um), anunciado downstream.
