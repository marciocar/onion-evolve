---
title: "Guardrails Onion — pesquisa de mercado sob a lente Aristóteles (abertura da discussão)"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/guardrails-nemo-lens
source: SEED.md
method: pesquisa orquestrada (fan-out-and-synthesize) — 4 frameworks de mercado + inventário interno → síntese
run_id: wf_66f3bf0d-b80
frameworks_pesquisados: [NeMo Guardrails, Llama Guard, Guardrails-AI, "OWASP Top 10 LLM + NIST AI RMF"]
---

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os outros temas.

# Guardrails Onion — abertura da discussão

Esta discussão nasce de um SEED provocador: o Sistema Onion já **tem** guardrails espalhados por toda a arquitetura (a2a-verify, trust-topology-check, `.claude/validation/*`, never-clobber, metaspec-gate-keeper, camadas de liberação), mas não tem o **nome**, a **moldura** nem a **superfície** que o mercado aprendeu a reconhecer com NVIDIA NeMo Guardrails, Llama Guard e Guardrails-AI. A pergunta não é "o Onion precisa de guardrails?" — ele já os enforça, e em execução/federação enforça melhor que qualquer biblioteca de runtime single-agent. A pergunta é: **vale nomear e consolidar essa camada dispersa sob uma lente reconhecível de mercado, sem trair o diferencial-âncora do Onion — que seus guardrails são determinísticos + gated + spec-as-code, não classificadores probabilísticos?** Este documento PENSA sobre isso; não entrega nada ao core.

---

## Mapa de mercado

| Framework | Categoria | Onde opera | Vocabulário que introduziu | Força central | Limitação central |
|-----------|-----------|-----------|----------------------------|---------------|-------------------|
| **NVIDIA NeMo Guardrails** | Taxonomia + DSL de diálogo | input · diálogo · execução · retrieval · output | `rail` (5 tipos), `Colang`, `canonical form`, `flow`, `intent`, `programmable guardrails` | Vocabulário de 5 rails por MOMENTO do ciclo de vida — a moldura de mercado mais reutilizável; controla diálogo multi-turno como spec declarativa | DSL próprio (Colang) exige engenharia dedicada; +300ms–1.5s/turno; output rail quebra streaming; qualidade do rail depende de exemplos manuais |
| **Llama Guard (Meta)** | Classificador input/output | input (pré-prompt) · output (pós-geração) | taxonomia `S1..S14` (MLCommons), `safe/unsafe + categoria`, `guard model como LLM separado`, falso-positivo como métrica de release | Taxonomia **nomeada e versionada** de risco, auditável e simétrica (mesmo vocabulário in/out); customizável via prompt sem retraining | É um 2º LLM de 7-8B por chamada (custo/latência dobrados); não gerencia fluxo; vulnerável a injection contra o próprio guard |
| **Guardrails-AI** | Validação de output estruturado | output · input (mais fraco) | `Guard`, `Validator`, `Guardrails Hub`, `OnFailAction` (REASK/FIX/FILTER/REFRAIN/NOOP/EXCEPTION/FIX_REASK), `num_reasks` | Vocabulário **nomeado de ação corretiva** (não só pass/fail); Hub de validators plugáveis; FILTER granular por campo | Foco quase só em output de 1 turno; não gerencia diálogo; qualidade heterogênea do Hub; REASK custa chamadas de LLM |
| **OWASP Top 10 LLM + NIST AI RMF** | Taxonomia de risco + processo de governança | input · diálogo · execução · output · retrieval (via rótulos NeMo) | `LLM01..LLM10` (Prompt Injection, Excessive Agency…), `Govern/Map/Measure/Manage`, decomposição de Excessive Agency (functionality/permissions/autonomy) | Vocabulário público mais citado por auditores; NIST dá processo formal de governança; Excessive Agency casa 1:1 com camadas de liberação | Nomeia a superfície, não prescreve o controle; voluntário/alto nível; não nomeia federação (a2a) nem never-clobber |

---

