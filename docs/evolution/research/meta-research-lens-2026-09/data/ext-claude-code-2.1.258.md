# Capacidades do Claude Code 2.1.258 para /meta:* de pesquisa (worker lens-claude-code, opus, web, 2026-09-02) — PARCIAL (tabela até SessionStart)

Versão instalada 2.1.258 = mais recente publicada (2026-09-01); changelog GitHub e docs code.claude.com concordam.

| Capacidade | Versão/data | Fonte | Serventia |
|---|---|---|---|
| Workflow `/deep-research` EMBUTIDO: leque de buscas, fetch, verificação cruzada por votação, relatório citado, claims não verificados marcados | anterior a 2.1.202, doc viva | code.claude.com/docs/en/workflows | (b)+(parte de e) já prontos: amplitude com refutação e "não verificado" marcado |
| Workflow tool: agent()/pipeline()/parallel()/phase()/log(), args, meta | workflowSizeGuideline 2.1.219; footprint reduzido 2.1.248 (2026-08-27) | workflows | a lente vira orquestração codificada e reexecutável |
| Workflows retomáveis; Date.now()/Math.random() proibidos (replay determinístico) | doc viva | workflows | revisitação: relançar reaproveita agentes cujo prompt não mudou |
| Limites: 16 concorrentes, 4.096 itens por parallel/pipeline, 1.000 agentes/run | doc viva | workflows | dimensiona o leque |
| Skills: !`comando` injeta contexto dinâmico antes do corpo | doc viva | skills | É o (a): a lente sem o usuário redigir (estado do .kg.yaml inlined) |
| context: fork + agent: + background | fork em background desde 2.1.218 | skills | pesquisa em subagente isolado |
| auto-ativação por description; disable-model-invocation: true | doc viva | skills | /meta:* sensível só-usuário; lente de leitura auto-ativa |
| .claude/rules/ com paths: glob, carga preguiçosa | paths via symlink 2.1.198; --setting-sources 2.1.211 | memory | regra de pesquisa carrega só ao tocar .kg.yaml |
| InstructionsLoaded hook (session_start, path_glob_match, include) | doc viva | hooks | prova QUAL lente carregou (contra "declarei que carreguei") |
| additionalContext em UserPromptSubmit, UserPromptExpansion, PostToolUse, PostToolBatch, Stop, SubagentStop | doc viva | hooks | injeta lente e frescor do grafo em cada ponto do laço |
| exit 2 bloqueia em todo evento bloqueável | doc viva | hooks | É o (e): lint do .kg.yaml vira veto |
| PreModelSwitch/PostModelSwitch com bloqueio | 2.1.251 (2026-08-28) | changelog | barra troca no meio de passada (re-cache) |
| SessionStart em resume recebe staleness da sessão e custo de re-cache | 2.1.251 | changelog | sinal nativo de temporalidade… (truncado — continuação pendente) |
| TaskCreated / TaskCompleted hooks, bloqueáveis | doc viva | hooks | impede fechar tarefa de pesquisa cujo nó não foi carimbado |
| Subagentes: model, effort (low..max), tools, skills (pré-carrega skill), memory, isolation: worktree, experimental.cacheTtl | cacheTtl 2.1.248 | sub-agents | tiering por fase; lente pré-carregada via `skills` |
| Teto 20 subagentes simultâneos (CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS — NÃO-VERIFICADO literal); ultracode isento | doc viva | sub-agents | dimensiona o leque |
| Subagentes em background mantêm WebSearch/WebFetch | doc viva | sub-agents | coletor em background |
| Subagente NÃO herda auto-memória nem histórico (só fork) | doc viva | memory | a lente tem de ser passada (skills/CLAUDE.md/prompt), nunca assumida |
| WebSearch: só título+URL; até 8 buscas de backend por chamada; allowed_domains/blocked_domains | doc viva | tools-reference | um subagente por classe de fonte com domínio fixado |
| WebFetch cache 15 min (CLAUDE_CODE_WEBFETCH_CACHE_TTL_MS, 2.1.233); regra WebFetch(domain:x) | | tools-reference | fallback quando WebSearch satura |
| Agent tool: contexto separado, devolve 1 texto | | | custo de contexto fica no filho |
| Auto-memória: tipos user/feedback/project/reference; só 200 linhas/25KB de MEMORY.md entram; campo modified ISO (2.1.214) | | memory | único carimbo nativo; markdown, não grafo |
| CLAUDE.md @import profundidade 4; claudeMdExcludes; claudeMd managed | | memory | lente estável por import; por caminho vai a .claude/rules/ |
| Routines /schedule (/routines): cadência ≥1h, único, API POST /fire com bearer, evento GitHub PR/release; GitHub trigger 2.1.225; /schedule why 2.1.227; payload embrulhado em <routine-fire-payload> não-confiável (2.1.213) | preview | routines | É a revisitação periódica — roda na NUVEM, clona o repo, empurra em branch claude/ |
| Trocar modelo OU effort recomputa o request inteiro (ambos na chave do cache); linha de cache em /cost 2.1.251 | | prompt-caching | fixar modelo+effort no início da fase |
| cache read ≈10% do input; promptCacheTtl / subagentPromptCacheTtl 5m|1h (2.1.242); subagente/workflow ficam em 5 min por default | | prompt-caching | passada longa não perde cache |
| Fable 5.1 default, 1M ctx, US$10/50 por Mtok, cache read US$0,25 | 2.1.257 (2026-09-01) | changelog | síntese de muitas fontes num contexto |
| CLAUDE_CODE_SUBAGENT_MODEL_FORCE | 2.1.257 | changelog | trava modelo dos coletores |
| MCP remoto HTTP: mcp.exa.ai/mcp, mcp.tavily.com/mcp/, mcp.firecrawl.dev/v2/mcp | 2026, terceiros | firecrawl/vellum blogs | busca como SDAAL |

## Padrões da Anthropic que ainda valem
Artigo do sistema multi-agente de pesquisa (2025-06-13): orquestrador-trabalhador 3-5 subagentes; ~15x tokens; subtarefa com objetivo/formato/ferramenta/fronteira explícitos; busca ampla→estreita; avaliação por ~20 consultas com juiz LLM (acurácia factual, citação, completude, qualidade de fonte, eficiência de ferramenta). Mudou: virou artefato — o /deep-research embutido já faz leque por ângulos, votação e "não verificado".

## LACUNAS da plataforma (o framework supre)
1. Persistência .kg.yaml com temporalidade não existe (auto-memória = markdown, 1 campo modified). 2. Nenhum estado sobrevive a um workflow (variáveis somem; gravar no grafo = passo de agente com Write). 3. Sem revisita local agendada com repo privado (routines = nuvem, conta individual, allowlist de rede; recorrência local = cron/systemd do Onion — MOAT W7). 4. Frescor não é medido; carimbo e gatilho são regra do lint. 5. Hook não valida YAML (exit 2 barra; quem lê é script seu). 6. Sem cota de busca compartilhada entre sessões (/clear zera). 7. argument-hint NÃO é aceito em SKILL.md (chaves: allowed-tools, compatibility, description, license, metadata, name).

## NÃO-VERIFICADOS
1. Teto 200 WebSearch/sessão somando subagentes, /clear zera, CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION (a partir de 2.1.212) — doc truncou 3x. 2. Nome literal CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS e default 20. 3. Se /deep-research aceita domínio/eixos fixos. 4. MCP oficial Perplexity/Brave. 5. Se routine na nuvem dispara workflow salvo.
