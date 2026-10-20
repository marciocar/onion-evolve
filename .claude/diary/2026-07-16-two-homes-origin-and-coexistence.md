---
date: 2026-07-16
instance: onion-evolve
type: decision
classification: protected
tags: [origin, coexistence, two-homes, avell, vps, ssot-first, memory, kg]
affects: [identity, infra, method]
breadcrumb_for: [catch-up, warm-up, meta:kg]
share_with: []
next_recommended: ""
review_after: 2027-01-18
conflict_class: static
---

## Signal
**Origem real do lar atual** (revelação do maestro, 2026-07-16): o notebook **Avell A70** queimou o jack de
energia e foi ao conserto **com trabalho não-commitado do Onion core**. Por isso a **VPS Hostinger KVM 8**
(`srv1812846`) foi alugada e o framework passou a **residir nela**. O maestro estava me evoluindo (o Onion
Evolve) **localmente** quando a máquina quebrou. Em julho ele quis as duas casas **coexistindo em conhecimento**
sobre **um repo**.

**Estado em 2026-10-20 (decisão do maestro no re-teste):** o Avell **não é mais casa**. O lar é **só a VPS**
(`srv1812846`; `members.yaml` l.36-37: "lar ÚNICO: dev + site + bridge"). Os princípios abaixo (origin é a
fonte, `git fetch` antes de evoluir, memória híbrida) valem para uma casa só e para qualquer clone futuro.

## Decision (modelada ssot-first — o veredito saiu do radar, não da prosa)
Grafo: `[[coexistence-two-homes-2026-07]]` (`docs/onion/graph/`), `kg-radar` limpo (13 nós/13 arestas):
- **origin (GitHub) = fonte única; git é o elo.** Tudo in-repo (código, **diário**, **KG**, sessions, docs)
  coexiste de graça — o repo **já é** o cérebro compartilhado. Única lacuna: memória machine-local (fora do repo).
- **Papéis assimétricos (superado em 2026-10-20):** em julho, VPS = casa primária always-on e Avell = workstation
  móvel. O Avell saiu e a VPS é o lar único. Fica a regra de fundo: um origin, nunca dois mestres.
- **Memória = HÍBRIDO:** fica local (rascunho por-máquina); o **durável promove pro diário/KG in-repo**.
  Sincronizar o dir cru foi **`REFUTED`** pelo limiar Hegel (20 arqs estáveis, abaixo do monotônico +
  conteúdo pessoal) — over-engineering.
- **Disciplina de instâncias vivas** (hoje: sessões e worktrees na mesma VPS): `git fetch`/`pull` antes de evoluir (cabeado no co-evolve v1.4.0),
  um-escritor-por-branch, beacon por-working-tree → coordenação **via commit**, não presença.

## Meta-aprendizado (a sessão que provou o dogfood em mim)
O maestro perguntou "estamos fazendo ssot-first?" no meio desta decisão — e a resposta honesta era **não**:
eu vinha respondendo de prosa. **A própria reincidência que o sinal metagamify denuncia**, em mim, minutos
após eu cabear o mecanismo (que vive nos comandos de loop, não no chat livre). A correção foi **modelar a
decisão como `.kg.yaml` e deixar o radar decidir** — foi assim que o `REFUTES` do sync-cru apareceu sozinho.
Lição: sem forcing function, o default é prosa; **este KG in-repo é o SSOT que coexiste nas 2 casas por
construção** (a resposta se comendo).

## Next crumb
O resgate do não-commitado do Avell foi feito (PR #394; ver `2026-07-16-avell-rescue-doc-predicted-session`).
Antes de evoluir, `git fetch` (cabeado em `co-evolve.md` l.51). Se um dia surgir uma 2ª máquina, ela entra como
clone de `origin`, não como 2º mestre.

## Re-testada em 2026-10-20 — PARCIAL: (static, contra a melhor fonte atual + decisão do maestro) os princípios valem: `members.yaml` l.36-37 declara a VPS como lar único, e `co-evolve.md` l.51 manda `git fetch` antes de ler o inbox. A 2ª casa saiu do texto: o maestro respondeu em 2026-10-20 que o Avell não é mais casa.
