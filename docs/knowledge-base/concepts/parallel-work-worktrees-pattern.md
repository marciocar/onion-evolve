---
title: "Padrão — Trabalho paralelo em worktrees independentes"
category: concepts
tags: [worktree, paralelismo, work-model, sessions, worklog, tmux, gitflow]
status: candidato
date: 2026-07-11
---

# Padrão — Trabalho paralelo em worktrees independentes

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Categoria** | Concepts |
| **Aplicação** | Tocar N questões do Onion em paralelo, cada uma isolada, sem colisão de escopo |
| **SSOT de layout** | [worktree-convention-2026.md](../../evolution/worktree-convention-2026.md) (localização, nomenclatura, doutrina W3) |
| **KBs irmãs** | [agent-orchestration.md](agent-orchestration.md) · [worklog-protocol.md](worklog-protocol.md) · [federation-usage-modes.md](federation-usage-modes.md) |

> Esta KB é o **padrão operacional** (o passo-a-passo reutilizável). A **estrutura** (onde a worktree vive, como
> se chama, a doutrina de um-escritor-por-escopo) é da SSOT [worktree-convention-2026.md](../../evolution/worktree-convention-2026.md) —
> **não duplicada aqui**. Esta KB cobre o **como fazer**; a convenção cobre o **contrato**.

## 1. Quando usar (e quando NÃO)

**Use** quando há **N questões independentes** do Onion (uma feature, um veredito, um seed de contexto, um
sinal de co-evolução) que tocam **escopos de arquivo disjuntos** e você quer tocá-las **em paralelo**, cada uma
retomável por conta própria.

**NÃO use** (serialize ou use handoff) quando as frentes tocam os **mesmos arquivos** — o guard-rail automático
não pega colisão entre worktrees irmãs (ver §5). Trabalho sequencial ou com muitas dependências: uma sessão só.

## 2. O modelo em uma frase

**1 questão = 1 branch = 1 worktree = 1 sessão Claude (com worklog próprio) = 1 tela.** Todas compartilham o
mesmo `.git`; o maestro rotaciona a atenção entre elas.

## 3. Passo a passo

### 3.1 Criar a worktree (cortada da branch de integração resolvida)
```bash
cd ~/<repo>                                   # o clone principal
git worktree add -b <tipo>/<slug> \
  ~/worktrees/<repo>/<tipo>-<slug> \
  "$(bash .claude/validation/resolve-branch-role.sh integration 2>/dev/null \
     || bash .claude/validation/resolve-integration-branch.sh)"
```
- `<tipo>/<slug>` = branch em kebab (`docs/veredito-x`, `feat/y`, `chore/z`); o slug do path troca `/`→`-`.
- A **base** é a branch de integração **resolvida** (não hardcode `main`/`develop`) — ver
  [branching-base-agnostic](../../analysis/onion-adr-branching-base-agnostic-2026-06.md). Layout `~/worktrees/<repo>/<slug>`:
  convenção SSOT.

### 3.2 Abrir a sessão (uma tela por worktree)
```bash
cd ~/worktrees/<repo>/<tipo>-<slug> && claude
```
- Rode **`claude` puro** — **não** `claude --worktree` (esse cria worktree efêmera tool-managed; a sua já é a
  durável do maestro — ver convenção §Escopo).
- Cada worktree tem seu **transcript nativo** E seu **worklog** (`.claude/sessions/<slug>/STATE.md`) próprios →
  isolamento real, resume frio independente ([worklog-protocol.md](worklog-protocol.md)).
- Acesso remoto (VPS): a sessão precisa sobreviver a queda de SSH. Opções — **tmux/zellij** (multiplexer leve,
  persistente) ou **VS Code/Cursor Remote-SSH** (server persiste os terminais). Detalhe operacional fica no
  runbook de acesso, não nesta KB.

### 3.3 Trabalhar, entregar, sincronizar
```bash
# ... trabalho na worktree (handoff commitado antes de trocar de ponta) ...
# entregar: gate + PR pela vertical de engenharia
/engineer:pr                                  # ou: bash gate + gh pr create via forge adapter
# após o merge do PR:
/git:sync                                      # FF da branch protegida + atualiza worktrees
```

### 3.4 Remover quando fechar (higiene)
```bash
git -C ~/<repo> worktree remove ~/worktrees/<repo>/<tipo>-<slug>
git -C ~/<repo> worktree prune                 # higiene periódica
```

## 4. Invariantes (da convenção — repetidos porque mordem)

- **Um escritor por escopo (W3):** paralelo só é seguro se as frentes tocam arquivos disjuntos. Sobreposição →
  serialize ou handoff **commitado** antes de trocar de ponta.
- **A branch fica presa ao worktree** que a tem em checkout — o maestro rotaciona, não os agentes.
- **`claude` puro** na worktree durável; nunca `claude --worktree` por cima.

## 5. ⚠️ Caveat técnico (não contornável hoje)

O **`session-beacon` é por working-tree** (`git rev-parse --show-toplevel` é a chave). **Worktrees irmãs NÃO
veem o farol uma da outra** — o beacon flagra 2 sessões na MESMA working tree, não em worktrees distintas. O
handoff entre worktrees confia em **convenção + commit**, não no farol. Por isso o §1 exige **escopos de
arquivo disjuntos**: o guard-rail automático não cobre esse cruzamento. (Farol compartilhado via `.git` comum é
slice futuro anotado, não implementado.)

## 6. Custo real

- **Disco/git:** barato — um só `.git`; só os arquivos de trabalho duplicam.
- **O teto real é cognitivo:** N linhas de raciocínio paralelas. A worktree resolve o *isolamento técnico*, não
  a *atenção humana*. **3–4 frentes** é o teto saudável; acima disso vira troca-de-contexto cara.

## 7. Evolução gated (o que ainda não é)

Este padrão é hoje **manual + convenção**. Um comando `/git:worktree <create|list|remove>` que encapsula os
passos §3 (resolvendo a base, aplicando o layout, semeando o worklog) é **candidato gated** — abre quando o uso
manual repetido justificar (doutrina helper-testável-primeiro + gated-until-trigger). Não construir à frente do
gatilho.

## 8. Resumo executável

| Faça | Não faça |
|---|---|
| 1 questão = 1 worktree = 1 sessão = 1 worklog | 1 checkout alternando temas com `git checkout` |
| Base = branch de integração **resolvida** | Hardcode `main`/`develop` como base |
| `claude` puro na worktree durável | `claude --worktree` por cima da durável |
| Escopos de arquivo **disjuntos** entre frentes | Duas worktrees mexendo no mesmo arquivo (beacon não pega) |
| Handoff **commitado** antes de trocar de ponta | Confiar no farol entre worktrees irmãs |
| Remover + `prune` ao fechar a frente | Deixar worktree órfã acumulando |
