---
title: 'RFC-0001 — Co-evolução e comunicação core ↔ derivados'
status: accepted (modelo dos 3 fluxos; doc-bridge leve, Federação como graduação)
canonical-in: onion-evolve (core) — fonte da série de RFCs de co-evolução
drafted-in: rhilo-metagamify (sala de obra, 2026-06-17) → promovida ao core (2026-06-18)
supersedes-reference: rhilo-metagamify/docs/evolution/rfc/rfc-0001-co-evolution-comms.md (vira referência)
defers-to: RFC-0002 (veredito profundo da doutrina catálogo-first)
---

# RFC-0001 — Co-evolução e comunicação core ↔ derivados

## 1. Contexto e escopo

O **Onion core** (`onion-evolve`, "sala de design") e os **projetos que o adotam** (derivados, ex.
`rhilo-metagamify`, "salas de obra") precisam **co-evoluir com método**, sem comunicação viva entre
instâncias de IA. Este RFC **fixa o modelo de comunicação**; o **guia operacional** (ritual, estrutura de
diretórios) vive no [`../README.md`](../README.md).

**Não-objetivos:** runtime IA-fala-IA (A2A); aceitar/rejeitar a doutrina catálogo-first (= RFC-0002);
construir infra de federação pesada antes de se pagar.

## 2. Decisão — modelo de 3 fluxos (híbrido, git-async, maestro humano)

> **Vocabulário canônico (2026-06-24):** os fluxos têm **nome próprio** — **downstream**, **upstream**,
> **handoff** — no lugar dos rótulos opacos *flow/fluxo A/B/C* (retirados; regra "rotular referências
> opacas", code-standards §7). Ver [ADR de vocabulário](../../analysis/onion-adr-coevolution-flow-naming-2026-06.md).
> Entradas antigas (`CHANGELOG.md`, `*/_processed/`) **preservam** "flow A/B" — são append-only/auditoria
> (invariante I7), não se reescrevem.

1. **Downstream · Core → projetos** _(ex-flow A)_: registro (`../federation/members.yaml`) + pin de versão
   (`.claude/.onion-version`) + log de anúncio (`../federation/CHANGELOG.md`). Projeto adota via
   `/meta:adopt --update`. = manifest-pinning.
2. **Upstream · Projetos → core** _(ex-flow B)_: `../inbox/` — qualquer projeto deposita sinal/bug/
   pedido-de-ajuda/status como markdown commitado. É o loop que evolui o framework a partir do uso real.
3. **Handoff · Dentro de um repo (sessões paralelas)** _(ex-flow C)_: git worktrees + um escritor por
   escopo + handoff commitado. (Eixo distinto: é **concorrência intra-repo**, não direção cross-repo.)

O **humano é o maestro** que roteia downstream e upstream entre repos. **System-of-record:** doc-bridge (markdown
commitado) agora; **Federação Onion** (`/meta:federation-*`, já implementada) é a **graduação** — ligar
quando houver contrato quebrável ou nº de projetos que torne o roteamento manual custoso (ver gatilho no
README).

## 3. Por que híbrido e não A2A-runtime

Atomicidade multi-repo não existe no git; **veto-no-silêncio + auditoria append-only** são mais seguros
que IA-fala-IA. O A2A (v1.2, Linux Foundation, prod em 150+ orgs) é maduro para **cross-org enterprise**,
mas é peso desnecessário aqui — fica `hold` no runtime, `assess` no formato (Agent Card como projeção
one-way do manifesto, se um dia).

## 4. Ownership

O **core é dono** do protocolo e da **série de RFCs** de co-evolução. Projetos **referenciam/respondem**
(não mantêm série própria). Esta RFC foi rascunhada na sala de obra e **promovida ao core como canônica**;
a cópia no `rhilo-metagamify` passa a ser **referência/resposta**.

## 5. Grounding externo (2026 — sólido vs experimental)

| Item | Estado real (2026) | Posição Onion |
|---|---|---|
| MCP (tool/contexto) | padrão sob Linux Foundation AAIF | `adopt` |
| A2A (coordenação; v1.2, 150+ orgs) | maduro p/ enterprise cross-org | formato `assess`, **runtime `hold`** |
| Meta-repo / manifest-pinning | padrão validado | o registro Onion **é** isto |
| Drop-box (estado commitado no repo) | GitHub Squad; async > tempo-real | **adotado** (inbox + handoff) |
| Orquestração-não-autonomia | consenso 2026 | **adotado** (maestro humano) |
| Multi-agente autônomo pleno | ainda experimental | fora de escopo |

## 6. Em aberto

- ~~**RFC-0002:** veredito da doutrina catálogo-first contra o `.claude/` real.~~ ✅ **Entregue (2026-06-22)** — ver [rfc-0002-meta-strategy-verdict.md](rfc-0002-meta-strategy-verdict.md).
- Automatizar a cópia `inbox` derivado→core (hoje manual/maestro) — só quando a Federação plena ligar.
