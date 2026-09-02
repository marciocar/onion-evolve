# Mercado + Capital: sinal de verdade para o Onion (worker lens-market, opus, web, 2026-09-02) — PARCIAL (bloco 1)

Bottom line do worker: o eixo tem sinal forte e datado. Três institucionais independentes convergiram em 2026 para a tese do Onion (contexto curado + controles determinísticos + grafo temporal) e o capital migrou de "gerar código" para "governar agentes". Achado adversarial: Thoughtworks pôs **agent instruction bloat** em CAUTION — descreve as 52k linhas de markdown do core.

## 1. Analistas e órgãos de referência
| Fonte (data) | Achado | Implicação |
|---|---|---|
| Thoughtworks Radar vol. 34 thoughtworks.com/about-us/news/2026/combat-ai-cognitive-debt-radar-v34 (2026-04-15) | temas "colocar agentes de código na coleira", "reter princípios, abandonar padrões"; cognitive debt | o tema central do Radar É a doutrina do Onion; vocabulário institucional pronto |
| Radar v34 Techniques (04/2026) | ADOPT: context engineering, curated shared instructions for software teams. TRIAL: Agent Skills, feedback sensors, sandboxed execution, progressive context disclosure | CLAUDE.md curado virou ADOPT institucional |
| Context graph — ASSESS (04/2026) thoughtworks.com/radar/techniques/context-graph | decisões/políticas/exceções/precedentes/evidências como nós; validade temporal em cada aresta; fato superado é invalidado, não sobrescrito; distinto de GraphRAG | descrição quase literal do KG do Onion; nome externo para NS1; valida superseded sobre editar |
| Agent instruction bloat — CAUTION (04/2026) thoughtworks.com/radar/techniques/agent-instruction-bloat | AGENTS.md/CLAUDE.md acumulam regras longas e contraditórias; atenção cai no meio do contexto; escritas à mão batem geradas | 🚩 risco direto ao core; cura: progressive context disclosure, conjunto mínimo e coerente |
| Spec-driven development — ASSESS | workflows elaborados e opinativos, specs longas difíceis de revisar, "relearning a bitter lesson" | SDD não é ADOPT; o diferencial é spec VERIFICÁVEL por máquina |
| Gartner Hype Cycle for Agentic AI (via tray.ai; relatório 2026-04-02) | inaugural; 17% implantaram, 42% em 12 m; governança/segurança/custo viraram perfis; >40% dos projetos agênticos cancelados até 2027; "agent washing" | governança determinística vira critério de compra |
| Forrester Predictions 2026 (sdtimes, 2025-10-28) | "observability as code e governance as code adotados por 80% dos times"; vibe coding → vibe engineering | a previsão mais alinhada: gates versionados = governance as code |
| Stack Overflow (survey 2025; análise 2026-02-18) | 84% usam IA, ~29-33% confiam, 3% muito; 66% "quase certo, mas não"; 45% depurar demora mais | o gap é VERIFICAÇÃO, não geração — o mercado do Onion |
| YC W26 (extruct.ai/research/ycw26) | 199 empresas, ~60% IA; 41,5% agent infrastructure (28,7% no W25); dev tools 13-17% | andar de baixo lotado; diferenciar pelo de cima (doutrina + grafo) |
| YC RFS | pede "Multiplayer AI" e ferra… (truncado — continuação pendente) |
| YC RFS ycombinator.com/rfs | pede "Multiplayer AI" e ferramentas que provem que devs/enterprises dão acesso ao codebase | sessões persistentes e federação do Onion batem no RFS atual |

## 2. Capital (12 meses) — siga o dinheiro
| Data | Empresa | Evento | Valor | Sinal |
|---|---|---|---|---|
| 2026-06-16→08-14 | Anysphere/Cursor | aquisição pela SpaceX (SpaceXAI), fechada | US$60B all-stock (cursor.com/blog; cnbc 2026/06/16) | camada de IDE CONSOLIDOU: ativo estratégico de outra indústria |
| 2026-05-27 | Cognition (Devin+Windsurf) | rodada Lux/GC/8VC | US$1B a US$26B; ARR 492M (techcrunch) | agente autônomo não esfriou (2,5x em 8 m); Devin escreve 89% do próprio código |
| 2026-03-12 | Replit | rodada | US$400M a US$9B (siliconangle) | capital ainda entra no topo |
| 2025-12-02 | Sourcegraph → Amp | spin-out, Amp Inc. lucrativa | n/d (sourcegraph.com/blog) | code search legado não sustenta agente de fronteira |
| 2026-01 | Langfuse | ADQUIRIDA pela ClickHouse (Série D US$400M a US$15B) | n/d | observabilidade de agente virou feature de banco |
| 2026-02 | Braintrust | Série B ICONIQ | US$80M a US$800M | evals é categoria financiada e ESCASSA |
| 2025-10 | LangChain (LangSmith) | Série B | US$125M a US$1,25B | orquestração+eval capitalizada |
| 2026-02 | Potpie | pre-seed | US$2,2M | codebase→KG (Neo4j) já recebe dinheiro |
| 2026-02 | Cognee | rodada | €7,5M | memória-como-grafo virou wedge financiável |
| 2026 | Graphon AI | seed Samsung Next/Hitachi | US$8,3M | "camada de inteligência pré-modelo" = memória relacional persistente |
| 2026-03 / 06-30 / 08-13 | UiPath / CSA STAR Registry / Cursor | AIUC-1 (1ª certificação; entra no STAR; Cursor obtém) | — | certificação de agente virou selo de compra enterprise (cloudsecurityalliance.org press 2026/06/30) |
ESCASSO (capital concentrando): verificação, evals, governança auditável, memória temporal. VIROU FEATURE DE OUTRO (não construir): observabilidade/tracing, autocomplete, orquestração multi-agente (Agent HQ, Copilot app Build 2026, swarms do Cursor). TESE QUE CAIU: IDE proprietário como fosso.

