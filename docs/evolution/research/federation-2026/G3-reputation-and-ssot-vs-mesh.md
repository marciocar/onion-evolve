# G3 — Reputação-por-evidência como condicionante + SSOT-central vs Mesh em N pequeno

> **Stream G3, 2ª rodada (fechar gaps) do redesign da federação Onion (2026).**
> Insumo de evidência para a decisão do maestro — **não é decisão de doutrina**. Cada achado
> material carrega FONTE (URL). Sem fonte sólida = materialidade `low` / `hypothesis`.
> Esta rodada **fecha gaps e firma achados rebaixados**; não reabre o que a 1ª rodada
> (`SYNTHESIS.md`) já deu por sólido.

## Resumo

Duas metades, ambas com veredito prático:

**(A) Reputação-por-evidência como condicionante de governança — deixa de ser "teoria imatura".**
Dois papers primários de 2025-2026 mostram, com números fortes, o mecanismo exato que o Onion já
esboça ("declarado ≠ verificado" + `trust-log` + `can_correct_to`): reputação acumulada de
comportamento passado **condiciona aceitar / vetar / isolar** um sinal ou um par. **RepuNet**
(reputação dual-level + gossip) leva cooperação de 19% → 85%; **Attention-based Trust Management**
usa registro de violações por agente com **threshold de aceitação** e **remoção automática** de
quem viola persistentemente, derrubando ataque de 94,6% → 23,5%. A aplicabilidade ao veto/urgência
da Federação formal é **evidenciada, porém ainda em simulação** (public-goods games, 20 agentes) —
promissora o bastante para sair de pura-hipótese, madura o bastante para **gate de dogfood**, não
para virar doutrina automática.

**(B) SSOT-central vs mesh em N≈5 — o veredito da 1ª rodada se firma em fonte MELHOR, não pior.**
O achado `S2·F11` ("CRDT remove SPOF") estava rebaixado a hipótese por falta de fonte primária.
Fonte primária agora **confirma o claim** (CRDT de fato elimina o coordenador central como SPOF) —
**mas o reenquadra**: essa remoção é **precificada pelo CAP** (troca consistência forte por
eventual + overhead de metadados) e seu valor central (escritas **concorrentes** conflict-free de
**múltiplos escritores**) fica **ocioso** num ledger de identidade de **escritor único** em N
pequeno. O corte certo não é "central vs mesh" por escala, e sim **recurso-exclusivo (ledger de
identidade/contratos → consistência forte, escritor único) vs estado-colaborativo (comunicação
assíncrona → replicação otimista)** — e a comunicação git-async do Onion **já é** replicação
otimista (o mesmo modelo copy-modify-merge do git/CVS). Logo: **single-source para
identidade/contratos + mesh-de-comunicação git-async** é o ótimo defensável, agora com fonte
primária dos dois lados.

---

## Metade A — Reputação-por-evidência como condicionante de decisão

### A1. RepuNet: reputação acumulada condiciona conectar/desconectar pares — 19% → 85%
- **Claim.** Sistema de reputação dual-level (nível-agente + nível-rede) em MAS de LLMs: agentes
  formam auto- e hetero-reputação por **interação direta + gossip indireto**, e usam `ri→j(t)` para
  **decidir conectar ou cortar** (`wi→j(t) ∈ {"Y","N"}`) — "*agents strengthen ties to
  high-reputation partners and sever links to disreputable ones*". Em public-goods games (20
  agentes GPT-4o-mini, 200 rodadas), a participação passa de **19% (±0,06) → 85% (±0,03)**; em
  cenário de investimento, sucesso **17% → 98%**. Emerge "*social isolation of exploitative
  agents*" — reputação funciona como **gate de exclusão**, não só escore contínuo.
