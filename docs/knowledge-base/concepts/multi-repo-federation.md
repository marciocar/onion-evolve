---
title: "Multi-repo federation — contratos spec-as-code + ledger git"
date: 2026-06-15
type: concept
status: active
related:
  - ../platforms/git-ledger-as-working-dir.md
  - ../../analysis/onion-federation-design-v2-2026-06.md
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

Schema mínimo estável (o `id` sobrevive a rename — review #24):

```yaml
version: 1
members:
  - id: m-7a1c            # estável; chave de correlação
    name: repo-a
    path: ./relative-or-config-path   # DADO de instância (não hardcode em comando — ajuste 2a)
    remote: git@...                    # opcional
    role: producer                     # producer | consumer | lib
```

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

## 5. Tooling (Fases 1-2)

**Scripts determinísticos** (`.claude/validation/`, sem LLM — ajuste 6a):
- **`federation-contract-validate.sh`** (Fase 1) — o *"teste que falha se o contrato quebrar"*:
  valida as seções obrigatórias (incl. `tests`+`fixtures`), exit ≠0 acionável. Espelha `inventory.sh`.
- **`federation-inbox-scan.sh`** (Fase 2) — lê o `CHANGELOG.md` e extrai, por consumer, os contratos
  endereçados na versão vigente + a classe do bump (BREAKING/COMPATIBLE/INITIAL). Saída `--json`.

**Comandos** (`meta/`, orquestram no nível principal):
- **`/meta:federation-register`** (Fase 1) — localiza/bootstrapa o ledger, valida e **grava+commita**
  o contrato em `contracts/<id>.md`. **Não** escreve no CHANGELOG (átomo local, sem anúncio).
- **`/meta:federation-publish`** (Fase 2) — o **único escritor do CHANGELOG/inbox**: classifica o
  bump, aplica o **checkpoint do maestro**, endereça os consumers e sela a entrada de inbox + commit.
- **`/meta:federation-check`** (Fase 2) — lado consumer: lê o inbox (`inbox-scan`), valida cada
  contrato em casa e emite o `MemberExpertSchema` **fail-safe** (BREAKING/inválido/ausência = veto).

> **Fronteira register × publish:** `register` atesta que um contrato **válido existe**; `publish` é
> o **ato deliberado de anunciar** (com humano no loop). Só o `publish` toca o CHANGELOG.
> O par **comando (orquestra) + script (valida)** é o padrão canônico do Onion para trabalho
> determinístico validável — o mesmo do inventário. Mantém a validação fora de agente (6a).

## 6. Limites (o que ainda NÃO está pronto)

- **`/meta:federation-status`** (monitor: CI por membro + contract-drift) — **Fase 3** do backlog.
- Fluxo do maestro **completo** cross-repo (PRs coordenados + ordem de merge + Rollback Protocol) — **Fase 3**.
- Ledger **real de produção** com **remote** + concorrência (lock/merge) — a Fase 2 valida o ciclo
  `publish→check` num ledger scratch (cross-repo simulável num repo só).
- Membros não-Onion / stacks heterogêneos — fases seguintes.
