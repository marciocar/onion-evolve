# Estado da arte: deep research agents + memória em grafo temporal (worker lens-sota, opus, web, 2026-09-02)

## A. Deep research de referência
| Fonte (data) | Achado | Implicação |
|---|---|---|
| Wikipedia, ChatGPT Deep Research (verif. 09-02) | fev/2025 em o3; migrou p/ GPT-5.2 em fev/2026; restrição a sites confiáveis, conectores MCP, steering; OpenAI admite "pode referenciar rumores" | Restringir busca por lista de domínios confiáveis é feature de 1ª classe; cabe no .kg.yaml como campo de tiering |
| Anthropic, "When to use multi-agent systems" claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them (2026-01-23) | 3 gatilhos (contexto, paralelização, especialização); 3-10x tokens; falhas "Early Victory" e "Telephone Game"; decompor por CONTEXTO, não por tipo de tarefa | Fatiar por eixo de evidência; gate anti-Early-Victory (verificador exige contagem de evidência) |
| Anthropic multi-agent research (via bytebytego, secundário) | orquestrador-worker; plano salvo em memória externa; +90,2% sobre single Opus 4; ~15x tokens | Persistir plano fora do contexto: o .kg.yaml já é essa memória |
| Google Deep Research / Deep Research Max blog.google (2026-04-21/22) | dois tiers (latência vs test-time compute); Max 93,3% DeepSearchQA, 54,6% HLE; MCP+File Search | Tiering de esforço por fase, não por preço |
| Perplexity, Search as Code research.perplexity.ai (2026-06-01) | agente escreve Python que faz fan-out/dedup/filtro/ranking ANTES do contexto: 2,5x, -85% tokens | Filtrar fora do contexto é a maior alavanca de custo; o lint do Onion é a versão local |
| Perplexity, WANDR (2026-07-14) | 500 tarefas; correção reference-free re-busca a página citada; líder 0,363 soft F1 / 0,133 hard F1; Anthropic 2º | Cobertura completa ~13% mesmo nos líderes: lacuna vira nó, não omissão |

## B. Infra de busca (siga o dinheiro)
| Fonte | Achado | Implicação |
|---|---|---|
| Tavily adquirida pela Nebius 2026-02-10, até US$400M (275M à vista) — resumo secundário (medium) | Busca agêntica virou ativo de nuvem | Não acoplar a provedor único: SDAAL para busca |
| Exa Série C mai/2026 US$250M (a16z), US$2,2B; índice 1,4T URLs (exa.ai, fornecedor) | Índice próprio é o escasso | Fonte de índice = dependência estratégica, nó com revisita |
| Brave Search API (via parallel.ai, concorrente) | free tier eliminado fev/2026; ~US$5/1k; cartão sem teto | Custo de busca não é zero: orçamento por pesquisa obrigatório |
| Parallel US$1/1k, MCP grátis; Firecrawl/Tavily/Exa com MCP oficial (blogs de fornecedores) | MCP virou tabela de entrada | Adapter de busca com transporte MCP opcional (igual task-manager) |
| Firecrawl Série A US$14,5M (ago/2025); Mem0 US$24M (out/2025, prnewswire) | Memória capitalizada 1 ordem abaixo de busca | Memória é commodity; valor está no que se GUARDA |
Aviso de tiering: quase toda comparação de preço vive em blog de concorrente direto — reconferir no fornecedor antes de decidir.

## C. KG temporal e conflito de memória
| Fonte | Achado | Implicação |
|---|---|---|
| Zep/Graphiti arXiv 2501.13956 (jan/2025) | bi-temporal: T do evento, T' da ingestão; valid_from/valid_to/invalid_at; invalidação por contradição não-destrutiva | .kg.yaml precisa das DUAS datas: quando o fato passou a valer e quando EU verifiquei |
| STALE arXiv 2605.06527 (2026-05-07) | 400 cenários; melhor modelo 55,2%; falha dominante "Conflito Implícito" | Nunca delegar obsolescência ao julgamento em runtime: precisa de regra |
| "Don't Ask the LLM to Track Freshness" arXiv 2606.01435 (2026-05-31, rev 08-02) | extrair evidência ≠ executar política (+10,8 pts); BM25 + resolução determinística bate KG temporal elaborado; limite: só p/ perguntas de valor-corrente com metadado explícito (LongMemEval p=0,45) | Endosso ao desenho Onion (metadado explícito + regra determinística) e delimita onde NÃO ajuda |
| MemStrata 2606.26511, TOKI 2606.06240 (jun/2026) | supersessão determinística em ledger bi-temporal; álgebra bitemporal | Supersessão é operação nomeada, não edição de arquivo |
| LazyGraphRAG (Microsoft) | GraphRAG chegou a US$33k/dataset; Lazy custa 0,1% adiando sumarização | Não sumarizar na escrita: YAML cru, projeção sob demanda |
| DREAM arXiv 2602.18940 (2026-02-21) | "Miragem da Síntese"; avaliador estático não julga validade temporal | Validade temporal só se verifica re-executando a busca: lint, não leitura |

