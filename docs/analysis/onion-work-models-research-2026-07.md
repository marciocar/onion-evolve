# Pesquisa — Estratégias de coordenação assíncrona e autonomia agendada para agentes (2025-2026)

> **Status:** efêmero / insumo de decisão (segue [analysis/README.md](README.md)) — alimenta o ADR
> [onion-adr-work-models-session-topologies-2026-07.md](onion-adr-work-models-session-topologies-2026-07.md).
> **Método:** deep-research harness (run `wf_80c7ae61-76e`, 104 agentes, ~2,7M tokens): 5 ângulos de busca
> paralelos → 22 fontes → 109 claims extraídos → **verificação adversarial 3-votos nos 25 principais →
> 24 confirmados, 1 refutado**. Pergunta: estratégias populares/emergentes para coordenação assíncrona
> entre agentes em repos distintos + autonomia agendada com HITL, avaliadas contra o fluxo **git-async
> soberano** do Onion (sem serviço vivo obrigatório, sem vendor lock-in, ato 3 sempre gated).

## Veredito de topo

**Divisão nítida em dois mundos:**

1. **Vendor scheduled/background agents** (Claude Code routines, Codex Cloud, Jules) — reais e maduros,
   mas **incompatíveis como base do fluxo soberano**: exigem serviço vivo, atam ao vendor, e **a autonomia
   é o default** (HITL é post-hoc ou opt-in). Único mecanismo reaproveitável: **gate git-nativo** (push
   restrito a branch prefixada + branch protection → mudança só entra via PR revisado).
2. **Padrões repo-nativos** (drop-box/inbox commitado, memória/breadcrumbs versionados, consolidação lazy
   por sessão) — **soberanos por construção, human-gated por design**, com evidência de produção
   experimental e benchmarks favoráveis. **É exatamente a família do Onion** (doc-bridge, diário, hooks).

## Achados confirmados (3-0 salvo indicado)

| # | Achado | Conf. | Fontes-chave |
|---|--------|-------|--------------|
| 1 | **Routines (Anthropic) = serviço vivo + autonomia na run**: cloud-only, intervalo mín. 1h, sem permission-mode nem prompts de aprovação — HITL inteiramente post-hoc. Incompatível como base soberana; referência de design apenas. | alta | code.claude.com/docs/routines (primária) |
| 2 | **Gate git-nativo é o padrão transplantável**: push só em branch prefixada (`claude/`) + branch protection = gate humano no merge, vendor-independente. | alta | idem |
| 3 | **Background agents (Codex Cloud, Jules): autonomia é default, gate é exceção** — Jules API aprova planos automaticamente salvo `requirePlanApproval=true`; alpha com breaking changes anunciadas. | alta | developers.openai.com/codex/cloud · developers.google.com/jules/api (primárias) |
| 4 | **Event-driven em produção é acoplado ao forge, não cron** (menção @codex, eventos PR/release). O equivalente soberano sem daemon é o **trigger lazy por sessão** (hooks SessionStart/End) — automação de transporte sem serviço vivo. | alta | idem + claude-memory-compiler |
| 5 | **Drop-box/inbox commitado (Squad) é o caso documentado mais completo**: decisões em `decisions.md` versionado; escrita concorrente resolvida com **arquivo individual por agente em `inbox/*.md` + um "Scribe" que mergeia no canônico** (post-mortem real: "Git didn't save us — nem toda colisão vira conflito limpo"). | alta | GitHub Blog + Microsoft Command Line blog + repo (~2,9k ⭐) |
| 6 | **Memória versionada em git como canal entre sessões** (Squad): "Make the agents disposable. Keep the memory in Git" — charter/history/decisions como Markdown versionado, diffável, auditável; sem store oculto. | alta | idem |
| 7 | **HITL robusto se impõe por código determinístico, não por prompt**: "Prompts can be ignored. Hooks are code — they execute deterministically"; guardrails como hooks pré-execução + revisão humana obrigatória em todo merge. | alta | idem |
| 8 | **Memória governada por classes** (TRANSIENT→FORBIDDEN × ALWAYS/ON-DEMAND/ARCHIVE/NEVER) cortou ~55% do contexto mantendo recall 1.0 (micro-benchmark reproduzível; demonstração de mecanismo, não prova de produção). | média | Squad PR #1145 |
| 9 | **Consolidação com cadência SEM daemon é viável** (claude-memory-compiler): cadência diária *lazy* — o flush da próxima sessão dispara a compilação; hooks de SessionStart reinjetam o índice. Consolidação acontece quando (e só quando) o humano abre sessão. ⚠️ Fonte única, demo-quality; 1 claim irmão sobre detalhes de armazenamento foi REFUTADO 0-3 — validar o *padrão*, não a implementação. | média | github.com/coleam00/claude-memory-compiler |
| 10 | **Arquivos versionados + coding agent VENCEM RAG como memória entre sessões**: 72,5% vs 48,5% do melhor RAG (LongMemEval-V2/AgentRunbook-C, preprint UCLA mai/2026). Suporte quantitativo direto à tese breadcrumbs-em-git. | média | arxiv 2605.12493 |
| 11 | **Loops de reflexão têm o ganho mais bem documentado**: Reflexion 80%→91% pass@1 (peer-reviewed NeurIPS); learnings estruturados reinjetados: +14,3pp (AppWorld/IBM); consolidação estruturada em estágios (REMIND) supera replay bruto (+11,8 a +26,2pts). Caveat: ganho depende de feedback verificável (oracle) e é capability-gated. | média | arxiv 2303.11366 + 2603.10600 + 2606.01223 |
| 12 | **Limite fundamental dos breadcrumbs** (2-1): recall passivo quase perfeito **despenca para 40-60% no uso ativo em decisão** (MemoryArena/RefMem-Bench). Escrever migalhas é fácil; a **absorção na decisão seguinte é o gargalo** — exige consolidação estruturada, não só arquivos no repo. | média | arxiv 2603.07670 + 2602.16313 |
| 13 | **Risco nº1 documentado da auto-melhoria sem gate: reflexão falsa persistida** — crença errada ("API X sempre falha") nunca re-testada, erro auto-reforçante, "can be catastrophic" em agente de longa duração; mitigações (quality gates, contradição, expiração) descritas como necessárias e subdesenvolvidas. **Argumento direto para gate humano na ABSORÇÃO, não só no transporte.** | alta | arxiv 2603.07670 + 2605.29463 + 2604.16548 |

