---
title: 'ADR — Branch-roles como SDAAL: papéis de branch/ambiente resolvidos por-projeto (de 1 papel para N)'
date: 2026-07-11
type: adr
status: proposto
decision-scope: engineering / branching-topology (SDAAL de papéis de branch)
supersedes: none
extends: onion-adr-branching-base-agnostic-2026-06.md
deciders: maestro + sessão de evolução
context_freshness: 2026-07-11
related:
  - onion-adr-branching-base-agnostic-2026-06.md (pai — resolução de base para 1 papel: integration)
  - onion-veredito-branch-methodology-2026-07.md (o veredito que este mecanismo alimenta)
  - onion-parecer-rhilo-lineages-2026-07.md (o modelo de linhagens do metagamify)
  - ../evolution/rfc/rfc-0005-scope-inheritance-polymorphism.md (eixo versão vs escopo)
  - ../../.claude/validation/resolve-integration-branch.sh (a semente a generalizar)
  - ../../.claude/utils/trust/interface.md (precedente: SDAAL adapter-por-papel/tier)
  - ../meta-specs/architecture.md (§6.1 — schema do .onion-version, onde entra branch_roles:)
  - ../knowledge-base/concepts/specification-driven-ai-abstraction-layer.md (anatomia SDAAL)
---

# ADR — Branch-roles como SDAAL (de 1 papel para N)

> **Status: PROPOSTO (design-only, gated).** Nomeia a decisão, o contrato e a costura. **Nenhum código
> executável** é escrito nesta fase — o resolver, os adapters e o rewire da matriz de proteção ficam
> **diferidos ao gatilho** (§7). Estende o ADR [branching-base-agnostic](onion-adr-branching-base-agnostic-2026-06.md)
> de **um** papel (`integration`) para **N** papéis por faceta.

## Contexto

O ADR de 2026-06 já cravou: *"a base de integração é **dado resolvido, agnóstico** — não uma constante
`develop` hardcoded"*, resolvida por `resolve-integration-branch.sh` (`.onion-version integration_branch` →
`git config` → detecção). Mas aplicou isso **só ao papel `integration`**. Os demais papéis de branch
continuam **assumidos por regex de nome** na Matriz de Proteção (`^(main|master|develop)$`).

O sinal do metagamify/rhilo (inbox `docs/evolution/inbox/2026-07-10-metodologia-branches-gitflow-main-produto-vs-rhilo.md` — ainda não commitado)
expôs o custo: o eixo de branch está **sobrecarregado**. `develop` é tratada como "integração/lane-de-
framework", mas na prática é a **branch de staging/homologação** do código na maioria dos adotantes:

- **GranaAi**: `develop` = **stage**.
- **metagamify** (originalmente): `develop` levava os PRs de desenvolvimento ao **servidor de homologação**.
- Muitos times têm uma branch **`homolog`** dedicada.

Quando um repo carrega **as duas dimensões** — negócio/conhecimento (co-evolução do framework) **e** código
(pipeline dev→homolog→produção) — o eixo de branch faz papel duplo, e o Onion não tem vocabulário para
declarar qual branch cumpre qual papel. **Nenhuma meta-spec ou KB modela ambientes de deploy**; o único
acoplamento doutrinário é `main=produção`.

### Diligência (verificado, não aceito de cara)
1. **Não há modelo de ambiente** — ✅ verdade: GitFlow do Onion trata `develop`="integração", nunca
   "staging/homolog"; vocabulário de branch fixo (feature/develop/release/main/hotfix).
2. **A filosofia "adota não impõe" já existe** — ✅ verdade, **mas só num eixo**: `resolve-integration-branch.sh`
   resolve **a** integration branch; não há análogo para "homolog"/"staging"/"produção-por-cliente".
3. **O SDAAL já generaliza para papéis** — ✅ verdade: `.claude/utils/trust/` tem adapters por **tier/papel**
   (source/hub/standalone/consumer) resolvidos de `members.yaml`. "Não parece SDAAL?" — **sim, e é o mesmo
   SDAAL do trust**.

## Decisão

**Modelar "qual branch cumpre qual papel" como um SDAAL — `branch-roles`.** Generalizar a resolução de base
de **1 papel** para **N papéis**, mantendo "adota não impõe": o framework define papéis abstratos; **cada
projeto mapeia suas branches reais**.

### 1. Contrato de papéis — enum ABERTO por FACETA

Unifica o **mecanismo** (um mapa, um resolver) e distingue a **semântica** por faceta. A faceta diz ao
consumidor como tratar um papel **desconhecido** — nunca se inventa comportamento.

| Faceta | O que é | Papéis canônicos | Default de resolução |
|---|---|---|---|
| `flow` | alvo de PRs de integração/evolução | `integration`, `framework-lane` | `develop` se existir, senão principal |
| `environment` | branch cujo push/merge deploya um ambiente (pipeline dev→homolog→prod) | `staging`/`homolog`, `production`, `preview`, `qa`, `canary` | só `production` (→ `main`); **`staging` SEM default** |
| `lineage` | linha de produto/cliente paralela (o "cliente-como-deploy" da RFC-0005) | `lineage:<nome>` (ex. `rhilo/main`) | nenhum |

