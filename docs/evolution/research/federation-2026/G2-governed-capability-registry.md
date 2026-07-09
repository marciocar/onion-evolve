# G2 — Registro/Descoberta de Capacidade GOVERNADO (2ª rodada — fecha gaps)

> Stream G2 do redesign da Federação Onion (2026). **2ª rodada:** o foco NÃO é achar coisa nova —
> é **confirmar ou refutar, com fonte melhor**, o alerta que a 1ª rodada rebaixou a "gap em aberto":
>
> > *"'Registry de capacidade governado' é problema **não-resolvido no mercado**"*
> > (SYNTHESIS §"O que ainda falta pesquisar"; origem `S2` alerta, citando
> > `github.com/IBM/mcp-context-forge/issues/2809` sob o rótulo "Backstage MCP registry proposal travada").
>
> **Natureza:** insumo de evidência para a decisão do maestro — **não é doutrina**. Cada achado material
> carrega FONTE (URL) + materialidade. Sem fonte sólida = `hypothesis` / materialidade `low`.

---

## Resumo

O alerta da 1ª rodada estava **certo na direção, errado na força e impreciso na citação**. A verificação
com fontes primárias 2025-2026 mostra um quadro em **duas camadas** que o rótulo genérico "não-resolvido"
achatava:

1. **DESCOBERTA está RESOLVIDA (refuta a leitura forte).** Desde set/2025 existe um **MCP Registry oficial**
   (Anthropic + GitHub + Microsoft + Block + PulseMCP) com **governança de namespace** (reverse-DNS +
   verificação por GitHub OIDC/DNS), modelo aberto de **sub-registries** e moderação por denúncia. Em
   paralelo: **Docker MCP Catalog** (assinatura + SBOM + provenance + commit-pinning) e o **Agent Card A2A**
   em `/.well-known/agent-card.json`. Há, sim, **padrões prontos de descoberta** — a premissa "não existe
   padrão" caiu.

2. **CONFIANÇA/CURADORIA GOVERNADA EM ESCALA continua NÃO-RESOLVIDA (confirma a direção).** O próprio
   ecossistema diz, com todas as letras: *"o MCP registry resolveu descoberta; o próximo desafio é resolver
   **confiança**"* — 64,7 milhões de entradas para 1.691 pacotes reais (bloat/duplicação), typosquatting
   persistente, meta-registry que só guarda metadados e **empurra a validação pro downstream**. E os
   protocolos **deixam a curadoria/aprovação/registry-API explicitamente "por sua conta"** (A2A: *"não
   prescreve API padrão para registries curados"*; MCP: sub-registry curado é responsabilidade de quem
   consome).

