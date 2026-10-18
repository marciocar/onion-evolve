---
title: 'Resíduo — o pr-finalize nomeia a etapa e o rc da rodada que para, e o --rebase aceita índice sujo'
date: 2026-10-18
branch: fix/pr-finalize-step-and-dirty-rebase
reviewed_diff_sha256: 4f5605769a9a8d2e738681e57cb50655ddae353b6754d230c5f14402987017f9
reviewed_code_sha256: 586a478933d74dc4ca30f5597771b2627a1abed6b1d8f94ca67e2374b33d0760
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 75
verdict: CORRIGIDO
elenxo: nao
nota: >-
  As duas pendências de Q_PR_FINALIZE_MELHORIAS foram revistas contra o código e medidas antes de ir ao
  maestro, que selou as duas recomendações por pergunta com opções. (1) Medido: um SIGTERM no grupo de
  processos, que é o que o runner faz, matava a rodada com rc=143, e o log terminava na linha do
  pré-voo sem dizer que tinha morrido, em que etapa nem com que código. Não dava para distinguir de uma
  rodada ainda viva. Agora o motor marca a etapa corrente (preparação, rebase, 0 pré-voo … 5 push) e o
  trap de saída imprime "parou na etapa «X» (rc=R)" ou "MORREU por sinal TERM na etapa «X»". Sem os
  traps de TERM/INT o bash morria sem rodar o de saída: esse era o defeito real. (2) Medido: o --rebase
  com índice sujo recusava com rc=1, e o commit feito à mão rodava o pre-commit inteiro para um commit
  que a etapa 3 linta de qualquer forma. Agora o conteúdo stageado vira commit pelo mesmo _commit (a
  mesma regra de hook) antes do rebase, e o commit de projeções seguinte não repete o assunto do PR.
  Não usei stash, porque o --autostash tiraria o conteúdo do índice. Dogfood num clone descartável: o
  kill do grupo imprime a etapa; a branch atrás da main com índice sujo passa a rc=0, com 0 HARD. (3)
  ACHADO, curado: um caso antigo da família pre_push ("PR aberto + 0 HARD → passa") rodava o pré-voo do
  CHECKOUT VIVO, e num PR que mexe na própria família ela rodava dentro de si mesma. O veredito dependia
  do cache do pré-voo: medido 1 ✗ sem cache e 58/58 com. A cura é o ponto de teste
  ONION_PREPUSH_PREFLIGHT no pre-push, que só vale sob ONION_PREPUSH_TEST=1, e a bancada aponta um stub.
  Bancada pre_push: 58/58, com os casos (dr), (st) e (sig), cada um com o seu mutante. A catraca de locale
  pegou um [^»] meu no (sig) e foi corrigida. As famílias vizinhas (preflight_*, hook_regen_table,
  shell_pipefail_robustness) passam verdes. Grafo: Q_PR_FINALIZE_MELHORIAS passa a done.
  (4) ACHADO DO CI, curado: a 1ª versão deste PR deixou a faixa 2 calada 14 min até o timeout. O caso
  "worktree do commit empurrado + 0 HARD", que é antigo, e o caso do "eater" chamavam o hook sem stub. O
  pré-voo rodava a pre_push (o diff a muda), ela chamava o hook, e de novo, SEM FIM: medido na VPS, 24
  processos aninhados. O meu "58/58" local só passava pelo cache do pré-voo. Duas curas: o stub agora é
  EXPORTADO no início da família, e vale para as chamadas diretas; e uma guarda de classe no
  preflight-run.sh, que não roda aninhado dentro de outro pré-voo (ONION_IN_PREFLIGHT, repassada pelo
  env -i). Medido depois: pre_push em 67 s, 58/58, zero órfãos. Num clone descartável com tudo
  commitado, o caminho antigo termina em 64 s com o pré-voo 61/61 (antes, timeout).
  Confirmed do grafo editado, todos vistos: E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA, E_HOOK_PR_SEM_PASSADA_CURADO,
  E_MAPA_SEM_MERGE_ONION_HOOKS, E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO,
  E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE,
  E_SKILL_CORE_ONLY_VIAJOU, D_PAPEL_DUAS_DIMENSOES, E_PR_FINALIZE_ATRITO_MEDIDO,
  E_CONFLITO_DE_PROJECAO_GERADA, E_BRAIN_MCP_PEDIDO_DE_CAMPO. Sem Elenxo, declarado: os modos de falha
  foram provocados de verdade (kill do grupo, índice sujo atrás da main) e cada cura tem mutante; a
  rodada que fecha este PR é o próprio motor novo.
---

# Resíduo — `fix/pr-finalize-step-and-dirty-rebase`

Teto: se o runner matar só o PID do motor e não o grupo, o bash espera o filho em primeiro plano
terminar antes de rodar o trap. A linha sai atrasada, mas sai. Morte por SIGKILL não roda trap nenhum,
e esse limite é do sistema.
