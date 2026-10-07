---
title: 'Resíduo — os 4 atritos medidos do pr-finalize entram na fila'
date: 2026-10-07
branch: chore/queue-pr-finalize-findings
reviewed_diff_sha256: 60d55ea753314c07cac90c128c382d77334a508c3c9a04495d7ceb1eee094cd3
reviewed_code_sha256: f873059eb65af4ccc3b1fb5db06b046b21e0c0f99ddbad8d5f2648f43de472a9
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 5
verdict: LIMPO
elenxo: nao
nota: >-
  Pedido do maestro ("acrescente esses 4 achados ao nó quando o PR da fila fechar", depois do #955).
  Nó novo E_PR_FINALIZE_ATRITO_MEDIDO (evidência do fechamento do #955 e das rodadas do dia) sustenta
  Q_PR_FINALIZE_MELHORIAS, cujo rótulo passa a nomear a cura aprovada: carimbar só depois de tudo
  passar, commit de projeções sem religar o pre-commit quando o pré-voo passou, violações HARD na
  saída final e modo --check sem escrita. Nenhum código muda; a cura sai em PR próprio. 23 → 24 nós;
  radar --integrity --schema exit 0. Nenhum id colhido. REGRA 87 (PR que EDITA um .kg.yaml enxergou os
  confirmed dele) — confirmed vistos: E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA, E_HOOK_PR_SEM_PASSADA_FALSO_POSITIVO, E_MAPA_SEM_MERGE_ONION_HOOKS, E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO, E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE, D_PAPEL_DUAS_DIMENSOES, E_PRECOMMIT_SELECAO_GROSSA, E_PR_FINALIZE_ATRITO_MEDIDO. Sem Elenxo, declarado: registro de compromisso já
  aprovado. Pre-commit pulado por ordem do maestro; validação = pr-finalize (0 HARD) + CI.
---

# Resíduo — `chore/queue-pr-finalize-findings`

Registro de fila; nenhum código muda.
