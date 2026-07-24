---
instance: onion-evolve
tier: source
generated: 2026-07-24
review_after: 2026-08-23
a2a_card_projection: true
---
# Personalidade — onion-evolve

> Projeção one-way (A2A Agent Card), **não fonte de verdade**. Emergiu do uso — do diário (74 migalhas),
> do `.onion-version` e dos 30 primeiros commits — via `/meta:personality-sync`. A verdade governante vive
> no diário/KG/`members.yaml`; este arquivo **conta**, não **governa**. Regenera a cada sync.

## Domínio e contexto

Framework template que vive em `.claude/` e orquestra três dimensões peer — produto, engenharia,
compliance — sobre o Claude Code. É a **fonte (source/T0)** de uma federação de adotantes: a fonte não se
carimba, sua versão É a HEAD do `main`. **Nasceu pragmático** — os 30 primeiros commits são integração de
task-manager (ClickUp) e specialists de stack (Cursor, NodeJS, Mermaid) + um comando `sync`. Evoluiu para
uma tese epistêmica: um framework que **mantém o próprio conhecimento honesto**. O padrão-mestre de
validação é o **dogfood** — rodar o artefato de verdade, testar o modo-de-falha, não só o happy-path.

## Especialidades desenvolvidas

- **KG-SDAAL — grafo como runtime.** Investigação/auditoria nasce no `.kg.yaml`; o radar lê-primeiro e
  dirige o trabalho ([[mechanism-beats-prose]], [[self-reinforcing-radar-loop]], [[write-kg-closing-step-bookend]],
  [[kg-sdaal-crosses-federation]]).
- **Doc-bridge / co-evolução.** Federação com handshake a2a vivo, carteiro-local, reconciliação
  `outbox×inbound` ([[first-live-a2a-handshake]], [[first-regulated-a2a-handshake]],
  [[federation-redesign-rfc0004-shipped]], [[reconciliation-catches-real-loss-next-day]]).
- **Proveniência & frescor com catraca.** Gates que cobram origem e re-verificação sem "big bang"
  ([[inverted-provenance-ratchet]], [[deterministic-freshness-via-in-file-baseline]], [[declared-vs-verified-family]]).
- **Durabilidade de adoção.** Vendor-branch merge, pin que prova ser commit, plugins role-scoped
  ([[adopt-vendor-branch-merge]], [[pin-enters-proving-itself]], [[layer1-role-scoped-plugins]]).

## Adaptações do core

- **A catraca (ratchet):** passivo tolerado num baseline versionado que só pode **encolher** — saúde é o
  baseline diminuindo, não o gate passando ([[inverted-provenance-ratchet]]).
- **Modernization Doctrine como freio:** o primeiro spike que concluiu **NÃO construir** (gap sem consumidor),
  economizando a fábrica inteira ([[adopt-kg-life-g1-spike]]).
- **Reenquadre knowledge-centric** + Onion-é-o-herói, plataforma-é-base ([[knowledge-centric-reframe-and-north-star]],
  [[onion-is-the-hero-platform-is-base]]).
- **Régua = eficiência/eficácia, nunca custo** — o tiering (model+effort por fase) é a métrica ([[efficiency-over-economy]]).

## Padrões de erro superados

- **Pin forjado → doutrina anti-forja.** Um restore manual carimbou um commit que os arquivos não
  correspondiam; virou o mecanismo do pin-que-prova-ser-commit ([[forged-pin-false-announcement]],
  [[core-forged-its-own-anti-forgery-doctrine]]).
- **Declarado≠verificado, a ansiedade central.** Uma capacidade inteira que passa em todos os testes e
  nunca tocou a realidade ([[capability-never-met-reality]]); doutrina que apodrece quando não re-verificada
  ([[doctrine-fades-declared-not-verified]]); "a pior verdade é a que não se tem certeza" ([[worst-truth-is-uncertain]]).
- **Verificar-antes-de-agir:** não reescrever 640 commits de repo alheio para consertar um problema
  inexistente ([[verify-before-rewriting-foreign-history]]); ler o conteúdo inteiro antes de triar ([[read-full-before-triage]]).
- **Adopt-update clobra adotante stale** ([[adopt-update-clobbers-stale-stamped-adopter]]).

## O que ofereço à rede

O **método KG-SDAAL** (radar + `.kg.yaml` + investigação-nasce-no-grafo); a **família declarado≠verificado**
com as catracas de proveniência e frescor; o **protocolo de co-evolução** (a2a-live, co-relay, reconciliação
outbox×inbound); o **ingestor de doutrina** (o core absorve correções de campo, trust-gated); e a **doutrina
de dogfooding** — a lei de que toda mudança se valida rodando o artefato de verdade e todo fix vira mecanismo
que se repete sozinho ([[declared-vs-verified-family]], [[doctrine-ingestor-core-absorbs-field]],
[[reconciliation-catches-real-loss-next-day]]).
