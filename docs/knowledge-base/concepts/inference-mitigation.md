# Mitigação de inferência — defender um KG do motor que o lê (doutrina)

> **Categoria:** concepts · **Status:** doutrina (contrato), mecanismo executável NÃO-embarcado (é do adotante — ver §6).
> **Proveniência:** promovida da pesquisa P4/P5 do programa de KG pessoal (~40 fontes, cada dimensão verificada
> adversarialmente). Esta KB é o **frame geral scrubado**; os específicos de qualquer adotante N=1 ficam privados.
> **Irmã:** [`knowledge-graph-sdaal.md`](knowledge-graph-sdaal.md) (o KG que o motor lê) · [`onion-guardrails.md`](onion-guardrails.md) (R15 — o gate de efeito/proveniência).

## O problema — o transformer que lê o grafo é o risco

Quando um KG concentra a verdade de um domínio (uma vida, uma organização, um cliente) e um LLM legítimo o lê para
servir o dono, o maior risco de privacidade **não** é o dado em repouso nem o operador do host — é o **próprio motor**:
um LLM sobre o KG **deduz o não-declarado** a partir de estilo e tópico, não de strings (Staab et al., *Beyond
Memorization*, ICLR 2024 — até 85% top-1). Cifra em repouso e zero-knowledge no transporte são corretos e necessários,
mas **não tocam** esta camada. A inferência é uma capacidade de raciocínio emergente, não memorização (memorização é ~8%
da superfície real — *Privacy Is Not Just Memorization!*, 2025).

## A verdade governante — feature dentro, perigo na fronteira

O achado que reenquadra tudo (Deng et al., *When Are LLM Inferences Acceptable?*, 2026, prova empírica): o conforto com
a inferência é **3,75/5** quando serve o dono, **2,34/5** quando vai a terceiros; o "creepy corner"
(intrusivo+surpreendente) despenca a **1,74**. Para o dono, inferir **correlaciona com utilidade** (ρ=0,613).

> **O dano é o *cruzamento* da fronteira, não a dedução.** Para o dono, o motor raciocinar sobre o próprio grafo *é o
> produto*. Logo a mitigação **não é impedir o motor de inferir** (impossível, e destrói a feature) — é **governar a
> fronteira de saída e o escopo de cada consulta**. A tensão *raciocínio rico × mínima superfície de inferência* é
> declarada **irreconciliável** na literatura de 2025; não se resolve por um telos ("versão segura final"), **se
> contorna** — deslocando a defesa da redação interna para a fronteira de saída.

## A honestidade dura — o cenário não tem defesa publicada

Aplicada a régua, quase toda defesa forte resolve o **threat model errado** (defender um *release* publicado ou um
adversário *externo*):

| Defesa forte | Contra quem protege | Contra o motor-legítimo-para-o-dono? |
|---|---|---|
| Capability-split (reasoner↔store) | modelo **externo** nunca vê o bruto | **NÃO** — o reasoner *é* o motor local do dono |
| TEE / confidential computing | o **operador** do host/nuvem | **NÃO** — ao contrário, **garante a entrega** ao dono |
| DP (inference-time) | adversário de **extração** | **NÃO** — inferência de atributo é *imputação* por correlação; **N=1 é o pior caso** (sem multidão onde esconder) |
| Machine unlearning | — | **NÃO** — imaturo/contornável; o fato vive no **store re-consultável** (*GraphSteal*, 2026) |
| Anonimização (FgAA, INTACT, TRACE-RPS) | defender um **release** publicado | **NÃO** — ofuscar o grafo que se **quer** reconciliar é autocontraditório |

**Scrubbing de PII é comprovadamente inútil aqui:** removido todo PII literal, um Llama-3.3-70B recupera
idade/gênero/país com F1 0,84–0,90, operando sobre estilo e tópico que o filtro nunca toca (*Inferential Privacy
Leakage*, 2026). **k-anonymity/l-diversity/t-closeness falham em grafo denso** (quase-identificadores estruturais
re-identificam). Declarar um KG "à prova de inferência" seria **falsa distinção às avessas**. Só se garante
**não-EMISSÃO** (o destilado não cruza) e **fronteira de acesso**. A inferência interna é indefesa **por construção —
e isso é a feature.**

