---
title: "Proposta: vigia de eventos fora da sessão — e-mail, Slack, wiki, GitHub e AWS chegando ao Onion sem depender de um Claude aberto"
date: 2026-10-28
type: proposal
kind: feature-request
from: brain-granaai (hub)
to: onion-evolve (core) — com onion-kg-ssot e onion-curation
flow: upstream (consumidor→core)
severity: medium
status: open
re:
  - docs/evolution/inbox/_processed/2026-10-27-proposal-company-brain-multiaudiencia.md
  - grafo company-brain-multiaudiencia-2026-10 (no core)
---

# Vigia de eventos fora da sessão

## O pedido do maestro (2026-10-28)

> "Temos como criar um serviço de monitoramento de eventos para e-mail, Slack, wiki... e deixar hospedado em
> uma VPS, cadastrando, e não precisar desta sessão? Incluindo canais de mensagens e afins?"

## O que motivou (medido hoje no hub)

Na entrega da auditoria de segurança da registradora, o hub precisou acompanhar coisas que acontecem fora do
repositório:

- a mitigação de uma falha em produção feita por outra pessoa (o WAF de uma distribuição CloudFront e o
  deploy da correção);
- respostas num canal privado do Slack sobre essa mitigação;
- avisos por e-mail e mudanças na wiki (Outline).

A única ferramenta disponível foi o `CronCreate` da sessão: dois agendamentos (de hora em hora e a cada 30
minutos) que **morrem quando a sessão fecha**, só rodam com o terminal ocioso e expiram em 7 dias. Funciona
para uma tarde, não para a operação.

## O que o hub pensa (proposta para o core discutir com o kg-ssot e a curadoria)

### 1. Separar três coisas que hoje estão misturadas

| Camada | Função | Precisa de LLM? |
|---|---|---|
| **Coleta** | Receber ou buscar eventos: webhook do Slack (Events API), push do Gmail (Pub/Sub), webhook do Outline, webhook do GitHub, EventBridge da AWS via SNS/HTTPS, e sondagem (polling) onde não há webhook | Não |
| **Registro** | Normalizar cada evento num formato único e gravar numa caixa de entrada durável (append-only), com fonte, horário, ator, link e hash | Não |
| **Triagem** | Aplicar regras (filtros declarados) e, só quando a regra pedir, chamar um agente para resumir, classificar ou propor decisão | Às vezes |

A coleta e o registro rodam como serviço comum na VPS (systemd), sem Claude. A triagem com LLM roda sob
demanda, por evento que casou uma regra — não fica um modelo "olhando" o tempo todo.

### 2. Encaixe no Onion

- **Evento vira entrada do `/meta:kg-inbox`.** O formato de evento pode ser um perfil do kg-ssot (pedido ao
  kg-ssot: `event` com fonte, ator, momento, link e proveniência `locality: web`), para que o radar e o
  `decide-census` enxerguem eventos como linhas em voo.
- **Regra declarada em arquivo versionado** no repo do adotante (ex.: `.onion/watch.yaml`): "thread X no canal
  Y", "mudança no Web ACL Z", "e-mail de tal domínio com tal assunto", com a ação (avisar no Slack, abrir
  rodada do `/meta:decide`, criar card).
- **Ação de saída limitada:** avisar (Slack DM, e-mail) e enfileirar decisão. Escrever em sistemas de terceiros
  (responder no Slack, mudar WAF) continua exigindo o maestro, como hoje.
- **Sessão do Claude passa a ser consumidora:** ao abrir, o hook "you have mail" já mostra os eventos
  triados; o `/meta:decide` lê a fila de decisões.

### 3. Duas formas de rodar (para o core escolher)

| Opção | Como | A favor | Contra |
|---|---|---|---|
| **A. Routines/agentes agendados na nuvem** (Claude Code `schedule`) | Um agente por cron, com os conectores MCP (Slack, Gmail, Drive) | Zero infraestrutura; já existe | Só por horário (sem webhook); credenciais na nuvem; custo por execução; sem estado entre execuções |
| **B. Serviço na VPS** (recomendado) | Coletores com webhook + polling, caixa de entrada em SQLite/JSONL, regras em YAML; triagem chama `claude -p` headless ou o Agent SDK só quando preciso | Tempo real; estado durável; segredos sob controle (pass/systemd-creds); um serviço para toda a família | Precisa operar (TLS, atualização, monitoramento do próprio vigia) |

A opção B pode reaproveitar o que o core já tem: o Bridge (contexto de organização e medidor), o servidor MCP
do hub e o transporte A2A entre sessões.

### 4. Segurança (inegociável)

- Todo conteúdo que chega (mensagem, e-mail, página) é **dado não confiável**: a triagem nunca executa o que o
  texto pede, e o agente de triagem roda com ferramentas só de leitura.
- Credenciais com o menor escopo possível e por conector (bot do Slack só nos canais cadastrados, Gmail só
  leitura de rótulos, AWS só leitura via EventBridge).
- Registro de cada ação de saída com quem autorizou.

## Pedido ao core

1. Abrir um nó no grafo de coordenação (ou no `company-brain-multiaudiencia-2026-10`, se couber) para decidir
   entre A e B e o formato do evento.
2. Pedir ao **kg-ssot** o perfil `event` (ou dizer que um perfil existente basta).
3. Pedir à **curadoria** um levantamento do estado da arte: webhooks e limites do Slack, Gmail push, Outline,
   e ferramentas prontas (n8n, Huginn, Windmill, ou similares) contra construir o serviço.
4. Responder pelo `inbound/` do hub. O hub não implementa nada até lá; segue com o `CronCreate` da sessão como
   paliativo.

Orquestrado com 🧅 Onion Evolve
