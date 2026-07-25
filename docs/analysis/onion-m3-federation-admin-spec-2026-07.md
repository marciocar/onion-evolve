---
title: "SPEC/PRD M3 — plataforma admin da federação Onion (command-side + auth) — ESPECIFICAR, build gated"
category: meta
tags: [federacao, admin-platform, command-side, cqrs, logto, sdaal, members-yaml, d6, spec-as-code, gated]
status: spec (build gated no gatilho objetivo)
date: 2026-07-25
deciders: maestro (Marcio)
context_freshness: 2026-07-25
kg: docs/onion/graph/m3-federation-admin-2026-07.kg.yaml
---

# SPEC/PRD M3 — Plataforma admin da federação Onion

> **Postura deste documento:** ESPECIFICAR, não construir. O build permanece **gated** atrás de um
> gatilho objetivo (§2). O que existe hoje — read-model completo servindo **um** operador (o maestro) —
> **basta** ao estado atual da federação (8 membros, 0 consumer real, 0 contrato registrado). Este spec
> desenha a **fronteira doutrinária** do *command-side* e do modelo de *auth* para o dia em que o gatilho
> disparar, sem pré-cozinhar a construção (anti-padrão `gated-work-derives-fresh`). **Toda referência a
> tecnologia/protocolo/layout de arquivo é ILUSTRATIVA — não comprometida** (§4).

---

## 1. Sumário — o que é / o que NÃO é

**O que É:** o desenho do **lado de comando (command-side)** da federação — as operações que **mutam** a
SSOT (`members.yaml`) e a **fronteira** de autenticação para quando houver mais de um operador humano. Hoje a
federação tem um **read-model** (query-side) maduro e um único **gate de escrita determinístico**
(`trust-topology-check.sh`, que grava só *log de decisão*, não o registro). Nenhuma mutação do registro
tem comando dedicado: registrar/promover/atualizar/revogar membro é **edição manual de YAML + commit**,
com os scripts de saúde rodando **depois** (advisory ou gate em superfície derivada).

**O que NÃO é:**

- **Não é uma plataforma tipo Backstage/Port.** A fronteira "NÃO é plataforma" já está fisicamente amarrada
  ao artefato (`federation-console.sh:6-9`) e travada por REGRA 24/REGRA 38. Backstage/Port custam 3+
  engenheiros dedicados + ~US$450k/ano e só compensam a 200–1000+ devs (S3·F1). Para N=8 é over-engineering.
- **Não é multi-ambiente / on-prem / multi-IDE.** A identidade **Claude Code-only** é ratificada
  (CLAUDE.md:9, D-identidade). Nada aqui reabre isso.
- **Não é multi-tenant SaaS cross-cliente.** A arquitetura de dado ratificada é **local-first + destilado**
  (D2): contexto bruto fica soberano/local, só predicado destilado sobe. "Multi-tenant" aqui significa
  **uma empresa, N squads/repos** — nunca federação de mercado entre empresas.
- **Não promete L1–L6.** Classificação-por-inferência, gate-por-propósito e ε-ledger são **gated** (D2).
  Nenhuma feature/copy deste spec pode citá-los como disponíveis (guardrail `declarado≠verificado`).

---

## 2. Postura: SPEC-agora / BUILD-gated — o gatilho objetivo

O console read-only atual (F1.3) serve **um** operador (o maestro) olhando **todos** os 8 membros com
paridade. Enquanto essa premissa vale, "projeção read-only para 1 pessoa" **basta** — não há hub-owner
autônomo que precise de visão/ação escopada, então uma "admin platform" com RBAC/multi-operador **não tem
consumidor**.

### Gatilho objetivo do build (o que liga a construção)

> **O build da plataforma admin liga quando ocorrer o primeiro de:**
>
> **(a)** o **1º membro `role: consumer` (T2) REAL** aparecer em `members.yaml` — porque T2 introduz um
> **hub-owner** que precisa de uma visão/ação **escopada ao próprio subgrafo** (seus T2s), quebrando a
> premissa "maestro-único vê tudo"; **OU**
>
> **(b)** o **1º contrato *breaking*** for registrado em `docs/evolution/federation/contracts/` — o gatilho
> de graduação da Federação formal já escrito em `docs/evolution/README.md:131-138` (contrato que pode
> quebrar consumidores, ou coordination-tax de N projetos começando a doer a ~15–30%).

