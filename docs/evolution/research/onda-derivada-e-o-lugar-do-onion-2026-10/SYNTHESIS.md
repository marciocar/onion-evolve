---
title: A onda derivada e o lugar do Onion — que peça ele é, e onde isso gera receita agora
date: 2026-10-01
kg: docs/evolution/research/onda-derivada-e-o-lugar-do-onion-2026-10/onda-derivada-e-o-lugar-do-onion-2026-10.kg.yaml
run_id: wf_fcacd012-07e
tokens: 10173983
agents: 148
duration_min: 99
review_after: 2026-10-31
type: research
mode: decision

> **Projeção do grafo, nunca fonte.** Formulário de decisão para o maestro:
> https://claude.ai/artifact/2kAYgkg214q4PuUgoEcdWF — seis blocos, cada opção com veredito e
> evidência datada. Nenhuma decisão aqui está selada.

## Resposta primeiro

Das quatro posições na cadeia de valor de outra pessoa, a peça que o Onion tem **mais pronta** é a
**PÓS** — *provar com evidência o que o agente fez e **com base em quê***. E a razão não é
preferência: é que **o buraco é auto-declarado pelo próprio ocupante**. Assina-se e atesta-se a
*execução*; ninguém responde o *"com base em quê"*. A metade "integridade" do PÓS já é **commodity
grátis**; a metade **"razão da decisão"** é a que sobra.

- **PRÉ (decidir: custo, roteamento) — FIQUE LONGE.** Está sendo absorvida pela plataforma no
  changelog *deste trimestre*: limite de gasto em dólares visível em `/usage` (2.1.284, 2026-09-28)
  e `assume_role` em upstreams Bedrock (2.1.281, 2026-09-23). Entrar nela é competir com o
  changelog.
- **DURANTE (gate) — validado por analista, sem fornecedor pago.** O Thoughtworks Radar Vol 34
  (abril/2026) põe *"feedback sensors for coding agents"* em **Trial**, e os pares diretos
  (agentplane, watchflow) são OSS sem receita. Somado à medição anterior de que o `exit 2` de hook
  é **substrato nativo e grátis**: o veto não é o produto.
- **META (conhecimento que não evapora)** — tem **selo de analista como DOR** (*agent instruction
  bloat* em **Caution**) e **segue sem comprador**.

**O único gargalo derivado com preço publicado** é **revisão de PR escrito por agente**: Stage, a
**US$30/usuário/mês** no Team, grátis em repo público (medido 2026-04). É o **único comparável de
preço** desta rodada para ancorar proposta.

**O único canal com taxa publicada** é marketplace de **terceiro** (Agensi, **30%**) — o
marketplace oficial **não documenta cobrança alguma**.

## A reconciliação da pilha refutada — e aqui ela PROTEGE a tese

Duas claims refutadas são as mais importantes da rodada, porque, se confirmadas, teriam absorvido
justamente a posição recomendada. Os refutadores mediram na primária e a distinção é limpa:

| Claim refutada | O que a primária diz |
|---|---|
| *"o Copilot já traz camada nativa de governança (AI Controls) → DURANTE está ocupado"* | **OVERREACH**. A página é de **adoção/entitlement**: *"control how Copilot cloud agent is **adopted**"*, *"manage and monitor AI policies"*, *"control the **availability** of third-party agents"*. Zero menção a bloquear tool call, commit, push ou merge **enquanto o agente roda**. Toggle de adoção ≠ gate. Na taxonomia da pergunta isso é **PRÉ**, não DURANTE |
| *"a plataforma já provê auditoria e evidência nativas da atividade do agente"* | mesma classe: listas de sessão, eventos de audit log e streaming são **registro de execução**, não o *"com base em quê"* |

E há contra-evidência **na própria doutrina da GitHub**: o bloqueio que existe vem de
ruleset/branch protection genéricos e **nega acesso ao agente** — *"access to the agent will be
blocked"* — sem motor de política por ação autorável pelo admin.

