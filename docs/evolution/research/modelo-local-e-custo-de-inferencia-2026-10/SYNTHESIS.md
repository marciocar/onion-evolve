---
title: A pergunta estava mal posta — e a própria casa é a prova
date: 2026-10-02
kg: docs/evolution/research/modelo-local-e-custo-de-inferencia-2026-10/modelo-local-e-custo-de-inferencia-2026-10.kg.yaml
run_id: wf_24ac2f5e-fbf
tokens: 15281705
agents: 192
duration_min: 97
review_after: 2026-11-01
type: research
mode: decision

> **Projeção do grafo, nunca fonte.** A decisão fica `open` — esta sessão não sela.

## Resposta primeiro: não há o que economizar onde eu procurei

O gate determinístico desta casa — 26.441 linhas de shell, 93 regras, radar sem LLM, 1605 asserções —
**não gasta token nenhum**. Custa **minuto de runner**. E a doc oficial da Anthropic recomenda
**exactly essa troca**: mover verificação para hook determinístico, caindo de **dezenas de milhares
de tokens para centenas**.

Ou seja: a parte do ciclo que eu ia otimizar **já está grátis e já é a prática recomendada**. Ela
**fica como está**.

## Modelo local nesta VPS: armadilha MEDIDA, não hipótese

- Um **32B denso Q4** entrega **3,54 tok/s** numa CPU **melhor** que esta (12c/24t, 96 GB).
- Aqui ele competiria pelos **mesmos 8 cores** que a bancada satura por **17 min**.
- E a página de benchmark da Qwen **não traz uma única medição CPU-only** — a faixa **sequer é
  anunciada** para este uso.

Não é "ruim": é **fora de escopo declarado pelo próprio fornecedor**.

## A ordem de retorno por esforço, com gatilho

| # | Movimento | Número | Gatilho |
|---|---|---|---|
| **1º** | **prompt caching, TTL de 1h** | leitura a **0,1×** do input; mínimo cacheável caiu para **512 tokens** | "o intervalo entre chamadas passa de 5 min" |
| **2º** | **Batch API** nas pernas assíncronas | **50%** em entrada **e** saída | "a perna não é interativa" |
| **3º** | **tiering por fase** | time de agentes usa **~7× mais token** que sessão padrão | já é doutrina **e** recomendação oficial |
| **4º** | cascata / porteiro com modelo pequeno | arte estabelecida (FrugalGPT; CodeJudgeBench: **Qwen3-8B com thinking supera juízes treinados de até 70B**) | só onde o salto de preço é **real** |

**O 3º já é a casa.** O tiering (Haiku para subagente simples, Sonnet para a maioria, Opus para
raciocínio complexo) é literalmente a recomendação oficial — logo a doutrina de `model+effort` por
fase não é preferência, é prática validada externamente.

## O que REFUTOU a tese da economia por modelo barato

**Toda claim que diria "modelo barato revisa igual" foi REFUTADA nesta rodada.** Barebone aberto só
vale onde o salto de preço é grande de verdade — **DeepSeek V4.1 Flash a $0.30/$1.20** e **Qwen3.8
Flash a $0.09/$0.28** contra **Haiku a $1/$5** — e **nunca para substituir o juiz final**.

E a premissa "fronteira é caro, aberto é barato" **enfraqueceu**: o aumento previsto de Sonnet para
**$3/$15** em 1/set/2026 **não ocorreu**, e o Sonnet 5.5 segue a **$2/$10** — mais barato que o
Sonnet 4.6. Tabela de out/2026: **Haiku 4.5 $1/$5 · Sonnet 5.5 $2/$10 · Opus 5.5 $4/$20 · Fable 5.1
$10/$50**, com contexto de 1M **sem sobretaxa** nos 4.6+.

## O mercado está fazendo o MESMO movimento que esta casa

**Copilot Code Review saiu do incluído e virou AI Credits em jun/2026, com a cota caindo de 3.000
para 1.900 em set/2026.** A casa desligou o revisor semântico por crédito e manteve os gates
determinísticos verdes — e isso não é improviso: é a direção que o fornecedor líder tomou.

## NÃO-VERIFICADOS

- **`unverified`: 0.** Nenhuma claim caiu por 403 ou truncagem.
- **`notVerifiedByBudget`: 31** de 83 claims (**37%**) — contra ~64% nas duas rodadas de ontem.
- **`budgetDropped`: 27 URLs.**
- **`refuted`: 19** — e ler esta pilha foi obrigatório: é dela que sai o veredito contra o modelo
  barato no juízo final.
- **SEM SINAL de CAPITAL**: nenhuma rodada, valuation ou M&A de 2026 em inferência barata sobreviveu
  aos votos. O eixo 7 está respondido só pelo lado comercial/preço.

## valeu-a-pena — e o gatilho que eu nomeei FUNCIONOU

| Medida | Esta rodada | As duas de ontem |
|---|---|---|
| tokens | 15.281.705 | 10,0M · 10,2M |
| nós | **62** | 48 · 42 |
| **tokens / nó** | **≈ 246k** | 212k · 242k |
| **claims verificadas** | **63%** (52/83) | **~36%** |
| agentes | 192 | 148 · 148 |

Subi `maxVerify` de 36 para **52** honrando o gatilho que eu mesmo havia escrito nas sínteses de
ontem. **Resultado: a fração verificada quase dobrou (36% → 63%) com custo por nó praticamente
igual** (~246k contra 212–242k). O gatilho comprou **cobertura**, não gastou mais por unidade — e
isso é eficiência, não economia. Mantenha a faixa.

## O que fica aberto

A decisão segue `open`: 9 perguntas, e a que decide é **onde o porteiro entra sem ferir "sempre o
latest/máximo com escada e degradação visível"** — porque o 4º movimento é o único que mexe em
qualidade de veredito, e a doutrina proíbe degradar veredito para economizar.

**O que fica como está, nomeado:** o gate, o radar, a bancada, o `exit 2` — e o revisor semântico
desligado por crédito.
