# 🚚 federation-transport — abstração SDAAL do transporte de co-evolução

> Instância concreta do padrão **SDAAL** (irmã de `task-manager/`, `forge/`, `trust/`).
> Referência canônica: `docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`.
> Decisão: **RFC-0004** (topologia de comunicação). F2.1 do roadmap de federação.

## Propósito

Abstrair **como um sinal de co-evolução viaja entre membros** (core ↔ adotante), para que os comandos
(`/meta:co-announce`, `/meta:co-deliver`, `/meta:co-relay`, `/meta:co-evolve`) não precisem saber o "como".
A *spec* (interface) define **o quê**; o *adapter* define **o como**; `FEDERATION_TRANSPORT` controla a via.

## Os três adapters

| Via | O quê | Estado | Adapter |
|-----|-------|--------|---------|
| **`git-async`** (default) | doc-bridge: `CHANGELOG` + `outbox/` + entrega-sem-commit; assíncrono, maestro transporta | ✅ em uso | [`adapters/git-async.md`](adapters/git-async.md) |
| **`local`** | carteiro same-machine: `co-deliver.sh`/`co-relay.sh` entregam untracked no repo vizinho | ✅ em uso | [`adapters/local.md`](adapters/local.md) |
| **`a2a-live`** | endpoint A2A sobre o `onion-bridge` — só **sinais gated**, verificados pelo `a2a-verify` | 🔒 **fundação viva, endpoint stub gated** — o gate de recepção (`a2a-verify`, 6 camadas) roda no core + 1º handshake regulado provado (2026-07-09); o endpoint/canal vivo é **stub** no `~/onion-bridge` (privado, gated) | [`adapters/a2a-live.md`](adapters/a2a-live.md) |

## Nomenclatura canônica — ATO vs VIA (fecha o sinal 2026-07-09)

O eixo SDAAL (`git-async | local | a2a-live`) é a **via** (o "como"). Nomes anteriores descrevem o **ato** ou a
**implementação** de uma via — não uma via concorrente. Mapeamento canônico:

| Via (adapter) | Implementada por (ato/canal) |
|---|---|
| `local` | **carteiro-local** — `co-deliver.sh` (downstream) / `co-relay.sh` (upstream); entrega untracked same-machine |
| `git-async` | canais do doc-bridge — `outbox/` → `inbound/` → `inbox/` (append-only; maestro transporta) |
| `a2a-live` | endpoint no `onion-bridge` + `a2a-verify` (gate) + fila `data/a2a-pending` + `a2a-accept.sh` (fila→inbox) |

**Regra:** "carteiro" nomeia o **ato de entregar** (e os scripts que o fazem), **nunca a via** — a via é sempre
uma das três do eixo. Refino didático (o vocabulário já funcionava); **sem rename em massa**.

## Resolução

`detect-transport.sh <member-id>` resolve a via por precedência (ver [`factory.md`](factory.md)): env
`FEDERATION_TRANSPORT` explícito → `auto` (local se same-machine, senão git-async) → **default `git-async`**
(sempre disponível, menor superfície de ataque — RFC-0004 §3). **`a2a-live` nunca é auto-selecionado** (gated).

## Dispensas declaradas (formato **SDAAL-papel**)

O eixo do adapter aqui é a **via** de transporte (papel interno), não um provider externo —
formato-papel na [abstraction-doctrine](../../../docs/knowledge-base/concepts/onion-abstraction-doctrine.md).
Duas dispensas da anatomia canônica, **deliberadas e registradas** (a doutrina exige que sejam
declaradas, não silenciosas — precedente: divergência `cli`-default do forge, `integrations.md` §1.0):

- **sem `adapters/none.md`** — `git-async` **já é** o Null Object deste eixo: sempre disponível, é o
  system-of-record e o fallback (§Resolução acima). "Sem transporte" não é um estado possível — se o
  repo existe, git existe. Um `none.md` seria um segundo nome para `git-async`.
- **sem `detector.md`** — a detecção é **determinística** (same-machine? env explícito?) e mora em
  [`detect-transport.sh`](detect-transport.sh). Pela régua P0-P3, determinístico → **script**; um
  `detector.md` seria spec de algo que o shell já decide sem juízo.

## Invariantes (RFC-0001/0004)

- git-async continua o **system-of-record e o fallback** — os outros aceleram, não substituem.
- **Aceitação gated** por humano/tipo (`members.yaml` = policy-as-data) — nenhuma via auto-aplica sinal.
- **Nunca IA-fala-IA autônoma**; a2a-live transporta só **sinais gated**, nunca conversas.
- **I3** (um escritor por repo, entrega-sem-commit) preservado em toda via.

## Reuso (não reinventa)

git-async e local **documentam/apontam** o fluxo que já existe (`co-*`), não reimplementam. O `a2a-live` é o
**único novo** — e fica stub gated até o F2.2. Precedente do padrão: `forge/factory.md` (abstrai `cli|api`).
