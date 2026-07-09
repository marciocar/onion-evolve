---
title: 'KG-SDAAL: des-gate já ocorrera (sua visão do core está stale) + camada de DOMÍNIO aceita para promoção (schema+método)'
date: 2026-07-09
from: onion-evolve (core / "mestre")
to: metagamify (MetaGamify — consumidor)
re: seu sinal 2026-07-08 (KG dogfood completo; promover ao core e des-gate do /meta:kg)
type: downstream-response
classe: COMPATÍVEL
status: ENVIADA (triagem 2026-07-09, confirmada pelo maestro)
---

# 📣 Resposta do core — dogfood reconhecido; metade do pedido já estava feita

> Resposta ao seu sinal upstream (KG-SDAAL passou de proto-audit a SSOT de domínio; 111 nós/170 arestas,
> radar-de-domínio, Fase-2 embeddings). Triado no core; veredito por item.

## Item 1 — "Des-gate o /meta:kg": **JÁ FEITO em 2026-07-04** (sua visão do core está stale)

O `/meta:kg` **existe e nunca esteve gated no core atual**: nasceu em 2026-07-04 do 1º dogfood do
próprio core (auditoria `/meta:evolve`), como F2 da vertical onion-investigation — e foi **anunciado
a vocês** no `inbound/` (`2026-07-04-meta-kg-nasceu-f2.md`, hoje possivelmente em `_processed/` aí).
Seu sinal foi escrito da branch `audit/oraculo-integration`, cuja cópia vendorizada do Onion antecede
esse ciclo. **Ação recomendada:** `/meta:adopt --update` para re-sincronizar a visão do core
(o mesmo dado stale reaparece no seu mapa de consolidação — ver resposta irmã de hoje).

## Item 2 — Camada de DOMÍNIO: **ACEITA como feature de promoção** (é genuinamente nova no core)

O KG do core hoje é **epistêmico** (claims/evidência/decisões, `SUPPORTS/REFUTES/SUPERSEDES`,
planes DEV/PROD). O que vocês construíram por cima — e que o core **não tem** — é:

- ontologia de domínio `ENTITY/STATE/EVENT/RULE|INVARIANT/POLICY` + arestas
  `HAS_STATE/TRANSITIONS(on)/EMITS/CONSTRAINS/READS|WRITES/TRACES_TO`;
- as **5 checagens do radar-de-domínio** (estado-absorvente, EVENT-sem-efeito, STATE-sem-dona,
  RULE-sem-trace, `--triples`);
- o padrão **Fase-2 semântica** (embeddings + cosseno para flag de redundância).

Entra no **backlog do core** como extensão de `knowledge-graph-sdaal.md` (KB doutrinária) +
`/meta:kg` + `kg-radar.sh`. Promoção respeita a soberania já pactuada
(`2026-07-04-kg-primeiro-dogfood-federacao`): **viaja schema + método, nunca o código** — cada
instância implementa seu motor.

## Item 3 — Distinção epistêmico×domínio + ressalva do `layer`: **aceitas como recomendadas**

Adotamos a distinção como doutrina (grafo de auditoria efêmero `TRACES_TO` grafo de domínio durável)
e **seguimos sua recomendação**: campo `layer` no mesmo `.kg.yaml` (menos maquinário, reusa
parser/radar); separação em arquivos só se a escala pedir.

## Ação esperada no adotante
- Classe **COMPATÍVEL** — nenhuma ação obrigatória. Recomendado: `/meta:adopt --update` (item 1).
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.
