---
title: 'KG-SDAAL ganha camada de DOMÍNIO + modo map + console visual'
date: 2026-07-10
from: onion-evolve (core / maestro principal)
to: pulse-mais (Pulse Mais — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-10 (downstream, conciliação de backlog)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — KG-SDAAL ganha camada de DOMÍNIO + modo map + console visual

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do
> CHANGELOG do core por `/meta:co-announce` (conciliação de backlog `alvo: todos`). O adotante é
> cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

## 2026-07-10 · KG-SDAAL ganha camada de DOMÍNIO + modo `map` + console visual · COMPATÍVEL · alvo: todos

- **`layer: domain`** no `.kg.yaml` (retrocompatível — grafo sem `layer` segue 100% audit):
  ontologia `entity/state/event/rule/invariant/policy` + arestas `HAS_STATE/TRANSITIONS(on)/EMITS/
  CONSTRAINS/READS/WRITES`. O grafo epistêmico (audit) `TRACES_TO` o SSOT de domínio (durável).
  **Radar-de-domínio** (`kg-radar.sh --domain`): 5 checagens de completude (estado-absorvente,
  EVENT-sem-efeito, STATE-sem-dona, RULE-sem-trace, fonte-única) — ⚠ atenção, não gate. Modo
  `--triples` p/ consumo por LLM. Crédito: 2º dogfood do **metagamify** (promoção schema+método;
  o motor de cada instância é soberano).
- **`/meta:kg map <área>`** (v1.2.0): PFR de mapeamento completo — inventário → contrato →
  `.kg.yaml` → radar → adaptador. 3 variantes por identidade: **UI → atom-map** (1 átomo = 1 fonte
  + 1 dono-de-exibição + 1 dono-de-escrita; `SourceTag`; ledger de de-dup; pergunta atômica por
  aba — crédito: artefato do **rhilo-app**) · **backend/API/funcionalidade → fatias de domínio** ·
  **jornadas/fluxos → máquina de estados** (estado-absorvente = drop-off do funil). Mapeie ANTES de
  redesenhar/refatorar — o contrato primeiro.
- **`kg-console.sh`**: `.kg.yaml` → HTML self-contained (grafo interativo + veredito do radar
  embutido). Projeção read-only dos próprios artefatos — o core não distribui componentes de front
  (`SourceTag` é sempre implementação local de cada adotante).
- Ação p/ adotantes: nenhuma obrigatória — chega via `/meta:adopt --update`. Sugestão: rodar
  `/meta:kg map` na próxima área que forem redesenhar.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Classe **COMPATÍVEL** — sem urgência. A mudança chega vendorizada via `/meta:adopt --update` no
  momento oportuno (ver a linha "Ação p/ adotantes" acima).
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/pulse-mais/2026-07-10-kg-dominio-map-console.md <repo-pulse-mais>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
