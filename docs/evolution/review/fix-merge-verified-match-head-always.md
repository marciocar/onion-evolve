---
branch: fix/merge-verified-match-head-always
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: a0aef489d8364a3332b6b070c2266ba1be68041055112a48fa764ac7480dcabd
reviewed_code_sha256: d2e9c29ccc182d3fd03845390f20f3b735d3bdebd5f7ebac6c4cda574c99a92c
findings_total: 9
findings_real: 4
tokens: 105419
duration_min: 4
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente refutador (general-purpose, só leitura, mutantes em cópia)
nota: "tokens e duração são do refutador; a cura do achado 1 (th4/th4m) e o re-rodar da família foram da sessão de execução"
---

# Passada adversarial: `fix/merge-verified-match-head-always`

## O que muda

O `ops/pr-merge-verified.sh` julgava os check-runs do head lido (cura do #634), mas o `gh pr merge` só
levava `--match-head-commit` no caminho sem o CI do head novo (`SKIP_CI=1`, com `--admin`). Nos demais
(rebase, squash, `--merge-commit`) um push entre a leitura do CI e o merge deixava o forge mergear um
head que ninguém julgou. Caso vivo: a curadoria, PRs #117 e #118 de 2026-10-26, em `--merge-commit`.
Agora `--match-head-commit "${JUDGED_HEAD}"` vai em todo caminho e o `--admin` segue só no de dispensa.
A recusa do forge com head movido é lida pelo `headRefOid` relido (dado, não prosa) e sai como
"o head mudou depois do julgamento (X → Y); rode de novo".

## Achados

1. **MÉDIA, real, curado:** o esboço só movia o head DENTRO da chamada de merge, então um mutante que
   relê o `headRefOid` logo antes do merge (reabrindo o TOCTOU) ficaria verde. Cura: caso (th4), em que
   o push cai entre o julgamento e o merge, e mutante (th4m), que relê, e reprova.
2. **MÉDIA, real, não curado (declarado):** o `_head_moved_die` do bloco `SKIP_CI=1` e o desvio rc 4 do
   `--no-wait-after-rebase` não têm caso próprio. A família `merge_skip_ci` monta auto-rebase real em
   sandbox; um caso de head movido ali é peça própria.
3. **BAIXA, real, curado:** na série (rc 4) a mensagem chamava de "head esperado" o sha julgado. Agora
   diz "o head julgado era X".
4. **BAIXA, real, aceito:** com rc≠0 e head movido, a causa narrada é o `--match-head-commit` mesmo se o
   forge recusou por outro motivo. O desfecho continua seguro (nada mergeado, rode de novo).
5. a 9. **Informativos:** `--ci-inoperante` julga a árvore local sem amarrá-la ao `HEAD_SHA`
   (pré-existente); no `SKIP_CI=1` o `JUDGED_HEAD` é o head novo e os gates leram o anterior (desenho
   de antes); a guarda de `HEAD_SHA` vazio é quase inalcançável; sem merge queue no ruleset, o
   `--match-head-commit` sem `--admin` não liga auto-merge; os ramos novos do esboço só agem com
   `GH_PUSH_AT_MERGE` e não tocam os outros casos.

## Mutantes

Família `pr_merge_verified`: 65 verdes, 0 falhos. (th3) tira o `--match-head-commit` do caminho de
sempre ⇒ mergeia o head não julgado e o (th1) reprova. (th4m) relê o head antes do merge ⇒ o (th4)
reprova. As duas âncoras acusam quando não casam (`cmp -s`).

## Limites declarados

- O gh falso imita o `expectedHeadOid` do forge; a mensagem real do GitHub não é lida (de propósito).
- Achado 2 fica aberto, como acima.
