# Panorama crítico de IA e IA Generativa — Junho/2026

> Curadoria + análise crítica das tecnologias que você não pode deixar de conhecer.
> Data de referência: 27 de junho de 2026. Fontes ao final.

## Como ler este documento

Cada tabela traz uma coluna **Classificação de mercado**, com 4 níveis:

- 🟢 **Popular / mainstream** — já é padrão de fato, todo time sério usa ou avalia.
- 🟡 **Em ascensão** — crescimento forte, ainda consolidando; vale apostar.
- 🔵 **Nicho / micro** — uso especializado, alto valor em contexto certo, baixo hype.
- ⚪ **Mosca branca** — raro de se ver bem feito ou subestimado pelo mercado; quem domina sai na frente.

A coluna **Leitura crítica** é onde está o valor: separa o que é real do que é marketing.

---

## 1. Modelos de fronteira (os "players")

| Modelo / Player | Lançamento | Posição (jun/2026) | Classificação | Leitura crítica |
|---|---|---|---|---|
| **Claude Opus 4.8** (Anthropic) | 28/mai/2026 | #1 no índice agregado (Artificial Analysis Intelligence Index v4.0 ≈ 61; Arena Elo ≈ 1545) | 🟢 Popular | Liderança geral e em uso agêntico/raciocínio, mas **perde** para o GPT‑5.5 em benchmarks estritos de engenharia de software. Novo "Fast Mode" ataca o calcanhar histórico da Anthropic: latência. |
| **GPT‑5.5** (OpenAI) | abr/2026 | #2 geral, **#1 em coding estrito** (~59% vs 56,7% do Opus) | 🟢 Popular | Ainda a referência para código e fluxos agênticos de terminal. A disputa virou empate técnico no topo — escolha por caso de uso, não por "melhor modelo". |
| **Gemini 3.1 Pro** (Google) | fev/2026 | #3 geral, **líder multimodal** | 🟢 Popular | Vantagem clara em multimodalidade + cortes agressivos de preço. É a escolha de custo-benefício quando há imagem/vídeo/áudio no fluxo. |
| **Grok 4.3** (xAI) | abr/2026 | Topo de tabela em nichos | 🟡 Ascensão | Forte em alguns benchmarks, mas ecossistema de governança/enterprise ainda atrás dos três grandes. |
| **Qwen 3.7 Max / Kimi K2.6 / MiniMax 3** (China) | 2026 | ~54–57% no índice agregado | 🟡 Ascensão | **A pegadinha do ano**: desempenho a uma fração do custo. Ignorá-los por viés geográfico é erro estratégico — viraram o "default" de quem otimiza custo. |
| **Llama 4** (Meta) | 2026 | Líder do mundo aberto/self-host | 🔵 Nicho | Relevante para quem precisa rodar on-prem, fine-tunar e ter controle total. Perdeu o protagonismo de "SOTA aberto" mas segue base de muita coisa. |

**Veredito da seção:** o conceito de "melhor modelo único" morreu. O padrão de 2026 é **roteamento dinâmico** — escolher modelo por custo, contexto e modalidade dentro do mesmo workflow.

---

## 2. SDKs e frameworks de agentes

| Tecnologia | Para quê serve | Classificação | Leitura crítica |
|---|---|---|---|
| **LangGraph** (LangChain) | Workflows agênticos com estado, ramificação e human-in-the-loop | 🟢 Popular | Maior "production readiness": menor latência, checkpointing, streaming e observabilidade (LangSmith). Default para grafos complexos. Curva de aprendizado real. |
| **Claude Agent SDK** (Anthropic) | Agentes nativos sobre o mesmo harness do Claude Code | 🟢 Popular | Busca por "claude agent sdk" saltou ~50.000% YoY (mai/25 → abr/26). Melhor caminho para agentes Anthropic-native em produção; traz subagents, sessões e MCP de fábrica. Lock-in no ecossistema Anthropic. |
| **CrewAI** | Protótipos multi-agente baseados em papéis | 🟡 Ascensão | Caminho mais rápido para um MVP. Ótimo para prototipar, questionável para alta escala/confiabilidade. |
| **AutoGen / AG2** (Microsoft) | Orquestração conversacional multi-agente | 🟡 Ascensão | Forte em diálogo entre agentes; mais pesquisa/experimentação do que produção enxuta. |
| **OpenAI Agents SDK / Google ADK** | Agentes nativos dos respectivos ecossistemas | 🟡 Ascensão | Adotaram MCP cedo → acesso a 270+ servidores MCP. Bom se você já é "casado" com o provedor. |
| **Pydantic AI** | Agentes type-safe em Python (ergonomia FastAPI) | 🔵 Nicho | ⚪ Quase mosca branca: subestimado, mas a tipagem forte resolve a dor real de confiabilidade que ninguém gosta de admitir. |
| **LlamaIndex Agents** | Agentes ancorados em recuperação (RAG) | 🔵 Nicho | Melhor quando o problema é essencialmente "buscar e fundamentar", não orquestração genérica. |
| **Semantic Kernel** (Microsoft) | Stacks .NET / Microsoft | 🔵 Nicho | Quase invisível fora do mundo .NET, dominante dentro dele. |

