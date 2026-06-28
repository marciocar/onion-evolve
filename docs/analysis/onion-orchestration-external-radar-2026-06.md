---
title: "Orquestração de subagentes — radar de sinais externos (Ringelmann + estado-da-arte multi-agente, jun/2026)"
date: 2026-06-21
type: analysis
status: proposed / living          # radar revisável — NÃO é execução, NÃO é spec congelada, NÃO é verdade absoluta
authority: mapeamento + comparação honesta; sem decisão executável (insumo p/ /meta:evolve)
research: conversa externa com Claude (share 332f6246, trazida pelo maestro 2026-06-21) — autor SEM acesso a esta base
last-review: 2026-06-21
next-review-trigger: "rodar no próximo /meta:evolve · OU se a orquestração plana atingir teto real de fan-in/contexto · OU se o Onion graduar p/ federação formal (A2A)"
relates:
  - ../knowledge-base/concepts/agent-orchestration.md
  - ./onion-distribution-strategy-2026-06.md
  - ./onion-review-2026-05.md
  - ../evolution/inbox/_processed/2026-06-20-heyclicky-model-routing-signal.md
---

# Orquestração de subagentes — radar de sinais externos (jun/2026)

> **Natureza deste doc:** artefato **vivo**, não veredito fechado. Captura ideias trazidas de fora,
> compara com o que o Onion já é, e classifica cada uma — **sem verdade absoluta**. O que hoje é
> 🔴/🟡 pode virar 🟢 noutro estágio: cada item carrega o **gatilho** que o reativa. Para retroagir,
> editar o §7 com data + porquê.

## 1. Contexto e proveniência (com ressalvas de honestidade)

O maestro trouxe uma conversa com outro Claude sobre **eficiência/eficácia em orquestração de
agentes** (Efeito Ringelmann → dimensionamento da orquestração → estado-da-arte multi-agente jun/2026 →
proposta de "persona orquestradora" + matemática de dimensionamento de árvore).

**Ressalvas que condicionam toda a leitura abaixo (ler primeiro):**

1. **O autor externo NÃO conhecia o Onion real.** Trabalhou de conhecimento geral + a skill pública,
   chegou a nomear o projeto como "Arandek" e **propôs construir uma "persona orquestradora" que já
   existe** canônica nesta base (a skill `onion-orchestration` + `/meta:orchestrate` + a KB de orquestração). Logo, a maior
   parte das "propostas" é **re-derivação independente** do que o Onion já especifica — o que vale
   como **validação externa**, não como trabalho novo. É o mesmo padrão do sinal HeyClicky
   ([_processed](../evolution/inbox/_processed/2026-06-20-heyclicky-model-routing-signal.md)).
2. **A matemática (atualizado 2026-06-21: VERIFICADA).** O **Efeito Ringelmann** (Max Ringelmann, 1913)
   é real e bem documentado. O paper citado — *"Phase Transition for Budgeted Multi-Agent Synergy"* —
   **foi verificado**: arXiv:2601.17311 (Liu, Kong, Pei, jan/2026); fórmulas conferidas e aprofundadas
   na [nota dedicada](./onion-orchestration-math-phase-transition-2026-06.md). Ressalva que permanece: a teoria
   é **escopada a tarefa binária + voto por maioria** (modela o judge-panel, não o fan-out geral), e
   `β, γ, ρ` são parâmetros empíricos não medidos no Onion → lente qualitativa, não calculadora.
3. **Métricas de mercado são direcionais.** "15× tokens", "29–39% de ganho de context engineering",
   "A2A em 150+ orgs", "ADK 1.0 GA", composição da AAIF — plausíveis e úteis como direção, mas
   **não verificados**; tratar como contexto, não como fato fechado.

## 2. Material-fonte capturado (as ideias, com atribuição)

Preservado aqui para o doc ser auto-contido (o link de share expira). Ideias centrais da conversa:

- **(R) Ringelmann/Social Loafing** como modelo mental: a força marginal por pessoa cai com o tamanho
  do grupo; análogo → existe um **nº ótimo de agentes por tarefa, não o máximo**. Atenua quando as
  subtarefas têm baixa interdependência (paralelizáveis).
