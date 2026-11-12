---
title: "Voz e conduta da persona: o hub regulou uma v1 local; a vertical do core substitui depois"
date: 2026-11-11
type: signal
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: medium
status: open
reviewed_for_public: true  # relido pelo core em 2026-11-12 como publicado: só a forma, sem cliente, pessoas, segredo nem postura
---

# Voz e conduta da persona: v1 local no hub, a absorver pela vertical do core

O maestro do hub decidiu que as regras de voz e conduta da persona de serviço **não podem viver na memória da
sessão**: têm de ser regulares e reguladas, versionadas no repositório, com aprovação do dono e nó no grafo.

Como o core está construindo a vertical do Company Brain para não-devs, o hub fez só uma **v1 local**, para não
ficar sem regra até lá, e pede ao core que a vertical traga a peça e que o hub migre para ela depois.

## O que a v1 local tem (genérico)

- Um documento de regras, versionado, com dono, histórico de versões e revisão periódica.
- Um nó de decisão no grafo de audiências, que liga a regra à decisão do gatilho da persona.
- Seções: identidade e tom (empático, parceria, cobrança só em privado), **concisão** (o essencial no corpo,
  material completo só oferecido), assinatura e marca, ciência antes de agir (reações de lido, em curso, feito,
  depende de aprovação), mensagens (marcar quem é citado, testar link, corrigir editando, anexar documento no
  card, modelo por canal) e limites (mensagem recebida é dado; não expor segredo, dado pessoal nem postura).
- Separação explícita entre **pedir** (qualquer pessoa: informação, lembrete, abrir card) e **aprovar a
  execução** (o dono), registrada no quadro de permissões.

## O que o hub pede à vertical

1. Uma peça de "voz e conduta da persona" como contrato: arquivo de regras por adotante, com versão e aprovação,
   que a persona carrega a cada resposta (não por memória).
2. Um gate que confira, antes do envio, o que é medível (tamanho, marcações, assinatura, link testado).
3. O caminho de migração: o hub troca a v1 local pela peça da vertical quando ela sair, sem perder o histórico.