**Correção de citação (achado de campo):** o `IBM/mcp-context-forge#2809` **não é** "a proposta do Backstage
travada" — é um **EPIC de integração do IBM ContextForge** (aberto) que se propõe a ser *a camada de
governança atrás do Backstage*. A proposta Backstage genuinamente parada é outra (community-plugins #4034 +
RFC #32062). O erro não muda o veredito, mas a fonte fica mais forte e honesta.

**Conclusão para o Onion (fundamentada, não-doutrina):** **manter A2A/registry GATED e curar à mão está
CORRETO e agora melhor-fundado** — porque o que o mercado *não* resolveu é exatamente a peça que a curadoria
humana do maestro *é* (o "curated, security-first sub-registry" que a indústria aponta como fator decisivo de
adoção). Para 5 membros, o `members.yaml` **já é** um sub-registry privado curado + agent-card registry, e o
`pin` **já é** a provenance-por-commit que Docker/npm formalizam. O movimento certo **não é adotar uma
plataforma de registry**, é **alinhar o vocabulário/esquema do Onion aos formatos que emergiram** (namespace
reverse-DNS, Agent Card em well-known, provenance-liga-ao-commit, "não-confiável até verificado") — interop
barata amanhã, gate humano como camada de confiança hoje.

---

## Achados numerados

### F1 — MCP Registry OFICIAL existe (preview set/2025), respaldado pela Anthropic + GitHub + Microsoft

**Claim:** Em 08/set/2025 lançou o **MCP Registry oficial** — catálogo aberto + API para descobrir MCP
servers publicamente disponíveis, *"maintained by the registry working group and permissively licensed"*,
com contribuição de **Anthropic, GitHub, Block, PulseMCP** (16 indivíduos, ≥9 empresas; +Microsoft, VS Code,
NuGet). Está em **preview**, sem garantias de durabilidade, breaking changes esperadas antes do GA.

**Fonte:** https://blog.modelcontextprotocol.io/posts/2025-09-08-mcp-registry-preview/ ·
https://registry.modelcontextprotocol.io/ · https://modelcontextprotocol.io/registry/about

**Materialidade: ALTA.** É a refutação direta da leitura forte "não existe padrão pronto de descoberta
governada". Existe, é oficial, e a Anthropic (o vetor do Onion) está dentro.

**Implicação p/ Onion:** o `members.yaml` deve ser lido como **sub-registry privado** desse modelo — a spec
OpenAPI do registry é aberta *"allowing everyone to build a compatible sub-registry"*, inclusive privado para
uso enterprise. Não adotar a plataforma; **espelhar o contrato** para interop futura sem custo.

---

### F2 — Governança do MCP Registry = namespace reverse-DNS + verificação OIDC/DNS + moderação por denúncia

**Claim:** A confiança do registry vem de **namespace authentication**: nomes em reverse-DNS
(`io.github.user/server`, `com.example/server`) atados a **contas GitHub verificadas ou domínios**, de modo
que *"only the legitimate owner… can publish under that namespace"*. Moderação é **reativa**: a comunidade
abre issues para sinalizar servers que violam as guidelines (spam, código malicioso, impersonation).

**Fonte:** https://blog.modelcontextprotocol.io/posts/2025-09-08-mcp-registry-preview/ ·
https://modelcontextprotocol.io/registry/about

**Materialidade: ALTA.** É o *modelo de governança real* que emergiu — e é **leve** (identidade verificável +
moderação reativa), não uma plataforma pesada. Bate com o custo/escala do Onion.

**Implicação p/ Onion:** o Onion **já faz o equivalente mais forte**: identidade verificada = pin explícito +
`trust:` no `members.yaml`; e a curadoria é **proativa** (gate humano do maestro), não reativa-por-denúncia.
Onde o mercado depende de "alguém reportar depois", o Onion aprova antes. Alinhar a *grafia* de identidade
(namespace/reverse-DNS por membro) é barato e prepara interop.

---

### F3 — O ecossistema declara: "descoberta resolvida, CONFIANÇA não" — curadoria em escala é o gap real

**Claim:** Análise de supply-chain (SafeDep, 2025-2026): *"The official MCP registry has successfully solved
the problem of discovery. The next challenge… is to solve the problem of **trust**."* Evidência do gap:
**~64,7 milhões de entradas para apenas 1.691 pacotes reais** (npm/PyPI/containers) — duplicação massiva de
CI/CD automático; **typosquatting persiste** apesar de OIDC/DNS; é um **"meta-registry"** que guarda só
metadados e *"leaving validation to downstream systems"*. Conclusão da fonte: *"a curated, security-first
sub-registry will be the deciding factor in its adoption… governed and verified discovery remains largely
unsolved at enterprise scale."*

**Fonte:** https://safedep.io/the-state-of-mcp-registries/

**Materialidade: ALTA.** Esta é **a confirmação refinada** do alerta da 1ª rodada, com fonte muito melhor que
o issue mal-atribuído: o problema não-resolvido não é *descobrir*, é **confiar/curar governadamente em
escala** — e o remédio apontado é literalmente "um sub-registry curado, security-first".

**Implicação p/ Onion:** o Onion **não tem o problema de escala** (5 membros) e **já opera a solução
apontada** — um sub-registry curado à mão. O gate humano + `trust:` + `.claude/validation/` são a "validação
downstream" que o meta-registry aberto não faz. **Manter GATED + curar à mão é a posição recomendada pela
própria evidência**, não uma limitação a superar.

---

### F4 — Docker MCP Catalog: catálogo GOVERNADO com assinatura + SBOM + provenance + commit-pinning

**Claim:** Docker MCP Catalog (abr/2025, 100+ tools verificadas) distingue **"Docker-built" (build signing,
SBOMs, provenance attestations, scan contínuo)** de **"community-built"**; e amarra cada server local a um
**`source.commit`** — *"a cryptographic fingerprint for the exact revision… built and published"* — porque
*"without commit pinning, a reference like `latest`… would build whatever happens to be at that reference…
vulnerable to supply chain attacks if an upstream repository is compromised."* Endereça explicitamente **Tool
Poisoning e Tool Rug Pulls**.

**Fonte:** https://www.docker.com/blog/enhancing-mcp-trust-with-the-docker-mcp-catalog/ ·
https://www.docker.com/blog/docker-mcp-catalog-secure-way-to-discover-and-run-mcp-servers/

**Materialidade: ALTA.** Prova que a governança de registry, quando feita a sério, **converge exatamente na
doutrina do Onion**: pin-por-commit + assinatura + "não-confiável até verificado" + tiers de trust.

**Implicação p/ Onion:** o **`pin` explícito no `members.yaml` É o `source.commit`** do Docker; o
`pin-integrity-check` é o equivalente da verificação de provenance. O Onion **já está alinhado** ao padrão
mais rigoroso do mercado. Reforça a doutrina "payload remoto = supply-chain não-confiável até verificado" com
uma fonte primária forte. Direção defensável: expor tier de trust visível (Docker-built vs community) no
console P0-3 — `verified` vs `community` por membro.

---

### F5 — Backstage: MCP entrou como *actions*, mas registry governado segue parado (CORREÇÃO da citação S2)

**Claim:** Backstage shippou `@backstage/plugin-mcp-actions-backend` (v1.40, meados 2025) expondo ações como
MCP tools — mas **não há descoberta/registro/governança de MCP servers em escala nativa**. A proposta
comunitária de MCP Registry (**community-plugins #4034**) segue *"open and stalled"*; há **RFC #32062**
(modelar MCP server como `kind: API`, `spec.type: mcp-server`) ainda em discussão; e *"zero A2A protocol
integration in Backstage — no plugins, no proposals, no community efforts."* O `IBM/mcp-context-forge#2809`
citado pela 1ª rodada **NÃO é** a proposta do Backstage — é um **EPIC do IBM ContextForge** (aberto) que se
propõe a ser *"the MCP federation, A2A agent gateway, and governance layer behind Backstage's developer portal."*

**Fonte:** https://github.com/IBM/mcp-context-forge/issues/2809 ·
https://github.com/backstage/backstage/issues/32062 ·
https://backstage.io/api/next/modules/_backstage_plugin-mcp-actions-backend.html

**Materialidade: ALTA (correção + confirmação).** Corrige a atribuição do SYNTHESIS (o issue é do
ContextForge, não do Backstage) **e ainda assim confirma** a tese: mesmo o IDP de referência do mercado
(Backstage) **não** resolveu registry/discovery de capacidade governado out-of-box — está fragmentado entre
RFC parado, EPIC de terceiro e modelagem ad-hoc.

**Implicação p/ Onion:** **não construir plataforma tipo Backstage** (já era o veredito P0-3 do SYNTHESIS —
reforçado). O gap que o Backstage não fecha é o que o Onion fecha com `members.yaml` + gate humano. Corrigir a
citação no SYNTHESIS para não pendurar a tese num issue mal-rotulado.

---

### F6 — A2A padroniza o DESCRITOR (Agent Card), mas deixa registry/curadoria "por sua conta"

**Claim:** A2A publica **Agent Card** em `/.well-known/agent-card.json` (skills, transporte, security schemes),
opcionalmente **assinado via JWS (RFC 7515)**; e descreve o padrão registry/catalog para "centralized
management, curation and governance" enterprise. **PORÉM** a spec é explícita: *"The current A2A specification
**does not prescribe a standard API for curated registries**"* — registro, naming service, resolução e
workflows de aprovação/curadoria ficam *"up to you"* (Solo.io: são *"the missing pieces to A2A"*).

**Fonte:** https://a2a-protocol.org/latest/topics/agent-discovery/ ·
https://www.solo.io/blog/agent-discovery-naming-and-resolution---the-missing-pieces-to-a2a

**Materialidade: ALTA.** Fecha a simetria com o MCP: **ambos os protocolos padronizam o *descritor* buscável;
nenhum padroniza a *governança/curadoria* do registry.** É aí, precisamente, que o Onion opera com gate humano.

**Implicação p/ Onion:** o par SSOT-central + gate confirma-se como **a camada que os protocolos deixam em
aberto**, não como reinvenção do que já existe. O `a2a-live` GATED transporta sobre o descritor padronizado
(Agent Card/`/.well-known/`) enquanto a **curadoria/aprovação** — que a spec delega — fica no maestro. Direção:
Agent Card por membro derivado do `members.yaml`, opcionalmente JWS-assinado; registry-API **fica GATED**
porque a própria spec não a resolve.

---

### F7 — Supply-chain de package registry convergiu em provenance criptográfica ligada ao commit (npm/Sigstore/SLSA)

**Claim:** npm provenance (GA 2023, endurecida 2025) = implementação do **SLSA** via **Sigstore**: publicar
com `--provenance` cria atestação **assinada** que liga *"a published package version, the exact source commit
that produced it, and the build system"*, registrada em **transparency log público**; **Trusted Publishing**
exige token **OIDC** do CI (GitHub/GitLab) em vez de senha/token de longa duração, e o npm *"will only accept
new versions that carry a valid OIDC attestation."* JSR e Homebrew seguem o mesmo modelo (cosign verifica os
bundles).

**Fonte:** https://github.blog/security/supply-chain-security/introducing-npm-package-provenance/ ·
https://blog.sigstore.dev/npm-provenance-ga/ · https://docs.npmjs.com/generating-provenance-statements/ ·
https://jsr.io/docs/trust

**Materialidade: ALTA.** Estabelece o **padrão de governança de registry que o mercado inteiro adotou** —
identidade verificável (OIDC), provenance liga artefato→commit→build, verificação pelo consumidor, log
público. É a espinha da tese "não-confiável até verificado".

**Implicação p/ Onion:** o Onion **já pratica a essência** (pin-por-commit no `members.yaml`, gate humano,
ledger append-only em git = transparency log de escritor único). O que **não** faz — assinatura
criptográfica/OIDC — é **desnecessário na escala atual** (transporte por git-async entre repos do próprio
maestro, um escritor por repo). É o candidato natural a **gatilho de revisão**: se um adotante passar a rodar
CI que publica artefatos consumidos por terceiros, adotar provenance Sigstore/SLSA vira barato e idiomático.

---

### F8 — Anthropic também distribui capacidade via Claude Code plugins com "safety screening" (o análogo nativo)

**Claim:** Plugins do Claude Code (GA out/2025) empacotam skills+subagents+slash-commands+hooks+MCP numa
unidade instalável, com discovery via **diretório oficial vetado pela Anthropic** + **marketplace comunitário
com "automated validation and safety screening"** (confirmado em `S4·F9`, contra claude.com/blog +
code.claude.com/docs + anthropics/claude-plugins-official).

**Fonte:** SYNTHESIS `S4·F9` (confirmed) · https://code.claude.com/docs (plugins) ·
https://github.com/anthropics/claude-plugins-official

**Materialidade: MÉDIA.** Não é registry de *federação* (é de *plugins*), mas mostra que **na plataforma-única
do Onion a Anthropic já opera o par "diretório vetado + marketplace com screening automático"** — o mesmo
formato de governança de F2/F3, no vetor certo.

**Implicação p/ Onion:** o "automated safety screening" é o análogo do `.claude/validation/` (gate mecânico); o
"diretório vetado" é o análogo da curadoria do maestro. Se o pacote de adoção for modelado como plugin
(direção `S4·F9`), o Onion pega carona no discovery/screening nativo **sem** construir registry próprio —
convergente com "não adotar plataforma, alinhar formato".

---

## Resolução do gap

**O que este stream FECHA do SYNTHESIS.**

O SYNTHESIS listava, em "O que ainda falta pesquisar":

> *"'Registry de capacidade governado' é problema não-resolvido no mercado (`S2` alerta: proposta Backstage
> MCP registry travada). O Onion não deve assumir padrão pronto de descoberta governada — daí manter
> A2A/registry gated."*

