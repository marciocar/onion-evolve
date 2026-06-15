---
name: init
description: Inicializar repositório com GitFlow e convenções padrão.
model: sonnet
allowed-tools: Grep Bash(git *)
category: git
tags: [init, gitflow, setup]
version: "3.0.0"
updated: "2025-11-24"
---

# 🔧 Git Flow - Inicialização

Configurar repositório Git com GitFlow seguindo as melhores práticas. Detectar automaticamente se deve usar `main` ou `master` como branch principal e configurar todas as branches e convenções necessárias.

## 🎯 Funcionalidades

### Detecção Automática Inteligente
- Verificar se Git Flow já está inicializado  
- Detectar branch principal existente (main/master) automaticamente
- Configurar develop branch baseado na convenção detectada
- Validar se repositório está em estado adequado para inicialização

### Setup Seguro e Educativo
- Configuração automática de prefixos GitFlow padrão (feature/, release/, hotfix/)
- Verificações de integridade do repositório antes da inicialização
- Criação da branch develop se não existir
- Integração com @gitflow-specialist para guidance personalizada

## 🚀 Como Usar

```bash
/git/init                    # Inicialização completa automática
```

## 📚 Motor GitFlow

O setup segue [gitflow-patterns.md §Template 1](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-1-setup-inicial-gitflow) — **fonte única** da detecção de branch principal, prefixos e validações. Para dúvidas ad-hoc ou recovery de estado inconsistente, consulte o mentor `@gitflow-specialist` (não é dependência de runtime do comando).

## 📋 Processo de Inicialização

### Verificações Pré-Inicialização
- **Repository check**: Verificar se estamos em um repositório Git válido
- **Status check**: Garantir que não há mudanças não commitadas
- **Remote check**: Verificar configuração de repositório remoto
- **GitFlow check**: Detectar se já está inicializado

### Configuração Automática
- **Branch detection**: Identificar main/master existente
- **Develop setup**: Criar develop branch baseada na principal  
- **Prefix configuration**: Configurar prefixos padrão GitFlow
- **Validation**: Verificar configuração final

## ⚙️ Configurações Aplicadas

### Branches Principais
```
main/master  (produção) ← detectado automaticamente
develop      (desenvolvimento) ← criado se não existir
```

### Prefixos de Branch
```
feature/     (novas funcionalidades)
release/     (preparação de releases)
hotfix/      (correções urgentes)
```

## ✅ Resultado da Inicialização

Após execução bem-sucedida:

- ✅ **Git Flow configurado** com branches apropriadas
- ✅ **Branch develop criada** e configurada como development branch  
- ✅ **Prefixos definidos** para todos os tipos de branch
- ✅ **Configuração validada** e testada
- ✅ **Próximos passos** fornecidos baseados no contexto

## 🔄 Próximos Passos Sugeridos

Após inicialização, o sistema recomendará:

- **Primeira feature**: `/git:flow feature start "nome-da-funcionalidade"`
- **Sincronização**: `/git/sync` se houver repositório remoto
- **Ajuda contextual**: `/git/help` para entender os workflows disponíveis

## ⚠️ Tratamento de Problemas

### Repository não é Git
**Problema**: Pasta atual não é um repositório Git  
**Solução**: Execute `git init` primeiro, depois `/git/init`

### GitFlow já inicializado  
**Problema**: GitFlow já está configurado
**Resultado**: Mostra configuração atual e próximos passos sugeridos

### Branch develop conflitante
**Problema**: Já existe branch develop com conteúdo divergente
**Solução**: ver [§Template 6 — Resolução de Conflitos](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-6-resolução-de-conflitos) ou consultar `@gitflow-specialist`

### Repositório remoto não configurado
**Problema**: Não há origin configurado
**Resultado**: Configuração local apenas, com sugestão de setup remoto

---

*Lógica canônica em [gitflow-patterns.md §Template 1](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-1-setup-inicial-gitflow). Mentor para dúvidas: `@gitflow-specialist`.*