**Estado atual do gate: FECHADO.** `members.yaml` tem 8 membros (1 source, 1 hub, 6 standalone, **0
consumer**); o diretório `contracts/` **ainda não existe** — ele nasce no **1º registro** via
`/meta:federation-register` (os 4 comandos `/meta:federation-register|publish|check|rollback` já estão
implementados e testados, mas nenhum contrato foi registrado). `role: consumer` só existe no
comentário-template (linha ~270), nunca instanciado.

**Por que nomear T2 no schema é barato, mas construir a superfície não:** o vocabulário/schema (RFC-0003
já desenha T2/consumer) é **dado** — barato, correto de ter. O que a fronteira Elenxo impede é a
**construção de superfície write/multi-operador** antes do 1º T2 real ou do 1º contrato breaking. Nomear ≠
construir.

---

## 3. Command-side sobre o read-model existente

O padrão CQRS já é doutrina no repo (read-side = projeção read-only sobre event-store append-only). O
command-side é o complemento: **cada mutação da SSOT passa a ter um comando dedicado que valida antes de
gravar** — em vez de edição manual + scripts de saúde rodando depois. **Cada operação abaixo se apoia em
artefato/script que JÁ existe.**

### Modelo de execução das OP-1..4: comando Onion NATIVO, zero backend

> **Invariante de execução (reconcilia §3↔§4):** o command-side das OP-1..4 é **nativo do Claude Code** —
> **edita `members.yaml` + faz commit git**, exatamente como o resto do framework (spec-as-code, git como
> event store). **Zero backend, zero serviço persistente, zero OIDC.** Isso serve o **operador-único de
> hoje** (o maestro) e é o que basta ao estado atual da federação. Auth/backend **NÃO é pré-requisito das
> OP-1..4** — só entra no **gatilho multi-operador** (1º `role: consumer`/T2 real, §4). Reintroduzir um
> serviço persistente antes disso tensiona o "zero backend" ratificado (`federation-console.sh:8`).

### Read-model existente (reusado, não redesenhado)

| Artefato | Papel | Traço |
|---|---|---|
| `members.yaml` | SSOT policy-as-data (schema por membro + matriz de trust) | `docs/evolution/federation/members.yaml:9-289` |
| `CHANGELOG.md` | event-log append-only (anúncios do core) | `docs/evolution/federation/CHANGELOG.md:1-9` |
| `federation-console.sh` → `.html` | projeção read-only (CQRS leve, zero backend/DB) | `.claude/validation/federation-console.sh` |
| `federation-radar.sh` | 3 checks advisory (pin drift, staging não-transportado, hub sem sub) | `.claude/validation/federation-radar.sh` |
| `pin-integrity-check.sh` | **gate real** de confiabilidade do pin | `.claude/validation/pin-integrity-check.sh` |
| `projection-safety.sh` | REGRA 30 — gate HARD anti-vazamento de confidencial | `.claude/validation/projection-safety.sh` |
| `trust-topology-check.sh` | **única escrita determinística** (append em `trust-log.md`) | `.claude/validation/trust-topology-check.sh` |
| `/meta:adopt` | único command-side que toca federação (para no registro) | `.claude/commands/meta/adopt.md:545` |

### As 4 operações de mutação (cada uma sobre o que já existe)

Todas rodam **nativas** (editam `members.yaml` + commit — sem backend, §3):

**OP-1 — REGISTRAR membro (create).** Escrever a entrada no ledger seguindo o **template comentado**
(`members.yaml:267-288`), reusando o pin já **VERIFICADO** por `pin-integrity-check.sh`. Hoje `/meta:adopt`
faz toda a adoção técnica (clona/vendoriza/carimba `.claude/.onion-version`) mas **para no passo final,
apenas sugerindo** o registro (`adopt.md:545`). *Fecha o gap:* o comando escreve a entrada em vez de sugerir.

**OP-2 — PROMOVER (mudar `role:`, ex. standalone→hub, consumer→T2).** Atualizar o campo `role:` no
`members.yaml` **do core**. Hoje `--promote-hub` só re-carimba o **stamp local do adotante**;
`federation-radar ③` detecta *pós-hoc* um hub sem sub-adotado (drift entre role declarado e topologia
real) mas **não previne nem corrige** — é só alarme. *Fecha o gap:* o comando escreve o `role:` novo,
matando o drift na origem.

