# 🌿 Agentes `git/` — GitFlow e gates pré-PR

Agentes que cuidam do ciclo Git do Onion: o motor **GitFlow** (branching, releases, versionamento) e os quatro especialistas **diff-scoped** que rodam o gate de qualidade sobre as mudanças do branch atual antes do merge (`/engineer/pre-pr`).

## Agentes

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@gitflow-specialist`](gitflow-specialist.md) | GitFlow: branching, releases, hotfix, versionamento semântico, resolução de conflitos | Guidance em workflows Git estruturados e colaborativos; acionado por `/git:init` e `/git:flow` |
| [`@branch-code-reviewer`](branch-code-reviewer.md) | Revisão de código pré-PR focada nas mudanças do branch (qualidade, bugs, best practices) | Antes do merge, para análise de qualidade do diff. Variante diff-scoped do `@code-reviewer` |
| [`@branch-test-planner`](branch-test-planner.md) | Cobertura de testes do diff do branch | Antes do merge, para identificar testes ausentes nas mudanças. Variante diff-scoped do `@test-planner` |
| [`@branch-metaspec-checker`](branch-metaspec-checker.md) | Conformidade com metaspecs (só as mudanças do branch) | Antes do merge, para garantir alinhamento arquitetural do diff. Variante diff-scoped do `@metaspec-gate-keeper` |
| [`@branch-documentation-writer`](branch-documentation-writer.md) | Sincronização da documentação com as mudanças do branch | Antes do merge, para manter docs alinhadas às alterações de código |

## 🔗 Relacionados

- Comando que orquestra os gates do branch: [`/engineer:pre-pr`](../../commands/engineer/pre-pr.md)
- Comandos GitFlow servidos pelo `@gitflow-specialist`: [`/git:init`](../../commands/git/init.md), [`/git:flow`](../../commands/git/flow.md)
- Variantes gerais (escopo amplo) dos especialistas de branch: `@code-reviewer`, `@test-planner`, `@metaspec-gate-keeper`
- KB do motor: [`gitflow-patterns.md`](../../../docs/knowledge-base/frameworks/gitflow-patterns.md)
