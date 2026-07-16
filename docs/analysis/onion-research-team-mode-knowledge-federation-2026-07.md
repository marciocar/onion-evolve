---
title: 'Pesquisa — Ontologia de coordenação jul/2026: Modo EQUIPE (validação externa) + Federação de Conhecimento (linha nova)'
date: 2026-07-01
type: analysis
status: proposed / living
research: fan-out WebSearch (11 ângulos, Workflow wf_621f7f40-bf1 + recuperação standalone do B4) + gate adversarial (painel de 3 céticos por afirmação, WebFetch obrigatório em números específicos)
extends: onion-research-harness-ledger-3-modes-2026-06.md (eixo A — validação externa do gap já nomeado)
related:
  - onion-research-harness-ledger-3-modes-2026-06.md (o modelo dos 3 modos que este documento valida)
  - onion-agent-teams-evaluation-2026-06.md (rejeição de coordenação emergente — confirmada externamente aqui, §2.3)
  - onion-orchestration-external-radar-2026-06.md (formato/disciplina deste radar)
  - panorama-ia-generativa-2026-06.md (disciplina de "leitura crítica")
  - ../knowledge-base/concepts/multi-repo-federation.md (federação código-cêntrica — cruzada em §3.7)
  - onion-adr-domain-context-lifecycle-2026-06.md (contexto intra-repo — cruzado em §3.7)
  - ../design-context/README.md (4º contexto peer provisório — cruzado em §3.7)
next-review-trigger: "1º caso real de N-devs/1-repo no Onion (Eixo A) · ou decisão do maestro de abrir/não-abrir a linha de Federação de Conhecimento (Eixo B)"
---

# Pesquisa — Modo EQUIPE (validação externa) + Federação de Conhecimento (linha nova)

> **Natureza deste doc:** radar vivo, não veredito fechado (mesma disciplina do `external-radar`). As duas
> perguntas binárias da §5 são para o **maestro decidir com a evidência abaixo** — este documento informa,
> não decide por conta própria.

## 0. Sumário executivo (veredito em 5 linhas)

**Eixo A (Modo Equipe):** o mercado **confirma** o gap que o Onion já nomeou internamente — nenhum vendor
relevante resolve "N devs humanos + IA no mesmo repo" como categoria própria, a dor concreta multi-humano
ainda é majoritariamente **anedótica** em 2026, e a peça que o Onion já tem (git worktrees) é o padrão de
fato consolidado. **Mas o dado mais forte não veio da pesquisa externa — veio de dogfood ao vivo nesta
própria sessão** (§5.1): um incidente real e pequeno de ambiguidade de autoridade-de-escrita entre duas
sessões IA no mesmo repo, corrigido só por julgamento manual, sem salvaguarda do sistema. **Eixo B
(Federação de Conhecimento):** há vocabulário de mercado emergente e dor real documentada (Meta, AWS,
Anthropic), mas o **dogfood desta sessão já testou a hipótese mais barata primeiro** — usar a infraestrutura
de federação existente para anunciar uma decisão de conhecimento — **e funcionou de primeira**, sem precisar
de contrato novo. Revisão pós-dogfood (§5): ambos os vereditos migram para a leitura **mais conservadora**
que a pesquisa de mercado sozinha sugeriria — registrar evidência, não construir infra nova ainda.

## 1. Método (transparência do processo)

- **11 ângulos de busca** (5 Eixo A + 6 Eixo B), cada um um worker independente com WebSearch/WebFetch,
  retornando 3-5 afirmações mais decisivas + termos de mercado + contradições auto-identificadas.
- **1 falha técnica real:** o ângulo B4 (RAG multi-repo) esgotou 5 tentativas de output estruturado no
  Workflow principal (erro de parse JSON) e foi recuperado **separadamente**, como agente standalone com
  formato de saída simplificado. Suas afirmações **não passaram** pelo painel adversarial de 3 votos que os
  outros 10 ângulos passaram — tratadas com cautela adicional na síntese (marcadas abaixo).
