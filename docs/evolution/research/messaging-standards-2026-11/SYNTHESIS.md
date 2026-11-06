---
title: A pilha de padrões do onion-messaging
date: 2026-11-06
kg: docs/evolution/research/messaging-standards-2026-11/messaging-standards-2026-11.kg.yaml
run_id: "wf_9be6279c-d87 (varredura, modo decision) + wf_f1285b27-a06 (primárias)"
tokens: 8732849          # 7.771.867 + 960.982
agents: 118              # 106 + 12
duration_min: 44         # 1.819.486 ms + 847.257 ms
review_after: 2026-12-06
type: research
mode: decision
---

> **Projeção do grafo, nunca fonte.** Quem manda é
> [`messaging-standards-2026-11.kg.yaml`](messaging-standards-2026-11.kg.yaml) (120 nós). Os retornos
> integrais dos dois runs estão em [`data/run-wf_9be6279c-d87.json`](data/run-wf_9be6279c-d87.json)
> (varredura em modo decision) e [`data/run-wf_f1285b27-a06.json`](data/run-wf_f1285b27-a06.json)
> (primárias sobre as lacunas), sem caminhos de máquina. Selos do maestro de 2026-11-06, todos pelo
> `kg-decide-seal.sh`, com testemunho e plane DEV.

## A pergunta

`Q_MESSAGING_STANDARDS_1106`: qual pilha de padrões de mercado o onion-messaging adota (envelope, fila,
campainha, identidade e adapters, e o que reaproveitar) para ligar sessões do Claude Code, pessoas, máquinas e
agentes, com uma versão local mínima na VPS compartilhada em 3 dias?

## A pilha selada (`D_MESSAGING_STACK_2026_11`, selada em 2026-11-06)

**Escolhida:** CloudEvents 1.0 dentro do sinal A2A assinado + fila honker vendorizada (versão fixa, bancada e
mutante antes de valer, ack só pela tool do channel, teto e dead-letter do honker) + campainha pelo channel MCP
com fallback por pull + identidade em dois adapters (Logto e local) + Slack Socket Mode e git.

**Descartadas:** fila própria em SQLite · NATS JetStream · a recomendação do Elenxo (o método de refutar antes de selar) sem o honker.

A diferença para a recomendação do Elenxo é a fila. O Elenxo recomendou escrever a Fila 1 (SQLite em WAL com
daemon escritor único). A rodada de primárias achou o honker, uma fila SQLite pronta com teto de tentativas,
`_honker_dead`, lease com fencing e WAL com um escritor. O maestro escolheu vendorizar o honker em vez de
reescrever, com a condição de que ele passe pela bancada e pelo mutante antes de valer. O README o declara
alpha, e ele não foi rodado no core.

| Selo | Escolhida | Descartadas |
|---|---|---|
| `D_MESSAGING_IDENTIDADE_DOIS_ADAPTERS_1106` | Dois adapters: Logto (pessoas, máquinas e a persona; código de vida curta, convite amarrado a membro, aprovação humana) e local sem servidor (chave A2A e convite por membro, já em produção) | Só Logto |
| `D_MESSAGING_DEVICE_FLOW_LOGTO_JA_1106` | Device flow do Logto já | Convite A2A agora, Logto na terça · Só convite A2A |
| `D_MESSAGING_SEGREDOS_VAULTWARDEN_SYSTEMD_1106` | Vaultwarden como fonte única (coleção da organização), copiado por script do maestro com `!` para uma credencial do systemd só do root, lida por `LoadCredential`; nunca `.env` nem chat | Só o pass · Só o Vaultwarden |
| `D_MESSAGING_SPIKE_CLAIM_ACT_SABADO_1106` | Spike no sábado 07/11: o token exchange do Logto emite o claim `act` para a persona? Sem tocar produção | Depois de segunda |
| `D_SESSAO_OPS_ONION_VPS_OPS_1106` | Repo novo privado onion-vps-ops, membro do Onion, com uma sessão de operação que é o escritor único dos repos de serviço da VPS; o código do bridge segue no core e o veto de deploy não muda | Adotar os 4 repos como estão · Depois de segunda |

O selo da identidade se apoia numa medida do maestro em 06/11 no Logto 1.42 da VPS: o discovery OIDC anuncia
`urn:ietf:params:oauth:grant-type:device_code` (com `device_authorization_endpoint` em `/oidc/device/auth`) e
`urn:ietf:params:oauth:grant-type:token-exchange`. O que ela **não** mede é se o token exchange emite o claim
`act`, e por isso existe o spike de sábado.