## D. Repos emergentes por TRAJETÓRIA (GitHub created:>2026-01-01 sort=stars; HN Algolia; lidos 2026-09-02)
| Repo | ★ | Criado | O que faz |
|---|---|---|---|
| tt-a1i/archify | 43.479 | 2026-04-15 | skill de arquitetura verificável |
| tinyhumansai/openhuman | 39.336 | 2026-02-18 | memória local-first + frotas + deep researcher (Rust) |
| Leonxlnx/unlazy | 2.974 | 2026-08-09 | "Depth Tree": cada folha com orçamento da tarefa inteira |
| NirDiamant/Agent_Memory_Techniques | 972 | 2026-05-05 | 30 notebooks de memória |
| neo4j-labs/agent-memory | 522 | 2026-01-06 | memória graph-native oficial Neo4j |
| 0xK3vin/MegaMemory | 513 | 2026-02-06 | KG persistente de PROJETO p/ agentes de código via MCP |
| caura-ai/caura | 473 | 2026-04-27 | memória compartilhada governada, trust tiers, auditoria |
| Socialpranker/deepdive | 393 | 2026-05-21 (push 09-01, MIT) | skill Claude Code: 12 fases, gate de plano, ledger de afirmações c/ proteção a dissenso, filtro relevância×autoridade, red team, verificação de citação em 4 camadas |
| serradura/okf | 148 | 2026-07-11 | Open Knowledge Format |
| lajosdeme/mole (HN 2026-08-14, 100 pts) | — | 2026 | deep research no terminal com ORÇAMENTO e fontes verificadas |
Leitura: vizinho mais próximo = deepdive (pipeline verificável dentro do Claude Code, SEM grafo versionado no repo). Sinais convergentes: orçamento explícito por pesquisa (mole, unlazy); trust tiers na memória (caura).

## E. Credibilidade e tiering de fontes
| Fonte | Achado | Implicação |
|---|---|---|
| DREAM 2602.18940 | "Domain Authoritativeness": domínio (governo/acadêmico/notícia/comercial), 1-10 em 4 faixas: 9-10 definitiva, 7-8 alta, 4-6 moderada, 1-3 baixa | Adotar a escala; campo do nó, não prosa |
| Authority Signals… arXiv 2601.17109 (jan/2026) | framework de sinais de autoridade | rubrica de referência |
| Temporal article-level credibility arXiv 2607.04560 (jul/2026) | credibilidade no nível do artigo varia no tempo | tier da fonte tem revisita própria |
| WANDR | re-busca a página citada e confere o trecho | verificação de citação é mecânica |
| SEO agregadores (verif. 09-02) | DA correlação r=0,18; 47% das citações fora do top-5 | autoridade de domínio sozinha é fraca; corroboração cruzada pesa mais |
Hype vs sinal: toda a camada de comparação de ferramentas de busca é escrita por concorrentes diretos → tier "fornecedor sobre concorrente" precisa existir e ser sempre suspeito.

## (i) 5 padrões a ADOTAR
1. Bi-temporal explícito (validade do fato ≠ data da minha verificação). 2. Resolução determinística de conflito; LLM só extrai. 3. Verificação de citação por re-busca (gate mecânico). 4. Decomposição por CONTEXTO + gate anti-Early-Victory (contagem de evidência). 5. Filtrar/dedup FORA do contexto do modelo.
## (ii) 3 pontos ORIGINAIS do .kg.yaml versionado + lint
1. Git é a 2ª linha temporal de graça (procedência, diff, reversão; revisão do conhecimento por PR — ninguém no mercado). 2. Obsolescência que REPROVA um build (exit 2 em fato vencido). 3. O grafo é FONTE, não derivado (GraphRAG extrai e descarta; aqui o grafo é decisão e a prosa é projeção — zero custo de indexação).
## (iii) Periodicidade por tipo
| Tipo | Revisita | Justificativa |
|---|---|---|
| versão de ferramenta / preço de API | 30 d | Brave matou free tier fev/2026 |
| lineup de modelos | 45 d | Deep Research o3→GPT-5.2 fev/2026; Gemini 2 tiers abr/2026 |
| mercado e capital | 90 d | Tavily fev/2026, Exa mai/2026 |
| benchmark / empírico | 120 d | WANDR jul, DREAM fev |
| doutrina / padrão arquitetural | 12 m ou gatilho nomeado | bi-temporal Zep jan/2025 segue canônico |
## (iv) NÃO VERIFICADOS
Jina (preço/MCP); Zep funding; Letta/LangGraph memory (só agregadores); OpenAI primário (403); custos de busca (blogs de concorrentes); estrelas GitHub sem controle de inflação; Anthropic +90,2%/15x (secundário); valor da Tavily (secundário).
