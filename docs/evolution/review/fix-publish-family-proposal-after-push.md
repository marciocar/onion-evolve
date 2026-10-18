---
title: 'Resíduo — a proposta de versão não conta a release que a própria rodada publica'
date: 2026-10-18
branch: fix/publish-family-proposal-after-push
reviewed_diff_sha256: f2c1010a014df41f99e13dba17b51ca3335980f0bd3d07f27857e76183a3e795
reviewed_code_sha256: 1d88f8bc179f70f836b6169a13e85b288ba39b2790709ba5d5cf7ba665d130b6
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 40
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Pedido do maestro: medir e curar o aviso falso depois da publicação da onion-v2.0.0. Medido: o --all --push
  terminou com "PROPOSTA DA FAMÍLIA onion-v3.0.0" e com a linha de divergência em cada tag. A causa: a 1ª
  porta cria a tag do número selado, e as seguintes liam o máximo da família (FAM_MAX) já com ela e somavam o
  nível medido contra a release anterior delas (1.2.1 → major), de modo que 2.0.0 virava 3.0.0. A cura separa
  as duas perguntas que FAM_MAX respondia: ele segue conferindo que o número selado passa da família, e
  PROP_BASE, que exclui o número desta rodada, vira a base da proposta. Não afetou o que foi publicado, só a
  proposta impressa e a linha de divergência. Bancada: caso (r3g) em run_publish_release_selftests, com
  mutante; publish_release e publish passam 61/61. ACHADO no caminho, curado: a 1ª redação do mutante apagava
  a tag da porta-p e commitava no core do sandbox, e derrubou o caso antigo (r9); agora o mutante troca o
  script só na árvore e compara as duas bases num ensaio com --version, sem push. Dogfood contra as portas
  reais: o ensaio --all --version 2.0.0 deu 2.0.0 nas quatro portas e na família, sem aviso. Grafo:
  E_PROPOSTA_CONTAVA_A_RELEASE_NOVA no door-role-parity, que SUPPORTS D_VERSIONAR_AS_PORTAS_POR_RELEASE
  (doutrina do publish, passo 6). Confirmed do grafo editado, todos vistos: E_DANO_85_ARQUIVOS,
  C_DUAS_FONTES_SEM_COBRANCA, E_LINT_NAO_FICA_NO_CAMINHO, C_TIER_HUB_E_CAPACIDADE, D_GUARDA_EM_DUAS_LINHAS,
  E_CORTE_DERIVA_COMPANHEIROS_DO_COMANDO, E_ONION_CORE_NASCEU_PUBLICO_2026_09_17, D_MATRIZ_DE_PORTAS_2026_10,
  E_ADOCAO_ROBUSTA_F1, E_REGISTRO_HONESTO_F15, E_HISTORICO_DO_REGISTRO_DAS_PORTAS,
  E_HISTORICO_DO_REGISTRO_DOS_ADOTANTES, E_MANIFESTOS_POR_PAPEL_F2, E_PUBLICAR_SOB_DEMANDA_F3,
  E_PLUGINS_FORA_DO_CORE_F4, E_MINI_GERADO_F5, E_DESTILACAO_DO_MINI_VIRA_ARTEFATO_ARQUIVADO,
  E_PORTAS_PUBLICADAS_F6, D_FABRICA_DE_VERTICAIS_FICA_FORA_DO_PLUGIN,
  D_PAPEL_DE_ADOCAO_STANDALONE_NAO_E_A_PORTA, E_CORTE_POR_DESTINO_MEDIDO, D_MINI_SEGUE_ENXUTO,
  D_PERSONALITY_SYNC_NO_CONJUNTO_FEDERACAO, E_ROLE_STANDALONE_RESPONDE_DUAS_PERGUNTAS,
  D_MODO_PORTA_VEM_DO_KIND, E_VERSIONAMENTO_NA_BANCADA, C_MAJOR_EXIGE_API_DECLARADA,
  C_CHANGELOG_DIZ_NENHUMA_QUEBRA, C_VERSAO_NUNCA_E_GUARDA, C_RECONCILIAR_O_SEMVER_SUPERADO,
  E_VAZAMENTO_SO_NO_FIM_DA_PUBLICACAO, D_VARREDURA_DA_PUBLICACAO_RODA_NO_PR,
  E_CARIMBADOR_DO_CACHE_LIA_O_CLONE_LOCAL, D_CACHE_DO_PIN_LE_O_REMOTO_PELA_LEITURA_DO_STATUS,
  E_FONTE_DO_UPDATE_SEM_ESCOLHA, D_FONTE_DO_UPDATE_RESOLVIDA_POR_MECANISMO, E_PROPOSTA_CONTAVA_A_RELEASE_NOVA.
  Sem Elenxo, declarado: a cura é de uma linha de base, provada pela publicação real, pelo ensaio real e pelo
  mutante.
---

# Resíduo — `fix/publish-family-proposal-after-push`

Teto: a cura vale para a mesma release no mesmo pin. Uma porta publicada noutro dia, com o core andando,
segue propondo sobre o máximo da família, que é o comportamento certo.
