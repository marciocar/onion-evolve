---
title: A2A para a empresa adotante — qual topologia liga sessões de pessoas e máquinas diferentes
date: 2026-10-27
kg: docs/evolution/research/a2a-empresa-adotante-2026-10/a2a-empresa-adotante-2026-10.kg.yaml
run_id: wf_25860bde-222
tokens: 7910511
agents: 106
duration_min: 23
review_after: 2026-11-26
type: research
mode: decision
---

> **Projeção do grafo, nunca fonte.** A decisão `D_A2A_EMPRESA_ADOTANTE_TOPOLOGIA_1027` foi **selada pelo
> maestro em 2026-10-27 como DIREÇÃO** (status `done`, plane DEV, selo por testemunho), depois da rodada
> complementar em modo primaries; ver [a rodada complementar](#rodada-complementar-em-modo-primaries-2026-10-27)
> e [os selos](#selos-do-maestro-2026-10-27). Os retornos integrais dos dois runs estão em
> [`data/run-wf_25860bde-222.json`](data/run-wf_25860bde-222.json) (decision) e
> [`data/run-wf_bd8f7f49-808.json`](data/run-wf_bd8f7f49-808.json) (primaries). As seções até
> "valeu-a-pena" projetam o run em modo decision e ficam como estavam.

## A pergunta

Como uma empresa adotante do Onion deve conectar sessões de agentes de pessoas e máquinas diferentes,
com ida e volta viva, identidade estável do remetente, mensagem de colega tratada como informação (nunca
como aprovação) e nada de envio automático para fora? (`Q_A2A_EMPRESA_ADOTANTE_2026_10`)

## As opções e a recomendação (nó `D_A2A_EMPRESA_ADOTANTE_TOPOLOGIA_1027`)

| Opção | Nó | O que é |
|---|---|---|
| **A** | `C_OPCAO_A_BRIDGE_HOSTED_PILOT_ONLY` | A2A do Onion hospedado pelo onion-bridge (HTTP A2A do bridge + MCP local cuja tool de envio só grava rascunho): só onboarding e piloto |
| **B** | `C_OPCAO_B_SELF_HOSTED_RECEIVER` | O mesmo receptor em self-host pela empresa (VPS ou serverless com armazenamento durável) |
| **C** | `C_OPCAO_C_OPEN_A2A_MCP_STREAMABLE_WIRE` | A2A aberto 1.0 (AAIF/LF) + MCP remoto por Streamable HTTP como formato de fio |
| **D** | `C_OPCAO_D_NATIVE_SAME_PERSON_ONLY` | Canais nativos da Anthropic (cross-session via Remote Control, `isolatePeerMachines`): só para a mesma pessoa entre máquinas |
| **Combinação** | `C_OPCAO_COMBINACAO_B_SPEAKS_C_PLUS_D` | B falando C (o A2A do Onion como perfil do padrão aberto) entre pessoas + D com `isolatePeerMachines` para a mesma pessoa; A como piloto |

**Recomendação do Elenxo** (afirmação de UM agente, sem votação; cópia fiel da narrativa do nó D_):

> Recomendação: uma combinação em duas camadas, não uma opção única. (1) Entre colegas e máquinas de
> donos diferentes, o canal é um receptor A2A que a própria empresa hospeda (opção B, numa VPS ou
> serverless com armazenamento durável). Ele fala o protocolo A2A aberto 1.0 (C) como formato de fio. O
> 'A2A do Onion' deixa de ser protocolo próprio e vira um PERFIL do A2A aberto: chave pinada no
> members.yaml, cards assinados obrigatórios, corpo assinado e tratado como dado, MCP local cuja tool de
> envio só grava rascunho. A trajetória sustenta isso: o A2A entrou na AAIF em 17/08/2026, junto ao MCP
> (aaif.io). O onion-bridge hospedado (A) fica só como onboarding e piloto, não como topologia de
> produção, porque concentra o dado de terceiros e já teve defeitos de gate. (2) Para a mesma pessoa em
> várias máquinas, o canal nativo (D: cross-session via Remote Control) com isolatePeerMachines=true no
> .claude/settings.json do adotado: é o gate determinístico de saída, que vale até sob bypass e o projeto
> liga mas não desliga. CONDIÇÕES (as objeções que sobreviveram): (a) a D não serve entre pessoas: o
> escopo é 'your sessions', exige login claude.ai, o dado passa pela Anthropic, fica vetada em org ZDR, e
> a proteção de configuração no receptor é INSTRUÇÃO ao modelo, não gate. (b) O card assinado autentica o
> agente, não a mensagem: o Onion precisa assinar o CORPO (emenda pendente da RFC-0004) e exigir
> assinatura, que a spec deixa opcional. (c) A identidade estável vem da chave pinada no members.yaml,
> nunca do nome de sessão ou do socket/PID. (d) Atrás de NAT, a volta é polling por tasks/get ou SSE. A
> entrega viva na sessão ociosa depende de Channels, que não foi lido e é research preview. (e) Na B
> serverless, a fila, a deduplicação de jti e o estado de Task são projeto da empresa. O McpAgent em
> Durable Object está deprecado, só Streamable HTTP tem OAuth, e o custo de operação NÃO foi medido. (f)
> A tool de rascunho tem de ser idempotente, porque o retry do cliente MCP repete chamada. (g) Lacunas
> abertas antes de selar: adoção real de A2A em produção (só contagem de apoiadores), Managed Agents/Agent
> SDK não avaliados, ataques a Agent Card não lidos, dois membros da mesma org Team não testados, e a
> linha de base viva VPS↔notebook (Q_COMPOSICAO_IDA_E_VOLTA_VIVA_1025) ainda não medida.

A decisão **depende** de duas perguntas abertas (arestas `DEPENDS_ON`): a linha de base viva
VPS↔notebook, `Q_COMPOSICAO_IDA_E_VOLTA_VIVA_1025` em `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`,
e a rodada complementar `Q_A2A_EMPRESA_RODADA_PRIMARIAS_1027` (abaixo).

## O que a varredura sustenta (15 confirmadas, 3-0)

- **O cross-session nativo é da mesma pessoa.** SendMessage e ListAgents falam com "your other
  sessions"; não é canal entre colegas (`E_XSESSION_SCOPED_TO_SAME_USER`, tier 10).
- **Mensagem de outra sessão não aprova nada** e comandos chegam como texto puro
  (`E_XSESSION_MESSAGE_NEVER_APPROVAL`). Só que "não altera configuração" é instrução ao modelo, não gate
  (`E_OBJECAO_01_CONFIG_GUARD_IS_INSTRUCTION_NOT_GATE`).
- **Entre máquinas, o dado passa pela Anthropic**, via Remote Control e com login claude.ai; na mesma
  máquina, por socket local (`E_XSESSION_CROSS_MACHINE_VIA_ANTHROPIC`, `E_REMOTE_CONTROL_OUTBOUND_HTTPS_ONLY`).
- **O nome de sessão não é identidade estável**: colide, ganha sufixo e não persiste
  (`E_SESSION_NAME_NOT_STABLE_IDENTITY`). A identidade tem de vir da chave pinada no members.yaml.
- **A2A 1.0 é estável e traz Signed Agent Cards**, mas o card autentica o agente, não a mensagem, e a
  assinatura é opcional (`E_A2A_1_0_SIGNED_AGENT_CARDS`, `E_OBJECAO_04_SIGNED_CARD_IS_AGENT_NOT_MESSAGE`).
- **Na Cloudflare, MCP novo é Streamable HTTP stateless** e o McpAgent está deprecado: na B serverless,
  fila e caixa de entrada são projeto da empresa (`E_CLOUDFLARE_MCPAGENT_DEPRECATED_STATELESS`).
- **Nenhum protocolo de agentes dispensa gate próprio**: o crescimento superou a segurança, e a
  autenticação é ad hoc (`E_SURVEY_PROTOCOL_GROWTH_OUTPACED_SECURITY`, `E_SURVEY_ADHOC_AUTH_WEAK_VALIDATION`),
  o que o próprio bridge confirmou com defeitos medidos.

## Mercado (`E_MERCADO_A2A_EMPRESA_ADOTANTE_1027`)

Há sinal de adoção e de financiamento; não há rodada, M&A nem parecer de analista confirmado.

- **Primária da Linux Foundation (abr/2026):** o A2A foi de mais de 50 para mais de 150 organizações em
  um ano, passou de 22 mil estrelas, está nas grandes nuvens e declara uso em produção, sem nome de
  cliente nem volume.
- **Tier 4 (ago/2026):** os patrocinadores platinum da AAIF são AWS, Anthropic, Block, Bloomberg,
  Cloudflare, Google, Microsoft e OpenAI. O A2A entrou na AAIF em **17/08/2026**, ao lado do MCP
  (primária aaif.io, `C_SUPERACAO_20261027_A2A_JOINS_AAIF_2026_08_17`).
- **Analista:** o Thoughtworks Technology Radar vol. 33 (nov/2025) pôs o A2A em **Assess**, abaixo do
  Trial; o blip não está na vol. 34 (`C_SUPERACAO_20261027_THOUGHTWORKS_ASSESS_NOT_TRIAL`).
- **Leitura:** o capital favorece C como formato de fio, não um protocolo próprio. Quem financia o padrão
  é o mesmo conjunto que financia o substrato do Onion. Limite: "apoiar" não é adoção medida
  (`E_OBJECAO_03_SUPPORTERS_ARE_NOT_PRODUCTION_USE`).

## As objeções que sobreviveram (31 de 47, todas modeladas)

O Elenxo julgou 47 objeções; 31 sobreviveram e cada uma é um nó `E_OBJECAO_NN` que `CONSTRAINS` o que
limita. As que pesam na escolha:

| Objeção | O que limita |
|---|---|
| `E_OBJECAO_01_CONFIG_GUARD_IS_INSTRUCTION_NOT_GATE` | a proteção de configuração no receptor nativo é instrução ao modelo, não gate |
| `E_OBJECAO_02_BUG_COUNT_IS_NOT_RELIABILITY` | contar bug corrigido mede manutenção; aplicada à A, a régua reprova mais; ninguém mediu taxa de perda |
| `E_OBJECAO_03_SUPPORTERS_ARE_NOT_PRODUCTION_USE` | apoiador e estrela não são adoção em produção |
| `E_OBJECAO_04_SIGNED_CARD_IS_AGENT_NOT_MESSAGE` | o card assinado autentica o agente; o Onion precisa assinar o corpo |
| `E_OBJECAO_05_STREAMABLE_HTTP_IS_TOOL_TRANSPORT` | Streamable HTTP é transporte de ferramenta, não ida e volta viva entre sessões |
| `E_OBJECAO_12_A2A_SPEC_CONTENT_NOT_UNTRUSTED` | tratar conteúdo de agente como dado fica com o implementador |
| `E_OBJECAO_16_ISOLATE_PEER_MACHINES_LOAD_BEARING` | o controle determinístico de saída da D foi cortado por orçamento e é load-bearing |
| `E_OBJECAO_19_STATELESS_INBOX_IS_COMPANY_PROJECT` | na B serverless, fila, deduplicação de jti e estado de Task são projeto da empresa |
| `E_OBJECAO_20_CLOUDFLARE_RPC_NO_AUTH` | o RPC da Cloudflare não tem autenticação; OAuth só no Streamable HTTP |
| `E_OBJECAO_23_DRAFT_TOOL_MUST_BE_IDEMPOTENT` | o retry do cliente MCP repete a chamada; a tool de rascunho tem de ser idempotente por chave |
| `E_OBJECAO_25_CHANGELOG_READ_9_PERCENT` | a maturidade da D se apoia em ~9% do CHANGELOG |
| `E_OBJECAO_27_YOUNG_INTEROP_LAYER` | a camada de interoperabilidade é jovem; identidade e isolamento não vêm de graça |
| `E_OBJECAO_29_CHANNELS_UNREAD` · `E_OBJECAO_30_MANAGED_AGENTS_UNEVALUATED` · `E_OBJECAO_31_AGENT_CARD_ATTACKS_UNREAD` | fontes load-bearing não lidas (abaixo) |

As demais (06 a 11, 13 a 15, 17, 18, 21, 22, 24, 26, 28) rebaixam achados de mercado e de maturidade ou
devolvem ao quadro um núcleo verdadeiro que a refutação jogou fora. Todas estão no grafo.

## NÃO-VERIFICADOS

**O orçamento cortou muito.** Com `maxFetch 15` e `maxVerify 25`, o run leu 15 fontes, verificou 25 das
65 claims e deixou de fora **34 fontes** (`budgetDropped`) e **40 claims** (`notVerifiedByBudget`). Não
verificadas por empate: **0**. A contabilidade está em `E_LACUNAS_A2A_EMPRESA_ADOTANTE_1027`.

**Fontes não lidas que o Elenxo marcou como load-bearing:**

- **`code.claude.com/docs/en/channels.md`** — Channels, a costura nativa que traz eventos externos para a
  sessão. A entrega viva na sessão ociosa do colega depende dela, e ela é research preview
  (`E_OBJECAO_29_CHANNELS_UNREAD`).
- **O handbook de Claude Managed Agents** e a página de sessões na nuvem — a opção D os nomeia e nenhum
  claim ancorado os avalia (`E_OBJECAO_30_MANAGED_AGENTS_UNEVALUATED`).
- **As fontes de ataque de envenenamento de Agent Card e agent-in-the-middle** (Keysight, LevelBlue) —
  as únicas específicas sobre o ataque que mais ameaça as opções A2A (`E_OBJECAO_31_AGENT_CARD_ATTACKS_UNREAD`).
- **`isolatePeerMachines` e `crossSessionInbound` como controles determinísticos** — aqui o corte foi de
  **claim**, não de fonte: a página de cross-session foi lida, mas as claims sobre os dois controles
  ficaram fora do `maxVerify` (`E_OBJECAO_16_ISOLATE_PEER_MACHINES_LOAD_BEARING`). A conferência do
  pós-run achou o texto na própria página: `isolatePeerMachines` pede aprovação antes de a mensagem sair
  "even in `bypassPermissions` mode", e um arquivo de projeto "can turn the requirement on but not off";
  `crossSessionInbound` aceita `accept`, `hold` ou `refuse`. Falta ancorá-los e ler a referência de settings.
- **O CHANGELOG do Claude Code, lido só ~9%** — a ausência num trecho parcial não é ausência; os
  controles Enterprise e a trilha OTel ficaram fora (`E_OBJECAO_25_CHANGELOG_READ_9_PERCENT`,
  `E_OBJECAO_24_NATIVE_ENTERPRISE_CONTROLS_CUT`).

**Refutadas (10).** Nenhuma virou evidência; cada uma tem superação modelada (`C_SUPERACAO_20261027_…`).
**Por fonte fraca (tier ≤ 4): 4**, todas vindas de blog ou artigo de terceiro:

| Tier | Fonte | Claim refutada | O que a superou |
|---|---|---|---|
| 4 | flowhunt.io | "Google Cloud doou o A2A à AAIF em 20/08/2026" | foi 17/08/2026, como projeto hospedado (aaif.io) |
| 4 | pasqualepillitteri.it | cross-session indisponível em Bedrock, Vertex e Foundry | a mesma máquina funciona em todos desde a 2.1.248 |
| 4 | pasqualepillitteri.it | entre máquinas só respostas, nunca abrir conversa | abrir conversa existe desde a 2.1.225 |
| 4 | grith.ai | a spec A2A não define autorização nem anti-injeção | autorização é MUST (§13); anti-injeção de fato ausente |

As outras 6 caíram em fonte forte (tier 6 a 10) por leitura mais fina da própria primária. O Elenxo
contestou quatro refutações (`E_OBJECAO_09`, `10`, `11`, `12`): o núcleo de cada uma volta como objeção.

**Cortadas por orçamento — as 34 fontes**, por relevância declarada no run: alta (4) aaif.io/blog/a2a-joins-aaif
(depois lida pelo Elenxo), code.claude.com agent-teams.md, keysight agent-card-poisoning e
github kaiser-data/claude-A2A-Comm; média (21), entre elas channels.md, claude-code-on-the-web.md,
LevelBlue, WorkOS, solo.io, Descope e o MCP em AWS Lambda; baixa (9), entre elas o handbook de Managed
Agents. A lista integral está no retorno do run (`budgetDropped`).

**Cortadas por orçamento — as 40 claims** vieram de 14 fontes, sobretudo glukhov.org (5),
github jjacke13/claude-peer (5) e grith.ai (4). A lista integral está no retorno (`notVerifiedByBudget`).

## Ações candidatas (o maestro decide)

1. **Rodada complementar em modo primaries** só com as fontes nomeadas acima
   (`Q_A2A_EMPRESA_RODADA_PRIMARIAS_1027`). As lacunas já têm nome, então a régua da skill manda
   primaries, não outra varredura. A medida da mesma skill: ≈42 mil tokens por nó contra ≈291 mil da
   varredura na mesma pergunta.
2. **Medir a linha de base viva VPS↔notebook** (`Q_COMPOSICAO_IDA_E_VOLTA_VIVA_1025`), de que a decisão
   depende.
3. **Selar `D_A2A_EMPRESA_ADOTANTE_TOPOLOGIA_1027`** pelo `/meta:decide`, antes ou depois de 1 e 2.

## valeu-a-pena

| Run | Modo | Tokens | Agentes | Nós | Por nó |
|---|---|---|---|---|---|
| **`wf_25860bde-222` (este)** | `decision` | 7.910.511 | 106 | 71 escritos (72 com o do pós-run) | **≈111 mil** (≈110 mil com 72) |
| `wf_88199ba9-b9a` (indivíduo × organização) | `decision` | 7.282.373 | 105 | 25 | ≈291 mil |
| `wf_1865aba9-e20` (mesma pergunta) | `primaries` | 2.680.149 | 28 | 64 | ≈42 mil |
| censo (típico da skill) | — | — | — | — | 68–74 mil |

Custou **≈2,6 vezes menos por nó** que a varredura de referência em modo decision, porque modelou as 31
objeções sobreviventes e as 16 superações como nós, em vez de deixá-las no journal. Custou **≈1,5 vez mais**
que o censo e **≈2,6 vezes mais** que o modo primaries. O valor está no mapa das lacunas: a varredura deu
nome às fontes que faltam, e a rodada seguinte pode ir pelo modo barato. O preço é o corte de orçamento,
que deixou cinco fontes load-bearing sem leitura **antes** de uma decisão de topologia.

## Rodada complementar em modo primaries (2026-10-27)

O maestro escolheu rodar a rodada antes de selar (`Q_A2A_EMPRESA_RODADA_PRIMARIAS_1027`, selada). Ela
rodou como **`wf_bd8f7f49-808`**: **1.361.368 tokens, 18 agentes, ~13 min**, 95 chamadas de ferramenta.
O retorno integral está em [`data/run-wf_bd8f7f49-808.json`](data/run-wf_bd8f7f49-808.json), e a
contabilidade, em `E_LACUNAS_A2A_EMPRESA_RODADA_PRIMARIAS_1027`.

**Contabilidade:** 7 fontes lidas, 0 inalcançáveis; **25 claims ancoradas** por verificador independente,
todas como nó de evidência; **12 rejeitadas** na ancoragem; 26 objeções julgadas pelo Elenxo, **8
sobreviventes** (todas modeladas, `E_OBJECAO_32` a `E_OBJECAO_39`), 18 derrubadas, 0 recusadas pelo motor;
**11 superações** achadas. O grafo foi de **72 para 119 nós** (+47), só por acréscimo.

### O que a rodada ancorou (25 evidências)

- **Channels** (`code.claude.com/docs/en/channels.md`, tier 9): a autenticação é uma allowlist de IDs da
  plataforma de chat, sem credencial criptográfica do remetente (`E_CC_CHANNELS_SENDER_ALLOWLIST`); o relay
  de permissão faz do colega da allowlist um **aprovador de ferramenta**, o oposto de "mensagem de colega é
  informação" (`E_CC_CHANNELS_PERMISSION_RELAY_APPROVER`); em Team e Enterprise quem liga primeiro é o
  Owner e depois o usuário, sessão a sessão (`E_CC_CHANNELS_ENTERPRISE_OPT_IN`); e a sessão pausa no prompt
  de permissão (`E_CC_CHANNELS_PAUSES_ON_PERMISSION_PROMPT`). Se o evento acorda uma sessão **ociosa** segue
  sem âncora (`E_OBJECAO_32`).
- **`isolatePeerMachines` e `crossSessionInbound`** (cross-session e settings, tier 9): a aprovação antes de
  a mensagem sair para outra máquina vale sob `bypassPermissions`, e o arquivo de projeto liga, mas não
  desliga (`E_CC_ISOLATE_PEER_MACHINES_BYPASS_ONE_WAY`); ninguém a desliga por cima, nem o managed
  (`E_CC_ISOLATE_PEER_MACHINES_OVER_MANAGED`). Consequência: numa sessão sem operador, a mensagem para
  outra máquina fica parada até alguém aprovar. O `crossSessionInbound` aceita `accept`, `hold` ou
  `refuse` (`E_CC_CROSS_SESSION_INBOUND_THREE_VALUES`), o padrão sob bypass é reter
  (`E_CC_CROSS_SESSION_INBOUND_BYPASS_DEFAULT_HOLD`) e o arquivo de projeto só endurece
  (`E_CC_CROSS_SESSION_INBOUND_PROJECT_ONLY_HARDENS`; o desligamento da organização pelo admin ficou sem
  citação, `E_OBJECAO_33`).
- **A spec A2A 1.0** (`a2a-protocol.org`, tier 9): a assinatura do Agent Card é **MAY**
  (`E_A2A_SPEC_CARD_SIGNING_MAY`), a canonicalização JCS é MUST quando há assinatura
  (`E_A2A_SPEC_CARD_JCS_MUST_WHEN_SIGNED`) e a verificação é **SHOULD** (`E_A2A_SPEC_CARD_VERIFY_SHOULD`).
  Autenticação em toda requisição e autorização em toda operação são MUST
  (`E_A2A_SPEC_AUTHN_EVERY_REQUEST_MUST`, `E_A2A_SPEC_AUTHZ_EVERY_OPERATION_MUST`), e `AUTH_REQUIRED` não é
  autorização (`E_A2A_SPEC_AUTH_REQUIRED_NOT_AUTHZ`). É o fato normativo que justifica o perfil do Onion
  endurecer assinatura e verificação para MUST, declarado como delta sobre a spec.
- **Nuvem e Managed Agents** (tier 9): as sessões na nuvem ficam fora de ZDR, HIPAA e CMEK
  (`E_CC_CLOUD_SESSIONS_EXCLUDED_ZDR_HIPAA_CMEK`), e o Managed Agents roda no servidor sem ZDR nem BAA
  (`E_MANAGED_AGENTS_SERVER_SIDE_NO_ZDR_BAA`). O que eles oferecem **entre pessoas** não foi ancorado
  (`E_OBJECAO_34`, `E_OBJECAO_35`).
- **Ataques ao Agent Card** (tier 3, blogs de fornecedor de segurança): a definição do envenenamento de
  card (`E_KEYSIGHT_CARD_POISONING_DEFINITION`), a superfície maior do A2A remoto
  (`E_LEVELBLUE_A2A_REMOTE_LARGER_SURFACE`) e a mitigação genérica do praticante
  (`E_LEVELBLUE_MITIGATION_GENERIC`). Somadas ao MAY e ao SHOULD da spec: nem a spec nem o praticante dão
  mitigação obrigatória ao envenenamento de card.
- **O CHANGELOG do Claude Code, baixado inteiro** (tier 9, linhas conferidas por `grep -nF`): o aviso de
  mensagem retida no receptor na 2.1.271 (`E_CHANGELOG_2_1_271_INBOUND_HELD_NOTICE`), a fila de mensagem
  entre máquinas por Remote Control na 2.1.261 (`E_CHANGELOG_2_1_261_REMOTE_CONTROL_QUEUE`) e os papéis
  Enterprise na 2.1.310 (`E_CHANGELOG_2_1_310_ENTERPRISE_ROLES`).
- **A AAIF** (`aaif.io/blog/a2a-joins-aaif`, tier 9): a AAIF hospeda o A2A sob a estrutura da Linux
  Foundation (`E_AAIF_HOSTS_A2A_LF_STRUCTURE`) como casa neutra da pilha (`E_AAIF_NEUTRAL_HOME_STACK`). A
  data ficou sem âncora nesta rodada (`E_OBJECAO_39`) e foi ancorada depois, na reconciliação (abaixo).

### As 12 rejeitadas na ancoragem

Nenhuma virou evidência. Onze foram **exageradas** e têm superação modelada (`C_SUPERACAO_20261027_…`);
uma foi **afirmada sem citação** e não tem.

| # | Fonte | Claim rejeitada | Por quê |
|---|---|---|---|
| 1 | channels | "é bidirecional, só enquanto aberta" | o texto diz "can be two-way" |
| 2 | channels | "não há fila nem entrega a sessão encerrada" | o texto não fala de fila |
| 3 | cross-session | "exige login claude.ai, não API key" como condição geral | vale só para sessões além da máquina |
| 4 | nuvem | "só pela conta do próprio usuário, sem mensagem entre pessoas" | o Auto-fix recebe comentário de revisor do GitHub e as sessões do Slack são compartilhadas |
| 5 | nuvem | "compartilhamento é só leitura, Private/Team" | "read-only" não aparece, e Max/Pro têm Public |
| 6 | nuvem | "o link é visão estática, logo não é canal" | "estática" e a conclusão são do leitor |
| 7 | nuvem | "VM e dados na Anthropic definem o dono do dado" | o trecho trata de VM, isolamento e rede, não de titularidade |
| 8 | ataques ao card | mecanismo do agent-in-the-middle | **afirmada sem citação**: veredito sem quote nem locator |
| 9 | ataques ao card | "metadados viram instrução executável" | o texto diz "may treat" |
| 10 | CHANGELOG | "cross-session APENAS na mesma máquina" | a linha 3253 contradiz |
| 11 | CHANGELOG | "managed manda, logo o admin liga e desliga" | o trecho trata só de valor inválido |
| 12 | CHANGELOG | "MCP 2026-07-28 por padrão" | apagou "on installs that fetch no flags" |

### As 6 lacunas que seguem abertas

1. **Channels numa sessão ociosa:** nenhuma claim ancorada diz se o evento acorda a sessão e é processado
   (`E_OBJECAO_32_CHANNELS_IDLE_DELIVERY_UNANCHORED`).
2. **O que a nuvem e o Managed Agents oferecem entre pessoas**, e a ausência de primitivo entre usuários
   sem citação (`E_OBJECAO_34`, `E_OBJECAO_35`).
3. **A ausência de assinatura de mensagem na spec 1.0** não foi medida no documento inteiro
   (`E_OBJECAO_36_MESSAGE_SIGNING_ABSENCE_UNMEASURED`).
4. **O mecanismo do agent-in-the-middle** está sem citação, e a ligação entre assinatura e envenenamento é
   inferência (`E_OBJECAO_37_AITM_MECHANISM_UNANCHORED`).
5. **Não há censo do CHANGELOG por eixo**, e a entrada de MCP remoto foi rejeitada
   (`E_OBJECAO_38_CHANGELOG_CENSUS_MISSING`; caminho natural: `/meta:cc-update`).
6. **A data de entrada do A2A na AAIF** e a contradição com `G4_AAIF_A2A_SEPARATE`
   (`E_OBJECAO_39_AAIF_DATE_AND_G4_CONTRADICTION`). **Fechada depois da rodada, na reconciliação** pedida
   pelo maestro (abaixo); o nó da objeção fica como registro do que a rodada não fechou.

Seguem abertas do run anterior e fora desta rodada: a adoção real do A2A em produção, dois membros da
mesma org Team, o custo da B serverless, a taxa de entrega e perda, a idempotência da tool de rascunho e a
linha de base VPS↔notebook.

### valeu-a-pena (a rodada)

| Run | Modo | Tokens | Agentes | Nós novos | Por nó |
|---|---|---|---|---|---|
| **`wf_bd8f7f49-808` (esta rodada)** | `primaries` | 1.361.368 | 18 | 47 | **≈29 mil** |
| `wf_25860bde-222` (o run anterior) | `decision` | 7.910.511 | 106 | 72 | ≈110 mil |
| `wf_1865aba9-e20` (referência) | `primaries` | 2.680.149 | 28 | 64 | ≈42 mil |

Valeu: **≈3,8 vezes menos por nó** que o run em modo decision e ≈1,5 vez menos que a referência em modo
primaries, porque as lacunas já tinham nome e a rodada foi direto às fontes. Fechou quatro lacunas
(`isolatePeerMachines` e `crossSessionInbound`, autenticação e gate de Channels, card, autenticação e
autorização da spec, controles Enterprise) e trocou um "não lido" por um "lido e rejeitado" em doze
claims. O limite: seis lacunas seguem abertas, e duas delas (Channels em sessão ociosa e o que a nuvem
oferece entre pessoas) só fecham com spike, não com mais leitura.

## Selos do maestro (2026-10-27)

Todos gravados por `bash .claude/validation/kg-decide-seal.sh`, com radar e contrato verdes a cada selo.

| Nó | Pergunta | Resposta | Rejeitadas |
|---|---|---|---|
| `Q_A2A_EMPRESA_RODADA_PRIMARIAS_1027` | Rodar a rodada complementar antes de selar? | Rodada complementar antes (rodou: `wf_bd8f7f49-808`) | Selar a combinação recomendada · Bridge hospedado em produção · Depois |
| `Q_A2A_EMPRESA_SELO_CONDICOES_1027` | Selar como direção, com as condições? | Sim: selar como direção com as condições | Não |
| `D_A2A_EMPRESA_ADOTANTE_TOPOLOGIA_1027` | Como selar a topologia de A2A para empresas? | Selar como direção, com as condições, e o enquadramento do maestro (abaixo) | Selar sem a camada nativa · Esperar a ida e volta medida · Depois |
| `Q_AAIF_G4_SUPERSEDE_PROPOSAL_1027` | Ancorar a data e gravar a SUPERSEDES do G4? | resposta livre (`--other`): a diretriz da AAIF (abaixo) | nenhuma registrada: as opções oferecidas não chegaram ao escritor do selo, e o nó diz isso |

**O enquadramento do maestro**, verbatim no nó D_:

> Selada como DIREÇÃO, não como avaliação completa. O padrão de comunicação é o A2A aberto (AAIF/Linux
> Foundation); o A2A do Onion é o EMPACOTAMENTO desse padrão com o que falta: identidade fixada no
> members.yaml, card assinado e verificado como MUST (a spec diz MAY e SHOULD), corpo assinado, envio só
> em rascunho, inbox durável no receptor e mensagem de colega tratada como dado. Entre pessoas: receptor
> A2A 1.0 em self-host da empresa. Mesma pessoa: canal nativo com isolatePeerMachines. FORA: Channels
> entre pessoas, e nuvem e Managed Agents para adotante regulado. Condição de produção: a ida e volta
> medida entre a VPS e o notebook, incluindo a entrega a uma sessão que estava fechada.

**A diretriz do maestro sobre a AAIF:** "aaif.io é fonte constante de consulta, validação e avaliação dos
projetos, documentos e recomendações do Onion; não reinventar a roda, o novo parte do conhecido." Ela foi
executada em dois atos:

- **A reconciliação do G4.** O post <https://aaif.io/blog/a2a-joins-aaif> foi reaberto por WebFetch em
  2026-10-27: datado de **2026-08-17**, título "A2A joins AAIF's open agentic stack", com a frase "is
  joining the Agentic AI Foundation (AAIF) as a hosted project". O nó novo
  `E_AAIF_HOSTS_A2A_SINCE_2026_08_17`, no grafo `docs/onion/graph/federation-research-2026-06-reconciled.kg.yaml`,
  **SUPERSEDES** `G4_AAIF_A2A_SEPARATE`, que fica no grafo como `superseded`, com `x_valid_to: "2026-08-17"`
  (o contrato v4 não tem campo `valid_to`; a extensão leva o prefixo `x_`). Nada foi apagado.
- **A AAIF entrou no roster de fontes** (`docs/onion/radar-sources.yaml`), num grupo novo
  `padroes-agentes`, porque nenhum dos oito grupos cobria padrão de protocolo de agentes nem a fundação
  que os hospeda.

**O que o selo não fecha:** a condição de produção (`Q_COMPOSICAO_IDA_E_VOLTA_VIVA_1025`, a ida e volta
medida VPS↔notebook com entrega a sessão fechada) segue aberta, e as cinco lacunas restantes acima também.
