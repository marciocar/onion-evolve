---
title: 'Resíduo — o conflito de projeção gerada entre PRs paralelos entra na fila'
date: 2026-10-08
branch: chore/queue-generated-projection-conflicts
reviewed_diff_sha256: 2dd794cf5e2416c3f1aa534d208cafe11a8c5ee4c024cd0c878bae9489d73ae6
reviewed_code_sha256: f4c740e74e2df5f1f178f5ff29280b7d7fce5e8dbdad090ed9200e976cdfd41f
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 5
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Pedido do maestro (2026-10-08), depois de perguntar por que os rebases apareceram. Na leva de
  2026-10-07/08, com até 6 PRs abertos, cada merge deixou os vizinhos em CONFLICTING nas projeções
  geradas que todo PR commita, e PR em conflito não dispara CI. E_CONFLITO_DE_PROJECAO_GERADA sustenta
  Q_MERGE_DRIVER_PARA_PROJECAO_GERADA (open). 26 → 28 nós; radar --integrity --schema exit 0; nenhum id
  colhido. REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed dele) — confirmed vistos: E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA, E_HOOK_PR_SEM_PASSADA_FALSO_POSITIVO, E_MAPA_SEM_MERGE_ONION_HOOKS, E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO, E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE, D_PAPEL_DUAS_DIMENSOES, E_PRECOMMIT_SELECAO_GROSSA, E_PR_FINALIZE_ATRITO_MEDIDO, E_TM_PERCENTUAL_IGNORA_STORY_POINTS, E_CONFLITO_DE_PROJECAO_GERADA.
  Sem Elenxo, declarado: registro de compromisso. Pre-commit pulado por ordem do maestro; validação =
  pr-finalize + CI.
---

# Resíduo — `chore/queue-generated-projection-conflicts`