- **Aberto p/ extensão, fechado p/ modificação:** o núcleo canônico tem semântica definida; projetos
  adicionam papéis livres (`preview`, `qa`, `lineage:acme`) só declarando chave→branch, sem tocar código.
- **`framework-lane`** pode **coincidir** com `integration` (caso comum) ou ser separado (`<projeto>-evolve`).

### 2. Onde mora a declaração — `.onion-version branch_roles:` (SSOT local versionado)

```yaml
# .claude/.onion-version (repo adotado)
branch_roles:
  integration: <projeto>-evolve   # faceta flow
  production: main                 # faceta environment
  staging: develop                 # faceta environment — GranaAi: develop=stage (o mapa, não a readaptação)
# integration_branch: <branch>     # LEGADO — vira alias de branch_roles.integration (retrocompat total)
```

O campo shipped `integration_branch` **permanece aceito** e passa a ser **açúcar/alias** de
`branch_roles.integration`. `members.yaml lineages:` **fica separado** — é a visão da **federação** (pins por
linha); harmoniza-se o **vocabulário** (mesmos nomes de papel), o `.onion-version` é a fonte de verdade local.

### 3. O resolver — `resolve-branch-role.sh <role>` (DESIGN-ALVO, não implementado nesta fase)

Generaliza `resolve-integration-branch.sh` para qualquer papel, mesma filosofia determinística/sem-LLM.

```
Uso:  resolve-branch-role.sh <role> [REPO_DIR]
Saída: nome da branch em STDOUT
Exit:  0 = resolvido · 3 = papel de faceta sem default e não-declarado (Null Object) · 2 = papel desconhecido
```
Cadeia por papel (primeiro que casar vence): **(1)** `.onion-version branch_roles.<role>` → **(2)** git config
(`integration`→`gitflow.branch.develop`, `production`→`gitflow.branch.master`, abertos→`onion.branch-role.<role>`)
→ **(3)** **default POR FACETA** (não global).

