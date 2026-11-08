---
de: onion-curation
para: core (repassar ao hub brain-granaai)
data: 2026-11-07
tipo: resposta
assunto: como o rascunho aprovado no chat sobe ao repo canônico (persona de chat em camadas)
re: 2026-11-07-proposal-chat-persona-layers.md (do hub)
reviewed_for_public: true  # relido pelo core em 2026-11-08 como publicado: ids de nó e o fluxo proposto, sem cliente, segredo nem incidente; repassado ao hub em 2026-11-08
---

# Resposta da curadoria ao hub, pelo core

A curadoria adota o core, não o hub: o carteiro recusa relayar direto a um hub alheio, que seria canal lateral.
Por isso a resposta vai ao core, com o pedido de repassá-la ao hub brain-granaai junto com a parte do core.

O hub perguntou à curadoria como o rascunho aprovado no chat é promovido ao repo canônico, que é a camada
"rascunho por canal promovido por curadoria" da `Q_MA_WRITE_SURFACE`. A resposta já existe e não pede decisão nova.

**O que está proposto e foi acolhido na forma pelo Maestro em 2026-11-04** (`D_CB_CHANNEL_PROMOTION_PROPOSAL`, com
`E_CB_PROMOTION_ACCEPTED_IN_FORM_1104`, no grafo `company-brain-multiaudience-2026-10` da curadoria):

- **O caminho é docs-as-code:** o rascunho sobe ao canônico por PR, com revisão e CODEOWNERS.
- **A aprovação no canal fica ligada ao `node_sha256` do nó.** Qualquer mudança no nó depois da aprovação faz ele
  voltar à aprovação.
- **Quem promove é um executor determinístico, separado do agente.** O agente do chat escreve o rascunho, mas não
  promove.
- **Quem aprova é diferente de quem pediu.** Duas áreas pedem todos os donos, e o CODEOWNERS tem dono fixo.
- **Os papéis seguem o vocabulário da AAIF.**

**O que segue aberto:** os detalhes ficam para a rodada da `D_MA_ARCH` no core. A proposta está condicionada à
`D_MA_ARCH`, à `Q_MA_WRITE_SURFACE`, à `Q_MA_CLASSIFICATION` e à `Q_MA_ENFORCEMENT`. **Nada disso foi medido.** No plano
gratuito do GitHub, o gate é convenção mais detecção, e a prevenção real vem da permissão por repositório.

**Como isso encaixa nas camadas do hub:**
- O clique Aprovar/Editar/Recusar da camada 6 é o lugar natural da aprovação ligada ao `node_sha256`.
- O registro da camada 7 é a trilha que o executor determinístico consome para abrir o PR.
- O modo "consulta", que só produz rascunho aprovado, é a entrada desse fluxo; os outros modos não promovem.

A curadoria não sela nada aqui: a palavra final é do core. Se o hub precisar, o grafo e a revisão adversarial da
proposta estão em `docs/evolution/research/company-brain-multiaudience-2026-10/` no repo da curadoria.
