# S4 — Concorrência + Academia + Governança de Agentes

> Stream de pesquisa para o redesign da federação do Sistema Onion (2026-07).
> Autoria: pesquisador S4. Fontes verificadas na web (prioridade 2025-2026).
> Regra: cada achado material tem FONTE (URL). Sem fonte sólida = hipótese marcada.

## Resumo

O mercado de frameworks de agente convergiu, em 2025-2026, para **três padrões diretamente reusáveis pelo Onion**, e para **dois erros conhecidos** que a doutrina atual do Onion (git-async gated, um-escritor-por-repo, sem IA-fala-IA) já evita — o que posiciona o Onion à frente na *governança*, mas atrás na *observabilidade* (console/história) e na *derivação automática* de mapas.

Os três padrões reusáveis:
1. **Config-as-code distribuído por git com rollback** (GitHub Copilot org instructions em `.github`; Cursor/Windsurf "uma fonte canônica compila para cada alvo"; Claude Code plugins). É exatamente o modelo `members.yaml`+`/meta:adopt` do Onion — validando a arquitetura, mas expondo a lacuna P0-4 (mapa derivado) e P0-2 (targeting por atributo, não só por id).
2. **Reputação/gossip como antídoto ao colapso de cooperação** em MAS-LLM (RepuNet, arxiv 2505.05029) e frameworks TRiSM (arxiv 2506.04133) — base acadêmica direta para o `trust` SDAAL e os blocos `trust:` do `members.yaml`.
3. **Interoperabilidade viva com descoberta de capacidade + auth mútua** (A2A: Agent Cards JSON, OAuth2, SSE/JSON-RPC; Linux Foundation) — costura pronta para a opção `a2a-live` de um `federation-transport` SDAAL, endereçando a dor P0-1 (Grana.Ai isolada) **sem** reescrever o transporte git-async.

Os dois erros conhecidos que **corroboram** a doutrina Onion: (a) o debate Anthropic×Cognition de jun/2025 — subagentes em contexto isolado falham por "assumptions conflitantes / contexto faltante", e domínios que exigem contexto compartilhado ou muitas dependências **não** são bons candidatos a multi-agente (justifica o gate humano e o *não* IA-fala-IA hoje); (b) a onda de MCP tool-poisoning/supply-chain de 2025 (CVE-2025-54136, backdoor postmark-mcp, OWASP MCP Top 10) — valida `never-clobber`, `entrega-sem-commit` e a ingestão gated de sinais remotos.

Confiança geral: **média-alta**. Achados de mercado/arquitetura têm fonte sólida; a extrapolação para "o Onion deve fazer X" é implicação, não doutrina (não decidida aqui).

---

## Achados

### F1 — Anthropic: multi-agente ganha ~90%, mas 15× tokens, e há domínios onde NÃO usar
**Claim:** No sistema de pesquisa multi-agente da Anthropic, a arquitetura orchestrator+subagents superou o agente único em **90,2%** num benchmark de pesquisa breadth-first, mas consome **~15× mais tokens** que um chat. Falhas iniciais: over-delegation (50 subagentes p/ query simples), duplicação de trabalho por instrução vaga, e "context confusion". A Anthropic é **explícita** sobre quando NÃO usar: *"domains that require all agents to share the same context or involve many dependencies between agents are not a good fit"* e *"LLM agents are not yet great at coordinating and delegating to other agents in real time"*.
**Fonte:** https://www.anthropic.com/engineering/multi-agent-research-system
**Materialidade:** alta.
**Implicação p/ Onion (P0-1, doutrina):** É o argumento técnico mais forte a favor do desenho atual — a federação Onion é *coordenação assíncrona com estado compartilhado explícito* (`members.yaml`, CHANGELOG), não IA-fala-IA em tempo real. A dor P0-1 (canal vivo core↔core Grana.Ai) deve nascer como **transporte** (troca de artefatos/sinais), preservando o gate humano e o estado-compartilhado-explícito; abrir "IA-fala-IA live" cai justamente no anti-padrão que a Anthropic sinaliza. Reuso: `federation-transport` SDAAL com opção `a2a-live` *transportando sinais*, não conversas autônomas.