- **(G0) Gate de acoplamento**: só orquestre se a tarefa decompõe em threads **independentes**;
  tarefa acoplada (código, raciocínio sequencial) → single-agent.
- **(C4) Contrato de subagente em 4 partes**: objetivo + formato de saída + ferramentas/fontes +
  limites de tarefa. Falte um → o subagente "deriva".
- **(ESC) Regras de escala de esforço**: 1 agente p/ fato simples · 2–4 p/ comparação · 5–10 p/
  pesquisa ampla · >10 p/ pesquisa complexa.
- **(TOPO) Topologia hierárquica** (árvore b-ária com compactação por nó) substituindo a orquestração plana:
  estrela satura em `N ≈ W/m`; árvore alcança `N = b^L` ao longo de L níveis.
- **(MATH) Transição de fase**: `α_ρ > 1` = árvore amplifica sinal; `α_ρ < 1` = dilui (colapso).
  `s > β` = scale-out (mais agentes) vence scale-up (agente maior), acima de um orçamento mínimo.
- **(PROTO) Stack de 2 protocolos**: MCP (vertical, agente↔ferramenta) + A2A (horizontal,
  agente↔agente), sob a Linux Foundation.
- **(CTX) Context Engineering** como disciplina de 1ª classe (Write/Select/Compress/Isolate);
  multi-agente é, em si, uma estratégia de **isolamento de contexto**. "Context folding".
- **(OPS) Consenso operacional**: "compre, não construa" (LinkedIn); gestão de estado é o desafio
  primário; inconsistência de contexto (não a escolha de padrão) é a causa nº 1 de falha.
- **(COST) Disciplina de custo**: multiplicador ~15×; maker barato + checker capaz → mesma qualidade
  a 40–60% menos custo.

## 3. O que o Onion JÁ tem (a comparação citada)

| Ideia externa | Estado no Onion | Citação canônica |
|---|---|---|
| G0 — gate de acoplamento | **já canônico** (opt-in, nunca default) | `onion-orchestration/SKILL.md:23-27,125-128` · `meta/orchestrate.md:42-60` · `agent-orchestration.md:56-71` |
| C4 — contrato de subagente | **já existe** (schema + budget + model + escopo) | `meta/orchestrate.md:105-110` · `agent-orchestration.md:237-241` |
| ESC — escala de esforço | **parcial**: tiering + caps + budget, mas **sem tabela classe→nº** | `onion-orchestration/SKILL.md:99-113` · `meta/orchestrate.md:112-118` |
| MODEL tiering | **já obrigatório** (opus orquestra; sonnet/haiku workers) | `onion-orchestration/SKILL.md:99-113` · `agent-orchestration.md:280-300` |
| CTX — isolamento de contexto | **já resolvido** (fan-in → 1 resultado, JS 0-token) | `onion-orchestration/SKILL.md:46-48,134-136` · `agent-orchestration.md:248` |
| Verificação adversarial / judge-panel | **já obrigatório** em alto risco + completeness critic | `onion-orchestration/SKILL.md:43-45,142` · `agent-orchestration.md:254-274,307` |
| Limites duros / circuit breakers | **já existem** (16 concorrentes, 1000 agregados, budget-gated) | `onion-orchestration/SKILL.md:18-19,106,145` |
| TOPO — hierarquia/árvore | **diverge**: orquestração aninhada é **proibida** por design | `onion-orchestration/SKILL.md:129-133` · `agent-orchestration.md:250,466-478` |
| COST — maker/checker tiering | **coberto na prática** (haiku workers + opus juízes) | `meta/orchestrate.md:120-146` |

**Contra-ponto honesto sobre TOPO/MATH:** o paper argumenta hierarquia porque assume que **o
orquestrador-LLM lê as N mensagens** (daí `estrela satura em W/m`). O Onion **já contorna isso por
outro caminho**: o fan-in é **agregação em JavaScript a 0 token** e cada worker devolve resumo
condensado — o contexto do orquestrador **não** é inundado pelas N saídas. Ou seja, a premissa que
torna a árvore "matematicamente necessária" **se aplica menos** ao Onion. A hierarquia vira relevante
só se/quando o gargalo real for outro (ver §4 TOPO).

