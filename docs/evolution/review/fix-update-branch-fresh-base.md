---
title: 'Resíduo — a branch do update nasce da ponta mais nova e o deny do adotante nunca encolhe'
date: 2026-11-06
branch: fix/update-branch-fresh-base
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 2
findings_blocking: 1
findings_fixed: 2
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
elenxo: nao
reviewer: passada própria sobre o diff inteiro (sem subagente, por regra do brief), com a bancada das famílias tocadas e o dogfood no caso real da curadoria
nota: >-
  O sinal da curadoria dizia que o --update apagava o permissions.deny (67 → 0 no #229). Medi antes de escrever:
  o merge-base do #229 (6edfb23) já tinha 0 regras, e o deny entrou na origin/main pelo #225 DEPOIS dele. O
  update não apagou nada; a branch nasceu da main local defasada. O merge-onion-hooks.sh não toca em
  permissions, e o git merge-tree de origin/main com o head deu 67 regras byte-iguais às da main. A cura está
  onde nasce o defeito, e não onde o sinal apontava: o dedicated-branch.sh passa a criar a branch a partir da
  ponta mais nova da integração, e o deny-monotonic.sh dá ao relatório a linha que teria visto o caso. Dogfood
  real: contra o head antigo do #229 (ec879ab) o helper diz "67 no alvo (origin/main) → 0 no head" com rc 1;
  contra o head consertado (8604185), "67 → 67" com rc 0. Passada adversarial com 4 pontos. (1) BLOQUEANTE,
  curado: nascer de origin/<base> com `checkout -b` grava origin/<base> como upstream da branch do update, e
  um `git push` sem argumentos com push.default=upstream iria para a integração. Ficou --no-track nos dois
  `-b`, com o caso (f1) conferindo que não há upstream e o mutante (u-MUT) mordendo. (2) Real, curado: o fetch
  podia travar pedindo credencial numa sessão sem TTY. Ficou GIT_TERMINAL_PROMPT=0, e a falha vira aviso
  "remota NÃO buscada". (3) Não é defeito: o deny do settings.local.json fica fora da conta. Ele não é
  versionado e o update não o toca. (4) Não é defeito: edição do vendor ADJACENTE à do adotante no
  settings.json gera conflito git, que o vendor-branch devolve ao maestro (rc 10). A fixture (d5) separa as
  edições de propósito e diz isso. Bancada: update_base_and_deny 12/0, com 4 mutantes (f-MUT, u-MUT, d-MUT e
  s-MUT, a fusão antiga que sobrescreve). Mais adopt_robust, adopt_update_source, worktree_hooks_ready e
  applied_delta, somando 56/0 na rodada conjunta. Sem Elenxo, declarado: é a cura de um helper de branch e um
  medidor read-only, sem veredito novo de guarda. tokens 0 = não medido.
---

# Resíduo — `fix/update-branch-fresh-base`

Teto: o deny-monotonic.sh mede o `settings.json` versionado da ponta mais nova da integração contra a árvore
da branch do update. Se as pontas local e remota divergem, ele lê a primeira candidata, que é a local. O
dedicated-branch.sh já recusa esse estado (rc 2) antes de a branch nascer, então a medida só cai nesse caso
numa branch criada por fora do helper.