Este item passa de **gap em aberto** para **RESOLVIDO com veredito refinado + citação corrigida**:

1. **REFUTADO (leitura forte):** *"não existe padrão pronto de descoberta"* — falso desde set/2025. Existe MCP
   Registry oficial (F1/F2), Docker MCP Catalog (F4), Agent Card A2A (F6) e plugins Anthropic (F8). **A
   descoberta está padronizada.**

2. **CONFIRMADO (direção, com fonte muito melhor):** *"governança/curadoria de confiança EM ESCALA é
   não-resolvida"* — sustentado por fonte primária de supply-chain (F3: *"discovery solved, trust not";* 64,7M
   entradas / 1.691 pacotes; typosquatting; meta-registry sem curadoria) + pelas specs que **delegam** a
   curadoria (F6: A2A *"does not prescribe a standard API for curated registries"*; F1: sub-registry curado é
   do consumidor). O que falta ao mercado é **exatamente** o "curated, security-first sub-registry".

3. **CORRIGIDO (citação):** `IBM/mcp-context-forge#2809` **não é** a proposta do Backstage — é um EPIC do IBM
   ContextForge (F5). A proposta Backstage parada é `community-plugins #4034` + RFC `#32062`. **Recomenda-se
   editar o SYNTHESIS** para trocar a fonte e o rótulo; a tese sobrevive, mais forte.