**Consequência:** a posição PÓS/"razão da decisão" **não está absorvida**, e a refutação é o que
prova isso. Descartar a pilha refutada teria perdido o achado que mais sustenta a recomendação.

## O precedente histórico (eixo 5) e o anti-padrão (eixo 6)

O padrão que a pergunta buscava — CI/CD → proveniência (SLSA, SBOM); cloud → custo e postura
(FinOps, CSPM); microsserviço → observabilidade — **não foi fechado com fonte datada** nesta
rodada. O que entrou do lado do anti-padrão: o **Flowise** anunciou encerramento em **29/07/2026**
(repo arquivado 10/08, fim de vida 31/08), com causa declarada de **deslocamento** — acertou o
gargalo e morreu porque a plataforma/modelo absorveu a função. É o mesmo formato do precedente
**Styra/OPA** medido antes: produtos comerciais **doados à CNCF**, não vendidos nem
descontinuados.

## NÃO-VERIFICADOS (declarado, não escondido)

- **`unverified`: 0** — nenhuma claim caiu por 403 ou truncagem.
- **`notVerifiedByBudget`: 64 claims** de 100 levantadas nunca chegaram ao repasse adversarial — o
  teto de `maxVerify` mordeu **~64%**. Entre as perdidas: a tração do Stage (~57 mil PRs revisados,
  **sem receita nem clientes divulgados** — sinal de tabela de preço, não de receita comprovada) e
  o registro de MCP do Copilot.
- **`budgetDropped`: 16 URLs**, incluindo `permit.io/mcp-gateway` e o changelog de habilitação de
  modelo do Copilot Business/Enterprise.
- **`refuted`: 17** — e a seção acima mostra por que lê-las é obrigatório, não opcional.
- **Sem sinal, explicitamente:** nenhum TAM sobreviveu · nenhuma rodada de capital **nova** nesta
  passada · nenhum fornecedor com preço para **onboarding de agente em repo legado** nem para
  **condução/adoção de framework de agente**. A frente de receita mais curta do Onion é também a
  **sem comparável público**.

## valeu-a-pena

| Medida | Esta rodada | Histórico |
|---|---|---|
| tokens | 10.173.983 | — |
| nós no grafo | 42 | — |
| **tokens / nó** | **≈ 242.000** | 68k (2026-08-30) · 74k (2026-09-01) |
| agentes | 148 | — |
| duração | 99 min | — |

**Regressão de ≈ 3,3×, e é achado.** Somada à rodada irmã de hoje (212k/nó), as duas rodadas
`mode: decision` de 148 agentes custaram **20,2M de tokens** e entregaram **zero decisão selada** —
por desenho (o comando nunca sela), mas também com **~64% das claims fora do repasse** nas duas. O
`price_per_node` do `/meta:census` **não** deve herdar este número: é o teto de custo da casa, não
a média. **Gatilho nomeado:** a próxima rodada `mode: decision` entra com `maxVerify` maior **ou**
com menos eixos — pagar 10M para deixar 64% sem verificar é o defeito, não o preço.

## O que fica aberto (o maestro sela, no formulário)

6 perguntas, e as duas que decidem: **qual metade do ativo entra no primeiro pacote pago** — o gate
(as 5.282 linhas de shell que REPROVAM, a metade que o mercado já provou não sustentar preço) ou o
**grafo bi-temporal com proveniência** —, e **quem é o comprador do "com base em quê"**: engenharia
(DevEx) ou compliance/auditoria interna. A resposta decide se o canal é plugin/skill ou proposta de
serviço, e **a rodada não mediu nenhum dos dois orçamentos**.

**Fechamento sobre a cláusula 11** (lente da onda derivada, candidata a entrar na doutrina de
pesquisa): ela rendeu **quatro achados que os outros dez eixos não renderiam** — preço em revisão
de PR, taxa de canal de 30%, o buraco auto-declarado do TRACE, e a absorção do PRÉ pelo changelog.
Pelo gatilho declarado na abertura, isso a mantém **candidata confirmada**, não refutada.
