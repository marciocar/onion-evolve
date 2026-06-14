# 📊 Análises do Sistema Onion — Ciclo de Vida

> **Princípio:** análises e planos são **efêmeros**. Uma vez **executados**, são **removidos** do repositório — o **git history é o arquivo**. Só permanecem aqui os **baselines ativos** referenciados por comandos ou pela constituição.

Isto reforça a doutrina de modernização (regra de inventário/SSOT em
[`../knowledge-base/concepts/onion-modernization-doctrine.md`](../knowledge-base/concepts/onion-modernization-doctrine.md)):
documentação ativa contém só o que é canônico ou usado em runtime; o resto não acumula.

## O que PERMANECE (baselines ativos)

| Arquivo | Por que fica |
|---------|--------------|
| `onion-review-2026-05.md` | **SSOT de identidade** — citado por `CLAUDE.md`. Sintetiza as análises-fonte de 2025 (que foram removidas). |
| `onion-vv-baseline-2026-06.md` | Baseline de V&V — lida por `/meta:evolve` como referência da auditoria automatizada. |
| `onion-evolution-<data>.md` (a mais recente) | Última auditoria de evolução — ponto de comparação para a próxima rodada de `/meta:evolve`. Versões anteriores são removidas. |

## O que é REMOVIDO (efêmero — git arquiva)

- **Planos de execução** depois de executados (ex.: planos de saneamento, épicos, migrações).
- **Retrospectivas** de tarefas/pilotos concluídos.
- **Relatórios de evolução antigos** quando uma versão mais nova existe.
- **Análises de vendor/POC** não relacionadas ao framework.

## Regra prática

Ao concluir um ciclo (plano executado, backlog resolvido, piloto encerrado):
1. Garanta que as **conclusões duradouras** estejam sintetizadas num baseline ativo (tipicamente `onion-review` ou a doutrina).
2. **Remova** o artefato efêmero (`git rm`) e corrija eventuais links em arquivos que ficam.
3. Regenere o inventário se KBs mudaram (`/meta:inventory`) e rode o lint.

> Recuperar um documento removido: `git log --all --full-history -- <caminho>` e `git show <commit>:<caminho>`.
