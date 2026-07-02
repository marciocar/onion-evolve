---
title: "Multi-repo federation — contratos spec-as-code + ledger git"
date: 2026-06-15
type: concept
status: active
related:
  - ../platforms/git-ledger-as-working-dir.md
  - ../../analysis/onion-federation-design-v2-2026-06.md
  - ../../analysis/onion-federation-adr-a2a-format-interop-2026-06.md
  - ../../sdaal/
---

# Multi-repo federation

> Como o Onion coordena mudanças entre **repositórios soberanos** sem quebrar integrações —
> com **contratos versionados** (spec-as-code) num **ledger git** e o humano como maestro.
> Esta KB define o **formato de contrato** (o artefato central da Fase 1) e enquadra a federação
> como uma instância de **SDAAL + spec-as-code**.

## 1. Modelo mental (peer, não hub)

Cada repo mantém seu Onion **soberano**. A comunicação é **assíncrona via git** — não há servidor,
conexão viva, nem IA-fala-IA (essa é a linha vermelha abandonada em 2026-05-18). O meio compartilhado
é o **ledger** (repo git dedicado, montado como *additional working directory* — ver
[git-ledger-as-working-dir](../platforms/git-ledger-as-working-dir.md)):

```
REPO A (producer)                         REPO B (consumer)
 muda a API X                              lê o inbox, valida em casa
      │ publica contrato/bump                    ▲ check local (veto de 1ª mão)
      └──────────►  LEDGER GIT (spine)  ─────────┘
                    ├─ members.yaml      (manifesto)
                    ├─ contracts/<C>.md  (SSOT versionada do contrato)
                    └─ CHANGELOG.md      (caixa de correio append-only = inbox)
        VOCÊ = maestro: leva a decisão de A para B.
```

É **SDAAL** aplicado: o contrato é a *interface estável*; cada repo é um *consumer da abstração*;
o ledger é o *registry*. É **spec-as-code**: o contrato é texto estruturado, versionado e
**validável por máquina** (o gate-keeper valida o formato; um script valida cada instância).

## 2. Formato de contrato (a SSOT do "não pode quebrar")

Um contrato vive em `contracts/<id>.md` no ledger. **Seções obrigatórias** (a validação falha se
faltar qualquer uma):

