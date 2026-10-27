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

> **Projeção do grafo, nunca fonte.** A decisão `D_A2A_EMPRESA_ADOTANTE_TOPOLOGIA_1027` está **`open`**.
> Esta sessão não sela: o maestro sela pelo `/meta:decide`. O retorno integral do run está em
> [`data/run-wf_25860bde-222.json`](data/run-wf_25860bde-222.json).

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
