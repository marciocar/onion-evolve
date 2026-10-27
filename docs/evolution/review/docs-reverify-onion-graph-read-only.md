---
title: "Revisão: re-verificação no vivo de 23 nós lidos da maquinaria"
date: 2026-10-27
branch: docs/reverify-onion-graph-read-only
pr: pendente
reviewer: "passada adversarial do próprio autor sobre cada nó novo, conferindo cada afirmação contra a saída do comando que a sustenta; duas frases que diziam mais que a medição foram cortadas"
reviewed_diff_sha256: dcad99c579f6051c2be13b3a092321624dead4a2ee5726fd4e77413dd6dd7b96
reviewed_code_sha256: 5d6ef488daf03487d479633456e78529d5748b920defd2c6c0a5e079b60b7180
findings_total: 2
findings_real: 2
verdict: CORRIGIDO
elenxo: sim
tokens: 0
duration_min: 20
nota: "Dois achados da passada, os dois curados antes do push. (1) O nó do offsite dizia '54 FALHOU rc=3, um por dia de 10-13 a 10-27', o que soma 15, não 54. Os 54 são do log inteiro; a redação passou a separar o total da janela. (2) O nó da rede afirmava que 'o Docker continua furando o ufw', e isso não foi medido nesta rodada (só docker ps e network ls). A frase saiu."
---

# Resíduo da REGRA 56

Re-verificação de 23 nós da camada canônica que afirmavam algo sobre a maquinaria do Onion com
`method: "leitura:"`. Cada nó ganhou uma evidência `measurement:` com o comando e o observado.
O resultado: 15 CONFIRMED, 7 DRIFTED, 0 REFUTED e 1 em parte UNVERIFIABLE.

Gates rodados antes do push: `kg-radar.sh --integrity --schema` com rc 0 nos 10 grafos,
`ops/kg-gate-ci.sh` com rc 0, a bancada de 10 famílias (98/0/0) e o pre-commit completo do
1º commit (lint com 0 HARD, bancada de 105 famílias 1513/0/0).

Ids (para a guarda): E_REVERIFY_DIARY_REVIEW_RODADO_1027 E_REVERIFY_KG_VIEW_PARSE_UNICO_1027
E_REVERIFY_REGRA28_DUAS_CLASSES_1027 E_REVERIFY_INVENTARIO_SSOT_REGERADO_1027
E_REVERIFY_FRESHNESS_SEM_WORK_TOOLS_1027 E_REVERIFY_INGESTOR_SEGUE_SEM_EXECUTAVEL_1027
E_REVERIFY_NONE_ADAPTER_RODADO_1027 E_REVERIFY_RADAR_SEM_CADENCIA_HISTORICO_1027
E_REVERIFY_REGRA_SEM_FIXTURE_SEGUE_SEM_GATE_1027 E_REVERIFY_REDE_SEM_BIND_PUBLICO_1027
E_REVERIFY_HOOK_PIPE_CEGO_AO_OU_1027 Q_HOOK_PIPE_OU_TRATADOR_NAO_COBERTO_1027
E_REVERIFY_POSTMARK_REPO_E_DNS_1027 E_REVERIFY_OFFSITE_ARMADO_E_FALHANDO_1027
Q_OFFSITE_PARADO_DESDE_1012_GPG_FRIO_1027 E_REVERIFY_SEGUNDO_DESTINO_SEGUE_AUSENTE_1027
E_REVERIFY_SOURCE_TAMBEM_E_A_PORTA_1027 E_REVERIFY_DECOUPLE_SOURCE_BANCADA_1027
E_REVERIFY_HAGEL_GIT_REPRODUZ_1027 E_REVERIFY_DOGFOOD_VALUE_PRS_1027
E_REVERIFY_CANARY_BANCADA_1027 E_REVERIFY_FRESHNESS_LAZY_HOOK_RODADO_1027
E_REVERIFY_DESIGN_SETUP_PEER_REF_1027 E_REVERIFY_ROTA_DEMO_401_E_SEM_DRIFT_1027
