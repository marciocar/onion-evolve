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
| **`a2a-live`** | endpoint A2A (SSE + webhook) sobre o `onion-bridge` — só **sinais gated** | 🔒 **GATED (stub)** — RFC-0004 fase-2 | [`adapters/a2a-live.md`](adapters/a2a-live.md) |

## Resolução

`detect-transport.sh <member-id>` resolve a via por precedência (ver [`factory.md`](factory.md)): env
`FEDERATION_TRANSPORT` explícito → `auto` (local se same-machine, senão git-async) → **default `git-async`**
(sempre disponível, menor superfície de ataque — RFC-0004 §3). **`a2a-live` nunca é auto-selecionado** (gated).

## Invariantes (RFC-0001/0004)

- git-async continua o **system-of-record e o fallback** — os outros aceleram, não substituem.
- **Aceitação gated** por humano/tipo (`members.yaml` = policy-as-data) — nenhuma via auto-aplica sinal.
- **Nunca IA-fala-IA autônoma**; a2a-live transporta só **sinais gated**, nunca conversas.
- **I3** (um escritor por repo, entrega-sem-commit) preservado em toda via.

## Reuso (não reinventa)

git-async e local **documentam/apontam** o fluxo que já existe (`co-*`), não reimplementam. O `a2a-live` é o
**único novo** — e fica stub gated até o F2.2. Precedente do padrão: `forge/factory.md` (abstrai `cli|api`).
