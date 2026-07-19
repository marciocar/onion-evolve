---
title: 'ADR — Topologia da porta Claude: desfazer o colapso porta pública ↔ core privado'
date: 2026-07-19
type: adr
status: aceito — D2 RESOLVIDA (2026-07-19) por onion-adr-family-repo-topology-2026-07.md em favor de B-via-adopt
decision-scope: meta / família-onion / distribuição / topologia-de-repos
supersedes: none
extends: onion-adr-mini-distillation-2026-07.md
deciders: maestro + sessão de investigação (rescue-adopters-core-vs-hub)
context_freshness: 2026-07-19
related:
  - docs/knowledge-base/concepts/public-door-vs-private-core.md (a doutrina que este ADR aplica)
  - docs/knowledge-base/concepts/source-vs-derivation.md (fonte≠derivação — a mãe da doutrina)
  - docs/evolution/federation/members.yaml (Q_COLD_ADOPTER; registro dos adotantes)
  - docs/analysis/onion-plugin-marketplace-runbook-2026-07.md (o marketplace aponta p/ onion-evolve)
---

# ADR — Topologia da porta Claude

> **Status: PROPOSTO (2026-07-19).** A investigação verificou o modo de falha e propõe o caminho;
> a escolha entre D2-A e D2-B (e o gatilho de D2-B) é **ratificação do maestro**. Nada de adotante
> é tocado por este ADR — os adotantes existentes estão corretos (ver Contexto §3).

## Contexto

A sessão nasceu de uma premissa: *"adotantes baixaram o onion-evolve como core quando deveriam
apontar para o hub público `marciocar/onion`; resgatá-los."* A investigação (evidência abaixo)
**refutou a premissa como enunciada** e revelou o problema real.

### 1. Verificação ao vivo (via `gh`, 2026-07-19)

| Repo | Visib. | Último push | Papel |
|---|---|---|---|
| `onion-evolve` (≡ redirect de `onion-claude`) | 🔒 **PRIVATE** | diário | core vivo — a fonte |
| `onion` (hub) | 🌐 public | **congelado 2026-06-04** | meta/história das 6 portas |
| `onion-cursor/codex/copilot/zed/antigravity` | 🌐 public | congelados 2026-06-04 | 5 destilações públicas |
| `onion-mini` | 🌐 public | 2026-07-06 | destilação de entrada |

### 2. Os dois colapsos

1. **Porta↔core:** `onion-claude` — a porta pública Claude que o README do hub anuncia — **foi
   renomeada e virou o core privado `onion-evolve`** (a API do GitHub resolve `onion-claude` →
   `onion-evolve`, PRIVATE). A porta pública Claude **não existe**: quem a segue cai num repo privado.
2. **Vitrine congelada:** hub + 5 portas empurrados uma vez (04-06) e nunca mais — o rosto público
   descreve um estado de ~6 semanas atrás.

Isto é a doutrina [`porta ≠ core`](../knowledge-base/concepts/public-door-vs-private-core.md) violada
na topologia real, e [`declarado ≠ verificado`](../knowledge-base/agentic-patterns/ai-strategies/verify-read-path-first.md)
aplicado ao **marketing público** da família.

### 3. Por que a premissa estava invertida (os adotantes estão certos)

Todo SSOT converge: `members.yaml` ("Fonte canônica: o core (onion-evolve)"), `onion-version.sh`,
o marketplace de plugins (`/plugin marketplace add marciocar/onion-evolve`) e a ADR
[mini-distillation §D2](onion-adr-mini-distillation-2026-07.md) declaram **onion-evolve como a
fonte**; o hub `onion` é **derivação/vitrine** ("prova de universalidade"). Os adotantes locais
(granaai, pulse-mais, metagamify, gustavo-pulga) vendorizam `.claude/` do core vivo — **têm acesso,
é a fonte, e o regulado quer vendoring deliberado**. "Vendoriza do core" ≠ "preso a um fork de
incubação". A condição da premissa só existiria para um **cold-adopter externo** — o thread
`Q_COLD_ADOPTER`, já aberto em `members.yaml`.

## Decisões

### D1 — Nomear o colapso (aceito)
`onion-claude` **é** `onion-evolve` (alias de rename, PRIVATE). Não é, e não deve ser tratado como,
uma porta pública. A doutrina [`porta ≠ core`](../knowledge-base/concepts/public-door-vs-private-core.md)
passa a ser a casa canônica dessa fronteira.

### D2 — Destino da porta pública Claude (**RESOLVIDA 2026-07-19 → B via adopt**)