### F2 — Cognition "Don't Build Multi-Agents": fragilidade vem de contexto faltante
**Claim:** Um dia antes do post da Anthropic (jun/2025), a Cognition publicou *"Don't Build Multi-Agents"* argumentando que subagentes paralelos são inerentemente frágeis: agem sobre "assumptions conflitantes que não foram estabelecidas upfront" e o modo-de-falha "sempre se reduz a contexto faltante no sistema". Princípio de reconciliação (LangChain): *"build agents that factor in the collective knowledge and decisions of the entire system before acting"* — a questão não é *se* decompor, mas *quando* e *quão longe*.
**Fonte:** https://www.langchain.com/blog/how-and-when-to-build-multi-agent-systems (resume Cognition + Anthropic)
**Materialidade:** alta.
**Implicação p/ Onion (P0-2 RUIDO, doutrina):** O "contexto coletivo antes de agir" é *exatamente* o que o `members.yaml` codifica (specializations/mode/classificação) e o que o targeting `alvo:` **hoje ignora** (só per-id/broadcast). O ruído P0-2 é uma instância do anti-padrão "contexto faltante": mensagens chegam a quem não tem o contexto para agir. Corrigir targeting = fazer o `alvo:` fatorar o conhecimento coletivo do `members.yaml` (resolver por specialization/mode/tier, não por lista de ids).

### F3 — Reputação/gossip previne colapso de cooperação em MAS-LLM (RepuNet)
**Claim:** Em MAS baseados em LLM, sem rastreio de reputação os agentes colapsam em defecção/exploração mútua; o framework **RepuNet** (rastreio de reputação + compartilhamento tipo "gossip" + ajuste de estratégia condicionado à reputação do parceiro) sustenta taxas de cooperação substancialmente mais altas. É reciprocidade indireta: histórico observável carrega consequência social.
**Fonte:** https://arxiv.org/pdf/2505.05029 (Reputation as a Solution to Cooperation Collapse in LLM-based MASs)
**Materialidade:** alta.
**Implicação p/ Onion (doutrina/trust):** Base acadêmica direta para o `trust` SDAAL (`.claude/utils/trust/`) e os blocos `trust:` do `members.yaml`. O `trust-log.md` do Onion já é um proto-ledger de reputação; F3 sugere torná-lo **condicionante de decisão** (ex.: peso do veto/urgência de um sinal varia com histórico verificado do emissor — casa com a doutrina "declarado ≠ verificado" e o `pin-integrity-check`). Reuso, não reinvenção: o padrão "verificado por script, nunca por stamp declarado" do `members.yaml` **já é** reputação baseada em evidência.

### F4 — TRiSM para Agentic AI: framework unificado de Trust/Risk/Security em MAS-LLM
**Claim:** Revisão de 2025-2026 propõe o **AI TRiSM** (Trust, Risk & Security Management) como framework unificado para gerir confiança, risco e segurança em workflows multi-agente dinâmicos baseados em LLM — sinalizado pela Gartner como tendência estratégica (agentic AI + AI governance platforms) para 2025/2026.
**Fonte:** https://arxiv.org/html/2506.04133v2 (TRiSM for Agentic AI)
**Materialidade:** média-alta.
**Implicação p/ Onion (P0-3 console, federação formal):** Nomenclatura/estrutura de referência para o que a *Federação formal dormente* (`/meta:federation-*` com veto fail-safe + rollback + ledger) já faz parcialmente. Ao construir o console P0-3, mapear as views para as dimensões TRiSM (trust=ledger de contratos/reputação; risk=drift/CI status via `federation-status`; security=proveniência dos sinais) dá vocabulário defensável e alinhado ao mercado.