## Lente Aristóteles — igual→transfere / diferente→desenha

> Princípio: onde a natureza é **igual**, transfere-se o nome/moldura/vocabulário direto (é barato e ganha reconhecimento). Onde a natureza **diverge** — sobretudo o eixo **probabilístico (mercado) vs determinístico+gated (Onion)** — o Onion tem que **desenhar o próprio**, porque importar o mecanismo alheio quebraria o diferencial-âncora.

### NeMo Guardrails

- **Igual → transfere:** a **moldura de 5 rails por momento do ciclo de vida** (input/diálogo/execução/retrieval/output) é pura taxonomia, agnóstica de implementação — transfere direto como índice/glossário. O Onion pode rotular cada mecanismo existente por estágio: `a2a-verify` = input+diálogo de federação; `never-clobber` = execution rail; `metaspec-gate-keeper` = output/gate rail. Também transfere o conceito de **forma canônica** ("normalizar a intenção antes de decidir") — o Onion já faz análogo ao classificar intake autônomo × execução gated, e nomear o passo o torna comparável externamente.
- **Diferente → desenha:** o **Colang** e a resolução de canonical forms por **similaridade com exemplos + LLM auxiliar** são probabilísticos e exigem manutenção de exemplos — natureza oposta ao Onion. O Onion **não** deve adotar um DSL próprio: seus "flows" (workflows faseados `plan→pr`, `collect→feature`) já são invariantes do framework, e o gate mecânico é `.sh` determinístico. O próprio aviso de mercado (Colang +300ms–1.5s/turno, streaming quebrado) é **argumento emprestável** para justificar por que o Onion prefere scripts + gates. O que o Onion pode desenhar de próprio: fazer cada flow **declarar pré/pós-condições** que `.claude/validation/` verifique deterministicamente ("este flow respeitou seu contrato") — a ideia de contrato de flow transfere, o mecanismo de verificação é determinístico, não LLM.

### Llama Guard

- **Igual → transfere:** a **taxonomia nomeada e versionada de categorias de risco** (`S1..S14`) é o empréstimo mais valioso. Hoje os guardrails do Onion retornam pass/fail sem vocabulário compartilhado do **tipo** de falha. Um esquema `ONION-R1..Rn` (ex.: R1 escopo-vazamento, R2 credencial-exposta, R3 clobber-de-customização-local, R4 violação-arquitetural, R5 pin-não-confiável) daria trilha de auditoria e comparabilidade entre `a2a-verify`, `trust-topology-check` e `metaspec-gate-keeper`. Transfere também **tratar falso-positivo/negativo como métrica de release** — versionar os gates (`lint`/`selftest`/`inventory`, a2a-verify) com FP/FN documentados a cada mudança, e a **classificação simétrica** (input e output usam o MESMO vocabulário).
- **Diferente → desenha:** Llama Guard **é um segundo LLM classificando por probabilidade do primeiro token com threshold 0.5** — exatamente o que o Onion recusa. O Onion não coloca um modelo-juiz no caminho crítico; seus gates são `jq`/`openssl`/regex/JWS determinísticos (a2a-verify camadas 1-7) ou humano-no-loop (`propose-only`). A **taxonomia** transfere; o **classificador probabilístico** o Onion desenha diferente — a categoria de risco vive em spec-as-code (docs/meta-specs ou KB) e é resolvida por regra determinística ou por abstenção com evidência (REGRA ZERO do metaspec-gate-keeper), nunca por confiança estatística de um guard model.

### Guardrails-AI

