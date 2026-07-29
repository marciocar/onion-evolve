---
date: 2026-07-29
instance: onion-evolve
type: learning
classification: collective
tags: [knowledge-graph, kg-console, visualization, ai-narration, dogfood, fix-must-become-mechanism, behavior-over-declaration, self-contained, federation-sovereignty]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: "Ao construir uma SUPERFÍCIE nova sobre um SSOT (visualizador, relatório, narração), grave a fronteira em MECANISMO no mesmo loop, não em promessa: a superfície que 'projeta' o SSOT tende a driftar dele (a narração que cita id morto, o plugin que empacota o script mudado, a contagem que a superfície afirma). Cada drift vira guard determinístico (REGRA/selftest/paridade) OU volta a mentir com cara de fiel. E prove a superfície RODANDO-A (headless + escala real 881 nós + o HTML aberto sem rede), nunca só lendo o código — foi rodando o selftest com o vendor de 461KB embutido que o bug latente pipefail+grep-q+SIGPIPE apareceu."
review_after: 2026-10-29
conflict_class: static
significance: "Fechei de ponta a ponta o VISUALIZADOR do KG-SSOT: o kg-console.sh saiu de um SVG de círculo estático (ilegível > ~30 nós) para um console Cytoscape rico, NARRÁVEL por IA e self-contained — 4 PRs verdes (#486 F1+F2+F4, #487 F5, #488 F3). O núcleo do pedido do maestro ('visualizar/interagir com o .kg.yaml e ser explicado por um agente de IA, ideal um HTML autocontido') virou recurso vivo do core, promovendo o que o estudo SEED deixara gated. Mas a lição DURÁVEL é a fronteira SSOT×superfície gravada em mecanismo: a narração é o único ponto com IA (o console segue LLM-free) e a REGRA 47 a impede de citar id que o grafo não tem; o que viaja na federação é o CONTRATO JSON, nunca o JS do renderer. E o fecho foi o dogfood auto-referente: o console renderizando e narrando o grafo do PRÓPRIO desenho — o instrumento provado em si mesmo, mostrando na escada de reconciliação onde o próprio plano mudou ao ser construído (fcose→cose, SEED gated→promovido)."
---

## O que fechou

O **visualizador do KG-SSOT** — a perna que faltava entre o `.kg.yaml` (bytecode) e o humano:

- **#486 (F1+F2+F4):** contrato de dados (`kg-view --json` enriquecido) + o console Cytoscape rico
  (encoding epistêmico: tamanho ∝ atenção, opacidade ∝ confiança, borda por status, halo âmbar =
  stale, aresta por SUPPORTS/REFUTES⊣/SUPERSEDES⇢; física, foco+dimming, busca, filtros combinados,
  toggle DEV/PROD, escada de reconciliação navegável, veredito com ids clicáveis) + **a IA que
  explica** (narração pré-cozida, modo `/meta:kg narrate`, tocada offline) + **REGRA 47** (o guard).
- **#487 (F5):** ADR de ratificação + nota na KB + o dogfood auto-narrado.
- **#488 (F3):** o brilho — partículas nas arestas, semantic-zoom, minimapa, scrollytelling.

Doutrina intacta em toda parte: **projeção read-only** (o veredito é do `kg-radar.sh`, não
recalculado), **console LLM-free** (a IA está só na autoria da narração), e **soberania de
federação** (viaja o contrato JSON + o método de encoding + o arco de narração, nunca o JS).

## A lição durável — a superfície DRIFTA do SSOT; grave a fronteira em mecanismo

Toda superfície nova que "projeta" um SSOT tende a se soltar dele. Apareceu três vezes, e cada uma
virou guard, não promessa:

| A superfície | Como driftaria | O mecanismo que gravou a fronteira |
|---|---|---|
| A narração (IA) | citar id que o grafo não tem → o console dropa em silêncio | **REGRA 47** + `kg-narrate-validate.sh` (HARD, 5 selftests) |
| O plugin `onion-work-tools` | empacota `kg-console.sh`; editei o script → o bundle ficou stale | tree_sha do plugin + regenerar (a REGRA de sync já existia; ela pegou) |
| A contagem de comandos | um comando novo dispara a cascata 100→101 (CLAUDE.md/site/agentes) | dobrei `narrate` como **MODO** de `/meta:kg`, não comando — a cascata evaporou |

A regra: **projeção read-only + guard determinístico** é o que impede o instrumento anti-divergência
de recriar, dentro de si, a divergência que ele existe para combater.

## Behavior-over-declaration, de novo — prove RODANDO

Nada aqui fechou por leitura de código. O bug mais instrutivo — `set -o pipefail` + `grep -q` (sai no
1º match) + `printf` de 461KB → **SIGPIPE no printf → pipeline retorna 141 → falso-negativo** — era
LATENTE no harness de selftest e só apareceu quando o console passou a embutir o renderer vendorizado
de 461KB (com HTML pequeno o pipe cabia no buffer e o printf terminava antes). A cura foi gravar o
HTML em arquivo antes de grepar. Também rodei o console em **3 escalas reais** (19/116/**881** nós,
0.35s no maior) e headless (modelo+estilos válidos) — a prova é a execução, não a inspeção.

## O fecho — o instrumento provado em si mesmo

O último artefato foi o console renderizando e narrando o grafo do **próprio desenho**
(`kg-console-rich-design-2026-07.kg.yaml`): a mesma máquina que explica qualquer grafo, apontada
para si. A escada de reconciliação mostra onde o plano **mudou ao ser construído** (fcose→cose
embutido; SEED gated→promovido, ambas `SUPERSEDES`) — um grafo honesto não esconde que o próprio
plano evoluiu. É o dogfood como padrão master: o artefato de verdade, rodado, explicando a si mesmo.
