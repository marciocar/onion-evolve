---
title: 'Mapa de consolidação RECEBIDO — o "declarado ≠ verificado" está satisfeito; destilação em KB entra no backlog do core'
date: 2026-07-09
from: onion-evolve (core / "mestre")
to: metagamify (MetaGamify — consumidor)
re: seu artefato 2026-07-09 (mapa-SSOT da consolidação — pedido na resposta 'consolidacao-multibranch-framework-candidate')
type: downstream-response
classe: COMPATÍVEL
status: ENVIADA (triagem 2026-07-09, confirmada pelo maestro)
---

# 📣 Resposta do core — o destilável chegou e sustenta o framework-candidate

> Vocês responderam ao nosso pedido ("relaye o mapa-SSOT") com o artefato completo: vereditos da
> verificação 6-branch, build-green provado (tsc EXIT=0 nas 2 consolidadas), salvage 2/3 commitado,
> política de escopo de PR e sequência sob comando. Exatamente o que "declarado ≠ verificado" pedia.

## Veredito: **verificação aceita — insumo da KB candidata**

- O artefato confirma que o método **sai do contexto WRR/SLA**: 2 lanes (código×conhecimento),
  migração-antes-do-código, "nada fica pelo caminho ≠ tudo vai no PR", salvage antes de drop,
  build-green como prova — tudo agnóstico de domínio. **Destilação em KB de engenharia**
  (método de consolidação segura multi-branch) entra no **backlog do core**.
- O **schema de veredito** (`PROD-CANDIDATE | NEEDS-CHANGES | NEEDS-REBASE | STRAGGLER-DROP |
  SUPERSEDED-SALVAGE | KNOWLEDGE-LANE | SAFE-TO-DROP`) segue para o `@metaspec-gate-keeper` antes de
  canonizar vocabulário — como antecipado na resposta anterior.

## Correção de visão stale (importa para a sua lane conhecimento)

A seção "Sinal para o Onion source" do mapa afirma que o core tem *"0 refs a `.kg.yaml`, 0 a
`/meta:kg`, nenhuma skill de KG"*. **Isso não é mais verdade desde 2026-07-04**: o core tem
`/meta:kg` (v1.0.0), `kg-radar.sh` e a KB `knowledge-graph-sdaal.md`. O que falta no core é a
**camada de domínio** — e ela acabou de ser aceita para promoção (ver resposta irmã
`2026-07-09-resposta-kg-dogfood-domain-layer-aceito`). Ao executar sua lane conhecimento, ajuste o
alvo do "sinal ao source": não é "levar o KG ao core", é "estender o KG do core com a camada domain".

## Ação esperada no adotante
- Classe **COMPATÍVEL** — nenhuma ação obrigatória. Recomendado: `/meta:adopt --update` + ajustar o
  item 7 da sua sequência de consolidação conforme a correção acima.
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.
