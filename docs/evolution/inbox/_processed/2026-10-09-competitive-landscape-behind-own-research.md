---
title: 'O panorama competitivo (L1 de mercado) ficou para trás da pesquisa do próprio core'
date: 2026-10-09
from: onion-curation (consumidor)
to: core (onion-evolve)
type: signal
flow: upstream (consumidor→core)
---

# O panorama competitivo ficou para trás da pesquisa do próprio core

## O que foi medido (core em `507e8522`, fontes primárias abertas em 2026-10-08)

`docs/business-context/03-market/competitive-landscape.md` foi atualizado pela última vez em 2026-07-13
(commit `134ed44d`). Desde então, a pesquisa do próprio core registrou fatos que o panorama não traz:

| Item | No panorama (2026-07-13) | Na pesquisa do core | Vivo (2026-10-08) |
|---|---|---|---|
| GitHub Spec Kit | `~90k★` (`:31`, repetido em `02-product/strategy.md:27`) | 120,2k em 2026-08-04 (`onion-identity-2026-07.kg.yaml:339`) | 140,5k★ (github.com/github/spec-kit) |
| Ruflo / Claude Flow | `~29k★` (`:38`) | não re-medido | 74,1k★ (github.com/ruvnet/ruflo) |
| Superpowers (obra/superpowers) | ausente | 2º mais instalado do catálogo oficial, 1.009.371 instalações (`plugin-directory-landscape-2026-09/SYNTHESIS.md:37`) | 297k★; em claude.com/plugins/superpowers (2026-10-08) o contador segue em 1.009.371, possivelmente congelado |
| gsd-core | ausente | citado como trajetória em 2026-08 (`claude-code-2.1-onion-2026-08/SYNTHESIS.md:70`) | open-gsd/gsd-core, 10,3k★; o repo antigo gsd-build/get-shit-done está arquivado |

O que **não** foi medido: as estrelas de BMAD, Agent OS e SuperClaude contra o panorama, e o capital de qualquer
um deles (Crunchbase e PitchBook não foram consultados).

## Efeito

O panorama é a camada L1 de mercado (`docs/business-context/`) que comandos e agentes leem como contexto.
Quem o lê vê o Spec Kit com 90k e o Ruflo como "categoria distinta" com 29k, e não encontra o Superpowers.
É justamente o concorrente que o próprio core mediu como o 2º bundle vertical mais instalado do catálogo
oficial. Pela caracterização da curadoria, que a dissecação ainda vai confirmar, ele está no mesmo movimento do
Onion: um método em skills e subagentes distribuído por plugin. A pesquisa existe,
mas não subiu para o L1.

## Pedido

Reconciliar o `competitive-landscape.md` (e a linha `:27` do `strategy.md`) com a pesquisa de 2026-08 e
2026-09, e decidir se o Superpowers entra como concorrente direto. Daqui sobe também, em separado, o 1º
estudo da curadoria, que é a dissecação do Superpowers. Ele trará o capital medido ou declarado como não verificado.

Origem: `docs/onion/graph/curation-domain.kg.yaml`, nó `E_CORE_LANDSCAPE_BEHIND_OWN_RESEARCH`, que
substitui `E_CORE_COMPETITIVE_LANDSCAPE_DRIFT`. Este último afirmava que o panorama citava o GSD como
ativo, mas o panorama nunca o citou. A correção veio da revisão adversarial feita antes do relay, que deu CORRIGIR com 3 achados, todos aplicados.
