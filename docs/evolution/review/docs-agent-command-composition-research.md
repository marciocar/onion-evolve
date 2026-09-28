---
title: 'Duas rodadas, e o refutador derrubou a minha própria síntese'
date: 2026-09-28
branch: docs/agent-command-composition-research
reviewed_diff_sha256: f92960b6fe24c5446874794ba7a5ebc061d5d0279c3f6b2cce1475b8eddea7a8
elenxo: sim
findings_total: 6
findings_real: 6
verdict: REPROVADO_E_CURADO
tokens: 8217748
duration_min: 83
agents: 114
nota: 'Elenxo SIM, e não por mim: o refutador é fase do próprio workflow `/onion-research` em modo primaries, e a objeção que ele levantou DERRUBOU a tese central que eu havia escrito na síntese. Dos 6 achados, 1 é meu erro de leitura corrigido pelo refutador, 4 são claims rejeitadas na ancoragem, e 1 é a lacuna de eixo que declaro sem fechar. O revisor semântico do CI segue fora por saldo da conta de API; o CI do repo está inoperante desde 2026-09-26T23:46Z.'
---

# Resíduo — duas rodadas sobre a composição de comando de agente

## O achado que vale mais: o refutador derrubou a MINHA síntese

Eu escrevi, na primeira redação, que *"o campo já tem destino declarativo e validade temporal"*. A
metade do **destino** era generosa, e a objeção do Elenxo **sobrevive**:

O `Context Store` do *Context Kubernetes* é peça da **via de LEITURA**. A única interface voltada ao
agente é `Definition 3.4 (Context Endpoint)`, **read-only por assinatura**, seguida de
*"The agent never specifies where knowledge lives—only what it needs."*

**Medido no texto inteiro, 88 KB:** `write(` ocorre **uma vez**, só na assinatura do CxRI, **sem
critério de aceitação**; `agent-produced`, `knowledge produced`, `write path`, `writes back`,
`contribute knowledge` → **zero**.

**Definir onde o conhecimento mora para ser ENTREGUE não é impor destino ao conhecimento PRODUZIDO.**
E a correção fortalece a conclusão em vez de enfraquecê-la: o `kg-radar exit 0` como **precondição** do
`write(KG)` não tem equivalente publicado nas quatro fontes primárias lidas.

## As 4 rejeitadas na ancoragem, e a que ensina

| fonte | veredito | o que caiu |
|---|---|---|
| `agentskills-spec` | `NÃO-ENCONTRADA` | versionamento normativo e governança/validação |
| `conductor-msft` | `EXAGERADA` | **"roteia, não veta"** — confirmado em conteúdo, **caído por locator** |
| `conductor-msft` | `EXAGERADA` | schema de output tipado por agente |
| `mcp-governance` | `EXAGERADA` | lista de membros fundadores por nível |

**A segunda é a lição:** o trecho existe, mas **no post do blog e não no README** como o leitor afirmou,
e o exemplo linkado (`examples/design-review.yaml`) **não existe no repositório** — o real é
`examples/design.yaml`. A ancoragem não pergunta *"isto é verdade?"*, pergunta ***"o texto diz isto,
aqui?"*** — e **claim certa sem âncora exata não vira nó**. Foi para a contabilidade de
`E_LACUNAS_PRIMARIES_0928`, de graça, sem virar afirmação.

## A régua provou-se, com número

| rodada | tokens | agentes | nós | por nó |
|---|---|---|---|---|
| varredura | 7.265.255 | 104 | 8 | **~908k** |
| primárias | **952.493** | **10** | **+18** | **~53k** |

**17× mais barato por nó.** A varredura pagou **descoberta** para uma pergunta cujas fontes eram poucas
e nomeáveis, e teve **20 refutadas todas por fonte fraca** — nenhuma por contra-evidência — mais 66
claims sem verificação por teto. O teto que **eu** declarei (`maxFetch 15`) foi o gargalo, não a
disponibilidade de fonte. A tabela da skill previa ~42k/nó para `primaries`; bateu em 53k.

## Aufhebung real, não decorativa

A newsletter tier 5 que sustentava a governança do MCP foi **supersedida** por fonte institucional
tier 10 e reconciliada para `superseded` — e a formulação foi **corrigida no caminho**: o MCP não
*"passou a ser governado"* pela AAIF; ele é **contribuição fundadora** dela, ao lado de `goose` e
`AGENTS.md`, desde 2025-12-09.

## O que NÃO foi medido, e fica dito

**Eixo CAPITAL: zero.** Nenhuma rodada de investimento, M&A, valuation ou down round — porque **nenhum
worker foi posto em base de capital**. É **lacuna de busca, não ausência de mercado**, viola
`follow-the-money-e-eixo-de-pesquisa`, e **não se fecha em `primaries`** (não há documento nomeado a
ler). Exige varredura por trajetória, numa rodada própria.

## Gate

- `lint-artifacts.sh` → **rc=0 · 0 HARD · 15 SOFT**
- `lint-selftest.sh --affected-staged --jobs auto` → **66 casos · 0 falhas**
- `kg-radar --integrity --schema` → **exit 0** (26 nós · 56 arestas)
- `kg-realign-project.sh` → **ALINHADO** nos cinco grafos da sessão, `(c)=0 (b)=0 (a)=0`
- **Nada selado:** as duas propostas de veredito são nós `question` abertos.

⚠️ **CI do repositório INOPERANTE** desde 2026-09-26T23:46Z (rajada de `startup_failure`, inclusive em
`main`). Este PR precisará do escape `--ci-inoperante`, que **prova** a inoperância no forge e **executa**
lint e bancada antes de liberar — não é `--force` com nome bonito.

## Rebase sobre o main de 2026-09-28

Este resíduo foi re-carimbado após rebase sobre `origin/main`, que passou a conter a cura da porta
(PR #883). O conflito caiu em `docs/onion/testing-state.md` — projeção GERADA — e foi resolvido
REGENERANDO do produtor, nunca escolhendo um lado: escolher lado numa projeção gerada é redigir
painel à mão, que é o que a REGRA 81 (Painel de estado é GERADO dos produtores, nunca redigido)
existe para impedir. O hash acima é o do diff pós-rebase.
