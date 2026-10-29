---
title: 'Proposta: o vigia de eventos fora da sessão sobre o A2A do Onion — padrão de mercado por camada, duas formas de coleta e três perguntas'
date: 2026-10-28
from: onion-curation (adotante)
to: core (onion-evolve)
type: proposal
estudo: docs/evolution/research/event-watcher-2026-10/
grafo: event-watcher-2026-10.kg.yaml (D_EVENT_WATCHER_PROPOSAL)
---

# O vigia de eventos fora da sessão, sobre o A2A do Onion

**O pedido:** o maestro, pelo hub brain (`2026-10-28-proposal-event-watcher.md`), quer que e-mail, Slack, wiki,
GitHub e AWS cheguem ao Onion sem depender de um Claude aberto, com o vigia rodando sobre o nosso A2A.

**Como o estudo foi feito:**
- pré-registro (PLAN.md) antes da busca, mais a emenda B depois da revisão;
- um braço de pesquisa em fonte primária;
- um laboratório sobre o A2A do Onion;
- uma revisão adversarial, que **reprovou a 1ª versão**. As 11 objeções que se sustentaram estão curadas aqui
  (`evidence/elenxo/REVIEW.md`).

## O padrão de mercado, camada por camada

| camada | padrão | o que importa para o Onion |
|---|---|---|
| envelope | **CloudEvents 1.0** (CNCF Graduated), em modo structured | a assinatura nativa (`verifiability`) é recente e não entrou em release |
| transporte entre agentes | **A2A 1.0** (AAIF, Linux Foundation) | **não assina mensagem**: só o Agent Card, e o push vai por credencial. **Nada oficial liga A2A e CloudEvents.** Há propostas abertas: #1131 (CloudEvents), #1829 (Ed25519 + RFC 9421), #2133 e #1029 |
| assinatura HTTP | **RFC 9421** (IETF) e **Standard Webhooks** (indústria, `v1a` ed25519) | servem para assinar o que sai |
| ingestão aberta | **Argo Events** (Apache-2.0, CNCF/Argo) | verifica nativamente Slack (`slack/start.go:288`), GitHub (`github/start.go:380`) e SNS (`awssns/start.go:142-143`) e emite CloudEvents; **exige Kubernetes e EventBus**, e não tem source de Outline, Gmail nem IMAP |
| coletores por fonte | o esquema nativo de cada uma | **Slack:** HMAC `v0`, janela de 5 min, ack em 3 s, 30.000 eventos por workspace e app em 60 min; o **Socket Mode** dispensa endpoint público. **GitHub:** `X-Hub-Signature-256`, deduplica pelo `X-GitHub-Delivery`. **Outline:** `t=…,s=…`. **SNS:** X.509, **assina o Timestamp**. **EventBridge API destinations:** não assina o payload |
| Gmail | três caminhos, cada um com a sua dependência | **push:** projeto Google Cloud + Pub/Sub. **IMAP com XOAUTH2:** cliente OAuth. **IMAP IDLE com senha de app:** só em conta com 2SV, e o Google não o recomenda |
| segurança | assinatura sobre o corpo cru com comparação em tempo constante, janela, deduplicação por id, conteúdo não confiável (OWASP LLM01), privilégio mínimo, humano no envio | |
| triagem | filtro declarativo (dialetos do CloudEvents Subscriptions) antes do modelo; agente só de leitura | |
| prontas | o n8n **não é código aberto** (Sustainable Use License); Huginn, Node-RED, Windmill e Activepieces são abertas | nenhuma verifica os quatro esquemas e emite CloudEvents |

## O que foi medido sobre o A2A do Onion

Rodado numa cópia descartável do core (fixado em `1d04d4e24`), sem rede, com um coletor de teste cadastrado só na
cópia:

| caso | o que se fez | resultado |
|---|---|---|
| W1 | evento CloudEvents assinado pelo `a2a-send` | passa no `a2a-verify` e chega intacto |
| W1b | o mesmo envelope enviado de novo | vetado por repetição |
| W2 | corpo trocado depois da assinatura | vetado (`body-mismatch`) |
| W2-MUT | cópia do gate sem a checagem do `body_sha256` | o adulterado passa: é essa checagem que segura o W2 |
| W3 | assinatura no estilo do Slack | bate com o vetor oficial da doc; a errada e a vencida são recusadas |
| W3d | repetição dentro da janela | recusada pela deduplicação do id |

**Não exercido:** o aceite (`a2a-accept`), a fila do bridge e um coletor real com ack em 3 s e fila local.

## A composição do maestro, ponto a ponto

| ponto | estado |
|---|---|
| 1. cada coletor é um remetente A2A que assina | **medido** (W1, W2). Pede um membro por coletor no `members.yaml` do core |
| 2. a fila do receptor no bridge é a caixa durável | não medido. A retenção, a durabilidade e o teto do JWS (3600 s até o aceite) estão em aberto |
| 3. o aceite reverifica | não medido (`--reverify-at` não foi rodado) |
| 4. a triagem usa a peça de rascunho | em aberto: a peça (`a2a-rt-mcp.py`) só tem `draft_message` e `read_inbox` |
| 5. só o humano envia | **em conflito** com o aviso automático (Slack DM, e-mail) pedido pelo hub |

## Recomendação: duas formas de coleta e três perguntas

**As duas formas:**

1. **O padrão de mercado aberto:** o Argo Events num k3s com EventBus, mais um publicador fino que leva o CloudEvent ao
   `a2a-send`. O Outline e o Gmail ficam com coletor próprio.
2. **Coletores finos próprios, declarados:** cada um verifica a assinatura da fonte, deduplica pelo id e chama o
   `a2a-send`. O custo é **estimativa não medida**, e cada coletor precisa de ack em 3 s e de fila local.

As duas levam o CloudEvent dentro do sinal A2A assinado, e isso é **solução própria**, porque o mercado não tem a
ligação.

**As três perguntas para o core e o maestro:**

1. Vale k3s mais EventBus na VPS para ter o padrão (1), ou fica a forma (2)?
2. O aceite é ato humano. Para eventos, o caminho é:
   - **(a)** aceite em lote;
   - **(b)** aceite automático por regra para coletor confiável e assinado;
   - **(c)** triagem antes do aceite, que contorna o gate e **não é recomendada**.
3. O Gmail vai por push (Google Cloud), por IMAP com OAuth ou por IMAP com senha de app?

**Respostas aos pedidos do hub:**
- **Opção A contra B:** as rotinas na nuvem rodam só por horário e põem as credenciais na nuvem, o que contraria o
  "sem dependência externa". O serviço na VPS é coerente com o A2A.
- **Perfil `event` do kg-ssot:** a sugestão é ele adotar os atributos do CloudEvents (`id`, `source`, `type`, `time`,
  `subject`, mais o link), em vez de um perfil novo. A sugestão vai ao kg-ssot.
- **Aviso automático:** conflita com o "só o humano envia". Fica para o maestro.

**Refutador:**
- uma ingestão aberta e leve, sem Kubernetes, que verifique as fontes e emita CloudEvents;
- uma ligação oficial A2A–CloudEvents (#1131);
- a assinatura de mensagem no A2A (#1829), que tornaria obsoleta a parte própria.

## Capital e quem paga

O capital está no n8n: Series C de US$180M a US$2,5B em 2025-10, mais um aporte da SAP em 2026-05, com o valor não
verificado. O n8n não é código aberto. As abertas não têm capital próprio. Na proposta, ninguém paga.

Orquestrado com 🧅 Onion Evolve
