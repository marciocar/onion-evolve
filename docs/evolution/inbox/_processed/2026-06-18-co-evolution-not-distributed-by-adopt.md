---
title: 'Furo: o modelo de co-evolução não é distribuído aos projetos pelo /meta:adopt'
date: 2026-06-18
from: sinal de campo (observado na sessão do rhilo-metagamify); registrado pela sessão-core
to: onion-evolve (core)
type: field-signal / framework-gap
severity: medium
flow: A (downstream) — lacuna de distribuição
status: aberto (proposta abaixo; ação = sessão-core futura)
---

# Furo — projetos nascem "surdos" ao modelo de co-evolução

## Sinal

Ao abrir uma sessão dedicada no `rhilo-metagamify` e rodar `/warm-up`, o modelo de co-evolução
(3 fluxos, ownership no core, ritual do maestro) **não apareceu**. A sessão do projeto fica sem saber
como falar com o core.

## Causa-raiz

1. **Memória é por-repo:** as memórias de coordenação vivem na pasta de memória do `onion-evolve`; a
   sessão do projeto carrega só a dela.
2. **`docs/evolution/` (canônico) NÃO é vendorizado** pelo `/meta:adopt` — o manifesto copia `.claude/`
   + `docs/meta-specs` + `docs/knowledge-base` + `docs/sdaal`, **não** `docs/evolution/`.
3. O `docs/evolution/` que o projeto tem é a versão **antiga** (rascunho pré-3-fluxos).

→ Resultado: o fluxo **A (core→projetos)** tem uma lacuna — o protocolo existe no core mas não chega
ao projeto. O projeto não sabe que deve usar o `inbox/` nem que o core é canônico.

## Proposta (decisão do core — não executar sem dono)

Opções (Pareto — preferir a mais barata que resolve):
- **(a) Starter mínimo no adopt:** o `/meta:adopt` planta no projeto um `docs/evolution/README.md`
  curto = "este projeto é consumidor; o protocolo canônico vive em onion-evolve; use o inbox do core
  p/ falar de volta; um escritor por repo" + um `inbox/` vazio. Barato; faz todo projeto nascer sabendo.
- **(b) Vendorizar `docs/evolution/`** inteiro no manifesto do adopt — mais pesado; arrisca divergência
  (cópia do protocolo no projeto). Provavelmente pior que (a).
- **(c) Warm-up aponta:** o `/warm-up` (ou `/product:warm-up`) do projeto passa a ler `docs/evolution/`
  se existir. Complementa (a).

**Recomendação:** (a) + (c). Manter o protocolo **canônico só no core** (sem cópia divergente); o projeto
recebe um **ponteiro** + o canal (`inbox/`).

## Próximo passo

Item de backlog do core. Quando uma sessão-core pegar: avaliar (a)+(c) contra o `/meta:adopt` real e o
warm-up, e abrir PR. Sem urgência — o workaround é o maestro briefar a sessão do projeto manualmente.