**OP-3 — ATUALIZAR (pin / trust / specializations / personality_summary).** Escrever o `onion_version:`
novo **após** `pin-integrity-check.sh` confiar nele, e **editar** a matriz de trust
(`can_correct_to`/`can_advise_to`/`can_receive_from`/`exposes_downstream`) que `trust-topology-check.sh`
hoje só **consulta** para autorizar relays — nunca **edita**. Hoje é 100% edição manual, anotada em
comentário ("VERIFICADO por pin-integrity-check.sh"). *Fecha o gap:* o comando persiste a verificação já
feita.

**OP-4 — REVOGAR / DESATIVAR (ex. `status: retired`, remover linhagem obsoleta).** Nenhum script/comando
existe; o padrão observado no próprio arquivo é anotar `status: retired` à mão e/ou remover blocos de
`lineages` via edição direta, documentando o porquê em comentário inline. Nenhuma das 5 checagens de saúde
tem comando companheiro de revogação. *Fecha o gap:* comando dedicado que efetua a desativação e sela o
motivo.

### Requisitos transversais do command-side

- **Validador de `members.yaml`** (hoje inexistente): um JSON Schema / validador determinístico que barre
  membro mal-formado **antes** do commit — hoje só há `yaml.safe_load` tolerante (`try/except` silencioso)
  e `awk` frouxo que falha em silêncio (bug FED-2-0). Pré-requisito de qualquer OP acima.
- **Validador de entrada do `CHANGELOG`** (`alvo:` / `compat:`) **antes** do append — hoje o formato é
  reconstruído por regex **na leitura** do console, não validado na escrita.
- **Enforcement da REGRA 30 no ponto de escrita** — `projection-safety.sh` protege superfícies derivadas;
  o command-side deve invocá-lo **antes** de qualquer mutação que possa expor nome comercial/confidencial.

---

## 4. Modelo de auth — a FRONTEIRA (commodity-BUY × diferencial-BUILD)

> **Escopo desta seção:** só a **fronteira doutrinária**. O *build* de auth é **gated** e **não** se
> pré-cozinha aqui (`gated-work-derives-fresh`): protocolo, tipo de client, backend, layout de arquivo e
> nomes de operação são **ILUSTRATIVOS, não comprometidos** — a construção se re-deriva fresca contra o
> vivo no dia do gatilho. O que **fica comprometido** é §4.3 (o que se compra × o que se constrói) e a
> **invariância** `Logto Orgs = PROJEÇÃO, members.yaml = SSOT`.

**Estado atual (verificado):** Logto self-hosted **1.41.0** vivo em `auth.onionevolve.com` (OIDC público),
MFA/passkeys disponíveis. O único consumidor de auth hoje é o **bridge**, que usa `AUTH_TOKEN` próprio,
**não Logto**. Nenhum admin-platform existe. Isto é design **prospectivo/gated**, não descrição de algo
construído — a decisão "plugar o bridge/command-side no Logto" segue **não tomada** e este spec **não a toma**.

### 4.1 Quando auth entra — e quando NÃO entra

O read-side (console/`federation-status`) já é público e read-only — **sem login**, e assim permanece. As
**OP-1..4 do command-side rodam nativas para o operador-único de hoje** (editam `members.yaml` + commit,
sem auth backend — §3). **Auth real só se torna necessária no gatilho multi-operador:** quando surgir o 1º
`role: consumer` (T2) real, aparece um segundo humano (hub-owner) que muta um subgrafo — aí, e só aí,
"quem é você / o que você pode mutar" precisa de identidade verificada. **Qualquer backend/servidor de auth
pertence a esse gatilho, não às OP-1..4.**

*(ILUSTRATIVO, não comprometido — a re-derivar no gatilho):* um caminho plausível quando o multi-operador
chegar seria OIDC contra o Logto já vivo, com MFA/passkeys exigidos ao menos na identidade `source` (a
superfície de maior privilégio). **Protocolo/tipo-de-client/backend concretos NÃO são decididos aqui.**

### 4.2 RBAC → topologia (Organization Logto ↔ tier Onion) — ILUSTRATIVO

*Mapa ilustrativo (não comprometido) de como um RBAC futuro se ancoraria na topologia já ratificada (D7).
As âncoras de tier vivem em `members.yaml` e em `.claude/utils/marketplace/roles.yaml`:*

