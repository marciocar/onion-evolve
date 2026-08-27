---
title: "Revisão — /meta:realign Fase 1 (a revisão em camadas do plano × o vivo)"
date: 2026-08-27
branch: feat/meta-realign-phase1
reviewer: "self-review (autor) + dogfood adversarial read-only do corpus real (fork, 73 grafos)"
reviewed_diff_sha256: d7aa1b06544cf4f85b093cc33029f4bcf6f610355d98b5cac9ba2bbedcaae086
findings_total: 4
findings_real: 1
verdict: APROVADO
tokens: 263000
duration_min: 55
---

# Resíduo — REGRA 56 (Fase 1 do /meta:realign)

A maquinaria de realinhamento em camadas que o reforço-prosa do maestro pedia, virada mecanismo
grafo-primeiro/radar-driven. Motor determinístico (`kg-realign-project.sh`) + comando fino
(`realign.md`, model: sonnet) + 6 fixtures + `run_realign_selftests` (6/6). Fundada na Fase 0
(`onion-kg-ontology-hierarchy.md`, merge #689).

## Método de revisão
Não foi só leitura: **dogfood por comportamento de cada tipo de drift** (5 fixtures com 1 drift
plantado de cada) + um **sweep adversarial read-only do corpus REAL** (73 grafos vivos, via fork,
sem escrita — I3). O sweep é o que dá lastro ao veredito: o motor rodou no corpus inteiro, não só
nos fixtures sintéticos.

## Achados

### 🔴 REAL #1 (corrigido no próprio commit) — binding-drift cego a SUPPORTS de ENTRADA
O sweep mediu **3 falsos-positivos num só grafo audit** (`claude-code-2.1-onion-2026-08`): decisões
que são ALVO de `evidence SUPPORTS decision` (apoio de entrada) eram marcadas "nó solto", porque a
regra só olhava vínculo de SAÍDA (`binding[from]`). Em grafo audit/research o padrão dominante é
`evidence→decision`, então a classe de FP era **sistêmica**. **Não afetava o gate** (bind é camada-3
informativa, não conta pro `agg` nem vira `REALINHAR`/`ATENCAO`), mas sujava o sinal.
**Cura:** `!(id in supports)` na condição de bind (1 linha; `supports[]` já era rastreado). **Virou
mecanismo:** fixture de regressão `bind-fp-supported-decision.kg.yaml` + caso na bancada. fix→re-dogfood
no mesmo loop — os 3 FPs sumiram, os 2 bind genuinamente soltos do grafo permaneceram, 6/6 verde.

### 🟡 LIMITAÇÕES DECLARADAS (não-defeitos, por desenho da Fase 1)
2. **Escopo do `--freshness-tsv`:** só nós "frescor-rastreado" (plane:PROD ou com `verified_against`)
   entram — nós DEV puros sem `verified_against` escapam da camada 2/3. Herdado do radar; declarado.
3. **binding confia na EXISTÊNCIA do `trace:`, não na validade do alvo** — decisão com `trace:` para
   artefato morto conta como vinculada (falso-negativo). Validar o alvo é mais fundo; Fase 1 declara.
4. **Camada 3 parcial:** o **nó north-star imutável** e a **ordenação `DEPENDS_ON` direcionada** (o
   radar não emite precedência — grau é não-direcionado por contrato do `fios-abertos`) são **Fase 2
   (gated)**. Hoje commitment/binding são aproximados pelos sinais disponíveis.

## Verificação (comportamento, não declaração)
- **Corpus real (73 grafos):** ALINHADO 71 · ATENCAO 2 · REALINHAR 0 · reprovou-Passo-0 0. As 2
  ATENCAO são drift custoso GENUÍNO (`autonomous-thread-runtime::D_RUNTIME_CONTRACT` STALE-MISSING com
  dependente; `onion-tier-matrix` idem) — a histerese cruzou 15 e virou ATENCAO como devia. 0 crash.
- **Fixtures:** cada tipo (a)/(b)/(c) + commitment/binding + clean + regressão → 6/6 na bancada.
- **Dente:** `--check` sai rc=1 SÓ no tipo-(c) (provado por `drift-c-unreconciled`); os demais informam
  sem bloquear.
- **Lint mecânico:** 0 HARD (os count-drifts em docs são SOFT item-16, padrão da casa; inventory.md +
  CLAUDE.md alinhados à SSOT, que são os HARD).

**Veredito: APROVADO** — 1 defeito real encontrado pelo dogfood e curado com mecanismo (fixture de
regressão), 3 limitações honestas declaradas, comportamento verificado no corpus inteiro. A camada 2
(Fase 2 gated) fica nomeada, não pré-cozida.
