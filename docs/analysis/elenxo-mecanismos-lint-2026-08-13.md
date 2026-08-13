---
title: "Elenxo dos mecanismos de validação — o custo não é das 700 conferências"
date: 2026-08-13
category: analysis
status: reference
kg: docs/onion/graph/elenxo-mecanismos-lint-2026-08-13.kg.yaml
run_id: wf_167fa138-c0a
tokens: 565393
agents: 4
duration_min: 15
---

# Elenxo dos mecanismos de validação

> **Projeção do grafo, não fonte paralela.** Os achados vivem no `.kg.yaml` acima. Pedido do
> maestro: *"muitas automações .sh para lint com tempo e custo elevados, 700+ conferências num
> único arquivo — usar o Elenxo e revisar os mecanismos."*

## O run

4 lentes adversariais independentes (`sonnet`/`high`, paralelas, sem se verem) · 19 achados ·
241 tool-calls de medição · 565k tokens · 15min. Cada lente recebeu o perfil já medido como
ponto de partida e ainda mediu o próprio caminho — a lente 1 fez **patch A/B com diff de
veredito**, a 4 fez arqueologia git.

## A tese — e ela inverte o diagnóstico do pedido

**O custo não é das 700 conferências. É de ~6 guardas que ignoram o escopo.**

| medição | valor |
|---|---|
| lint completo | 86s (era **16s** no PR #357 — regressão 5,4×) |
| `--only` de 1 arquivo | **16,2s** no baseline |
| `--only` com o patch das lentes | **5,3s** — e `diff` de veredito **vazio** em 2 cenários |
| bancada | ~15min, com ~90-99 invocações `--only` — o custo multiplica |

O crescimento não foi o preço do escopo: guardas 2,19×, linhas 2,51×, **tempo 5,37×** —
concentrado em 3 guardas novas que nasceram sem o gate de `ONLY_PATH` que ~30 irmãs já tinham.

**As 4 lentes convergiram sem se ver** no mesmo vilão: `check_plugins_sync` (8,9s por invocação,
reassembla os 7 plugins a cada `--only`; na bancada, ~10,5-11,7 **minutos**).

## Backlog priorizado (proposto — o maestro decide)

### P1 — early-return `ONLY_PATH` nas guardas globais `[ganho MEDIDO: --only 16,2→5,3s]`
5 guardas ganham `[ -n "${ONLY_PATH}" ] && return 0` (padrão que já existe em ~30 irmãs):
`check_plugins_sync`, `check_bundled_command_script_deps`, `check_outbox_channel_exists`,
`check_role_bundle_sync`, `check_research_kg` (+ `check_agent_tool_names` pela lente 4).
Impacto composto na bancada: dezenas de minutos. **Risco provado nulo** nos 2 cenários A/B.

### P2 — `check_capability_conformance`: scope-filter, NUNCA blanket-skip `[cuidado provado por sabotagem]`
O selftest r20 a exercita via `--only` — blanket-skip a cegaria (provado injetando a fixture
`bad-overclaim`: saída vazia). E o scope-filter só funciona com `vdir` **normalizado**
(`vdir="$(cd "${vdir}" && pwd)"`) — bug pré-existente de path com `..` literal que nunca casa
com `ONLY_PATH` canônico.

### P3 — `sha1sum` em lote no `kg-verification-coverage.sh` `[ganho MEDIDO: 8,5s de 14,1s]`
**2.486 spawns** de `sha1sum`, um por nó do corpus. Lote único derruba a guarda mais cara do
lint para ~5-6s. Junto: `kg-view --assert-parity` gasta 5 subprocessos/arquivo quando o motor
tem modo combinado (12,3s → estimado -5-8s).

### P4 — higiene de verdade declarada `[1 linha cada]`
- comentário do pre-commit declara **44s**; o vivo é **86s** (declarado≠verificado no próprio hook)
- cabeçalho do `consumed-mode-check.sh` mente sobre o próprio wire-in

### P5 — os 6 scripts sem consumidor `[decisão do maestro, um a um]`
~690 linhas sem invocação de produção. **Cuidados:** `never-shutdown-vps-tools` (sem consumidor
= falta ligar, não licença para apagar); e `vps-exposure-check.sh` aparece como zero-consumidor
no grep mas roda por **systemd timer** — consumo se mede pelo runtime, não só pelo grep.

## O que as lentes disseram para NÃO fazer (tão valioso quanto o backlog)

- **Não** consolidar os 227 `mktemp` nem copiar menos de `docs/` — medido: a cópia é barata, não é lá que o tempo mora
- **Não** reduzir os 91 casos do manifest — cada fixture testa uma REGRA distinta
- **Não** paralelizar a bancada agora — depois do P1, sobra ~1-2min de ganho; antes, mascararia a causa
- **Não** mover `kg_view_sync` para CI-only nem deletar guardas do top-6 — todas têm incidente real no cabeçalho
- **Não** aplicar blanket-skip em `check_claude_md_counts`/`check_site_inventory_sync` — um arquivo novo escopado **muda** a contagem total; custo (0,8s) não paga o risco

## Teto declarado

A extrapolação "18min de bancada recuperáveis" **excede o total observado** (~15min) — a própria
lente rotulou: caching de kernel amortiza; o número confiável é o ganho **por invocação**
(10,9s). O ganho real da bancada só se mede aplicando P1 e cronometrando a suíte inteira.
