---
branch: perf/hook-autofix-fechamentos
pr: 590
date: 2026-08-13
reviewed_diff_sha256: 8fccf7eb812df2b7bf5f4dd3fd5dd8de7b1268b62ff673aca38497683f07547c
findings_total: 9
findings_real: 9
findings_fixed: 8
tokens: 110467
duration_min: 17
verdict: CORRIGIDO-E-RE-REVISADO
reviewer: code-reviewer (opus, adversarial — 4º Elenxo da linha de mecanismos)
---

# Passada adversarial — `perf/hook-autofix-fechamentos`

## O 4º Elenxo da linha, e a lei se confirmou pela 4ª vez

O revisor recebeu instrução explícita: *"os 3 anteriores SEMPRE acharam a mesma classe: a cura
reincide no que fecha — procure isso"*. Achou. **A v1 do auto-fix fechava 57% da população que
declarava fechar**, e o probe que eu escolhi para prová-la (kg.md, entrada-arquivo) era o
happy-path da metade coberta.

## Achados

| # | sev | achado | status |
|---|---|---|---|
| A1 | **HIGH** | grep textual cego a entradas-DIRETÓRIO — 72/167 fontes (43%) nunca disparariam; repro `engineer/plan.md` sem nada impresso e `tree_sha` divergente | corrigido — `source` das arrays do manifesto |
| A2 | **HIGH** | `git commit <pathspec>` usa índice temporário — o `git add` do hook virava **revert fantasma** staged para o commit seguinte; verde local, vermelho no CI, culpando o commit errado | corrigido — gate por `GIT_INDEX_FILE` |
| A3 | **HIGH** | o assemble lê a árvore — staging parcial **publicaria WIP não-staged** em artefato que ninguém lê em review | corrigido — aborta com instrução |
| A4 | MEDIUM | manifesto e assembler editados não disparavam (o ato mais plugin-afetante, invisível) | corrigido — entram como fontes |
| A5 | MEDIUM | rename de fonte não dispara | **teto declarado** — o assemble-falho da R19 bloqueia fail-loud |
| A6 | LOW | `printf \| grep -q` sob pipefail: SIGPIPE engole match acima de ~78KB (limiar medido; classe do PR #502) | corrigido — padrões em arquivo |
| A7 | LOW | rc=2 do check tratado como "schema quebrado" (defeito errado apontado); check lê a árvore, não o índice | corrigido + teto declarado |
| A8 | LOW | `git add \|\| true` engolia falha depois de o rastro afirmar "stageado" — rastro mentiria | corrigido — aviso explícito |
| A9 | cosmético | path feio na violation | corrigido |

**Limpo (atacado, não achado):** `-x` com linha vazia/prefixo; `-f <(…)` sob `set -e`;
`git add` cobre remoção; sem recursão (nenhum manifesto declara `plugins/`); **idempotência do
amend** (o diff-cached é vazio no amend — sem churn); fluxo do `tmp` sem vazamento; zero
falso-positivo do extractor nos 7 manifests; adotante não afetado (hook de template próprio) —
com a nota para o futuro: se este bloco for espelhado no template do adotante, precisa do gate
`IS_DERIVED`.

## As provas da v2, uma a uma

- entrada-DIRETÓRIO (`engineer/plan.md` — o repro da v1): **dispara** e stagea
- `GIT_INDEX_FILE` temporário: **pula com aviso**
- staging parcial: **aborta com instrução**
- manifesto editado: **dispara**
- schema sabotado no gatilho do SUT: **bloqueia** com a violation nomeada
- skill bundlada removida: o lint **acusa E soma** (era morte rc=2 sem sumário)

## A propriedade estrutural da v2

A v1 mantinha uma **lista paralela** de fontes (o grep do texto do manifesto) — e lista paralela
diverge no primeiro edit. A v2 lê as fontes **pela mesma via que o assemble** (`source` das
arrays): não pode divergir por construção. É a mesma cura do `kg-reverify-schema-check` extraindo
o schema do arquivo em vez de copiá-lo. A classe "duas fontes divergem" morre no desenho, não na
disciplina.

## Teto declarado

O grafo (`Q_R19_AUTOFIX`) foi **re-carimbado**: o `verified_against` anterior afirmava cobertura
por um probe da metade que funcionava — exatamente o que o revisor apontou como "o grafo carimba
como fechado o pedaço que o 5º Elenxo reabriria". Não houve 5º Elenxo sobre estas correções:
re-validação por gate mecânico (bancada 803/0 nos dois hooks, radar exit 0) + os 6 repros
dirigidos acima. E o rename (A5) fica como teto permanente do auto-fix — bloqueio fail-loud pela
R19 é o comportamento aceito, não um furo.
