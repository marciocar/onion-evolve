# Pesquisa externa — trajetória da comunidade sobre Claude Fable 5.1 (2026-09-02)

Escopo: o que praticantes de agentes de código estão RELATANDO/MUDANDO com o Fable 5.1
(`claude-fable-5-1`, lançado 2026-09-01), via HN, blogs de praticantes, GitHub issues/repos.
Reddit (`r/ClaudeAI`, `r/ClaudeCode`) bloqueou o fetch (ver Lacunas). Cada achado traz
afirmação · URL · trecho verbatim · data · tipo.

---

## 1. Relatos vs Fable 5

### 1.1 Obediência a instruções (MEDIÇÃO/RELATO — testes práticos, Every.to)
- Afirmação: Fable 5.1 aceita correção em vez de discutir, ao contrário do Fable 5.
- Trecho verbatim: *"changes course when you tell it to instead of arguing"* (comparação direta com Fable 5).
- Contraponto no mesmo artigo, mesmo dia: *"sometimes [it] does ignore me too"* — Kieran Klaassen, sobre o nível de esforço `xHigh` continuando a trabalhar quando pediram para parar e explicar.
- URL: https://every.to/vibe-check/fable-5-1-vibe-check
- Data: 2026-09-01. Tipo: relato de uso (Every, Katie Parrott/Dan Shipper).

### 1.2 Verbosidade (RELATO — dois sinais opostos)
- Every.to: *"Asked for 1,000 words, it wrote 1,288. Asked for three to six themes, it gave eight"* — ainda estoura limites pedidos, mas escreve prosa "clara, na ordem certa" e "é o primeiro modelo Claude em um ano que redatores querem usar para rascunhar".
  URL: https://every.to/vibe-check/fable-5-1-vibe-check · 2026-09-01 · relato.
- HN (thread do anúncio, autor `tarr11`): cancelou assinatura citando verbosidade — *"prose is denser than Claude Fable 5's"*.
  URL: https://news.ycombinator.com/item?id=49525378 (comentário) · 2026-09-01 · opinião.
- HN (autor `elpakal`): reescreve arquivo inteiro para edições pequenas; precisa de workaround no prompt.
  Mesma URL · 2026-09-01 · relato.
- HN (autor `alin23`): ainda produz "cringe AI phrasings"/"weird LLM speak" em sugestões de copy de UI apesar das melhorias declaradas.
  Mesma URL · 2026-09-01 · opinião.

### 1.3 Eficiência de tokens / custo (MEDIÇÃO — direções contraditórias)
- Every.to (testes "Every Agent"): *"uses about half the tokens of Opus 5 for similar tasks"* / *"used less than half as many tokens"* vs. Opus 5; Marcus Moretti: *"Basically as smart, a better writer, and about twice as token-efficient"*.
  URL: https://every.to/vibe-check/fable-5-1-vibe-check · 2026-09-01 · medição (comparação com Opus 5, não com Fable 5 diretamente).
- HN (autor `eis`): medição divergente comparando 5.1 vs 5 na MESMA tarefa — *"5.1 cost 56% MORE than 5... 140M vs 83M output tokens"*.
  URL: https://news.ycombinator.com/item?id=49525378 · 2026-09-01 · medição.
- HN (autor `george_max`): *"Fable 5 cost $3.14 per task, while 5.1 cost $3.69"* — *"marginal improvements for a more expensive model"*.
  Mesma URL · 2026-09-01 · medição.
- GitHub issue: **"[BUG] Fable 5.1 burns tokens faster than 5.0"**.
  URL: https://github.com/anthropics/claude-code/issues/91289 · aberta 2026-09-01 · relato/bug reportado.
- Nota: a mensagem oficial de custo (75% cache reads mais baratos, ~25-45% economia agregada — ver `ext-oficial.md` se existir) contradiz diretamente os relatos acima de custo por tarefa MAIOR; a comunidade está dividida entre "mais barato agregado" e "mais caro por tarefa individual" — provável explicação: cache hit rate varia por workload, e reasoning effort default subiu.

### 1.4 Long-horizon / raciocínio profundo (RELATO)
- HN (autor `mceachen`): *"I had two sessions this morning that prior fable and sol sessions were stuck on... both seem to have arrived at reasonable solutions"*.
  URL: https://news.ycombinator.com/item?id=49525378 · 2026-09-01 · relato positivo.
