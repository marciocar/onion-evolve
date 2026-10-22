---
branch: docs/radar-e3-r16
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: e73414ce05c4199c9a431daa696def1ee0e17e04155605e12c2420b481eda57d
reviewed_code_sha256: 8770cb45c4b82a7f75703b6312d9a38dcc9cfa2dd65644a3d240846e1b32ffc1
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 20
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork da sessão (claude-opus-5-5), passada própria"
nota: "tokens não medidos (fork); o achado é do medidor e virou issue, não foi curado aqui (o cc-update não implementa ações)"
---

# Passada adversarial: `docs/radar-e3-r16`

## O que muda

- Rodada r16 do radar E3: grafo `radar-E3-2026-10-22-r16.kg.yaml` (8 nós), `data/2.1.308.txt`,
  `data/judge-verdicts.json`, `SYNTHESIS.md`, a baseline do E3 em `docs/onion/radar-baselines.yaml` e a projeção
  `docs/backlog.md`.

## Achados

1. O `cc-delta-census.sh` filtra `/worktrees/` pelo caminho absoluto e zera a contagem de `scriptPath` numa
   worktree (8 contra 0, medido). Fica como `Q_CENSO_FILTRA_WORKTREE_PELO_CAMINHO_RELATIVO_1022` e SAC-219, por
   desenho do comando, que não implementa ações.

2. O 1º push reprovou no CI (família kg-machine-path, ISENCAO-NOVA): o nó do achado isentava um caminho de
   máquina por `x_path_is_content`. Re-revisado: o caminho não era o conteúdo; o nó passou a citar o filtro pela
   forma, sem caminho, e a família roda verde localmente.

## Mutantes

- CU1: o diff da cópia contra o CHANGELOG oficial sai vazio; com uma linha alterada, o diff acusaria.
- CU4: os três alvos de SUPERSEDES existem na r15 (grep), e o contrato confere os alvos (rc 0).

## Limites declarados

- O juiz não foi independente: a rodada rodou num fork, que não pode lançar subagente.
- A versão do CLI no runner do CI não foi lida num log de job.