## As seis camadas negativas na fronteira (o contrato)

A defesa é **negativa** (não dar / não emitir) e começa no **acesso** — a regra-mãe: *a saída não consegue filtrar
uma conclusão que nunca foi string*.

| Camada | Mecanismo (fonte) | O que reduz | O que **NÃO** fecha |
|---|---|---|---|
| **L1 — Escopo de consulta** | schema-masking + fatia-por-propósito (AskSafely); permission-aware retrieval | dá ao motor **só o que o propósito exige** | inferência sobre o liberado; **topologia sensível** (a aresta já vaza) |
| **L2 — Propósito vinculado** | monitor de traço tipado data-category×purpose (C-Trace) | rejeita ação/saída **fora do propósito** | inferência **dentro** do propósito |
| **L3 — Filtro por composição** | 2ª camada QI-cluster + CI-CoT | vazamento **por-composição** e literal | conclusão nova nunca-string; **colapsa sob confusão de estilo** (AUROC 0,95→0,72) |
| **L4 — Juiz-de-CI separado** | gerador ≠ porteiro (1-2-3 Check) | o que o gerador (otimizado p/ ajudar) deixa passar | probabilístico (−18/−19pt, não zero) |
| **L5 — Self-red-team** | rodar o **próprio motor como atacante** contra o destilado antes de emitir (FgAA) | vazamento detectável **pré-emissão** | atacante mais forte que o self-red-team; custo 15–20× |
| **L6 — ε-ledger** | débito monotônico por release (DP-Fusion/DP-ICL) | **reconstrução por repetição** no tempo | N=1 é o pior caso — garantia degrada, custo morde |

## O que o Onion já provê que se reaproveita (régua Aristóteles)

A postura do Onion **já é** metade do stack; a arte externa dá o nome técnico. Reusar o que é **igual**, desenhar
fresh o que é **diferente** — nunca reuso preguiçoso nem reinvenção do maduro
([transfer-heuristic-aristotle](transfer-heuristic-aristotle.md)):

| Primitiva Onion | Camada | IGUAL / DIFERENTE |
|---|---|---|
| **`query-gate`** | L1 | IGUAL o gesto / DIFERENTE — falta schema-masking + fatia-por-propósito (hoje recupera "tudo") |
| **`responder-gated`** (gerador≠porteiro) | L4 | IGUAL (já é doutrina) / DIFERENTE — o juiz-de-CI é subagente novo |
| **`de-identification`** (`none` fail-safe) | L3 | IGUAL transporte / DIFERENTE — só pega formato-fixo; precisa 2ª camada whole-graph-aware |
| **`verify-before-act`** | L2/L5 | IGUAL — monitor de propósito + self-red-team ("veredito como hipótese a verificar") já são a postura |
| **`exposes:` + níveis de trust** (RFC-0003) | L1 | IGUAL — aplicados no adapter de recuperação = permission-aware retrieval |
| **fail-safe `none` / abstain** | L3/L4 | IGUAL — "abster para revisão humana" *é* o `none` fail-safe (recusar, não degradar) |
| **guardrails R15** (efeito-gate + proveniência) | fronteira | IGUAL o gesto — R15 cerca o efeito irreversível; a inferência é o mesmo gate virado para a **saída de conclusão** |

**A descoberta bonita:** o **self-red-team** (L5) — rodar o próprio motor de inferência como atacante contra o
destilado antes de emitir — **é a doutrina de dogfood do Onion aplicada à privacidade**: "veredito de revisor como
hipótese a verificar com evidência", virado guarda de saída. Se o motor deduz o oculto, **não emite**.

## Fronteira core ↔ adotante — quem escreve o quê

Distinção de escopo (decidida em campo, 2026-07-19):

