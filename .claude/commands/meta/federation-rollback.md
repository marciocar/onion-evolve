---
name: federation-rollback
description: 'Rollback Protocol guiado da Onion Federation (Fase 3, design §5.5). Para um contrato que quebrou, pina a versão anterior no ledger + sela entrada ROLLBACK no CHANGELOG e GUIA o maestro pela ordem inversa de reverts por repo (consumers→producer) via forge. Human-gated: automatiza só o determinístico/reversível (pin no ledger); NÃO executa merges/reverts cross-repo (atomicidade multi-repo não existe). Falha parcial → gate humano.'
category: meta
tags: [federation, rollback, ledger, semver, recovery, sdaal]
version: "1.0.0"
updated: "2026-06-15"
allowed-tools: Read Write Edit Grep Glob Bash(cat .env*) Bash(bash .claude/validation/federation-contract-validate.sh*) Bash(git *)
argument-hint: "<id-do-contrato> [--to <version>] [--ledger <path>] [--reason \"motivo\"]"
---

# /meta:federation-rollback — Reverter um contrato quebrado (guiado, human-gated)

## 🎯 Objetivo

Quando uma mudança de contrato quebrou consumers (check vetou, ou CI vermelho após merge),
**reverter de forma coordenada e reversível** ao estado anterior são (design v2 §5.5). O comando
**automatiza só o determinístico** (pinar a versão anterior no ledger + selar `ROLLBACK`) e **guia** o
maestro pelo resto — porque **atomicidade multi-repo não existe** no GitHub e gate humano é de 1ª classe.

> **NÃO faz:** revert/merge automático cross-repo, force-push, nem nada irreversível em repos de
> membros. Isso é decisão + execução do **maestro** (linha vermelha: sem A2A/runtime distribuído).

## 🔑 Resolver o ledger (2a — sem path absoluto)
`--ledger <path>` → `.env FEDERATION_LEDGER` → relativo. Faltando → avisar em pt-BR. Nunca absoluto.

## ⚡ Etapas

### Passo 1 — Determinar o alvo do rollback
- `<id>` do contrato. Versão-alvo: `--to <version>` se dado; senão a **penúltima** versão PUBLISH do
  `<id>` no CHANGELOG (a anterior à vigente). Se não houver versão anterior → **parar**: não há para
  onde reverter (avisar; talvez o caso seja "despublicar", fora deste comando).
- Computar **ordem inversa**: primeiro os **consumers** (do contrato), depois o **producer**
  (oposto da ordem de merge producer-primeiro). Esta ordem é o roteiro do maestro.

### Passo 2 — Checkpoint do maestro (confirmar)
- Mostrar: `<id>` `<versão-atual> → <versão-alvo>`, consumers afetados, ordem inversa de revert, motivo.
- **Confirmar** antes de tocar o ledger. Rollback é evento sério — sem confirmação, não prossegue.

### Passo 3 — Pinar a versão anterior no ledger (determinístico, reversível)
- Reverter `contracts/<id>.md` para a `version` alvo (e o conteúdo correspondente, via `git -C <ledger>`
  checkout do blob daquela versão, se disponível). Revalidar:
  `bash .claude/validation/federation-contract-validate.sh "<ledger>/contracts/<id>.md"`.
- Selar entrada no CHANGELOG (append-only — **não** apaga histórico):
  `## <data> · <id> · <versão-alvo> · <producer> · ROLLBACK · de <versão-atual>` + consumers + motivo.
- `git -C <ledger> add -A && commit -m "rollback(<id>): v<atual> → v<alvo> [<motivo>]"`.

### Passo 4 — Guiar os reverts por repo (maestro executa via forge)
- **Listar** o que o maestro precisa fazer, na ordem inversa:
  - por consumer: reverter o PR/commit que adotou a versão quebrada (forge, no repo do membro);
  - por producer: reverter por último.
- O comando **não executa** isso — entrega o roteiro acionável + lembra de validar CI verde a cada passo.

### Passo 5 — Falha parcial → gate humano explícito
- Se algum repo não puder reverter limpo (conflito, divergência, CI ainda vermelho) → **parar e
  escalar ao maestro** com o estado parcial exato. Não tentar "forçar" consistência.

## 📤 Saída esperada
```
↩️  rollback guiado: user-auth-api v2.0.0 → v1.0.0  (motivo: quebrou m-cons)
   ◆ ledger: contrato pinado em v1.0.0 + entrada ROLLBACK + commit <sha>
   ▶ ordem inversa p/ o maestro (via forge, repo a repo):
       1. m-cons: reverter PR que adotou v2.0.0 → CI verde
       2. m-prod: reverter por último → CI verde
   ⚠️ falha parcial em qualquer passo = pare e me chame
```

## ⚠️ Notas
- **2a/6a:** ledger por arg/.env/relativo; revalidação pelo script de `.claude/validation/`.
- **Append-only:** o CHANGELOG nunca é reescrito; rollback **adiciona** uma entrada `ROLLBACK` (auditoria).
- **`/meta:federation-status`** deve voltar a `SÃO` após o rollback completo — use-o para confirmar.
- **Human-gated:** automatiza só o pin no ledger; reverts cross-repo são do maestro. Verbo solto em `meta/`.

## 🔗 Referências
- Rollback Protocol: [multi-repo-federation.md](../../../docs/knowledge-base/concepts/multi-repo-federation.md) (§ Rollback) · design v2 §5.5
- Confirmar saúde: `/meta:federation-status` · Anunciar bump: `/meta:federation-publish`
- Reverts por repo: forge adapter (`.claude/utils/forge/`) — execução do maestro
