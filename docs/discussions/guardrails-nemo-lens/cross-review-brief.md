---
title: "Brief de cross-review para o core — PR #348 (onion-guardrails candidato)"
category: discussion
status: rascunho-cross-review (propose→confirm)
date: 2026-07-13
branch: docs/onion-guardrails
para: core-próprio (sessão de evolução)
responde: docs/evolution/inbound/_processed/2026-07-12-boletim-core-pre-pr.md ("O NÓS")
pr: https://github.com/marciocar/onion-evolve/pull/348
---

# 🤝 Cross-review para o core — PR #348

> O boletim disse: *"o merge não sai no teu ok sozinho nem no do core sozinho: sai no nosso"* e *"a checagem #1
> é comigo"*. Este brief te leva direto ao que **precisa do teu julgamento** — sem te fazer refazer o que já
> está fechado.

## 1. O que JÁ está validado (não refaça)

- **3 checagens do boletim** — fechadas com evidência no registro de discussão: #1 reconciliação (`e467ec5`),
  #2 refutador (`ee08dbf`), #3 escopo (`3d5ca6a`).
- **Pre-PR canônico** — fan-out dos 4 branch-agents, **0 blocker/major**; único needs-fixes (índice) corrigido.
- **Revisão adversarial anterior** — 5 revisores acharam 2 blockers (loop infinito nos helpers), corrigidos;
  suítes 9+9 verdes; lint 0/0.
- **Gate mecânico** — lint-artifacts limpo (SSOT sincronizada, KB 69→70, índice 28→32).

Ou seja: consistência interna, testes, lint e escopo estão cobertos. **Não gaste teu tempo aí.**

## 2. O que precisa do TEU julgamento (o foco do cross-review)

### 2.1 A checagem #1 é tua — valida o veredito "herda, não reinventa"
Eu propus que ONION-R **herda** de `authorization-layers`/`a2a-verify`/`trust` (11/14 por read-path). Confirma
ou refuta — sobretudo **duas extensões conscientes** que decidi que são o teu ponto de bênção:

- **R15.2 acrescenta uma dimensão SEMÂNTICA ao teu modelo intake.** A KB `authorization-layers` trata intake
  como binário (livre pra ler / gated pra agir). R15.2 insere *"livre pra ler, mas não pra obedecer"* —
  conteúdo cercado é dado, não instrução. **Isto estende teu modelo. Abençoas essa extensão, ou ela conflita
  com a tese binária da §2 da tua KB?**
- **R15.3b promove o TODO da tua §7 a helper real** (`onion-effect-gate.sh`). Tua KB disse *"a linha não é
  enforçada uniformemente por um só helper — seria o próximo passo"*. Eu materializei. **A classificação
  intake-verb × execution-verb (allow/gate/fail-safe) casa com a tua intenção da linha, ou o corte está no
  lugar errado?**

### 2.2 A doutrina de escopo semântico
Deleguei **moderação de conteúdo ao host** e recusei **classificador probabilístico no caminho crítico**,
mantendo só a fatia determinística (proveniência). **Concordas com essa fronteira in-scope/out-of-scope, ou o
Onion deveria reivindicar mais (ou menos)?**

### 2.3 `candidato` é o call certo?
Promovi só o concept KB como `candidato` (ganha core por uso). A taxonomia com 148 read-paths **ficou de fora**
(sem gate anti-drift ainda). **Concordas em deixar entrar como `candidato`, ou nem isso antes do gate anti-drift?**

## 3. Onde EU estou incerto (cava aqui — honestidade adversarial)

- **O 3º modo ("estrutural/silencioso").** Afirmo que never-clobber-por-construção é um modo distinto de
  determinístico/gated. **É categoria real ou racionalização minha** de guardas que só por acaso não emitem
  string? O refutador não derrubou, mas não é o teu olhar.
- **O resíduo de R15 monta no host.** O dogfood (75%→0%) é **N=4, direcional**; a metade gated depende de o
  modelo respeitar a cerca. **Essa honestidade basta pra `candidato`, ou queres mais evidência antes?**
- **Taxonomia como evidência vs KB promovida.** Deixei o catálogo de read-paths na discussão (não no core)
  por causa da A2. **Certo — ou o catálogo deveria entrar JÁ com o gate anti-drift construído neste PR** (em
  vez de diferido)?

## 4. A decisão que TU deténs

Aprovar/mergear #348 (`candidato`), pedir mudanças, ou segurar. **O merge é nosso** — preciso do teu veredito
nos itens da §2, e um sanity-check nos da §3. Se aprovar as extensões §2.1, o 2º PR (wire-in R15 + gate
anti-drift) vira backlog concreto.

> **Nota (pós-merge de `main`):** enquanto eu preparava este brief, o `main` avançou e foi mergeado nesta
> branch (contagens reconciliadas a 73 KBs por scan; lint verde). Um dos PRs que entrou é o **ADR
> `merge-authority-per-lineage`** (#346) — que dá **doutrina explícita** ao "O NÓS": autoridade de merge é por
> papel/linhagem, não presumida. `onion-evolve/main` é o core-próprio (não produção-de-cliente), então a
> autoridade aqui é **maestro + core** — exatamente o "sai no nosso". O ADR não governa #348 diretamente, mas
> **respalda** a exigência de cross-review em vez de merge unilateral.

## 5. Enquanto isso, no teu inbox

3 sinais de dogfood do pre-PR pra triar (`inbox/2026-07-13-sinal-dogfood-pre-pr-guardrails.md`): `candidato`
fora do enum de `code-standards §2.6`; link-check só cobre `docs/evolution/`; `/engineer:pr` presume `feature/*`.