**Veredito:** comece pelo problema (estado? papéis? RAG? tipagem?) e não pela marca. LangGraph e Claude Agent SDK são as apostas mais seguras para produção hoje.

---

## 3. Protocolos e padrões de interoperabilidade (a infraestrutura invisível)

| Protocolo | O que padroniza | Classificação | Leitura crítica |
|---|---|---|---|
| **MCP — Model Context Protocol** (Anthropic) | Conexão agente ↔ ferramentas/dados | 🟢 Popular | **Padrão de fato.** 18.000+ servidores indexados; doado à Linux Foundation (dez/2025); suportado por Google, OpenAI e Anthropic. Se você só aprender 1 sigla deste ano, é esta. |
| **A2A — Agent-to-Agent** (Google → Linux Foundation) | Coordenação agente ↔ agente | 🟡 Ascensão | 150+ organizações no 1º ano (Salesforce, ServiceNow, MongoDB...). Camada de "agentes conversando entre si" — complementa o MCP, não compete. |
| **AP2 — Agent Payments Protocol** (Google) | Transações iniciadas por agentes | 🔵 Nicho → ⚪ | 60+ orgs de pagamentos. **Mosca branca com bomba-relógio**: red-teaming acadêmico já mostrou vulnerabilidade a prompt injection. Promissor e perigoso ao mesmo tempo. |
| **ACP — Agent Communication Protocol** (AGNTCY: Cisco, LangChain, LlamaIndex, Dell, Oracle, Red Hat) | Coordenação agêntica REST-nativa | 🔵 Nicho | Filosofia "REST + o mínimo necessário". Alternativa pragmática ao A2A; ainda fragmenta o mercado. |

**Veredito:** o "caos de protocolos" de 2025 convergiu para um eixo claro — **MCP (ferramentas) + A2A (agentes) + AP2 (pagamentos)** — mas ainda fragmentado. Aposte em MCP sem medo; trate o resto como evolução.

---

## 4. Técnicas que mudaram o jogo

| Técnica | O que é | Classificação | Leitura crítica |
|---|---|---|---|
| **Agentic RAG / Reasoning RAG** | RAG embutido em sistemas multi-agente; o modelo decide *quando, o que e como* recuperar | 🟢 Popular | Padrão dominante em RAG empresarial em 2026. Supera o "RAG ingênuo", mas custa mais tokens/latência — nem todo caso justifica. Pergunta-chave: seu problema precisa de raciocínio iterativo ou só de uma boa busca? |
| **SLMs — Small Language Models (1–12B)** | Modelos pequenos para tarefas agênticas específicas | 🟡 Ascensão → ⚪ | **A tese mais subestimada do ano.** Paper da NVIDIA: servir um 7B é 10–30x mais barato que 70–175B. Gartner projeta uso 3x maior que LLMs genéricos até 2027. Para agentes com schema/API fixos, SLM frequentemente *ganha* do LLM gigante. |
| **Speculative decoding** | Modelo "rascunho" pequeno propõe tokens; o grande verifica em paralelo | 🔵 Nicho | 2–3x (até 2,8x) de speedup, já integrado a vLLM e TensorRT-LLM. Invisível para o usuário final, decisivo para custo de inferência. |
| **Diffusion LLMs** | Geração de texto como "denoising" — refina todos os tokens em paralelo em vez de esquerda→direita | ⚪ Mosca branca | Promete quebrar o gargalo sequencial dos LLMs autoregressivos. Ainda experimental, mas é a aposta de pesquisa mais disruptiva para latência. Vale acompanhar de perto. |
| **Quantização (FP8 / INT4 / AWQ / GPTQ)** | Reduzir precisão numérica para caber e rodar mais rápido | 🟢 Popular | FP8 nativo em hardware (Blackwell/Hopper) com qualidade ~indistinguível de BF16. AWQ 4-bit no DeepSeek-V3.2: 2,1x throughput. **Saber a diferença entre FP8/INT8/INT4/AWQ/GPTQ é alfabetização básica de infra em 2026.** |
| **Memória em camadas (≠ vector DB)** | Working memory + sumários + artefatos + preferências de longo prazo | 🔵 Nicho → ⚪ | Verdade incômoda: "memória de agente" não é só jogar tudo num vector DB. Quem trata os dois como sinônimos sofre em produção. |

