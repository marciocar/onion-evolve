---
title: "Veredito Elenxo — /meta:guardrails é índice-de-leitura ou DSL? (Q_INDEX_VS_DSL)"
category: discussion
status: veredito-elenxo-ratificavel
date: 2026-07-31
branch: discuss/guardrails-nemo-lens
method: "Elenxo orquestrado (fan-out-and-synthesize + verificação adversarial) — 10 workers: 3 steelman (sonnet/medium) → 6 refutação multi-lente (opus/high) → 1 síntese (opus/high)"
run_id: wf_15cebeba-773
kg: docs/onion/graph/guardrails-2nd-pr-state-2026-07.kg.yaml
---

# Veredito Elenxo — Q_INDEX_VS_DSL

> ## ⚑ ADENDO — Spike 2026-07-31 (SUPERSEDE a recomendação abaixo)
>
> O Elenxo condicionou o índice a "**promoção GANHA por dogfood**". O dogfood rodou (spike:
> grep-pelado vs. lente em `product/task.md` e no canal C2) e a promessa **não se pagou**:
> - **Forward (categoria→vetos):** grep que o maestro já tem; lente-viva só sobrepõe o lint.
> - **Resolução-de-canal:** carrega peso, mas a resposta **já vive na KB §4.1/4.2**.
> - **Join-reverso:** único gap real, MAS **não há escopo machine-readable por guarda** →
>   hand-curar tabela **drifta** (a ironia que mata a doutrina) ou instrumentar 48 guardas (churn).
>
> **Veredito pós-spike (nó `D_NO_COMMAND`): NÃO construir `/meta:guardrails` como comando.** Os
> guardrails já rodam (48 gates+selftest) e já são navegáveis (grep + taxonomia + tabela-canal). Fio #4
> **fechado como resolvido-sem-comando**. O join-reverso fica deferido atrás de uma decisão maior
> (guardas self-declararem escopo — nó `Q_REVERSE_JOIN_SCOPE`), gated na demanda real (hoje N=0).
> A análise índice-vs-DSL abaixo permanece **válida e útil** (por que não-DSL, por que não-híbrido),
> mas a conclusão operacional é **não-construir**, não "construir o índice".

# (análise original — índice-vs-DSL)

> **Projeção do grafo, não fonte paralela.** O SSOT desta decisão é
> [`guardrails-2nd-pr-state-2026-07.kg.yaml`](../../onion/graph/guardrails-2nd-pr-state-2026-07.kg.yaml)
> (nós `D_INDEX_FORTIFIED`, `E_DSL_REFUTED`, `E_HYBRID_REFUTED`, `E_INDEX_LIVE_LENS`,
> `Q_AUTHORING_TRIGGER`). Este markdown é a leitura humana.

## A pergunta