| Tier Onion | Mapeamento Logto (ilustrativo) | Ancoragem |
|---|---|---|
| **source** (T0, `onion-evolve`) | papel global fora de org, ou M2M via Management API | `members.yaml:12` "lê tudo; escreve só em si" |
| **hub** (T1, ex. metagamify) | 1 Organization por hub, papel de org = admin, escopo = só a própria org | `.claude/utils/marketplace/roles.yaml:63-65` (Camada 2: controle local dos próprios projetos) |
| **consumer** (T2) | Organization Role `member` dentro da org do seu hub-pai | **modelo** — 0 instância real hoje (`.claude/utils/marketplace/roles.yaml:75-78`, `work_tools: tbd`) |
| **standalone** (T3) | **SEM organização nenhuma** — a fronteira de org no Logto É a fronteira de federação do D7 | `decisions.md:29` (D7: standalone = dev solo, sem federação) |
| **distilled** | fora de qualquer identidade Logto | `.claude/utils/marketplace/roles.yaml:81-84` (`work_tools: none`) |

### 4.3 Fronteira: commodity-BUY (Logto) × diferencial-BUILD (Onion) — COMPROMETIDO

**Comprar (undifferentiated, Logto):** emissão de identidade, sessão/token, MFA/passkeys, recuperação de
senha, CRUD de Organization + atribuição de papel primitivo, Secret Vault.

**Construir (diferencial Onion, nunca delegável ao Logto):**

1. **A tradução do papel grosso de Organization → semântica de tier (D7) + matriz de confiança fina de
   `members.yaml`.** O RBAC do Logto (admin/member por org) só responde "que org, que papel grosso" — **não**
   expressa `can_receive_from`/`can_advise_to`/`can_correct_to`/`diary_readable_by`/`exposes_downstream`.
   Essa autorização fica **enforced no control-plane Onion**, lendo `members.yaml` como dado de autorização
   *depois* que o OIDC resolve identidade+org+papel. Reconstruí-la dentro do Logto **duplicaria a SSOT**.
2. **O ledger de contratos + CHANGELOG event-store + veto fail-safe** — já existe, git-nativo, e continua
   sendo a SSOT de domínio. **Invariância comprometida:** Logto Organizations é tratado como
   **PROJEÇÃO/espelho** da topologia hub definida em `members.yaml` (sincronização futura, gated, **nunca o
   inverso**) — preserva "control plane = single source of truth, um único escritor". **`members.yaml` é a
   SSOT; Logto Orgs, se algum dia sincronizado, é só projeção.**

### 4.4 Forma de integração (ILUSTRATIVO, não comprometido)

*Se/quando o build de auth ligar, o padrão idiomático seria uma 3ª instância SDAAL (irmã de task-manager e
forge) — mesma disciplina de factory/interface/adapter + `AUTH_PROVIDER` no `.env`, e **nenhum
comando/agente chamando o SDK do Logto direto** (integrations.md:299). Layout de arquivos, nomes de operação
e variáveis concretas **NÃO são fixados aqui** — re-derivar fresco no gatilho.*

### 4.5 Limite operacional a registrar (decisão futura do maestro)

Logto OSS self-hosted permite **só UMA conta de administrador no console** (gestão de apps/orgs). Isso é
sobre o **console do próprio Logto**, não sobre um eventual fluxo OIDC do admin-platform. Se o tier `source`
precisar de **múltiplos operadores humanos** gerindo Organizations direto no console, esbarra nesse teto —
exigindo Logto Cloud ou operar **toda** gestão de org via Management API a partir do control-plane Onion.
**Fora do escopo deste spec** — nota para o dia da decisão.

---

## 5. Requisitos por comprador (D6) — requisitos-HIPÓTESE

> **Aviso de status (declarado≠verificado):** **P3 e P4 são ambas `[hipótese]` não-provada** (0 adotante
> P3/P4 validado — o próprio §8 elege isto como risco-mãe). Portanto **nenhum item abaixo é MUST de
> construção**: são **requisitos-hipótese**, condicionais à **validação da persona**. A régua usada:
> `SHOULD (condicional: quando a persona for validada)` para o que serviria do que já existe; `GATED` para
> o que depende de mecanismo não-construído.

D6 está cindida: **MENSAGEM/posicionamento = P4** (regulado/enterprise, whitespace compliance-peer);
**PIPELINE/receita = P3** (empresa/sistemas internos, mais líquido). Guardrail duro: a mensagem P4 vai ao
ar **sem prometer o mecanismo L1–L6** (gated).

