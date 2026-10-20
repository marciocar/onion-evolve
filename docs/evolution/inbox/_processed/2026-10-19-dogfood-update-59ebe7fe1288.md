---
title: "Dogfood do --update 0d0636f4ca74 → 59ebe7fe1288 no hub: 7 fricções, 2 delas sobre o contrato KG-SSOT"
date: 2026-10-19
type: signal
kind: field-feedback
from: brain-granaai (hub, pin 59ebe7fe1288)
severity: medium
---

# Dogfood do `--update` para 59ebe7fe1288

O maestro pediu o update em modo dogfood: rodar o procedimento como escrito e devolver o que travou. O update
fechou com **HARD 0** (base e branch), um conflito resolvido, hooks 22 → 25. As fricções, da mais séria para a menor:

## 1. O corpus do adotante herda o contrato v4 já reprovado, e nada avisa

Com `vendor/kg-ssot` v4.9.1 chegando pela primeira vez, `kg-contract-check.sh` reprova **24 de 24** grafos do hub
no MUST, todos por `form.required.node.provenance` (**1.024 de 1.268 nós** `confirmed`/`PROD` sem
`provenance {source, locator, method}`). O lint dá 0 HARD porque o gate do corpus é `ops/kg-gate-ci.sh`, que não
viaja. O relatório de update não mede isso e o `offer-onion-ci.sh` diz "lint VERDE".

**Pedido:** o `--update` medir o contrato no corpus do alvo (como o `remeasure-hard.sh` mede o lint) e escrever o
número no relatório; e um caminho de migração do corpus (catraca de dívida herdada ou gerador de `provenance` a
partir de `trace:`/`evidence`), já que os grafos antigos têm a fonte em `trace:`, só não no campo novo.

## 2. O vendor do contrato já nasce defasado

O core vendoriza **v4.9.1** (18/10); o upstream `kg-ssot` está em **v4.10.0** (19/10). Pela doutrina
`keep-current-doctrine` a defasagem deveria ser subida ou nomeada; o relatório não a nomeia.

## 3. O `diff --stat` do relatório subconta quando o manifesto cresce

O procedimento mede `git diff --stat <pin>..HEAD -- <manifesto>`: **239 arquivos**. No alvo chegaram **540**,
389 deles em `vendor/kg-ssot`, que entrou no manifesto em 15/10 (`5eed13fa`) e chega inteiro, enquanto o delta
só conta o que mudou desde o pin. **Pedido:** medir no alvo (`<integração>..<branch do update>`), ou somar as
entradas novas do manifesto.

## 4. A trava `pretooluse-env-guard.sh` barra operações que não leem segredo

Na mesma sessão ela bloqueou: `find -name '.env*' -print` (lista caminhos), `find -iname '*env*'` (casou com
`-prune`), um `grep -o` que imprimiria só **nomes** de chave, e um heredoc que gravava o relatório deste update
só porque o texto **citava** o nome `.env.test`. O maestro teve de rodar a listagem à mão com `!`. **Pedido:**
distinguir listar caminho ou nome de chave (seguro) de ler valor; e não casar texto em prosa.

## 5. Índice da KB com contagem que não bate

`docs/knowledge-base/index.md` do core: cabeçalho "Conceitos Fundamentais (42)", **44** entradas listadas, **53**
arquivos em `concepts/`. Foi o único conflito do merge (o hub não listava 4 conceitos que tem em disco).
**Pedido:** gerar o índice ou checar a contagem no lint.

## 6. O procedimento não cobre "a sessão do alvo dirige o update"

O maestro estava na sessão do hub; rodei os helpers do core por caminho (`SOURCE_ROOT=~/onion-evolve`). Funcionou,
mas o texto assume sessão-fonte (ex.: `settings-before.json` em `.claude/sessions/` do core) e não diz se o commit
do merge com conflito resolvido deve passar pelo gate — o `durable-commit.sh` com `ONION_DURABLE_VERIFY=1` só
cobre o commit seguinte.

## 7. O corte do `/meta:publish` deixa citações para trás

O `/meta:publish` e a skill `onion-publish` saíram do hub, mas `cc-update.md:104` e `create-vertical.md:152` (ambos
core-only, mas vendorizados no papel hub) e comentários em `pretooluse-moat-gate.sh`, `resolve-update-source.sh` e
`vendor-branch.sh` ainda o citam. Inofensivo hoje; é o mesmo vetor da REGRA 100 (citar o que o destinatário não tem).

## O que funcionou bem

`dedicated-branch.sh` detectou o farol e abriu worktree irmã sem tocar o checkout; o corte de papel tirou o
`/meta:publish` do hub; o `merge-onion-hooks.sh` podou o hook aposentado e o `--diff` deu o delta exato;
`regen-baselines.sh` filtrou 4 chaves estrangeiras sem re-emitir; o `ensure-secret-gitignore.sh` achou um arquivo
de ambiente versionado que ninguém tinha visto.