- **A DOUTRINA/contrato é do CORE** — esta KB: o frame das 6 camadas, os limites honestos, o mapa de reúso SDAAL, as
  âncoras de pesquisa. Qualquer adotante de KG-de-vida a **cita**.
- **O SSOT executável é do ADOTANTE** — o mecanismo que integra classificação-por-inferência + gate-por-propósito +
  ε-ledger, rodando sobre o KG **privado**, **nunca** vive no core. Invariante: o KG cru não sai do device/nó
  confiável; o motor local é do adotante (ex.: porta on-device do gate, como o kg-radar multi-runtime de
  [`knowledge-graph-sdaal.md`](knowledge-graph-sdaal.md)). Construir o mecanismo no core violaria a invariante **e**
  seria mecanismo sem consumidor (adotante-KG opera por método-por-referência ou cliente próprio, não por vendorização).
- **Promoção dirigida por dogfood:** cada camada vira doutrina refinada **a partir do uso real** do adotante (o
  de-id v1 → 6 camadas), não à frente dele — a mesma disciplina da promoção dos guardrails R15.

## O irredutível e as decisões abertas (engenharia, não achado)

**Irredutível:** a inferência do motor legítimo sobre o próprio grafo, para o dono, **não se impede**. Gerenciada na
fronteira, não zerada. Resíduo ~7–8%; garantia **por-resposta, não composta** (N=1 é o pior caso). Declarar um KG
"privado" **exige nomear esse resíduo**.

**Abertas (a desenhar no adotante):**
1. **Taxonomia de QI por vertical** (L3 é domínio-dependente; ~36% falso-positivo em finanças) — quem mantém?
2. **Granularidade do purpose-binding** — propósito largo legitima inferência indesejada; quão fino sem matar usabilidade?
3. **ε-ledger em N=1** — por-destinatário? por-vertical? qual ε preserva utilidade sem agregado onde esconder?
4. **Custo do self-red-team** (15–20× por release) — por-release? amostrado?
5. **O juiz-de-CI usa o mesmo modelo ou um SLM capado?** (menos inferência × julgamento mais grosso)
6. **Superfície de metadados do sync** (frequência de commit vaza padrão comportamental) — é esta fronteira na
   camada de transporte; prior-art: git-remote-gcrypt whole-repo, age-wire para interop.

## Referências

- Staab, R. et al. (2024). *Beyond Memorization: Violating Privacy via Inference with LLMs.* ICLR 2024. https://arxiv.org/pdf/2310.07298
- Staab, R. et al. (2025). *Large Language Models are Advanced Anonymizers (FgAA).* ICLR 2025. https://arxiv.org/abs/2402.13846
- *Position: Privacy Is Not Just Memorization!* (2025). https://arxiv.org/pdf/2510.01645
- *Inferential Privacy Leakage in Anonymized Conversational AI Logs* (2026). https://arxiv.org/abs/2605.23820
- Jayaraman & Evans (2022). *Are Attribute Inference Attacks Just Imputation?* https://arxiv.org/abs/2209.01292
- *Truthful Text Sanitization Guided by Inference Attacks (INTACT)* (2024). https://arxiv.org/abs/2412.12928
- *Stop Tracking Me! (TRACE-RPS)* (2026). https://arxiv.org/abs/2602.11528
- *Ask Safely (PrivateNL2CYPHER)* (RCIS 2026). https://arxiv.org/abs/2512.04852
- *Contextual Integrity via Reasoning and RL (CI-CoT/CI-RL)* (2025). https://arxiv.org/abs/2506.04245
- *Capable but Careless (AgentCIBench)* (2026). https://arxiv.org/abs/2606.23189
- *Runtime Compliance Verification (C-Trace)* (2026). https://arxiv.org/abs/2606.19242
- *1-2-3 Check* (2025). https://arxiv.org/abs/2508.07667
- Deng et al. (2026). *When Are LLM Inferences Acceptable?* https://arxiv.org/abs/2605.10013
- *GraphSteal* (2026). https://arxiv.org/abs/2605.28645
