---
title: "Checagem #3 do core — escopo + status honestos do PR"
category: discussion
status: escopo-checagem-3-core
date: 2026-07-12
branch: docs/onion-guardrails
responde: docs/evolution/inbound/_processed/2026-07-12-boletim-core-pre-pr.md (checagem #3)
---

# Checagem #3 — o que o PR promove (e o que NÃO)

> **Pedido do core:** *"Escopo + status honestos. O que exatamente o PR promove (espinha KB? taxonomia?
> proto?); marca `candidato` onde é candidato. Doutrina ganha core **por uso**, não por estar pronta."*

Aplicando a doutrina "ganha core por uso": o **primeiro PR é mínimo e docs-only** — promove a **doutrina como
KB `candidato`**, nada que mude comportamento. O código (R15) e o wire-in ficam para um segundo passo,
**depois** do cross-review e por uso, não agora.

## ✅ O que ESTE PR promove

| Artefato de origem | Vira, no core | Status |
|--------------------|---------------|--------|
| `kb-spine-onion-guardrails.md` | `docs/knowledge-base/concepts/onion-guardrails.md` | **`candidato`** ✅ criado |
| `taxonomy-onion-r.md` (148 read-paths) | **FICA como evidência de discussão linkada — NÃO entra no core ainda** | (refinamento A2) |

> **Refinamento dirigido pela checagem #2/A2:** um catálogo de `arquivo:linha` no core **sem gate anti-drift**
> violaria ONION-R1. Então só o **concept KB** (que referencia gates **por nome** — resiliente a drift) é
> promovido; a taxonomia detalhada fica linkada como evidência até a promoção amarrar o gate anti-drift. É
> mais conservador que o rascunho original desta #3 — na direção certa (menos-no-core-primeiro).

**Natureza:** docs puros, **zero mudança de comportamento**, zero código novo no runtime. É a moldura/lente +
a taxonomia (índice sobre gates que já rodam). Segue a convenção `status: candidato` que a KB
[`authorization-layers`](../../knowledge-base/concepts/authorization-layers-intake-vs-execution.md) já usa.

## ❌ O que este PR NÃO promove (e onde continua)

| NÃO entra | Por quê | Onde continua |
|-----------|---------|---------------|
| Helpers R15 (`onion-untrusted-wrap.sh`, `onion-effect-gate.sh`) | protótipo em quarentena, não wired | `docs/discussions/…/prototype/` (registro de design) |
| Wire-in R15.1/R15.2/R15.3b (cerca, constituição, gate nos consumidores) | muda comportamento — precisa do cross-review + gate anti-drift | plano §Fases 2-5 |
| Qualquer reivindicação "cobre OWASP LLM0X" como fato | é **provisório** até uso | marcado provisório no corpo |
| Comando `/meta:guardrails` (superfície) | questão índice-vs-DSL ainda aberta (fio #4) | fora de escopo |
| O "75%→0%" como capacidade ativa | é dogfood de protótipo (N=4, direcional) | fica em `prototype/`, citado como evidência-de-design, não capacidade-do-core |

## Honestidade de status (as marcas explícitas no corpo do PR)

- **`candidato`**, não `estável` — a doutrina entra pra ganhar core **por uso**; a promoção não afirma maturidade.
- **R15 = desenhado + prototipado, NÃO wired** — dito com todas as letras; nada finge estar ligado.
- **Cobertura de mercado = provisória** — as 4 entradas OWASP com lastro (LLM03/04/06/09) são reais; as
  demais são lacuna/delegação, não cobertura.
- **Auto-drift conhecido** (checagem #2/A2) — a taxonomia precisa de gate anti-drift próprio na Fase 1; a KB
  o declara em vez de esconder.
- **Nem tudo é guardrail de segurança** — R1/R7/R12 são gates de qualidade; a taxonomia separa os dois.

## Escopo em uma linha (pro título/corpo do PR)

> **`docs(kb): onion-guardrails — camada de guardrails nomeada (candidato, docs-only)`** — promove a moldura +
> taxonomia como KB `candidato`; sem código, sem wire-in, sem reivindicação de capacidade ativa. R15 e a
> materialização ficam para passos gated posteriores, pós cross-review. As 3 checagens do core (reconciliação,
> refutador, escopo) estão fechadas no registro de discussão.

## Transição de branch (mecânica, pós-#3) — ✅ FEITA

`discuss/guardrails-nemo-lens` → **`docs/onion-guardrails`** (é doutrina/KB, não feature de código → prefixo
`docs/*`, não `feat/*`) — renomeada local + remoto, ref antigo removido. O corpus de discussão viaja junto como
**registro de design** (rastreabilidade pesquisa→taxonomia→R15→checagens).

## O fluxo daqui é o CANÔNICO do core (não improviso)

O plano de promoção é o **o quê**; o **como** é o fluxo faseado do core `…→ pre-pr → pr`:
- **`/engineer:pre-pr`** — fan-out dos 4 branch-agents (metaspec/code/docs/test) → relatório único; termina
  **pedindo a permissão do maestro** antes do PR (o gate humano é do core, não meu).
- **`/engineer:pr`** — abre o PR via **adapter forge** (nunca `gh` cru), base resolvida por
  `resolve-integration-branch.sh`, assinatura Onion no corpo.
- **+ camada de co-evolução (o "O NÓS"):** chamar o core-próprio pro **cross-review** antes do merge — isto
  NÃO é do pre-pr/pr canônico; é o gate extra que o boletim pediu porque a mudança afeta o core.
