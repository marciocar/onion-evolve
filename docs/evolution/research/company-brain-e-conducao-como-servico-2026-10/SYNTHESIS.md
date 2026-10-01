---
title: Company Brain como serviço e Condução como serviço — a unidade bilhetável das duas candidatas
date: 2026-10-01
kg: docs/evolution/research/company-brain-e-conducao-como-servico-2026-10/company-brain-e-conducao-como-servico-2026-10.kg.yaml
run_id: wf_192911fe-13d
tokens: 9987160
agents: 148
duration_min: 97
review_after: 2026-10-31
type: research
mode: decision

> **Projeção do grafo, nunca fonte.** Toda afirmação aqui tem nó correspondente no `.kg.yaml`
> declarado no frontmatter. A decisão `D_COMPANY_BRAIN_OU_CONDUCAO_COMO_SERVICO` está **`open`** —
> esta sessão não sela.

## Resposta primeiro

**Nenhuma das duas candidatas chega selável sobre este corpus**, e a razão não é falta de achado: é
que as duas pernas que decidiriam ruíram sob medição.

- **(b) Company Brain / grafo ancorado** tem a única unidade de cobrança com preço publicado que
  casa com "orquestração ancorada no grafo" — a **Zep cobra por episódio ingerido** (1 crédito até
  350 bytes), deixando grafo, recuperação, threads e usuários a **0 crédito**. Mas a mesma unidade
  derruba a candidata pela aritmética: o corpus **inteiro** de grafos do core (114 arquivos
  `.kg.yaml`, 3.830.401 bytes, medidos hoje) dá **10.944 créditos** contra os **10.000 do plano
  FREE** — ao único preço publicado de grafo-como-serviço, o ativo completo da casa vale ≈ **US$0
  por mês**. E a curva é **invertida**: o mercado dá de graça o que o Onion faz bem (consultar,
  versionar, verificar) e cobra o que ele quase não faz (ingestão automática em volume).
- **(d) Condução / adoção** tem a unidade que a casa sabe medir **sem receptor nenhum** (22 membros
  no `members.yaml`) e é exatamente a unidade que **nenhum fornecedor cobra**: ninguém fatura por
  repo onboarded nem por golden path mantido.

## A correção que inverteu a rodada

A recomendação do Elenxo foi **"(d) é a candidata que o mercado JÁ PROVOU QUE MORRE"**, apoiada em
três casos. Ler os pareceres dos refutadores **depois** do run desarmou os três — e esta é a parte
que a síntese quase perdeu, porque estavam na pilha `refuted`:

| Caso | O que a rodada afirmou | O que o refutador MEDIU na primária |
|---|---|---|
| **Thoughtworks Studios** | divisão de produto criada 2006, fechada 2020 → método-como-produto não escala | a frase está no wikitexto **sem nota de referência**; nenhuma primária datada corrobora "2020"; a tese causal é inferência do pesquisador, não da fonte |
| **Pivotal** | formada 2012 por spin-out; método absorvido na suíte Tanzu | **S-1 e Form D da SEC (tier 1)**: incorporada **1º de abril de 2013** como GoPivotal, Inc.; Pivotal Labs era *consulting firm*, e o rename de 2021 é rebranding de **serviços** — a unidade seguiu engajamento/hora |
| **Roadie** | cobra US$24 por dev contribuinte | os dois planos por-dev trazem o selo literal **"Existing subscribers only"** (2× no HTML); a SKU **viva** é *"Enterprise Context — a live graph … Custom / Per organization"*, e está em **waitlist, sem GA e sem preço** |

**Veredito:** o cemitério de método-como-produto **não tem lastro nesta rodada**. "(d) morre" volta a
ser **hipótese**, não achado — e a opção *NENHUMA AGORA* ganha força **por falta de dado**, não por
excesso.

E uma quarta correção inverte o eixo 5: **a Onyx já entrega grafo de conhecimento**. A doc do próprio
fornecedor diz *"advanced RAG, hybrid search, and AI-generated knowledge graphs"*, e o módulo
`backend/onyx/kg` está vivo no código (clustering, extractions, vespa). Logo o diferencial do Onion
**não pode ser "temos grafo"** — se existe, é a **proveniência verificável** (tier de fonte,
`verified_at` datado, radar determinístico sem LLM), e essa continua **sem preço próprio em nenhum
fornecedor medido**.

## Proveniência: lacuna ou sinal de que ninguém paga?

Medido: o **Guru** anuncia citações permission-aware, lineage e fluxos de verificação — e **empacota
no plano sob consulta, sem preço próprio**. A objeção sobrevivente do Elenxo lê isso para o lado
desconfortável, e está registrada no grafo: *ausência numa página de preço é ausência de **saliência
comercial***, e se proveniência vendesse sozinha, estaria lá. Isso é evidência **contra** a tese de
que proveniência é diferencial pago — não prova de lacuna a explorar.

