# Spec-as-code → spec-as-run → spec-as-all — trajetória do spec-driven development (2025→jul/2026)

> **Pesquisa de mercado + comunidade para o maestro PENSAR sobre a trajetória do conceito de "spec-as-code".**
> Recorte: até julho/2026. Foco na EVOLUÇÃO de "spec gera código" (one-shot) para "spec-as-run" (spec viva/executada
> em runtime) e "spec-as-all" (spec como fonte única; código descartável).
>
> **Natureza:** insumo de evidência para a decisão do maestro — **não decide doutrina**. Cada afirmação material
> tem FONTE (URL + autor/veículo + data). Onde não achei fonte sólida, sinalizei explicitamente. Sem invenção de
> fontes. Prioridade ao recorte 2025-2026 e a vozes primárias (Grove/OpenAI, Karpathy, docs oficiais, arXiv).

---

## Enquadramento útil (a taxonomia da Böckeler)

O vocabulário mais limpo e citável do campo vem de Birgitta Böckeler (Thoughtworks, no site do Martin Fowler,
15/out/2025). Ela separa três ambições crescentes, que mapeiam quase 1:1 no que o maestro pediu:

- **spec-first** — a spec guia a geração e depois é **descartada**; o código volta a ser a fonte. (= *spec-as-code*, one-shot)
- **spec-anchored** — a spec é artefato **vivo, versionado**, e o código é reconciliado contra ela continuamente. (= *spec-as-run* fraco)
- **spec-as-source** — a spec é a **fonte única**; código = saída gerada e descartável ("GENERATED FROM SPEC — DO NOT EDIT"). (= *spec-as-all*)

Tese central da tensão em 2026: quase todas as ferramentas **dizem** mirar o terceiro nível e **operam** no primeiro.

---

## 1. Estado atual do spec-driven development (2025–2026)

O termo "SDD" na sua forma atual, centrada em IA, coalesceu em 2025.

| Ferramenta | Lançamento | O que é "spec" | One-shot ou vivo? |
|---|---|---|---|
| **AWS Kiro** | jul/2025 | 3 markdown: `requirements.md` (user stories + **EARS notation**), `design.md`, `tasks.md` | **spec-first**. Böckeler: specs são *descartadas* após a feature; nova spec por mudança. O mais "leve" dos três. |
| **GitHub Spec Kit** | open-source **02/set/2025** | Fluxo `Constitution → Specify → Plan → Tasks`; cada fase gera markdown; `constitution.md` = princípios inegociáveis | **Aspira a spec-anchored, opera como spec-first**. Blog diz "living, executable artifacts", mas cria **branch por spec** → ciclo preso ao change-request. Funciona com 30+ agentes. |
| **BMAD-METHOD** | comunidade, 2025 | Personas de time ágil (Analyst, PM, Architect, PO, SM, Dev, QA) em markdown+YAML; artefatos = PRDs, arquitetura, stories | **Simulação de time ágil primeiro**, spec-driven "aparafusado". Doc (não código) é a fonte. |
| **Tessl** | Framework + Registry (Série A); private beta | Specs mapeiam p/ arquivos de código com tags `@generate`/`@test`; "vibe-specs"; + Registry de **10.000+ specs** de libs OSS (anti-alucinação de API) | **Único mirando explicitamente spec-anchored E spec-as-source**. Código = "GENERATED FROM SPEC – DO NOT EDIT". |

Definição de consenso emergente (thebcms, IBM): *"SDD = metodologia em que especificações versionadas e estruturadas —
não o código — são a fonte da verdade, e o código é gerado/mantido contra essas specs por humanos e agentes."*
Bordão de 2025–26: **"the spec is the prompt."**

**Honestidade (hype vs. real):** fora Tessl (beta), o que roda em produção é predominantemente **spec-first one-shot
com re-geração manual**. O "artefato vivo reconciliado" é, na maioria, aspiração de marketing.

---

## 2. "Spec as run" / specs executáveis

**Discurso (líderes):**

