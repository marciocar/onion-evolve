---
title: "Federação e adoção do Onion — guia de síntese"
date: 2026-07-24
type: concept
status: active
note: "Os perfis da §6 são ilustrativos (anonimizados para circulação pública)."
related:
  - multi-repo-federation.md
  - federation-usage-modes.md
  - source-vs-derivation.md
  - public-door-vs-private-core.md
  - ../../evolution/federation/members.yaml
  - ../../../.claude/commands/meta/adopt.md
  - ../../../.claude/commands/meta/co-evolve.md
  - ../../../.claude/utils/trust/adapters/source.md
  - ../../../.claude/utils/trust/adapters/hub.md
  - ../../../.claude/utils/trust/adapters/standalone.md
  - ../../../.claude/utils/trust/adapters/consumer.md
  - ../../../.claude/identity/personality.md
  - ../../../.claude/validation/federation-radar.sh
---

# Federação e adoção do Onion — guia de síntese

> **O que este documento é — e o que não é.** É uma **derivação de leitura** (doutrina
> [fonte≠derivação](source-vs-derivation.md)): reúne, num só lugar e numa ordem pedagógica, o que
> já está espalhado — e correto — nas fontes canônicas listadas em `related:` acima. **Não**
> é uma segunda matriz concorrente: onde a matriz canônica de tipos de uso já existe
> ([federation-usage-modes.md](federation-usage-modes.md)), este guia **cita**, não reescreve. O
> valor novo aqui é a costura pedagógica: caminhar o processo real de `/meta:adopt` fase-a-fase, a
> tabela de permissão consolidada dos 4 adapters de trust, e os perfis reais como estudo de caso —
> nenhum dos três existe hoje reunido em um só lugar. Se uma fonte citada mudar, corrija a fonte —
> este documento é descartável e reconstruível a partir dela. Camada de leitura irmã: o Artifact
> HTML "premium" derivado deste markdown (link entregue à parte, uso interno).

## 1. Dois sistemas, não um

O Onion tem **duas máquinas de coordenação entre repos**, com maturidade muito diferente. Confundi-las
é o erro mais comum ao explicar "a federação":