| Seção | Obrigatória | Conteúdo |
|---|---|---|
| `id` | ✅ | identificador estável do contrato (kebab-case) |
| `version` | ✅ | **semver** (`MAJOR.MINOR.PATCH`) — bump major = breaking |
| `producer` | ✅ | `id` do membro que emite (do `members.yaml`) |
| `consumers` | ✅ | lista de `id`s de membros que consomem |
| `interface` | ✅ | o que a integração expõe (descrição) |
| `types` | ✅ | assinatura/shape (ex.: bloco TS, JSON Schema) |
| **`tests`** | ✅ | **≥1 path** de contract-test no repo producer — *sem teste = blocker* (review #4) |
| **`fixtures`** | ✅ | **≥1 payload** de exemplo — contrato **comportamental**, não só sintático (review #14) |

`tests` e `fixtures` são o que transforma o gate de **promessa** em **gate**: a mudança é validada
contra payloads reais, então uma alteração de *significado* com a mesma assinatura é pega.

### Template canônico

```markdown
# Contract: <id>

- **id:** <id>
- **version:** 0.1.0
- **producer:** <member-id>
- **consumers:** [<member-id>, ...]

## interface
<o que a integração faz>

## types
​```ts
interface <Name> { /* shape */ }
​```

## tests        # OBRIGATÓRIO — ≥1 path; sem teste = blocker
- <repo>/test/contracts/<id>.spec.ts

## fixtures     # OBRIGATÓRIO — ≥1 payload de exemplo
​```json
{ "...": "..." }
​```
```

## 3. Manifesto (`members.yaml`)

Schema mínimo estável (o `id` sobrevive a rename — review #24). **v2 desde a RFC-0003** (2026-07-01):
o `role` de membro usa a hierarquia de tiers (`source | hub | standalone | consumer`), que **substituiu**
o binário `producer | consumer | lib`:

```yaml
version: 2
members:
  - id: m-7a1c            # estável; chave de correlação
    name: repo-a
    path: ./relative-or-config-path   # DADO de instância (não hardcode em comando — ajuste 2a)
    remote: git@...                    # opcional
    role: hub                          # source (T0 core) | hub (T1) | standalone (T3) | consumer (T2, exige parent:)
    parent: <id-do-core-ou-hub>        # obrigatório para hub/standalone/consumer (RFC-0003 §2.1)
```

> ⚠️ **Não confundir os namespaces:** o `role:` acima é o papel do **membro** na rede (tier RFC-0003).
> Os campos `producer:`/`consumers:` do **contrato** (`contracts/<id>.md`, §2 acima) são um eixo
> **ortogonal** — papel por contrato — e permanecem inalterados pela RFC-0003.

> **Ajuste 2a:** `path` é **dado de configuração** lido do `members.yaml` — comandos e scripts do
> framework **nunca** embutem caminho absoluto. Resolução é por argumento / manifesto / path relativo.

## 4. Máquina de segurança (resumo — design v2 §5)

1. **Contrato** = SSOT spec-as-code, versionado, semver.
2. **Contract-tests** no repo producer (CI dele); campo `tests:` obrigatório.
3. **Comportamental:** `fixtures` obrigatórias revisam mudança de *significado*.
4. **Veto de 1ª mão:** o consumer valida **em casa** ao ver o inbox e emite `MemberExpertSchema`
   `{approved, blocked_contracts[], required_migrations[], reasoning}`; `approved:false` (ou output
   ausente) **bloqueia** (fail-safe). A lógica de validação é **determinística** e vive em
   `.claude/validation/` — **nunca** um agente (ajuste 6a).
5. **Coordenação + rollback:** maestro humano; PRs por repo (forge); ordem de merge; Rollback Protocol.

## 5. Tooling (Fases 1-3)

**Scripts determinísticos** (`.claude/validation/`, sem LLM — ajuste 6a):
- **`federation-contract-validate.sh`** (Fase 1) — o *"teste que falha se o contrato quebrar"*:
  valida as seções obrigatórias (incl. `tests`+`fixtures`), exit ≠0 acionável. Espelha `inventory.sh`.
- **`federation-inbox-scan.sh`** (Fase 2) — lê o `CHANGELOG.md` e extrai, por consumer, os contratos
  endereçados na versão vigente + a classe do bump (BREAKING/COMPATIBLE/INITIAL). Saída `--json`.
- **`federation-status-scan.sh`** (Fase 3) — detecção determinística de **contract-drift**: compara a
  versão de cada `contracts/<id>.md` com a última PUBLISH no CHANGELOG (`in-sync`/`drift`/`unpublished`). `--json`.

**Comandos** (`meta/`, orquestram no nível principal):
- **`/meta:federation-register`** (Fase 1) — localiza/bootstrapa o ledger, valida e **grava+commita**
  o contrato em `contracts/<id>.md`. **Não** escreve no CHANGELOG (átomo local, sem anúncio).
- **`/meta:federation-publish`** (Fase 2) — o **único escritor do CHANGELOG/inbox**: classifica o
  bump, aplica o **checkpoint do maestro**, endereça os consumers e sela a entrada de inbox + commit.
- **`/meta:federation-check`** (Fase 2) — lado consumer: lê o inbox (`inbox-scan`), valida cada
  contrato em casa e emite o `MemberExpertSchema` **fail-safe** (BREAKING/inválido/ausência = veto).
- **`/meta:federation-status`** (Fase 3) — monitor read-only: drift (via `status-scan`) + CI por
  membro (via **forge adapter**). Veredito `SÃO`/`ATENÇÃO`.
- **`/meta:federation-rollback`** (Fase 3) — Rollback Protocol guiado: pina a versão anterior no
  ledger + entrada `ROLLBACK`, guia os reverts por repo (ordem inversa). **Human-gated.**

> **Fronteira register × publish:** `register` atesta que um contrato **válido existe**; `publish` é
> o **ato deliberado de anunciar** (com humano no loop). Só o `publish` toca o CHANGELOG.
> O par **comando (orquestra) + script (valida)** é o padrão canônico do Onion para trabalho
> determinístico validável — o mesmo do inventário. Mantém a validação fora de agente (6a).

## 6. Fluxo cross-repo conduzido + Rollback Protocol (maestro — design §6/§5.5)

A mudança que atravessa repos é **conduzida pelo maestro humano** (atomicidade multi-repo não existe
no GitHub). O ciclo completo:

```
1. muda no PRODUCER (sessão normal) → /meta:federation-register  (valida + grava o contrato)
2. /meta:federation-publish          → anuncia o bump (checkpoint do maestro)
3. em cada CONSUMER: /meta:federation-check → veto de 1ª mão (breaking/ausência = bloqueia)
4. /meta:federation-status           → SÃO/ATENÇÃO (drift + CI por membro) antes de mergear
5. PRs coordenados (1/repo via /engineer:pr + forge); ORDEM DE MERGE: producer-compatível
   primeiro, consumers depois (gate de CI verde)
6. quebrou? /meta:federation-rollback → reverte coordenado (abaixo)
```

**Rollback Protocol (§5.5) — guiado, human-gated** (`/meta:federation-rollback`):
- **Trigger:** check vetou pós-merge, ou CI de consumer vermelho após adotar o bump.
- **Ordem inversa:** consumers primeiro, producer por último (oposto da ordem de merge).
- **Pin no ledger** (única parte automatizada, reversível): contrato volta à versão anterior +
  entrada `ROLLBACK` **append-only** no CHANGELOG.
- **Reverts por repo:** o comando **lista** (não executa); o maestro aplica via forge.
- **Falha parcial → gate humano:** se um repo não reverte limpo, **pare e escale** — não force consistência.
- Confirme com `/meta:federation-status` que voltou a `SÃO`.

## 7. Limites (o que ainda NÃO está pronto)

- Ledger **real de produção** com **remote** + concorrência (lock/merge) — o MVP valida o ciclo
  completo num ledger scratch (cross-repo simulável num repo só).
- Membros **não-Onion** / stacks heterogêneos — fases seguintes.
- **A2A — distinção de camadas** (refinada em 2026-06-15; razão, mapeamento e gatilho no
  [ADR A2A](../../analysis/onion-federation-adr-a2a-format-interop-2026-06.md)):
  - 🔴 **Runtime A2A / instâncias vivas distribuídas** — **linha vermelha** (Fase 5 ABANDONADA, design §2):
    a federação é **assíncrona via git + forge**, **nunca IA-fala-IA em tempo real**. Inegociável.
  - 🟢 **Formato/vocabulário A2A (Agent Card) como projeção one-way** — **permitido em princípio**:
    exportar a camada de manifesto (`members.yaml`) num formato Agent Card-compatível, **sem** transporte
    vivo. **Não implementado** — diferido até o gatilho do ADR (1º consumer não-Onion / interop real). Os
    `contracts/` permanecem nativos (o Agent Card não os cobre — ver mapeamento no ADR).
