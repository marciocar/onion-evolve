---
title: "P5 — Mitigação de inferência (o motor que lê o grafo é o risco)"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/onion-pessoal-marcio
lente: "Aristóteles (a régua) + Hegel (o motor)"
ancora_pesquisa: research/SYNTHESIS-P5.md
constroi_sobre: [04-privacidade-soberania.md]
---

# 🧵 P5 — Mitigação de inferência

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> **Derivação (camada 2):** consome [research/SYNTHESIS-P5.md](research/SYNTHESIS-P5.md) (~40 fontes, cada dimensão
> verificada adversarialmente); constrói sobre a **P4**, que nomeou a inferência como o **elo sem cifra**.

A P4 fechou as 4 perguntas do SEED e deixou **uma fronteira aberta**: o maior risco de privacidade do Onion pessoal
é o **próprio transformer que o lê** — um LLM sobre o KG deduz o não-declarado (Staab, ICLR 2024). A P5 pergunta:
**como um KG pessoal se defende do motor que lhe dá vida?** A resposta honesta redefine o problema.

---

## O veredito, em uma frase

> **Não há cifra. A inferência interna é feature, não bug — e é indefesa por construção.** Para o **dono**, o motor
> raciocinar sobre o próprio grafo *é o produto*. O perigo só existe quando o resultado **cruza a fronteira** para
> fora. Logo a mitigação **não é impedir o motor de inferir** (impossível, e destrói a feature) — é **governar a
> fronteira de saída e o escopo de cada consulta**, em camadas negativas. Corta ~80%, **não zera**.

---

## 1. A verdade governante — feature dentro, perigo na fronteira

O achado que reenquadra tudo, agora com **prova empírica** (Deng et al., 2026): o conforto com a inferência é
**3,75/5** quando ela serve o dono, **2,34/5** quando vai a terceiros; o "creepy corner" (intrusivo+surpreendente)
despenca a **1,74**. Para o dono, inferir **correlaciona com utilidade** (ρ=0,613). **O dano é o *cruzamento*, não
a dedução.**

E a tensão é declarada **irreconciliável** na literatura de 2025: raciocínio rico e mínima superfície de inferência
conflitam diretamente — *"não se maximiza raciocínio e se minimiza vulnerabilidade sem degradação significativa;
privacidade em tempo de inferência segue fundamentalmente não-resolvida em sistemas implantados."* Capar o motor
mata a feature. **A saída de Hegel:** a contradição não se resolve por um telos ("versão segura final") — **se
contorna**, deslocando a defesa da *redação interna* para a *fronteira de saída*. Não há síntese que dissolva; há
mudança de lugar.

---

## 2. A honestidade dura — o cenário do Onion não tem defesa publicada

Aqui a P5 recusa inventar solução. Aplicando a régua, quase toda defesa forte **resolve o threat model errado**:

| Defesa forte | Contra quem protege | Contra o motor-para-o-dono? |
|---|---|---|
| Capability-split reasoner↔store | modelo **externo** nunca vê o bruto | **NÃO** — o reasoner *é* o motor local do dono |
| TEE / confidential computing | o **operador** do host/nuvem | **NÃO** — ao contrário, **garante a entrega** ao dono |
| DP (inference-time) | adversário de **extração** | **NÃO** — inferência de atributo é *imputação* por correlação; **N=1 é o pior caso** (sem multidão onde se esconder) |
| Machine unlearning | — | **NÃO** — imaturo e contornável; e o fato vive no **store re-consultável** (GraphSteal) |
| Anonimização/ofuscação (FgAA, TRACE-RPS, INTACT) | defender um **release** publicado | **NÃO** — ofuscar o grafo que você **quer** reconciliar é autocontraditório |

> **Toda a literatura assume defender um RELEASE (texto/embedding publicado) ou um adversário externo.** O cenário
> do Onion — o motor **legítimo e local**, agindo **para o dono**, inferindo sobre um KG que **deve permanecer
> legível** — **não tem defesa publicada.** A P4 estava certa: o gap é **nomeado, não resolvido.** E scrubbing de
> PII é comprovadamente inútil aqui — removido todo PII literal, um Llama-3.3-70B recupera idade/gênero/país com
> F1 0,84–0,90, operando sobre **estilo e tópico** que o filtro nunca toca.

Declarar o Onion pessoal "à prova de inferência" seria **falsa distinção às avessas.** Só se pode garantir
**não-EMISSÃO** (o destilado não cruza) e **fronteira de acesso**. A inferência interna é indefesa **por construção
— e isso é a feature.**

---

## 3. Onde a defesa É desenhável: seis camadas negativas na fronteira

A defesa é **negativa** (não dar / não emitir) e começa no **acesso** — a **regra-mãe**: *a saída não consegue
filtrar uma conclusão que nunca foi string.* Modelo executável em
[proto/inference-mitigation.kg.yaml](proto/inference-mitigation.kg.yaml).

