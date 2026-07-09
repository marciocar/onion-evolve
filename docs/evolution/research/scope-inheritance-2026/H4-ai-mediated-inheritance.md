# H4 — Herança mediada por IA (o centro SDAAL/KG)

> **Stream H4 do redesign de herança-de-escopo do Sistema Onion (2026).**
> Pergunta: como **versionar, herdar e polimorfar** a entrega do Onion (`.claude` + docs + agentes +
> scripts) através de uma **hierarquia de escopos** — framework → empresa → time → pessoa — **mediada
> por IA generativa** (SDAAL/KG/dogfood no centro), **seguindo a corrente do mercado** (Claude Code é o
> vetor) e **sem criar atrito**. Gatilho concreto: **Grana.Ai** (fintech regulada, monorepo nx privado,
> time de devs + stage/prod; dentro dela empresa/times/pessoas, cada um querendo sua camada de
> `.claude`/docs herdando do pai e podendo **sobrepor**).
>
> **Foco deste stream:** como sistemas de IA generativa **compõem/herdam PROMPTS, AGENTES e
> CONHECIMENTO por escopo** — não só config estática. O ângulo é o **polimorfismo SDAAL**: a mesma
> base (spec/doc/agente) **resolvida diferente** pelo contexto do escopo inferior; e o **SUPERSEDES do
> KG** (conhecimento novo supera sem apagar).
>
> **Natureza:** insumo de evidência para a decisão do maestro — **não decide doutrina**. Cada achado
> material carrega FONTE (URL) + materialidade. Sem fonte sólida = `hypothesis`/materialidade `low`.
> Prioridade a fontes primárias (docs oficiais Anthropic/OpenAI/MCP, specs, papers) e ao recorte
> 2024–2026.

---

## Resumo

A corrente do mercado é inequívoca e conveniente para o Onion: **a herança de escopo em sistemas de IA
generativa não acontece por _branch_ — acontece na _montagem de contexto_ (context assembly), por
composição ordenada do mais amplo ao mais específico.** O próprio vetor (Claude Code) **já implementa
uma cascata nativa de 4 camadas** exatamente no eixo framework→empresa→time→pessoa: os arquivos
`CLAUDE.md` de todas as camadas (managed policy → user → project → local, mais `.claude/rules/` e
subdiretórios) são **concatenados, não sobrescritos**, "ordered from the filesystem root down to your
working directory" — instruções mais próximas de onde você lança o Claude são lidas **por último** e
por isso vencem (H4·F1). Isso é a **generalização N-camadas** que o `resolve-integration-branch.sh` e o
`vendor-branch.sh` (hoje bilaterais/2 camadas) precisam — **e o mecanismo já existe fora do Onion, é
nativo, e é não-atrito**.

Sobre **por que não é branch**: o mercado separa dois planos que o Onion hoje confunde. (a) **Composição
de arquivos/prompts** = _overlay/concatenação_ resolvida em runtime cognitivo (Claude Code cascade;
Kustomize base→overlay; MCP prompts/resources/roots) — H4·F1, F6, F7, F8. (b) **Versionamento de
CONHECIMENTO/verdade** = _supersessão bitemporal_, um eixo **ortogonal** ao merge de arquivos — o Zep/
Graphiti confirma, com fonte primária, que "superseded facts are invalidated, not deleted", cada fato
com **janela de validade + proveniência** (H4·F5). Isso é o análogo direto e já-provado do **SUPERSEDES
do KG do Onion** — e prova a intuição "git merge não reconcilia verdades": são **dois mecanismos
diferentes**, não um.

O **polimorfismo SDAAL** ("base resolvida diferente pelo contexto do escopo inferior") tem lastro
teórico forte em duas specs de fronteira: o **Model Spec da OpenAI** (chain of command Root→System→
Developer→User→Guideline) distingue **defaults que o escopo inferior sobrepõe _explicitamente_** de
**guidelines sobrepostas _implicitamente_ por pistas de contexto/histórico** (H4·F3) — que é
precisamente a diferença entre "override de arquivo" e "distilled = doutrina reescrita pelo contexto".
A **Constituição do Claude** (Anthropic, jan/2026) reforça: virou **reason-based, não rule-based** —
herda-se o _porquê_, e o escopo inferior re-resolve o _como_ (H4·F4). A **hierarquia de instrução**
(OpenAI, 2024) dá o substrato de segurança/precedência tipada (H4·F2).

Para **agentes**, o Claude Code já resolve colisão de subagentes por precedência de escopo
(session > project > user > plugin) e tem **herança de ferramentas** (herda tudo por padrão; allowlist/
`disallowedTools`; `model: inherit`) — o análogo direto do `roles.yaml`/`resolve-role-bundle.sh` (H4·F6).
Para **distribuição por escopo** (o "empresa/time" da entrega), o **plugin marketplace** da Anthropic
tem **override de grupo herdando a preferência org-wide** — "every group inherits that organization-wide
setting … a group-level override replaces the org-wide setting for members of that group" (H4·F9): é o
framework→empresa→time em produção, com precedência+proveniência explícitas. Para **conhecimento escopado**
(RAG/KG por empresa/time/pessoa), **namespaces** de vetor (Pinecone) são o "sandbox" de isolamento
hierárquico já idiomático (H4·F10), e a literatura de **memória de agente** (2025–2026) escopa memórias
a user/session/agent com **controle de acesso dinâmico** para memória colaborativa multi-usuário (H4·F11).

