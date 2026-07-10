---
date: 2026-07-09
instance: onion-evolve
type: decision
classification: public
tags: [federation, rfc-0004, single-source, git-async, a2a-live, gated, orchestrated-research, dogfood]
affects: [federation, meta, transport]
breadcrumb_for: [meta:co-evolve, meta:co-announce, meta:evolve]
share_with: [collective]
next_recommended: "2026-07-09-scope-inheritance-rfc0005"
review_after: 2026-10-07
conflict_class: static
---

## Signal
O redesign da federação saiu de discussão para **doutrina decidida**: **RFC-0004 ACCEPTED** (#306) —
**single-source SSOT p/ identidade+contratos + mesh de comunicação git-async + `a2a-live` GATED (fase-2)**.
Gatilho real: o git-async **atrapalhava** (Grana.Ai isolada num nx monorepo regulado; frota local com ruído;
sem console/mapa). O corte é por **natureza-do-dado** (CAP: recurso-exclusivo=single-writer vs
estado-colaborativo=replicação otimista — e o git-async do Onion **já É** replicação otimista canônica).
Grana.Ai = **data-plane subordinado** (padrão Argo CD Agent), NÃO `role:source`.

## Evidence
- **Decidido por pesquisa orquestrada** (2 rodadas, 18 agentes, ~1,2M tokens, verificação adversarial):
  `docs/evolution/research/federation-2026/`. `declarado≠verificado` aplicado ao insumo — estatística MCP
  30%→5,5%; S1.F8 (AAIF↔A2A) **refutado**; S2.F11 (CRDT) confirmado firmando o veredito.
- **Moat preservado na decisão:** aceitação segue **gated** (members.yaml = policy-as-data); a2a-live só
  **sinais gated** (A2A não protege prompt-injection cross-agent); `never-live-pull` p/ regulados;
  `pin-integrity` = verificar-antes-de-agir. Descoberta governada em escala = não-resolvida no mercado (G2)
  → manter gated+curado.
- **Fase 1 SHIPPED dogfood-first, reusando fundações** (selftest 178→198): F1.1 (#307) `graph.sh` ingere
  `members.yaml` → `--map`; F1.2 (#310) targeting fino `resolve-target.sh` (mata o ruído; reusa
  `graph --triples`); F1.3 (#311) console estático **DEPLOYADO live** em https://onionevolve.com/federacao/;
  F1.4 (#312) `mail-receiver.sh` (avisa via ntfy, git-async intacto).
- **Fase 2 aberta SEM canal vivo:** F2.1 (#313) `federation-transport` SDAAL (`git-async|local|a2a-live`,
  a2a-live é stub GATED) — enquadra a fase gated antes de escrever endpoint.

## Next crumb
Revisa RFC-0001 (git-async: de invariante → **default-com-exceção-gated**). Gatilho de revisão da própria
RFC-0004: **2º hub escrevendo identidade concorrente** desconectado. Restante do roadmap: só **F2.2** (endpoint
a2a-live no bridge) — o grande/arriscado, exige **gate humano + dogfood** antes de tocar `bypassPermissions`.
Ver [[2026-07-09-scope-inheritance-rfc0005]] (RFC-irmã, mesma leva) e [[2026-07-01-federation-usage-modes-decision]].