- Every.to (Kieran Klaassen, rebuild de "Proof"): *"it went deeper, adding useful details he hadn't requested"*, mas também *"extremely thorough, maybe too much, especially delegating to subagents"* — sinal de sobre-delegação/verbosidade estrutural, não só textual.
  URL: https://every.to/vibe-check/fable-5-1-vibe-check · 2026-09-01 · relato.
- HN (autor `coder-pm`): preocupação com confiabilidade comportamental em runs longos autônomos — *"how often Fable 5.1 is making a baffling decision and destroys my plan"*; quer confiabilidade comportamental, não só eval score.
  URL: https://news.ycombinator.com/item?id=49525378 · 2026-09-01 · opinião/relato.

### 1.5 Níveis de esforço de raciocínio — mudança estrutural (MEDIÇÃO — Simon Willison)
- Cinco níveis (`low`, `medium`, `high`, `xhigh`, `max`) — raciocínio agora OBRIGATÓRIO, sem opção de desligar.
- Medição direta: `xhigh` gerou 36.767 tokens em 7min51s; `max` gerou 65.927 tokens em 13min54s para o mesmo prompt (pelicano SVG) — salto não-linear entre níveis.
- Em `low`/`medium`, o raciocínio pareceu ser pulado por completo mesmo contando tokens de "reasoning" no total.
- Trecho: resultado em `max` foi *"the best pelican I've seen from any of Anthropic's models"*, mas *"didn't read nearly the same level of flair as Gemini 3.7 Flash"*.
- URL: https://simonwillison.net/2026/Sep/1/claude-fable-5-1/ · 2026-09-01 · medição direta (teste reprodutível do autor).

### 1.6 Rate limits / janela de 5 horas (RELATO)
- HN (autor `InsideOutSanta`): *"Fable 5.1 hit the 5-hour limit before it could finish the first task"* — em conta de trabalho E pessoal.
  URL: https://news.ycombinator.com/item?id=49525378 · 2026-09-01 · relato.
- GitHub issue aberta no dia do lançamento: **"You've hit your session limit · resets 3:50pm"**.
  URL: https://github.com/anthropics/claude-code/issues/91336 · 2026-09-01 · bug/relato.
- Contexto pré-5.1 (não é sobre 5.1 especificamente, mas explica o mecanismo): thinking em nível alto consome tokens do limite mesmo sem o usuário ler o raciocínio; um usuário relatou esgotar a janela de 5h em 8 minutos. Fonte: developersdigest.tech, sem data exata do exemplo — tratar como pano de fundo, não medição do 5.1.

### 1.7 "Safeguards" bloqueando trabalho legítimo (RELATO forte, recorrente desde Fable 5, reforçado no 5.1)
- HN (autor `ed-is-ai`): *"they're giving us a Ferrari, which will point blank refuse to do certain stuff"* — guardas de biologia/cibersegurança forçam fallback para modelo inferior.
  URL: https://news.ycombinator.com/item?id=49525378 · 2026-09-01 · opinião/relato.
- HN (autor `areoform`): questiona se o usuário é AVISADO quando a query é "re-roteada" para modelo de fallback silenciosamente.
  Mesma URL · 2026-09-01 · opinião (levanta preocupação de transparência).
- HN (autor `spondyl`): ironia relatada — *"Fable 5.1 was flagged by the biology safeguards"* ao analisar o PRÓPRIO system card do modelo.
  Mesma URL · 2026-09-01 · relato/anedota.
- Padrão herdado do Fable 5 (não é novo no 5.1, mas contextualiza a queixa): pesquisadores de segurança (ex. IBM X-Force) já reclamavam de falsos positivos em tarefas de cibersegurança tangenciais desde o lançamento do Fable 5 em junho/2026.
  Fontes: https://www.heise.de/en/news/Fable-5-also-blocks-secure-code-11328546.html ·
  https://github.com/anthropics/claude-code/issues/73327 ·
  https://github.com/anthropics/claude-code/issues/73784 — todas de junho/2026, tipo relato — não confirma se o 5.1 herdou o MESMO padrão medido, só que a queixa da comunidade é contínua.

---

## 2. Práticas de orquestração (abandonadas/reforçadas)