**Veredito de mecanismo (deste stream):** **híbrido, com a cascata nativa do Claude Code como espinha
dorsal.** Branches **não** são o mecanismo de composição (não se compõe fazendo checkout; ninguém fica
em 4 branches). Branches servem como **transporte/proveniência** (o `vendor-branch` como _base herdada_
importada, o ledger de federação) — não como o plano onde a herança **compõe**. A composição vive em
**cascade-nativa** (arquivos/prompts, ordenada amplo→específico) + **merge-N-camadas** (overlay estilo
Kustomize/strategic-merge quando é override _estrutural_, generalizando o `vendor-branch` de 2→N) +
**SUPERSEDES bitemporal** (conhecimento/verdade, eixo ortogonal ao merge de arquivo). Ver §Veredito.

---

## Achados

### H4·F1 — Claude Code JÁ tem a cascata N-camadas framework→empresa→time→pessoa: CLAUDE.md é CONCATENADO (não sobrescrito), ordenado do mais amplo ao mais específico
**Claim:** O mercado-vetor já resolve o problema central deste redesign, nativamente. As 4 camadas de
`CLAUDE.md` mapeiam **exatamente** no eixo de escopo do Onion: **managed policy** (org/empresa,
`/etc/claude-code/CLAUDE.md`, "cannot be excluded by individual settings") → **user** (`~/.claude/CLAUDE.md`,
pessoa, todos os projetos) → **project** (`./CLAUDE.md` ou `./.claude/CLAUDE.md`, time via source control)
→ **local** (`./CLAUDE.local.md`, pessoa neste repo, gitignored). O mecanismo de herança é
**concatenação, não override**: *"All discovered files are concatenated into context rather than
overriding each other. Across the directory tree, content is ordered from the filesystem root down to
your working directory … so instructions closer to where you launched Claude are read last."* Há ainda:
(a) `.claude/rules/*.md` **path-scoped** por glob (`paths:` frontmatter) — regra carrega só quando a IA
toca arquivos casados; (b) `@path` **imports** recursivos até **4 hops** (composição de fragmentos);
(c) `claudeMdExcludes` para **monorepo** pular CLAUDE.md de outros times ("Arrays merge across layers");
(d) rules compartilháveis via **symlink** entre projetos. Managed CLAUDE.md **não pode** ser excluído —
o piso de compliance é inviolável.
**Fonte:** https://code.claude.com/docs/en/memory (docs oficiais, primária)
**Materialidade:** ALTA — é o achado central. **Implicação p/ Onion:** a "sub-repo scoping" que o
grounding marca como _gap que não existe em nenhum eixo_ **existe nativa** via monorepo + subdiretório
CLAUDE.md + `.claude/rules/` path-scoped + `claudeMdExcludes`. O Onion deve **parar de reinventar** e
**gerar** a cascata (managed=empresa, user=pessoa, project=time, subdir/rules=sub-repo). **Base reusável:**
generaliza o `resolve-integration-branch.sh` (precedência por camadas) de N=cadeia-de-config para
N=cadeia-de-contexto; é o **veículo óbvio das camadas nativas** que o grounding aponta como inexploradas.

### H4·F2 — Hierarquia de instrução: precedência TIPADA por privilégio é padrão de fronteira (OpenAI, 2024)
**Claim:** A "The Instruction Hierarchy: Training LLMs to Prioritize Privileged Instructions"
(Wallace et al., 2024) estabelece que o modelo deve **priorizar instruções privilegiadas** (system) sobre
as de menor privilégio (developer/user/terceiros), definindo explicitamente o comportamento **quando
instruções de prioridades diferentes conflitam** — o modelo aprende a **ignorar seletivamente** a de menor
privilégio. Ganho medido de robustez até ~63% mantendo funcionalidade.
**Fonte:** https://openai.com/index/the-instruction-hierarchy/ · arXiv: https://arxiv.org/html/2404.13208v1
(primária)
**Materialidade:** ALTA — dá o **substrato formal de precedência entre camadas** (por que o escopo
superior às vezes _vence_ e às vezes _cede_). **Implicação p/ Onion:** a resolução de conflito
framework↔empresa↔time↔pessoa não é ad-hoc; deve declarar **qual camada é privilegiada para qual tipo
de regra** (ex.: managed/compliance = inviolável; doutrina de time = default sobreponível pela pessoa).
**Base reusável:** formaliza a cadeia de precedência do `resolve-integration-branch.sh` como
**política tipada**, não só "primeiro que casar vence".

