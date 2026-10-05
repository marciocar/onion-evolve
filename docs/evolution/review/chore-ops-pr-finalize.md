---
reviewed_diff_sha256: 6b0c5a51069aec7147a8128abde661507c6b5f9d512389845d2ef1f7cf35adba
reviewed_code_sha256: e8c3c948e8d0c9369126b4cde7cf1d582171ca8429d4853b3e7975998e58806b
findings_total: 20
findings_real: 20
tokens: 298815
duration_min: 48
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  2ª PASSADA (opus, 4a357b01): REPROVADO — 1 bloqueador (B1 reaberto: hash entre aspas/espaço
  tratado como pendente e recarimbado), 5 maiores (sobra de edição 157-165; die em $(...) sem abortar;
  falso positivo no rebase limpo; marcador depois do gh; 11 de 19 mutantes sobreviviam) e 4 menores
  (remote por nome; exclusão do dir review inteiro no hash de código; stdin do laço; caso r3). Todos
  curados neste PR; família 32/32; 23 de 24 mutantes mordem (o 24º é redundante por construção).
  O menor 8 na GUARDA (exclui o dir inteiro) fica declarado: o motor agora exclui só o próprio resíduo.
  FORA DO ESCOPO, CURADO AQUI (o core não devolve defeito pré-existente): o Claude Code subiu para
  2.1.290 no meio da sessão e a bancada (f) do cited-directive acusou DERIVA — re-extraídos PCe/lUn/dUn/
  aFr/D3n; semântica igual (aFr = trim + CRLF→LF); selftest 15/15.
  1ª PASSADA:   1ª passada do Elenxo (opus, worktree isolada, sandbox git real sobre 376e04c2): REPROVADO com 3
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
