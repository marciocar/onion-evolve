---
title: 'lint-selftest.sh robusto a adotante (não aborta mais sem plugins/)'
date: 2026-06-28
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-28 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — lint-selftest.sh robusto a adotante (não aborta mais sem plugins/)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **Seu sinal de campo foi endereçado** (relayado via `/meta:co-relay`, PR #202). O `lint-selftest.sh` **abortava com exit 2** no seu repo (sem `plugins/`) — sob `set -e`, um modo **core-only** derrubava o script **antes** do `run_de_identification_selftests` (o de-id do #201) rodar. Você teve que validar o round-trip à mão; agora não precisa mais.
- **Diagnóstico (seu, confirmado):** o harness é **artefato distribuído** com dois contextos — core (tem `plugins/`, `fixtures/`) e adotante (subconjunto). Um `set -e` global tornava o modo mais frágil o **teto de todos**. Não era regressão do #201 — fragilidade estrutural pré-existente que o de-id apenas tornou visível.
- **Fix (PR #202, sua opção (2) + (1) combinadas):**
  1. **Skip gracioso por precondição local** (mesmo idioma do `jq ausente → pulado`): modos core-only auto-reportam `pulado (adotante)` como **PASS** quando o artefato falta — loop de fixtures (sem `manifest`), `assemble-plugin`/`plugins-sync`/`graph` (sem `plugins/` vendorizados; o consumidor **não publica plugins**).
  2. **Rede de segurança `|| true`** nos modos de maquinaria de marketplace: um abort imprevisto **jamais esconde** os modos self-contained seguintes.
- **Strictness do core preservada:** onde `plugins/`/`fixtures/` existem (o core), o skip **nunca dispara** → drift real ainda vira FAIL + exit ≠0. O gate ficou **context-aware, não mais frouxo**.
- **Validado nos dois contextos (dogfood adversarial):** core **100/0 exit 0**; adotante simulado (sem `plugins/` nem `fixtures/`) **47/0 exit 0**, com o **de-id passando** (round-trip, dedupe, determinismo).

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- No próximo `/meta:adopt --update`, o `lint-selftest.sh` corrigido chega vendorizado. A partir daí, o passo pós-update **"rode `lint-selftest.sh`"** conclui com **exit 0** e valida o de-id no harness (sem rodar o `redact-deterministic.sh` à mão). Não é BREAKING — sem ação obrigatória agora.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-28-lint-selftest-robusto-adotante.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
