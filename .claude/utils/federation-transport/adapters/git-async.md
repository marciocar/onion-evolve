# adapter: git-async (default)

> Implementa `ITransport` via **doc-bridge** (o que já está EM USO). Não reimplementa — **aponta** o fluxo.

## deliver(signal) — downstream (core→adotante)
1. `/meta:co-announce` resolve o `alvo:` (via `resolve-target.sh` — F1.2) e escreve o rascunho na staging do
   core: `docs/evolution/federation/outbox/<id>/<data>-<slug>.md`.
2. O maestro **transporta** ao `inbound/` do adotante (mesma máquina → `co-deliver.sh`; outra → manual).
3. `DeliveryResult{ transport:'git-async', delivered:true, committed:false, gated:true }` — o adotante
   commita+tria (I3). O `CHANGELOG` (append-only) é o ledger.

## receive(memberId) — upstream (projeto→core)
Poll do `docs/evolution/inbox/` (sinais commitados/relayados). `mail-receiver.sh` (F1.4) acelera o aviso.

## Disponibilidade
**Sempre** (é git + markdown). É o **fallback universal** das outras vias e o system-of-record (RFC-0001).

## Invariantes
Assíncrono; maestro no gate; entrega-sem-commit (I3); append-only auditável. Nenhum sinal auto-aplicado.
