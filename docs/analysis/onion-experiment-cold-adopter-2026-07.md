---
title: "Experimento Q_COLD_ADOPTER — existe pull arms-length pelo diferenciador raro?"
category: meta
tags: [experimento, customer-development, north-star, cold-adopter, kg, estrategia, desempate]
status: desenhado-para-execucao
date: 2026-07-11
resolve: Q_COLD_ADOPTER (grafo onion-identity-2026-07.kg.yaml)
decide_entre: [NS1-KG, NS3-Educacao]
---

# Experimento Q_COLD_ADOPTER

> **Por que este experimento é o desempate.** O grafo (radar) reduziu a north-star a uma tensão: **NS1** tem
> toda a convergência + o combo único (multi-vertical reconciliado, que a pesquisa confirmou desocupado), mas
> sua convicção está `DEPENDS_ON` de **uma pergunta**: a demanda provada é do **eixo** (Company Brain = aposta
> YC 2026), **não do Onion** — zero adotante frio (`C_DEMAND_AXIS_NOT_ONION`, atenção 17.0). Este experimento
> resolve exatamente essa pergunta com o **menor teste falsificável** — não construindo produto (erro v4.0).

## 1. Hipótese

- **H1 (NS1 destrava):** existe **pull arms-length** — alguém FORA da órbita de Marcio busca, tenta e volta
  ao diferenciador raro, por conta própria.
- **H0 (empurra pro hedge NS3):** não há pull externo; a demanda é do eixo, não do Onion. O norte de curto
  prazo vira caixa (educação) enquanto o eixo amadurece.

## 2. O que NÃO conta (guardas — a parte mais importante)

- **Vaidade não conta** (lição F2): stars, views, "que legal!" — não são pull.
- **Órbita não conta** (lição `C_ORBIT_CAVEAT`): repo de Marcio, cliente, convidado, alguém a quem ele pediu.
  Pull tem que ser de quem **não deve nada** a ele e **não foi empurrado**.
- **Construir distribuição pra testar demanda não conta** (guarda anti-v4.0): usa a superfície que **já existe**
  (`onion-mini` público, site, a2a/bridge) + no máximo **um one-pager**. Se exigir construir produto, **pare** —
  o experimento falhou de desenho, não a hipótese.

## 3. O diferenciador sob teste (um só, o mais defensável)

**O método KG SDAAL de reconciliação de conhecimento** — o núcleo do NS1, o eixo que a pesquisa achou **quente
e desocupado**. Testa-se **isso**, não o framework inteiro. Vantagem doutrinária: o método **viaja como
schema+método, não código** ([knowledge-graph-sdaal.md](../knowledge-base/concepts/knowledge-graph-sdaal.md)) —
dá pra oferecer sem distribuir o core.

## 4. Desenho — 2 instrumentos (orgânico barato + concierge controlado)

### Instrumento A — Probe orgânico (pull passivo, mais barato)
- **Artefato:** `onion-mini` (já público) + um **one-pager** "reconcilie o conhecimento da sua org como grafo"
  (o problema — drift, verdade×verdade, "git merge não reconcilia verdades" — + o método schema/radar + um
  `.kg.yaml` de exemplo).
- **Canal:** onde a conversa de **knowledge-reconciliation / Company-Brain / SDD** já acontece (as comunidades
  que a pesquisa mapeou) — **NÃO** a rede pessoal de Marcio.
- **Sinal de pull (falsificável):** em **4–6 semanas**, ≥1 estranho arms-length (a) tenta **sem ser pedido** E
  (b) **volta** com artefato real (um `.kg.yaml` do domínio DELE) **ou** pergunta de adoção concreta.

### Instrumento B — Design-partner concierge (pull ativo, fallback controlado)
- Recrutar **1–3 parceiros arms-length** (não-clientes, sem autoridade de Marcio sobre eles).
- Sessão estruturada de customer-dev (@pain-price-specialist + @product-agent): reconciliar **uma dor de
  conhecimento deles** com o método, ao vivo.
- **Sinal de pull:** **depois** da sessão, eles **continuam sem ser puxados** (produzem/pedem mais) — vs
  educado-mas-bounce. Continuar-sozinho é o tell; elogio na sessão não é.

## 5. Instrumentação (detectar honesto)
- `onion-mini` tem tráfego; o a2a/bridge tem telemetria de superfície — registrar **quem toca e o que produz**.
- Cada sinal vira **claim no KG** (`SUPPORTS`/`REFUTES` → `Q_COLD_ADOPTER`): a reconciliação do resultado usa
  a mesma máquina que o experimento testa (dogfood recursivo).

## 6. Time-box, custo e regra de decisão

- **Janela:** 4–6 semanas. **Custo:** ~zero código novo (one-pager + sessões). Teto: se pedir distribuição, pare.

| Resultado | Q_COLD_ADOPTER resolve | Decisão de north-star |
|---|---|---|
| **≥1 pull arms-length genuíno** (artefato ou adoção real) | **SIM** | **NS1 destrava com convicção** — investir no loop KG como produto/identidade |
| **Zero pull em 6 semanas** | **NÃO (por ora)** | peso pro **hedge NS3** (educação/caixa); re-testar quando a superfície pública crescer |
| **Ambíguo** (interesse sem artefato) | parcial | estender 1 ciclo, OU declarar "eixo validado, execução não" → NS3 com **NS1 em incubação** |

## 7. Riscos do próprio experimento (honestidade)
- **Superfície pública fina → risco de falso-negativo** ("ninguém ACHOU" ≠ "ninguém QUER"). Mitigação: o canal
  precisa ir **onde a demanda já está**, não esperar descoberta passiva.
- **N=1–3 é sinal, não prova estatística** — mas **1 adotante frio genuíno já falsifica "zero pull"**, que é a
  pergunta que trava a decisão agora. Não precisamos de significância; precisamos de existência.
- **Viés do concierge:** o Instrumento B, mal-conduzido, vira demo-de-vendas (empurra). O sinal é só o
  **continuar-sozinho pós-sessão** — blindar contra "elogio educado".

## 8. Próximo passo
Decisão do maestro: (a) **rodar o Instrumento A** (barato, precisa do one-pager + escolher o canal); (b) **rodar
o B** (precisa recrutar 1–3 parceiros arms-length); ou (c) **os dois** (A capta pull passivo, B força um teste
ativo). O resultado realimenta `Q_COLD_ADOPTER` no grafo e destrava (ou não) o NS1.
