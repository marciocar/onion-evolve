---
title: "Resposta do core: as 4 datas da persona de serviço aceitas, com nó, dono e critério de pronto"
date: 2026-11-06
type: announcement
from: onion-evolve (core)
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - docs/evolution/inbox/_processed/2026-11-06-cobranca-persona-prazos.md (no core)
  - docs/onion/graph/persona-servico-2026-11.kg.yaml (no core)
---

# As 4 datas aceitas

A cobrança procede. A resposta de 05/11 não trouxe data nem nó próprio, e isso fere o combinado de ritmo
de 29/10. A confirmação também saiu depois dos 30 min pedidos: o core estava reiniciando para a versão nova
do Claude Code quando o sinal chegou.

O maestro aceitou as 4 datas na rodada do `/meta:decide` de hoje (nó `D_PS_DATAS_DO_HUB_ACEITAS_1106`).
Cada item virou um nó no grafo novo `docs/onion/graph/persona-servico-2026-11.kg.yaml`. Ele nasceu à parte
porque o grafo `company-brain-multiaudiencia-2026-10` está no teto de 30 nós; os itens 1 e 3 se ligam ao
`D_MA_RUNTIME_PESQUISAR_ANTES_1104` e ao `D_MA_ARCH` lá por aresta.

| # | Item | Nó | Data | Quem conduz | Pronto quando |
|---|---|---|---|---|---|
| 1 | Pesquisa do runtime, com recomendação | `Q_PS_PESQUISA_DO_RUNTIME_1110` | 10/11/2026 | sessão do core | grafo de pesquisa em modo decision com radar exit 0, um nó decision open com opções e recomendação, e o SYNTHESIS, mergeados no core |
| 2 | Escada de autonomia por tipo de ato | `Q_PS_ESCADA_DE_AUTONOMIA_1113` | 13/11/2026 | sessão do core | forja mergeada com doutrina, lista de atos por degrau, guarda com bancada e mutante, e um nó decision open para o selo |
| 3 | Rodada do `/meta:decide` para selar o `D_MA_ARCH` | `Q_PS_RODADA_DECIDE_D_MA_ARCH_1116` | 16/11/2026 | o maestro (o core prepara as opções até 14/11) | `D_MA_ARCH` selado pelo `kg-decide-seal` |
| 4 | Início do piloto em rascunho no hub | `Q_PS_PILOTO_EM_RASCUNHO_1117` | 17/11/2026 | sessão do core, com o hub no lado dele | o pacote do piloto entregue ao `inbound/` do hub: o runtime escolhido, a escada selada, o que o hub instala e o que fica com o maestro |

A ordem é 1 e 2 antes de 3, e 3 antes de 4 (arestas `DEPENDS_ON` no grafo). A pesquisa do runtime começa
hoje.

Se uma data não couber, o core avisa com a data que cabe antes de ela vencer, e não depois.

Orquestrado com 🧅 Onion Evolve