- **Gate adversarial:** cada afirmação coletada (54 no total, dos 10 ângulos que rodaram no Workflow) foi
  julgada por 3 críticos independentes — aprovada só com ≥2/3 votos **e**, na prática, o próprio painel
  exigiu **WebFetch na fonte primária** antes de aprovar qualquer número específico. Resultado: **18
  confirmadas**, **36 mantidas como sinal não-confirmado** (nunca descartadas silenciosamente — a maioria
  foi rebaixada não por serem falsas, mas por serem **fonte-única-de-vendor sem 2ª confirmação**, que é
  exatamente o comportamento anti-hype pretendido).
- **O que foi descartado e por quê:** nenhuma afirmação foi removida do registro — as 36 não-confirmadas
  continuam citadas abaixo com o rótulo `[não-confirmado]`. Duas afirmações que a busca inicial quase
  introduziu por confusão de fonte (um framework "Author/Editor/Director/Orchestrator" atribuído
  erroneamente à Microsoft; um "incidente de 3000 commits em 48h" que na verdade era sobre destruição de
  dados) foram **excluídas antes mesmo da verificação**, por terem sido desmentidas na 1ª leitura da fonte.

## 2. Eixo A — Modo Equipe: o que o mercado externo confirma/refuta (jul/2026)

### 2.1 Como players de coding agent descrevem "multiplayer" (produto)

