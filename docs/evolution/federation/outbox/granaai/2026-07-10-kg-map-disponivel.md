---
title: 'KG-SDAAL ganhou camada de DOMÍNIO + modo map — mapeamento completo (sistema, API, funcionalidades, jornadas, fluxos) nos trilhos'
date: 2026-07-10
from: onion-evolve (core / maestro principal)
to: granaai (Grana.Ai — consumidor, regulated)
re: promoção da camada domain (PRs #315 + feat/kg-map-mode) — o método que o rhilo dogfoodou, empacotado para o próximo mapeamento (o seu)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core; entregar só após merge no core)
---

# 📣 Anúncio do core — `/meta:kg map <área>`: mapeie antes de mexer

> Push core→derivado (downstream, doc-bridge). Nenhuma ação obrigatória — é capacidade nova.

## O que chegou ao core

1. **Camada de domínio no KG-SDAAL** (`layer: domain` no mesmo `.kg.yaml`): ontologia
   `entity/state/event/rule/invariant/policy` + arestas `HAS_STATE/TRANSITIONS(on)/EMITS/
   CONSTRAINS/READS/WRITES`. O grafo de auditoria (epistêmico) `TRACES_TO` o de domínio (SSOT durável).
2. **Radar-de-domínio** no motor determinístico (`kg-radar.sh --domain`): estado-absorvente,
   EVENT-sem-efeito, STATE-sem-dona, RULE-sem-trace, fonte-única (>1 READS). ⚠ atenção, não gate.
   Modo `--triples` para consumo por LLM.
3. **Modo `map <área>` no `/meta:kg`** — o PFR de mapeamento completo (F0 inventário → F1 contrato →
   F2 `.kg.yaml` → F3 radar → F4 adaptador), destilado dos 2 dogfoods reais do rhilo-metagamify:
   - **UI → atom-map**: 1 átomo = 1 fonte + 1 dono-de-exibição + 1 dono-de-escrita; `SourceTag`;
     ledger de de-duplicação; pergunta atômica por aba.
   - **Backend/API/funcionalidade → fatias de domínio** ancoradas no código.
   - **Jornadas/fluxos → máquina de estados**: passos = `state`, avanço = `TRANSITIONS(on evento)`;
     o radar acha **drop-off de funil como estado-absorvente**.

## Por que interessa à Grana.Ai

O mapeamento completo que o rhilo fez (atomização do command-center + fatias WRR/SLA) é o mesmo
movimento que um mapeamento da Grana.Ai vai pedir — agora ele roda **nos trilhos** em vez de ser
reinventado. Para um domínio regulado, o subproduto importa: regras/invariantes com `TRACES_TO`
para o código é exatamente a rastreabilidade que auditoria pede.

## O que fazer (quando quiser)

1. `/meta:adopt --update` para puxar o core atualizado (traz `/meta:kg` v1.2.0 + `kg-radar.sh`).
2. Escolher a primeira área e rodar `/meta:kg map <área>` — sugestão: uma jornada de usuário ou o
   módulo que estiver para ser refatorado (o contrato primeiro, o refactor depois).
3. O que o mapeamento revelar de sinal (falta de expressividade na ontologia, tipo novo necessário,
   bug no método) → seu `inbox/` + relay ao core. É assim que o método evolui (foi assim com o rhilo).

- Tratado → `git mv` deste arquivo para `inbound/_processed/`.