### F5 — A2A: interoperabilidade viva com Agent Cards + OAuth2, agora na Linux Foundation
**Claim:** O Agent2Agent (A2A), lançado pelo Google em abr/2025 e doado à Linux Foundation em jun/2025 (150+ orgs), padroniza comunicação client↔remote agent com **descoberta de capacidade via "Agent Cards" (JSON)**, transporte HTTP+SSE+JSON-RPC 2.0 e **OAuth 2.0 para auth mútua** sem compartilhar credenciais.
**Fonte:** https://www.linuxfoundation.org/press/linux-foundation-launches-the-agent2agent-protocol-project-to-enable-secure-intelligent-communication-between-ai-agents ; https://www.ibm.com/think/topics/agent2agent-protocol
**Materialidade:** alta.
**Implicação p/ Onion (P0-1):** Costura pronta para a opção `a2a-live` do `federation-transport` SDAAL — resolve o "core↔core sem canal vivo" da Grana.Ai reusando um padrão vendor-neutral já com auth mútua e descoberta de capacidade. Cautela (ver F1/F6): adotar A2A como **transporte de sinais gated** (o Agent Card anuncia o que a instância *expõe* — espelha o campo `exposes:` do `members.yaml`), **não** como canal de conversa autônoma. Precedente de reuso: assim como `task-manager/factory.md` abstrai `api|mcp`, o `federation-transport` abstrai `git-async | local | a2a-live`.

### F6 — MCP tool-poisoning e supply-chain: 30%+ de servidores vulneráveis, backdoor real
**Claim:** 2025 viu o primeiro servidor MCP malicioso confirmado in-the-wild (backdoor **postmark-mcp**, set/2025), tool-poisoning via metadata (**CVE-2025-54136**), e o **OWASP MCP Top 10** (Tool Poisoning = MCP03:2025). Levantamento sistemático de **1.800+ servidores MCP** achou **>30% com ao menos uma vulnerabilidade explorável**. Tool-poisoning é "supply-chain": o agente confia em metadata de capacidade autorada por quem ele nunca concordou em confiar.
**Fonte:** https://owasp.org/www-project-mcp-top-10/2025/MCP03-2025%E2%80%93Tool-Poisoning ; https://datasciencedojo.com/blog/mcp-security-risks-and-challenges/ ; https://arxiv.org/abs/2508.12538
**Materialidade:** alta.
**Implicação p/ Onion (doutrina/trust, P0-1):** Corrobora fortemente `never-clobber`, `entrega-sem-commit` (um-escritor-por-repo) e a **ingestão gated** de sinais remotos. Qualquer canal vivo (F5) tem de tratar payload remoto como *não-confiável até verificado* — o triângulo `pin-integrity-check` + `trust-log` + gate-do-maestro é a defesa que o mercado descobriu na dor. Ao ligar A2A/live, o Agent Card e os sinais recebidos precisam de validação determinística antes de virar ação (espelho do `/meta:federation-check` fail-safe).

### F7 — GitHub Copilot: instruções de org versionadas em git, com audit + rollback + hierarquia fail-safe
**Claim:** Instruções custom de organização do Copilot (GA em abr/2026) suportam **configuração file-based versionada num repo `.github`** — "version-control your org-wide Copilot instructions ... for easier rollout, audit trails, and rollback". Escopo: Copilot Chat, code review e cloud/coding agent. Política é hierárquica **enterprise→org** com **fail-safe**: policy "Unconfigured" no enterprise faz a org default para **Disabled** ("restricted unless explicitly enabled").
**Fonte:** https://github.blog/changelog/2026-04-02-copilot-organization-custom-instructions-are-generally-available/ ; https://github.blog/changelog/2025-11-04-github-copilot-policy-update-for-unconfigured-policies/
**Materialidade:** alta.
**Implicação p/ Onion (P0-4, P0-2, federação formal):** Validação externa quase-1:1 do modelo Onion — config-as-code distribuída por git, versionada, com rollback (= `/meta:adopt` + `members.yaml` + `/meta:federation-rollback`). Dois aprendizados: (a) o **default fail-safe hierárquico** ("unconfigured = disabled/veto") é idêntico ao veto fail-safe da Federação formal — evidência de que o Onion acertou o default; (b) a **hierarquia enterprise→org** informa P0-2/P0-4: o mapa/targeting deve respeitar tiers (source→hub→standalone), resolvendo `alvo:` na topologia que o `members.yaml` já tem.

