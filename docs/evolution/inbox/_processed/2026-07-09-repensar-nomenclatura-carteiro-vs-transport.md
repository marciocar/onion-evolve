---
title: 'Repensar nomenclatura: "carteiro-local" e outros vs o vocabulário federation-transport'
date: 2026-07-09
from: maestro (pensamento durante o F2.1)
to: onion-evolve (core)
re: consistência de vocabulário pós-federation-transport SDAAL
type: signal (backlog — não-bloqueante, refino de nomenclatura)
status: aberto — para triagem num /meta:co-evolve ou /meta:evolve
---

# Sinal — repensar nomes agora que o transporte é formal (F2.1)

## Contexto
O F2.1 (#313) formalizou o **federation-transport SDAAL** com o vocabulário `git-async | local | a2a-live`.
Isso torna alguns nomes pré-existentes **redundantes ou inconsistentes** com o novo eixo.

## Candidatos a repensar (não-bloqueante)
- **"carteiro-local"** (doutrina de `co-deliver.sh`/`co-relay.sh`) ↔ o **adapter `local`** do federation-transport:
  hoje descrevem a mesma coisa com nomes diferentes. Alinhar (ex.: "carteiro-local" → "transporte local", ou
  manter "carteiro" só como metáfora do ATO, não da via).
- Revisar se `outbox/`/`inbound/`/`inbox/` (canais do doc-bridge) se beneficiam de mapear explicitamente ao
  `git-async` adapter (são a implementação dele).
- Verificar outros nomes que a formalização SDAAL tornou ambíguos.

## Ação sugerida
Triar num `/meta:evolve` (dimensão redundância/nomenclatura) ou `/meta:co-evolve`. **Refino, não urgência** —
o vocabulário funciona; a inconsistência é cosmética/didática. Não mexer no meio de um slice; agrupar num
passe de nomenclatura próprio. Relacionado: RFC-0004 (F2.1 federation-transport), code-standards §7 (rótulos).
