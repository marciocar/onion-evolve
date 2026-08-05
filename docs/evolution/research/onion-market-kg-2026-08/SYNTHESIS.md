---
title: "KG-SSOT First e Runtime × mercado — o Onion dentro da categoria que a YC nomeou (Elenxo de dois eixos)"
category: research
date: 2026-08-02
status: veredito-ratificado-por-evidencia-externa-e-refinado
method: "Elenxo imersivo de dois eixos, 38 workers em 4 workflows. W1: 5 lentes internas adversariais com mandato de PROCURAR CERIMÔNIA (sonnet/medium) + 8 pistas externas (sonnet/medium) + pareamento (opus/high). Pista dedicada dev+problema (6 workers). Varredura corretiva por TRAJETÓRIA (7 workers, rodada 2× por acidente — virou medição do método). W2: 4 lentes de correlação com régua de Aristóteles → 3 re-litígios com replay + ataque adversarial em pipeline (opus/high) → síntese (opus/high)."
run_id: "wf_0b0267b9-362 + wf_a489acb8-067 + wf_7725217c-e1c + wf_9f6d7daf-8f7 + wf_eb01875e-962"
kg: docs/evolution/research/onion-market-kg-2026-08/onion-market-kg-2026-08.kg.yaml
verified_at: 2026-08-02
source: "https://www.ycombinator.com/rfs · https://github.com/Graphify-Labs/graphify · https://code.claude.com/docs/en/hooks · arXiv:2603.02473 · arXiv:2601.03236 · medição direta no HEAD"
---

# O Onion dentro da categoria que o mercado nomeou

> **Projeção do grafo.** SSOT: [`onion-market-kg-2026-08.kg.yaml`](./onion-market-kg-2026-08.kg.yaml) (radar exit 0).

## ⚖️ Veredito

**`D_build_none_of_three` fica RATIFICADO — agora por evidência externa, não por introspecção — e REFINADO.**

| Substância re-litigada | Placar | Aceite era |
|---|:--:|:--:|
| **D** — `.claude/rules/` path-scoped | **1/7** | ≥5/7 |
| **E** — hook `prompt`/`agent` roda o radar e injeta o veredito | **3/7** | ≥5/7 |
| **F** — cura de resíduo (id de nó em artefato durável) | **1/7** | ≥5/7 |

**O refinamento importa:** a substância **E** fez **3× melhor que a cura B** (1/9). A distinção *"roda e
injeta o resultado" ≠ "injeta prosa pedindo que o modelo rode"* **era real e é mensurável**.

E veio um fato externo que **nenhuma introspecção acharia**:

