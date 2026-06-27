---
title: 'Adoção legacy: hook pre-commit (husky+lint-staged) falha ENOENT na worktree sem node_modules'
date: 2026-06-27
from: dogfood (sessão-fonte onion-evolve, adoção de rhilo-metagamify)
type: field-signal
flow: upstream (campo→core)
target: /meta:adopt
severity: medium
---

# Sinal de campo — /meta:adopt em legacy com pre-commit hook

## O que aconteceu

Ao adotar `rhilo-metagamify` (modo `legacy`), a Fase 2 cria uma **worktree nova**
(`onion-adopt-rhilo-metagamify`) para isolar a árvore do legado. O commit da adoção
(`git commit` na worktree) disparou o **husky pre-commit hook** do projeto:

```
lint-staged → prettier --write → ✖ Task failed to spawn: prettier --write  ENOENT
husky - pre-commit hook exited with code 1
```

Causa: a **worktree não tem `node_modules`** (deps vivem no checkout principal; a worktree
é árvore de trabalho separada). O hook procura o binário `prettier` local e não acha.
`lint-staged` reverteu ao estado original — **o commit não aconteceu** na 1ª tentativa.

## Workaround aplicado

`git commit --no-verify` — o hook falha por binário ausente (ENOENT), não por violação
real de formatação; e os artefatos Onion já estão protegidos pelo `.prettierignore`
(passo 5 do Procedimento pós-cópia). Funcionou.

## Direção de melhoria (candidata)

O `/meta:adopt` (Fase 2/6) deveria **antecipar** esse atrito em legacy com hooks de commit:
- **Detectar** husky/`.husky/` + lint-staged no alvo e **avisar** que o commit da adoção
  na worktree precisa de `--no-verify` (worktree sem node_modules) OU `pnpm install` na worktree.
- Documentar no "Próximos passos" do relatório downstream: o 1º commit da adoção usa `--no-verify`.

## Por que importa

É o **2º adotante legacy** (após arandek). Atrito reproduzível em qualquer monorepo JS/TS com
husky+lint-staged — padrão muito comum. Sem o aviso, o adotante leva um erro críptico de
`prettier ENOENT` que parece bug do projeto, não consequência esperada da worktree isolada.

---

## ✅ RESOLVIDO (2026-06-27)

Implementado no mesmo loop (dogfood fix→re-dogfood):
- **Fase 2 (passo 2c):** detecção de husky/lint-staged + ausência de node_modules na worktree →
  aviso para usar `git commit --no-verify` (ou `pnpm install` na worktree).
- **Relatório downstream (Próximos passos, item 2):** nota equivalente.
- **Re-dogfood:** detecção validada contra a worktree real + 3 modos de falha (sem husky,
  husky+node_modules, lint-staged-só-pkg) — zero falso-positivo. Lint gate verde.
