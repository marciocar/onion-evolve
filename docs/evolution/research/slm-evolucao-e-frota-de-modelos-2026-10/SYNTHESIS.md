---
title: A linha do tempo dos SLMs sobrevive até 2025 — e a fase 2026 é declaração de fornecedor
date: 2026-10-02
kg: docs/evolution/research/slm-evolucao-e-frota-de-modelos-2026-10/slm-evolucao-e-frota-de-modelos-2026-10.kg.yaml
run_id: wf_c91aa717-878
tokens: 12213737
agents: 175
duration_min: 91
review_after: 2026-11-01
type: research
mode: research

> **Projeção do grafo, nunca fonte.** A narrativa de origem veio de outro assistente e entrou como
> **dado a verificar**, nunca como evidência.

## O achado que derruba a narrativa, e ele vem do analista INDEPENDENTE

O **Thoughtworks Technology Radar** carrega o blip *small language models* desde **out/2024 (Trial)**
e **MOVEU DE TRIAL PARA ASSESS** entre abr/2025 e nov/2025, **mantendo Assess em abr/2026**.

Ou seja: **o analista independente REBAIXOU a recomendação no mesmo período em que o discurso de
fornecedor subia para "agente local"**. Quando as duas curvas apontam em direções opostas, a do
fornecedor é a suspeita.

## A linha do tempo, fase por fase — o que sobreviveu

| Fase | Veredito | Evidência |
|---|---|---|
| **2023** — SLM como LLM comprimido | plausível, **pouco medido** nesta rodada | — |
| **2024** — eficiência + qualidade do dado | **A MAIS SÓLIDA**, com data e fornecedor | Phi-3-mini: **3,8B, 3,3T tokens, 69% MMLU, 8,38 MT-bench**, rivalizando com modelos muito maiores |
| **2025** — reasoning + multimodal + edge | **PARCIALMENTE REFUTADA: dois marcos são de 2024** | MoE e multimodal em SLM já estão na v4 do paper Phi-3 (**2024-08-30**): Phi-3.5-MoE (16×3,8B, **6,6B ativos**) e Phi-3.5-Vision |
| **2026** — SLM como agente local | **SÓ DECLARAÇÃO DE FORNECEDOR** | blog Gemma 4 (**2026-04-02**) com eco da NVIDIA no mesmo dia, + um **position paper de jun/2025**. **Nenhuma medição de produção atravessou os três votos.** |

**A fase 2025 é retrospectiva arrumada.** Marcos de 2024 foram realocados para ela — e é exatamente o
sintoma de "narrativa limpa demais" que eu pedi para procurar.

## A tabela de claims

| # | Claim | Veredito |
|---|---|---|
| **(a)** | variante pequena de reasoning na família Phi | **CONFIRMA, com correção de fornecedor**: Phi-4-mini-reasoning, 3,8B, 128K, abr/2025 — **Microsoft, não Google** |
| **(h)** | a survey SLM-first / LLM-fallback | **CORRIGIDA**: é arXiv **2506.02153**, v1 **2025-06-02**, **NVIDIA Research + Georgia Tech** — **anterior** à narrativa de 2026, e é **position paper, não medição** |
| (b)–(g) | contexto 128k, Gemma 3n 2-3 GB, Gemma 4 agentic, 270M, DiffusionGemma 26B/3,8B, INT4 2,5-4× | ver o grafo: parte confirmada, parte **refutada na atribuição** (o "DiffusionGemma" mapeia num MoE real de 128 experts, mas a atribuição da narrativa não bate) |

**E o mesmo card que confirma (a) refuta a leitura agentic:** o Phi-4-mini-reasoning é **especializado
e restrito a raciocínio matemático, com capacidade factual limitada**. *Reasoning SLM* **não é**
*agentic SLM* — a narrativa funde os dois.

## A tese da FROTA: NÃO MEDIDA

O que existe: survey de **métodos** (Moslem & Kelleher, TMLR 08/2026) · número de **benchmark
acadêmico** (BEST-Route: **−60% de custo a −1,59% de qualidade**) · analista em estágio **Assess**.

O que **não** existe: operação real com número. A única evidência de cascade em carga real cobria
**UMA tarefa (NER), em H100**, sem CPU-only e **sem custo de scaffolding** — e mesmo essa não
sobreviveu aos votos.

**Veredito: a frota é desenho defensável, não prática medida.**

## CPU-only — o constraint desta casa

**Nenhum tok/s em x86 sobreviveu aos votos.** O que resta:

- **ARM**: Raspberry Pi 5 a **7,6 tok/s de decode** no Gemma 4 E2B — **medição do próprio
  fornecedor**, logo vendor-on-self.
- **Em MoE, a MEMÓRIA segue o parâmetro TOTAL, não o ativo.** Parâmetro ativo ajuda a velocidade de
  decodificação; **não** ajuda a caber na RAM. Para quem tem 22 GB livres, a conta que manda é a do
  total.

## As minhas apostas pré-registradas

| Aposta | Status |
|---|---|
| (a) SLM ganha em classificação/extração/roteamento, perde em julgamento adversarial | **sustentada** |
| (b) o padrão de melhor retorno é porteiro, não substituto | **sustentada** (e é o que a casa já pratica como tiering) |
| **(c) CPU-only de 8 cores disputando com o gate: inviável no caminho quente** | **DE PÉ** — nenhum tok/s x86 sobreviveu |
| **(d) a escada de tamanhos é desenho de blog mais que prática medida** | **DE PÉ, sem nenhuma contra-evidência numérica sobrevivente** |

Nenhuma caiu. Isso é confortável e por isso **suspeito**: declaro que não reescrevi hipótese depois
do dado, e que o risco de apofenia estava nomeado no corpus antes de a rodada começar.

## valeu-a-pena — e um defeito do meu desenho

| Medida | Esta rodada | A irmã (custo) |
|---|---|---|
| tokens | 12.213.737 | 15.281.705 |
| nós | **40** | 62 |
| **tokens / nó** | **≈ 305k** | ≈ 246k |
| claims verificadas | **65%** (48/74) | 63% |
| **claims DUPLICADAS** | **13** | 3 |

**O custo por nó subiu (305k contra 246k) e a causa é minha:** `dupes: 13` contra 3 na irmã. Eu
declarei a fronteira entre as duas rodadas em prosa no corpus — *"o cruzamento legítimo é só o eixo
6"* — e **prosa não é fronteira**. Treze claims foram levantadas duas vezes. É a mesma lição que o
refutador que escreveu em seis arquivos já ensinou nesta casa: **instrução em prosa não segura
escritor; só mecanismo segura**.

**Cura candidata, não implementada:** o workflow aceitar uma lista de `kgPath` irmãos e descartar
claim cuja URL+asserção já exista num deles. **Gatilho:** a próxima vez que eu disparar duas rodadas
com temas vizinhos.

## O que isto implica para esta casa

SLM **não entra** no juízo final nem na síntese multi-fonte — a doutrina proíbe degradar veredito, e
nada na rodada sustenta que um modelo pequeno julgue igual. **Entra**, se entrar, em
classificação/extração/roteamento **de lote assíncrono**, e mesmo aí a conta de CPU desta VPS não
fecha hoje.

**O que fica como está:** o gate, o radar, a bancada, e o tiering por fase — que esta rodada acabou
de confirmar como o padrão de melhor retorno, por caminho independente.