- **Igual → transfere:** o **vocabulário de ação on-fail** (REASK/FIX/FILTER/REFRAIN/NOOP/EXCEPTION/FIX_REASK) é um dialeto que falta ao Onion — hoje os guardrails reportam veredito, mas não nomeiam o **tipo de ação corretiva**. `FIX_REASK` (autofix determinístico → revalida → só então escala) mapeia elegante no gate mecânico: regenerar `inventory.md` automaticamente antes de escalar para gate humano é exatamente esse padrão, e o loop "fix → re-dogfood" da doutrina de dogfooding **é** um REASK. `FILTER` granular por campo serve a outputs estruturados do Onion (YAML de contratos de federação, front-matter de ADR). O **Guardrails Hub** como catálogo de validators plugáveis é análogo ao **SDAAL** (adapters plugáveis) — um "hub" de checks reaproveitáveis reduziria duplicação entre a2a-verify/trust-topology-check.
- **Diferente → desenha:** o REASK de Guardrails-AI **re-pergunta a um LLM** (custa chamadas). No Onion, o "reask" é **determinístico ou gated** — autofix por script ou devolução ao maestro humano, não uma nova geração probabilística. O Onion também cobre **execução e federação**, território que Guardrails-AI explicitamente não pisa (é output de 1 turno). Transfere-se o **nome das ações**; o **motor** que as executa é `.sh`+gate, não `num_reasks` contra um modelo.

### OWASP Top 10 LLM + NIST AI RMF

- **Igual → transfere:** rotular cada guardrail Onion com o item **OWASP LLM0X** correspondente (na KB) ganha reconhecimento de auditores sem mudar nada. **Excessive Agency (LLM06)**, decomposto em functionality/permissions/autonomy, casa quase 1:1 com **camadas de liberação** (intake autônomo × execução gated) — vira um checklist de 3 perguntas antes de liberar autonomia a qualquer agente/comando novo. E enquadrar a doutrina "determinístico + gated + spec-as-code" como instância de **Govern→Map→Measure→Manage** do NIST, com `docs/meta-specs/` como artefato de *Govern* e `/meta:context-freshness` como *Manage* executável, é tradução barata para linguagem de compliance.
- **Diferente → desenha:** nenhuma das duas molduras nomeia **federação entre instâncias de agentes (a2a)** nem **never-clobber** — conceitos nativos do Onion sem equivalente público. Aqui o Onion **desenha o próprio vocabulário** (trust topology, entrega-sem-commit/I3, propose-only) e, no máximo, aproxima por mapeamento. OWASP nomeia a superfície mas não prescreve o controle; o `.claude/validation/` **é** o controle determinístico que falta ao lado deles — essa é a contribuição que o Onion tem a mais, não a menos.

---

## Onde o Onion já tem guardrail

Mapeando o inventário interno contra as 4 superfícies (**input | execução | output | federação**):

| Superfície | Mecanismos Onion existentes | Cobertura |
|-----------|-----------------------------|-----------|
| **Federação** | `a2a-verify` (7 camadas: parse→trust→replay→timestamp→SSRF→JWS→never-live-pull) · `trust-topology-check` (policy-as-data) · `members.yaml` · `pin-integrity-check` · `federation-contract-validate.sh` · RFC-0004 §4 (gate tipado único, fail-safe = veto) · entrega-sem-commit (I3) | **Muito forte** — mais robusta que qualquer framework de mercado, que sequer nomeia a superfície |
| **Execução** | `never-clobber` · `durable-commit.sh` · `apply_mode:propose-only` (never-live-pull) · Regra Zero de orquestração (`.filter(Boolean)`, falha parcial explícita) | **Forte** — gates determinísticos + humano-no-loop; equivale a "execution rail" mas real, não declarativo |
| **Meta/arquitetura** | `lint-artifacts.sh` (múltiplas regras HARD) · `lint-selftest.sh` (guarda das guardas) · `inventory.sh`+`inventory.md` (SSOT gerada) · `authorization-layers-intake-vs-execution` (a linha nomeada) | **Forte** — o "gate mecânico" é o dogfood determinístico do core |
| **Output** | `metaspec-gate-keeper` (gated, REGRA ZERO — evidência ou abstenção) · `lint-design-tokens.sh` (WCAG calculado) · `onion-validation` (skill) | **Parcial/pontual** — metaspec-gate-keeper é gated por invocação explícita, não filtro automático de toda saída; design-tokens só cobre a vertical design |
| **Input** | *(quase ausente como categoria nomeada)* — a fronteira intake×execução classifica, mas não há validação de instrução/prompt de usuário antes da execução, análoga a dialogue rail ou classifier | **Lacuna real** — não só de nome |