> **Resolução:** o maestro ratificou o desmembramento da família em repos próprios
> ([ADR family-repo-topology](onion-adr-family-repo-topology-2026-07.md)). A porta Claude passa a ser
> uma **instância adotada** (`/meta:adopt` role-scoped numa pasta vazia) — não um espelho read-only.
> Isto é a **Opção B reformulada via adopt**: `onion-standalone` é o repo público adotável, `onion-claude`
> = mesmo código (mirror), e o redirect re-aponta para a standalone pública. As opções A/B abaixo ficam
> como registro do raciocínio original.

**Opção A — Aposentar a pretensão de porta-Claude-standalone (recomendada agora).**
A entrada pública Claude passa a ser, explicitamente: **Onion Mini** (já público) para iniciantes +
**`/meta:adopt` a partir do core privado** (adoção assistida, acesso concedido) para adoção plena.
O hub para de anunciar `onion-claude` como porta pública separada e reescreve a "porta Claude" como
"Mini (público) + core (privado, adoção assistida)".
- *Fiel a "core Claude-Code-only, não-distribuído" (`CLAUDE.md`).* Zero infra nova. Corrige a mentira
  imediatamente (o hub não pode anunciar repo privado como porta pública).

**Opção B — Publicar uma porta pública `onion-claude` destilada/read-only (gated).**
Um espelho/destilação público sincronizado do core privado, simétrico às 5 portas de plataforma.
- Restaura a simetria "6 portas públicas" da tese de universalidade. Uma porta destilada **não** é
  distribuir o core — é publicar uma **derivação** ([`fonte ≠ derivação`](../knowledge-base/concepts/source-vs-derivation.md)),
  como Cursor/Codex/etc já são. Custo: mecanismo de sync core→porta + manutenção.

**Recomendação:** **A agora** (correção da face pública é urgente e barata), com **B `gated-until-trigger`**
— só materializa quando um **cold-adopter externo real** aparecer (`Q_COLD_ADOPTER`). Coerente com a
doutrina [`gated-until-trigger`](../knowledge-base/concepts/onion-modernization-doctrine.md): o
artefato (porta pública mantida) nasce do uso que o prove, não da simetria.

### D3 — Vitrine congelada: datar ou refrescar (aceito, faseado)
No mínimo, **datar** o hub + as 5 portas ("snapshot de 2026-06-04") para não enganar por omissão.
Refresh completo é **gated** (destilar do estado atual — trabalho das verticais de cada porta,
alinhado à rampa M3 da [mini-distillation](onion-adr-mini-distillation-2026-07.md)).

### D4 — Higiene de registro (aceito, executado nesta sessão)
`gustavo-pulga` tinha stamp `adopted_from: onion-evolve` mas **não estava** em `members.yaml`.
Registrado como `role: standalone`, pin `c9eb2c40bc3b` **verificado** por `pin-integrity-check.sh`
(pin-ok, 2026-07-19) — respeitando o invariante "pin só entra verificado".

## Consequências

- **A premissa "resgatar adotantes" não gera trabalho de re-apontamento** — gera **doutrina**
  (`porta ≠ core`) + **correção de face pública** (D2/D3) + **higiene** (D4).
- **Não vira "comando de resgate".** Não há lineage a re-apontar; há topologia a corrigir. Um comando
  só se justificaria se D2-B graduasse (aí: automação do sync core→porta).
- **Q_COLD_ADOPTER ganha uma resposta parcial:** hoje, entrada pública = Mini + adopt assistido; porta
  pública dedicada é gated ao 1º cold-adopter.

## Rampa (estado)

| Fase | O quê | Estado |
|---|---|---|
| P0 | Investigação + doutrina `porta ≠ core` + este ADR | ✅ 2026-07-19 |
| P1 | D4 — registrar gustavo-pulga em `members.yaml` | ✅ 2026-07-19 |
| P2 | D2 — maestro ratifica A (e o gatilho de B) | ⏳ aguarda ratificação |
| P3 | D3 — datar hub + 5 portas ("snapshot 06-04") | ⏳ gated (repos públicos, fora desta árvore) |
| P4 | D2-B — porta pública destilada | ⏳ gated até 1º cold-adopter externo (`Q_COLD_ADOPTER`) |

## Referências

- Doutrina: [`public-door-vs-private-core.md`](../knowledge-base/concepts/public-door-vs-private-core.md)
- Fonte da tese: [`source-vs-derivation.md`](../knowledge-base/concepts/source-vs-derivation.md)
- Registro/threads: [`members.yaml`](../evolution/federation/members.yaml)
- Distribuição: [`onion-adr-mini-distillation-2026-07.md`](onion-adr-mini-distillation-2026-07.md) · [`onion-plugin-marketplace-runbook-2026-07.md`](onion-plugin-marketplace-runbook-2026-07.md)
