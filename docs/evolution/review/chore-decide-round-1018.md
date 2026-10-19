---
title: 'Resíduo — a rodada do /meta:decide de 2026-10-18: quatro selos, a fila colhida e o pin da action em dia'
date: 2026-10-18
branch: chore/decide-round-1018
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 30
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Rodada do /meta:decide de 2026-10-18. Na 2ª rodada (2026-10-19) o maestro selou Q_GRANAAI_CLONE_SEM_CARIMBO em "Guarda lê a integração"; a cura vai em PR próprio. Na 1ª, escolheu as quatro recomendadas, e cada uma foi selada pelo
  kg-decide-seal.sh, com radar e contrato verdes: D_PORTAS_ENSAIAR_E_PUBLICAR_1018 (door-role-parity),
  D_WRITER_MEDIR_E_ATUALIZAR_1018 (mcp-kg-writer), D_GRANAAI_MEDIR_ANTES_1018 e D_FILA_PODA_PRIMEIRO_1018
  (fila). As duas da fila são decisões de RUMO, não de encerramento, e por isso nascem como nós novos ligados
  às perguntas, que seguem abertas. A fila estava no teto de 30: colhi a trinca do pr-finalize
  (Q_PR_FINALIZE_MELHORIAS done e as duas evidências que só a sustentavam); as referências externas eram dados
  históricos de triagem e o índice de leitura, que é gerado. ACHADO, barrado pelo próprio selador: o 1º selo
  do granaai levava para a proveniência o texto da pergunta, que tinha um caminho de máquina, e a REGRA 99
  desfez a escrita. Refeito com a pergunta sem o caminho. Também neste PR, derivado da ordem de base atual e
  sem pergunta: o pin do claude-code-action sobe de v1.0.252 para v1.0.253 (5eb090f3, commit conferido pela
  tag anotada). O diff é um commit só, que leva o CLI a 2.1.303 e o SDK a 0.3.303, sem tocar input nem output
  usado pelo job; a prova fica para o PR seguinte, porque este edita o workflow. Confirmed dos grafos
  editados, todos vistos: fila-2026-10-06.kg.yaml: E_HOOK_PR_SEM_PASSADA_CURADO, E_MAPA_SEM_MERGE_ONION_HOOKS,
  E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO, E_RADAR_CEGO_A_TIPO_TROCADO,
  E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE, E_SKILL_CORE_ONLY_VIAJOU,
  D_PAPEL_DUAS_DIMENSOES, E_CONFLITO_DE_PROJECAO_GERADA, E_BRAIN_MCP_PEDIDO_DE_CAMPO · door-role-
  parity-2026-09.kg.yaml: E_DANO_85_ARQUIVOS, C_DUAS_FONTES_SEM_COBRANCA, E_LINT_NAO_FICA_NO_CAMINHO,
  C_TIER_HUB_E_CAPACIDADE, D_GUARDA_EM_DUAS_LINHAS, E_CORTE_DERIVA_COMPANHEIROS_DO_COMANDO,
  E_ONION_CORE_NASCEU_PUBLICO_2026_09_17, D_MATRIZ_DE_PORTAS_2026_10, E_ADOCAO_ROBUSTA_F1,
  E_REGISTRO_HONESTO_F15, E_HISTORICO_DO_REGISTRO_DAS_PORTAS, E_HISTORICO_DO_REGISTRO_DOS_ADOTANTES,
  E_MANIFESTOS_POR_PAPEL_F2, E_PUBLICAR_SOB_DEMANDA_F3, E_PLUGINS_FORA_DO_CORE_F4, E_MINI_GERADO_F5,
  E_DESTILACAO_DO_MINI_VIRA_ARTEFATO_ARQUIVADO, E_PORTAS_PUBLICADAS_F6,
  D_FABRICA_DE_VERTICAIS_FICA_FORA_DO_PLUGIN, D_PAPEL_DE_ADOCAO_STANDALONE_NAO_E_A_PORTA,
  E_CORTE_POR_DESTINO_MEDIDO, D_MINI_SEGUE_ENXUTO, D_PERSONALITY_SYNC_NO_CONJUNTO_FEDERACAO,
  E_ROLE_STANDALONE_RESPONDE_DUAS_PERGUNTAS, D_MODO_PORTA_VEM_DO_KIND, E_VERSIONAMENTO_NA_BANCADA,
  C_MAJOR_EXIGE_API_DECLARADA, C_CHANGELOG_DIZ_NENHUMA_QUEBRA, C_VERSAO_NUNCA_E_GUARDA,
  C_RECONCILIAR_O_SEMVER_SUPERADO, E_VAZAMENTO_SO_NO_FIM_DA_PUBLICACAO, D_VARREDURA_DA_PUBLICACAO_RODA_NO_PR,
  E_CARIMBADOR_DO_CACHE_LIA_O_CLONE_LOCAL, D_CACHE_DO_PIN_LE_O_REMOTO_PELA_LEITURA_DO_STATUS,
  E_FONTE_DO_UPDATE_SEM_ESCOLHA, D_FONTE_DO_UPDATE_RESOLVIDA_POR_MECANISMO, E_PROPOSTA_CONTAVA_A_RELEASE_NOVA
  · mcp-kg-writer-2026-10.kg.yaml: . Sem Elenxo, declarado: selos de testemunho do maestro pelo mecanismo,
  colheita de nós concluídos sem referência viva e um bump de pin lido no diff.
---

# Resíduo — `chore/decide-round-1018`

Teto: os selos registram o que o maestro escolheu, e a execução de cada um (publicar, medir e atualizar o writer,
medir o granaai, a poda) vem nos PRs seguintes.
