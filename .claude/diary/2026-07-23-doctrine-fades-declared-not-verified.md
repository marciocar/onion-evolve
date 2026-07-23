---
date: 2026-07-23
instance: onion-evolve
type: error
classification: collective
tags: [world-sync, freshness, declared-vs-verified, fabrication, doctrine, model-tiering]
affects: [meta, engineering, compliance, product]
breadcrumb_for: []
share_with: []
next_recommended: "Toda KB que publica lineup/versão/teto sensível ao tempo entra na lista world-facing do doctrine-freshness.sh (REGRA 42) com verified_at + source — nunca confie em 'parece fina, deve estar certa'. Quando encontrar uma citação entre aspas numa KB, tratá-la como suspeita até re-confirmar contra a fonte primária; aspas fabricadas passam despercebidas justamente porque têm a forma de verdade."
review_after: 2026-10-21
conflict_class: static
significance: "O world-sync de hoje achou um tier de modelo inteiro que a doutrina não sabia existir e aspas fabricadas na própria KB de inferência — e essa descoberta é o que pariu a REGRA 42, não uma auditoria de rotina."
---

## Signal
**Doutrina que "parece fina" apodrece em silêncio.** O world-sync de 2026-07-23 confrontou a KB de
tiering/orquestração contra fontes primárias e achou três classes de erro que nenhum gate cobria: um tier
inteiro ACIMA do Opus (Mythos-class, com Fable 5 GA) que a doutrina desconhecia, tetos de sessão inferidos
errado, e ASPAS FABRICADAS dentro da própria KB de mitigação de inferência. Lembrar de verificar não escala;
só uma forcing function escala.

## Evidence
- **Tier Mythos-class acima de Opus:** a doutrina de orquestração/model-tiering tratava Opus como o teto;
  o world-sync (commit `77b701d`) confirmou um tier Mythos-class superior (Fable 5 GA; Mythos 5 restrito a
  organizações específicas), com regra de 3 passos (GA no mercado ≠ habilitado na conta ≠ grátis na margem).
- **Tetos de sessão corrigidos:** a alegação "o teto de sessão bate antes do teto de run" era FALSA — a
  correção importa mais que o fato em si (registrada no próprio commit, não silenciosamente substituída).
- **Aspas fabricadas na KB de inferência:** a KB `inference-mitigation.md` (a mesma que fechou P5 no core,
  `91d5dbb`) continha citação entre aspas que não existia na fonte — achada só porque alguém confrontou
  contra a fonte primária, não porque um gate cobrava isso.
- **Nenhum mecanismo cobrava frescor antes disso:** o KG-SSOT tinha forcing function em LEITURA (catch-up,
  kg-radar, STALE-TRACE) mas nada forçava a doutrina em PROSA a se re-verificar contra o mundo — o mesmo
  buraco espacial que a REGRA 29 fechou (conhecimento nascendo fora do grafo), aqui no eixo temporal.
- **O achado pariu a REGRA 42** no mesmo dia (`44d7e05`) — ver [[doctrine-freshness-ratchet-composed-not-new]].

## Next crumb
Ver `next_recommended`. A lição não é "seja mais cuidadoso" (não escala) — é que doutrina world-facing
precisa de TTL + verified_at obrigatórios, cobrados por mecanismo, não por memória. Ver
[[doctrine-freshness-ratchet-composed-not-new]] (o gate que nasceu disso) e
[[runflow-doctrine-freshness-proves-value-day-one]] (a prova em produção, no mesmo dia).
