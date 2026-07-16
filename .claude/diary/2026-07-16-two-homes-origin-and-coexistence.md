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
review_after: 2026-10-14
conflict_class: static
---

## Signal
**Origem real do lar atual** (revelação do maestro, 2026-07-16): o notebook **Avell A70** queimou o jack de
energia e foi ao conserto **com trabalho não-commitado do Onion core**. Por isso a **VPS Hostinger KVM 8**
(`srv1812846`) foi alugada e o framework passou a **residir nela**. O maestro estava me evoluindo (o Onion
Evolve) **localmente** quando a máquina quebrou. Agora quer as duas casas **coexistindo em conhecimento**
sobre **um repo**.

## Decision (modelada ssot-first — o veredito saiu do radar, não da prosa)
Grafo: `[[coexistence-two-homes-2026-07]]` (`docs/onion/graph/`), `kg-radar` limpo (13 nós/13 arestas):
- **origin (GitHub) = fonte única; git é o elo.** Tudo in-repo (código, **diário**, **KG**, sessions, docs)
  coexiste de graça — o repo **já é** o cérebro compartilhado. Única lacuna: memória machine-local (fora do repo).
- **Papéis assimétricos:** VPS = casa **primária always-on** (federação/carteiro/cron); Avell = **workstation
  móvel**. Um origin, dois workspaces (evita "dois mestres divergem").
- **Memória = HÍBRIDO:** fica local (rascunho por-máquina); o **durável promove pro diário/KG in-repo**.
  Sincronizar o dir cru foi **`REFUTED`** pelo limiar Hegel (20 arqs estáveis, abaixo do monotônico +
  conteúdo pessoal) — over-engineering.
- **Disciplina de 2 instâncias vivas:** `git fetch`/`pull` antes de evoluir (cabeado no co-evolve v1.4.0),
  um-escritor-por-branch, beacon por-working-tree → coordenação **via commit**, não presença.

## Meta-aprendizado (a sessão que provou o dogfood em mim)
O maestro perguntou "estamos fazendo ssot-first?" no meio desta decisão — e a resposta honesta era **não**:
eu vinha respondendo de prosa. **A própria reincidência que o sinal metagamify denuncia**, em mim, minutos
após eu cabear o mecanismo (que vive nos comandos de loop, não no chat livre). A correção foi **modelar a
decisão como `.kg.yaml` e deixar o radar decidir** — foi assim que o `REFUTES` do sync-cru apareceu sozinho.
Lição: sem forcing function, o default é prosa; **este KG in-repo é o SSOT que coexiste nas 2 casas por
construção** (a resposta se comendo).

## Next crumb
Resgate do não-commitado do Avell (cápsula pré-VPS): capturar em `rescue/avell-uncommitted-2026-07` **antes**
de sincronizar; da VPS, diff vs `main` e reaplicar só o relevante. Ver plano da coexistência.
