---
title: "Checagem #1 do core — reconciliação ONION-R × authorization-layers / a2a-verify / trust (herda, não reinventa)"
category: discussion
status: reconciliacao-checagem-1-core
date: 2026-07-12
branch: discuss/guardrails-nemo-lens
responde: docs/evolution/inbound/_processed/2026-07-12-boletim-core-pre-pr.md (checagem #1)
lente: igual→transfere / diferente→desenha
ancoras: [authorization-layers-intake-vs-execution.md, a2a-verify.sh, trust-topology-check.sh, metaspec-gate-keeper.md]
---

# Checagem #1 — ONION-R herda, não reinventa

> **Pedido do core (boletim pré-PR):** *"A taxonomia Onion-R contra `authorization-layers` (intake×execução) +
> `a2a-verify` + `trust`. Guardrail que duplica/contradiz a linha ou o gate a2a precisa **herdar, não
> reinventar** (régua: igual→transfere)."* Este doc fecha essa checagem, aterrado na leitura das âncoras.

## Método

Para cada categoria ONION-R, o veredito é um de três:
- **HERDA** (`igual→transfere`) — a categoria **É** um mecanismo existente; ONION-R apenas o **nomeia/indexa
  via read-path**. Não há código novo nem conceito paralelo. Herança **por construção**.
- **ESTENDE** — a categoria aplica um modelo existente a um território que ele deixou em aberto; cita o pai.
- **NOVO** (`diferente→desenha`) — genuinamente ausente das âncoras; desenhado próprio, sem contradizê-las.

**Tese central (a resposta ao core):** ONION-R **não é um sistema paralelo** — é uma **lente/índice** sobre
gates que já existem. 6 das 14 categorias destiladas *são literalmente* camadas do `a2a-verify`/`trust`/
`metaspec-gate-keeper` (mesmo read-path); a única parte nova (R15) **estende** a linha intake×execução que a
própria KB `authorization-layers` §7 deixou aberta. Herança é a regra; reinvenção, nenhuma.

## Reconciliação por categoria

| ONION-R | Veredito | Âncora (read-path) | Nota de herança/transferência |
|---------|----------|--------------------|-------------------------------|
| **R2** Autenticidade cripto A2A | **HERDA** | `a2a-verify.sh` camadas 1,6 (parse, JWS) = authorization-layers §2 tabela, linhas #1,#6 | É a verificação a2a. ONION-R só a nomeia. |
| **R4** SSRF / egress | **HERDA** | `a2a-verify` / `a2a-ssrf-check.sh` = auth-layers camada #5 | Idem — camada 5 da escada. |
| **R6** Topologia de confiança | **HERDA** | `trust-topology-check.sh` + `a2a-verify` camada 2 = auth-layers **trust** (#2) | É o `trust`. Nome, não reimplementação. |
| **R11** Anti-replay / frescor | **HERDA** | `a2a-verify` camadas 3,4 = auth-layers #3 (replay), #4 (timestamp) | Idem. |
| **R9** Anti-alucinação (REGRA ZERO) | **HERDA** | `metaspec-gate-keeper.md` (constituição) | Gate epistêmico já existente; ONION-R o cataloga. |
| **R5** Never-clobber / I3 | **HERDA** | `durable-commit.sh`, `co-deliver.sh` = auth-layers §4 (co-evolução/adoção) + I3 | O invariante entrega-sem-commit; nomeado. |
| **R1/R3/R7/R8/R12** SSOT, spec-as-code, CLI, contrato, WCAG | **HERDA** | `lint-artifacts.sh`, `federation-contract-validate.sh`, `lint-design-tokens.sh` | Gates do `.claude/validation/` — fora do escopo a2a/trust, sem overlap. |
| **R13** Invariantes de orquestração | **HERDA** | `metaspec-gate-keeper.md` + `onion-validation` + `lint-artifacts.sh:349` | Regra arquitetural existente; nomeada. |
| **R14** Fronteira SDAAL | **HERDA** | `lint-artifacts.sh:670,713,744` | Idem. Sem overlap com a2a/trust. |
| **R15.3a** Efeito-gate estrutural (C1/C2) | **HERDA** | `a2a-accept.sh:8` (never-apply) + `co-deliver.sh:12` (I3) = auth-layers **A LINHA** (§2, guarda gated) + §4 | **É a linha intake×execução**, nomeada. Zero código novo. |
| **R15.3b** Efeito-gate (C3) | **ESTENDE** | pai: auth-layers **§7 lacuna** — *"a linha não é enforçada uniformemente por um só helper — um lint transversal seria o próximo passo"* | ⭐ **A própria KB pediu isto.** `onion-effect-gate.sh` é o "próximo passo" que ela nomeou. Herança máxima. |
| **R15.1** Cerca de proveniência | **NOVO** (`diferente→desenha`) | — (ausente das 3 âncoras) | O `a2a-verify` prova o *envelope*; nenhuma âncora marca a *proveniência do corpo*. Genuinamente novo. |
| **R15.2** Dado-não-instrução | **ESTENDE** | pai: auth-layers §2 ("intake é autônomo") | Refina: intake segue autônomo, **mas** conteúdo lido no intake é enquadrado como dado. Dimensão semântica que a KB não tinha. |

## Os três achados que respondem ao core

### 1. HERANÇA POR CONSTRUÇÃO — 11 das 14 categorias *são* mecanismos existentes
R2/R4/R5/R6/R9/R11 + R1/R3/R7/R8/R12/R13/R14 não têm uma linha de código nova: seus vetos apontam para
`a2a-verify.sh`/`trust-topology-check.sh`/`metaspec-gate-keeper.md`/`.claude/validation/*` **por read-path
verificado**. ONION-R é a **lente** que os nomeia sob um vocabulário comum — exatamente o que a pesquisa de
mercado prescreveu (consolidação transversal, não sistema paralelo). *igual→transfere* aplicado ao próprio core.

### 2. R15.3 É a linha intake×execução — herda, não redefine
A KB `authorization-layers` é o modelo intake×execução. **R15.3a nomeia os efeito-gates que ela já lista**
(`a2a-accept` never-apply na §2; `co-deliver` I3 na §4). **R15.3b é literalmente o "próximo passo" que a KB
§7 declarou faltar** ("um lint/helper transversal que enforça a linha uniformemente"). O `onion-effect-gate.sh`
não inventa a linha — **materializa o TODO da própria âncora**. Não há modelo concorrente: há um modelo (o da
KB) ganhando o helper que lhe faltava.

### 3. Só R15.1 é genuinamente NOVO — e não contradiz nada
A cerca de proveniência (R15.1) preenche o vão que o `a2a-verify` **explicitamente não cobre**: ele prova
*quem assinou o envelope* (`verified-crypto`), nunca *que o corpo é confiável* (`verified-semantic`). É
`diferente→desenha` — desenhado próprio, ortogonal às âncoras (não duplica nem contradiz nenhuma camada).

## Correções de enquadramento aplicadas (pra herança ficar à prova de leitura)

Para que a taxonomia **leia** como lente e não como sistema paralelo, ajustei os docs:
1. **kb-spine + taxonomia:** cabeçalho afirmando explicitamente "ONION-R é índice sobre gates existentes; 11/14
   herdam por read-path" (não um registro novo de controles).
2. **r15 design:** R15.3 marcado como **herança** da KB `authorization-layers` (cita a §7 como pai de R15.3b),
   não como linha nova.
3. **R15.2:** nomeado como **extensão semântica** do modelo intake (a KB trata intake como binário
   livre/gated; R15.2 acrescenta "livre para ler, não para obedecer") — a bênção dessa extensão é item de
   cross-review com o core.

## Veredito (checagem #1)

**ONION-R herda, não reinventa.** 11/14 categorias são gates existentes nomeados por read-path; R15.3 é a
linha intake×execução da própria KB (R15.3b materializa o TODO da §7); só R15.1 é novo, e é ortogonal. **Zero
contradição** com as 3 âncoras encontrada. Os únicos pontos que exigem a bênção do core no cross-review são
**extensões conscientes**, não colisões: (a) R15.2 acrescenta a dimensão semântica ao modelo intake; (b) R15.3b
promove o "próximo passo" que a KB já previa a status de helper real.

> **Para o NÓS (cross-review):** a checagem #1 é do core. Este doc é a proposta; o veredito final da
> reconciliação — sobretudo se (a) e (b) acima são extensões que o core abençoa — *sai no nosso*.
