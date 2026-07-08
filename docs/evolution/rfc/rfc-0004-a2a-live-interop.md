---
title: 'RFC-0004 — Interop L3 ao vivo resiliente (A2A) com aceitação gated'
status: draft (stub — aberto para triagem/discussão; ainda NÃO decidido)
canonical-in: onion-evolve (core) — série de RFCs de co-evolução
drafted-in: onion-evolve (2026-07-08, follow-up 2 da co-evolução)
origin-signal: docs/evolution/inbox/_processed/2026-07-08-proposta-branch-onion-vendor.md (§ "Síntese estratégica 2026", Dim 3)
evolves: RFC-0001 (que lista "runtime IA-fala-IA (A2A)" como NÃO-objetivo — este RFC reabre esse fio deliberadamente)
defers-to: RFC-0003 (identidade federada / inteligência coletiva)
---

# RFC-0004 — Interop L3 ao vivo resiliente (A2A) com aceitação gated

> **Estado: STUB.** Registra o problema, a hipótese e as perguntas abertas para uma discussão futura.
> **Não é decisão.** O modelo vigente (RFC-0001) — git-async, maestro humano, sem IA-fala-IA — **permanece**
> até que este RFC seja aceito. Nada aqui deve ser implementado antes disso.

## 1. Contexto

A RFC-0001 fixou a co-evolução como **git-async deliberado** (doc-bridge markdown commitado; o humano é o
maestro; sem runtime IA-fala-IA) e listou **A2A como não-objetivo explícito**. Esse git-async é parte do
**moat** — o controle vem de ser assíncrono e gated por humano, não apesar disso.

A pesquisa de 2026-07-08 (sinal de origem) identificou o **A2A (Agent2Agent)** como o padrão-comunidade
vigente para interop ao vivo resiliente entre agentes. Este RFC pergunta: **dá para ter interop ao vivo
SEM perder o moat do controle gated?**

## 2. Problema

Quando a coordenação cross-repo precisa ser mais rápida que o ciclo "maestro transporta markdown à mão"
(ex.: frota de adotantes na mesma máquina; sinal urgente; federação com nº de membros que torna o
roteamento manual custoso — o gatilho de graduação já previsto na RFC-0001), o git-async vira gargalo.
Mas trocar por IA-fala-IA irrestrita **destruiria o moat** (aceitação deixaria de ser gated por humano/tipo).

## 3. Hipótese (a explorar, não decidida)

Interop ao vivo é compatível com o moat **se e somente se a aceitação continuar gated por tipo/camada**.
Os elementos que o sinal levantou:

- **Transporte resiliente**: streaming quando conectado + **webhook push quando offline** (recebe/retoma)
  + **checkpoint durável** — o membro offline não perde o sinal, retoma ao voltar.
- **Aceitação gated tipada**: o trust model do `members.yaml` (`can_receive_from` / `can_advise_to` /
  `can_correct_to`) **já É** a política de aceitação. Falta só o **transporte ao vivo** por cima dela.
  A ponte que preserva o controle: nenhuma mensagem ao vivo é auto-aplicada — ela entra pelo mesmo gate
  tipado do doc-bridge (proposta → confirmação do maestro), só que com latência menor.
- **Camada**: é interop **L3** (governança/co-evolução), não L1 (capacidade, já resolvida por plugin) nem
  L2 (docs, via adopt).

## 4. Não-objetivos (deste stub)

- Decidir adotar A2A. Isto é um convite à discussão, não um veredito.
- Auto-aplicação de mensagens ao vivo (violaria o gate humano — fora de cogitação).
- Substituir o doc-bridge git-async (ele continua o system-of-record e o fallback).

## 5. Perguntas abertas (para virar RFC aceita)

1. **Gatilho**: qual custo/latência do git-async justifica ligar o transporte ao vivo? (herda o gatilho de
   graduação da RFC-0001 — contrato quebrável ou nº de membros).
2. **Superfície mínima**: dá para pilotar só o caso "frota na mesma máquina" (transporte local, sem rede)
   antes de qualquer coisa em rede? (espelha o `co-relay`/`co-deliver` carteiro-local, mas ao vivo).
3. **Fail-safe**: sem gate válido ou sem output tipado → **veto** (mesma doutrina do `federation-check`:
   ausência de aprovação = bloqueio). Confirmar que o A2A herda isso.
4. **Doutrina**: isto muda o "git-async deliberado" da RFC-0001 de invariante para default-com-exceção-gated?
   Precisa do aval explícito de que o moat sobrevive.

## 6. Relacionados
- RFC-0001 (modelo git-async — o que este evolui) · RFC-0003 (identidade federada) · `/meta:federation-*`
  (a graduação já implementada) · `members.yaml` (a política de aceitação que já existe).
- Família **declarado ≠ verificado**: uma mensagem ao vivo "declarada" só vale quando "verificada" pelo gate.