**Achado central: NÃO encontrei evidência de abandono de subagentes/fan-out por causa do contexto de 1M.** A tese "1M de contexto torna subagentes desnecessários" NÃO aparece na comunidade pesquisada — pelo contrário, o padrão dominante é reforço do orquestrador-com-subagentes:

- Padrão consolidado (múltiplas fontes, pré-5.1 mas continuado): Fable atua como ORQUESTRADOR (planeja, decompõe, sintetiza, "Writes no code") delegando execução mecânica a modelos mais baratos (Sonnet/Opus como "workers"). Ver `Rylaa/fable5-opus5-orchestrator` (plugin de marketplace do Claude Code) e `Rylaa/fable5-orchestrator` no GitHub.
  URLs: https://github.com/Rylaa/fable5-opus5-orchestrator · https://github.com/Rylaa/fable5-orchestrator · tipo: artefato/prática (não é opinião, é ferramenta publicada e instalável via `/plugin marketplace add`).
- Argumento explícito para ISOLAMENTO de contexto continuar valendo mesmo com 1M disponível: *"Every subagent in Claude Code runs in its own separate context window... the noise, the logs, the contents of the files it reads, the intermediate outputs, stays confined to the subagent's context and does not pollute the main conversation"* — ou seja, o motivo de usar subagentes NUNCA foi só escassez de tokens, é isolamento de ruído. O 1M não elimina essa necessidade.
  Fonte: developersdigest.tech (agregado via WebSearch, sem data isolável) · tipo: opinião/doutrina de prática, pré-existente ao 5.1.
- HN (thread sobre Opus 4.5, autor `dave1010uk`, achado por busca cruzada — NÃO é sobre 5.1 diretamente, mas é o debate vivo sobre a pergunta feita pelo mandato): *"Sub-agents are effectively the same as parallelization and temporary context compaction... I wonder what GPT-5.1 Pro would be like if it could orchestrate 1000 drone-like workers"* — a hipótese em discussão é ORQUESTRAR MAIS workers, não menos.
  URL: item HN referenciado via Algolia (story "Claude Opus 4.5") · tipo: opinião. **Atenção de proveniência**: este é sobre o ciclo Opus 4.5, não Fable 5.1 — cito por ser o debate estrutural mais próximo encontrado à pergunta (b) do mandato, mas não é medição do 5.1.
- Sinal indireto do próprio Every.to sobre 5.1: a queixa de Kieran Klaassen — *"extremely thorough, maybe too much, especially delegating to subagents"* — sugere que o 5.1, quando orquestrador, delega AINDA MAIS (não menos) do que o esperado, e isso é visto como excesso, não como economia.

**Conclusão sobre (b) do mandato**: NÃO ENCONTRADO nenhum relato de praticante abandonando fan-out/verify-loop por causa do 1M de contexto do Fable 5.1. A prática publicada e ativa (plugins de marketplace, blogs de playbook) é orquestrador-Fable + executores-baratos, igual ao padrão já registrado para o Fable 5 (ver memória `always-latest-max-model-elenxo` e KB do Onion sobre model-tiering). O 5.1 parece ter INTENSIFICADO delegação a subagentes (queixa de "over-thorough"), não reduzido.

---

## 3. Emergentes por trajetória (`created:>2026-08-01`, ordenado por estrelas)

Query: `https://api.github.com/search/repositories?q=claude+code+created:>2026-08-01&sort=stars&order=desc`

