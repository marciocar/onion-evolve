# Pesquisa — Breadcrumbs Inteligentes no SDAAL (LLM-as-VM, markdown-as-bytecode)

> **Data**: 2026-07-02 · **Método**: deep-research harness (run `wf_b1cf8d42-e18`: 5 ângulos, 24
> fontes, 117 claims extraídos → 25 verificados adversarialmente com 3 votos → **19 confirmados,
> 6 refutados, 0 não-verificados** → 7 achados sintetizados; 106 agentes). Encomendada pelo maestro
> em 2026-07-02 ("pesquisa fundamentada ampla — academia + projetos de ponta, sem restrição").
> **Consome**: visão registrada em memória (`sdaal-intelligent-breadcrumbs-vision`) + nota de
> honestidade da instância rhilo (campo-mãe: Argumentation Mining + Knowledge Graphs + Network
> Science). **Alimenta**: futuro ADR de breadcrumbs inteligentes (gated — ver §6).

## 0. TL;DR executivo

A visão **assenta sobre precedentes reais e lacunas genuínas**. O paradigma markdown+YAML-como-
programa é prática estabelecida (Anthropic Agent Skills; progressive disclosure ≈ nosso
gated-until-trigger); LLM-as-VM tem precedente formal desde mai/2024 (CoRE/AIOS). A doutrina
**"re-testar, nunca re-carimbar" ganhou fundamentação empírica forte** (STALE: melhor modelo 55,2%
em detectar memória vencida; MemConflict: melhor sistema 0,2501 em reconhecer contradição) —
reconciliação de contradição é **lacuna real do campo, não hype**. As peças herdadas do KG SDAAL
estão nomeadas com precisão (AIF 2006, ASPIC+, divisiveness 2017); **a combinação completa não foi
encontrada publicada**. Veredito prático: **MENSAGEM e ESTRUTURA DE DECISÃO têm a evidência mais
forte; ARMAZENAMENTO EXECUTÁVEL ficou sem prova sobrevivente** (claims quantitativos refutados
0-3). Menor enabler dogfoodável: **migalha estruturada com validade condicionada à query**,
acoplada ao `review_after` existente.

## 1. Achados confirmados (7, verificação adversarial 3 votos)

