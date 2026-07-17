# Semente — O KG das peças (lego) como substrato generativo: entender → projetar → compor → auto-evoluir

> **Status: SEMENTE (2026-07-17)** — visão do maestro registrada, fios conectados, gatilhos nomeados.
> **NÃO construída.** É norte citável, não backlog de execução. Plantada a partir da sugestão do maestro
> (2026-07-17), no mesmo dia do ADR [SDAAL-aninhado](onion-adr-sdaal-nested-two-level-2026-07.md) — que é
> o **1º tijolo** dela (a 1ª peça formalmente modelada como composição).
>
> **Princípio-guia (canônico do maestro):** *"LLM como VM; MD/KG/grafos/scripts como bytecode"* — o poder do
> Transformer com a lente do Onion, mapeando e deixando migalhas para guiar **em tempo de execução**.

## A visão (verbatim destilado)

Mapear **cada peça do lego** — funcionalidade, técnica, metodologia — e **como se encaixam**, tudo em KGs que
sirvam para: (1) **entendê-las**; (2) **projetar** evoluções, novos relacionamentos, novas peças, conexões;
(3) dado um **problema**, **projetar soluções com as peças que tem** (as partes montadas, as partes "comuns");
(4) **aprender e criar padrões** de uso e de criação; (5) rodar como **PLEA** (Planejar-Executar-Avaliar) **com
um PLEA como intrafases de cada fase** — fractal, adaptando-se e **autorregulando o próprio processo de
adaptação**; (6) montadas para **uso em tempo de execução, autocorrigindo-se para evoluir**; (7) com as
**diferentes camadas de teste e promoção** dessas peças. *Sem filosofia* — concreto e executável.

## O alerta honesto (a lente Onion, não omitida)

*"Um sistema que, dado um problema, projeta soluções, aprende, se autocorrige e evolui"* é **a assinatura exata
da catedral que o Onion abandonou** — as FASES 5-9 do v4.0 (*"aprendizado contínuo"*), riscadas em 2026-05-18
por serem construídas à frente do gatilho ([modernization-doctrine](../knowledge-base/concepts/onion-modernization-doctrine.md)
§`gated-until-trigger`; proibição em `architecture.md`). Esta semente **existe para não repetir esse erro**: a
visão é destilada em **peças com gatilho**, não construída como todo. A diferença entre catedral e evolução é
uma só — construir a peça que **um uso pediu**, não o sistema que a simetria pede.

## O que JÁ existe (não reinventar)

| Peça da visão | O que já existe | Onde |
|---|---|---|
| Grafo das peças | `/meta:graph` gera a **lente sócio-técnica** da spec-as-code (actors + capabilities; impacto reverso, órfãos, caminho necessidade→capacidade) — mas **DESCRITIVO** | `.claude/validation/graph.sh` · `docs/onion/graph.md` |
| PLEA fractal | Já mapeado sobre o loop (Planificação=radar-KG · Execução=atuadores-dogfood · Avaliação=juiz/re-teste); deep-research rodada (11 achados); **fricção de campo real** | [seed SRL-PLEA](onion-research-seed-srl-plea-2026-07.md) · [fricções F1](../evolution/inbox/_processed/2026-07-05-friccoes-f1-doutrina-plea.md) |
| Usar em runtime + autocorrigir | `read(KG)→verify→act→write` (SSOT-as-runtime), cabeado em catch-up/warm-up/work | [knowledge-graph-sdaal](../knowledge-base/concepts/knowledge-graph-sdaal.md) §SSOT-as-runtime |
| Dado problema → compor com peças | `@onion` recomenda comandos/agentes; `/meta:graph` acha caminho necessidade→capacidade | `.claude/skills/onion/` |
| Contradição/reconciliação | KG-SDAAL (`SUPERSEDES`/`REFUTES`, `confidence`/`status`) | knowledge-graph-sdaal |
| Camadas de teste/promoção | assess→trial→adopt · gate mecânico vs de uso · gated-until-trigger · dogfood | [toolbox-lifecycle](onion-adr-toolbox-lifecycle-2026-06.md) · [dogfooding](../knowledge-base/concepts/onion-dogfooding-doctrine.md) |

## A lacuna real (o que a sugestão adiciona ao que existe)

