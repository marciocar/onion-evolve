---
title: 'Proposta da curadoria: dissecar qualquer objeto (app, categoria, ideia, prática, ator, ferramenta), com o desenho v4 e o protótipo curation-dissect medidos contra o /meta:dissect atual'
date: 2026-10-23
from: onion-curation
to: onion-evolve (core)
type: proposal
issue: SAC-226 (Linear), fases SAC-227 a SAC-233
answers: Q_DISSECT_OBJECT_SCOPE (onion-adoption.kg.yaml)
kg: docs/evolution/research/dissect-any-object-2026-10/dissect-any-object-2026-10.kg.yaml
decision_node: D_DAO_RULE_OUTCOME (open; o core sela)
---

# Dissecar qualquer objeto: o que medimos e o que propomos

Hoje o `/meta:dissect` disseca ferramenta de terceiro. O maestro pediu para dissecar também apps (ex.: Duolingo),
categorias de produto (ex.: bilhetagem), ideias e o resto, com a lista de famílias aberta e o destino declarado: se é do
Onion, chega ao core; se é de um projeto, fica no projeto; produto novo fica na curadoria. A curadoria desenhou,
forjou um protótipo pelo `/meta:forge` e o mediu contra o método atual por uma regra pré-registrada. Tudo está no grafo
do `kg:`, no repo da curadoria (PRs #58 a #64, merge `ca5639d`).

## O desenho (v4, `docs/curation/proposals/dissect-any-object-v4.md`)

- **Famílias registradas**, abertas, no perfil `x_term` do contrato (`docs/curation/registry/dissect-families.kg.yaml`):
  ferramenta, prática, ator, app, categoria e ideia. Cada uma diz o que o N0 a N4 provam, os vereditos válidos e o
  destino padrão. A família sai de uma ordem de predicados; família nova entra por PR antes do N0.
- **Etapa 0 pré-registrada:** `STAGE0.md` com 8 elementos e o nó `S_STAGE0` com `x_criterion` (contrato 4.12). O
  commit do plano é ancestral estrito do primeiro N0.
- **Veredito por família** (ator não absorve; categoria e ideia perseguem, com `x_dissect_pursue`).
- **Destino declarado:** `core` · `panorama` · `projeto:<slug>` · `projeto-novo`.
- **Superação buscada também na web** (o c1 mostrou que a busca só no repo não viu o FSRS, que supera a HLR).
- **Gatilho do parque persistente:** uma consulta `kg_query` numa lista branca, contando o que persiste (`SUPERSEDES`),
  nunca `drifted`.

## O protótipo (7 peças do `/meta:forge`, censo 6/7)

Skill fina, doutrina e lente; o workflow `.claude/workflows/curation-dissect.js` (v2: 3 agentes, plano, pesquisador e
refutador); o checador K3 dos 8 itens da §7 do desenho (`.claude/validation/curation-dissect-check.sh`), com bancada de
60 casos e 2 de rc 3, cobertura de todo código e mutante por código; e um CI próprio. A bancada não conta no censo
porque o `lint-selftest.sh` é vendorizado: a família `run_curation_dissect_selftests` sobe com esta proposta. O Elenxo
revisou a forja duas vezes (a 1ª reprovou, com 7 achados letais; a 2ª aprovou com emendas, aplicadas).

## A comparação (regra `SAC226_RULE`, v1 a v3, emendas datadas antes de cada julgamento)

| Objeto | A′ (dissect atual + brief) | B (protótipo) | K1 (juiz cego, 3 × 2 ordens) | K2 (custo) |
|---|---|---|---|---|
| c1 Duolingo (desenvolvimento) | 178 mil (2 réplicas, ruído 2,8%) | 671 mil, v1 | B 3 de 3 | 3,78× |
| c2 billing por uso | 185 mil | 258 mil, v2 | B 3 de 3 | 1,40× (reprova) |
| c3 kg_query × vetorial | 211 mil | 259 mil, v2 | B 2 de 3, 1 empate | 1,23× (passa) |

**Resultado pela regra: inconclusivo, sobe ao core.** No K1 o B vence c2 e c3 sem derrota; no K2 reprova no c2.

**O que o core precisa pesar:**
- No c2 o B rodou a implementação de referência com Docker, e o brief do A′ proíbe instalar. Os limites foram
  igualados antes do c3.
- No c3 dois juízes leram o `perseguir` do A′ como inválido. Para ideia ele vale, e o protocolo não mostrava ao juiz
  os vereditos da família.
- A amostra decisória tem 2 objetos, e um só modelo faz os braços e os juízes.
- Em todos os objetos os juízes cobraram do B o que o A′ faz melhor: medir no próprio corpus e dizer o próximo passo
  concreto. E cobraram do A′ o que o B faz melhor: quem paga em fonte primária, gatilho checável, lista específica do
  não verificado e superação medida.
- O custo vem da arquitetura (~38 mil de contexto fixo por agente). Ele caiu de 3,78× para 1,23× quando o B passou
  de 12 para 3 agentes.

## O que propomos (o core sela)

1. **Absorver as peças determinísticas, que valem independentemente da comparação:** o registro de famílias, o
   checador K3 com a bancada e a Etapa 0 pré-registrada. Elas curam três falhas medidas no c1: a busca de superação só
   no repo, o gatilho que contava estado transitório e o app sem superfície executável.
2. **Parquear o workflow como motor do `/meta:dissect` até um objeto decisório a mais, com o protocolo corrigido.**
   As correções são mostrar ao juiz os vereditos válidos da família e manter os limites iguais. **Gatilho:** esse
   objeto rodado, com o K1 e o K2 lidos. Se o B vencer de novo com custo até 1,25×, absorver.
3. **Fluxo por destino:** quando o core selar, a curadoria emenda o próprio CLAUDE.md (os vereditos por família e o
   destino declarado). Antes disso, nada muda lá.

**Quem paga:** é custo interno. Um estudo pelo B v2 custa cerca de 260 mil tokens, contra cerca de 200 mil do método
atual. Não abre via de bilhetagem.

**Não verificado:** o B com outro modelo; o efeito do vocabulário de família na projeção (corrigido só na proposta);
os vereditos de c2 e c3 contra o mundo, que ainda não foram selados.
