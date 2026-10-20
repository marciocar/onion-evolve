---
date: 2026-07-18
instance: onion-evolve
type: decision
classification: collective
tags: [doctrine-ingestor, co-evolution, trust-gate, kg-backed, federation, aggregator]
affects: [meta, co-evolution]
breadcrumb_for: []
share_with: [granaai, metagamify]
next_recommended: "Fase 3 do plano: 1a federation.kg.yaml de producao (domain) — a foto da federacao como KG (extrator = reconcile-inputs.sh; radar = core nao surpreendido). F0-F2 e devolucao FEITOS."
review_after: 2027-01-18
conflict_class: static
---

## Signal
Nasceu **o ingestor de doutrina** — o elo que faltava na cadeia adotante→core. A metade produtora+transporte já existia (`diary` → `export-sharable` → `co-relay`/a2a-live → gate `trust:`); a **ingestora estava vazia**: o "agregador que ingere com política" foi nomeado e nunca construído; `/meta:co-evolve` **tria** um sinal mas **não absorve** doutrina estruturalmente. O padrão: o core absorve doutrina de campo por absorção **curada · trust-gated · KG-backed · human-gated** — o **precursor curado** da síntese coletiva (RFC-0003 F4, gated), não o cron automático. É aceitação-gated (mesmo moat da RFC-0004/merge_authority): nada se impõe na superfície de quem tem a palavra final; aqui a superfície é a doutrina do core, o gate é o trust + o maestro.

## Evidence
- ADR: `docs/analysis/onion-adr-doctrine-ingestor-2026-07.md` (nomeia o padrão: trust-gate → KG-backed → aterrissagem por tipo → human-gated).
- 1º dogfood — 4 sinais de KG do granaai modelados em `docs/onion/graph/granaai-doctrine-absorption-2026-07.kg.yaml` (13 nós, 11 arestas, `kg-radar` exit 0, `SUPERSEDES` do S2 na reconciliação).
- Doutrina absorvida no KB `docs/knowledge-base/concepts/knowledge-graph-sdaal.md`: **S1** (integridade técnica ≠ completude de rastreabilidade) + **S3a** (validador local delega ao radar soberano). S3b/S4 → backlog; S2 → superseded (já em `kg-radar.sh:120-139`).
- Trust-gate autorizou: granaai `can_correct_to: [onion-evolve]` (`docs/evolution/federation/members.yaml:178` em 2026-10-20; era a l.154 em julho).
- **Estado em 2026-10-20 (re-teste):** a Fase 3 do `next_recommended` foi feita, mas não como `domain`: a foto da
  federação virou `docs/onion/graph/federation-health-2026-07.kg.yaml`, um overlay AUDIT de saúde de verificação
  mais um radar de federação. O próprio grafo registra o achado (l.216): adopts/trust não cabem nas arestas de
  domínio. A selagem de sinais entrantes foi mecanizada depois em `/meta:kg-inbox`.
- Diagnóstico completo: exploração orquestrada 3-streams em `docs/evolution/research/doctrine-sync-ingestor-2026-07/SYNTHESIS.md`.

## Next crumb
Para absorver doutrina de um adotante: **(1)** checar `trust.can_correct_to`/`can_advise_to` inclui `onion-evolve` (sem trust → não absorve, fail-safe); **(2)** modelar a doutrina entrante como `.kg.yaml` audit — `evidence`(sinal, `arquivo:linha`) → `claim`(doutrina) → `decision`(absorver|backlog|superseded), radar exit 0; **(3)** aterrissar por tipo — doutrina→KB, feature→backlog, já-feito→superseded (com `SUPERSEDES`); **(4)** soberania: absorve o **princípio/método**, nunca o **código** do adotante; **(5)** human-gated + `declarado≠verificado`. Quando houver 3+ instâncias com diários maduros, este ingestor curado generaliza para `/meta:synthesize-collective` (F4, automático).

## Re-testada em 2026-10-20 — PARCIAL: (static) o ADR e o grafo de absorção existem, e o trust do granaai segue `can_correct_to: [onion-evolve]` (`members.yaml` l.178). O Evidence foi atualizado com a Fase 3 feita (como overlay AUDIT, não como `domain`) e com o ponteiro de linha novo.
