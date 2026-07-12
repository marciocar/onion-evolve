---
title: "P2 — Três gates, não um: intake × execução aplicado ao pipeline do sensor"
category: discussion-note
status: fonte-de-discussao-isolada
branch: discuss/behavior-mapping-kg
responde: "SEED.md — pergunta 2 (intake × execução — o estudo de camadas aplica direto)"
lente: "a linha intake↔execução do Onion + o ato regulado (GDPR Art. 22/profiling)"
ancora_pesquisa: research/SYNTHESIS-P2.md
metodo: "pesquisa orquestrada 2 frentes (citada) + doutrina interna; posição depois"
constroi_sobre: [01-consentimento-dual]
---

# 🧵 P2 — Três gates, não um

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os
> outros temas. Constrói sobre a [nota 01](01-consentimento-dual.md).

## O veredito, em uma frase

**O estudo de camadas do Onion dá _uma_ linha (guardar × agir); um sensor de comportamento tem
_três_ gates — observar, inferir e agir — e entre eles vale a regra de intake autônomo.**

A KB [`authorization-layers-intake-vs-execution`](../../knowledge-base/concepts/authorization-layers-intake-vs-execution.md)
crava: *"guardar ≠ aceitar ≠ aplicar"* — intake (receber/verificar/guardar de contato permitido) é
**autônomo**; só a **execução** (efeito de saída) é gated. Isso resolve a maioria dos canais com uma
linha só. O pipeline de um sensor **bruto→ação** rompe isso em dois pontos, e o resultado são três
gates ([SYNTHESIS-P2](research/SYNTHESIS-P2.md)).

## O pipeline e onde caem os gates

```
                         GATE 1                         GATE 2                    GATE 3
                       (observar)                     (inferir)                  (agir)
   latente  ──observe──▶  bruto ──store──▶ guardado ──map──▶ mapeado ──infer──▶ inferido ──propose──▶ proposto ──apply──▶ aplicado
              ▲dupla                └──────── intake AUTÔNOMO ────────┘   ▲perfilar          propose-only    ▲só humano
           autorização                (guardar ≠ aceitar ≠ aplicar)    = ato regulado                     efeito irreversível
```

- **Gate 1 — OBSERVAR** (o pré-intake da P1). Para um sensor, a captura *é* a intrusão: observar é
  o ato sensível. É a **inversão** que a P1 cravou — a permissão de observar é o gate, não autônoma.
  Sem dupla autorização, **VETO** (nunca skip).
- **Zona de intake autônomo** (guardar → verificar/de-identificar → mapear em KG). Aqui vale a regra
  original: guardar não é agir. É autônomo — mas **local-first, não-retido, escopado ao propósito**
  (a não-retenção do bruto vale mais que a cifra).
- **Gate 2 — INFERIR** (o gate novo, no meio). Este é o achado da P2: **derivar já é ato regulado**.
  O GDPR Art. 4(4) trata *profiling* (avaliar/prever comportamento) como tratamento regulado mesmo
  sem "agir"; e o **SCHUFA** (TJUE C-634/21, 2023) foi além — **derivar um score já _é_ a decisão
  automatizada** quando alguém se apoia nele. Traduzindo: inferir/perfilar/agregar-cross-pessoa
  **não é intake livre**. Debita escopo e orçamento (ε), e a inferência entra no *threat model*
  (ecoa a lacuna aberta da [P1 §4](01-consentimento-dual.md)).
- **Propor é propose-only.** Sugerir um processo/automação não tem efeito de saída — guardar a
  proposta ≠ aplicá-la. Fica na zona autônoma.
- **Gate 3 — AGIR** (a execução clássica). Automatizar/decidir *sobre a pessoa* dispara o Art. 22
  (decisão unicamente automatizada → intervenção humana) e o AI Act Art. 14 (monitorar trabalho =
  alto risco → supervisão humana efetiva, com override e stop). Só **humano** aplica; regulado =
  **propose-only**.

## Por que isto não é só "aplicar o estudo de camadas"

O estudo de camadas nasceu para **ingestão de sinal de um contato** (a2a, co-evolução): uma linha,
entre guardar e agir. Um sensor tem duas diferenças que criam gates extras:

1. **A ponta da frente inverte** (P1): observar não é "guardar de contato permitido" — é produzir o
   dado mais sensível. O gate vem **antes** do intake, não depois.
2. **O meio ganha um gate** (P2): no a2a, processar/derivar do sinal guardado é inócuo. Aqui,
   **derivar é perfilar** — a lei trata como ato regulado (SCHUFA). Então há um gate *dentro* do que
   seria "intake".

