---
title: "Proposta: identidade própria do agente em cada ferramenta (app onde existe, usuário de serviço onde não)"
date: 2026-11-13
type: proposal
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: medium
status: open
reviewed_for_public: true  # repo privado (core/source); relido 2026-11-14 — regra genérica de identidade não-humana, sem segredo/credencial/pessoa
re:
  - docs/evolution/inbox/2026-11-13-proposal-agent-acts-with-requester-privilege.md
  - docs/evolution/inbox/2026-11-12-question-brain-posts-as-itself.md
---

# Proposta ao core: o agente com identidade própria em cada ferramenta

No chat o agente já tem identidade própria (o app). Nas demais ferramentas ele ainda age com a credencial pessoal
do maestro: arquivo criado no drive, página da wiki, card do gerenciador de tarefas e envelope de assinatura
aparecem em nome dele, e o trabalho para quando o cofre local do maestro está trancado. O maestro do hub pediu
em 13/11 que isso vire padrão da família, consultado ao core antes.

## Regra proposta

Em cada ferramenta, **identidade de app quando a plataforma oferece; usuário de serviço do agente só onde a
plataforma conhece apenas usuários**. Nunca a credencial pessoal de alguém.

| Ferramenta (tipo) | Identidade de app existe? | Caminho proposto |
|---|---|---|
| Chat de equipe | sim | app do agente (já em uso) |
| Suíte de escritório / drive | sim | conta de serviço da nuvem; arquivos num drive compartilhado do agente (conta de serviço não tem cota própria); e-mail só com delegação ou usuário |
| Gerenciador de tarefas | não (token é pessoal; app OAuth age em nome de quem autorizou) | usuário de serviço do agente |
| Wiki | não (token por usuário; login pelo provedor de identidade) | usuário de serviço do agente |
| Assinatura eletrônica | token da conta da empresa | conferir como a trilha registra o autor |

## O que pedimos ao core

1. Validar a regra e a tabela contra o que o mercado faz (identidades não humanas, contas de serviço).
2. Amarrar com a proposta do privilégio de quem pediu: a identidade própria diz **quem age**; o privilégio
   efetivo e o `on_behalf_of` dizem **em nome de quem e até onde**.
3. Kit de auditoria: registro de identidade não humana (dono humano, MFA onde couber, acesso mínimo, rotação de
   segredo, revisão periódica), na mesma matriz de acesso das pessoas.
4. Ordem sugerida de migração: drive e wiki (maior volume), depois tarefas e assinatura, e-mail por último
   (mandar e-mail como agente para fora pede regra própria).
