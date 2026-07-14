---
name: help
description: Ajuda contextual da vertical {{PROJECT_TITLE}} — o que ela entrega e os próximos passos a partir do estado vivo.
model: sonnet
allowed-tools: Read Bash(git *)
category: {{PROJECT}}
tags: [help, {{PROJECT}}]
version: "0.1.0"
---

# 🧭 {{PROJECT_TITLE}} — Ajuda

Sem argumentos: mostro **o que a vertical {{PROJECT_TITLE}} entrega**, seus comandos, e os
**próximos passos** derivados do estado vivo do projeto.

## O que a vertical entrega

_(Descreva aqui o propósito da vertical {{PROJECT_TITLE}} — o problema que resolve, o fluxo principal.)_

## Comandos

| Comando | Finalidade |
|---------|-----------|
| `/{{PROJECT}}:help` | esta ajuda (sem input → o que faz + próximos passos) |
| _(adicione os comandos da vertical conforme forem criados)_ | — |

> **Prefixo por instalação:** o namespace pode aparecer como `/{{PROJECT}}:` (completo) ou como
> `/{{PROJECT}}-<algo>:` quando empacotado como plugin — cite o prefixo real da instalação.

## Próximos passos (estado vivo)

_(Leia o estado do projeto — branch, SSOT/book via a skill `{{PROJECT}}-context`, sessões — e
sugira o próximo passo concreto a partir dele. Nunca invente; se a SSOT não diz, declare.)_

## Troubleshooting rápido

| Sintoma | Ação |
|---------|------|
| "por onde começo?" | invoque o hub `{{PROJECT}}` (roteia a partir do estado) |
| "cadê a SSOT/book?" | skill `{{PROJECT}}-context` resolve/valida (e faz bootstrap do stub mínimo) |

## Fonte canônica

- Hub/roteamento: skill `{{PROJECT}}`
- SSOT/book: skill `{{PROJECT}}-context`

> Gerado por `bootstrap-new-project.sh`. Preencha as seções `_(...)_` com o domínio real.