- **Andrej Karpathy** — "The hottest new programming language is English" (tweet, jan/2023) e keynote
  **"Software 3.0 / Software Is Changing (Again)"** (AI Engineer World's Fair, jun/2025; transcrita na Latent.Space).
  Prompts em linguagem natural *programam* via LLM; "2025–2035 é a década dos agentes". Semente do spec-as-run.
- **Sean Grove (OpenAI)** — talk **"The New Code"** (AI Engineer World's Fair, jun/2025). Tese mais forte do campo:
  *specifications são a unidade fundamental de programação*; specs versionadas "compilam" p/ docs, evals, comportamento
  do modelo e potencialmente o código. Dogfooding: o **Model Spec** da OpenAI (markdown no GitHub) — a correção da
  bajulação (sycophancy) foi feita **editando a especificação, não re-treinando**, e propagou pelo sistema.

**Onde "a spec é o que roda" tem implementação real (não codegen estático):**

- **AgentSpec** (Wang, Poskitt et al., arXiv:2503.18666; **ICSE 2026, Rio, abr/2026**) — DSL leve para *especificar e
  impor restrições em runtime* sobre agentes LLM (triggers + predicados + enforcement). A spec **não gera código; é
  interpretada em runtime** para manter o agente em fronteiras. Exemplar mais literal de "spec-as-run".
- Adjacências que rodam como contrato interpretado por agentes: **MCP**, **ANP** (Agent Network Protocol), ProbGuard.
- **Model Spec da OpenAI** = caso vivo de spec-como-comportamento-de-runtime (o comportamento do modelo *é* a spec renderizada).

**Honestidade:** "spec executável que substitui o código de app inteiro" ainda é sobretudo Tessl (beta) + protótipos.
O que genuinamente *roda como spec-em-runtime* hoje é **governança/segurança de agentes** (AgentSpec) e
**comportamento de modelo** (Model Spec) — não a lógica de negócio de aplicações completas.

---

## 3. "Spec as all" / single-source-of-truth

**Defensores (spec como SSOT de tudo; código descartável):**
- **Sean Grove/OpenAI** — versão mais pura ("specs são a fonte; o resto compila").
- **Tessl** — "spec-as-source": código gerado marcado como não-editável; testes ligados a asserções da spec.
- **Augment Code** — guia *"The Spec as Source of Truth: Why Codebases Should Be Rebuildable from Documentation"*.
- **BMAD** — versão branda: "source code is no longer the sole source of truth — documentation is."

**Críticos (o código continua a fonte):**
- **Thoughtworks / Böckeler** — *rejeita explicitamente* o "specs alone suffice"; código executável continua a fonte
  que precisa manutenção. Compara ao **Model-Driven Development** falido; cunha o alerta *"Verschlimmbesserung"*
  (piorar tentando melhorar).
- **Robert Encarnacao** ("The Emperor's New Code", Medium, 22/jul/2025) — o corte mais afiado: *"no momento em que você
  torna uma especificação precisa o bastante para um computador agir sobre ela, você essencialmente escreveu código."*

---

## 4. Tensões, críticas e reconciliação epistêmica

Limites apontados pela comunidade:
- **Spec drift** (crítica central): no waterfall a spec derrapa porque *ninguém* atualiza; no SDD porque *todos* podem
  atualizar e *ninguém* assume reconciliar mudanças concorrentes. "Quem revisa a mudança de spec? E quando o agente edita
  a spec com algo de que o dev discorda?" (Gojko Adzic é citado sobre o colapso da "living documentation" no BDD.)
- **Não-determinismo do LLM** (Böckeler): p/ geração confiável a spec fica *cada vez mais específica* → vira pseudo-código;
  "você escreveu o programa duas vezes" (over-specification).
- **Verificação / falsa confiança**: casar com spec *errada* não satisfaz requisito; workflows elaborados dão "falso controle".
- **Knowledge drift**: modelos sugerem APIs obsoletas com confiança (Encarnacao).

**Propostas de grafo de conhecimento / reconciliação (implementadas em pesquisa):**
- **Spec Growth Engine** (Hartwig Grabowski, Hochschule Offenburg, **arXiv:2606.27045, 25/jun/2026**) — o achado mais
  relevante para o maestro. Combate "context explosion" + "silent drift" tornando a divergência uma **condição de merge
  bloqueante** (não disciplina). Usa **"spec graph" legível por máquina** (nós em níveis C4: sistema→container→componente→código,
  árvore de ownership + DAG de dependências). Compara um **"Intent Graph"** (dos `SPEC.md`) contra um **"Evidence Graph"**
  (de análise estática); erros duros (código órfão, dependência não declarada, contrato burlado) **bloqueiam o commit**.
  O agente atualiza o delta da spec *no mesmo commit* do código; o arquiteto humano só aprova mudanças de contrato.
  → reconciliação spec↔código automatizada via grafo (exatamente o "grafo + reconciliação" pedido).
- **Semantic Commit** (arXiv:2504.09283) — atualizar *especificações de intenção* mantendo consistência quando novas
  intenções conflitam com as existentes (resolução de ambiguidade em specs de intenção).

---

## 5. Padrões emergentes adjacentes

- **Context engineering** — subiu de "prompt engineering". Prompt = "como pedir"; contexto = "o que o agente sabe, vê e
  lembra no momento da ação" (Atlan; arXiv:2603.09619). "Contexto é o SO do agente." Fórmula do Google: *Agent = Model +
  Scaffold* — valor no scaffold, não no modelo. "Context layer for SDLC" = significado de negócio/lineage fora do código.
- **Agentic SDLC** — ciclo de vida reorganizado em torno de agentes (Port.io; vmblog "7 best agentic SDLC tools 2026").
  SDD frequentemente descrito como a *camada de planejamento/gestão* que faltava aos coding agents.
- **Markdown como novo source code** — Spec Kit, Kiro, BMAD e Model Spec são **todos markdown**. `constitution.md` /
  `ARCHITECTURE.md` como "invariantes transversais" é o revival mais concreto de *literate programming*.
  *(Ressalva: não achei fonte que use o rótulo "literate programming revival" com força — leitura minha do padrão.)*
- Fundamento acadêmico: "Agentic Software Engineering: Foundational Pillars and a Research Roadmap" (arXiv:2509.06216).

---

## Mapa em um parágrafo: para onde o campo vai

O campo migra de **spec-as-code** (Kiro, Spec Kit hoje: spec = prompt estruturado que gera código uma vez e é descartada —
o que *realmente roda em produção* em 2026) para **spec-as-run** (spec como artefato vivo e reconciliado, no limite
interpretada em runtime — real e implementado apenas em nichos: governança de agentes via AgentSpec, comportamento de
modelo via Model Spec, e Tessl em beta para lógica de app), com **spec-as-all** (spec como fonte única de código+testes+docs,
código descartável) ainda **majoritariamente discurso** — potente (Grove/OpenAI, Tessl, Augment) mas contestado de frente
por Thoughtworks ("código continua a fonte") e por críticos que apontam o colapso lógico ("spec precisa o bastante para
executar *é* código") e o drift/não-determinismo não resolvidos. O vetor mais concreto para *pensar a trajetória* é a
**reconciliação epistêmica via grafo** (Spec Growth Engine: Intent Graph vs. Evidence Graph com gate de merge bloqueante) —
que aceita que spec e código vão divergir e faz da reconciliação uma máquina, não uma virtude. Em suma: spec-as-code é
presente; spec-as-run é fronteira ativa; spec-as-all é aposta ideológica cuja viabilidade depende de resolver
drift + verificação + quem-reconcilia — e a resposta mais séria hoje é "grafo de conhecimento + gate determinístico",
não "confie no LLM".

---

## Ressalvas de honestidade

- Datas das keynotes de Karpathy (Software 3.0, jun/2025) e Grove vêm de fontes secundárias/transcrições, não do vídeo primário.
- "spec-as-run" e "spec-as-all" **não** são termos consagrados na literatura; o vocabulário citável mais próximo é o de
  Böckeler (spec-first / spec-anchored / spec-as-source).
- "literate programming revival" é leitura própria do padrão markdown-as-source, não citação de fonte.
- Nenhuma fonte foi inventada; onde não achei, sinalizei.

---

## Sources

1. GitHub Spec Kit — docs oficiais. https://github.github.com/spec-kit/
2. "Spec-driven development with AI: Get started with a new open source toolkit" — The GitHub Blog, 02/set/2025. https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/
3. github/spec-kit (repo). https://github.com/github/spec-kit
4. "GitHub Spec Kit Takes Off as Antidote to Piecemeal 'Vibe Coding'" — Visual Studio Magazine, 12/mai/2026. https://visualstudiomagazine.com/articles/2026/05/12/github-spec-kit-takes-off-as-antidote-to-piecemeal-vibe-coding.aspx
5. Kiro — "Specs" docs. https://kiro.dev/docs/specs/
6. "Beyond Vibe Coding: Amazon Introduces Kiro, the Spec-Driven Agentic AI IDE" — InfoQ, ago/2025. https://www.infoq.com/news/2025/08/aws-kiro-spec-driven-agent/
7. Birgitta Böckeler, "Understanding Spec-Driven-Development: Kiro, spec-kit, and Tessl" — martinfowler.com, 15/out/2025. https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
8. Tessl, "Spec-Driven Development: 10 things you need to know about specs". https://tessl.io/blog/spec-driven-development-10-things-you-need-to-know-about-specs/
9. Tessl, "From code-centric to spec-centric / Why Code Alone Isn't Enough". https://tessl.io/blog/from-code-centric-to-spec-centric/
10. Tessl, "Announcing Our Series A for AI Native Software Development". https://tessl.io/blog/announcing-our-series-a-for-ai-native-software-development/
11. BMAD-METHOD (repo). https://github.com/bmad-code-org/bmad-method — docs: https://docs.bmad-method.org/
12. Sean Grove (OpenAI), "The New Code" — AI Engineer World's Fair, jun/2025 (transcrição). https://lawwu.github.io/transcripts/8rABwKRsec4.html — resumo: https://www.classcentral.com/course/youtube-the-new-code-sean-grove-openai-467279
13. "The end of coding? How specifications are becoming the new source code" — implicator.ai. https://www.implicator.ai/the-end-of-coding-how-specifications-are-becoming-the-new-source-code/
14. Andrej Karpathy, "Software 3.0 / Software Is Changing (Again)" — Latent.Space, jun/2025. https://www.latent.space/p/s3 — tweet (jan/2023): https://x.com/karpathy/status/1617979122625712128
15. Robert Encarnacao, "The Emperor's New Code: Hype vs. Reality of AI 'Executable Specs'" — Medium, 22/jul/2025. https://medium.com/@delimiterbob/the-emperors-new-code-hype-vs-reality-of-ai-executable-specs-ff64d961e8ab
16. Thoughtworks, "Spec-driven development" — Medium. https://thoughtworks.medium.com/spec-driven-development-d85995a81387
17. IBM, "What is Spec-Driven Development?". https://www.ibm.com/think/topics/spec-driven-development
18. "Spec-Driven Development (SDD): The Definitive 2026 Guide" — thebcms.com. https://thebcms.com/blog/spec-driven-development
19. Augment Code, "The Spec as Source of Truth: Why Codebases Should Be Rebuildable from Documentation". https://www.augmentcode.com/guides/spec-as-source-of-truth-rebuildable-codebase
20. Wang, Poskitt et al., "AgentSpec: Customizable Runtime Enforcement for Safe and Reliable LLM Agents" — arXiv:2503.18666 (ICSE 2026). https://arxiv.org/abs/2503.18666
21. Hartwig Grabowski, "The Spec Growth Engine: Spec-Anchored, Code-Coupled, Drift-Enforced Architecture…" — arXiv:2606.27045, 25/jun/2026. https://arxiv.org/html/2606.27045
22. "Semantic Commit: Helping Users Update Intent Specifications…" — arXiv:2504.09283. https://arxiv.org/pdf/2504.09283
23. "Context Engineering: From Prompts to Corporate Multi-Agent Architecture" — arXiv:2603.09619. https://arxiv.org/pdf/2603.09619
24. Atlan, "Context Layer for SDLC: Guide for AI Coding Agents [2026]". https://atlan.com/know/ai-agent/context-layer-for-sdlc/
25. Port.io, "The Agentic SDLC: The Software Lifecycle, Rebuilt Around Agents". https://www.port.io/blog/agentic-sdlc-software-lifecycle-rebuilt-around-agents
26. "Agentic Software Engineering: Foundational Pillars and a Research Roadmap" — arXiv:2509.06216. https://arxiv.org/pdf/2509.06216
