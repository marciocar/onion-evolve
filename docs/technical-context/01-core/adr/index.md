---
title: "Índice de Architecture Decision Records (ADR) — Core do Sistema Onion"
date: 2026-07-25
---

# Índice de ADRs — Core do Sistema Onion

> Escopo: **CORE** (framework template em `.claude/`). Este arquivo é um **índice** — não recria o
> conteúdo dos ADRs, só aponta para eles com 1 linha de sumário + status. Os ADRs em si vivem fora da
> árvore `docs/technical-context/`, em `docs/analysis/onion-adr-*.md` (decisão consolidada de 2026-05-18:
> ADRs do core ficam em `docs/analysis/`, não em pasta própria — ver
> [`docs/analysis/onion-review-2026-05.md`](../../../analysis/onion-review-2026-05.md)).

**Fonte**: `docs/analysis/onion-adr-*.md` — 36 arquivos no filesystem em 2026-07-25
(`ls docs/analysis/onion-adr-*.md | wc -l` → `36`). Cada linha abaixo foi lida do `title:`/`status:`
do frontmatter e da linha `## Decisão` (ou equivalente) de cada arquivo-fonte — nenhum resumo foi
inventado sem abrir o arquivo.

**Convenção de status** (como aparece nos arquivos-fonte, não normalizada aqui): `aceito`/`accepted`,
`proposto`/`proposed`, `provisório`, ou um status composto (ex.: "aceito — doutrina; implementação
gated"). Onde o arquivo mistura doutrina aceita com execução gated, a linha reproduz os dois.

---

## 1. Adoção & Topologia da Família Onion

Como o framework se instala em outro repo, versiona a distribuição e resolve quem manda em cada linhagem.

| ADR | Decisão (1 linha) | Status |
|---|---|---|
| [Adoção de repositório: comando in-platform, não CLI](../../../analysis/onion-adr-repo-adoption-2026-06.md) | `/meta:adopt` é comando faseado in-platform (nunca CLI standalone); suporta instalar ou operar in-place, com isolamento opcional em worktree | accepted |
| [`/meta:adopt --update` via merge de vendor-branch](../../../analysis/onion-adr-adopt-vendor-branch-merge-2026-07.md) | `--update` migra de copy-over (`cp -R`+diff) para merge de uma branch `onion/vendor` persistente (never-clobber estrutural) | accepted — implementado 2026-07-09 (Fases 1-3), verificado por dogfood de campo (392 arquivos) |
| [`"Onion adota, não impõe"`: verticais opinativas deferem ao padrão do projeto](../../../analysis/onion-adr-adopt-to-not-impose-2026-06.md) | Na adoção, o eixo design-system-provider é SDAAL: o Onion detecta e defere ao padrão já em uso no projeto-alvo em vez de impor o seu | proposto |
| [Topologia de repositórios da família Onion: core selável + doors + apps](../../../analysis/onion-adr-family-repo-topology-2026-07.md) | Forma híbrida por tipo de repo (core selável, doors públicas, apps) para a família de repositórios que usam/derivam do Onion | aceito — F0-F1 doutrina; F2+ execução gated fora deste worktree |
| [Topologia da porta Claude: desfazer o colapso porta pública ↔ core privado](../../../analysis/onion-adr-claude-door-topology-2026-07.md) | Resolve a confusão entre a porta pública "Claude" e o core privado do Onion | aceito — D2 resolvida 2026-07-19 por `family-repo-topology` em favor de B-via-adopt |
| [O ingestor de doutrina (adotante→core)](../../../analysis/onion-adr-doctrine-ingestor-2026-07.md) | O core absorve doutrina de campo vinda de um adotante, de forma trust-gated e apoiada em KG, sempre human-gated | accepted (doutrina) — 1º dogfood nesta rodada (granaai); generalização a F4 é gated |
| [Autoridade de merge por papel/linhagem](../../../analysis/onion-adr-merge-authority-per-lineage-2026-07.md) | Em produção de cliente, merge é consent-gated pelo cliente — a autoridade de merge depende do papel/linhagem do branch | accepted (doutrina) — implementação design-target (slice de follow-on) |
| [Grana.Ai na linhagem do Onion](../../../analysis/onion-adr-granaai-consolidation-2026-07.md) | Registra onde o Onion se consolidou como potência de uso real (não a origem do framework) — confidencialidade INTERNO | aceito — Fase 0 e Fase 3 executadas 2026-07-06 |
| [Onion Mini: destilação federada como produto de entrada da família](../../../analysis/onion-adr-mini-distillation-2026-07.md) | `marciocar/onion-mini` (ex-onion-portable) como destilação federada, produto de entrada leve da família de repos | aceito e executado — rebrand + refresh v2 entregues; publicação web gated |

## 2. Federação, Co-evolução & Comunicação Cross-repo

Como core e adotantes trocam contrato/sinal sem acoplamento nem push cross-repo indevido.

| ADR | Decisão (1 linha) | Status |
|---|---|---|
| [Vocabulário dos fluxos de co-evolução: downstream / upstream / handoff](../../../analysis/onion-adr-coevolution-flow-naming-2026-06.md) | Renomeia os 3 fluxos de co-evolução (antes "A/B/C") para nomes que descrevem a direção do fluxo, não a letra | accepted |
| [Eixo de risco da comunicação: transporte (auto) vs execução (gate)](../../../analysis/onion-adr-comms-transport-vs-execution-2026-06.md) | O risco de A2A não é binário sim/não; separa transportar+notificar (automatizável) de ler+interpretar+executar (gate humano obrigatório) | accepted (doutrinário) — 2026-06-20 |
| [Ledger de co-evolução: formato e localização](../../../analysis/onion-adr-ledger-format-location-2026-06.md) | Markdown fica como formato do ledger; repo-neutro é gated; norte é automatizar o transporte, não o formato | proposto |
| [Sub-protocolo do transporte manual de co-evolução (relay upstream)](../../../analysis/onion-adr-manual-relay-subprotocol-2026-06.md) | `/meta:co-relay` entrega-sem-commit no relay upstream — corrige a Decisão 3 do ADR de ledger-format-location | accepted |
| [A foto da federação como KG: overlay AUDIT de saúde-de-verificação](../../../analysis/onion-adr-federation-kg-audit-overlay-2026-07.md) | A saúde da federação é um overlay AUDIT no KG (não um domain-layer forçado); radar de federação é slice de follow-on | accepted (finding do dogfood) |
| [Capability Contract: auto-descrição por componente + conformance tiers](../../../analysis/onion-adr-capability-contract-2026-06.md) | Padrão de plugin Onion descentralizado: cada componente se auto-descreve, com tiers de conformidade e injeção condicional | aceito |
| [Capability-update fora-do-git: o 4º modo de proveniência](../../../analysis/onion-adr-capability-update-out-of-git-2026-07.md) | `--update` de capability em adotante docs-only é entrega-fora-do-git com 3-way por manifest de hashes, maestro-gated | proposto — design only; implementação gated até 1º `--update` docs-only real (granaai) |
| [SDAAL aninhado de 2 níveis (canal → solução)](../../../analysis/onion-adr-sdaal-nested-two-level-2026-07.md) | O adapter de comunicação é, ele mesmo, um SDAAL de 2 níveis: canal (nível 1) e solução dentro do canal (nível 2) | accepted (design) — materialização gated por nível |
| [Modelos de trabalho: topologias de sessão da federação Onion](../../../analysis/onion-adr-work-models-session-topologies-2026-07.md) | Eixo E (topologia de sessão, valores W1-W7) nomeia as formas de concorrência entre sessões/repos da federação | aceito — 2026-07-02, decisão durável |

## 3. Knowledge Graph, Design & Investigação

Como o Onion modela rastreabilidade, frescor e investigação de longo prazo.

| ADR | Decisão (1 linha) | Status |
|---|---|---|
| [Design estende o KG (não ganha grafo próprio)](../../../analysis/onion-adr-design-extends-kg-2026-07.md) | Design e KG-SDAAL são eixos ortogonais: design DIVERGE (gera N versões, gate WCAG decide), KG REGE (rastreabilidade); atom-map estende o KG, não cria 2º grafo | accepted |
| [Frescor como cidadão de 1ª classe no KG SDAAL](../../../analysis/onion-adr-kg-freshness-gate-2026-07.md) | Duas guardas irmãs: (A) `verified_at`/gate STALE para nós PROD (estendido a DEV via `verified_against`) e (B) `schema_version`/gate de drift | accepted — F1/F1.1/F2 implementadas 2026-07-16 |
| [Contexto de domínio: SSOT viva com ciclo de vida CRUD+](../../../analysis/onion-adr-domain-context-lifecycle-2026-06.md) | `business-context/`, `technical-context/`, `compliance-context/` são SSOT vivas com ciclo de vida CRUD+, não snapshot gerado uma vez | accepted |
| [Duas verticais novas no LEGO: investigação (KG+pesquisa) e cartografia de contextos](../../../analysis/onion-adr-verticals-investigation-cartography-2026-07.md) | Desenha, via SDAAL, as verticais de investigação (KG + pesquisa) e cartografia de contextos de domínio | provisório — F0 aceito (desenho + gatilhos); construção gated |
| [Modelo operacional "Constelação de Estudos"](../../../analysis/onion-adr-constellation-operating-model-2026-07.md) | Estudos (`discuss/*`) isolados operam como constelação, com o core como observatório sob convite | proposto |
| [Telescópio: observação read-only de sessões vivas](../../../analysis/onion-adr-telescope-session-observation-2026-07.md) | Nomeia e funda a doutrina (10 invariantes) de observar sessões vivas sem comunicar com elas — observar ≠ comunicar | accepted (doutrina) — gated até 1 dogfood de recall + cabeamento (P0) |
| [Runtime de orquestração autônoma de fios: escada graduada de autonomia](../../../analysis/onion-adr-autonomous-thread-runtime-2026-07.md) | Escada graduada Audit→Automate com moat determinístico para conduzir fios de trabalho autonomamente | proposed — gated até checkpoint da Fase 2 |
| [Object-Led Discovery & Fitting](../../../analysis/onion-adr-object-led-discovery-2026-07.md) | "Promover objeto a papel premium" é playbook do catálogo (materializado na skill `onion-patterns`), não skill/ADR-heavy nova | aceito (doutrina + playbook materializado); dogfood retroativo concluído |

## 4. Engenharia & Padrões Transversais (L0)

Padrões que atravessam comandos/agentes/skills — não pertencem a uma vertical só.

| ADR | Decisão (1 linha) | Status |
|---|---|---|
| [Git hooks nativos (`core.hooksPath`) como padrão Onion de pre-commit](../../../analysis/onion-adr-native-githooks-standard-2026-06.md) | Hooks nativos do git são o padrão Onion; husky/lefthook ficam como opcionais do adotante | aceito |
| [Padrão Faseado Retomável (PFR) como padrão transversal L0](../../../analysis/onion-adr-phased-resumable-pattern-2026-06.md) | Nomeia o PFR (fases + retomada por sessão persistente) como padrão L0 aplicável a qualquer comando faseado do framework | proposto — provisório |
| [Ciclo de vida do toolbox: régua P0-P3](../../../analysis/onion-adr-toolbox-lifecycle-2026-06.md) | Régua de classificação P0-P3 + coesão dos `create-*` sobre o substrato existente é a porta de entrada do toolbox | accepted |
| [Branch-roles como SDAAL (de 1 papel para N)](../../../analysis/onion-adr-branch-roles-sdaal-2026-07.md) | Papéis de branch/ambiente passam a ser resolvidos por-projeto via SDAAL, em vez de fixos | proposto — design-only, gated |
| [Branching: base resolvida (agnóstica), não GitFlow/develop hardcoded](../../../analysis/onion-adr-branching-base-agnostic-2026-06.md) | A base de branch é dado resolvido (agnóstico), aplicando "adota não impõe" ao próprio GitFlow | proposto — provisório |

## 5. Verticais & Produto do Framework

Decisões que criam ou ampliam uma vertical/dimensão do próprio Onion.

| ADR | Decisão (1 linha) | Status |
|---|---|---|
| [`/meta:create-vertical`: generalizar o padrão hub-onion](../../../analysis/onion-adr-create-vertical-2026-07.md) | Generaliza o padrão hub-onion para scaffoldar qualquer vertical de projeto (não só as 3 dimensões peer) | accepted — ratificado 2026-07-14 (4 decisões fechadas); F1 é o próximo passo |
| [Vertical Educacional (`onion-education`)](../../../analysis/onion-adr-education-vertical-2026-07.md) | F0 aberto: camada de conhecimento (`docs/knowledge-base/education/`) sobre os confirmados da pesquisa SRL/PLEA; construção gated | provisório — F0 aberto |
| [Unidade de troca do Onion: "vertical-skill" SDAAL via marketplace](../../../analysis/onion-adr-exchange-unit-2026-06.md) | A unidade de troca do Onion é a vertical-skill, empacotada como plugin Claude Code (marketplace + proveniência); monetização gated | aceito |
| [Blog/publicação do Onion: fonte-no-repo, gerador determinístico](../../../analysis/onion-adr-blog-publication-generator-2026-07.md) | Publicação editorial do Onion usa fonte-no-repo + gerador determinístico + voz autoral gated, em plataforma SSG-git | aceito (plataforma + arquitetura do gerador); gated (1º ensaio real; costura SDAAL) |
| [SLM como ferramenta via SDAAL: de-identificação de PII](../../../analysis/onion-adr-slm-as-tool-de-identification-2026-06.md) | Um SLM local faz de-identificação de PII como "segundo runtime" (ferramenta via SDAAL), não como orquestrador | aceito |

---

## Como este índice se mantém

Este arquivo é **gerado por leitura direta** de `docs/analysis/onion-adr-*.md` (frontmatter `title`/`status`
+ seção `## Decisão`), não por contagem hardcoded. Ao criar um novo ADR nessa convenção de nome, adicione
uma linha na tabela de tema mais próxima (ou crie uma nova seção temática) e atualize a contagem no topo
deste arquivo. Não existe automação dedicada (`/meta:inventory` cobre comandos/agentes/skills/KBs, não ADRs)
— a atualização deste índice é manual, no mesmo PR que adiciona o ADR.

## Ver também

- [`docs/analysis/onion-review-2026-05.md`](../../../analysis/onion-review-2026-05.md) — decisões de
  identidade canônica do Onion (2026-05-18) que fixam `docs/analysis/` como o lar dos ADRs do core.
- [`docs/onion/inventory.md`](../../../onion/inventory.md) — SSOT de contagens do framework (comandos,
  agentes, skills, KBs) — não inclui ADRs.
