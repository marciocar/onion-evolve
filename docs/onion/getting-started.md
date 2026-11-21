# 🚀 Guia de Início Rápido

> **Versão**: 3.0.1 | **Última atualização**: 2026-06-14

Bem-vindo ao sistema Onion v3.0! Este guia vai te ajudar a começar rapidamente com os comandos `.claude/` e integração com gerenciadores de tarefas através do **Task Manager Abstraction**.

## 📊 Visão Geral v3.0

| Componente | Quantidade | Descrição |
|------------|------------|-----------|
| Comandos | 124 | Organizados em 11 categorias + root |
| Agentes | 51 | 9 categorias especializadas |
| Skills | 16 | Orquestração, validação, pesquisa e resolvers de contexto |
| Knowledge Bases | 117 | Documentação estruturada |

## 📋 Checklist de Setup

### **✅ Pré-requisitos**

#### Software necessário

| Ferramenta | Versão mínima | Verificar |
|-----------|---------------|-----------|
| **Claude Code** | v0.43+ | `claude --version` |
| **Node.js** | v22.14.0+ | `node --version` |
| **Git** | v2.30+ | `git --version` |

```bash
# Verificar todas as dependências de uma vez
node --version   # v22.x.x
git --version    # git version 2.30.x ou superior
```

#### Checklist de pré-requisitos
- [ ] **Node.js v22.14.0+** instalado
- [ ] Claude Code instalado e configurado
- [ ] Git inicializado no projeto
- [ ] Pasta `.claude/` presente no projeto

### **📁 Estrutura de Diretórios**

Após instalar o Sistema Onion no projeto, você deve ver a seguinte estrutura:

```
seu-projeto/
├── .claude/
│   ├── commands/           # 124 comandos em 11 categorias