- **L1 — O grafo é DESCRITIVO, não GENERATIVO.** Hoje responde *"o que existe / o que é impactado / o que é
  órfão"*. A visão quer *"dado um problema, **compõe** a solução com as peças"*. Isso é **generativo** —
  território **emergente** (a pesquisa de mensageria já tocou: *spec-driven composition*, *Tool RAG*). Exige
  **research-first**, não desenho de priori.
- **L2 — O KG das PEÇAS não existe.** Nenhum `.kg.yaml` modela o framework como peças componíveis (o ADR
  #402 acabou de nomear que nem o SDAAL-abstração está em KG). É o 1º tijolo, e ele já tem gatilho.
- **L3 — As camadas de teste/promoção estavam dispersas.** ✅ **RESOLVIDO (2026-07-17)** —
  [onion-promotion-ladder](../knowledge-base/concepts/onion-promotion-ladder.md) consolidou a esteira.
  *Correção de premissa (declarado≠verificado):* o `radar.md` **não** era citação-fantasma do core — é o
  radar de apetite do **adotante** (metagamify); a régua `assess→trial→adopt` **já vivia** no
  toolbox-lifecycle §Dec.4. O que faltava eram as **camadas de experimentação** (PoC/spike/stub/simulação/
  quarentena/candidato/MVP), agora nomeadas numa esteira. Foi o gatilho mais próximo — e disparou.
- **L4 — PLEA como MECANISMO, não lente.** A **Q5 do seed SRL-PLEA ficou ABERTA**: *"como as fases PLEA se
  materializam em cada classe de bytecode (MD/KG/grafo/script)"*. É o "PLEA fractal auto-regulado" da visão,
  ainda não aterrissado num ciclo executável.

## Questões de pesquisa (quando disparar)

- **QA — Composição generativa guiada por grafo:** estado da arte 2026 de "dado um problema, compor solução com
  as peças existentes" (spec-driven composition, tool/skill retrieval, planejadores sobre grafo de capacidades).
  O que é comprovado vs emergente vs hype. Conecta com a pesquisa WhatsApp (Tool RAG, RouteLLM).
- **QB — PLEA como mecanismo de auto-regulação de FERRAMENTAS** (não de aprendiz humano) — fecha a Q5 do seed
  SRL-PLEA: materializar planejar/executar/avaliar sobre a família de bytecodes, com auto-regulação da adaptação.
- **QC — A esteira aplicada às PEÇAS:** ✅ a esteira geral já foi consolidada
  ([onion-promotion-ladder](../knowledge-base/concepts/onion-promotion-ladder.md), 2026-07-17). O que resta
  como pesquisa é **aplicá-la ao KG das peças** — cada peça (SDAAL, comando, skill) carregando sua camada/grau
  de certeza no grafo, para o radar dizer "esta peça é spike, aquela é canon". Cruza com dogfood e gated-until-trigger.

## Gatilhos nomeados (cada peça gradua quando…)

| Peça | Gatilho | Nota |
|---|---|---|
| **KG das peças** | dogfoodar `/meta:kg` sobre um subconjunto real (os SDAALs — o ADR #402 é o 1º) e provar que o grafo revela o que a prosa escondia | o mais perto de disparar |
| **Esteira de promoção (SSOT)** | a dor da `radar.md` fantasma já existe — gatilho **ativo**; forma mínima = destilar a régua num KB/ADR, não um sistema | candidato mais maduro |
| **Composição generativa** | um caso real onde "dado um problema, compor com as peças" seria usado e falta | research-first antes |
| **PLEA-mecanismo** | o maestro pedir a rodada dedicada da Q5 (o seed SRL-PLEA já a nomeia) | herda o gatilho do seed |

## Método (quando disparar)

Deep-research orquestrada (verificação adversarial, tiering model/effort por fase) → achados citados → **claims
no KG** (não prosa) → candidatos a ADR/KB. Mesmo ciclo que levou breadcrumbs→`conflict_class` e o `/meta:kg`.
**Cada peça é gated e dogfood-first** — a visão nunca é construída como todo.

## Relação

Fecha a **Q5** de [srl-plea](onion-research-seed-srl-plea-2026-07.md) (bytecodes) e adiciona a metade
**generativa/composicional** que ele não cobria · é o horizonte que o ADR [SDAAL-aninhado](onion-adr-sdaal-nested-two-level-2026-07.md)
aponta (o KG das peças) · evolui o `/meta:graph` de descritivo para generativo · governada pela
[modernization-doctrine](../knowledge-base/concepts/onion-modernization-doctrine.md) (o anti-catedral).