`/meta:guardrails` — a **única** superfície que falta da camada de guardrails do Onion (todo o
resto entregue: helpers R15, wire-in PR #452, anti-drift por construção) — é um **índice-de-leitura**
(navegador sobre os gates que já rodam) ou uma **DSL** (linguagem para definir guardrails)? 3ª via: **híbrido**.

## O método

Elenxo orquestrado: steelman das 3 posições → refutação adversarial por 2 lentes independentes
(doutrina Onion; estado-vivo + mercado) → síntese que pesa os **sobreviventes**, não a eloquência.

## Veredito: **ÍNDICE-DE-LEITURA** — mas o índice **FORTIFICADO** (lente-viva), não o espelho-de-snapshot

O eixo índice-vs-DSL **foi decidido pela evidência, não pelo maestro** — DSL e Híbrido não
sobrevivem como proposições vivas hoje:

- **DSL — refutada nas duas lentes.** Inverte `estrutural > gated` (move a lógica de decisão do
  gate — hoje verbos hardcoded no `.sh`, selftestada — para dado de config autorado, fora da
  superfície testada pelo `lint-selftest`). Só sobrevive satisfazendo condições que **não valem
  hoje**: `effect-gate` é protótipo em quarentena **não-wired**; **N=0** demanda de campo por
  autoria; sua evidência-âncora até **descreve errado** o artefato vivo (é whitelist
  INTAKE/EXECUTION + `unknown→gate`, deny-by-default **já** em bash). Genuinamente **deferida**.
- **Híbrido — refutado com confiança ALTA (doutrina).** Sua metade distintiva (Fase B = compilador)
  repousa numa **transferência falsa**: a catraca `REGRA 42` **não** é "declaração compila para gate"
  — é **dado tipado** consumido por um **runner fixo escrito à mão** (zero codegen). A Fase B só
  sobrevive colapsando até **deixar de ser** DSL/compilador — e então **dissolve no índice**. Seu
  próprio custo confessa que o compilador exige **disciplina de revisor a cada PR** — o exato
  anti-padrão que a discussão existe para matar.
- **Índice — também refutado nas duas lentes, MAS** suas condições de sobrevivência **convergem numa
  única forma construível que o ELEVA**: do tier mais fraco (declaração/README) ao tier
  determinístico (grep + verdade formato-exit) que a doutrina endossa. O espelho-de-snapshot **é**
  refutado (a taxonomia é snapshot 2026-07-12 de 148 vetos/14 categorias, e o lint **já** está em
  `REGRA 48` — ~20 regras nasceram depois, sem categorização; o snapshot **já driftou**).

O centro de gravidade: a sobrevivência da DSL **e** a do Híbrido **terminam ambas** em "índice agora
+ autoria genuinamente deferida". Logo vence o índice.

## A forma concreta (3 propriedades não-negociáveis que as refutações forjaram)

Comando `/meta:guardrails [categoria|canal|arquivo|termo]`, **só-leitura**, nascido **atrás** do gate
anti-drift da Fase 1 do promotion-plan:

1. **Lente-viva, não espelho.** A direção forward (categoria Rn → vetos) resolve por **grep AO VIVO**
   contra os próprios scripts de gate (`.claude/validation/*`, `guardrails/onion-effect-gate.sh`,
   `a2a-verify`, `metaspec-gate-keeper`) pela string de veto emitida, reportando
   **CONFIRMADO/DIVERGENTE** contra o read-path. **Nunca** apresenta linha da `taxonomy-onion-r.md`
   como verdade vigente — a taxonomia vira **companheira só-humana**, jamais fonte-de-dado do comando.
2. **O código próprio é só o que um grep único NÃO entrega** — a **estrutura**: o **join reverso**
   (arquivo/termo → categorias que cobrem) e a **resolução de canal** (C1/C2/C3 → R15.3a/R15.1/R15.2).
   É o valor genuíno que **ambas** as refutações concederam ser real.
3. **Toda linha ecoada é RE-PROVADA** contra o código vivo no momento da chamada
   (behavior-over-declaration virado mecânico); **nenhum veredito PASS/FAIL novo** é cunhado
   (enforcement fica 100% nos gates reais).
   - **Restrição de correção (não escolha):** o re-grep de verificação **É** o mesmo mecanismo do
     gate anti-drift da Fase 1, apontado aos read-paths dos guardrails — construir como **UM**, não dois.

## Dissent (a objeção sobrevivente mais forte CONTRA a recomendação)

Uma vez lente-viva pura, a direção forward colapsa em `grep -rn "ONION-R\|violation(" .claude/validation/`
— que o maestro **já tem**. A **única** novidade carga-relevante é o **join reverso + resolução de
canal**. Se, no dogfood, essas duas peças se provarem magras, o deliverable honesto é um
**helper/companheira-de-KB, NÃO um comando promovido**. **A promoção só se paga se ganhá-la por
dogfood** — não assumida.

## O que fica com o maestro — só o EIXO 2

O EIXO 1 (índice fortificado, só-leitura, atrás da Fase 1) está **assentado pela evidência — só
ratificar**. Resta **uma** escolha genuinamente sua, e `gated-work-derives-fresh` **proíbe
pré-cozinhar** a forma do compilador:

> **EIXO 2 — o gatilho para reabrir autoria/DSL algum dia:**
> **(a)** autoria fica **FECHADA** até materializar demanda de campo concreta (≥N guardrails
> recorrentes de adotantes reais do `members.yaml` que provadamente **não** sejam append a
> INTAKE/EXECUTION nem um `.sh` determinístico fresco), **re-derivada FRESCA** então; **ou**
> **(b)** sancionar desde já um **scaffold-generator** (emite stub `.sh` editável + fixture de
> selftest para um humano completar sob `/engineer:plan`, estilo `/meta:create-command` — **jamais**
> um compilador em runtime).
>
> Ambos defensáveis; ambos ficam **fora** da "camada configurável central". A evidência que decide é
> factual e checável: **quantos adotantes reais pediram autoria — hoje, zero.**

## Tradeoffs honestos

- Valor **modesto e pouco "vendável"** vs. o paralelo de mercado (Colang/RAIL) — transfere
  vocabulário, não motor; o pedido do SEED "tão prático quanto NeMo" fica **parcialmente** não-cumprido.
- **Não** responde "como declarar um guardrail novo padronizado" — adia (corretamente, dado N=0).
- O grep-ao-vivo **acopla** o comando às strings exatas dos gates — churn de string = report
  DIVERGENTE (feature: expõe drift; mas é superfície de manutenção, e deve andar no **mesmo** re-grep
  da Fase 1).
- A fronteira "sem modo de authoring" é **doutrinária, não auto-executável** — exige vigiar que
  ninguém reintroduza authoring por conveniência.

---

## 🔒 Autoria de guardrail pelo usuário — a REGRA pull-not-push (2026-07-31)

> **SSOT no grafo:** nós `D_GUARDRAIL_PULL_NOT_PUSH`, `E_PRIMITIVE_EXISTS`, `E_HOOK_SUBSTRATE`,
> `Q_AUTHORING_TRIGGER`(done). Origem: demanda do maestro — "guardrail à frente de agente/skill
> (tema/palavras/escopo)?" + o precedente Gustavo P7.

**REGRA:** autoria de guardrail se **PUXA por caso concreto recorrente**, nunca se **EMPURRA por hipótese.**

1. **O primitivo determinístico JÁ EXISTE e funciona:** `projection-safety.sh --terms` (adotante
   declara os próprios termos → gate `exit 1`, fail-loud P0–P5), dogfoodado no **Gustavo P7**
   (gate client-safe: adotante declara nomes de cliente, gateia artefato antes da fronteira).
   **Não construir camada.**
2. **Caso concreto aparece** → fiar **à mão ~15 min** (`PostToolUse`/`UserPromptSubmit` → tmp →
   `projection-safety --terms`), fresco e descartável.
3. O scaffold `/meta:create-guardrail` **só se paga** após o **mesmo** padrão ser fiado à mão **2–3×**
   (o boilerplate vira o peso morto que o justifica) — `gated-work-derives-fresh` até lá.
4. **NUNCA por padrão:** gate de **tema** (determinístico impossível → soft-only, invariante #3) nem
   gate **por-agente no input** (`tool_input` carregar o prompt do subagente é **não-verificado** →
   uma **Fase-0** teste-empírico-de-5-min é o gate, não dívida).

**Design de referência (se/quando puxado — não é plano):** placements verificados —
`UserPromptSubmit`(input, sessão) · `PostToolUse`(output = análogo exato do Gustavo) · `PreToolUse`
matcher `Agent`/`Skill`(por nome). Motor = o `projection-safety.sh` existente + um modo stdin (pequeno).
Os três medos do maestro — não-funciona / ineficiente / ineficaz — matam, respectivamente: o gate
por-agente-input (não-verificado), o comando/DSL para N=2 (cerimônia), e o gate de tema (soft≠trava).
