---
title: "ADR — Meia-vida por CLASSE para nós do KG (desenhado, GATED)"
category: analysis
date: 2026-08-02
status: gated-com-gatilho-escrito
decides: maestro
verified_at: 2026-08-02
source: "medição direta no HEAD 2e12840 + docs/evolution/research/onion-market-kg-2026-08/"
kg: docs/evolution/research/onion-market-kg-2026-08/onion-market-kg-2026-08.kg.yaml
---

# Meia-vida por classe — desenhado e **gated**

> **Estado:** desenho completo, **não construído**. Gatilho de abertura escrito abaixo.
> Companheiro da **REGRA 49** (`kg-verification-coverage.sh`), que já está viva.

## A pergunta do maestro

> *"90 dias total não é muito tempo para revisão, já que estamos trabalhando com tecnologias e
> conceitos que são a bordo da tecnologia e estão em criação? Temos uma periodicidade ajustável
> para tipos, momento e abrangência?"*

**Sim, é longo demais — para algumas classes.** E a evidência é da própria sessão de 2026-08-02.

## O que existe hoje (medido)

| onde | cadência |
|---|---|
| `.claude/diary/` | **por entrada** — `review_after` (data) + `conflict_class` (`static` 59 · `dynamic` 13 · `conditional` 13) + `valid_when` (condição) |
| `doctrine-freshness.sh:162` | **UM TTL global**, `DOCTRINE_FRESHNESS_TTL_DAYS:-90` |
| `.kg.yaml` | **nenhuma** — zero campos de cadência por nó |

**A casa resolveu isso uma vez, no diário, e não generalizou.** É a mesma forma de tudo que esta
sessão encontrou.

## Por que 90 dias é longo demais — evidência desta sessão

| classe | o que aconteceu em ≤120 dias |
|---|---|
| **plataforma** | **5 mudanças** do Claude Code: `.claude/rules/`, os 5 tipos de hook, memory tool GA, commands fundidos em skills, ~80% do system prompt cortado |
| **mercado** | **Graphify: 100.765 ★ em 120 dias** · a YC nomeou "Company Brain" **7 dias** depois do nosso nó afirmar que não havia categoria nomeada |
| **infra própria** | flip P7, SDK 0.3.195→0.3.220, WAHA — tudo dentro do mês |

Com TTL de 90 dias, **nada disso teria disparado re-verificação a tempo**.

## O desenho — e a chave é que a classe se DERIVA, não se declara

Mudar a gramática do `.kg.yaml` custaria a **todos os adotantes** (a KB declara isso explicitamente).
Medido em 2026-08-02, a classe **já está no dado**:

| classe | meia-vida | **derivada de** | quantos hoje |
|---|---|---|---|
| **plataforma / fornecedor** | **14d** | `trace:` aponta doc de vendor (`anthropic.com`, `claude.com`…) | — |
| **mercado / player** | **30d** | `trace:` = URL externa não-vendor | **53** |
| **infra própria** | **30d** | `verified_against:` cita host/deploy/systemctl/container | **43** |
| **código** | **por evento** | `verified_against:` cita commit/branch/sha | **11** |
| **decisão nossa** | **180d** | `node_type: decision` | **344** |
| **doutrina / invariante** | **por evento** | KB, `node_type: invariant`/`policy` | — |

Mesmo truque do `EXTRACTED`/`INFERRED` do Graphify: **ler o que já está lá, em vez de pedir mais**.

## Os três eixos do maestro — e o segundo é o que muda tudo

**TIPO** → a classe derivada acima.

**MOMENTO** → para as classes de cima, **calendário é o instrumento errado**. O gatilho certo para
"plataforma" não é *a cada 14 dias* — é ***quando o fornecedor lançou release***. Data é aproximação
pobre de um evento observável. O diário já tem o campo: **`valid_when`** (condição), e a classe
`conditional` existe para essa família.

**ABRANGÊNCIA** → um nó que afirma *"não há categoria nomeada no mercado"* precisa de varredura
ampla; um que afirma *"a porta 8787 responde 200"* precisa de um `curl`. **Hoje os dois teriam o
mesmo TTL** — caro demais para um, frouxo demais para o outro.

## Por que fica GATED

**Medido em 2026-08-02: nós no escopo com `verified_at` VENCIDO (>30d) = ZERO.**

A doutrina do KG tem **29 dias**; nada teve tempo de envelhecer. **Regra de expiração sobre conjunto
vazio é cerimônia elegante** — passa no selftest, não guarda nada, e engorda a superfície no mesmo
repo onde a auditoria de hoje mediu 13 peças de cerimônia.

E o portão que decide, honestamente: **o volume não força** — ainda.

## O gatilho de abertura (verificável)

> **≥ 20 nós no escopo da REGRA 49 com `verified_at` mais velho que 30 dias.**

Comando que responde, determinístico:

```bash
git ls-files '*.kg.yaml' | grep -v '/fixtures/' | xargs -r awk '
  /verified_at:/ { print $2 }' | sort | awk -v c="$(date -d '30 days ago' +%Y-%m-%d)" '$1 < c' | wc -l
```

Previsão honesta: os carimbos de julho começam a vencer em **~30–60 dias**. Aí a classe nasce com
**dado real** em vez de tabela bonita — que é a diferença entre mecanismo e cerimônia.

## Dissent

**Esperar pode ser o erro.** Se em 60 dias existirem 200 nós vencidos de uma vez, a classe nasce
diante de um muro, e muro não se drena — ele se ignora, e o gate vira decoração com selftest verde.
O contra-argumento é que a **REGRA 49 já para o sangramento hoje** (nó novo nasce carimbado), então
o passivo futuro cresce devagar. Mas isso é previsão, não medição — e está declarado como tal.