### H4·F3 — Model Spec (OpenAI): chain of command distingue defaults sobreponíveis EXPLICITAMENTE de guidelines sobreponíveis IMPLICITAMENTE — o núcleo do polimorfismo SDAAL
**Claim:** O Model Spec (rev. 2025-12-18) estrutura autoridade em **Root → System → Developer → User →
Guideline**. Crucial para o Onion: distingue **user-level defaults** (que "users or developers can
**explicitly** override") de **guidelines** ("instructions that can be **implicitly** overridden … from
contextual cues, background knowledge, or user history"). Root é **prohibitivo e inviolável** ("cannot be
overridden by system or any other message"). Conflito entre dois princípios root → **default à inação**.
**Fonte:** https://model-spec.openai.com/2025-12-18.html (spec oficial, primária)
**Materialidade:** ALTA — é o **modelo mais fino de polimorfismo por escopo** que o mercado tem.
**Implicação p/ Onion:** dá vocabulário preciso para as 3 formas de herança que o Onion mistura:
(1) **inviolável** (managed/compliance = Root — nunca sobreponível); (2) **default explícito** (base do
framework/time que o escopo inferior sobrescreve por _arquivo_ = override estrutural, o `vendor-branch`);
(3) **guideline implícita** (doutrina que o `*-context` local **re-resolve pelo contexto** — o "distilled"
do grounding, herança de doutrina reescrita, não de arquivo). **Base reusável:** eleva o
`resolve-role-bundle.sh` (`distilled`) e o SDAAL (`base spec + contexto local`) a uma taxonomia com
lastro de spec: `distilled` ≈ guideline implicitamente sobreponível.

### H4·F4 — Constituição do Claude (Anthropic, jan/2026): virou reason-based, não rule-based — herda-se o PORQUÊ, o escopo inferior re-resolve o COMO
**Claim:** A nova Constituição do Claude (22/jan/2026) "shifts from rule-based to **reason-based** AI
alignment, explaining the **logic behind** ethical principles rather than prescribing specific behaviours
… explains **why** Claude should behave in certain ways, not merely **what** it should do", sob uma
**hierarquia de prioridade** explícita (segurança/oversight → ética → guidelines Anthropic → ser útil).
**Fonte:** https://www.anthropic.com/news/claudes-constitution (primária)
**Materialidade:** MÉDIA-ALTA — valida arquiteturalmente a aposta do Onion em **doutrina como spec que a
IA simula** (SDAAL), não como regra rígida. **Implicação p/ Onion:** a herança de doutrina entre escopos
deve transmitir **razões** (que o escopo inferior recompõe ao seu contexto), não só arquivos congelados —
é o que torna a herança **não-atrito**: o time/pessoa não precisa "editar o pai", só adicionar contexto
que re-resolve o porquê herdado. **Base reusável:** fundamenta os `*-context` locais (SDAAL = base do
framework + contexto local que especializa o vertical em runtime cognitivo).

### H4·F5 — Grafo de conhecimento temporal (Zep/Graphiti): supersessão BITEMPORAL "invalida, não apaga" — o análogo primário do SUPERSEDES do KG, e prova que é eixo ORTOGONAL ao merge de arquivo
**Claim:** Zep/Graphiti (arXiv 2501.13956, jan/2025; Graphiti 20k+ estrelas) implementa **rastreamento
bitemporal**: cada fato carrega **valid time** (verdade no mundo) + **ingestion/provenance time**;
"**superseded facts are invalidated, not deleted**"; cada fato tem **janela de validade + proveniência**,
e a chegada de informação nova **invalida o fato superado** sem removê-lo (permite raciocínio sobre
correções/retroatividade).
**Fonte:** https://arxiv.org/abs/2501.13956 · https://github.com/getzep/graphiti (primária — paper +
implementação)
**Materialidade:** ALTA — é a **prova de mercado, com fonte primária, do SUPERSEDES do Onion**, e
resolve a ambiguidade central do stream. **Implicação p/ Onion:** o versionamento de **conhecimento**
(verdade que supera verdade) é **um mecanismo separado** do versionamento de **arquivos** (merge/overlay).
"Git merge não reconcilia verdades" está **certo** — a reconciliação de verdade é bitemporal-supersede,
não 3-way-merge. O `meta:kg` (SUPERSEDES) e o `vendor-branch` (3-way merge) **não devem convergir**: são
os dois eixos ortogonais da herança. **Provenance-por-camada** cai naturalmente do `provenance time`.
**Base reusável:** valida e nomeia o **SUPERSEDES do KG** como o 3º dos 4 pilares; dá a semântica
bitemporal que hoje o KG não formaliza.

