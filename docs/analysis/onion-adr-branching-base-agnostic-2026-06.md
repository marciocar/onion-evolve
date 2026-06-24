---
title: 'ADR — Branching: a base é dado resolvido (agnóstica), não GitFlow/develop hardcoded — "adota não impõe" aplicado'
date: 2026-06-24
type: adr
status: proposto
decision-scope: engineering / branching-topology (SDAAL-ish base resolution)
supersedes: none
deciders: maestro + sessão de evolução
context_freshness: 2026-06-24
related:
  - onion-adr-adopt-to-not-impose-2026-06.md (princípio-pai: detecta e defere, never-clobber)
  - ../../.claude/validation/resolve-integration-branch.sh (a semente: resolução de base já existe)
  - ../../.claude/commands/engineer/pr.md (já resolve a base via .onion-version → git config → detect)
  - ../../.claude/commands/git/flow.md (motor GitFlow — ainda assume develop)
  - ../../.claude/commands/git/sync.md (default develop)
  - ../knowledge-base/frameworks/gitflow-patterns.md (motor GitFlow — KB)
---

# ADR — Branching: base resolvida (agnóstica), não GitFlow/develop hardcoded

> **Status: PROPOSTO (provisório).** Nomeia a decisão e a costura; a **implementação** (propagar a
> resolução de base aos `git:*` + canal-na-trunk) fica **diferida ao gatilho**. Aplicação direta do ADR
> [onion-adr-adopt-to-not-impose](onion-adr-adopt-to-not-impose-2026-06.md) (#160) ao eixo branching.

## Contexto

Sinal de campo do `rhilo-metagamify` (2026-06-24, `inbox/_processed/2026-06-24-sinal-branching-trunk-based-vs-develop.md`):
o adotante faz **CD** (deploy no push de `rhilo/main`) e tem feature flags, mas o Onion lhe impôs
**GitFlow/`develop`** — e o canal `docs/evolution/` + os comandos vendorizados ficaram **encalhados em
`develop`**, divergente (53 commits) da trunk que deploya. "Metade em cada lado": o que se commita no canal
não é o que roda em produção.

### Diligência (alegações verificadas, não aceitas de cara)

1. **git:* embute `develop`** — ✅ verdade: `git:sync` (default `develop`), `git:init` (cria `develop`),
   `git:flow` (`feature→develop`, `release` de `develop`).
2. **Já existe resolução de base** — ✅ verdade, **mas só metade**: `resolve-integration-branch.sh` existe
   e o `/engineer:pr` (#104) já resolve a base pela cadeia `.onion-version` → `git config gitflow.branch.develop`
   → default detectado. **Não propagou** aos `git:*`.
3. **"/meta:co-evolve manda commitar em develop"** — ❌ falso: o comando é **agnóstico a branch**; o canal
   vive onde o `docs/evolution/` foi commitado. Quem o pôs em `develop` foi a adoção, não o comando.

## Decisão

**1. A base de integração é DADO RESOLVIDO, não constante.** O default GitFlow/`develop` deixa de ser
hardcoded nos `git:*`; passa a ser **resolvido** pela mesma cadeia que o `/engineer:pr` já usa
(`resolve-integration-branch.sh`: `.onion-version integration_branch` → `git config` → detecção). É o ADR
#160 ("adota não impõe") aplicado a branching: o Onion **detecta a trunk de integração do projeto** e
opera nela, em vez de impor `develop`.

**2. NÃO trocar o default para trunk-based.** Migrar o default de GitFlow→trunk-based só **troca uma
imposição por outra** — proibido pelo #160. GitFlow continua **uma** topologia suportada (para adotante
versionado/multi-versão); trunk-based é obtido **setando a integration branch = a trunk** (`main`/`rhilo/main`).
O framework é **agnóstico**; a topologia é configuração do adotante.

**3. O canal de co-evolução segue a integration branch resolvida.** `docs/evolution/` (e os comandos
vendorizados) devem viver na **trunk que o adotante integra/deploya**, não numa `develop` paralela —
senão o canal/comandos ficam fora de produção (a dor do sinal, e a causa do *"Unknown command"* fora de
develop).

**4. Escopo da costura (diferido ao gatilho):** propagar `resolve-integration-branch.sh` para
`git:sync`/`git:flow`/`git:init` (substituir o `develop` literal pela base resolvida) + guidance no
`/meta:adopt`/`/design`-style discovery de que o canal mora na trunk resolvida. **Implementação = follow-up
com diligência + selftest + revisão independente** (mexe no motor GitFlow — não se apressa).

## Coerência

- **#160 (adota não impõe):** este ADR é uma **instância** — branching é onde o Onion mais impõe. Não
  reabre o princípio; aplica-o.
- **`/engineer:pr` + `resolve-integration-branch.sh`:** a direção já é a oficial (base resolvida); este ADR
  só **termina** a propagação que parou no `pr`.
- **gitflow-patterns.md (KB):** GitFlow permanece o motor **documentado e suportado** — vira "a topologia
  default quando a base resolve para uma `develop`", não a única.

## Gatilho de promoção (quando implementar)

Disparar a costura quando **qualquer**: (a) este adotante (`rhilo-metagamify`) executar a migração local
para trunk única e precisar dos `git:*` coerentes; (b) surgir 2º adotante CD/trunk-based; (c) o `git:init`
for rodado num projeto trunk-based novo. Até lá: **provisório** — o `/engineer:pr` já resolve a base; os
demais `git:*` seguem default `develop` (sem regressão para adotantes GitFlow).

## Consequências

- ✅ Onion para de **impor** branching; a base vira configuração detectada — coerente com #160 e com o
  consenso 2026 (trunk-based para CD) **sem** impor trunk-based a quem não faz CD.
- ✅ Canal/comandos deixam de encalhar fora de produção.
- ✅ Reusa a semente existente (`resolve-integration-branch.sh`) — não inventa mecanismo.
- ⚠️ Implementação **diferida** — mexe no motor GitFlow (`git:*`); exige selftest + revisão. Este ADR só
  nomeia + costura.
- ⚠️ "Provisório" até o gatilho — vive em `docs/analysis/`.

## Alternativas consideradas

1. **Trocar o default para trunk-based** — rejeitado: troca imposição por imposição (#160).
2. **Manter GitFlow/develop hardcoded** — rejeitado: é a dor do sinal (encalhe fora de prod) e contraria #160.
3. **Resolver caso-a-caso, sem nomear** — rejeitado: o `/engineer:pr` já resolve; deixar os `git:*` fora
   gera o "metade em cada lado". Nomear fecha a inconsistência.
4. **Implementar já, nesta tacada** — rejeitado: mexe no motor GitFlow; merece ADR (este) + costura
   revisada à parte. Eficaz ≠ apressado no motor.
