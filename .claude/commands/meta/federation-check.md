---
name: federation-check
description: 'Lado consumer da Onion Federation (Fase 2). Lê o inbox (CHANGELOG) do ledger git, detecta contratos endereçados a este membro, valida cada um em casa (formato + classe do bump) e emite o veredito MemberExpertSchema {approved, blocked_contracts, required_migrations, reasoning}. Fail-safe: bump breaking ou ausência de output válido = veto (approved:false). Não muta o ledger — só lê e reporta ao maestro.'
category: meta
tags: [federation, contract, check, consumer, inbox, member-expert, sdaal]
version: "1.0.0"
updated: "2026-06-15"
allowed-tools: Read Grep Glob Bash(cat .env*) Bash(bash .claude/validation/federation-inbox-scan.sh*) Bash(bash .claude/validation/federation-contract-validate.sh*) Bash(git *)
argument-hint: "[--ledger <path>] [--member <id>]  (também via .env FEDERATION_LEDGER / FEDERATION_MEMBER_ID)"
---

# /meta:federation-check — Validar inbox em casa (veto de 1ª mão)

## 🎯 Objetivo

Do ponto de vista do **consumer**, ler o **inbox** (CHANGELOG) do ledger, ver quais contratos que
**este repo consome** mudaram, validá-los **em casa** e emitir um veredito estruturado
(`MemberExpertSchema`) ao maestro. É o **"veto de 1ª mão"** da [Onion Federation](../../../docs/knowledge-base/concepts/multi-repo-federation.md)
(design v2 §5.4/§6): cada Onion defende seu repo validando localmente.

> **Read-only sobre o ledger:** este comando **não muta** o ledger — só lê o inbox e os contratos.
> O veredito vai para **você (maestro)**, que decide migração / PRs / rollback (design §6).

## 🔑 Resolver ledger + membro (ajuste 2a — sem path absoluto)

- **Ledger:** `--ledger <path>` → `.env FEDERATION_LEDGER` → path relativo convencional (se existir).
- **Membro (este consumer):** `--member <id>` → `.env FEDERATION_MEMBER_ID`.
- Faltando qualquer um → **avisar em pt-BR** pedindo o argumento/`.env`. **Nunca** assumir caminho absoluto.

## ⚡ Etapas

### Passo 1 — Ler o inbox (determinístico)
```bash
bash .claude/validation/federation-inbox-scan.sh --ledger "<ledger>" --member "<member>" --json
```
Retorna `{member, breaking_count, contracts:[{id, version, producer, class}]}` — só os contratos
endereçados a este membro, na versão vigente. **A regra de leitura vive no script** (ajuste 6a).

### Passo 2 — Validar cada contrato em casa (formato)
Para cada `contracts[].id`:
```bash
bash .claude/validation/federation-contract-validate.sh "<ledger>/contracts/<id>.md" --json
```
`valid:false` → o contrato entra em `blocked_contracts` (formato quebrado = blocker, review #4/#14).

### Passo 3 — Compor o veredito (`MemberExpertSchema`)
Regra determinística de aprovação:
- `class == BREAKING` → contrato **bloqueia** (entra em `blocked_contracts` + `required_migrations`).
- `valid == false` → contrato **bloqueia**.
- `class ∈ {COMPATIBLE, INITIAL}` **e** `valid == true` → contrato passa.
- `approved = true` **somente se** `blocked_contracts` estiver **vazio**.

Emitir o schema:
```json
{
  "approved": false,
  "blocked_contracts": ["user-auth-api"],
  "required_migrations": ["user-auth-api v1→v2: remover uso do campo legacy token"],
  "reasoning": "1 contrato breaking (major bump) endereçado a este consumer; migração necessária antes do merge."
}
```

### Passo 4 — Reportar ao maestro
Saída humana + o schema. Em `approved:false`, listar o que migrar antes de qualquer merge cross-repo.

## 🛡️ Fail-safe (invariante de segurança)

**Ausência de output válido = veto.** Se o scan falhar, o `.env`/argumento não resolver, um contrato
endereçado não existir em `contracts/`, ou o comando não conseguir produzir um `MemberExpertSchema`
bem-formado → trate como **`approved:false`** (design §5.4). O silêncio **nunca** é aprovação.

## 📤 Saída esperada

```
🔎 check de <member> contra <ledger>
   ∟ user-auth-api v2.0.0 [BREAKING] → BLOQUEIA (migração necessária)
   ∟ billing-events v0.2.0 [COMPATIBLE] · formato OK → passa
   ───
   veredito: approved=false · blocked=[user-auth-api]
   migração: user-auth-api v1→v2 (remover campo legacy token)
```

## ⚠️ Notas

- **2a (sem path absoluto):** ledger/membro por argumento / `.env`. Nada embutido.
- **6a (validação não-agente):** leitura de inbox em `federation-inbox-scan.sh`; formato em
  `federation-contract-validate.sh`. Este comando **orquestra** e compõe o veredito.
- **Fail-safe > fail-open:** na dúvida, **veto**. É o sentido forte de "defende seus interesses".
- **Não muta o ledger;** **não** funde nem dispara workflows faseados. Verbo solto em `meta/`.

## 🔗 Referências

- `MemberExpertSchema` + máquina de segurança: [multi-repo-federation.md](../../../docs/knowledge-base/concepts/multi-repo-federation.md) §4
- Lado producer (gera o inbox): `/meta:federation-publish`
- Scan determinístico: `.claude/validation/federation-inbox-scan.sh`
- Validação de formato: `.claude/validation/federation-contract-validate.sh`
- Workflow do maestro: design v2 §6
