---
branch: fix/review-dirty-tree-guard
pr: 592
date: 2026-08-13
reviewed_diff_sha256: 10eb53f0a7dd06a9a195feff82864eed337b6bdfb1a60c3a14b99bf0f1a99633
findings_total: 6
findings_real: 6
findings_fixed: 5
tokens: 52008
duration_min: 14
verdict: CORRIGIDO
reviewer: code-reviewer (opus, adversarial — 6º Elenxo da linha de mecanismos)
---

# Passada adversarial — `fix/review-dirty-tree-guard`

## O 6º Elenxo derrubou a v1 da guarda — a lei da linha, 6ª instância

A guarda dirty-tree v1 (porcelain após a revisão) nasceu da anomalia do PR #590 e caiu em dois
golpes simétricos: **gritaria em 100% das runs** (falso-positivo estrutural) e era **cega em 2
das 3 modalidades** que o próprio prompt novo proíbe.

## Achados

| # | sev | achado | status |
|---|---|---|---|
| 1 | **ALTA** | o SessionEnd do próprio Onion apenda em `.claude/session-lifecycle.jsonl` (TRACKED) em toda run — provado no clone: sessão headless de 1 turno suja o porcelain; o runner carrega `settingSources: [user, project, local]` | corrigido — `ledger_append` ganha `[ -z "${GITHUB_ACTIONS:-}" ] || return 0` (na origem, não guarda-por-lista no workflow) |
| 2 | **ALTA** | `git checkout <sha>` e `git stash` deixam o porcelain **VAZIO** (medido) — a v1 via só 1 das 3 modalidades proibidas | corrigido — marco HEAD/stash capturado ANTES da revisão; condição composta (porcelain ∨ HEAD movido ∨ stash criado) |
| 3 | MÉDIA | o aviso caía DEPOIS do rodapé `<sub>advisory</sub>` — o leitor consumia o parecer inteiro antes de saber que talvez nada fosse do PR | corrigido — aviso entra por cima, preservando a MARCA sticky na 1ª linha |
| 4 | MÉDIA | `origin/main` fixo nos 2 prompts quebra em adotante com default branch diverso (o arquivo é distribuído por `/meta:setup-code-review`) | corrigido — `origin/${{ github.event.pull_request.base.ref }}` (cobre também PR empilhado) |
| 5 | BAIXA | `head -10` truncava em silêncio (12 linhas → 2 somem sem marca) | corrigido — "(mostrando 10 de N)" quando N>10 |
| 6 | BAIXA | a guarda só roda no ramo "revisou" — crash do revisor cai no `else` sem carimbo | **teto declarado** em comentário no próprio bloco |

**Refutados (9):** working-directory; `${{ }}` acidental; injeção via nomes hostis (bancada com
`a$(touch /tmp/PWNED).sh` — nada executou); quebra do `--sticky` (casamento é `contains`);
execution_file/mktemp dentro do repo (ambos em `_temp`); lint suja a árvore (rc=0, porcelain
vazio); three-dot no merge-ref (byte-idêntico a `HEAD^1...HEAD^2` — o two-dot é que erra);
`origin/main` ausente no fetch do runner; a proibição atrapalhar leitura legítima.

## Verificação da v2 (minha, além da do revisor)

Harness do Elenxo em clone descartável, 3 cenários: `checkout HEAD~2` → **HEAD-movido** ·
`stash` → **stash-criado** · `checkout <base> -- arquivo` (o gesto do #590) → **arquivos-alterados**.
O 3º cenário silenciou na 1ª rodada — probe ruim (arquivo idêntico entre os SHAs), reprovado e
re-provado com probe que difere. YAML validado (`yaml.safe_load`).

## Teto declarado

Sujar-e-limpar (checkout+restore na mesma sessão) passa invisível às três réguas. E **este PR
edita o workflow, logo não mede o revisor** (`onion-review-ci-semantics`): a action se auto-pula
no caso `benigno`; a prova viva da guarda vem do 1º PR seguinte ao merge. Registrado também o
efeito colateral fora de escopo: o predicado `benigno` mede `git diff BASE_SHA HEAD` — com HEAD
deslocado pelo revisor, mede outro commit (fica como observação no nó do grafo).