---

## 5. Infraestrutura, libs e LLMOps (o que sustenta produção)

| Ferramenta / Categoria | Função | Classificação | Leitura crítica |
|---|---|---|---|
| **vLLM** | Engine de serving de LLM de alta throughput | 🟢 Popular | Padrão para servir modelos abertos; já integra speculative decoding. Conhecimento obrigatório para quem opera inferência própria. |
| **ExecuTorch** (Meta) | Inferência on-device / edge | 🟡 Ascensão | GA 1.0 (out/2025), footprint de 50KB, 12+ backends, 80%+ dos LLMs de edge populares "out of the box". O motor da onda **on-device** (latência, privacidade, custo, offline). |
| **Evals (Braintrust, etc.)** | Avaliação orientada a experimentos | 🟡 Ascensão → ⚪ | **A disciplina mais negligenciada e mais importante.** Regra de 2026: teste *trajetórias completas* (escolha de ferramenta + resultado), não só a resposta final. Sem evals, você não tem engenharia — tem aposta. |
| **Observability (Arize Phoenix, Helicone, MLflow)** | Tracing/debug de agentes (OpenTelemetry) | 🟡 Ascensão | Só gera valor se fechar o loop com dev e alertas. Logar em silo isolado é teatro de observabilidade. |
| **Guardrails (Guardrails AI, NeMo Guardrails)** | Garantias estruturais/segurança na saída | 🔵 Nicho | Necessário, mas não substitui evals nem bom design de prompt/permissões. |
| **Vector DBs** (Pinecone, Weaviate, pgvector...) | Busca semântica | 🟢 Popular | Commoditizado. O diferencial migrou do "qual vector DB" para "qual arquitetura de memória" (ver seção 4). |

---

## 6. As "moscas brancas" — o que quase ninguém domina, mas separa os melhores

1. **SLMs para agentes** — o mercado ainda pensa "quanto maior, melhor". Quem desenha pipelines com modelos pequenos task-específicos corta 10–30x de custo. Tese da NVIDIA, endossada pelo Gartner.
2. **Diffusion LLMs** — paralelização da geração de texto. Se vingar, redefine latência. Hoje é território de pesquisa — ótimo momento para entender antes de virar mainstream.
3. **Arquitetura de memória em camadas** — a diferença silenciosa entre um agente de demo e um de produção.
4. **AP2 e segurança de pagamentos agênticos** — fronteira nova, com vulnerabilidades reais já documentadas (prompt injection). Quem entende risco aqui é raro e valioso.
5. **Pydantic AI / type-safety em agentes** — não dá hype, mas resolve a dor nº 1 de produção: confiabilidade.

---

## 7. Síntese crítica — o que realmente importa

**O que mudou de verdade em 2026:** saímos da era do "modelo herói" para a era da **arquitetura**. As decisões de maior impacto não são mais "qual LLM", e sim: roteamento de modelos por custo/modalidade, escolha de SLM vs LLM, qualidade da arquitetura de memória, rigor dos evals, e adoção de padrões (MCP à frente).

