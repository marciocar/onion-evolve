---
title: 'Panorama competitivo: duas afirmações sobre a Tessl não se sustentam hoje'
date: 2026-10-14
from: onion-curation (consumidor)
to: core (onion-evolve)
type: signal
flow: upstream (consumidor→core)
---

# Duas afirmações do core sobre a Tessl não se sustentam em 2026-10-14

Origem: estudo C da curadoria (`onion-curation:docs/evolution/dissect/tessl-2026-10/`) e a linha de base
`/onion-research` (`onion-curation:docs/evolution/research/tessl-baseline-2026-10/`, run `wf_645d8c3a-2bb`).

## 1. "Registry de 10k+ specs" (`competitive-landscape.md:38`)

- **Medido em 2026-10-14:** o sitemap `https://tessl.io/sitemap.xml` lista **1.274 páginas de skill**
  (`/registry/<workspace>/<nome>`). Esse é um piso: o sitemap pode omitir páginas.
- **Fonte do número antigo:** nenhuma página atual da Tessl (`/`, `/registry`, `/pricing`) declara "10k". A API
  de busca (`api.tessl.io/experimental/search`) exige termo e não devolve total.
- **Leitura:** o número pode ter vindo do antigo "Spec Registry", que virou registry de skills e plugins.
  Isso é hipótese, não verificada.
- **Nó de origem:** `E_CORE_10K_SPECS_UNCONFIRMED`.

## 2. "Único produto mirando spec-as-source" (`B5_17_tessl_unico_as_source`, `federation-research-2026-06-reconciled.kg.yaml`)

- **Refutado na linha de base:** a afirmação "a Tessl é a única que persegue spec-as-source" foi refutada pelo
  Verify da rodada, com base no arXiv 2606.27045 (tier 6). O spec-as-source que aparece no registry é um
  plugin de terceiro (Giuseppe Di Canosa, sobre o OpenSpec), e não um produto da Tessl. Ver as linhas
  544-545 do grafo da linha de base, cuja narrativa não registra o placar da votação.
- **Indício de pivô:** o `llms.txt` da Tessl não menciona spec-driven nem spec-as-source, e o produto se
  apresenta como "skills are software" (`E_OBJECAO_PIVO_PARA_SKILLS`, `E_OBJECAO_NARRATIVA_SKILLS_CODIGO`).
  Atenção: esses dois nós vêm de 1 agente, sem votação.
- **Efeito:** a tensão com o `B5_17` fica aberta. O eixo spec-as-source deixou de ser o terreno de disputa
  com a Tessl.

## Também medido no estudo C (para a entrada da Tessl no panorama)

- **Capital:** US$ 124,5M em dois Form D de 2024; nenhum Form D em 2025 ou 2026.
- **Subsidiária britânica:** contas sem auditoria até jan/2025, com 14 funcionários e prejuízo de £2,71M
  em 11 meses. Em jan/2026 houve uma emissão de cerca de £17,5M em ações, provavelmente conversão da
  dívida com a holding.
- **Tração no npm:** de cerca de 2 mil para 64 a 69 mil downloads por mês em um ano, que é proxy inflável
  por CI.
- **Código e preço:** núcleo fechado; preço estável desde 2026-07-18.
- **Veredito da curadoria:** PARQUEAR, com gatilho em 2026-11-15, depois do prazo das contas da
  subsidiária (2026-10-31).

## Pedido

Revisar a linha 38 do `competitive-landscape.md` (número do registry e eixo spec-as-source) e reabrir o
`B5_17` com a medição acima. Esta mensagem é só sinal: a proposta do estudo C, com o veredito, sobe em
separado se o maestro quiser.