## 4. Classificação por ideia (sem absoluto — cada uma com gatilho)

### 🟢 Validações (já canônico — sem trabalho novo; valor = confirmação externa)
- **G0, C4, MODEL, CTX, judge-panel, circuit breakers, COST, OPS-"compre-não-construa"** — o Onion
  já faz, e o "compre não construa" o Onion **encarna** ao orquestrar sobre a ferramenta **nativa**
  `Workflow` em vez de um motor próprio. Citar como evidência externa de que a arquitetura está certa.
- **R (Ringelmann como vocabulário/ensino)** — micro-ganho opcional: nomear explicitamente o gate de
  acoplamento como "gate Ringelmann" na KB pode melhorar a didática. Custo ~nulo. *Gatilho:* próxima
  edição da KB de orquestração.

### 🟡 Manter no radar (não agora — talvez noutro estágio; com gatilho de reativação)
- **ESC-tabela (classe→nº de agentes)** — o Onion escala por **dificuldade/budget**, não por contagem
  fixa. Uma tabela-heurística (1 / 2–4 / 5–10 / >10) poderia entrar como *guia* na KB. Risco: contagem
  fixa briga com o princípio "budget como teto". *Gatilho:* se sessões reais mostrarem over/under-scale
  recorrente → avaliar a heurística no `/meta:evolve`.
- **TOPO — topologia hierárquica com sub-orquestradores** — **aprofundado em 2026-06-21** no
  [ADR-rascunho de topologia](./onion-orchestration-topology-adr-draft-2026-06-21.md): a "hierarquia" conflacia
  *locus de orquestração* (invariante — fica no nível principal) com *forma de grafo* (árvore com nós
  sumarizadores — **já permitida** no nível principal). O ADR reafirma a invariante e legitima a árvore
  **sob gatilho**: só quando a síntese exige LLM sobre conjunto que estoura 1 agente (senão o fan-in JS
  0-token vence). *Gatilho:* esse caso real de síntese-por-LLM ocorrer → aplicar o padrão "nó
  sumarizador" do ADR (compactação por nó `b·m ≤ W`).
- **MATH — formalização (α_ρ>1, s>β, mixing depth)** — **paper VERIFICADO** em 2026-06-21
  (arXiv:2601.17311) e aprofundado na [nota dedicada](./onion-orchestration-math-phase-transition-2026-06.md):
  a teoria modela **precisamente o judge-panel** (tarefa binária + voto), não o fan-out geral. Dela saem
  3 lentes (diversidade do panel = requisito de correção via α_ρ · gate `s>β` orquestrar-ou-não · teto
  do panel via mixing depth). Recomendação: **adotar qualitativo já** (explica/justifica o que o Onion
  faz), **calibração quantitativa fica no radar**. *Gatilho:* se quisermos critérios de aceite
  **numéricos** p/ judge-panel ou calibrar `N_max` por modelo.
- **PROTO-A2A (coordenação horizontal IA↔IA)** — **já ADJUDICADO** (aprofundado 2026-06-21, ver
  [nota de reconciliação](./onion-a2a-federation-reconcile-2026-06.md)). SSOT =
  [ADR A2A](./onion-federation-adr-a2a-format-interop-2026-06.md) (aceito 2026-06-15): **runtime A2A =
  linha vermelha** (git-async + maestro, sem IA-fala-IA); **formato A2A** (Agent Card one-way) permitido
  mas **diferido**. O Onion está **à frente** do sinal externo (que tratou A2A como monólito). *Gatilho
  preciso (do ADR):* 1º consumer não-Onion OU interop real nomeada — **não disparou** (só consumidor
  Onion hoje). MCP (vertical) **já é** transporte opcional.
- **CTX-vocabulário (Write/Select/Compress/Isolate) + "context folding"** — o Onion já faz isolamento;
  adotar o vocabulário canônico pode enriquecer a KB de orquestração/contexto. *Gatilho:* refresh da KB.