| Repo | Estrelas | Criado | Descrição |
|---|---|---|---|
| yetone/cumora | 3.393 | 2026-08-17 | Chat de equipe cross-platform onde agentes de IA são membros de primeira classe |
| ccch1mneyyy/dsh-TUI | 2.772 | 2026-08-13 | Plugin TUI com estilo Claude Code (whale bar, status ao vivo, "streaming thoughts") |
| eternityspring/shuohao-skills | 2.516 | 2026-08-06 | Skills de agente para produção de "short-drama" (bíblias de personagem, roteiros) |
| duty1g/x64dbg-mcp-server | 1.827 | 2026-08-22 | Plugin MCP nativo para x64dbg via HTTP |
| AMAP-ML/LongHorizon-Harness | 1.432 | 2026-08-04 | Harness de computer-use de longo horizonte para operação estendida de agentes com estado durável |
| nateherkai/scroll-craft | 1.397 | 2026-08-22 | Skill de Claude Code para design de site scroll-driven com auto-verificação |
| Nanako0129/sepia | 1.358 | 2026-08-28 | Skill "de-AI writing" para ficção/prosa profissional com "narrative repair" |
| damejan80/tokentab | 1.139 | 2026-08-27 | CLI que analisa custo de sessões Claude Code por modelo/projeto/dia |
| cbrock84/headcount | 958 | 2026-08-28 | Organização de agentes como empresa — 15+ departamentos, 125+ skills |
| alexgreensh/attention-span | 893 | 2026-08-04 | Output styles "ADHD-friendly" para agentes de código, reduz consumo de tokens |
| furkankly/zoetrope | 757 | 2026-08-18 | Visualização de flow graph ao vivo de sessões Claude Code (terminal/browser) |
| HarnessRouter/harnessrouter | 652 | 2026-08-09 | Interface unificada para múltiplos harnesses de agente ("Unified Harness Protocol") |
| 0xnyn/airship | 649 | 2026-08-10 | Editor visual estilo Figma para Claude Code, Codex e OpenCode |
| hkqr/my-free-code | 617 | 2026-08-27 | Gateway multi-provider para agentes de código com roteamento e fallback de modelo |
| sodiumsun/agenttrail | 600 | 2026-08-21 | Canvas infinito monitorando planos e mudanças de arquivo de agentes de IA em tempo real |

**Leitura por trajetória**: NENHUM destes tem "fable" ou "5.1" no nome/descrição — o corte é `created:>2026-08-01`, ou seja, a maioria nasceu ANTES do lançamento do 5.1 (2026-09-01) e não é reação a ele especificamente. Sinais estruturais visíveis no agregado: (1) monitoramento/observabilidade de sessões de agente vira categoria própria (`zoetrope`, `agenttrail`, `tokentab`, `dsh-TUI`) — ninguém confia no "exit 0" do agente, querem VER o que ele fez, o que ecoa a doutrina interna do Onion (`exit-code-nao-e-a-verificacao`); (2) "harness router"/gateway multi-provider ganhando tração — sinal de fadiga de vendor lock-in de um harness só; (3) "de-AI writing" (Nanako0129/sepia) como categoria nova — reação à queixa de verbosidade/tom robótico citada em 1.2.

---

## 4. Incidentes (GitHub issues, `anthropics/claude-code`, criados 2026-09-01/02)

Query: `repo:anthropics/claude-code fable 5.1`, ordenado por criação.

