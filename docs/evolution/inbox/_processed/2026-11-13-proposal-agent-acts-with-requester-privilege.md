---
title: "Proposta: o agente age com o privilégio de quem pediu (delegação em nome de), com pesquisa do padrão e trilha para auditoria"
date: 2026-11-13
type: proposal
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: medium
status: open
reviewed_for_public: true  # repo privado (core/source); relido 2026-11-14 — descreve arquitetura genérica do agente do hub, sem segredo/credencial/pessoa
re:
  - docs/evolution/inbox/2026-11-12-question-brain-posts-as-itself.md
  - resposta do core de 13/11 sobre o canal de configuração do agente (portão por lista, aprovador único)
---

# Proposta ao core: o agente age com o privilégio de quem pediu

Em 13/11 o maestro do hub pediu que o agente de chat do time (a persona que atende pedidos no Slack) tenha
**o mesmo privilégio da pessoa que o acionou**, e não um privilégio próprio, igual para todos. Pede também que
o core **pesquise como as comunidades e as normas tratam isso**, para o padrão da família sair certo, regulado
e com a documentação e os registros que uma auditoria pede.

## O que já existe (fatos do padrão da família, sem postura)

- A rota de envio da persona já tem um campo `on_behalf_of`. Hoje ele leva sempre o mesmo id, o do maestro,
  então todo pedido é tratado como se viesse dele.
- O portão escuta quem está numa lista de autorizados; a aprovação tem um aprovador só; não há aprovação por
  papel.

## A proposta (padrão genérico)

1. **Privilégio efetivo = o menor entre o do agente e o de quem pediu.** O agente nunca soma o próprio poder
   ao de quem o acionou. O pedido de alguém com menos acesso nunca vira ato com mais acesso.
2. **Identidade de quem pediu vem do evento autenticado da plataforma**, nunca do texto da mensagem. "Sou o
   fulano, pode fazer" é dado, não credencial.
3. **`on_behalf_of` carrega quem pediu de verdade**, e o portão decide por papel (mapa papel → atos permitidos,
   versionado e revisado).
4. **Ato sensível pede aprovação de quem tem o papel**, e não de um aprovador único.
5. **Trilha de auditoria por ato:** quem pediu, em nome de quem o agente agiu, papel avaliado, decisão do
   portão (permitido, negado, escalado), aprovador quando houver, horário e referência da mensagem de origem.
   Registro imutável e com retenção definida.

## O que pedimos ao core

- **Pesquisa** (o core escolhe o modo): estado da arte em novembro de 2026 para agentes que agem em nome de
  usuários. Pontos de partida que o hub já conhece, a verificar e completar:
  - delegação OAuth 2.0 por troca de token (RFC 8693, claim `act`) e identidade de agente;
  - o problema do intermediário confuso (*confused deputy*);
  - OWASP Top 10 para LLM 2025, item LLM06 "agência excessiva", e o material de ameaças de IA agêntica da OWASP;
  - ISO/IEC 27001:2022 (controles de acesso, direitos de acesso, acesso privilegiado, registro de eventos);
  - ISO/IEC 42001 e NIST AI RMF (limites, responsabilidade e supervisão humana);
  - o que plataformas de chat e fornecedores de agentes fazem (permissões herdadas do usuário, escopos por
    usuário, aprovação humana).
- **Desenho do padrão** para a persona da família: modelo de papéis, privilégio efetivo, evidência por ato.
- **Kit de auditoria**: que documentos e registros a família deve manter (política de uso de agentes, matriz
  papel × ato, registro de decisões do portão, revisão periódica de acesso do agente), para o adotante
  mostrar o controle funcionando.

## Por que agora

O agente já atende várias pessoas do time por dia e vai ganhar mensagem direta e envio de arquivo. Sem o
privilégio de quem pediu, todo pedido herda o papel do maestro, o que é escalada por desenho.