4. **DECISÃO DE POSTURA (insumo, não-doutrina):** **manter A2A/registry GATED e curar à mão** não é só
   defensável — é a posição que a **própria evidência recomenda** para a escala do Onion. O `members.yaml` já
   é o sub-registry privado curado (F1); o `pin` já é a provenance-por-commit (F4/F7); o gate humano é a
   curadoria proativa que o mercado só faz reativa-por-denúncia (F2/F3); o `.claude/validation/` é o "safety
   screening" (F8). **Não adotar plataforma de registry** (F5 reforça o veredito anti-Backstage de P0-3).

5. **AÇÃO BARATA que o gap sugere (fecha P0-2/P0-4 com alinhamento de formato):** ao fazer `graph.sh` ingerir
   o `members.yaml` (pré-requisito já identificado no SYNTHESIS), **alinhar o esquema aos formatos emergentes**
   — identidade em namespace reverse-DNS por membro, Agent Card derivado em `/.well-known/agent-card.json`,
   tier de trust `verified|community` visível no console, `pin` documentado como provenance-de-commit. Custo
   ~zero de schema (campos já existem), e prepara interop futura com MCP Registry / A2A sem comprometer o gate.

**Nada aqui abre o que já estava sólido** (single-source, comunicação federada, Grana.Ai como data-plane,
a2a-live gated). O stream **firma** a peça que o SYNTHESIS deixara como "não pesquisado" e **remove a
insegurança** de estar apoiado numa citação frágil.