### H4·F6 — Subagentes do Claude Code: precedência de escopo (session>project>user>plugin) + herança de ferramentas configurável — o análogo direto do roles.yaml/resolve-role-bundle
**Claim:** Subagentes vivem em 4 locais com escopo/prioridade distintos; na colisão de nomes a resolução
é **estrita: session-defined > project (`.claude/agents/`) > user (`~/.claude/agents/`) > plugin**.
Herança de capacidade: "**Agents inherit all session tools by default**; o campo `tools` cria allowlist
explícita, `disallowedTools` remove do conjunto herdado"; `model: inherit` herda o modelo da conversa
principal. Project-level = especialistas compartilhados do time (commitados); user-level = ferramentas
pessoais em todo projeto.
**Fonte:** https://code.claude.com/docs/en/sub-agents (docs oficiais, primária)
**Materialidade:** ALTA — mostra que **agente base especializado por sub-escopo já é nativo**, com o
mesmo eixo project=time/user=pessoa. **Implicação p/ Onion:** os 51 agentes do Onion podem ser
**especializados por escopo** (o time sobrepõe o `@code-reviewer` do framework; a pessoa sobrepõe o do
time) **sem branch** — só posicionando o arquivo na camada certa, com override por nome. **Base reusável:**
é o `roles.yaml` + `resolve-role-bundle.sh` (polimorfismo de bundle por papel) **já implementado pelo
vetor**; o Onion deve mapear seu polimorfismo de papel na resolução nativa de subagente + herança de tools.

### H4·F7 — MCP: Prompts (templates reusáveis), Resources e Roots (escopo de workspace) são primitivas de escopo de PROMPT e CONHECIMENTO
**Claim:** O MCP (spec 2025-11-25) expõe primitivas relevantes ao escopo: **Prompts** = "predefined
instruction templates … standardize how models perform common tasks … ensure consistency and best
practices **across teams**"; **Resources** = dados/contexto legíveis (estático/semi-estático); **Roots**
= "define the workspace or filesystem **boundaries** … security scoping … the IDE exposes the current
project directory as a root … operates within the defined **project scope**".
**Fonte:** https://modelcontextprotocol.io/specification/2025-11-25 · https://workos.com/blog/mcp-features-guide
(primária + secundária)
**Materialidade:** MÉDIA — dá primitivas padronizadas para **servir prompt/conhecimento escopado** por
transporte neutro. **Implicação p/ Onion:** um servidor MCP por escopo (empresa/time) poderia servir
**Prompts** e **Resources** herdáveis, com **Roots** delimitando o sub-repo — encaixe natural com a
abstração forge/task-manager (SDAAL) do Onion, que já trata MCP como **transporte opcional**. **Base
reusável:** conversa com a doutrina SDAAL (adapter API-first, MCP opcional); Roots ≈ o "sub-repo scoping"
como fronteira de segurança.

### H4·F8 — Kustomize (base→overlay, strategic merge): o padrão de mercado para herança de config por composição N-camadas, sem branch — e a recomendação de manter raso
**Claim:** Kustomize modela herança por **base + overlay**: "a base has **no knowledge of an overlay** and
can be used in **multiple overlays**"; overlay "may refer to **multiple bases**, combining all resources
into a unified configuration". O merge é **strategic-merge** ("replace scalars, **merge maps**, use
**merge keys for lists**") com overlay sobrepondo a base por chave. Boas práticas: "**Keep hierarchies
shallow. Three levels (base → shared → overlay) usually suffice**" — deep inheritance vira difícil de
entender.
**Fonte:** https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/ (docs oficiais K8s,
primária)
**Materialidade:** ALTA — é o **mecanismo de referência do mercado** para exatamente "herdar do pai e
sobrepor", provando que **overlay/merge-N-camadas > branch** para composição, e que **a base não conhece
os overlays** (desacoplamento = não-atrito). **Implicação p/ Onion:** generaliza o `vendor-branch.sh`
(3-way merge base-herdada + override-local) de **2 camadas bilaterais → N camadas de overlay**; o
strategic-merge (merge maps, merge-key em listas) é a semântica exata que falta. **Aviso de campo:**
"mantenha raso" — 4 escopos (framework→empresa→time→pessoa) já está no limite; não crie sub-níveis extras.
**Base reusável:** é o `vendor-branch.sh` N-ificado — o coração do "merge-N-camadas".

### H4·F9 — Plugin marketplace da Anthropic: distribuição por escopo com override de GRUPO herdando a preferência org-wide — o framework→empresa→time de entrega, em produção
**Claim:** Enterprise: cada plugin tem **preferência org-wide** (Installed by default / Available /
Required / Not available). "**By default, every group inherits that organization-wide setting. When you
set a group-level override for a plugin, it replaces the org-wide setting for members of that group**" —
grupos manuais ou provisionados por SCIM. `strictKnownMarketplaces` (managed settings) restringe fontes.
Plugins **empacotam skills + hooks + agentes + comandos + MCP** para distribuição de time.
**Fonte:** https://support.claude.com/en/articles/13837433-manage-plugins-for-your-organization ·
https://code.claude.com/docs/en/plugin-marketplaces (docs oficiais, primária)
**Materialidade:** ALTA — é **literalmente** o eixo framework→empresa→time da **entrega** (não só do
contexto), com **herança + override + proveniência de camada** explícitos. **Implicação p/ Onion:** a
entrega do Onion (`.claude` como bundle) pode ser um **plugin/marketplace** onde empresa define o default
e o time sobrepõe — sem clonar/branchar. Encaixa a nota do grounding "org-marketplace groups". **Base
reusável:** é o veículo de distribuição das **camadas nativas**; o `resolve-role-bundle` (bundles por
papel) pode virar **plugins por escopo** com a herança grupo⊃org já pronta.

