---
title: 'Diretriz candidata — ATUAL/emergente/popular ⇒ DEVE verificar externo (web), nunca do cutoff'
date: 2026-07-19
from: sessão de core-dev (branch discuss/onion-pessoal-app, na VPS)
to: onion-evolve (core / sala de design)
type: doctrine-candidate (co-evolução, fluxo upstream)
status: novo — triagem pendente (/meta:co-evolve)
re: research-first / declarado≠verificado / SSOT-as-runtime (verify leg) — pedido explícito do maestro de recomendar ao core
---

# Sinal: forçar a busca externa quando a pergunta aponta pra algo ATUAL/emergente/popular

> Pedido explícito do maestro (2026-07-19): *"SEMPRE que a pesquisa ou pergunta apontar algo atual, emergente,
> popular, você DEVE buscar informações fora (por exemplo a internet). Esta diretriz deve ser recomendada à sessão core."*

## A diretriz (candidata a doutrina)

**Trigger** = a pergunta/pesquisa toca **versão · device · projeto · player · framework · tendência** (qualquer coisa
*current/emerging/popular*). **Ação obrigatória** = **buscar EXTERNO** (WebSearch/WebFetch) **ANTES de afirmar** — nunca
responder do conhecimento de cutoff/priors. Sem verificar (orçamento esgotado / bloqueio) → **DECLARAR "não verificado"**
e parar, nunca apresentar prior como fato. É `declarado≠verificado` sharpado numa **forcing function com gatilho explícito**.

## Evidência de campo (esta sessão)

- **Quase afirmei versões do stack do cutoff** (Expo SDK **52**) — o drive-to-verify (npm ao vivo) pegou **57** (drift de 5 majors).
- Specs de **device 2026** (Poco X8 Pro Max) — não sei de cabeça; a diretriz me obrigou a buscar (WebFetch), e a honestidade
  a declarar "não verificado" quando o WebSearch esgotou + GSMArena bloqueou.
- Detalhe operacional útil ao core: **`WebFetch` é budget SEPARADO do `WebSearch`** — quando o WebSearch esgota na sessão,
  o WebFetch ainda verifica URLs conhecidas (fallback real).

## Direção proposta (o core prevê + cabeia)

1. **Cabear no fluxo de pesquisa** (`/meta:orchestrate`, skill `onion-orchestration`, comandos de research): passo/afordância
   **"claim sobre atual/emergente/popular ⇒ verify externo obrigatório; senão marcar não-verificado"** — mecanismo, não conselho.
2. **KB/doutrina:** promover a `research-first-over-priors` (ou nova KB) o **gatilho explícito** (current/emerging/popular) +
   o fallback WebFetch-quando-WebSearch-esgota + o "declarar não-verificado" como saída honesta.
3. Espelha o `verify(vivo)` do ciclo SSOT-as-runtime — aqui aplicado ao **mundo externo**, não só ao KG.

## Onde vive a evidência
`docs/discussions/onion-pessoal-app/` (o drift de versão está em `research/compat-research-2026-07.md` + `E_VERSIONS`/`E_COMPAT`
no KG). Staged na inbox desta branch; **relayar à inbox da main** para `/meta:co-evolve` triar.