### F8 — Cursor/Windsurf: uma fonte canônica compila para cada alvo; global "drifta" em silêncio
**Claim:** Para times, só regras **commitadas no repo** contam; regras globais por-dev "drift silently". A prática mantível para múltiplos alvos é **manter uma fonte canônica (ex.: `AGENTS.md`) e compilar/referenciar para o formato nativo de cada ferramenta** (`.cursor/rules/*.mdc`, `.windsurf/rules/*.md`) — os formatos não são interoperáveis entre si.
**Fonte:** https://dev.to/olivia_craft/cursor-rules-for-teams-how-to-share-ai-rules-across-your-entire-codebase-4l0g ; https://dev.to/deployhq/claudemd-agentsmd-and-every-ai-config-file-explained-4pde
**Materialidade:** média-alta.
**Implicação p/ Onion (P0-4):** Reforça que **o SSOT tem de ser derivado, não desenhado à mão** (o "drift silencioso" é literalmente a dor do mapa-do-site desenhado à mão vs `members.yaml`). Padrão "uma fonte → compila para alvos" = o `graph.sh` já é um *gerador-de-seed sem store*; ligá-lo a ingerir `members.yaml` produz o mapa de adoções derivado (P0-4) pelo mesmo princípio que a indústria adotou. O Onion está **à frente**: seu SSOT é executável (spec-as-code), não um `.md` copiado.

### F9 — Claude Code plugins/marketplace GA (out/2025): a primitiva de distribuição da Anthropic
**Claim:** Plugins do Claude Code saíram de beta (out/2025) para parte estável do fluxo; **empacotam skills+subagents+slash-commands+hooks+MCP numa unidade instalável**. Discovery via **diretório vetado da Anthropic (55+)** + marketplace comunitário (70+) com "automated safety screening".
**Fonte:** https://www.marktechpost.com/2026/06/14/claude-code-guide-2026-25-features-with-examples-demo/ ; https://github.com/anthropics/skills
**Materialidade:** alta.
**Implicação p/ Onion (direção Anthropic, P0-4/adopt):** É o vetor oficial de distribuição na plataforma-única do Onion. `/meta:adopt` é conceitualmente um "plugin install" com estado (`members.yaml`). Direção defensável: **modelar o pacote de adoção como plugin Claude Code** (ou ao menos alinhar o layout) para pegar carona no discovery/safety-screening da Anthropic — sem virar produto npm (a linha vermelha do CLAUDE.md permanece). O "automated safety screening" do marketplace é o análogo do gate mecânico `.claude/validation/`.

### F10 — Mercado converge para control-planes gerenciados (MS Agent Framework 1.0, CrewAI AMP)
**Claim:** A Microsoft fundiu AutoGen+Semantic Kernel no **Microsoft Agent Framework 1.0** (preview out/2025, GA abr/2026); a **CrewAI AMP** oferece plataforma de gestão com "deployment, tracing e monitoring" e "hierarchical memory isolation". O mercado está padronizando **planos de controle com observabilidade** para frotas de agentes.
**Fonte:** https://softmaxdata.com/blog/definitive-guide-to-agentic-frameworks-in-2026-langgraph-crewai-ag2-openai-and-more/ ; https://crewai.com/agent-management-platform
**Materialidade:** média.
**Implicação p/ Onion (P0-3):** Confirma a dor P0-3 (falta console/histórico/relações) como *lacuna competitiva real*, não luxo. O Onion não precisa de SaaS — mas precisa de **um lugar para VER** (console read-only). Reuso barato: `/meta:federation-status` já é o "monitor read-only" (drift + CI por membro); P0-3 é dar-lhe superfície visual. "Hierarchical memory isolation" da CrewAI ecoa os tiers do RFC-0003.