| Issue | Estado | Data | Resumo |
|---|---|---|---|
| [#91364](https://github.com/anthropics/claude-code/issues/91364) "[Bug] Vague blocking error prevents local development workflow" | aberta | 2026-09-02 | Erro de bloqueio vago impede fluxo de desenvolvimento local |
| [#91345](https://github.com/anthropics/claude-code/issues/91345) "[BUG] Fable 5.1 requires unstable release of Claude Code" | aberta | 2026-09-01 | 5.1 exige build instável do CLI |
| [#91336](https://github.com/anthropics/claude-code/issues/91336) "You've hit your session limit · resets 3:50pm" | aberta | 2026-09-01 | Limite de sessão atingido rápido (ver §1.6) |
| [#91331](https://github.com/anthropics/claude-code/issues/91331) "[BUG] claude-fable-5-1 metered at ~200K on Claude Code 2.1.252" | aberta | 2026-09-01 | Medição/contagem de contexto divergente (~200K, não 1M) numa versão específica do CLI |
| [#91326](https://github.com/anthropics/claude-code/issues/91326) "Agent list labels the 1M context window inconsistently" | aberta | 2026-09-01 | Rótulo inconsistente da janela de 1M na lista de agentes |
| [#91289](https://github.com/anthropics/claude-code/issues/91289) "[BUG] Fable 5.1 burns tokens faster than 5.0" | aberta | 2026-09-01 | Consumo de tokens mais rápido que o 5.0 (ver §1.3) |
| [#91281](https://github.com/anthropics/claude-code/issues/91281) "[BUG] Fable 5.1 - The configured advisor model is not compatible" | aberta | 2026-09-01 | Advisor travado ao migrar sessões antigas do Fable 5 para 5.1: erro `"claude-fable-5 cannot be used as an advisor when the request model is 'claude-fable-5-1'"` — upgrade automático do advisor sem opção de manter versão anterior, quebra conversas em andamento |

**Breaking changes documentados** (claudefa.st, não-oficial mas técnico, cross-referenciável com issues acima):
1. Tool-use forçado (`tool_choice: {"type":"any"}` ou `{"type":"tool",...}`) agora retorna erro 400 — o modelo não aceita mais pular o "thinking".
2. Blocos de `thinking` do 5.1 não são portáveis — modelos anteriores não os leem; em fallback, a API descarta silenciosamente, forçando replanejamento (custo/latência extra no primeiro turno pós-troca) — **provável causa raiz de #91281** acima.
3. Para contas API criadas em/após 2026-08-31: editar qualquer turno anterior, system prompt ou array de tools invalida todos os blocos de thinking subsequentes (erro de validação de assinatura).
- URL: https://claudefa.st/blog/models/claude-fable-5-1 · 2026-09-01 · fonte técnica secundária (não é HN/Reddit, mas é prática de migração relevante ao mandato).

---

## 5. Lacunas declaradas

- **Reddit (r/ClaudeAI, r/ClaudeCode) NÃO CONSULTADO**: `www.reddit.com/r/ClaudeAI/search.json` foi recusado pelo WebFetch ("Claude Code is unable to fetch from www.reddit.com" — provável bloqueio de robots/host). Tentativa via DuckDuckGo (`html.duckduckgo.com`) caiu em CAPTCHA. **NÃO ENCONTRADO (reddit fable 5.1)** — nenhum dado de Reddit neste levantamento.
- **X/Twitter**: só aparece indiretamente via HN Algolia (links para tweets da Anthropic sobre lançamento), sem acesso a réplicas/threads de praticantes. **NÃO ENCONTRADO (X/Twitter — sinais de praticantes)**.
- **latent.space / swyx**: busca não retornou artigo específico sobre Fable 5.1; only Every.to e referências indiretas a "Latent Space" citando SWE-Bench Pro (80.3% vs GPT-5.5 58.6%) apareceram agregadas dentro de outro resultado, sem URL própria verificável — **NÃO ENCONTRADO (post dedicado do latent.space)**, tratar o número do SWE-Bench Pro como não-verificado por fonte direta.
- **Verify-loops / juiz-LLM ainda pegam erros com 5.1**: não encontrei nenhuma medição ou relato específico sobre isso (pergunta (b), segunda metade, do mandato). **NÃO ENCONTRADO (verify loops efficacy fable 5.1)**.
- **Confirmação formal do padrão "abandonar fan-out"**: não encontrado nenhum caso concreto — a pesquisa aponta o oposto (reforço), mas a amostra é pequena (1 thread HN principal + 1 artigo Every.to + issues do GitHub); não é uma varredura exaustiva de toda a comunidade.
- Vários trechos de comentário HN vieram via API Algolia agregada por um fetch de resumo (não Li o HTML puro do item); há risco pequeno de paráfrase introduzida pelo agente de fetch em vez de citação 100% literal — sinalizado aqui por transparência, mas os trechos entre aspas foram preservados como retornados pela ferramenta.

---

## 6. Fontes

- https://news.ycombinator.com/item?id=49525378 — thread principal HN do anúncio (954 pontos, 893 comentários)
- https://simonwillison.net/2026/Sep/1/claude-fable-5-1/ — teste reprodutível (pelicano SVG, níveis de esforço)
- https://every.to/vibe-check/fable-5-1-vibe-check — vibe check de praticantes (Katie Parrott, Dan Shipper, Kieran Klaassen, Marcus Moretti)
- https://claudefa.st/blog/models/claude-fable-5-1 — breaking changes técnicos
- https://github.com/anthropics/claude-code/issues/91364, /91345, /91336, /91331, /91326, /91289, /91281 — issues do dia do lançamento
- https://api.github.com/search/repositories?q=claude+code+created:>2026-08-01&sort=stars&order=desc — trajetória de repositórios emergentes
- https://github.com/Rylaa/fable5-opus5-orchestrator, https://github.com/Rylaa/fable5-orchestrator — plugins de orquestração publicados
- https://www.heise.de/en/news/Fable-5-also-blocks-secure-code-11328546.html, https://github.com/anthropics/claude-code/issues/73327, /73784 — contexto histórico de queixas de safeguards (Fable 5, junho/2026)