**Confirmado:** nenhum dos vendors líderes (Cursor, GitHub Copilot, Devin/Cognition) nomeia uma feature para
"N desenvolvedores humanos + IA simultaneamente no mesmo repositório" — todos resolvem fluentemente **"1
humano : N agentes"** (Agents Window, Mission Control, Agent Command Center), via isolamento em git
worktrees. A única exceção real é o **Replit** ("multiplayer" explícito — "everyone works in the same
project… dispatch tasks at the same time as their teammates", Kanban compartilhado) `[não-confirmado
formalmente — fonte única do vendor, mas conteúdo factual não contestado]`. O sinal mais forte: a própria
**Anthropic contrasta Claude Code como "single-player" vs. Claude Tag (Slack) como "multiplayer"** — o
vendor líder de coding agent admite, na própria comunicação de produto, que a ferramenta de código não
resolve coordenação entre pessoas.

### 2.2 Terminologia de mercado — convergiu ou fragmentado?

**Fragmentado, confirmado com evidência forte.** GitHub usa "Agent HQ"/"Mission Control"/"fleet"; Cursor usa
"Background Agents"; Claude Code usa "Agent Teams"; Devin Desktop, Microsoft Rayfin e Augment Cosmos
lançaram três plataformas rivais **na mesma semana** de junho/2026, cada uma com nome próprio `[confirmado]`.
"Multi-agent orchestration" é o termo mais repetido por analistas, mas descreve coordenação **agente↔agente**,
não o problema humano↔humano. Dado mais revelador: no Stack Overflow Developer Survey, **apenas 17% dos
usuários de agentes concordam que agentes melhoraram a colaboração em equipe** — a pior nota entre todos os
impactos medidos (vs. ~70% de ganho individual) `[confirmado, fonte oficial]` — sinal quantitativo de que o
próprio problema que um termo vencedor descreveria **ainda não está resolvido**, o que ajuda a explicar por
que não há convergência de nome.

### 2.3 Falso-cognato enterprise (checagem deliberada, ver plano §A3)

**Confirmado exatamente como temido.** Em AWS Bedrock e Microsoft Copilot Studio, "equipe de agentes"
significa **hierarquia IA↔IA** (supervisor + collaborator/subagentes) — o humano aparece só como usuário
final, nunca como membro da equipe `[confirmado, docs técnicas oficiais]`. Salesforce Agentforce é ainda mais
explícito: "team" é 100% de agentes. **ServiceNow é o único que mistura os dois sentidos deliberadamente**
(A2A entre agentes sem humano + "Autonomous Workforce" onde humanos "gerenciam" agentes como colegas)
`[não-confirmado — fonte única de vendor, mas o padrão de mistura é real]`. **Isto valida externamente** a
rejeição que `onion-agent-teams-evaluation-2026-06.md` já tinha feito: "equipe de agentes" no discurso
enterprise **não é** o problema "N devs humanos + IA no mesmo repo" — é outro problema, coordenação
emergente IA↔IA, que o Onion já descartou como padrão por atrito com "fail-loud-and-resume".

### 2.4 Dor REPORTADA vs. feature vendida (o achado mais importante do Eixo A)

**A dor concreta de "2+ devs HUMANOS colidindo via agentes no mesmo repo" é escassa e majoritariamente
anedótica em 2026** — nenhum post-mortem público citável com nomes/datas/logs foi encontrado. O relato mais
próximo e mais rigoroso é sobre colisão **agente↔agente** sob a orquestração de **um único humano**: no
projeto do compilador C da própria Anthropic Engineering, 16 agentes Claude simultâneos "hit the same bug,
fix that bug, and then overwrite each other's changes" — mitigado com locks de arquivo `[confirmado, fonte
primária Anthropic]`. Isso é exatamente o problema que **worktrees isolados já resolvem** (§2.5) — não é o
handoff entre pessoas diferentes. O dado mais forte de fricção em nível de *equipe* continua sendo o "17%"
do survey (§2.2). **Leitura honesta:** a mitigação-padrão (worktrees) já virou categoria de produto **antes**
de haver evidência pública de um incidente multi-humano real e documentado — a indústria resolveu o
sintoma técnico adjacente (isolamento de agentes) sem que o cenário-gatilho completo (múltiplos humanos
colidindo) tenha, de fato, ocorrido e sido relatado em escala.

### 2.5 Comparação linha-a-linha contra o design já esboçado

| Peça do design esboçado (harness-ledger-3-modes) | Validação externa |
|---|---|
| Worktrees como isolamento ("um escritor por escopo") | 🟢 **Confirmado como padrão de fato** — suporte nativo consolidado em Claude Code, Codex e Cursor em Q1 2026 `[confirmado, mas o número "4+ sessões" específico ficou não-confirmado — fonte única secundária]` |
| `HANDOFF.md` append-only + hook bidirecional (comunicação entre pessoas) | 🟡 **Sem blueprint de mercado para copiar** — nenhum vendor pesquisado tem um protocolo nomeado de handoff entre desenvolvedores humanos; o Kanban compartilhado do Replit é o único análogo, mas vive dentro de um produto de app-building, não é padrão portável |
| `role detection` intra-repo (coordinator vs. developer) | 🔴 **Não encontrado no sentido humano** — "role" no vocabulário de mercado (supervisor/collaborator) é sempre entre agentes (§2.3), nunca entre pessoas |

### 2.6 Classificação por achado

- 🟢 **Git worktrees como primitiva de isolamento** — o Onion já escolheu certo; nenhuma mudança necessária.
- 🟢 **"Agent Teams"/coordenação emergente IA-IA ≠ problema do Modo Equipe** — confirma a rejeição prévia
  (`onion-agent-teams-evaluation`); nenhuma reavaliação necessária.
- 🟡 **Camada de comunicação humano↔humano sem blueprint de mercado** — mantido no radar; reavaliar se
  Replit's Kanban compartilhado (ou sucessor) ganhar tração fora do nicho de app-building.
- 🟡 **Dor real ainda anedótica** — mantido no radar; não é evidência de que o problema não existe, é
  evidência de que **ninguém documentou publicamente um caso completo** — reforça que o gatilho interno
  ("1º caso real de N-devs/1-repo") é a fonte de evidência certa, não a pesquisa externa.
- 🔴 **Terminologia de mercado convergente para "multiplayer coding"** — descartado; fragmentado.

## 3. Eixo B — Federação de Conhecimento: nomear o gap (linha nova)

### 3.1 Data mesh → "context mesh"?

**Termo real, mas fragmentado e sem prova de adoção.** Gartner cunhou "context mesh" (jan/2026); Kong lançou
produto homônimo (fev/2026, tech preview, **zero clientes documentados**) `[confirmado, fonte primária]`.
Crucialmente: **a própria criadora do data mesh (Zhamak Dehghani) evita o termo**, preferindo "agent-ready
data mesh" `[confirmado]` — e uma peça satírica (Joe Reis) já ironiza que isso repete o ciclo de hype
mesh→fabric que ocorreu em dados `[confirmado — mas é sátira, não endosso técnico]`. Nenhuma fonte documenta
adoção real com métricas.

### 3.2 Context engineering em escala de organização

**A dor é real; o framework não convergiu.** Dois nomes concorrentes e não-convergentes: "Context
Development Lifecycle" (Debois, proposta teórica sem produção) e "ContextOps" (Packmind, vendor). O sintoma
concreto e **relatado em prática real** (não vendor): drift entre `CLAUDE.md`/`.cursor/rules`/`AGENTS.md`
quando times usam ferramentas diferentes, e duplicação de convenções cross-repo. A **Anyline** documentou um
caso concreto (padrão "meta-repo": repo dedicado com `AGENTS.md` + `repos.yaml` centralizando convenções) —
resolveu fix cross-repo em 8 MRs / 6 repositórios / 2 plataformas `[confirmado, fonte primária relato de
prática]`. **Este é o achado mais diretamente reusável** para o Eixo B — não é vendor, é prática real, e o
padrão (repo dedicado como fonte de verdade citada pelos demais) é compatível com a filosofia de repos
soberanos do Onion.

### 3.3 DDD Context Mapping reaplicado a IA

**Em estágio de "ensaio arquitetural", não de produção.** Framework nomeado mais concreto: **DICE**
(Domain-Integrated Context Engineering, Rod Johnson) — mas repo pequeno (30 stars) `[confirmado]`. A DDD
Europe 2026 incluiu trilha "Strategic + AI" formalmente `[confirmado]`. **Tensão relevante:** quem nomeia DDD
explicitamente não tem caso de produção; quem resolve o mesmo problema em produção real (o padrão
"repo-of-repos", §3.2/3.5) **não usa** terminologia DDD — convergência de solução, divergência de
vocabulário.

### 3.4 RAG multi-repo — federação de índice ou centralização?

**Achado central do Eixo B, recuperado após falha técnica (não passou pelo painel de 3 votos — cautela
adicional).** A prática dominante em RAG enterprise é **centralização**: Sourcegraph Cody indexa todos os
repositórios num corpus único (Zoekt/SCIP), não índices federados independentes; plataformas como Onyx
consolidam múltiplos conectores num índice central com controle de permissão. **"Federação de índice" real
(sem centralizar dados) aparece quase exclusivamente em pesquisa acadêmica para cenários regulatórios
cross-organização** (saúde, finanças — papers como RAGRoute, FD-RAG) — não como padrão adotado em
ferramentas de desenvolvimento de código. Sinal de limite prático: mesmo indexando 300k+ repos, o Cody
Enterprise limita consultas a ~10 repositórios por vez — a UX de contexto federado por consulta não escala
ainda, só o armazenamento.

**Implicação direta para o Onion:** se a "Federação de Conhecimento" copiasse ingenuamente o padrão dominante
de mercado (RAG centralizado), isso **contradiria** a filosofia de repos-soberanos/sem-servidor-vivo que
sustenta toda a arquitetura de co-evolução do Onion (git-async, sem índice central, sem conexão viva). A
prática de mercado que **de fato combina** com a filosofia Onion não é RAG — é o padrão "meta-repo"/"context
products versionados" (§3.2), que é git-async e sem centralização de dados.

### 3.5 Monorepo vs. polyrepo na era de agentes

**Não confirmado como causa real.** Nenhuma empresa documentada migrou monorepo↔polyrepo **por causa
comprovada** de agentes de IA. A migração mais citada (Block/Cash App, ~450 serviços JVM) foi motivada por
"dependency bankruptcy" — a própria empresa nega explicitamente: **"We didn't move to a monorepo because of
AI"** `[confirmado, fonte primária]` — o benefício para agentes foi constatado depois, como bônus
retrospectivo. A tese contrária ("Great Monorepo Unbundling" — big techs fragmentando por causa de agentes)
tem evidência quase nula (boato). **Conclusão:** o discurso de mercado sobre "agentes mudando o cálculo
monorepo-vs-polyrepo" é, até jul/2026, majoritariamente narrativa pós-hoc, não causa comprovada.

### 3.6 Dor REPORTADA (espelha §2.4, para o eixo B)

**Confirmada, com evidência concreta e diversa — mais forte que o Eixo A neste ponto.** A Meta documentou
cobertura de apenas ~5% do codebase antes de mapear conhecimento tribal com IA, produzindo "silent wrong
output" por divergência de nomes de campo entre subsistemas `[confirmado, fonte primária Meta Engineering]`.
Um relato prático de engenheiro AWS: 8 agentes construíram componentes "perfeitos" isoladamente, gerando 17
bugs de integração por convenções divergentes (nomes de campo, rotas de API, formatos de ID) `[confirmado]`.
Um issue público no próprio `claude-code` (Anthropic) documenta "split-brain workflow" ao abrir sub-repos no
Claude Desktop `[confirmado, fonte primária]`. **Ressalva honesta:** nenhum dado quantifica precisamente "%
de incidentes causados por contexto divergente entre repos" — o mais próximo (State of AI 2026, "lack of
context" ~38%) mede o problema em geral, não o recorte multi-repo isolado.

### 3.7 Onde isso NÃO é coberto hoje pela doutrina Onion

Confirmado (já mapeado nesta sessão, antes da pesquisa externa): `multi-repo-federation.md` é inteiramente
código/API-cêntrico (contratos `interface`/`types`/`tests`/`fixtures`); `onion-adr-domain-context-lifecycle`
e `docs/design-context/` são inteiramente intra-repo. **Nenhum documento cobre como contexto de
negócio/técnico/compliance/design se propaga entre repos diferentes que adotam o Onion.** A pesquisa externa
confirma que isso também é um gap real na indústria (fragmentado, sem padrão consolidado) — não é o Onion
ficando atrás do mercado; é um problema genuinamente aberto em 2026.

## 4. Síntese comparativa

**Pergunta do maestro: os dois eixos são a mesma forma em escalas diferentes, ou estruturalmente distintos?**

**Resposta: mesma forma no vocabulário, superfícies de falha diferentes — e isso tem uma implicação
concreta de arquitetura.** Os dois eixos compartilham a mesma estrutura de ledger (`registry · changelog ·
contracts`, já isomórfica nos 3 modos do documento-base), mas a **natureza do conflito** é distinta:

- **Eixo A (Equipe) é um problema de ESCRITA CONCORRENTE** — a falha é colisão em tempo real (dois agentes
  ou pessoas editando o mesmo arquivo, race condition, overwrite silencioso). Isso exige **isolamento físico
  síncrono** (worktrees) — não dá para resolver com git-async puro, porque o conflito acontece **antes** de
  qualquer commit existir para coordenar em torno dele.
- **Eixo B (Conhecimento) é um problema de LEITURA DESATUALIZADA/DIVERGENTE** — a falha é dois repos
  operando com verdades de negócio contraditórias, sem colisão de escrita nenhuma (cada repo edita o próprio
  contexto). Isso é **exatamente o formato que o Ledger de Federação já resolve para código** (git-async,
  contratos versionados, sem servidor vivo) — a diferença é só o *conteúdo* do contrato (context-domain em
  vez de interface/API).

**Implicação prática:** o Eixo B pode **reusar** a infraestrutura de federação que já existe e está em
produção — e o dogfood desta sessão (§5.2) confirma que o envelope genérico já basta para um anúncio pontual
de conhecimento, sem precisar de formato de contrato dedicado ainda. O Eixo A **não pode** reusar essa
infraestrutura da mesma forma — precisa de uma camada nova (é exatamente por isso que o
harness-ledger-3-modes já o classificou como gap crítico, e por isso que fica corretamente gated, agora com
1 incidente real registrado como evidência, mas sem gatilho suficiente pra construir a camada nova ainda —
§5.1).

## 5. Veredito e recomendação

### 5.1 Modo Equipe — o gatilho disparou?

**Revisão pós-dogfood (2026-07-01) — o veredito abaixo mudou de leitura ao aplicar a doutrina "dogfood é o
padrão master" em vez de só a pesquisa de mercado.** A leitura inicial ("não disparou, foi só teste de
acesso") subestimava o que já aconteceu **ao vivo, nesta própria sessão**: o `mauriciomatos` tem a própria
sessão de Claude Code rodando contra um clone do `onion-evolve`, e essa sessão **considerou ativamente
commitar direto na `main` compartilhada** (mensagem: "Quer que eu commite este staging na main?"). A sessão
do core teve que **intervir manualmente** para impedir isso ("quebra um-escritor-por-repo") — não havia
nenhuma salvaguarda do sistema, só julgamento humano no momento certo. Pela doutrina de dogfood ("testar modo
de falha, não só happy-path" — um incidente de falha real vale mais que uma anedota de mercado), **isto é
evidência de dogfood real**, mais forte que qualquer achado da pesquisa externa (que também só encontrou
anedota, §2.4).

**Mas não é o gatilho completo ainda.** Foi um incidente **pontual** (uma decisão de commit, não trabalho
concorrente sustentado) — não justifica construir o `HANDOFF.md`/hook bidirecional/role-detection completos
agora (seria infra antes da necessidade provada — "nem suavizar cego, nem refatorar tudo"). **Recomendação
revisada:** registrar este incidente concreto como evidência no item gated (`onion-research-harness-ledger-3-modes`),
e refinar o próprio critério do gatilho — talvez não seja "N devs trabalhando sustentadamente", e sim
"qualquer ambiguidade real de autoridade-de-escrita entre 2 sessões IA no mesmo repo", que **já ocorreu**.
Continuar observando (crescimento orgânico com critério), não construir ainda.

### 5.2 Federação de Conhecimento — abre linha formal?

**Revisão pós-dogfood — recomendação fica ainda mais conservadora do que a pesquisa de mercado sozinha
sugeria.** As duas condições do plano continuam satisfeitas: (a) vocabulário de mercado nomeado sem
equivalente Onion (context mesh, ContextOps, meta-repo pattern, §3.1-3.3); (b) ≥1 dor reportada batendo com
limitação já observada (§3.6, Meta/AWS/Anthropic). Mas **esta própria sessão já dogfoodou a hipótese mais
barata primeiro**: usei a infraestrutura de federação **já existente** (`CHANGELOG.md` + `outbox/` +
`/meta:co-deliver`) para anunciar ao `rhilo-metagamify` uma decisão de **conhecimento** (o playbook
object-led-discovery), não um contrato de API/código — **e funcionou de primeira, sem fricção nem formato
novo**. Isso é evidência direta de que o envelope genérico do doc-bridge **já generaliza** de código para
conhecimento.

**Recomendação revisada: NÃO abrir uma linha formal nova agora.** A recomendação anterior ("estender
`multi-repo-federation.md` com um novo formato de contrato de contexto") estava à frente da necessidade
provada. O passo certo, mais barato: **só nomear/documentar** que o doc-bridge existente já serve para
anúncios de conhecimento (não só código) — uma nota em `multi-repo-federation.md`, não um subsistema novo.
Formalizar um "contrato de contexto" dedicado (schema, versionamento semântico, validação) fica **gated**,
esperando um 2º caso real que exponha um limite que o envelope genérico não aguente (ex.: necessidade de
sincronização bidirecional contínua, não só anúncio pontual — aí sim o padrão **meta-repo**, §3.2, vira
referência de design).

### 5.3 Riscos identificados nesta pesquisa

- **Vendor-hype residual:** mesmo com o gate de 3 votos, várias afirmações "não-confirmadas" foram
  rebaixadas por fonte-única-de-vendor, não por serem falsas — ao citar este documento no futuro, preservar
  o rótulo `[não-confirmado]`, não promover silenciosamente a fato.
- **B4 sem verificação adversarial completa** — recuperado fora do pipeline principal; suas 5 afirmações
  têm força de evidência auto-declarada (2 dado-primario, 2 opiniao-vendor, 1 relato-pratica) mas não
  passaram pelo painel de 3 votos. Tratar com o mesmo ceticismo que as demais opiniao-vendor.
- **Risco de sub-interpretar o dogfood, na direção oposta ao vendor-hype:** ao revisar §5 com a lente de
  dogfood, o risco simétrico é o oposto do hype — descartar um incidente real pequeno como "não conta"
  porque não é grande/sustentado. A revisão desta seção tentou o meio-termo (registrar como evidência
  concreta, não como gatilho completo) — mas é uma leitura, não uma medição; o maestro pode pesar diferente.
- **Falha técnica registrada (não é vendor-hype, é harness):** o Workflow's `agent()` esgotou 5 retries de
  StructuredOutput para o B4 original — sinal de possível fragilidade do schema/prompt para esse ângulo
  específico (conteúdo com aspas/citações longas), não do harness em geral (os outros 10/11 ângulos + toda a
  fase de verificação rodaram sem esse problema).

## 6. Log / revisibilidade

- **2026-07-01** — Documento criado a partir de fan-out de 11 ângulos (Workflow `wf_621f7f40-bf1`, 173
  agentes, ~7.1M tokens) + recuperação standalone do ângulo B4 após falha de 5 retries. Veredito inicial:
  Eixo A confirma o gap já nomeado internamente (sem mudança de gate); Eixo B abre como linha nova, com
  recomendação de reusar a infraestrutura de federação existente em vez de copiar o padrão RAG centralizado
  de mercado.
- **2026-07-01 (revisão, mesma sessão)** — §0/§4/§5 revisados ao aplicar a doutrina "dogfood é o padrão
  master" em vez de só a pesquisa de mercado. Dois achados de dogfood ao vivo, na própria sessão: (1) um
  incidente real de ambiguidade de autoridade-de-escrita entre a sessão do core e a sessão do
  `mauriciomatos` no mesmo repo (Eixo A) — corrigido por julgamento manual, sem salvaguarda de sistema;
  (2) o doc-bridge existente (`CHANGELOG.md`+`outbox/`+`co-deliver`) usado com sucesso para anunciar uma
  decisão de conhecimento, não código (Eixo B). Ambos os vereditos migraram para a leitura mais
  conservadora: Eixo A registra o incidente como evidência mas **não** dispara construção de infra nova;
  Eixo B **não** abre linha formal nova ainda — só documenta que o envelope genérico já generaliza. Para
  retroagir: editar aqui com data + porquê.

## Fontes

Fontes completas com URL, data e força de evidência estão citadas inline em cada afirmação nas Seções 2-3
(rótulo `[confirmado]` = ≥2/3 votos do painel adversarial + WebFetch de números específicos; `[não-confirmado]`
= sinal mantido no radar, tipicamente por ser fonte-única-de-vendor). Destaques primários usados na síntese:
Anthropic Engineering (blog de compilador C), Meta Engineering (mapeamento de conhecimento tribal), Stack
Overflow Developer Survey 2025/2026, AWS Bedrock/Microsoft Copilot Studio (docs técnicas oficiais), Cursor
(blog scaling-agents), arXiv 2602.19441 (coordenação em PRs de agentes), arXiv 2604.03551 (AgenticFlict,
conflitos de merge), Sourcegraph (arquitetura Cody), Block/Cash App Engineering (migração monorepo),
GitHub Issue anthropics/claude-code#56853 (split-brain Claude Desktop).
