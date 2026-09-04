---
title: 'Pedido de pesquisa profunda — não existe visão CONSOLIDADA cross-grafo (radar/dashboard) para N .kg.yaml peer'
date: 2026-09-04
from: marcio-pessoal (Onion pessoal do Marcio — N=1, method-adopter, kind: method, onion_version: n/a)
to: onion-evolve (core / sala de design)
type: dogfood-signal (co-evolução, fluxo upstream) — pedido de pesquisa, não proposta de solução
status: novo — triagem pendente (/meta:co-evolve)
re: knowledge-graph-sdaal.md · kg-radar.sh · kg-backlog-project.sh · doutrina P1 (verticais peer) — onion-pessoal-marcio/01-verticais-peer.md
---

# Sinal: o método não tem mecanismo para "o quadro geral" quando há N grafos peer

## O gap (dogfood de campo, medido hoje)

O KG de vida N=1 tem 4 verticais **peer** por desenho doutrinário (P1 — `01-verticais-peer.md`: "não é uma
lista, é uma arquitetura"): `marcio-trabalho-f0.kg.yaml`, `marcio-saude-f0.kg.yaml`, `marcio-relacoes-f0.kg.yaml`,
`marcio-aprendizado-f0.kg.yaml` — 4 arquivos independentes, cada um com seu próprio `kg-radar` (`exit 0/1`).

Ao pedir "o quadro geral das 4 verticais", medi o que existe:

- `kg-radar.sh` roda **um arquivo por vez** — sem glob, sem lista de args.
- `kg-backlog-project.sh` existe, mas o escopo é **hardcoded** para a camada canônica do próprio `onion-evolve`
  (`docs/onion/graph/*.kg.yaml`) — é o backlog do framework, não um mecanismo reusável para N grafos peer de
  outro domínio.
- `kg-view.sh` / `kg-console.sh` projetam **um** grafo em markdown/HTML — não agregam.
- As ligações cross-vertical que existem hoje (`P_HIDDEN_IMPORTANCE_XV`, `P_WORK_DRIVER_XV`,
  `P_DISCRETE_SURVIVES_XV`, `P_NOMAD_XV`) são **texto na label** ("ver marcio-saude-f0: P_LEISURE"), não
  arestas de grafo — cada `.kg.yaml` é uma ilha; a referência cruzada só é legível por um humano (ou por um
  agente costurando à mão, o que fiz nesta sessão para responder "como estão as 4 verticais").

**Consequência:** não existe hoje uma "evolução do quadro geral" versionada nem uma régua de atenção
comparável ENTRE verticais (ex.: qual vertical pesa mais agora? qual está regredindo?) — só o que cada
`git log` de cada grafo mostra, separadamente.

## Por que isso não é só um pedido de N=1

Qualquer adotante com **mais de um `.kg.yaml` peer** no mesmo repo/domínio esbarra nisso — não é peculiaridade
do life-KG. O próprio core já tem múltiplos `.kg.yaml` em `docs/onion/graph/` e em `docs/evolution/research/*`;
o `kg-backlog-project.sh` resolveu o caso do core hardcoding o caminho, o que sugere que o padrão "N grafos,
1 visão" já apareceu antes e foi resolvido ad-hoc, não como mecanismo generalizável.

## Pedido (pesquisa, não solução prescrita)

Peço que o core faça uma pesquisa profunda e **determine** o mecanismo certo — não estou propondo a resposta.
Pontos que a pesquisa provavelmente precisa decidir:

1. **Radar multi-arquivo:** `kg-radar.sh` ganha um modo `--corpus <glob>` que agrega atenção/estado/reconciliação
   de N grafos, ou isso é anti-padrão (cada grafo deve ser julgado sozinho, por design)?
2. **Arestas cross-arquivo de verdade:** as referências `_XV` deveriam virar um mecanismo de fato (ex.: um
   `.kg.yaml` de nível 0 que importa/referencia nós de outros arquivos por id) em vez de prosa na label?
   Ou isso quebra a soberania de cada grafo (P3: "adota o método, soberano no dado")?
3. **`kg-backlog-project.sh` generalizável:** vale a pena parametrizar o escopo (hoje hardcoded ao core) para
   servir qualquer adotante com múltiplos grafos peer, sem forkar o script?
4. **Dashboard/console multi-grafo:** `kg-console.sh` (HTML self-contained) faz sentido evoluir para aceitar
   N arquivos e renderizar um painel comparativo, ou isso é escopo demais para uma ferramenta que hoje é
   deliberadamente "projeção pura de um grafo"?

## Onde vive a evidência

`/home/marcio/onion-pessoal/marcio-{trabalho,saude,relacoes,aprendizado}-f0.kg.yaml` (privado — não
acompanha este sinal; o pedido é sobre o MECANISMO, não sobre o dado). Sessão de realign 2026-09-03/04 no
mesmo repo mostrou o padrão de uso: perguntar "como está o quadro geral" e receber síntese manual, refeita
a cada pergunta, sem SSOT do agregado.


---

## Triagem (core, 2026-09-04)

**Processado por pesquisa profunda** (`/onion-research`, modo decision, `wf_bb97173d-425`): grafo `docs/evolution/research/kg-multi-graph-view-2026-09/` + `SYNTHESIS.md`. Decisão proposta: O2 + O5 + O7 (radar de um arquivo; xref tipado + resolver; raiz do backlog parametrizada); console multi-grafo não agora. Resposta entregue no inbound do adotante (`~/onion-pessoal/docs/evolution/inbound/`, sem commit — I3); cópia em `docs/evolution/research/kg-multi-graph-view-2026-09/RESPOSTA-marcio-pessoal-2026-09-04.md` (o adotante é de MÉTODO, sem canal outbox por desenho — REGRA 28). Nó `D_KG_MULTI_GRAPH_VIEW_0904` aguarda selo do maestro.
