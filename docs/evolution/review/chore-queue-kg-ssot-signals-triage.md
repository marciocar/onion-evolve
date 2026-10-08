---
title: 'Resíduo — triagem dos sinais do contrato do .kg.yaml e do Brain MCP'
date: 2026-10-08
branch: chore/queue-kg-ssot-signals-triage
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 20
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Triagem do /meta:co-evolve de 2026-10-08, selada pelo maestro por pergunta. 8 sinais lidos inteiros e
  arquivados em inbox/_processed: os 2 já curados nesta leva (spike-schema pelo #957, Zoho pelo #956) e
  os 6 novos. Conferido no vivo antes: trace repetido em 5 de 140 grafos; REGRA 78 e REGRA 82 varrem
  git ls-files sem o predicado de fixture; o backlog enumera só rastreados. Os fixes confirmados vão no
  PR fix/kg-ssot-signals-confirmed. Decisões seladas: o gate chama o validador do contrato
  (D_GATE_CHAMA_O_VALIDADOR_DO_CONTRATO); gerador primeiro, corpus em ondas
  (Q_MIGRAR_CORPUS_PARA_CONTRATO_V3); Brain MCP vai a pesquisa + decisão (Q_ONION_BRAIN_MCP). Os nós do
  contrato nasceram num grafo próprio (contrato-kg-absorcao-2026-10, 6 nós) porque a fila está no teto
  de 30; a fila recebeu só o par do Brain MCP (28 → 30). Os dois radares --integrity --schema exit 0;
  nenhum id colhido (6 nós saíram da fila no mesmo PR em que nasceram, nunca estiveram na main). REGRA
  87 (PR que EDITA um .kg.yaml enxergou os confirmed dele) — confirmed vistos: E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA, E_HOOK_PR_SEM_PASSADA_FALSO_POSITIVO, E_MAPA_SEM_MERGE_ONION_HOOKS, E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO, E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE, D_PAPEL_DUAS_DIMENSOES, E_PRECOMMIT_SELECAO_GROSSA, E_PR_FINALIZE_ATRITO_MEDIDO, E_TM_PERCENTUAL_IGNORA_STORY_POINTS, E_CONFLITO_DE_PROJECAO_GERADA, E_BRAIN_MCP_PEDIDO_DE_CAMPO, E_GATE_ACEITA_FORMA_QUE_O_CONTRATO_REPROVA, D_GATE_CHAMA_O_VALIDADOR_DO_CONTRATO, E_CONTRATOS_V2_V3_PEDEM_MIGRACAO. Sem Elenxo,
  declarado: registro de decisões já seladas pelo maestro. Pre-commit pulado por ordem do maestro;
  validação = pr-finalize + CI.
---

# Resíduo — `chore/queue-kg-ssot-signals-triage`
