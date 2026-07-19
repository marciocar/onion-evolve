---
name: setup-code-review
description: |
  Setup, validação e otimização de code review automático no CI (GitHub Actions).
  Use para configurar o workflow de review de PRs do projeto.
model: sonnet
allowed-tools: Bash(git *) Bash(gh *) Read Edit Write Bash(cat .env*)

parameters:
  - name: mode
    description: Modo de operação (auto/setup/validate/status)
    required: false
    default: auto

category: meta
tags:
  - code-review
  - automation
  - ci-cd

version: "1.0.0"
updated: "2026-06-13"

related_commands:
  - /engineer/pre-pr
  - /meta/setup-integration

related_agents:
  - code-reviewer
---

# 🤖 Setup de Code Review no CI

Gerencia o workflow de **code review automático** no CI (GitHub Actions) do projeto. É uma tarefa de **configuração de integração** (não de GitFlow) — por isso vive em `meta/`, ao lado de `/meta:setup-integration`.

> ℹ️ **Compatibilidade com a porta Claude Code do Onion**: o CI canônico deste repositório é o **`.github/workflows/onion-review.yml`** (revisor baseado em Claude). Este comando reconhece e valida esse workflow; opcionalmente, também sabe scaffoldar um review de terceiros. _Conteúdo herdado de uma versão que citava a action `anc95/ChatGPT-CodeReview` — refresh completo desse template está marcado para iteração 2._

## ⚡ Modos de Operação

```bash
/meta/setup-code-review           # AUTO: detecta e executa ação apropriada
/meta/setup-code-review setup     # Criar/reconfigurar o workflow de CI
/meta/setup-code-review validate  # Validar configuração existente
/meta/setup-code-review status    # Mostrar status atual
```

## 🔄 Fluxo de Execução

### Passo 1: Detectar modo

```bash
# Workflow de review já existe? (onion-review.yml canônico, ou code-review.yml legado)
test -f .github/workflows/onion-review.yml || test -f .github/workflows/code-review.yml \
  && MODE="validate" || MODE="setup"
```

Se `{{mode}}` fornecido → usar o modo especificado; senão → detecção automática.

### Passo 2: Executar modo

**🆕 SETUP** — detectar stack (`pnpm`/`npm`, `nx`, backend/frontend) e gerar/ajustar o workflow:
- **Recomendado (porta Claude Code)**: `onion-review.yml` baseado em Claude — secret `ANTHROPIC_API_KEY` no repositório (Settings > Secrets and variables > Actions). Ver `.env.example` (a key local **não** chega ao runner).
- Aplicar regras por stack (TypeScript: tipos; React: hooks; NX: monorepo).

**🔍 VALIDATE** — arquivo existe? YAML válido? secrets configurados? Usar o checklist de `common/prompts/code-review-checklist.md` e gerar relatório (🔴 críticos, 🟡 importantes, 💡 sugestões).

**📊 STATUS** — dashboard: arquivo configurado, stack detectado, secret presente, métricas (PRs revisados, issues, auto-fixes).

### Passo 3: Reportar no PR (opcional)

Para postar o resultado da validação como comentário no PR, usar o **adapter forge** (`forge.addReviewComment(...)` em [.claude/utils/forge/](../../utils/forge/interface.md)) — **não** chamar `gh`/API direto (integrations.md §9).

### Passo 4: Task Manager (opcional)

Se houver task associada e `TASK_MANAGER_PROVIDER` != `none`, registrar o resultado via o adapter ([utils/task-manager/factory.md](../../utils/task-manager/factory.md)). Roteamento por provider é do adapter — **não reimplementar aqui**.

## 📤 Output Esperado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ CODE REVIEW CONFIGURADO
∟ Workflow: .github/workflows/onion-review.yml
∟ Stack: TypeScript + React + NX
⚠️ Próximo: configurar ANTHROPIC_API_KEY em Settings > Secrets
🚀 Validar: /meta/setup-code-review validate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔗 Referências

- Checklist: `common/prompts/code-review-checklist.md`
- Forge (comentário no PR): [utils/forge/interface.md](../../utils/forge/interface.md)
- Integração / secrets: [.env.example](../../../.env.example) · `/meta:setup-integration`
- Review manual: `@code-reviewer`

## ⚠️ Notas

- Requer GitHub Actions habilitado e o secret de API do revisor configurado.
- Alias de compatibilidade: `/git/code-review` redireciona para cá (será removido em iteração futura).
