---
title: "ADR (RASCUNHO) — Topologia de frota: locus plano (invariante) × forma de grafo (escalável sob gatilho)"
date: 2026-06-21
type: adr-draft
status: accepted
decision-scope: agent-fleet-orchestration / topology
supersedes: none
related:
  - ../meta-specs/architecture.md
  - ../meta-specs/agents.md
  - ../knowledge-base/concepts/agent-fleet-orchestration.md
  - ./onion-fleet-external-radar-2026-06.md
  - ./onion-adr-comms-transport-vs-execution-2026-06.md
---

# ADR (RASCUNHO) — Topologia de frota: locus plano × forma de grafo

| Campo | Valor |
|-------|-------|
| **Decisão** | Separar dois eixos que costumam ser confundidos: o **locus da orquestração** (sempre no nível principal — invariante) e a **forma do grafo de agentes** (plano por padrão, **árvore com nós sumarizadores sob gatilho**). Topologia hierárquica é uma decisão de **forma de grafo composta no nível principal**, **não** a criação de um orquestrador aninhado. |
| **Escopo** | `agent-fleet-orchestration` / topologia / skill `onion-fleet` + `/meta:fleet` |
| **Status** | 🟢 **Aceito** em 2026-06-22 (proposto em 2026-06-21). Parte doutrinária (a desambiguação) é a decisão **vigente**; a documentação do padrão "nó sumarizador" na KB/skill fica **diferida** até um caso real bater o gatilho (ver Gatilho de Implementação). Revisão prevista (acordada com o maestro no aceite). |
| **Origem** | Item 🟡 TOPO do [radar de frota](./onion-fleet-external-radar-2026-06.md) — sinal externo (Ringelmann + paper de transição de fase) trazido pelo maestro. |

---

## Status

🟢 **Aceito (doutrinário) — 2026-06-22** (proposto em 2026-06-21). O ADR **reafirma** a invariante de
locus (`architecture.md §4.2`) e **acrescenta** uma distinção que hoje falta na doutrina. Nenhuma
meta-spec atual governa "frota plana vs. hierárquica" — este é o gap que o ADR fecha. Implementação
(texto novo na KB/skill) diferida até um caso real bater o gatilho. **Revisão prevista** — acordada com
o maestro no aceite (re-examinar a parte doutrinária e a condição de gatilho com mais distância).

---

## Contexto

### O gap
A doutrina de frota ([`agent-fleet-orchestration.md`](../knowledge-base/concepts/agent-fleet-orchestration.md))
e a skill `onion-fleet` cobrem com precisão *quando* orquestrar, contrato de subagente, tiering,
fan-in e verificação adversarial. Mas **nenhuma meta-spec governa a topologia do grafo** (plano vs.
árvore). O texto vigente **silencia sobre a forma do grafo** e só fala de **locus** — a armadilha
"frota dentro de um agente" (`agent-fleet-orchestration.md:461`, `:478`) restringe *onde* a
orquestração mora, não *que forma* o grafo tem. A KB sequer usa as palavras "hierarquia"/"árvore"
nesse sentido. O risco, portanto, é **por omissão**: na ausência de doutrina sobre forma, o leitor
**infere** que "hierarquia é proibida", quando o proibido é coisa mais estreita (o locus). É essa
inferência-por-silêncio que o ADR corrige — não uma frase contraditória no texto.

### A confusão (locus × forma)
Um sinal externo (conversa com Claude que invoca o efeito **Ringelmann** + um paper de transição de
fase: estrela satura em `N≈W/m`, árvore alcança `N=b^L`) propôs "migrar de frota plana para
hierárquica com sub-orquestradores". Ao confrontar com a base, fica claro que a proposta **conflacia
dois eixos distintos**:

1. **Locus da orquestração** — *onde* mora a lógica de fan-out/fan-in/decisão:
   - **No nível principal** (skill/comando) → é a invariante do Onion.
   - **Dentro de um agente** (um agente dispara sua própria frota) → **proibido**.
   - Por quê: (a) **economia de tokens** — a coordenação roda em **JavaScript a 0 token**
     (`agent-fleet-orchestration.md:247-248`); mover para dentro de um agente volta a custar tokens e
     replica contexto × níveis (`onion-fleet/SKILL.md:131` — "mais caro e turvo"). (b) **regra
     arquitetural** — `architecture.md:204` (§4.2): `agents/* → commands/*` = **Não** ("Agente não
     invoca comando diretamente — sugere ao usuário") → **não existe** agente `fleet-orchestrator`.
2. **Forma do grafo de agentes** — o *shape* do fan-out: plano (todos os workers no mesmo nível) vs.
   **árvore** (workers agrupados sob **nós sumarizadores** que condensam antes do fan-in final).

O ponto central: **a invariante restringe o eixo 1, não o eixo 2.** A "forma de árvore" que este ADR
legitima é **uma só**: **(a) `parallel`/`pipeline` aninhados compostos no nível principal** — os
próprios exemplos da ferramenta nativa Workflow fazem `parallel(items.map(() => parallel([...lenses])))`,
um grafo de **dois níveis** orquestrado inteiramente no script principal. **Não** confundir com **(b)
nesting de subagentes** (`agents/* → agents/*`, até 5 níveis desde v2.1.172,
`agent-fleet-orchestration.md:250`): isso é **delegação entre especialistas**, onde o agente delega mas
**não orquestra frota** — a mesma fonte (`:250`) recomenda manter a orquestração no nível principal.
O ADR constrói sobre **(a)**; **(b)** é fato adjacente, não evidência de "árvore permitida". O que
**nunca** pode acontecer é a *orquestração* migrar para dentro de um worker.

### Contra-ponto honesto à matemática do paper
A premissa "estrela satura em `N≈W/m`" assume que **o orquestrador-LLM lê as N mensagens** dos
workers — é isso que enche a janela `W`. **O Onion já contorna essa premissa**: o fan-in é
**agregação em JavaScript a 0 token** e cada worker devolve um resumo condensado; o orquestrador
**não lê** as N saídas. Logo a saturação `W/m` **não morde no orquestrador**. O cap de **16
concorrentes** (`onion-fleet/SKILL.md:18`) é limite de **throughput do substrato Workflow**, não de
contexto — e o excedente apenas enfileira.

Conclusão: a hierarquia é necessária **bem menos** do que o paper sugere. Ela só agrega valor num
caso específico — quando a **síntese precisa de um LLM** (não dá para fazer em JS determinístico)
sobre um conjunto grande **que estouraria um único agente sintetizador**. Aí, e só aí, nós
sumarizadores intermediários ganham sentido.

> ⚠️ O paper *"Phase Transition for Budgeted Multi-Agent Synergy"* e seus escalares (`α_ρ>1`, `s>β`)
> **não foram verificados** — entram como lente conceitual, não como teorema. Este ADR **não constrói**
> sobre eles; o efeito Ringelmann (1913), sim, é estabelecido.

---

## Decisão

> **O que este ADR decide (e o que NÃO decide).** Aceitar este ADR **não introduz um padrão de uso
> obrigatório** nem torna a árvore o default — mantém o **default plano** (CA1) e apenas torna a
> árvore-no-principal um caminho **legítimo e nomeado** para um caso-limite estreito. A peça **vigente**
> é a **desambiguação locus×forma**; a documentação do padrão "nó sumarizador" na KB/skill fica
> diferida (Gatilho de Implementação). O contra-ponto W/m é justamente o que justifica manter o gatilho
> estreito.

1. **Locus é invariante — não muda.** A orquestração (fan-out, fan-in, decisão, roteamento) mora
   **sempre no nível principal** (skill/comando). Nenhum agente dispara frota; `fleet-orchestrator`
   permanece proibido (`architecture.md:204` §4.2). Os dois pilares — economia de token (fan-in JS) e
   auditabilidade — seguem de pé.
   > **Nota (lendo de fora):** a regra `agents/* → commands/* = Não` (§4.2) é um **proxy** de um
   > princípio mais amplo — *sem inversão de controle: a orquestração mora no topo*. Não é capricho de
   > grafo de arquivos: se um agente pudesse invocar comando, poderia orquestrar (ciclo
   > `command → agent → command`, controle disperso, fan-in fora do JS). A regra **não** torna o agente
   > uma função isolada — agentes delegam a *outros agentes* (`agents/* → agents/* = Sim`) e aninham
   > até 5 níveis; o que se proíbe é só a seta **para cima** (worker dirigindo a camada de
   > orquestração). É a mesma aposta da co-evolução (git-async, humano-maestro): troca-se flexibilidade
   > emergente por auditabilidade e custo previsível.

2. **Forma do grafo é escalável.** O grafo de agentes pode ser **plano por padrão** ou **árvore com
   nós sumarizadores**. A árvore é **legítima** desde que **composta no nível principal** (via
   `parallel`/`pipeline` aninhados ou `workflow()` de 1 nível) — nunca por um agente que orquestra.
   Hierarquia ≠ violação da invariante; hierarquia escondida num agente = violação.

3. **Gatilho do nó sumarizador.** Introduzir nós sumarizadores **somente** quando o fan-in
   determinístico em JS **não basta** — isto é, quando a **síntese exige raciocínio de LLM** sobre um
   conjunto que **estouraria a janela de um único agente sintetizador**. Nos demais casos (dedupe,
   ranqueamento, merge, filtro), o **fan-in JS a 0 token vence** — é mais barato e mais auditável.

4. **Compactação por nó é requisito.** Havendo nó sumarizador, cada nó devolve **resumo condensado**
   (não bruto), de modo que o **input do agente sintetizador caiba na sua janela de contexto** — um
   requisito de **primeiros princípios** (não herdado do paper). A heurística de design
   `b·m ≤ W` (b = fan-in local, m = tamanho do resumo, W = janela) é só uma forma compacta de dizer
   isso; é onde a aritmética de orçamento-de-janela morde no Onion — no **agente sintetizador**, não no
   orquestrador. É **heurística**, não critério mensurável (W/m/b não têm valor fixado aqui); o que se
   **verifica** é a parte observável: o sintetizador lê *k resumos*, não *N brutos* (ver CA2).

### Esboço ilustrativo (não é implementação)
```javascript
// PLANO (default): fan-in determinístico em JS — 0 token, vence quase sempre
const found = await parallel(targets.map(t => () => agent(scan(t), { schema: S, model: "haiku" })));
const consolidated = dedupeAndRank(found.filter(Boolean));   // JS, 0 token

// ÁRVORE (sob gatilho): só quando a SÍNTESE precisa de LLM sobre conjunto grande.
// Nós sumarizadores agrupam por subdomínio e condensam ANTES do fan-in final.
// Tudo composto no nível principal — nenhum agente dispara frota.
const groups = partition(targets, bySubdomain);              // JS
const summaries = await parallel(groups.map(g => () =>
  // nó sumarizador: recebe os achados do grupo e devolve resumo condensado (b·m ≤ W)
  pipeline(g, t => agent(scan(t), { schema: S, model: "haiku" }))
    .then(rs => agent(summarizeGroup(rs), { schema: SUMMARY, model: "sonnet" }))  // m pequeno
));
const finalSynthesis = await agent(synthesize(summaries), { model: "opus" });     // lê k resumos, não N brutos
```

---

## Alternativas consideradas

- **A — Status quo (só plano; árvore mencionada apenas como armadilha).** *Pró:* zero trabalho.
  *Contra:* mantém a confusão "hierarquia é proibida" e não dá caminho quando a síntese por LLM
  estoura. ❌ Rejeitada — o gap permanece.
- **B — Permitir agente `fleet-orchestrator` (hierarquia via agente).** *Pró:* "hierárquico" literal
  do paper. *Contra:* viola `architecture.md §4.2`, perde o fan-in JS 0-token, esconde a orquestração
  no lugar mais caro e opaco. ❌ Rejeitada — fere a invariante e os dois pilares.
- **C — Desambiguar locus×forma; legitimar árvore-no-principal sob gatilho. ✅ ESCOLHIDA.** *Pró:*
  fecha o gap sem tocar a invariante; reusa primitivas existentes; honra o contra-ponto W/m. *Contra:*
  mais um padrão a documentar e nomear com cuidado (mitigado: "nó sumarizador no nível principal" ≠
  "fleet-orchestrator").

---

## Consequências

### Positivas
- Remove a inferência-por-omissão "hierarquia = proibida"; deixa explícito o que é permitido (forma de
  árvore no nível principal) e o que é armadilha (locus dentro de um agente).
- Prepara escala para o caso real (síntese por LLM sobre conjunto grande) sem inflar custo no caso comum.
- Reafirma a invariante de locus com fundamento renovado (o contra-ponto W/m fortalece o "fan-in JS").

### Negativas / trade-offs
- Introduz um padrão a mais ("nó sumarizador") — risco de ser confundido com a armadilha. Mitigação:
  nomenclatura e a regra "composto no nível principal; nenhum agente dispara frota".
- A condição de gatilho ("JS não basta") exige julgamento; pode ser mal aplicada (over-engineering).
  Mitigação: default é plano; árvore é exceção justificada.

---

## Gatilho de Implementação (diferido até aceite)

Quando aceito, e **só** quando um caso real bater o gatilho (síntese por LLM sobre conjunto que
estoura 1 agente):
1. Documentar o padrão **"nó sumarizador no nível principal"** em
   [`agent-fleet-orchestration.md`](../knowledge-base/concepts/agent-fleet-orchestration.md), ao lado
   da armadilha "frota dentro de agente" (contraste explícito).
2. Acrescentar um exemplo curto na [`onion-fleet/SKILL.md`](../../.claude/skills/onion-fleet/SKILL.md).
3. **Reusa** `parallel`/`pipeline`/`workflow()` existentes — **não cria primitiva nova** nem agente.

---

## Critérios de aceite testáveis

- **CA1 (default plano):** dado um fan-out de N workers cuja consolidação cabe em JS (dedupe/rank/merge),
  o padrão **não** usa nó sumarizador — fan-in JS 0-token. *Verificável:* nenhum `agent()` de síntese
  intermediária no script.
- **CA2 (árvore sob gatilho):** dada síntese por LLM sobre conjunto que estouraria 1 agente, o grafo
  usa nós sumarizadores (resumo condensado, heurística `b·m ≤ W`) e a orquestração permanece no nível
  principal. *Verificável (estrutural):* o agente final lê *k resumos*, não *N brutos* — inspeção da
  estrutura do script (nº de inputs do `agent()` de síntese). A condensação em si é design, não
  grep-able.
- **CA3 (invariante intacta):** em nenhum caso existe agente `fleet-orchestrator`. **Dois níveis de
  verificação, não confundir:** *(a) ausência estrutural — determinística:* `grep -rL` por um agente
  real chamado `fleet-orchestrator` em `.claude/agents/**` retorna vazio (hoje a única ocorrência da
  string é a **referência-proibição** em `metaspec-gate-keeper.md`, não um agente). É o gate canônico do
  projeto (selftest/inventory). *(b) conformidade de design — julgamento:* "nenhum agente *dispara
  frota*" é semântico (intenção em prosa), **não** grep-able; afere-se por **veredito LLM** via
  `/meta:metaspec-validate` contra `architecture.md §4.2` (com evidência citada) — não como prova
  mecânica automática.

---

## Referências

- [`architecture.md`](../meta-specs/architecture.md) — §4.2 (`agents/* → commands/*` = Não, linha 204), §4.3 (acoplamento entre dimensões)
- [`agents.md`](../meta-specs/agents.md) — §5-6 (delegação; sem agente fleet-orchestrator)
- [`agent-fleet-orchestration.md`](../knowledge-base/concepts/agent-fleet-orchestration.md) — doutrina de frota vigente (caps :246, fan-in :247-248, nesting :250, armadilha :461/:478)
- [`onion-fleet-external-radar-2026-06.md`](./onion-fleet-external-radar-2026-06.md) — origem (item 🟡 TOPO)
- [`onion-adr-comms-transport-vs-execution-2026-06.md`](./onion-adr-comms-transport-vs-execution-2026-06.md) — ADR-irmão (também desambígua dois eixos confundidos)
- **Não verificado:** *"Phase Transition for Budgeted Multi-Agent Synergy"* (jan/2026) — lente, não fonte.

---

**Mantido por:** Sistema Onion · **Última atualização:** 2026-06-22 (aceite + correção de citação
`architecture.md:204`; refino pós-revisão em frota — separação mecânico×julgamento nos CAs, `b·m≤W`
rebaixada a heurística, "O gap" reframado como omissão, mecanismo (a)×(b) na forma de árvore)

> **Histórico de revisão.** Revisão adversarial em frota (5 lentes + verificação adversarial,
> 2026-06-22): 16 achados, **0 blocker/major** — decisão central validada. Refinos das camadas 1-2
> aplicados. **Diferido à promoção:** ancorar "nó sumarizador" ao termo de mercado/`agente de síntese`
> (regra de linguagem ubíqua); frase-âncora locus×forma na KB ao lado da armadilha; promoção de
> metadados (title/`type`/filename `draft→adr`) + atualizar 4 referências cruzadas em
> `onion-fleet-math-phase-transition-2026-06.md` e `onion-fleet-external-radar-2026-06.md`.