### P4 (regulado/enterprise) — evidência e trilha acima de velocidade

- **SHOULD (condicional: P4 validada)** — Trilha de auditoria **legível/exportável** das sessões e fases
  executadas (quem/quando/o quê), derivada de `.claude/sessions/` que **já existe**.
- **SHOULD (condicional: P4 validada)** — Visibilidade do resultado do **gate mecânico**
  (lint/selftest/inventory) por execução, não só local.
- **SHOULD (condicional)** — Export/relatório do histórico de decisões (`decisions.md`-like) por
  projeto/tenant.
- **GATED** — Qualquer prova de isolamento/classificação de dado por sensibilidade (L1–L6 / D2).
- **GATED (tensão M3, não-resolvida)** — On-prem / execução fora do Claude Code. O comprador regulado
  costuma exigir multi-ambiente/on-prem/auditoria de terceiros, o que **tensiona a identidade Claude
  Code-only ratificada**. **Direção do spec:** servir a auditoria de P4 a partir de artefatos que **já
  existem dentro do Claude Code** (sessions/git/CI) — **não** infra on-prem nova. Citar a tensão como
  **aberta**, jamais como requisito a construir.

### P3 (empresa/sistemas internos) — consistência e escala entre squads

- **SHOULD (condicional: P3 validada)** — **Self-service de onboarding multi-squad** (endereça a dor "cada
  dev usa IA de um jeito; nenhuma trilha; contexto não escala"). O hub já é "federação como camada de time"
  (D7) — a plataforma admin seria a superfície natural desse onboarding.
- **SHOULD (condicional)** — Visão **agregada** de adoção/consistência entre N repos/times **da mesma
  empresa** (multi-tenant = "uma empresa, N squads", nunca cross-empresa) + métricas de ROI/consistência
  para o comprador org/procurement.
- **GATED** — Qualquer flywheel de dado **cross-tenant/cross-empresa** (é exatamente D2). A plataforma
  agregaria/compararia **só dentro da mesma empresa** — federação de time, não federação de mercado.

### Fora de escopo agora (base textual)

Multi-tenant SaaS cross-cliente com dado compartilhado; qualquer mecanismo L1–L6;
certificação/relicenciamento pós-abertura de dado; suporte a P6/leigo (D3, gated); multi-ambiente/on-prem;
qualquer requisito vindo de feedback **real** de P4 ("zero adotante regulado provado").

---

## 6. O que REUSA da pesquisa federation-2026

A tese central do SYNTHESIS — **não construir plataforma; console/mapa = projeção estática read-only (CQRS
leve) sobre o que já existe** — é o **ponto de partida**, verificada adversarialmente (S3 F1/F3/F5/F8-10)
e reforçada em G2 (registry governado não é o gap do Onion) e G3 (SSOT-central é o ótimo pela natureza CAP
do dado). Divergência maior a registrar: **os "4 candidatos a 1º slice" do SYNTHESIS já foram
construídos** — não são mais trabalho a fazer:

- **mapa derivado** (`graph.sh --map` → `docs/onion/federation-map.md`, Mermaid);
- **seletor fino** `key:value` (`co-announce` via `resolve-target.sh` sobre `graph.sh --triples`);
- **console** (`federation-console.sh` → HTML self-contained, com sanitizador REGRA 30);
- **hook "you have mail"** — **parcial**: existe (`co-evolution-inbox-check.sh`) mas é SessionStart
  pull-based, **não** "acorda a sessão". Este pedaço segue **em aberto** (§7).

**Régua IGUAL→TRANSFERE / DIFERENTE→DESENHA** (a mesma da pesquisa): `members.yaml` **É** o grafo de
entidades do Backstage/Port → reusar; `CHANGELOG` **É** o event store do Event Sourcing/CQRS → reusar;
doc-bridge git-async **É** replicação otimista canônica → reusar. **NÃO** adotar Backstage/Port (over-eng
p/ N pequeno), **NÃO** adotar CRDT/mesh (resolve concorrência multi-escritor inexistente em ledger
single-writer N≈5), **NÃO** promover Grana.Ai a `role: source` (roda como data-plane subordinado).

**Vocabulário barato a alinhar (custo ~zero de schema, G2):** identidade em namespace reverse-DNS por
membro; Agent Card derivado em `/.well-known/agent-card.json` (já parcial via `a2a-agent-card.sh`); pin
documentado como **provenance-de-commit**; tier de trust `verified|community` visível no console. **Checar
no filesystem antes de declarar concluído.**

**Correção que o mercado recomenda:** MCP e A2A padronizam só o **descritor** (discovery), deixando
registry/curadoria/aprovação **"por sua conta"** (A2A não prescreve API de registry curado). Logo: manter
A2A/registry **gated e curado à mão** pelo maestro é o que a própria evidência recomenda para 5 membros —
o spec **não** deve desenhar auto-aprovação/registry automático como "trabalho pendente do admin".

---

## 7. O que fica DORMENTE até o gatilho

Nada de novo precisa nascer agora. A fronteira já está fechada em três pontos **existentes**, revisitáveis
no dia em que `role: consumer` aparecer em `members.yaml` ou o **1º contrato breaking** for registrado
(criando o diretório `contracts/`, que hoje **ainda não existe**):

1. **Guard textual no próprio artefato** — `federation-console.sh:6-9` documenta o que não fazer e por quê,
   com fonte de pesquisa (S3·F1). Não é prosa que descola — é código travado por selftest.
2. **Gatilho objetivo já escrito** — `docs/evolution/README.md:131-138`.
3. **REGRA 24 / REGRA 38** mantendo o artefato atual sincronizado à SSOT para sempre, sem custo
   incremental.

Fios de design/dogfood que **permanecem gated** (não pesquisa — medir/dogfoodar primeiro):

- **Acordar a sessão** via SSE/webhook sem quebrar pull-first/I3 (hoje SessionStart-only).
- **Instrumentar `trust-log`** para acumular histórico **antes** de deixar reputação condicionar o veto
  (G3-A4: "medir primeiro, não ligar automaticamente").
- **Endpoint a2a vivo** na VPS (fundação de segurança de 6 camadas já existe; falta o endpoint) — gated,
  aguardando gate humano + dogfood com adotante regulado.
- **Auth multi-operador** (§4) — só re-derivar fresco quando o 1º T2 real chegar.
- **Cytoscape.js** só entra se o grafo virar objeto de exploração interativa — hoje Mermaid estático é o
  recomendado para N≈5.

**Princípio:** trabalho gated **não se pré-cozinha**; re-derivar fresco contra o vivo quando o gate abre
**É** o ponto. Este spec é o mapa da fronteira, não o pré-plano do build.

---

## 8. Riscos

- **`declarado ≠ verificado` (o risco-mãe).** Nenhuma feature/copy da plataforma pode prometer L1–L6
  (classificação por inferência, gate por propósito, ε-ledger) nem "federação segura de dado regulado" —
  **não construído**, gated (D2). Prometer = queima de moat. A promessa **hoje** = workflows faseados +
  auditabilidade estrutural (existe/dogfoodada). **Corolário:** os requisitos de §5 são **hipótese**
  (0 P3/P4 validado) — por isso são SHOULD-condicional, não MUST.
- **Virar Backstage para N=8.** Construir backend/DB/write-model/portal antes do gatilho é over-engineering
  comprovado por custo (S3·F1) e sem consumidor (operador-único). Mitigação: o gate de §2 + os 3 guards de §7.
- **Duplicar a SSOT no Logto.** Expressar a matriz de trust fina dentro do RBAC do Logto reconstruiria o
  trust model fora de `members.yaml`. Mitigação: Logto Orgs = projeção; autorização fina enforced no
  control-plane (§4.3).
- **Reabrir decisão fechada (Claude Code-only) pela porta P4.** O requisito de auditoria de P4 deve ser
  servido de artefatos que já vivem dentro do Claude Code, nunca por infra on-prem (§5, tensão M3 aberta).
- **Pré-cozinhar o build gated.** Escrever spec de "plataforma admin futura" detalhada demais é o anti-padrão
  `gated-work-derives-fresh`. Mitigação: este documento especifica a **fronteira e o gatilho**, não a
  implementação — todo detalhe de tecnologia/layout em §4 está marcado **ILUSTRATIVO/não-comprometido**.

---

**KG-irmão:** [`docs/onion/graph/m3-federation-admin-2026-07.kg.yaml`](../onion/graph/m3-federation-admin-2026-07.kg.yaml)
— nó central `D_spec_now_build_gated`, gatilho `Q_gatilho`, o command-side DEPENDS_ON os artefatos do
read-model existente.