### F11 — Federated learning: compartilhar conhecimento abstrato, não dado bruto (cross-silo)
**Claim:** Em FL/FRL, clientes (orgs/silos) colaboram **compartilhando updates abstratos (gradientes/parâmetros/políticas), nunca o dado bruto**, com um agregador coordenando — padrão "cross-silo" para orgs com datasets privados. Revisões de 2025 cobrem 200+ papers.
**Fonte:** https://arxiv.org/html/2504.17703v3 (Federated Learning survey) ; https://www.frontiersin.org/journals/computer-science/articles/10.3389/fcomp.2025.1617597/full
**Materialidade:** média.
**Implicação p/ Onion (memória organizacional, RFC-0003 F2):** Fundamento teórico para `/meta:diary` + `personality-sync` (Fase 2 gated): a federação Onion deve trocar **conhecimento destilado** (sinais, migalhas, vereditos, `personality_summary`) e **não** o repo bruto do adotante — que é precisamente o invariante `entrega-sem-commit`/`exposes:`. A Grana.Ai (monorepo nx privado, time de devs) é o caso cross-silo canônico: compartilha aprendizado, não código-fonte. Reuso: o `diary` já é o "update abstrato local"; falta o agregador (o core) ingeri-lo com política.

### F12 — Threat-modeling comparativo de protocolos de agente (MCP/A2A/Agora/ANP)
**Claim:** Análise comparativa de segurança (2026) dos protocolos emergentes MCP, A2A, Agora e ANP mapeia superfícies de ataque distintas por protocolo; paralelamente, "Aiming for AI Interoperability" cataloga desafios de interop entre frameworks.
**Fonte:** https://arxiv.org/pdf/2602.11327 (Security Threat Modeling for Emerging AI-Agent Protocols) ; https://arxiv.org/pdf/2601.14512
**Materialidade:** média.
**Implicação p/ Onion (P0-1, escolha de transporte):** Ao desenhar `federation-transport` com opção `a2a-live`, herdar o modelo de ameaças por-protocolo em vez de improvisar. Reforça F6: a escolha de transporte é decisão de *segurança*, não só de conveniência — e o default `git-async` (auditável, versionado, gated) tem o menor perfil de ataque; `a2a-live` é opt-in para o caso Grana.Ai.

### F13 — Hipótese: o limiar de coordenação é a *interface*, não o headcount
**Claim (opinião/first-principles, não peer-reviewed):** A decomposição multi-agente teria um "sweet spot"; uma "handoff fidelity" crítica decide se a coordenação se sustenta ou cascateia em erro — e a alavanca seria a **qualidade da interface** entre agentes, não o número de agentes.
**Fonte:** https://medium.com/@brian-curry-research/the-coordination-threshold-when-many-agents-beat-one-and-when-they-cascade-6ef7beb8c153
**Materialidade:** baixa (fonte não acadêmica; tratar como hipótese).
**Implicação p/ Onion (P0-2):** Se verdadeiro, o ROI de arrumar a *interface* de mensagem (o schema do `alvo:`/CHANGELOG, campos de contexto) supera o de adicionar automação/atores. Alinha com F2: melhorar targeting (interface) > abrir IA-fala-IA (mais atores). Marcar como hipótese a validar em dogfood.

---

## Encaixe nas fundações / viabilidade VPS

### Reuso, não reinvenção — mapeamento por fundação

