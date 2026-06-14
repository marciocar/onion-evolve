---
name: code-review
description: |
  [Alias] Redireciona para /meta:setup-code-review (setup de code review no CI).
  Mantido por compatibilidade — code review automático é configuração de CI, não GitFlow.
model: sonnet
allowed-tools: Read
category: git
tags: [alias, code-review, ci-cd]
version: "3.1.0"
updated: "2026-06-13"
related_commands:
  - /meta/setup-code-review
---

# 🔁 Git Code Review — Alias

Este comando **mudou de lugar**. O gerenciamento de code review automático é uma tarefa de **configuração de CI** (GitHub Actions), não de GitFlow — por isso passou para a categoria `meta/`.

## ➡️ Use

```bash
/meta/setup-code-review [auto|setup|validate|status]
```

Comando canônico: [meta/setup-code-review.md](../meta/setup-code-review.md). Os argumentos são idênticos. Este alias é mantido por compatibilidade e será removido em iteração futura — atualize seus atalhos/documentação para `/meta:setup-code-review`.