- **Fonte.** [arXiv:2505.05029 — Beyond the Tragedy of the Commons: Building a Reputation System
  for Generative Multi-agent Systems](https://arxiv.org/abs/2505.05029) ·
  [HTML v2](https://arxiv.org/html/2505.05029v2)
- **Materialidade.** ALTA (fonte primária, resultado quantitativo forte, mecanismo direto).
- **Implicação p/ Onion.** É o molde do que o Onion já tem em embrião: `trust-log` + "declarado ≠
  verificado" = reputação-por-evidência; o `can_correct_to` elevado por rigor = reputação que
  **eleva o peso** de um par. A federação pode condicionar **prioridade/urgência** de um sinal ao
  histórico verificado do emissor. **Ressalva de maturidade:** é simulação de teoria de jogos, não
  governança de produção — direção validada, aplicação ao veto ainda a dogfoodar.

### A2. Attention-based Trust Management: threshold de aceitação + remoção por taxa-de-violação — ataque 94,6% → 23,5%
- **Claim.** Sistema de trust por dimensões para MAS de LLMs decide **filtrar (rejeitar) vs aceitar**
  uma mensagem por **threshold**: "*if the score for one trust dimension exceeds its corresponding
  threshold (score > τ), the message is flagged as untrustworthy and is filtered out*". Mantém
  **registro temporal de violações por agente**; quando a taxa de violação passa de ~80% numa
  janela de 20 mensagens, o agente é **removido automaticamente**. Resultado: attack success de
  ataque AiTM cai de **94,6% → 23,5%**, detecção de agente malicioso **100%**, perda de utilidade
  limpa **< 2%**. Nota honesta: o sistema **filtra, não "questiona"** — não há trilha explícita de
  "question" para casos incertos.
- **Fonte.** [arXiv:2506.02546 — To trust or not to trust: Attention-based Trust Management for LLM
  Multi-Agent Systems (v2)](https://arxiv.org/html/2506.02546v2)
- **Materialidade.** ALTA (fonte primária; é o análogo **mais direto** do veto Onion — histórico
  acumulado de violação → exclusão automática).
- **Implicação p/ Onion.** Mapeia quase 1:1 na Federação formal: o **fail-safe hierárquico**
  ("unconfigured = disabled", `S4·F7`) é o threshold conservador; o `trust-log` é o "registro
  temporal de violações"; a **remoção por taxa-de-violação** é a versão automatizável do
  `blocked_contracts` do `MemberExpertSchema`. Dá o vocabulário para **reputação condicionar o
  veto**: um membro/contrato com histórico de violação verificada rebaixa o threshold de aceitação
  dos seus próximos sinais. Advertência do próprio paper: sem trilha de "question", o design pende
  a **filtrar** — no Onion isso é bom (fail-safe), mas exige o gate humano do maestro para o
  "question".

### A3. A reputação é peer-to-peer + gossip — casa com o mesh de comunicação, não exige autoridade central
- **Claim.** Em RepuNet a reputação é **descentralizada**: cada agente mantém suas crenças e as
  propaga por **gossip**, cuja credibilidade é ponderada pela reputação do próprio fofoqueiro e pela
  confiança da comunidade no gossip anterior (`rl→y(t+1) ← ShapeRepuGossip(...)`). Não há árbitro
  central de reputação.
- **Fonte.** [arXiv:2505.05029 (HTML v2)](https://arxiv.org/html/2505.05029v2)
- **Materialidade.** MÉDIA (fonte primária; o encaixe com o transporte Onion é implicação, não
  achado do paper).
- **Implicação p/ Onion.** A reputação **não precisa** de um serviço central para funcionar — pode
  viajar pelo **mesmo mesh git-async** (CHANGELOG/inbox como veículo de "gossip verificável"). Isso
  reconcilia a metade A com a metade B: identidade/contratos ficam single-source, **reputação
  circula pelo mesh** como estado colaborativo — sem SPOF de reputação, sem novo serviço stateful.

### A4. Maturidade: sistemas de reputação em MAS têm base acadêmica longa, mas a aplicação a LLM-agents é 2025+ e ainda em simulação
- **Claim.** Trust/reputation em MAS é campo consolidado (surveys desde ~2011-2015), mas a onda
  LLM-agent (RepuNet, Attention-Trust, TRiSM para Agentic AI) é toda **2025-2026** e validada em
  **benchmarks/simulação**, não em governança de produção multi-org. Gartner posiciona
  TRiSM/multiagent como tendência estratégica 2025-2026 — sinal de imaturidade de mercado, não de
  solução pronta.
- **Fonte.** [ACM Computing Surveys — Trust and Reputation Models for Multiagent
  Systems](https://dl.acm.org/doi/10.1145/2816826) ·
  [TRiSM for Agentic AI (arXiv:2506.04133v2)](https://arxiv.org/html/2506.04133v2)
- **Materialidade.** MÉDIA (contextual — calibra expectativa, não decide).
- **Implicação p/ Onion.** Reputação-condicionante do veto **sai de "teoria imatura"** para
  "evidência-simulação sólida, produção não-provada". Veredito: **mantê-la gated atrás de dogfood**
  — instrumentar o `trust-log` para acumular o histórico primeiro, medir, e só então deixar a
  reputação **mexer no threshold** do veto. Não virar doutrina automática nesta rodada.

---

## Metade B — SSOT-central vs Mesh descentralizado em N≈5 (firmar S2·F11)

### B1. CRDT **de fato** remove o SPOF do coordenador central — mas precificado pelo CAP
- **Claim.** Fonte primária confirma o claim que estava rebaixado: "*The application can update any
  replica independently, concurrently and without coordinating with other replicas*" — o que
  **elimina o coordenador central como ponto único de falha**. Porém a contrapartida é explícita:
  consistência **eventual** (não forte), e overhead — "*the entire state of every CRDT must be
  transmitted eventually to every other replica, which may be costly*", além de crescimento de
  tombstones/metadados.
- **Fonte.** [Wikipedia — Conflict-free replicated data
  type](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type) ·
  [crdt.tech](https://crdt.tech/) · [zxch3n — CRDT intro](https://www.zxch3n.com/crdt-intro/crdt-intro.en/)
- **Materialidade.** ALTA (fonte primária fecha o gap de `S2·F11`).
- **Implicação p/ Onion.** `S2·F11` **passa de hipótese a confirmado** no claim literal — mas o
  reenquadramento é o que importa: remover o SPOF via CRDT **custa** consistência forte + banda +
  complexidade. Para um ledger de identidade/contratos que precisa ser **autoritativo**, esse é o
  trade errado.

### B2. A escolha central-vs-mesh é enraizada no CAP, não na escala — e o Onion quer consistência forte na identidade
- **Claim.** crdt.tech coloca a decisão em termos de CAP: replicação **fortemente consistente**
  ("*strong consistency models such as serializable transactions and linearizability*") **reduz
  performance e impede modificação offline**; replicação **otimista** dá "*maximum performance and
  availability*" mas **exige resolução de conflito**. É o teorema CAP, não o tamanho do cluster, que
  dita o corte.
- **Fonte.** [crdt.tech](https://crdt.tech/) · [Wikipedia — Eventual
  consistency](https://en.wikipedia.org/wiki/Eventual_consistency)
- **Materialidade.** ALTA.
- **Implicação p/ Onion.** O corte doutrinário certo **não é** "central vs mesh por escala", e sim
  por **natureza do dado**: **identidade/contratos = recurso que exige autoridade/consistência forte**
  (quem é membro, qual contrato vale) → **single-source**. **Comunicação = estado colaborativo
  assíncrono** onde escritas concorrentes devem sobreviver → **replicação otimista (mesh)**. O
  veredito da 1ª rodada acerta o corte pela razão certa.

### B3. A comunicação git-async do Onion **já é** replicação otimista (copy-modify-merge) — fonte primária
- **Claim.** A replicação otimista / consistência eventual tem como **exemplo canônico o modelo
  copy-modify-merge de sistemas de controle de versão** (CVS/git): "*optimistic replication enables
  asynchronous collaboration between users… changes made at different nodes are eventually
  synchronized, assuming that conflicts will be rare*" e "*consistency between the replicas is
  eventually re-established via 'merges'*". É o survey seminal de Saito & Shapiro (Microsoft
  Research).
- **Fonte.** [Saito & Shapiro — Optimistic Replication (MSR
  TR-2003-60)](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/tr-2003-60.pdf) ·
  [Wikipedia — Optimistic replication](https://en.wikipedia.org/wiki/Optimistic_replication)
- **Materialidade.** ALTA (fonte primária; ancora "git-async = mesh certo" em teoria de sistemas,
  não em analogia solta).
- **Implicação p/ Onion.** O doc-bridge git-async (co-* + CHANGELOG + inbox/inbound, um-escritor-
  por-repo, merge por repo) **é literalmente** um mesh de replicação otimista para a **comunicação**.
  Ou seja: "federar apenas a comunicação via mesh git-async" **não é invenção** — é aplicar o modelo
  já provado do próprio git à camada colaborativa. A pré-condição "conflitos raros" é satisfeita pelo
  invariante um-escritor-por-repo. **Não é preciso CRDT explícito** para ter o benefício do mesh na
  comunicação; o git já entrega.

### B4. Num ledger de escritor único em N pequeno, o valor central do CRDT fica ocioso
- **Claim.** O valor-núcleo do CRDT é resolver **escritas concorrentes de múltiplos escritores** sem
  coordenação ("*updates to be performed independently and concurrently at any replica*"). Um ledger
  de identidade/contratos com **um escritor** (o core como control-plane, um-escritor-por-repo) **não
  gera concorrência a resolver** — logo o mecanismo que justificaria o CRDT não tem trabalho a fazer,
  enquanto seus custos (metadados, eventual-consistency, complexidade de B1) permanecem.
- **Fonte.** [Wikipedia — CRDT](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type)
  (definição de valor) — a **conclusão** para o caso Onion é implicação derivada, não afirmação da
  fonte.
- **Materialidade.** MÉDIA (raciocínio derivado de definições primárias; sólido mas não citado
  literalmente).
- **Implicação p/ Onion.** Confirma que **para N≈5 com maestro único, CRDT é over-engineering** — não
  por ser "cedo demais em escala", mas porque **a condição de uso do CRDT (multi-escritor concorrente)
  não existe** na identidade. Só reabrir se surgir 2º hub escrevendo identidade concorrentemente e
  desconectado por longos períodos (o gatilho de revisão já previsto no SYNTHESIS).

### B5. Em escala pequena, o control-plane central único é o ótimo operacional — o SPOF residual mitiga-se com HA, não com mesh
- **Claim.** Doc primária de fornecedor (Argo CD / Red Hat, hub-and-spoke): o hub central "*serves as
  the single source of truth*" e dá "*single pane of glass*"; para escala menor o custo operacional de
  rodar **um** control-plane é **menor**, com a ressalva de que "*a central ArgoCD is a single point of
  failure (needs HA setup)*". Isto é, o remédio ao SPOF de um SSOT central é **HA/versionamento**, não
  trocar por mesh descentralizado.
- **Fonte.** [Red Hat — Argo CD Agent architecture
  overview](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/1.19/html/argo_cd_agent_architecture/argocd-agent-architecture)
  · [Argo CD docs](https://argo-cd.readthedocs.io/en/stable/)
- **Materialidade.** ALTA (fonte primária de fornecedor; é o padrão que a 1ª rodada já adotou —
  control-plane + agente remoto).
- **Implicação p/ Onion.** Firma a linha do veredito: "*SPOF só na identidade (mitigável:
  `members.yaml` versionado + ledger append-only)*". A mitigação canônica do mercado para o SPOF do
  control-plane é **HA + git como histórico**, exatamente o que o Onion já tem (SSOT versionado + ledger
  append-only). O Grana.Ai rodar seu Onion local como **agente/data-plane subordinado** (não
  `role:source`) é o mesmo hub-and-spoke — confirmado por fornecedor primário.

---

## Resolução do gap (o que isto fecha do SYNTHESIS)

| Item do SYNTHESIS | Estado antes | Estado depois desta rodada |
|---|---|---|
| **`S2·F11`** — "mesh-CRDT remove SPOF" (sem fonte primária) | `hypothesis` (rebaixado) | **Claim CONFIRMADO** por fonte primária (Wikipedia CRDT + crdt.tech): CRDT **remove** o SPOF do coordenador — porém **precificado pelo CAP** e com **valor ocioso** em ledger de escritor único N pequeno (B1/B4). O trade-off SSOT-vs-mesh deixa de ser "sem fonte". |
| **Veredito multi-core** — "single-source p/ identidade + mesh de comunicação" | Sólido, mas apoiado parcialmente em `S2·F11` (fraco) | **Firmado em evidência MELHOR.** O corte correto é **recurso-exclusivo (identidade/contratos → consistência forte, single-writer) vs estado-colaborativo (comunicação → replicação otimista)** (B2), e a comunicação git-async **já é** replicação otimista canônica (B3, Saito & Shapiro). O veredito **se sustenta com fonte primária dos dois lados** — não repousa mais em hipótese. |
| **"Reputação como condicionante do veto" (`S4·F3`)** — teoria sólida, aplicação = hipótese a validar em dogfood | `hypothesis` de aplicação | **Direção evidenciada** por 2 papers primários 2025-2026 (RepuNet A1 + Attention-Trust A2): o mecanismo evidência→aceitar/vetar/isolar funciona com números fortes **em simulação**. Sobe de "teoria imatura" para "evidência-simulação sólida". **Aplicação ao veto permanece gated atrás de dogfood** — não vira doutrina automática (A4). |
| **Grana.Ai como data-plane subordinado (não `role:source`)** | Recomendado (Argo CD Agent, `S2·F5`) | **Reforçado** por fonte primária de fornecedor (B5): hub-and-spoke com control-plane único = ótimo operacional em escala pequena; SPOF residual mitiga-se com HA/ledger versionado — que o Onion já tem. |
| **Reputação exige serviço/autoridade central?** | Não abordado | **Não.** Reputação em MAS é peer-to-peer + gossip (A3) — pode viajar **pelo próprio mesh git-async**, sem SPOF de reputação nem serviço stateful novo. Reconcilia as duas metades. |

**Síntese do stream G3:** ambas as perguntas fecham a favor do desenho da 1ª rodada, agora com fonte
primária onde antes havia hipótese. **(A)** reputação-por-evidência é mecanismo real e forte para
condicionar aceite/veto/prioridade, madura para **instrumentar-e-dogfoodar** (acumular `trust-log`
primeiro), não para ligar no veto sem medição. **(B)** SSOT-central para identidade/contratos + mesh
git-async para comunicação é o **ótimo pelo motivo certo** (natureza do dado via CAP, não escala) —
CRDT só entra se aparecer multi-escritor concorrente desconectado, condição que N≈5 com maestro único
não satisfaz.

### Advertências de citação (declarado ≠ verificado)
- **B4** é **implicação derivada** de definições primárias (o CRDT serve multi-escritor concorrente;
  identidade Onion é single-writer) — sólida, mas **não** é frase literal de fonte. Materialidade média.
- **A "distinção recurso-exclusivo vs colaborativo"** (consenso p/ ledger/leader-election; CRDT p/
  estado colaborativo) apareceu em **resumo de busca**, mas **não** foi confirmada como texto literal
  do crdt.tech na leitura direta — está sustentada aqui pela framing-CAP primária (B2) + princípio de
  sistemas, não por citação verbatim. Tratar o princípio como **consenso de engenharia**, não como
  spec.
- Os resultados de reputação (A1/A2) são de **simulação/benchmark**; nenhum é governança
  multi-organização em produção. Não usar os números (85%, 23,5%) como promessa de resultado no Onion.

---

## Verificação adversarial

> **2ª rodada — verificador adversarial (doutrina: evidência ou abstenção).** Cada achado material
> foi checado contra a fonte primária (existe? recente? sustenta o claim SEM exagero? há
> contra-evidência?). Fontes lidas diretamente via WebFetch/WebSearch em 2026-07-09.

| finding_id | veredito | nota |
|---|---|---|
| **G3-A1** | **confirmed** | Fonte primária (arXiv:2505.05029, HTML v2) sustenta TODOS os elementos com números **exatos**: reputação dual-level (agent + network), formada por interação direta + gossip, decisão `wi→j(t)∈{"Y","N"}` de conectar/cortar; Cenário 1 (participação) **0.19(±0.06) → 0.85(±0.03)**; Cenário 2 (investimento) **0.17(±0.08) → 0.98(±0.02)**; **20 agentes** GPT-4o-mini, 200/100 rodadas ×5; emerge "social isolation of exploitative agents". Sem exagero. |
| **G3-A2** | **confirmed** | Fonte primária (arXiv:2506.02546v2) confirma verbatim: `score>τ` → mensagem filtrada; "timestamped, agent-level trust records"; "if the violation rate exceeds 80%… removed" em janela de **20 queries**; AiTM **94.6% → 23.5%** (redução 71.1%, MMLUPhy/Complete); **100% ADR**; clean-task accuracy cai **<2%**. **Ressalva:** o paper define **três** ações — transmitir / filtrar / **"requesting further verification"** — logo o claim "filtra, não questiona / sem trilha de question" é leve **simplificação**: existe uma ação de verificação, embora os experimentos enfatizem filtrar. Materialidade numérica intacta. |
| **G3-A3** | **confirmed** | Confirmado no paper: reputação descentralizada peer-to-peer, propagada por gossip ponderado pela reputação do fofoqueiro, sem árbitro central ("90% of gossip is positive"; correlação freq×reputação p<0.002). O encaixe com o mesh git-async do Onion é **implicação** (declarada como tal, materialidade média), não achado do paper — corretamente rotulada. |
| **G3-A4** | **confirmed** | Ambas as âncoras existem e sustentam a framing de maturidade: ACM Comp. Surveys 10.1145/2816826 (Granatyr et al., **2015**) — survey extenso de trust/reputation em MAS; TRiSM Agentic AI (arXiv:2506.04133v2, **2025**) explicitamente "conceptual survey", "no unified framework exists", padrões "nascent guidance rather than validated cross-organizational governance in production". A escalada "teoria imatura → evidência-simulação sólida, produção não-provada, gated atrás de dogfood" é fiel e devidamente hedgeada. |
| **G3-B1** | **confirmed** | Wikipedia CRDT confirma **verbatim**: "update any replica independently, concurrently and without coordinating with other replicas"; "the entire state of every CRDT must be transmitted eventually… which may be costly"; convergência **eventual** (não forte); tombstones com "potentially unbounded growth". `S2·F11` de fato passa de hipótese a claim confirmado, com o reenquadramento CAP correto. |
| **G3-B2** | **confirmed** | crdt.tech sustenta a framing CAP-não-escala: coordenação forte "reduces the performance"; sob consistência forte "it is impossible to make any data changes on a replica while… disconnected"; otimista "enables maximum performance and availability, but… conflicts". **Nota:** a frase exata "serializable transactions and linearizability" não foi confirmada verbatim na leitura direta — a **substância** (trade-off enraizado no CAP) está confirmada; tratar como paráfrase fiel, não citação literal. |
| **G3-B3** | **confirmed** | Wikipedia (Optimistic replication) confirma: "One well-known example… is the CVS version control system, or any other version control system which uses the copy-modify-merge paradigm"; eventual consistency; conflitos "flagged for that user to fix manually"; atribuição **Saito & Shapiro (2005), ACM Comp. Surveys 37(1):42–81**. "git-async = replicação otimista canônica" é modelo provado, não invenção. Pré-condição "conflitos raros" satisfeita pelo invariante um-escritor-por-repo. |
| **G3-B4** | **confirmed** | Raciocínio derivado **honestamente rotulado** como implicação (não citação): o valor-núcleo do CRDT (resolver escritas concorrentes de múltiplos escritores sem coordenação) é definição primária confirmada; um ledger single-writer em N≈5 não gera essa concorrência → mecanismo ocioso, custos permanecem. Lógica válida; materialidade média por ser inferência, como o próprio doc declara. |
| **G3-B5** | **confirmed** | Substância confirmada por múltiplas fontes (Red Hat / Akuity / Codefresh): control-plane central = "single point of failure"; hub-and-spoke; "Git serves as the single source of truth" + observabilidade centralizada; mitigação por HA (server/repo ≥2 réplicas, Redis HA 3 sentinelas). **Contra-evidência parcial:** o próprio **Argo CD Agent** introduz descentralização agent-based que "removes the control plane as a single point of failure" (agente segue operando offline) — ou seja, o fornecedor caminha para um híbrido, então "remédio é HA, NÃO mesh" é levemente forte. Mas o núcleo — control-plane único = ótimo operacional em escala pequena + Grana.Ai como agente/data-plane subordinado (hub-and-spoke) — está confirmado. A ressalva já ecoa o "reabrir se surgir 2º hub" do SYNTHESIS. |

**Veredito do verificador:** nenhum achado **refutado**. Todos os 9 sustentam-se em fonte primária/
autoritativa com números conferidos. Duas ressalvas de calibração (não refutações): **A2** simplifica
ao dizer "não questiona" (existe ação de "request further verification"); **B5** superdimensiona
"remédio é HA e não mesh" à luz do próprio Argo CD Agent, que descentraliza para reduzir o SPOF.
Paráfrases não-literais explicitamente sinalizadas: **B2** (frase "serializable/linearizability" não
verbatim) e **B4** (implicação derivada). Números de reputação (A1/A2) permanecem **de simulação** —
não são promessa de resultado em produção.