| Fundação existente | Achados que a informam | Como estende (reuso) |
|---|---|---|
| **`graph.sh`** (motor BFS impact/path/closure; gerador-de-seed SEM store; ainda NÃO ingere `members.yaml`) | F7, F8, F4 | Ligar ingestão de `members.yaml` → **mapa de adoções derivado (P0-4)** pelo princípio "uma fonte canônica compila para os alvos" (F8). O grafo vira o dado do console (P0-3) e do mapa do site. |
| **SDAAL** (`task-manager/factory.md` já abstrai `api\|mcp` c/ fallback) | F5, F6, F12, F1 | Precedente direto para um **`federation-transport` SDAAL** com `git-async` (default, menor superfície de ataque) \| `local` (carteiro-local já existe) \| `a2a-live` (opt-in p/ Grana.Ai, F5). O fallback gracioso já é padrão. |
| **doc-bridge** (`/meta:co-*` + CHANGELOG `alvo:` + inbox/inbound) | F2, F7, F13 | **P0-2 RUIDO:** resolver `alvo:` por specialization/mode/tier (fatorar o `members.yaml`, F2/F7-hierarquia) em vez de per-id/broadcast. A interface da mensagem é a alavanca (F13). |
| **Federação formal** (`/meta:federation-*`: veto fail-safe + rollback + ledger) | F3, F4, F7 | Já implementa o **default fail-safe hierárquico** que o Copilot validou (F7) e a estrutura TRiSM (F4). `federation-status` é o **monitor read-only** que vira o console P0-3. Ligar reputação (F3) como condicionante do veto/urgência. |
| **trust SDAAL** (`.claude/utils/trust/` + `trust-log.md` + `pin-integrity-check`) | F3, F6 | "Declarado ≠ verificado" **já é** reputação-por-evidência (F3). Endurecer ingestão de sinais remotos como supply-chain não-confiável (F6) antes de qualquer canal vivo. |
| **`/meta:diary` + `personality-sync`** (RFC-0003 F2, gated) | F11 | Trocar **conhecimento destilado, não repo bruto** (cross-silo FL) — casa com `exposes:`/`entrega-sem-commit`. Grana.Ai = caso cross-silo canônico. |

### P0 → achado → menor passo de reuso

- **P0-1 (Grana.Ai isolada, sem canal vivo):** F5 (A2A) + F1/F6 (cautela). Menor passo: `federation-transport` SDAAL com `a2a-live` **transportando sinais gated** (Agent Card ~ `exposes:`), default segue `git-async`. NÃO abrir IA-fala-IA autônoma (F1/F2).
- **P0-2 (ruído do targeting):** F2 + F7 + F13. Menor passo: resolver `alvo:` na topologia/atributos do `members.yaml` (specialization/mode/tier), no motor `graph.sh`.
- **P0-3 (falta console/histórico/relações):** F10 + F4. Menor passo: dar superfície visual ao `federation-status` + grafo derivado; deploy read-only na VPS.
- **P0-4 (falta mapa derivado):** F8 + F7. Menor passo: `graph.sh` ingere `members.yaml` → mapa (substitui o desenho à mão do site).

### Viabilidade VPS (Hostinger KVM 8 — srv1812846, 8 vCPU/32 GB)

A infra atual **já hospeda** site estático (Caddy + TLS auto) e o `onion-bridge` (systemd, `@anthropic-ai/claude-agent-sdk`) sob `app.onionevolve.com` (reverse_proxy → 127.0.0.1:8787), com DNS via API Hostinger. Consequências para os P0:

- **P0-3/P0-4 (console + mapa) — viável e barato hoje:** o padrão canônico é **build-on-VPS leve, estático**. `graph.sh` (+ ingestão `members.yaml`) e `federation-status` são scripts determinísticos que emitem JSON/HTML → servidos como estáticos por Caddy num subdomínio (ex.: `map.onionevolve.com` / `console.onionevolve.com`), regenerados por hook/cron a partir do `members.yaml`+CHANGELOG. Zero serviço novo stateful; é o mesmo file_server já em uso. **Recomendado começar por aqui** (menor risco, ataca 2 dores).
- **P0-1 (`a2a-live`) — viável mas gated:** um endpoint A2A (Agent Card em `/.well-known` + OAuth2) caberia atrás do reverse_proxy Caddy já existente, mas F6/F12 exigem validação determinística de payload + gate humano antes de virar ação. Tratar como Fase 2 opt-in, **depois** de P0-3/P0-4.
- **Segurança (F6):** o `onion-bridge` roda `bypassPermissions` num clone dedicado isolado — qualquer canal vivo deve manter esse isolamento e nunca dar ao transporte remoto poder de escrita cross-repo (invariante `entrega-sem-commit`).

