---
name: federation-status
description: 'Monitor read-only da Onion Federation (Fase 3). Lê o ledger (members.yaml + CHANGELOG + contracts/) e reporta saúde cross-repo: contract-drift (contrato alterado sem publish, via script determinístico) + status de CI por membro (via forge adapter). Não muta nada — dá ao maestro a visão "está tudo são?" antes/depois de coordenar uma mudança.'
category: meta
tags: [federation, status, monitor, drift, ci, ledger, forge, sdaal]
version: "1.0.0"
updated: "2026-06-15"
allowed-tools: Read Grep Glob Bash(cat .env*) Bash(bash .claude/validation/federation-status-scan.sh*)
argument-hint: "[--ledger <path>]  (também via .env FEDERATION_LEDGER)"
---

# /meta:federation-status — Monitor de saúde da federação

## 🎯 Objetivo

Dar ao **maestro** a visão consolidada "**está tudo são?**" — antes de coordenar uma mudança e
depois de aplicá-la. Combina dois sinais (design v2 §4, review #16):
1. **Contract-drift** (determinístico, no ledger): contrato alterado **sem** publish correspondente.
2. **CI por membro** (via **forge adapter**): cada repo-membro está verde?

**Read-only:** não muta ledger nem repos. Só lê e reporta.

## 🔑 Resolver o ledger (ajuste 2a — sem path absoluto)

`--ledger <path>` → `.env FEDERATION_LEDGER` → path relativo convencional (se existir). Faltando →
avisar em pt-BR. **Nunca** assumir caminho absoluto.

## ⚡ Etapas

### Passo 1 — Drift (determinístico)
```bash
bash .claude/validation/federation-status-scan.sh --ledger "<ledger>" --json
```
Retorna `{contracts:[{id, file_version, published_version, status}], drift_count}` —
`status ∈ {in-sync, drift, unpublished}`. A regra vive no **script** (ajuste 6a). `drift` =
contrato à frente do último publish (mudança fora do fluxo).

### Passo 2 — CI por membro (via forge adapter — NUNCA `gh` direto em prosa)
Para cada membro de `members.yaml` com `remote`/`path` resolvível:
```
const forge = getForge();                 // .claude/utils/forge/factory.md
const ci = await forge.getCIStatus(ref);  // ou getPRStatus({number}) p/ PR aberto do membro
```
- `forge.isConfigured == false` → **degrada**: marca CI de todos como `indisponível`, avisa em pt-BR,
  e segue só com o sinal de drift (fail-soft, não aborta o monitor).
- O adapter resolve transporte (`gh` cli default / REST). O comando **não** chama `gh` direto.

### Passo 3 — Reportar (tabela ao maestro)
- **Por contrato:** id · file_version · published_version · status (drift destacado).
- **Por membro:** id · role · CI (verde/vermelho/indisponível).
- **Veredito de topo:** `SÃO` se `drift_count == 0` e nenhum CI vermelho; senão **`ATENÇÃO`** com a lista do que resolver.

## 📤 Saída esperada

```
🩺 federation-status · ledger <ledger>
contratos:
   · user-auth-api   arquivo=1.0.0 publicado=1.0.0 [in-sync]
   ⚠️ billing-events  arquivo=2.0.0 publicado=1.0.0 [drift]  ← alterado sem publish
membros (CI via forge):
   · m-prod (producer)  CI: verde
   · m-cons (consumer)  CI: vermelho ← investigar
───
veredito: ATENÇÃO · 1 drift, 1 CI vermelho
ação: publicar billing-events (ou reverter o arquivo) + investigar CI de m-cons
```

## ⚠️ Notas

- **2a:** ledger/membros por argumento / `members.yaml` / `.env` / relativo. Nada embutido.
- **6a:** o drift determinístico vive em `federation-status-scan.sh`; este comando orquestra + agrega CI.
- **Forge via adapter (capability, não só prosa):** CI por membro **sempre** pelo adapter
  (`.claude/utils/forge/`). Este comando **não** detém `gh`/`git` no `allowed-tools` — a capacidade de
  host vive no adapter; conceder `gh` aqui burlaria a abstração que o adapter existe para fechar.
- **Fail-soft no forge, fail-loud no ledger:** forge indisponível degrada graciosamente; ledger ausente/ilegível interrompe com mensagem.
- **Read-only;** verbo solto em `meta/`; **não** funde nem dispara workflows faseados.
- **Linha vermelha (design §2):** monitor é polling **assíncrono** sob demanda — **não** é runtime vivo nem A2A.

## 🔗 Referências

- Componente + drift: [multi-repo-federation.md](../../../docs/knowledge-base/concepts/multi-repo-federation.md) · design v2 §4
- Forge: [`.claude/utils/forge/interface.md`](../../utils/forge/interface.md) (`getCIStatus`/`getPRStatus`/`getCheckRuns`)
- Scan determinístico: `.claude/validation/federation-status-scan.sh`
- Reverter mudança: `/meta:federation-rollback` · Anunciar: `/meta:federation-publish`