**O hype a calibrar:**
- "Agentes autônomos resolvem tudo" — na prática, confiabilidade ainda depende de evals, guardrails e human-in-the-loop. O Computer Use da Anthropic (preview, mar/2026) é impressionante, mas é *research preview* por uma razão.
- "Quanto maior o modelo, melhor" — falso para a maioria das tarefas agênticas; SLMs frequentemente ganham em custo e adequação.
- "Modelos chineses são inferiores" — viés caro: Qwen/Kimi/MiniMax entregam ~90% do topo a fração do preço.

**O que você não pode *não* saber (lista mínima):**
MCP · Claude Agent SDK / LangGraph · Agentic RAG · SLMs · Quantização (FP8/INT4/AWQ) · Evals de trajetória · Roteamento dinâmico de modelos.

---

## Fontes

- [AI Models in June 2026: Claude Opus 4.8 Dethrones GPT-5.5 (Artificial Analysis)](https://renovateqr.com/blog/ai-models-april-2026)
- [Claude Opus 4.8 vs GPT-5.5 vs Gemini 3.1: June 2026](https://pristren.com/blog/claude-opus-4-8-vs-gpt-5-5-gemini-3-1-june-2026/)
- [AI Model Benchmarks Jun 2026 (LM Council)](https://lmcouncil.ai/benchmarks)
- [Best AI Model 2026: GPT-5.5 vs Claude 4.8 vs Gemini 3.5 vs Llama 4 (Stob.AI)](https://stob.ai/blog/best-ai-model-2026-chatgpt-vs-claude-vs-gemini-vs-llama)
- [The best AI agent frameworks in 2026 (LangChain)](https://www.langchain.com/resources/ai-agent-frameworks)
- [Best AI Agent Frameworks 2026: 7 Compared (AliceLabs)](https://alicelabs.ai/en/insights/best-ai-agent-frameworks-2026)
- [Claude Agent SDK in 2026 (Totalum)](https://www.totalum.app/blog/claude-agent-sdk-totalum-2026)
- [Claude Code Guide 2026: 25 Features (MarkTechPost)](https://www.marktechpost.com/2026/06/14/claude-code-guide-2026-25-features-with-examples-demo/)
- [Anthropic Claude Computer Use Agent (Tech Insider)](https://tech-insider.org/anthropic-claude-computer-use-agent-2026/)
- [Anthropic Release Notes — June 2026 (Releasebot)](https://releasebot.io/updates/anthropic)
- [Top 13 Agentic AI Trends to Watch in 2026 (Firecrawl)](https://www.firecrawl.dev/blog/agentic-ai-trends)
- [Reasoning Agentic RAG — Survey (arXiv)](https://arxiv.org/pdf/2506.10408)
- [Small Language Models are the Future of Agentic AI (arXiv)](https://arxiv.org/html/2506.02153v2)
- [On-Device LLMs in 2026 (Edge AI and Vision Alliance)](https://www.edge-ai-vision.com/2026/01/on-device-llms-in-2026-what-changed-what-matters-whats-next/)
- [LLM Quantization Explained: INT4, INT8, FP8, AWQ, GPTQ in 2026 (VRLA Tech)](https://vrlatech.com/llm-quantization-explained-int4-int8-fp8-awq-and-gptq-in-2026/)
- [AI Agents in 2026: Tools, Memory, Evals, and Guardrails (A. Furmanets)](https://andriifurmanets.com/blogs/ai-agents-2026-practical-architecture-tools-memory-evals-guardrails)
- [Agent Interoperability Protocols 2026: MCP, A2A, ACP (Zylos Research)](https://zylos.ai/research/2026-03-26-agent-interoperability-protocols-mcp-a2a-acp-convergence/)
- [A2A Protocol Surpasses 150 Organizations (Linux Foundation)](https://www.linuxfoundation.org/press/a2a-protocol-surpasses-150-organizations-lands-in-major-cloud-platforms-and-sees-enterprise-production-use-in-first-year)
- [Announcing Agent Payments Protocol (AP2) (Google Cloud)](https://cloud.google.com/blog/products/ai-machine-learning/announcing-agents-to-payments-ap2-protocol)
- [Red-Teaming Google's Agent Payments Protocol via Prompt Injection (arXiv)](https://arxiv.org/pdf/2601.22569)