**Conclusão de viabilidade:** o caminho de menor custo/maior retorno é **P0-4→P0-3 como estáticos gerados na VPS** (reusa Caddy + `graph.sh` + `federation-status`), deixando P0-1 (`a2a-live`) e reputação-condicionante (F3) para uma fase gated posterior. Nada aqui exige serviço novo ou dependência externa — só ligar fundações que já existem.

---

## Verificação adversarial

> Verificador S4 (adversarial), 2026-07-09. Doutrina "evidência ou abstenção": a missão foi **refutar**, não confirmar por gentileza. Fontes checadas via WebFetch/WebSearch contra os originais. Na dúvida → `hypothesis`, nunca `confirmed`.

| Finding | Veredito | Nota |
|---|---|---|
| **F1** | **confirmed** | As três citações batem **verbatim** na página oficial da Anthropic: "outperformed single-agent Claude Opus 4 by 90.2%", "use about 15× more tokens than chats", "domains that require all agents to share the same context or involve many dependencies between agents are not a good fit". Fonte primária sólida. |
| **F2** | **confirmed** | O debate Cognition×Anthropic (jun/2025) é real e a fonte LangChain referencia o argumento da Cognition ("conflicting decisions carry bad results"). Ressalva menor: a frase exata "build agents that factor in the collective knowledge…" não foi confirmada verbatim na página citada — é paráfrase do princípio, não citação literal dessa URL. O substrato material (fragilidade por contexto/assumptions faltantes) está sólido. |
| **F3** | **confirmed** | arxiv 2505.05029 existe e o título/abstract batem: "Reputation as a Solution to Cooperation Collapse in LLM-based MASs"; RepuNet = framework de reputação dual-level com "direct interactions and indirect gossip", formação de clusters cooperativos e isolamento de agentes exploradores. AAMAS 2026. Sustenta o claim sem exagero. |
| **F4** | **confirmed** | arxiv 2506.04133 confirma título "TRiSM for Agentic AI: A Review of Trust, Risk, and Security Management in LLM-based Agentic Multi-Agent Systems". Ressalva: o paper **não cita a Gartner explicitamente** no conteúdo visível — mas TRiSM É um termo/tendência de origem Gartner, então a atribuição é razoável (não fabricada). |
| **F5** | **confirmed** | Linux Foundation lançou o projeto A2A em **23/jun/2025** (doado pelo Google, launch abr/2025 com 50+ e crescido a 150+ orgs). Agent Cards (JSON) p/ descoberta de capacidade, HTTP+SSE+JSON-RPC 2.0, OAuth2/OIDC/mTLS p/ auth mútua sem compartilhar credenciais. Todos os elementos confirmados. |
| **F6** | **confirmed (com ressalva no número)** | Verificados: backdoor **postmark-mcp** (v1.0.16, 17/set/2025, BCC exfil) = primeiro MCP malicioso in-the-wild; **CVE-2025-54136 (MCPoison)** real (rug-pull de config MCP no Cursor → RCE, trust preso ao nome-da-chave); **OWASP MCP Top 10** existe e **Tool Poisoning = MCP03:2025** exato. **Ressalva material:** o número "**30%+ de 1.800 servidores**" NÃO se sustentou — o survey arxiv 2508.12538 existe mas estudos de escala semelhante (~1.899 servidores) reportam ~7% por detector tradicional; outro mede 40,55% sem auth. A estatística específica parece **conflada/superestimada**; o thrust qualitativo (supply-chain MCP é ameaça real) permanece sólido. |
| **F7** | **hypothesis** | Refutação parcial da forma como está escrito. O changelog GA citado (2026-04-02) **NÃO contém** a frase "version-control your org-wide Copilot instructions … audit trails, and rollback" nem menciona repo `.github`/rollback/audit. Version-control em git com commit/push/rollback é real, mas para **instruções de REPO** (`.github/copilot-instructions.md`) — não para o feature **org-level GA** citado, que é configurado via **settings UI**. Além disso, a precedência de instruções é **personal > repo > org** (não "enterprise→org"), e o "unconfigured=disabled fail-safe" é um feature **separado** (changelog 2025-11-04 de policies). Os fatos individuais existem, mas o claim **confla dois features distintos e cita a fonte errada** para o núcleo material. Implicação p/ Onion sobrevive; a citação, não. |
| **F8** | **hypothesis** | O claim (só regras commitadas contam; global "drifta em silêncio"; uma fonte canônica compila p/ formato nativo de cada alvo) reflete **consenso de prática** amplamente repetido, mas a fonte é um blog dev.to (baixa autoridade) e não foi corroborado por fonte primária/autoritativa. Plausível e útil, mas não é evidência forte — tratar como hipótese de trabalho. |
| **F9** | **confirmed** | Claude Code plugins GA em **09/out/2025**; empacotam slash-commands + subagents + hooks + MCP servers (+ skills namespaced) numa unidade instalável; diretório oficial gerido pela Anthropic + marketplace comunitário com "automated validation and safety screening". Confirmado contra fontes oficiais (claude.com/blog, code.claude.com/docs, anthropics/claude-plugins-official). As contagens exatas "55+/70+" vêm da fonte secundária (marktechpost) e não foram verificadas número-a-número, mas o qualitativo está sólido. |
| **F10** | **confirmed (com ressalva)** | **Microsoft Agent Framework 1.0** GA em **03/abr/2026** (fusão AutoGen+Semantic Kernel, APIs estáveis + LTS, MCP+A2A nativos) confirmado no devblogs.microsoft.com. CrewAI AMP como plataforma de gestão (deployment/tracing/monitoring) é real. **Ressalva:** o detalhe específico "hierarchical memory isolation" da CrewAI AMP não foi verificado numa fonte primária — tratar essa fração como não-confirmada. O thrust (mercado converge p/ control-planes gerenciados c/ observabilidade) está sólido. |
| **F11** | **confirmed** | Federated learning cross-silo = compartilhar updates abstratos (gradientes/parâmetros/políticas) com agregador coordenando, nunca o dado bruto — conhecimento fundamental e não-controverso da área; o survey arxiv 2504.17703 existe. Baixo risco de exagero. |
| **F12** | **confirmed** | arxiv 2602.11327 confirma título exato "Security Threat Modeling for Emerging AI-Agent Protocols: A Comparative Analysis of MCP, A2A, Agora, and ANP" e mapeia superfícies de ataque **distintas por protocolo**. Sustenta o claim. |

**Síntese do verificador:** 9 de 12 achados materiais **confirmados** contra fonte primária (F1, F3, F4, F5, F9, F11, F12 sólidos; F2/F6/F10 confirmados com ressalva pontual). **Dois `hypothesis`:** F7 (citação errada/conflação de dois features do Copilot — o fato existe, a fonte citada não o sustenta) e F8 (consenso de prática sobre fonte de baixa autoridade). **Alertas de precisão a corrigir antes de citar externamente:** (a) o "30%+ de 1.800 servidores" de F6 está superestimado — estudos comparáveis dão ~7%; (b) F7 deve ser recitado apontando para instruções **de repo** (`.github`) + o changelog de policies (2025-11-04), não para o GA org-level. Nenhum achado material foi **refutado por completo** — as fraquezas são de *citação/estatística*, não de tese. A tese central de S4 (mercado valida config-as-code por git + reputação/trust + interop com auth mútua; erros conhecidos corroboram a doutrina Onion) resiste à verificação adversarial.
