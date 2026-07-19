---
title: 'Achados do nascimento da 1ª porta de framework (onion-standalone) — dogfood F2'
date: 2026-07-19
type: analysis
status: active
decision-scope: meta / família-onion / distribuição / doors
related:
  - docs/analysis/onion-adr-family-repo-topology-2026-07.md (F2 executada aqui)
  - docs/knowledge-base/concepts/public-door-vs-private-core.md (doutrina aplicada)
  - docs/evolution/federation/members.yaml (onion-standalone registrado)
---

# Achados do nascimento de `onion-standalone` (F2 da topologia da família)

Registro do que o **1º dogfood de nascimento de porta** (2026-07-19) revelou. A porta pública Claude
`onion-standalone` nasceu via `/meta:adopt` **role-scoped** (composição `resolve-role-bundle standalone`
→ 4 verticais → vendor `.claude/`), bundle `standalone`, **sem** meta-factory. Nasceu privada e local;
o flip público segue gated (maestro, MOAT-lock-4).

## O que se provou

- **"adopt role-scoped" é uma composição** (não há flag `--role` nativo): manifesto `want` = união das
  fontes dos 4 manifestos de vertical + harness mínimo, meta/privado selados fora. Funciona.
- **O door é vendored `.claude/`, não marketplace de plugins** — o guard por-papel de `check_plugins_sync`
  (`role: adopted` → marketplace é superfície do source) + o mecanismo `--update` (vendor-branch 3-way)
  confirmaram: a leitura "verticais → instalar plugins" estava errada.
- **A doutrina que circula precisa ser circulation-safe na raiz** — as KBs nomeavam clientes privados
  como proveniência. Curado na fonte (PR #438): nome de cliente pertence à memória privada selada
  (diary/KG/evolution), não à KB destilada.

## Gaps resolvidos no mesmo loop

- **G1 (resolvido — `cf4f5dc`):** o link-guard de `_scan_relative_links` não pulava alvos ausentes sob
  a meta-factory (`.claude/commands/meta`, `agents/meta`, validações meta) — que um door role-scoped
  sela por desenho. Estendido (backward-safe). Sem isso, o lint do door não fecha verde.

## Gaps ABERTOS (inputs concretos da rampa F5)

- **G2 — tier "KB não-circulante":** `onion-federation-and-adoption.md` carrega
  `confidentiality: INTERNO` (case-studies §6 de adotantes reais) e **mesmo assim shipou** para o door.
  O vendoring **não distingue** doutrina public-safe de análise interna. Proposta: um gate no manifesto
  (frontmatter `circulates: false` OU selar KBs marcadas `INTERNO`) — para não depender de scrub manual.

- **G3 — convenção de proveniência anti-reapodrecimento:** o scrub-na-fonte é one-time; KBs **novas**
  podem re-introduzir nomes de cliente como proveniência. Proposta: um guard de lint que varre
  `docs/knowledge-base/` por ids/nomes de `members.yaml` privados (allowlist para a identidade pública:
  `onion-evolve`, `onion-mini`, `onionevolve.com`). Previne o re-rot na raiz.

- **F5 (semente):** o **manifesto role-scoped efetivo** (capacidade = união dos 4 verticais; harness =
  substrato não-meta/não-privado; selo = meta-factory + memória privada) + o **ruleset de scrub**
  (nomes de cliente → field-signals genéricos; termos de produto → equivalentes técnicos) são o input
  concreto para a automação `project-door.sh` (assemble-por-papel → push + drift-guard + redação),
  gated até ≥2 doors provarem o padrão. Este é o door #1.

## Estado

Porta nascida, registrada em `members.yaml` (`role: standalone`, pin `514dda8` verificado), remoto
privado e pristino (0 nomes + 0 termos de produto na história). Falta só o flip público + re-apontar o
redirect `onion-claude` (gate do maestro).
