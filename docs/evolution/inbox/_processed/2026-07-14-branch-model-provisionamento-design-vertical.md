---
title: 'Branch model two-tier + provisionamento de colaborador + design-vertical'
date: 2026-07-14
from: gustavo-pulga (consumidor / workspace Betahauss)
to: core (onion-evolve)
type: signal-feedback
flow: upstream (consumidor → core)
evidencia: sessão 2026-07-14 (dogfood Tornak); .onion-version; docs/tornak/ONBOARDING-GUSTAVO.md; docs code.claude.com/docs/en/desktop
---

# Sinais ao core (2026-07-14)

## Sinal 1 — `integration_branch` ausente causa resolução errada no `/meta:adopt --update`
Num repo adotado **sem** `integration_branch` no `.onion-version`, o `/meta:adopt --update` resolveu a branch
de integração como **"main"** (inexistente; as reais eram `master`/`onion/adopt`). Corrigimos gravando
`integration_branch: onion/adopt` + `git config gitflow.branch.develop onion/adopt`.
**Proposta ao core:** o `/meta:adopt` (install) capturar e gravar `integration_branch` por padrão, e **avisar**
quando o repo tem branch de integração ≠ default. Evita o modo silencioso de resolver errado.

## Sinal 2 — padrão "provisionar colaborador" (SSH + Claude Desktop)
Ao pôr um 2º consultor no MESMO servidor rodando Claude Code via Claude Desktop, três pegadinhas reais:
1. **Claude Code é per-user** — o `claude` do dono (no home dele) não serve; instalar per-user (`curl
   claude.ai/install.sh`) + garantir `~/.local/bin` no PATH de login.
2. No Claude Desktop, o campo **SSH Host é `user@host`** (junto). Sem o `user@`, o SSH usa o nome do Mac como
   usuário → `Invalid user ...` → prompt de senha **que nunca funciona** (com `PasswordAuthentication no`).
3. "password" ≠ "passphrase": senha = usuário/host errado; passphrase = senha da chave.
**Proposta ao core:** um walkthrough/checklist "provisionar colaborador" no onboarding do framework (o Desktop
já instala o Claude Code no remoto sozinho na 1ª conexão SSH — vale documentar).

## Sinal 3 (menor) — design-vertical (extensão do padrão vertical-hub)
O padrão vertical-hub ganhou uma **face de design**: uma skill de identidade de marca acoplada à vertical +
um onboarding auto-guiado (exemplos preenchidos copiáveis, selo teoria↔prática "cara×crachá"). Candidato a um
**scaffold de design-vertical** no `bootstrap-new-project` (skill de marca + tokens + slides prontos).

> Nota: há um sinal anterior **pendente de relay** ao core —
> `docs/evolution/inbox/2026-07-13-vertical-hub-pattern-e-ingestao-multimidia.md`. Transportar os dois juntos.

---

## 🗂️ Triagem do core — 2026-07-14 (os dois sinais arquivados juntos, como pedido)

- **B1 — `integration_branch` resolve "main" silencioso: FIX ✅ ENTREGUE (PR #365).** Correção de eixo: a
  proposta literal (persistir por padrão) conflita com o design intencional do adopt 0e (carimbar palpite
  trava resolução errada). Fix bem-pensado: **avisar** no STDERR quando cai no palpite cego "main" (não
  persistir). Autoritativo segue silencioso; STDOUT/selftests inalterados.
- **B2 — checklist "provisionar colaborador" (SSH + Claude Desktop per-user): DOCS.** Walkthrough no
  `onboarding-remote-member.md`. Backlog pequeno.
- **B3 — design-vertical (skill de marca + onboarding auto-guiado no bootstrap): FEATURE/BACKLOG.** Extensão
  do padrão vertical-hub — **acopla ao A1** (sinal 2026-07-13) no mesmo design pass de `/meta:create-vertical`.

**Resumo:** B1 fixado (#365); A1+B3 = design-pass grande (backlog priorizado); A2 (pesquisa), A3 (fix), B2 (docs) = backlog.