| | **Co-evolução / Adoção** | **Federação formal por contrato** |
|---|---|---|
| Estado | 🟢 **ativo, em uso real** — **8 adotantes** hoje (de 12 membros; `kind: adopter`, régua D8) | 🔒 **construído, não graduado** — 0 contratos, 1 adotante de peso |
| Unidade | um **membro** (repo inteiro) | um **contrato** (uma integração específica entre 2 repos) |
| Mecanismo | `/meta:adopt`, `members.yaml` (tiers + trust), canais `inbox/`/`inbound/`, doc-bridge leve (`co-*`) | `contracts/<id>.md` num ledger git, `CHANGELOG.md` como inbox |
| Pergunta que responde | "este repo é do Onion — o que ele pode trocar com o resto?" | "esta API específica entre A e B pode mudar sem quebrar nada?" |
| Quando liga | sempre que alguém adota | só quando um contrato **pode quebrar consumers** ou há **3-5+ adotantes** ([gatilho](federation-usage-modes.md#4-gatilhos-de-graduação--tabela-única)) |

Este guia cobre os dois: §2-§6 são a Co-evolução/Adoção (o que está em uso); §7 é a Federação formal
(a capacidade latente, para quando o gatilho chegar).

## 2. Modelo mental (por que "federação", não "plataforma")

Fonte: [`multi-repo-federation.md` §1](multi-repo-federation.md#1-modelo-mental-peer-não-hub).

- **Peer, não hub-and-spoke.** Cada repo mantém seu Onion **soberano** — o core não hospeda nada dos
  adotantes, não roda dentro deles, não os controla remotamente.
- **Git-assíncrono por padrão.** A troca base é sempre um arquivo markdown commitado (ou entregue
  sem-commit) em um canal convencionado — não há servidor central, dono de estado ou orquestração viva.
- **O humano é o maestro.** Toda decisão de "levar isto de A para B" passa por uma pessoa.
- **A linha vermelha permanece:** nunca IA-fala-IA **autônoma** entre repos distintos. Isto **não**
  foi revogado pelo canal `a2a-live` (ver abaixo) — o canal existe, mas é *verifica-antes-de-agir*,
  gated por `members.yaml`, e para receptores `mode: regulated` degrada a `propose-only`
  (never-live-pull). O gate humano é o invariante; o transporte só encurtou a distância.

**Sobre o `a2a-live` (RFC-0004 F2.2, shipou 2026-07-10).** O antigo "só projeção one-way, nunca
transporte vivo" foi **superado na prática**: existe hoje um `federation-transport` SDAAL com adapter
`a2a-live.md` sobre o `onion-bridge`, um **canal vivo** que aceita sinais de remetentes (inclusive
regulados) com guarda de clock-trust. O que *não* mudou é a semântica de aceitação: cada sinal é
assinado por um `kid` cuja pubkey o core **pinou** (`jwks/<kid>.pem`), passa por `a2a-verify.sh`
(6 camadas, fail-safe) na fronteira, e a aplicação continua sob moat gated (`members.yaml` `trust:`).
Nenhuma auto-aplicação. O Agent Card servido em `/.well-known/agent-card.json` é **do core** (single-source,
RFC-0004 veta fatiar o SSOT) — hospedar o endpoint não cria uma segunda identidade.

## 3. As camadas (tiers) — RFC-0003

Fonte: `members.yaml` (`role:` de cada membro) + os 4 adapters de trust
(`.claude/utils/trust/adapters/*.md`).

| Tier | Papel | Parent | Sub-adotados (downstream) |
|---|---|---|---|
| **T0 — source** | o core (`onion-evolve`) — autoridade emissora, lê tudo por papel | nenhum | qualquer membro |
| **T1 — hub** | adotou o core **e** tem (ou pode ter) seus próprios adotados | `source` | T2 (consumers) |
| **T2 — consumer** | adotou um **hub**, não o core diretamente — o hub é seu único ponto de contato upstream | um hub T1 específico | nenhum |
| **T3 — standalone** | adotou o core direto, sem sub-adotados — a instância mais simples | `source` | nenhum |

### 3.1 Quem pode falar com quem (a tabela que faltava consolidada)

Extraída literalmente dos 4 adapters — cada linha é uma regra real do arquivo-fonte, não inferida:

| De ↓ / Para → | Core (T0) | Hub T1 (peer) | Seu parent (se T2) | Seus T2 (se hub) | Outro T3 |
|---|---|---|---|---|---|
| **Core (T0)** | — | `relay`/`advise`/`correct` sempre autorizados (autoridade implícita) | idem | idem | idem |
| **Hub (T1)** | `relay` sempre; `advise`/`correct` só com concessão explícita em `trust:` | `relay`/`advise` só se **ambos** os lados concederem (`can_advise_to` + `can_receive_from` do peer); `correct` bloqueado por padrão, exige intermediação do core | — | `relay`/`advise`/`correct` sempre (hub tem autoridade sobre seus T2) | n/a |
| **Consumer (T2)** | **bloqueado** — sem canal direto; tudo passa pelo hub | n/a | `relay`/`advise` sempre; `correct` bloqueado por padrão | n/a | **bloqueado** sempre |
| **Standalone (T3)** | `relay` sempre; `advise`/`correct` só com concessão explícita | **bloqueado** por padrão (sem acesso lateral a T1) | n/a | n/a | **bloqueado** sempre — T3s são isolados entre si e nem sabem da existência uns dos outros |

**Visibilidade de classificação** (`private`/`protected`/`peer`/`downstream`/`public`/`collective`) segue
o mesmo funil: `private` é **imutável** — nem o core lê `private` de outro membro, em nenhuma
circunstância. `public`/`collective` fluem livremente para o core; `protected` só para quem está
em `diary_readable_by`; T3 só enxerga `public` de qualquer origem.

**Verificação, não confiança de leitura:** a máquina de trust não é papel — é script determinístico
(`.claude/validation/trust-topology-check.sh`, `--dry-run`). O mesmo vale para o **pin** de cada
membro (o commit do framework que ele diz ter): `pin-integrity-check.sh` verifica um canário
vendorizado contra o pin declarado antes de qualquer `--update` confiar nele. O incidente que
motivou isso (pin forjado por restore manual, 2026-06-30) está registrado como memória de família
"declarado≠verificado". Desde 2026-07-21 o check ganhou modo **`--audit-vendor`**, que varre os pins
*vendorizados* no adotante contra o commit real do core — e já achou (2026-07-24) instâncias da classe
**`vnextpin`** (um pin que não prova ser commit): de um *placeholder* literal a uma **data** gravada
onde deveria haver um SHA auditável — inclusive no vendor de um hub. O
stamp local reporta `pin-ok`, mas o pin não resolve a commit — passivo **ainda ativo**, fix é
adopter-side.

### 3.2 A fronteira comercial dos tiers (reframe ratificado 2026-07-19)

A separação entre tiers deixou de ser "completude do produto" e passou a ser **acesso à federação**
(pesquisa `onion-tier-matrix-2026-07`, decisão em `docs/business-context/decisions.md`, codificada em
`roles.yaml` via PR #443):

- **standalone (T3) = framework COMPLETO, grátis, para sempre, SEM federação.** As 3 dimensões peer
  (produto/engenharia/compliance) + todas as ferramentas de trabalho (KG soberano, diário,
  orquestração). É deliberadamente **MOAT / advocacy / dogfood-de-campo**, não funil de receita
  (solo não sustenta volume). Em business-context, "standalone" também virou um **degrau de funil**
  (D7, `45f9e90`) — uma camada de significado comercial sobre o tier técnico.
- **hub (T1) = adoção de EMPRESA:** tudo do standalone + **federação** (sync multi-repo, bundles
  role-scoped por squad, autoridade de sub-adoção, `members.yaml`/console) + serviço
  (treino/consultoria/certificação). É o **upsell/moat** inimitável. O gatilho de promoção
  standalone→hub é **sinal social** (a chegada do "multi": 2º repo / 2ª pessoa), não crescimento de
  uso individual.
- **consumer (T2)** onboarda **via core** (core-driven: o maestro roda `/meta:adopt` do core e
  registra `parent: <hub-id>`; o hub não roda adopt). Doutrina fechada, **nenhum T2 real existe hoje**.

`members.yaml` hoje (medido 2026-08-13): **1 source + 1 hub + 10 standalone** = **12 membros**, dos quais **8 são adotantes** (`kind: adopter`) e 0 consumer. ⚠️ `role` e `kind` respondem perguntas DIFERENTES: `role` é a topologia (quem adota quem), `kind` é a natureza da adoção (quem vendoriza para trabalhar). Contar adotante por `role` infla — `distillation`, `door` e `method` são `standalone` e NÃO são adotantes. **Derive, não copie**: `grep -c '^ *kind: adopter' docs/evolution/federation/members.yaml` (régua D8).

### 3.3 Identidade emergente — `/meta:personality-sync` (RFC-0003 F2, shipou 2026-07-24)

O `personality_summary` de um membro deixou de ser só um seed manual. O comando
**`/meta:personality-sync`** (F2, commit `d7807bf`) **gera** `.claude/identity/personality.md` a partir
do diário + `.onion-version` + primeiros commits — é uma **projeção A2A-card one-way**, não fonte de
verdade (o diário continua sendo a autobiografia; a personality é uma leitura dele). Estado hoje: dos
12 membros, **1 (o core) já é emergente** — ancorado em 74 migalhas do diário; os demais adotantes seguem
`seed manual datado`; `marcio-pessoal` é `n/a` por design (soberania do dado, nada sobe proativamente).

### 3.4 Saúde de verificação — o overlay de auditoria da federação

A estrutura da federação (quem-adota-quem, tier, trust, pin) **já é grafo**: `graph.sh --triples` emite
triplas do `members.yaml`. Por cima disso roda um **overlay AUDIT de saúde-de-verificação** — não um
domain-layer forçado — via **`federation-radar.sh`** (shipou 2026-07-18, `ff6c22a`; deixou de ser
design-target e virou mecanismo vivo). Consolida 4 checks num veredito único:

1. pin **declarado ≠ verificado**;
2. anúncio em staging **não-transportado**;
3. hub **sem sub-adotado**;
4. linhagem **sem pin**.

O grafo `federation-health-2026-07.kg.yaml` sai limpo em 2026-07-24 (16 nós / 16 arestas, sem
contradição estrutural).

## 4. O processo de adoção, passo a passo

Fonte: `/meta:adopt` (única via de entrada na federação —
"NÃO é CLI standalone", roda dentro de uma sessão Claude Code que já é a fonte).

### 4.1 Contrato de Segurança (antes de qualquer fase)
1. **Dry-run primeiro** — todo `diff` é mostrado antes de qualquer escrita.
2. **Branch dedicada** (`onion/adopt`) — nunca a branch default sem consentimento.
3. **Never-clobber implementado** — extrai para tmp, faz `diff` contra o alvo, só aplica após revisão;
   customização local do alvo aparece no diff em vez de ser sobrescrita. O mecanismo de `--update` é
   **vendor-branch 3-way merge** (`onion/vendor` ramificada, nunca órfã): customização local vira
   conflito git real, não é clobbed em silêncio — verificado em campo (392 arquivos, 7/7 asserts)
   desde 2026-07-09, com hardening contínuo (o commit mais recente, `1dc8c02`, ainda em 07-24, corrige
   um caso do selftest onion-version-tracked).
4. **Idempotente** — re-adotar/atualizar aplica o delta, nunca duplica.

### 4.2 As fases
| Fase | O que faz |
|---|---|
| **PASSO 0** | Captura a identidade da fonte (`onion-version.sh`) **antes de qualquer cd/cópia**; resolve o alvo (path ou clone); detecta o modo (greenfield/legacy/regulated). |
| **Fase 1 — Engenharia reversa** | Pulada em greenfield. Em legacy/regulated, roda `/docs:reverse-consolidate` para alimentar o `technical-context` do alvo. |
| **Fase 2 — Instalar** | Cria a branch/worktree `onion/adopt`; aplica o Procedimento de cópia segura (manifesto filtrado → `git archive` → tmp → diff → `cp`). |
| **Fase 3 — Scaffold** | Cria `docs/{business,technical,compliance}-context/` vazios (governança **do alvo**, L1+); gera `CLAUDE.md` (never-clobber → `CLAUDE.onion.md` se já existir); registra hooks no `settings.json` (merge); cria o starter `docs/evolution/{inbox,inbound}/`; **gera `docs/onion/inventory.md` do alvo** — gap real descoberto no dogfood de um adotante (greenfield): o próprio hook recém-instalado bloqueava o 1º commit sem isso. |
| **Fase 4 — Integrações (`.env`)** | Roda **dentro do alvo** (não da fonte) — `/meta:setup-integration`. |
| **Fase 5 — Carimbar** | Escreve `.claude/.onion-version` no alvo com a identidade **da fonte capturada no PASSO 0** (nunca re-derivada do alvo). |
| **Fase 6 — Relatório** | Auto-emite um relatório em `docs/evolution/inbound/` do alvo (nunca no `inbox/` dele — canais têm direção); oferece registrar o alvo em `members.yaml`. |

### 4.3 Dois eixos ortogonais: cenário e forma de adoção

**Eixo A — cenário do alvo no momento da adoção** (os "três modos"):

| Modo | O que muda |
|---|---|
| **greenfield** | scaffold + instalação direta; engenharia reversa mínima |
| **legacy** | engenharia reversa obrigatória; instala em **worktree** (isola do código legado); `CLAUDE.md` nunca sobrescreve o existente |
| **regulated** | tudo do legacy **+** `compliance-context` populado via `/docs:build-compliance-docs` + agentes de compliance (ISO 27001/22301/SOC2/PMBOK) já no manifesto |

**Eixo B — forma de adoção** (dimensão ortogonal nomeada pelo adendo RFC-0005 §4.1, 2026-07-10):
**full** (vendoriza o framework, é membro durável), **docs-only** (só a camada de doutrina/docs) e
**in-place** (inspeção/operação efêmera, **fora da federação por construção** — não instala, não
carimba, não entra em `members.yaml`). Um 4º modo de proveniência — **capability-update fora-do-git**
para o caso docs-only — está **desenhado, mas gated**: abre no 1º `--update` docs-only real do time
hub (ainda não disparado).

RFC-0005 Fase 2 (shipou 2026-07-10) entregou o maquinário de **herança de escopo**: `compose-settings.sh`
+ `resolve-scope-layers.sh` + `--show-scope` (texto/JSON) — merge N-camadas de `settings.json` com
proveniência, cavalgando a convenção subdiretório-por-time em vez de reinventá-la.

### 4.4 A catraca — baseline que só encolhe (dois gates novos, 2026-07-23)

Dois gates de verificação shiparam com **doutrina de catraca** (a baseline só pode encolher; crescer é
regressão, também HARD):

- **REGRA 29** (`kg-provenance-coverage.sh`) — proveniência invertida: documento novo em
  `docs/analysis/` ou `docs/evolution/research/` **sem citação em nenhum `.kg.yaml`** falha HARD.
- **REGRA 42** (`doctrine-freshness.sh`) — TTL de 90 dias em afirmações world-facing **sem
  `verified_at`**.

O passivo existente é tolerado via baseline versionado (SOFT). **Ação obrigatória para adotantes no
próximo `--update`:** semear os dois arquivos de baseline **antes** do próximo commit — senão ambos
degradam fail-closed.

### 4.5 A Condução — projetar movimentos da topologia a partir do KG (2026-07-23)

Por cima da topologia de repos nasceu a **Condução**: uma **tríade** de skills —
**onion-wizard** (ajuda a **FAZER** um movimento), **onion-onboarding** (ajuda a **CONHECER**) e o
scaffold (**GERA**) — que **projetam de uma SSOT-topologia única no Knowledge Graph**, guardada pela
**REGRA 41** (que barra drift). Trocar a topologia no KG basta; as skills projetam por leitura, sem
hard-code. As **3 transições** da topologia — convite-colaborador, transferência-ownership e
fonte-desacoplada — saíram de `status: open` (gated) para **ATIVAS/implementadas em código**
(`d48ffef`).

Efeito prático: **empresa adota os próprios projetos** como movimento **local/não-gated**
(`write-stamp.sh --role hub` / `/meta:adopt --promote-hub` promovem um repo a hub sem passar pelo
core). Só a federação **cross-empresa** segue gated.

### 4.6 A operação viva — o doc-bridge leve (`co-*`)

Os canais `inbox/`/`inbound/` são movidos por comandos-carteiro. Papéis inalterados desde 07-06, mas
amadurecidos operacionalmente:

- **`/meta:co-evolve`** (orienta a sessão: detecta papel via stamp, lê inbox+inbound, propõe rascunho
  responder-gated). Ganhou **Passo 2.0** (git fetch/pull **antes** de ler o inbox — sincronizar antes
  de ler, não só antes de escrever) e **Passo 2.1** (reconciliação `outbox × inbound` via `comm -13`,
  para adotante na mesma máquina, mecanizado 2026-07-23, commit `8451a39`) — nascido do sinal de campo
  `carteiro-cego` (2026-07-21): a entrega-sem-commit escolhe **um** checkout, e num adotante
  multi-máquina o carteiro pode ter acertado o checkout errado (falha silenciosa, nenhum gate dispara
  sozinho). Provou valor no menor intervalo possível: **menos de 24h** depois de mecanizado, o mesmo
  `comm -13` caçou **5 anúncios reais** (07-09/07-16) marcados transportados no core mas **ausentes do
  inbound do checkout que trabalha** — recuperados por re-entrega never-clobber (diário
  `2026-07-24-reconciliation-catches-real-loss-next-day`).
- **`/meta:co-announce`** (producer downstream, escreve na staging `federation/outbox/<id>/`). Ganhou
  modo **`--reconcile`** (concilia **todo** o backlog do CHANGELOG contra a outbox — revela o open-set
  de anúncios nunca transportados) e **seletor fino** `alvo: key:value` (mode/tier/specialization).
- **`/meta:co-deliver`** e **`/meta:co-relay`** (carteiros-locais, entrega-sem-commit): inalterados em
  desenho; `co-deliver` agora só aceita membro `hub` ou `standalone` (T2/consumer fica fora do
  carteiro-local, por design).

**Invariante I3** (um escritor por repo — o core nunca commita no repo alheio) e o **gate humano no
Ato 3** (propor→confirmar, W6) seguem intocados — nenhuma regressão.

## 5. O que cada perfil leva do core (e o que nunca leva)

Manifesto real copiado pela Fase 2 (`want=()` do Procedimento de cópia segura):

```
.claude/{agents,commands,skills,utils,validation,hooks}
docs/{meta-specs,knowledge-base,sdaal}
```

**Nunca vendorizado** (é do alvo, por definição): `docs/{business,technical,compliance}-context/`
(a governança L1+ do domínio dele), `docs/evolution/` (os canais são infraestrutura local — copiá-los
clobaria o inbox/inbound em uso), `.env`/`.env.example` (never-clobber por-arquivo, específico do
projeto), qualquer coisa em `docs/{analysis,materials,applying}` da fonte (nunca sai da árvore
rastreada por `git archive`).

## 6. Casos de uso reais — os perfis hoje registrados

Fonte: `members.yaml` (interno do core — o SSOT versionado dos membros da federação: tiers, pins, trust,
personality) — nenhum número inventado. **Perfis anonimizados para circulação pública.**

### 6.1 Destilação curada — a exceção que define a fronteira
`role: standalone`, mas **`onion_version: n/a`**. Não é adoção — é **destilação curada**: reescreve a
doutrina (master-prompt como bytecode) sem vendorizar `.claude/`. Existe precisamente para marcar
onde "adotar" termina e "destilar/citar" começa — um standalone de verdade sempre tem um
`onion_version` verificável; este não tem porque não é o mesmo contrato.

### 6.2 Adotante greenfield padrão
`role: standalone`, `mode: greenfield`, `onion_version` **verificado** por `pin-integrity-check.sh`
na própria adoção. Organização externa real — o Onion **ajuda**, não é produto do Onion. Ciclo
completo rodado até F1 (vertical educacional).

### 6.3 Adotante hub (T1)
`role: hub`, **multi-linhagem** (`framework` em `develop`, `production` em `<adopter>/main` — cada
linhagem com seu próprio pin verificado). Pin re-verificado desde 07-06 (avançou uma revisão em 07-23,
`pin-ok`). Opera hoje como standalone com potencial de crescer: tem a *capacidade* de ter sub-adotados
(T2), mas nenhum existe ainda — `exposes_downstream: []`. **Passivo vivo:** o `--audit-vendor` achou 1
pin inválido (classe `vnextpin` — um valor que não é um SHA auditável) no `onion/vendor` deste membro — fix adopter-side,
ainda pendente.

### 6.4 Adotante regulado — trust elevado sem role elevado
`role: standalone`, `mode: regulated` (ambiente regulado real). Trust elevado incomum:
`can_correct_to: [onion-evolve]` — concedido não por hierarquia, mas por rigor comprovado: a mesma
falha de lint (`|| return` sem argumento, abortando sob `set -e`) foi achada e corrigida
independentemente lá **e** no core, no mesmo dia, com poucas horas de diferença, zero comunicação
entre as partes — descoberta convergente verificada via `git blame`. Pin re-verificado desde 07-06
(avançou uma revisão em 07-23) **+ vendor-audit 5/0 limpo** (5 pins válidos, 0 inválidos) — o que
reconciliou o nó de *pin-untrusted* que o grafo de saúde carregava como stale. Ilustra a doutrina
[fonte≠derivação](source-vs-derivation.md) na prática: a pergunta "um adotante regulado deve ter seu
próprio `source`?" foi respondida **não** — existe uma só fonte; o que o ambiente regulado precisa
(controle deliberado de quando puxar updates) já é resolvido pelo `integration_branch: develop`
explícito, sem duplicar autoridade.

### 6.5 O próprio core — também multi-linhagem
`role: source`, T0. Sem bloco `trust:` (lê tudo por papel, não por concessão). Seu
`personality_summary` é hoje **emergente** (`/meta:personality-sync`, 74 migalhas do diário), não mais
seed manual. Vive num lar consolidado (a KVM 8), que serve dev + site + o `onion-bridge` (o host do
endpoint `a2a-live`) — o clone do bridge é dedicado, isolado do checkout do maestro.

### 6.6 Adotante de campo greenfield (dogfood real)
`role: standalone`, `mode: greenfield`. A sessão dele **achou + corrigiu o bug #303 do core** —
descoberta convergente que validou o adopt durável, ancorado corretamente na fonte viva
(`onion-evolve`), não preso a um fork de incubação. Registrado tarde (o stamp existia, o membro
faltava em `members.yaml`: drift de registro regularizado em 07-19).

### 6.7 A porta pública Claude — `onion-standalone`
`role: standalone`, mas é **porta de framework**, não projeto-adotante: distribui o **bundle
standalone** (eng/product/testing/docs), **sem meta-factory nem memória privada de evolução**. Nasceu
2026-07-19 via `/meta:adopt` **role-scoped**, com pin verificado — a 1ª peça que desfaz o colapso
"porta ≡ core" ([public-door-vs-private-core.md](public-door-vs-private-core.md)). Nasceu privada e **flipou PÚBLICA em 2026-07-19** (`onion-standalone` é público — verificado ao vivo).
Resta **gated** só **reapontar o redirect** `onion-claude → onion-standalone`: o `onion-claude` segue
**privado** (descrição ainda da era Cursor), então quem chega por ele ainda não cai na porta pública.
(Nota: qualquer linha de rampa que ainda liste o *flip público* como gated está **stale** — o flip
aconteceu; só o **repoint do redirect** segue.)

### 6.8 O braço de pesquisa — método, não vendor
`role: standalone`, `onion_version: n/a` — adota o **MÉTODO** (KG SDAAL: `kg-radar` + `/meta:kg` +
SDAAL destilado), **não vendoriza `.claude/`**. É o dogfood do método num cérebro de vida N=1 do
próprio criador — **prova o método, não o mercado** (o `Q_COLD_ADOPTER` segue aberto). Trust
**soberano/zerado**: `diary_readable_by: []` e `diary_classifications_shared: []` — nem o core lê o
diário, sem privilégio de criador. O KG bruto é privado e local-first; só destilado gated sai.

## 7. Federação formal por contrato (capacidade latente — ainda não graduada)

Fonte: [`multi-repo-federation.md`](multi-repo-federation.md) completa.
Resolve um problema **diferente** do §2-§6: não "quem é membro", mas "esta integração específica X
entre o repo A e o repo B pode mudar sem quebrar o B".

- **Unidade:** um contrato em `contracts/<id>.md` num ledger git dedicado, com 8 seções obrigatórias
  — `id`, `version` (semver), `producer`, `consumers`, `interface`, `types`, e as duas que fecham o
  gate de verdade: **`tests`** (≥1 path de contract-test — sem teste é blocker) e **`fixtures`**
  (≥1 payload real — o que transforma "promessa sintática" em "gate comportamental").
- **Ciclo:** `/meta:federation-register` (valida+grava o contrato, sem anunciar) →
  `/meta:federation-publish` (único escritor do CHANGELOG/inbox — anuncia com checkpoint do maestro)
  → `/meta:federation-check` em cada consumer (veto de 1ª mão: `approved:false` ou saída ausente
  **bloqueia**, fail-safe) → `/meta:federation-status` (drift + CI, veredito SÃO/ATENÇÃO) → PRs
  coordenados pelo maestro (producer primeiro, consumers depois) → se quebrar,
  `/meta:federation-rollback` guia a reversão na ordem inversa.
- **Por que ainda não graduou:** o gatilho é "contrato que pode quebrar consumers **OU** 3-5+
  adotantes" — hoje há 1 adotante real de peso (os adotantes ainda não trocam contratos
  entre si) e 0 contratos registrados. O MVP mecânico existe e foi validado num ledger scratch;
  falta o ledger de produção com remote+concorrência real. Graduar antes disso seria especulação —
  o doc-bridge leve (§2-§6) já resolve o que existe hoje.

## Referências
- [multi-repo-federation.md](multi-repo-federation.md) — formato de contrato + ciclo da federação formal
- [federation-usage-modes.md](federation-usage-modes.md) — a matriz canônica dos 5 eixos (cenário/controle/tier/operação/topologia) + gatilhos de graduação
- [source-vs-derivation.md](source-vs-derivation.md) — a doutrina que rege como este próprio documento deve se comportar
- [public-door-vs-private-core.md](public-door-vs-private-core.md) — o litmus porta pública ≠ core privado (§6.7)
- `/meta:adopt` — o comando fonte de toda a §4
- `/meta:co-evolve` — o orientador do doc-bridge leve (§4.6)
- `members.yaml` (interno do core) — os perfis reais da §6 (uso interno)
