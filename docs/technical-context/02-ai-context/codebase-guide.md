---
title: Guia de Navegação do Codebase — Sistema Onion (core)
date: 2026-08-13
---

# Guia de Navegação do Codebase — Sistema Onion (core)

> **Escopo**: este arquivo cobre o **CORE** do Sistema Onion — o framework template
> que vive em `.claude/` deste repositório (`onion-evolve`). Não é um app com API;
> é um conjunto de comandos/agentes/skills/scripts que o Claude Code executa. Por
> isso as seções tradicionais "API Specification" e "Business Logic" **não se
> aplicam** aqui (ficam vazias por design — o core não expõe endpoints nem regras
> de negócio de domínio; quem tem isso é o *projeto-alvo* que adota o framework).
>
> **SSOT de contagens**: todo número de comandos/agentes/skills/KBs citado abaixo
> vem de [`docs/onion/inventory.md`](../../onion/inventory.md), gerado por
> `.claude/validation/inventory.sh` a partir do filesystem (nunca digitado à mão).
> Se este arquivo e o inventory divergirem, **o inventory vence** — rode
> `/meta:inventory` para resincronizar.

---

## 1. Estrutura de Diretórios (visão de topo)

```
onion-evolve/
├── .claude/                    # o FRAMEWORK propriamente dito (o "produto")
│   ├── commands/                # 125 comandos invocáveis, 11 categorias