## Tradução para o Onion (resposta às perguntas do maestro)

- **"cron?"** → **Não como base.** Cron vendor = serviço vivo + autonomia-default (achados 1, 3). O
  equivalente soberano validado é o **trigger lazy por sessão** (achados 4, 9) — exatamente o padrão do
  hook `co-evolution-inbox-check.sh`. A extensão ⏰ (review_after vencido) implementada em 2026-07-02 **é**
  a "cadência sem daemon" que a pesquisa valida.
- **"migalhas?"** → **Sim, com dois upgrades obrigatórios**: (a) migalha necessária-mas-não-suficiente
  (achado 12) — o gargalo é a absorção; o índice Tier-0 do diário + `breadcrumb_for`/`next_recommended`
  são a mitigação certa (consolidação estruturada > replay bruto, achado 11); (b) **toda migalha vencida
  (⏰) deve ser RE-TESTADA, não re-carimbada** (achado 13) — reavaliar a validade contra evidência atual é
  o antídoto do erro auto-reforçante.
- **"não podemos ser dependentes"** → confirmado pela evidência: o mundo vendor ata e defaulta autonomia;
  a família repo-nativa (a do Onion) é soberana por construção e tem os benchmarks a favor (achado 10).
- **"gatilho invariável de reflexão"** → o padrão validado é **lazy-por-sessão + gate humano na absorção**:
  ⏰ no boot (transporte/notificação automáticos — atos 1-2) + protocolo de re-teste da migalha na sessão
  (ato 3, humano). Nenhuma fonte sustenta reflexão autônoma persistida sem gate (achado 13 é o contra-caso).
- **Modelo (c) "um responder ao outro"** → o padrão Squad valida o desenho do Onion (drop-box + um
  escritor canônico + hooks determinísticos + revisão humana em todo merge — achados 5, 7). O passo
  seguro é **responder-gated**: a sessão do destino PROPÕE o rascunho ao ver 📬/📥/⏰; o maestro confirma.
  Idéia transplantável adicional: **gate git-nativo por prefixo de branch** (achado 2) se um dia houver
  automação que commite.

## Ressalvas (do próprio harness)

Routines em research preview, Jules v1alpha, Squad é projeto experimental MIT (não produto oficial) e
**opera dentro de 1 repo** — eficácia cross-repo não demonstrada (a pergunta aberta nº1). Benchmarks
acadêmicos fortes são preprints não replicados (autores do método = autores do benchmark em vários).
Evidência de memória vem de domínios adjacentes (diálogo, web-agents) — transferência para diários
git-committed é inferência analógica. **Ninguém mediu o drop-box entre repositórios distintos** — o Onion
está à frente da literatura nesse recorte (oportunidade de virar o post-mortem público que falta).

## Perguntas abertas (da pesquisa)

1. Drop-box escala entre repos com cadências diferentes? (taxa real de conflito/perda)
2. Gate humano na absorção preserva os ganhos do Reflexion ou o atrito anula? (nenhum estudo mede)
3. A vantagem arquivos+agente vs RAG transfere para diários git reais?
4. Existe post-mortem público de reflexões falsas persistidas em produção? (só qualitativo hoje)
