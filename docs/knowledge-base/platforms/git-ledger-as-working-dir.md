---
title: "Git ledger como additional working directory (Claude Code)"
date: 2026-06-14
type: platform
status: validated
related:
  - ../../analysis/onion-federation-design-v2-2026-06.md
  - ../../analysis/onion-federation-design-review-2026-06.md
  - ../concepts/multi-repo-federation.md   # (a criar na Fase 1 do backlog)
---

# Git ledger como *additional working directory*

> **O que esta KB prova:** que um repositório git dedicado (o "ledger" / *federation
> spine* do design Onion Federation v2) pode ser **lido, escrito e versionado via `git`**
> a partir da sessão de um repo-membro, usando o recurso **nativo** de *additional working
> directories* do Claude Code — **sem** servidor, sem CLI standalone, sem IA-fala-IA.
>
> Resultado do spike da **Fase 0** (GATE) do backlog Federation v2. De-risca o alerta
> sistêmico **SA-3** da [review adversarial](../../analysis/onion-federation-design-review-2026-06.md).

## 1. Contexto — por que este spike existiu

O design v1 (topologia hub) repousava num spike **não-verificado e load-bearing**: uma sessão
Claude Code operar sobre o diretório de outro repo como raiz de subagente (SA-3). Se falhasse,
todas as fases cross-repo colapsariam.

O design v2 (topologia peer) substituiu isso por um **ledger git montado como working directory
adicional**. A pergunta da Fase 0: *ler/escrever + `git` nesse diretório, a partir da sessão de
um membro, é tão trivial quanto o design supõe?* Esta KB responde: **sim.**

## 2. O mecanismo (nativo do Claude Code)

O Claude Code expõe **additional working directories** — diretórios fora do `cwd` primário que a
sessão pode ler e escrever com as ferramentas nativas (Read/Edit/Write/Bash). O ledger é um desses
diretórios:

```
sessão do membro (cwd primário = repo-A)
        │  ferramentas nativas: Read / Edit / Write / Bash(git)
        ▼
LEDGER GIT (additional working directory)   ← repo dedicado, neutro
        ├─ members.yaml        (manifesto)
        ├─ contracts/<C>.md    (SSOT versionada do contrato)
        └─ CHANGELOG.md        (caixa de correio append-only = "inbox")
```

Nenhuma primitiva nova: é o mesmo acesso a arquivos que a sessão já usa para os additional working
directories do ambiente (ex.: `/tmp`, repos irmãos). Remote git **opcional** (local-only para solo
mesma-máquina; com remote para time/distribuído).

## 3. O spike — o que foi feito (reproduzível)

Ledger scratch criado em `/tmp/federation-ledger-spike` (`/tmp` é additional working directory da
sessão). Ciclo *producer publica → consumer lê inbox → consumer valida em casa → consumer registra*:

| Passo | Ator | Ferramenta | Prova |
|---|---|---|---|
| 1. `git init` + skeleton + commit | producer (repo-a) | `Bash` | contrato `v0.1.0` publicado |
| 2. ler `CHANGELOG.md` + `contracts/` | consumer (repo-b) | **`Read` nativo** | inbox alcançável da sessão |
| 3. anexar entrada `CHECK-OK` no CHANGELOG | consumer (repo-b) | **`Edit` nativo** | escrita persiste na working-dir adicional |
| 4. commit + `git log` | consumer (repo-b) | `Bash` | 2º commit; histórico íntegro |

### Evidência

Estrutura:
```
federation-ledger-spike/
├── CHANGELOG.md
├── contracts/
│   └── sample-contract.md
└── members.yaml
```

`git log --oneline` (≥2 commits = ciclo completo):
```
22875f3 check(user-created-event): repo-b validated v0.1.0 locally, compatible [consumer m-b9f2]
a83c089 publish(user-created-event): v0.1.0 initial contract [producer m-7a1c]
```

Mailbox (`CHANGELOG.md`) após o ciclo — append-only, producer e consumer:
```
## 2026-06-14 · user-created-event · 0.1.0 · m-7a1c (producer) · PUBLISH
Contrato inicial publicado por repo-a. Consumers afetados: m-b9f2.

## 2026-06-14 · user-created-event · 0.1.0 · m-b9f2 (consumer) · CHECK-OK
repo-b leu o inbox, validou em casa contra as fixtures: compatível. Sem migração necessária.
```

Conclusão: **read, write e `git` na working-dir adicional funcionam pelas ferramentas nativas.**
O `Read` leu o inbox; o `Edit` escreveu o `CHECK-OK`; o `Bash(git)` versionou — tudo da sessão
`onion-plus`, sem nenhuma primitiva fora do Claude Code.

## 4. Conclusão do gate (placement) — `@metaspec-gate-keeper`

A Fase 0 também exigia veredito de placement **antes do primeiro arquivo** (de-risca SA-1).
Veredito: **Sim-com-ajustes** — sem resíduo estrutural SA-1. Itens aprovados: comandos em `meta/`
(não nova categoria — commands.md §2:111, §8:309), ledger **externo** (não `.claude/federation/` —
architecture.md §7:251), KBs em `concepts/`+`platforms/` (§1.3:107/110), orquestração no nível
principal (§4.2:203, §10.1:332-333).

**Dois ajustes obrigatórios para a implementação (Fase 1+):**

1. **Zero path absoluto em artefato `.claude/`** (architecture.md §7:255). Comandos/skill
   `federation-*` resolvem ledger e membros **exclusivamente** via `members.yaml` (dado) + working
   dirs registrados. Path absoluto vive **só** no dado de config do ledger externo, nunca no código
   do framework. ⚠️ Implicação direta para o `members.yaml`: o campo `path:` é dado de instância,
   não pode ser lido por hardcode no comando.
2. **Declarar onde vive `MemberExpertSchema`** (o "veto" da validação local): embutido no
   comando/skill (nível principal) **ou** em `.claude/validation/` (precedente `inventory.sh`).
   **Nunca** como agente (§4.2:203).

## 5. Limites desta validação

- **Spike descartável.** O ledger `/tmp/federation-ledger-spike` foi removido após esta KB. O
  **bootstrap do ledger real** (repo dedicado de produção) é a **Fase 1** do backlog, não a Fase 0.
- **Remote não exercitado.** Provou-se local-only (mesma máquina). O fluxo com remote git (push/pull
  do ledger para time distribuído) é git padrão, mas fica para validar quando a Fase 1+ precisar.
- **Concorrência não exercitada.** Dois membros escrevendo o ledger ao mesmo tempo (lock/merge) é
  débito da Fase 1+ (review #24); o `id` estável no manifesto é o primeiro passo.

## 6. Conexão com a evolução

Esta KB fecha a parte técnica da **Fase 0** (GATE) do
[Onion Federation v2](../../analysis/onion-federation-design-v2-2026-06.md) §7. Com SA-3 de-riscado
e o placement liberado (Sim-com-ajustes), o caminho para a **Fase 1** (formato de contrato +
bootstrap do ledger real, testável num repo só) está aberto — respeitados os ajustes 2a e 6a acima.