> **A chave do design — Null Object por-faceta.** O resolver de integração faz "exit 0 sempre" (correto:
> sempre há base). O generalizado **não pode** para `staging` — ela pode não existir. Por isso o default é
> **por-faceta** e o Null Object emite código distinto: o chamador degrada com honestidade ("nenhuma staging
> declarada"), **nunca aponta para uma branch errada**. É a resposta honesta a "qual a branch de stage?".

**Absorção retrocompat:** `resolve-integration-branch.sh` viraria um shim → `exec resolve-branch-role.sh
integration "$@"`. Zero churn para os consumidores (`/engineer:pr`, `/meta:adopt`). *(Fase 1, gated.)*

### 4. A estrutura SDAAL — `.claude/utils/branch-roles/` (DESIGN-ALVO, não criada nesta fase)

Espelha a anatomia SDAAL ([SDAAL](../knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)).
Decisão: **o adapter é a TOPOLOGIA de branching**, não o papel (o que varia entre projetos são os defaults de
resolução e a política de proteção — e isso varia por topologia). Precedente: no `trust`, adapter = tier.

```
.claude/utils/branch-roles/
├── interface.md   # IBranchRoles: resolveRole(role)→BranchResolution; roleOf(branch)→[Role] (reverso, p/ proteção);
│                  #   protectionFor(branch)→ProtectionPolicy; environments()→[Role ordenado]; isDeclared(role)→bool
├── types.md       # BranchRole (enum aberto + facet), BranchFacet (flow|environment|lineage), BranchResolution
│                  #   (found, branch, source[stamp|gitconfig|detected|null], facet), ProtectionPolicy, BranchTopology
├── factory.md     # resolve_branch_topology(): .onion-version branch_topology: → detector; retorna adapter
├── detector.md    # detect_topology(): develop+release/* → gitflow; só main+CD → trunk-based;
│                  #   ≥2 linhas prod-like → multi-lineage; senão none
└── adapters/
    ├── gitflow.md        # integration=develop, production=main, matriz clássica
    ├── trunk-based.md    # integration=production=trunk; sem develop; staging opcional
    ├── multi-lineage.md  # production por linhagem (rhilo/main); integration separado — a forma metagamify
    └── none.md           # Null Object: só defaults de detecção
```
Como no `trust`, os `.md` são o **contrato-alvo** e o `resolve-branch-role.sh` é a **projeção executável
determinística** (o gate que roda). Paridade `.sh` ↔ adapters vigiada por `lint-selftest.sh` (modo novo). *(Fase 3.)*

## Reconciliação com o resto do sistema

- **Matriz de Proteção GitFlow** (`gitflow-patterns.md`, ambas as cópias): o regex `^(main|master|develop)$`
  vira **projeção do adapter `gitflow`**, não a fonte. Proteção deriva de `roleOf(branch)`. Corrige 2 bugs
  latentes reais: (i) `rhilo/main` **é** produção mas não casa o regex → hoje não é protegida; (ii) granaai
  `develop=stage` casa o regex como "Integração" → semântica errada. **Gated:** só reescrever quando morder.
- **`members.yaml lineages:`** → **consumidor** do mesmo vocabulário, não fonte concorrente. `.onion-version
  branch_roles` = SSOT local; `members.yaml` = pins da federação por linha.
- **RFC-0005 (eixo versão vs escopo)** — a fronteira que este ADR **crava** para não reabrir a RFC: papéis de
  branch vivem no eixo **VERSÃO/entrega**, nunca escopo. A faceta `lineage` **é** o "cliente-como-deploy" que a
  RFC-0005 deixou no eixo versão (`vendor-branch` no tempo). "Cliente-como-customização" continua **escopo**
  (cascata cognitiva/config nativa + `resolve-scope-layers.sh`) e **não** é papel de branch.
  > **Regra de ouro:** *compõe por leitura em runtime (N camadas coexistem) → escopo; é uma linha paralela
  > onde se fica numa por vez → papel de branch (`lineage`).*
- **O veredito** ([onion-veredito-branch-methodology-2026-07.md](onion-veredito-branch-methodology-2026-07.md)):
  este ADR é o **mecanismo** que sustenta a resposta "metodologia de branch = papéis resolvidos, não impostos".

## Smell nomeado (não resolvido agora)

O `members.yaml lineages:` hoje mistura **duas dimensões** sob o mesmo nome: (a) linhagem-de-branch
(metagamify: `framework`/`production` = duas branches) e (b) instância-de-máquina (granaai:
`local-kvm8`/`mauricio`; onion-evolve: `workstation`/`vps-bridge` = hosts). O SDAAL branch-roles é dono **só
de (a)**. (b) = "clones físicos com pins", outro conceito. **Nomeado aqui; refactor gated** por gatilho de
federação — não forçar agora.

## Como responde as 3 perguntas do maestro

- **(a) Qual a branch de stage?** → A que o projeto **declara** em `branch_roles.staging`. GranaAi: `develop`.
  Se não declarada, Null Object responde "nenhuma staging declarada" — **honesto**, não chuta.
- **(b) A empresa readapta a convenção dela?** → **NÃO.** A abstração se adapta a ela: só **mapeia**
  `branch_roles: {staging: develop, integration: <proj>-evolve, production: main}`. O framework não muda, a
  empresa não muda, o mapa reconcilia.
- **(c) E se surgir coisa nova (`preview`, nova linhagem de cliente)?** → **Novo papel/mapeamento**:
  `branch_roles.preview: preview` ou `branch_roles["lineage:acme"]: acme/main`. Aberto p/ extensão.

## 7. Rollout faseado e gated (a doutrina — o que NÃO fazer agora)

- **Fase 0 — AGORA (design-only, zero código):** este ADR + o veredito + `branch_roles:` como **PROPOSTO** em
  `architecture.md §6.1` + notas nas KBs (SDAAL + matriz de proteção). Responde o sinal 2026-07-10 sem
  construir à frente do gatilho.
- **Fase 1 — gatilho: um 2º papel é de fato consumido por um comando.** Escrever `resolve-branch-role.sh` +
  shim retrocompat + cobertura em `lint-selftest.sh` (helper-testável-primeiro).
- **Fase 2 — gatilho: branches protegidas de um projeto divergem do regex e isso morde.** Religar a matriz de
  proteção a `roleOf()` + consumir `branch_roles:`. Toca **as duas cópias** de `gitflow-patterns.md` + `git:*`.
- **Fase 3 — gatilho: comando precisa dos adapters de topologia OU a federação precisa reconciliar linhagem.**
  Materializar `.claude/utils/branch-roles/` + harmonizar `members.yaml` + registrar em `integrations.md`.

**Guardas anti-v4.0 (construir à frente do gatilho foi o erro v4.0):** não criar a árvore `utils/branch-roles/`
especulativamente; não reescrever `git:sync|flow|init` (mesmo diferimento do ADR de 2026-06); não fundir
`lineages:` no `.onion-version`; não trocar o default de `integration` (#160).

## Consequências

- **Positivas:** responde um gap formalmente aberto; adotante não readapta convenção; novos ambientes/linhagens
  são open/closed; corrige 2 bugs latentes de proteção quando a Fase 2 abrir; reusa o padrão SDAAL provado.
- **Custo:** uma dimensão a mais (faceta) para o leitor; duas superfícies de declaração (`.onion-version` +
  `members.yaml`) com risco de drift (mitigado: SSOT local + pins da federação); a Fase 0 entrega doutrina, não
  o resolver executável — GranaAi/metagamify só terão `staging` resolvível na Fase 1 (deliberado: sem
  consumidor, o helper seria construção à frente do gatilho).
