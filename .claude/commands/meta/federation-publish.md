---
name: federation-publish
description: 'Anuncia (publica) um bump de contrato de federação aos consumers, escrevendo a entrada de inbox no CHANGELOG do ledger git. Classifica o bump como breaking (major) ou compatível (minor/patch), aplica o checkpoint do maestro (confirmar escopo) e endereça os consumers do contrato. É o lado producer da comunicação assíncrona (Onion Federation Fase 2). Pré-requisito: contrato já registrado via /meta:federation-register.'
category: meta
tags: [federation, contract, publish, ledger, changelog, semver, sdaal]
version: "1.0.0"
updated: "2026-06-15"
allowed-tools: Read Write Edit Grep Glob Bash(cat .env*) Bash(bash .claude/validation/federation-contract-validate.sh*) Bash(git *)
argument-hint: "<id-do-contrato> [--ledger <path>] [--note \"resumo da mudança\"]  (ledger também via .env FEDERATION_LEDGER)"
---

# /meta:federation-publish — Anunciar bump de contrato aos consumers

## 🎯 Objetivo

Publicar — no sentido de **anunciar** — uma mudança de contrato no **ledger git**, gravando a
entrada de **inbox** (CHANGELOG append-only) que os consumers vão ler com `/meta:federation-check`.
É o **lado producer** da comunicação assíncrona da [Onion Federation](../../../docs/knowledge-base/concepts/multi-repo-federation.md)
(design v2 §6). Diferente do `register` (que só atesta que um contrato **válido existe** no ledger),
o `publish` é o **ato deliberado** de comunicar uma mudança — com checkpoint humano.

> **Fronteira register × publish** (decisão Fase 2): `register` = validar + gravar/commitar o
> `contracts/<id>.md`. `publish` = classificar o bump + checkpoint do maestro + escrever a entrada de
> inbox endereçada aos consumers + commit. **Só o `publish` escreve no `CHANGELOG.md`.**

## 🟢 Quando usar

- Depois de `register` confirmar um contrato válido, quando a mudança **deve ser comunicada** aos
  consumers (nova versão, breaking ou compatível).
- **Não** use para mero registro local sem intenção de anunciar — isso é `register`.

## 🔑 Resolver o ledger (ajuste 2a — sem path absoluto)

Idêntico ao `register`. Resolva nesta ordem:
1. Flag `--ledger <path>` no `$ARGUMENTS`.
2. `FEDERATION_LEDGER` no `.env` (`set -a; source .env; set +a`).
3. Caminho **relativo** convencional (ex.: `../federation-ledger`) — só se existir.

Se nenhum resolver → **avisar em pt-BR** pedindo `--ledger` ou `FEDERATION_LEDGER`. **Nunca** assumir
caminho absoluto.

## ⚡ Etapas

### Passo 1 — Localizar o contrato + revalidar
- O contrato precisa já existir em `<ledger>/contracts/<id>.md` (senão: rodar `register` antes).
- Revalidar (defensivo — não anunciar contrato inválido):
  ```bash
  bash .claude/validation/federation-contract-validate.sh "<ledger>/contracts/<id>.md" --json
  ```
  `valid:false` → **parar** e reportar os `errors[]` como blocker.

### Passo 2 — Classificar o bump (breaking vs compatível)
- Ler a `version` atual do contrato (semver). Comparar com a **versão anterior** anunciada (última
  entrada do `<id>` no CHANGELOG, ou via `git -C <ledger> log`/diff de `contracts/<id>.md`).
- **major** incrementou → `BREAKING`; **minor/patch** → `COMPATIBLE`. Sem versão anterior → `INITIAL`.
- Ler os `consumers` do contrato (lista de `id`s) — são os destinatários do anúncio.

### Passo 3 — Checkpoint do maestro (human-in-the-loop, design §6.2)
- Apresentar ao humano: `<id>`, `from_version → to_version`, classificação (`BREAKING`/`COMPATIBLE`),
  consumers afetados e o resumo (`--note`). **Confirmar o escopo** antes de selar.
- Em `BREAKING`, deixar explícito que cada consumer precisará de `check` + provável migração.

### Passo 4 — Selar a entrada de inbox no CHANGELOG (append-only)
- Anexar entrada datada no `<ledger>/CHANGELOG.md` (formato que o `check` parseia):
  ```
  ## <data-ISO> · <id> · <to_version> · <producer> · PUBLISH · <BREAKING|COMPATIBLE|INITIAL>
  - consumers: [<id>, ...]
  - resumo: <note>
  ```
- Commitar no ledger:
  `git -C <ledger> add CHANGELOG.md && git -C <ledger> commit -m "publish(<id>): v<to_version> <BREAKING|COMPATIBLE> [producer <member-id>]"`.

## 📤 Saída esperada

```
📣 publicado: <id> v<from> → v<to>  [<BREAKING|COMPATIBLE>]
   ◆ consumers notificados: <id>, <id>
   ◆ CHANGELOG: entrada PUBLISH + commit <sha>
   ▶ próximo: em cada consumer, rodar /meta:federation-check
```
ou, em falha:
```
❌ não publicado: <motivo acionável>
   (contrato inválido → corrija e /meta:federation-register; ou ledger não resolvido → --ledger / .env)
```

## ⚠️ Notas

- **2a (sem path absoluto):** ledger/contrato resolvidos por argumento / `members.yaml` / `.env` /
  path relativo. Nada de `/home/...` embutido.
- **6a (validação não-agente):** a regra dura de formato vive em
  `.claude/validation/federation-contract-validate.sh`; este comando **orquestra** o anúncio.
- **Fail-loud:** contrato inválido ou ledger não resolvido **interrompe** com mensagem acionável —
  não anuncia pela metade.
- **Append-only:** o `publish` **nunca** reescreve entradas anteriores do CHANGELOG; só anexa. O
  histórico de anúncios é a auditoria.
- **Verbo solto em `meta/`** (não subdir `meta/federation/`); **não** funde nem dispara workflows faseados.

## 🔗 Referências

- Formato + máquina de segurança: [multi-repo-federation.md](../../../docs/knowledge-base/concepts/multi-repo-federation.md) (§2, §4)
- Workflow do maestro: design v2 §6 (`onion-federation-design-v2-2026-06`, core-only)
- Lado consumer: `/meta:federation-check` (lê esta entrada de inbox)
- Átomo local (pré-requisito): `/meta:federation-register`
- Validação: `.claude/validation/federation-contract-validate.sh`
