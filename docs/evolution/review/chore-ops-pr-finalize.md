---
reviewed_diff_sha256: a7154bac1c31e9601bdcf26c94b960a1566dc64cf1d915f98a6bcda9c94bdb50
reviewed_code_sha256: cd477ccca57c93238695fae5c3adb0c8d1a29d0797fde38457a57120a7a242c8
findings_total: 10
findings_real: 10
tokens: 145702
duration_min: 37
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  1ª passada do Elenxo (opus, worktree isolada, sandbox git real sobre 376e04c2): REPROVADO com 3
  bloqueadores — B1 o motor LAVAVA resíduo (recarimbava com o código mudado), B2 lint-rules.md fora do
  commit e veredito lido da árvore, B3 gh falhando lido como "sem PR" — e 7 maiores (lease vazio depois
  do fetch, --rebase declarando sucesso sem rebasear, resíduo isento antes do PR, diagnóstico que
  escondia o HARD, mutante sobrevivente, custo ~10x o declarado, commits antes do veredito). Todos
  curados, salvo o último, declarado. Bancada 18/18; 12 de 13 mutantes mordem — o 13º é redundante por
  construção (o ramo seguinte recusa o mesmo caso).
---

# Resíduo — `chore/ops-pr-finalize`

Motor `ops/pr-finalize.sh` + gatilho `.githooks/pre-push`. Grafo: `guard-pre-push-2026-10`
(`E_ELENXO_REPROVOU_O_MOTOR_QUE_LAVAVA_RESIDUO`, `D_MOTOR_EM_OPS_E_GATILHO_NO_PRE_PUSH_DO_GIT`).
