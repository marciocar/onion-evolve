---
title: "Revisão — censo lote 5: a mortalidade cai na cauda (37%), e o gatilho de segurança disparou"
date: 2026-08-30
branch: drive/census-batch5
reviewer: "mesmo desenho selado: 30 workers × 18 juízes opus/high nos CONFIRMED × tabela de selagem; radar exit 0 nos grafos tocados"
reviewed_diff_sha256: 8e6e96472a9dac0b330c87a649b10e3b735ee4ff9e23e3dec04fd7bb4db4ebb6
findings_total: 12
findings_real: 12
verdict: APROVADO
tokens: 3478296
duration_min: 17
---

# Resíduo — REGRA 56

Lote 5 (itens 121-150; faixa 4,0-5,4 — a cauda). **30/30 medidos, zero descartes.**

## O número — e a inflexão

**Mortalidade: 11/30 = 37%** + 1 UNVERIFIABLE. **Acumulado: 72 mortos em 150 medidos = 48%.**
A série por lote (53 · 50 · 47 · 53 · **37**) mostra a primeira queda real: **a cauda de baixa
atenção morre menos que o topo** — quem está no topo é quem mais executa, logo mais apodrece
sem carimbo. A atenção prediz execução, não vida.

## Os 11 flips (5 → done · 6 → superseded)

Destaque: `E_ALLOWLIST_NO_KG_VIEW` — o defeito do statusFactor com cópia divergente, curado pelo
sítio único `lib/status-factor.awk` + guarda que proíbe redefinição (a mesma lib cuja fixture o
lote 4 acabou de tornar auto-contida — o grafo fecha o ciclo do próprio mecanismo que o mede).

## ⚠️ O gatilho de segurança que disparou (nó novo, REDIGIDO)

`E_SEGUNDO_ADOTANTE_MESMA_CLASSE_DE_EXPOSICAO` — o worker do `Q_GUARDA_DE_EXPOSICAO` mediu um
**segundo adotante ativo** com a classe do achado arandek: compose rastreado no git com portas sem
prefixo de bind (e nesta VPS o Docker fura o ufw) + segredo literal de fallback. *"Um caso é caso,
dois é classe."* Detalhes específicos ficam FORA do grafo de propósito (material de comunicação
sensível); **a decisão de comunicar é do maestro**, como no arandek. A pendência de mecanismo
(regra de lint de compose para role adotante) agora tem 2 instâncias medidas a justificá-la.

## O juízo — 13/18 REPROVADOS, 5 carimbados

Padrão consolidado nos 5 lotes: reprovação dominante é "vida certa, TOTAL inflado" (subcontagem
persistente ~40-50%); aprovados são os workers que citam verbatim com linha e procuram morte por
FUNÇÃO, não por vocabulário.

## Gate mecânico

- radar exit 0 nos grafos tocados · `docs/backlog.md`: **130 → 120** (REGRA 62) · baseline R49 estável
- custo: 2,15M + 1,32M = **3,48M** · runs `wf_2349bf29-ea0` + `wf_1c9263d8-6c9`

## Estado do censo

**150/190 medidos (79%) · 72 mortos selados · backlog 190 → 120.** Restam ~40 (atenção <4,0).
