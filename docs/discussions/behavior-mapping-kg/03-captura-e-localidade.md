---
title: "P3 — Captura: passiva E declarada, e o bruto fica em casa"
category: discussion-note
status: fonte-de-discussao-isolada
branch: discuss/behavior-mapping-kg
responde: "SEED.md — pergunta 3 (passiva vs declarada; local-first vs nuvem)"
lente: "personal informatics (say-do gap, reactivity) + local-first + soberania (rfc-0003)"
ancora_pesquisa: research/SYNTHESIS-P3.md
metodo: "pesquisa orquestrada 2 frentes (citada) + doutrina interna; posição depois"
constroi_sobre: [01-consentimento-dual, 02-intake-execucao]
---

# 🧵 P3 — Como capturar, e onde o dado vive

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os
> outros temas. Constrói sobre a [01](01-consentimento-dual.md) e a [02](02-intake-execucao.md).

## O veredito, em uma frase

**Nem passiva nem declarada sozinha: o sensor precisa das duas (uma mostra o que a pessoa faz, a
outra o que ela diz), e o bruto vive local — só o derivado/predicado atravessa a fronteira.**

Dois eixos independentes: **como** capturar (passiva × declarada) e **onde** o dado vive (local ×
nuvem). A pesquisa ([SYNTHESIS-P3](research/SYNTHESIS-P3.md)) resolve os dois na mesma direção.

## 1. Passiva × declarada — os dois planos do KG

- **Passiva** (telas/ações observadas): completa, contínua, contorna o *recall bias* — mas **cega ao
  significado**. Sabe o "fez", não o "porquê". É o plano **PROD** (o que a pessoa faz).
- **Declarada** (o usuário anota, via ESM/EMA): rica em sentido, in-situ — mas **esparsa, custosa e
  enviesada** (desejabilidade social, reactivity). É o plano **DEV** (o que a pessoa diz).
- Entre as duas mora o **say-do gap**: o que se declara ≠ o que se faz (em consumo, ~50% de gap
  intenção→compra). **Isto não é erro a corrigir — é informação.** No KG, as duas viram claims em
  planos opostos e o radar mostra a divergência (isto prepara a [Q4](04-sinal-ao-kg.md)).

> Nenhuma é a "verdade" contra a qual a outra erra. A passiva **não é neutra** (carrega viés de
> medição, proxies pobres); e combinar **nem sempre soma** (para alguns construtos, sensor e relato
> quase não se sobrepõem). O sensor triangula — sem fingir que é uma medida só.

## 2. Reactivity — observar já muda o observado

O efeito Hawthorne / *participant reactivity* é direto ao tema: **ser medido altera o comportamento**
— e contamina as duas fontes quando o sujeito se sabe observado. Isso reforça, por um caminho
epistêmico, o que a [P1](01-consentimento-dual.md) disse pelo ético: observar é o ato sensível (o
gate 1). Consequência de design: **parcimônia** — capturar o mínimo que serve ao propósito, não o
máximo que a técnica permite. Menos captura é, ao mesmo tempo, mais ética e menos enviesada.

## 3. Local-first × nuvem — o bruto fica em casa

O eixo de localidade resolve com o **local-first** (Ink & Switch: soberania, privacy-by-default,
propriedade do usuário) + **on-device/edge** (processar onde nasce; o bruto não cruza a rede). O
meio-termo já é produção: **Apple PCC** (stateless, nada retido) e **Gboard** (federated learning +
DP, texto bruto nunca sai). A regra que fecha o eixo:

> **O bruto NUNCA sai do dispositivo. Só o de-identificado/agregado/predicado atravessa a fronteira.
> E não-guardar o bruto (não-retenção) vale mais que cifrá-lo.**

Isto ancora nas primitivas do Onion: a classificação 6-níveis do
[`rfc-0003`](../../evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md) (`private`
inviolável, soberania), o [`de-identification`](../../../.claude/utils/de-identification/README.md)
(redige antes de sair), e casa com a lacuna da inferência (P1) — como só o predicado sai, o `ε` da
[P2 gate 2](02-intake-execucao.md) é debitado na saída.

## Honestidade (o fecho)

- **Triangular não é somar.** Para alguns construtos (ex.: estresse) sensor e relato medem coisas
  diferentes — a reconciliação pode estar juntando dois construtos, não confirmando um.
- **Edge não é bala de prata.** Mover o modelo pro cliente troca superfície de rede por superfície
  de dispositivo (ataque white-box). "Verificável" (PCC) ainda é confiança no fabricante.
- **"Non-retention > cifra" é princípio composto**, não citação única — sustentado pelo statelessness
  da PCC + a limitação de armazenamento do GDPR (Art. 5), não por um texto que o enuncie assim.
- **Não decide o formato do KG.** O que o sinal vira (`event`/`entity`/`claim`) e como reconcilia é
  a [Q4](04-sinal-ao-kg.md). A P3 decide só **como** e **onde** capturar.

## Tabela de fecho

| Eixo | Posição | Ancora |
|------|---------|--------|
| Como capturar | passiva **E** declarada (triangular; o gap é informação) | say-do gap, ESM/EMA |
| Plano no KG | passiva → PROD ("faz"); declarada → DEV ("diz") | reconciliação (Q4) |
| Quanto capturar | parcimônia (reactivity + minimização) | Hawthorne, GDPR Art. 5 |
| Onde o dado vive | local-first; só o predicado sai | Ink & Switch, PCC, rfc-0003 |
| Bruto | nunca sai; não-retenção > cifra | de-identification, GDPR |

## Dogfood

A localidade e os modos de captura vivem em
[`proto/capture-modes.kg.yaml`](proto/capture-modes.kg.yaml) — a máquina `local-bruto → derivado →
compartilhado`/`purgado` (só o derivado exporta; o ciclo fecha em purge), as duas fontes
(passiva/declarada) alimentando a captura, e o gate de localidade como `policy`/`invariant`.

```bash
$ bash .claude/validation/kg-radar.sh docs/discussions/behavior-mapping-kg/proto/capture-modes.kg.yaml
# ══ RECONCILIAÇÃO: REFUTES  C_LOCAL_FIRST → C_CLOUD_FIRST_OK  ("cifra na nuvem basta" refutado)
# ══ RADAR-DE-DOMÍNIO: ✅ camada domain completa (sem lacunas nas 5 checagens)
# ══ INTEGRIDADE: ✅ sem contradições estruturais (19 nós, 20 arestas)  → exit 0
```

---

### Próximas perguntas (não desta nota)

- **Q4** — do sinal bruto ao KG: o que vira `event`/`entity`/`claim`; reconciliar declarado × observado.
- **Q5** — fronteira de produto: feature do Onion pessoal × produto próprio.
