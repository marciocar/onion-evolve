---
name: help
description: Ajuda contextual para comandos GitFlow do Sistema Onion.
model: sonnet
allowed-tools: Read Bash(git *)
category: git
tags: [help, gitflow, documentation]
version: "3.0.0"
updated: "2025-11-24"
---

# 🆘 Git Flow - Sistema de Ajuda

Fornecer ajuda contextual e interativa para todos os comandos GitFlow do Sistema Onion. Detectar automaticamente o estado atual do repositório e sugerir próximos passos apropriados.

## 🎯 Funcionalidades

### Detecção Inteligente de Contexto
- Verificar se Git Flow está inicializado no repositório atual
- Identificar branch ativa e sugerir workflows apropriados  
- Detectar estado do projeto e recomendar próximos passos
- Integração com @gitflow-specialist para guidance avançada

### Sistema de Ajuda Estruturado
- **Help geral**: Visão completa de todos os comandos disponíveis
- **Help específico**: Documentação detalhada por comando individual
- **Troubleshooting**: Soluções para problemas comuns
- **Quick reference**: Comandos essenciais por situação

## 🚀 Como Usar

```bash
/git/help                    # Help completo interativo
/git/help feature           # Ajuda específica para features
/git/help release           # Ajuda específica para releases  
/git/help hotfix            # Ajuda específica para hotfixes
/git/help init              # Ajuda para inicialização
```

## 📚 Fontes

A ajuda detecta o estado do repositório e aponta para a **fonte única** de cada workflow em [gitflow-patterns.md](../../../docs/knowledge-base/frameworks/gitflow-patterns.md) (Templates 1-6, semver, sessão). Para dúvidas ad-hoc/recovery, o mentor é `@gitflow-specialist`. Operações de host remoto (PR/CI/Release) → [`utils/forge/`](../../utils/forge/README.md).

## 📋 Comandos Disponíveis

### Setup e Inicialização
- `/git/init` - Configurar Git Flow no repositório
- `/git/help` - Este sistema de ajuda

### Ciclo de vida GitFlow — dispatcher único `/git:flow`
- `/git:flow feature start "nome"` · `/git:flow feature publish` · `/git:flow feature finish`
- `/git:flow release start "versão"` · `/git:flow release finish`
- `/git:flow hotfix start "nome"` · `/git:flow hotfix finish`

> `<tipo>` = feature|release|hotfix · `<ação>` = start|publish(só feature)|finish. Matriz completa em [`flow.md`](flow.md).

### Sincronização e commit
- `/git/sync [branch]` - Sincronizar após merge de PR
- `/git/fast-commit` - Adicionar tudo e commit rápido

## ⚠️ Troubleshooting Comum

### Repository não inicializado
**Problema**: Git Flow não configurado
**Solução**: Execute `/git/init` para configuração automática

### Branch errada
**Problema**: Não está na branch correta para operação
**Solução**: Use comandos Git Flow que fazem checkout automaticamente  

### Conflitos de merge
**Problema**: Conflitos durante operações GitFlow
**Solução**: Resolva conflitos manualmente e continue com comando finish

### Estado inconsistente
**Problema**: Operação GitFlow interrompida
**Solução**: ver [§Template 6 — Resolução de Conflitos](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-6-resolução-de-conflitos); recovery complexo → `@gitflow-specialist`

## 💡 Próximos Passos Sugeridos

O sistema detectará automaticamente sua situação atual e sugerirá:

- **Se Git Flow não inicializado**: `/git/init`
- **Se em develop**: `/git:flow feature start "nome-da-feature"`
- **Se em feature branch**: `/git:flow feature finish` ou `/git:flow feature publish`
- **Se pronto para release**: `/git:flow release start "versão"`
- **Se problema em produção**: `/git:flow hotfix start "correção"`

---

*Fonte canônica dos workflows: [gitflow-patterns.md](../../../docs/knowledge-base/frameworks/gitflow-patterns.md). Mentor para guidance contextual: `@gitflow-specialist`.*
