---
title: "Três gates de um sensor de comportamento — mapear consentido ≠ vigiar"
category: concepts
tags: [seguranca, gate, autorizacao, privacidade, consentimento, intake, execucao, inferencia, telemetria]
status: candidato
date: 2026-07-12
---

# Três gates de um sensor de comportamento — mapear consentido × vigiar

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Categoria** | Concepts |
| **Aplicação** | Qualquer projeto que **colete/mapeie comportamento ou atividade** (telas, ações, logs de trabalho) para documentar, padronizar, entender e automatizar |
| **Origem** | Frente de discussão isolada `discuss/behavior-mapping-kg` (2026-07-12) — extrato generalizável (a frente completa não é doutrina fechada) |
| **Estende** | [`authorization-layers-intake-vs-execution.md`](authorization-layers-intake-vs-execution.md) (a linha intake↔execução) |

> **Por que este KB existe.** A linha `intake↔execução` do Onion resolve a maioria dos canais de
> ingestão com **uma** fronteira (*"guardar ≠ aceitar ≠ aplicar"*). Mas um sistema que **observa
> comportamento** é diferente: a captura *é* a intrusão. Este KB consolida o que a linha vira nesse
> caso — **três gates, não um** — e a distinção ética que a antecede (**mapear consentido ≠ vigiar**).

## 1. A distinção ética que vem antes (mapear ≠ vigiar)

A mesma técnica que mapeia "o que a pessoa faz" — para **documentar, padronizar, entender o problema
e automatizar** — é a mesma que **vigia**. O que as separa não é a ferramenta; são **quatro eixos**,
e violar **qualquer um** converte mapa em vigilância:

| Eixo | Mapeamento (legítimo) | Vigilância (anti-padrão) |
|------|-----------------------|--------------------------|
| **Finalidade** | otimizar/automatizar o fluxo transversal | avaliar/punir o indivíduo |
| **Transparência** | o titular sabe o quê, como, quem vê | coleta oculta / default-on |
| **Agregação** | agregado, k-anonimizado, por equipe | rastreio nominal, ao segundo |
| **Controle** | consentimento atualizado, revogável, contestável | sem saída, fora do expediente |

**Autorização dual e deliberada:** a captura só é legítima se a **pessoa E a organização** querem e
autorizam — **nunca imposto nem acidental**. Numa empresa, a organização entra como **compositora de
conhecimento consentido** de várias pessoas para mapear uma atividade/produto transversal — *não*
como vigia. Compor entre pessoas exige o consentimento próprio de cada uma.

## 2. Os três gates (a linha intake↔execução, para um sensor)

O KB [`authorization-layers`](authorization-layers-intake-vs-execution.md) diz: intake (receber·
verificar·guardar de contato permitido) é **autônomo**; só a **execução** (efeito de saída) é gated.
Para um sensor de comportamento, a mesma linha aparece **três vezes**:

```
              GATE 1                      GATE 2                    GATE 3
            (observar)                  (inferir)                  (agir)
   ──observe──▶ [ guardar · verificar · mapear ] ──infer──▶ [ propor ] ──apply──▶
      ▲dupla         └──── intake AUTÔNOMO ────┘   ▲derivar      ▲só humano
   autorização      (guardar ≠ aceitar ≠ aplicar)  = ato regulado  efeito irreversível
```

- **Gate 1 — OBSERVAR** (a inversão). Para um sensor, a captura *é* o ato sensível → a **permissão de
  observar** é o gate, **antes** do intake. Não é autônoma: exige autorização prévia, opt-in,
  revogável. Sem ela, **VETO** (nunca skip — o fail-open é "capturar por default").
- **Zona de intake autônomo.** Uma vez capturado com permissão, **guardar → verificar/de-identificar
  → mapear** é autônomo — mas local-first, escopado, minimizado.
- **Gate 2 — INFERIR** (o gate do meio). **Derivar já é ato regulado.** O GDPR trata *profiling*
  (Art. 4(4)) como tratamento regulado mesmo sem "agir", e o TJUE (**SCHUFA**, C-634/21, 2023)
  decidiu que **derivar um score já É a decisão automatizada** quando alguém se apoia nele. Logo:
  inferir/perfilar/agregar-cross-pessoa **não é intake livre** — debita escopo/orçamento (ε) e entra
  no *threat model*.
