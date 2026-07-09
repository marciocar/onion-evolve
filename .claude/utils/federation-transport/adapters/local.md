# adapter: local (carteiro same-machine)

> Implementa `ITransport` via **carteiro-local** (o que já está EM USO: `co-deliver.sh`/`co-relay.sh`).
> Acelera a **frota local** (repos na mesma máquina) sem rede. Não reimplementa — aponta.

## Quando (detect)
`FEDERATION_TRANSPORT=auto` **e** o `local_path` do membro (`members.yaml`) **existe** nesta máquina.

## deliver(signal)
- **downstream:** `co-deliver.sh` copia o rascunho da `outbox/<id>/` p/ o `inbound/` do adotante como
  **untracked (entrega-sem-commit)** — o hook "you have mail" (📥) dispara sem commit.
- **upstream:** `co-relay.sh` (roda no adotante) relaya o sinal do `inbox/` do adotante p/ o `inbox/` do core,
  untracked.
- `DeliveryResult{ transport:'local', delivered:true, committed:false, gated:true }`. Dedup por `Signal.id`
  byte-idêntico (co-relay v≥incidente 2026-07-03).

## receive(memberId)
Igual ao git-async (poll do canal local) — a diferença é só na ENTREGA (same-machine, sem o maestro copiar à mão).

## Invariantes
Entrega-sem-commit (I3 — a sessão do destino commita); dissolve o incidente "commit cross-repo na branch errada"
(sem commit → sem pergunta de branch/push). Fallback → git-async se o clone sumiu.