**Leitura:** o Onion cobre **execução e federação melhor que os frameworks de mercado**, que são bibliotecas de runtime single-agent e nem nomeiam federação/execução multi-agente. Onde o mercado tem vantagem — e o Onion tem lacuna — é **input** (validação de instrução antes de agir) e **output genérico** (filtro automático de toda saída de subagente, não só invocação explícita do gate-keeper). O gap **maior é INPUT/OUTPUT genérico, não federação**, o que refina a leitura do SEED. E o próprio estudo `authorization-layers-intake-vs-execution` (§7) já admite que a linha "não é enforçada uniformemente por um só helper" — corroborando a ausência de uma camada/API unificada.

---

## As 4 perguntas do SEED — posição preliminar (não veredito)

### (1) Guardrail Onion = camada de liberação (intake×execução) formalizada como produto?

**Posição:** parcialmente — a camada de liberação é o **conceito-núcleo** de guardrail do Onion, mas guardrail ⊋ camada de liberação. Evidência: `authorization-layers-intake-vs-execution.md` já é a peça conceitual mais próxima de uma moldura ("receber-verificar-guardar é autônomo; aceitar-aplicar-efeito-de-saída exige gate"), e casa 1:1 com Excessive Agency (OWASP LLM06). Mas ela é **conceitual**, não um catálogo dos mecanismos concretos por placement. Formalizar "guardrail = camada de liberação" capturaria o eixo intake×execução, mas **deixaria de fora** os rails de input (validação de instrução) e de output genérico (filtro pós-resposta). A camada de liberação é o *coração*; a moldura de guardrails é o *corpo* que a inclui e a estende para input/output.

### (2) Como se compara/complementa NeMo (diálogo) / Llama Guard (classificador) / Guardrails-AI (output)?

**Posição:** os três são **complementares por placement, não substitutos** — e nenhum toca federação/execução multi-agente, onde o Onion é forte. Complementaridade:
- **NeMo (diálogo)** → o Onion empresta a **taxonomia de 5 rails** como índice, mas recusa o Colang (probabilístico, custoso); os "flows" do Onion já existem como workflows faseados determinísticos.
- **Llama Guard (classificador)** → o Onion empresta a **taxonomia nomeada de risco** (`ONION-R1..Rn`) e o tratamento de FP como métrica, mas recusa o guard model no caminho crítico — resolve por regra determinística/abstenção.
- **Guardrails-AI (output)** → o Onion empresta o **vocabulário de ação on-fail** (mapeando FIX_REASK ao loop fix→re-dogfood e ao autofix de inventory), mas o motor é `.sh`+gate, não reask a LLM.

A síntese: o Onion não integra nenhum deles literalmente (a analogia "rails" é estrutural, não import de código); **empresta vocabulário e moldura, mantém o motor determinístico+gated**.

### (3) Guardrails por onde — input / execução / output / federação?

**Posição:** o mapa acima mostra que o Onion **já enforça execução e federação com robustez**, tem output **parcial** e input **em lacuna**. A pergunta de cobertura, então, aponta backlog claro para o `/meta:evolve`: rodar um inventário perguntando "para cada guardrail existente, em que estágio ele intercepta?" e usar os buracos (falta um **output-rail canônico pós-resposta de subagente** — análogo a fact-check/PII-scrub, mas determinístico; e um **input-rail** de validação de instrução antes de execução gated) como fios de trabalho. O eixo é: **consolidar o que existe sob a lente de placement primeiro; só então avaliar se input/output merecem novos mecanismos** — e qualquer novo mecanismo tem que ser determinístico ou gated, nunca um classificador probabilístico no caminho crítico.

### (4) Vertical nova (`onion-guardrails`) vs consolidação transversal das existentes?

**Recomendação preliminar: consolidação transversal primeiro — NÃO uma vertical nova.** Trade-offs:

| Opção | A favor | Contra |
|-------|---------|--------|
| **Consolidação transversal** (uma KB `docs/knowledge-base/concepts/onion-guardrails.md` como moldura/índice + taxonomia `ONION-R1..Rn` + rótulos de placement cross-referenciando os mecanismos existentes) | Barato; não reescreve nada; ganha o **nome** e a **moldura** que faltam (gaps 1 e 2 do inventário) sem inflar o framework; respeita "não consolidar workflows invariantes"; dogfoodável de imediato | Não fecha o gap de **superfície** (gap 3 — não cria um `/meta:guardrails` consultável); a moldura sozinha não enforça input/output |
| **Vertical nova `onion-guardrails`** (comando/skill de entrada + camada configurável central) | Fecharia o gap de superfície; daria API consultável análoga a NeMo/Guardrails-AI | Risco alto de inflar o conjunto (o CLAUDE.md alerta contra promover `design-context` a peer sem gate); os guardrails do Onion são scripts+convenções, não uma DSL configurável — forçar uma "camada configurável central" pode importar a complexidade do Colang que a doutrina recusa; guardrail **não é 4ª dimensão peer** (as 3 permanecem produto/engenharia/compliance) |

**Sequência sugerida (gated, sem entrega):** (a) consolidar a moldura + taxonomia nomeada como KB transversal e provar que ela cross-referencia corretamente os mecanismos reais (dogfood: rodar a2a-verify/lint/metaspec-gate-keeper e verificar que cada veredito se mapeia num `ONION-Rn`); (b) só depois de a moldura estar validada, discutir se uma **superfície** (`/meta:guardrails` como índice consultável, não DSL configurável) se justifica — e mesmo aí, como comando de leitura, não como nova vertical peer. O diferencial-âncora manda: o valor do Onion é que os guardrails são **determinísticos+gated+spec-as-code**; uma "camada configurável central" ao estilo Colang/RAIL trairia isso. Consolidar o vocabulário é ganho puro; criar uma vertical é dívida a justificar.

---

## Próximos passos de discussão

1. **Fechar a taxonomia `ONION-R1..Rn` antes de qualquer código.** Puxar o fio: quais são as categorias de risco realmente distintas que os mecanismos atuais já detectam (escopo-vazamento, credencial-exposta, clobber-local, violação-arquitetural, pin-não-confiável, replay, clock-untrusted, SSRF…)? A taxonomia tem que emergir dos vetos que a2a-verify/lint/metaspec-gate-keeper **já emitem**, não ser inventada — dogfood: ler os `{verified:false,gated:true}` reais e agrupá-los.

2. **Auditar cobertura por placement como hipótese, não como fato.** Rodar o inventário "cada guardrail intercepta em que estágio?" e verificar se o gap input/output é real ou aparente — talvez a fronteira intake×execução já cubra input melhor do que o mapa sugere. Tratar o veredito de gap como hipótese a confirmar com evidência (REGRA ZERO aplicada à própria discussão).

3. **Contrato de flow verificável — vale o esforço?** Explorar se fazer cada workflow faseado (`plan→pr`, `collect→feature`) **declarar pré/pós-condições** que `.claude/validation/` verifique é ganho real ou cerimônia. É o empréstimo mais ambicioso do NeMo (flow com contrato) e o que mais arrisca importar complexidade — merece ceticismo.

4. **Superfície: índice consultável vs DSL configurável.** Puxar a distinção fina — um `/meta:guardrails` que só **lista/explica** os guardrails existentes (leitura) é muito diferente de uma camada que os **configura** (o território Colang/RAIL que a doutrina recusa). Decidir onde exatamente fica a linha antes de qualquer proposta.

5. **Falso-positivo/negativo como métrica versionada dos gates.** Discutir se e como o Onion passa a documentar FP/FN a cada mudança de `lint`/`selftest`/`a2a-verify` (empréstimo de Llama Guard) — o que muda no ciclo de dogfood e se isso é sustentável sem virar burocracia.