### A1 — Markdown+YAML-como-programa é paradigma estabelecido de vendor (3-0 ×3) · confiança ALTA
Agent Skill = diretório com SKILL.md (markdown + frontmatter YAML `name`/`description`) + scripts +
recursos, carregado por **progressive disclosure em 3 níveis** (metadados no boot → corpo sob
demanda → arquivos linkados só quando necessário) — análogo direto dos breadcrumbs
gated-until-trigger. Contexto empacotável "efetivamente ilimitado" (asserção de design do vendor,
não benchmark independente).
Fontes: [anthropic.com/engineering — Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) · [agentskills.io](https://agentskills.io) · [docs Claude Code](https://code.claude.com/docs/en/skills)

### A2 — LLM-as-VM tem precedente formal publicado (3-0, 3-0, 2-1) · confiança ALTA
**CoRE** (AIOS/Yongfeng Zhang, Rutgers, mai/2024): LLM-como-interpretador executando programas de
agente em linguagem natural estruturada; unifica NL + pseudo-código + flow programming sob UMA
representação com steps tipados (Process/Decision/Terminal) e fluxo condicional — precedente
direto do markdown-as-bytecode. ⚠️ Ressalva: o paper NÃO roda ablação estrutura-vs-prosa-livre —
é **precedente representacional, não prova de vantagem**.
Fontes: [arXiv 2405.06907](https://arxiv.org/abs/2405.06907) · [github.com/agiresearch/CoRE](https://github.com/agiresearch/CoRE)

### A3 — "Implicit Conflict" é modo de falha real; nem modelos de fronteira detectam (3-0 ×3) · ALTA
Benchmark **STALE** (400 cenários, 1.200 queries, contextos até 150K): melhor modelo = **55,2%**
em detectar/agir sobre memórias invalidadas; lacuna sistemática entre RECUPERAR evidência nova e
AGIR sobre ela (modelos aceitam premissas vencidas embutidas na query). Corroborado por
MemoryArena (recall passivo ~perfeito cai a 40-60% em uso ativo). **Fundamentação empírica direta
do `review_after`/⏰ e do protocolo de re-teste.**
Fontes: [arXiv 2605.06527](https://arxiv.org/abs/2605.06527) · [2605.20926](https://arxiv.org/html/2605.20926) · [2606.01435](https://arxiv.org/html/2606.01435v1) · [2410.10813](https://arxiv.org/pdf/2410.10813)

### A4 — Estado da arte NÃO resolve reconciliação de contradição (3-0 ×3) · ALTA
**MemConflict** avaliou A-Mem, LangMem, Letta, MemOS, Mem0, Memobase: **nenhum reconhece
contradições de forma confiável** (melhor Conflict Recognition Score: **0,2501**); sistemas acertam
a resposta SEM detectar o conflito. Formaliza validade como *fitness-for-use condicionado à query*
com 3 classes de conflito (**dinâmico, estático, condicional**) — vocabulário mapeável às nossas
migalhas. Nuance: Zep/Graphiti (fora dos 6) já faz invalidação temporal de arestas — o vizinho
mais próximo identificado.
Fontes: [arXiv 2605.20926](https://arxiv.org/pdf/2605.20926) · [2501.13956](https://arxiv.org/abs/2501.13956)

### A5 — Semantic drift + arquitetura dual-track valida grafo+replay+ledger (2-1 ×2) · MÉDIA
Reescrita descontrolada distorce fatos progressivamente (drift). A arquitetura proposta (SSGM):
**grafo ativo mutável + log episódico append-only imutável como fonte de verdade + operador de
reconciliação por replay** — validação conceitual do desenho SDAAL (grafo + replay-como-gate + git
como ledger). ⚠️ Paper conceitual, sem benchmark próprio; drift corroborado por trabalhos
independentes.
Fontes: [arXiv 2603.11768](https://arxiv.org/html/2603.11768v1) · [2505.16067](https://arxiv.org/abs/2505.16067) · [2509.25250](https://arxiv.org/abs/2509.25250)

### A6 — Staleness é problema aberto reconhecido; markdown-as-memory NÃO está no radar acadêmico (3-0 ×2) · MÉDIA
Survey mais recente (mar/2026) prescreve versionamento temporal, detecção de contradição e
"desafiar periodicamente crenças armazenadas" (≈ nosso ⏰/re-teste). Taxonomia nomeia "structured
stores (KGs)" e "executable repositories" como categorias. **Mas: zero ocorrências de memória
markdown/CLAUDE.md/AGENTS.md** (verificado por grep mecânico no HTML) — **a camada
markdown-as-bytecode do Onion está fora do estado da arte mapeado** (oportunidade e risco).
Fontes: [arXiv 2603.07670](https://arxiv.org/html/2603.07670v1) · [2601.02845](https://arxiv.org/abs/2601.02845) · [2606.06240](https://arxiv.org/abs/2606.06240)

### A7 — Posicionamento honesto: herdado vs nosso na camada de argumentação (3-0 ×3) · ALTA
(a) Grafo argumentativo com suporte/conflito é **padronizado há 2 décadas** (AIF 2006; AIFdb:
14.000+ mapas, 160.000 claims) — não é invenção nossa. (b) A teoria (Pollock 1986, ASPIC+)
distingue **rebutting** (ataca proposição), **undercutting** (ataca a INFERÊNCIA) e **undermining**
(ataca premissa) — nosso SUPPORTS/REFUTES binário nó-a-nó é **mais grosseiro que o estado da
arte** (não expressa ataque a arestas). (c) Pesar proposições por sinais estruturais tem precedente
(divisiveness, Lawrence et al. 2017) — PageRank especificamente não consta.
Fontes: [Argument Mining Survey (MIT Press)](https://direct.mit.edu/coli/article/45/4/765/93362/Argument-Mining-A-Survey) · [AIF (Cambridge)](https://www.cambridge.org/core/journals/knowledge-engineering-review/article/abs/towards-an-argument-interchange-format/B5398A5BC5ECB369AF119DE7913558AA) · [AIFdb](https://www.johnlawrence.net/res/pubs/lawrence2014aifdb.pdf) · [AIF spec](http://www.arg-tech.org/wp-content/uploads/2011/09/aif-spec.pdf)

## 2. Refutados na verificação adversarial (6) — e por que importa

Todos os claims de **prova quantitativa de vantagem para armazenamento executável e memória
estruturada-com-estado caíram**:

| Claim refutado | Voto | Implicação para o ADR |
|---|---|---|
| Voyager 15,3× como prova de breadcrumb executável | 0-3 | pilar "armazenamento executável" **sem evidência sobrevivente** |
| MemStrata 0.95–1.00 vs RAG 0.20–0.47 | 0-3 | idem — número não sustentado pela fonte |
| Regra determinística de supersessão é *suficiente* | 0-3 | supersessão ajuda mas não basta sozinha |
| Embeddings *estruturalmente incapazes* (AUROC 0.59) | 1-2 | direção certa, força do claim exagerada |
| Write Validation Gate obrigatório | 0-3 | prescrição de paper conceitual, não achado |
| Decay w(Δτ) formalizado como TTL | 0-3 | fórmula específica não sustentada |

**Leitura correta:** armazenamento executável **não foi refutado como ideia** — ficou **sem prova
de vantagem** nesta rodada. A doutrina manda: medir no próprio fluxo antes de investir (dogfood
como prova, não paper).

## 3. O que é genuinamente NOSSO vs herdado (síntese honesta)

**Herdado (com nome e fonte):** grafo argumentativo suporte/conflito (AIF/AIFdb, 2006);
rebut/undercut/undermine (Pollock/ASPIC+); métricas estruturais de peso (divisiveness 2017);
LLM-as-interpreter (CoRE 2024); progressive disclosure (Anthropic Skills); dual-track
grafo+ledger+replay (SSGM, conceitual); fitness-for-use condicionado à query (MemConflict).

**Não encontrado publicado (candidato a contribuição):** a **combinação completa** — grafo
argumentativo + staleness com re-teste (⏰/`review_after`) + governança DEV↔PROD por plane +
replay-como-gate + **federação git-nativa soberana** (doc-bridge inbox/inbound, entrega-sem-commit,
human-gated). E: **markdown-as-memory não aparece no survey mais recente** — o recorte que o Onion
pratica está fora do mapa acadêmico. ⚠️ Ausência ≠ inexistência: faltou busca dedicada de prior
art em Zep/Graphiti-derivados e multi-agente federado (questão aberta Q1).

## 4. Veredito prático — as 3 capacidades da visão

| Capacidade do breadcrumb | Evidência | Veredito |
|---|---|---|
| **MENSAGEM** (sinal endereçado entre sessões/instâncias) | doc-bridge já dogfoodado; blackboard-pattern com ganho reportado (fonte de busca, não verificada adversarialmente) | ✅ manter e evoluir |
| **ESTRUTURA DE DECISÃO** (campos tipados, validade, conflito explícito) | A2 (estrutura como precedente), A3+A4 (lacuna real que estrutura endereça), A7 (vocabulário maduro disponível) | ✅ **a aposta com mais lastro** |
| **ARMAZENAMENTO EXECUTÁVEL** (migalha que carrega código/estado executável) | A1 (precedente de design: skills embutem scripts) mas **zero prova quantitativa sobrevivente** (§2) | ⚠️ gated — medir em dogfood antes de investir |

## 5. Menor enabler dogfoodável (recomendação)

**Migalha estruturada com validade condicionada à query**, acoplada ao `review_after` existente:
adotar o vocabulário MemConflict no frontmatter do diário — campo `conflict_class:
dynamic|static|conditional` + `valid_when:` (condição de aplicabilidade em 1 linha) — e ensinar o
`/meta:diary review` a re-testar **por classe** (dinâmica: re-verificar contra o artefato; estática:
confrontar fonte; condicional: checar se a condição ainda vale). Custo ~zero (campos novos +
protocolo existente), soberano (git-nativo), e gera o dado que falta: **medir re-absorção entre
sessões com vs sem estrutura** (a ablação que nem CoRE rodou — questão aberta Q2 vira experimento
nosso).

## 6. Gates (doutrina gated-until-trigger)

| Passo | Gate |
|---|---|
| ADR breadcrumbs inteligentes | escrever só após o enabler §5 rodar 1 ciclo real de re-teste por classe |
| Enriquecer SUPPORTS/REFUTES → rebut/undercut/undermine (Q4) | 1º caso real no KG SDAAL onde atacar a INFERÊNCIA (não o nó) mudaria o veredito |
| Armazenamento executável | prova de vantagem em dogfood próprio (métrica: re-absorção/retrabalho) |
| Re-selagem desta pesquisa | ⏰ trimestre (benchmarks têm semanas de idade — caveat 6) |

## 7. Questões abertas (da síntese)

1. **Prior art da combinação completa** — busca dedicada em Zep/Graphiti-derivados e multi-agente federado pendente.
2. **Estrutura vence prosa livre?** Nenhuma ablação existe — candidato a experimento dogfood do Onion (métrica de re-absorção).
3. **Vantagem mensurável de armazenamento executável?** Medir no próprio fluxo (claims externos refutados).
4. **Vale enriquecer o modelo de arestas para ASPIC+?** Undercutting exige atacar arestas; custo em simplicidade determinística a avaliar.

## 8. Caveats (do harness, na íntegra condensada)

1. Pilares empíricos de memória (STALE, MemConflict, SSGM, survey) são **preprints 2026 sem peer
review**; a parte de argumentação é peer-reviewed madura. 2. "Critical and underexplored" é
retórica de autores de benchmark; co-autor de MemConflict é do time MemOS (mitigado). 3.
"Effectively unbounded" da Anthropic é asserção de design. 4. Refutados listados em §2 — o pilar
executável fica sem prova. 5. Ausência ≠ inexistência (§3). 6. Campo move em ciclos de meses —
**revisar antes de selar o ADR se passar de um trimestre**. 7. "Estrutura necessária" (CoRE)
sobreviveu 2-1 sem ablação — precedente de design, não fato.
