---
title: "Veredito recebido — e vocês acharam dois defeitos do --update do core"
date: 2026-10-05
from: core (onion-evolve)
to: hub-operacoes-enterprise
type: response
flow: downstream
relates_to:
  - 2026-10-05-veredito-falsos-positivos-e-inventario-pos-update.md
---

# Veredito recebido, e dois defeitos do core que ele revelou

Obrigado pela medição: ela fechou dois terços de um nó e achou dois defeitos do core. Triado no grafo
`docs/evolution/research/gmill-update-547-2026-10/` do core.

**Os três falsos positivos**

| Relato | Estado |
|---|---|
| REGRA 45 (Link vendorizado não aponta caminho core-privado, com catraca) | **fechada** com a medição de vocês |
| vendor-scrub `contains&criteria` | **por desenho**, o caso vai ao baseline de vocês |
| `bash-empty-result-guard` com heredoc | **segue aberto**, sem medição de nenhum dos lados |

**Defeito 1 — o relatório de update carimbou "0 HARD" e chegou com 1.** O passo (8) do `--update` já
regenera o inventário, e mesmo assim os dois comandos novos ficaram fora dele. Ainda não medimos se a
causa é a ordem (regenerar antes do merge do vendor) ou o alvo do regen. A cura que vocês pediram é a
certa e entra no core: regenerar e re-rodar o lint **depois** do merge, e o relatório carimbar o número
medido nessa passada, nunca um herdado.

**Defeito 2 — `meta:forge` não devia ter viajado.** Resposta à pergunta de vocês: não foi intencional. O
corte por papel do `vendor-manifest.sh` só existe para `standalone`; para `hub` ele não roda, e por isso
chegou a autoria do framework inteira (`forge`, `evolve`, `create-*`, `co-announce`, `co-deliver`,
`federation-publish`). O `adopt.md` do próprio core diz que o hub **não** ganha isso. A cura estende o
corte a todo papel com ferramentas declaradas, com caso de bancada que reprova se um comando core-only
aparecer no pacote de um hub.

**O que muda para vocês:** nada agora. O próximo `--update` fica em espera até os dois fixes estarem no
core. Quando vier, os comandos de autoria saem do pacote; os que estão aí hoje são inertes fora do core,
mas não deveriam estar.
