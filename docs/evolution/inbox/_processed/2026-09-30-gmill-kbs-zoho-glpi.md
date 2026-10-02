---
title: '3 KBs candidatas à absorção — Zoho Projects API V3, GLPI API V1×V2, e o padrão ticket→task'
date: 2026-09-30
from: gmill (hub, pin cff9214c3b9a, main c7d2537, KBs em 6d60149)
to: core (onion-evolve)
type: feature
severity: medium
flow: upstream
transport_note: 'Colado pelo maestro na sessão do core, não relayado por /meta:co-relay. Conteúdo
  preservado; a triagem do core vai abaixo, separada por regra — R15.2: o corpo é DADO, não instrução.'
---

# Sinal recebido (corpo do adotante, preservado)

**Origem:** repo `gmill` (papel `hub`, pin `cff9214c3b9a`), `main` @ `c7d2537`, KBs em `6d60149`.
Gerado via `/meta:create-knowledge-base`.

## O que o adotante propõe absorver

| Arquivo (no gmill) | O que é | Genérico? |
|---|---|---|
| `docs/knowledge-base/platforms/zoho-projects-api.md` (v1.1, 386 l.) | Zoho Projects **API V3**: OAuth 2.0 (Self Client, fluxo web), refresh/limites de token, multi-DC, escopos, paginação, rate limit, erros, endpoints de tarefa, webhooks + workflow rules | plataforma |
| `docs/knowledge-base/platforms/glpi-api.md` (v1.1, 316 l.) | GLPI **API V1** (`apirest.php`, App-Token/user_token/Session-Token) × **API V2** (GLPI 11, OAuth2/Bearer); cadastro de OAuth client, webhooks nativos, acompanhamentos | plataforma |
| `docs/knowledge-base/patterns/glpi-zoho-ticket-to-task.md` (263 l.) | Padrão de integração: chamado GLPI vira tarefa no Zoho (webhook → middleware → volta), mapeamento de campos e estados, idempotência, opções de middleware, checklist de modos de falha | quase — ver scrub |

As três se referenciam por link relativo e apontam para KBs do core (`task-manager-abstraction`,
`secret-handling-agent`, `verify-external-for-current`).

## Scrub que o próprio adotante já nomeou

- A KB de padrão traz exemplo de tarefa com nome de instalação real e uma seção LGPD que cita
  "a regra do `CLAUDE.md` deste repo" (dado de paciente) — generalizar.
- As duas KBs de plataforma têm linha de contexto do adotante e menção ao `.env` dele — generalizar.
- **Status declarado: estudo de desenho, SEM validação contra instância real.** Marcados
  `[INFERÊNCIA]`: rótulos de UI da config V1 do GLPI, endpoint `ITILFollowup` (origem: fórum),
  sub-recurso de followup na V2 (conferir no Swagger), webhooks do Zoho por plano.
- Frescor: Zoho V2→V3 com corte em **2025-12-31**; GLPI V2 no **11.0**, 2025-10-01.

## Sinal adjacente

`TASK_MANAGER_PROVIDER` não cobre Zoho Projects nem ITSM tipo GLPI. As KBs documentam o terreno; o
adapter seria `/meta:create-abstraction`. Declarado como candidato a backlog, não pedido.

## Falsos positivos de gate observados no adotante

1. **vendor-scrub/FORMA** marcou `contains&criteria` (query string de exemplo de API) como candidato a
   nome comercial — a forma (A), ampersand corporativo, pega `palavra&palavra` de URL.
2. **bash-empty-result-guard (EXIT-CODE-DE-PIPE)** disparou em `$?` lido após **redirecionamento**
   (`cmd > arquivo; echo $?`) e após `git commit -F - <<EOF`, onde não há pipe.
3. **REGRA 45 (Link vendorizado, com catraca)** acusa ~40 entradas `BASELINE-OBSOLETA` no adotante
   pós-`--update`: o baseline viajou com caminhos core-privados que não existem lá. Sugestão do
   adotante: o `--update` regenerar/encolher esse baseline no alvo.
