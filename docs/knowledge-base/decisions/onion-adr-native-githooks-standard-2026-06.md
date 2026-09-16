---
title: 'ADR — git hooks NATIVOS (core.hooksPath) são o padrão Onion de pre-commit; husky/lefthook são opcionais do adotante'
date: 2026-06-27
type: adr
status: aceito
decision-scope: adoption / dev-tooling / standardization
supersedes: none
deciders: maestro + sessão de evolução
context_freshness: 2026-06-27
related:
  - ../../.githooks/pre-commit (o hook nativo que o core já dogfooda)
  - ../../.claude/utils/adopt/githook-pre-commit-onion.tpl (template shippado a adotantes)
  - ../../.claude/utils/adopt/install-onion-githook.sh (helper que provisiona no alvo)
  - ../../.claude/commands/meta/adopt.md (/meta:adopt — Fase 3 passo 6)
  - ../evolution/inbox/_processed/2026-06-27-adopt-legacy-husky-precommit-enoent.md (sinal de campo que originou)
  - ../knowledge-base/frameworks/gitflow-patterns.md (motor GitFlow)
  - onion-adr-adopt-to-not-impose-2026-06.md (princípio: adotar sem impor)
---

# ADR — git hooks nativos como padrão Onion de pre-commit

> **Status: ACEITO.** Nomeia o padrão que o core **já dogfooda** e o estende aos adotantes via
> `/meta:adopt`. Implementação concreta no mesmo loop (template + helper + passo na Fase 3 +
> cobertura de selftest). Husky/Lefthook permanecem **opções do adotante**, não padrão.

## Contexto

A adoção de um adotante legacy (2026-06-27) bateu num atrito reproduzível: o projeto usa
**husky v8 + lint-staged**, e a worktree de instalação (`onion/adopt`) não tem `node_modules` → o
pre-commit invoca `prettier`/`eslint` ausentes → **`ENOENT`**, `lint-staged` reverte, o commit da
adoção **não acontece**. 2º adotante a bater nisso. Sinal de campo:
`docs/evolution/inbox/_processed/2026-06-27-adopt-legacy-husky-precommit-enoent.md`.

A investigação "husky ainda faz sentido em 2026?" revelou o quadro real:

- **O core onion-evolve NÃO usa husky.** Usa git hook **nativo**: `.githooks/pre-commit` (bash puro)
  ativado por `git config core.hooksPath .githooks`. Zero dependências; Onion nem é projeto npm.
- **Husky** (não depreciado, mas v8 desatualizado no alvo) existe essencialmente para **registrar**
  hooks — trabalho que o `core.hooksPath` (git ≥ 2.9) faz **nativo, de graça**. Acopla o hook ao
  runtime Node (a causa-raiz do ENOENT).
- **Lefthook** (binário Go) traz paralelismo/config única, mas **adiciona uma 3ª ferramenta** ao stack
  e **não** resolve o ENOENT da worktree se instalado como devDep npm (mesma classe). Otimização
  local de um projeto, não padrão de ecossistema.

## Decisão

**O padrão Onion de pre-commit é o git hook nativo (`core.hooksPath` + diretório versionado
`.githooks/`).** É o que o core já roda; `/meta:adopt` passa a **shippar e recomendar** o mesmo padrão
aos adotantes.

Critérios que pesaram (pedido do maestro: **máxima padronização + alinhamento à estratégia Onion**):

| Critério | Husky | Lefthook | Nativo (`core.hooksPath`) |
|---|---|---|---|
| Dependências extras | Node + pacote | binário Go | **zero** (git nativo) |
| Funciona sem node_modules (worktree) | ❌ | ❌ se npm devDep | ✅ (degrada gracioso) |
| Já dogfoodado pelo core | não | não | ✅ |
| Um padrão único core↔adotantes | não | não | ✅ |
| Adiciona ferramenta ao stack Onion | — | sim | não |

O hook nativo é o **mais padronizado** (um mecanismo só, core e adotantes) e o **mais alinhado à
estratégia** (framework não-npm, mínimo de dependências, dogfood como padrão master).

## Implementação

1. **Template** `.claude/utils/adopt/githook-pre-commit-onion.tpl` — espelha o `.githooks/pre-commit`
   do core e encadeia o `lint-staged` do projeto **com degradação graciosa**: roda o lint Onion (se
   presente) → roda `lint-staged` **só se** `node_modules/.bin/lint-staged` existe (senão pula, nunca
   ENOENT).
2. **Helper** `.claude/utils/adopt/install-onion-githook.sh <DEST>` — provisiona o template em
   `<DEST>/.githooks/pre-commit` (never-clobber → sidecar `.onion`), detecta husky e **avisa migração**,
   seta `core.hooksPath .githooks` **só se UNSET** (never-clobber do hooksPath do adotante). Idempotente.
3. **/meta:adopt Fase 3** (Procedimento pós-cópia, passo 6) chama o helper. **Fase 2c** mantém o aviso
   `--no-verify` como paliativo do 1º commit, apontando o nativo como cura de raiz.
4. **Cobertura** `lint-selftest.sh: run_githook_selftests` — exercita os cenários (absent/sidecar/
   husky-detect/hooksPath-never-clobber/idempotente).

## Consequências

- **+** Um padrão de hook em todo o ecossistema Onion; dor de adoção curada na raiz (não só avisada).
- **+** Dogfood honesto: o Onion recomenda exatamente o que ele próprio roda.
- **−** A migração husky→nativo num adotante existente é **gesto do adotante** (never-clobber não
  desinstala husky nem força `core.hooksPath`): o helper provisiona e **avisa**, mas a troca é manual.
- **Ressalva honesta:** o *mecanismo* fica dependency-free; comandos que o hook chama (eslint/prettier
  via lint-staged) ainda precisam de `node_modules` — daí a degradação graciosa (pula em vez de quebrar).

## Não-decisões (fora de escopo)

- **Não** banir husky/lefthook: adotantes podem mantê-los; o Onion só estabelece o **default** e a
  recomendação. Lefthook segue como escolha legítima de projeto (monorepo grande que queira paralelismo).
- **Não** tocar o core (já usa o nativo).
