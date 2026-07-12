---
title: "P4 — Do sinal bruto ao KG: event/entity/claim e a reconciliação faz × diz"
category: discussion-note
status: fonte-de-discussao-isolada
branch: discuss/behavior-mapping-kg
responde: "SEED.md — pergunta 4 (bruto → KG; reconciliar o que a pessoa faz × diz)"
lente: "object-centric process mining (XES/OCEL/EKG) + a ontologia DEV/PROD do KG SDAAL"
ancora_pesquisa: research/SYNTHESIS-P4.md
metodo: "pesquisa orquestrada 1 frente (citada) + ontologia interna; posição depois"
constroi_sobre: [01-consentimento-dual, 02-intake-execucao, 03-captura-e-localidade]
---

# 🧵 P4 — Do sinal bruto ao KG

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os
> outros temas. Constrói sobre a [01](01-consentimento-dual.md), [02](02-intake-execucao.md) e
> [03](03-captura-e-localidade.md).

## O veredito, em uma frase

**A ação observada vira `event` (PROD); pessoa/app/doc viram `entity` (object-centric); a inferência
vira `claim` (audit, não fato bruto); e o observado (PROD) reconcilia com o declarado (DEV) por
SUPPORTS/REFUTES/SUPERSEDES — o say-do gap vira aresta, não é apagado.**

O KG SDAAL já tem o vocabulário. A Q4 é o **mapa de tradução** do sinal de comportamento para ele —
e a reconciliação é o coração ([SYNTHESIS-P4](research/SYNTHESIS-P4.md)).

## 1. O mapa de tradução (o que vira o quê)

| Átomo bruto | Vira | Plano | Porquê |
|-------------|------|-------|--------|
| Ação observada (click/edit/tela) | `event` | **PROD** | o artefato vivo se comportando |
| Pessoa / app / doc / sistema | `entity` | — | object-centric: **1 evento ↔ N objetos** (não achatar) |
| Intenção/anotação declarada | `claim` | **DEV** | "o que a pessoa diz" = intenção, não fato |
| Inferência/derivação (perfil, padrão) | `claim` (audit) | — | herda o **gate 2** (P2): derivar é ato |
| Padrão de fluxo / jornada | `state` + `TRANSITIONS(on:)` | domain | jornada como máquina de estados |

Duas escolhas de fundo, ancoradas no estado-da-arte:

- **Object-centric, não single-case.** XES (IEEE 1849) exige a tripla `case+activity+timestamp`, mas
  achata tudo num eixo. OCEL e o **Event Knowledge Graph** (Esser & Fahland) permitem um evento
  ligado a **vários objetos** — que é exatamente o `entity`/`event` do KG SDAAL. O Onion **já é**
  property-graph; não precisa achatar.
- **Abstração é decisão gated.** Transformar clique→"revisar PR" é escolha semântica (*event
  abstraction*) — e, sendo derivação, cai no **gate 2** (P2): não é intake automático.

## 2. A reconciliação — o say-do gap vira aresta

O KG **não escolhe** entre o que a pessoa faz e o que ela diz. Registra os dois em planos opostos e
deixa as arestas falarem (a P3 preparou isto; a P4 executa):

- **observado sustenta** ⇒ `SUPPORTS` (event log → `claim` observado).
- **say-do gap** ⇒ `REFUTES` (observado **PROD** refuta declarado **DEV**) — o gap é registrado, não
  apagado.
- **comportamento mudou** ⇒ `SUPERSEDES` (observado novo supera o antigo).

O `kg-radar.sh` então **rankeia o gap** (atenção) e lista a reconciliação. Vale aqui a doutrina do
KB [`knowledge-graph-sdaal`](../../knowledge-base/concepts/knowledge-graph-sdaal.md): *"git merge não
reconcilia verdades"* — a divergência faz/diz é resolvida na camada de conhecimento (claims por
plano + REFUTES/SUPERSEDES + radar), append-mostly (nada se apaga).

## 3. Por que a inferência vira `claim`, não `event`

Distinção que amarra o tema todo: o **fato observado** é `event` (PROD); a **derivação** (perfil,
predição, "você trabalha melhor de manhã") é `claim` na camada audit. Manter os dois separados é o
que segura a inferência **dentro** do threat model (P1/P2) em vez de disfarçá-la de dado bruto. Uma
inferência é uma *hipótese com evidência e confiança*, sujeita a REFUTES — não uma verdade capturada.

## Honestidade (o fecho)

- **Object-centric tem custo.** OCEL/EKG são mais fiéis, mas muitas técnicas de discovery só operam
  sobre logs achatados — coexistência, não substituição. Adotar grafo puro cobra em tooling.
- **Não há granularidade "correta".** O nível de abstração é escolha (esforço × fidelidade
  semântica); LLM-labeling de clusters é direção emergente, não consenso validado.
- **Reconciliar pode juntar construtos diferentes** (P3): um REFUTES faz×diz pode significar "mudou",
  "mentiu", ou "a passiva mediu outra coisa" — a aresta marca o gap; interpretá-lo é trabalho humano.
- **Não decide se isto é produto.** Feature do Onion pessoal × produto próprio é a [Q5](05-fronteira-produto.md).

## Tabela de fecho

| Pergunta (SEED Q4) | Posição |
|--------------------|---------|
| O que vira `event`? | a ação observada (PROD), object-centric |
| O que vira `entity`? | pessoa/app/doc/sistema (1 evento ↔ N objetos) |
| O que vira `claim`? | o declarado (DEV) e a inferência (audit) — não fato bruto |
| Como reconcilia faz × diz? | SUPPORTS/REFUTES/SUPERSEDES entre planos; o radar mostra o gap |

## Dogfood

O mapa de tradução + a reconciliação vivem em
[`proto/signal-to-kg.kg.yaml`](proto/signal-to-kg.kg.yaml) — um `event` object-centric (`EMITS`/
`READS`/`WRITES` para 3 objetos), e a reconciliação onde o **observado REFUTA o declarado** (say-do
gap) e **SUPERA o observado antigo** (mudança de comportamento).

```bash
$ bash .claude/validation/kg-radar.sh docs/discussions/behavior-mapping-kg/proto/signal-to-kg.kg.yaml
# ══ RECONCILIAÇÃO:
#     REFUTES     C_OBSERVED → C_DECLARED     (o say-do gap, explícito)
#     SUPERSEDES  C_OBSERVED → C_OBSERVED_OLD (comportamento mudou)
# ══ RADAR-DE-DOMÍNIO: ✅ camada domain completa (sem lacunas nas 5 checagens)
# ══ INTEGRIDADE: ✅ sem contradições estruturais (13 nós, 14 arestas)  → exit 0
```

---

### Próxima pergunta (não desta nota)

- **Q5** — fronteira de produto: feature do Onion pessoal × produto próprio de process-mining consentido.
