---
name: federation-register
description: Registra e valida um contrato de federação (spec-as-code) localmente em UM repo, contra o ledger git. Bootstrapa o ledger se ausente, roda a validação determinística (tests:+fixtures obrigatórios) e, em sucesso, grava+commita o contrato em contracts/<id>.md. NÃO anuncia aos consumers — o CHANGELOG/inbox é responsabilidade do /meta:federation-publish. É o "átomo" da Onion Federation (Fase 1) — testável num repo só.
category: meta
tags: [federation, contract, spec-as-code, ledger, validation, sdaal]
version: "1.1.0"
updated: "2026-06-15"
allowed-tools: Read Write Edit Grep Glob Bash(cat .env*) Bash(bash .claude/validation/federation-contract-validate.sh*) Bash(git *) Bash(mkdir *)
argument-hint: "<path-do-contrato> [--ledger <path>]  (ledger também via .env FEDERATION_LEDGER)"
---

# /meta:federation-register — Registrar/validar contrato no ledger

## 🎯 Objetivo

Registrar um **contrato de integração** (spec-as-code) no **ledger git** e **validá-lo
localmente**, garantindo que ele cumpre o formato (incl. `tests:` e `fixtures` obrigatórios) antes
de entrar na federação. É o átomo da [Onion Federation](../../../docs/knowledge-base/concepts/multi-repo-federation.md):
funciona **num repo só**, sem precisar de outros membros vivos.

> **Padrão:** este comando **orquestra**; a **validação determinística** vive em
> `.claude/validation/federation-contract-validate.sh` (espelha o par `/meta:inventory` ↔
> `inventory.sh`). A validação **nunca** é um agente (ajuste 6a do gate da Fase 0).

## 🟢 Quando usar

- Ao criar/atualizar um contrato que o seu repo **produz** (antes de publicar a mudança).
- Para conferir, num PR, que um contrato existente continua válido (CI local / pre-merge).

## 🔑 Resolver o ledger (ajuste 2a — sem path absoluto)

O caminho do ledger é **dado de configuração**, nunca embutido. Resolva nesta ordem:

1. Flag explícita `--ledger <path>` no `$ARGUMENTS`.
2. `FEDERATION_LEDGER` no `.env` (`set -a; source .env; set +a`).
3. Caminho **relativo** convencional (ex.: `../federation-ledger`) — só se existir.

Se nenhum resolver → **avisar em pt-BR** pedindo `--ledger` ou `FEDERATION_LEDGER`. **Nunca**
assumir `/home/...` nem outro caminho absoluto.

## ⚡ Etapas

### Passo 1 — Localizar ou bootstrapar o ledger
- Resolver o path (acima). Se o diretório não for repo git: `git init`, e criar o skeleton mínimo
  — `members.yaml` (manifesto), `contracts/` (dir), `CHANGELOG.md` (mailbox append-only). Formato:
  KB [multi-repo-federation §2/§3](../../../docs/knowledge-base/concepts/multi-repo-federation.md).

### Passo 2 — Registrar o contrato
- Copiar/mover o contrato informado para `<ledger>/contracts/<id>.md` (o `<id>` vem do próprio
  contrato). Não sobrescrever silenciosamente uma versão anterior sem registrar o bump.

### Passo 3 — Validar (determinístico)
```bash
bash .claude/validation/federation-contract-validate.sh "<ledger>/contracts/<id>.md" --json
```
- `valid:true` → segue. `valid:false` → **parar** e reportar os `errors[]` como **blocker**
  (sem teste/fixture = blocker; semver inválido = blocker). Não registrar contrato inválido.

### Passo 4 — Commitar o contrato (sem anunciar)
- `git -C <ledger> add contracts/<id>.md && git -C <ledger> commit -m "register(<id>): v<version> [producer <member-id>]"`.
- **NÃO** escrever no `CHANGELOG.md` nem anunciar aos consumers — isso é do
  `/meta:federation-publish` (que carrega o checkpoint do maestro). O `register` apenas **atesta que
  um contrato válido existe** no ledger; o **anúncio** é um ato deliberado separado.

## 📤 Saída esperada

```
✅ contrato <id> v<version> registrado em <ledger>/contracts/<id>.md
   ◆ validação: OK (tests:N, fixtures:M)
   ◆ commit <sha> (register) — anuncie aos consumers com /meta:federation-publish
```
ou, em falha:
```
❌ contrato <id> NÃO registrado — validação falhou:
   ∟ <erro acionável>
```

## ⚠️ Notas

- **2a (sem path absoluto):** ledger e contrato resolvidos por argumento / `members.yaml` / `.env` /
  path relativo. Nenhum caminho absoluto embutido neste comando nem no script.
- **6a (validação não-agente):** a regra dura vive no script de `.claude/validation/`.
- **Átomo num repo só:** não exige outros membros vivos. O **anúncio** aos consumers (CHANGELOG/inbox)
  é do `/meta:federation-publish`; `check`/`status` completam o ciclo cross-repo. Este comando **não**
  funde nem dispara workflows faseados.
- **Idempotente na validação:** revalidar o mesmo contrato não muda nada; só o bump gera nova entrada.

## 🔗 Referências

- Formato + máquina de segurança: [multi-repo-federation.md](../../../docs/knowledge-base/concepts/multi-repo-federation.md)
- Mecanismo do ledger: [git-ledger-as-working-dir.md](../../../docs/knowledge-base/platforms/git-ledger-as-working-dir.md)
- Validação: `.claude/validation/federation-contract-validate.sh`
- Precedente comando↔script: `/meta:inventory` ↔ `.claude/validation/inventory.sh`