- **Gate 3 — AGIR** (execução clássica). Automatizar/decidir *sobre a pessoa* dispara o GDPR Art. 22
  (decisão unicamente automatizada → intervenção humana) e o EU AI Act Art. 14 (monitorar trabalho =
  alto risco → supervisão humana efetiva, com override e stop). Só **humano** aplica; regulado =
  **propose-only**.

## 3. Por que inverte E multiplica a linha original

O estudo de camadas nasceu para **ingestão de sinal de um contato** (a2a, co-evolução): uma linha,
entre guardar e agir. Um sensor tem duas diferenças que criam gates extras:

1. **A ponta da frente inverte:** observar não é "guardar de contato permitido" — é *produzir* o dado
   mais sensível. O gate vem **antes** do intake.
2. **O meio ganha um gate:** no a2a, processar/derivar do sinal guardado é inócuo. Aqui, **derivar é
   perfilar** — a lei trata como ato regulado. Há um gate *dentro* do que seria "intake".

O que **não** muda: entre os gates, a regra de ouro se mantém — gatear pelo **efeito de saída**, e
todo gate degrada para **VETO, nunca skip**.

## 4. Convergência — o Onion já é o padrão

O estado-da-arte de 2026 para agentes que agem **reencontra**, por fora, a doutrina que o Onion já
tem:

| Doutrina Onion (interna) | Estado-da-arte externo (2024–2026) |
|--------------------------|-------------------------------------|
| "guardar ≠ aceitar ≠ aplicar" — gatear no **efeito de saída** | gatear pelo *output/side-effect*, não pela leitura |
| gate degrada para **VETO, nunca skip** | bloquear o irreversível até aprovação; stop-button (AI Act 14) |
| `apply_mode: propose-only` (membros regulados) | *tiered autonomy* — Tier 3 bloqueia o irreversível |
| gate **determinístico** (shell/awk, "não aluga LLM") | autorização determinística *downstream*, **não** o auto-julgamento do agente |

## 5. O que isto NÃO resolve (a lacuna da inferência)

Consentir a **captura** não protege da **inferência**. Um modelo sobre o grafo *deduz* atributos
sensíveis nunca capturados (Staab et al., ICLR 2024, ~85% top-1), e **redigir strings de PII não
protege** (o modelo reconstrói pelo estilo/contexto). O orçamento ε de differential privacy **não
cobre** a inferência externa. Mitigações são **parciais**: minimização de propósito, não-retenção do
bruto (local-first), revelar **predicados** em vez de valores (SD-JWT VC / ZKP), e um **ledger de ε**
que trate cada agregação como gasto. Honestidade: **dupla-consentida na captura ≠ protegida na
inferência** — é fronteira aberta.

## 6. Doutrina consolidada (fontes)

- **Interna:** [`authorization-layers-intake-vs-execution.md`](authorization-layers-intake-vs-execution.md)
  (a linha), `de-identification` SDAAL (fail-safe `none`), rfc-0003 (classificação 6-níveis,
  `private` inviolável), `knowledge-graph-sdaal.md` (planos DEV/PROD — observado × declarado).
- **Externa:** GDPR Art. 4(4)/5/7/22 · TJUE SCHUFA C-634/21 (2023) · EU AI Act Art. 14 · Nissenbaum
  (Integridade Contextual) · van der Aalst FACT / *Responsible Process Mining* · Staab et al. (ICLR
  2024) · Kleppmann et al. *Local-first software* (2019).

## 7. Lacunas honestas (o que este KB NÃO fecha)

- **A fronteira derivar×agir é porosa** — SCHUFA move o gatilho para quem infere, mas nem toda
  derivação aciona o Art. 22 (só a decisão *unicamente* automatizada com efeito significativo).
- **A mitigação de inferência é fronteira aberta** — nenhuma cifra protege um modelo raciocinando
  sobre o próprio grafo; é tema de pesquisa em curso, não doutrina fechada.
- **HITL pode ser de fachada** — supervisão humana real (override efetivo) ≠ carimbo sob pressão.
