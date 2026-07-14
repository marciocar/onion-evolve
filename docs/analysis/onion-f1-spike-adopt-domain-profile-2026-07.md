---
title: "Spike F1 — o gap G1: /meta:adopt presume software; adoção de domínio (KG de vida) precisa de --profile"
date: 2026-07-13
type: spike
status: concluído — sizing feito; alimenta o desenho do F2 (não implementa)
decision-scope: adoption / non-software domain / adopt profile
related:
  - docs/discussions/onion-pessoal-marcio/README.md
  - docs/discussions/onion-pessoal-marcio/proto/membership-marcio-pessoal.yaml
  - .claude/commands/meta/adopt.md
---

# Spike F1 — o gap G1 (adoção de domínio não-software), dimensionado

> **Origem:** plano faseado do Onion pessoal (F0 método → **F1 spike G1** → F2 build → F3 campo). O F0 provou
> o método num N=1 real; este F1 dimensiona o gap **G1** que a discussão só tinha **nomeado**
> ([`onion-pessoal-marcio`](../discussions/onion-pessoal-marcio/README.md)): *"o que viaja é o método KG SDAAL,
> não a máquina de adoção de repo de código."* Spike = **probe, não build**.

## Método (dogfood)

Examinei o artefato real — o manifest `want=`, o wiring e as fases de [`/meta:adopt`](../../.claude/commands/meta/adopt.md) —
e **quantifiquei** o mismatch contra um alvo cujo conteúdo é um `.kg.yaml` de vida (não código).

## Achado central: o modo de falha é **inadequação silenciosa**, não crash

`/meta:adopt` num repo de KG **não quebra com erro** — ele **sucede e entrega um resultado inchado e mal-fiado.**
Um adotante ingênuo levaria peso morto + hooks sem sentido, sem nenhum sinal de que algo está errado.

### (1) Payload — vendoriza o framework inteiro

O `want=` copia todo o `.claude/` no alvo: **~3,7MB** de framework de engenharia — ~130 arquivos sob
`.claude/commands`, ~60 sob `.claude/agents`, mais skills/utils/hooks. Dos quais **relevantes a um KG de vida**:

- [`/meta:kg`](../../.claude/commands/meta/kg.md) (1 arquivo de comando)
- `kg-radar.sh` + `kg-console.sh` (2 validators)

Ou seja: **~3 arquivos de método** contra **~3,7MB** de suíte code-oriented (react/jira/docker/gitflow/`/engineer:*`…
nenhum aplicável). O método é ~0,1% do que seria vendorizado.

### (2) Wiring — todo de dev-workflow de código

O `Procedimento pós-cópia` fia atuadores que **não fazem sentido** num repo de KG pessoal:

| Wiring | Pressupõe | Num KG de vida |
|---|---|---|
| `install-onion-githook.sh` | pre-commit que linta artefato de framework | linta `.claude/`, não `.kg.yaml` — inócuo/errado |
| `merge-prettierignore.sh` | formatador de código (prettier) | não existe formatador num repo de KG |
| `vendor-branch.sh` · `durable-commit.sh` · integration-branch | **GitFlow** + fluxo de PR | um KG de vida pessoal não tem branch de integração nem PR |

### (3) O que TRANSFERE (a metade que encaixa)

A camada de **governança** é agnóstica de domínio e serve: `--mode regulated`, o pin `.onion-version`,
`pin-integrity-check.sh`, e a soberania (private / local-first) — exatamente o que o
[proto de membership](../discussions/onion-pessoal-marcio/proto/membership-marcio-pessoal.yaml) já previa.

## Conclusão — o fix não é "fazer o adopt funcionar pra KG"

É dar ao adopt uma noção de **perfil de domínio**. Direção proposta (input pro **F2 build**):

1. **`--profile <kg|domain>`** — perfil de vendoring **mínimo**: só o método (`/meta:kg` + `kg-radar`/`kg-console`
   + docs SDAAL do KG), **não** a suíte de engenharia.
2. **Zero wiring de código** — sem GitFlow/integration-branch, sem pre-commit de lint de framework; no lugar,
   um gate **KG-apropriado** (integridade do `.kg.yaml` via `kg-radar`).
3. **Governança reusada como está** — `--mode regulated` + pin + soberania.

## Fronteira do spike

Este F1 **dimensiona**, não implementa. O manifest já é conclusivo pro sizing; a validação extra natural
(não-bloqueante) seria um `/meta:adopt <throwaway-kg> --mode regulated --dry-run` real. A construção do
`--profile` é **F2**.