## As opções (11 na rodada de decisão, 1 reconciliada nas primárias)

- **Envelope:** A (A2A 1.0 só com o perfil Onion) · B (CloudEvents 1.0 puro) · **C (CloudEvents no corpo do
  sinal A2A, amarrado pelo `body_sha256` assinado)**, que já é a forma de `a2a-accept.sh` e `a2a-metrics.py`.
- **Fila:** 1 (SQLite WAL própria) · 2 (Redis Streams; nesta VPS o Docker fura o ufw) · 3 (NATS JetStream),
  reconciliada em `C_OPCAO_QUEUE_3_NATS_JETSTREAM_R2`: a fonte primária mostra que o JetStream **não** tem DLQ (fila de dead-letter)
  nativa, então ele não "fecharia a dead-letter" como a rodada de decisão supunha. A escolha final, o honker,
  veio das primárias.
- **Campainha:** i (channel próprio derivado do spike, só em sessão interativa com a flag de desenvolvimento,
  sem permission relay, gate pelo `kid` do remetente) · ii (hook "you have mail" e pull, para headless e Agent
  SDK). Selado: i com ii de fallback.
- **Identidade:** a (convite A2A por membro) · b (device flow RFC 8628). Selado: as duas, como dois adapters.
- **Adapters dos 3 dias:** Slack por Socket Mode (só conexão de saída) e git assíncrono pelo doc-bridge;
  e-mail depois.

## O que o dado sustenta

Varredura: 20 confirmadas de 25 verificadas (3 votos), 5 refutadas. As que movem a pilha:

- O channel MCP **não confirma entrega**: o `await` de `mcp.notification()` resolve na escrita do transporte, e
  eventos somem em silêncio quando a sessão não carregou o channel ou a política bloqueia. Logo o ack mora numa
  tool que o Claude chama, amarrada ao id e ao `body_sha256` (`C_SUPERACAO_20261106_CHANNEL_ACK_TOOL_BOUND`).
- Channel fora da allowlist só carrega com `--dangerously-load-development-channels`, que exige sessão
  interativa; o Claude Code não tem fila durável, então reenviar a quem estava offline é da mensageria.
- Channels estão em prévia de pesquisa e não existem em Bedrock, Google Cloud nem Foundry: a campainha é
  opcional por adotante e o pull é obrigatório como caminho de fundo.
- No A2A 1.0 a assinatura JWS vale para o Agent Card, não para cada mensagem: a assinatura do sinal é perfil
  Onion (`C_SUPERACAO_20261106_BODY_SHA256_PROFILE`).
- A volta entre usuários é por pull (`tasks/get`), nunca por webhook: NAT e a proteção contra SSRF (requisição forjada do servidor) o barram.
- O phishing por device code cresceu 37,5x (abril de 2026): código de vida curta, convite amarrado a membro, e
  o código nunca viaja em convite por Slack ou e-mail.

Primárias: 4 fontes nomeadas, todas alcançadas, 15 claims ancoradas, 8 rejeitadas na ancoragem.

- **Dead-letter:** o SQS recomenda teto "alto o bastante para retentativas", sem número; a DLQ isola para
  diagnosticar.
- **JetStream:** sem DLQ nativa, advisory publicada uma vez, `MaxDeliver` padrão ilimitado (-1), `AckWait` de
  30 s, entrega pelo menos uma vez. Como as duas filas são at-least-once, a dedupe por `ce_source`+`ce_id` ou
  `jti` vale em qualquer escolha.
- **honker:** fila SQLite at-least-once com retries, visibility timeout, lease com fencing, `_honker_dead` por
  "max attempts exceeded", ack por DELETE, WAL com um escritor; alpha no README, licença Apache-2.0 OR MIT,
  release v0.6.0 visível na API do GitHub e não no README (`C_SUPERACAO_20261106_HONKER_ALPHA_WITH_RELEASE_V060`).
- **CloudEvents entre agentes tem prior art:** a ADR 0021 do agent-governance-toolkit adota CloudEvents v1.0
  para exportação de auditoria, e o apache/eventmesh v1.12.0-rc1 lista A2A sobre CloudEvents. Isso basta para
  rever a frase "o mercado não a tem" (`Q_MESSAGING_PRIMARIES_REVIEW_1106`, sem selo).