> Hooks `type: "prompt"` e `type: "agent"` **não retornam `additionalContext`** — são decisores sim/não,
> não injetores. Teto de **10.000 chars** por saída de hook; a forma completa mede **138.433 bytes**
> (13,8× acima), e a única versão que cabe (só ids, 8.092 b) **é literalmente a condição de C4–C6**.
> **A forma que chegou a 3/7 não é construtível como descrita.** ([hooks](https://code.claude.com/docs/en/hooks))

## 🔎 O que decide (o eixo)

> **O laço `read(KG)` está protegido por TEXTO; o laço `write(KG)` está protegido por SCRIPT.**

`write`: 6 gates HARD no CI, resultado medível (103/103 docs cobertos, 50/50 grafos íntegros).
`read`: **zero gates** — prosa nos 3 comandos cabeados, e nada mede se foi lido.

E a consequência comportamental, medida: **o KG é arquivo de auditoria, não motor de trabalho.**

- O modo `map` (F0→F4, o **único** caminho especificado para popular a camada `domain`) **nunca rodou
  dentro do onion-evolve** — seu único dogfood produziu grafo no repo de um **adotante**.
- **29 dos 30 grafos do core nascem no mesmo commit** do doc de análise que sintetizam.
- `engineer/start.md` e `engineer/plan.md` — onde a feature **nasce** — têm **zero** menções a KG.
- Fluxo de problema: `existe-só-como-spec`. O estado de um bug aberto vive em **prosa no diário**.
- **Prova reflexiva:** a própria pesquisa sobre *por que o KG não é consultado* modelou seus 9 casos
  como **tabela em prosa** e manteve o grafo **100% audit**.

## 🧱 A conta que o campo maduro já pagou

> **O CMDB fracassou por mais de 30 anos precisamente porque dependia de humanos preencherem um
> repositório PARALELO ao trabalho real.** A correção foi **automatizar** identificação e
> reconciliação — não disciplinar gente. A Forrester já declarou *"CMDB is dead"*.

Nossa camada `domain` tem o **mesmo sintoma**: mantida à mão, paralela ao trabalho, **6/6 instâncias com
1 único commit**, 81% dos nós `open` sem data. E o **CodeSee** morreu em 2024 por ser *visualização sem
ação* — o mesmo diagnóstico que a lente interna deu ao `kg-console.sh` (31 KB, **0 call-sites reais**).

## 📊 Matriz — nós × mercado (régua de Aristóteles)

| O que temos | Mercado | Veredito |
|---|---|---|
| `.kg.yaml` escrito à mão, modela **decisão/proveniência** | 5 players de KG-de-codebase **derivam** o grafo do código; modelam **estrutura** | **categoria diferente** — e o nosso lado não tem ocupante. Mas é **MOAT não-realizado**: ninguém lê o que escrevemos |
| `confidence` (float subjetivo) + `trace` opcional | Graphify: **cada aresta** com tag `EXTRACTED` vs `INFERRED`, mecanizada na construção | **transfere** — e é o **barato**: derivável do `trace:` que já existe, **sem tocar o schema** |
| Camada `domain` mantida à mão | CMDB, 30 anos de fracasso documentado | **cegueira nossa** — temos a cura na prateleira (`kg-freshness`) e nunca a apontamos para o nosso sintoma |
| 6 gates HARD na **escrita** | Papers: *retrieval domina (20 pts); escrita varia 3–8* | **desenha** (ver armadilha) |
| Teste do Eixo + Teste do Gatilho | Rule of Three, "The Wrong Abstraction" — o **pedaço**, não o empacotamento | **diferencial de formalização**, não moat técnico — citar com proveniência |

## ⚠️ A armadilha, resolvida em duas partes

Os papers ([arXiv:2603.02473](https://arxiv.org/abs/2603.02473), [MAGMA](https://arxiv.org/abs/2601.03236))
medem **QA conversacional**. Nosso KG serve **auditoria de decisão**. Aplicando Aristóteles com rigor:

- **A TAREFA é diferente → o NÚMERO não transfere.** *"Retrieval domina, escrita varia 3–8"* **não**
  autoriza concluir *"investimos no lado de retorno baixo"*. LoCoMo não pontua auditabilidade por
  terceiro, que é o bem que nosso gate de escrita produz. **Rejeitado.**
- **O MECANISMO CAUSAL é indiferente à tarefa → o PADRÃO transfere.** MAGMA (grafo + **política de
  travessia**) tem o maior score; GraphRAG-Bench mostra **grafo cru pior que RAG vanilla**. O padrão:
  *grafo rende ganho só quando (a) amarrado a tarefa que texto plano não resolve e (b) com camada de
  política decidindo o que navegar.* **A peça faltante é POLÍTICA sobre o grafo** — não mais gates de
  escrita, não mais prosa.

E a armadilha de palavra: **copiar *"o sistema decide"* sem a arquitetura**. Graphiti funciona porque é
**infraestrutura fora da sessão, retrieval determinístico, zero LLM**. Um hook que injeta texto continua
dependendo do julgamento da sessão — que é o desenho do Letta, medido em 1/9.

## 🥊 A objeção de mercado vence — em 2 dos 3 eixos

[`mattpocock/skills`](https://github.com/mattpocock/skills) (**199.551 ★**) critica frameworks *"que
tomam conta do processo"* (cita GSD, BMAD, Spec-Kit). O `CLAUDE.md:12` declara os workflows faseados
**"invariantes do framework, não devem ser consolidados"** — o oposto literal. Não há disanalogia que nos
separe de GSD/BMAD.

**Onde não vence:** compliance como dimensão peer — lá o acoplamento **é** o produto.

**O agravante — ⚠️ CORRIGIDO em 2026-08-02, algumas horas depois:** este parágrafo afirmava que
*"a doutrina diz indivisível enquanto o `plugins/` divide"*. **É falso.** O `CLAUDE.md:12` diz que os
workflows *"não devem ser **CONSOLIDADOS**"* — ou seja, **não devem ser fundidos um no outro**. Ler
*"consolidados"* como *"divididos"* inverte o sentido: manter `product/` e `engineer/` como fluxos
distintos é **compatível** com enviá-los como verticais separadas.

**A objeção segue de pé; o agravante cai.** E o que sobrevive é positivo, não defensivo: o `plugins/`
tem **7 verticais instaláveis**, e já houve **teste de instalação e uso de skills em separado** — o
consumo em fatias é **estratégia de distribuição já exercitada**, não concessão a uma crítica.
SSOT da correção: nó `E_leitura_errada_consolidados` (aresta `REFUTES`).

> Causa do erro: afirmei contradição **sem reler a frase**. É a mesma família `declarado ≠ verificado`
> que esta pesquisa investiga — desta vez **dentro da própria pesquisa**.

## 🏢 O "Company Brain" da YC — e o que ele **não** significa

Categoria oficial do [RFS Summer 2026](https://www.ycombinator.com/rfs), escrita por **Tom Blomfield**
(GP, fundador do Monzo e GoCardless): *"we need a new primitive: a company brain"* — sistema que **puxa**
conhecimento fragmentado, **estrutura**, **mantém atual**, e converte num **executable skills file**.

**Vira checklist de 3 verbos, e falhamos no do meio:** estrutura ✅ · converte ✅ parcial ·
**mantém atual ❌** (`kg-freshness` com 0 runs, 81% dos nós sem data).

> **O verbo em que falhamos é exatamente o que separa "company brain" de "wiki".**

**O que NÃO muda:** um RFS é **lista de desejos de investidor**, não prova de demanda paga. **Zero pull
datado** de adotante pedindo isso. Reivindicar a categoria hoje é reivindicar a **ambição** — e
`behavior-over-declaration` proíbe precisamente isso.

## 🗣️ Contra-argumento honesto (dissent que quase inverte)

> **O corpus de 9 casos é ele mesmo um CMDB**: hand-curado, feito de falhas que **alguém lembrou e
> registrou**. As falhas não notadas — o denominador real — nunca entraram no ringue.

E o placar 3/7 pende de **uma única inferência não medida**. Se falsa, sobe a **6/7 e passa**. Logo:

> **A formulação correta é "não construir por falta de evidência a favor" — nunca "está provado que não
> funciona".** A primeira mantém o gate honesto; a segunda o transforma em decreto.

**E a observação sem resposta:** o único disparo que **comprovadamente** funcionou (C7) foi **social** —
um humano perguntando *"você está fazendo SSOT-first?"*. Nesta sessão isso se repetiu **duas vezes**
(*"o KG-SSOT entrou na pesquisa?"* e *"tem ferramenta de KG com 'yy' no final?"*) — e as duas perguntas
**corrigiram a pesquisa**. Cinco instrumentos reprovados depois, o gate social segue imbatido.

## 🧭 Confiança e gaps

**Sustentam a decisão (`confirmed`, dois lados ancorados):** a tese texto-vs-script · as 13 peças de
cerimônia com número · a categoria de KG-de-codebase (autenticidade verificada por ★/fork 7–17) · a
desqualificação do mecanismo pela plataforma · a objeção do mattpocock.

**Ficou `open` (não sustenta decisão):** `D_extracted_inferred_transfere` (desenho, não construído) ·
`D_consumivel_em_fatias` (decisão de doutrina, do maestro) · o dissent.

**Não foi possível verificar:** se as falhas de leitura **não notadas** mudam o placar — é
estruturalmente inauditável sem instrumentação de sessão, que só agora foi consertada.

**Aposentado por falta de fonte:** a alegação *">40% de redução de alucinação"* do GraphRAG — sem fonte
primária. O número real é *"+40% de correção de resposta"* em método ontology-grounded (OG-RAG, EMNLP
2025), que é outra coisa. **Nunca entrou no repo** — o registro aqui é para não entrar.

## 🔬 Lição de método, medida por acidente

Dois runs **idênticos** de uma varredura de descoberta (mesmo script, prompt, modelo, effort) acharam
**46 e 41** achados, união de **74** — cada um cobriu só **55–62%**. E foi na **borda**, não no núcleo,
que apareceram os dois achados decisivos: o **Company Brain da YC** e o **microsoft/agent-governance-toolkit**.

> **Descoberta em espaço de tamanho desconhecido exige N passadas com união (ou `loop-until-dry`).
> Julgamento converge e não precisa.**

Agravante: `loop-until-dry` **já é um dos 6 padrões canônicos** da skill `onion-orchestration` — e não
foi usado. Mesma classe de falha que a pesquisa investiga: doutrina que existe e não é aplicada.

E o viés que a originou: **buscar por nome conhecido só acha incumbente**. As 8 pistas perderam o
[Graphify](https://github.com/Graphify-Labs/graphify) — **100.765 ★ em 120 dias, skill para Claude Code**,
o nosso substrato exato. Quem o achou foi o maestro, de memória.

---

# Adendo W2 (2026-08-05) — os dois eixos, e as cinco posições que caíram

> **Projeção da leva W2** do grafo irmão (`wf_b516b6a2-b84`, 15 workers). O W1 correlacionou e
> ratificou; o W2 pôs **cinco propostas concretas em steelman** e atacou cada uma com lente própria.

## O placar

```
correlação ..... 44 itens    18 desenha · 14 não-transfere · 12 transfere
posições ....... 5 propostas → 5 REFUTADAS, todas por MEDIÇÃO
```

**Os 12 que transferem** (o que importa, não o placar): MAGMA — *grafo só vale com política de
travessia* · **CMDB** — *a camada `domain` tem o mesmo modo de falha* · **Graphify** — *proveniência
mecanizada por **aresta***, enquanto o Onion tipa só o **nó** · **EU AI Act** — rastro auditável
exigível desde 2026-08-02 · **Graphiti** — retrieval determinístico do lado do sistema ·
**ICLR-gargalo** — *retrieval domina 20 pontos; escrita/estrutura, 3-8*.

## A tese-mãe foi refutada na junta — e o erro era do proponente

Ela sobrevive só como **duas afirmações verdadeiras que não compõem**. O `logo` quebra em quatro
pontos medidos, e o segundo é aritmético:

> `claim + decision + question` = **1.437 / 2.049 = 70,1%**, não os ~90% alegados. Só chega a 89,2%
> contando os **390 `evidence`** — e `evidence` é justamente o que **pode** ser parcialmente derivado.
> **O erro estava do lado que sustentava a tese.**

E o ganho declarado não existe: 8% de 2.049 = **167 nós, escritos uma vez cada**. O gargalo medido é
**leitura**, não escrita. Por fim, *"julgamento é o que o Graphify não tem"* é verdade de **forma** e
falsa de **motor**: dos **221** alvos de `SUPERSEDES`/`REFUTES`, só **11 (5,0%)** têm `trace:`
resolvível para superfície executável.

> *"Por que ela seduz: porque faz técnico e estratégico coincidirem. Mas o único jeito de fazê-los
> coincidir foi escolher, nos dois eixos, o trabalho **confortável porque o volume é zero**."*

## Eixo técnico — **não derivar nada de novo; zero gate novo**

A fronteira correta **não é** *derivável × não-derivável*. É **já legível no dado × pede campo novo**:
`node_type` + presença de `trace:` já classificam; campo novo custa **gramática a todo adotante**.

O que entra é **reparo, não mecanismo**: os 8 números errados de `docs/technical-context/`, à mão, um
commit. E vem com o refinamento que vale mais que o conserto:

> **Taxa de defeito medida: 8 números em meses. Custo do gate > custo do conserto ⇒ mecanizar É a
> catedral.** `fix-must-become-mechanism` **não** é *"todo fix vira gate"* — é *"todo fix vira
> mecanismo **quando o volume justifica**"*. Sem o portão 4, a doutrina anti-catedral fabrica catedral.

## Eixo estratégico

**E1 — plataforma única: CONFIRMADA**, e a "correção" proposta foi refutada por evidência que estava no
repo **desde junho**: smoke-test **PASS 6/6** em 2026-06-15 (`TeamCreate` → spawn → `SendMessage`).
*"`0 hits` de uso não é vaporware — é a assinatura de uma decisão registrada funcionando."*
`C_POSTURA_ACOPLAMENTO` e `C_CORE_NAO_E_FAMILIA` ficam **intocados**.

**E2 — a porta: HIPÓTESE.** Contra-experimento **N=6 na própria família**, medido ao vivo: `onion` 0★
(com description+MIT), `onion-cursor` 0★, `onion-antigravity` 0★ **mesmo com +3 topics**… A teoria
*"publique e melhore o metadado"* **já rodou em casa e deu zero**. O ausente é **rota de chegada**.

**E3 — o moat: a substância se sustenta, a palavra não.** *Moat* é termo de defensabilidade
competitiva — exatamente o que `C_NS1_KG` declara **não provado**.

## Dissent (preservado — é a objeção mais forte da rodada)

> *"Isto é indistinguível de **paralisia vestida de rigor**. Um método que refuta 5/5 das próprias
> posições pode estar medindo bem — ou estar calibrado para nunca aprovar."*
>
> *"O replay 'grátis' que recomendo é ele mesmo **infalseável**: se declaro que dá 0/9 por construção
> antes de rodar, rodar não é medição, é cerimônia."*
>
> *"A **assimetria de rigor** é real e não é acidente: força máxima contra propostas **baratas**, força
> zero contra re-perguntar o caro."*

## Correção de estado (deriva de 42 commits em 3 dias)

`.claude/rules/` **existe** — `kg-grammar.md`, path-scoped em `paths: ["**/*.kg.yaml"]`. A afirmação
*"não existe"* de 08-02 está **stale**. E são **9** hooks, não 7 — todos `type=command`, o que o W2
julgou **escolha certa**: `command` é o único tipo com exit-code + injeção garantida.
