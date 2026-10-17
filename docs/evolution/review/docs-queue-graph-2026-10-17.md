---
title: 'Resíduo — a fila de 2026-10-06 re-medida contra o vivo: um falso positivo curado, uma hipótese confirmada, um item feito'
date: 2026-10-17
branch: docs/queue-graph-2026-10-17
reviewed_diff_sha256: 87ec677e7ab92e9e481adc07e89b5de312c078f1fd9fc8aefa3133898a6af75b
reviewed_code_sha256: 050fe4a4ceb903927f7f6234035ffa7b9311d6379839f78d9afd6c8c53fff827
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 25
verdict: CORRIGIDO
elenxo: nao
nota: >-
  PR de grafo pedido pelo maestro. O grafo já trazia, de outras sessões, D_PAPEL_DUAS_DIMENSOES, o nó
  GATED Q_VETO_PRETOOLUSE_NO_PR_CREATE e Q_GRANAAI_CLONE_SEM_CARIMBO. Não dupliquei nenhum deles. Cada
  item aberto foi re-medido contra o código de hoje:
  (1) o falso positivo do aviso PR-SEM-PASSADA-ADVERSARIAL foi curado no #948, com bancada e mutante e
  provado ao vivo em #949, #1186 e #1187, por isso nasce E_HOOK_PR_SEM_PASSADA_CURADO, que faz SUPERSEDES
  sobre E_HOOK_PR_SEM_PASSADA_FALSO_POSITIVO;
  (2) E_SKILL_CORE_ONLY_VIAJOU deixa de ser hipótese e passa a confirmed: o manifesto de papel adopted,
  extraído por git archive, entrega .claude/skills/onion-publish, porque o _role_cut só a corta em
  standalone|plugins. Q_MANIFESTO_SEM_SKILL_CORE_ONLY segue open, agora com a cura nomeada;
  (3) Q_MAPA_NOMEAR_MERGE_ONION_HOOKS passa a done: o --map já faz hooks_diff e merge_hooks_prune
  reivindicarem o merge-onion-hooks.sh;
  (4) Q_MERGE_GATE_AVISA_NO_ADOTANTE segue open, re-medido: a trava ainda sai com exit 0 calada sem
  ops/pr-merge-verified.sh;
  (5) Q_PR_FINALIZE_MELHORIAS registra que a catraca estática no checkpoint foi curada (pré-voo, #946).
  Restam a etapa e o rc da falha, e o rebase com índice sujo, que o pr-finalize.sh ainda recusa na
  linha do `--rebase exige índice limpo`.
  O grafo está no teto de 30, então colhi Q_ROTULO_SEPARADO_DA_NARRATIVA (done e sem referência
  externa; a história fica no git) para abrir a vaga.
  Achado real, curado no próprio PR: o kg-contract-check reprovou (MUST form.required.node.provenance)
  porque promovi E_SKILL_CORE_ONLY_VIAJOU a confirmed sem provenance, e o method do nó novo fugia da forma
  canônica. Os dois foram corrigidos, e contrato, radar e gate saem rc=0.
  Confirmed do grafo editado, todos vistos: E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA, E_HOOK_PR_SEM_PASSADA_CURADO,
  E_MAPA_SEM_MERGE_ONION_HOOKS, E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO,
  E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE,
  E_SKILL_CORE_ONLY_VIAJOU, D_PAPEL_DUAS_DIMENSOES, E_PR_FINALIZE_ATRITO_MEDIDO,
  E_CONFLITO_DE_PROJECAO_GERADA, E_BRAIN_MCP_PEDIDO_DE_CAMPO.
  Sem Elenxo, declarado: é um PR só de grafo, com cada mudança de status ancorada numa medição deste
  dia.
---

# Resíduo — `docs/queue-graph-2026-10-17`

Teto: re-medi só os nós abertos que esta fila nasceu para cobrar. O nó do granaai e o GATED do veto
foram escritos por outras sessões e ficaram como estão.
