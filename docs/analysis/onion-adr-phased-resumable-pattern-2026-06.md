---
title: 'ADR — Padrão Faseado Retomável (PFR) como padrão transversal L0 (PROPOSTO / provisório)'
status: proposto
date: 2026-06-23
deciders: maestro + sessão de evolução
context_freshness: 2026-06-23
related:
  - docs/meta-specs/commands.md §3 (workflows faseados — invariante)
  - docs/meta-specs/architecture.md §8 (critério de promoção a peer)
  - docs/knowledge-base/concepts/worklog-protocol.md (SSOT mecânica)
  - docs/knowledge-base/frameworks/gitflow-patterns.md (contrato de sessão)
  - docs/analysis/onion-strategy-layer-adr-draft-2026-06-17.md (camada de seleção — a reconciliar)
  - docs/design-context/decisions/onion-adr-design-peer-promotion.md (precedente: ADR provisório + gatilho)
---

# ADR — Padrão Faseado Retomável (PFR) como padrão transversal L0

> **Última Atualização:** 2026-06-23 · **Status: PROPOSTO (provisório).** Esta decisão **nomeia** um
> padrão que já existe e governa onde ele mora — **não** crava nova constituição. O PR formal à meta-spec
> (`commands.md §3`) fica **diferido até gatilho** (ver §Gatilho). Espelha o método do
> [ADR design-peer](../design-context/decisions/onion-adr-design-peer-promotion.md): provisório primeiro,
> evidência antes de lei.

## Contexto

Recorrentemente o maestro observa um processo importante do Onion (adoção, federação, geração de
contexto, a própria vertical de design) e pergunta: *"não deveríamos ter um **domínio de wizards** que
padronize esses fluxos guiados?"* — onboarding, adoção, federação, monitoramento, mensagens, geração de
domínios/funcionalidades, padronização de ferramentas, análise.

A investigação (3 exploradores + 1 arquiteto, 2026-06-23) reenquadra o pedido: **esses fluxos já existem
e o padrão sob eles já é invariante** — falta-lhe **nome próprio** e uma porta de entrada para criá-lo
conforme. O risco real não é ausência de fundação; é o padrão ser **folclore citado de N lugares** sem um
termo único, e cada novo fluxo nascer por cópia-à-mão em vez de scaffolding.

### O que já existe (evidência)

1. **O padrão já é INVARIANTE L0.** `docs/meta-specs/commands.md:14` declara *"o conceito **invariante** de
   workflows faseados retomáveis, mecanismo que distingue o Onion de coleções de comandos avulsos"*, e a
   **§3** ("Workflows faseados — INVARIANTE DO FRAMEWORK") já normatiza o conceito (princípio na abertura
   não-numerada, §3.1 workflows canônicos, §3.2 regras, §3.3 identificação).
2. **A mecânica está descrita numa SSOT.** `worklog-protocol.md` cobre, em 9 seções, o `STATE.md` Tier-0
   (§3), o protocolo de leitura escalonado Tier 0→3 (§4), a ordenação prompt-cache-friendly (§5), o
   vocabulário `[DONE]/[ACTIVE]/[TODO]` (§6) e o checkpoint resistente a `/compact` (§7). O **contrato**
   (quais arquivos, ACTIVE vs ARCHIVED) vive em `gitflow-patterns.md §Contrato de Sessão`.
3. **O padrão é usado de fato.** **13 comandos** referenciam `STATE.md` hoje: `meta/adopt`,
   `engineer/{start,work,plan,hotfix,validate-phase-sync,warm-up}`, `design/identity`, `product/task-check`,
   `docs/sync-sessions`, `catch-up`, `onion`, `product/README`. Não é teoria — é o esqueleto operacional.

### O que falta

- **Nome canônico.** O padrão é referenciado por descrição ("workflow faseado retomável") sem um termo
  único, o que dispersa o vocabulário.
- **Porta de entrada executável.** Não há scaffolder: um novo fluxo faseado nasce copiando outro à mão,
  arriscando deriva do contrato.
- **Fronteira com a camada de seleção.** Existe um ADR irmão (abaixo) que trata de *qual* fluxo usar,
  sem que a fronteira entre "selecionar" e "executar" esteja nomeada.

### Validação externa (jun/2026)

O padrão de mercado dominante para sistemas agênticos é *"deterministic backbone + intelligence at
specific steps"*: um esqueleto determinístico de fases onde o modelo é invocado em pontos específicos e o
**controle sempre volta ao backbone**. O PFR do Onion **é** essa forma (`STATE.md` + fases + agentes nos
passos). A camada de scaffolding equivalente (Yeoman, Backstage Software Templates) é o que os
`/meta:create-*` já materializam.

## Decisão

**1. Nomear o padrão: Padrão Faseado Retomável (PFR)** / *Phased Resumable Pattern* — o backbone
determinístico de execução: sessão durável em `.claude/sessions/<slug>/`, `STATE.md` como ponteiro de
resume Tier-0, fases `[DONE]/[ACTIVE]/[TODO]`, checkpoint por fase, resume frio sem transcript.

> Preferir **PFR** a "wizard" no vocabulário L0: "wizard" conota UI guiada passo-a-passo; o que o Onion
> tem é **retomabilidade determinística** através de fronteiras de contexto. "Wizard" permanece como
> apelido coloquial aceitável na skill `onion` e na conversa com o maestro.

**2. PFR é padrão TRANSVERSAL, pertencente ao L0 — não é dimensão peer (L1).** O critério **dono × ritmo
de mudança × decisão distintos** (juntos) de `architecture.md §8` é, na origem, escopado à promoção de uma
**sub-camada a contexto peer** (`*-context/` própria) — não é um critério universal de "o que é dimensão
peer". Adoto-o aqui como **régua por analogia**: a mesma que governou a incubação de `design-context/`
(`architecture.md:120`, `commands.md:116`) e o ADR design-peer. Aplicada ao PFR:

| Critério §8 | PFR | Veredito |
|---|---|---|
| Dono distinto | Todo domínio (produto, eng, compliance, design, meta) **usa** PFR — não há um dono exclusivo | ❌ |
| Ritmo de mudança distinto | O padrão muda com o framework, não em cadência própria | ❌ |
| Decisão distinta que informa | PFR não informa uma decisão de domínio; é **como** se executa qualquer fluxo | ❌ |

Falha nos três. Não há **conteúdo de domínio** para um `wizard-context/` (não há tokens/personas/controles
a guardar — só um *método*). Logo, PFR não é um 5º peer; é da mesma natureza de `commands.md` e
`architecture.md` — **regra que todos os componentes seguem**. Mora no L0.

**3. Localização da formalização (quando cravar):** uma **seção nomeada em `commands.md §3`** (que já trata
do invariante), **não** uma meta-spec `wizards.md` nova — não há matéria que não caiba em `commands.md §3`
+ a KB. A KB `worklog-protocol.md` é a SSOT mecânica e deve **declarar-se** a definição única do PFR (sem
KB irmã que fragmente).

## Reconciliação com o ADR de Camada de Estratégia (o ponto central)

`docs/analysis/onion-strategy-layer-adr-draft-2026-06-17.md` (status `proposed`, aguardando reconciliação
na sala de obra) propõe um **catálogo de playbooks** — *"situação reconhecida → fluxo nomeado → grupo de
ferramentas → sequência"* (recognition-primed decision making) — também como regra L0 acima de
`commands.md`. Seu **Princípio 3** já cita os workflows faseados retomáveis como invariante que preserva o
fio condutor. Há sobreposição aparente; a fronteira correta é de **camadas**:

| Camada | ADR | Pergunta que responde | Natureza |
|---|---|---|---|
| **Seleção** | strategy-layer (catálogo-first) | *Qual* fluxo aplicar a esta situação? | Reconhecimento → playbook (ou deliberar, se não há match) |
| **Execução** | **PFR (este ADR)** | *Como* executar um fluxo de forma retomável e auditável? | Backbone determinístico + agentes nos passos |

**Complementares, não concorrentes:** o catálogo **seleciona**; o playbook escolhido é, na maioria dos
casos não-triviais, **um PFR**. O strategy-ADR deixou em aberto "meta-spec nova vs seção em
`architecture.md`"; este ADR recomenda que **ambos entrem coordenados** numa mesma rodada constitucional
(seleção + execução), evitando duas regras L0 que se ignoram. Nomear o PFR **destrava** o strategy-ADR:
dá a ele o termo concreto que seu Princípio 3 já pressupõe sem nomear.

## Gatilho de promoção (quando cravar a seção L0 em `commands.md §3`)

Disparar o PR constitucional (PR dedicado + bump `version` + aprovação `@metaspec-gate-keeper`, conforme
`commands.md §9`) quando **qualquer** ocorrer:

1. O scaffolder `/meta:create-phased-command` for usado para gerar **≥2 PFRs novos** conformes — prova de
   que o padrão nomeado é executável e estável.
2. O **strategy-ADR for aceito** — então seleção + execução entram coordenados na mesma rodada (evita L0
   fragmentado).
3. Surgir um terceiro consumidor do termo (ex.: a skill `onion` roteando explicitamente por "PFR") que
   torne a ausência do nome no L0 um atrito real.

Até lá: **provisório**. O valor (nome canônico + scaffolder + reconciliação) é entregue sem risco
constitucional.

## Consequências

- ✅ Vocabulário único ("PFR") para um padrão hoje citado por descrição em 13+ lugares.
- ✅ Fronteira seleção↔execução nomeada — destrava o strategy-ADR parado sem duplicá-lo.
- ✅ Autoriza o scaffolder `/meta:create-phased-command` a existir referenciando um conceito nomeado.
- ✅ A decisão de mexer no L0 fica ancorada em evidência (uso real + gatilho), não em entusiasmo — fiel ao
  precedente design-peer e a `architecture.md §9`.
- ⚠️ O termo "PFR" carrega o rótulo "provisório" até o gatilho — aceitável (vive em `docs/analysis/`, não
  na constituição).
- ⚠️ Risco de over-engineering explicitamente vetado: o esqueleto do PFR **não** é uma abstração SDAAL
  (não há provedores intercambiáveis; o worklog já é a abstração — de *processo*, não de *transporte*).
  SDAAL aplica-se **dentro** de um passo do PFR que fala com provedor externo (ex.: o auto-update do Task
  Manager já usa o adapter SDAAL `task-manager`).

## Alternativas consideradas

1. **Criar um domínio/categoria `wizard/` + `wizard-context/`** — rejeitado: falha no critério §8 (não é
   peer); não há conteúdo de domínio; inventa estrutura para um método que já é transversal.
2. **Criar uma KB nova `phased-resumable-pattern.md`** — rejeitado: `worklog-protocol.md` já é 70% disso;
   uma KB irmã fragmentaria a SSOT que se quer unificar. Expandir, não duplicar.
3. **Cravar já a seção L0 em `commands.md`** — rejeitado: viola o precedente design-peer e o regime de
   mudança de `architecture.md §9` (cravar cedo, sem evidência de uso do nome nem coordenação com o
   strategy-ADR, é promover por entusiasmo).
4. **Não nomear (manter implícito)** — rejeitado: é o baseline ad-hoc; o padrão segue disperso e cada novo
   fluxo nasce por cópia, com deriva de contrato.
