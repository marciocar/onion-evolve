---
title: "Síntese P4 — Do sinal bruto ao KG: event logs (XES/OCEL), abstração e reconciliação"
category: research-synthesis
responde: "SEED.md — pergunta 4 (bruto → KG; reconciliar o que faz × o que diz)"
data: "2026-07-12"
branch: "discuss/behavior-mapping-kg"
fontes_verificadas: 10
metodo: "pesquisa orquestrada 1 frente (agente direto, WebSearch real) + ontologia interna do KG SDAAL"
---

# Síntese P4 — Do sinal bruto ao modelo

> **Carimbo: hoje = 2026-07-12.** Uma frente de pesquisa (padrões de event log + abstração) + a
> ontologia interna do KG SDAAL. Datas como fornecidas; **s/d** = sem data.

---

## Do sinal bruto ao modelo — event logs (XES/OCEL) e abstração

O caminho do sinal bruto ao modelo passa por uma primeira decisão: **o que é um "evento" e a que ele
se liga**. O padrão dominante, **XES (IEEE 1849-2016)**, formaliza o log como log → trace (caso) →
event; o mínimo operacional é a tripla **case + activity + timestamp**. O limite é que XES força um
**único case notion** (achata tudo num eixo). **OCEL / object-centric process mining** (van der
Aalst) responde permitindo que um mesmo evento se ligue a **múltiplos objetos** (pessoa, app, doc) —
o que mapeia direto para entidade↔evento. Antes disso há o **gap semântico**: cliques/teclas/sensores
não são "atividades" — **event abstraction** os converte em atividades de alto nível. E a ponte final
"log como grafo" é o **Event Knowledge Graph** (Esser & Fahland): eventos + entidades como
labeled property graph consultável por relações temporais e estruturais.

- **XES** — log/trace/event; `concept:name` = atividade, `time:timestamp` = momento — [IEEE 1849-2016 (XES)](https://standards.ieee.org/standard/1849-2016.html), 2016; [The IEEE XES Standard (van der Aalst)](https://vdaalst.com/publications/z92.pdf), 2024.
- A tripla mínima obrigatória **case + activity + timestamp** — [Data Requirements (Fluxicon)](https://fluxicon.com/book/read/dataext/), s/d.
- **OCEL 2.0** — um evento, múltiplos objetos; supera o "flattening" — [OCEL 2.0 Spec](https://www.ocel-standard.org/2.0/ocel20_specification.pdf), 2024; [OC-PM (van der Aalst)](https://link.springer.com/article/10.1007/s10009-022-00668-w), 2022.
- **Event abstraction** — de baixo nível a atividade significativa; taxonomia — [Event abstraction review (Diba et al.)](https://link.springer.com/article/10.1007/s41066-020-00226-2), 2020; [Low-Level Events to Activities (session-based)](https://arxiv.org/pdf/1903.03993), 2019.
- **Event Knowledge Graph** — eventos+entidades como property graph (Neo4j/Cypher) — [Multi-Dimensional Event Data in Graph DBs (Esser & Fahland)](https://link.springer.com/article/10.1007/s13740-021-00122-1), 2021.
- Do sensor bruto à atividade nomeada (pipeline com rotulagem) — [IoT Miner (LLM labeling)](https://arxiv.org/pdf/2509.05769), 2025; [Process-aware Human Activity Recognition](https://arxiv.org/pdf/2411.08814), 2024.

**Tensões:** single-case (XES) × object-centric (OCEL) — coexistência, não substituição (muitas
técnicas de discovery só operam sobre logs achatados). O **nível de abstração é escolha, não dado**
(não há granularidade "correta" objetiva). LLM-labeling é direção emergente, não consenso. Log linear
× grafo: o EKG argumenta que só o grafo consulta bem "sequências sobre múltiplas entidades" — custo de
adoção ainda não trivial.

---

## A tradução para o KG SDAAL do Onion (ontologia interna)

O KG SDAAL já tem o vocabulário; o mapeamento do sinal de comportamento é:

| Átomo bruto | Vira no KG | Plano | Porquê |
|-------------|-----------|-------|--------|
| Ação observada (click/edit/tela) | `event` | **PROD** | é o artefato vivo se comportando |
| Pessoa / app / doc / sistema | `entity` | — | object-centric (OCEL/EKG): 1 evento ↔ N objetos |
| Intenção/anotação declarada | `claim` | **DEV** | "o que a pessoa diz" = intenção, não fato observado |
| Inferência/derivação (perfil, padrão) | `claim` (audit) | — | herda o **gate 2** (P2): derivar é ato, não fato bruto |
| Padrão de fluxo / journey | `state` + `TRANSITIONS(on:)` | domain | jornada como máquina de estados |

E a **reconciliação** é o coração: o KG não escolhe entre observado e declarado — registra os dois em
planos opostos e deixa as arestas falarem:

- **observado sustenta** ⇒ `SUPPORTS` (event log → claim observado).
- **say-do gap** ⇒ `REFUTES` (observado PROD refuta declarado DEV) — o gap vira aresta explícita,
  não é apagado.
- **comportamento mudou** ⇒ `SUPERSEDES` (observado novo supera o antigo).
- o `kg-radar.sh` então **rankeia o gap** (atenção) e lista a reconciliação — exatamente o que a P3
  pediu: o say-do gap é informação, e o radar o torna visível.

## Convergências e implicações para a nota P4

1. **Object-centric bate com o KG.** OCEL/EKG dizem "1 evento, N entidades" — é o `entity`/`event`
   do KG SDAAL, sem achatar num case id único (o Onion já é property-graph).
2. **Abstração é uma decisão gated.** Transformar clique→atividade é escolha semântica — e, sendo
   *derivação*, cai no gate 2 (P2): não é intake automático.
3. **Reconciliação = planos DEV/PROD + SUPPORTS/REFUTES/SUPERSEDES.** O say-do gap (P3) tem, no KG,
   uma representação nativa; a doutrina "git merge não reconcilia verdades" aplica direto.
4. **Inferência vira `claim`, não `event`.** Distinguir o fato observado (event PROD) da derivação
   (claim audit) mantém a inferência dentro do threat model (P1/P2), não disfarçada de dado bruto.
