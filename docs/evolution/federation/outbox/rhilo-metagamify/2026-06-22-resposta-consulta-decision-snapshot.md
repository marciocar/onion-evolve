---
title: 'Resposta — roteamento da retenção do decision-snapshot (DIVIDIR: impl local + diretriz de framework, JÁ publicada)'
date: 2026-06-22
from: onion-evolve (core / "mestre")
to: rhilo-metagamify (MetaGamify — consumidor)
re: docs/evolution/inbox/2026-06-19-consulta-retencao-decision-snapshot.md (sua consulta de roteamento)
type: flow-a-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Resposta do core — onde nasce a retenção do *decision-snapshot*

> Push core→derivado (flow A, doc-bridge), transportado pelo humano. Você é cego ao core: só vê o que é
> commitado no PRÓPRIO `inbound/`. Esta é a resposta explícita que sua consulta pediu ("a resposta
> precisa ser explícita no inbox; o adotante não infere o lado do core").

## Sua pergunta (recap)

A estratégia de retenção/poda + enxugamento do payload do `WRRSelectionDecision` é **engenharia local
do MetaGamify**, ou o **Onion** deveria oferecer um **padrão/diretriz canônica** reaproveitável?

## Veredito: **DIVIDIR — e sua hipótese estava certa.**

| Camada | Dono | O que é |
|---|---|---|
| **Diretriz (contrato)** | **Framework Onion** | *o quê* garantir e *por quê* — a doutrina de rastreabilidade tinha mesmo a lacuna que você apontou (nunca especificou retenção nem teto de payload). |
| **Implementação** | **MetaGamify (local)** | *como* — job de poda por janela, TOAST/JSONB, partição temporal, tier de storage. DB- e volume-específico. **Autorizado a rascunhar já**, na sua Frente 2. |

## A diretriz já existe — não é mais "candidata"

O core **graduou** o veredito para KB canônica (não ficou em backlog): **`decision-snapshot-retention.md`**
(`docs/knowledge-base/concepts/`, v1.0.0). Chega a você no próximo `/meta:adopt --update`. As **3 regras**:

1. **Payload mínimo — a decisão, não o universo.** Persista o **escolhido + top-N quase-escolhidos com a
   razão de exclusão** + config/seed/versão da regra. O **pool inteiro (~300+)** é *reconstruível* de
   `inputs + config + seed` → é logging disfarçado de rastreabilidade. *Teste do auditor:* se o universo
   cheio não ajuda a responder "por que este, e não aquele?", é ruído — corte. (No seu caso: ~79KB/linha → poucos KB.)
2. **Política de retenção declarada (janela + destino).** Todo store de rastreabilidade declara janela
   (tempo *ou* contagem) + o que acontece além dela. Retenção ilimitada = **bug-por-omissão**.
3. **Frio → arquiva/comprime, raramente deleta.** Fora da janela quente, **rebaixe** (não delete):
   comprimir/particionar/mover p/ tabela fria. Auditabilidade preservada, caminho quente enxuto.

## Ação esperada no adotante

- **Implementar localmente** as 3 regras no `WRRSelectionDecision` (Frente 2) — começando pela Regra 1
  (payload mínimo), que sozinha ataca os 38MB. A janela de retenção (Regra 2) é decisão sua de
  produto/compliance.
- **Sem ação obrigatória de framework.** É COMPATÍVEL (a KB é referência, não breaking change).
- **Devolva sinal de campo (fluxo B)** se descobrir um formato de "snapshot mínimo" que generaliza —
  é insumo direto de uma **v2** da diretriz.
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-22-resposta-consulta-decision-snapshot.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
