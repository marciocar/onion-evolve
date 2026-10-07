---
title: 'Resíduo — colheita da fila 2026-10-06, o nó da seleção do pre-commit e um falso positivo da REGRA 63'
date: 2026-10-07
branch: chore/queue-precommit-selection
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Registro pedido pelo maestro: re-forjar o pre-commit para escolher a bancada por caso. Antes de
  registrar, medido em origin/main 33d4067a com lint-selftest.sh --affected <arquivo> --dry-run:
  tocar a própria bancada cai no failsafe (todas as famílias), e um núcleo fixo de 14 famílias entra
  em qualquer commit, inclusive num que só toca docs/README.md. Isso virou E_PRECOMMIT_SELECAO_GROSSA,
  que sustenta o compromisso Q_PRECOMMIT_SELECAO_POR_CASO (open). Para caber sem estourar o TETO de 30,
  a fila foi colhida: saíram os 5 nós done (Q_PRECOMMIT_NAO_LAVA_RESIDUO, Q_ADOPT_TRES_DEFEITOS,
  Q_HOOK_LER_RESIDUO_DA_BRANCH_DO_PR, Q_ONION_KG_SSOT_REPO, Q_TABELA_DE_TEMPOS_NO_MAPA) e as 4
  evidências que só sustentavam eles (E_PRECOMMIT_RECARIMBA_RESIDUO, E_ADOPT_SEM_GITIGNORE_DE_SEGREDOS,
  E_DURABLE_COMMIT_SEM_ASSINATURA, E_CI_TEMPLATE_IGNORA_GITHOOKS). Nenhum outro grafo cita esses ids;
  só resíduos antigos, em prosa, e a história fica no git. 30 → 23 nós; radar --integrity --schema
  exit 0. REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed dele) — confirmed vistos: E_PR_FINALIZE_PAGOU_PRIMEIRO_DIA, E_HOOK_PR_SEM_PASSADA_FALSO_POSITIVO, E_MAPA_SEM_MERGE_ONION_HOOKS, E_DOIS_LEITORES_DIVERGIAM, E_NARRATIVA_NO_ROTULO_VAZA_GABARITO, E_RADAR_CEGO_A_TIPO_TROCADO, E_CANAL_VIVO_ENTRE_SESSOES_USADO, E_MERGE_GATE_INERTE_NO_ADOTANTE, D_PAPEL_DUAS_DIMENSOES, E_PRECOMMIT_SELECAO_GROSSA.
  Achado curado no caminho: a REGRA 63 (Colheita de grafo emite os ids colhidos no resíduo de
  revisão) acusou HARD pedindo para nomear Q_GRANAAI_CLONE_SEM_CARIMBO, que NÃO foi colhido: ao
  inserir os nós novos antes das arestas, o diff de linhas mostrou esse nó saindo e voltando. A
  guarda agora desconta os ids readicionados no mesmo diff; caso (e) da família harvest_residue
  (nó só movido → cala), e o mutante que remove o desconto faz o caso reprovar (medido). Pre-commit
  pulado por ordem do maestro (checkpoint --no-verify); validação = família tocada + mutante +
  pr-finalize + CI. Sem Elenxo, declarado: registro de compromisso, colheita de itens já fechados e
  uma cura estreita de falso positivo com caso e mutante.
---

# Resíduo — `chore/queue-precommit-selection`

Registro de fila; nenhum código muda.