## Mercado e capital (eixo 7) — assimétrico e fraco

- **Receita:** Glean acima de **US$300M de ARR** em 2026-05 (tier 5, votos 2-1), triplicando US$100M
  em 15 meses — com a própria fonte qualificando ARR como métrica sem definição contábil padrão.
- **Preço como sinal de categoria:** publicam Dust (seat + crédito, 24–150€), Onyx (US$20/seat
  anual), Port (**seat + cotas de entidade** 10K/50K/250K/1M+ e de runs), Humanitec (mensalidade por
  tier com usuários inclusos), Zep (crédito por episódio). **Glean e Guru não publicam** — o topo da
  categoria é enterprise sob consulta, sinal de venda com toque humano.
- **Analistas:** Thoughtworks Radar Vol 34 (2026-04) traz **Context Graph em ASSESS**, distinguido de
  GraphRAG pela **validade temporal por aresta** — o reconhecimento mais próximo do ativo do Onion, e
  explicitamente **sem lado comercial**.
- **M&A:** um único caso, e **histórico** (VMware/Pivotal, fechado 2019-12-30). **Zero** rodada de
  capital de 2026, zero valuation, zero M&A de 2026 sobreviveu aos votos.

## NÃO-VERIFICADOS (declarado, não escondido)

- **`unverified`: 0** — nenhuma claim caiu por 403 ou truncagem.
- **`notVerifiedByBudget`: 67 claims** nunca chegaram ao repasse adversarial (de 103 levantadas, 36
  verificadas). O teto de `maxVerify` mordeu em ~65% do levantamento.
- **`budgetDropped`: 7 URLs**, e duas delas doem: **`glean.com/pricing`** e **`cortex.io/pricing`** —
  as páginas de preço de dois nomes centrais dos eixos 1 e 2 foram buscadas e **descartadas por
  orçamento**.
- **Eixo 1 sem o lado SUÍTE:** Atlassian Rovo, Microsoft Copilot sobre o Graph, Notion AI, Writer,
  Sana, Hebbia, Credal e Gradial **nunca foram abertos** — e é exatamente onde a categoria morre
  absorvida.
- **Eixo 6 (ICP, quem assina o cheque, ciclo de venda, caso público com número): ZERO evidência.**
- **Um achado medido no instrumento errado:** ausência de "company brain" no CHANGELOG do Claude Code
  passou 3-0. O changelog de uma CLI nunca conteria uma categoria de mercado — informação zero,
  inflando a aparência de cobertura. Classe já nomeada na casa: `testar-no-caminho-errado-e-nao-testar`.

## valeu-a-pena

| Medida | Esta rodada | Histórico |
|---|---|---|
| tokens | 9.987.160 | — |
| nós no grafo | 47 | — |
| **tokens / nó** | **≈ 212.500** | 68k (2026-08-30) · 74k (2026-09-01) |
| agentes | 148 | — |
| duração | 97 min | — |

**Regressão de custo/nó de ≈ 2,9×, e é achado, não rodapé.** A rodada gastou 10M de tokens para
produzir 36 claims verificadas e **nenhuma decisão selável** — com os dois eixos que decidiriam
(suíte e ICP) intocados e as duas páginas de preço mais relevantes descartadas por orçamento. O
`price_per_node` para a próxima invocação de `/meta:census` **não** deve herdar este número: ele é de
rodada `mode: decision` com 5 ângulos de tema + 5 eixos fixos e votação 3/2, que é o teto de custo da
casa, não a média.

## O que fica aberto (o maestro sela)

`D_COMPANY_BRAIN_OU_CONDUCAO_COMO_SERVICO` — 4 opções nomeadas: **(b)**, **(d)**, **(b+d) no formato
Guru** (conhecimento verificado com condução humana embutida, preço fechado por contrato — a única
forma com precedente de mercado que dissolve o teto de assento e o piso de byte de uma vez), e
**NENHUMA AGORA**. As **6 perguntas de selagem** estão no label do nó; a 6ª exige, se for *NENHUMA
AGORA*, **gatilho, data e orçamento nomeados** — sem isso é adiamento com outro nome.

**Flip nomeado neste checkpoint (§4.1):** `E_ROADIE_POR_DEV_CONTRIBUINTE` → `superseded` por
`E_ROADIE_POR_DEV_ESTA_FECHADO_1001`. Nó nascido e derrubado na mesma rodada, ainda não commitada;
predicado `kg-seal-exception.sh` saiu **AUTO**.