---

## Nota de método

Todas as URLs foram buscadas/fetchadas nesta rodada (jul/2026), priorizando **fontes primárias** (blog oficial
MCP, spec A2A, docs Docker/npm/GitHub/Sigstore, issues no GitHub). A única fonte secundária estrutural é
`safedep.io` (F3) — mas é análise de supply-chain com dados quantitativos verificáveis e sua tese central
("discovery solved, trust not") é **corroborada** independentemente pelas specs primárias A2A/MCP (F1/F6). O
achado `S4·F9` (F8) é reuso de veredito `confirmed` da 1ª rodada, não re-verificado aqui.

---

## Verificação adversarial

> 2ª rodada, stream G2. Doutrina: **evidência ou abstenção** — nunca `confirmed` na dúvida.
> Cada veredito checou a fonte (existe? recente? sustenta SEM exagero? há contra-evidência?).

- **F1 → `refuted`** — O payload recebido para verificação (`claim: "teste"`, `source:
  https://example.com`, materialidade `high`) é um **placeholder de teste**, não um achado material. A fonte
  `example.com` é o **domínio reservado da IANA para exemplos de documentação** (RFC 2606/6761): ao ser
  fetchada (jul/2026) retorna apenas *"This domain is for use in documentation examples without needing
  permission. Avoid use in operations"* — **nenhuma** menção a "teste", capability registry, MCP ou
  federação. A fonte não sustenta claim material algum; a claim é uma string-placeholder. Logo: **sem
  evidência = refutado** (contra-evidência direta: a própria página se declara não-operacional/ilustrativa).
  Observação de campo: **não confundir** com o F1 real deste documento ("MCP Registry oficial existe",
  respaldado por fontes primárias) — o payload verificado aqui é o stub, não o achado do arquivo.