### H4·F10 — Namespaces de vetor (Pinecone): isolamento hierárquico de CONHECIMENTO escopado por tenant, com filtro de metadado — o RAG/KG por empresa/time/pessoa
**Claim:** "Records are stored in **namespaces** … a namespace is a **sandbox** within an index. Vectors
in Namespace A are **completely invisible** to a search in Namespace B" — isolamento por tenant sem
penalidade de performance; **metadata filtering** (`tenant_id`, category, user_id) para recorte fino;
namespaces são "**stronger and more efficient boundary** for multi-tenancy" que filtro de metadado; até
10.000 namespaces/índice. Offboard = deletar namespace.
**Fonte:** https://docs.pinecone.io/guides/index-data/implement-multitenancy (docs oficiais, primária)
**Materialidade:** MÉDIA-ALTA — é o padrão idiomático de **conhecimento escopado hierárquico** para RAG.
**Implicação p/ Onion:** o conhecimento vivo (KB/`*-context`/KG) por empresa/time/pessoa mapeia em
**namespaces** (isolamento forte) + **metadata** (recorte por escopo dentro do namespace), com herança
via **consulta em cascata** (busca no namespace da pessoa → do time → da empresa → do framework, primeiro
match vence — o mesmo padrão do F1). **Base reusável:** dá substrato de armazenamento ao SUPERSEDES do KG
(F5) e ao `*-context` (F4) quando o conhecimento escala além de arquivos markdown.