## 3. Big techs e líderes
| Fonte (data) | Posição | Implicação |
|---|---|---|
| Anthropic Eng, "Harness design for long-running application development" (2026-03-24) | initializer lê a spec e converte em LISTA DE TAREFAS PERSISTENTE; "todo componente do harness assume que o modelo não sabe algo; essas suposições EXPIRAM" | valida workflows faseados retomáveis; critério de PODA: instrução por limitação vencida sai |
| Anthropic, "How we built Claude Code auto mode" (2026-03-25) anthropic.com/engineering/claude-code-auto-mode | classificador em 2 estágios; admite 17% de FALSO-NEGATIVO em ações perigosas; "julgamento humano continua essencial" | 🎯 defesa numérica do exit 2 determinístico: o caminho probabilístico erra 1 em 6 |
| Anthropic, "An update on recent Claude Code quality reports" (2026-04-23) | postmortem público de degradação | re-medir a cada update é obrigação |
| Anthropic, "Scaling Managed Agents" (2026-04-08); "C compiler with parallel Claudes" (2026-02-05) | multi-agente / cérebro-mãos como padrão de casa | orquestração do Onion na linha oficial |
| Claude Code comercial (agregadores; NÃO-VERIFICADO) | ~US$2,5B ARR 02/2026; >50% enterprise; ~54% do mercado enterprise vs ~21% OpenAI | substrato lidera; pagante é enterprise |
| Ecossistema de plugins (04-05/2026) | 100+ plugins oficiais, 4.000+ skills, 770+ MCP servers, 2.500+ marketplaces | janela ABERTA mas SATURANDO: curadoria vence volume; Fase 5 do marketplace tem prazo |
| GitHub/Microsoft: Agent HQ (11/2025), Claude+Codex (2026-02-04), Copilot app Build (2026-06-02) github.blog | mission control multi-vendor | orquestração virou commodity de plataforma |
| Amazon Kiro | specs como unidade de trabalho (EARS) | SDD virou produto de big tech: commodity |
| OpenAI Codex | >2M usuários semanais 03/2026 | pressão de plataforma, não de doutrina |

## 4. Sinal vs hype
ESFRIARAM: vibe coding como categoria (Forrester → "vibe engineering"; Radar v34 pôs "coding throughput como produtividade" em Caution; Phind fechou — agregador); MCP em tudo ("MCP by default" em CAUTION no Radar v34); IDE proprietário como fosso.
SUBIRAM: harness engineering (disciplina nomeada); governança e certificação de agente (Hype Cycle, AIUC-1, Forrester 80% governance-as-code); grafo temporal de contexto ("context graph" em Assess; Cognee/Potpie/Graphon/Zep financiados).

## 5. NÃO reinventar
observabilidade/tracing (ClickHouse/Braintrust/LangSmith); orquestração multi-agente ("coding agent swarms" em Caution); sandbox/permissões (auto mode, sandboxed execution Trial) — consumir o primitivo, o valor é o veto ACIMA; scaffolding de spec (Kiro, spec-kit); certificação (AIUC-1).
## 6. Onde o Onion lidera — NÃO abandonar
1. exit 2 determinístico (17% FN do classificador da própria Anthropic; único que barra sob bypassPermissions). 2. Grafo com validade temporal (context graph só em ASSESS; liderança de 1-2 ciclos). 3. Dogfood como gate de release. 4. Governance-as-code real (regras numeradas, catraca, lint no CI). 5. Compliance como dimensão peer.
CONTRA-SINAL: "agent instruction bloat" em CAUTION (Radar v34) descreve as 52.655 linhas de markdown do core; cura = progressive context disclosure (Trial) MECANIZADA: skills sob demanda em vez de doutrina sempre carregada.
## 7. Fontes que valem rotina
SEMANAL: anthropic.com/engineering + changelog do Claude Code (gatilho de re-medição); cursor.com/blog; TechCrunch/CNBC filtrados por M&A "AI coding"; HN Algolia por trajetória. MENSAL: State of AI newsletter (Benaich); a16z Big Ideas/"Notes on AI apps"; YC RFS. TRIMESTRAL: Thoughtworks Radar (abril e novembro — maior densidade por palavra); Menlo State of GenAI in the Enterprise; Gartner Hype Cycles; composição do batch YC. ANUAL: Stack Overflow Survey; State of AI Report; Forrester Predictions (outubro).
## 8. NÃO-VERIFICADOS
SO Survey 2026 (aberta 06-23, sem resultados — números são de 2025); State of AI Report 2026 (não publicado); Gartner 403 (números via terceiro; MQ 2026 não obtido); quedas de tráfego Lovable/v0/Bolt e aquisições Supermaven/Continue/Base44/Fine.dev (agregador único); ARR Claude Code e fatias 54/21 (agregadores); Menlo só 2025 (coding = US$4,2B); posições de Cat Wu/Thariq não localizadas; Boris Cherny só via terceiros ("build for the model six months from now").
