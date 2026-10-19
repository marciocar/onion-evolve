---
title: 'Resíduo — a catraca de tamanho do CLAUDE.md (REGRA 109) e o selo da poda em duas pernas'
date: 2026-10-19
branch: feat/claude-md-size-ratchet
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 9
findings_fixed: 8
tokens: 110310
duration_min: 60
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Forja pelo /meta:forge-guard da 1ª perna de D_PODA_CATRACA_E_L2_DIRIGIDO_1019, selada pelo maestro hoje no
  grafo da fila (o grafo da poda estava no teto). Defeito datado: o CLAUDE.md foi de 17.041 B para 25.918 B
  (+52%) depois do selo de 2026-09-25 que mandava medir antes de podar. A guarda é check de lint (REGRA 109) no
  molde do ops-citation-travel-check.sh: teto em bytes num baseline versionado, HARD acima dele, SOFT com folga
  maior que 512 B, e catraca contra o merge-base com a integração, em que o teto só sobe com linha raise: nova
  citando nó existente. O refutador isolado reprovou a 1ª versão com 7 achados executados: catraca contra a
  ponta da main (acusava PR honesto depois de uma poda na main), teto sem folga para a contagem da REGRA 9,
  travamento com flag sem valor, NODE_ID cru numa regex, raise: antiga editada contando como nova, baseline
  apagado desligando a guarda, e outras cargas permanentes fora do alcance. Os seis primeiros foram curados,
  cada um com caso e mutante que morde (14 casos no --selftest). O sétimo fica declarado como TETO em nó
  próprio. O teto nasce em 25.982 B, com 64 B de folga declarada no baseline para a contagem da REGRA 9.
  No 1º CI, duas reprovações curadas no mesmo PR: o arquivo de teto chamava-se *-baseline.txt, e essa convenção exige emissor --emit-baseline (regen-ensure-from (g)); virou claude-md-size-ceiling.txt, que diz o que ele é. E a falha intermitente do empty-result-guard (g) era a classe EPIPE (printf | grep -q sob pipefail) no próprio hook: 10 pontos trocados por here-string, e o caso (r), com comando de 200 KB, a torna determinística (hook antigo calou 8 de 8 vezes, o curado acusou 8 de 8). Tokens = os do refutador. Confirmed dos grafos editados, todos vistos: fila-2026-10-06.kg.yaml: E_HOOK_PR_SEM_PASSADA_CURADO, E_MAPA_SEM_MERGE_ONION_HOOKS, E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO, E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE, E_SKILL_CORE_ONLY_VIAJOU, D_PAPEL_DUAS_DIMENSOES, E_CONFLITO_DE_PROJECAO_GERADA, E_BRAIN_MCP_PEDIDO_DE_CAMPO · claude-md-size-2026-10.kg.yaml: E_CLAUDE_MD_CRESCEU_52_DEPOIS_DO_SELO, C_TETO_MEDE_BYTES_NAO_COMPORTAMENTO, C_TETO_NO_CITADO_SO_POR_EXISTENCIA, C_TETO_CATRACA_PRECISA_DA_INTEGRACAO, C_TETO_NAO_VE_OUTRAS_CARGAS_PERMANENTES
---