### H4·F11 — Memória de agente escopada (2025–2026): memórias por user/session/agent + memória colaborativa multi-usuário com CONTROLE DE ACESSO DINÂMICO
**Claim:** A literatura recente (survey "Memory in the Age of AI Agents"; Mem0; Bi-Mem; "Collaborative
Memory") converge em memória **escopada e hierárquica**: "atomic memory facts, **scoped to users,
sessions, or agents** … metadata for filtering by user, session, or application, where a **single
instance can serve multiple agents or user populations with scoped retrieval**"; e pesquisa em
**collaborative memory** para "multi-user memory sharing in LLM agents with **dynamic access control**".
Arquiteturas hierárquicas (HiMem, G-Memory) com reconsolidação _conflict-aware_.
**Fonte:** https://github.com/Shichun-Liu/Agent-Memory-Paper-List · https://mem0.ai/blog/state-of-ai-agent-memory-2026
(secundária + índice de primárias)
**Materialidade:** MÉDIA — mostra que **memória por escopo com controle de acesso** é frente ativa, não
resolvida-mas-em-consolidação. **Implicação p/ Onion:** o `auto memory` do Claude Code já é **per-repo**
(F1 adjacente); a herança de memória pessoa⊂time⊂empresa precisa de **controle de acesso** (o que a
pessoa vê do time; o que o time compartilha) — direção para a federação do Onion. **Reconciliação
conflict-aware** ≈ o radar do `meta:kg`. **Base reusável:** informa como a camada pessoal (`user`,
`CLAUDE.local.md`, auto-memory) herda/compartilha com a do time sem vazar escopo.

### H4·F12 — Layered Context Management / Context Engineering: a virada de "prompt" para "montagem de contexto em camadas lógicas priorizáveis"
**Claim:** A indústria consolidou (2025) o **Context Engineering / Layered Context Management (LCM)**:
"context organized into **logical layers** instead of a monolithic block … easier to manage, prioritize,
and **prune** … explicit management of the **importance** of different context types ensures critical
instructions aren't accidentally pruned"; uma **Prompt Composition Layer** gera templates parametrizados
reusáveis via orquestrador.
**Fonte:** https://dev.to/jefejica/beyond-basic-prompts-architecting-robust-ai-with-model-context-protocol-mcp-layered-context-450j
(secundária/industrial) — `hypothesis` de reforço, não fonte primária
**Materialidade:** BAIXA-MÉDIA — corroboração da **direção** (camadas + prioridade + prune), sem
autoridade de spec. **Implicação p/ Onion:** a herança de escopo deve carregar **prioridade/importância
por item** (não só ordem), para o prune sob orçamento de contexto não descartar a camada de compliance —
casa com o `claudeMdExcludes`+managed-inviolável do F1. **Base reusável:** reforça que a cascata (F1) é
**assembly com prioridade tipada** (F2/F3), não concatenação cega.

---

## Veredito de mecanismo (deste stream)

**Recomendação: HÍBRIDO, com a cascata nativa do Claude Code como espinha dorsal — e branches rebaixadas
a transporte/proveniência, não a mecanismo de composição.**

Avaliação dos 4 candidatos sob a lente deste stream (composição cognitiva de prompts/agentes/conhecimento):

| Mecanismo | Veredito | Evidência-chave |
|---|---|---|
| **Branches** (o exemplo do maestro) | **REJEITADO como mecanismo de composição** | Ninguém compõe fazendo checkout de 4 branches; a herança precisa **somar em runtime**, e todo o mercado compõe na **montagem de contexto**, não no VCS. Branch permanece útil como **transporte de base herdada** (o `vendor-branch` importado) e **proveniência/ledger** — não como o plano onde compõe. |
| **Overlays** | **FORTE (para override estrutural)** | Kustomize base→overlay + strategic-merge (F8); base não conhece overlays (desacoplamento não-atrito); é o `vendor-branch` N-ificado. |
| **Cascata-nativa** | **ESPINHA DORSAL (para prompts/docs/agentes)** | Claude Code **já** concatena CLAUDE.md amplo→específico nas 4 camadas exatas (F1), resolve subagente por escopo (F6), distribui por grupo herdando org (F9). É o caminho de **menor atrito e maior alinhamento à corrente**. |
| **Merge-N-camadas** | **NECESSÁRIO onde há override estrutural de arquivo** | Generaliza `resolve-integration-branch.sh` (F2) + `vendor-branch.sh` (F8) de 2→N; strategic-merge dá a semântica (merge maps, merge-key em listas). |
| **SUPERSEDES bitemporal** (eixo ORTOGONAL) | **OBRIGATÓRIO para conhecimento/verdade** | Zep/Graphiti (F5): verdade nova **invalida sem apagar**, com valid-time + provenance-time. É um **eixo separado** do merge de arquivo — confirma "git merge não reconcilia verdades". |

**Síntese do mecanismo:** três planos, não um.
1. **Prompts/docs/agentes (config cognitiva)** → **cascade-nativa** (Claude Code CLAUDE.md/rules/imports/
   subagentes), ordenada framework→empresa→time→pessoa, concatenação com **precedência tipada** (F2/F3:
   managed=Root inviolável; time=default explícito; pessoa=override; doutrina=guideline implícita).
2. **Override estrutural de arquivo/bundle** → **overlay/merge-N-camadas** estilo Kustomize (F8),
   generalizando o `vendor-branch` — para quando concatenar não basta e é preciso **substituir/mesclar
   por chave**.
3. **Conhecimento/verdade** → **SUPERSEDES bitemporal** (F5), eixo ortogonal, com proveniência-por-camada
   nativa (o `provenance time` responde "qual camada contribuiu o quê").

**Não-atrito & proveniência (lente transversal):** os três planos são **legíveis e a IA já os monta** —
seguir a corrente é _posicionar arquivos na camada certa_ (F1/F6) e _publicar bundles por grupo_ (F9), não
inventar orquestração de branch. A proveniência-por-camada sai de graça: ordem de concatenação (F1),
override de grupo⊃org (F9), e provenance-time do KG (F5) já dizem **qual escopo contribuiu cada pedaço**.

---

## Encaixe Grana.Ai

**Caso:** fintech regulada, monorepo **nx** privado, time de devs + stage/prod; dentro dela
empresa (Grana.Ai) ⊃ times (ex.: `desenvolvimento`) ⊃ pessoas (ex.: `mauricio`), cada um querendo sua
camada de `.claude`/docs herdando do pai e podendo sobrepor. `integration_branch: develop`, regulado
(nunca live-pull — ver stream G1).

**Resolução concreta, sem branches de escopo, seguindo a corrente:**

1. **Framework (Onion)** → entregue como **base herdada** via `vendor-branch` (transporte) **e/ou** como
   **plugin/marketplace** (F9). É a camada mais ampla; imutável do ponto de vista dos escopos abaixo (a
   base não conhece os overlays — F8).
2. **Empresa (Grana.Ai)** → **managed policy CLAUDE.md** + **managed-settings** (`claudeMd`,
   `permissions.deny`, `strictKnownMarketplaces`) na raiz do monorepo (F1/F9). Aqui mora o **piso de
   compliance inviolável** (Root/managed — F2/F3): "nunca live-pull", `integration_branch: develop`,
   políticas regulatórias. **Nenhum time/pessoa sobrepõe** — é o que o regulado exige.
3. **Time (`desenvolvimento`)** → **`./.claude/CLAUDE.md` + `.claude/rules/*.md`** do subdiretório do
   time no monorepo nx (F1), commitado (compartilhado via source control). Herda a empresa por
   concatenação; **sobrepõe** por default explícito (F3). O `claudeMdExcludes` isola CLAUDE.md de **outros
   times** do monorepo (F1) — é a **sub-repo scoping que o grounding dava como inexistente, e é nativa**.
   Agentes do time em `.claude/agents/` do subdir sobrepõem os do framework por nome (F6).
4. **Pessoa (`mauricio`)** → **`~/.claude/CLAUDE.md`** (preferências cross-projeto) + **`CLAUDE.local.md`**
   gitignored no repo (preferências pessoais neste monorepo) + auto-memory per-repo (F1/F11). Lida por
   último → **vence** onde não colide com managed/compliance.
5. **Conhecimento vivo** (KB/`*-context`/KG do Grana.Ai) → **SUPERSEDES bitemporal** (F5) para verdades de
   negócio/compliance que evoluem (nova regra regulatória **supera** a antiga sem apagar, com proveniência);
   se escalar além de markdown, **namespaces** por empresa/time/pessoa (F10) com consulta em cascata.
6. **Polimorfismo SDAAL** (o que faz herdar-sem-atrito): a doutrina do framework/empresa é **guideline
   reason-based** (F3/F4); o **`*-context` local** do time/pessoa **re-resolve o vertical** em runtime
   cognitivo — o `mauricio` não edita o pai, só adiciona contexto que especializa a base herdada.

**Resultado:** a hierarquia framework→empresa→time→pessoa do Grana.Ai é **montada em contexto** a cada
sessão (concatenação amplo→específico, precedência tipada), com **compliance inviolável no topo** (managed),
**override estrutural** onde preciso (overlay/vendor-branch N-ificado), e **verdade versionada** por
SUPERSEDES — **tudo já suportado pelo vetor, sem manter ninguém em 4 branches ao mesmo tempo**. O único
_gap de engenharia_ do Onion é **gerar e resolver** essa cascata N-camadas (hoje 2, bilateral) e **casar**
seus 4 pilares (`resolve-integration-branch`, `vendor-branch`, SUPERSEDES, camadas nativas) sobre ela — não
inventar mecanismo novo.

---

## Verificação adversarial

> **Passe adversarial (2026-07-09)** fechando a lacuna do retorno estruturado não-entregue pelo agente
> original. Doutrina "evidência ou abstenção": tentei **refutar** cada achado material (materialidade
> high/medium — F12 é `low` e fica fora), checando a fonte primária com WebFetch/WebSearch. Verdicts:
> **confirmed** = fonte primária sólida sustenta o claim; **hypothesis** = plausível mas sem primária
> forte / sourcing secundário; **refuted** = fonte errada/contradita. Onde há **estatística declarada mas
> não verificável na primária**, marco `declarado≠verificado` na nota (o veredito do achado como um todo
> pode continuar `confirmed` se o *mecanismo* se sustenta e só um número ancilar falha).

| finding_id | veredito | nota |
|---|---|---|
| **H4·F1** | **confirmed** | Verbatim na primária (`code.claude.com/docs/en/memory`): *"All discovered files are concatenated into context rather than overriding each other … ordered from the filesystem root down to your working directory … instructions closer to where you launched Claude are read last."* As 4 camadas (managed `/etc/claude-code/CLAUDE.md` "cannot be excluded", user `~/.claude/CLAUDE.md`, project `./CLAUDE.md`, local `CLAUDE.local.md`), `.claude/rules/` com `paths:` glob, `@path` imports até **4 hops**, e `claudeMdExcludes` ("Arrays merge across layers") batem todos com o texto oficial. Pilar central — **sólido**. |
| **H4·F2** | **confirmed** | Paper real (`arXiv:2404.13208`, Wallace et al.). Abstract confirma o mecanismo: *"teaches LLMs to **selectively ignore** lower-privileged instructions"* + *"drastically increases robustness … while imposing minimal degradations"*. **Ressalva:** o número *"~63%"* **não** aparece no abstract público (está no corpo do paper, se existir) — `declarado≠verificado` para a cifra exata; o mecanismo de precedência tipada está confirmado. |
| **H4·F3** | **confirmed** | Verbatim no Model Spec (`model-spec.openai.com/2025-12-18`): cadeia Root>System>Developer>User>Guideline; *"Unlike user defaults that can only be explicitly overridden, guidelines can be overridden **implicitly** (e.g., from contextual cues, background knowledge, or user history)"*; Root *"cannot be overridden by system (or any other) messages"*; *"When two root-level principles conflict, the model should default to inaction."* Núcleo do polimorfismo SDAAL — **sólido**. |
| **H4·F4** | **confirmed** | Claim e priority-hierarchy sustentados por múltiplas fontes 2026 (Anthropic, BISI, Forbes 22/jan/2026): *"shifting from rule-based to reason-based AI alignment that explains the logic behind ethical principles rather than prescribing specific behaviours"* + hierarquia 4-tier (safety→ethics→compliance→helpfulness). **Ressalva de sourcing:** o WebFetch direto de `anthropic.com/news/claudes-constitution` devolveu conteúdo do CAI clássico (critique-and-revise), não as frases citadas; a URL primária canônica parece ser `anthropic.com/news/claude-new-constitution` / `anthropic.com/constitution`. Imprecisão de URL, **não** de claim — as citações conferem. |
| **H4·F5** | **confirmed** | Verbatim na primária (Graphiti, getzep): *"Each fact … has a validity window: when it became true, and when (if ever) it was **superseded**"* + *"When information changes, old facts are **invalidated — not deleted**"* + query "what was true at any point in time". Análogo direto do SUPERSEDES do KG — **sólido**. **Nota fina:** os docs enquadram como *validity windows + episodes (proveniência)*; o rótulo estrito **"bitemporal"** (valid-time × transaction-time como 2 eixos) vem do paper Zep (`arXiv:2501.13956`), cujo abstract público não detalha a mecânica — mas a semântica invalidar-sem-apagar está confirmada. |
| **H4·F6** | **confirmed** | Primária (`code.claude.com/docs/en/sub-agents`) confirma precedência por escopo (*"When multiple subagents share the same name, Claude Code uses the one from the higher-priority location"*) e herança de ferramentas: `tools` *"Inherits all tools if omitted"*, `disallowedTools` *"removed from inherited … list"*, `model` *"Defaults to `inherit`"*. **Nota:** a ordem exata do achado (session>project>user>plugin) omite o tier **managed**, que na verdade *"take precedence over project and user subagents"* — precisão incompleta, não erro material. |
| **H4·F7** | **confirmed** | Primária (spec MCP 2025-11-25) confirma as primitivas: *Resources* = "Context and data, for the user or the AI model to use"; *Prompts* = "Templated messages and workflows"; *Roots* = "URI or filesystem **boundaries** to operate in". O mapeamento prompt/resource/root↔escopo se sustenta. **Nota:** as frases de sabor ("across teams", "security scoping") vêm da fonte secundária (WorkOS), não da spec — o núcleo é primário. Materialidade média, ok. |
| **H4·F8** | **confirmed** | Base→overlay confirmado na primária citada (`kubernetes.io/.../kustomization/` + glossário): *"a base has no knowledge of an overlay and can be used in multiple overlays"*; overlay *"may refer to multiple bases, combining all the resources … into a unified configuration"*. **Ressalva de atribuição (declarado≠verificado):** a citação *"Keep hierarchies shallow. Three levels (base → shared → overlay) usually suffice"* **NÃO** está na página oficial K8s citada — é meme de best-practices de **blogs secundários** (oneuptime/medium). O conselho é real e amplamente sustentado, mas a fonte primária atribuída não o contém. |
| **H4·F9** | **confirmed** | Verbatim na primária (`support.claude.com/.../manage-plugins`): *"By default, every group inherits that organization-wide setting"* + *"When you set a group-level override for a plugin, it replaces the org-wide setting for members of that group."* Os 4 valores (Installed by default / Available / Required / Not available) e SCIM confirmados. **Nota:** `strictKnownMarketplaces` não aparece **nesse** artigo (é managed setting documentado noutra página) — o eixo org⊃grupo, que é o coração do achado, está sólido. |
| **H4·F10** | **confirmed** | Mecanismo confirmado na primária (`docs.pinecone.io/.../implement-multitenancy`): namespace = isolamento físico por tenant, invisível cross-namespace, e *mais forte/eficiente que metadata filtering* (100 RU→1 RU no exemplo). **ESTATÍSTICA ERRADA (declarado≠verificado):** *"até 10.000 namespaces/índice"* é **incorreto** — o 10.000 é o limite de valores do operador `$in` de **metadata**, não um teto de namespaces/índice; a doc atual diz *"million-scale namespaces and beyond"* (Standard/Enterprise). O número foi confundido com outro limite; o mecanismo de conhecimento escopado permanece válido. |
| **H4·F11** | **hypothesis** | Sourcing **secundário** (índice de papers no GitHub + blog `mem0.ai`), e o próprio achado se declara "frente ativa, não resolvida". Memória escopada a user/session/agent e "collaborative memory com dynamic access control" são consistentes com a literatura 2025-2026 (Mem0 é real), mas sem uma **primária forte única** verificada aqui. Não refutado; plausível — na dúvida, `hypothesis` (materialidade média, direção correta). |

**Resumo:** 11 achados materiais verificados (F1–F11; F12 é `low`, fora de escopo) → **10 confirmed, 1 hypothesis, 0 refuted**. Três `confirmed` carregam ressalva explícita `declarado≠verificado`: **F2** (a cifra "~63%" não é verificável no abstract), **F8** (a citação "keep hierarchies shallow" é de blog, não da página K8s oficial atribuída — mecanismo base/overlay confirmado), e **F10** (a estatística "10.000 namespaces/índice" está **errada** — confusão com o limite `$in` de metadata; mecanismo de isolamento confirmado). Nenhuma estatística fabricada compromete o veredito de um achado inteiro, mas as três acima devem ser corrigidas no corpo antes de qualquer citação downstream.

**Pilares:** os três eixos que sustentam o stream sobreviveram ao passe adversarial — **herança de conhecimento mediada por IA** (F1, F4: **confirmed** com primárias fortes), **SUPERSEDES/bitemporal** (F5: **confirmed**, semântica invalidar-sem-apagar verbatim; só o rótulo "bitemporal" estrito é do paper, não dos docs), e **polimorfismo SDAAL** (F3, F6: **confirmed** com Model Spec + docs de subagente). Nenhum pilar ficou fraco. O `hypothesis` isolado (F11, memória escopada) é periférico e já se declarava frente aberta.