### 🔴 Descartar (com porquê — fica registrado, não some)
- **"Criar uma persona/spec orquestradora" como artefato novo** (o entregável central do autor externo)
  — **duplicaria** a skill `onion-orchestration` canônica; violaria SSOT + "um escritor". O conteúdo útil dele
  é **minerável** para enriquecer os docs existentes (ver 🟡 ESC/CTX), não para um doc paralelo.
- **Reabrir superfície de produto/multi-IDE/CLI** (não proposto explicitamente, mas é onde "personas
  genéricas" tendem a escorregar) — escopo **formalmente abandonado em 2026-05-18** (ver
  [onion-review](./onion-review-2026-05.md)).

## 5. Cenários abertos (sem resolver à força)

- **Se** o uso real da orquestração crescer em largura (varreduras/migrações com dezenas de alvos) **e** o
  cap de 16 concorrentes / contexto do orquestrador virar gargalo medido → **então** a topologia
  hierárquica (TOPO) + a matemática de dimensionamento (MATH) deixam de ser radar e viram avaliação
  ativa de arquitetura.
- **Se** o Onion graduar para federação formal (coordenação viva cross-repo) → **então** A2A (PROTO)
  reentra como candidato real; até lá, git-async + maestro vence em simplicidade e auditabilidade.
- **Se nada disso ocorrer** → o estado atual (orquestração plana, fan-in JS 0-token, tiering, judge-panel)
  permanece o ótimo, e este radar serve de registro de "avaliamos e não precisávamos".

## 6. Próximo passo

Item de **baixa prioridade**, sem trabalho de implementação agora. Insumo para o `/meta:evolve`
avaliar os 🟡 quando seus gatilhos dispararem. Antes de mover qualquer 🟡 para 🟢, **verificar o paper**
(existência + validade dos resultados) — não construir sobre matemática não confirmada.

## 7. Log / revisibilidade

- **2026-06-21** — Radar criado a partir da conversa externa (share 332f6246). Veredito inicial:
  ~80% validação do que o Onion já é (autor não conhecia a base); deltas reais (TOPO hierárquica, MATH
  do paper, A2A) parqueados no radar com gatilho. Paper não verificado — tratado como hipótese.
  Para retroagir: editar aqui com data + porquê. Liberdade total — é tudo novo.
- **2026-06-21** — Eixo TOPO aprofundado no
  [ADR-rascunho de topologia](./onion-orchestration-topology-adr-draft-2026-06-21.md): desambígua *locus*
  (invariante) × *forma de grafo* (árvore sob gatilho, no nível principal). Item TOPO de §4 atualizado.
- **2026-06-21** — Eixo MATH aprofundado na
  [nota de transição de fase](./onion-orchestration-math-phase-transition-2026-06.md): paper **verificado**
  (arXiv:2601.17311); modela o judge-panel (binário+maioria), não o fan-out geral. Item MATH de §4
  atualizado (não-verificado → verificado+mapeado).
- **2026-06-21** — Eixo A2A aprofundado na
  [nota de reconciliação](./onion-a2a-federation-reconcile-2026-06.md): **já adjudicado** pelo ADR A2A
  (SSOT); Onion à frente do sinal. **Radar percorrido nos 3 eixos** (TOPO/MATH/A2A) — todos tratados,
  nenhum virou adoção cega. Radar segue vivo para quando algum gatilho disparar.

## Fontes

- **Primária:** conversa Claude↔Marcio (share `claude.ai/share/332f6246-35b6-4d26-89e7-e3c5c4a998da`),
  trazida pelo maestro em 2026-06-21. Conteúdo-chave preservado no §2.
- **Conceito estabelecido:** Efeito Ringelmann / Social Loafing (Max Ringelmann, 1913) — verificável.
- **Não verificado (a confirmar antes de adotar):** *"Phase Transition for Budgeted Multi-Agent
  Synergy"* (atribuído a jan/2026); métricas de mercado (15× tokens, 29–39% context-engineering,
  A2A/ADK/AAIF).
- **Canônico interno:** `.claude/skills/onion-orchestration/SKILL.md`, `.claude/commands/meta/orchestrate.md`,
  `docs/knowledge-base/concepts/agent-orchestration.md`.
