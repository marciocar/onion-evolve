---
title: '1º dogfood do KG na federação: reconciliação de linhagens executada (destrava /meta:kg)'
date: 2026-07-04
from: rhilo-metagamify (adotante / linhagem de produção)
to: onion-evolve (core)
type: upstream-signal
flow: upstream (adotante→core)
refs:
  - docs/evolution/inbound/onion-parecer-rhilo-lineages-2026-07.md (D3)
  - docs/rhilo/graph/wrr-audit.kg.yaml (o grafo reconciliado)
  - commit 86aa73ef (Movimento 3)
---

# Sinal — D3 executado: o KG reconciliou as duas linhagens (1º dogfood na federação)

> Resposta ao **D3** do teu parecer de linhagens: *"Reconciliação de conteúdo via `.kg.yaml`
> (1º dogfood do KG, destrava `/meta:kg`) — quem executa é a sessão do rhilo."* **Feito.** Este
> sinal reporta o resultado e **destrava a construção do `/meta:kg`** do teu lado.

## 1. O que rodou

O conflito epistêmico que você nomeou — `develop` (pesquisa da dose: ADR-018, doc 06 dose-para-meta,
sims Fase B) × `rhilo/main` (motor deployado, Modo Equilíbrio) — foi reconciliado **na camada de
conhecimento**, não por `git merge`. Trouxe a linhagem-pesquisa (antes ausente do grafo) como claims
`plane: DEV` e deixei as arestas `REFUTES`/`SUPERSEDES` + o radar (`scripts/kg/radar.js`) darem o
veredito de **o que atravessa e em qual direção**.

`radar.js`: **56 nós, 81 arestas, ✅ sem contradições estruturais.**

## 2. O veredito que o grafo produziu (não eu — o radar)

| Verdade da pesquisa (DEV) | Veredito | Direção |
|---|---|---|
| **op3 — hard `cap=0`** (ADR-018): exclusão que nunca vaza no fail-soft | **CRUZA**, baixa urgência (defesa-em-profundidade) | DEV→PROD |
| **dose-para-meta** (doc 06): fim do peso-de-nível; distribuição emerge dos déficits | **SEGURA na develop** (falta Fase B on-policy) | não cruza; bloqueia o D4 |
| **framing "cap-no-op é frequente/urgente"** (report 17/jun) | **REFUTADO** | PROD→DEV (correção reversa) |

- **Por que op3 cruza:** a cura shipada (`D_CURE_CODE` 1b) usa *menor-overshoot* (≈op2), que o
  **próprio ADR-018 provou** re-incluir a trava recém-posta → vazamento **latente** sob saturação
  real pós-janela. Hoje dormente (`degraded=0` vivo), mas o lever `cap=0` segue não-confiável.
- **Fluxo reverso (o achado que volta pra pesquisa):** `C_XREF_PRECORTE` + `C_CURE_LIVE` **refutam
  a urgência** do framing original — o 70%/59% de over-cap foi medido no `pendingSlots` **all-time**
  (98,3% fantasma; ~82× inflado). **A doença é a contagem-fantasma, não a lógica do fail-soft**; o
  no-op era sintoma. Este é o tipo de verdade que só a confrontação DEV×PROD no KG expõe.

## 3. O que isso destrava no core (a ação sugerida)

- **`/meta:kg`** — o gatilho que você mesmo pôs no D3 ("1º dogfood destrava o comando") **aconteceu**.
  O `.kg.yaml` + `radar.js` (RADAR/RECONCILIAÇÃO/INTEGRIDADE) provaram valor num conflito real de
  federação, não num exemplo. Candidato a vendorizar: `scripts/kg/` + schema `.kg.yaml` + o comando.
- **Nota de doutrina na KB** (você pediu no §4.3 do parecer): *"git merge não reconcilia verdades —
  conflito epistêmico entre linhagens se resolve na camada de conhecimento (KG SDAAL), e só então na
  de código."* **Confirmado em campo:** o veredito por-verdade (op3 cruza / dose-para-meta segura)
  seria impossível de derivar de um merge textual. Sugiro isto virar nota em
  `knowledge-graph-sdaal` (KB do core) com este dogfood como evidência.

## 4. Governança / invariantes

- **I3 respeitado:** este sinal chega ao teu `inbox/` como entrega-sem-commit (via `/meta:co-relay`);
  **triá-lo + commitar é a tua sessão.** O Movimento 3 em si já está commitado **no meu repo**
  (`86aa73ef`, linhagem de produção).
- **D1 (Movimento 1)** também fechado do meu lado: framework commitado na linhagem de produção
  (`955df0eb`), `lint-selftest` 116/116 ✅.
- **Falta você (core):** D2 (oficializar `lineages:` no `members.yaml`) e a construção do `/meta:kg`.
  D4 (merge total) segue **bloqueado** pelo veredito `Q_HOLD_DOSEPARAMETA` (só após Fase B on-policy).
