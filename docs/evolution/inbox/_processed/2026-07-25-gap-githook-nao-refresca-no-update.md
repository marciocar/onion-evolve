---
title: 'Gap: install-onion-githook não refresca um hook Onion-autorado no --update (escreve sidecar, deixa o velho ativo)'
date: 2026-07-25
from: core (auto-observação — sessão-fonte rodando /meta:adopt --update no arandek)
to: core (onion-evolve)
type: field-observation
flow: handoff (dentro do core / backlog acionável)
---

# Gap — `install-onion-githook.sh` não refresca hook Onion no `--update`

## O que aconteceu (evidência)

Rodando `/meta:adopt --update /home/marcio/arandek --integration-branch develop` (pin 5e3ee → 65d8a7),
o passo (6) da config pós-cópia (`install-onion-githook.sh`) é **never-clobber**: como o alvo JÁ tinha
`.githooks/pre-commit` (instalado na adoção), ele **não sobrescreveu** — escreveu a versão nova como
sidecar `.githooks/pre-commit.onion` e **deixou o hook velho ativo**.

Consequência concreta nesta rodada: o fix D1-do-sinal-2 (o hook lê `packageManager` em vez de mandar
`pnpm install` cego) **NÃO teria pegado** no adotante — o hook ativo continuaria com a mensagem velha.
Tive que promover o sidecar à mão (`mv .githooks/pre-commit.onion .githooks/pre-commit`), verificando
antes a assinatura Onion + que o único diff era o fix.

## Por que o never-clobber está certo E incompleto

O never-clobber existe para não pisar num pre-commit **do adotante** (hook próprio dele → sidecar é o
certo). O gap: quando o `.githooks/pre-commit` **É o hook Onion** (de uma adoção anterior, versão
antiga), o update deveria **refrescá-lo in-place**, não sidecá-lo. Existência de arquivo ≠ autoria do
adotante — mesma família do contra-sinal develop-fantasma (existência ≠ autoridade).

## Suggested mechanism (candidato a guarda/fix, não one-off)

`install-onion-githook.sh`: antes de sidecar, checar se o `.githooks/pre-commit` existente carrega a
**assinatura Onion** (ex.: marcador `🧅 Onion pre-commit` / `hook nativo Onion`). Se sim → sobrescrever
in-place (é nosso, versão velha). Se não → sidecar (é do adotante). Determinístico, testável
(lint-selftest kind=githook: caso "hook Onion antigo → refrescado in-place"; caso "hook alheio →
sidecar preservado").

## Família

Mesma classe do `docs/evolution/inbox/_processed/2026-06-18-adopt-update-skips-phase3-steps.md` (o
`--update` esquecendo passos install-only) e do sinal arandek D2/D3 (instrução sem consultar o alvo).
Vale varrer se outros passos install-only têm o mesmo modo-de-falha "existe → não refresca".