| Camada | Mecanismo (fonte) | O que reduz | O que **NÃO** fecha |
|---|---|---|---|
| **L1 — Escopo de consulta** | schema-masking + fatia-da-vertical por propósito (AskSafely); permission-aware retrieval | dá ao motor **só o que o propósito exige** | inferência sobre o liberado; **topologia sensível** (a aresta já vaza) |
| **L2 — Propósito vinculado** | monitor de traço tipado data-category×purpose (C-Trace) | rejeita ação/saída **fora do propósito** | inferência **dentro** do propósito (saúde deduzida de dados de carreira liberados p/ "coaching") |
| **L3 — Filtro por composição** | Camada-2 QI-cluster + CI-CoT | vazamento **por-composição** e literal | conclusão nova nunca-string; **colapsa sob confusão de estilo** (AUROC 0,95→0,72) |
| **L4 — Juiz-de-CI separado** | gerador ≠ porteiro (1-2-3 Check) | o que o gerador (otimizado p/ ajudar) deixa passar | probabilístico (−18/−19pt, não zero) |
| **L5 — Self-red-team** | rodar o **próprio motor como atacante** contra o destilado antes do release (FgAA) | vazamento detectável **pré-emissão** | atacante mais forte que o self-red-team; custo 15–20× |
| **L6 — ε-ledger** | débito monotônico por release (DP-Fusion/DP-ICL) | **reconstrução por repetição** no tempo | N=1 é o pior caso — garantia degrada, custo morde |

---

## 4. O que o Onion já tem que se reaproveita (régua Aristóteles)

A postura do Onion **já é** metade do stack — a arte externa dá o nome técnico:

| Peça Onion | Camada | IGUAL / DIFERENTE |
|---|---|---|
| **`query-gate`** | L1 | **IGUAL** o gesto / **DIFERENTE** — falta schema-masking + fatia-por-propósito (hoje recupera "tudo") |
| **`responder-gated`** | L4 | **IGUAL** (gerador≠porteiro já é doutrina) / **DIFERENTE** — o juiz-de-CI é subagente novo |
| **`de-identification`** (`none` fail-safe) | L3 | **IGUAL** transporte / **DIFERENTE** — só pega formato-fixo; precisa Camada-2 whole-graph-aware |
| **`verify-before-act`** | L2/L5 | **IGUAL** — o monitor de propósito (C-Trace) e o self-red-team ("veredito como hipótese a verificar") já são a postura |
| **ε-budget (P4)** | L6 | **IGUAL** (a P4 já pediu) / **DIFERENTE** — N=1 não tem tratamento publicado |
| **fail-safe `none` / abstain** | L3/L4 | **IGUAL** — "abster para revisão humana" *é* o `none` fail-safe (recusar, não degradar) |
| **`exposes:` + níveis RFC-0003** | L1 | **IGUAL** — aplicados no adapter de recuperação = permission-aware retrieval |
| **disclosure-como-predicado** (SD-JWT/BBS, P3) | L5/L6 | **DIFERENTE / novo** — o release sai como predicado provado |

**A descoberta bonita:** o **self-red-team** (L5) — rodar o próprio motor de inferência como atacante contra o
destilado antes de emitir — **é a doutrina de dogfood do Onion aplicada à privacidade**: "veredito de revisor como
hipótese a verificar com evidência", virado guarda de saída. Se o motor deduz o oculto, **não emite.**

---

## 5. O irredutível e as decisões abertas

**Irredutível:** a inferência do motor legítimo sobre o próprio grafo, para o dono, **não se impede.** Gerenciada
na fronteira, não zerada. Resíduo ~7–8%, garantia **por-resposta, não composta** (N=1 é o pior caso).

**Abertas (engenharia a desenhar, não achado a citar):**
1. **Taxonomia de QI por vertical** (L3 é domínio-dependente; 36% de falso-positivo em finanças) — quem mantém?
2. **Granularidade do purpose-binding** — propósito largo legitima inferência indesejada; quão fino sem matar usabilidade?
3. **ε-ledger em N=1** — por-destinatário? por-vertical? qual ε ainda preserva utilidade sem agregado onde esconder?
4. **Custo do self-red-team** (15–20× por release) — por-release? amostrado?
5. **O juiz-de-CI usa o mesmo modelo ou um SLM capado?** (menos inferência vs julgamento mais grosso)
6. **SSOT único ausente** — ninguém integrou classificação-por-inferência + gate-por-propósito + ε-ledger num só
   mecanismo executável para um life-KG lido pelo próprio LLM.

---

## 6. Honestidade (o fecho)

- **Caveat intra-órbita:** inalterado — a P5 decide *o mecanismo*, não move o north-star. Rodar o próprio motor
  como atacante **é** dogfood do método, não pull externo.
- **A inferência NÃO tem defesa completa — e o doc diz, não inventa.** O único freio conhecido é **negativo**
  (não dar o material) e colide com a utilidade. Declarar o Onion pessoal "privado" **exige nomear esse resíduo.**

---

## O que a P5 fecha (e o que fica)

A P5 **resolve a fronteira aberta da P4 até onde a honestidade permite**: mapeia a defesa desenhável (6 camadas
negativas na fronteira), mostra o que o Onion reaproveita, e **crava o limite fundamental** (a inferência interna é
indefesa por construção — é a feature). O que fica é **engenharia**, não pesquisa: o SSOT único que integra as 6
camadas para um life-KG lido pelo próprio motor. Não é uma P6 de descoberta — é a construção, se um dia o Onion
pessoal sair do papel.

## Dogfood

```bash
bash .claude/validation/kg-radar.sh docs/discussions/onion-pessoal-marcio/proto/inference-mitigation.kg.yaml
```