## Mercado (`E_MERCADO_MESSAGING_1106`)

Sem sinal de capital. Nenhuma claim confirmada traz rodada, M&A ou avaliação de analista sobre mensageria
entre agentes, A2A, CloudEvents, NATS ou Redis no período. A única fonte de analista é a nota da CSA de
2026-04-04 sobre o phishing por device code, e ela é sinal de segurança, não de capital.

## NÃO-VERIFICADOS

**Refutadas (5, todas modeladas):**

| Voto | Claim |
|---|---|
| 0-3 | Um channel exige só três coisas (capability, notificação e stdio); superada por `C_SUPERACAO_20261106_CHANNEL_REQUIREMENTS_FULL_LIST` |
| 0-3 | O A2A basta como envelope único, porque a página não cita CloudEvents |
| 0-3 | O push do A2A é autenticado por JWT com `kid`/`jti`/`taskId` verificado por JWKS; o esquema fica aberto (`C_SUPERACAO_20261106_A2A_PUSH_AUTH_SCHEME_OPEN`) |
| 0-3 | O device code flow não tem vulnerabilidade a corrigir (`C_SUPERACAO_20261106_RFC10027_CROSS_DEVICE_PHISHING`) |
| 1-2 | O ack HTTP do agent-inbox confirma processamento (`C_SUPERACAO_20261106_AGENT_INBOX_ACK_IS_TRANSPORT`) |

Nas primárias, 8 claims foram rejeitadas na ancoragem (5 exageradas, 2 afirmadas sem citação, 1 não
encontrada), contabilizadas em `E_LACUNAS_MESSAGING_PRIMARIES_1106`. Nenhuma virou nó de evidência.

**Fora por orçamento:** 34 URLs de 49 não foram buscadas (entre elas a página MCP do Claude Code, os
`external_plugins` oficiais e a spec do CloudEvents), e 39 claims de 64 não foram verificadas. As duas listas
estão nomeadas no JSON da varredura (`budgetDropped`, `notVerifiedByBudget`).

**Lacunas abertas que a pilha selada carrega:**

- **O smoke do channel na 2.1.319** (`E_OBJECAO_F5_PIN_CC_AND_RESMOKE`): o channel do spike não foi
  repetido na versão atual do Claude Code, e a campainha selada segue sem medida nela.
- **O valor do teto de tentativas:** o SQS não dá número, o README do honker não dá o padrão, e o evento que
  conta como tentativa (claim, fim de lease ou recebimento) difere entre as fontes. Fica para a bancada do
  honker.
- **O que a dead-letter guarda e como se reprocessa:** o redrive com o mesmo `ce_id` cai na dedupe (perda
  silenciosa) e com id novo duplica a ação. Nenhuma fonte ancorada decide, e o honker não tem API de requeue.
  É a objeção que **bloqueia**; ela pede regra própria testada no modo de falha.
- **Operação mínima do JetStream** (RAM, disco, loopback na VPS): sem medida. Perdeu peso com o descarte.
- **O mapeamento A2A do EventMesh:** só uma linha de changelog do rc1, design-document não ancorado.

## valeu-a-pena

| Run | Agentes | Tokens | Duração | Nós | Tokens/nó |
|---|---|---|---|---|---|
| `wf_9be6279c-d87` (varredura) | 106 | 7.771.867 | 30 min | 81 | ~96 mil |
| `wf_f1285b27-a06` (primárias) | 12 | 960.982 | 14 min | 34 | ~28 mil |
| **Total** | **118** | **8.732.849** | **44 min** | **115** (+5 selos) | **~76 mil** |

Valeu, e a rodada de primárias foi o que pagou o conjunto. Por 11% dos tokens ela mudou a decisão: tirou do
JetStream o argumento da dead-letter, achou o honker (o que trocou "escrever a fila" por "vendorizar e medir a
fila") e achou prior art de CloudEvents entre agentes. A varredura deixou a forma da pilha (envelope C,
campainha com pull, ack pela tool, pull na volta) e as restrições do channel, mas gastou 3,4 vezes mais por nó
e deixou sem fonte as três lacunas que as primárias foram buscar. Vai na mesma direção da medida de 2026-09-13 (291 mil contra 42 mil tokens por nó, quase 7 vezes): primárias
nomeadas custam uma fração por nó da varredura.
