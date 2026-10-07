---
title: 'Resíduo — o programa do SDAAL completo do task manager entra na fila'
date: 2026-10-07
branch: chore/queue-task-manager-sdaal-program
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 5
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Nota do maestro (2026-10-07): forjar o SDAAL do task manager por inteiro, em ondas, com o plano gerido
  num task manager. Medido antes de registrar: o % de progresso (zoho.md:311, pós-#956) pesa as fases
  igual e ignora story points, e nenhum adapter calcula o % da task-mãe (E_TM_PERCENTUAL_IGNORA_STORY_POINTS).
  Nó Q_TASK_MANAGER_SDAAL_COMPLETO (open): interface com assinaturas do vocabulário padrão, declaração por
  adapter de mínimo/obrigatório/implementado/não implementado por versão, e a maquinaria de criar, validar e
  atualizar adapter. 24 → 26 nós; radar --integrity --schema exit 0; nenhum id colhido. REGRA 87 (PR que
  EDITA um .kg.yaml enxergou os confirmed dele) — confirmed vistos: E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA, E_HOOK_PR_SEM_PASSADA_FALSO_POSITIVO, E_MAPA_SEM_MERGE_ONION_HOOKS, E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO, E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE, D_PAPEL_DUAS_DIMENSOES, E_PRECOMMIT_SELECAO_GROSSA, E_PR_FINALIZE_ATRITO_MEDIDO, E_TM_PERCENTUAL_IGNORA_STORY_POINTS. Sem Elenxo, declarado:
  registro de compromisso. Pre-commit pulado por ordem do maestro; validação = pr-finalize + CI.
---

# Resíduo — `chore/queue-task-manager-sdaal-program`