O que **não** muda: entre os gates, a regra de ouro do Onion se mantém — guardar/mapear é autônomo,
gatear pelo **efeito de saída**, e todo gate degrada para **VETO, nunca skip**.

## Convergência (o Onion já é o padrão)

O estado-da-arte de 2026 reencontra, por fora, a doutrina que o Onion já tem
([SYNTHESIS-P2](research/SYNTHESIS-P2.md) §Convergência): gatear pelo *side effect* (Auth0), tiered
autonomy que **bloqueia o irreversível** (BetterClaw), autorização **determinística downstream — não
o auto-julgamento do agente** (Auth0), supervisão **real** e não de fachada (AI Act 14). Isso é, uma
a uma, a linha intake↔execução + `apply_mode: propose-only` + o gate determinístico (shell/awk que
"não aluga LLM"). A P2 só multiplica a linha por três.

## Honestidade (o fecho)

- **A fronteira derivar×agir é porosa.** SCHUFA move o gatilho para quem *infere* — mas nem toda
  derivação aciona o Art. 22 (só a decisão *unicamente* automatizada com efeito significativo). O
  gate 2 é real, mas seu *nível* de exigência varia com o uso da inferência.
- **HITL pode ser de fachada.** Um humano carimbando sob pressão não é supervisão (o próprio AI Act
  alerta contra *automation bias*). O gate 3 exige poder **real** de override, não presença formal.
- **"Read-only" nem sempre é inócuo.** Algumas leituras têm efeito colateral — gatear pelo *side
  effect*, não pelo verbo. Para o sensor, "só observar" **tem** efeito (é a intrusão) — daí o gate 1.
- **Não decide o "como capturar".** Passiva × declarada, local × nuvem é a P3; do sinal ao KG é a
  P4; fronteira de produto é a P5. A P2 só mapeia **onde** os gates ficam.

## Tabela de fecho

| Etapa do pipeline | Intake ou execução? | Gate? |
|-------------------|---------------------|-------|
| Observar/capturar | **execução-de-entrada** (inverte) | 🔴 GATE 1 — dupla autorização; VETO |
| Guardar / verificar / de-identificar | intake | 🟢 autônomo (local-first) |
| Mapear bruto → KG (event/entity) | intake | 🟢 autônomo (escopado) |
| Inferir / perfilar / agregar | **ato regulado** (SCHUFA) | 🔴 GATE 2 — escopo + ε |
| Propor processo/automação | intake (propose-only) | 🟢 autônomo (sem saída) |
| Aplicar / automatizar / decidir | execução | 🔴 GATE 3 — só humano; Art. 22/AI Act |

## Dogfood

O pipeline vive como máquina de estados de domínio em
[`proto/pipeline-gates.kg.yaml`](proto/pipeline-gates.kg.yaml) — `latente → bruto → guardado →
mapeado → inferido → proposto → aplicado`, com os 3 gates como `policy`/`rule`/`invariant` que
`CONSTRAINS` seus eventos, e o ciclo fechando (`aplicado → latente`) para não haver estado
absorvente.

```bash
$ bash .claude/validation/kg-radar.sh docs/discussions/behavior-mapping-kg/proto/pipeline-gates.kg.yaml
# ══ RADAR: EV_OBSERVE (gate 1) e EV_APPLY (gate 3) no topo dos eventos — os dois gates duros
# ══ RECONCILIAÇÃO: REFUTES  C_THREE_GATES → C_SINGLE_GATE  ("1 gate basta" refutado)
# ══ RADAR-DE-DOMÍNIO: ✅ camada domain completa (sem lacunas nas 5 checagens)
# ══ INTEGRIDADE: ✅ sem contradições estruturais (29 nós, 32 arestas)  → exit 0
```

O radar coloca `EV_OBSERVE` e `EV_APPLY` como os eventos de maior atenção — o grafo "vê" sozinho que
as duas pontas (observar e agir) são os gates duros; o gate 2 (inferir) aparece logo abaixo, como a
novidade que a P2 nomeia.

---

### Próximas perguntas (não desta nota)

- **Q3** — captura passiva (telas/ações) × declarada; local-first × nuvem.
- **Q4** — do sinal bruto ao KG: o que vira `event`/`entity`/`claim`; reconciliar declarado × observado.
- **Q5** — fronteira de produto: feature do Onion pessoal × produto próprio de process-mining consentido.
